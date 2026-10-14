#!/usr/bin/env bash
# Fixed Phase B diagnostic slice and hand-written corpus probes.
set -euo pipefail
cd "$(dirname "$0")/.."
[ "$(git branch --show-current)" = astra/research ]
[ -f research/runs/phase-b-final-gates/build.ok ]
run_dir=research/runs/phase-b
mkdir -p "$run_dir"
for target in semantic-repair nl2proof-explain proofwriter-coverage; do
  binary=$(cabal list-bin "$target")
  cp "$binary" "$run_dir/$target"
done
"$run_dir/semantic-repair" --corpus > "$run_dir/corpus-final.log" 2>&1 &
corpus_pid=$!
"$run_dir/nl2proof-explain" --all-readings < research/phase-a-inputs.txt > "$run_dir/explain-final.log" 2>&1 &
explain_pid=$!
PROOFWRITER_DIR=/home/gram/data/proofwriter "$run_dir/proofwriter-coverage" --owa --split dev --limit 120 --questions --examples 10 --check-context 0 +RTS -N2 -RTS > "$run_dir/coverage-default.log" 2>&1 &
default_pid=$!
PROOFWRITER_DIR=/home/gram/data/proofwriter "$run_dir/proofwriter-coverage" --owa --split dev --limit 120 --questions --examples 10 --check-context 0 --pos-backoff +RTS -N2 -RTS > "$run_dir/coverage-pos.log" 2>&1 &
pos_pid=$!
status=0
for child_pid in "$corpus_pid" "$explain_pid" "$default_pid" "$pos_pid"; do
  wait "$child_pid" || status=1
done
exit "$status"
