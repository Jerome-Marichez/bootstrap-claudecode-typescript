#!/bin/bash
# smoke-test.sh — tests du générateur.
# Génère les layouts dans un dossier temporaire et vérifie les invariants :
# structure, substitution des tokens, blocs conditionnels, filtrage CI par layout,
# Makefile réellement câblé (aucune cible TODO), Docker, framework effectif,
# comportement des hooks (dont le routage de modèles) et git init.
# Exécuté en local et par la CI du repo (.github/workflows/ci.yml). Nécessite : jq, make.
# Si le registre npm est joignable, valide aussi la résolution des package.json.

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
fail=0

check() { # check "description" <commande...>
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "  ✓ $desc"
  else
    echo "  ✗ $desc"; fail=1
  fi
}

echo "→ Syntaxe des scripts"
for f in "$ROOT"/scripts/*.sh "$ROOT"/templates/hooks/*.sh "$ROOT"/templates/scripts/*.sh; do
  check "bash -n $(basename "$f")" bash -n "$f"
done

echo "→ Cohérence des points de vérité"
# BIOME_VERSION (plage installée) et BIOME_SCHEMA_VERSION (schéma figé de
# biome.json) sont deux constantes distinctes : leurs majeurs doivent concorder.
biome_majors_match() {
  local bs range schema
  bs="$ROOT/scripts/bootstrap.sh"
  range=$(awk -F'"' '/^BIOME_VERSION=/{gsub(/[^0-9.]/,"",$2); split($2,a,"."); print a[1]}' "$bs")
  schema=$(awk -F'"' '/^BIOME_SCHEMA_VERSION=/{split($2,a,"."); print a[1]}' "$bs")
  [ -n "$range" ] && [ "$range" = "$schema" ]
}
check "majeurs Biome cohérents (version/schéma)" biome_majors_match
# Deux fichiers distincts portent le seuil des 300 lignes (CI et hook) : ils sont
# copiés séparément dans les projets générés et doivent rester alignés.
max_lines_aligned() {
  local n
  n=$(grep -hE '^MAX=' "$ROOT/templates/scripts/check-max-lines.sh" \
        "$ROOT/templates/hooks/check-file-length.sh" | sort -u | wc -l)
  [ "$n" -eq 1 ]
}
check "seuil 300 aligné (check-max-lines / check-file-length)" max_lines_aligned

echo "→ Génération des layouts"
"$ROOT/scripts/bootstrap.sh" --name proj-fb     --owner Testeur --target "$TMP/fb"     --layout front-back --acceptance --no-git >/dev/null
GIT_AUTHOR_NAME=Testeur GIT_AUTHOR_EMAIL=t@local GIT_COMMITTER_NAME=Testeur GIT_COMMITTER_EMAIL=t@local \
  "$ROOT/scripts/bootstrap.sh" --name proj-single --owner Testeur --target "$TMP/single" --layout single --framework vite >/dev/null
"$ROOT/scripts/bootstrap.sh" --name proj-pkg    --owner Testeur --target "$TMP/pkg"    --layout package --ci gitlab --no-storybook --no-git >/dev/null
"$ROOT/scripts/bootstrap.sh" --name proj-api    --owner Testeur --target "$TMP/api"    --layout package --postman --no-git >/dev/null
bad_name_refused() { ! "$ROOT/scripts/bootstrap.sh" --name 'Bad Name' --owner Testeur --target "$TMP/bad" >/dev/null 2>&1; }
check "nom non kebab-case refusé" bad_name_refused
# Un retour à la ligne dans --desc cassait le s/// de sed.
multiline_desc_ok() {
  "$ROOT/scripts/bootstrap.sh" --name proj-nl --owner Testeur --target "$TMP/nl" \
    --layout package --no-git --desc "$(printf 'ligne1\nligne2')" >/dev/null 2>&1 \
    && grep -q 'ligne1 ligne2' "$TMP/nl/README.md"
}
check "--desc multi-ligne accepté" multiline_desc_ok
# Sans trap, un échec à mi-parcours laissait une cible à moitié construite que la
# garde « existe et non vide » refusait ensuite de re-remplir. On sabote sed (que
# render utilise) pour faire échouer la génération APRÈS la création de la cible.
partial_target_cleaned() {
  local t="$TMP/boom" fakebin="$TMP/fakebin"
  mkdir -p "$fakebin"
  printf '#!/bin/sh\nexit 1\n' > "$fakebin/sed"
  chmod +x "$fakebin/sed"
  ! PATH="$fakebin:$PATH" "$ROOT/scripts/bootstrap.sh" --name proj-boom --owner Testeur \
      --target "$t" --layout package --no-git >/dev/null 2>&1
  rm -rf "$fakebin"
  [ ! -e "$t" ]
}
check "cible nettoyée après échec" partial_target_cleaned

echo "→ Layout front-back (Next.js)"
check "shared/schemas généré"            test -f "$TMP/fb/shared/schemas/exemple.schema.ts"
check "6 workflows GitHub"               test "$(ls "$TMP/fb/.github/workflows" | wc -l)" -eq 6
check "release-main sur front/package"   grep -q 'front/package.json' "$TMP/fb/.github/workflows/release-main.yml"
check "template d'issue GitHub (+ frontmatter)" grep -q '^name:' "$TMP/fb/.github/ISSUE_TEMPLATE/issue.md"
check "collection Postman côté back"     test -f "$TMP/fb/back/tests/systeme/postman_collection.json"
check "dossiers UAT (--acceptance)"      test -d "$TMP/fb/tests/acceptance/uat/robustesse"
check ".nvmrc présent"                   test -f "$TMP/fb/.nvmrc"
check "owner substitué"                  grep -q 'Testeur' "$TMP/fb/README.md"
check "hooks exécutables"                test -x "$TMP/fb/.claude/hooks/check-test-location.sh"
check "aucun token non substitué"        bash -c "! grep -rE '\{\{(PROJECT_NAME|PROJECT_DESC|OWNER|FRAMEWORK|NODE_VERSION|BIOME_VERSION|BIOME_SCHEMA_VERSION)\}\}' '$TMP/fb'"
check "aucun marqueur only résiduel"     bash -c "! grep -rE '>>only:|<<only' '$TMP/fb' '$TMP/single' '$TMP/pkg' '$TMP/api'"
check "check-max-lines passe"            "$TMP/fb/scripts/check-max-lines.sh" "$TMP/fb"
check "package.json front (next)"        grep -q '"next"' "$TMP/fb/front/package.json"
check "nom suffixé front/back"           bash -c "grep -q '\"proj-fb-front\"' '$TMP/fb/front/package.json' && grep -q '\"proj-fb-back\"' '$TMP/fb/back/package.json'"
check "app Next.js (layout+page)"        bash -c "test -f '$TMP/fb/front/src/app/layout.tsx' && test -f '$TMP/fb/front/next.config.mjs'"
check "serveur back généré"              test -f "$TMP/fb/back/src/index.ts"
check "Dockerfiles front+back + compose" bash -c "test -f '$TMP/fb/front/Dockerfile' && test -f '$TMP/fb/back/Dockerfile' && test -f '$TMP/fb/docker-compose.yml' && test -f '$TMP/fb/.env.example'"
check "compose : services front et back" bash -c "grep -q '  front:' '$TMP/fb/docker-compose.yml' && grep -q '  back:' '$TMP/fb/docker-compose.yml'"
check "Makefile sans cible TODO"         bash -c "! grep -qi 'TODO' '$TMP/fb/Makefile'"
check "tableau de tests front/back (CLAUDE.md)" grep -q 'front/tests/unitaire' "$TMP/fb/CLAUDE.md"
check "test d'exemple front + back"      bash -c "test -f '$TMP/fb/front/tests/unitaire/exemple.spec.ts' && test -f '$TMP/fb/back/tests/unitaire/exemple.test.ts'"

echo "→ Layout single (Vite, git)"
check "tests/systeme + Postman"          test -f "$TMP/single/tests/systeme/postman_collection.json"
check "ci-main-system présent"           test -f "$TMP/single/.github/workflows/ci-main-system.yml"
check "release-main présent"             grep -q 'jq -r .version package.json' "$TMP/single/.github/workflows/release-main.yml"
check "config Vite + index.html"         bash -c "test -f '$TMP/single/vite.config.ts' && test -f '$TMP/single/index.html' && test -f '$TMP/single/src/main.tsx'"
check "package.json avec vite"           grep -q '"vite"' "$TMP/single/package.json"
check "pas de fichiers Next.js"          bash -c "! test -e '$TMP/single/next.config.mjs' && ! test -d '$TMP/single/src/app'"
check "Dockerfile + compose (service app)" bash -c "test -f '$TMP/single/Dockerfile' && grep -q '  app:' '$TMP/single/docker-compose.yml'"
check "tableau de tests racine (CLAUDE.md)" bash -c "grep -q 'tests/unitaire' '$TMP/single/CLAUDE.md' && ! grep -q 'front/tests/unitaire' '$TMP/single/CLAUDE.md'"
check "git init : branches main + dev"   bash -c "git -C '$TMP/single' branch --list | grep -q main && git -C '$TMP/single' branch --list | grep -q dev"
check "commit de bootstrap présent"      bash -c "git -C '$TMP/single' log --oneline | grep -q bootstrap"

echo "→ Layout package (GitLab, --no-storybook)"
check "template d'issue GitLab"          test -f "$TMP/pkg/.gitlab/issue_templates/issue.md"
check "issue GitLab sans frontmatter"    bash -c "! grep -q '^name:' '$TMP/pkg/.gitlab/issue_templates/issue.md'"
check ".gitlab-ci.yml sans job e2e"      bash -c "! grep -q '^e2e:' '$TMP/pkg/.gitlab-ci.yml'"
check ".gitlab-ci.yml sans job system"   bash -c "! grep -q '^system:' '$TMP/pkg/.gitlab-ci.yml'"
check ".gitlab-ci.yml avec job release"  grep -q '^release:' "$TMP/pkg/.gitlab-ci.yml"
check "Makefile sans cible storybook"    bash -c "! grep -q '^storybook' '$TMP/pkg/Makefile'"
check "Makefile valide après filtrage"   make -C "$TMP/pkg" -n help
check "pas de mention Storybook (README/CLAUDE)" bash -c "! grep -qi storybook '$TMP/pkg/README.md' '$TMP/pkg/CLAUDE.md'"
check "pas de config Cypress"            bash -c "! test -e '$TMP/pkg/cypress.config.ts'"
check "package.json lib (tsup + exports)" bash -c "grep -q '\"tsup' '$TMP/pkg/package.json' && grep -q '\"exports\"' '$TMP/pkg/package.json'"
check "pas de Docker pour une lib"       bash -c "! test -e '$TMP/pkg/Dockerfile' && ! test -e '$TMP/pkg/docker-compose.yml' && ! test -e '$TMP/pkg/docs/docker.md'"
check "pas de mention docker (README/Makefile)" bash -c "! grep -qi 'docker' '$TMP/pkg/README.md' '$TMP/pkg/Makefile'"
check "pas de cible e2e/system"          bash -c "! grep -qE '^test-(e2e|system):' '$TMP/pkg/Makefile'"

echo "→ Layout package --postman (GitHub)"
check "tests/systeme + Postman"          test -f "$TMP/api/tests/systeme/postman_collection.json"
check "ci-main-system présent, pas e2e"  bash -c "test -f '$TMP/api/.github/workflows/ci-main-system.yml' && ! test -e '$TMP/api/.github/workflows/ci-main-e2e.yml'"
check "cible test-system présente"       grep -q '^test-system:' "$TMP/api/Makefile"

echo "→ Cibles Make (dry-run)"
for t in install build lint test-unit test-int test-mutation; do
  check "make -n $t (fb)" make -C "$TMP/fb" -n "$t"
done
check "make -n test-e2e (fb)"        make -C "$TMP/fb" -n test-e2e
check "make -n test-acceptance (fb)" make -C "$TMP/fb" -n test-acceptance
check "make -n docker-up (single)"   make -C "$TMP/single" -n docker-up
check "make -n build (pkg)"          make -C "$TMP/pkg" -n build

echo "→ Hooks (check-test-location)"
hook="$TMP/fb/.claude/hooks/check-test-location.sh"
payload() { printf '{"tool_name":"Write","tool_input":{"file_path":"%s"}}' "$1"; }
allowed() { test -z "$(payload "$1" | bash "$hook")"; }
denied()  { payload "$1" | bash "$hook" | grep -q '"deny"'; }
check "acceptance .test.ts autorisé"           allowed "$TMP/fb/tests/acceptance/uat/securite/dispo.test.ts"
check "unitaire front au bon endroit autorisé" allowed "$TMP/fb/front/tests/unitaire/Button.spec.tsx"
check "spec unitaire hors convention refusé"   denied  "$TMP/fb/front/src/components/Button.spec.tsx"
check "test back hors convention refusé"       denied  "$TMP/fb/back/src/services/cart.test.ts"
check "test .tsx hors convention refusé"       denied  "$TMP/fb/back/src/services/cart.test.tsx"
check "test .js hors convention refusé"        denied  "$TMP/fb/src/util.test.js"

echo "→ Hooks (route-task : routage de modèles)"
rhook="$TMP/fb/.claude/hooks/route-task.sh"
route() { printf '{"prompt":"%s"}' "$1" | CLAUDE_PROJECT_DIR="$TMP/fb" bash "$rhook"; }
routes_to() { route "$1" | jq -r '.hookSpecificOutput.additionalContext' | grep -q "$2"; }
no_output() { test -z "$(route "$1")"; }
check "architecture → opus-architect"    routes_to "repense l architecture du module de paiement" "opus-architect"
check "sécurité → opus-architect"        routes_to "ajoute la gestion des tokens auth" "opus-architect"
check "feature → opus-dev"             routes_to "implémente le tri de la liste des produits par prix" "opus-dev"
check "mécanique → haiku-mechanic"       routes_to "corrige la typo dans le readme" "haiku-mechanic"
check "override !! → silence"            no_output "!!repense toute l architecture"
check "commande slash → silence"         no_output "/merge-prod"
check "court sans signal → silence"      no_output "ok merci"
check "journal JSONL écrit"              bash -c "jq -e '.agent' '$TMP/fb/.claude/route-task.log' >/dev/null"
# CREDITS_LIMIT_TOKENS=0 provoquait une division par zéro. Le bloc budget n'est
# atteint que si un cache ccusage frais existe : on l'injecte, sinon le test ne
# vérifierait rien (et aucun appel réseau n'est fait, le cache faisant foi).
credits_zero_silent() {
  local dir="$TMP/credits" cache err
  mkdir -p "$dir"
  cache="$dir/claude-route-task-$(printf '%s' "$TMP/fb" | cksum | cut -d' ' -f1).json"
  printf '{"blocks":[{"totalTokens":1000,"endTime":"2099-01-01T00:00:00.000Z"}]}' > "$cache"
  err=$(printf '{"prompt":"implémente le tri de la liste des produits"}' \
    | CLAUDE_PROJECT_DIR="$TMP/fb" TMPDIR="$dir" CREDITS_LIMIT_TOKENS=0 bash "$rhook" 2>&1 >/dev/null)
  [ -z "$err" ]
}
check "CREDITS_LIMIT_TOKENS=0 sans erreur" credits_zero_silent
# Le journal grossissait indéfiniment (une ligne par prompt).
log_rotates() {
  local log="$TMP/fb/.claude/route-task.log" n
  seq 1 60 | sed 's/.*/{"ts":"x","class":"c","agent":"a","words":1}/' > "$log"
  printf '{"prompt":"implémente le tri de la liste des produits"}' \
    | CLAUDE_PROJECT_DIR="$TMP/fb" LOG_MAX_LINES=50 bash "$rhook" >/dev/null 2>&1
  n=$(wc -l < "$log")
  [ "$n" -le 30 ]
}
check "journal tronqué au-delà du seuil" log_rotates

echo "→ Hooks (check-file-length, remind-docs + throttle)"
flhook="$TMP/fb/.claude/hooks/check-file-length.sh"
big="$TMP/fb/front/src/services/big.service.ts"
seq 1 320 | sed 's/^/\/\/ ligne /' > "$big"
check "fichier > 300 lignes signalé" bash -c "printf '{\"tool_input\":{\"file_path\":\"%s\"}}' '$big' | bash '$flhook' | grep -q 'LIMITE DE TAILLE'"
rm -f "$big"
rdhook="$TMP/fb/.claude/hooks/remind-docs.sh"
rd_payload='{"tool_input":{"file_path":"front/src/services/x.service.ts"}}'
mkdir -p "$TMP/throttle"
check "remind-docs : premier rappel émis" bash -c "printf '%s' '$rd_payload' | TMPDIR='$TMP/throttle' bash '$rdhook' | grep -q 'Doc '"
check "remind-docs : throttle actif"      bash -c "test -z \"\$(printf '%s' '$rd_payload' | TMPDIR='$TMP/throttle' bash '$rdhook')\""

echo "→ Résolution npm des package.json générés (si réseau)"
if npm ping >/dev/null 2>&1; then
  for d in "$TMP/single" "$TMP/fb/front" "$TMP/fb/back" "$TMP/pkg"; do
    check "npm install --package-lock-only ($(basename "$d"))" \
      npm install --package-lock-only --ignore-scripts --prefix "$d"
  done
else
  echo "  – registre npm injoignable : étape sautée"
fi

echo ""
if [ "$fail" = 1 ]; then
  echo "✗ Smoke test en échec."
  exit 1
fi
echo "✓ Smoke test OK."
