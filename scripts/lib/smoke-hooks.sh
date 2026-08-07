# shellcheck shell=bash
# smoke-hooks.sh — assertions de comportement des hooks générés.
# Sourcé par scripts/smoke-test.sh ; n'est pas exécutable seul.
# Lit les globales : TMP (projets générés) et la fonction check() de smoke-test.sh.
# Extrait de smoke-test.sh pour tenir la règle des 300 lignes que ce dépôt
# s'applique à lui-même.

check_hook_test_location() {
  echo "→ Hooks (check-test-location)"
  local hook="$TMP/fb/.claude/hooks/check-test-location.sh"
  payload() { printf '{"tool_name":"Write","tool_input":{"file_path":"%s"}}' "$1"; }
  allowed() { test -z "$(payload "$1" | bash "$hook")"; }
  denied()  { payload "$1" | bash "$hook" | grep -q '"deny"'; }
  check "acceptance .test.ts autorisé"           allowed "$TMP/fb/tests/acceptance/uat/securite/dispo.test.ts"
  check "unitaire front au bon endroit autorisé" allowed "$TMP/fb/front/tests/unitaire/Button.spec.tsx"
  check "spec unitaire hors convention refusé"   denied  "$TMP/fb/front/src/components/Button.spec.tsx"
  check "test back hors convention refusé"       denied  "$TMP/fb/back/src/services/cart.test.ts"
  check "test .tsx hors convention refusé"       denied  "$TMP/fb/back/src/services/cart.test.tsx"
  check "test .js hors convention refusé"        denied  "$TMP/fb/src/util.test.js"
}

# require-test-first : le test précède le code, et c'est le développeur qui l'écrit.
check_hook_test_first() {
  echo "→ Hooks (require-test-first)"
  local hook="$TMP/fb/.claude/hooks/require-test-first.sh"
  local fb="$TMP/fb"
  rtf() { # rtf <chemin> <contenu> — payload Write
    printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"%s"}}' "$1" "$2" \
      | CLAUDE_PROJECT_DIR="$fb" bash "$hook"
  }
  rtf_deny() { rtf "$1" "$2" | grep -q '"deny"'; }
  rtf_ask()  { rtf "$1" "$2" | grep -q '"ask"'; }
  rtf_pass() { test -z "$(rtf "$1" "$2")"; }

  check "test écrit par l assistant refusé" \
    rtf_deny "$fb/front/tests/unitaire/Panier.spec.tsx" "describe(x)"
  check "jeu de données autorisé" \
    rtf_pass "$fb/front/tests/fixtures/panier.json" "[]"
  check "source non couvert → confirmation" \
    rtf_ask "$fb/front/src/services/panier.service.ts" "export class PanierService {}"
  check "types.ts autorisé sans test" \
    rtf_pass "$fb/front/src/interfaces/types.ts" "export type A = string"
  check "baril de ré-exports autorisé" \
    rtf_pass "$fb/front/src/services/index.ts" "export * from './panier.service';"

  # Une fois le test posé par le développeur, le code passe sans blocage.
  printf 'import { PanierService } from "../../src/services/panier.service";\n' \
    > "$fb/front/tests/unitaire/panier.spec.ts"
  check "source couvert par un test posé → autorisé" \
    rtf_pass "$fb/front/src/services/panier.service.ts" "export class PanierService {}"
  rm -f "$fb/front/tests/unitaire/panier.spec.ts"

  # Délégation explicite de l'humain : l'intention doit rester écrite dans le test.
  deleg() { TESTS_WRITABLE_BY_ASSISTANT=1 rtf "$1" "$2"; }
  deleg_deny() { deleg "$1" "$2" | grep -q '"deny"'; }
  deleg_pass() { test -z "$(deleg "$1" "$2")"; }
  check "délégation sans intention refusée" \
    deleg_deny "$fb/front/tests/unitaire/Panier.spec.tsx" "describe(x)"
  check "délégation avec intention autorisée" \
    deleg_pass "$fb/front/tests/unitaire/Panier.spec.tsx" "/* Intention : panier vide = 0 EUR */"

  off_silent() { test -z "$(REQUIRE_TEST_FIRST=0 rtf "$1" "$2")"; }
  check "REQUIRE_TEST_FIRST=0 → silence" \
    off_silent "$fb/front/tests/unitaire/Panier.spec.tsx" "describe(x)"
}

# check-test-doubles : pas de mocks, des jeux de données.
check_hook_test_doubles() {
  echo "→ Hooks (check-test-doubles)"
  local hook="$TMP/fb/.claude/hooks/check-test-doubles.sh"
  local fb="$TMP/fb"
  ctd() { # ctd <chemin> <contenu>
    printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"%s"}}' "$1" "$2" \
      | CLAUDE_PROJECT_DIR="$fb" bash "$hook"
  }
  ctd_deny() { ctd "$1" "$2" | grep -q '"deny"'; }
  ctd_pass() { test -z "$(ctd "$1" "$2")"; }

  check "jest.mock refusé" \
    ctd_deny "$fb/front/tests/unitaire/panier.spec.ts" "jest.mock(../src/services/panier.service)"
  check "mockResolvedValue refusé" \
    ctd_deny "$fb/back/tests/integration/api.test.ts" "repo.trouver.mockResolvedValue(rien)"
  check "vi.mock refusé" \
    ctd_deny "$fb/front/src/services/panier.service.ts" "vi.mock(./depot)"
  check "dossier __mocks__ refusé" \
    ctd_deny "$fb/front/__mocks__/panier.service.ts" "export default {}"
  check "moduleNameMapper vers un mock refusé" \
    ctd_deny "$fb/front/jest.config.mjs" "moduleNameMapper: { depot: ./mocks/depot }"
  check "MSW (setupServer) autorisé" \
    ctd_pass "$fb/front/tests/integration/panier.integration.spec.ts" "const serveur = setupServer(...gestionnaires)"
  check "supertest autorisé" \
    ctd_pass "$fb/back/tests/integration/api.test.ts" "await request(app).get(/produits)"
  check "jest.fn observateur autorisé" \
    ctd_pass "$fb/front/tests/unitaire/panier.spec.ts" "const auClic = jest.fn()"
  off_doubles() { test -z "$(ALLOW_TEST_DOUBLES=1 ctd "$1" "$2")"; }
  check "ALLOW_TEST_DOUBLES=1 → silence" \
    off_doubles "$fb/front/tests/unitaire/panier.spec.ts" "jest.mock(../src/services/panier.service)"
}

# check-ci-before-publish : la pipeline fait foi avant toute publication.
# Un faux gh, déposé en tête de PATH, rend l'état de la CI déterministe : il
# répond un run list dont le headSha est bien celui de HEAD (sinon le hook
# conclurait « aucun run pour ce commit » et le test ne prouverait rien).
check_hook_ci_publish() {
  echo "→ Hooks (check-ci-before-publish)"
  local hook="$TMP/single/.claude/hooks/check-ci-before-publish.sh"
  local bin="$TMP/fakebin-gh"
  mkdir -p "$bin"
  cat > "$bin/gh" <<'FAKE'
#!/bin/sh
case "$*" in
  *"run list"*)
    printf '[{"headSha":"%s","status":"%s","conclusion":%s,"workflowName":"ci-dev-tests"}]' \
      "$(git rev-parse HEAD)" "${FAKE_STATUS:-completed}" "${FAKE_CONCLUSION:-\"failure\"}" ;;
  *) exit 1 ;;
esac
FAKE
  chmod +x "$bin/gh"

  cip() { # cip <commande shell> — payload Bash, exécuté depuis le projet généré
    printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$1" \
      | (cd "$TMP/single" && PATH="$bin:$PATH" bash "$hook")
  }
  cip_deny() { cip "$1" | grep -q '"deny"'; }
  cip_ask()  { cip "$1" | grep -q '"ask"'; }
  cip_pass() { test -z "$(cip "$1")"; }
  vert() { test -z "$(printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$1" \
    | (cd "$TMP/single" && PATH="$bin:$PATH" FAKE_CONCLUSION='"success"' bash "$hook"))"; }
  encours() { printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$1" \
    | (cd "$TMP/single" && PATH="$bin:$PATH" FAKE_STATUS=in_progress FAKE_CONCLUSION=null bash "$hook") \
    | grep -q 'EN COURS'; }

  check "push sur main, CI rouge → refusé"   cip_deny "git push origin main"
  check "push sur main, CI verte → autorisé" vert     "git push origin main"
  check "push sur main, CI en cours → refusé" encours "git push origin main"
  check "npm publish, CI rouge → refusé"     cip_deny "npm publish --access public"
  check "gh pr merge, CI rouge → refusé"     cip_deny "gh pr merge 12 --squash"
  check "push d une branche feature → autorisé" cip_pass "git push -u origin feature/panier"
  check "commande quelconque → autorisée"    cip_pass "make test-unit"
  check "--no-verify refusé"                 cip_deny "git commit --no-verify -m wip"
  check "[skip ci] refusé"                   cip_deny "git commit -m 'fix: bidule [skip ci]'"
  check "gh pr merge --admin refusé"         cip_deny "gh pr merge 12 --admin"
  check "gh run cancel refusé"               cip_deny "gh run cancel 42"
  check "désarmement en ligne refusé"        cip_deny "REQUIRE_GREEN_CI=0 git push origin main"
  check "REQUIRE_GREEN_CI=0 (session) → passe" bash -c \
    "test -z \"\$(printf '{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"git push origin main\"}}' | (cd '$TMP/single' && PATH='$bin:\$PATH' REQUIRE_GREEN_CI=0 bash '$hook'))\""
  check "gh absent → confirmation"           bash -c \
    "printf '{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"git push origin main\"}}' | (cd '$TMP/single' && PATH=/usr/bin:/bin bash '$hook') | grep -q '\"ask\"'"

  check "continue-on-error refusé" bash -c \
    "printf '{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$TMP/single/.github/workflows/ci-dev-tests.yml\",\"new_string\":\"    continue-on-error: true\"}}' | bash '$hook' | grep -q '\"deny\"'"
  check "allow_failure refusé" bash -c \
    "printf '{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$TMP/pkg/.gitlab-ci.yml\",\"new_string\":\"  allow_failure: true\"}}' | bash '$hook' | grep -q '\"deny\"'"
  check "|| true sur un test refusé" bash -c \
    "printf '{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$TMP/single/.github/workflows/ci-dev-tests.yml\",\"new_string\":\"        run: make test-unit || true\"}}' | bash '$hook' | grep -q '\"deny\"'"
  check "workflow inchangé autorisé" bash -c \
    "test -z \"\$(printf '{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$TMP/single/.github/workflows/ci-dev-tests.yml\",\"new_string\":\"        run: make test-int\"}}' | bash '$hook')\""
}

check_hook_route_task() {
  echo "→ Hooks (route-task : routage de modèles)"
  local rhook="$TMP/fb/.claude/hooks/route-task.sh"
  route() { printf '{"prompt":"%s"}' "$1" | CLAUDE_PROJECT_DIR="$TMP/fb" bash "$rhook"; }
  routes_to() { route "$1" | jq -r '.hookSpecificOutput.additionalContext' | grep -q "$2"; }
  no_output() { test -z "$(route "$1")"; }
  check "architecture → opus-architect"    routes_to "repense l architecture du module de paiement" "opus-architect"
  check "sécurité → opus-architect"        routes_to "ajoute la gestion des tokens auth" "opus-architect"
  check "feature → opus-dev"               routes_to "implémente le tri de la liste des produits par prix" "opus-dev"
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
}

check_hook_reminders() {
  echo "→ Hooks (check-file-length, remind-docs + throttle)"
  local flhook="$TMP/fb/.claude/hooks/check-file-length.sh"
  local big="$TMP/fb/front/src/services/big.service.ts"
  seq 1 320 | sed 's/^/\/\/ ligne /' > "$big"
  check "fichier > 300 lignes signalé" bash -c "printf '{\"tool_input\":{\"file_path\":\"%s\"}}' '$big' | bash '$flhook' | grep -q 'LIMITE DE TAILLE'"
  rm -f "$big"
  local rdhook="$TMP/fb/.claude/hooks/remind-docs.sh"
  local rd_payload='{"tool_input":{"file_path":"front/src/services/x.service.ts"}}'
  mkdir -p "$TMP/throttle"
  check "remind-docs : premier rappel émis" bash -c "printf '%s' '$rd_payload' | TMPDIR='$TMP/throttle' bash '$rdhook' | grep -q 'Doc '"
  check "remind-docs : throttle actif"      bash -c "test -z \"\$(printf '%s' '$rd_payload' | TMPDIR='$TMP/throttle' bash '$rdhook')\""
}

check_hooks() {
  check_hook_test_location
  check_hook_test_first
  check_hook_test_doubles
  check_hook_ci_publish
  check_hook_route_task
  check_hook_reminders
}
