#!/bin/bash
# Hook UserPromptSubmit — garde-fou consommation de crédits ({{PROJECT_NAME}})
# Deux comportements selon l'état de la session de facturation (bloc de 5 h) :
#   1. FREIN  : usage > USAGE_THRESHOLD_PCT (50 %) ET reset dans moins de
#      MIN_HOURS_LEFT (2 h) → directive : INTERDICTION d'utiliser Fable 5 ou Opus
#      en "max effort" — basculer sur un modèle/effort plus économe.
#   2. BOOST  : usage < USAGE_THRESHOLD_PCT (50 %) ET reset dans moins de
#      BOOST_HOURS_LEFT (1 h) → message VIOLET dans la console : crédits sur le
#      point d'être réinitialisés et peu consommés — Fable 5 utilisable à fond.
#
# Limites assumées :
#   - un hook ne peut pas changer le modèle lui-même : il injecte une consigne
#     forte dans le contexte + un message visible ;
#   - la consommation est estimée via `ccusage` (lecture des transcripts locaux) ;
#     le plafond du bloc doit être fourni via CREDITS_LIMIT_TOKENS (tokens) —
#     sans lui, le hook ne fait rien (pas de fausse alerte) ;
#   - nécessite : npx (ccusage), jq.

set -u
USAGE_THRESHOLD_PCT="${USAGE_THRESHOLD_PCT:-50}"
MIN_HOURS_LEFT="${MIN_HOURS_LEFT:-2}"
BOOST_HOURS_LEFT="${BOOST_HOURS_LEFT:-1}"
CREDITS_LIMIT_TOKENS="${CREDITS_LIMIT_TOKENS:-}"

[ -z "$CREDITS_LIMIT_TOKENS" ] && exit 0
command -v npx >/dev/null 2>&1 || exit 0

block=$(npx -y ccusage@latest blocks --active --json 2>/dev/null | jq '.blocks[0] // empty' 2>/dev/null)
[ -z "$block" ] && exit 0

tokens=$(printf '%s' "$block" | jq -r '.totalTokens // 0')
end=$(printf '%s' "$block" | jq -r '.endTime // empty')
[ -z "$end" ] && exit 0

end_epoch=$(date -j -f '%Y-%m-%dT%H:%M:%S' "$(printf '%s' "$end" | cut -c1-19)" +%s 2>/dev/null \
         || date -d "$end" +%s 2>/dev/null)
[ -z "$end_epoch" ] && exit 0

now=$(date -u +%s)
hours_left=$(( (end_epoch - now) / 3600 ))
pct=$(( tokens * 100 / CREDITS_LIMIT_TOKENS ))

if [ "$pct" -gt "$USAGE_THRESHOLD_PCT" ] && [ "$hours_left" -lt "$MIN_HOURS_LEFT" ]; then
  jq -n --arg pct "$pct" --arg h "$hours_left" '{
    hookSpecificOutput: {
      hookEventName: "UserPromptSubmit",
      additionalContext: ("BUDGET CRÉDITS — " + $pct + "% de la session de facturation consommés et moins de " + $h + "h avant le reset. RÈGLE STRICTE : ne PAS travailler avec Fable 5 ni Opus en max effort d ici le reset. Si le modèle courant est Fable 5 ou Opus avec un effort élevé, demande à l utilisateur de basculer (/model sonnet ou effort réduit) AVANT toute tâche lourde, et privilégie des réponses économes (pas de fan-out d agents, pas de workflows).")
    },
    systemMessage: ("⚠️ Budget crédits : " + $pct + "% consommés, reset dans < " + $h + "h — Fable 5 / Opus max effort déconseillés.")
  }'
  exit 0
fi

if [ "$pct" -lt "$USAGE_THRESHOLD_PCT" ] && [ "$hours_left" -lt "$BOOST_HOURS_LEFT" ]; then
  # Message violet (ANSI 35) : crédits bientôt réinitialisés et peu consommés.
  purple=$(printf '\033[35m')
  reset=$(printf '\033[0m')
  jq -n --arg msg "${purple}🟣 Crédits : seulement ${pct}% consommés et reset dans moins de ${BOOST_HOURS_LEFT}h — fonce, Fable 5 (max effort) utilisable sans compter.${reset}" \
    '{ systemMessage: $msg }'
fi
exit 0
