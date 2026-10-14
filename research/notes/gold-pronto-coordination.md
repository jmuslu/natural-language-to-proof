# ProntoQA independent sentence coordination gold

2026-10-14. Full-access shell verified on astra/gold-pronto-coordination.
Owned only this note and test/fidelity/prontoqa-coordination.jsonl. English input
and locators were read from the previously sealed input-only unique-sentence
cache; no labels, hidden formulas, proofs or parser observations supplied gold.
No parser, CCGbank, solver, benchmark or model launch is authorized by this task.

Seven new unchanged source sentences: one AND-relative/negative-consequent case,
three distinct-subject sentence conjunctions, and three sentence comma lists
whose final conjunct is negative. The first completes the thin semantic subgroup
with existing pronto-nested-negative-3; its construction label matches the old
relative_negative_consequence label, but the AND subtype is explicit in notes.
The seven texts and IDs must not duplicate any existing fidelity file. Input
locators include demonstration membership, not just example number; each index
is zero-based under the inventory's sentence segmentation.

## Independently chosen meaning and derivation

Units 2/3: names are NP with generalized-quantifier meaning lift(name), property
nouns are N:e→t, and predicative a/an N classifies the subject directly. No new
referent/equality is licensed by predicative articles. Full named clauses derive
S[dcl], then sentence conjunction has category (S\\S)/S and term
λq:t.λp:t.(p∧q). Distinct subjects remain in their own predicates; this is not NP
coordination or a VP that distributes one subject across both clauses. Written
name case and predicate order are preserved.

Comma lists are three whole S clauses: commas delimit conjuncts and final and
licenses the conjunction. Final full stop preserves the S meaning. These examples
do not license deleting punctuation in attribution/apposition/nonrestrictives.
Their formula is P(name)∧Q(name)∧¬R(name), not ¬(P∧Q∧R).
DRS flattening yields two positive conditions and a negative child box. Unit 4:
positive conditions and whole negative box are Asserted; only R inside negation
is Embedded. No Reported, Presupposed or Confirmed claim is licensed.

The relative example means ∀x((brimpus(x)∧dumpus(x)∧jompus(x))→¬grimpus(x)).
Everything uses the existing controlled unrestricted-domain convention, without
an extra thing predicate. The relative clause adds restriction, not consequent
claims. A bound r0 lives in the implication antecedent and is accessible in its
consequent; no root witness is introduced. Only the implication is Asserted;
the three restriction atoms, negative consequent box and its positive atom are
Embedded in preorder. The manually specified arrays are not produced by the
production claim splitter. Conjunction association disappears into the declared
ordered condition list, so no parser-fitted alternate gold readings are added.

For category architecture, DESIGN's bounded subject-relative reanalysis uses
(N\\N)/(S[dcl]\\NP) with λV.λN.λx.(N(x)∧V(lift(x))) before quantification;
CCGbank NP-modifier attachment instead requires the separately designed restriction
interface. These gold structures constrain either implementation; they do not
claim the current parser already supplies an appropriate derivation.

Comparison uses the reviewed local TEMPLATE_COMPARISON.md and REFERENCES.md:
Boxer (Bos 2008) composition and resolution motivate retaining binders/scopes;
ccg2lambda's 2015 coordination rules distinguish VP shared-subject conjunction
from sentence composition, and its punctuation rules distinguish comma functions.
Adopt truth-functional AND for sentence conjunction, adapt categories to this
project's NP type, and reject globally treating punctuation as identity. The
NP* relative restriction interface cannot be pasted into current Q types. The
published sentence-OR conjunction counterexample is irrelevant permission for
changing these English ANDs, and is a reason to check meanings independently.
These are contract comparisons, not new empirical tests of Boxer/ccg2lambda.

## Prediction before validation

All seven cases should pass independent gold schema validation with unique IDs
and texts, exact cache source/text/index matches, no overlap with existing gold,
and group counts 1/3/3. The relative case should have one asserted implication
and five embedded entries; comma cases should have three asserted conditions
and one embedded atom; distinct-name conjunctions two assertions and no embedded
conditions. These are schema/provenance checks, not parser fidelity predictions.

Validation result: all seven schemas pass; seven unique IDs/texts, no overlap
with existing worktree gold, group sizes 1/3/3 and all expected explicit claim
counts. Cache lookup found every exact text and supplied its source/member/index;
only these seven compact authored meanings were written. No source or scorer
files changed, and no parser fidelity outcome is claimed. Prediction held.
