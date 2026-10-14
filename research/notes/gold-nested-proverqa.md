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

## Approved frozen construction diagnostic prediction — 2026-10-14

Shell and branch verified with inherited full access. Before execution, predict
that the ten approved nested constructions will mostly be no-parse or wrong-but-
typed, because closed either licensing, quantified/pronoun binding and explicit
not-both remain unimplemented. Ground conjunction may be easier, but no exact
rate is presumed. Keep gold fixed after observing results. This is a ten-sentence
construction diagnostic, not an answer benchmark or model run.

Command (shared corpus lock covers the entire scorer/parser subprocess):
`python3 /home/gram/nl2proof-astra/scripts/with-ccgbank-slot.py python3 test/fidelity/fidelity.py --cases test/fidelity/proverqa-nested.jsonl --binary /home/gram/nl2proof-astra/research/runs/integration-fidelity/fidelity-frozen --parser default --output research/runs/nested-baseline/default.json --timeout-seconds 600`

### Frozen result

Exit 0, 86.96 seconds; prediction of mostly failed selected meanings held.
Binary SHA256 `5b3f5e9fe4fbe58928bd6d43facc8657cf344c80a55fd06afc8b79f27dc7f035`;
gold SHA256 `3798999a1711d87a4b8eb99686735fc95f6b53389f2c49b3e278c5b2aeaded04`.
Ignored evidence in this worktree: `research/runs/nested-baseline/default.json`
and `default.observations.jsonl`, plus parser stderr. Preserve/transfer these
before removing the worktree. Source hashes in the report describe scorer-time
files; they do not prove what source compiled the frozen binary.

| Construction (two cases each) | Exact | Wrong but typed | No parse | Any-reading exact |
| --- | ---: | ---: | ---: | ---: |
| Consequent explicit XOR | 0 | 0 | 2 | 0 |
| Consequent inclusive OR | 0 | 0 | 2 | 0 |
| Shared antecedent pronoun | 0 | 2 | 0 | 2 |
| Antecedent conjunction | 0 | 0 | 2 | 0 |
| Antecedent disjunction | 0 | 0 | 2 | 0 |
| Total | 0 | 2 | 8 | 2 |

No errors, type failures or incomplete cases. Selected fidelity is 0/10; the
secondary any-reading score is 2/10 and must not replace selected fidelity.

First divergences supported by sealed parse evidence:

- Both XOR inputs lack interpretable categories for `he` and `but`. Goofy's
  conjunction and adapted disjunction lack an interpretable `he`. These lexical
  failures precede composition; they do not prove the remaining operators work.
- Muffin/researcher consequent OR and Cupcake antecedent AND/OR report no derivation
  to S. The exporter does not include enough category/tree evidence to isolate an
  earlier cause. Do not label these proven either/coordination-only failures.
- Both binding cases select `(antecedent→consequent) ∧ consequent` instead of the
  single conditional. This extra top-level atom is already present in the typed
  λ-form, before DRS construction or claim splitting. Antecedent accessibility
  succeeds for the inner consequent, whereas the duplicated outer consequent has
  an unresolved `?it_7` / `?they_6` constant. Claim splitting faithfully asserts the
  unwanted top-level atom: this is a semantic-composition/selection defect, not
  evidence that the claim boundary itself lifts an embedded atom.
- Retained reading index 1 for both binding cases has the exact independently
  authored DRS, claims and marker list. Its pronoun resolves correctly. Selected
  reading index 0 wins by supertagger log-probability according to the trace.
  Consequently a blanket anaphora repair would target the wrong first seam;
  inspect the extra-conjunct derivation before implementation.

Gold unchanged after observations. No success claim for construction gate, and
no new implementation is authorized by this baseline without review.
