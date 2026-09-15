# External oracle bridge

## Run it

From this repository, with the updated companion checkout at `~/projects`:

```sh
# Read existing files; generate only ignored local journal/reports.
python3 corpus/pipeline.py --oracle-only --oracle-repo ~/projects

# Full graph/brain/retrieval run, using the existing brain environment.
corpus/.venv/bin/python corpus/pipeline.py --quick --oracle-repo ~/projects

# Explicit inputs; no live backtests, service startup, or trading actions.
python3 corpus/pipeline.py --oracle-only --results /path/result_a.json /path/result_b.json

# Replay current receipts without ingesting files; use a historical UTC cutoff.
python3 corpus/pipeline.py --oracle-only --results --as-of 2026-09-15

# Withdraw a result without deleting its history; old files cannot restore it.
python3 corpus/ingest_outcomes.py --withdraw RUN_ID --reason 'measurement withdrawn'

# Deliberately reinstate an earlier journal revision after investigation.
python3 corpus/ingest_outcomes.py --reinstate REVISION_NUMBER --reason 'externally rechecked'
```

`--runtime-dir` defaults to ignored `corpus/runtime/`. It contains `oracle.sqlite`,
the current `receipts.tsv`, `oracle_report.json`, `pipeline_report.json`, graph,
index, and optional brain database. Source result files are read-only. Runtime
artifacts and private inputs are not committed. An absent evaluator is an error;
the adapter never silently substitutes a pass/fail flag.

## Scope and policy

The external proposition is `passes_validation(run_id)`, not the truth of the
strategy's explanation or its source claims. agentic-qr's `oracle_receipt.py`
recomputes the receipt from a completed run's certificate. Stored receipt blobs
are ignored. It checks exact boolean types, finite numeric inputs, OOS summaries,
both null tests, resampling resolution, and the explicitly selected FDR family.
Confirmed means all declared gates pass. Refuted requires a complete audited
failure. Missing, stale, malformed or pending evidence is Unknown.

The FDR family records run identities, p-values and ordering. It cannot prove
that an operator supplied the full research search history. Consistency checks
also cannot prove the returns were held out from strategy selection. These limits
are attached to the oracle rather than hidden by the word "validated".

`claim_refs` survive as structural attribution only. The graph creates one
run-validation claim with signed evidence, and the brain indexes that claim with
its observation time. Existing corpus reference/owner scores are separate; this
bridge does not upgrade proposed reference verdicts into independent checks.

## Revisions and transport

The SQLite journal appends revisions and materializes the latest per run. Identical
replays are inert; older certificate identities cannot replace newer evidence,
even when attribution changes. A malformed replacement becomes Unknown. Missing
files abort ingestion rather than fabricating a reversal. Conflicting same-run
certificates in one batch abort the batch. Administrative withdrawal and explicit
reinstatement both retain their reasons.

Evidence becomes knowable when the local journal observes it, never from a file's
date-looking name. `--as-of` rebuilds the receipt view at a UTC cutoff. A latest
brain snapshot conservatively excludes a revised fact before its latest evidence
time; use historical journal replay to recover an earlier revision.

The Haskell transport is deliberately small and dependency-free:

```text
run_id\tverdict\tevidence_id
run-1\tconfirmed\tsha256:...
run-2\tunknown\tsha256:...
```

The displayed `\t` represents a literal tab. IDs are restricted ASCII tokens;
malformed rows or duplicate run IDs invalidate the whole snapshot. Run:

```sh
runghc -isrc tools/ExternalOracle.hs corpus/runtime/receipts.tsv RUN_ID
```

`Verify.External` uses `Verify.Oracle.confirmAll`, `Fusion.fuse`,
`Verify.Claims.genealogyOf`, and `Reward.score`. It returns JSON for the run
verdicts, grounded membership, fused count and reward. A locally supplied receipt
is a trusted artifact, not a signature or an independently fetched measurement.

## Validation and measured residuals

```sh
cabal test all
bash scripts/check-oracle-boundary.sh
ORACLE_REPO=~/projects python3 -m unittest discover -s corpus -p test_oracle_bridge.py -v
python3 -m unittest discover -s corpus -p test_grounding.py -v
python3 -m unittest discover -s ~/projects/shared/backtesting/validation -v
```

- Haskell: 899 runtime checks, including 44 new receipt/weakening checks;
  six constructor/record-update compilation failures verify admission boundaries.
- Bridge regressions cover actual Haskell invocation, real statistical-validator
  output on explicitly synthetic returns, disk replay, revisions, withdrawal,
  stale-file rejection, and source-attribution isolation.
- Real legacy audit: 32 files, 9 completed; all lacked run IDs and certificates.
  All 32 remained Unknown, with zero fused claims and zero Haskell reward.
- A planted perfect-timing synthetic series exercises positive transport. It is
  not a discovered strategy or a claim of economic efficacy.

The next research milestone is a held-out multi-hop evaluation with a modest
proposer, measured verification/repair, matched budgets and documented residuals.
