# Independent extended FOLIO gold

Owner: gold-folio-extended specialist. Shell verified in isolated branch
astra/gold-folio-extended. Own only this note and test/fidelity/folio-extended.jsonl.
No parser, solver, model, or CCGbank process supplies these meanings.

## Selection and semantic decisions before validation

The first FOLIO gold slice lacks universal nominal classification, indefinite
conditionals with bound object pronouns, and predicative restrictive relatives.
These are selected from the inventory's high-frequency areas:117 universal outer
units,114 conditional-initial outer units, and83 overlapping relative cues.
Those counts are not exact counts of these scoped subfamilies. This bounded
extension does not close the full439-unique-input FOLIO inventory.

Seven cases: three exact universal sentences, two exact animal conditionals,
one exact predicate-relative sentence and one explicit lexical adaptation.
All sources are committed sample context fields, with zero-based line indices.
The lexical variant substitutes cats/jump for dogs/bark to check the same
relative-head binding with different predicates; it is not another source fact.

Only English supplies meanings. During initial format inspection the first350
bytes of sample.jsonl inadvertently displayed extra label/formula fields for
folio-val-121; that item is excluded, those fields were not used, and all later
source extraction explicitly emits id/context only. Selected items are156,125,
and197. This records the exposure honestly rather than claiming no extra field
was ever displayed.

Hand derivations fixed before any validation or parse:

- Every/all P R: forall x(P(x) implies R(x)); no existential import. Universal
  implication alone Asserted; antecedent and consequent atoms Embedded.
- If an animal barks, then Jane does not like it: universal conditional over an
  antecedent animal witness. The pronoun denotes that witness, not Jane; like's
  arguments are Jane then witness. Negation stays in the consequent. Full outer
  implication Asserted; animal, bark, whole inner negation, and like Embedded.
- If an animal jumps, then Jane likes it: same antecedent binding, positive
  consequent, no unsupported premise asserted independently.
- All dogs are animals that bark: universal dog restriction; animal and bark
  both classify the same dog in the consequent. The relative restricts the
  predicative nominal, not the universal subject. It must not strengthen the
  antecedent to dog-and-bark or introduce a second animal witness. Singular
  predicate lemmas and noun-head-before-relative condition order are fixed
  independently. The cats/jump variant has the same structure.

Reported and Presupposed empty; no disjunctions, so explicit empty disjunction
metadata. DRS objects and each claim array are authored directly; no production
claim splitter generates expected status. Small serialization helpers below the
surface authoring step only construct terms/boxes, never infer the claim table.

Prediction before schema/source checks: all7 cases validate, group counts3/2/2,
six exact input matches and one disclosed lexical adaptation. This validates
well-formedness and provenance only, not parser fidelity. Review required before
integration; no gold changes justified by observed parser output.

Validation result: fidelity.validate_case accepted all7 rows, IDs unique,
construction counts3/2/2; six exact source-input comparisons pass and the seventh
locator verifies original dogs/bark before disclosed cats/jump adaptation.
No parser fidelity measurement performed. Generation helper remains /tmp, not
committed; committed fixtures contain explicit full DRS/claim tables.
