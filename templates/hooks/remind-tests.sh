#!/bin/bash
# Hook PostToolUse — rappel politique de tests ({{PROJECT_NAME}})
# Après modification/création d'un fichier source (hors tests, config, doc),
# rappelle la politique : le test précède le code, il est écrit par le développeur,
# l'assistant propose intention + contenu (le blocage, lui, est fait en amont par
# require-test-first.sh).
# Throttle : au plus un rappel par REMIND_THROTTLE_MINUTES (15 min).

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

stamp="${TMPDIR:-/tmp}/claude-remind-tests-$(printf '%s' "${CLAUDE_PROJECT_DIR:-$PWD}" | cksum | cut -d' ' -f1)"
[ -n "$(find "$stamp" -mmin -"${REMIND_THROTTLE_MINUTES:-15}" 2>/dev/null)" ] && exit 0
touch "$stamp" 2>/dev/null

jq -n --arg f "$f" '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:("Tests {{PROJECT_NAME}} — modif ou création de " + $f + ". POLITIQUE : (1) LE TEST PRÉCÈDE LE CODE — au moins l un des trois niveaux (UNITAIRE, INTÉGRATION, SYSTÈME) couvre le comportement avant que le code existe ; l unitaire est le minimum dès qu il y a de la logique. (2) LE TEST EST ÉCRIT PAR {{OWNER}} — tu ne poses pas les fichiers de test : expose l intention (comportement attendu, cas limites, jeu de données) et le contenu proposé, puis attends qu il soit posé. (3) LE CODE S ADAPTE AU TEST — ne modifie jamais l intention d un test pour le faire passer. (4) E2E = parcours navigateur critique, à proposer via AskUserQuestion. (5) PAS DE MOCKS des données métier : des jeux de données réalistes, seules les frontières (HTTP, base) sont pilotées. Référence : docs/testing.md.")}}'
