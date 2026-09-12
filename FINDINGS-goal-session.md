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

- **[structural] Integration gap, partially bridged.** `bars.py` handles the
  bars→returns half. The remaining half: real strategies must emit their *own*
  per-period returns (the `results/*.json` store only summary stats — PnL/win-
  rate/expectancy, no returns series), so `strategy-core` still needs extending
  before the live engine feeds the suite. Also still open: a price-level
  random-strategy Monte-Carlo null (complements the returns-level sign-flip null;
  needs the engine + bar data). Both documented in the module README.

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

## Open items, by layer (for the next pass)

- **[Layer 1/2] Migrate the core parser (`CCG.hs`) to feature unification, or
  keep the ingestion path separate.** The unification policy is now built and
  externally validated on `CCat`, but the hand-written fragment's parser still
  uses `==` on bare `Cat`. Decision still open: extend the core `Cat` with
  features + `PP` and swap `==` for `unifiable` (bigger blast radius, risks the
  386-check Stage-1 suite), vs. keep CCGbank ingestion on its own `CCat` path
  and bridge only where needed. Either way, `PP`'s semantic type must be decided
  before PP-bearing entries become real `Entry` values.
- **[Layer 1/2] The type-changing rule class** (the measured ~8% gap above) —
  implement as an explicit, separately-named rule set with its own coverage
  measurement, not by loosening the combinators.
- **[Layer 2] Done: `.auto` derivation parser + reconstruction** (`CCGDeriv`,
  `ccg-reconstruct`, ~96% of real sentences). Remaining: use the reconstructed
  sentences as an actual test-case *fixture* feeding the DRT/SDRT stages, to hit
  the two known-unreachable properties a 9-case fixture can't produce.
- **[Layer 3] Suite built; two things remain.** The three properties now exist
  (`agentic-qr:shared/backtesting/validation/`, commit `aeee8d5`). Remaining:
  (a) extend `strategy-core` to emit a per-period returns series so the live
  engine can feed the suite (the recorded integration gap), and (b) add the
  deterministic prefilter + price-level random-strategy Monte-Carlo null
  (Layer 3/3.5). Both are `~/projects` work (confirmation now granted).
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
