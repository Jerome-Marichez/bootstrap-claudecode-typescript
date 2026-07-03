#!/bin/bash
# smoke-test.sh — tests du générateur.
# Génère les trois layouts dans un dossier temporaire et vérifie les invariants :
# structure, substitution des tokens, filtrage CI par layout, comportement des hooks.
# Exécuté en local et par la CI du repo (.github/workflows/ci.yml). Nécessite : jq, make.

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

echo "→ Génération des trois layouts"
"$ROOT/scripts/bootstrap.sh" --name proj-fb     --owner Testeur --target "$TMP/fb"     --layout front-back --acceptance --no-git >/dev/null
"$ROOT/scripts/bootstrap.sh" --name proj-single --owner Testeur --target "$TMP/single" --layout single --no-git >/dev/null
"$ROOT/scripts/bootstrap.sh" --name proj-pkg    --owner Testeur --target "$TMP/pkg"    --layout package --ci gitlab --no-storybook --no-git >/dev/null
bad_name_refused() { ! "$ROOT/scripts/bootstrap.sh" --name 'Bad Name' --owner Testeur --target "$TMP/bad" >/dev/null 2>&1; }
check "nom non kebab-case refusé" bad_name_refused

echo "→ Layout front-back"
check "shared/schemas généré"            test -f "$TMP/fb/shared/schemas/exemple.schema.ts"
check "5 workflows GitHub"               test "$(ls "$TMP/fb/.github/workflows" | wc -l)" -eq 5
check "template d'issue GitHub (+ frontmatter)" grep -q '^name:' "$TMP/fb/.github/ISSUE_TEMPLATE/issue.md"
check "collection Postman côté back"     test -f "$TMP/fb/back/tests/systeme/postman_collection.json"
check "dossiers UAT (--acceptance)"      test -d "$TMP/fb/tests/acceptance/uat/robustesse"
check ".nvmrc présent"                   test -f "$TMP/fb/.nvmrc"
check "owner substitué"                  grep -q 'Testeur' "$TMP/fb/README.md"
check "hooks exécutables"                test -x "$TMP/fb/.claude/hooks/check-test-location.sh"
check "aucun token non substitué"        bash -c "! grep -rE '\{\{(PROJECT_NAME|PROJECT_DESC|OWNER|FRAMEWORK)\}\}' '$TMP/fb'"
check "check-max-lines passe"            "$TMP/fb/scripts/check-max-lines.sh" "$TMP/fb"

echo "→ Layout single"
check "tests/systeme + Postman"          test -f "$TMP/single/tests/systeme/postman_collection.json"
check "ci-main-system présent"           test -f "$TMP/single/.github/workflows/ci-main-system.yml"

echo "→ Layout package (GitLab, --no-storybook)"
check "template d'issue GitLab"          test -f "$TMP/pkg/.gitlab/issue_templates/issue.md"
check "issue GitLab sans frontmatter"    bash -c "! grep -q '^name:' '$TMP/pkg/.gitlab/issue_templates/issue.md'"
check ".gitlab-ci.yml sans job e2e"      bash -c "! grep -q '^e2e:' '$TMP/pkg/.gitlab-ci.yml'"
check ".gitlab-ci.yml sans job system"   bash -c "! grep -q '^system:' '$TMP/pkg/.gitlab-ci.yml'"
check "Makefile sans cible storybook"    bash -c "! grep -q '^storybook' '$TMP/pkg/Makefile'"
check "Makefile valide après filtrage"   make -C "$TMP/pkg" -n help
check "pas de mention Storybook (README/CLAUDE)" bash -c "! grep -qi storybook '$TMP/pkg/README.md' '$TMP/pkg/CLAUDE.md'"
check "pas de config Cypress"            bash -c "! test -e '$TMP/pkg/cypress.config.ts'"

echo "→ Hooks (check-test-location)"
hook="$TMP/fb/.claude/hooks/check-test-location.sh"
payload() { printf '{"tool_name":"Write","tool_input":{"file_path":"%s"}}' "$1"; }
allowed() { test -z "$(payload "$1" | bash "$hook")"; }
denied()  { payload "$1" | bash "$hook" | grep -q '"deny"'; }
check "acceptance .test.ts autorisé"           allowed "$TMP/fb/tests/acceptance/uat/securite/dispo.test.ts"
check "unitaire front au bon endroit autorisé" allowed "$TMP/fb/front/tests/unitaire/Button.spec.tsx"
check "spec unitaire hors convention refusé"   denied  "$TMP/fb/front/src/components/Button.spec.tsx"
check "test back hors convention refusé"       denied  "$TMP/fb/back/src/services/cart.test.ts"

echo ""
if [ "$fail" = 1 ]; then
  echo "✗ Smoke test en échec."
  exit 1
fi
echo "✓ Smoke test OK."
