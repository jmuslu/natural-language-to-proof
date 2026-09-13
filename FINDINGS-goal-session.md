# Findings log — goal session

Per-layer research log for the session driven by `HANDOFF-goal-session.md`.
Every entry is tagged with the layer it belongs to, per the handoff's own
discipline ("log which layer any given finding belongs to rather than letting
insights bleed across layers"). Status tags follow `TRACE.md`:

**[proved]** theorem of the calculus · **[checked]** asserted in a test suite ·
**[measured]** came out of a run · **[conjectured]** believed, unverified ·
**[stipulated]** chosen, not derived · **[structural]** the object or its use is
wrong, and no amount of data fixes it.

The throughline is unchanged: *a system cannot use its own internal consistency
as the check on the step that produced the thing being checked.* Each finding
notes whether the check behind it is external or internal.

---

## Layer 0 — physical ground truth

- **[checked] `~/nl2proof` is a working git checkout on `main`.** The handoff
  said a `tree` listing showed no `.git/`; that was wrong. `git rev-parse
  --is-inside-work-tree` returns true, tracking `origin/main`. (The harness
  environment banner also reports "Is a git repository: false" — also wrong;
  the direct check overrides both.) Commits work here.

  *Correction (later in the session, per the "verify against real tool output"
  convention):* an earlier revision of this line read "Nothing committed this
  session." That became stale the moment the Layer 0–2 work was committed and
  pushed. Verified against `git log`: commit **`98eb904`** ("Layer 0-2: fix
  build, survey CCGbank features, add category ingestion") is at HEAD on `main`,
  in sync with `origin/main`, and the working tree was clean after it. The
  operating conventions now grant free commit/push within `~/nl2proof`, so
  subsequent work commits directly rather than waiting.

- **[checked] No raw or bulk-derived CCGbank data is tracked** (LDC2005T13
  licensing guard). `git grep` for AUTO-format markers (`wsj_NNNN`,
  `PARSER=GOLD`, `<L …>`/`<T …>` nodes) over all tracked files returns nothing;
  the largest tracked file is the pre-existing `TRACE.md`. The survey and report
  tools reference `~/ccgbank/` by path at runtime and embed no corpus text; the
  findings log carries only aggregate counts and a handful of grammar category
  strings (e.g. `(S[dcl]\NP)/NP`), which are not corpus text. The corpus stays
  outside the repo, on purpose.

- **[measured→fixed] The repo did not build cleanly as committed.** Two cabal
  stanzas imported `Data.Map` without depending on `containers`:
  `executable nl2proof-demo` (`app/Main.hs:10`) and `test-suite nl2proof-test`
  (`test/Spec.hs:16`). `cabal build all` / `cabal test all` failed on both with
  an identical "hidden package `containers`" error. The other two suites
  (`substrate`, `stage2`) already listed `containers` and passed, so anyone
  running only those saw green while the Stage-1 front-end suite (`Spec.hs` —
  the one that checks lexicon type-coherence) *never compiled*. This is the
  silent-failure/real-failure problem living in the build config: `Spec.hs` is
  precisely the external check for Layer 1/2 lexicon work, and it was dark.
  **Fix:** added `containers` to both stanzas. All four suites now build and
  pass. This restored the verification harness before any lexicon work touched
  it.

- **[measured] CCGbank layout confirmed.** `~/ccgbank/ccgbank_1_1/data/` has
  `AUTO/` and `PARG/` (sections 00–24), plus pre-extracted `GRAMMAR/` (3,471
  attested rule instances) and `LEX/` (the extracted lexicon). The lexicon
  `LEX/CCGbank.00-24.lexicon` has **83,540 distinct (word, category) entries**,
  format `word␠category␠count␠p(cat|word)␠p(word|cat)`. This is the authoritative
  input for Layer 2 lexicon growth — no need to re-extract from AUTO.

---

## Layer 1 — the syntactic substrate

Survey of **1,148,426 leaf tokens across all 24 AUTO sections** (read-only;
`docs/ccgbank-feature-survey.py`, `docs/ccgbank-feature-survey-nodes.py`), plus
the verified classifier run over the 83,540-entry LEX file
(`tools/CCGBankReport.hs`).

- **[measured] The atoms CCGbank actually uses beyond {S, NP, N} are:** `PP`
  (46,840 leaf occ.), `conj` (24,825), and punctuation atoms (`,` `.` `:` `;`
  `LRB` `RRB`). `Cat` has a constructor for none of them.

- **[measured] Feature inventory (all syntactic/selectional):**
  - **S** carries 20 distinct features — `[dcl]` `[b]` `[to]` `[ng]` `[pss]`
    `[pt]` `[adj]` `[em]` `[qem]` `[q]` `[wq]` `[for]` `[inv]` `[bem]` `[poss]`
    `[frg]` `[intj]` `[asup]` `[as]` `[thr]`.
  - **NP** carries `[nb]` `[thr]` `[expl]`.
  - **N** carries `[num]`.
  - **PP** carries none.
  - `[conj]` is a **category-level** marker: it wraps whole complex categories
    (e.g. `(S[dcl]\NP)/NP[conj]`), not just atoms.

- **[measured] `[conj]` is always the trailing feature token.** Across the whole
  corpus, **0** categories carry a `[conj]` in non-final position. This validates
  the ingestion parser's simplifying assumption (an external, whole-corpus check
  on a design decision, not an assertion of it).

- **[conjectured→argued] No new `Ty` primitive is required.** The handoff asked
  the survey — not speculation — to decide what `Ty` must distinguish. The answer
  the data supports: **nothing new.** Every S/NP/N feature is a *selectional*
  (syntactic) distinction, not a *semantic-type* one: `S[dcl]`, `S[b]`, `S[to]`,
  `S[adj]\NP` all still denote `t` / `e→t`. Features belong on `Cat` (to gate
  composition — a modal must select `S[b]\NP`, a control verb `S[to]\NP`), and
  are **erased by `catTy`**. The two-primitive `{e, t}` calculus type-checks all
  of it. This is implemented as `ccatToTy` in the new module and **[checked]** to
  agree with the repo's existing `catTy` on every shared-fragment category.

- **[structural] `PP` is the one atom whose semantic type is not mechanically
  settled** — exactly the "needs real scrutiny per construction" case the handoff
  flagged. A case-marking `PP/NP` preposition ("of", "as") wants `PP ↦ tyGQ`
  (making the preposition `λx.x`, semantically transparent); a predicative /
  locative PP wants `PP ↦ e→t`. `ccatToTy` deliberately returns
  `Left (AmbiguousAtomType "PP")` rather than pick a silent default — the same
  discipline the handoff applies to LLM-proposed entries. `conj` likewise returns
  `Left (PolymorphicAtom "conj")` (coordination is `X\X/X`, genuinely
  polymorphic in this monomorphic calculus).

- **[measured] Parser rules use exact category equality**, not feature
  unification (`arg == c` in `fwdApp`/`bwdApp`, `CCG.hs:78,84`). Once features
  land on `Cat`, this is the real design work: a verb selecting `NP` must accept
  `NP[nb]`; underspecified `S` must unify with `S[dcl]`. Adding features naively
  and keeping `==` would *break* composition, not extend it. **Not yet done —
  see open items.**

---

## Layer 2 — the generator (lexicon growth from CCGbank)

New module **`NL2Proof.Syntax.CCGBank`** (library, `base`+`containers` only, no
new deps), unit-tested (`test/CCGBankSpec.hs`, suite `nl2proof-ccgbank-test`),
run over the real corpus (`tools/CCGBankReport.hs`, executable `ccgbank-report`).

- **[measured] Representability of the full 83,540-entry lexicon** (verified
  classifier, feature-erasing projection into the current `Cat`):

  | bucket | distinct entries | corpus tokens |
  |---|---|---|
  | representable-as-is ({S,NP,N}, no features) | 55,544 (66.5%) | 620,548 (54.0%) |
  | needs-feature (S/NP/N + features) | 21,887 (26.2%) | 342,665 (29.8%) |
  | needs-new-atom (PP / conj / punct) | 6,107 (7.3%) | 185,211 (16.1%) |
  | malformed (unparseable) | 2 (0.0%) | 2 (0.0%) |

  The three buckets are kept **visibly separate** (the handoff forbids collapsing
  them into one "N ingested" count). Highest-leverage `Cat` extension by far is
  **PP**: 6,039 of the 6,107 "needs-new-atom" entries need only the PP atom.

- **[measured] Malformation is essentially nil and correctly isolated.** Exactly
  **2** of 83,540 entries fail to parse, both `((S[b]\NP)/NP)/` (trailing slash —
  a LEX extraction artifact). This is the payoff of the parser: the
  "malformed vs. unrepresentable" ambiguity the handoff flagged is now
  *decidable* — a `Left` from `parseCCGCat` is real malformation; a successful
  parse that mentions PP/features is representable-pending-extension.

- **[structural] `typeOf` cannot gate a CCGbank entry the way it gates a
  hand-authored one — and pretending otherwise would be the trap.** For a
  hand-written entry, `typeOf` checks a *human-supplied meaning* against the
  category's demanded type and can catch a wrong meaning. CCGbank supplies a
  category but **no meaning**. Since every type in the `{e,t}` calculus is
  trivially inhabited by a bare constant, "synthesise an inhabitant and run
  `typeOf`" can *never fail* — it verifies nothing. So the real, non-vacuous
  mechanical checks for corpus ingestion are **parseability** and
  **representability** (both provided here); the faithful-*meaning* question
  stays exactly where the handoff puts LLM-proposed meanings: unverifiable
  internally, requiring provenance + external attestation, never promoted to
  "checked" by type-checking alone. The module documents this in its header so a
  later pass cannot quietly build a vacuous gate and report it as the Stage-1
  discipline.

- **Provenance note (design, not yet coded):** when these categories are turned
  into actual `Entry` values, the handoff's three-way provenance split
  (corpus-attested / required-schema-extension / LLM-proposed) maps directly onto
  the buckets above plus a future LLM source. `Entry` (`Lexicon.hs:45`) would
  gain a provenance field; corpus-attested entries carry section/frequency, and
  PP-bearing entries additionally carry the `AmbiguousAtomType` scrutiny flag so
  they never inherit a corpus-attested trust level for a type choice that was
  actually stipulated.

---

## Layer 1/2 continuation — feature unification & GRAMMAR coverage

Second pass, under the handoff's Layer 1 autonomy grant (schema calls made
directly, logged `[stipulated]` with reasoning/alternatives, kept provisional).
New module `NL2Proof.Syntax.CCGRules`; validated by `tools/CCGGrammarCoverage.hs`
against CCGbank's own `GRAMMAR` file (the external oracle for this layer).

- **[stipulated] Feature unification = underspecification-as-wildcard.** An empty
  feature list unifies with any feature (`S` ~ `S[dcl]`); two specified lists
  unify iff equal as sets. Implemented as `unifiable`/`featCompat` in
  `CCGRules`. *Reasoning:* it is the only policy under which the corpus's
  highest-frequency rules combine at all — `NP[nb]/N N → NP`, an
  `(S\NP)\(S\NP)` adverbial modifying an `S[dcl]\NP`, `S/S S[dcl] → S[dcl]`.
  *Alternatives considered:* (a) strict equality — this is what the core parser
  (`CCG.hs` `fwdApp`/`bwdApp`, `==`) does; **measured** to cover only 80.5% of
  binary rule firings vs. 99.8% for the wildcard policy, so it is demonstrably
  wrong for the corpus. (b) full feature-variable unification with binding
  propagation — deferred, not needed here because `GRAMMAR` categories are
  ground; would be required for a *generative* parser emitting novel categories.
  This choice stays `[stipulated]` and provisional; the core parser was **not**
  migrated to it this pass (see open items).

- **[measured] Combinatory-rule coverage against CCGbank GRAMMAR** (external
  check; `ccg-grammar-coverage` over `CCGbank.00-24.grammar`, 3,471 rule
  instances):
  - Binary rules: 3,241 types / 1,099,492 occurrences. Unary rules: 230 types /
    212,581 occurrences (type-changing / type-raising / `TOP` — counted
    separately, never folded into binary coverage).
  - **Unify-coverage: 2,984/3,241 binary types (92.1%), 99.8% of binary
    occurrences.** Exact-coverage: 81.9% types / 80.5% occurrences. Parse
    failures: 0.
  - Every combinator fires on real data (FwdApp 1326, PunctRight 402, CoordMark
    329, PunctLeft 301, BwdApp 231, BwdXComp 197, FwdComp 191, CoordApply 127,
    BwdComp 56, FwdXComp 15) — none is dead code.

- **[measured/structural] The ~8% uncovered binary rules are CCGbank
  type-changing rules, a genuinely distinct mechanism** — dominated by
  comma-mediated category change (`(S\NP)\(S\NP) --> , NP`;
  `(S\NP)/(S\NP) --> S[dcl]/S[dcl] ,`) and cross-category coordination
  (`S[dcl][conj] --> conj S[em]`; `S[adj]\NP[conj] --> conj PP`). These are not
  pure combinatory application/composition and were **deliberately not forced**
  into the combinator set — doing so would manufacture coverage by loosening the
  rules until they fit, exactly the self-agreement move the stack forbids.
  Handling them is a separate, explicit rule class (future work), not a tuning
  knob on the existing rules.

- **[measured→resolved] `[conj]` parser normalisation.** The first pass recorded
  a deferred limitation: the unparenthesised VP-conjunct form `S[dcl]\NP[conj]`
  was parsed with `[conj]` on the `NP` atom rather than the whole category. This
  pass removes the limitation: `parseCCGCat` now strips a trailing `[conj]` and
  re-attaches it to the root. *This is not overturning a `[stipulated]` choice* —
  it was a documented gap, now closed, justified by the **measured** invariant
  that `[conj]` never occurs non-trailing anywhere in either the LEX file (0) or
  the GRAMMAR file (0). Backward-compatible: the parenthesised form parsed the
  same way before and after; new tests pin the equivalence.

- **[stipulated, unchanged] `PP`'s semantic type remains flagged, not decided.**
  This pass did not settle it — `ccatToTy` still returns
  `Left (AmbiguousAtomType "PP")`. Recorded as still-open rather than silently
  resolved, since the coverage work above did not require a `PP` meaning (only
  its category structure).

## Layer 2 continuation — the test-case generator over real sentences

The handoff's *second* generator: real CCGbank sentences as the test corpus,
replacing combinatorial synthesis over the 9-case fixture. New library module
`NL2Proof.Syntax.CCGDeriv` parses `.auto` derivation trees (tokeniser treats
`<...>` headers as opaque, so the parenthesised predarg category inside a leaf
does not break tree bracketing) and checks, at each binary node, whether the
combinator set reproduces the gold category. Tool: `ccg-reconstruct`.

- **[measured] Whole-sentence reconstruction over real `.auto` derivations**
  (sections 00, 01, 23 — includes the standard dev/test sections):

  | section | sentences | fully reconstructed | binary-node coverage | line parse fails |
  |---|---|---|---|---|
  | 00 | 1,913 | 1,833 (95.8%) | 43,425/43,509 (99.8%) | 0 |
  | 01 | 1,982 | 1,908 (96.3%) | 44,644/44,719 (99.8%) | 0 |
  | 23 | 2,407 | 2,313 (96.1%) | 52,860/52,964 (99.8%) | 0 |

  ~96% of real sentences reconstruct end-to-end; 99.8% of binary nodes; zero
  parse failures, zero category-parse errors, zero arity anomalies. The AUTO
  parser handles every derivation in these sections.

- **[measured] The ~4% of sentences that don't fully reconstruct are exactly the
  ones containing a type-changing rule** — uncovered binary nodes concentrate on
  `(S\NP)\(S\NP)`, `(S[dcl]\S[dcl])\NP`, `S/S`, `S\S`, and the `NP[expl]`
  extraposition family, matching the GRAMMAR-level gap. This is the same
  measured limitation seen two ways (rule types, then sentence instances), not a
  new one — and it is the concrete target for the type-changing rule class in the
  open items.

- **Licensing:** the unit tests use synthetic words (`foo`/`bar`/`baz`), never
  corpus text; only the `ccg-reconstruct` tool touches real `.auto` files, at
  runtime, from `~/ccgbank/`. Nothing corpus-derived is committed.

## Layer 1/2 continuation — core parser migration & the type-change rule class

- **[checked] The core parser (`CCG.hs`) now combines by feature unification, not
  exact equality, and the fragment is unaffected.** `Cat` was extended
  *additively* — added `PP` and a `Feature` wrapper, keeping `S/NP/N/:/ /:\` so
  every existing constructor and pattern match is untouched — and `fwdApp`,
  `bwdApp`, `fwdComp`, `bwdComp`, and the parse goal filter now use `catUnify`.
  `catUnify` is underspecification-as-wildcard, so on the feature-free fragment
  it *is* structural equality: **stage-1 core stays 386/386**, all suites green.
  A new test shows the capability the migration adds — the core `fwdApp` now
  fires on a verb selecting `NP` applied to an `NP[nb]` object (rejected by `==`
  before), while `S[dcl]` still does not unify with `S[b]`. Blast radius was
  small because only `Category`, `CCG`, `Lexicon`, `Pipeline` touch `Cat` (Stage 2
  and DRT work on `Term`/`DRS`).

- **[stipulated, now empirically supported] `catTy PP = tyGQ`.** The core type
  map must be total, so `PP` is typed like an argument-position `NP` (a
  case-marking `PP/NP` preposition then types `tyGQ -> tyGQ`, a transparent
  identity function). *This is deliberately more committal than the ingestion
  classifier* (`ccatToTy` still returns `AmbiguousAtomType "PP"` so PP-bearing
  corpus entries are flagged for human review); the two coexist by design.

  **The choice was checked against the corpus, not just asserted**
  (`docs/ccgbank-pp-role-survey.py`, over the 6,039 PP-bearing lexicon entries /
  45,384 corpus tokens, 0 parse failures): weighted by frequency, PP occurs as
  **RESULT 49.2%** (a preposition's output, `PP/NP`), **ARGUMENT 48.5%** (a
  complement a head selects, `(S\NP)/PP`), **MODIFIER 2.3%** (`PP/PP`), **BARE
  0.1%** — i.e. **97.7% argument-like and 0% predicate**. This is the structural
  reason: CCGbank routes adjunct/predicative PPs through prepositions whose
  *result* is a modifier category like `(S\NP)\(S\NP)`, never through the `PP`
  atom, so `PP` is uniformly an argument constituent. That supports `tyGQ` over
  the `e->t` (predicative) alternative — which would have been a systematically
  wrong default had PP actually been predicative-dominant, but the data shows it
  is not. The 2.3% `PP/PP` modifiers type-check under `tyGQ` (`tyGQ -> tyGQ`).
  Still `[stipulated]` (a semantic-type choice is not corpus-derivable the way a
  category is), and still open to revision, but no longer a bare guess.

- **[measured] The type-changing rule class is a small, closed, learnable
  inventory that generalises — measured train/test to avoid self-agreement.**
  `CCGTypeChange` induces type-change rules (unary `N->NP`, reduced relatives,
  `TOP`; binary punctuation/coordination category changes) from training
  sentences and classifies a *held-out* section, reporting combinator
  (generalising) / type-change-known (generalising memorisation) / UNEXPLAINED
  (genuine unseen) separately. Train sections 02–21 (39,604 sentences) → held-out
  section 23 (2,407): **only 423 exact / 223 feature-erased rules induced**; on
  held-out data combinators cover **87.1%**, learned type-changes **12.9%**, and
  **UNEXPLAINED is 7 nodes exact / 1 feature-erased out of 60,717 (0.01%)**;
  sentence reconstruction **99.7% / 100.0%**. The soundness design is the point:
  inducing rules and scoring them on the *same* corpus would be circular
  (trivially ~100%); the held-out split makes the ~100% genuine generalisation,
  and the 7→1 unexplained nodes are the honest productive residue. Feature-erased
  matching generalises better with *fewer* rules (223 < 423), showing the
  inventory is even smaller than it first appears.

## Layer 3 — the oracle candidate (`~/projects/shared/backtesting/`), interrogated

Read-only survey (no changes made to `~/projects`; the operating conventions
require explicit confirmation before modifying it). The handoff said this
backtester's statistical maturity "wasn't established" — now it is, measured.

- **[measured] Most accumulated "results" are failed runs.** 32 result JSONs in
  `shared/backtesting/results/`: **23 (72%) have `status: strategy_written` with
  a `backtest_error`** — all the same failure, `No module named
  'nautilus_trader.model.data.bar'` (a packaging/version break in the
  `nautilus_trader` dependency the engine imports). Only **9 are `completed`**.

- **[measured] Even the completed runs are thin.** Of the 9 completed, 4 produced
  non-zero PnL (2465, 1836, 342, 342) and 5 are all-zeros (the strategy never
  traded). The entire metric inventory across every completed run is the
  PnL family only: `PnL (total)`, `PnL% (total)`, Max/Avg/Min Winner, Max/Avg/Min
  Loser, `Expectancy`, `Win Rate`. **No Sharpe, Sortino, drawdown, volatility, or
  trade count** — no risk adjustment of any kind.

- **[measured] None of the three required properties exists anywhere in
  `~/projects`.** A grep across all Python for walk-forward / out-of-sample /
  train-test-split / purge / embargo (property 1), Bonferroni / Benjamini-Hochberg
  / FDR / deflated-Sharpe / family-wise (property 2), and null-model /
  permutation / bootstrap / random-strategy baseline (property 3) returns **zero
  hits for all three**. Verified by reading the engine path and metrics code, not
  grep alone.

- **[structural] Therefore, per the handoff's own rule, this is not yet usable as
  the Layer 3 oracle.** "Until it demonstrably has all three properties, don't
  let anything route through it as ground truth… a weak statistical suite here is
  worse than no oracle at all." The backtester is a *scaffold that mostly does not
  run*, reporting single-split raw PnL when it does. This is exactly the
  "producing output is not the same as being correct" case the handoff predicted
  for "already exists" systems. Building the suite out (the three properties,
  plus the deterministic-prefilter and export-boundary design in Layer 3/3.5) is
  real work located in `~/projects`, so it is gated on explicit confirmation
  rather than done here.

## Layer 3.5 — regime-conditional evaluation (real edge vs. uniformly mediocre)

Built in `agentic-qr:shared/backtesting/validation/regime.py` (commit `b3954c8`),
answering a point the owner raised: a global out-of-sample pass/fail conflates two
very different failures, and the more valuable question is often *when* a
mechanism works, not a global yes/no.

- **[structural] The distinction, and the trap next to it.** A strategy can be
  *uniformly mediocre* (real "nothing here") or have *genuine edge concentrated in
  specific conditions* (a real, identifiable mechanism) — and averaged over the
  whole sample the second looks like the first. Surfacing the second is valuable.
  But operationalising "does it have a good regime" as "scan the strategy's own
  rolling Sharpe for a flattering window" is **the multiple-comparisons problem
  relocated to time-window space**: any series, including pure noise, has some
  good window, so finding one is evidence of nothing. This is the same failure the
  whole suite exists to prevent (cf. Layer 3's gate-search independence), moved to
  time.

- **[checked] The sound design.** Regime labels must be defined *independently of
  the strategy's P&L*, *before* looking at performance, and ideally
  forward-computable (filtering, not smoothing — a hindsight-only regime is not
  tradeable; this is the same alpha/gamma, filtered/smoothed distinction Layer 3.5
  of the handoff draws). `regime.py` **requires the caller to supply the labels
  and never derives them from the returns it scores** — the independence is
  structural, not a convention. Then:
  - `regime_structure_pvalue` tests whether the spread of per-regime Sharpes
    exceeds a **cyclic rotation** of the label series against the returns (which
    preserves both autocorrelations and the regime block structure, breaking only
    alignment). A high p-value is the *sharper falsification* the owner pointed
    at: uniformly mediocre across every independently-defined regime — stronger
    evidence of "nothing here" than a global null p-value.
  - `regime_conditional_report` gives per-regime null p-values with BH-FDR across
    the bins (one test per regime = multiplicity), and a verdict:
    `concentrated-edge` / `regime-dependent-but-no-clear-edge` /
    `no-regime-structure`.
  - `rolling_sharpe` is diagnostic/visualisation **only**, explicitly not a pass
    criterion.
  Tests (29 total in the suite) demonstrate the distinction directly: **on the
  same noise, a rolling scan finds a flattering window (>1.0 Sharpe) while the
  rotation-null structure test against fixed labels correctly finds no
  structure** — the trap and its remedy, side by side. Real regime-concentrated
  edge is detected as `concentrated-edge`; uniform noise as `no-regime-structure`.

- **[stipulated] Still needed for the real pipeline:** the independently-defined,
  forward-computable regime labels themselves (a VIX bucket, an HMM state, a
  macro/calendar split) are the caller's responsibility and are not yet produced
  by `strategy-core`/`quant-lib`; the module enforces that they be external but
  cannot manufacture them. Wiring a real label source in is the next step for this
  layer.

## Layer 4 — the reward manifold gap, verified against current code

- **[measured] The handoff's `rwScore` claim is accurate.** `Reward.hs:245-249`:
  `rwScore = wConfirmed·nConfirmed + wEntailed·nEntailed + wRefuted·nRefuted +
  wUncovered·nUncovered`. `rwCorroborated`/`rwNovel` are computed and stored on
  the `Reward` record (lines 240-241) but never enter the scalar; the `Weights`
  record (lines 147-164) has no corroboration/novelty field at all, and
  `wUncovered` is pinned to `0.0` (the Lagrangian-like precedent the handoff
  noted). So the two corroboration coordinates are structurally outside the
  reward, not merely zero-weighted.

- **[structural, cross-layer dependency] Layer 4's sanctioned fix is currently
  blocked on Layer 3.** The handoff's non-trap direction is "fit the combination
  function against held-out, oracle-checked outcomes" (keeping an external check
  on weight selection). That requires a trustworthy oracle — which the Layer 3
  survey above just measured as not-yet-real. So Layers 3 and 4 are coupled the
  way the handoff suspected Layers 4 and 5 are: no falsifying oracle → no
  held-out outcomes to fit against → the anti-correlated corroboration/novelty
  objectives cannot be combined by any externally-checked rule yet. Adding fixed
  positive weights now would be precisely the linear-scalarization trap. Recorded
  as blocked-with-reason, not attempted. (The anti-correlation argument itself is
  the handoff's reasoning, `[conjectured]` — it is not something the code proves.)

- **[checked] Vector-valued reward built — the non-trap step that does NOT wait on
  Layer 3.** The blocked part is only the *scalarization* (how to combine the
  anti-correlated coordinates), which needs the external fitness function. But the
  handoff's other sanctioned direction — "don't collapse to a scalar; train toward
  the frontier, defer scalarization" — needs no oracle and is now implemented:
  `Reward.rewardCoordinates` exposes the value-bearing coordinates *including*
  `rwCorroborated`/`rwNovel` (oriented higher-is-better, refuted negated),
  `dominates` is Pareto dominance, `paretoFrontier` is the non-dominated set.
  Corroboration-heavy and novelty-heavy rewards come out **incomparable** (neither
  dominates), which is the correct treatment of a genuine trade-off and exactly
  what a linear sum destroys. `rwScore` is left untouched (its suite invariants
  hold); the frontier is additive and takes **no** position on the trade-off —
  that choice stays for the external fitness function. Substrate suite +5
  (now 114) pins the incomparability, the frontier membership, and that `rwScore`
  is blind to corroboration/novelty.
- **[conjectured→supported] Layers 4 and 5 are the same problem, and both now have
  their structure with the mechanism deferred to external checks.** Layer 4's
  frontier defers "how to combine anti-correlated coordinates" to an external
  fitness function; Layer 5's epistemic graph (`corpus/epistemic_graph.py`)
  propagates trust *only* from external checks and leaves the trust-update
  *mechanism* (edge-weight vs existence vs node propagation) open. Same shape: a
  weight-free structure now, the combination/mechanism chosen later by something
  externally checked (the validation suite / calibration), never by an internal
  metric. Solving one — an externally-fit combination of trade-off signals —
  should answer both.

## Layer 3 continuation — statistical validation suite built (`~/projects` confirmation granted)

After the survey above, the owner granted confirmation to build in `~/projects`
(= `agentic-qr`). Built the statistical suite the survey found missing.

- **[checked] A dependency-free, deterministic validation suite now exists** at
  `agentic-qr:shared/backtesting/validation/` (pushed to `main`, commit
  `aeee8d5`; the repo's **first** automated test suite, 18 stdlib-`unittest`
  cases, all passing). It supplies exactly the three properties the survey found
  absent:
  - **walk-forward / out-of-sample split** — expanding-window, time-ordered, no
    lookahead; reports per-fold in-sample vs held-out Sharpe + a consistency
    verdict.
  - **null-model baseline** — sign-flip permutation test, empirical p-value with
    add-one correction, deterministic per seed.
  - **multiple-comparisons correction** — Benjamini-Hochberg FDR + Bonferroni
    across a batch (the anti-p-hacking step).
  Plus a `ValidationCertificate` export-boundary artifact (verdict + full trail:
  tests run, thresholds, per-fold Sharpes, null p-value, FDR survival).

- **[checked] The suite has real falsification power, checked on synthetic
  ground truth (it does not certify itself).** Tests confirm: a planted-drift
  signal fully validates against 15 noise decoys; a batch of 20 pure-noise
  candidates yields ≤1 FDR "discovery"; the null test flags a planted signal
  (p ≤ 0.05) and does not flag symmetric noise (p > 0.05). This is the
  external-check discipline applied to the checker itself.

- **[stipulated] Design choices, provisional.** Pure stdlib (no
  numpy/pandas/nautilus — cannot break on a missing package the way the existing
  engine does, and 72% of existing results *are* such breakages); engine-agnostic
  (consumes a returns series from any source); fixed thresholds and procedures so
  the signal-proposing agents can't shape the gate (the construction-independence
  Layer 3 requires). *Alternative considered:* fixing/using the nautilus engine
  and its heavy stack — rejected for now precisely because the suite must be
  robust and independent of that stack; wiring to real backtests is the
  integration step below, not a prerequisite for the gate's correctness.

- **[checked] End-to-end on real market data.** `bars.py` (commit `636a2f5`,
  lazy `pyarrow` import so the core stays dep-free) bridges a NautilusTrader bars
  parquet → close-to-close returns → certificate. On the sample SPY bars (62
  daily returns) the suite **correctly refuses to validate** buy-and-hold: a
  full-sample Sharpe of 0.88 looks fine but `passed: false` — it fails
  out-of-sample consistency (33% of folds positive) and the sign-flip null
  (p = 0.36). The intended falsification behaviour, demonstrated on real data:
  a strong full-sample number is not a validated edge.

- **[checked] Integration gap closed and verified against a live engine.**
  `strategy-core`'s `run_backtest` (commit `09cfd9b` in agentic-qr) now captures
  `result.stats_returns` (the engine's own Sharpe/Sortino/vol, previously
  discarded), extracts the per-period returns series via
  `engine.portfolio.analyzer.returns()` (equity-curve fallback:
  `generate_account_report(VENUE)['total']`), and runs the validation suite,
  attaching a `ValidationCertificate` to every completed backtest — all guarded
  so it cannot break the backtest. Verified by installing NautilusTrader 1.231
  and running the real `spy_daily_dip_hold_5` backtest: the loop backtest →
  returns → validated certificate runs end-to-end, and the strategy correctly
  gets `passed: false` (null p = 0.44 — edge not distinguishable from random
  timing).

  **Correction — the Sharpe agreement is a convention cross-check, not
  independent verification.** An earlier revision of this entry (and the
  agentic-qr commit `09cfd9b` message) said the suite's Sharpe
  (`0.4196274976589618`) "matches nautilus's own (`...617`) to 15 significant
  figures" as an *independent* cross-check. That over-claimed. The suite consumes
  `engine.portfolio.analyzer.returns()` — **Nautilus's own returns array** — so
  both numbers share their input; only the Sharpe *formula* is separately
  written. A probe (`scratchpad/sharpe_probe.py`) confirms the ~15.6-digit match
  (reldiff 2.65e-16, ~1 ULP) is fully explained by *same input + same convention*:
  a population-variance variant of my formula diverges from Nautilus at ~2 digits
  (reldiff 7.7e-3), and reversed summation is bit-identical (`math.fsum` is
  order-independent). So the check establishes something real but narrow — my
  Sharpe **convention** (sample n−1 std, ×√252) matches Nautilus's, and a wrong
  convention *would* have been caught — but it does **not** independently verify
  the returns computation or execution accounting, because the returns array is
  Nautilus's, not independently derived. A genuinely independent end-to-end check
  would require recomputing the strategy's returns from fills without Nautilus;
  that remains open.
- **[measured] The earlier "72% of results are import failures" is a stale
  environment artifact, not a code defect.** With `nautilus_trader` 1.231
  installed in a venv, the engine runs cleanly; the failures in `results/*.json`
  were from an environment that lacked the dependency. The engine code was fine;
  the environment wasn't. (`.venv/` is gitignored.)
- **[stipulated] Still open:** a price-level random-strategy Monte-Carlo null is
  now built (`random_strategy_pvalue`) but not yet wired into `run_backtest`'s
  certificate (it needs the market returns series alongside the strategy's); and
  `validate_batch` FDR should be applied across a *run* of many candidate
  strategies, not one at a time. Both are follow-ons, documented.

## Layer 9 — `agentic-qr` identified as `~/projects` itself

- **[measured] `~/projects` *is* `aiqs-org/agentic-qr`.** `git remote -v` in
  `~/projects` returns `git@github.com:aiqs-org/agentic-qr.git`. So the handoff's
  Layer 0/9 uncertainty ("relationship not established") resolves: the trading
  system (`strategy-core`, `quant-lib`, `shared/backtesting`) and the multi-agent
  runtime described in Layer 9 are **one repo**, not two. Its README titles it
  "Agentic QR … a multi-agent quantitative research and strategy-development
  workspace."
- **[measured] The repo had no automated tests before this session.** No test
  dirs, no `test_*.py`, no `pytest`/`unittest` imports anywhere. The Layer 3
  validation suite is the first — a small concrete step toward the "deterministic
  gate every claim passes through" that Layer 9 says `nl2proof`'s discipline
  should impose on `agentic-qr`.
- **[measured] Repo hygiene note.** `agentic-qr` `main` had diverged from a local
  working tree carrying stale/legacy uncommitted edits (owner-confirmed
  overwritable) that overlapped with newer commits already on `origin/main`
  (`quant-lib/src/agent.py`, `strategy-core/src/swe.py`). The Layer 3 commit was
  landed cleanly on top of `origin/main` without entangling that reconciliation.
  `.gitignore` validated: `results/`, `*.parquet`, `vault/`, `shared/data/`,
  secrets, and venvs are ignored (bulk data stays untracked); the validation
  module is correctly tracked.

- **[measured] Agent-boundary survey — the separation to preserve.** `agentic-qr`
  communicates over a **file-based message bus** (`/vault/bus/` with per-agent
  inbox/outbox: `strategy-core-inbox`, `quant-lib-inbox/outbox`,
  `librarian_to_researcher.json`, `researcher_out_*`, `pipeline_complete_*`).
  Agents have narrow roles: intake (discord/telegram → classifier → dispatcher),
  verbose (librarian gathers context → researcher writes notes), caveman
  (pipelines ingest data, quant-lib builds catalogs), strategy-core (swe:
  hypothesis → strategy → backtest → result). This is real, deliberate
  separation on the safe (retrieval/data/formatting) side — the "strong
  separations worth preserving" the handoff names. Keep the bus pattern.
- **[structural] Where the deterministic gate exists, and the one place it
  doesn't.** Two of the three agent-output paths now pass a real gate: (a)
  strategies (LLM-generated code) are gated by the **validation certificate**
  (out-of-sample + both nulls) before a result is trustworthy; (b) claims are
  gated by the **corpus/epistemic graph** (external-reference verdicts +
  reverse-propagated backtest outcomes). The **ungated path** is the researcher's
  free-text LLM notes → `shared/knowledge` → hypotheses: LLM-produced claims
  become load-bearing without passing a deterministic gate. Closing it is the
  Layer 9 task — route researcher-derived claims through the corpus/epistemic
  graph so they carry provenance and get checked; Thread 1's `claim_refs`
  auto-proposal (hypothesis ↔ corpus claim ids) is the first hook for that.
- **[resolved-direction] The integration is a data boundary with `nl2proof`'s
  core as the gate.** The handoff left open whether `agentic-qr` calls into
  `nl2proof` (service boundary) or replicates its discipline. The concrete shape
  that emerged this session is the former in *data* form: `agentic-qr` agents
  emit **provenance-tagged data** (backtest results with an `attribution` block +
  `claim_refs`, published `claims_index.json`), and `nl2proof`'s deterministic
  core (the validation suite, the epistemic graph's `ingest_outcomes`) consumes
  and gates it. No shared call path yet, but a real, typed data contract — the
  "route through `nl2proof` rather than re-implement in parallel" reading, now
  instantiated.

## Corpus-adversarial track (Layers 6–8) — records structured to schema v2

Companion track per `HANDOFF-corpus-adversarial.md`: a small labeled corpus
(YouTube + articles) to test whether the epistemic layer can tell
checkable-and-consistent from common-but-inconsistent, *before* it faces anything
unsupervised. The four collected records (from `files.zip`) were cross-checked
against the handoff and brought up to its requirements.

- **[measured] State found vs. requirements.** `record_schema.json` was a minimal
  stub the records had outgrown *inconsistently*: only articles carried
  `media_type`; only record 001 tracked a word count; 001 had segment+claim
  structure, 003/004 had a flat `key_claims_surface`, and **002 had no claim
  decomposition at all**; there were no `format`, `length`, `confidence`, or
  risk/quality fields anywhere. All four correctly had `verification NOT
  PERFORMED`.
- **[stipulated] Schema v2** (`corpus/record_schema.json`, applied to all four via
  the reproducible `corpus/build_records.py`) unifies video + article and adds
  exactly the fields the handoff calls for: `format` and `length` (the two
  confounds to track as fields, not verdicts); `owner_label = {class, confidence,
  is_adversarial_bucket, reasoning}` with confidence factored out of the label
  string; **`risk_quality` as an axis separate from factual consistency**;
  and `claims[]` with per-claim attribution, `domain`, `claim_type`, and null
  `checkable_reference`/`consistency_verdict` slots. Record 003 forced the
  risk_quality split — the owner disputes not the article's facts but its
  risk-adjusted quality (leverage front-loading tail risk); collapsing that into
  consistent/inconsistent would corrupt the axis the suite is meant to test.
- **[checked] Provenance layers are physically separate.** The structural layer
  (`records/`) asserts no verdicts — every claim's `consistency_verdict`/
  `checkable_reference` is null there, with `provenance` recording
  `label_source: owner` vs `structure_source: agent`.

- **[correction] The "agent never fills verdicts" framing was an over-read of the
  live-system rule — corrected.** An earlier revision of this section (and the
  corpus README) treated leaving all verdicts null as the standing discipline. The
  owner clarified: "an agent must never decide consistency" is scoped to the
  **live, autonomous** system, not bootstrapping. During development the agent
  *should* verify, as a **proposer** — check each claim against an external,
  checkable reference and propose a verdict, cited, `verdict_source:
  agent_proposed`, pending owner/external confirmation. The forbidden move (the
  agent's own "sounds right" substituting for an external check) still stands.
- **[measured] Agent-proposed verification pass** (`corpus/verify_claims.py` →
  `verdicts_agent_proposed.json`): 25 reference-backed verdicts — **16 consistent,
  3 inconsistent, 6 unresolved**. The three inconsistencies are real, checkable
  errors, not vibes: "normal junk spread 8-10%" (BofA HY OAS normal is ~3-5%),
  consumer-confidence 100 called "neutral" (it is the 1985 base value), and "Kevin
  Worsh" (misspells Warsh). `unresolved` is used honestly for specific current
  statistics, self-reported track records, and future events. Divergence worth
  noting: record 002's *individual claims* (market efficiency, null-baseline
  methodology, standard ML fixes) are individually consistent even though the
  owner's global label calls the *strategy* inconsistent — exactly why per-claim
  decomposition matters.
- **[checked] The corpus is a bidirectional epistemic graph, echo-chamber-guarded.**
  `corpus/epistemic_graph.py` + `build_graph.py` → `graph.json`: 88 nodes / 117
  edges (source/claim/domain/reference/owner_label; `outcome` reserved). Two
  handoff disciplines are enforced and self-tested: (1) **trust originates only
  from external checks** (Layer 8 Version A) — a corroborating cluster with no
  external check stays at 0 (30 of 48 claims sit at trust 0 correctly), and
  corroboration only *amplifies* externally-rooted trust; (2) **information
  propagates both ways** — forward support/corroboration, and backward
  `implicate_from_outcome` walks `feeds` edges so a checked outcome implicates the
  claims that fed it (the `Genealogy` retraction shape; the future Layer-5 trust
  *mechanism* plugs in here, kept open, not brute-forced). A sign double-negative
  was caught by sanity-checking output against a known label (source 002 read
  +1.0 while owner-firm-inconsistent) and fixed: external-check nodes carry a
  positive reliability *seed*, the edge sign carries the verdict; 002 now reads
  -0.429 (its consistent per-claim statements vs the owner's negative global
  judgment, held in visible tension rather than falsely resolved).
- **[measured] The confound is real and visible at n=4, which is itself the
  finding.** Word counts: 001=22,394, 002=1,338, 003=532, 004=453 — a 42× spread.
  The two not-inconsistent items (003 ambiguous, 004 tentatively consistent) are
  both *articles* and *short*; the inconsistent item (002) is a *video*; the
  unlabeled 001 is a huge *video*. So on this set, "article" and "short" correlate
  with "not-inconsistent" and "video" with "inconsistent/unlabeled" — any
  discrimination signal built now would key off format/length, not epistemic
  content (exactly the handoff's small-hand-picked-corpus risk). Concrete
  consequence, logged not assumed: **no discrimination result should be run until
  the corpus grows and is balanced across classes on both format and length.**
  This is the same "ablate before you trust a result" discipline as Layer 3.5,
  applied to corpus features.
- **[stipulated] Placement + a flag.** Structured records in-repo (`corpus/`);
  raw full transcripts outside at `~/corpus/raw/` (ccgbank pattern; third-party
  ToS/copyright), `corpus/raw/` gitignored. **Flag for the owner:** `files.zip` at
  the repo root (the owner's collection bundle) still contains the raw transcripts
  *inside* the repo, which contradicts that discipline. Left in place rather than
  silently removed — recommend `git rm --cached files.zip` (keeping it locally) to
  match the CCGbank-outside-the-repo pattern, but that is the owner's call since
  the handoff frames placement as an open question.
- **[checked] Reverse propagation / Layer 7 demonstrated end-to-end on the real
  corpus** (`corpus/reverse_propagation_demo.py`, synthetic attribution +
  outcome, clearly labelled). Claims 003-a/003-b (crypto return figures) are
  `unresolved` by direct checking (trust 0); once a strategy that leaned on them
  is backtested, the oracle-checked outcome propagates backward to implicate them
  — an otherwise-unverifiable claim acquires a delayed, indirect verdict. A single
  outcome is deliberately weak (implicate edge weight 0.3 → −0.3); confidence
  accrues as independent outcomes accumulate (5 → saturates), which is the
  calibration-over-many-instances signal Layer 7 asks for, not a single P&L
  verdict. **The un-built prerequisite is real attribution logging** — recording
  which claims a strategy used at generation time — which the handoff flags as
  "not free the way exact derivation dependency is in `Genealogy.hs`."

- **[checked] The live Layer 7 loop is now closed with a real oracle verdict.**
  Three pieces built: `strategy-core` records an `attribution` block
  (hypothesis + `claim_refs`) on every backtest result (agentic-qr `5a1d4b2`);
  `corpus/export_claims_index.py` → `claims_index.json` gives the 48 stable claim
  ids an upstream stage cites; `corpus/ingest_outcomes.py` reads a real result
  (attribution.claim_refs + validation certificate, passed→+1/failed→−1) and
  reverse-propagates into the graph. Verified end-to-end with a **real nautilus
  backtest** (`spy_daily_dip_hold_5`, `validation.passed=False`): its result —
  real attribution (`claim_refs` 002-b market-efficiency, 002-c null-baseline) and
  the real verdict — ingested and propagated.
- **[measured] Combination behaviour is correct: indirect signal is decisive only
  where a claim has no other external check.** The failed backtest left 002-b/002-c
  at **+0.6**, not negative, because both already carry strong external *reference*
  support (+0.9); a single failed backtest is weak contrary evidence (−0.3) that
  reduces but doesn't flip a well-established claim. An *unresolved* claim (003-a,
  trust 0) fed to a failed strategy **does** go negative — the backtest is its only
  external signal. This is the Layer 7/8 combination discipline working: reputation
  never overrides, and the noisy indirect signal is dominated by direct references
  exactly when those exist.

## Layers 4/7/8 — calibration, the shared build

- **[checked] Calibration module built** (`agentic-qr:shared/backtesting/validation/
  calibration.py`, commit `3be3cbc`). The handoff asks for one object from three
  directions — Layer 4 (fit the reward combination against held-out oracle-checked
  outcomes), Layer 7 (measure confidence by calibration, not raw P&L), Layer 8
  (Version-A entropy = calibration improving against real resolutions, not
  Version-B coherence). It is one build: given many `(confidence, externally-checked
  outcome)` pairs, is the confidence good? Provides `brier_score`,
  `reliability_bins`, `expected_calibration_error`, `discrimination` (does higher
  confidence predict a higher outcome rate), and a `calibration_report` verdict that
  separates two distinct properties — **calibrated** (low ECE) vs **informative**
  (confidence actually ranks outcomes). A system can be one without the other; the
  Version-A signal needs both. Validated on synthetic ground truth (6 tests):
  well-calibrated-informative scores well, overconfident is flagged miscalibrated,
  uninformative is flagged as noise.
- **[structural] The Version-A/B line is enforced by contract, not code.** The
  module consumes only `(confidence, outcome)` pairs and the outcome MUST be an
  external check (oracle resolution, backtest verdict) — never the system's own
  coherence. That is the caller's responsibility and is stated as the boundary; it
  is the same discipline the epistemic graph enforces structurally (trust only from
  external checks). Together: the graph produces externally-anchored confidence,
  the calibration module measures whether that confidence is any good — the two
  halves of Layer 8 Version A.
- **This is the external fitness function Layers 4 and 5 were waiting on.**
  Layer 4's Pareto frontier defers "how to combine anti-correlated coordinates";
  calibration against oracle-checked outcomes is exactly the external signal that
  can *choose* a point on that frontier (or a graph-trust parameterisation for
  Layer 5) without self-reference — once enough resolved instances exist.

## Layer 5 — the graph-trust mechanism, now fit against external calibration

- **[override] The deferral is lifted.** The mechanism was held open (don't
  brute-force which shape is correct). The owner lifted that this session — the
  scaffolding (external oracle, calibration, the graph structure) has matured
  enough — so the mechanism is now in scope. The standing rule that does *not*
  lift: a mechanism is graded only by an **external** fitness function, never the
  system's own internal metric.
- **[checked] Parameter-fit within the fixed topology, graded by held-out
  calibration** (`corpus/fit_graph.py`; `epistemic_graph.propagate` gained a
  `threshold` = inert-below-threshold gate). This is exactly the handoff's allowed
  move (search *parameter values* — `corroboration_gain`, `threshold` — within one
  fixed topology) and none of the forbidden one (searching *which mechanism shape*
  by internal coherence). The fitness is `discrimination`: among claims with a
  known external outcome, do the ones the graph trusts more resolve true more
  often? Fitting is train/test split, so the reported number is generalisation.
  Self-test: on an anchored graph the fitted parameters generalise to held-out
  claims (discrimination > 0.5); **on a pure echo chamber (no external anchoring)
  no parameter setting yields any discrimination** — the mechanism cannot be fit
  into a signal from coherence alone, which is the whole point. So Layers 4 and 5
  are now the *same solved shape*: a weight-free structure (frontier / graph)
  whose parameters are chosen by external calibration, not internal metric.

## Open items, by layer (for the next pass)

- **[Layer 5/7 — loop closed, incl. the upstream half (Thread 1)] `claim_refs`
  now auto-populate at generation time.** `corpus/propose_claim_refs.py`
  (deterministic token/domain retrieval over `claims_index.json`, selftested) is
  the proposer; agentic-qr `strategy-core._build_attribution` uses it —
  author-supplied `claim_refs` take precedence, else retrieval proposes them,
  tagged `claim_refs_source: author | agent_proposed_retrieval | none`. The
  index is published to `agentic-qr:shared/corpus/claims_index.json`. So every
  backtest now stamps retrieval-backed, author-confirmable `claim_refs`, and the
  ingestion side reverse-propagates real outcomes to them. Retrieval only (safe
  side) — a proposer, never a truth decision. The Layer-5 trust-*mechanism*
  choice stays open and not-to-be-brute-forced.
- **[Thread 2 — corpus grown to 5; confound honestly still red, not gamed]**
  Collected a real source via WebFetch (White Coat Investor, ~1100-word article,
  consistent bucket; raw provenance note outside the repo). Schema v2 gained
  `agent_label` — a reference-backed, agent-*proposed* record label distinct from
  `owner_label` (owner remains the gold standard) — so owner-unlabeled records can
  be grown and balance-measured during bootstrapping; `confound_check` uses it as
  a provisional fallback and reports the owner/agent provenance split. **Outcome
  (honest):** corpus 4→5 (pos 2 / neg 1); `confound_check` still returns NOT READY
  (needs ≥3 per bucket) and still flags format confounded (every pos is an
  article, the one neg is a video). Adding a consistent article grew pos but
  *worsened* the format skew — exactly why the remaining need is **balanced**
  collection (inconsistent sources + videos, the latter needing transcript
  tooling), not padding. Padding to pass the count would be the gaming move the
  project forbids, so the check is correctly left red.

- **[Layer 1/2] Done: core parser migrated to feature unification** (additive
  `Cat` extension + `catUnify`, fragment preserved at 386/386).
- **[Layer 2] Done (Thread 3): CCGbank → provenance-tagged lexical entries.**
  `NL2Proof.Syntax.CCGLexicon`: `Provenance` (HandWritten | CorpusAttested |
  LLMProposed), `ProvEntry`, `skeletonFor` (the canonical type-correct meaning
  skeleton `Con word (catTy cat)` — a usable placeholder of the right type,
  honestly *not* faithful predicate-argument semantics), and `ingest` →
  Built / Unrepresentable / Unparseable. `CCGBank.ccatToCat` projects into the
  feature-bearing core `Cat` (features→`Feature`, `PP`→`PP`). **[measured]** over
  the real 83,540-entry lexicon: **83,468 (99.9% types / 87.8% tokens) built as
  corpus-attested entries; 0 ill-typed skeletons**; 70 unrepresentable (conj +
  punctuation — 0.1% of types but 12.2% of tokens, i.e. few in variety, frequent
  in use); 2 unparseable. The feature migration lifted representability from 66.5%
  (bare {S,NP,N}) to 99.9%. `skeletonWellTyped` is retained as the typeOf gate but
  is *explicitly weak* (every `{e,t}` type is inhabited, so it verifies the
  synthesiser, not meaning faithfulness — the structural point logged earlier).
  Remaining: the `conj`/punctuation atoms (a coordination + punctuation rule
  class), and — for faithful (non-skeleton) meanings — the LLM-proposed path with
  its own provenance, still future. `PP`'s type stays `tyGQ` (`[stipulated]`,
  survey-supported at 97.7% argument-like).
- **[Layer 1/2] Done: type-changing rule class, measured train/test** as a
  learnable inventory (`CCGTypeChange`, `ccg-typechange-coverage`; 0.01%
  held-out residue). Remaining: fold combinators + the induced type-change
  inventory into one parser path so real sentences parse end-to-end (not just
  node-classify), and decide whether type-raising should be a generalising
  combinator rather than a memorised unary rule.
- **[Layer 2] Done: `.auto` derivation parser + reconstruction** (`CCGDeriv`,
  `ccg-reconstruct`, ~96% of real sentences). Remaining: use the reconstructed
  sentences as an actual test-case *fixture* feeding the DRT/SDRT stages, to hit
  the two known-unreachable properties a 9-case fixture can't produce.
- **[Layer 3] Statistical suite now complete end-to-end.** Built and wired:
  walk-forward/OOS, **both** nulls (sign-flip + random-timing, the latter now in
  the live certificate), regime-conditional evaluation, the single-signal
  certificate, **run-level Benjamini-Hochberg** (`apply_run_fdr`), calibration
  (`calibration.py`), and the **export boundary** (`export_boundary.py`, gated on
  full validation). `strategy-core` emits the returns series + attribution and runs
  it all per backtest. Remaining (smaller): a deterministic prefilter to narrow a
  large candidate space before the per-signal gates, and wiring `apply_run_fdr`
  into the multi-hypothesis run loop (the primitive + post-processor exist; the
  batch runner call site doesn't yet).
- **[Layer 4] Now unblockable via the Layer 3 suite, once returns flow.** The
  externally-checked fix (fit the corroboration/novelty combination against
  held-out oracle outcomes) needs oracle-checked outcomes; the validation suite +
  its `ValidationCertificate` is the mechanism that produces them, once
  `strategy-core` emits returns. Still do **not** add fixed corroboration/novelty
  weights in the interim — that remains the trap. When revisiting, check whether
  the same fitted combination answers Layer 5 (graph-trust).
- **[Layer 5/7/8] Untouched.** Graph-trust, news-attribution logging, and the
  entropy/calibration metric were not opened. Per the handoff, Layer 5 likely
  shares Layer 4's solution; Layer 7's calibration likely shares Layer 3's build.
  Recorded as genuinely open, not assumed.
