# ProverQA starter gold: scope and unresolved representation

`test/fidelity/proverqa.jsonl` contains 24 manually authored meanings, two for each
of 12 outer inventory families. ProverQA is LLM-verbalized rather than a finite
controlled-English grammar; outer families are surface inventory buckets. Sources are isolated English input fields from
local `proverqa/dev/{easy,medium,hard}.json`; row origins give item IDs, zero-based
sentence indices under the inventory splitter, and every simplification. No
answer labels, proof strings, formula fields, or production parser observations
were consulted. Fixed question wrappers are removed before interpreting a query
as a proposition. These compact examples are diagnostic controls, not a copy of
the dataset and not a random sample.

DRS structures and claim arrays were specified separately. A root implication,
negation, or disjunction is asserted as a whole; its children occur only in the
embedded array, retaining order and multiplicity. Antecedent indefinite witnesses
are available to conditional consequents, and proper-name pronouns reuse their
constant. Predicative nominals classify an individual directly, while the object
of possessive *have* introduces an existential witness. Both arguments of a
transitive verb remain explicit. Ordinary *or* and *either … or* receive distinct
exporter annotations; an overt *but not both* adds a negated conjunction rather
than silently disappearing into a marker. Bare *either* marking alone does not
prove a universal linguistic XOR reading.

These are agreed fragment conventions, not semantic conclusions from benchmark
labels. Names preserve written case; verbal inflection is lemmatized; everyone
uses a stipulated domain-wide diagnostic reading without adding a person
restriction; this is not a general-English rule or an independently established
property of every ProverQA verbalization. The singular indefinite controls use the episodic existential
reading. The topical universal examples treat *born* as a property, not an event.
The attributive *thriving* example assumes intersective property predication.
Broader tense, event, kind, and generic readings require a representation decision
and further gold; adding a convenient alternate parser output is not such a
decision.

## Coverage limitations block the resume gate

The 13th outer family, `subject_modal`, remains **unscored and unsupported** in
this starter set. For example, local `dev/hard.json`, item 197, context sentence
13 is “Frankie can fly.”, and sentence 10 is “Kendall can fly.” A positive fly
claim would erase capability modality. `att` is an attitude/reporting operator;
using it for *can* would fabricate a reporting source. The current gold schema
has no explicit modal operator, and no capability predicate convention has been
approved. These cases must count as a missing construction, not be dropped from
any gate denominator or treated as exact/abstaining parser successes.

The inventory `unclassified` family is a residual surface bucket with thousands
of occurrences. Its two lexical-intransitive controls do **not** establish
coverage of its particle, PP, reflexive, transitive, adverbial, or multiword-name
subcases. Likewise two simplified singular-indefinite controls do not cover
generic indefinite rules; the quantified-pronoun controls do not cover the
relative-clause subfamily. `for_topic` controls use topical universal XOR and do
not cover hedged exclusivity, named topic pronouns, or nested conditionals.
In particular, *not necessarily both* does not entail *not both*: examples with
that hedge require modal treatment and cannot safely use the XOR gold.

Consequently even 24/24 exact would only mean success on these controls. It would
not establish the owner's ProverQA construction fidelity target or authorize new
benchmark/model launches. Before a gate decision, expand the inventory crosswalk
to nested constructions, add independent gold for each supported semantic
subfamily, account for schema-blocked cases, and publish per-family exact,
wrong-but-typed, no-parse, and other harness failure counts with denominators.
