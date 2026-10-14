# Independent ProverQA relatives and overt inclusive consequents

Shell verified in /home/gram/astra-wt/gold-prover-relatives on
astra/gold-prover-relatives. Scope: this note and
`test/fidelity/proverqa-relatives.jsonl` only. Source selection reads context
English, not answers, proofs, formalizations, or parser observations.

Four exact source inputs, two per missing family: restrictive subject who with
universal everyone, and conditional consequents containing explicit *or both*.
Source paths, item IDs, zero-based split context indices, and unchanged wording
are recorded in every row. This is construction-selected diagnostic gold, not
random population evidence. Frequency cues959 quantified-who and776 or-both
(302 inside initial-if) motivate the families but are not additive strata.
No claim of covering all their lexical, scope, or argument variants.

## Unit 2: intended category derivation

*Everyone who is driven is persistent*: everyone NP; who ordinarily
(NP\NP)/(S[dcl]\NP); copular adjective clauses assemble from
is:(S[dcl]\NP)/(S[adj]\NP) and driven/persistent:S[adj]\NP. The subject-relative
VP combines with who, making NP\NP, then combines with everyone; the matrix VP
combines backward with the modified NP. In this context driven is the adjectival
motivational sense, not passive driving with an omitted agent. The second exact
case uses persistent/determined in parallel adjectival senses. No extra cause,
agent, event or person witness is implied by the adjectives.

The standard NP-relative category does not license putting the restriction in
the universal's consequent. NP semantics needs a restriction continuation (or a
coherent noun-level reanalysis) to get the intended reading. Applying an ordinary
NP predicate conjunction after quantifier closure is a scope error.

*If Cakes is dishonest, then he is either manipulative or isolated (or both)*:
if:(S/S)/S[dcl], then:S/S; adjective coordination builds one VP under a shared
subject; either marks the OR while the explicit parenthetical blocks exclusive
strengthening. The conditional consumes antecedent and full consequent clause.
Pronoun he binds the named antecedent subject Cakes; she similarly binds Bubbies.
Parentheses are meaningful scope delimiters here, not an instruction to discard
an exclusion/inclusion cue. The isolated adjective means socially isolated in
this property frame, not an eventive passive agent relation.

## Units 3 and 4: meanings fixed before parsing

Let P=e→t and Q=P→t. everyone has universal force with the lexical restriction
person; the relative adds driven/persistent to that restriction. Intended forms:

- forall x((person(x) and driven(x)) implies persistent(x)).
- forall x((person(x) and persistent(x)) implies determined(x)).

This strict-English person restriction is explicit. Earlier starter *Everyone*
fixtures deliberately used an unrestricted diagnostic-domain convention; these
rows do not import that simplification. Do not mix the two conventions without
reporting their different gold assumptions. No global domain axiom is supplied.

DRS: `[ | [x | person(x), driven(x)] => [ | persistent(x)]]`, and the parallel
persistent/determined case. Person and relative property share one antecedent
binder, antecedent first; the entire implication alone is Asserted. All three
atoms are Embedded; Reported and Presupposed are empty. The relative adds no
existential import and no independent fact that everyone is driven.

For each overt-inclusive conditional, let A be the antecedent property and B/C
the two consequent properties of the same named subject. Meaning `A => (B or C)`.
Explicit *or both* rules out XOR: A=true,B=true,C=true must satisfy it. The
parenthetical is a semantic inclusive-clarification operator on this coordinated
pair, not a third alternative with independent truth conditions. We choose the
plain inclusive OR normal form before parsing, rather than retaining redundant
`(B or C) or (B and C)` structure. This choice is not inferred from outputs.

DRS root contains only implication; its consequent contains one OR with each
property in its own box. Only the implication is Asserted; A, OR, B and C are
Embedded in traversal order. No atom is independently asserted, no negated-both
condition is licensed, and no additional witness is introduced. The OR's schema
annotation is `either=true,scope_ambiguous=false`: this preserves lexical either,
not exclusivity. Current metadata lacks a separate explicit-inclusive override.
Consequently these gold rows test exact English DRS/claim fidelity but cannot by
themselves certify a solver's benchmark-level XOR policy. A downstream rule that
turns every either=true into XOR is invalid on these sentences. Document/repair
that distinct contract rather than corrupt the gold to deny the both-true model.

## Source comparison and independent-review obligations

[Boxer 2008](https://aclanthology.org/W08-2222.pdf) separates category-driven
composition from lexical selection and resolution (§§3.2–3.3). Adopt that
separation and scoped DRS binding; do not infer claim-status/oracle guarantees
from its parsing coverage. Adjectival sense/voice is a lexical obligation, not
settled by the word's morphology alone.

[ccg2lambda 2015 templates](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_emnlp2015.yaml#L564-L573)
use an extra NP restriction slot for relatives; adapt that distinction to our
interface instead of pasting terms with incompatible NP types. For disjunction,
retain shared-subject coordination and reject importing the audited sentence-or
entry that conjoins sentences. Neither source is gold for this English's overt
inclusive cue; its both-true countermodel decides the truth conditions. See
REFERENCES.md/TEMPLATE_COMPARISON.md for the pinned source audit; no upstream
runtime is claimed.

Prediction before validation: four well-formed independent rows, two per group,
all exact source-locator matches. Only schema/provenance checks, no parser,
CCGbank, solver, model, or benchmark run. Full tables explicitly authored; no
production splitter or parser supplies expected values.

Reviewer precheck agrees strict-English person restriction if convention departure
remains explicit. Contrast unrestricted *something*: exists x P(x) over the
entity domain does not entail person(x). A lexical *someone* does restrict to
person, whereas literal *some thing* may introduce thing. These cases must not
inherit starter unrestricted-everyone convention accidentally; root must audit
whole-gold contracts before interpreting pooled results. Reviewer also agrees
inclusive DRS plus lexical either=true, with unresolved downstream override.

Validation result: all4 rows pass fidelity.validate_case; both groups have2
examples; all4 locator matches reproduce exact context sentences. No parsing,
semantic output inspection, solver execution or external model invocation.
