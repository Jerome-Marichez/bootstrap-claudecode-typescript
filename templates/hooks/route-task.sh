#!/bin/bash
# Hook UserPromptSubmit — routage de modèles ({{PROJECT_NAME}})
# Classifie la demande (architecture / développement / mécanique) par heuristique
# FR/EN et RECOMMANDE le subagent adapté (.claude/agents/ : opus-architect,
# sonnet-dev, haiku-mechanic). Conception et garde-fous : docs/model-routing.md.
#
# Garde-fous anti-perte de précision :
#   - défaut = vers le haut : zone grise → sonnet-dev, jamais haiku ;
#   - recommandation, pas contrainte : le modèle principal (qui voit tout le
#     contexte) peut outrepasser — dans le doute, un cran AU-DESSUS ;
#   - escalade : un subagent qui répond « ESCALATE: <raison> » est re-délégué
#     au niveau supérieur ;
#   - override utilisateur : prompt préfixé par « !! » → aucune injection ;
#   - fail-open : toute erreur (jq absent, ccusage KO…) → exit 0 silencieux.
#
# Budget crédits (fusion de l'ancien guard-model-usage) : si CREDITS_LIMIT_TOKENS
# est défini, l'usage du bloc de facturation est lu via ccusage avec un CACHE de
# 10 min (aucun appel réseau à chaque prompt) ; budget bas → recommandation
# plafonnée à sonnet-dev. Journal JSONL : .claude/route-task.log.

set -u
command -v jq >/dev/null 2>&1 || exit 0
input=$(cat 2>/dev/null) || exit 0
prompt=$(printf '%s' "$input" | jq -r '.prompt // empty' 2>/dev/null) || exit 0
[ -z "$prompt" ] && exit 0
case "$prompt" in
  '!!'*) exit 0 ;;  # override utilisateur explicite
  /*)    exit 0 ;;  # commande slash / skill : ne pas router
esac

words=$(printf '%s' "$prompt" | wc -w | tr -d ' ')
[ "$words" -ge 1 ] 2>/dev/null || exit 0

# --- Classification heuristique (signaux FR/EN) --------------------------------
UP_RE='architectur|conception|concevoir|conçoi|redesign|refonte|migrat|scalab|montée en charge|s[ée]curit|security|auth|paiement|payment|billing|concurren|race condition|deadlock|chiffr|crypto|trade-?off|stratégi|strategy|schéma de (base|données)|data model|modèle de données|pourquoi|\bwhy\b|comment devrait|how should|repense|rethink|restructur'
DOWN_RE='typo|coquille|renomm|rename|formate|reformat|indent|docstring|commentaire|readme|changelog|\bcommit\b|\bgit (status|log|push|pull|add)\b|gitignore|\bbump\b|déplace le fichier|move the file|supprime le fichier|delete the file|trouve le fichier|find the file|où (est|se trouve)|where is'
MID_RE='impl[ée]ment|ajoute|\badd\b|cr[ée]e|corrige|\bfix\b|r[ée]pare|\bbug\b|teste|\btest\b|refactor|am[ée]liore|improve|optimis|mets? à jour|\bupdate\b|endpoint|composant|component|branche'

# Priorité : signaux UP (risque/architecture), puis longueur, puis signaux
# mécaniques nets sur prompt court (avant MID : « corrige la typo » contient un
# verbe MID mais reste mécanique), puis développement, puis zone grise → sonnet.
if printf '%s' "$prompt" | grep -Eiq "$UP_RE"; then
  class="architecture" agent="opus-architect"
elif [ "$words" -gt 150 ]; then
  class="architecture (demande longue / ouverte)" agent="opus-architect"
elif printf '%s' "$prompt" | grep -Eiq "$DOWN_RE" && [ "$words" -lt 25 ]; then
  class="mécanique" agent="haiku-mechanic"
elif printf '%s' "$prompt" | grep -Eiq "$MID_RE"; then
  class="développement" agent="sonnet-dev"
elif [ "$words" -lt 8 ]; then
  exit 0  # court et sans signal : conversationnel, ne pas polluer le contexte
else
  class="zone grise (défaut vers le haut)" agent="sonnet-dev"
fi

# --- Budget crédits (cache ccusage 10 min) --------------------------------------
budget_note="" boost_msg=""
if [ -n "${CREDITS_LIMIT_TOKENS:-}" ] && command -v npx >/dev/null 2>&1; then
  cache="${TMPDIR:-/tmp}/claude-route-task-$(printf '%s' "${CLAUDE_PROJECT_DIR:-$PWD}" | cksum | cut -d' ' -f1).json"
  if [ -z "$(find "$cache" -mmin -10 2>/dev/null)" ]; then
    if npx -y ccusage@latest blocks --active --json > "$cache.tmp" 2>/dev/null; then
      mv "$cache.tmp" "$cache"
    else
      rm -f "$cache.tmp"
    fi
  fi
  block=$(jq -c '.blocks[0] // empty' "$cache" 2>/dev/null)
  if [ -n "$block" ]; then
    tokens=$(printf '%s' "$block" | jq -r '.totalTokens // 0')
    end=$(printf '%s' "$block" | jq -r '.endTime // empty')
    end_epoch=$(date -j -u -f '%Y-%m-%dT%H:%M:%S' "$(printf '%s' "$end" | cut -c1-19)" +%s 2>/dev/null \
             || date -d "$end" +%s 2>/dev/null)
    if [ -n "$end_epoch" ]; then
      hours_left=$(( (end_epoch - $(date -u +%s)) / 3600 ))
      pct=$(( tokens * 100 / CREDITS_LIMIT_TOKENS ))
      if [ "$pct" -gt "${USAGE_THRESHOLD_PCT:-50}" ] && [ "$hours_left" -lt "${MIN_HOURS_LEFT:-2}" ]; then
        if [ "$agent" = "opus-architect" ]; then agent="sonnet-dev"; fi
        budget_note=" BUDGET CRÉDITS : ${pct}% du bloc consommés, reset dans < ${hours_left}h — recommandation plafonnée à sonnet-dev (pas d'Opus ni d'effort max) jusqu'au reset ; privilégie des réponses économes."
      elif [ "$pct" -lt "${USAGE_THRESHOLD_PCT:-50}" ] && [ "$hours_left" -lt "${BOOST_HOURS_LEFT:-1}" ]; then
        boost_msg="🟣 Crédits : ${pct}% consommés et reset dans < ${BOOST_HOURS_LEFT:-1}h — marge disponible, modèle fort utilisable sans compter."
      fi
    fi
  fi
fi

# --- Journal (évaluer avant d'abaisser un type de tâche) ------------------------
log="${CLAUDE_PROJECT_DIR:-.}/.claude/route-task.log"
if [ -d "$(dirname "$log")" ]; then
  jq -nc --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg c "$class" --arg a "$agent" \
    --arg w "$words" '{ts:$ts, class:$c, agent:$a, words:($w|tonumber)}' >> "$log" 2>/dev/null
fi

# --- Injection -------------------------------------------------------------------
ctx="ROUTAGE MODÈLE — demande classée « ${class} ». Recommandation : délègue l'exécution au subagent « ${agent} » (défini dans .claude/agents/, modèle et effort adaptés). Heuristique basée sur le prompt seul : si le contexte de la session indique une complexité différente, choisis le subagent adapté — dans le doute, un cran AU-DESSUS, jamais en dessous. Si le subagent termine par « ESCALATE: <raison> », re-délègue la tâche un niveau au-dessus (haiku-mechanic → sonnet-dev → opus-architect) avec la raison. L'utilisateur peut bypasser ce routage en préfixant son prompt par « !! ».${budget_note}"

if [ -n "$boost_msg" ]; then
  jq -n --arg ctx "$ctx" --arg msg "$boost_msg" \
    '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:$ctx}, systemMessage:$msg}'
else
  jq -n --arg ctx "$ctx" \
    '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:$ctx}}'
fi
exit 0
