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
- **[checked]** Audited run receipts now reach `Verify.Oracle` through
  `Verify.External`, preserving Unknown, identity, and evidence hashes. Immutable
  confirmation/fusion types also close two verified forgery paths. See §4 and
  [ORACLE_BRIDGE.md](ORACLE_BRIDGE.md). This certifies the recorded run checks,
  not economic efficacy or source-claim truth.

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

## 4. Epistemic graph, fact brain, and reasoning (`corpus/`)

- **[checked] The oracle handoff executes.** `pipeline.py` reads result files,
  re-evaluates their certificates using agentic-qr's policy, journals revisions,
  rebuilds run-scoped graph/index entries, and invokes the Haskell
  oracle/confirmation/genealogy/fusion/reward path. `--oracle-only` needs no
  embedding dependencies. [ORACLE_BRIDGE.md](ORACLE_BRIDGE.md) gives commands.
- **[checked] Scope is explicit.** The verdict is about
  `passes_validation(run_id)`. Source `claim_refs` are attribution edges, not
  source-truth updates. This replaces the earlier shortcut that a
  strategy pass/failure should confirm/refute the prose it cited.
- **[checked] Replay and revision are operational.** Immutable journal history,
  duplicate suppression, stable run identities, exact support differences,
  withdrawal and explicit reinstatement. Neither stale files nor attribution
  edits can resurrect withdrawn evidence. Changed malformed files become Unknown.
- **[measured] The available legacy evidence is incomplete.** 32 result files
  (9 completed) lack run IDs and validation certificates. Replaying them yields
  32 Unknown receipts, zero fused claims and zero Haskell reward. A positive
  transport test uses an explicitly planted synthetic timing signal; it is
  integration evidence, not an economic result.
- **[checked] Grounding primitives are stricter.** `retract.py` handles
  three-valued premises and persistent verdict changes. Empty justifications
  need oracle confirmation; cycles cannot bootstrap. `estimand.py` rejects
  empty/null-only/unmeasured patterns, invalid uncertainty and unsupported
  provenance. Repeated measurements cannot tighten the same posterior; correctly
  predicted negative effects support the hypothesis. Declared provenance groups
  are not a proof of statistical independence, and their weight is stipulated.
- **[measured, prior corpus] Semantic trust imputation remains unlicensed.**
  Existing corpus calibration has skill near zero against its mean null. The
  small checked subset and learning-curve runs are diagnostic; adding receipts
  does not establish a general improvement. Proposed reference verdicts remain
  labeled proposals in the base graph.
- **[research prototypes]** `reason.py`, `abstain.py`, `multihop.py`,
  `selector.py`, `alternates.py`, `metalearn.py`, `grok.py`, `discover.py`,
  `regime_estimand.py` and `surprise.py` contain useful typed composition,
  selection, abstention, invariant and residual ideas. Their synthetic
  self-tests do not establish faithful extraction, out-of-generator transfer,
  or frontier reasoning. Several remain standalone. The earlier labels
  "loop closed", "generalization", and "proven" exceeded the evaluation.
- **[open, next research milestone]** A non-frontier proposer participating in
  an externally checked multi-hop pipeline: held-out compositions/topologies,
  direct-answer and ablation baselines, equal budgets, proof checking, repair,
  coverage/false-acceptance measures, and a versioned residual agenda. Then
  connect DRT alternatives, typed composition, oracle and vector reward to the
  same measured experiment. [BRAIN.md](BRAIN.md) records this scope.


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
