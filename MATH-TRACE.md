# Math trace: one sentence, layer by layer

A single scenario traced through every layer, naming **the mathematical object at
each step**, what structure it has, what is actually checked, and where the
structure looks wrong or underused.

Purpose: make the mathematics inspectable so it can be corrected.

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

## Layer 0 — Text and spans

| | |
|---|---|
| Object | `String` = element of the free monoid Σ\* over characters |
| Spans | half-open intervals `[a,b) ⊂ ℕ`, ordered by inclusion |
| Operation | tokenization: a partial map Σ\* → list of (token, interval) |
| Structure used | `spanUnion` = join in the interval lattice (least interval containing both) |
| Checked | slicing a token's span out of the source reproduces the token (348-suite) |

`spanUnion` is a **join**, not a union: intervals are not closed under set union,
so the operation returns the least covering interval. That is why a provenance
span can cover characters that contributed nothing.

**Suspect / open — structural.** Spans form a lattice under inclusion, but the
code only ever uses join. Meet (intersection) would give "what do these two derivations share
textually", which is currently uncomputable. Worth having for the conversational
track's edit-to-scope problem.

---

## Layer 1 — Syntactic categories

| | |
|---|---|
| Object | `Cat`, generated from atoms {S, NP, N} by two binary operations `/` and `\` |
| Structure | a **residuated** structure: `/` and `\` are the right and left residuals of string concatenation |
| Laws | `(X/Y) · Y ⊢ X` and `Y · (Y\X) ⊢ X` — these *are* forward and backward application |
| Checked | every lexical entry's meaning inhabits `catTy` of its category |

This is the Lambek calculus fragment. Application is not an arbitrary rule; it is
residuation, i.e. the adjunction `(− · Y) ⊣ (− / Y)`.

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

## Layer 2 — Lambda terms

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

## Layer 3 — Provenance

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
Idempotence is what destroys multiplicity: `{A} ∪ {A} = {A}` is precisely why
truth-mode cannot tell two assertions from one.

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
the real reason `Prov` cannot serve letra** — not that its leaves are text spans
(fixable) but that trees are an initial algebra and lineage is a free category.

Consequence: implementing genealogy means introducing node identity, which is
hash-consing / a coend — turning the initial algebra into a graph with sharing.
That is a change of mathematical object, so it is a rewrite rather than an
extension.

---

## Layer 4 — DRS

| | |
|---|---|
| Object | `DRS` = (finite list of referents, finite list of conditions) |
| Structure | a **monoid** under `mergeDRS`, identity `emptyDRS` |
| Commutative? | **no** — merge concatenates |
| Idempotent? | **no** |

The monoid is (nearly) free: it is lists, so it retains order and multiplicity.

### This is where truth-mode and letra separate, exactly

Semantically, conjunction of conditions *should* be commutative and idempotent.
The DRS monoid is neither. The gap between them is the whole design:

| | Quotient taken | Resulting structure |
|---|---|---|
| `canonicalize` | provenance, referent names | still a list — order and multiplicity **kept** |
| truth-mode `compress` | order, multiplicity | free **commutative idempotent** monoid = finite **sets** |
| letra | none | the free monoid itself |

So: **truth-mode is the canonical projection onto the commutative idempotent
quotient; letra is the refusal to take it.** One sentence, and the two tracks fall
out of it.

And the collapse question becomes a standard one: truth-mode takes the quotient
and picks a representative; provenance-mode keeps the **fibers** of the quotient
map. `selRejected` is the fiber.

**Suspect / open — structural.** `canonicalize` deliberately does *not* quotient by order,
which is right for letra but means it is not a normal form. Two DRSs equal as sets
of conditions compare unequal. If a "same claim" test is ever wanted independently
of truth-mode, it needs the commutative quotient without the idempotent one —
i.e. finite **multisets**, which is a third structure nothing currently
constructs.

---

## Layer 5 — Candidate generation

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

---

## Layer 6 — Fingerprints

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

---

## Layer 7 — Distributions

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

## Layer 8 — RSA

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
a latency knob. Worth determining — it directly answers the conversational track's
open question about how deep RSA can afford to go.

---

## Layer 9 — Models and entailment

| | |
|---|---|
| Object | `Mod(σ)` = set of all σ-structures on domain `{0..n−1}` |
| `truthSet` | a map `Formula → P(Mod)` |
| Structure | a **Boolean algebra homomorphism** from the Lindenbaum algebra of formulas into `(P(Mod), ∩, ∪, ᶜ)` |
| `entails` | `⊆` in that Boolean algebra |
| `equivalent` | equality in the Lindenbaum algebra |
| `informativity` | `−log₂ μ(truthSet φ)` with μ the uniform counting measure — Shannon surprisal |

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

## Layer 9b — Discourse structure and the frontier

| | |
|---|---|
| Object | a labelled DAG `(K, E ⊆ R × K × K)` whose nodes carry DRSs |
| Map out | `acc : SDRS → P(Ref)`, the frontier's referents |
| What it replaces | `accessibleRefs ∘ mergeDRS`, a monoid homomorphism |

Sits between Layer 4 (DRS) and Layer 10 (collapse), and it is the one place where
a *graph* is load-bearing rather than a convenience.

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

**Two deflations, both measured.** First, `μ` takes only **two** values at one
free edge: `1` for a referent in `acc_coord`, `P(sub)` for one in
`acc_sub \ acc_coord`, since those are the only two focal sets. One global degree
of freedom, not a per-referent grade. Second, "deletes nothing" is about the
prefix and not about the discourse: at four segments the implementation offers
**nothing** while the full marginal keeps the referent at `0.488`, because the
truncation holds every earlier edge at a committed value. `fullMarginalAt`
measures this; it is a total deletion, not a perturbation.

That is the same move as everywhere else in the design: replace a hard quotient by
a ranking, and keep the collapse separate and logged.

### Resolved: `μ` is on the *wrong* space, and that is a Stage 1 bug

The question "which non-additive measure is `μ`" has an answer, and it is that the
question is premature: **`Ref` is not a discourse-wide identifier.** Referent names
are generated per sentence, so `"A student arrived. A professor walks."` gives both
existentials the name `x`, and the merge asserts `student(x) & arrive(x) &
professor(x) & walk(x)` — one individual who is both. Two distinct elements of the
domain have been identified.

For this layer specifically: `acc` is supposed to distinguish referents *by
originating unit*, since that is what open-versus-closed means, and `Ref` does not
record the unit. `accessibleOn`'s `nub` then merges a closed unit's `x` with an
open unit's `x`. The correct index is `(Label, Ref)` or globally fresh names.

And the index decides the answer to the measure question:

| index | distinct focal sets | nested (consonant)? |
|---|---|---|
| `Ref` | 2 | **yes** |
| `(Label, Ref)` | 4 | **no** — `{(K2,x)}` crosses `{(K1,x)}` |

So a consonance test would report "possibility measure", and that report would be
an artefact of the name collision. Under the correct index the focal family is not
nested, so `μ` is **not** a possibility distribution and the t-norm route is closed
on the merits rather than left open.

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

## Layer 10 — Collapse

| | |
|---|---|
| Object | a quotient map `q : Readings → Readings/∼` and a choice of section |
| truth-mode | take the quotient; pick the canonical representative |
| provenance-mode | keep the **fibers** `q⁻¹(c)` |
| conversational | keep the fibers *during* the session, quotient at the end |

`Selection` carrying `selRejected` is the fiber. A function `[DRS] → DRS` cannot
represent a fiber, which is the type-level statement of why that signature was
rejected.

---

## Summary

### Structural — wrong object or wrong use, would persist at any scale

Ordered by how much a good answer changes the design. These are the ones where
your judgement would actually redirect the work.

1. **`Ref` is not a discourse-wide identifier, and the merge is unsound because
   of it.** Two same-shaped existential sentences collide on `x`, so the merged DRS
   asserts one individual is both a student and a professor. A Stage 1 bug that all
   348 checks miss, and the reason the frontier mass cannot be typed: `acc` must
   distinguish referents by originating unit and `Ref` does not record it. Fixing
   it is a design choice with provenance consequences — globally fresh names, or
   accessibility indexed by `(Label, Ref)`. (Layer 9b)
2. **Make antecedent choice an alternative.** The frontier mass has nowhere to go
   because `μ : Ref → [0,1]` and readings are indexed by `Int`; there is no joint
   space, which is upstream of every question about combination rules. Materialise
   antecedent assignments in `Stage2.Alternatives` and `μ` becomes a prior over
   readings, combined by the existing `reweight`. Dissolves the question rather
   than answering it, and it is the same move scope already made. (Layer 9b)
3. **Drop the one-edge marginalisation truncation.** Common cause of four separate
   symptoms: `μ` is two-valued, multiset collapses to set, the candidate semirings
   coincide, and `Marginal` still deletes referents at four segments.
   `fullMarginalAt` measures the gap; it does not close it. (Layer 9b)
4. **Is the RSA operator a contraction?** Would replace a latency knob with a
   convergence criterion, and answers the conversational track's open question
   about affordable depth directly. (Layer 8)
5. **`Dist` should be the finite distribution monad.** No `join`/`>>=`, so
   probabilistic steps cannot compose. RSA's recursion *is* Kleisli composition,
   and Stage 3 rollback is a probabilistic state transformer that will need it.
   (Layer 7)
6. **Genealogy is a free category, not an initial algebra.** A fold cannot answer
   "is there a path from A to B". This is the real reason `Prov` cannot serve
   letra — not its leaf type — and it makes letra a rewrite rather than an
   extension. (Layer 3)
7. **Should content and structure similarity stay separate coordinates** rather
   than being averaged into one scalar? (Layer 6)
8. **Is a multiset quotient of DRS wanted** — commutative but not idempotent —
   for a "same claim" test independent of truth-mode? Nothing currently
   constructs it. (Layer 4)
9. **Count linear extensions** rather than filtering `n!` permutations. The
   number of linear extensions is also the right thing to report as the size of
   the scope space. (Layer 5)
10. **Span meet is missing**, so "what do two derivations share textually" is
   uncomputable — needed by the conversational track's edit-to-scope problem.
   (Layer 0)
11. **Only application is enabled** from the Lambek calculus. A deliberate
   restriction to a strictly smaller sub-calculus; worth naming as such rather
   than leaving it to look accidental. (Layer 1)

### Resolved this session

- **The frontier mass is not a possibility distribution, and the cheap test that
  says otherwise is reading an artifact.** Under `Ref`-indexing the focal family
  has 2 sets and is nested; under `(Label, Ref)`-indexing it has 4 and is not,
  crossing at `{(K2,x)}` vs `{(K1,x)}`. Consonance is a property of `acc` and the
  index, not of the weights, so no choice of semiring makes it hold. (Layer 9b)
- **The candidate semirings coincide where the code currently operates.**
  `(max,×)` and `(max,min)` both give `0.122` at one free edge, because `⊗` meets
  a boolean indicator and `P ≤ 1`. They separate only at two free edges. So "the
  semiring is a free parameter" is true but gated on dropping the truncation.
  And max-over-licensors is not MAP — argmax-then-test is `Committed`. (Layer 9b)
- **There is no joint space for the frontier mass and the RSA posterior**, so the
  choice of combination rule was never the live question. `Ref` occurs nowhere in
  `Alternatives`, `Stage2.Pipeline` or `RSA` — checked, not assumed. (Layer 9b)
- **Coupling readings form an antichain; scope readings form a chain.** Measured
  over 524,288 models at domain size 2: all six coupling pairs incomparable,
  scope strictly ordered. The two ambiguity types are genuinely different
  order-theoretic situations, which was the top open question. (Layer 9)
- **An antichain is not a partition.** The four coupling truth sets overlap —
  individually 8 + 16 + 16 + 16 = 56 models, union strictly smaller — so
  marginals over readings do not sum to 1. A third situation, distinct from both
  a chain and a partition, and both mis-modellings are available.
- **RSA does rank coupling readings**, once given informativity from the model
  layer instead of a scope-signature prior. The earlier "sharpening exactly 0"
  was an artifact of a prior blind to coupling, not a fact about coupling.
  Corrected in place rather than only in git history. (Layer 8)

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
