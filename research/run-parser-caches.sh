#!/usr/bin/env bash
# Snapshot one parser build and collect paired, gold-free caches with two loads.
set -euo pipefail
cd "$(dirname "$0")/.."
[ "$(git branch --show-current)" = astra/research ]
[ -f research/runs/phase-cd/build.ok ]
mkdir -p research/runs/phase-d
binary=$(cabal list-bin nl2proof-parse-json)
cp "$binary" research/runs/phase-d/parser
research/.venv/bin/python bench/reasoning/run.py parse --bench all --limit 120 --binary research/runs/phase-d/parser --output research/runs/phase-d/parses-default.jsonl > research/runs/phase-d/parse-default-driver.log 2>&1 &
default_pid=$!
research/.venv/bin/python bench/reasoning/run.py parse --bench all --limit 120 --binary research/runs/phase-d/parser --output research/runs/phase-d/parses-pos.jsonl --pos-backoff > research/runs/phase-d/parse-pos-driver.log 2>&1 &
pos_pid=$!
status=0
wait "$default_pid" || status=1
wait "$pos_pid" || status=1
exit "$status"
