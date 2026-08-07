#!/bin/bash
# Hook PreToolUse — pas de mocks, des jeux de données ({{PROJECT_NAME}})
# Refuse toute DOUBLURE DE MODULE (jest.mock, vi.mock, __mocks__, sinon.stub,
# mockResolvedValue, proxyquire, moduleNameMapper vers un mock…) : un test qui
# remplace la logique métier par une doublure ne prouve rien. Les services réels
# collaborent entre eux et tournent sur des JEUX DE DONNÉES réalistes, versionnés
# dans tests/fixtures/.
# Ce qui reste autorisé, parce que ce sont des FRONTIÈRES et non des mocks :
# MSW (setupServer) à la frontière réseau, Supertest / vrai serveur HTTP
# (listen(0)), base de test dédiée, testcontainers — et jest.fn()/jest.spyOn,
# qui observent un appel sans remplacer un module.
# Analyse uniquement le texte AJOUTÉ par l'outil (content / new_string / edits).
# ALLOW_TEST_DOUBLES=1 désarme le hook. Référence : docs/testing.md.

set -u
[ "${ALLOW_TEST_DOUBLES:-0}" = "1" ] && exit 0

input=$(cat)
tool=$(printf '%s' "$input" | jq -r '.tool_name // empty')
case "$tool" in Write|Edit|MultiEdit) ;; *) exit 0 ;; esac
f=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
[ -z "$f" ] && exit 0

deny() { jq -n --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'; exit 0; }

REMEDE="Les données métier ne se mockent pas : fais tourner le VRAI service sur un JEU DE DONNÉES réaliste versionné dans tests/fixtures/. Seules les FRONTIÈRES se pilotent — MSW (setupServer) pour le réseau, Supertest ou un vrai serveur (listen(0)) pour HTTP, une base de test dédiée pour la persistance ; jest.fn()/jest.spyOn restent permis pour observer un appel. Voir docs/testing.md."

# Un dossier __mocks__ n'a pas lieu d'exister dans ce projet.
case "$f" in
  */__mocks__/*|__mocks__/*) deny "PAS DE DOSSIER __mocks__ — $f. $REMEDE" ;;
esac

case "$f" in
  */node_modules/*|*/dist/*|*/build/*|*/.next/*|*/coverage/*) exit 0 ;;
  *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs) ;;
  *) exit 0 ;;
esac

added=$(printf '%s' "$input" | jq -r '[.tool_input.content?, .tool_input.new_string?,
  (.tool_input.edits // [] | map(.new_string) | join("\n"))]
  | map(select(. != null and . != "")) | join("\n")')
[ -z "$added" ] && exit 0

# Doublures de modules — le motif trouvé est cité pour que la correction soit ciblée.
DOUBLES='jest\.mock\(|jest\.unstable_mockModule|vi\.mock\(|vitest\.mock\(|__mocks__|proxyquire|td\.replace|sinon\.(stub|mock|fake)|mock(Resolved|Rejected|Return)Value|mockImplementation'
hit=$(printf '%s' "$added" | grep -oE "$DOUBLES" | head -1)
[ -n "$hit" ] && deny "PAS DE DOUBLURE DE MODULE — « $hit » dans $f. $REMEDE"

# Un moduleNameMapper qui redirige un module vers un mock revient au même.
case "$f" in
  */jest.config.*|jest.config.*)
    printf '%s' "$added" | grep -q 'moduleNameMapper' \
      && printf '%s' "$added" | grep -qi 'mock' \
      && deny "MODULE REDIRIGÉ VERS UN MOCK — moduleNameMapper dans $f. $REMEDE"
    ;;
esac

exit 0
