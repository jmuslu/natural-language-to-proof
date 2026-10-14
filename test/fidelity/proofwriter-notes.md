# ProofWriter independent fidelity gold

The initial 24 cases cover twelve controlled construction families, two examples
per family. They are meaning diagnostics, not a random population sample or an
answer benchmark. Expectations were written from input sentences before any
parser observation; answer labels, inference representations, and proof chains
were not used. The separate DRS and claim tables were manually specified: whole
implications and negative boxes are Asserted, their contents are Embedded in
preorder, and no positive atom inside negation becomes Asserted.

Origins identify existing committed sample item IDs or local relative release
paths and input fields. The nominal examples come from line 139 of
`OWA/birds-electricity/meta-test.jsonl` in local V2020.12.3. ProofWriter is by
Tafjord, Dalvi and Clark (2021), Allen Institute for AI, CC BY 4.0; see
`bench/proofwriter/README.md`. Only this compact authored diagnostic set is saved.

## Strict meaning and fragment conventions

Names retain written case. Predicative `a/an` contributes unary classification,
not an additional referent linked to the subject by identity. Negation scopes
over the predicate with its argument order intact. Repeated names denote the
same individual; a subject repeated as object does not require reflexive syntax.
The relation examples replace definite animal descriptions with proper names;
these adaptations test relation composition and negation, **not** definiteness.

Explicit universals retain `person` (for *people*) and `thing` restrictors. Bare
plurals receive the controlled fragment's idealized exceptionless generic reading;
this is not a claim that all English generics are universally quantified. Within
a restrictor the fixed gold order is nominal head first, then modifiers in surface
order. Structural scoring is sensitive to that declared order. Conditional
*something* is an unrestricted indefinite bound in the antecedent and accessible
to *it* in the consequent; it does not introduce a lexical `thing` predication.
Conjoined adjectives share that binder. An antecedent binder is never in the root
universe.

These are **not** ProofWriter domain-adapter expectations. The benchmark adapter
may erase sortal predicates or map definite animal NPs to rigid domain constants;
those transformations must be measured separately and must not rewrite strict
meaning gold. The set does not establish fidelity of such an adapter. Every gold
reading explicitly records an empty disjunction annotation list, because none of
these controlled sentences contains disjunction.

## Uncovered constructions

The inventory's template dictionary includes positive/negative intransitives and
positive/negative *can fly*. The completed all-110-file surface inventory records zero matches for either
plain intransitive family. Modal atomic input occurrences are 10 positive and
18 negative; these do not include embedded modals or the separate NatLang
modal/habitual cue bucket. Modal input examples include:
`Arthur can fly.` and `Bill cannot fly.` at local line 140,
`AttPos-OWA-BirdsVar2-3`, questions Q21 and Q17. They remain pending: the current
canonical schema has no modal operator, and equating ability with actual flying
would be an independent gold error. An extensional `can_fly` predicate would be a
deliberate benchmark adapter, not strict compositional modal semantics.

The NatLang `PW.NL.*` categories are heterogeneous surface diagnostic buckets,
not completed semantic construction inventories. They need finer annotation,
including attitude strength, habituality, causality, relative clauses, and
fragments. Neither they nor original definite descriptions are covered by these
24 cases. This initial file therefore does not satisfy the full all-construction
gold milestone and must not be used to claim that it does.
