#!/bin/bash
# Hook PostToolUse — rappel documentation ({{PROJECT_NAME}})
# Après toute modification de code (hors doc, config, .claude), rappelle de mettre à
# jour le README.md et la doc docs/ impactée, conformément au CLAUDE.md.

set -u
input=$(cat)
f=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_response.filePath // empty')

case "$f" in
  ""|*.md|*/docs/*|docs/*|*.gitignore|*.lock|*package-lock.json|*/.claude/*|*.claude/*) exit 0 ;;
esac

jq -n --arg f "$f" '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:("Doc {{PROJECT_NAME}} — tu viens de modifier " + $f + ". Conformément au CLAUDE.md, pense à mettre à jour le README.md et la doc docs/ impactée (architecture, data-model, testing, ci-cd, docker, tooling...), ou à créer une nouvelle catégorie docs/ si le changement le justifie — et dans ce cas, ajoute le lien dans le README.md ET le CLAUDE.md.")}}'
