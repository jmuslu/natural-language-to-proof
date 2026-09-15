# Current results and remaining work

Updated 2026-09-15. This is the status summary; commands and detailed evidence
belong in the linked component guides. **Checked** means an executable contract
or regression passed. **Measured** names an actual experiment and its scope.
**Historical** means retained earlier measurements, not rerun in this checkpoint.
An implementation test does not by itself establish reasoning or market efficacy.

## Financial target

The intended outcome is inductive alpha research: start from participant incentives
or constraints, propose links through positioning and order flow to a conditional
price response, and test a signal with explicit timing and costs. The system must
compose uncertain links, seek discriminating measurements, and reuse failed tests
to refine conditional hypotheses. The original private Futures-Reversal writeup
is the concrete starting mechanism; generic daily-price baselines and synthetic
proof tasks establish supporting behavior, not completion of that objective.

## Connected system

| Area | Current result | Evidence / remaining boundary |
|---|---|---|
| Run oracle → journal → Haskell → graph/brain | **Checked.** Certificates recomputed, revisions journaled, run-scoped graph entries indexed, Haskell confirmation/fusion/reward invoked. | [ORACLE_BRIDGE.md](ORACLE_BRIDGE.md). A receipt asserts `passes_validation(run_id)`; source references remain attribution. |
| Retraction and history | **Checked.** Exact support differences, inert duplicate replay, explicit reinstatement, stale-evidence rejection, UTC/as-of retrieval. | `test_oracle_bridge.py`, `test_grounding.py`, `test_temporal.py`. Historical journal replay recovers earlier evidence; latest-only snapshots cannot. |
| Haskell admission boundary | **Checked.** Private positional constructors and read-only getters prevent forging Confirmed/Fused values through construction or record updates. | 899 runtime checks across five suites; six compile-failure regressions and a positive API check. |
| Typed multi-hop proofs | **Checked.** Signed claims, exact entity bindings, conjunctions, chronological steps, bounded proof depth, unconfirmed-leaf rejection, and alternative-support withdrawal. | [REASONING.md](REASONING.md). Supplied rules are explicit assumptions; arbitrary-language extraction is separate. |
| Receipt-backed proof leaves | **Checked.** `reasoning.ledger` and the pipeline bind only run-validation facts, support scoped negative receipts, recheck revisions, and fingerprint task/rule/evidence dependencies. | Seven cross-repository regressions; rule consequences retain their assumption scope. |
| Model loop | **Measured with configuration correction.** Earlier model comparisons omitted reasoning effort and do not establish a matched-effort ceiling. Fresh explicit-medium development runs give both models four of four direct answerable proofs; scaffolding adds cost without improving that small result. | [REASONING.md](REASONING.md). Both development runs replay cleanly. A frozen full 45-world comparison is underway, including an explicit zero-model symbolic solver. |
| Retrieval evidence | **Repaired and replayed.** Direct observed receipt provenance is separate from exploratory graph scores, including historical observation cutoffs. | The actual replay has 45 nonzero graph scores and 21 directly checked run outcomes among 75 claims; none of the 54 base factual claims is directly checked. Answers report related evidence coverage without asserting entailment or calibrated confidence. |
| Uncertain research context → hypothesis | **Connected with explicit design checks.** Scoped context, signed variable paths, measurements and contrasts survive agenda conversion without new checked labels. | The initial eight semantic bundles failed operational review. One source-based Futures-Reversal pilot now preserves missing definitions, latent participant variables and absent NQ data: zero runnable contrasts and zero new checked claims. Specification consistency does not establish a mechanism. |
| Experiment selection | **Implemented and replicated under synthetic models.** Bounded information/decision-value policies, historical score provenance and binding checks. | [RESEARCH_THREADS.md](RESEARCH_THREADS.md). Two 600-replicate suites retain wrong-model losses; calibrated gains over stopping remain uncertain. Actual financial tests with missing likelihoods/costs stay unmodeled. |

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
- **Measured cached-price replay:** seven daily-price caches × three fixed
  long/cash policies produced 21 completed validation runs, all refuted under
  `passes_validation(run_id)`. The connected journal/Haskell/graph pipeline
  retained all 21 outcomes. This retrospective baseline experiment does not test
  the original NQ intraday mechanism. Protocol, full family and limitations:
  [agentic-qr report](https://github.com/aiqs-org/agentic-qr/blob/main/docs/R30_CACHED_PRICE_REPLAY.md).
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
| Online surprise and residuals | Causal predictive/posterior KL plus progressive past-state revision are implemented. The connected reconstruction freezes next-step predictions before outcomes and emits residuals before training. Twenty-two tests pass; a two-path synthetic forecast diagnostic essentially ties a historical-mean baseline. The original strategy's progressive smoother is causal; full-sequence smoothing remains retrospective. |
| Nonstationarity | First observation used once; variance/standard-deviation mismatch fixed. Separate jump-adaptive and outlier-robust options expose opposing tradeoffs. |
| Conditional discovery | An independently evaluated XOR interaction survives zero marginal effects; retain conditional search with untouched confirmation. |
| Acquisition and stopping | Explicit finite experiment models expose information-versus-decision tradeoffs and wrong-prior losses. Work caps and historical annotation checks prevent unbounded search or future scores being treated as eligible evidence. |
| Confidence and selection | Explicit numerical targets, equivalence margins and outcome-based method selection replace unsupported shortcuts. A finite noise-tolerant concept learner succeeds on two same-law replications; changed target laws still defeat its calibration. |
| Uncertainty and pooling | Two 200-replicate matrices compare matched methods. Covariance modeling repairs common-error undercoverage; heavier tails alone do not. Partial pooling helps exchangeable groups and fails a shifted subgroup. Nonlinear exact-model and simulation results expose delta-method and tail-sampling limits. |

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
