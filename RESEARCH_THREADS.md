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
python3 -m unittest discover -s corpus -p test_estimand_contracts.py -v
python3 -m unittest discover -s corpus -p test_multihop.py -v
python3 -m unittest discover -s corpus -p test_grounding.py -v
python3 -m unittest discover -s corpus -p test_uncertainty_experiments.py -v
python3 corpus/uncertainty_experiments.py --out corpus/runtime/research/uncertainty-matrix-seed9501.json
python3 corpus/uncertainty_experiments.py --seed 19501 --out corpus/runtime/research/uncertainty-matrix-seed19501.json
```

The JSON battery contains 12 cases, labels exact algebra, finite enumeration,
current-code probes, and seeded Monte Carlo separately, and never writes beliefs
or oracle receipts. Defaults: 20,000 Gaussian draws and independent 4,000-example
training/holdout interaction samples. The 77 scoped tests above pass on the development
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
| `smoothing_causality` / deterministic | Appending future observations changes historical `KL(filter‖smooth)` from `0` to `.494173`; filtering remains unchanged. New `causal_surprise_series` reports predictive/posterior state probabilities, realized `KL(posterior‖predictive)`, and negative log predictive density. Prefix tests pass. `surprise_series` remains an explicitly retrospective compatibility wrapper; `retrospective_surprise_series` names it clearly. Both passes now use log-space arithmetic. Fixed parameters must themselves be trained before the cutoff. [HMM filtering/smoothing](https://www.cs.cmu.edu/~tom/10601_sp09/lectures/Rabiner_HMM_tutorial.pdf) |
| `free_energy_and_acquisition` / exact | Bernoulli posterior `.9`, prior `.5`: forward KL `.368064`, reverse `.510826`. A 1,000-outcome state-independent experiment has entropy `6.907755`, information gain `0`; a state-revealing fair binary experiment has both `.693147`. Realized surprise is not expected experiment value. [Expected information gain](https://www.mathnet.ru/eng/mat101) |
| `free_energy_and_acquisition` / exact | For fixed data/model, `ELBO=log evidence−KL(q‖posterior)`. Optimizing `q` changes approximation gap, not model evidence. Comparing models through ELBO also compares gaps; a UCB bonus or MDL analogy does not establish this equivalence. [Variational inference](https://www.cs.columbia.edu/~blei/papers/BleiKucukelbirMcAuliffe2017.pdf) |
| `evidence_and_confidence` / code + exact | Exact duplicates remain inert; relabeling the same data increases heuristic weight `.393469→.632121`. Caller-declared tags cannot authenticate lineage or prove independence. `N(0,1)` plus estimate `10,SE=1` gives mean `5`, sd `.707107`, tanh-SNR `.9999986`: conflict does not automatically widen conjugate uncertainty. At SNR `1`, tanh `.761594` and its probability rescaling `.880797` differ from normal sign probability `.841345`. |
| `evidence_and_confidence` / code + exact | Historical necessity check accepted `0,SE=100`; its 90% interval `±164.485` cannot establish equivalence within `±.1`. Corrected necessity/null checks require `abs(effect)+z*SE < margin`; absent-specificity requires a directional upper bound below a declared tolerated edge. Missing margins remain unverified. Normal-approximation validity, preregistration and matched causal contrasts remain separate requirements. [Equivalence testing](https://pure.tue.nl/ws/portalfiles/portal/80918653/lakeequi2017.pdf) |
| `dead_marginal_interaction` / exact + independent holdout | Fair independent signs `x,z`, `y=xz+noise`: both marginal conditional means zero, interaction mean one. Train-only selection freezes `xz`; independent holdout mean `1.01567`, SE `.00789`, marginal effects `−.00577,−.02573`, permuted control `−.01537`. Dead marginals must not eliminate conditional search. This is an existence witness, not a market discovery. |
| `holdout_reuse` / exact | Even 100 independent null tests at 5% give probability `.994079` of at least one false positive. Adaptive reuse requires its own controls; retain training/confirmation separation and search records. [Adaptive data analysis](https://proceedings.neurips.cc/paper_files/paper/2015/hash/bad5f33780c42f2588878a9d07405083-Abstract.html) |
| `nonstationarity` / deterministic | Fixed/adaptive/robust ten-step MSE after persistent jump: `.257752/.000673/.358970`; after isolated outlier: `.754647/9.986321/.0000173`. New opt-in robust observation-variance inflation protects against outliers while delaying real jumps. Adaptive state-variance inflation has the opposite tradeoff. No universal winner or coverage guarantee. |
| `nonstationarity` / regression | Corrected `regime_estimand.py`: first observation used once, initial variance `R`, unavailable initial innovation `None`; optional independent mean/variance prior permits a scored first update. `R` is observation variance, `q_base` process variance. Demo now generates sd `.15` and passes `R=.0225`; historical `.15` mismatch remains in battery. Joseph covariance update, finite-input guards, prefix invariance and exact Gaussian regressions pass. |
| `repertoire_and_abstention` / deterministic | Historical `Grokker` forgot early negatives; retaining/recomputing them now makes both orders reject the negative example. Historical abstention labeled all corruption as low confidence; its adverse witness remains: 20 high-confidence errors plus 80 rejected correct answers increases error `.2→1`. Independent calibration replaces that assumption. [Selective classification](https://papers.neurips.cc/paper_files/paper/2017/hash/4a8423d5e91fda00bb7e46540e2b0cf1-Abstract.html) |
| `repertoire_and_abstention` / exact | Cheap can be right/heavy wrong; both can share a bias with zero disagreement. The selector now learns signed independently checked loss differences; test outcomes do not update the policy. [Bandit guarantees](https://doi.org/10.1023/A:1013689704352) still require stated reward assumptions. |
| `adaptive_evaluation.py` v1 baseline / independent splits | Same-law concept accuracy `1`, changed-law `.4867`. Calibration on 4,000 examples selects confidence `.8`; separate test risk `.05194` at coverage `.34175` versus all-label risk `.24825`. Reversed quality breaks it: risk `.69254` at coverage `.335`. Both noisy exact learners remain inconsistent, accuracy `.2995`; selecting better labels alone does not fix brittle induction. |
| `adaptive_evaluation.py` / independent splits | Selector train/calibration/test `6000/2000/4000`: learned mean stipulated error+cost `1.877`, never `2.4675`, always `3.17`, fixed `2.709`. Context shift reverses the benefit: learned `3.9035`, never `2.72`; error `.3645` versus `.272`. Heavy-harmful and shared-bias controls are included. Costs and channel laws are synthetic, not operational performance claims. |
| `robust_concept.py` / two fixed fresh replications | Enumerate 24,552 signed conjunctions over 20 supplied features, capped at three required/one forbidden; train on 1,500 noisy examples, select using 4,000 independent checked examples, risk-calibrate on 2,000, test on 4,000. Seeds `19501/29501`: clean/symmetric/confident-asymmetric cases recover the source law with accuracy/coverage `1/1`; exact learners under symmetric noise remain around `.29`. Irreducible 25% outcomes give accuracy `.74525/.73825` and abstain at risk cap `.1`. Changed law gives accuracy `.5295/.5175` while retaining full coverage: calibration shift still fails. Development seed `9501` informed calibration sample size and is not pristine confirmation. |

### Executed uncertainty/pooling matrix

`uncertainty_experiments.py` runs 200 independent replicates per case with fixed
method settings: six posterior cases, three transformed-latent targets, four state
paths, and two pooling populations. Seeds `9501` and fresh replication `19501`
each take about 40 seconds. Methods share observations; Student-t scale is converted
from the same declared error variance. Grid and particles approximate the same
posterior, without treating either as an oracle. Pooling hyperparameters are frozen
from 200 separate training groups; each replicate scores 12 new groups. Per-method
MSE, coverage, width, elapsed time, work counts, particle ESS and Monte Carlo errors
are retained in `corpus/runtime/research/uncertainty-matrix-seed*.json` (ignored run
artifacts, reproducible with commands above). Group/time-point dependence is kept
within replicates when estimating simulation uncertainty.

| Scoped outcome | Seed 9501 result; fresh replication where useful |
|---|---|
| Dependence versus heavier tails | Naive Gaussian coverage `.425`, Student-t `.445`; supplying the actual covariance model raises Gaussian coverage to `.925`. Fresh replicate: `.445→.970`. Wider-tailed likelihoods do not repair an omitted common error. |
| Prior/bias misspecification | Shifted latent population: Gaussian MSE `4.512`, Student-t `8.807`; both cover poorly (`.17/.15`). Under matched t4 noise their MSEs `.553/.548` are close, not evidence for a universal winner. Observation bias also leaves low coverage. |
| Numerical cost/reliability | Gaussian ~`.02s`, grid ~`.94s`, 2,048 particles ~`3s` per 200-case posterior batch. Particle/grid mean absolute point differences `.009–.056`; minimum particle ESS `2.86` exposes a numerical failure despite small average disagreement. Grid boundary mass is reported, not silently assumed negligible. |
| Nonlinear target | Square target coverage delta `.790`, exact `.965`, MC `.955`; fresh replicate `.810/.980/.980`. Methods target the same transformed latent value, never swap a mean for a median. Exp-target sample exact-model MSE `18.924±17.155` simulation SE falls to `2.167±.517` on replication; analytic expected risk is `exp(2)−exp(1.5)=2.907`. Tail-sensitive MSE needs substantially more sampling; no confident ranking from the first run. |
| Regime tradeoff with observation noise | Jump event-window MSE fixed/adaptive/robust `.26367/.02703/.37977`; isolated outlier `.12209/1.61462/.00349`. No-change whole-path MSE fixed/adaptive `.00302/.02169`: fast adaptation has a real false-reaction cost. Coverage and width differ, so narrowness alone is not calibration. |
| Partial pooling and subgroup shift | Exchangeable-group MSE no/full/partial pooling `.17031/.24242/.09953`, coverage `.951/.367/.943`, width `1.600/.462/1.212`. Shifted subgroup: partial MSE `2.836`, coverage `0`; no-pooling `.133`, coverage `.98`. Fresh partial results: exchangeable MSE `.10479`, coverage `.949`; shifted subgroup `2.073`, coverage `.02`. Benefit depends on the group model; fitting is explicit and does not bypass estimand identity. [Hierarchical modeling assumptions and limitations](https://sites.stat.columbia.edu/gelman/research/published/multi2.pdf) |

Coverage is measured over each stated generator. Nominal intervals, plug-in
simulation standard errors and per-metric Hoeffding bounds do not certify all cases
simultaneously or generalize to unmodeled populations. Empirical-Bayes intervals
approximate center uncertainty and omit uncertainty in fitted group variance.

## Complete thread inventory

**Mechanism** means implemented within its stated boundary; **prototype** means
an illustration; **refuted** applies to the strong claim, not the research topic;
**open** means specified evidence is still needed. Priorities order engineering,
not permission to explore. IDs remain stable for future changes and experiment reports.

| ID / priority | Thread and current code | Status and next falsification opportunity |
|---|---|---|
| R01 / P0 | External measurement membrane; `oracle_bridge.py`, QR `oracle_receipt.py` | **Mechanism.** Audit forged summaries, incomplete evidence, revisions, run scope. Consistent receipt does not authenticate producer/raw data. |
| R02 / P1 | Quantitative versus propositional claims; `estimand.py`, `multihop.py` | **Guard implemented.** Numerical chains require an explicit measured Quantity and matching candidate target; qualitative verdicts create no value/SE. Missing numeric data leaves exploration templates intact. Tests reject units strings and wrong targets. |
| R03 / P1 | Estimand identity; `EstimandIdentity`, `commensurable` | **Declared identity mechanism.** Observable, population, horizon, conditioning, units, basis, summary and optional intervention/comparator must match. Legacy missing identities remain constructible but cannot pool. Labels assert semantics; they do not authenticate them. Registry governance remains future work. |
| R04 / P1 | Deployment basis and portfolio value; `paired_sharpe`, `to_deployed_approx` | **Direct estimator implemented.** Retained equal-period stream gives calendar `.229416`, active `1`; nonzero idle returns change calendar to `.456937`, active stays `1`. No invented SE. Old exact conversion raises; approximation requires explicit assumptions and bounded point error. Annualization/cost/capacity need their own models. |
| R05 / P1 | Data quality/externality/lineage; `Measurement.provenance` | **Open.** Manifest datasets, spans, transforms and hashes; test vendor revisions/shared data disguised as replication. External data can remain biased. |
| R06 / P1 | Hierarchical partial pooling; `PoolingModel` | **Implemented and replicated offline.** Separate training fit improves exchangeable groups, fails a sign-flipped subgroup (matrix above). Cross-group inference is an explicit model; incompatible targets and repeated training provenance are rejected. Next group predictors, variance-parameter uncertainty and shifted-group diagnostics. |
| R07 / P1 | Nonstationary/regime quantities; `regime_estimand.py` | **Repaired and noise-tested.** Paired no-change/drift/jump/outlier cases across 200 paths and fresh seed; adaptive jump benefit trades off against no-change/outlier error. Next learning a regime/outlier selector from independent outcomes. |
| R08 / P1 | Jacobian chains/uncertainty; `compose_chain`, `uncertainty_experiments.py` | **Local-linear boundary measured.** Same-target square/exp/linear comparisons report coverage, error and cost; exact risk exposes tail-unstable Monte Carlo estimates. Next richer nonlinear/correlated models only where diagnostics justify them. |
| R09 / P1 | Spectral contractivity as robustness/truth | **Equivalence refuted.** Evaluate finite-horizon gain, chosen Lyapunov metric, additive noise, bias and coverage. No spectral gate for semantic truth. |
| R10 / P2 | MES/colimits/universal cocones; `colimit` | **Prototype metaphor.** Optional actual objects/morphisms and universal factorization tests. Universality and maximum model evidence are distinct. |
| R11 / P1 | Multiplicity/independent realization; `_summary`, `MethodClass.realized_by` | **Name-based trust removed.** Method realization names are inventory only; trust remains unknown and 100 renamed entries do not change numeric precision. Leg overlap grouping remains a declared-source heuristic; actual lineage and independently evaluated method performance remain required. |
| R12 / P0 | Least-fixed-point grounding/retraction; Python/Haskell Genealogy | **Mechanism.** Empty/cycle/alternate-support/exact-diff tests exist. Next dependent certificate/rule revisions and persistence. Logical alternate support need not be statistically independent. |
| R13 / P1 | Typed language/reasoning spine; `catTy`, `reason.py`, DRT | **Syntax mechanism; truth prototype.** Well-typed false rules, quantifier/scope changes and semantic identity checked against independent outcomes. |
| R14 / P0 | Oracle→fusion→genealogy→reward | **Narrow mechanism.** Checked proposition is `passes_validation(run_id)`. Test unsupported tokens, Unknown/Refuted fusion, replay and reward novelty; attribution grants no source-theory truth. |
| R15 / P1 | Discrete facts/graded confidence; `brain_evidence.py`, `derived_trust`, `Inf.conf` | **Direct evidence separated from exploratory scores.** Brain admits only exact observed run-receipt provenance, masks future observations, and reports retrieval coverage without answer entailment. Pending references and source judgments never supply checked labels. General confidence remains uncalibrated. |
| R16 / P1 | Matched dead ends/necessity; necessity `Leg`, ablation | **Equivalence gate implemented.** Missing margin and underpowered null fail; precise synthetic interval inside margin passes. Still require preregistration, paired removal/sham/retraining/cost/capacity/redundancy controls before a causal necessity claim. |
| R17 / P1 | Thesis specificity/negative controls; specificity `Leg` | **Directional bound implemented.** No positive effect uses an upper confidence bound below declared tolerance; no effect uses two-sided equivalence. Both differ from predicted reversal. Missing margins and underpowered negatives cannot pass. |
| R18 / P0 | Holdouts/all-holds/FDR/selection; QR validation | **Explicit-family mechanism.** Audit full attempt families, dependence, repeated looks, selection logs and untouched confirmation; local family checks cannot prove research completeness. |
| R19 / P1 | Dead marginals/interaction/residual discovery; `discover.py`, `brain_exploration.py` | **Synthetic witness and exploratory bridge.** Uncertain/refuted premises can nominate different conditional chains; scoped counterevidence is retained. Stable designs pass into QR hypotheses without any new checked claim. Semantic nomination still requires concrete observable/contrast design and independent confirmation. |
| R20 / P1 | Synthetic inference/abstraction/method classes; `multihop.py`, `discover.py` | **Prototype with corrected contracts.** 300 held-out synthetic candidates: screening precision/recall `1`, 97 coherent generated-response checks; source grouping remains one per candidate and no portfolio estimate is invented. Next hold out target laws/mechanisms; measure novelty, cost and later validation. |
| R21 / P0 | HMM surprise/residuals; `surprise.py`, `online_residual.py` | **Connected causal reconstruction tested.** Progressive lagged KL, two online ridge branches, frozen forecasts, pre-update residuals and past-event thresholds have 22 tests, including an independent probability/batch-regression reference. The original progressive smoother is causal; the full-session toy leaks. Exact historical learner settings remain unavailable. Forecasting and conditional market value need separate evaluation. |
| R22 / P1 | Free energy/model evidence/MDL | **Strong equivalence refuted.** Compare exact evidence with unequal variational gaps; any MDL link requires declared coding/model scheme. |
| R23 / P1 | Acquisition/stopping/dark-room avoidance; `where_to_explore`, agenda | **Heuristic.** Finite experiment benchmark: noise distractions, resolved questions, misspecified likelihoods, cheap/expensive actions. Compare EIG, decision improvement, cost and coverage budgets. |
| R24 / P1 | Gaussian/Student-t/particle/interval engines; `uncertainty_experiments.py` | **Matched model matrix executed.** Heavy tails, dependence, observation bias and prior shift have known latent targets. ESS/grid disagreement, interval coverage and cost are measured; Student-t fails badly under shifted prior. No engine is an answer key. |
| R25 / P1 | Adaptive selection/residual learning/UCB; `selector.py`, `metalearn.py`, `adaptive_evaluation.py` | **Fallible-outcome learning implemented/tested.** Signed checked losses and fixed acceptance rule replace assumed-correct heavy escalation. Independent same-law test benefits; shifted contexts fail (figures above). Next drift detection and randomized audit policy under real costs. |
| R26 / P1 | Grokking/noisy induction/abstention; `grok.py`, `abstain.py`, `robust_concept.py` | **Repaired and noise-tolerant class search replicated.** Two fresh seeds recover same-law concepts under noisy/confidently wrong labels; irreducible outcomes trigger abstention. Changed target laws still defeat source calibration. Scope is the supplied finite hypothesis class; next shift-aware audits and broader classes. |
| R27 / P2 | Neuromorphic/Hodgkin–Huxley/Hopf engines | **Open analogy.** Identifiable dynamical models versus HMM/simple baselines on causal holdouts. HMM state change need not be bifurcation; estimate observables before attractor/proximity claims. |
| R28 / P1 | Proposer ceiling/diversity/reasoner–coder ladder/trajectory DAG | **Experiment scheduling connected; discovery open.** One immutable request/run/protocol, crash recovery, explicit-family FDR wait and independent result checking. Loop workers now run in supervised POSIX process groups with bounded cleanup; timeouts or malformed execution reports end incomplete. Caller-crash cleanup and legacy direct entry points remain outside that guarantee. Model comparisons and explicit-effort controls are in REASONING.md. |
| R29 / P0 | Knowability/events/hindsight labels; `brain.py`, event store | **Mechanism strengthened.** Offset/date/prefix/as-of tests exist. Extend cutoffs to fitting, label availability, source revisions and selector training; publication differs from observation. |
| R30 / P0 | Financial mechanism/source fidelity; [private source](https://github.com/aiqs-org/Futures-Reversal) | **Original source located; replication incomplete.** The write-up postdates its code and requires an absent online predictor; no producing notebook or intraday sample was recovered in that repository. Keep the detailed source audit in ignored runtime storage. Reconstruct a causal residual primitive, then test the intended conditioned intraday mechanism with genuine data. Fixed daily baselines are plumbing controls; legacy figures and 32 uncertified results remain unverified. |

## Next experiments and acceptance criteria

The primary application is financial mechanism discovery: participant constraints
and incentives → positioning/flows → conditional price response → executable
signal after costs. Use the recovered private Futures-Reversal source as the
first concrete case. Preserve exploratory chains with uncertain or weak marginal
links, then test their conditional consequences; checked admission applies to
claimed conclusions, not permission to form a hypothesis. Recover the producing
notebook and suitable intraday data before claiming reproduction or new alpha.
The numerical and proof experiments below support this application.

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

### Exploration with uncertain premises

`brain_exploration.py` nominates topical semantic chains under a caller-specified
condition. Every premise retains its source, scoped check and exploratory score;
every causal link remains `proposed_unknown`. A refuted run-validation proposition
is counterevidence about that run, not a negated economic law or an admitted fact
in a proof. Link ablations, conditional interactions and negative controls remain
incomplete designs needing observables, timing, confounding assumptions, margins
and a confirmation family. No source hypothesis becomes true through nomination.

Proposal/design IDs bind the question, condition and test definitions; a separate
context hash records evidence revisions. Unknown-to-refuted updates preserve the
research question's identity while changing its counterevidence. The QR adapter
rejects promoted/tampered context and converts a selected item into a stable
proposed hypothesis without execution. Historical eligibility is applied before
nomination, and acquisition annotations are separate from evidence.

An offline conversion of the actual stored Brain produced eight exploratory
hypotheses and 40 `design_required` tests. Its 32 premise occurrences contained
eight scoped refutations and 24 unknowns, with zero confirmed premises or newly
checked claims. The Brain file stayed byte-identical. This demonstrates the
handoff of uncertain research context; it does not establish novelty, meaningful
causal links or useful alpha. Detailed context stays in ignored
`corpus/runtime/exploratory-agenda-20260915-v2/`.

### Online residual reconstruction

`replay_progressive_residual` connects a supplied fixed scalar Gaussian HMM to
the next available lagged-KL target. Three mature targets provide AR level,
difference and second difference; the caller supplies the second branch's causal
context features. The report records model identity, target lag, forecasts made
before their outcomes, and residuals before current-label updates. Single-session
replay resets the fit; this is a declared generic reconstruction, not the missing
QuantConnect learner or the private strategy's full feature/gate implementation.

```sh
PYTHONPATH=corpus python3 -m unittest test_surprise test_online_residual -q
python3 corpus/evaluate_online_residual.py --out corpus/runtime/research/online-residual-synthetic-score.json
```

Two fixed synthetic paths, seeds 20501/30501, each score 1,000 forecasts after
100 observations. Blended MSE is `.016248/.014185` nats squared; persistence
`.032725/.028700`; past mean `.016295/.014177`. The blend essentially ties the
past mean. This diagnostic does not establish forecasting superiority or alpha.
Training availability, real feature timing and the market effect of a conditional
residual remain independent questions.
