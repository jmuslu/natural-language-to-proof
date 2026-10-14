# Licensed intransitive particle lexemes without a PR migration

Proposal, 2026-10-14; no implementation or gold changes. Continues
[particle-contract.md](particle-contract.md). The smallest defensible first
fragment is a **licensed two-token intransitive lexeme**, not a general particle
modifier. A category-shape rule alone cannot derive the idiomatic cessation
meaning from the ordinary meanings of give and up.

## Evidence and its exact limits

The complete source input *Raul gives up.* occurs at ProverQA dev/easy.json
item222, query0. This licenses examination of the construction, not a guessed
population frequency. English lexical evidence independently supports an
intransitive sense describing abandonment of an effort; the [Cambridge entry](https://dictionary.cambridge.org/dictionary/english/give-up)
also distinguishes other give-up uses. Choose that sense explicitly, with a
contextually fixed effort and a time-abstracted assertion contract. Do not
silently equate it with every relinquishment, cessation or physical-giving sense.

The sealed original-model `research/runs/linguistics-design/explain.log`,
lines1426–1434, offers **up:(S\NP)\(S\NP)**, alongside other categories. This
is category evidence read from the cache, not an expected meaning taken from a
parser. It comes from a wakes-up diagnostic, not an attested gives-up derivation.
No sealed gives-up lexical-head derivation was found during this task. Whether
*gives* supplies the intended finite intransitive category is an outstanding
preimplementation check; it must not be assumed true from the particle evidence.

The [CCGbank manual §3.7.6](https://shannon.cs.illinois.edu/Papers/CCGbank/CCGbankManual.pdf)
does not provide a general particle-subcategorization analysis. The pinned
[ccg2lambda PR entries](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_event.yaml#L1153-L1190)
are for rebanked parses. Consequently this proposal uses the observed original
VP-modifier-shaped category and never claims that original-model up is PR.

## Unit2: lexical construction and provenance certificate

Proposed category certificate for the initial fragment:

```
head token:     S[dcl]\NP          or S[b]\NP
particle token: (S\NP)\(S\NP)
licensed complete lexeme: same finite/base VP as the head
```

This is compatible with the original modifier-shaped syntactic analysis, but
**ordinary backward application does not supply idiomatic meaning**. Treat the
pair as one multiword lexical entry over a two-token chart span, with both
original leaves recorded under a `particle-lexeme` provenance rule. Instantiate
its independently reviewed lexeme meaning at that span. Do not replace the
source text with an underscored token, alter offsets, or drop either input leaf.

The certificate must contain all of:

1. A lexical record `(head lemma, particle surface, intransitive frame, sense id)`
   justified by English lexical evidence, independent of dataset item/answer/name.
   Initial candidate is give + up, intransitive stop-trying sense. This is a
   normal sense/valency lexicon, not a benchmark sentence whitelist. Additional
   records need independent evidence and gold; the algorithm is shared.
2. Adjacent original tokens and their offered categories: finite/base intransitive
   head and backward VP-modifier particle. No inferred head category from spelling,
   no transitive-to-intransitive deletion of an unsatisfied NP, no generic S wildcard.
3. Original lexical spans, scores and source-category evidence, preserved in the
   constructed VP. Inflection normalization must follow the lexical morphology
   contract: gives→give is available; unseen past/participial variants are not
   automatically licensed by this record.
4. A complete two-token lexical span, not a pending unary give_up head that can
   become a sentence without its particle. Only the certified construction may
   introduce its sense predicate. No global up-as-identity entry is added.
5. Conservative attachment: only the reviewed adjacent pair is matched. Object
   intervention, extraposition, coordinated heads/particles and particle-looking
   PPs have no license from this rule. Genuine existing nonparticle readings
   are not deleted globally; wrong retained readings must remain visible in
   fidelity and block acceptance if the construction's meaning remains unsafe.

Current corpus-backed semParse seeds lexical items only in one-token cells;
the hand-lexicon lattice's multiword capability is not evidence the corpus parser
already supports this construction. The implementation would need one reviewed
span-seeding hook shared by category feasibility and semantic chart construction,
so the backward usefulness pass cannot prune the new lexical span. The completed
VP is an ordinary existing sign: no PR type, event type, new all-sign payload, or
pending identity-particle semantics is necessary. Preserve one-token alternatives
and their scores, and log the lexical choice/competing actual candidates. Do not
claim this hook has been implemented or verified.

If actual head-category evidence is absent, stop at a documented category gap.
A lexical category repair would be a separate reviewed proposal with its own
independent tests, not a hidden extension of this certificate. This condition
prevents easy apparent coverage through fabricated intransitive tags.

## Unit3: one general typed template, sense-specific lexical data

Let `Q=(e→t)→t`, `V=Q→t`. The general intransitive-lexeme template is

```
lexeme1(p) = λS:Q.S(λx:e.p(x))      : V
```

For the chosen cessation sense, `p=give_up`. The same template already underlies
ordinary intransitive meanings; new work is the lexical construction certificate,
not a new logical connective or rule that edits a normalized term's predicate
name. `give_up` is a declared lexical sense identifier, with no automatic
`give_up(x) ↔ give(x) ∧ up(x)`, surrender synonym, or hidden event quantifier.
A lexical meaning for an idiom is legitimate, but cannot be manufactured by
concatenating arbitrary head/particle strings.

After construction, normal subject application, closed negation, quantification
and clause embedding operate on the VP. One subject witness is shared across
the whole predicate. In a direct relational fragment there is no object argument
for this intransitive sense. Transitive *give up a seat* or *carry out a task*
requires a different lexical frame and object-first type `Q→Q→t`; this rule must
not absorb their object or pretend they share its unary meaning.

## Independent hand meanings for review, not new gold files

These expectations are derived from the declared English sense and compositional
scope, before any candidate parse. Except Raul's positive sentence, the controls
are explicitly authored; they are not additional ProverQA observations. They
abstract from tense/aspect and hold the relevant effort context fixed.

| Sentence | DRS expectation | Independent claim expectation |
| --- | --- | --- |
| Raul gives up. (exact source) | `[ | give_up(Raul)]` | Asserted: give_up(Raul); Reported/Presupposed/Embedded empty |
| Every runner gives up. (authored) | `[ | [x | runner(x)] ⇒ [ | give_up(x)]]` | Asserted: whole implication; Embedded: runner(x), give_up(x); Reported/Presupposed empty |
| Raul does not give up. (authored) | `[ | not [ | give_up(Raul)]]` | Asserted: whole negation; Embedded: give_up(Raul); Reported/Presupposed empty |

An eventual reporting control must keep give_up in Reported content; only the
speech-act envelope may be Asserted. The lexical multiword span must not move
outside its sentence, negation or attitude scope. These sketches are contracts
for independent author/reviewer agreement, not executable fixture output or a
claim that bare present English universally has this time-abstracted meaning.

## Contrasts that must not be collapsed into this template

| Complete contrast | Required distinction | Present disposition |
| --- | --- | --- |
| Felix moves to Tokyo. (source easy206 theory2) | Mover Felix and goal Tokyo, not unary move with deleted PP | Separate directional-goal contract from particle-contract.md |
| Raul walks up a hill. (authored) | Up takes hill as directional/path argument; it is not intransitive give-up morphology | No particle-lexeme license; no unary up(Raul) or automatic walk_up |
| Alisson wakes up early. (source medium54 theory2) | Waking-up sense plus early on its event/time, not on Alisson as a property | No give-up license; event/time modifier gold remains deferred |
| Justin does not easily give up. (source medium69 query0) | Ease/disposition remains inside its justified operator scope | Matching a give-up subspan must not cause easily to disappear or the whole sentence to receive the simpler negative control's meaning |
| Raul gives up a seat. (authored) | Transitive relinquishment sense with object witness | Initial intransitive frame must not produce a complete root by dropping the object |

A subspan may be recognized inside an otherwise unsupported sentence. That does
not authorize a partial whole-sentence success or pruning unsupported words.
Every input token must belong to a licensed derivation, including modifiers and
NP/PP dependents. An event-based future design may express these distinctions,
but there is no declared canonical equivalence with the direct unary fragment.

## Source comparison and conditions before implementation

[Boxer 2008](https://aclanthology.org/W08-2222/) motivates lexical information and
shared event participants, but does not supply this lexical certificate or our
claim barriers. Adopt lexical/category separation; defer event migration until
a whole-interface contract is reviewed. ccg2lambda's event PR combination preserves
one event across verb and particle; adopt that principle only in a coherent
event design. It does not establish the idiomatic sense by conjunction of two
uninterpreted event predicates. Reject its higher-order PR identity fallback for
this task. The present lexical-span proposal avoids that loss rather than
pretending the modifier-shaped up already has a universal lexical lambda term.

Before any source change: independent reviewer approves the sense/abstraction
contract and span-certificate design; independent author supplies positive and
negative gold; root verifies actual gives/give head categories and up modifier
evidence without silently broadening them. Add red corpus-free cases for absent
particle, wrong lemma, NP/PP continuation, separated tokens, quantifier scope,
negation, trace/span conservation, and seen-rule/category-chart pruning. Only
then implement the shared lexical-span mechanism and rerun all exact/wrong-typed/
no-parse panels, including complete unsupported adverb/PP sentences. Keep failures
and retained wrong alternatives in the denominator. No current count, source
repair or ProverQA gate release follows from this proposal.
