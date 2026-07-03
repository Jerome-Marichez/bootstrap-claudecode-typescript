#!/bin/bash
# check-max-lines.sh — échoue si un fichier source dépasse 300 lignes.
# Exécuté par `make lint` et par la CI. Exclusions : tests, config, généré.
# Usage : ./scripts/check-max-lines.sh [racine]

set -euo pipefail
MAX=300
ROOT="${1:-.}"
fail=0

while IFS= read -r f; do
  lines=$(wc -l < "$f" | tr -d ' ')
  if [ "$lines" -gt "$MAX" ]; then
    echo "✗ $f : $lines lignes (max $MAX)"
    fail=1
  fi
done < <(find "$ROOT" \
  \( -path '*/node_modules' -o -path '*/.next' -o -path '*/dist' -o -path '*/build' \
     -o -path '*/coverage' -o -path '*/.git' \) -prune -o \
  -type f \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' \) \
  ! -name '*.test.*' ! -name '*.spec.*' ! -name '*.cy.ts' ! -name '*.config.*' ! -name '*.d.ts' \
  ! -path '*/tests/*' \
  -print)

if [ "$fail" = 1 ]; then
  echo ""
  echo "Des fichiers dépassent $MAX lignes : extraire des sous-composants / hooks / services."
  exit 1
fi
echo "✓ Aucun fichier source ne dépasse $MAX lignes."
