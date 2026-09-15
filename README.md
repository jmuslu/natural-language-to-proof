# Natural language to checked reasoning

This repository combines a Haskell language/proof substrate with a Python
evidence journal, retrieval system, and measured multi-hop proposer loop.
[agentic-qr](https://github.com/aiqs-org/agentic-qr) supplies the statistical
oracle and bounded model client.

The application is inductive alpha research: participant constraints and incentives
→ positioning/flows → conditional price response → a testable signal after costs.
Reliable multi-hop reasoning from a smaller proposer supports that objective.
Current experiments separate a correct answer, a valid derivation under supplied
rules, and empirical evidence. Frontier-level reasoning and financial efficacy
remain objectives to measure.

## Start here

| Need | Read |
|---|---|
| Current results and limitations | [PROGRESS.md](PROGRESS.md) |
| System components and interfaces | [ARCHITECTURE.md](ARCHITECTURE.md) |
| Run receipts, history, withdrawal, replay | [ORACLE_BRIDGE.md](ORACLE_BRIDGE.md) |
| Multi-hop experiment protocol and results | [REASONING.md](REASONING.md) |
| Research hypotheses, counterexamples, next experiments | [RESEARCH_THREADS.md](RESEARCH_THREADS.md) |
| Corpus schemas and ingestion | [corpus/README.md](corpus/README.md) |
| Temporal semantics | [TEMPORAL.md](TEMPORAL.md) |
| Detailed language-substrate reasoning | [TRACE.md](TRACE.md) |

## What runs together

```text
agentic-qr result files → recomputed run receipts → append-only journal
                                                ├→ Haskell oracle → fusion/reward
                                                └→ graph/index → brain/retrieval
                                                                   └→ proposed research designs

bounded model client → proposed proof → typed step checker → errors/repair
                                         └→ evidence genealogy/retraction
```

The second path uses generated finite worlds with separate trusted fact receipts
and explicit rule assumptions. It exercises exact signed claims, conjunctions,
entity bindings, proof depth, abstention, and repair. Local rule tools are compared
with a separately labeled symbolic solver. Exploratory research preserves uncertain
premises and counterevidence; nomination alone does not operationalize a mechanism.
The language front end's
CCG/DRT alternatives are a separate input path; arbitrary prose-to-faithful-rule
extraction is still an integration and evaluation task.

## Run

Haskell needs GHC and Cabal, with only bundled `base` and `containers`:

```sh
cabal build all
cabal test all
bash scripts/check-oracle-boundary.sh
cabal run nl2proof-demo
```

Without Cabal, use `scripts/build.sh` or `scripts/build.ps1`; set `GHC_BIN` if GHC
is outside PATH. Their default interpreted execution avoids requiring a newly
compiled executable. Research tools read a separately supplied CCGbank corpus;
the repository contains no raw corpus data.

The receipt-only path needs Python and the updated companion checkout:

```sh
python3 corpus/pipeline.py --oracle-only --oracle-repo ~/projects
ORACLE_REPO=~/projects python3 -m unittest discover -s corpus -p test_oracle_bridge.py
PYTHONPATH=corpus python3 -m unittest discover -s corpus/reasoning
```

For the full retrieval path, use the corpus environment with its embedding and
libSQL dependencies: `corpus/.venv/bin/python corpus/pipeline.py --quick
--oracle-repo ~/projects`. Model experiments require an explicitly selected
endpoint/model; see [REASONING.md](REASONING.md). Journals, private inputs, model
responses, and transport logs belong in ignored `corpus/runtime/`.

## Evidence contract

- A model response is a proposal. Type compatibility alone does not establish
  entailment or factual truth.
- A run receipt asserts `passes_validation(run_id)` under the recorded policy.
  Source references preserve attribution; they do not inherit that verdict.
- Missing evidence is Unknown. Abstention earns no supported-answer credit.
- Confirmed and Fused Haskell values have private constructors and read-only
  accessors. Fusion accepts only confirmations obtained through the oracle.
- Genealogy uses least-fixed-point support: unsupported cycles cannot ground
  themselves, and withdrawal preserves genuinely independent alternatives.
- Observation times govern historical access. Stale files cannot reinstate
  withdrawn evidence.

Measured results live in one place, [PROGRESS.md](PROGRESS.md). Detailed research
claims carry their scope and falsification tests in
[RESEARCH_THREADS.md](RESEARCH_THREADS.md); older revisions remain in Git history.
