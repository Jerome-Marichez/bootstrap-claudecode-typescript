#!/bin/bash
# Hook PreToolUse — le test précède le code ({{PROJECT_NAME}})
# Deux règles, dans cet ordre :
#   A. UN TEST EST ÉCRIT PAR LE DÉVELOPPEUR. Toute création/modification d'un
#      fichier de test par l'assistant est refusée : il expose l'intention
#      (comportement attendu, cas limites, jeu de données) et le contenu proposé
#      dans le chat, {{OWNER}} pose le fichier. Les jeux de données de
#      tests/fixtures/ ne sont pas des tests : ils restent à la charge de l'assistant.
#      Délégation ponctuelle : TESTS_WRITABLE_BY_ASSISTANT=1 dans l'environnement
#      de la SESSION (une affectation écrite dans une commande Bash n'atteint pas
#      l'environnement du hook — la clé reste à l'humain). Même déléguée, l'écriture
#      exige un en-tête « Intention : … » : l'intention reste tracée dans le test.
#   B. LE TEST VIENT AVANT LE CODE. Écrire un fichier source qu'aucun test des trois
#      niveaux (unitaire, intégration, système) ne couvre demande une confirmation.
#      Le code s'adapte au test, jamais l'inverse.
# REQUIRE_TEST_FIRST=0 désarme le hook. Fail-open : toute erreur laisse passer.
# Référence : docs/testing.md.

set -u
[ "${REQUIRE_TEST_FIRST:-1}" = "1" ] || exit 0

input=$(cat)
tool=$(printf '%s' "$input" | jq -r '.tool_name // empty')
case "$tool" in Write|Edit|MultiEdit) ;; *) exit 0 ;; esac
f=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
[ -z "$f" ] && exit 0

deny() { jq -n --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'; exit 0; }
ask()  { jq -n --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"ask",permissionDecisionReason:$r}}'; exit 0; }

# Texte réellement écrit par l'outil (Write, Edit ou MultiEdit confondus).
written() {
  printf '%s' "$input" | jq -r '[.tool_input.content?, .tool_input.new_string?,
    (.tool_input.edits // [] | map(.new_string) | join("\n"))]
    | map(select(. != null and . != "")) | join("\n")'
}

# Les jeux de données ne sont pas des tests : l'assistant peut les préparer.
case "$f" in */tests/fixtures/*|tests/fixtures/*) exit 0 ;; esac

# ---------------------------------------------------------------- Règle A
is_test=0
case "$f" in
  *.spec.ts|*.spec.tsx|*.spec.js|*.spec.jsx) is_test=1 ;;
  *.test.ts|*.test.tsx|*.test.js|*.test.jsx)  is_test=1 ;;
  *.cy.ts|*.cy.tsx|*/tests/*|tests/*)         is_test=1 ;;
esac

if [ "$is_test" = 1 ]; then
  if [ "${TESTS_WRITABLE_BY_ASSISTANT:-0}" != "1" ]; then
    deny "TEST ÉCRIT PAR LE DÉVELOPPEUR — n'écris pas $f. Expose dans le chat (1) l'INTENTION du test : comportement attendu, cas limites, niveau visé (unitaire, intégration ou système), jeu de données réaliste utilisé ; (2) le contenu que tu proposes. {{OWNER}} pose le fichier lui-même. Tu écriras ENSUITE le code qui le fait passer, sans jamais modifier l'intention du test pour l'arranger. Voir docs/testing.md."
  fi
  # Écriture déléguée : l'intention doit être écrite noir sur blanc dans le test.
  # Sur un Write on lit ce qui va être posé ; sur un Edit, l'en-tête du fichier.
  if [ "$tool" = "Write" ] || [ ! -f "$f" ]; then
    head_txt=$(written | head -20)
  else
    head_txt=$(head -20 "$f" 2>/dev/null)
  fi
  printf '%s' "$head_txt" | grep -qi 'intention' && exit 0
  deny "INTENTION MANQUANTE — l'écriture des tests t'a été déléguée (TESTS_WRITABLE_BY_ASSISTANT=1), mais $f doit porter en tête un bloc « Intention : … » validé par {{OWNER}} : comportement attendu, cas limites, jeu de données utilisé. Fais valider l'intention, écris-la en tête du fichier, puis repose le test."
fi

# ---------------------------------------------------------------- Règle B
case "$f" in
  *.ts|*.tsx|*.js|*.jsx) ;;
  *) exit 0 ;;
esac
case "$f" in
  *.d.ts|*.config.ts|*.config.js|*.config.mjs|*.config.cjs|*.config.tsx) exit 0 ;;
  *.stories.ts|*.stories.tsx|*/main.tsx|*/app/layout.tsx) exit 0 ;;
  */interfaces/*|interfaces/*|*/types.ts|*/@types/*) exit 0 ;;
  */node_modules/*|*/dist/*|*/build/*|*/.next/*|*/coverage/*|*/.claude/*) exit 0 ;;
esac

# Fichier baril (uniquement des ré-exports) : rien à tester en propre.
if [ "$tool" = "Write" ]; then
  written | grep -qvE '^[[:space:]]*($|//|/\*|\*|import |export .* from |export \{|export type |\})' \
    || exit 0
fi

# Module couvert ? On cherche le nom de base (celui du dossier pour un index.*)
# dans le NOM et dans le CONTENU des tests, tous niveaux confondus.
root="${CLAUDE_PROJECT_DIR:-$PWD}"
base=$(basename "$f"); base="${base%.*}"
[ "$base" = "index" ] && base=$(basename "$(dirname "$f")")
case "$base" in ""|.|/|src) exit 0 ;; esac

PRUNE=(-name node_modules -o -name dist -o -name build -o -name .next -o -name coverage -o -name .git)
name_hit=$(find "$root" \( "${PRUNE[@]}" \) -prune -o \
  -type f \( -name "*${base}*.spec.*" -o -name "*${base}*.test.*" -o -name "*${base}*.cy.*" \) \
  -print 2>/dev/null | head -1)
[ -n "$name_hit" ] && exit 0

EXCL=(--exclude-dir=node_modules --exclude-dir=dist --exclude-dir=build
      --exclude-dir=.next --exclude-dir=coverage --exclude-dir=.git)
body_hit=$(grep -rlF "${EXCL[@]}" --include='*.spec.*' --include='*.test.*' --include='*.cy.*' \
  -- "$base" "$root" 2>/dev/null | head -1)
[ -n "$body_hit" ] && exit 0

ask "TEST D'ABORD — aucun test ne couvre « $base » ($f). Politique {{PROJECT_NAME}} : (1) au moins l'un des trois niveaux — UNITAIRE, INTÉGRATION ou SYSTÈME — couvre le comportement avant que le code existe ; (2) le test est écrit par {{OWNER}} : expose l'intention (comportement attendu, cas limites, jeu de données réaliste) et le contenu proposé, attends qu'il soit posé ; (3) le code s'adapte au test — ne modifie JAMAIS l'intention d'un test pour le faire passer. Emplacements : docs/testing.md."
