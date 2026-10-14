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
