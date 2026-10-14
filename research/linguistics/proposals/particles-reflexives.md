# Particles, reflexives and feature-sensitive predicates

Proposal for DESIGN.md, 2026-10-14. No production rule is changed here. Review
against independent benchmark gold before implementation. The evidence below is
from the coordinator's sealed `research/runs/linguistics-design/explain.log`, not
a new parser or benchmark run. Hand-authored contrasts below are design checks,
not a substitute for the benchmark-derived fidelity denominator.

## Reading the interface: STUDY_PLAN Units 2, 3 and 4

Unit 2 asks which lexical category combines with which neighbor. Unit 3 asks
which typed meaning follows that combination. Unit 4 asks where the resulting
condition lives and which claim can be asserted. All three must agree: a
well-typed `himself(x)` predicate answers Unit 3 mechanically but fails the
linguistic interpretation before DRS construction.

Use `P=e→t`, `Q=(e→t)→t`, `lift(x)=λP.P(x)`, `V=Q→t` and
`T=Q→Q→t`. Thus `NP:Q`, `N:P`, `S[f]\NP:V`, and
`(S[f]\NP)/NP:T`. The transitive term is object-first:
`see=λO:Q.λS:Q.S(λx:e.O(λy:e.see(x,y)))`.
World arguments are suppressed only in these extensional examples; this does
not authorize moving conditions across an attitude or world boundary.

## Locally bound object reflexives

**Observed first divergence.** The sealed Explain lines 1484–1572 analyze
*Bob sees himself* with `himself:N`, then generic `N→NP`, yielding
`∀y(himself(y)→see(Bob,y))`. This is wrong-but-typed. The first fault is allowing
a reflexive through the ordinary open-class noun template; replacing the DRS
later would conceal the faulty derivation.

**Category/meaning proposal.** Reserve reflexive forms from open-class fallback.
For a licensed direct-object reflexive following its finite transitive verb,
use a logged construction reanalysis:

```
sees : (S[dcl]\NP)/NP
himself : (S[dcl]\NP)\((S[dcl]\NP)/NP)
sees himself : S[dcl]\NP                         <
Bob : NP
Bob sees himself : S[dcl]                        <
```

This reflexive category is proposed, not an attested CCGbank tag in the cache.
Its meaning is `λR:T.λS:Q.S(λx:e.R(lift(x))(lift(x)))`, of type `T→V`.
Reduction gives `λS.S(λx.see(x,x))`. For every-subject quantification the single
subject witness occupies both argument positions; there is no separately
resolved object pronoun. Preserve the verb's feature, rather than copying the
cached accidental `S[b]` root.

| Authored acceptance sentence | Intended DRS | Claim status |
| --- | --- | --- |
| Bob sees himself. | `[ | see(Bob,Bob)]` | Asserted atom; other tables empty |
| Every cat sees itself. | `[ | [x | cat(x)] ⇒ [ | see(x,x)]]` | Whole implication Asserted; cat/see atoms Embedded |
| Anne says that Bob sees himself. | Report of `[ | see(Bob,Bob)]` attributed to Anne | Complement Reported; never Asserted |

For the third case, use the existing reporting-envelope contract rather than
inventing a new representation for speech. A preceding name, as in *Anne is
red. Bob sees himself*, must not change binding. Negation encloses the diagonal
relation: *Bob does not see himself* has `[ | ¬[ | see(Bob,Bob)]]`, not a
negated antecedent or a fresh witness. Only the negation is Asserted; its atom
is Embedded. The example does not license isolated reflexives, possessives,
exempt/logophoric reflexives, or long-distance binding. Number/gender features
must be checked when independently known; unknown name gender is not evidence
of incompatibility. Unsupported contexts stay unsupported, recorded in the
fidelity denominator. No unbounded latest-discourse-referent heuristic.

## Phrasal particles versus PP arguments

**Observed first divergence.** In the same cache, lines 1406–1458, *Bob wakes up*
has a category-only parse to S but no semantic parse. `up`'s best category is
`(S\NP)\(S\NP)` and lacks a meaning; its surviving open-class alternatives
are adjectival predicates. `wakes` also lacks the desired simple finite VP in
the displayed surviving list. Therefore adding a meaning to *up* alone is not
established as sufficient. This is a semantic-parse failure, not evidence that
the syntactic grammar cannot derive the string.

**Unit 2 design.** A particle lexeme may appear as a selected `PR` argument or
a VP-modifier-shaped category. A PP, by contrast, has an NP complement (*up the
hill*) and may express path, location, or selection by the verb. The surface
word *up* does not decide between them. The following is a proposed licensed
particle analysis; actual tag availability must be audited separately:

```
wakes : (S[dcl]\NP)/PR      up : PR
wakes up : S[dcl]\NP                            >
Bob wakes up : S[dcl]                            <
```

**Unit 3 decision.** For the current direct-predicate ontology, use a reviewed
lexical multiword frame such as `wake_up:V = λS.S(λx.wake_up(x))`, retaining the
particle as part of predicate identity. Selection of the frame must be licensed
by the verb/particle pair, category, argument structure, and particle POS or
other explicit evidence. This can be a traceable lexical construction before
ordinary composition; it is not arbitrary token concatenation or a general
lambda term for `PR`. It requires a design decision for PR's semantic carrier,
which the current Q-valued PP mapping does not provide. Do not pretend a generic
`λV.V` preserves particle meaning. Do not rename predicates by inspecting lambda
syntax after composition.

For transitive frames, `pick_up:T = λO.λS.S(λx.O(λy.pick_up(x,y)))` preserves
object-first application. Both contiguous *picks up a box* and separated
*picks a box up* should normalize to this frame only under the same reviewed
lexical license. They require separate derivation tests; support for one does
not prove support for the other. Particle meaning is lexically variable:
*give up* is not conjunction of `give` and `up`.

| Authored acceptance sentence | Intended direct-fragment DRS | Claim status |
| --- | --- | --- |
| Bob wakes up. | `[ | wake_up(Bob)]` | Asserted atom |
| Bob picks up a box. | `[y | box(y), pick_up(Bob,y)]` | Contextual Asserted conditions with shared witness |
| Bob picks a box up. | Same as preceding row | Same; separate syntax obligation |

Witness-bearing conditions are not automatically closed oracle facts. *Bob
walks up a hill* is a required negative contrast: it must not become `walk_up`
merely because those tokens are adjacent. A full path/event representation
could be `[e,y | walk(e),agent(e,Bob),hill(y),path_up(e,y)]`, with explicit event
ontology and event-to-claim contracts. This is an alternative design, not the
current canonical direct-fragment gold. Until path attachment and representation
are agreed independently, report unsupported rather than flattening PP to a
unary `up(Bob)` or silently dropping it. The inventory's `particle_or_pp` label
is a candidate detector, not proof of lexical particle frequency.

## S[adj], S[ng], S[pss] and punctuation

The cache lines 1681–1747 selects `running:S[adj]\NP`; *Bob is running* becomes
`running(Bob)`. That accurately describes current output, not a validated
analysis of progressive aspect. A verbal analysis uses
`running:S[ng]\NP` with progressive `is:(S[dcl]\NP)/(S[ng]\NP)`. A declared
time-abstracted benchmark fragment may use `run(Bob)`; unrestricted English
needs aspect/event semantics. Neither generic spelling normalization nor an
identity copula justifies collapsing every progressive, especially accomplishment
verbs. Contrast *Bob is red*, whose adjective predicate is `red(Bob)`.

Passive *Bob is chased by Anne* requires patient Bob and agent Anne, yielding
`chase(Anne,Bob)` in the direct relational fragment. Agentless *Bob is chased*
needs an existential agent or a declared event representation, not unary active
`chase(Bob)`. Record separate canonical conventions before adding gold. These
feature requirements constrain the particle/reflexive repair: do not introduce
an all-S-features identity template to increase coverage.

Sentence-final punctuation can be structural when it preserves the same complete
sentence meaning. Quotes and comma attachments are not covered by this statement;
quotation and reporting guards remain mandatory. Punctuation should not enable
a reflexive to bind across clauses.

## Boxer 2008 and ccg2lambda: adopt, adapt, reject

Sources and exact pin are documented in [REFERENCES](../REFERENCES.md). The
[Boxer paper](https://aclanthology.org/W08-2222/) §§2–3 distinguishes event roles,
lexical/POS interpretation and later anaphora resolution. Adopt that separation;
adapt local coargument binding to our Q-valued NP interface. §3.3 mentions
reflexive triggers but does not establish the proposed binding rule. Do not
cite the paper as proof that arbitrary reflexives are correctly resolved.

The pinned [ccg2lambda event templates](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_event.yaml#L1181-L1190)
combine a verb event predicate and PR event property, preserving subject and
accusative roles in the transitive case. Adopt preservation of particle content
and argument roles; adapt only through an explicit event-ontology migration or
reviewed lexical frame. They use event continuations and a two-predicate NP,
so their terms are not type-compatible drop-ins. Reject the higher-order
PR template at lines 1189–1190 as a general fallback: it ignores both lexical
verb and particle arguments, returning the supplied VP unchanged.

The existing primary-source audit searched all three pinned English YAML files
for reflexive spellings and `reflex`, finding no dedicated entry. This establishes
no dedicated matching entry in those files, not absence across the whole system.
Our local-binding proposal therefore needs independent gold, not an upstream
correctness claim. Neither upstream source supplies nl2proof's Asserted/Reported/
Presupposed/Embedded admission guarantee.

## Integration order and release obligations

Have the independent reviewer validate these typed reductions and canonical
status choices against benchmark-derived ProverQA/FOLIO gold. Prioritize by
verified construction frequencies, distinguishing PP candidates from particles.
First block reflexive-as-common-noun paths and add the local binding rule with
named/universal/embedded/negated contrasts. Implement particle frames only when
the reviewed lexical inventory, category license and PR representation are
concrete; do not broaden support from the three authored examples alone.

For each integrated change, write a prediction before execution, then score all
cases as exact, wrong-but-typed, or no-parse. Report retained wrong alternative
readings separately; one exact reading does not erase wrong alternatives.
Keep all failures in the denominator and rerun claim-boundary regressions. This
proposal supplies no new fidelity percentage and cannot release the ProverQA
90% gate. No corpus load, model call, or answer benchmark was launched here.
