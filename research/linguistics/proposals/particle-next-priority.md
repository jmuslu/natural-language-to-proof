# Next particle and reflexive priorities after give up

Proposal and three independent AUTHORED controls; no source implementation or
new parser measurement. Existing accepted give-up behavior is not generalized
by this document.

## Input evidence and priority

Counted existing input-only `other-refresh/*-unique.jsonl` caches with
case-insensitive whole-word expressions, summing each matched sentence's count
once. ProofWriter uses its read-only sentences.sqlite3 occurrences table across
all 110 inventoried files. These are sentence-bearing cues, not semantic types,
independent problems, successful parses, or coverage estimates.

| Cue | ProverQA occurrences / distinct | ProofWriter physical occurrences / distinct |
| --- | ---: | ---: |
| stand(s) up | 32 / 31 | 0 / 0 |
| stand(s) out | 15 / 15 | 84 / 5 |
| wake(s) up | 3 / 3 | 0 / 0 |
| singular/plural self reflexive forms | 117 / 116 | 1,564 / 34 |

The tested stand-up, stand-out, wake-up and reflexive cues are absent from the
ProntoQA cache (177,560 distinct strings) and FOLIO sample cache (439 strings).
This is not absence of all particles, multiword predicates or anaphora there.
ProverQA care(s) for has 94/94 cue-bearing sentences but is a prepositional
verb/semantic-sense family, not evidence for the existing two-token IV template.
Its narrower residual pattern inventory reports 16 cares-for-patients/plants
cases; that anchored subset and the 94 broad cue total are different scopes.

Within adjacent up/out/off/back/away strings, ProverQA's stand(s) up is the
largest lexical candidate (32); grow(s)/grew up totals 14, stand(s) out 15.
The raw pair counter is an index, not a valency inventory. Stand-up examples
in the cache carry for-complements: exact `Alora stands up for herself.`
(medium342 theory7) and `Ellis does not stand up for himself.` (hard336 theory2)
show why treating this as unary physical standing loses beneficiary and reflexive
binding. This higher-frequency family is the next **design** priority. Its
three-token lexical frame, PP-local binder and stance sense need review before
gold; existing direct-object reflexive licensing does not establish them.
ProofWriter's reflexive total likewise includes association/PP/concessive
paraphrases; it is not 1,564 local direct-object cases awaiting one rule.

The bounded **lexical-sense control** priority is stand out: 15 ProverQA cue
sentences plus a nonzero ProofWriter paraphrase cue. Exact ProverQA anchors are
`Aliya stands out.` (medium215 theory6) and `Goofy does not stand out.`
(hard461 theory4). They locate a construction, but do not disambiguate its sense.
The five ProofWriter matched strings all include a pronoun-headed stand-out
clause with a because-clause about skin colors; four retain preceding named
context within the same inventory string. Their multiplicities are 10, 32, 12,
10 and 20. Do not collapse that causal/pronominal content to an isolated name
plus unary predicate. A broad SQL substring search also retrieves outdoors and
standout strings; the reported 84/5 total excludes those regex nonmatches.

Three stand-out sentences contain from-others complements; those need their
comparison phrase preserved and are not unary source controls. Wakes-up is
lower-frequency and all three source examples carry early or at-dawn material,
so it still needs event/time semantics rather than deletion of a modifier.

## Meaning boundary and independent controls

The [Cambridge lexical entry](https://dictionary.cambridge.org/dictionary/english/stand-out)
distinguishes noticeability from being better than comparables. Neither the
source spelling nor a parser output chooses between them. Thus the three new
rows are explicitly AUTHORED, not silently disambiguated benchmark gold:

| Control | DRS | Claim status |
| --- | --- | --- |
| Mira stands out. | `[ | stand_out_noticeable(Mira)]` | Atom Asserted |
| Noel stands out. | `[ | stand_out_noticeable(Noel)]` | Atom Asserted |
| Mira does not stand out. | `[ | not [ | stand_out_noticeable(Mira)]]` | Whole negation Asserted; inner atom Embedded |

All three have empty universes, Reported and Presupposed lists and disjunction
inventories. `stand-out-noticeable-fixed-comparison-v1` fixes the comparison
background externally and abstracts from tense/aspect. It asserts neither
physical standing nor superiority, and introduces no hidden background witness.
The predicate is a lexical sense identity, not stand AND out or a synonym axiom.
These controls are justified within their declared authored context only; they
supply zero additional source-fidelity numerator credit.

## Units 2/3/4 and implementation gate

Unit 2 proposed certificate: stands `S[dcl]\NP` or stand `S[b]\NP`, adjacent out
`(S\NP)\(S\NP)`, with exact original token spans/features and independent sense
record. These are target categories, **not observed lexical offers for stand/out**.
The accepted give/up alternatives cache proves only that earlier lexeme's
categories. No sealed stand/out offered-category diagnostic was established by
this audit. Freeze/review these controls before a coordinator-authorized diagnostic.
If IV/particle offers are missing, report the category gap; no borrowed give-up
category or deletion of stand's argument is permitted.

Unit 3, if categories and sense are approved: the existing shared unary template
`lambda S.S(lambda x.stand_out_noticeable(x))` with a separately reviewed lexical
record. Preserve ordinary senses and both token scores; no identity out, arbitrary
verb-particle concatenation, name whitelist or unconditional selection bonus.
Unit 4: preserve negation and the authored claim barriers above. A PP, comparison
phrase, degree modifier, physical-location reading, or stance-for complement
cannot be dropped to match the control. Add wrong lemma/particle, absent particle,
transitive/comparative continuation, morphology and scope rejection tests before
any implementation proposal.

Original CCGbank lacks the rebanked particle subcategorization assumed by the
ccg2lambda PR templates; see the primary citations and exact comparison in
[PARTICLE_LICENSING.md](PARTICLE_LICENSING.md). [Boxer 2008](https://aclanthology.org/W08-2222/)
motivates event and lexical information but does not establish the authored
fixed-comparison direct-unary convention. Event-based PR composition does not
resolve noticeability/superiority or justify erasing a comparison PP. The
higher-frequency stand-up-for/reflexive family remains a separate lexical and
binding design problem; this smaller control panel does not mark it solved.
