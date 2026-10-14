#!/usr/bin/env bash
# Reproduce the baseline gates and hand-written deviation probes; raw logs stay local.
set -euo pipefail
cd "$(dirname "$0")/.."
[ "$(git branch --show-current)" = astra/research ]
mkdir -p research/runs/phase-a
cabal build all > research/runs/phase-a/build.log 2>&1
cabal test all > research/runs/phase-a/test.log 2>&1
bash scripts/check-oracle-boundary.sh > research/runs/phase-a/oracle.log 2>&1
bash scripts/check-explain.sh > research/runs/phase-a/explain-gate.log 2>&1
cabal run -v0 nl2proof-explain -- --all-readings < research/phase-a-inputs.txt > research/runs/phase-a/deviations.log 2> research/runs/phase-a/deviations.stderr
printf '%s\n' 'Phase A gates and deviation probes completed.'
