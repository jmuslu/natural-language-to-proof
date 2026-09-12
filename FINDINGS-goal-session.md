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
- **[Layer 2] Test-case generator over real AUTO derivations** — the second
  "generator". Needs full-tree ingestion (internal `<T>` nodes, hence the
  node-level atom inventory already surveyed). Target: the two known-unreachable
  properties a 9-case fixture can't produce.
- **[Layer 3/4/5/7] Untouched this session.** The `~/projects/` backtester,
  reward-manifold scalarization, graph-trust, and news-attribution layers were
  not opened; per the handoff they depend on lower-layer traction and/or a shared
  external-fitness build. Layers 4 and 5 remain "likely one problem"; Layers 3
  and 7 "likely one build". No findings to report there yet — recorded as
  genuinely open rather than assumed.
