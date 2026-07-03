#!/bin/bash
# bootstrap.sh — génère la structure standard d'un projet TypeScript/React.
#
# Usage :
#   ./scripts/bootstrap.sh --name mon-projet --target ~/Desktop/mon-projet \
#       [--desc "Description"] [--owner "Jérôme"] \
#       [--layout front-back|single|package] [--framework nextjs|vite] \
#       [--ci github|gitlab|none] [--no-storybook] [--no-tests-setup] [--no-git]
#
#   --no-tests-setup : ne pose pas l'outillage de tests (Jest + Stryker pour
#   unitaire/intégration, Cypress pour e2e, Postman pour le système API) —
#   la structure de dossiers reste créée.
#   --acceptance : ajoute les tests d'acceptation / non-fonctionnels
#   (tests/acceptance/ + uat/{disponibilite,securite,performance,robustesse}).
#
# Tokens substitués : {{PROJECT_NAME}} {{PROJECT_DESC}} {{OWNER}} {{FRAMEWORK}}

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TPL="$ROOT/templates"

NAME=""
DESC=""
OWNER="Marichez Jérôme"
LAYOUT="front-back"
FRAMEWORK="nextjs"
CI="github"
TARGET=""
STORYBOOK=1
TESTS_SETUP=1
ACCEPTANCE=0
DO_GIT=1

while [ $# -gt 0 ]; do
  case "$1" in
    --name)   NAME="$2"; shift 2 ;;
    --desc)   DESC="$2"; shift 2 ;;
    --owner)  OWNER="$2"; shift 2 ;;
    --layout) LAYOUT="$2"; shift 2 ;;
    --framework) FRAMEWORK="$2"; shift 2 ;;
    --ci)     CI="$2"; shift 2 ;;
    --target) TARGET="$2"; shift 2 ;;
    --no-storybook) STORYBOOK=0; shift ;;
    --no-tests-setup) TESTS_SETUP=0; shift ;;
    --acceptance) ACCEPTANCE=1; shift ;;
    --no-git) DO_GIT=0; shift ;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Option inconnue : $1" >&2; exit 1 ;;
  esac
done

[ -n "$NAME" ]   || { echo "--name est obligatoire" >&2; exit 1; }
[ -n "$TARGET" ] || { echo "--target est obligatoire" >&2; exit 1; }
[ -n "$DESC" ]   || DESC="Projet $NAME"
case "$LAYOUT" in front-back|single|package) ;; *) echo "--layout doit être front-back, single ou package" >&2; exit 1 ;; esac
case "$FRAMEWORK" in nextjs|vite) ;; *) echo "--framework doit être nextjs ou vite" >&2; exit 1 ;; esac
case "$CI" in github|gitlab|none) ;; *) echo "--ci doit être github, gitlab ou none" >&2; exit 1 ;; esac

case "$FRAMEWORK" in
  nextjs) FRAMEWORK_LABEL="Next.js (App Router)" ;;
  vite)   FRAMEWORK_LABEL="Vite + React" ;;
esac

if [ -e "$TARGET" ] && [ -n "$(ls -A "$TARGET" 2>/dev/null)" ]; then
  echo "Refus : $TARGET existe et n'est pas vide." >&2
  exit 1
fi

mkdir -p "$TARGET"

# Copie un template en substituant les tokens.
render() { # render <src> <dst>
  mkdir -p "$(dirname "$2")"
  sed -e "s/{{PROJECT_NAME}}/$NAME/g" \
      -e "s/{{PROJECT_DESC}}/$(printf '%s' "$DESC" | sed 's/[&/\]/\\&/g')/g" \
      -e "s/{{OWNER}}/$(printf '%s' "$OWNER" | sed 's/[&/\]/\\&/g')/g" \
      -e "s/{{FRAMEWORK}}/$(printf '%s' "$FRAMEWORK_LABEL" | sed 's/[&/\]/\\&/g')/g" \
      "$1" > "$2"
}

echo "→ Documentation (README.md, CLAUDE.md, docs/)"
render "$TPL/README.md.tpl"  "$TARGET/README.md"
render "$TPL/CLAUDE.md.tpl"  "$TARGET/CLAUDE.md"
for f in "$TPL"/docs/*.md; do
  base="$(basename "$f")"
  if [ "$STORYBOOK" = 0 ] && [ "$base" = "storybook.md" ]; then continue; fi
  render "$f" "$TARGET/docs/$base"
done
if [ "$STORYBOOK" = 0 ]; then
  # Retire les références à Storybook des index de doc (portable macOS/Linux).
  for doc in "$TARGET/README.md" "$TARGET/CLAUDE.md"; do
    grep -iv 'storybook' "$doc" > "$doc.tmp" && mv "$doc.tmp" "$doc"
  done
fi

echo "→ Outillage (Makefile, biome.json, .gitignore, scripts/)"
render "$TPL/Makefile.tpl"   "$TARGET/Makefile"
render "$TPL/biome.json"     "$TARGET/biome.json"
render "$TPL/gitignore.tpl"  "$TARGET/.gitignore"
mkdir -p "$TARGET/scripts"
cp "$TPL/scripts/check-max-lines.sh" "$TARGET/scripts/check-max-lines.sh"
chmod +x "$TARGET/scripts/check-max-lines.sh"

echo "→ Claude Code (.claude : hooks, settings, skills)"
mkdir -p "$TARGET/.claude/hooks" "$TARGET/.claude/skills"
for f in "$TPL"/hooks/*.sh; do
  render "$f" "$TARGET/.claude/hooks/$(basename "$f")"
  chmod +x "$TARGET/.claude/hooks/$(basename "$f")"
done
render "$TPL/claude-settings.json" "$TARGET/.claude/settings.json"
for f in "$TPL"/skills/*.md; do
  skill="$(basename "$f" .md)"
  mkdir -p "$TARGET/.claude/skills/$skill"
  render "$f" "$TARGET/.claude/skills/$skill/SKILL.md"
done

echo "→ Convention interfaces/ + types.ts + services/ + utils/"
if [ "$LAYOUT" = "front-back" ]; then
  mkdir -p "$TARGET/front/src/interfaces" "$TARGET/front/src/services" "$TARGET/front/src/utils" \
           "$TARGET/back/src/interfaces"  "$TARGET/back/src/services"  "$TARGET/back/src/utils"
  render "$TPL/interfaces-types.ts" "$TARGET/front/src/interfaces/types.ts"
  render "$TPL/interfaces-types.ts" "$TARGET/back/src/interfaces/types.ts"
  touch "$TARGET/front/src/services/.gitkeep" "$TARGET/back/src/services/.gitkeep" \
        "$TARGET/front/src/utils/.gitkeep"    "$TARGET/back/src/utils/.gitkeep"
else
  mkdir -p "$TARGET/src/interfaces" "$TARGET/src/services" "$TARGET/src/utils"
  render "$TPL/interfaces-types.ts" "$TARGET/src/interfaces/types.ts"
  touch "$TARGET/src/services/.gitkeep" "$TARGET/src/utils/.gitkeep"
fi

echo "→ Structure de tests (layout : $LAYOUT)"
if [ "$LAYOUT" = "front-back" ]; then
  mkdir -p "$TARGET/front/tests/unitaire" "$TARGET/front/tests/integration" "$TARGET/front/tests/e2e" \
           "$TARGET/back/tests/unitaire"  "$TARGET/back/tests/integration"  "$TARGET/back/tests/systeme"
  for d in front/tests/unitaire front/tests/integration front/tests/e2e \
           back/tests/unitaire back/tests/integration back/tests/systeme; do
    touch "$TARGET/$d/.gitkeep"
  done
elif [ "$LAYOUT" = "package" ]; then
  mkdir -p "$TARGET/src" "$TARGET/tests/unitaire" "$TARGET/tests/integration"
  for d in tests/unitaire tests/integration; do
    touch "$TARGET/$d/.gitkeep"
  done
else
  mkdir -p "$TARGET/src" "$TARGET/tests/unitaire" "$TARGET/tests/integration" "$TARGET/tests/e2e"
  for d in tests/unitaire tests/integration tests/e2e; do
    touch "$TARGET/$d/.gitkeep"
  done
fi

if [ "$TESTS_SETUP" = 1 ]; then
  echo "→ Outillage de tests (Jest + Stryker, Cypress)"
  if [ "$LAYOUT" = "front-back" ]; then
    render "$TPL/tests-setup/jest.config.mjs"     "$TARGET/front/jest.config.mjs"
    render "$TPL/tests-setup/stryker.config.json" "$TARGET/front/stryker.config.json"
    render "$TPL/tests-setup/cypress.config.ts"   "$TARGET/front/cypress.config.ts"
    render "$TPL/tests-setup/jest.config.mjs"     "$TARGET/back/jest.config.mjs"
    render "$TPL/tests-setup/stryker.config.json" "$TARGET/back/stryker.config.json"
  elif [ "$LAYOUT" = "package" ]; then
    render "$TPL/tests-setup/jest.config.mjs"     "$TARGET/jest.config.mjs"
    render "$TPL/tests-setup/stryker.config.json" "$TARGET/stryker.config.json"
  else
    render "$TPL/tests-setup/jest.config.mjs"     "$TARGET/jest.config.mjs"
    render "$TPL/tests-setup/stryker.config.json" "$TARGET/stryker.config.json"
    render "$TPL/tests-setup/cypress.config.ts"   "$TARGET/cypress.config.ts"
  fi
  # Postman — validation rejouable de l'API (pas pertinent pour un package)
  if [ "$LAYOUT" = "front-back" ]; then
    render "$TPL/tests-setup/postman_collection.json" "$TARGET/back/tests/systeme/postman_collection.json"
  elif [ "$LAYOUT" = "single" ]; then
    render "$TPL/tests-setup/postman_collection.json" "$TARGET/tests/postman_collection.json"
  fi
fi

if [ "$ACCEPTANCE" = 1 ]; then
  echo "→ Tests d'acceptation / non-fonctionnels (UAT)"
  for d in tests/acceptance/uat/disponibilite tests/acceptance/uat/securite \
           tests/acceptance/uat/performance tests/acceptance/uat/robustesse; do
    mkdir -p "$TARGET/$d"
    touch "$TARGET/$d/.gitkeep"
  done
fi

echo "→ CI ($CI)"
case "$CI" in
  github)
    mkdir -p "$TARGET/.github/workflows"
    for f in "$TPL"/workflows/github/*.yml; do
      base="$(basename "$f")"
      # Les jobs back/e2e/system n'ont pas de sens selon le layout.
      if [ "$LAYOUT" = "single" ] && [ "$base" = "ci-main-system.yml" ]; then continue; fi
      if [ "$LAYOUT" = "package" ]; then
        case "$base" in ci-main-system.yml|ci-main-e2e.yml) continue ;; esac
      fi
      render "$f" "$TARGET/.github/workflows/$base"
    done
    ;;
  gitlab)
    render "$TPL/workflows/gitlab/gitlab-ci.yml" "$TARGET/.gitlab-ci.yml"
    ;;
  none) ;;
esac

if [ "$DO_GIT" = 1 ] && [ ! -d "$TARGET/.git" ]; then
  echo "→ git init (branches main + dev)"
  git -C "$TARGET" init -q -b main
  git -C "$TARGET" add -A
  git -C "$TARGET" commit -qm "chore: bootstrap du projet $NAME (structure standard)"
  git -C "$TARGET" branch dev
fi

echo ""
echo "✔ Projet '$NAME' généré dans $TARGET (framework : $FRAMEWORK_LABEL)"
echo "  Prochaines étapes :"
echo "   1. Compléter la présentation dans README.md / CLAUDE.md et les docs/ (sections TODO)."
if [ "$LAYOUT" = "package" ]; then
  echo "   2. Initialiser le package : npm init + tsconfig (build tsup/tsc), exports dans package.json."
elif [ "$FRAMEWORK" = "nextjs" ]; then
  echo "   2. Initialiser le code : npx create-next-app@latest (TypeScript) + back selon le layout."
else
  echo "   2. Initialiser le code : npm create vite@latest (react-ts) + back selon le layout."
fi
echo "   3. Adapter le Makefile aux commandes réelles du projet."
if [ "$STORYBOOK" = 1 ]; then
  echo "   4. Initialiser Storybook : npx storybook@latest init (voir docs/storybook.md)."
fi
