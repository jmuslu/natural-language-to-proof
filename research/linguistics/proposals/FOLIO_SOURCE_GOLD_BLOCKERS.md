# FOLIO source controls: retained gaps after the input-only audit

Three independent unchanged No-determiner sentences are proposed in
[test/fidelity/folio-source-controls.jsonl](../../../test/fidelity/folio-source-controls.jsonl).
They come from records 100, 147 and 28, not the previous No source 65 or its
repeated-context counterpart 63. All source bytes are verified against the
committed sample SHA256
`23ba94be7ce19de4f1345cd6849b1d916b1d65636b44548a22a6f7fc2b66561d`.
Line numbers below are one-based JSONL lines; context sentence indices are
zero-based newline-delimited input units, matching the existing inventory.
Only id/context/statement were inspected; no labels, supplied formulas, proofs
or parser outputs were used. No root fidelity membership changes are made.

## Complete proposed references

| Exact source text | Locator | Independently chosen full formula |
|---|---|---|
| No ugly person is handsome. | line 11, `folio-val-100`, context[1] | ¬∃x.(person(x) ∧ ugly(x) ∧ handsome(x)) |
| No young person teaches. | line 46, `folio-val-147`, context[3] | ¬∃x.(person(x) ∧ young(x) ∧ teach(x)) |
| No extraterrestrial is human. | line 98, `folio-val-28`, context[2] | ¬∃x.(extraterrestrial(x) ∧ human(x)) |

Contract `folio-current-context-no-v1` evaluates lexical properties in the
utterance context; young/ugly are retained restrictions, not erased scalar
modifiers. Teaches denotes the standing teaching property, not a newly asserted
teaching event. Nominal extraterrestrial/human classifications do not license
an extra lexical axiom that extraterrestrials cannot be human. The source's
negative quantifier supplies precisely that local exclusion. This is a narrow
full-sentence reference contract, not a generic tense/aspect abstraction for
all FOLIO language.

The Unit 2 candidate interface is `No:NP/N`, a modified noun restriction at N,
and an adjectival or intransitive VP. Unit 3 uses
`NO = λP Q.¬∃x.(P(x)∧Q(x))`; each modifier strengthens P, and the matrix predicate
is Q. Noun head precedes its modifiers in the declared structural order, followed
by Q. Proposed categories do not claim actual observed CCGbank offers.
Unit 4 binds r0 **only inside NOT**. The entire negated-existential condition is
Asserted; every head/modifier/matrix predicate is Embedded. Root universe,
Reported and Presupposed groups are empty. No witness or positive predicate is
asserted separately. There are no disjunction marker paths.

These are three source cases of the broad No construction, including two
modified-person restrictions and one unmodified nominal restriction; they do
not supply three controls for every verb/adjective/nominal cross-product.
They are distinct source sentences and records, not statistically independent
generator draws or a representative acceptance panel. No source fidelity result
or production-support claim follows from authoring gold.

## Exact blocked candidates, not executable gold

| Exact text and locator | Why no complete gold is assigned |
|---|---|
| Some basketball players are not American. — line 5, `folio-val-190`, context[0] | Existential witness and narrow predicate negation are clear, but basketball-player compound sense and American nationality/geographic sense need an independently declared lexical ontology. Neither basketball(x)∧player(x) nor a convenient sentence-sized predicate is licensed. Preserve the full compound; do not replace it with people. |
| There is at least one cove in Antarctica named after a place in Bulgaria. — line 84, `folio-val-119`, statement | Preserve existential cardinality, both locations, a second place witness, and passive named-after relation. The naming relation, passive reference/event treatment, and locative attachment contract are not settled. Isolating “one cove” would not test this source. |
| Ailton is a football player who was loaned out to Braga. — line 20, `folio-val-200`, context[1] | Full predicative-relative construction also contains a football-player compound, past passive particle and goal relation. Do not erase was/out/to-Braga or invent the original lender. Ailton/Braga referent licensing and full temporal/role contract must precede gold. |
| All people who have a wedding are people who have at least one child. — line 88, `folio-val-129`, context[0] | Universal person restriction and local child witness must be preserved, but eventive have-a-wedding versus parent/child have uses need separate lexical relation and time policy. Do not treat a wedding as an ordinary possessed object or replace the antecedent by a flat unexplained property to make a simple existential case. |

These rows remain blocked source evidence, outside the runnable fixture. Their
scope constraints alone are not complete DRS/claim references. No default
compound, nationality, passive or eventive-have contract was found in the
reviewed existing design; the reviewer confirmed those gaps before drafting.

A tempting alternate `folio-val-196:context[1]`, “All dogs are animals that bark.”,
is the **same text and repeated-context source family** as the existing
`folio-val-197` fixture. It is excluded as a new independent observation. The
other source examples above deliberately avoid pretending a renaming or a
repeated query context fills a gold gap. The inspected input filters were
bounded surface-candidate searches, not proof that no other tractable
construction exists in the entire FOLIO release.

The audit used the already committed 120-record / 744-unit / 439-surface sample.
No full-release search, new model call, CCGbank load, parser execution or
benchmark launch occurred. Existing fixtures and their historical results remain
unchanged. Negative-some, at-least-one and predicative-relative source gaps are
still open rather than falsely declared complete.
