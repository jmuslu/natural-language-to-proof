# ProofWriter gold validation

2026-10-14 prediction before checks: 24 cases cover twelve controlled families
with exactly two independently authored cases per family; all should satisfy
the current DRS/claim/disjunction schema. Source audit should find each input or
explicitly described adaptation in its cited input field. Known prose defect:
Erin's question locator is correct but its adaptation description says theory;
correct it to question. No parser outputs, answer labels, supplied logical forms,
or proof chains are used. No parser/model/benchmark will run.

First check: all 24 schema-valid, twelve families × two. Source audit exposed one
additional locator defect: `pw-atom-transitive-neg-1` was adapted from the query,
not the theory, of `RelNoneg-OWA-D5-453-Q12`. Corrected its field and adaptation
note. Erin's adaptation prose corrected too. No semantic expectations changed.
Full110 inventory confirms no plain-intransitive pattern matches and 10 positive /
18 negative atomic modal occurrences; uncovered-construction notes now state this.

Manual claim review: all atoms are Asserted; negative boxes alone are Asserted
with positive bodies Embedded; each implication alone is Asserted with antecedent
then consequent Embedded in preorder (including nested negative boxes and their
bodies). No rule facts leak into root assertion. Antecedent r0 is accessible to
consequent predicates without appearing in the root universe. Unary nominal
heads precede restrictive modifiers. person/thing remain in explicit/bare
universal restrictors; unrestricted conditional something is separately explained.

Prediction before recheck: revised source locators all match; schema remains
24/24 with one reading per case and empty complete disjunction lists. No semantic
claim is inferred from a successful schema check.

Recheck passed: 24 schemas and source locators, 24 unique IDs, twelve families ×
two, one reading per case, complete empty disjunction annotations. Validation used
`fidelity.validate_case` and assertions against source English fields (including
adaptation source text before ` -> `); did not invoke the production parser or
claim splitter. Independent reviewer must approve meanings before integration.
