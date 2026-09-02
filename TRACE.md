# Trace: one scenario through every layer

One sentence carried through the whole pipeline. At each layer:

- **Object** — what the thing *is*, mathematically. Naming it wrong is how a
  design goes wrong quietly, so it is named first.
- **State** — the artifact, written out explicitly enough to read off the page.
- **Propositions** — claims about that state, each with a status and a way to
  falsify it.
- **Analysis** — where the object is the wrong one, or the right one used wrongly.

The propositions are the point. They are meant to be argued with: a wrong one
should be visible as wrong without running anything.

Status tags: **[proved]** a theorem of the underlying calculus · **[checked]**
asserted in a test suite · **[measured]** came out of a run · **[conjectured]**
believed, unverified · **[stipulated]** chosen, not derived · **[structural]** the
object or its use is wrong, and no amount of data fixes it.

**Input:** `Every student reads a book.`

Two exceptions, flagged where they occur. S5b needs a three-sentence discourse,
because a single sentence has no discourse graph and a two-sentence one cannot
show the frontier doing anything. S11–S13 use synthetic claims, because no real
oracle is wired in yet.

> This document replaces the former `MATH-TRACE.md` and `WALKTHROUGH.md`, which
> were parallel spines over the same layers — one naming objects, one exhibiting
> state. Keeping them apart meant every finding had to be recorded twice, and
> twice is where they drift.

## Two kinds of gap, kept apart

This is a construction yard. Most of what looks unfinished is scaffolding, and
scaffolding is not a design question. Conflating the two makes the real questions
harder to find, so this document separates them:

- **Scaffolding** — an artifact of what is available in this environment. A toy
  corpus, a domain size of 2, a hand-written table of five adjectives, a specific
  numeric weight. These get replaced when data or compute arrives. They are not
  arguments about the design and they are not defects.
- **Structural** — the mathematical object is wrong, or is being used for
  something it cannot express. These would still be wrong with unlimited data and
  unlimited compute, which is exactly what makes them worth arguing about now.

Every **"Suspect / open"** row below is tagged one way or the other. The summary
at the end lists them separately. Only the structural list is a request for your
judgement.

Scenario throughout:

```
"Every student reads a book."
```

Chosen because it is the one fragment case that is genuinely ambiguous, so every
layer has something non-trivial to do.

---

## S0 — Source


| | |
|---|---|
| Object | `String` = element of the free monoid Σ\* over characters |
| Spans | half-open intervals `[a,b) ⊂ ℕ`, ordered by inclusion |
| Operation | tokenization: a partial map Σ\* → list of (token, interval) |
| Structure used | `spanUnion` = join in the interval lattice (least interval containing both) |
| Checked | slicing a token's span out of the source reproduces the token (Stage 1 suite) |

`spanUnion` is a **join**, not a union: intervals are not closed under set union,
so the operation returns the least covering interval. That is why a provenance
span can cover characters that contributed nothing.

**Suspect / open — structural.** Spans form a lattice under inclusion, but the
code only ever uses join. Meet (intersection) would give "what do these two derivations share
textually", which is currently uncomputable. Worth having for any edit-to-scope query: given a change to the text,
which derivations does it touch.

### State and propositions

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
### State and propositions

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
> textually" is therefore not expressible. Any edit-to-scope query needs it.

---

## S2 — Lexicon


| | |
|---|---|
| Object | `Cat`, generated from atoms {S, NP, N} by two binary operations `/` and `\` |
| Structure | a **residuated** structure: `/` and `\` are the right and left residuals of string concatenation |
| Laws | `(X/Y) · Y ⊢ X` and `Y · (Y\X) ⊢ X` — these *are* forward and backward application |
| Checked | every lexical entry's meaning inhabits `catTy` of its category |

This is the Lambek calculus fragment. Application is not an arbitrary rule; it is
residuation, i.e. the adjunction `(− · Y) ⊣ (− / Y)`.

### State and propositions

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

### `catTy` is a homomorphism that forgets direction

```
catTy (X / Y) = catTy Y → catTy X
catTy (X \ Y) = catTy Y → catTy X
```

Both slashes map to the same function type. So `catTy` is a **surjective,
non-injective** homomorphism from the residuated structure onto the function-type
structure.

That non-injectivity is the precise statement of "syntax carries more information
than semantics": directionality is exactly the information in the kernel. `S/NP`
and `S\NP` are distinct syntactic objects with identical semantic type.

**Suspect / open — structural.** Only application is enabled; composition and
type-raising are defined but unused. Those are the other residuation laws. A fragment with
coordination would need them, and the current rule set is a strictly smaller
sub-calculus than Lambek — worth naming as a deliberate restriction rather than a
coincidence.

---

## S3 — Derivation


| | |
|---|---|
| Object | simply-typed λ-calculus over base types {`e`, `t`} |
| Category | the syntactic category of STLC is the free **cartesian closed category** on the base types |
| Types | objects; `→` is the internal hom |
| Terms mod βη | morphisms |
| Checked | `typeOf` is total type synthesis; `wellTyped` requires the term to be a morphism `1 → t` |

Generalized quantifiers as `(e → t) → t` is the double-dual / continuation type.
That every NP has this type means every NP is a morphism `1 → (e→t)→t`, which is
why they compose uniformly with one verb entry.

### State and propositions

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

### Normalization and α-equivalence are two different quotients

| Quotient | By what | Representative |
|---|---|---|
| β-normalization | β-reduction | unique normal form (STLC is strongly normalizing **and** confluent) |
| α-equivalence | renaming of bound variables | `canonical`, via de Bruijn **levels** |

`normalize` picks the unique β-normal form; the Church–Rosser property is what
makes "the" normal form well-defined. `canonical` is a **section** of the
α-quotient map: it chooses one representative per equivalence class, so
`alphaEq a b ⟺ canonical a = canonical b`.

Both are quotient-then-section. The pattern recurs at every later layer, and it is
worth reading the rest of this document with it in mind.

---

## S4 — Provenance


| | |
|---|---|
| Object | `Prov` = the **initial algebra** of the functor `F X = (SourceId × Span × String) + (RuleName × List X)` |
| i.e. | finite trees with labelled leaves and labelled branchings |
| Folds | F-algebras. Every "fold class" in the code is a choice of carrier + structure map |

The fold classes, stated precisely:

| Fold | Carrier | Structure | Is it a monoid hom? |
|---|---|---|---|
| `provSources` | finite sets of `SourceId` | (P(S), ∪, ∅) — commutative, **idempotent** | yes |
| `provSpan` | intervals | join lattice | yes |
| `provSize` | ℕ | (ℕ, +) | no — the `1 +` at each node makes it an F-algebra, not a hom |
| `provDepth` | ℕ | (ℕ, max) | no, same reason |

So "why-provenance" is exactly the image of the **idempotent commutative** fold.
Idempotence is what destroys multiplicity: `{A} ∪ {A} = {A}` is precisely why a
fused set cannot tell two assertions from one — see S12, and why that quotient
has to wait until after the oracle.

### State and propositions

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
> multiplicity. `{A} ∪ {A} = {A}` is literally why a fused set cannot distinguish
> two assertions of a proposition from one.
>
> **P4.3 [proved]** `provSize` and `provDepth` are **not** monoid homomorphisms —
> the `1 +` at each node makes them F-algebras only.
> *Why state it:* "fold" is not one thing. The homomorphism folds are the ones
> that can be computed incrementally under merge; the others cannot.
>
> **P4.4 [proved]** `provSize > provDepth` here (9 > 4), and in general no single
> numeric fold recovers the tree.
> *Consequence:* the verification stage retains strictly more than any summary of it.
> That is not a design preference, it is a counting fact.
>
> **P4.5 [structural]** Genealogy is **not** obtainable as a fold of this object.
> Lineage is "is there a path from node A to node B", a question about morphisms in
> the free category on a graph. An initial algebra of a tree functor has no node
> identity and no sharing, so the question cannot even be posed.
> *Consequence:* the genealogy is a rewrite, not an extension. The leaf type is a red
> herring; the object class is the problem.

### Genealogy is a different object, not a different fold

This is the sharpest thing in this document.

| | Provenance | Genealogy |
|---|---|---|
| Object | initial algebra of a tree functor | **free category on a directed graph** |
| Elements | trees | objects = nodes; morphisms = paths |
| Sharing | impossible (trees duplicate) | the point (DAG shares) |
| Query | fold to a carrier | morphism existence / enumeration between two objects |

A fold cannot express "is there a path from node A to node B", because that is a
question about morphisms in a category, not about an algebra on a tree. **That is
the real reason `Prov` could not serve retraction** — not that its leaves are text spans
(fixable) but that trees are an initial algebra and lineage is a free category.

Consequence: implementing genealogy means introducing node identity, which is
hash-consing / a coend — turning the initial algebra into a graph with sharing.
That is a change of mathematical object, so it is a rewrite rather than an
extension.

---

## S5 — DRS


| | |
|---|---|
| Object | `DRS` = (finite list of referents, finite list of conditions) |
| Structure | a **monoid** under `mergeDRS`, identity `emptyDRS` |
| Commutative? | **no** — merge concatenates |
| Idempotent? | **no** |

The monoid is (nearly) free: it is lists, so it retains order and multiplicity.

### State and propositions

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
> **P5.2 [proved]** Fusion is exactly the canonical projection onto the
> **commutative idempotent quotient** of that monoid, i.e. finite sets of
> conditions. Verification is the refusal to take that quotient — see S11, S12.
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
> "same claim" test independent of fusion? Nothing currently constructs one.

### This is where verification and fusion separate, exactly

Semantically, conjunction of conditions *should* be commutative and idempotent.
The DRS monoid is neither. The gap between them is the whole design:

| | Quotient taken | Resulting structure |
|---|---|---|
| `canonicalize` | provenance, referent names | still a list — order and multiplicity **kept** |
| `Fusion.compress` | order, multiplicity | free **commutative idempotent** monoid = finite **sets** |
| `Verify.Claims` | none | the free monoid itself |

So: **fusion is the canonical projection onto the commutative idempotent
quotient; verification is the refusal to take it.** One sentence, and the stage
split falls out of it.

And the collapse question becomes a standard one: fusion takes the quotient and
picks a representative; verification keeps the **fibers** of the quotient map.
`selRejected` is the fiber.

The refactor added one thing to this picture that changes its force. The two
dispositions used to be alternatives, chosen per use case. They are now
*sequential*, and the order is forced: the quotient destroys the multiplicity
that retraction needs, so it cannot be taken until an oracle has settled truth.
Idempotence is not merely lossy here, it is lossy **about corroboration** —
`{A} ∪ {A} = {A}` is exactly the erasure of "two derivations agree" into "one
derivation said it".

**Suspect / open — structural.** `canonicalize` deliberately does *not* quotient by order,
which is right for the retaining stage but means it is not a normal form. Two DRSs
equal as sets of conditions compare unequal. If a "same claim" test is ever wanted
independently of fusion, it needs the commutative quotient without the idempotent
one — i.e. finite **multisets**, which is a third structure nothing currently
constructs.

---

## S5b — Discourse structure


| | |
|---|---|
| Object | a labelled DAG `(K, E ⊆ R × K × K)` whose nodes carry DRSs |
| Map out | `acc : SDRS → P(Ref)`, the frontier's referents |
| What it replaces | `accessibleRefs ∘ mergeDRS`, a monoid homomorphism |

Sits between Layer 4 (DRS) and Layer 10 (collapse), and it is the one place where
a *graph* is load-bearing rather than a convenience.

### State and propositions

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
> **P5b.9 [was measured, now fixed]** `mergeDRS` is sound only when the two
> universes are disjoint, and nothing enforced it. `Ref` was per-sentence, so
> `"A student arrived. A professor walks."` gave both existentials the name `x` and
> the merge asserted `student(x) & arrive(x) & professor(x) & walk(x)` — one
> individual who is both a student and a professor.
> *Consequence:* a **Stage 1 soundness bug**, missed by all 348 checks because no
> fragment case has two same-shaped existential sentences. It blocked this layer in
> particular: telling `x`-from-a-closed-unit apart from `x`-from-an-open-unit is the
> frontier's entire job, and `Ref` did not record the unit.
> *Fixed* by `freshenAgainst`, applied at the merge rather than in `toDRS` — so
> sentence-local boxes are untouched. It is alpha-conversion, hence unlogged, and
> `mapRefs` carries each referent's provenance through. The box now reads
> `professor(x2)`, and the anaphora decision reads `chose x2 over 1: x` instead of
> the degenerate `chose x over 1: x`.
> *Falsify:* find a discourse whose merged universe has fewer distinct names than
> entries. 18 checks in `Spec.hs` §14 try.
>
> **P5b.10 [proved + measured]** Consonance holds exactly where the truncation
> does. Since `frontier(Sub) = frontier(Coord) ∪ {parent}`, one free edge gives
> exactly two focal sets ordered by inclusion — nested **by construction**, a
> theorem rather than a measurement. Two free edges cross.
>
> | free edges | focal sets | nested? |
> |---|---|---|
> | 1 | 2 | yes — theorem |
> | 2 | 4 | no — `[x2]` crosses `[x]` |
>
> *Consequence:* the implementation occupies the **only** regime in which `μ` is a
> possibility distribution, and that regime is the truncation. The truncation has
> to go, so the possibility reading goes with it — the
> possibility-versus-belief-function question **retires** rather than being
> answered, which is a stronger outcome than either answer.
>
> **P5b.10b [measured]** The two-tier deflation in P5b.4 is also an artefact of one
> free edge. At two, `μ` is genuinely graded: `x2` at `0.488`, `x` at `0.435` on
> the four-segment colliding text — and the truncated implementation offers only
> `x2`, deleting the deeper candidate.
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

### The frontier is not expressible as a fold over the merge

`mergeDRS` is a monoid, so anything computed by folding it can only see order and
multiplicity. "Which units are still open for attachment" is not such a property:
it depends on the *kinds* of the edges above a node, which the merge has already
discarded. This is the same shape of argument as Layer 3's genealogy — the
information is destroyed by the homomorphism, so no fold over the target can
recover it — and it is why SDRT is a new object rather than a richer DRS.

Concretely, `frontierFrom` is a reachability computation: the least set containing
`ℓ` and closed under "climb to a parent, and keep it if the edge is
subordinating". Reachability is exactly what an initial-algebra fold cannot do.

### `acc` is antitone in commitment, which is why the default is graded

Write `acc_C` for the frontier referents under `Committed` and `acc_F` for the
flat merge's universe. Then, for any structure:

> `acc_C(S) ⊆ acc_F(S)`

with equality only when every edge is subordinating. Committing to a relation can
only shrink the antecedent set — the frontier is a **filter**, and a filter
driven by stipulated cue weights.

`Marginal` replaces the filter with a measure. For referent `r`, define

> `μ(r) = Σ { P(ρ) : ρ ∈ R, r ∈ acc(S[e ↦ ρ]) }`

the mass of relation values for the last edge `e` under which `r` survives.
Because `relationKind⁻¹(Subordinating)` is non-empty and `glue` gives every
relation positive mass, `μ(r) > 0` for every `r ∈ acc_F` restricted to the
committed prefix. So `Marginal` deletes nothing **on the committed prefix**, and
grades instead. Measured on the three-sentence example, `μ(x) = 0.488`, which is
exactly `P(relationKind = Subordinating)` at that edge — a derived quantity, not a
threshold.

**Two deflations, both measured, and both artifacts of the same truncation.**
First, `μ` takes only **two** values at one free edge: `1` for a referent in
`acc_coord`, `P(sub)` for one in `acc_sub \ acc_coord`, since those are the only
two focal sets. At two free edges it is genuinely graded — `0.488` and `0.435` on
the four-segment colliding text. Second, "deletes nothing" is about the prefix and
not the discourse: at four segments the implementation offers **nothing** while the
full marginal keeps the referent at `0.488`, because the truncation holds every
earlier edge at a committed value. `fullMarginalAt` measures this; it is a total
deletion, not a perturbation.

That is the same move as everywhere else in the design: replace a hard quotient by
a ranking, and keep the collapse separate and logged.

### Fixed: `μ` was on the wrong space, because DRS merge had an unstated precondition

`mergeDRS` is sound only when the two universes are **disjoint** — the standard
side condition on DRS merge, and nothing enforced it. Referent names come from the
lambda terms, so `"A student arrived. A professor walks."` gave both existentials
the name `x`, and the merge asserted `student(x) & arrive(x) & professor(x) &
walk(x)`: one individual who is both. Two distinct elements of the domain
identified.

For this layer specifically, `acc` must distinguish referents *by originating
unit*, since that is what open-versus-closed means, and `Ref` did not record the
unit — `accessibleOn`'s `nub` merged a closed unit's `x` with an open unit's `x`.

`freshenAgainst` discharges the precondition at the merge (not in `toDRS`), so
`Ref` is now discourse-unique and `(Label, Ref)` adds nothing. It is
alpha-conversion, hence a translation and not a decision: nothing is logged, and
`mapRefs` carries provenance through so a renamed referent is still traceable.

### And consonance holds exactly where the truncation does

Before the fix the index decided the answer, which is how a cheap test came to lie:

| index | focal sets | nested? |
|---|---|---|
| `Ref` (buggy) | 2 | yes |
| `(Label, Ref)` | 4 | no — `{(K2,x)}` crosses `{(K1,x)}` |

After the fix both agree: 4 sets, non-nested, crossing `[x2]` versus `[x]`. But
the structural statement is sharper than "not consonant". Since

> `frontier(Subordinating) = frontier(Coordinating) ∪ {parent}`

at **one** free edge there are exactly two focal sets, ordered by inclusion — so
consonance is a **theorem** there, not a measurement. At **two** free edges they
cross, measured.

The implementation marginalises over one edge. So it occupies the only regime in
which `μ` is a possibility distribution, and that regime *is* the truncation.
Since the truncation must go — it deletes referents — the possibility reading goes
with it. That retires the possibility-versus-belief-function question rather than
answering it, and it is a stronger result than either answer would have been.

### The semiring is a free parameter only once the truncation is gone

`μ(r) = ⊕_ρ P(ρ) ⊗ 1[r ∈ acc(S[e ↦ ρ])]` is a semiring-weighted sum, so the
semiring is formally a choice, and different choices yield different *kinds* of
object. Measured at one free edge: `(+,×) = 0.488`, `(max,×) = 0.122`,
`(max,min) = 0.122`. The Viterbi and possibilistic semirings **coincide**, because
`⊗` meets a boolean indicator and `P ≤ 1` gives `min(P,1) = P × 1 = P`. They
separate only at two free edges (`0.018` versus `0.122`).

So the four-way choice is really two — sum over licensors or max over licensors —
and it becomes a genuine four-way choice exactly when the one-edge truncation is
dropped. Note also that max-over-licensors is *not* MAP: MAP is argmax-then-test,
which is `Committed`, already implemented and measured to offer nothing here.

### No joint space, so no combination rule applies yet

`μ : Ref → [0,1]`. The RSA posterior is `Dist Int` over `readingIndex`, ranging
over scope permutations and coupling fusions. `Ref` occurs nowhere in
`Stage2.Alternatives`, `Stage2.Pipeline` or `Stage2.RSA` — checked. Every question
about Dempster's rule, t-norms, or credal sets presupposes a product space that
does not exist.

The native construction is to make antecedent choice an **alternative**, so a
reading is `(scope order, coupling, antecedent assignment)`. Then `μ` is a prior
over readings, the same object as every other Stage 2 weight, and `reweight` is
the combination. Same pattern as scope: Stage 1 collapses and logs the rejected
antecedents as strings; materialising them is Stage 2's job, and anaphora is the
one place it has not been done.

### The multiset gap and the truncation are one gap

At one free edge a licensing witness contains each relation at most once, so
multiset and set coincide — measured multiplicity `1`. At two free edges
multiplicity `2` appears. So the Layer-4-style "commutative but not idempotent"
intermediate is not a separate thing to build here: `rkLicensors` already carries
the set-level version, and the multiplicity it is missing exists only in the
regime the truncation excludes.

### Superseded: is `μ` a measure on the right space?

`μ` is a sum of probabilities over relation values, indexed by referents. It is
not a probability distribution over referents — masses do not sum to 1 across
`Ref`, and should not, since accessibility is not exclusive. It is closer to a
**fuzzy membership function**, or to the belief function of a Dempster–Shafer
structure whose focal elements are the sets `acc(S[e ↦ ρ])`.

Worth settling, because it decides how `μ` may legitimately be combined with the
RSA posterior at Layer 8. If it is a belief function, combining by multiplication
is wrong and Dempster's rule is the operation; if it is fuzzy membership, a
t-norm is; if it is neither, it should not be combined with a probability at all
and can only be used to order candidates. Right now it only orders, which is the
safe reading, and nothing downstream multiplies it.

### And the marginal is truncated at one edge, deliberately

Marginalising over every relation choice means a distribution over structures,
whose support is `|R|^(n-1)` for `n` segments — `8^(n-1)` here. The
implementation marginalises over the most recent edge only. This is a stated
truncation with no error bound, and it is the first thing that has to change if
discourses longer than three sentences matter.

---

## S6 — Scope-neutral form


| | |
|---|---|
| Object | scope-neutral form: (list of quantifier bindings, core formula) |
| Operation | permutation of the prefix — the symmetric group `S_n` acting on the binding list |
| Constraint | `validOrder`: only permutations respecting the dependency partial order are admissible |

The admissible orders are the **linear extensions** of the dependency poset on
bindings. That is the precise characterization: not all of `S_n`, but
`|linear extensions|` of a poset where `q_i < q_j` when `q_j`'s restrictor mentions
`q_i`'s variable.

For this sentence the poset is discrete (two incomparable bindings), so both
linear extensions are admissible: 2 readings. For the relative-clause case the
inner binding is *inside* the restrictor and never lifted, so the poset has one
element: 1 reading.

**Suspect / open — structural (algorithmic).** The code enumerates `permutations` and filters. That is
`O(n!)` where counting linear extensions directly would be far better — and the
number of linear extensions is what should be reported as the size of the scope
space. Not a correctness problem, but the wrong algorithm for the object.

### State and propositions

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


| | |
|---|---|
| Object | `Mod(σ)` = set of all σ-structures on domain `{0..n−1}` |
| `truthSet` | a map `Formula → P(Mod)` |
| Structure | a **Boolean algebra homomorphism** from the Lindenbaum algebra of formulas into `(P(Mod), ∩, ∪, ᶜ)` |
| `entails` | `⊆` in that Boolean algebra |
| `equivalent` | equality in the Lindenbaum algebra |
| `informativity` | `−log₂ μ(truthSet φ)` with μ the uniform counting measure — Shannon surprisal |

### State and propositions

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

### The scope readings are a *chain*, not an antichain

This is the mathematical content of the empirical finding:

```
truthSet(inverse) ⊊ truthSet(surface)        119/256 ⊊ 137/256
```

The two readings are **comparable** in the entailment order. So they are not
alternatives to choose between; they are two points on a chain, and the ambiguous
sentence sits at the join:

```
truthSet(surface ∨ inverse) = truthSet(surface)
```

because `inverse ≤ surface`. Hence `P(surface | ambiguous) = 1` **necessarily** —
not as an empirical result but as a lattice fact. The only live question is whether
the strengthened reading also holds, which is **scalar implicature**, structurally.

Any model that treats scope readings as a partition of a space is therefore
mis-specified. Mine did, at first. The right object is a sub-poset of the
Lindenbaum algebra, and the question is where in it the speaker was.

**Resolved — measured.** Coupling readings **are** an antichain: all six
pairs incomparable over 524,288 models, while scope readings are a chain. The two
ambiguity types are genuinely different order-theoretic situations.

Two consequences, the second of which corrects an earlier claim made right here:

- **An antichain is not a partition.** The four coupling truth sets overlap
  (8 + 16 + 16 + 16 = 56 models individually, union strictly smaller), so
  marginals over readings do not sum to 1. Neither a chain nor a partition — a
  third situation, and both mis-modellings are available.
- **RSA does rank coupling readings after all.** An earlier version of this
  paragraph said RSA "does nothing for coupling" and cast the fingerprint kernel
  as the necessary substitute. Wrong: the zero sharpening came from
  `surfaceScopePrior` being blind to coupling — all four readings share a
  quantifier signature — not from anything about coupling itself. Given
  informativity from this layer, sharpening is `0.0575` bits and the *more*
  informative reading is down-weighted, the same scalar pattern as scope. The
  fingerprint kernel measures structural similarity, a different quantity, not a
  fallback for where RSA fails.

---

## S8 — Ranking

**Object — Distributions**

| | |
|---|---|
| Object | `Dist a` = finitely-supported probability measure = point of the simplex Δ(A) |
| `fromWeights` | normalization: radial projection of the positive cone onto the simplex |
| `mapDist f` | **pushforward measure** `f_* μ` — functor action |
| `reweight g` | unnormalized multiplication then renormalize = **Bayes**, `g` the likelihood |
| `filterDist p` | **conditioning** on an event |
| `softmax α` | **Gibbs measure** at inverse temperature α |
| `entropy` | Shannon, base 2 |

`softmax` limits are the right sanity check: α = 0 gives the maximum-entropy
(uniform) measure, α → ∞ gives the zero-temperature limit (argmax). Both are
asserted in the suite.


**Object — RSA**

| | |
|---|---|
| Object | an operator `T : Δ(M)^U → Δ(M)^U`, one listener distribution per utterance |
| `L_k` | the k-th iterate `T^k(L_0)` |
| `S_k` | the intermediate speaker step, a Gibbs measure over `log L_{k-1} − cost` |
| Domain | `Δ(M)^U` is compact and convex |

Since `T` is a continuous self-map of a compact convex set, **Brouwer guarantees a
fixed point exists.** But nothing guarantees the iteration converges to it, and
nothing here checks. `pragmaticListener k` is iterate `k`, not a fixed point, and
the code is honest that `k` is a parameter — but the relationship between "depth
k" and "the fixed point" is unestablished.

**Suspect / open — structural.** Is `T` a contraction? If it were, iteration would converge
geometrically and depth `k` would have a principled stopping rule instead of being
a latency knob. Worth determining — it settles the open question about how
deep RSA can afford to go.

### State and propositions

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
> being a latency knob. This is the open question about affordable RSA depth.
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

### Missing: `Dist` is not a monad, and it should be

`Dist` is the **finite distribution monad** (the finitary Giry monad). `mapDist`
is `fmap`; `certain` is `return`. But there is no `join`/`>>=`, so a probabilistic
step cannot be *composed* with another — every multi-step probabilistic
computation has to be written by hand.

This is a real gap, not a stylistic one. RSA's recursion is literally a Kleisli
composition of listener and speaker steps, and writing it without `>>=` is why
`listenerTable` had to be hand-hoisted for performance. Adding the monad instance
would make the recursion expressible as composition, and would make the
Stage 3 rollback story (which is a probabilistic state transformer) tractable.

---

## S9 — Fingerprints


| | |
|---|---|
| Object | a tuple of multisets (predicates, arities, connectives) plus a sequence (quantifier prefix) and two scalars |
| Kernel | weighted Jaccard = `Σ min / Σ max` on multisets |

Jaccard on multisets is a genuine metric's complement (`1 − J` is a metric, the
Tanimoto/Jaccard distance), so `similarity` is a bounded symmetric kernel with
`similarity x x = 1`.

**Scaffolding.** The specific weights — `0.65/0.35`, and `0.75/0.25`,
`0.5/0.2/0.2/0.1` inside the halves — are stipulated. They encode nothing but a
guess and get replaced when there is data to fit them to. Not a design question;
just read every similarity number as carrying that caveat.

**Suspect / open — structural.** Whether to collapse content and structure into
one scalar *at all*. A convex combination of kernels is a kernel, so the object is
well-formed — but the two halves measure incomparable things, and averaging them
discards precisely the asymmetry that made separating them worthwhile. Keeping them
as two coordinates and letting the consumer decide would be wrong-free at any
weight. This one would still be a question with perfect data.

### State and propositions

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


| | |
|---|---|
| Object | a quotient map `q : Readings → Readings/∼` and a choice of section |
| Verification (S11) | keep the **fibers** `q⁻¹(c)` — the quotient is not taken |
| Fusion (S12) | take the quotient; pick the canonical representative |

`Selection` carrying `selRejected` is the fiber. A function `[DRS] → DRS` cannot
represent a fiber, which is the type-level statement of why that signature was
rejected.

### State and propositions

> **P10.1 [proved]** Collapse is quotient-then-section: a quotient map
> `q : Readings → Readings/∼` and a choice of representative.
>
> **P10.2 [proved]** `selRejected` is the **fiber** `q⁻¹(c)`. A function
> `[DRS] → DRS` cannot represent a fiber, which is the type-level statement of why
> that signature was rejected in favour of `Selection`.
>
> **P10.3 [proved]** Verification and fusion are two dispositions toward one
> quotient, and the refactor made them sequential rather than alternative:
>
> | stage | action |
> |---|---|
> | verification (S11) | never quotient; keep the fibers, so retraction stays possible |
> | fusion (S12) | take the quotient, keep a representative — only after the oracle |
>
> *Consequence:* the earlier framing had these as a choice per use case, which
> made the ordering look arbitrary. It is not: the quotient destroys what
> retraction reads.

---

## S11 — Verification: the oracle and the genealogy

| | |
|---|---|
| Object (verdict) | a three-element set `{Confirmed, Refuted, Unknown}`, **not** a Boolean |
| Object (graph) | a labelled DAG of claims with `Justification` edges, plus a verdict assignment on premises |
| Map out | `grounded : Genealogy → P(NodeId)`, the **least** fixed point of grounded support |
| What it replaces | nothing — this layer did not exist before the refactor |

### State

A confirmed premise `n0`, a confirmed premise `n1`, a claim `n2` derived
independently from each, and a claim `n3` derived from `n0` alone:

```
        n0 [Confirmed]            n1 [Confirmed]
         |        \                /
         |         \              /
       (d3)        (d2a)      (d2b)
         |            \        /
         v             v      v
        n3               n2
```

```
grounded = {n0, n1, n2, n3}          all four supported

retract n0:
  precise   (difference of fixed points)  ->  {n0, n3}
  coarse    (transitive dependents)       ->  {n2, n3}
  survived  (what coarse would destroy)   ->  {n2}
```

### Propositions

> **P11.1 [proved]** `Verdict` has three inhabitants and `Unknown ≠ Refuted`.
> *Consequence:* "outside the oracle's domain" is representable, so uncovered
> claims can score zero instead of being forced into a truth value. Collapsing
> the two would manufacture grounding for domains that have none.
>
> **P11.2 [proved]** `Confirmed` is abstract — its constructor is not exported and
> `confirm` is the only producer. So "fusion sees only oracle-confirmed claims" is
> a property of the module system.
> *Falsify:* find a way to obtain a `Confirmed` without an `Oracle`. There is no
> `Read`, `Generic` or exported record update.
>
> **P11.3 [proved]** `grounded` is the least fixed point of a monotone operator on
> the finite powerset of nodes, so by Knaster–Tarski it exists, is unique, and is
> reached by iteration from `∅` in at most `|N|` steps.
>
> **P11.4 [proved]** Least and greatest fixed points differ exactly on circular
> support. A ring of mutually-justifying claims with no confirmed premise is in
> the greatest and not in the least.
> *Consequence:* **a claim cannot ground itself, directly or around a cycle.** This
> is the formal content of the design's central constraint, and the reason the
> least fixed point is not an implementation detail.
>
> **P11.5 [checked]** Measured on rings of two and three nodes: none grounded. The
> same ring with one confirmed premise beneath it: all grounded. So cycles are
> excluded without poisoning legitimate support that happens to pass through one.
>
> **P11.6 [proved]** `retract` is the set difference of `grounded` before and
> after flipping a verdict. Reachability (`dependents`) over-approximates it,
> because a claim with an independent surviving derivation is reachable from the
> retracted node and does not lose support.
> *Consequence:* precision is not a heuristic here; it falls out of recomputing
> the fixed point rather than walking edges.
>
> **P11.7 [measured]** On the fixture above: lost `{n0, n3}`, downstream
> `{n2, n3}`, survived `{n2}`. The coarse answer over-retracts by exactly the
> independently-supported claim.
>
> **P11.8 [proved]** `grounded` is monotone in the verdict assignment ordered by
> `Confirmed > {Refuted, Unknown}`: confirming a premise can only enlarge the
> grounded set.
> *Consequence:* adding evidence never withdraws a conclusion. Withdrawal requires
> a reversal, which is what `retract` is for.
>
> **P11.9 [structural gap]** **Retraction is not supersession.** Both granularities
> of retraction exist — source-level (`retractSource`, coarse, for an unreliable
> document) and node-level (`retract`, precise, for a reversed measurement). What
> does not exist is revision *with history*: "this claim was updated at T", where
> the prior claim is historical rather than wrong.
> *Open:* this is where AGM belief revision would be evaluated, and it should be
> derived from this use case rather than inherited from a roadmap.
>
> **P11.10 [structural, does not close]** The oracle bounds the **truth** of a
> claim and says nothing about its **correspondence** to the source text. A policy
> that extracts true-but-unfaithful claims scores well. No internal mechanism
> supplies extraction faithfulness, and none plausibly can.

### Analysis: why a DAG and not a richer tree

S4's `Prov` is an initial algebra, so every question you can ask of it is a fold.
Two questions here are not folds:

- **"Is there a path from A to B"** is reachability. `grounded`, `antecedentsOf`
  and `dependents` are all reachability computations.
- **"What loses support if this changes"** needs addressable identity to change
  *something specific*, which structural identity cannot provide — two claims can
  be structurally identical and need to be separate nodes because they were
  derived differently.

This is the same argument P4.5 made, and it is why the genealogy is a rewrite
rather than an extension of `Prov`. The two coexist: `nodeProv` still carries the
derivation tree, because the tree remains the right object for "which words
produced this".

---

## S12 — Fusion: the quotient, taken late

| | |
|---|---|
| Object | the canonical projection onto the free **commutative idempotent** monoid on confirmed claims = finite **sets** |
| Also | a one-rule mechanical entailment closure over that set |
| Precondition | every input carries a `Confirmed` token (S11) |

### State

```
input   [p, p, p]  (three confirmed assertions of one claim)
output  fusedClaims  = [p]
        fusedDropped = 2
        fusedOracles = ["yes"]

base    [p, p -> q, q -> r]
entailedFrom  ->  [p, p -> q, q -> r, q, r]
```

### Propositions

> **P12.1 [proved]** `fuse` is `sort` then `dedup`: the canonical projection of
> S5's free monoid onto its commutative idempotent quotient. Same map P5.2 names,
> applied one stage later.
>
> **P12.2 [proved, and checked]** Syntactic canonical equality is **strictly
> finer** than logical equivalence. Witness: `~(P | Q)` and `~P & ~Q` are
> equivalent, produce different `CanonCond` shapes, and do not merge.
> *Consequence:* the gap does not close by improving `compress`. It is the reason
> this module is bookkeeping rather than verification, and the reason the old
> "collapses sentences entailing the same proposition" claim was retired.
>
> **P12.3 [proved]** `detachable` guards modus ponens on `null (canonUniverse a)`.
> A duplex condition whose antecedent box binds a referent is a **universal**, not
> a material implication, and detaching from it without producing a witness is
> unsound.
> *Consequence:* the entailment layer is deliberately incomplete rather than
> unsound. Removing the guard would let `every student reads a book` plus
> `student(r0)` detach as if the duplex were `P → Q` over closed formulas.
>
> **P12.4 [checked]** `entailedFrom` closes over chained implications, and adds
> nothing when no antecedent is present in the base.
>
> **P12.5 [structural — the ordering is a correctness requirement]** Idempotence
> erases corroboration: `{A} ∪ {A} = {A}` turns "two derivations agree" into "one
> derivation said it". Upstream of the oracle that is destructive, because
> corroboration is evidence while truth is undecided. Downstream it is free,
> because truth is already settled and only storage is at stake.
> *Consequence:* fusion before verification is not merely lossy, it removes the
> record retraction depends on. The stage order cannot be relaxed.

---

## S13 — Reward: what may and may not count

| | |
|---|---|
| Object | a function `Fused × Genealogy → ℝ` |
| Notably not | a function of `Term`, so it cannot consult `typeOf`, and it has no proof search available |
| Self-check | `admissibility : Weights → Bool`-shaped record |

### State

```
weights      confirmed 1.0   entailed 0.5   refuted -1.0   uncovered 0.0

chain of 5 mutually-justifying claims, no oracle beneath any of them
  grounded   = {}
  score      = 0.0

chain of 50, same shape
  score      = 0.0
```

### Propositions

> **P13.1 [proved]** The signature excludes the inadmissible signals. `score`
> receives a `Fused` and a `Genealogy` and never a `Term`, so typedness is
> unreachable from it; and there is no prover in scope, so provability is too.
> *Consequence:* the constraint is enforced by the type, not by remembering it.
>
> **P13.2 [checked]** A chain of five internally-coherent, mutually-justifying,
> perfectly well-formed claims with no oracle beneath it scores `0.0`. A chain of
> fifty scores `0.0`.
> *Consequence:* internal coherence cannot be farmed for reward. This is the
> executable form of "a system cannot use its own consistency as its reward".
>
> **P13.3 [proved]** Uncovered premises contribute exactly zero, because
> `wUncovered = 0` and `admissibility` rejects any other value.
> *Why zero rather than negative:* penalising uncovered claims would train the
> policy away from domains that merely lack instrumentation, which is a fact about
> the tooling and not about the claim. Rewarding them would invent evidence.
>
> **P13.4 [checked]** The admissibility check has teeth: paying anything for
> uncovered claims, failing to penalise refutation, or valuing inherited grounding
> above direct confirmation are each reported inadmissible.
> *The third one matters most:* if entailment outscored confirmation, the policy
> would be rewarded for laundering claims through `entailedFrom` instead of getting
> them checked.
>
> **P13.5 [proved]** `rwScore` is strictly monotone in the confirmed count and
> strictly antitone in the refuted count, with `wRefuted < 0`.
> *Consequence:* guessing costs more than silence, which is the property that stops
> the policy from emitting claims speculatively.
>
> **P13.6 [stipulated]** The weight *values*. Only the structure — which categories
> exist, and which are pinned to zero — is derived. A real training run replaces
> the numbers; it must not replace the zero.

### Analysis: the two admissible sources, and why only two

Reward may come from oracle confirmation, or from mechanical entailment over an
already-confirmed base. Nothing else, and the exclusions are specific:

| Rejected signal | Why |
|---|---|
| well-typedness | necessary, not sufficient. Multiple mutually-incompatible extractions of one sentence are all well-typed — the S6 scope readings are exactly this — and `typeOf` cannot break the tie. |
| provability in isolation | a found proof certifies derivability, not correspondence to the input. Rewarding it gives the policy a cheaper path than faithful extraction: drift toward easily-provable statements. |
| internal consistency | measures self-agreement. Formally excluded by the least-fixed-point choice in P11.4. |

The one safe use of a provability-shaped signal is **cross-derivation
convergence**: independent extraction paths arriving at mutually-entailing forms.
That is what `hasIndependentSupport` and `convergentNodes` measure, and it is safe
precisely because it is a property of *two* derivations rather than of one
statement.

---

## Summary

### Structural — wrong object or wrong use, would persist at any scale

Ordered by how much a good answer changes the design. These are the ones where
your judgement would actually redirect the work.

1. **Make antecedent choice an alternative.** The frontier mass has nowhere to go
   because `μ : Ref → [0,1]` and readings are indexed by `Int`; there is no joint
   space, which is upstream of every question about combination rules. Materialise
   antecedent assignments in `Stage2.Alternatives` and `μ` becomes a prior over
   readings, combined by the existing `reweight`. Dissolves the question rather
   than answering it, and it is the same move scope already made. (S5b)
3. **Drop the one-edge marginalisation truncation.** Common cause of four separate
   symptoms: `μ` is two-valued, multiset collapses to set, the candidate semirings
   coincide, and `Marginal` still deletes referents at four segments.
   `fullMarginalAt` measures the gap; it does not close it. (S5b)
4. **Is the RSA operator a contraction?** Would replace a latency knob with a
   convergence criterion, and settles the affordable-depth question directly. (S8)
5. **`Dist` should be the finite distribution monad.** No `join`/`>>=`, so
   probabilistic steps cannot compose. RSA's recursion *is* Kleisli composition,
   and Stage 3 rollback is a probabilistic state transformer that will need it.
   (S8)
6. **Genealogy is a free category, not an initial algebra.** A fold cannot answer
   "is there a path from A to B". This is the real reason `Prov` cannot serve
   retraction — not its leaf type — and it made the DAG a rewrite rather than an
   extension. (S4)
7. **Should content and structure similarity stay separate coordinates** rather
   than being averaged into one scalar? (S9)
8. **Is a multiset quotient of DRS wanted** — commutative but not idempotent —
   for a "same claim" test independent of fusion? Nothing currently
   constructs it. (S5)
9. **Count linear extensions** rather than filtering `n!` permutations. The
   number of linear extensions is also the right thing to report as the size of
   the scope space. (S6)
10. **Span meet is missing**, so "what do two derivations share textually" is
   uncomputable — needed by any edit-to-scope query.
   (S0, S1)
11. **Only application is enabled** from the Lambek calculus. A deliberate
   restriction to a strictly smaller sub-calculus; worth naming as such rather
   than leaving it to look accidental. (S2)

### Resolved this session

- **DRS merge had an unstated disjointness precondition, and violating it was
  unsound.** `"A student arrived. A professor walks."` merged to one `x` that was
  both. Fixed by `freshenAgainst` at the merge; 348 Stage 1 checks pass unchanged,
  18 regression checks added. `Ref` is now discourse-unique, so `(Label, Ref)`
  buys nothing. (S5b)
- **Consonance holds exactly where the one-edge truncation does, and that is a
  theorem.** `frontier(Sub) = frontier(Coord) ∪ {parent}` gives exactly two nested
  focal sets at one free edge; at two they cross (measured). So `μ` is a
  possibility distribution only under the truncation, and the truncation has to go
  — the possibility-versus-belief-function question retires rather than being
  answered. (S5b)
- **The candidate semirings coincide where the code currently operates.**
  `(max,×)` and `(max,min)` both give `0.122` at one free edge, because `⊗` meets
  a boolean indicator and `P ≤ 1`. They separate only at two free edges. So "the
  semiring is a free parameter" is true but gated on dropping the truncation.
  And max-over-licensors is not MAP — argmax-then-test is `Committed`. (S5b)
- **There is no joint space for the frontier mass and the RSA posterior**, so the
  choice of combination rule was never the live question. `Ref` occurs nowhere in
  `Alternatives`, `Stage2.Pipeline` or `RSA` — checked, not assumed. (S5b)
- **Coupling readings form an antichain; scope readings form a chain.** Measured
  over 524,288 models at domain size 2: all six coupling pairs incomparable,
  scope strictly ordered. The two ambiguity types are genuinely different
  order-theoretic situations, which was the top open question. (S7)
- **An antichain is not a partition.** The four coupling truth sets overlap —
  individually 8 + 16 + 16 + 16 = 56 models, union strictly smaller — so
  marginals over readings do not sum to 1. A third situation, distinct from both
  a chain and a partition, and both mis-modellings are available.
- **RSA does rank coupling readings**, once given informativity from the model
  layer instead of a scope-signature prior. The earlier "sharpening exactly 0"
  was an artifact of a prior blind to coupling, not a fact about coupling.
  Corrected in place rather than only in git history. (S8)

### Scaffolding — environment artifacts, not design questions

Listed only so they are not mistaken for the above.

| Scaffold | Replaced by |
|---|---|
| nine-case fragment as the evaluation set | chunked real corpus, extended deliberately |
| domain size 2–3 in model enumeration | larger domains; compute is cheap and the entailment is already stable across 1–3 |
| hand table of five adjective classes | a lexical resource, plus corpus statistics for the layer-2 conventionalization judgement |
| structural fingerprints in place of distributional vectors | real vectors composed along the CCG derivation |
| stipulated kernel weights | fitted weights |

None of these change what the objects *are*. They change how well the numbers
attached to them mean anything.
## Reviewing this document

The propositions most worth attacking, in order:

1. **P8.5** — is the RSA operator a contraction? Converts a latency knob into a
   stopping rule, and settles the affordable-depth question.
2. **P4.5** — genealogy needs a free category rather than an initial algebra.
   Now built on that basis (S11); if there is a fold-based encoding I have
   missed, the rewrite was unnecessary.
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
