#!/bin/bash
# Hook PostToolUse — rappel politique de tests ({{PROJECT_NAME}})
# Après modification/création d'un fichier source (hors tests, config, doc),
# rappelle la politique : unitaire systématique ; intégration/e2e proposés avant création.

set -u
input=$(cat)
f=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_response.filePath // empty')

case "$f" in
  ""|*.test.*|*.spec.*|*.cy.ts|*/tests/*|tests/*|*.d.ts|*.config.*|*/docs/*|docs/*|*.md|*.json|*.css|*.scss|*.gitignore|*.lock|*/.claude/*|*.claude/*) exit 0 ;;
esac
case "$f" in
  *.ts|*.tsx|*.js|*.jsx) ;;
  *) exit 0 ;;
esac

jq -n --arg f "$f" '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:("Tests {{PROJECT_NAME}} — modif ou création de " + $f + ". POLITIQUE : (1) UNITAIRE = systématique et sans demander, dès que tu crées ou modifies un composant ou de la logique (Jest + React Testing Library ; back : *.test.ts). (2) INTÉGRATION et E2E = vérifie d abord si un test pertinent existe ; sinon, et si le composant le justifie (frontière API, accès base, auth pour intégration ; parcours utilisateur critique pour e2e), NE LE CRÉE PAS directement : propose-le via AskUserQuestion. RÈGLE GLOBALE : pas de mocks des données métier, utilise des fixtures. Référence : docs/testing.md.")}}'
