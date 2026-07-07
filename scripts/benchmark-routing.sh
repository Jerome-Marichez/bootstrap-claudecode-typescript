#!/bin/bash
# benchmark-routing.sh — benchmark du routage de modèles sur une app basique.
#
# Rejoue la charge de travail fixe de scripts/benchmark-prompts.txt sur un
# projet généré par le plugin, dans deux bras :
#   - routing    : hooks actifs, le routage recommande opus-architect /
#                  opus-dev / haiku-mechanic ;
#   - no-routing : chaque prompt préfixé « !! » (override : aucune injection),
#                  tout est traité par le modèle principal (Opus).
# Chaque prompt est une session `claude -p` headless ; l'usage API réel est lu
# dans le JSON de sortie (modelUsage : tokens + coût par modèle). Après chaque
# bras : make lint + make test-unit (garde-fou qualité — une économie qui casse
# les tests ne vaut rien).
#
# Usage : benchmark-routing.sh --app <projet-pristine> --out <dossier-résultats>
#         [--runs N] [--prompts fichier] [--model opus]
# Nécessite : claude (CLI), jq, rsync, make, npm. Coût : appels API réels.
set -eu

APP="" ; OUT="" ; RUNS=1 ; MODEL="opus"
PROMPTS="$(cd "$(dirname "$0")" && pwd)/benchmark-prompts.txt"
while [ $# -gt 0 ]; do
  case "$1" in
    --app) APP="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    --runs) RUNS="$2"; shift 2 ;;
    --prompts) PROMPTS="$2"; shift 2 ;;
    --model) MODEL="$2"; shift 2 ;;
    *) echo "Option inconnue : $1" >&2; exit 1 ;;
  esac
done
[ -n "$APP" ] && [ -d "$APP" ] || { echo "--app <projet généré> obligatoire" >&2; exit 1; }
[ -n "$OUT" ] || { echo "--out <dossier> obligatoire" >&2; exit 1; }
command -v claude >/dev/null && command -v jq >/dev/null || { echo "claude + jq requis" >&2; exit 1; }
mkdir -p "$OUT"
# Chemins absolus : les logs/résultats sont écrits après des cd dans le workdir.
OUT="$(cd "$OUT" && pwd)"; APP="$(cd "$APP" && pwd)"
PROMPTS="$(cd "$(dirname "$PROMPTS")" && pwd)/$(basename "$PROMPTS")"

run_arm() { # run_arm <arm> <run_index>
  arm="$1"; run="$2"
  work="$OUT/work-$arm-$run"
  res="$OUT/results-$arm-$run"
  rm -rf "$work"; mkdir -p "$res"
  rsync -a "$APP/" "$work/"
  ( cd "$work" && make install >"$res/install.log" 2>&1 ) || { echo "make install KO ($arm/$run)" >&2; return 1; }
  i=0
  grep -v '^#' "$PROMPTS" | while IFS="$(printf '\t')" read -r cat prompt; do
    [ -n "$prompt" ] || continue
    i=$((i+1)); id=$(printf '%02d' "$i")
    p="$prompt"; [ "$arm" = "no-routing" ] && p="!! $prompt"
    echo "  [$arm/$run] $id ($cat) : $prompt"
    # </dev/null : sans ça, claude consomme le stdin de la boucle (la liste des prompts).
    ( cd "$work" && claude -p "$p" --model "$MODEL" --output-format json \
        --dangerously-skip-permissions </dev/null ) >"$res/$id.json" 2>"$res/$id.err" || true
    jq -n --arg cat "$cat" --arg prompt "$prompt" \
      --slurpfile r "$res/$id.json" \
      '{cat: $cat, prompt: $prompt,
        cost: ($r[0].total_cost_usd // null),
        turns: ($r[0].num_turns // null),
        duration_ms: ($r[0].duration_ms // null),
        is_error: ($r[0].is_error != false),
        models: (($r[0].modelUsage // {}) | to_entries
          | map({model: .key, out: .value.outputTokens, cost: .value.costUSD}))}' \
      >"$res/$id.summary.json" 2>/dev/null || echo '{"is_error":true}' >"$res/$id.summary.json"
  done
  lint=KO; test=KO
  ( cd "$work" && make lint      >"$res/lint.log" 2>&1 ) && lint=OK
  ( cd "$work" && make test-unit >"$res/test.log" 2>&1 ) && test=OK
  jq -s --arg arm "$arm" --arg run "$run" --arg lint "$lint" --arg test "$test" '
    {arm: $arm, run: ($run|tonumber), lint: $lint, test: $test,
     prompts: length,
     errors: [.[] | select(.is_error)] | length,
     total_cost_usd: ([.[].cost // 0] | add),
     total_duration_s: (([.[].duration_ms // 0] | add) / 1000 | round),
     tokens_out_by_model: ([.[].models[]] | group_by(.model)
       | map({(.[0].model): ([.[].out] | add)}) | add),
     cost_by_model: ([.[].models[]] | group_by(.model)
       | map({(.[0].model): (([.[].cost] | add * 100 | round) / 100)}) | add)}' \
    "$res"/*.summary.json > "$OUT/summary-$arm-$run.json"
  echo "→ $OUT/summary-$arm-$run.json"
}

r=1
while [ "$r" -le "$RUNS" ]; do
  run_arm routing    "$r"
  run_arm no-routing "$r"
  r=$((r+1))
done
echo "=== Synthèse ==="
jq -s '.' "$OUT"/summary-*.json | tee "$OUT/summary-all.json"
