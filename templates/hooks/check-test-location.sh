#!/bin/bash
# Hook PreToolUse — garde-fou structure des dossiers de tests ({{PROJECT_NAME}})
# Bloque la CREATION (Write) d'un fichier de test hors de la convention :
#   front/tests/unitaire/**/*.spec.ts(x)            (jamais *.integration.spec.*)
#   front/tests/integration/**/*.integration.spec.ts(x)
#   front/tests/e2e/**/*.cy.ts
#   back/tests/{unitaire,integration,systeme}/**/*.test.ts
#   tests/acceptance/**/*.test.ts (acceptation / UAT, si activé)
# Layout single : tests/{unitaire,integration,e2e,systeme}/ à la racine.
# Référence : docs/testing.md. Ne bloque pas Edit (fichiers déjà à leur place).

set -u
input=$(cat)
tool=$(printf '%s' "$input" | jq -r '.tool_name // empty')
[ "$tool" = "Write" ] || exit 0

f=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
[ -z "$f" ] && exit 0

deny() { jq -n --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'; exit 0; }

case "$f" in
  *.integration.spec.ts|*.integration.spec.tsx)
    case "$f" in
      */front/tests/integration/*|front/tests/integration/*|*/tests/integration/*|tests/integration/*) exit 0 ;;
      *) deny "Test d'intégration hors de {front/,}tests/integration/ — crée le fichier au bon endroit (voir docs/testing.md)." ;;
    esac
    ;;
  *.spec.ts|*.spec.tsx)
    case "$f" in
      */front/tests/unitaire/*|front/tests/unitaire/*|*/tests/unitaire/*|tests/unitaire/*) exit 0 ;;
      *) deny "Test unitaire hors de {front/,}tests/unitaire/ — crée le fichier au bon endroit (voir docs/testing.md)." ;;
    esac
    ;;
  *.cy.ts)
    case "$f" in
      */front/tests/e2e/*|front/tests/e2e/*|*/tests/e2e/*|tests/e2e/*) exit 0 ;;
      *) deny "Spec Cypress hors de {front/,}tests/e2e/ — crée le fichier au bon endroit (voir docs/testing.md)." ;;
    esac
    ;;
  *.test.ts)
    case "$f" in
      */tests/acceptance/*|tests/acceptance/*) exit 0 ;;
      */back/tests/unitaire/*|back/tests/unitaire/*) exit 0 ;;
      */back/tests/integration/*|back/tests/integration/*) exit 0 ;;
      */back/tests/systeme/*|back/tests/systeme/*) exit 0 ;;
      */back/*|back/*) deny "Test back hors de back/tests/{unitaire,integration,systeme}/ — crée le fichier au bon endroit (voir docs/testing.md)." ;;
      */tests/unitaire/*|tests/unitaire/*|*/tests/integration/*|tests/integration/*|*/tests/systeme/*|tests/systeme/*) exit 0 ;;
      */tests/*|tests/*) deny "Test .test.ts hors de tests/{unitaire,integration,systeme}/ — crée le fichier au bon endroit (voir docs/testing.md)." ;;
      *) exit 0 ;;
    esac
    ;;
  *) exit 0 ;;
esac
