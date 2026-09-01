# Traceable walkthrough: state and propositions

One sentence carried through every layer. At each step:

- **State** — the object, written out explicitly enough to read off the page.
- **Propositions** — claims about that state, each with a status and a way to
  falsify it.

The propositions are the point. They are meant to be argued with: a wrong one
should be visible as wrong without running anything.

Status tags: **[proved]** a theorem of the underlying calculus · **[checked]**
asserted in the test suite · **[measured]** came out of a run · **[conjectured]**
believed, unverified · **[stipulated]** chosen, not derived.

Companion to [MATH-TRACE.md](MATH-TRACE.md), which names the object at each layer.
This one exhibits the objects and what holds of them.

**Input:** `Every student reads a book.`

One exception, flagged where it occurs: S5b needs a three-sentence discourse,
because a single sentence has no discourse graph and a two-sentence one cannot
show the frontier doing anything. Every other layer runs on the input above.

---

## S0 — Source

```
offset  0         1         2
        0123456789012345678901234567
source  Every student reads a book.
```

State: an element of Σ\*, plus the interval `[0,27)`.

> **P0.1 [checked]** For every token `t`, lower-casing the source restricted to
> `span(t)` yields `text(t)`.
> *Falsify:* find a token whose span slices to something else. Every provenance
> claim downstream rests on this, so it is the one to attack first.

---

## S1 — Tokens

```
0  every    [0,5)
1  student  [6,13)
2  reads    [14,19)
3  a        [20,21)
4  book     [22,26)
```

The period at `[26,27)` contributes no token.

> **P1.1 [checked]** Token spans are pairwise disjoint and ordered.
>
> **P1.2 [proved]** Spans form a lattice under inclusion; `spanUnion` is its
> **join**, not set union. Intervals are not closed under union, so the result may
> cover characters that contributed nothing.
> *Consequence:* a provenance span is an over-approximation. Anyone reading a span
> as "exactly the characters responsible" is reading it wrong.
>
> **P1.3 [structural gap]** Meet is never computed. "What do two derivations share
> textually" is therefore not expressible. The conversational track's
> edit-to-scope problem needs it.

---

## S2 — Lexicon

| # | token | category | meaning |
|---|---|---|---|
| 0 | `every` | `NP/N` | `λP. λQ. ∀x. P(x) → Q(x)` |
| 1 | `student` | `N` | `student` |
| 2 | `reads` | `(S\NP)/NP` | `λO. λS. S(λx. O(λy. read(x,y)))` |
| 3 | `a` | `NP/N` | `λP. λQ. ∃x. P(x) ∧ Q(x)` |
| 4 | `book` | `N` | `book` |

> **P2.1 [checked]** For every entry, `typeOf(meaning) = catTy(category)`.
> This is the syntax–semantics coherence condition, and it holds for all 40-odd
> entries, not just these five.
> *Falsify:* exhibit an entry whose term does not inhabit its category's type.
>
> **P2.2 [proved]** `catTy` is a homomorphism from the residuated (Lambek)
> structure to function types, and it is **not injective**:
> `catTy(X/Y) = catTy(X\Y)`.
> *Consequence:* directionality is precisely the kernel. `S/NP` and `S\NP` are
> distinct syntactically, identical semantically. This is the exact sense in which
> syntax carries more information than semantics.
>
> **P2.3 [stipulated]** Every NP has type `(e→t)→t`, including proper names. Not
> forced by anything; chosen so one verb entry serves all subjects.
> *Cost of the choice:* proper names get a continuation type they do not need.
> *Benefit:* no type-raising rule is required.

---

## S3 — Derivation

Chart cells, by increasing length. Only application is enabled.

```
(0,2)  NP      every student      λQ. ∀x. student(x) → Q(x)
(3,2)  NP      a book             λQ. ∃z. book(z) ∧ Q(z)
(2,3)  S\NP    reads a book       λS. S(λx. ∃z. book(z) ∧ read(x,z))
(0,5)  S       whole sentence     ∀x. student(x) → (∃z. book(z) ∧ read(x,z))
```

> **P3.1 [proved]** Forward and backward application are the two residuation laws
> `(X/Y)·Y ⊢ X` and `Y·(Y\X) ⊢ X`. They are not stipulated inference rules; they
> are the adjunction `(−·Y) ⊣ (−/Y)`.
>
> **P3.2 [proved]** Each application step preserves (a) closedness and (b) the
> typing invariant `typeOf(sem) = catTy(cat)`. By induction, the root sign
> satisfies both.
> *Consequence:* the root is a closed term of type `t`, i.e. a morphism `1 → t` in
> the free CCC. No separate well-formedness pass is needed.
>
> **P3.3 [proved]** The normal form is unique. STLC is confluent (Church–Rosser)
> and strongly normalizing, so "the" β-normal form is well-defined and
> `normalize` is total without a fuel parameter.
> *Falsify:* impossible for STLC. If it ever appeared to fail, the calculus has
> been extended beyond STLC — which would be the actual finding.
>
> **P3.4 [checked]** This sentence has exactly **one** derivation to `S`.
> *Falsify:* enable composition or type-raising and it will not stay one. That is
> why the default rule set is application-only, and the restriction is deliberate
> rather than accidental.
>
> **P3.5 [proved]** The λ-apparatus is absent from the normal form: it is
> first-order. Quantifiers survive, abstraction does not.
> *Why it matters:* every downstream layer can assume a first-order formula and
> none of them need to handle `Lam`.

---

## S4 — Provenance

The tree is isomorphic to the derivation:

```
<
├── > ── {lex every [0,5)  ·  lex student [6,13)}
└── > ── {lex reads [14,19)  ·  > ── {lex a [20,21) · lex book [22,26)}}
```

Folds, read off the same tree:

| fold | value |
|---|---|
| `provSources` | `{demo}` |
| `provSpan` | `[0,26)` |
| `provDepth` | 4 |
| `provSize` | 9 |

Count it off the tree: **four** rule nodes — one root `<` and three `>` — plus five
lexical leaves. An earlier version of this table said 8, miscounting the rule
nodes as three; the drawing above was always right.

> **P4.1 [proved]** `Prov` is the initial algebra of
> `F X = (SourceId × Span × String) + (RuleName × List X)`. Every fold is an
> F-algebra: a carrier plus a structure map.
>
> **P4.2 [proved]** `provSources` is a **monoid homomorphism** into
> `(P(SourceId), ∪, ∅)`, which is commutative and **idempotent**.
> *Consequence — and this is the crux of the two tracks:* idempotence destroys
> multiplicity. `{A} ∪ {A} = {A}` is literally why truth-mode cannot distinguish
> two assertions of a proposition from one.
>
> **P4.3 [proved]** `provSize` and `provDepth` are **not** monoid homomorphisms —
> the `1 +` at each node makes them F-algebras only.
> *Why state it:* "fold" is not one thing. The homomorphism folds are the ones
> that can be computed incrementally under merge; the others cannot.
>
> **P4.4 [proved]** `provSize > provDepth` here (9 > 4), and in general no single
> numeric fold recovers the tree.
> *Consequence:* provenance-mode retains strictly more than any summary of it.
> That is not a design preference, it is a counting fact.
>
> **P4.5 [structural]** Genealogy is **not** obtainable as a fold of this object.
> Lineage is "is there a path from node A to node B", a question about morphisms in
> the free category on a graph. An initial algebra of a tree functor has no node
> identity and no sharing, so the question cannot even be posed.
> *Consequence:* letra is a rewrite, not an extension. The leaf type is a red
> herring; the object class is the problem.

---

## S5 — DRS

```
┌────────────────────────┐
│  (universe empty)      │
├────────────────────────┤
│  ┌───────────┐         │
│  │ x         │         │
│  ├───────────┤    ⇒    │
│  │ student(x)│         │
│  └───────────┘         │
│                        │
│  ┌────────────┐        │
│  │ z          │        │
│  ├────────────┤        │
│  │ book(z)    │        │
│  │ read(x,z)  │        │
│  └────────────┘        │
└────────────────────────┘
```

> **P5.1 [proved]** `(DRS, mergeDRS, emptyDRS)` is a monoid. It is **neither
> commutative nor idempotent** — merge concatenates lists.
>
> **P5.2 [proved]** truth-mode is exactly the canonical projection onto the
> **commutative idempotent quotient** of that monoid, i.e. finite sets of
> conditions. letra is the refusal to take that quotient.
> *Consequence:* the entire truth/provenance distinction is one quotient. Not two
> data models, not two pipelines — one projection, taken or not.
>
> **P5.3 [checked]** Accessibility is the **top** universe only. Here it is empty.
> *Consequence:* `"Every student reads a book. She smiles."` cannot resolve `she`;
> both referents are trapped in subordinate boxes. Same mechanism that blocks
> `"No student sleeps. She smiles."`, and it is the correct DRT result rather than
> a limitation.
>
> **P5.4 [structural gap]** `canonicalize` quotients provenance and referent names
> but **not** order or multiplicity, so it is not a normal form. Two DRSs equal as
> multisets compare unequal.
> *Open:* is a multiset quotient wanted — commutative but not idempotent — for a
> "same claim" test independent of truth-mode? Nothing currently constructs one.

---

## S5b — Discourse structure

**A second input is needed here, and that is itself the point.** One sentence has
no discourse graph, and a *two*-sentence discourse has exactly one edge whose
parent is always reachable, so it cannot show the frontier doing anything either.
Three segments is the minimum at which this layer is observable.

**Input:** `A student arrived. Mary smiles. She reads a book.`

Per-segment DRSs, top universes only:

```
K1  ┌───────────┐      K2  ┌───────────┐      K3  ┌────────────┐
    │ x           │          │ (empty)     │          │ x1          │
    ├───────────┤          ├───────────┤          ├────────────┤
    │ student(x)  │          │ smile(mary) │          │ book(x1)    │
    │ arrive(x)   │          │             │          │ read(?she,  │
    └───────────┘          └───────────┘          │       x1)   │
                                                    └────────────┘
```

The graph the threader builds, with the kind of each edge:

```
K1 ──Continuation──▶ K2 ──Narration──▶ K3
      (coordinating)        (coordinating)
```

State at each step. `sites` is the pre-attachment frontier; `μ` is the mass of
last-edge relation values under which each referent survives.

| step | sites | antecedents offered | resolves `?she`? |
|---|---|---|---|
| K1 | — | — | n/a |
| K2 | `K1` | `x` at `μ = 1.0` | n/a |
| K3, flat | — | `x` (whole universe) | yes |
| K3, `Committed` | `K2` | none | **no** |
| K3, `Marginal` | `K2` | `x` at `μ = 0.488` | yes |

The distribution at the `K1 → K2` edge, with no cue firing:

| relation | mass | kind |
|---|---|---|
| `Continuation` | 0.146 | coordinating |
| `Narration`, `Result`, `Contrast` | 0.122 each | coordinating |
| `Elaboration`, `Explanation`, `Background`, `Instance` | 0.122 each | subordinating |
| | **0.488 subordinating** | |

> **P5b.1 [proved]** For `relation(a, b)`, `a`'s referents are accessible to `b`
> whatever the relation is; the kind governs what the **next** unit sees.
> *Consequence:* the frontier consulted when resolving unit *n* is the frontier
> through *n-1*, so the threading loop runs one step behind the graph. Reading it
> otherwise would make a coordinating relation block its own right argument.
> *Falsify:* find a relation under which K2 fails to see `x`. The K2 row above is
> `μ = 1.0` for exactly this reason.
>
> **P5b.2 [proved]** `acc_Committed(S) ⊆ acc_flat(S)`, with equality iff every
> edge is subordinating.
> *Consequence:* SDRT threading can only **remove** antecedents. It is a filter,
> and on this fragment the filter is set by stipulated cue weights — which is
> why it is not installed as the Stage 1 default.
>
> **P5b.3 [measured]** `μ(x) = 0.488` at K3, and this equals
> `P(relationKind = Subordinating)` at the `K1 → K2` edge exactly.
> *Consequence:* the grade is derived from the relation distribution, not a
> threshold. Changing a cue weight moves it; nothing else does.
>
> **P5b.4 [checked, and narrower than it first looked]** `Marginal` deletes
> nothing *on the committed prefix*, because `Elaboration` always retains positive
> mass and is subordinating.
> *Consequence:* at one uncertain edge the frontier contributes a ranking rather
> than a veto. **But not beyond it:** at four segments the implementation offers
> nothing while the full marginal keeps the referent at `0.488`, because the
> truncation holds every earlier edge at a committed value. `fullMarginalAt`
> measures the gap.
> *Also narrower:* `μ` takes only **two** values here — `1` and `P(sub)` — since
> there are only two focal sets. A two-tier partition with one global tier weight,
> not a per-referent grade.
>
> **P5b.5 [checked]** The nine-case corpus shows **zero** divergence between flat
> and either policy.
> *Consequence:* one assertion says two things — the tie-in is safe on the
> existing corpus, and the corpus is too short to exercise it.
>
> **P5b.6 [stipulated]** `glue`'s no-cue default is `Continuation`, the least
> committal *relation*. But it is coordinating, hence the most restrictive choice
> for *accessibility*.
> *Open:* two notions of "least committal" that look like one and point opposite
> ways. Left as-is because `Marginal` makes the choice non-destructive; if
> `Committed` ever becomes the default, this weight is the first thing to revisit.
>
> **P5b.7 [structural gap]** A resolved pronoun adds no referent to its unit's
> universe, so under `Committed` a chain of coordinating relations starves:
> `"A man walked in. He sat down. He ordered."` reaches the third unit with an
> empty frontier universe. Real SDRT percolates referents up the graph.
> *Open:* percolation is the fix; `Marginal` only hides the symptom.
>
> **P5b.8 [checked]** `μ` is not a probability distribution over referents —
> masses need not sum to 1, and should not, since accessibility is not exclusive.
> But the follow-up question is not "which non-additive measure is it", because
> **its domain is wrong** (P5b.9).
>
> **P5b.9 [measured]** `Ref` is per-sentence, not per-discourse.
> `"A student arrived. A professor walks."` gives both existentials the name `x`,
> and the merge asserts `student(x) & arrive(x) & professor(x) & walk(x)` — one
> individual who is both a student and a professor.
> *Consequence:* a **Stage 1 soundness bug**, missed by all 348 checks because no
> fragment case has two same-shaped existential sentences. It blocks this layer in
> particular: telling `x`-from-a-closed-unit apart from `x`-from-an-open-unit is
> the frontier's entire job, and `Ref` does not record the unit.
> *Falsify:* find a discourse where two segments introduce referents and the merged
> universe has as many distinct names as entries.
>
> **P5b.10 [measured]** Consonance depends on the index, so a nestedness test
> would answer the measure question from an artefact:
>
> | index | focal sets | nested? |
> |---|---|---|
> | `Ref` | 2 | yes |
> | `(Label, Ref)` | 4 | no — `{(K2,x)}` crosses `{(K1,x)}` |
>
> *Consequence:* under the correct index `μ` is **not** a possibility
> distribution, so the t-norm route is closed on the merits.
>
> **P5b.11 [measured]** The Viterbi and possibilistic semirings give the *same*
> number here (`0.122`), because `⊗` meets a boolean indicator and `P ≤ 1`. They
> separate only at two free edges (`0.018` vs `0.122`).
> *Consequence:* "the semiring is a free parameter" is true but downstream of the
> truncation, not available now. And max-over-licensors is not MAP —
> argmax-then-test is `Committed`, already built.
>
> **P5b.12 [checked]** There is no joint space: `μ` is indexed by `Ref`, readings
> by `readingIndex :: Int`, and `Ref` occurs nowhere in `Alternatives`,
> `Stage2.Pipeline` or `RSA`.
> *Consequence:* the native move is to make antecedent choice an **alternative**,
> so `μ` becomes a prior over readings and `reweight` is the combination. No
> borrowed uncertainty calculus.

---

## S6 — Scope-neutral form

```
prefix   [ (∀, x, student(x)) , (∃, z, book(z)) ]
core     read(x,z)
```

> **P6.1 [checked]** `unscope` and `relinearize` are mutually inverse on the
> original prefix order.
> *Falsify:* find a term where the round trip is not α-equal to the input.
>
> **P6.2 [proved]** The admissible orders are exactly the **linear extensions** of
> the dependency poset, where `qᵢ < qⱼ` iff `qⱼ`'s restrictor mentions `qᵢ`'s
> variable. Reordering across a dependency would leave a variable unbound.
> *Here:* neither restrictor mentions the other's variable, so the poset is
> discrete, and both of the 2 linear extensions are admissible.
>
> **P6.3 [proved]** For `"Every student who reads a book smiles"` the inner
> existential lies inside the universal's restrictor and is never lifted, so the
> prefix has one element and there is exactly one reading.
> *Why it matters:* no special case in the code. It falls out of where the
> quantifier sits.
>
> **P6.4 [structural, algorithmic]** The implementation enumerates all `n!`
> permutations and filters by `validOrder`. Counting linear extensions directly
> would be the right algorithm, and the count is also the right thing to report as
> the size of the scope space.
>
> **P6.5 [checked]** Every generated reading is closed and well-typed.

Two readings:

```
surface   ∀x. student(x) → ∃z. book(z) ∧ read(x,z)
inverse   ∃z. book(z) ∧ ∀x. student(x) → read(x,z)
```

---

## S7 — Model space, and the result that changed the design

Domain `{0}`. Symbols: `student ⊆ {0}`, `book ⊆ {0}`, `read ⊆ {(0,0)}`.
**8 models.** At a one-element domain both quantifiers collapse:

```
surface ≡ student(0) → (book(0) ∧ read(0,0))
inverse ≡ book(0) ∧ (student(0) → read(0,0))
```

| # | student | book | read | surface | inverse |
|---|---|---|---|---|---|
| 1 | F | F | F | T | F |
| 2 | F | F | T | T | F |
| 3 | F | T | F | T | T |
| 4 | F | T | T | T | T |
| 5 | T | F | F | F | F |
| 6 | T | F | T | F | F |
| 7 | T | T | F | F | F |
| 8 | T | T | T | T | T |

This table is small enough to be the reviewable object: 8 rows, both columns
derivable by inspection.

> **P7.1 [proved]** `truthSet` is a **Boolean algebra homomorphism** from the
> Lindenbaum algebra of formulas into `(P(Mod), ∩, ∪, ᶜ)`. Entailment is `⊆`;
> logical equivalence is equality in the Lindenbaum algebra.
>
> **P7.2 [measured]** `truthSet(inverse) = {3,4,8} ⊊ {1,2,3,4,8} = truthSet(surface)`.
> Counts at larger domains: 3/5 at n=1, 119/137 at n=2, 15465/17303 at n=3.
> *Falsify:* exhibit a model satisfying inverse but not surface. Model 1 falsifies
> the converse, which is what makes the inclusion strict.
>
> **P7.3 [proved from P7.2]** The two readings form a **chain**, not an antichain:
> `inverse ≤ surface` in the entailment order.
> *Consequence:* they are not alternatives to choose between.
>
> **P7.4 [proved from P7.3]** The ambiguous sentence, true when either reading is,
> is true in `truthSet(surface) ∪ truthSet(inverse) = truthSet(surface)` — the join
> of a chain is its top. Hence
>
> > `P(surface | sentence) = 1`
>
> as a **lattice fact**, not an empirical finding. The only live question is
> whether the strengthened reading also holds.
> *Consequence:* scope ambiguity of this shape is **scalar strengthening**. Any
> model treating the readings as a partition is mis-specified — mine was, and this
> is the proposition that showed it.
>
> **P7.5 [measured — RESOLVED]** Coupling readings form an **antichain**. All
> six pairs are incomparable, over 524,288 models at domain size 2.
> `chinese_dragon` is an uninterpreted predicate with no relation to
> `chinese(x) ∧ dragon(x)`, so neither direction entails.
> *Confirmed:* scope and coupling are genuinely different order-theoretic
> situations — a chain and an antichain respectively.
>
> **P7.7 [measured]** Incomparable is **not** disjoint. The four coupling truth
> sets overlap: individually 8 + 16 + 16 + 16 = 56 models, whose union is
> strictly smaller. So coupling is neither a chain nor a partition — a third
> situation, and marginal probabilities over readings do not sum to 1.
> *Consequence:* any model that treats an antichain as a partition is as wrong as
> one treating a chain as a partition. Both errors are available.
>
> **P7.6 [proved]** `entails` over a finite model set is sound for
> counterexamples and **not** complete for entailment. A counterexample found is
> real; none found is evidence at that domain size, not a proof.
> *Consequence:* this sits on the search side of the search/verification split,
> not the verification side.

---

## S8 — Ranking

> **P8.1 [proved]** `Dist a` is a point of the simplex `Δ(A)`. `mapDist` is the
> **pushforward measure** (functor action), `reweight` is unnormalized Bayes,
> `filterDist` is conditioning, `softmax α` is a Gibbs measure at inverse
> temperature α.
>
> **P8.2 [checked]** `softmax 0` is the maximum-entropy (uniform) measure;
> `softmax α → argmax` as `α → ∞`. Both limits asserted.
>
> **P8.3 [structural gap]** `Dist` is the **finite distribution monad** but has no
> `join`/`>>=`. Probabilistic steps therefore cannot compose.
> *Consequence:* RSA's recursion *is* Kleisli composition, and writing it without
> `>>=` is why `listenerTable` had to be hand-hoisted for performance. Stage 3's
> rollback is a probabilistic state transformer and will need the monad.
>
> **P8.4 [proved]** The RSA operator is a continuous self-map of the compact convex
> set `Δ(M)^U`, so by Brouwer a **fixed point exists**.
>
> **P8.5 [conjectured]** Whether the iteration *converges* to it. Nothing checks.
> *If it is a contraction:* depth `k` gets a principled stopping rule instead of
> being a latency knob, which directly answers the conversational track's open
> question about affordable depth.
>
> **P8.6 [measured]** With a uniform world prior, `P(inverse | sentence)` falls
> from `0.869` (literal) to `0.808` (pragmatic) at n = 2, weakening to `0.835` and
> `0.853` as the paraphrase cost rises.
> *Reading:* hearing the ambiguous form **lowers** belief in the stronger reading,
> because a speaker meaning it had an unambiguous alternative. A scalar
> implicature, from a uniform prior — nothing about scope preference stipulated.
> The weakening with cost is the sanity check: not-using an expensive alternative
> is weaker evidence.
>
> **P8.7 [measured — CORRECTED]** An earlier version recorded coupling
> sharpening as exactly 0 and concluded RSA cannot rank coupling readings. That
> was an artifact of the prior, not a fact about coupling: `surfaceScopePrior` is
> blind to coupling differences because all four readings share a quantifier
> signature.
>
> Given real informativity from the model layer, RSA **does** rank them:
>
> | reading | true in | informativity | L0 | L1 |
> |---|---|---|---|---|
> | fully intersective (4 conjuncts) | 8 | 5.0 bits | 0.205 | **0.114** |
> | each fused variant (3 conjuncts) | 16 | 4.0 bits | 0.410 | 0.376 |
>
> Sharpening `0.0575` bits. And the direction is the same scalar pattern as scope:
> the *more* informative reading is **down**-weighted, because a speaker who meant
> it had a more explicit option available.
> *Corrected consequence:* RSA handles both ambiguity types once it has
> informativity. The fingerprint kernel is not a substitute for it — it
> measures a different thing (structural similarity), not a fallback for where RSA
> fails.
>
> **P8.8 [retracted]** *"RSA cannot break a symmetry the prior does not already
> break."* False. The reference-game test produces the implicature under a uniform
> prior from an asymmetric **lexicon**. The true statement is about the earlier
> setup only: it had no informativity measure, so the prior was its sole
> asymmetry — a property of the construction, not of RSA.

---

## S9 — Fingerprints

| | surface | inverse |
|---|---|---|
| predicates | `student:1, book:1, read:1` | identical |
| arities | `1:2, 2:1` | identical |
| quantifier prefix | `[∀, ∃]` | `[∃, ∀]` |

> **P9.1 [proved]** Weighted Jaccard `Σmin/Σmax` on multisets is symmetric,
> bounded in `[0,1]`, and equals 1 exactly on equal multisets. `1 − J` is a metric.
>
> **P9.2 [checked]** Scope readings: content similarity `= 1.0` exactly,
> structural `< 1` (prefixes compared as **sequences**, agreeing in 0 of 2
> positions).
> *Reading:* same subject matter, different quantification.
>
> **P9.3 [measured]** Coupling readings: content `0.575`, structural `0.917` — the
> mirror image.
> *Consequence:* scope differs structurally with identical content; coupling
> differs in content with identical structure. Neither measure alone separates
> both, which is why the fingerprint is split in half.
>
> **P9.4 [stipulated]** The weights `0.65 · content + 0.35 · structure`, and
> `0.75/0.25` and `0.5/0.2/0.2/0.1` within the halves. A convex combination of
> kernels is a kernel, so the object is well-formed — but the numbers encode
> nothing but a guess.
>
> **P9.5 [structural]** Whether to collapse the two halves into one scalar **at
> all**. They measure incomparable things, and averaging discards precisely the
> asymmetry that made separating them worthwhile. This would still be a question
> with perfectly fitted weights.

---

## S10 — Collapse

> **P10.1 [proved]** Collapse is quotient-then-section: a quotient map
> `q : Readings → Readings/∼` and a choice of representative.
>
> **P10.2 [proved]** `selRejected` is the **fiber** `q⁻¹(c)`. A function
> `[DRS] → DRS` cannot represent a fiber, which is the type-level statement of why
> that signature was rejected in favour of `Selection`.
>
> **P10.3 [proved]** The three tracks are three dispositions toward one quotient:
>
> | track | action |
> |---|---|
> | epistemic | take the quotient, keep a representative, verify it |
> | conversational | keep the fibers during the session, quotient at teardown |
> | letra | never quotient; keep the fibers indefinitely |

---

## Reviewing this document

The propositions most worth attacking, in order:

1. **P8.5** — is the RSA operator a contraction? Converts a latency knob into a
   stopping rule, and answers the conversational track's depth question.
2. **P4.5** — genealogy needs a free category. If this is right, letra is a
   rewrite; if there is a fold-based encoding I have missed, it is not.
3. **P9.5** — should content and structure ever be averaged?
4. **P5.4** — is a multiset quotient of DRS wanted?
5. **P7.7** — coupling is an antichain with *overlapping* truth sets. Does the
   ranking layer need to represent that overlap explicitly, rather than treating
   readings as if marginals summed to 1?

**Resolved this session:** P7.5 (coupling is an antichain, measured over 524,288
models) and P8.7 (RSA does rank coupling, given informativity — the earlier
zero was a prior artifact).

Everything tagged **[stipulated]** is scaffolding: replaced when data arrives, not
a design question. Everything tagged **[structural]** or **[conjectured]** would
still be open with unlimited data and compute.
