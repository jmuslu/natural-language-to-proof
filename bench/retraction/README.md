# Generated evidence withdrawal benchmark

This benchmark tests **structured admission and production Genealogy semantics**.
Its authored graph is not inferred from English, and perfect graph results are not
an English parser accuracy claim. The same synthetic scene is also rendered as a
narrative for an isolated raw-text model comparison.

The protocol distinguishes four query statuses after the stated withdrawals:

- `Conflict`: the query and its explicit negation both retain evidence. This
  flags attributed disagreement, even if one side is weak; it does not establish
  both sides or permit arbitrary conclusions.
- `Established`: the query has an all-oracle support environment and its negation
  has no surviving evidence.
- `WeakOnly`: the query has evidence, every support environment uses at least
  one weak item, and its negation has no surviving evidence. This includes reports,
  presuppositions, unconfirmed assertions, and model translations.
- `Unsupported`: no evidence supports the query; its negation may have evidence.

Strong and weak support are separately emitted alongside the status, so a weak
contradiction never erases or upgrades the strength of either side. Rules combine
all their antecedents; independent rules are alternatives. Source-dependent rules
are explicit evidence nodes included in their derivations. Cycles need an external
seed. Withdrawing a source disables every dependent evidence item. Neither repeated
hearsay nor a factive verb creates an oracle confirmation under this protocol.

Sample: 64 items, eight seeded variants in each of eight families:
alternatives, conjunctions, cycles, rule withdrawal, nested reports, factive traps,
contradictions, and translated hearsay. Templates specify expected outcomes and
source environments by independent closed-form cases; the generator does not call
Genealogy or implement another closure/antichain engine to obtain its gold labels.

The generator separates narrative input from structured graph fixtures and expected
outcomes. The model prompt consumes only context and statement; fixture and expected
fields cannot enter its prompt. The Haskell adapter consumes only the structured
fixture, and the scoring script compares its output with the separate expectations.
Raw model output belongs in the ignored results directory.

The fixed seed is `20261013`. Each family has four meaningful admission/withdrawal
regimes with both positive and negative queries, plus seeded entity/document names
and row order. These are 64 designed cases, not independent population draws.
There are 18 Established, 20 WeakOnly, 18 Unsupported and 8 Conflict outcomes.
`sample.jsonl` is generated here from authored synthetic content (66,021 bytes),
not copied from an external dataset.

Reproduce:

```bash
python3 bench/retraction/generate.py --seed 20261013
cabal build nl2proof-retraction-bench
RETRACTION_BENCH_BIN="$(cabal list-bin nl2proof-retraction-bench)" python3 -m unittest discover -s bench/retraction -p 'test_*.py'
python3 bench/retraction/evaluate_graph.py --binary "$(cabal list-bin nl2proof-retraction-bench)"
python3 bench/retraction/score.py bench/retraction/results/graph.jsonl
```

The no-cabal adapter build is `ghc -O1 -isrc tools/RetractionBench.hs -o build/retraction-bench`
(create the output directory first). The executable accepts NDJSON objects with
only `id` and `fixture`. Its output never reads the expected label. Source and class
sets remain correlated within each minimal support environment. The fixture oracle
is an explicitly authored simulation, not an external real-world verification.

The existing isolated model runner can collect the raw baseline:

```bash
python3 bench/common/run_codex.py retraction gpt-5.5 low 64 4
python3 bench/retraction/score.py bench/retraction/results/results_gpt-5.5__low.jsonl
```

Use this local scorer: the older shared lenient parser recognizes only truth labels.
The strict parser requires exactly one allowed label after ordinary markup trimming;
the lenient parser accepts case changes and explicit answer markers, rejecting
ambiguous same-segment labels. The scorer re-parses `raw`, reports invalid/missing
answers through coverage, and sums numeric usage fields. Raw outputs stay ignored.

Results (2026-10-14): **64/64 graph labels and 64/64 exact support records**,
8/8 in every family. The subprocess evaluation took 0.071 seconds on the shared
run host. Five tests pass: seeded/family generation, prompt gold isolation, all
independent expected records versus production, malformed-admission rejection, and
four-label parsing.

The isolated `gpt-5.5 / low` raw-text baseline scores **63/64** under both strict
and lenient scoring, with all 64 answers valid and no tools, errors, or retries.
Its sole error is `retraction-20261013-factive-07`: `WeakOnly` instead of `Conflict`.
It scores 7/8 on factive traps and 8/8 in each other family. The recorded total usage
is 925,514 input tokens (876,544 cached) and 3,360 output tokens (2,901 reasoning);
cached/reasoning counts are subsets, not additional tokens. The graph advantage
is one designed case, which does not establish a broad statistical improvement.
These results do not measure CCG parsing, broad language understanding, or
calibration of numerical confidence.
