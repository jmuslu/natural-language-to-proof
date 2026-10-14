#!/usr/bin/env bash
# All release gates for an explicitly named local research run; no data is staged.
set -euo pipefail
cd "$(dirname "$0")/.."
[ "$(git branch --show-current)" = astra/research ]
run_dir="research/runs/${1:?usage: bash research/run-gates.sh RUN_NAME}"
mkdir -p "$run_dir"
git rev-parse HEAD > "$run_dir/parent.txt"
cabal build all > "$run_dir/build.log" 2>&1
touch "$run_dir/build.ok"
cabal test all > "$run_dir/test.log" 2>&1
bash scripts/check-oracle-boundary.sh > "$run_dir/oracle.log" 2>&1
bash scripts/check-explain.sh > "$run_dir/explain.log" 2>&1
touch "$run_dir/all-gates.ok"
printf '%s\n' "All gates passed: $run_dir"
