# shellcheck shell=bash
# tests.sh — génération de la structure et de l'outillage de tests.
# Sourcé par scripts/bootstrap.sh ; n'est pas exécutable seul.
# Lit les globales : TARGET TPL LAYOUT POSTMAN TESTS_SETUP ACCEPTANCE
# et la fonction render() de lib/render.sh.

gen_tests() {
  echo "→ Structure de tests (layout : $LAYOUT)"
  # tests/fixtures/ : les JEUX DE DONNÉES sur lesquels tournent les vrais services
  # (la politique interdit les mocks — cf. docs/testing.md et check-test-doubles.sh).
  if [ "$LAYOUT" = "front-back" ]; then
    mkdir -p "$TARGET/front/tests/unitaire" "$TARGET/front/tests/integration" "$TARGET/front/tests/e2e" \
             "$TARGET/front/tests/fixtures" \
             "$TARGET/back/tests/unitaire"  "$TARGET/back/tests/integration"  "$TARGET/back/tests/systeme" \
             "$TARGET/back/tests/fixtures"
    for d in front/tests/unitaire front/tests/integration front/tests/e2e front/tests/fixtures \
             back/tests/unitaire back/tests/integration back/tests/systeme back/tests/fixtures; do
      touch "$TARGET/$d/.gitkeep"
    done
  elif [ "$LAYOUT" = "package" ]; then
    mkdir -p "$TARGET/src" "$TARGET/tests/unitaire" "$TARGET/tests/integration" "$TARGET/tests/fixtures"
    for d in tests/unitaire tests/integration tests/fixtures; do
      touch "$TARGET/$d/.gitkeep"
    done
    if [ "$POSTMAN" = 1 ]; then
      mkdir -p "$TARGET/tests/systeme"
      touch "$TARGET/tests/systeme/.gitkeep"
    fi
  else
    mkdir -p "$TARGET/src" "$TARGET/tests/unitaire" "$TARGET/tests/integration" \
             "$TARGET/tests/e2e" "$TARGET/tests/systeme" "$TARGET/tests/fixtures"
    for d in tests/unitaire tests/integration tests/e2e tests/systeme tests/fixtures; do
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
    # Jeu de données d'exemple — la forme attendue des fixtures, jamais un mock.
    if [ "$LAYOUT" = "front-back" ]; then
      render "$TPL/tests-setup/exemple-fixture.json" "$TARGET/front/tests/fixtures/exemple.fixture.json"
      render "$TPL/tests-setup/exemple-fixture.json" "$TARGET/back/tests/fixtures/exemple.fixture.json"
    else
      render "$TPL/tests-setup/exemple-fixture.json" "$TARGET/tests/fixtures/exemple.fixture.json"
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
}
