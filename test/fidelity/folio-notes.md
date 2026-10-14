# FOLIO fidelity gold: bounded first slice

These 12 independent manual fixtures cover six groups, two examples each:
`some_existential`, `some_negative_existential`, `at_least_one_relational`,
`no_universal`, `predicate_disjunction_ground`, and `authored_attitude_control`.
They are construction diagnostics, not a representative FOLIO estimate. Two
positive existential cases are verbatim sample inputs; eight cases explicitly
adapt sample vocabulary/constructions, and two speech controls are wholly
invented. Source IDs, zero-based context-line indices, and changes are recorded
per row. Only English context/statement fields were examined; labels, proofs and
FOL formalizations did not supply gold. No parser observations supplied gold.

The schema objects and claim arrays were written independently of the production
splitter. Reusing a manually specified condition object in two explicitly selected
arrays is serialization convenience; no recursive claim classifier was used.
Root existential binders remain in the claim universe. Negated positive bodies,
universal components, and disjuncts are embedded; only their full root conditions
are asserted. Each ordinary-or fixture requires `either=false` and
`scope_ambiguous=false`, preventing a canonical OR match from hiding a provenance
marker disagreement. Reported contents retain the speech-source chain and never
become assertions. Gold fixes structural order and written-case proper names;
`no_universal` uses the design-selected negated-existential encoding. Its root
negation is asserted and both predicates in its existential body are embedded.
The equivalent universal-negative implication is not an accepted structural
alternative. This convention was fixed before any parser observation.
Predicate lemmas are lowercase, including `american`; entity constants retain
their written case.

## Deferred constructions and why

- **Never / temporal generics:** `folio-val-163`, context line 0, “A hawk never
  lands.” requires both a generic subject decision and quantification over
  times/events. The current fidelity schema has no agreed temporal semantics.
  Replacing it with ordinary `not land(hawk)` would erase the very distinction
  being tested. There is one observed source sentence; inventing a second hawk
  example would not increase sample coverage. No scored gold for this group yet.
- **Recurring cardinality:** `folio-val-175`, context line 5, “at least once a
  day” needs events and daily recurrence. Neither `once` nor `day` can be dropped.
  At-least-one **individual** fixtures here instead need only an existential
  child, with `child(x)` and `have(John,x)`. They do not license a claim of numeric
  or temporal cardinality coverage. Exactly/at-most n would require a separately
  justified distinctness and quantifier design, even though equality can encode
  some such meanings in principle.
- **Modal permission / scalar money:** `folio-val-93` uses “allowed”, “can”, and
  a security-deposit bound. An uninterpreted positive permission predicate would
  not capture the full modality; treating money strings as ordinary individuals
  would not provide arithmetic. Gold is blocked pending the design contract.
- **Attitudes:** a lexical scan of committed sample contexts and statements for
  believe/say/said/know-that found no propositional-attitude candidate. “Commonly
  known as Ailton” (`folio-val-200`) is naming, not a factive complement. The two
  explicit say controls test the epistemic boundary but are **not** evidence for
  FOLIO attitude frequency or coverage. Factive projection remains separate work.
- **Mass nouns and implicit domains:** “Some affection is love” (`folio-val-121`)
  is not included by pretending mass nouns denote countable individuals. A
  declared domain/mereological convention is needed before it becomes scored gold.
- **Broader syntax:** possessives, relative clauses, named multiword entities,
  background markers, passives, tense, and coordination of complex predicates
  remain unrepresented by this small slice. The inventory, not this fixture file,
  defines the outstanding construction denominator.

## Validation record

Prediction (2026-10-14, before validation; root also records it in research LOG):
all 12 rows should satisfy the independent fidelity schema, with unique IDs,
explicit scoped DRS/claim tables and two fixtures per group. This checks fixture
well-formedness only; no parser, solver, benchmark or model is launched, and no
exact-fidelity result is predicted or claimed here.

Result: schema validation passed all 12 fixtures (six groups × two cases), and
all ten source locators were independently verified against context lines. Two
verbatim matches, eight documented adaptations, and two authored controls.
Final no-quantifier convention was reviewed and schema-checked before any parser
observation. No measured parser fidelity is reported by this change.
