# Current results and remaining work

Updated 2026-09-15. This is the status summary; commands and detailed evidence
belong in the linked component guides. **Checked** means an executable contract
or regression passed. **Measured** names an actual experiment and its scope.
**Historical** means retained earlier measurements, not rerun in this checkpoint.
An implementation test does not by itself establish reasoning or market efficacy.

## Connected system

| Area | Current result | Evidence / remaining boundary |
|---|---|---|
| Run oracle → journal → Haskell → graph/brain | **Checked.** Certificates recomputed, revisions journaled, run-scoped graph entries indexed, Haskell confirmation/fusion/reward invoked. | [ORACLE_BRIDGE.md](ORACLE_BRIDGE.md). A receipt asserts `passes_validation(run_id)`; source references remain attribution. |
| Retraction and history | **Checked.** Exact support differences, inert duplicate replay, explicit reinstatement, stale-evidence rejection, UTC/as-of retrieval. | `test_oracle_bridge.py`, `test_grounding.py`, `test_temporal.py`. Historical journal replay recovers earlier evidence; latest-only snapshots cannot. |
| Haskell admission boundary | **Checked.** Private positional constructors and read-only getters prevent forging Confirmed/Fused values through construction or record updates. | 899 runtime checks across five suites; six compile-failure regressions and a positive API check. |
| Typed multi-hop proofs | **Checked.** Signed claims, exact entity bindings, conjunctions, chronological steps, bounded proof depth, unconfirmed-leaf rejection, and alternative-support withdrawal. | [REASONING.md](REASONING.md). Supplied rules are explicit assumptions; arbitrary-language extraction is separate. |
| Receipt-backed proof leaves | **Checked.** `reasoning.ledger` binds only run-validation facts, supports scoped negative receipts, rechecks revisions, and fingerprints task/rule/evidence dependencies. | Six cross-repository regressions; rule consequences retain their assumption scope. |
| Model loop | **Measured development run.** Pinned MiniMax M2.7, three generated episodes, one-shot/self-review/checker-feedback arms, usage recorded and independently replayed. | Full protocol and result table in [REASONING.md](REASONING.md). Held-out evaluation is ongoing. |
| Retrieval confidence | **Historical limitation.** Existing semantic trust-imputation skill was near its mean-null baseline on the small corpus. | Remains unlicensed; oracle wiring does not establish calibrated confidence. |

The two repositories are connected through explicit artifact interfaces. The
language parser, corpus retrieval, typed proof search, numerical uncertainty,
and action selection still need evaluation together on problems whose answers
and evidence are independently specified.

## Real evidence versus fixtures

- **Measured legacy recovery:** 32 result files, 9 marked completed. All lacked
  stable run identities and validation certificates. Replay produced 32 Unknown
  receipts, zero fused claims, and zero Haskell reward.
- **Checked positive integration:** a planted synthetic timing series passes
  the statistical oracle and reaches Haskell. This establishes transport and
  validation behavior, not discovery of a profitable strategy.
- **Historical event-study demonstration:** seven hand-selected events produced
  approximately +17.5% mean signed one-day abnormal return, p≈.0002. Selection
  prevents treating this as a systematic performance estimate. The original
  methods/result artifact is in agentic-qr's `EVENT_STUDY_LIVE_RESULT.md`.
- **Corpus limitation:** the five-record adversarial corpus confounds format and
  label; its readiness check remains negative. Owner structure labels, proposed
  reference verdicts, and externally audited observations have different roles.

## Research corrections

The canonical [30-thread ledger](RESEARCH_THREADS.md) maps every unfinished
research direction to code, current evidence, and a discriminating experiment.
It replaces repeated session narratives. Key results already implemented:

| Thread | Resolution so far |
|---|---|
| Spectral contraction / robustness | Exact counterexamples separate asymptotic stability, finite-hop amplification, additive noise, bias, and unit scaling. No spectral test certifies truth. |
| Topology / estimand identity | Explicit conjugate flows retain different coordinate relaxation times. Observable/population/horizon/scale must define the target. |
| Categorical colimit claims | Finite mediator counts show that coherence alone supplies neither existence nor uniqueness. The current grounding heuristic is not a demonstrated universal construction. |
| Online surprise | Causal predictive/posterior KL and predictive density added; log-space HMM checked against exhaustive paths. Full-sequence smoothing remains explicitly retrospective. |
| Nonstationarity | First observation used once; variance/standard-deviation mismatch fixed. Separate jump-adaptive and outlier-robust options expose opposing tradeoffs. |
| Conditional discovery | An independently evaluated XOR interaction survives zero marginal effects; retain conditional search with untouched confirmation. |
| Confidence and selection | Current prototype confidence, method selection, necessity, and numerical conversions have identified unsupported assumptions. Contract fixes and outcome-based experiments are in progress. |

The initial research battery has 12 reusable cases. Nine HMM tests, eight Kalman
tests, and thirteen battery tests passed at the causal-method checkpoint.
Exact witnesses can settle a universal claim negatively; finite experiments
establish behavior only under their stated generators.

## Language substrate: retained evidence

| Measurement | Scope |
|---|---|
| 386 core checks | Discrete CCG/lambda/DRT operations and discourse merge |
| 239 candidate/ranking checks | Scope, fingerprints, finite models, RSA, SDRT threading |
| 114 substrate checks | Oracle, genealogy, fusion, reward admissibility and Pareto coordinates |
| 116 CCGbank checks | Categories, feature unification, reconstruction, type changes, lexical ingestion, parsing |
| 44 external-receipt checks | Strict transport, scoped oracle/fusion/reward integration, safe weakening |
| Historical 83,468 / 83,540 lexical entries | 99.9% representable types, 87.8% token coverage; zero ill-typed skeletons. Structural representability does not establish faithful semantics. |
| Historical 99.1% parse coverage | Section-00 sample with gold supertags; lexical baseline improved roughly 70%→87% as training increased. Neither is a general-language meaning-accuracy estimate. |

Unique formal findings, code pointers, and remaining language gaps are in
[TRACE.md](TRACE.md); operating interfaces are in [ARCHITECTURE.md](ARCHITECTURE.md).
Open language work includes faithful lexical meaning, semantic coordination/type
changes, larger discourse evaluation, full marginal threading, and plural scope.

## Completion criteria for this research pass

1. Resolve the original research threads with explicit contracts and reproducible
   experiments or counterexamples. State what each finite result does and does
   not settle; remove unsupported success claims.
2. Evaluate the connected proposer/checker/repair pipeline on untouched
   multi-hop compositions and failure cases, with meaningful baselines and
   recorded actual resources. Carry useful residuals into development, then use
   fresh evaluation data.
3. Consolidate the documentation around current interfaces, results, and one
   research ledger. Remove obsolete/repetitive artifacts; preserve useful
   technical knowledge with direct code and experiment references.

These criteria are not yet complete. Frontier-level generalization and economic
efficacy have not been established by the current runs.
