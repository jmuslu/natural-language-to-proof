# Progress: what is proven, and what is open

The single organized record of results and open threads across the system, by area.
It replaces the chronological session logs (the old `FINDINGS-goal-session.md`) and the
original directive docs (the `HANDOFF-*.md`), which stated the same layer story three
times over. Design *reasoning* lives in `ARCHITECTURE.md` and `TRACE.md`; this file is
the *status*: each area lists what is externally checked (with the measured number) and
what remains genuinely open.

**Status tags** (from `TRACE.md`): **[proved]** theorem · **[checked]** asserted in a
suite · **[measured]** came out of a run · **[conjectured]** believed, unverified ·
**[structural]** the object/use is wrong and no data fixes it · **[stipulated]** chosen,
not derived.

**The one discipline, stated once for the whole system:** *nothing internal to the
system counts as evidence; only an external check does.* Typedness, provability, and
internal coherence are admission criteria and bookkeeping — never grounding. Every
result below is anchored to an external check or carries provenance to one; every
proposal (retrieval, inference, exploration) is a proposal until an external check
disposes of it.

---

## 1. Front end — substrate, ingestion, parsing (`src/NL2Proof/Syntax`, `DRT`)

- **[measured] CCGbank ingestion is sound.** 83,540 lexicon entries → **83,468 (99.9%
  of types, 87.8% of tokens) built as provenance-tagged, well-typed skeletons; 0
  ill-typed** (`ccg-lexicon-ingest`). The feature migration (`Cat` gained features +
  `catUnify`) lifted representability 66.5% → 99.9%. The remaining tail is honest: **40
  coordinator entries are rule-handled** (the tested `conj X ⇒ X[conj]` / `X X[conj] ⇒ X`
  coordination rule), **30 genuinely unrepresentable** (conj-*function* categories +
  punctuation), 2 unparseable.
- **[measured] Whole-sentence parsing works.** `CCGParse` folds application, composition,
  coordination and the learned type-change inventory into one CKY: **99.1% of a
  section-00 sample derive the gold root from gold supertags.** `CCGSupertag` (frequency
  β-beam) drives it from raw words: **~70% → 87% from-words root coverage** as training
  grows (per-word oracle 85→92%, OOV 16→4.6%).
- **[structural] The meaning skeletons are not faithful.** `skeletonFor` is an opaque
  typed constant; `templateSkeletonFor` adds canonical first-order Montague templates
  (noun/verb/adjective/determiner) — a *stipulated* default, explicitly not faithful,
  enough to make DRT non-degenerate (demonstrated: "a dog barks" → ∃x.dog(x)∧barks(x) →
  a real DRS with a referent).
- **[open]** (a) a schematic/polymorphic `conj` for the coordination-function tail;
  (b) **faithful meaning** — the genuinely hard frontier the substrate flags as not
  mechanically derivable (`typeOf` on a synthesized inhabitant is a *vacuous* gate: every
  `{e,t}` type is inhabited); an LLM-proposed `Term` path (tagged provenance, gated by
  `typeOf`) is future; (c) **DRT scale-up** — feeding *reconstructed* sentences into the
  discourse stages is blocked because the core `Cat` parser is application+composition
  only (no semantic coordination/type-change), and the CCat chart that parses real
  sentences carries no semantics; needs one or the other extended.

## 2. Oracle — the external check for the trading domain (`agentic-qr:shared/backtesting/validation`)

- **[checked] The statistical suite is complete and construction-independent:**
  walk-forward/OOS, sign-flip + random-timing nulls, regime-conditional evaluation
  (rotation null on per-regime Sharpe, labels defined independently of P&L),
  Benjamini-Hochberg run-level FDR, calibration (Brier/ECE/discrimination), and an
  export boundary that lets *only* fully-validated signals cross. 47 tests, each proven
  on synthetic ground truth first.
- **[measured, accessory] Event study runs on real data.** The dated-event → price
  pipeline (Alpaca SIP, market-adjusted, no lookahead via `disclosure_timing`) pooled
  +17.5% mean signed abnormal at 1 day (p≈0.0002) over 7 hand-picked events, reproducing
  the known BIIB/SRPT moves. **Deprioritized as an accessory** — it validates the wiring,
  not system efficacy; a systematic event universe is the only thing that would make it a
  real study, and that is not the priority.
- **[open]** routing a real oracle into `nl2proof`'s own `Verify.Oracle` seam (today the
  seam uses toy oracles; the real one lives in agentic-qr).

## 3. Reward — what may count as an RL signal (`src/NL2Proof/Reward.hs`)

- **[checked] Reward is vector-valued, not a farmed scalar.** `rewardCoordinates` /
  `dominates` / `paretoFrontier` expose corroboration and novelty as *anti-correlated,
  incomparable* axes; the choice among frontier points is deferred to an **external**
  fitness function (calibration against oracle-checked outcomes), never to `rwScore`.
- **[structural] Only two reward sources are admissible:** oracle confirmation, and
  mechanical entailment over an already-confirmed base. Well-typedness, provability in
  isolation, and internal consistency are each excluded, for reasons in `TRACE.md` P13.
- **[open]** fit the corroboration/novelty combination against held-out oracle outcomes
  — likely the *same solved shape* as the graph-trust mechanism (§4).

## 4. Epistemic graph + fact brain (`corpus/`)

- **[checked] Trust originates only from external checks.** `epistemic_graph.py`: a
  mutually-corroborating cluster with no external check stays at 0 (echo chamber → 0);
  references/owner-labels/oracle-outcomes are the only sources; trust flows both ways
  (forward corroboration; backward `implicate_from_outcome`, the same shape as
  `Genealogy`'s retraction). Layer-5 parameters are *fit against held-out external
  calibration*, never internal coherence (`fit_graph.py`: a pure echo chamber cannot be
  fit into discrimination).
- **[measured] The brain grades itself honestly.** A libSQL vector store embeds the
  graph's claims (geometry) carrying trust copied verbatim (never invented).
  `calibrate()` is the external check on the brain: leave-one-out vs a mean null →
  **skill ≈ 0, NOT licensed** — trust is *not semantically smooth* (`corr(sim,|Δtrust|)
  ≈ −0.03`), because it is earned per-claim by external check and 56% of claims are
  unchecked. So the brain **refuses to impute trust from topic**. On the checked subset a
  real signal appears (skill 0.15), and `learning_curve` shows skill rising as checks
  accumulate — evidence the loop pays off, un-fabricated.
- **[checked] The loop is closed both ways.** Retrieval / synthesis (`answer`, gated by
  query-local checked-fraction) / directed exploration (`explore_frontier`,
  `bridge_hypotheses`) → a ranked research agenda (`brain_agenda.py`) → hypotheses with
  `claim_refs` → oracle → reverse-propagation to the cited claims. `answer` returns
  `insufficiently_checked` when the relevant evidence is mostly unchecked (honest refusal
  to overclaim). `evidence_basis` (public_reference / self_reported / unquantifiable)
  routes "what to check next" to the right *kind* of check.
- **[open]** the brain is corpus-size-limited: imputation stays not-licensed until more
  claims are externally checked. The fix is *more external checks* (the frontier proposes
  them), not tuning.
- **[built] Discovery-brain mechanics (`BRAIN.md`; `corpus/estimand.py`, `multihop.py`,
  wired into `ingest_outcomes.py`).** Reverse-propagation upgraded from the one-bit hole
  (`passed→±1`, flat 0.3) to a *typed numerical* update: an estimand carries value·σ·
  units·**basis**·support; measurements update a conjugate/robust posterior; grounding is
  a **colimit** of externally-checked legs whose *multiplicity* (provenance-independent
  bindings) sets a graded verdict + edge weight — an ungrounded apex earns **no** belief.
  Adds multi-hop reasoning (uncertainty composing honestly, two-gate exploration/belief
  guard) and **synthetic inference** (propose a signal by abstraction from a method-class;
  method trust rises across independent domains). Proven end-to-end on the real
  Futures-Reversal fixture (grounds NQ, refuses the ablation & YM controls, basis-types the
  Sharpe 0.70→3.26) and generalized to a **neuromorphic** bifurcation-reversal signal.
- **[built] Repertoire + tandem selection + residual meta-learning** (`alternates.py`,
  `selector.py`, `metalearn.py`). Alternate machineries per mechanic compared fairly; a
  selector uses them in tandem (cheap→heavy escalation near a decision boundary); a bandit
  LEARNS the escalation thresholds from the divergence residuals, beating the hand-rule and
  discovering a hidden divergence corner it prunes. `surprise.py`: `KL(filter‖smooth)` as
  the shared alpha/exploration/epistemic primitive.
- **[built] Generalization, not memorization** (`grok.py`, `discover.py`). The brain
  distills the domain-agnostic invariant from grounded examples (memorizer stalls at base
  rate; grokker snaps to 1.00 and TRANSFERS market→neuromorphic), then proposes+screens
  NOVEL signals it never saw (precision/recall 1.00) and grounds the real ones. The
  measurement plane (`agentic-qr:shared/backtesting/grounding.py`) emits the `grounding`
  block and is cross-checked against the real colimit — **loop closed across both repos.**
- **[built] Non-stationary regime estimand** (`regime_estimand.py`). The estimand is a
  state tracked by a Kalman filter whose process noise inflates on surprise (the innovation
  residual = a regime break/bifurcation): at a +1.0 jump it tracks with MAE 0.07 and
  honestly widens covariance to 0.11, vs a fixed filter's confidently-wrong MAE 0.65 at
  covariance 0.012. Same residual principle as the alpha signal and the meta-learner.
  All corpus self-tests green. *Open:* estimand identity/registry; deeper compositional
  multi-hop; scaling grok invariant-induction to noisy/soft labels.

## 5. Temporal discipline (`TEMPORAL.md`, condensed)

- **[structural] No lookahead, as a first-class property.** A fact may inform a decision
  at `T` only if its `knowable_time ≤ T`; the brain's `retrieve`/`answer` take an `as_of`
  date and answer *what was knowable then*. `knowable_time` (disclosure) is distinct from
  `event_time` (when the thing held) and can precede it; `disclosure_timing` (pre-market
  vs after-close) decides which session first makes a fact actionable. This is the
  "external checks only" discipline applied to the time axis, and it is **system-general**
  (the event-study use case in §2 is just one consumer).

## 6. The adversarial epistemic corpus (`corpus/`, `corpus/README.md`)

- **[checked] Structure and verdicts are kept apart by provenance.** Owner-labeled
  structure (`records/`) asserts no verdicts; reference-backed *agent-proposed* verdicts
  (`verdicts_agent_proposed.json`, `pending_owner_confirmation`) are the bootstrap
  proposer role — an agent proposes against a cited external reference, never substitutes
  its own read of what "sounds right." `unresolved` is used honestly and often.
- **[measured] The confound is honestly still red.** With 5 records, format/length are
  confounded with the label; `confound_check.py` correctly returns NOT READY (needs ≥3
  balanced per bucket). Growing it needs *inconsistent* sources and *videos* — balanced
  collection, not padding, which would be the gaming move the project forbids.

---

## Open questions that bear on system *efficacy* (surfaced, not buried)

These are the questions that decide whether the whole thing is actually good, over and
above the per-area open items above:

- **[structural] The corpus cannot falsify several things the suite appears to check**
  (ARCHITECTURE §"Standing limitations"). Results on the nine-case fragment and the
  5-record corpus are *lower bounds / existence proofs*, not performance claims. The
  single most important lever on efficacy is **real data that can falsify** — a corpus
  that can actually discriminate, and a domain with a real oracle.
- **[structural] Faithful extraction has no oracle** (well-typed ≠ faithful; provable ≠
  faithful). This caps what Stage 1 can *claim*, independent of coverage.
- **Substrate design questions still open** (`TRACE.md` "Reviewing this document"):
  **P8.5** is the RSA operator a contraction (turns a latency knob into a stopping rule)?
  **P9.5** should content and structure ever be averaged? **P5.4** is a multiset quotient
  of DRS wanted? **P7.7** should the ranking layer represent overlapping truth sets of a
  coupled antichain explicitly? **P4.5** genealogy as a free category vs a fold.
- **`Dist` is not a monad and should be** (TRACE S8) — a real structural gap in ranking.
- **Plural predication** is a coverage gap fusion/compression will hit (ARCHITECTURE).

## Origins (replacing the handoff directives)

The work was originally framed as a stack of barriers — a language front end (CCG/DRT/
Montague), an external oracle, a vector-valued reward, a graph-trust mechanism, and an
epistemic ingestion layer — deliberately laid out as separate barriers rather than one
hard problem, so each could be attacked with its own external check. That framing is now
realized across the docs above; the original `HANDOFF-*.md` directives were removed once
their content lived here and in `ARCHITECTURE.md` / `TRACE.md`. Operating conventions
that still hold: commit/push freely in both repos; never take capital-relevant or
externally-destructive actions without confirmation; verify against real tool output
before logging; an agent proposes, external checks decide.
