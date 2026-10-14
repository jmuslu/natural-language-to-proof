# Particle and directional-PP contracts before gold

Design proposal only, 2026-10-14. Read English inputs independently of parser
outputs, labels, proofs or benchmark FOL. No gold or production edits. This
extends the earlier [particles proposal](particles-reflexives.md), separating
source evidence, category analysis and the semantics still requiring review.
STUDY_PLAN Unit2 concerns categories/derivations, Unit3 lexical meaning/types,
and Unit4 witness scope and claim admission. A surface-token cue answers none
of those questions by itself.

## Six source-derived candidates, without deleting difficult words

Coordinates use the input-only unique-sentence cache's zero-based index. Theory
means context sentence; query means stripped input question. Each sentence below
is an exact isolated source sentence, not a simplified gold fixture.

| Family | Complete input sentence | Source coordinate | Unresolved obligation |
| --- | --- | --- | --- |
| Lexical particle | Raul gives up. | ProverQA dev/easy.json, item222, query0 | Select cessation/abandonment sense from the injury/perseverance context; retain multiword lexical identity |
| Lexical particle | Alisson wakes up early. | dev/medium.json, item54, theory2 | Preserve early as an event/time modifier, with a contextual comparison standard; do not erase it |
| Lexical particle | Justin does not easily give up. | dev/medium.json, item69, query0 | Scope of not and easily, plus dispositional versus episodic reading; not equivalent to simple not-give-up |
| Directional PP | Felix moves to Tokyo. | dev/easy.json, item206, theory2 | Preserve Tokyo as goal and Felix as mover; movement/relocation sense |
| Directional PP | Sugar moves to Tokyo. | dev/easy.json, item206, theory0 | Same construction with independent subject, no subject/object reversal |
| Directional PP | Melissa travels to new places. | dev/easy.json, item312, theory1 | Goal NP, plural cardinality/distribution, and contextual newness; not just unary travel |

These are three candidates per family, not six approved gold readings. The
second directional example tests the same lexical frame; it is not another
construction or independent population sample. A wider source neighbor is
item hard230 theory19's conditional with Khai travelling to new places: preserve
its antecedent and conditional scope if later used. The six candidates do not
make the residual PP/particle inventory complete.

The existing [ProverQA section](../sections/proverqa.md) reports zero narrow
carry-out matches. An independent scan of context/question fields in all1500
local easy/medium/hard items likewise found no carry/carries/carried/carrying
followed by out. Thus *carry out* below is explicitly an authored lexical contrast;
it cannot be claimed as one of the ProverQA examples. The broad PP/particle cue
count is a search index, not proof of particle identity or lexical frequency.

## Unit2: actual source categories versus proposed analyses

The original [CCGbank manual §3.7.6, printed p.53](https://shannon.cs.illinois.edu/Papers/CCGbank/CCGbankManual.pdf)
says its grammar does not subcategorize phrasal verbs for particles; the source
annotation makes them hard to isolate. Its discussion of corpus limitations
also cautions about complement/adjunct distinctions. Therefore neither a
particle-looking token nor a well-formed PR derivation certifies original
CCGbank lexical attestation. The pinned [ccg2lambda event YAML](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_event.yaml#L1153-L1190)
puts PR and particle-selecting verb templates under its rebanked-parser section.
PR is an actual upstream template category, not evidence our original CCGbank
model offers that category to up/out in any of these six sentences.

Here are explicit CCG analyses to review. They use real CCG category notation;
per-token offered categories in this project's model remain **unverified here**.
No new parser/tagger launch was used to turn these intended analyses into an
attestation claim. Future Explain diagnosis must independently locate any
category/tag gap after gold is fixed.

| Analysis | Lexical categories and derivation | Limitation |
| --- | --- | --- |
| Particle in modifier shape | `gives:S[dcl]\NP`, `up:(S\NP)\(S\NP)`; backward application gives VP, then Raul NP gives S[dcl] | Category only: ordinary modifier semantics does not recover give-up sense |
| Explicit rebanked particle | `gives:(S[dcl]\NP)/PR`, `up:PR`; forward application gives VP | Requires explicit lexical/category reanalysis and PR semantic carrier |
| Selected goal PP | `moves:(S[dcl]\NP)/PP`, `to:PP/NP`, `Tokyo:NP`; to Tokyo gives PP, moves+PP gives VP, Felix+VP gives S[dcl] | Requires lexical goal-role selection, not generic PP erasure |
| Directional VP adjunct | `travels:S[dcl]\NP`, `to:((S\NP)\(S\NP))/NP`; NP application gives a VP modifier, then backward application | Needs shared event/path semantics to preserve attachment |
| Bare plural destination | `new:N/N`, `places:N`, then reviewed N-to-NP interpretation feeding either to analysis | Intersective new and generic-universal bare NP are not licensed automatically |

Preserve finite/base verbal features through do-support. Sentence-final
punctuation may attach structurally after composition; no punctuation or adverb
may be deleted to manufacture a simpler particle example. Separated object
patterns require their own derivations; contiguous attestation does not license
*carry the task out* through arbitrary word reordering.

## Unit3: lexical identity and argument order

Current interface: `Q=(e→t)→t`, `NP:Q`, `VP:Q→t`, and extensional transitive
verbs have type `Q→Q→t`, object first. The category projection currently treats
PP argument-like, as Q, and has no reviewed PR/event carrier. A generic
up modifier cannot transform an arbitrary predicate into its idiomatic sense
by conjunction or lambda-string renaming.

**Bounded lexical sense option.** A reviewed give-up cessation lexeme can have
`λS:Q.S(λx:e.give_up(x))`. Predicate identity is a lexical sense identifier,
not a derived equivalence with `give(x) ∧ up(x)`, `stop(x)`, or `surrender(x)`.
The lexical license must be general English lexical evidence for this sense,
particle and valency, usable independently of benchmark names or answers. No
benchmark-text whitelist, arbitrary verb-plus-particle concatenation, or
pre-parser replacement that deletes up. A traceable multiword lexical entry
may retain both token spans; ambiguous directional analyses must remain visible.
This proposal does not introduce such an entry or license table.

For the authored execution sense *carry out a task*, a transitive frame would be
`λO:Q.λS:Q.S(λx:e.O(λy:e.carry_out(x,y)))`: carrier/executor x, task y. The
separate directional reading *carry a box out of a room* is a carrying event
with theme box and source/path room; it is not this carry_out predicate merely
because carry and out occur. Do not automatically equate carry_out with execute
or infer ordinary physical carrying from task execution. Two or three future
authored controls should distinguish contiguous execution, separated execution,
and literal directional carrying, but they must remain outside the ProverQA
source-derived sample denominator. No such fixtures are authored here.

**Event/goal option.** A declared event interface could use event sort ε,
`K=ε→t`, and `VP=Q→K→t`. Illustratively, a lexical goal-selecting frame has
`λO.λS.λK.S(λx.O(λy.∃v:ε(move(v)∧agent(v,x)∧goal(v,y)∧K(v))))`.
Its selected PP is a goal-bearing argument, not any Q-valued NP with the
preposition thrown away. A PP adjunct instead transforms the same event
continuation to add a goal/path constraint. ε and these continuations are
**proposed**, not existing nl2proof types. An encoding using e-sorted event
referents must explicitly document its sort and inference contracts before use.

Direct `move_to(Felix,Tokyo)` and event `∃v(move(v)∧agent(v,Felix)∧goal(v,Tokyo))`
are different representations. This note does not declare them canonical equals
or freely derive either from the other. Event identity matters when early,
easily, multiple PPs or event anaphora refer to the same event. A unary
`early(Alisson)` or `easily(Justin)` is not a justified substitute.

## Unit4: DRS and claim obligations before any fixture is frozen

| Candidate | Proposed interpretation boundary | Gold disposition now |
| --- | --- | --- |
| Raul gives up. | Under explicit lexical/time-abstraction contract: `[ | give_up(Raul)]`; positive main atom Asserted, other tables empty | Narrow candidate for independent author/reviewer approval; sense selection still needs lexical evidence |
| Alisson wakes up early. | Event waking-up with Alisson agent/experiencer and early relative to contextual standard on that same event | Defer canonical gold: no agreed event/time standard representation |
| Justin does not easily give up. | Preserve the scope of negation over ease/disposition; cannot silently rewrite to `[ | not [ | give_up(Justin)]]` | Defer: operator/modal/event contract unresolved |
| Felix/Sugar move to Tokyo. | Proposed event DRS `[v | move(v), agent(v,Name), goal(v,Tokyo)]` under declared movement sense and time abstraction | Defer canonical choice between event representation and explicitly licensed direct relation |
| Melissa travels to new places. | Event with destinations that are plural and new relative to a context; a fresh existential singular place is not automatically equivalent | Defer: plural and contextual-newness contracts unresolved |

These sketches explain obligations, not committed expected canonical JSON.
Top-level event conditions would be contextual Asserted conditions under the
same witness, not individually closed oracle facts. Under negation, conditional,
disjunction or attitude, all scope/claim barriers still apply. A graph may not
promote movement, giving-up or any event participant from an embedded box.
Where source English is ambiguous, retain independently justified readings or
abstain; do not choose the one the existing exporter happens to produce.

## Boxer/ccg2lambda decisions and next review

[Boxer 2008](https://aclanthology.org/W08-2222/) §2.2 provides an event/participant
representation and §3 distinguishes category, lexical/POS information and
resolution. Adopt explicit participant roles and lexical evidence; adapt only
through a coherent event interface. It does not supply this project's source-
specific idiom senses, temporal standards, or claim-admission guarantees.

The pinned ccg2lambda PR templates combine the lexical verb event property and
particle event property on the same event, retaining Subj/Acc roles. Adopt that
shared-event discipline; reject treating it as proof that arbitrary idioms have
compositional give+up/carry+out meaning. Its higher-order PR template at
lines1189–1190 discards both verb and particle arguments; reject as a general
fallback. Its PP/NP continuation types differ from our present Q interface and
cannot be copied without a representation migration. Neither reference allows
an empty particle meaning merely to increase parser coverage.

Recommended next step: reviewer chooses a narrowly lexical sense contract for
the simple give-up case and separately decides whether directional goals need
a coherent event interface. Independent gold authors can then fix meanings
before an implementation run. Do not turn the deferred rows into guessed gold,
rename all particles into predicates, or trim source modifiers to satisfy a
2–3-example quota. Retain unresolved cases in the construction inventory and
fidelity-gate accounting. No implementation or gate release is authorized by
this design artifact.
