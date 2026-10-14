# Nested ProverQA gold — prediction and scope

2026-10-14, before schema validation or parser measurement: predict that ten
hand-authored readings will pass structural schema and complete OR-path checks.
This predicts format consistency only, not parser fidelity. No parser observations,
answers, proofs, or generated formulas were consulted to determine expectations.
Input-only provenance is from the root ignored cache
`research/runs/linguistics/other-refresh/proverqa-unique.jsonl`.

Five diagnostic families have two cases each: conditional consequent inclusive OR,
conditional consequent explicit XOR, accessible antecedent witness, antecedent
conjunction, and antecedent OR. Two OR-antecedent cases are deliberate minimal
contrast adaptations of input conjunctions; they are not claimed as untouched
corpus sentences. One binding case substitutes patient for passive respected to
isolate reference accessibility. The cat/nimble example overlaps earlier gold and
must not increase the distinct-sentence denominator when suites are combined.

Each implication alone is asserted. The explicit not-both condition is inside its
consequent, hence Embedded, not a second top-level assertion. Embedded tables are
specified independently in preorder, including nested OR/NOT and repeated atoms.
Either markers target only the scoped OR. Indefinite antecedent references remain
accessible to consequent pronouns; names introduce no synthetic existential.
Noun heads precede modifiers. No no-determiner occurs (global no=negexists policy
is unchanged). Copular nominals are direct predicates. Reviewer rejected plain expert(x)
for the subsective expert researcher source. The diagnostic now explicitly adapts
that source to tall researcher, an intersective modifier; the original subsective
construction remains unresolved and outside this diagnostic set.

Selection leaves modal/temporal, not-necessarily-both, causality, events, particles,
and discourse anaphora outside this small representable diagnostic set. In
particular literal not-necessarily-both is not NOT-both; it must remain unresolved
rather than become XOR. The input cache contains those exclusions; this set is not
a random sample or complete denominator for the >=90% construction fidelity gate.
Reviewer approval must precede any parser measurement.

First schema check failed because the handwritten serializer used `box` rather
than required `body` for NOT. Corrected that field only; intended meaning unchanged.
Prediction for repeat: all ten schemas and full OR annotations validate.

Repeat result: `validate_case` passes all ten rows, two per construction family;
IDs unique and every OR has a valid complete marker path. Expected claims were
specified as independent ordered lists, not derived with claimsOfDRS or by
walking the DRS. The schema check does not certify lexical or pragmatic choices;
review must assess participial determined as a dispositional adjective and the
declared coordination bracketing. No parser run occurred.

Reviewer correction before repeat schema validation: changed expert researcher
to explicitly adapted tall researcher, preserving conditional/OR/pronoun shape
without conflating subsectivity with intersection. Counts now six exact sentences
and four disclosed adaptations. Localized Goofy/Cupcake notes. Prediction: all ten
schemas and source/adaptation references remain valid; no parser measurement.
Result: ten schemas and ten input-only source locators pass; all six exact cases
match their source text. Four adaptations have explicit rationale. No source
labels/proofs or parser outputs were read during this correction.
