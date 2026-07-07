#!/bin/bash
# Hook PreToolUse — garde-fou dépendances ({{PROJECT_NAME}})
# Avant d'autoriser l'ajout d'une dépendance (npm/yarn/pnpm/bun install ou édition
# d'un package.json), vérifie pour chaque NOUVEAU paquet qu'il remplit AU MOINS UNE
# des deux conditions :
#   A. au moins MIN_CONTRIBUTORS (3) contributeurs différents
#      ET une publication récente (moins de MAX_AGE_MONTHS (6) mois) ;
#   B. maintenu par un gros éditeur de confiance (Meta/Facebook, Google, Amazon/AWS,
#      Microsoft, Vercel…) AVEC au moins BIG_ORG_MIN_STARS (1000) étoiles GitHub.
# Dans TOUS les cas (A comme B), la dernière version publiée doit respecter la
# convention SemVer — refus si non conforme OU si l'information est indisponible.
# Sortie : rien = laisser passer ; sinon "deny" (critère non respecté) ou
# "ask" (vérification impossible : réseau, rate limit… — ou publication ancienne :
# un paquet mature en maintenance n'est pas refusé d'office, l'humain tranche).

set -u
MIN_CONTRIBUTORS="${MIN_CONTRIBUTORS:-3}"
MAX_AGE_MONTHS="${MAX_AGE_MONTHS:-6}"
BIG_ORG_MIN_STARS="${BIG_ORG_MIN_STARS:-1000}"
# Orgs/mainteneurs de confiance — extensible sans écraser la liste via
# TRUSTED_ORGS_EXTRA="org1 org2" dans l'environnement.
TRUSTED_ORGS="${TRUSTED_ORGS:-facebook meta-llama google googleapis angular aws awslabs amzn amazon-archives microsoft azure vercel vitejs vuejs sveltejs nodejs openjs-foundation colinhacks jestjs testing-library cypress-io stryker-mutator biomejs egoist sindresorhus}"
TRUSTED_ORGS="$TRUSTED_ORGS ${TRUSTED_ORGS_EXTRA:-}"

input=$(cat)
tool=$(printf '%s' "$input" | jq -r '.tool_name // empty')

deny() { jq -n --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'; exit 0; }
ask()  { jq -n --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"ask",permissionDecisionReason:$r}}'; exit 0; }

pkgs=""
case "$tool" in
  Bash)
    cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
    printf '%s' "$cmd" | grep -qE '(npm (install|i|add)|yarn add|pnpm (add|install|i)|bun add)( |$)' || exit 0
    pkgs=$(printf '%s' "$cmd" \
      | grep -oE '(npm (install|i|add)|yarn add|pnpm (add|install|i)|bun add)[^&|;]*' \
      | sed -E 's/^[a-z]+ (install|i|add)//' \
      | tr ' ' '\n' \
      | grep -vE '^(-|$)' \
      | sed -E 's/(.)@[^@]*$/\1/' \
      | sort -u)
    ;;
  Edit|Write)
    file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
    case "$file" in */package.json|package.json) ;; *) exit 0 ;; esac
    if [ "$tool" = "Write" ]; then
      newdeps=$(printf '%s' "$input" | jq -r '.tool_input.content // empty' \
        | jq -r '(.dependencies // {}) + (.devDependencies // {}) | keys[]' 2>/dev/null)
    else
      newdeps=$(printf '%s' "$input" | jq -r '.tool_input.new_string // empty' \
        | grep -oE '"@?[A-Za-z0-9._/-]+"[[:space:]]*:[[:space:]]*"[~^>=<]?[0-9]' \
        | sed -E 's/^"([^"]+)".*/\1/' \
        | grep -vE '^(version|node|npm|pnpm|yarn|bun|packageManager)$')
    fi
    olddeps=""
    [ -f "$file" ] && olddeps=$(jq -r '(.dependencies // {}) + (.devDependencies // {}) | keys[]' "$file" 2>/dev/null)
    pkgs=$(comm -13 <(printf '%s\n' "$olddeps" | sort -u) <(printf '%s\n' "$newdeps" | sort -u) | grep -v '^$')
    ;;
  *) exit 0 ;;
esac

[ -z "$pkgs" ] && exit 0

TOKEN=$(gh auth token 2>/dev/null || printf '%s' "${GITHUB_TOKEN:-}")
gh_get() { # $1 = url — corps puis code HTTP en dernière ligne
  if [ -n "$TOKEN" ]; then
    curl -sSL --max-time 10 -H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.github+json" -w '\n%{http_code}' "$1" 2>/dev/null
  else
    curl -sSL --max-time 10 -H "Accept: application/vnd.github+json" -w '\n%{http_code}' "$1" 2>/dev/null
  fi
}

# Date limite (il y a MAX_AGE_MONTHS mois) au format ISO — comparaison lexicographique.
cutoff=$(date -u -v-"${MAX_AGE_MONTHS}"m +%Y-%m-%dT%H:%M:%S 2>/dev/null \
      || date -u -d "-${MAX_AGE_MONTHS} months" +%Y-%m-%dT%H:%M:%S 2>/dev/null)
[ -z "$cutoff" ] && ask "Impossible de calculer la date limite de fraîcheur — confirmation manuelle requise."

for pkg in $pkgs; do
  enc=$(printf '%s' "$pkg" | sed 's|/|%2F|g')

  # Métadonnées npm complètes (dist-tags + dates de publication + repository)
  resp=$(curl -sSL --max-time 10 -w '\n%{http_code}' "https://registry.npmjs.org/$enc" 2>/dev/null)
  code=$(printf '%s' "$resp" | tail -n1)
  body=$(printf '%s' "$resp" | sed '$d')
  case "$code" in
    200) ;;
    404) deny "Dépendance $pkg : introuvable sur le registre npm — installation refusée." ;;
    *)   ask  "Dépendance $pkg : registre npm injoignable (HTTP $code) — confirmation manuelle requise." ;;
  esac

  latest=$(printf '%s' "$body" | jq -r '."dist-tags".latest // empty')

  # SemVer obligatoire — refus aussi quand l'information est indisponible.
  SEMVER_RE='^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$'
  if [ -z "$latest" ]; then
    deny "Dépendance $pkg : version publiée introuvable — impossible de vérifier la convention SemVer, installation refusée."
  fi
  if ! printf '%s' "$latest" | grep -qE "$SEMVER_RE"; then
    deny "Dépendance $pkg : la version publiée '$latest' ne respecte pas la convention SemVer — installation refusée."
  fi

  pubdate=$(printf '%s' "$body" | jq -r --arg v "$latest" '.time[$v] // .time.modified // empty')
  repo=$(printf '%s' "$body" | jq -r '.repository.url // .repository // empty' \
    | grep -oE 'github\.com[/:][A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+' | head -1 \
    | sed -E 's|github\.com[/:]||; s|\.git$||')
  owner=$(printf '%s' "$repo" | cut -d/ -f1 | tr '[:upper:]' '[:lower:]')

  recent=0
  [ -n "$pubdate" ] && [ "$(printf '%s' "$pubdate" | cut -c1-19)" '>' "$cutoff" ] && recent=1

  # Condition B — gros éditeur de confiance + beaucoup d'étoiles
  if [ -n "$owner" ]; then
    for org in $TRUSTED_ORGS; do
      if [ "$owner" = "$org" ]; then
        resp=$(gh_get "https://api.github.com/repos/$repo")
        gcode=$(printf '%s' "$resp" | tail -n1)
        gbody=$(printf '%s' "$resp" | sed '$d')
        if [ "$gcode" = "200" ]; then
          stars=$(printf '%s' "$gbody" | jq -r '.stargazers_count // 0')
          [ "$stars" -ge "$BIG_ORG_MIN_STARS" ] 2>/dev/null && continue 2
        fi
      fi
    done
  fi

  # Condition A — fraîcheur + contributeurs. Une publication ancienne peut être un
  # simple paquet mature en maintenance : confirmation manuelle plutôt que refus sec.
  if [ "$recent" != 1 ]; then
    ask "Dépendance $pkg : dernière publication le ${pubdate:-inconnue} (> $MAX_AGE_MONTHS mois) et pas un éditeur de confiance. Paquet mature en maintenance ou paquet abandonné ? Confirmation manuelle requise."
  fi
  [ -z "$repo" ] && deny "Dépendance $pkg : aucun dépôt GitHub déclaré sur npm — impossible de vérifier les contributeurs, installation refusée."

  resp=$(gh_get "https://api.github.com/repos/$repo/contributors?per_page=$MIN_CONTRIBUTORS")
  code=$(printf '%s' "$resp" | tail -n1)
  body=$(printf '%s' "$resp" | sed '$d')
  [ "$code" != "200" ] && ask "Dépendance $pkg : impossible de compter les contributeurs de $repo (HTTP $code) — confirmation manuelle requise."
  contribs=$(printf '%s' "$body" | jq -r 'length' 2>/dev/null || echo 0)
  if [ "$contribs" -lt "$MIN_CONTRIBUTORS" ] 2>/dev/null; then
    deny "Dépendance $pkg ($repo) : $contribs contributeur(s) (< $MIN_CONTRIBUTORS) — installation refusée."
  fi
done

exit 0
