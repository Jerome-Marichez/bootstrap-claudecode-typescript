#!/bin/bash
# Hook PreToolUse — la pipeline fait foi avant toute publication ({{PROJECT_NAME}})
# Trois garde-fous :
#   1. CONTOURNEMENTS refusés sans condition : --no-verify, [skip ci], -o ci.skip,
#      gh pr merge --admin, gh workflow disable, gh run cancel, et toute tentative
#      de désarmer un garde-fou depuis une commande (REQUIRE_GREEN_CI=0…).
#   2. PUBLICATION conditionnée à l'état RÉEL de la pipeline pour le commit HEAD :
#      push vers main/master/dev/prod, push de tags, gh pr merge / glab mr merge,
#      npm|pnpm|yarn|bun publish, gh|glab release create.
#      Rouge → refus (on corrige le CODE, jamais le test ni le workflow).
#      En cours → refus (attendre la fin). Invérifiable → confirmation humaine.
#      Le push d'une branche feature/hotfix passe : c'est lui qui déclenche la CI.
#   3. INTÉGRITÉ des workflows : neutraliser un job (continue-on-error, allow_failure)
#      est refusé ; if:false / when:never demandent confirmation (usage légitime
#      possible dans des règles de déclenchement).
# REQUIRE_GREEN_CI=0 (décision humaine) désactive le seul point 2.
# Référence : docs/ci-cd.md.

set -u
input=$(cat)
tool=$(printf '%s' "$input" | jq -r '.tool_name // empty')

deny() { jq -n --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'; exit 0; }
ask()  { jq -n --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"ask",permissionDecisionReason:$r}}'; exit 0; }

# ------------------------------------------------ Intégrité des workflows CI
if [ "$tool" = "Write" ] || [ "$tool" = "Edit" ] || [ "$tool" = "MultiEdit" ]; then
  f=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
  case "$f" in
    *.github/workflows/*.yml|*.github/workflows/*.yaml|*.gitlab-ci.yml) ;;
    *) exit 0 ;;
  esac
  added=$(printf '%s' "$input" | jq -r '[.tool_input.content?, .tool_input.new_string?,
    (.tool_input.edits // [] | map(.new_string) | join("\n"))]
    | map(select(. != null and . != "")) | join("\n")')
  hit=$(printf '%s' "$added" | grep -oE 'continue-on-error:[[:space:]]*true|allow_failure:[[:space:]]*true' | head -1)
  [ -n "$hit" ] && deny "JOB NEUTRALISÉ — « $hit » dans $f. Un job qui ne peut plus faire échouer la pipeline ne protège plus rien : la CI mentirait sur l'état du code. Corrige le CODE qui fait échouer le job, jamais le job. Voir CLAUDE.md (intégrité des contrôles) et docs/ci-cd.md."
  printf '%s' "$added" | grep -qE '(make[[:space:]]+test|npx[[:space:]]+jest|npm[[:space:]]+(run[[:space:]]+)?test|cypress[[:space:]]+run)[^|&]*\|\|[[:space:]]*true' \
    && deny "ÉCHEC MASQUÉ — un « || true » sur une commande de test dans $f rend le job toujours vert. Corrige le CODE. Voir docs/ci-cd.md."
  hit=$(printf '%s' "$added" | grep -oE 'if:[[:space:]]*false|when:[[:space:]]*never' | head -1)
  [ -n "$hit" ] && ask "DÉCLENCHEMENT DÉSACTIVÉ — « $hit » dans $f. Légitime dans une règle d'exclusion, inacceptable pour éteindre un job de test : confirme que ce n'est pas un contournement."
  exit 0
fi

[ "$tool" = "Bash" ] || exit 0
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
[ -z "$cmd" ] && exit 0

# ------------------------------------------------------------ Contournements
printf '%s' "$cmd" | grep -qE '(^|[;&|][[:space:]]*)(REQUIRE_GREEN_CI|REQUIRE_TEST_FIRST)=0[[:space:]]' \
  && deny "GARDE-FOU DÉSARMÉ — désactiver un contrôle depuis une commande n'est pas une correction. Ces variables relèvent de {{OWNER}}, dans l'environnement de sa session. Corrige la cause."
printf '%s' "$cmd" | grep -qE '(^|[;&|][[:space:]]*)(TESTS_WRITABLE_BY_ASSISTANT|ALLOW_TEST_DOUBLES)=1[[:space:]]' \
  && deny "GARDE-FOU DÉSARMÉ — la délégation d'écriture des tests et l'autorisation des doublures appartiennent à {{OWNER}}, pas à une commande."
printf '%s' "$cmd" | grep -qE 'git[^|;&]*(commit|push)[^|;&]*(--no-verify|[[:space:]]-n([[:space:]]|$))' \
  && deny "CONTRÔLES LOCAUX CONTOURNÉS — --no-verify saute les hooks git. Corrige ce qu'ils signalent."
printf '%s' "$cmd" | grep -qiE '\[(skip ci|ci skip)\]|-o[[:space:]]+ci\.skip|--skip-ci' \
  && deny "PIPELINE SAUTÉE — un commit qui n'est pas vérifié par la CI n'a pas le droit d'être publié. Retire la directive de saut."
printf '%s' "$cmd" | grep -qE 'gh[[:space:]]+pr[[:space:]]+merge[^|;&]*--admin' \
  && deny "CHECKS OUTREPASSÉS — gh pr merge --admin force la fusion malgré les checks requis. Attends la pipeline verte."
printf '%s' "$cmd" | grep -qE 'gh[[:space:]]+workflow[[:space:]]+(disable|delete)|gh[[:space:]]+run[[:space:]]+cancel|glab[[:space:]]+ci[[:space:]]+(cancel|delete)' \
  && deny "PIPELINE DÉSACTIVÉE OU ANNULÉE — on ne fait pas taire la CI pour avancer. Corrige le CODE."

# -------------------------------------------------------- Commande publiante
publish=0
printf '%s' "$cmd" | grep -qE '(^|[;&|][[:space:]]*)(npm|pnpm|yarn|bun)[[:space:]]+publish' && publish=1
printf '%s' "$cmd" | grep -qE '(gh|glab)[[:space:]]+release[[:space:]]+create'              && publish=1
printf '%s' "$cmd" | grep -qE 'gh[[:space:]]+pr[[:space:]]+merge|glab[[:space:]]+mr[[:space:]]+merge' && publish=1
printf '%s' "$cmd" | grep -qE 'git[[:space:]]+push[^|;&]*(--tags|--follow-tags)'            && publish=1

PROTEGEES='main|master|dev|prod|production'
seg=$(printf '%s' "$cmd" | grep -oE 'git[[:space:]]+push[^|;&]*' | head -1)
if [ -n "$seg" ] && [ "$publish" = 0 ]; then
  if printf '%s' "$seg" | grep -qE "([[:space:]]|:)($PROTEGEES)([[:space:]]|$)"; then
    publish=1
  else
    # Ni branche ni refspec explicite : la destination est la branche courante.
    reste=$(printf '%s' "$seg" | sed -E 's/^git[[:space:]]+push//' | tr ' ' '\n' | grep -cvE '^(-.*)?$')
    if [ "$reste" -le 1 ]; then
      case "$(git rev-parse --abbrev-ref HEAD 2>/dev/null)" in
        main|master|dev|prod|production) publish=1 ;;
      esac
    fi
  fi
fi
[ "$publish" = 1 ] || exit 0
[ "${REQUIRE_GREEN_CI:-1}" = "1" ] || exit 0

# ------------------------------------------------------- État réel de la CI
branche=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || true
sha=$(git rev-parse HEAD 2>/dev/null) || true
[ -z "${sha:-}" ] && ask "ÉTAT DE LA CI INVÉRIFIABLE — impossible de lire le commit courant (hors dépôt git ?). Vérifie la pipeline à la main avant de publier."

forge=""
case "$(git remote get-url origin 2>/dev/null || true)" in
  *github.com*) forge=github ;;
  *gitlab*)     forge=gitlab ;;
esac
if [ -z "$forge" ]; then
  top=$(git rev-parse --show-toplevel 2>/dev/null || printf '%s' "${CLAUDE_PROJECT_DIR:-$PWD}")
  [ -d "$top/.github/workflows" ] && forge=github
  [ -f "$top/.gitlab-ci.yml" ]    && forge=gitlab
fi
ATTENTE="Attends la fin (gh pr checks --watch, gh run watch, glab ci status) puis relance."
ROUGE="Une pipeline rouge se corrige par le CODE : ne touche ni aux tests, ni aux seuils, ni aux workflows (CLAUDE.md, intégrité des contrôles)."

case "$forge" in
  github)
    command -v gh >/dev/null 2>&1 || ask "ÉTAT DE LA CI INVÉRIFIABLE — la CLI gh est absente. Vérifie la pipeline à la main avant de publier."
    runs=$(gh run list --branch "$branche" --limit 20 --json headSha,status,conclusion,workflowName 2>/dev/null) \
      || ask "ÉTAT DE LA CI INVÉRIFIABLE — gh n'a pas pu lister les runs (authentification, réseau ?). Vérifie la pipeline à la main."
    sel=$(printf '%s' "$runs" | jq -c --arg s "$sha" '[.[] | select(.headSha == $s)]' 2>/dev/null) || sel="[]"
    [ "$(printf '%s' "$sel" | jq 'length' 2>/dev/null || echo 0)" -eq 0 ] \
      && ask "AUCUN RUN CI POUR CE COMMIT ($sha) — la pipeline n'a pas encore vu ce code. Pousse la branche de travail, attends les checks, puis publie."
    rouges=$(printf '%s' "$sel" | jq -r '[.[] | select(.conclusion=="failure" or .conclusion=="timed_out" or .conclusion=="cancelled" or .conclusion=="startup_failure")] | map(.workflowName) | unique | join(", ")')
    [ -n "$rouges" ] && deny "PIPELINE ROUGE — $rouges en échec sur $sha. Publication refusée. $ROUGE"
    encours=$(printf '%s' "$sel" | jq -r '[.[] | select(.status != "completed")] | map(.workflowName) | unique | join(", ")')
    [ -n "$encours" ] && deny "PIPELINE EN COURS — $encours pas encore terminé sur $sha. $ATTENTE"
    ;;
  gitlab)
    command -v glab >/dev/null 2>&1 || ask "ÉTAT DE LA CI INVÉRIFIABLE — la CLI glab est absente. Vérifie la pipeline à la main avant de publier."
    pipes=$(glab api "projects/:id/pipelines?sha=$sha&per_page=5" 2>/dev/null) \
      || ask "ÉTAT DE LA CI INVÉRIFIABLE — glab n'a pas pu lire les pipelines. Vérifie à la main."
    etat=$(printf '%s' "$pipes" | jq -r '.[0].status // empty' 2>/dev/null)
    case "$etat" in
      success) ;;
      failed|canceled) deny "PIPELINE ROUGE — pipeline « $etat » sur $sha. Publication refusée. $ROUGE" ;;
      running|pending|created|preparing|waiting_for_resource) deny "PIPELINE EN COURS — pipeline « $etat » sur $sha. $ATTENTE" ;;
      *) ask "ÉTAT DE LA CI INDÉTERMINÉ — pipeline « ${etat:-aucune} » pour $sha. Vérifie à la main avant de publier." ;;
    esac
    ;;
  *) ask "FORGE INDÉTERMINÉE — impossible de savoir où tourne la CI de ce dépôt. Vérifie la pipeline à la main avant de publier." ;;
esac

exit 0
