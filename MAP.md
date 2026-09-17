# Repo map — what each part is, and its status

Legend: `[real]` works+tested · `[synth]` mechanics on generated data only · `[island]`
real but nothing downstream consumes it · `[refuted]` the actual financial test came back
negative/biased · `[glue]` bridge (currently thin/dead-ends) · `[doc]` · ★ standout.

```
nl2proof/  —  NL → typed proof → external check → epistemic graph → fact brain
│
├─ src/NL2Proof/                         HASKELL PROOF SUBSTRATE
│  ├─ Verify/Oracle.hs        ★[real]    phantom-token truth gate: `Confirmed` unconstructable
│  │                                     except via the oracle; truth enters reward through ONE
│  │                                     compiler-enforced door → blocks reward-hacking. The best thing here.
│  ├─ Verify/{Claims,External}.hs [real] claim verdicts; 3-valued (Confirmed/Refuted/Unknown)
│  ├─ Genealogy.hs             [real]    provenance DAG; grounding = least-fixed-point (anti-self-
│  │                                     agreement); precise retraction (indep. support survives)
│  ├─ Provenance.hs            [real]    derivation tree (fold)
│  ├─ Reward.hs               [real]    vector-valued reward; *requires* a `Confirmed`
│  ├─ Semantics/Lambda.hs      [real]    e/t/→ type algebra + typeOf — the type spine
│  ├─ Syntax/ (CCG parser)  ★⌂[island]  built vs CCGbank (licensed, not committed). Historical:
│  │                                     99.9% lexicon type-cov, 99.1% held-out parse (disjoint split).
│  │                                     Strongest empirical result in the repo — wired to NOTHING downstream.
│  ├─ DRT/                     [island]  CCG derivation → discourse rep; reasoning never consumes it
│  ├─ Stage2/ (RSA,SDRT,…)     [island]  pragmatics/alternatives — exploratory
│  └─ Fusion/Fragment/Pipeline/Trace/Collapse  [glue]  substrate plumbing
│
├─ corpus/                               PYTHON: graph · brain · reasoning · uncertainty
│  ├─ reasoning/  scaffold,engine,ledger,benchmark,run  [synth]  bounded Horn proof-checker +
│  │                                     model/deterministic tool loop on GENERATED finite worlds.
│  │                                     30/30 vs a dumb exhaustive baseline 26/30 → a control, not alpha.
│  ├─ brain*.py (9 files)      [real]    libSQL vector fact-brain over the graph; honest calibration
│  │                                     null. Real corpus = 5 records (too small to be a readiness check).
│  ├─ epistemic_graph / build_graph / fit_graph  [real]  trust graph + fitted update params
│  ├─ estimand,multihop,reason,retract,grok,   [synth/  reasoning + uncertainty MECHANICS. Each
│  │  discover,surprise,regime_estimand,        island]  proves its own contract on synthetic data;
│  │  metalearn,selector,alternates,online_residual,     none run together on one real problem.
│  │  acquisition,mechanism_spec,robust_concept,
│  │  abstain,uncertainty_experiments,adaptive_evaluation
│  ├─ ingest_outcomes / oracle_bridge / reverse_propagation_demo  [glue]  reverse-prop + audited receipts
│  ├─ events/                  [real]    dated event store (bitemporal, no-lookahead)
│  ├─ fixture_futures_reversal.py  [refuted] legacy signal reconstruction; code asserts NOT grounded
│  │                                     (missing preregistered nulls + external receipts)
│  └─ pipeline.py              [glue]    orchestrator ingest→graph→brain→reasoning — stages run
│                                        side-by-side, don't yet feed each other (ingest = a printout)
│
└─ *.md   README·ARCHITECTURE·PROGRESS·REASONING·RESEARCH_THREADS·TEMPORAL·TRACE·ORACLE_BRIDGE·BRAIN  [doc]

agentic-qr/  (~/projects)  —  EXECUTION + ORACLE side
├─ shared/backtesting/        [real]     validation oracle: walk-fwd, sign-flip/random-timing nulls,
│  │                                     regime-rotation, BH-FDR — proven on SYNTHETIC ground truth
│  ├─ grounding.py            [glue]     emits the brain's grounding block (cross-checked vs colimit)
│  └─ event_study_live.py     [refuted]  7-event study; +17.5% flagged selection-biased
├─ caveman/{pipelines,quant-lib,strategy-core,tool-test,intake}  [island]  execution circles + file bus
├─ verbose/{researcher,librarian}   [island]  reasoning circles
└─ manager/ construction/ vault/ infisical/   [glue]  runtime + secrets
```

## Bottom line (the fragmentation, stated plainly)

- **One genuinely strong piece:** `Verify/Oracle.hs` — a type-level truth gate that makes
  reward-hacking impossible by construction. Real, tested, solves a problem people get wrong.
- **One strong-but-isolated result:** the CCG parser on CCGbank (99%+, held-out). Never
  consumed by anything downstream — a benchmarked island.
- **Everything else:** individually-tested mechanics on synthetic/generated data. Well-built,
  honestly scoped, but **never run together on one real hypothesis.**
- **Every real financial test so far:** refuted (21/21 cached-price replay, external) or
  selection-biased (+17.5% event study); the legacy signal asserts *ungrounded*. The pipes are
  being de-risked; the scientific claim (participant constraints → order flow → price) is unproven.
