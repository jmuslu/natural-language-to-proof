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

## Conditional chart regression prediction

Before standalone run: predict hand-tagged `If Bob is red, then Bob is big`
retains both p→q and (p→q)∧q readings through punctuation-coordination of S/S
functors, while comma-without-then, then-without-comma, ground comma coordination
and explicit and preserve their intended meanings. Command:
`runghc -isrc -itest test/ConditionalDuplicationSpec.hs`.
No corpus load; tests demand all retained readings correct, not merely one exact.

Mini-chart first result: four pass, comma+then fails exactly as predicted.
Hand-chart provenance confirms CoordMark(comma, then), followed by
CoordApply(if+antecedent, marked-then), followed by FwdApp to consequent.
A temporary source-only renderer printed rrSign provenance; no corpus loaded.
Expanded prediction before repeat: nested comma-separated conditional modifiers
and a coordinated consequent also retain contaminated readings. Added two controls
to force general scope rather than a single comma+then patch.
Expanded seven-check run: four pass, three fail (comma+then, nested conditionals,
and explicit-coordination contamination). The latter sentence has a genuine wide
conjunction attachment as well as narrow consequent conjunction. Corrected that
new test's authored acceptance list to retain both legal attachments rather than
conflating ambiguity with contamination; nested benchmark gold remains unchanged.
Repeat prediction: same three failures, with duplicated consequent excluded from
both legitimate scope alternatives. No production source was edited.
Final authored control run confirms 4/7 pass, three intended red failures. Test is
standalone and not cabal-registered; coordinator owns cabal and production fixes.
Reviewer should approve the conditional-role guard and acceptance controls before
implementation. This result does not represent a regression in an existing suite.

Before production edit, add reviewer-required completed-conditional comma and
completed conditional inside report neighbors, plus nested report delimiter.
Prediction: first two contain their intended completed-clause coordination;
nested report may expose the same duplication inside its complement. These tests
use independently composed attitude terms, never cached parser output as gold.
Run `runghc -isrc -itest test/ConditionalDuplicationSpec.hs` (no corpus).
Before fix, expanded10 controls:6pass/4fail, including duplication inside reported
complement; completed conditional comma neighbors already pass.
Bounded implementation candidate: boolean pending closed-conditional role,
propagated until complete S and included in packing key; reject comma CoordApply
only for S/S or S\S modifiers carrying it. No global comma/coordination change.
Prediction:10 controls pass with completed/report neighbors preserved. Reviewer
consultation is pending; source-only tests are diagnostic before approval/merge.
Reviewer requested nested antecedent and type-raising controls. Added both plus
explicit and/or coordination of open conditional modifiers. Prediction before run:
nested antecedent and explicit operators pass; type-raised modifier may expose a
category-shape bypass of the initial S/S-only guard, which must be resolved before
source approval. No corpus use; same standalone command.
The raising prediction held: nested antecedent and explicit and/or pass, but
raised modifier coordination bypasses a literal S/S-only guard. Extended category
recognition through the same opposing-slash type-raising shape as unarySem;
retained boolean role still distinguishes open from completed conditionals.
Prediction before repeat:14/14 pass. No blanket all-functor ban introduced.
Recursive category extension still fails the all-exact raising check. Provenance
shows a DIFFERENT defect: BwdXComp(if, raised antecedent) reverses implication,
with no unwanted conjunction remaining. Earlier bypass inference was premature.
Before comparing a temporary source-only basic-guard copy, predict its raised
readings include both reversal and duplication; inspect actual forms before
claiming which extension is necessary. Working production file is unchanged by
this temporary-copy comparison.
Temporary basic-guard comparison verified BOTH defects: A→B and B→A, plus each
conjoined with B. Recursive raising recognition removes only the duplicated-B
readings. Added a second metadata bit seeded only by an actual unary raising step;
it participates in packing and is cleared with the pending role at complete S.
This avoids treating a merely isomorphic lexical category as a raised obligation.

Targeted14 controls now pass. Preserve the wider raising-direction expectation
under `--raising-audit` as a documented known failure (expected-red), rather than
silently accepting reversal as exact. Before full suites predict existing suites
remain green; raising audit remains red for the independently exposed reversal.
Commands: `runghc -isrc -itest test/ConditionalDuplicationSpec.hs --raising-audit`;
`cabal test all -j2` in this worktree. New standalone controls are not registered
in cabal here because the coordinator owns that file. All corpus-backed tests
must remain opt-in; no new corpus run is requested.
Reviewer approved concrete source candidate for coordinator integration/gates,
with bounded-composition/raising history and fragile closed-entry gloss identity
explicitly documented. This does not approve claiming dataset construction gate
met. Full suite build is live; no frozen gold was changed.
Full existing suite result: `cabal test all -j2` exits0; all13 suites pass,
1199 checks (386+115+116+89+44+131+97+57+29+53+22+30+30). Targeted standalone
14/14 pass. The separate `--raising-audit` exits1 as the explicit known reversal
failure. `git diff --check` clean. No cabal edits, no new corpus/model run.
Coordinator still must register new controls, rerun frozen/current fidelity and
all release gates on the integrated branch before push.
