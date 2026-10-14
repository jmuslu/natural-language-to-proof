# ProofWriter NatLang: attribution candidates blocked before gold

Three complete actual input sentences were recovered and verified. **No runnable
fidelity gold is added:** their full representation contracts are unresolved.
The [blocked-source ledger](proofwriter-natlang-attribution-blocked.json) records
exact wording, file hashes, record/field locators, presented-theory character
spans and the questions that must be settled. It contains no `gold` field and
must not be loaded as a fidelity fixture. No sentence was simplified or given
its hidden controlled interpretation.

## Input evidence and scope

The existing 110-file inventory's attribution cue reproduces 32,684 physical-file
occurrences across 487 distinct strings. This is a lexical cue total, not a
semantic reporting family. The cue list includes say/said, think/thought,
know/known, notice, seem and appear; nominal `thought`, acquaintance `know`, and
appearance predicates can satisfy it without an asserted speech report.

Read-only queries inspected the inventory's text, frequency and source locator
columns. Direct source verification then projected only `id`, `theory` and
`sentences` for the three selected records. No answer, proof, hidden logical
representation, or controlled triple/rule text was used. File SHA256 values
match the existing inventory manifest. The complete selected sentences occur
verbatim and uniquely in the raw presented theory at the ledger's offsets.

| Actual complete sentence | Exact standard-file locator | Physical occurrences of this exact sentence |
|---|---|---:|
| Alan is also said to be very kind. | `CWA/NatLang/meta-test.jsonl`, line 288, `AttNonegNatLang-CWA-161`, `sentences.sent1`, presented sentence 2 | 8 |
| Bob is known to be rough and green. | `CWA/NatLang/meta-train.jsonl`, line 60, `AttNonegNatLang-CWA-1374`, `sentences.sent1` | 74 |
| A young someone is red in thought but green in ideas. | `CWA/NatLang/meta-train.jsonl`, line 149, `AttNonegNatLang-CWA-647`, `sentences.sent7` | 200 |

These are three different construction diagnoses, not three independent
reporting templates. Physical multiplicities include stored world/bucket/stage
repetitions and must not be treated as independent semantic observations. The
exact simple passive-known surface across names has 806 occurrences / 8 strings,
but that does not settle the missing knowledge-holder representation.

For the first selected item, `sentences.sent1` joins two clauses with a semicolon
while authoritative `theory` places a period at that boundary. The verified
second presented sentence is retained exactly; its preceding discourse remains
relevant to `also`. Verification reused the inventory's explicit punctuation
alignment and independently checked raw-theory substring offsets. This is not
a new sentence rewrite. No conclusion about a general tokenizer follows.

## A. Passive reporting with additive and degree scope

`Alan is also said to be very kind.` is reporting/evidential wording. Alan is
the subject of the embedded predicate, not thereby the reporter. The additive
`also` and degree modifier `very` are part of the source and cannot disappear
from an exact gold representation.

Unit 2 candidate frames are finite passive auxiliary plus a passive raising
report predicate, schematically `said:(S[pss]\NP)/(S[to]\NP)`, and a to/be
complement supplying the property of Alan. The modifier `very` must scope over
the adjective property inside the reported content. These are **proposed
analysis categories**, not observed CCGbank offers or a recovered derivation;
no corpus parser was launched.

Unit 3 needs a licensed treatment of the unexpressed report source. Neither an
arbitrary existential reporter nor `say(Alan,P)` is warranted just by NP type.
Likewise, focus alternatives for `also` and degree semantics for `very` require
an explicit interface. An otherwise well-typed `say(unknown,kind(Alan))` drops
both modifiers and invents a source policy; it is not acceptable full gold.

Unit 4 boundary obligation: reported kindness must not become an ordinary
Asserted `kind(Alan)`. But that negative constraint is not a complete DRS and
claim table: the report event/source, additive presupposition, and degree
content remain unresolved. Do not silently use a partial claim constraint as
an exact fidelity label. This sentence stays in the blocked ledger until all
three choices are independently specified and reviewed.

## B. Factive passive knowledge with coordinated content

`Bob is known to be rough and green.` has no degree/additive modifier and is a
useful compact target, but its passive knowledge frame still lacks an explicit
holder contract. Treating Bob as the knower would reverse the relevant roles.
Treating the sentence as simply `rough(Bob) ∧ green(Bob)` erases the knowledge
predication and its commitment boundary.

Unit 2 again suggests a passive raising complement,
`known:(S[pss]\NP)/(S[to]\NP)`, with coordinated adjectival content. A future
Montague meaning must receive the shared embedded subject once while retaining
knowledge-source provenance. The empty `holders` array permitted by the JSON
schema is only syntactic permission: it does not establish an approved
impersonal-knowledge semantics. An existential knower, generic community
knowledge, and a contextual implicit source are distinct policy choices.

Under the project's factive-knowledge convention, the matrix knowledge claim
and the complement's Presupposed status must be represented separately. Both
roughness and greenness belong to the coordinated complement; no operator may
retain one and drop the other. Exactly how passive holder omission composes
with this projection must be approved before a full DRS/claim gold is written.
No passive contract is invented merely to populate the test set.

## C. A nominal cue is not an attitude

`A young someone is red in thought but green in ideas.` contains `thought` as
the nominal complement of `in`, not as a finite attitude verb with a propositional
complement. The inventory cue is therefore not evidence for a Reported claim.
The two PPs constrain or metaphorically qualify the predicates; deleting them
and asserting literal colors would change the source.

Unit 2 needs the indefinite nominal with its age modifier, property-modifying
PPs, and contrastive coordination. Unit 3 still needs a declared interpretation
of those PP-restricted/metaphorical predicates and of `but`'s contrast
contribution. Unit 4 must preserve the individual/young commitments warranted
by the eventual interpretation without promoting unsupported literal red/green
atoms. None of these decisions may be inferred from the dataset's synthetic
fact role. The whole sentence remains blocked rather than becoming an invented
unary label or a simplified color conjunction.

## Why there is no two-to-three-row gold family yet

Other short inputs such as `People think that Bob is round.` introduce a generic
or indefinite collective source whose quantificational force is not fixed by
an NP category. `Bob seems to be round.` requires an appearance/evidential
contract, not automatic speech attribution or actual-world roundness. More
explicit reports in the inspected buckets carry additional frequency, degree,
comparison, pronoun, temporal, or discourse operators. This audit establishes
specific blockers for selected inputs; it does **not** claim that all 487 unique
cue-bearing sentences are impossible to represent or that no tractable family
exists elsewhere.

The next bounded design step is the compact passive-known family: decide and
review implicit-holder semantics and factive projection, then independently
author 2–3 complete source controls with source provenance before parser
observations. Passive said with `also`/`very` additionally requires degree and
additive contracts. Keep the lexical thought counterexample as a boundary
control so a word-based reporting rule cannot promote it into an attitude.

The [primary-source comparison](../REFERENCES.md) remains relevant: Boxer 2008
separates lexical/category evidence from construction and discourse resolution;
ccg2lambda's paper explicitly leaves factive presupposition projection outside
its scope. Neither supplies an automatic license for our empty-holder passive
contract. The existing direct active reporting implementation and its typed
terms do not resolve these source-level choices by themselves.

Validation is input verification and document/ledger consistency only. No parser,
model, answer benchmark, corpus load, source implementation, or gold alteration
was performed. The linguistic fidelity gate remains closed.
