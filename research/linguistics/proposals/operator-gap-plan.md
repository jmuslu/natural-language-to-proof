# Bounded `but` investigation: contrast versus exception and ellipsis

Proposal only; base990760f. No production change or new parser measurement.
Learner route: Unit2 categories/derivations; Unit3 typed meanings; Unit4 nested
boxes and independent claim status. `but = and` without a construction license is
not the proposed rule.

## First divergence and priority

Accepted cache `research/runs/expanded-gold167/explain.log`, lines70–86, for
`Everyone is either spiritual or atheistic, but not both.` (person-pronoun-2 in
its13-input manifest) stops **at lexicon**: `but` offered `conj` and `(NP\NP)/NP`,
neither interpretable. The manifest identifies producer source183f0ec and binary
SHA256 a3a2191ae7d6bd4ba46d559eed8d441b21399531f150e851e77e4dac7c0f5bf3.
This is the first reported failure, not proof that adding `but` will complete the
sentence. Best displayed tags also give Everyone:N, either:N/N, spiritual:N,
atheistic:N, both:N/N. Displayed best tags are not all offered categories.
The preceding inclusive `(or both)` case already reaches syntactic S but has no
semantic derivation, demonstrating an independent ellipsis/attachment obligation.

Input-only unique cache bb4787e94e99f97f41f5aa0045e307aa05043ce769d5d2cc2a627e8b4013269e,
weighted by stored occurrence multiplicity: word `but`4409, exact contiguous
`but not both`4146, `but not necessarily both`143, `either`5632. Existing inventory
has5279 initial conditionals,4146 explicit not-both,145 not-necessarily-both
(any position),776 or-both. These overlapping counts do not add. The remaining
120 but occurrences after subtracting the two disjoint exact phrases are NOT
certified simple contrastive coordination. Thus broad but-AND has no defensible
4409-case coverage claim; the high-frequency target is scoped explicit exclusion,
whose elliptical pair retrieval is harder than ordinary coordination. Prioritize
its independent contract/design after the currently reviewed nominal/token fixes;
implement full-conjunct contrast first only as a small prerequisite, not an
expected large fidelity win. No sample or acceptance estimate is drawn.

## A. Full contrastive conjunction: narrowly licensable prerequisite

Examples: `Bob is tall but Bob is quiet.`; `Bob is tall but quiet.`;
`Someone is tall but quiet.`. For already licensed complete operands,
`but:conj`, CoordMark + CoordApply yield same-category S and S\NP respectively.
A lexicalized presentation `(X\X)/X` abbreviates the same two-step derivation;
it must not silently admit new offered categories. Restrict initial repair to
finite declarative S and predicative/finite VP with the same features and semantic
type; neither NP nor N coordination nor arbitrary function types enter the rule.
For S: `λq.λp.(p ∧ q)`. For property-level VP: `λQ.λP.λx.(P x ∧ Q x)`;
for existing generalized-quantifier VP type use shared-subject coordination, so
`Someone` contributes ONE witness with `person(x),tall(x),quiet(x)`.
Do not implement VP as two independent generalized-quantifier applications.

At matrix S the two proposition conditions are Asserted. Inside `Mary says that
Bob is tall but quiet`, the conjunction remains Reported content; its atoms must
not escape as Asserted. Negation of the full coordination gives a NOT box with
both atoms Embedded. Preserve contrast as a provenance decision/stipulation:
truth-conditional conjunction does not represent the expectation contrast. No
extra fact or Presupposed proposition is licensed merely from `but`.
If the chosen fidelity contract requires that contrast itself be represented,
these cases remain explicitly incomplete until its representation exists.

Minimum source footprint after approval: reserve the lexical coordinator from
open-class/punctuation fallback; structural entry only at actually offered conj;
context-aware CoordApply operator selection checks exact output category and
operand provenance. Do NOT add unconditional `but -> TAnd` to coordinatorOp,
which lacks context. Keep but edges atomic barriers for the comma-list resolver:
`p or q, but r` must not inherit OR into but or reinterpret but as a list-ending
AND token. Preserve existing conditional/fused/reflexive guards and packing.

## B. Elliptical not-both: separate pair certificate, not ordinary AND

For explicit `either P or Q, but not both`, the intended property is
`λx.((P x ∨ Q x) ∧ ¬(P x ∧ Q x))`. For Everyone under strict English:
`∀x.(person(x) → ((P x ∨ Q x) ∧ ¬(P x ∧ Q x)))`.
The DRS asserts one implication; its antecedent introduces x with person(x);
its consequent contains OR([P(x)],[Q(x)]) and NOT([P(x),Q(x)]).
All consequent/subbranch atoms and exclusion contents are Embedded, never
unconditional matrix Asserted facts. The two-person model in which one person
has P and the other Q satisfies this sentence: `¬(∀x.P(x) ∧ ∀x.Q(x))` is NOT its
per-person exclusion. Countermodel: one person has both P,Q and another has P
only. Universal inclusive OR plus global not-both-universals holds, while the
intended per-person XOR fails. Asserted conjunction at the quantifier level is
too weak.

`both` here retrieves the two **specific antecedent alternatives** at the same
scope and subject binder. N/N intersection or lexical both(x) cannot do that.
A future distinct certificate must store two original alternative terms and
marker spans, binder/scope identity, and exactly one licensed elliptical tail;
require adjacency/attachment evidence and record discharge. Do not inspect a
normalized TOr subtree opportunistically. Nested ORs, more than two alternatives,
multiple either markers and intervening report/negation boundaries require
separate controls. Do not reuse the comma list certificate as proof of ellipsis.

Full explicit `P or Q, but not (P and Q)` can use ordinary clausal conjunction
ONLY when both operands really are complete at the same scope. The short `not
both` tail is not a complete S/VP without pair reconstruction. A global token
substitution, a sentence regex, or a parser-output-driven gold change is rejected.

## C. Negative controls and deferred constructions

| Input/control | Required outcome/meaning boundary |
|---|---|
| Everyone but Bob is tall. | Exceptive NP modifier `(NP\NP)/NP`; never AND. Restriction/exception and Bob inference need their own contract. |
| Nobody but Bob is tall. | Cannot mean nobody AND Bob; exception/polarity separately licensed. |
| Bob is not tall but quiet. | Corrective scope can assert ¬tall and quiet; reject automatic negation over both conjuncts. Correction/contrast status remains explicit. |
| Bob is not only tall but also quiet. | Focus/correlative construction; reject erasing not into ordinary negative VP. |
| Bob is anything but quiet. | Idiomatic exclusion; not a coordinated clause. |
| Everyone is P or Q, but not necessarily both. | Modal hedge is not literal NOT-both; abstain until modal contract. |
| Bob is either P or Q. | Inclusive OR unless explicit independent convention; no invented NOT. |
| Bob is P or Q (or both). | Inclusive OR plus overt marker/ellipsis; no exclusivity. |
| Bob is P or Q but R. | Preserve licensed `(P∨Q)∧R` or `P∨(Q∧R)` ambiguity; do not collapse to three-way OR. |
| Mary says P but Q. | Report attachment ambiguous; never infer both P,Q Asserted by flattening. |

Complete semantic gold needs2–3 independently authored cases per admitted
construction, including quantified subject, mixed-scope and negative controls;
these examples are proposed controls, not new input-derived benchmark gold.
Before implementation obtain reviewer approval of the category/provenance
license and contrast-status decision. Then pure lexical/chart controls, independent
DRS+claim tests, full suites, and coordinator fresh fidelity with predictions.
No broad either/both repair is authorized by the narrow conjunction prerequisite.

## Source comparison, with limits

Locally verified `REFERENCES.md` records Bos2008 §§2–3: category/POS/lexical
selection, compositional λ-DRSs and separate resolution. Adopt that separation
and explicit nested NOT/OR; no claim that Boxer supplies a verified not-both
ellipsis or exceptive-but solution. The locally recorded paper audit lacks
semantic gold (§5), so coverage cannot certify these meanings. This proposal did
not redownload or run Boxer. [Bos2008](https://aclanthology.org/W08-2222/).

Reinspected pinned local ccg2lambda2015 YAML at
`a68cb264413791150011c347c64a7b35e2f7270d`: lines72–99 provide surface-conditioned
and rules by S/NP/N/VP category; VP shares its quantified subject. Lines102–106
encode sentence-level or with conjunction (reject for this project). Lines204–206
make NP both an existential with two(x), not our elliptical property pair;
lines609–617 make selected either categories identity, insufficient to establish
marker attachment or XOR. No `but` lexical surface match appears in this file;
absence here is not a claim about all upstream templates. Adapt per-category
selection/shared-subject composition, reject wholesale import and erased markers.
[2015 templates](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_emnlp2015.yaml).
These are source comparisons, not upstream execution results.
