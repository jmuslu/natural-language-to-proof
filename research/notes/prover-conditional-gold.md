# ProverQA unchanged conditional and named XOR gold

Full-access verified; isolated astra/prover-conditional-gold from acceptedd0054ee.
Own gold+notes only. Used input-only context strings from local dev/easy.json,
medium.json and hard.json via the existing inventory sentence splitter; no labels,
proofs, formulas, parser outputs, models, corpus or benchmark loads. Bounded
candidate display only; no bulk source export. Existing gold checked for duplicate
texts; none of the four selected texts is already present.

## Semantic derivation before observations

No parser output is consulted. Source sentences are unchanged, including either,
parenthetical but not both, punctuation and pronoun. Declared contract:
strict-English-explicit-xor-static-property-v1. Present-tense unary properties
are evaluated at a fixed contextual time, with time not separately represented;
conditional he/she binds the explicitly named subject in its own antecedent.
Lexical uninspired remains its own property, not silently NOT inspired.

For subject a and properties P,Q, define O(a)=[ | P(a)] OR [ | Q(a)] and
N(a)=NOT[ | P(a),Q(a)]. Named fact asserts both O and N. Its embedded traversal
is P,Q,P,Q: two occurrences each, not a deduplicated set. Either annotation marks
the OR node; the annotation alone does not encode not-both.

For source If ... either P or Q (but not both), then ... R, the whole condition
is IMP([ | O(a),N(a)],[ | R(a)]). Only IMP is Asserted. Embedded traversal is
O,P,Q,N,P,Q,R. In particular, neither the antecedent OR nor its NOT is Asserted;
both predicates true makes the XOR antecedent false, not an inconsistent global
assertion. No Reported/Presupposed content, no new referents, no dropped modifier.

Independent assignments:
- dev/easy.json record70/id70 context sentence7: Kenji; talented,dedicated;
  successful consequent.
- dev/easy.json record111/id111 context sentence0: Kora; cautious,impulsive;
  successful consequent.
- dev/easy.json record14/id14 context sentence0: Georgina; creative,uninspired;
  named XOR fact.
- same record14 sentence2: Beckham; creative,uninspired; named XOR fact.
The two named facts share a lexical pair and source record; they are name controls,
not independent lexical or population coverage. No quantified-XOR claim follows.

Unit2: named NP plus adjective VPs; compatible VP coordination shares subject.
Either scopes over that coordination; the explicit exclusion parenthesis adds
NOT of the same two predications. The conditional takes this entire antecedent,
then the consequent. These are intended category/binding requirements, not a
claim of current parser support for the full parenthetical construction.
Unit3: XOR(P,Q)=(P OR Q) AND NOT(P AND Q); conditional antecedent scope wraps the
whole expression. Unit4: boxes and claim multiplicities above are independently
specified, not inferred from structural scorer output.

Boxer2008 construction/resolution separation motivates keeping the pronoun's
local named referent and boxes intact; no verbatim event-DRS projection is claimed.
The pinned ccg2lambda2015 sentence-or entry102–106 uses AND, so it cannot serve as
this gold's oracle. Follow the reviewed REFERENCES/TEMPLATE_COMPARISON rather
than importing either annotation as XOR truth conditions. No upstream execution.

## Blocked ledger: inclusive antecedent OR remains unfilled

Coordinator explicitly agreed to preserve source XOR as a distinct family,
not relabel it inclusive OR to meet a count. Examples inspected but NOT frozen:
- dev/medium.json record295 context7: brave/determined antecedent; consequent
  includes can and successful pioneer. Modal force and modifier/nominal content
  must not be removed or reduced to a simple successful predicate.
- dev/hard.json record128 context8: timid versus takes risks antecedent. Light-verb
  risk-taking interpretation needs an independent lexical contract; no synthetic
  unary predicate introduced just to fill the OR slot.
- dev/medium.json record453 context3: grows in reverse/blooms in winter. Both
  modifiers require faithful temporal/directional treatment; neither may vanish.
These are compact locator descriptions, not rejected parser observations. Further
input audit may find a simpler inclusive example; this audit does not prove none
exists. Quantified XOR also remains unfilled by these four named examples.

No root fidelity denominator or dataset-membership entry changed. Reviewer approval
required before freezing/integration; no exact/wrong/no-parse statuses claimed.
