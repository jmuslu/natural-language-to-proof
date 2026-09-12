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
  the direct check overrides both.) Commits work here. Nothing committed this
  session — changes left in the working tree pending explicit request.

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

## Open items, by layer (for the next pass)

- **[Layer 1/2] Extend `Cat` with features + PP.** Design work, not brute force.
  The hard part is *feature unification* in `fwdApp`/`bwdApp` (replace `==` with
  a subsumption check: underspecified selects specified). PP needs the manual
  semantic-type decision above; until made, PP entries stay flagged. Doing this
  unlocks 26%→92% of the distinct lexicon as representable.
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
