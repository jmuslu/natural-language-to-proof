# Independent fidelity scope-contract audit — 2026-10-14

Full-access shell works in assigned clean worktree. Read scorer, canonicalizer,
export seam and existing Python contracts; no parser or corpus/model process.
Own this note and test/fidelity/test_scope_contract_review.py only.

Prediction before adversarial tests: exact structural comparison should reject
changed witness identity, scope nesting, claim status and report-holder changes.
Gold scope validation should reject free refs and inaccessible inner witnesses.
Two likely gold-admission gaps merit explicit expected-failure regressions:
canonical first-occurrence numbering is not enforced; a nested box can redeclare
an already-bound canonical identifier. These are fixture-validation concerns,
not demonstrated false-positive scores against correctly authored gold.

An additional audit will distinguish an intentionally independent claim table
from its validation: gold acceptance does not prove its Asserted/Embedded labels
are sound. No scorer or production changes authorized in this task. Run only
`python3 -m unittest discover -s test/fidelity -p 'test*.py'`.

## Results and limits

All original29 contracts still pass. New13 adversarial cases yield11 passes and
two explicit expected failures:42 total,40 passing,2 expected failures. Every
new fixture/observation is hand-authored; no parser, model, corpus or benchmark
launched. The report-holder fixture was checked against the documented claim
contract: the speech-act envelope is Asserted while its content is Reported.
This corrects fixture setup, not a change fitted to parser output.

**Structural comparison held for correctly authored gold.** Scope inversion,
independent versus repeated argument witnesses, free-variable mutation, missing
scope binders, claim promotion across negation/presupposition, and changed report
holder do not score exact. Antecedent binders reach consequents; binders inside
antecedent negation do not. A repeated reference in argument positions is valid
and distinct from redeclaring the binder. No false-positive exact match against
correct gold was found in these controls. This bounded audit is not proof of
all scorer or exporter behavior.

**Counterexample 1: canonical numbering admission.** Gold
`[r9 | dog(r9)]` with matching contextual Asserted `dog(r9)` passes validation.
Production `canonicalize` numbers first appearance from r0, so this cannot be a
canonical export of that one-witness structure. Wire comparison deliberately
does not alpha-normalize: canonical `[r0 | dog(r0)]` would be marked wrong against
this accepted gold. This is a false-negative route through malformed gold, not
a claim that semantically different valid meanings collide. The expected-failure
test asks validation to reject noncanonical numbering; a future repair should
validate once at fixture admission, not normalize both sides and mask exporter
renaming regressions.

**Counterexample 2: canonical binder redeclaration.** Gold
`[r0 | cat(r0), not [r0 | dog(r0)]]` passes validation. Canonical identifiers denote
global reference identity; the inner binder cannot be assumed an innocent new
variable with the same spelling. For an independent nested witness it must use
r1, whereas a coreference use of the outer witness needs no new declaration.
The expected-failure test requests rejection of this ambiguous/malformed gold.
Check any intended repeated-declaration convention before changing admission;
this audit does not silently redefine canonicalization or existing DRS semantics.
The current code checks each universe's uniqueness independently and unions bound
sets, so it cannot distinguish this redeclaration from legitimate accessibility.

**Independent claims remain a human-review trust boundary.** A separate authored
counterexample used DRS `[ | not [r0 | red(r0)]]` but an incorrect expected claim
table asserting both the negation and `red(r0)`, with no Embedded atom. Validation
accepted it, and an observation mirroring it scored exact. Every reference occurs
somewhere in the DRS, satisfying the current reference-membership check, despite
crossing a status/scope barrier. This is not a false positive against correct
gold: the expected claim table is itself wrong. It demonstrates why schema-valid
cannot mean independently reviewed. A future narrow sanity check could require
Asserted conditions to occur at admissible main-box positions without deriving
the complete expected table through production splitClaims. Do not replace the
independently authored table with scorer-generated classifications. No such
change is made or claimed necessary for this bounded audit.

Alpha-renaming responsibilities: source inspection confirms Canonical uses one
first-occurrence map across the whole DRS, including nested refs and attitude
holders. Python receives canonical output and compares it structurally; it does
not perform raw-variable alpha-conversion. The added test exercises this wire
boundary only, not a fresh runtime test of Haskell canonicalize. Status, order,
multiplicity and witness sharing remain explicit. Observation protocol and
retained-alternative consistency beyond these13 cases were not reaudited.

Recommendations: retain both red admission contracts with explicit expectedFailure
until the coordinator chooses the canonical-gold policy; independently review all
new gold claims; repair admission separately from production semantics if approved.
These findings do not justify scorer changes, denominator pruning or releasing
the ProverQA gate. `git diff --check` passed; only owned audit/test files staged.
