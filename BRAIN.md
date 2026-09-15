# The Discovery Brain — design

The goal is a **brain** that natively does state-of-the-art **multi-hop reasoning with
synthetic inference** over discrete, typed, externally-grounded facts — a *discovery*
engine that can create *and* verify alpha signals of the Futures-Reversal class,
reasoning through discrete facts instead of hallucinable probabilities.

Two standing commitments frame every choice here:

- **Discovery is primary.** Falsification/red-teaming is a *light* honesty check woven
  into the mechanics, never an exhaustive audit that strangles the generative goal. A
  design (or a signal) earns trust by surviving discipline, but the discipline is a
  servant of discovery, not its master.
- **Never prune a promising corner.** A region can look dead in its low-dimensional
  marginal and be beautiful in a subspace — this is the *norm* in interaction/conditional
  structure, not the exception. The Futures-Reversal KL-predictor is the exemplar: worse
  than a naive forecast in aggregate (dead marginal), decisive in its *residual* corner.
  The exploration frontier keeps such corners alive by default; only *belief/deploy*
  gates are strict.

Engineering goes to the **brain** (`corpus/epistemic_graph.py`, `graph.json`,
`brain*.py`, `ingest_outcomes.py`). The reasoner⇄coder loop + SWE ladder (agentic-qr)
is the inherently messy execution substrate that discharges measurement leaves — keep it,
do not over-engineer it.

## The task, concretely

Reproduce — and generalize — the reasoning that lands a real signal. Futures-Reversal is
the fixture: an 8-hop chain the brain should be able to walk end-to-end.

```
seed → mechanism ⊢ entailed predictions → typed estimands → oracle measurements
     → basis coercions → grounding (colimit) → method abstraction → portfolio value
```

Its apex is grounded not by a P&L number but by a *pattern* of checked discrete facts
(edge across all holds; ablation collapses to p≈0.50; NQ +5.4 / YM −7.7; losers move
right-first; …). Negative controls the brain must **refuse** to ground: the raw-feature
ablation, the NQ-thesis applied to YM, an overfit gate that fails held-out re-measurement.

## Three brain mechanics (the engineering focus)

### 1. Reverse-propagation mechanics

How an external measurement updates belief. Today `ingest_outcomes.py` collapses a whole
certificate to `validation.passed → ±1`, edge weight 0.3 — a one-bit hole. Replace with:

- **Coproduct dispatch.** `Claim = Quantitative⟨Q⟩ | Propositional`. Quantitative claims
  carry an estimand `{value, σ, units, basis, support}`; propositional claims keep scalar
  trust. Do not force estimands onto qualitative claims.
- **Numerical update** = conjugate/robust (Student-t for small-n fat tails) update of the
  estimand's prior by the measurement likelihood — not a trust nudge. Trust becomes
  *derived* (posterior precision × prior↔measurement agreement).
- **Basis-typed quantities.** Store `sharpe[basis=deployed|calendar|portfolio_marginal,
  support=p]`, never bare `sharpe`. Cross-basis comparison requires an explicit,
  assumption-carrying coercion (`calendar → deployed` is ×1/√p *and records* it assumed
  redeployable capital). The Sharpe "0.7 vs 5" swing is a units error the type prevents.
- **Hierarchical propagation.** A measurement of a child estimand updates its shared
  genealogy parent (partial pooling), and thence siblings — the graph's least-fixed-point
  grounding given the measurements.
- **Evidence-independence accounting.** Two measurements sharing underlying data are not
  independent; down-weight by provenance overlap before both hit a shared parent. This is
  FDR lifted from selection to *evidence independence across the graph*.

### 2. Multi-hop reasoning

Typed traversal over the belief graph.

- **Typed nodes + typed edges.** Nodes carry estimands; edges carry inference-types
  (`entails`, `measures`, `coerces`, `grounds`, `abstracts`). The graph becomes a
  *reasoning* graph, not just a trust graph.
- **Traversal = typed path-finding.** A query is "find a path from hypothesis to a
  grounded conclusion where every edge type-checks." Embeddings propose *where to look*
  (soft manifold); the type-check decides *which hops are legal* (discrete skeleton).
- **Uncertainty composes along hops.** Delta-method / Jacobian for numerical hops
  (measurement, coercion); interval/credal for non-numerical hops (entailment,
  abstraction). Confidence degrades honestly with hop-count — a thin chain yields a *wide*
  posterior, not false certainty. (Contractivity of the composed map is a diagnostic, not
  a guarantee — it's exact only in the local-linear regime.)

### 3. Synthetic inference (the discovery engine)

The brain generating *new* candidate facts, not just retrieving stored ones. This is where
discovery lives.

- **Interpolate/extrapolate the smooth estimand field** where a region is well-checked
  (licensed by calibration). Propositional trust stays non-smooth (calibration-NULL kept);
  the *numerical estimand field* is where interpolation is legitimate.
- **Analogy by abstraction.** A grounded method-class (e.g. weak-predictor-residual)
  applied to a new instrument/mechanism proposes a new estimand + its entailed predictions.
- **Search conditional/interaction structure, not marginals.** Because the promising
  corners live where marginal projections are flat, synthetic inference must probe
  interactions and conditionals (the tensor's interaction terms; the KL residual =
  prediction-error conditioned on microstructure), not one-dimensional screens.
- **Everything synthesized is tagged `proposed-not-grounded`.** Synthesis *proposes*
  (questions, candidate estimands, analogies); external measurement *disposes*.

## The two gates: why anti-pruning and multiple-comparison honesty coexist

Keep **exploration** and **grounding** as separate gates:

- **Exploration is generous** — a corner is *never* pruned for looking dead in aggregate.
  It stays on the frontier as a proposal. This is safe.
- **Grounding is strict** — and, crucially, its honesty comes from checks that are
  **independent of how many corners you explored**: *held-out re-measurement* (fresh
  data/instruments the corner was not mined on), *mechanism ablation* (the edge must
  depend on its claimed mechanism), and *thesis-predicted specificity* (works where the
  mechanism says, fails where it says). Futures-Reversal mined its gates over a huge search
  yet validated this way — all-holds, cross-instrument held-out, KL ablation — none of
  which punish search breadth.

So breadth of discovery is *free*: explore infinitely many corners; a corner earns belief
only by surviving held-out + ablation + specificity. Search-size-dependent FDR applies
narrowly (within a single backtest batch, `apply_run_fdr`); the deep honesty is
search-size-*independent*. This is the reconciliation — and it is exactly the exemplar's
own method.

## The invariant (governs belief, not search)

Every *belief update* factors through an externally-checked measurement; every *hop* is
either an external check, a typed transform carrying its assumption, or an explicitly
tagged proposal; grounding is a **colimit of provenance-independent checked legs**. This
polices *belief*, never *exploration* — search roams the corners freely.

## Formal backbone (bounded)

From Memory Evolutive Systems, used as design structure, not decoration:

- **Grounding = colimit.** A mechanism claim is the colimit (universal cocone) binding the
  pattern of its checked leaf-measurements. If the pattern does not cohere, no colimit
  exists — that non-existence *is* the "the facts don't bind, the signal isn't real."
- **Robustness = the multiplicity principle.** A claim is robust to the degree it is the
  colimit of *multiple provenance-independent, non-isomorphic patterns* (all-holds AND
  cross-instrument AND ablation …). Independence must be verified, not assumed.
- **Classes = higher colimits** (invariants across trajectories); **evolution = partial
  functors** over bitemporal time. This sits on nl2proof's existing functorial spine
  (Montague semantics; `catTy`).
- **Bound:** a colimit of unchecked legs is beautiful and empty. The external-measurement
  membrane supplies every leg or the hierarchy means nothing. Do not over-formalize claims
  that have no dynamical/numerical content — that is the farmed-scalar sin in nicer dress.

## Discovery objective (approximated, not asserted)

Pick the next measurement by expected posterior-variance reduction × downstream leverage −
cost (active-inference-flavored). Keep a strong *epistemic* term so the agenda actively
seeks uncertain high-potential corners (guards the dark-room failure). Free energy is used
as an operational acquisition function, not a law. Resonance worth remembering: the
strategy's `KL(filtering ‖ smoothing)` is this same quantity one level down — act on where
the model is surprised.

## Status

- **Proven / exists:** validation oracle (walk-forward/OOS, sign-flip + random-timing +
  regime-rotation nulls, BH-FDR, calibration, export boundary) on synthetic ground truth;
  temporal no-lookahead membrane; the epistemic graph + libSQL brain (single-hop retrieval,
  trust copied verbatim, calibration-NULL); the reasoner⇄coder loop + SWE-ladder scaffold
  (message protocol, sim green).
- **Built (this pass, in `corpus/`, all self-tests green):**
  1. `estimand.py` — reverse-propagation mechanics: typed `Quantity`
     (value·σ·units·basis·support), conjugate/robust (Student-t small-n) update, basis
     coercion (calendar→deployed ÷√p with the redeployable-capital licence attached),
     evidence-independence downweighting, and grounding-as-**colimit** with multiplicity →
     a *graded* verdict + edge weight (replacing the flat ±1/0.3 hole).
  2. `multihop.py` — multi-hop reasoning (typed hops, uncertainty composing honestly,
     confidence degrading with hop-count) under the two-gate guard (exploration roams,
     belief refuses the ungrounded), plus **synthetic inference** (`propose` a new signal
     by abstraction from a `MethodClass`; method trust rises as it grounds across
     independent domains — the Multiplicity Principle one level up).
  3. `ingest_outcomes.py` — wired to grade via the colimit when a result carries a
     `grounding` block (ungrounded ⇒ *no* belief update, where the old flat 0.3 believed
     everything); legacy `passed→±1` preserved for existing results.
  4. `fixture_futures_reversal.py` — end-to-end on the real fixture: grounds NQ, refuses
     both negative controls, basis-types the Sharpe (0.70→3.26), composes honest multi-hop
     uncertainty, reverse-props a graded verdict into the graph. The **neuromorphic**
     generalization (bifurcation-proximity reversal proposed by abstraction) is
     demonstrated in `multihop.py`.
  Run: `python3 corpus/{estimand,multihop,fixture_futures_reversal}.py`,
  `python3 corpus/ingest_outcomes.py --selftest`.
  5. `alternates.py` — a REPERTOIRE of machineries per mechanic, compared fairly on the
     fixtures (no pruning): UPDATE {Gaussian | Student-t | particle | interval-credal},
     GROUND {strict-colimit | noisy-AND | quorum-hybrid}, PROPAGATE {delta | Monte-Carlo |
     interval}, PROPOSE {abstraction | composition | bifurcation-search}. Checked findings:
     Gaussian over-trusts a small-n outlier (robust methods hold; interval flags conflict);
     strict-colimit prunes a signal over one marginal leg that quorum keeps; delta misses
     a convex hop's Jensen gap; composition/bifurcation reach signals abstraction cannot.
  6. `selector.py` — the machineries used IN TANDEM, switching by situation: cheap
     machinery first, escalate to the heavy one only near a decision boundary (small-n,
     outlier, marginal leg, nonlinearity), logging cheap↔heavy divergence as the learning
     signal. **Robustness = the repertoire + adaptive selection, not one default.**
  7. `metalearn.py` — the brain LEARNS its own escalation thresholds from the divergence
     residuals (a contextual bandit with UCB). Beats the fixed hand-rule on cumulative
     regret (1.6k vs 9.0k over 12k situations) and DISCOVERS a hidden divergence corner the
     hand-rule prunes — the KL-residual principle turned reflexively on the brain.
  8. `surprise.py` — `KL(filtering ‖ smoothing)` as ONE primitive doing double duty: the
     Futures-Reversal alpha mechanism AND the brain's exploration driver (active inference)
     AND `metalearn`'s epistemic bonus. One principle, three uses.
  9. `grok.py` — **generalization, not memorization.** The brain distills the domain-
     agnostic invariant of "what makes a signal real" from grounded examples; a memorizer
     stalls at base rate on held-out while the grokker snaps to 1.00 (the memorization→
     generalization transition), recovers the exact invariant, and TRANSFERS market→
     neuromorphic (a domain it never trained on).
  10. `discover.py` — the full loop: grok the invariant → build a LEARNED method-class →
     propose & screen NOVEL signals never seen (synthetic inference; precision/recall 1.00)
     → ground the real ones via the same colimit → multi-hop to a portfolio estimate. Every
     signal novel; reached by the generalized invariant, grounded externally.
  Plus (agentic-qr) `shared/backtesting/grounding.py` — the measurement plane emits the
  `grounding` block (mechanism-ablation, all-holds Stouffer sweep, cross-sectional
  specificity, deployment/basis Sharpe) and is cross-checked against the real nl2proof
  colimit: **loop closed end-to-end across both repos.**
  11. `reason.py` — domain-general typed reasoning composition, lifting nl2proof's own
     `Ty`/`catTy`/combinator discipline (src/NL2Proof/Semantics/Lambda.hs, Syntax/Category.hs,
     CCGRules.hs) into the brain so the parser, estimands, and multi-hop inference speak ONE
     type algebra. Composition is combinator application under type unification; the type
     functor refuses ill-typed steps (soundness under the hood); confidence degrades honestly
     over hops; a grounded signal enters as a `t`-typed proposition (`from_grounding`). Shown
     identical across linguistic, abstract, and trading composition — **robustness of
     reasoning is domain-general; the trading domain is an instantiation, not the point.**
  12. `abstain.py` — the faithfulness gate: the discrete invariant stays faithful by
     REFUSING to ingest low-confidence labels (calibration-NULL / belief-gate applied to
     induction), not by softening. Under 25% flipped labels, ingest-all corrupts the
     invariant (R=∅) while abstaining keeps the exact invariant and generalizes on FEWER
     labels. **Not everything should be ingested, by design — the projection's value is its
     faithfulness.**
  Note (dropped): a portfolio-Sharpe `compose.py` was written and removed — the Sharpe
  framing was domain-overfit; composition belongs at the typed-reasoning level (`reason.py`),
  not the finance-metric level.
- **Remaining — measurement plane (agentic-qr) so REAL backtests emit a `grounding`
  block:** mechanism-ablation, all-holds/parameter-axis sweep with pooled meta-p,
  thesis-predicted cross-sectional specificity, deployment/support + basis-typed Sharpe,
  evidence-independence. Plus the estimand identity/registry, non-stationary/regime-
  conditional estimands, and calibrating the belief layer itself.
- **Left messy on purpose:** the reasoner⇄coder loop + ladder. Feature *invention* (the
  KL-residual leap) is a proposer act, not a ladder mechanic.

## Open problems (kept, not weaponized)

- **Estimand identity / registry** — the boring, highest-silent-error-risk piece; "same
  quantity?" approximated by declared units+params (topological-equivalence of portraits is
  the ideal but generally uncomputable — use finite qualitative invariants).
- **Non-stationarity** — estimands drift with regime; the honest form is conditional
  (`effect | regime`), a state-space object, hooking into the regime machinery.
- **Proposer ceiling** — the system is only as creative as its soft layer; discreteness
  buys honesty, not imagination. Feed dead-ends back to broaden proposals.
- **Prior self-confirmation** — new estimands default to weak priors; calibrate the belief
  layer itself (reliability diagram over estimands).
- **Cost** — pay for the membrane only on claims headed for trust/deploy; explore cheaply.
