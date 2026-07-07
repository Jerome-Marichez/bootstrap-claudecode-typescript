#!/bin/bash
# bootstrap.sh — génère la structure standard d'un projet TypeScript/React.
#
# Usage :
#   ./scripts/bootstrap.sh --name mon-projet --target ~/Desktop/mon-projet \
#       [--desc "Description"] [--owner "Jérôme"] \
#       [--layout front-back|single|package] [--framework nextjs|vite] \
#       [--ci github|gitlab|none] [--no-storybook] [--no-tests-setup] [--acceptance] \
#       [--postman] [--no-git]
#
#   --postman : pour --layout package, ajoute quand même les tests système API
#   (tests/systeme + collection Postman + job CI system) — utile si la librairie
#   expose une API. Sans effet sur front-back/single (Postman déjà inclus).
#
#   --no-tests-setup : ne pose pas l'outillage de tests (Jest + Stryker pour
#   unitaire/intégration, Cypress pour e2e, Postman pour le système API) —
#   la structure de dossiers reste créée.
#   --acceptance : ajoute les tests d'acceptation / non-fonctionnels
#   (tests/acceptance/ + uat/{disponibilite,securite,performance,robustesse}).
#
# Tokens substitués : {{PROJECT_NAME}} {{PROJECT_DESC}} {{OWNER}} {{FRAMEWORK}}
#                     {{NODE_VERSION}} {{BIOME_VERSION}}
#
# Blocs conditionnels dans les templates : une ligne contenant «>>only:tag1,tag2»
# ouvre un bloc conservé seulement si l'un des tags est actif (layout, framework,
# docker, storybook, e2e, system, acceptance, tests-setup, ci-github/gitlab) ;
# une ligne contenant «<<only» le ferme. Les lignes marqueurs sont retirées.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TPL="$ROOT/templates"

# Points de vérité uniques — propagés partout via les tokens.
NODE_VERSION="24"
BIOME_VERSION="^2.0.0"

NAME=""
DESC=""
OWNER=""   # défaut : compte connecté à la CLI GitHub (gh api user), sinon git config user.name
LAYOUT="front-back"
FRAMEWORK="nextjs"
CI="github"
TARGET=""
STORYBOOK=1
TESTS_SETUP=1
ACCEPTANCE=0
POSTMAN=0   # package uniquement : force les tests système API (Postman)
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
    --postman) POSTMAN=1; shift ;;
    --no-git) DO_GIT=0; shift ;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Option inconnue : $1" >&2; exit 1 ;;
  esac
done

[ -n "$NAME" ]   || { echo "--name est obligatoire" >&2; exit 1; }
case "$NAME" in *[!a-z0-9-]*) echo "--name doit être en kebab-case (a-z, 0-9, tirets)" >&2; exit 1 ;; esac
[ -n "$TARGET" ] || { echo "--target est obligatoire" >&2; exit 1; }
[ -n "$DESC" ]   || DESC="Projet $NAME"
if [ -z "$OWNER" ]; then
  # L'auteur est TOUJOURS le compte lié à la forge : celui connecté à la CLI gh.
  OWNER=$(gh api user --jq '.name // .login' 2>/dev/null || true)
  [ -z "$OWNER" ] && OWNER=$(git config user.name 2>/dev/null || true)
  [ -z "$OWNER" ] && { echo "--owner requis : aucun compte gh connecté (gh auth login) ni git config user.name" >&2; exit 1; }
fi
case "$LAYOUT" in front-back|single|package) ;; *) echo "--layout doit être front-back, single ou package" >&2; exit 1 ;; esac
case "$CI" in github|gitlab|none) ;; *) echo "--ci doit être github, gitlab ou none" >&2; exit 1 ;; esac

if [ "$LAYOUT" = "package" ]; then
  # Une librairie npm est agnostique : aucun framework front n'est imposé.
  FRAMEWORK="none"
  FRAMEWORK_LABEL="aucun (librairie TypeScript agnostique)"
else
  case "$FRAMEWORK" in nextjs|vite) ;; *) echo "--framework doit être nextjs ou vite" >&2; exit 1 ;; esac
  case "$FRAMEWORK" in
    nextjs) FRAMEWORK_LABEL="Next.js (App Router)" ;;
    vite)   FRAMEWORK_LABEL="Vite + React" ;;
  esac
fi

if [ -e "$TARGET" ] && [ -n "$(ls -A "$TARGET" 2>/dev/null)" ]; then
  echo "Refus : $TARGET existe et n'est pas vide." >&2
  exit 1
fi

mkdir -p "$TARGET"

# Tags actifs pour les blocs conditionnels (>>only:.../<<only) des templates.
# Attention : les blocs ne s'imbriquent pas — utiliser un tag composite (ex. postman).
KEYS="$LAYOUT $FRAMEWORK ci-$CI"
if [ "$LAYOUT" != "package" ]; then KEYS="$KEYS docker e2e"; fi
if [ "$LAYOUT" != "package" ] || [ "$POSTMAN" = 1 ]; then KEYS="$KEYS system"; fi
if [ "$LAYOUT" = "package" ] && [ "$POSTMAN" = 1 ]; then KEYS="$KEYS postman"; fi
if [ "$STORYBOOK" = 1 ]; then KEYS="$KEYS storybook"; fi
if [ "$ACCEPTANCE" = 1 ]; then KEYS="$KEYS acceptance"; fi
if [ "$TESTS_SETUP" = 1 ]; then KEYS="$KEYS tests-setup"; fi

# Fichier point de vérité de la version SemVer (workflow de release sur main).
if [ "$LAYOUT" = "front-back" ]; then VERSION_FILE="front/package.json"; else VERSION_FILE="package.json"; fi

# Copie un template en substituant les tokens puis en filtrant les blocs only.
render() { # render <src> <dst>
  mkdir -p "$(dirname "$2")"
  sed -e "s/{{PROJECT_NAME}}/$NAME/g" \
      -e "s/{{PROJECT_DESC}}/$(printf '%s' "$DESC" | sed 's/[&/\]/\\&/g')/g" \
      -e "s/{{OWNER}}/$(printf '%s' "$OWNER" | sed 's/[&/\]/\\&/g')/g" \
      -e "s/{{FRAMEWORK}}/$(printf '%s' "$FRAMEWORK_LABEL" | sed 's/[&/\]/\\&/g')/g" \
      -e "s/{{NODE_VERSION}}/$NODE_VERSION/g" \
      -e "s/{{BIOME_VERSION}}/$(printf '%s' "$BIOME_VERSION" | sed 's/[&/\]/\\&/g')/g" \
      -e "s|{{VERSION_FILE}}|$VERSION_FILE|g" \
      "$1" \
  | awk -v keys=" $KEYS " '
      index($0, ">>only:") {
        tags = $0
        sub(/.*>>only:/, "", tags); sub(/[^a-z0-9,-].*/, "", tags)
        keep = 0
        n = split(tags, a, ",")
        for (i = 1; i <= n; i++) if (index(keys, " " a[i] " ")) keep = 1
        skip = !keep; next
      }
      index($0, "<<only") { skip = 0; next }
      !skip
    ' > "$2"
}

echo "→ Documentation (README.md, CLAUDE.md, docs/)"
render "$TPL/README.md.tpl"  "$TARGET/README.md"
render "$TPL/CLAUDE.md.tpl"  "$TARGET/CLAUDE.md"
for f in "$TPL"/docs/*.md; do
  base="$(basename "$f")"
  if [ "$STORYBOOK" = 0 ] && [ "$base" = "storybook.md" ]; then continue; fi
  if [ "$LAYOUT" = "package" ] && [ "$base" = "docker.md" ]; then continue; fi
  render "$f" "$TARGET/docs/$base"
done

echo "→ Outillage (Makefile, biome.json, .gitignore, .nvmrc, scripts/)"
printf '%s\n' "$NODE_VERSION" > "$TARGET/.nvmrc"   # version Node unique (workflows via node-version-file)
render "$TPL/Makefile.tpl"   "$TARGET/Makefile"
render "$TPL/biome.json"     "$TARGET/biome.json"
render "$TPL/gitignore.tpl"  "$TARGET/.gitignore"
mkdir -p "$TARGET/scripts"
cp "$TPL/scripts/check-max-lines.sh" "$TARGET/scripts/check-max-lines.sh"
chmod +x "$TARGET/scripts/check-max-lines.sh"

echo "→ Claude Code (.claude : hooks, settings, agents, skills)"
mkdir -p "$TARGET/.claude/hooks" "$TARGET/.claude/skills" "$TARGET/.claude/agents"
for f in "$TPL"/hooks/*.sh; do
  render "$f" "$TARGET/.claude/hooks/$(basename "$f")"
  chmod +x "$TARGET/.claude/hooks/$(basename "$f")"
done
for f in "$TPL"/agents/*.md; do
  render "$f" "$TARGET/.claude/agents/$(basename "$f")"
done
render "$TPL/claude-settings.json" "$TARGET/.claude/settings.json"
for f in "$TPL"/skills/*.md; do
  skill="$(basename "$f" .md)"
  mkdir -p "$TARGET/.claude/skills/$skill"
  render "$f" "$TARGET/.claude/skills/$skill/SKILL.md"
done

echo "→ Convention interfaces/ + schemas/ (Zod) + services/ + utils/ + components/ + views/"
if [ "$LAYOUT" = "front-back" ]; then
  mkdir -p "$TARGET/front/src/interfaces" "$TARGET/front/src/schemas" "$TARGET/front/src/services" \
           "$TARGET/front/src/utils" "$TARGET/front/src/components" "$TARGET/front/src/views" \
           "$TARGET/front/src/hooks" \
           "$TARGET/back/src/interfaces" "$TARGET/back/src/schemas" "$TARGET/back/src/services" \
           "$TARGET/back/src/utils"
  render "$TPL/interfaces-types.ts" "$TARGET/front/src/interfaces/types.ts"
  render "$TPL/interfaces-types.ts" "$TARGET/back/src/interfaces/types.ts"
  for d in front/src/services front/src/utils front/src/components front/src/views front/src/hooks \
           back/src/services back/src/utils; do
    touch "$TARGET/$d/.gitkeep"
  done
  # shared/ : interfaces & schémas Zod partagés entre le front et le back.
  mkdir -p "$TARGET/shared/interfaces" "$TARGET/shared/schemas"
  render "$TPL/interfaces-types.ts"   "$TARGET/shared/interfaces/types.ts"
  render "$TPL/zod-schema-example.ts" "$TARGET/shared/schemas/exemple.schema.ts"
  render "$TPL/zod-schema-example.ts" "$TARGET/front/src/schemas/exemple.schema.ts"
  render "$TPL/zod-schema-example.ts" "$TARGET/back/src/schemas/exemple.schema.ts"
elif [ "$LAYOUT" = "package" ]; then
  mkdir -p "$TARGET/src/interfaces" "$TARGET/src/schemas" "$TARGET/src/services" "$TARGET/src/utils"
  render "$TPL/interfaces-types.ts"   "$TARGET/src/interfaces/types.ts"
  render "$TPL/zod-schema-example.ts" "$TARGET/src/schemas/exemple.schema.ts"
  touch "$TARGET/src/services/.gitkeep" "$TARGET/src/utils/.gitkeep"
else
  mkdir -p "$TARGET/src/interfaces" "$TARGET/src/schemas" "$TARGET/src/services" "$TARGET/src/utils" \
           "$TARGET/src/components" "$TARGET/src/views" "$TARGET/src/hooks"
  render "$TPL/interfaces-types.ts"   "$TARGET/src/interfaces/types.ts"
  render "$TPL/zod-schema-example.ts" "$TARGET/src/schemas/exemple.schema.ts"
  for d in src/services src/utils src/components src/views src/hooks; do
    touch "$TARGET/$d/.gitkeep"
  done
fi

echo "→ Code applicatif (package.json, tsconfig, framework : $FRAMEWORK_LABEL)"
# render_front <dossier> : package.json + tsconfig + fichiers du framework choisi.
render_front() { # $1 = racine de l'app front ("" pour la racine du projet)
  local dst="${1:+$1/}"
  render "$TPL/app/package-front-$FRAMEWORK.json.tpl" "$TARGET/${dst}package.json"
  render "$TPL/app/tsconfig-$FRAMEWORK.json.tpl"      "$TARGET/${dst}tsconfig.json"
  if [ "$FRAMEWORK" = "nextjs" ]; then
    render "$TPL/app/next.config.mjs.tpl" "$TARGET/${dst}next.config.mjs"
    render "$TPL/app/app-layout.tsx.tpl"  "$TARGET/${dst}src/app/layout.tsx"
    render "$TPL/app/app-page.tsx.tpl"    "$TARGET/${dst}src/app/page.tsx"
  else
    render "$TPL/app/vite.config.ts.tpl"  "$TARGET/${dst}vite.config.ts"
    render "$TPL/app/index.html.tpl"      "$TARGET/${dst}index.html"
    render "$TPL/app/main.tsx.tpl"        "$TARGET/${dst}src/main.tsx"
  fi
}
if [ "$LAYOUT" = "front-back" ]; then
  render_front "front"
  sed "s/\"name\": \"$NAME\"/\"name\": \"$NAME-front\"/" "$TARGET/front/package.json" > "$TARGET/front/package.json.tmp" \
    && mv "$TARGET/front/package.json.tmp" "$TARGET/front/package.json"
  render "$TPL/app/package-back.json.tpl" "$TARGET/back/package.json"
  sed "s/\"name\": \"$NAME\"/\"name\": \"$NAME-back\"/" "$TARGET/back/package.json" > "$TARGET/back/package.json.tmp" \
    && mv "$TARGET/back/package.json.tmp" "$TARGET/back/package.json"
  render "$TPL/app/tsconfig-node.json.tpl" "$TARGET/back/tsconfig.json"
  render "$TPL/app/back-index.ts.tpl"      "$TARGET/back/src/index.ts"
elif [ "$LAYOUT" = "package" ]; then
  render "$TPL/app/package-lib.json.tpl"   "$TARGET/package.json"
  render "$TPL/app/tsconfig-node.json.tpl" "$TARGET/tsconfig.json"
  render "$TPL/app/lib-index.ts.tpl"       "$TARGET/src/index.ts"
else
  render_front ""
fi

if [ "$LAYOUT" != "package" ]; then
  echo "→ Docker (Dockerfile, docker-compose.yml, .env.example)"
  render "$TPL/docker/docker-compose.yml.tpl" "$TARGET/docker-compose.yml"
  render "$TPL/docker/env.example.tpl"        "$TARGET/.env.example"
  if [ "$LAYOUT" = "front-back" ]; then
    render "$TPL/docker/Dockerfile.tpl" "$TARGET/front/Dockerfile"
    render "$TPL/docker/Dockerfile.tpl" "$TARGET/back/Dockerfile"
  else
    render "$TPL/docker/Dockerfile.tpl" "$TARGET/Dockerfile"
  fi
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
  if [ "$POSTMAN" = 1 ]; then
    mkdir -p "$TARGET/tests/systeme"
    touch "$TARGET/tests/systeme/.gitkeep"
  fi
else
  mkdir -p "$TARGET/src" "$TARGET/tests/unitaire" "$TARGET/tests/integration" \
           "$TARGET/tests/e2e" "$TARGET/tests/systeme"
  for d in tests/unitaire tests/integration tests/e2e tests/systeme; do
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
  # Test unitaire d'exemple : valide la chaîne Jest + ts-jest + tsconfig dès le bootstrap.
  if [ "$LAYOUT" = "front-back" ]; then
    render "$TPL/tests-setup/exemple-unit.ts.tpl" "$TARGET/front/tests/unitaire/exemple.spec.ts"
    render "$TPL/tests-setup/exemple-unit.ts.tpl" "$TARGET/back/tests/unitaire/exemple.test.ts"
  elif [ "$LAYOUT" = "package" ]; then
    render "$TPL/tests-setup/exemple-unit.ts.tpl" "$TARGET/tests/unitaire/exemple.test.ts"
  else
    render "$TPL/tests-setup/exemple-unit.ts.tpl" "$TARGET/tests/unitaire/exemple.spec.ts"
  fi
  # Postman — validation rejouable de l'API (package : seulement si --postman)
  if [ "$LAYOUT" = "front-back" ]; then
    render "$TPL/tests-setup/postman_collection.json" "$TARGET/back/tests/systeme/postman_collection.json"
  elif [ "$LAYOUT" = "single" ] || { [ "$LAYOUT" = "package" ] && [ "$POSTMAN" = 1 ]; }; then
    render "$TPL/tests-setup/postman_collection.json" "$TARGET/tests/systeme/postman_collection.json"
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
    mkdir -p "$TARGET/.github/workflows" "$TARGET/.github/ISSUE_TEMPLATE"
    render "$TPL/issue-template.md" "$TARGET/.github/ISSUE_TEMPLATE/issue.md"
    for f in "$TPL"/workflows/github/*.yml; do
      base="$(basename "$f")"
      # Package : pas de e2e ; system seulement si --postman (lib exposant une API).
      if [ "$LAYOUT" = "package" ]; then
        case "$base" in
          ci-main-e2e.yml) continue ;;
          ci-main-system.yml) [ "$POSTMAN" = 1 ] || continue ;;
        esac
      fi
      render "$f" "$TARGET/.github/workflows/$base"
    done
    ;;
  gitlab)
    mkdir -p "$TARGET/.gitlab/issue_templates"
    # GitLab affiche le frontmatter YAML comme du texte : on le retire.
    render "$TPL/issue-template.md" "$TARGET/.gitlab/issue_templates/issue.md"
    sed '1,/^---$/d' "$TARGET/.gitlab/issue_templates/issue.md" > "$TARGET/.gitlab/issue_templates/issue.md.tmp" \
      && mv "$TARGET/.gitlab/issue_templates/issue.md.tmp" "$TARGET/.gitlab/issue_templates/issue.md"
    render "$TPL/workflows/gitlab/gitlab-ci.yml" "$TARGET/.gitlab-ci.yml"
    if [ "$LAYOUT" = "package" ]; then
      # Même filtrage que côté GitHub : pas de e2e ; system conservé si --postman.
      awk -v keep_system="$POSTMAN" \
        '/^[a-zA-Z0-9_-]+:/{skip=($0=="e2e:"||($0=="system:"&&keep_system!=1))} !skip' \
        "$TARGET/.gitlab-ci.yml" > "$TARGET/.gitlab-ci.yml.tmp" && mv "$TARGET/.gitlab-ci.yml.tmp" "$TARGET/.gitlab-ci.yml"
    fi
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
echo "   2. make install puis make lint / make test — la chaîne (Zod, Jest, Biome) est déjà câblée."
if [ "$STORYBOOK" = 1 ]; then
  echo "   3. Initialiser Storybook : npx storybook@latest init (voir docs/storybook.md)."
  echo "   4. Créer le dépôt distant (gh repo create), pousser main + dev, protéger main."
else
  echo "   3. Créer le dépôt distant (gh repo create), pousser main + dev, protéger main."
fi
