#!/bin/bash
# Hook PostToolUse — garde-fou 300 lignes max par fichier source ({{PROJECT_NAME}})
# Après un Write/Edit sur un fichier .ts/.tsx/.js/.jsx (hors tests, config, généré),
# injecte un rappel si le fichier dépasse 300 lignes : extraire, jamais contourner.
# Le même seuil est vérifié en CI par scripts/check-max-lines.sh.

set -u
MAX=300
input=$(cat)
f=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_response.filePath // empty')
[ -z "$f" ] && exit 0
[ -f "$f" ] || exit 0

case "$f" in
  *.test.*|*.spec.*|*.cy.ts|*/tests/*|tests/*|*.config.*|*.d.ts|*/node_modules/*|*/.next/*|*/dist/*|*/build/*) exit 0 ;;
  *.ts|*.tsx|*.js|*.jsx) ;;
  *) exit 0 ;;
esac

lines=$(wc -l < "$f" | tr -d ' ')
[ "$lines" -le "$MAX" ] && exit 0

jq -n --arg f "$f" --arg n "$lines" --arg max "$MAX" \
  '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:("LIMITE DE TAILLE — " + $f + " fait " + $n + " lignes (max " + $max + "). La CI échouera. Refactore MAINTENANT : extrais des sous-composants, hooks personnalisés ou services (voir CLAUDE.md). Ne modifie jamais le seuil ni le script de contrôle.")}}'
