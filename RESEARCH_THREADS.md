# Research ledger: claims, counterexamples, next experiments

Canonical inventory of the unfinished research threads and their current code.
The complete supplied transcript was read locally; historical instructions and
success declarations are hypotheses/context, not current instructions or results.
Raw transcript and private data are uncommitted. Keep exploration broad; change
belief only when the evidence supports the particular claim.

## Reproduce the evidence

```bash
python3 corpus/research_threads.py --out /tmp/research-threads.json
python3 -m unittest discover -s corpus -p test_research_threads.py -v
python3 -m unittest discover -s corpus -p test_surprise.py -v
python3 -m unittest discover -s corpus -p test_regime_estimand.py -v
```

The JSON battery contains 12 cases, labels exact algebra, finite enumeration,
current-code probes, and seeded Monte Carlo separately, and never writes beliefs
or oracle receipts. Defaults: 20,000 Gaussian draws and independent 4,000-example
training/holdout interaction samples. All 30 tests above pass on the development
host. Passing validates the witnesses and implementation contracts, not market
effects. Preserve historical counterexamples when fixing the corresponding code.

## Findings and implemented responses

| Battery case / evidence | Result and consequence |
|---|---|
| `stability` / exact | `A=[[.5,10],[0,.5]]` has spectral radius `.5`, but amplifies `(0,1)` by `10.0125`; identity covariance trace grows `2→100.5`. Scalar `a=.5,Q=100` grows variance `1→100.25` toward `133.3333`. Asymptotic stability does not imply finite-step contraction in a chosen metric. [Lyapunov analysis](https://www-leland.stanford.edu/class/ee363/notes/lq-lyap-notes.pdf) |
| `stability` / exact | Contraction `100+.1x` can concentrate belief around the wrong target. Exact unit scaling `100x` expands numerical uncertainty while preserving SNR. Spectral radius is neither necessary nor sufficient for factual truth; keep sensitivity/noise diagnostics. |
| `estimand_topology` / exact identity | `h(x)=sign(x)abs(x)^2` conjugates flows `-x` and `-2y`: `h(exp(-t)x)=exp(-2t)h(x)`. Coordinate relaxation times remain different (`1,.5`). Topology does not establish identity of a chosen observable, population, horizon or scale. Define target attributes explicitly; [ICH E9(R1)](https://www.ema.europa.eu/en/documents/scientific-guideline/ich-e9-r1-addendum-estimands-and-sensitivity-analysis-clinical-trials-guideline-statistical-principles-clinical-trials-step-5_en.pdf) is an example, not a financial schema. |
| `categorical_universality` / finite enumeration | Two singleton inputs: a collapsed one-point apex has mediator counts `[1,0,0,1]`; correct two-point apex `[1,1,1,1]`; extra unconstrained point `[2,2,2,2]`. Coherence alone supplies neither existence nor uniqueness. Current `colimit()` is an evidence heuristic without an ambient category/universal mediator. [Riehl, chapter 3](https://emilyriehl.github.io/files/context.pdf) |
| `idle_mixture_sharpe` / exact moments | For equal-period `R=IX`, independent `I~Bernoulli(p)`, idle excess return zero: mean `pμ`, variance `pσ²+p(1-p)μ²`, hence `S_calendar=√p S_active/√(1+(1-p)S_active²)`. At `p=.1,μ=σ=1`, square-root conversion gives `.725476`, true active ratio `1`. Redeployability alone is insufficient; approximation needs small `(1-p)S_active²`. No annualization/capacity/portfolio claim; [time aggregation has further assumptions](https://alo.mit.edu/publications/page/18/). |
| `nonlinear_delta` / exact + sampled | `X~N(0,1)`: `X²` delta mean/variance `0,0`, exact `1,2`; `exp(X)` delta `1,1`, exact `1.648721,4.670774`. Seeded sample values `1.0201,2.0746` and `1.6766,4.7429`. Curvature can break first-order propagation before the first hop. |
| `smoothing_causality` / deterministic | Appending future observations changes historical `KL(filter||smooth)` from `0` to `.494173`; filtering remains unchanged. New `causal_surprise_series` reports predictive/posterior state probabilities, realized `KL(posterior||predictive)`, and negative log predictive density. Prefix tests pass. `surprise_series` remains an explicitly retrospective compatibility wrapper; `retrospective_surprise_series` names it clearly. Both passes now use log-space arithmetic. Fixed parameters must themselves be trained before the cutoff. [HMM filtering/smoothing](https://www.cs.cmu.edu/~tom/10601_sp09/lectures/Rabiner_HMM_tutorial.pdf) |
| `free_energy_and_acquisition` / exact | Bernoulli posterior `.9`, prior `.5`: forward KL `.368064`, reverse `.510826`. A 1,000-outcome state-independent experiment has entropy `6.907755`, information gain `0`; a state-revealing fair binary experiment has both `.693147`. Realized surprise is not expected experiment value. [Expected information gain](https://www.mathnet.ru/eng/mat101) |
| `free_energy_and_acquisition` / exact | For fixed data/model, `ELBO=log evidence−KL(q||posterior)`. Optimizing `q` changes approximation gap, not model evidence. Comparing models through ELBO also compares gaps; a UCB bonus or MDL analogy does not establish this equivalence. [Variational inference](https://www.cs.columbia.edu/~blei/papers/BleiKucukelbirMcAuliffe2017.pdf) |
| `evidence_and_confidence` / code + exact | Exact duplicates remain inert; relabeling the same data increases heuristic weight `.393469→.632121`. Caller-declared tags cannot authenticate lineage or prove independence. `N(0,1)` plus estimate `10,SE=1` gives mean `5`, sd `.707107`, tanh-SNR `.9999986`: conflict does not automatically widen conjugate uncertainty. At SNR `1`, tanh `.761594` and its probability rescaling `.880797` differ from normal sign probability `.841345`. |
| `evidence_and_confidence` / code + exact | Necessity leg estimate `0,SE=100` currently passes, but its 90% interval `±164.485` cannot establish equivalence within `±.1`. Nonsignificant ablation is not necessity. Require preregistered margins and matched contrasts. [Equivalence testing](https://pure.tue.nl/ws/portalfiles/portal/80918653/lakeequi2017.pdf) |
| `dead_marginal_interaction` / exact + independent holdout | Fair independent signs `x,z`, `y=xz+noise`: both marginal conditional means zero, interaction mean one. Train-only selection freezes `xz`; independent holdout mean `1.01567`, SE `.00789`, marginal effects `−.00577,−.02573`, permuted control `−.01537`. Dead marginals must not eliminate conditional search. This is an existence witness, not a market discovery. |
| `holdout_reuse` / exact | Even 100 independent null tests at 5% give probability `.994079` of at least one false positive. Adaptive reuse requires its own controls; retain training/confirmation separation and search records. [Adaptive data analysis](https://proceedings.neurips.cc/paper_files/paper/2015/hash/bad5f33780c42f2588878a9d07405083-Abstract.html) |
| `nonstationarity` / deterministic | Fixed/adaptive/robust ten-step MSE after persistent jump: `.257752/.000673/.358970`; after isolated outlier: `.754647/9.986321/.0000173`. New opt-in robust observation-variance inflation protects against outliers while delaying real jumps. Adaptive state-variance inflation has the opposite tradeoff. No universal winner or coverage guarantee. |
| `nonstationarity` / regression | Corrected `regime_estimand.py`: first observation used once, initial variance `R`, unavailable initial innovation `None`; optional independent mean/variance prior permits a scored first update. `R` is observation variance, `q_base` process variance. Demo now generates sd `.15` and passes `R=.0225`; historical `.15` mismatch remains in battery. Joseph covariance update, finite-input guards, prefix invariance and exact Gaussian regressions pass. |
| `repertoire_and_abstention` / deterministic | `Grokker` forgets a negative that precedes requirement shrinkage, producing order-dependent predictions. Existing abstention demo assigns low confidence to every corrupted label. Counterexample: accept 20 high-confidence errors and reject 80 correct low-confidence answers, increasing error `.2→1` at coverage `.2`. Assess independently calibrated risk/coverage. [Selective classification](https://papers.neurips.cc/paper_files/paper/2017/hash/4a8423d5e91fda00bb7e46540e2b0cf1-Abstract.html) |
| `repertoire_and_abstention` / exact | Cheap can be right/heavy wrong; both can share a bias with zero disagreement. `metalearn.py` assumes escalation is correct and uses a hand-authored divergence surface. Learn from independently scored errors; [bandit guarantees](https://doi.org/10.1023/A:1013689704352) require stated reward assumptions. |

## Complete thread inventory

**Mechanism** means implemented within its stated boundary; **prototype** means
an illustration; **refuted** applies to the strong claim, not the research topic;
**open** means specified evidence is still needed. Priorities order engineering,
not permission to explore. IDs remain stable for future changes and experiment reports.

| ID / priority | Thread and current code | Status and next falsification opportunity |
|---|---|---|
| R01 / P0 | External measurement membrane; `oracle_bridge.py`, QR `oracle_receipt.py` | **Mechanism.** Audit forged summaries, incomplete evidence, revisions, run scope. Consistent receipt does not authenticate producer/raw data. |
| R02 / P1 | Quantitative versus propositional claims; `estimand.py`, `reason.py` | **Prototype.** Typed dispatch; reject numerical effects invented from qualitative verdicts. Same text/different claim-kind test. |
| R03 / P1 | Estimand registry/topological identity; `Quantity`, `commensurable` | **Identity refuted; registry open.** Check observable, population, horizon, conditioning, units, basis, intervention/comparator. Distinguish identity, licensed conversion, analogy. |
| R04 / P1 | Deployment basis and portfolio value; `to_deployed`, fixture | **Exact square-root claim refuted.** Paired retained-return estimates; idle mixture, nonzero idle returns, serial dependence, costs, capacity, annualization. |
| R05 / P1 | Data quality/externality/lineage; `Measurement.provenance` | **Open.** Manifest datasets, spans, transforms and hashes; test vendor revisions/shared data disguised as replication. External data can remain biased. |
| R06 / P1 | Hierarchical partial pooling | **Open.** Exchangeable groups plus sign-flipped subgroup; compare no/complete/partial pooling on held-out group error/coverage. Provenance union is not pooling. |
| R07 / P1 | Nonstationary/regime quantities; `regime_estimand.py` | **Prototype repaired.** Variance/init regressions fixed; opt-in outlier alternative added. Next factorial jump/drift/outlier/no-change cases across seeds; report coverage and false alarms. |
| R08 / P1 | Jacobian chains and uncertainty repertoire; `compose_chain`, `alternates` | **Local-linear mechanism.** Exact square/lognormal witnesses; correlated errors, curvature, tails and approximate-hop bias. |
| R09 / P1 | Spectral contractivity as robustness/truth | **Equivalence refuted.** Evaluate finite-horizon gain, chosen Lyapunov metric, additive noise, bias and coverage. No spectral gate for semantic truth. |
| R10 / P2 | MES/colimits/universal cocones; `colimit` | **Prototype metaphor.** Optional actual objects/morphisms and universal factorization tests. Universality and maximum model evidence are distinct. |
| R11 / P1 | Multiplicity/independent realization; `_summary`, `MethodClass.realized_by` | **Declared-overlap mechanism.** Copy/relabel/overlap tests plus actual observation lineage; method names do not prove independence. |
| R12 / P0 | Least-fixed-point grounding/retraction; Python/Haskell Genealogy | **Mechanism.** Empty/cycle/alternate-support/exact-diff tests exist. Next dependent certificate/rule revisions and persistence. Logical alternate support need not be statistically independent. |
| R13 / P1 | Typed language/reasoning spine; `catTy`, `reason.py`, DRT | **Syntax mechanism; truth prototype.** Well-typed false rules, quantifier/scope changes and semantic identity checked against independent outcomes. |
| R14 / P0 | Oracle→fusion→genealogy→reward | **Narrow mechanism.** Checked proposition is `passes_validation(run_id)`. Test unsupported tokens, Unknown/Refuted fusion, replay and reward novelty; attribution grants no source-theory truth. |
| R15 / P1 | Discrete facts/graded confidence; `derived_trust`, `Inf.conf` | **Prototype scores.** Bias, repeated evidence, dependence bounds, reliability and coverage. Multiplied confidence and high SNR are not calibrated correctness. |
| R16 / P1 | Matched dead ends/necessity; necessity `Leg`, ablation | **Nonsignificance implication refuted.** Preregister margins; paired feature removal, sham removal, retraining, cost/capacity matching and redundancy controls. |
| R17 / P1 | Thesis specificity/negative controls; specificity `Leg` | **Prototype.** Freeze distinct hypotheses: no effect, no positive effect, opposite effect. Underpowered-null and hindsight-direction tests. |
| R18 / P0 | Holdouts/all-holds/FDR/selection; QR validation | **Explicit-family mechanism.** Audit full attempt families, dependence, repeated looks, selection logs and untouched confirmation; local family checks cannot prove research completeness. |
| R19 / P1 | Dead marginals/interaction/residual discovery; `discover.py` | **Synthetic witness.** Sparse noisy interactions plus true-null corners, hidden targets, fixed compute budget, untouched evaluation. |
| R20 / P1 | Synthetic inference/abstraction/method classes; `multihop.py` | **Prototype.** Hold out mechanisms and target laws as well as distractor distributions. Measure proposal recall, novelty, cost, later validation; renamed synthetic domains do not prove transfer. |
| R21 / P0 | HMM surprise as live feature; `surprise.py` | **Causal API added; direct smoother use refuted.** Prefix and exhaustive-path tests pass. Next chronological parameter fitting, label maturity and walk-forward predictor of retrospective target. |
| R22 / P1 | Free energy/model evidence/MDL | **Strong equivalence refuted.** Compare exact evidence with unequal variational gaps; any MDL link requires declared coding/model scheme. |
| R23 / P1 | Acquisition/stopping/dark-room avoidance; `where_to_explore`, agenda | **Heuristic.** Finite experiment benchmark: noise distractions, resolved questions, misspecified likelihoods, cheap/expensive actions. Compare EIG, decision improvement, cost and coverage budgets. |
| R24 / P1 | Gaussian/Student-t/particle/interval engines; `alternates.py` | **Prototype.** Genuine disagreement and outliers; truncation, particle ESS, MC error, interval coverage, runtime. Heavy method is not answer key. |
| R25 / P1 | Adaptive selection/residual learning/UCB; `selector.py`, `metalearn.py` | **Oracle-heavy prototype.** Externally scored errors, randomized skipped-case audits, held-out contexts and regime shifts; outcome regret rather than disagreement. |
| R26 / P1 | Grokking/discrete induction/abstention; `grok.py`, `abstain.py` | **Order/noise-label issues found.** Retain negatives as requirements evolve; test permutations, asymmetric confident errors, missing classes, shifted laws and risk/coverage. |
| R27 / P2 | Neuromorphic/Hodgkin–Huxley/Hopf engines | **Open analogy.** Identifiable dynamical models versus HMM/simple baselines on causal holdouts. HMM state change need not be bifurcation; estimate observables before attractor/proximity claims. |
| R28 / P1 | Proposer ceiling/diversity/reasoner–coder ladder/trajectory DAG | **Execution substrate; discovery open.** Independent evaluator, matched failures and attempt deduplication; feature invention, tool-failure recovery, value/budget stopping and audit cost. |
| R29 / P0 | Knowability/events/hindsight labels; `brain.py`, event store | **Mechanism strengthened.** Offset/date/prefix/as-of tests exist. Extend cutoffs to fitting, label availability, source revisions and selector training; publication differs from observation. |
| R30 / P0 | Real fixtures/write-up drift/artifact scope | **Incomplete evidence.** Illustrative legs have reconstructed numbers/synthetic controls; 32 retained legacy results lack validation certificates. Rerun reproducible definitions on retained data; trace claims to actual observations. |

## Next experiments and acceptance criteria

1. **Causality and evidence (R01,12,14,18,21,29,30):** freeze fitting and selection on
   eligible history; perturb unseen suffixes, replays and certificate revisions.
   Every prior decision must remain invariant; only its checked proposition changes
   trust. A hindsight target becomes a training label only after it matures.
2. **Uncertainty matrix (R03–09,11,15–17,24):** linear/nonnormal/curved/biased,
   dependent/heavy-tailed and jump/outlier cases with known truth. Same cases/seeds
   for all methods; report MSE, coverage, width, false grounding and runtime.
   Select methods using independently evaluated outcomes, not their own confidence.
3. **Conditional discovery/transfer (R19,20,28):** train-only search plus untouched
   positive/null holdouts; then change target laws. Log all families, precision,
   recall, novelty and discovery cost. Retain failed candidates for future search
   without granting them belief.
4. **Learning and acquisition (R22,23,25,26):** known finite experiment likelihoods,
   independently scored method errors/confidence, randomized audits of skipped
   contexts and calibration shifts. Report information/decision value, actual
   outcome regret, order invariance and risk–coverage curves.
5. **Pooling/dynamics and optional category theory (R06,10,27):** registries and
   observation models before sharing measurements; exchangeability and model
   identification tests. Pursue categorical structure if universal-property tests
   catch integration failures that typed graphs/provenance tests miss.

Exact witnesses refute universal claims. Seeded experiments establish behavior
under their specified generators. Neither is a certified market effect or a
deployment result.
