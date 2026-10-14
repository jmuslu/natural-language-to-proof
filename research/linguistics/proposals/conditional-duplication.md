# Conditional boundary versus comma coordination

Proposal and source-only red tests, not production implementation. This refines
`residual-priority.md` with a confirmed chart path. Unit2 supplies categories,
Unit3 supplies terms, Unit4 keeps only the intended implication Asserted.

## Confirmed first divergence

Miniature hand-tag model (no CCGbank load) for `If Bob is red, then Bob is big.`
reproduces both frozen alternatives. Wrong reading provenance is:

```
FwdApp
  CoordApply
    FwdApp(If, Bob is red)       : S/S = λq.red(Bob)→q
    CoordMark(comma, then)      : (S/S)[conj] = λq.q
  Bob is big                   : S[dcl] = big(Bob)
```

`CCGRules.step CoordMark` accepts commas with arbitrary categories;
`CCGSemParse` remembers the comma; CoordApply selects `coordinatorOp "," = TAnd`;
`coordTerm` pointwise conjoins the two t→t functions. The first wrong composition
is CoordApply: `λq.(red(Bob)→q)∧q`. Final application merely exposes it.
Correct provenance instead absorbs comma before applying if to `then B`.
Nested `If A, if B, C` also wrongly coordinates open modifiers into
`(A→C)∧(B→C)`, confirming that blocking only a literal `comma then` pair misses
the general issue. The target is A→(B→C).

## Proposed minimal general rule

Track an **open conditional modifier** role originating at the lexical conditional
entry, alongside category/meaning. Applying if to its antecedent creates that role
on S/S. Composition and punctuation absorption preserve its unfilled consequent
obligation; application to a sentence discharges it. Nested modifiers must retain
their obligations separately. A comma may absorb at their boundary, but must not
CoordApply two functors when either remains an open conditional modifier.
CoordApply with an explicit and/or keeps its existing licensing; ordinary comma
coordination of complete sentences, NP lists, and unrelated adverbial modifiers
must survive. The role is linguistic interface metadata, not a sentence string
match or a test for particular predicate names. Preserve roles during chart packing
so identical terms with different syntactic obligations do not erase the guard.

A smaller helper can inspect provenance/category plus the closed-class conditional
lexical entry, but searching merely for any descendant token `if` overblocks
completed conditionals and nested complements. A term-only `TImp` search also
confuses already-completed sentences with pending functors. Explicit role metadata
is preferred; coordinator should assess its footprint before implementing.

Do not change ifTerm, pointwise coordTerm, pronoun resolution or claim extraction.
Those operations compose the structures they receive consistently. Do not filter
out root atoms after lowering or choose a favourable retained reading by gold.

## Regression obligations

`test/ConditionalDuplicationSpec.hs` uses one hand-built lexical dictionary and
checks every retained typed reading. Seven controls cover comma+then, each marker
alone, nested open conditionals, a consequent with explicit coordination, ordinary
comma clauses, and ordinary and clauses. The explicit coordination control admits
both linguistically available attachments `A→(B∧C)` and `(A→B)∧C`; it rejects the
extra B assertion introduced by comma-functor coordination. This avoids using
structural ambiguity as a pretext to demand a single favourable reading.

For the simple conditional, DRS is `[ | [ |red(Bob)]⇒[ |big(Bob)]]`; Asserted is
only that implication, Embedded red/big. Nested conditions remain nested; no
consequent atom is independently asserted. Frozen binding cases already show
correct accessible antecedent references in the clean alternative, so rerun the
independent full fidelity set after the reviewed change and require no extra-root
atoms in any retained reading.

Follow the primary-source comparison in `residual-priority.md`: adopt Boxer's
syntax/semantics/resolution separation and ccg2lambda's category-sensitive
punctuation licensing, adapting local types. Neither upstream coverage nor a green
regression set proves the 90% ProverQA gate. No model/answer benchmarks are opened.

## Candidate implementation and bounded evidence

Root authorized an isolated implementation in CCGSemParse only. The candidate
uses two booleans, not a new generalized obligation framework:
`ssOpenConditional` and `ssConditionalRaised`. The first is seeded only by the
closed lexical entry whose gloss is conditional. The second records that this
pending role actually passed a licensed unary type-raising step; an isomorphic
lexical category by itself does not set it. Both participate in chart packing.

| Operation | Pending role | Raised evidence |
| --- | --- | --- |
| Closed if lexical entry | True | False |
| Other lexical/structural entry | False | False |
| Application or any of four compositions | Union children, then clear if result category is atomic S | Union children, clear unless pending survives |
| Unary transformation | Preserve unless result is atomic S | Preserve; additionally set at actual type-raising of a pending role |
| Coordination marking | Preserve right constituent (left structural role is empty) | Same |
| Explicit and/or coordination | Union children, clear at atomic S | Union; clear with pending |
| Punctuation absorption | Preserve retained constituent exactly | Same |
| Comma CoordApply | Reject a pending clause modifier or genuinely raised wrapper around one | Does not alter accepted meanings |

Discharge tests the **result**, not whether any child is a sentence. Therefore an
inner complete conditional contributes no pending role while the outer if lexical
child still marks the resulting outer modifier. A complete conditional inside a
report is already discharged before the report functor uses it.

A direct modifier is S/S or S\S. Raised wrappers recurse through opposing slash
shapes T/(T\X) and T\(T/X), requiring matching repeated T and recursively guarded
X. Each recursion removes two slash nodes, so repeated wrappers terminate and
both orientations have the same definition. The raised bit requires an actual
unary derivation in addition to that category-shape condition. Ordinary complete
clauses, explicit coordinators and unrelated unmarked functors are unaffected.

The miniature dictionary with clause/modifier raising exposed two separate
issues. A direct-category-only guard allows raised CoordApply to reconstruct the
bad extra consequent. The recursive wrapper guard removes it. Separately,
BwdXComp(if, type-raised antecedent) admits B→A rather than A→B. This pre-existing
crossed-composition/raising issue remains a **known wrong reading**: run
`ConditionalDuplicationSpec.hs --raising-audit` for its retained expected-red
all-exact assertion. The default raising control checks only that A→B survives
and no extra top-level conjunction survives; it never labels B→A exact.

The14 targeted controls pass; the wider raising audit fails as documented. The
source guard is bounded to clause-modifier and raised-wrapper categories, not a
proof about every composition/wrapping category. Role propagation through all
composition variants is explicit, but a future composition that changes the
category outside the recognized family needs an independent counterexample and
review, not an unsubstantiated claim of complete protection. The full dataset gate
and all-reading English fidelity remain unproven.

Reviewer approved this concrete bounded candidate for coordinator integration
experiments/gates, not as a fidelity claim. Two implementation limits remain
explicit: the raised bit records history rather than a complete current-wrapper
proof after arbitrary composition, and identifying the closed entry by its gloss
is a fragile internal API key. Renaming that gloss requires updating the seed and
running these controls; a future lexical-role interface can replace this key if
scope warrants it. Neither limit is concealed by the targeted green checks.
