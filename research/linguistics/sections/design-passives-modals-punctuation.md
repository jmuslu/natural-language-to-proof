# C11/C12 supplement: clausal features and commitment boundaries

Ready-to-include learner section for [DESIGN](../DESIGN.md), based on accepted
`d83adaa`, completeness audit `5b4fa3c` and blocked NatLang ledger `801b9a8`.
**Licensed** below means an existing source mechanism or an explicit fact about
an analysis, not proof that a whole sentence passes the parser. **Proposed**
means a worked interpretation requiring independent gold and source review.
**Unresolved** means no complete semantics/export contract is approved.
All short Bob/Anne teaching examples below are authored, not benchmark excerpts.
No parser, model or corpus was loaded to write this section.

Use [STUDY_PLAN Units 2/3/4](../../../STUDY_PLAN.md): category combination,
Montague meaning, then DRS accessibility and claim status. Write `P=e→t`,
`Q=P→t`, `lift(a)=λP.P(a)`. A typed result alone does not establish fidelity.
Explain internal categories/leaf terms are compatible reconstructions constrained
by provenance and root meaning, not necessarily the original chart choices.

## C11a. Passive with an overt agent

**Construction/contract.** Authored `Bob is chased by Anne.` contrasts with
`Bob chases Anne.` The first makes Bob patient, Anne agent. A direct binary
relation `chase(agent,patient)` is a proposed tense/event abstraction for these
controls only. It is not an event ontology for unrestricted passives, ditransitives,
idioms, adjectival participles or impersonal reporting.

**Unit 2: proposed complete by-complement route.** Let `Vpss=S[pss]\NP`:

```text
by: PP/NP       Anne: NP
---------------------- >
       by Anne: PP
chased: Vpss/PP     by Anne: PP
------------------------------ >
        chased by Anne: Vpss
is: (S[dcl]\NP)/Vpss       chased by Anne: Vpss
------------------------------------------------ >
                    is chased by Anne: S[dcl]\NP
Bob: NP                 is chased by Anne: S[dcl]\NP
----------------------------------------------------- <
                         S[dcl]
```

These are candidate CCG categories, **not measured offers**. Another grammar may
attach by as a passive-VP modifier; that alternative needs its own role-bearing
interface. Do not replace these categories by a feature-erased active template.

**Unit 3: proposed typed meanings.** In this restricted derivation let the PP
carry the agent generalized quantifier (`PP` mapped to `Q`), but only through a
construction-certified agent-by slot:

```text
Anne = lift(Anne)                     : Q
by_agent = λA.A                      : Q→Q
chased_by = λA Qs.Qs(λpatient.A(λagent.chase(agent,patient)))
                                      : Q→Q→t
is_pss = λV.V                        : (Q→t)→Q→t
Bob = lift(Bob)                      : Q
```

Forward application supplies Anne before Bob; beta reduction yields
`chase(Anne,Bob)`. The identity term for by does not erase its licensing duty:
`by_agent`, the PP slot and the passive lexical frame must be linked by evidence.
A generic PP identity would also admit instruments, locations or unrelated PPs
as agents. This section supplies no production certificate or authorization to
reuse the existing generic `PP` mapping without that guard.

**Unit 4: intended under this contract.** `[ | chase(Anne,Bob)]`; Asserted has
that one ground relation, Reported/Presupposed/Embedded are empty. Active reversal
has `[ | chase(Bob,Anne)]` and must remain distinct. Negative passive must keep
the relation under negation rather than assert either argument ordering.

**Licensed versus first mismatch.** The current open template for a unary
`S[pss]\NP` is a one-place predicate; it does not create an agent slot merely
because the feature says passive. The closed `is/are` table supplies the adjective
copula, not a general passive auxiliary. These source facts identify candidate
construction obligations, not an observed first failure for the teaching example.
No sealed sentence-level trace is claimed. If a future trace produces unary
`chase(Bob)`, the role loss is independently wrong under this contract even when
typed; locate its producer before altering the grammar.

## C11b. Agentless passive

**Proposed contract.** For authored `Bob is chased.`, existential closure of an
unexpressed agent gives `∃a.chase(a,Bob)` in the same direct relational abstraction.
This is one declared analysis of this eventive use, not permission to existentially
invent holders for passive reporting/knowledge or to treat adjectival states as
events.

**Units 2/3: complete candidate derivation.**
`chased:Vpss`, `is:(S[dcl]\NP)/Vpss`, then Bob NP by backward application:

```text
chased_agentless = λQs.Qs(λpatient.∃agent.chase(agent,patient)) : Q→t
is_pss chased_agentless lift(Bob) = ∃agent.chase(agent,Bob)
```

The passive-by lexical alternative fills its agent slot explicitly; it must not
also add a second existential agent. Agentless closure is a distinct licensed
valency operation, not the ordinary unary verb template.

**Unit 4.** `[a | chase(a,Bob)]`. Asserted conditions retain the top-level
existential universe; `a` is not a globally named person. Under negation:
`[ | ¬[a | chase(a,Bob)]]`, with only the negative condition Asserted and the
relation Embedded. No outer existential agent escapes. Compare an active named
agent, positive agentless passive and negative agentless passive in independent
controls before implementing this contract.

## C11c. Progressive, gerund and modality: interfaces still unresolved

**Unit 2 licensed distinctions.** CCGbank features distinguish
`S[ng]\NP` from `S[pss]\NP` and `S[b]\NP`. Candidate auxiliary frames are
`is:(S[dcl]\NP)/(S[ng]\NP)` for a progressive and
`can:(S[dcl]\NP)/(S[b]\NP)` for a modal. They are not interchangeable with
the adjective copula. Authored `Bob is running`, `Running is tiring` and
`Bob can run` require respectively progressive predication, a nominalized
activity, and modal predication. Category shape does not choose their ontology.

**Unit 3 unresolved meaning.** A progressive needs a declared interval/event
and aspect policy; using `λV.V` would be an explicit lossy abstraction, not ordinary
English progressive semantics. A gerund needs an activity/event denotation and
an appropriate predicate over it; applying tiring to Bob would change its subject.
No event sort, aspect operator or gerund-to-entity conversion is adopted here.

For a named subject, a modal can be sketched as
`CAN(λw.run_w(Bob))`, where the content has type `s→t`. This is an interface
obligation, **not a lexical implementation**: ability versus permission,
accessibility relation, quantified-subject scope and de-re/de-dicto alternatives
remain open. `can_fly` in a controlled ontology must be a separately versioned
contract, not a template for arbitrary can. A modal cannot be treated as identity
merely because the following VP already has a convenient type.

**Unit 4 unresolved schema.** A faithful modal representation would assert its
modal condition, without asserting actual-world run(Bob). It is neither automatic
Reported content (no reporter) nor Presupposed content. Existing attitude boxes
are not a substitute modality schema. No exact modal/progressive gold should be
minted from these placeholders. Keep unsupported status explicit until full
scoped representation and export/claim semantics are independently reviewed.

**First divergence/evidence.** No fresh trace here. Source feature handling and
one-place predicate abstraction expose plausible failure points, not a measured
count of modal errors. ProverQA's 139 short-subject-modal outer strings and its
passive/ing cue counts are surface opportunities; they do not license erasing
operators or certify semantic family membership.

## C12a. Punctuation and topic dependencies

**Licensed boundary.** Sentence-final `.` is structural; a `punct` combination
may preserve a completed clause's category and meaning. For an independently
licensed `Bob is red:S[dcl]`, absorbing `.` gives the same `red(Bob)` and
`[ | red(Bob)]` Asserted atom. The punctuation token has no standalone lexical
lambda term. This is a rule-local identity, not a general deletion operation.

**Proposed/unresolved boundary.** List commas participate in C6 coordination.
Supplementary relatives require a distinct attachment/projection contract from
restrictive relatives; neither comma deletion nor unrestricted conjunction settles
it. Topic `For Bob, he is red` requires resolution of he plus a declared relation
between the topic and clause. The semantic sketch `λa F.F(a)` only applies after
a genuine `F:e→t` gap is established. A complete clause of type t cannot be
silently coerced into that gap. No complete lexical category sequence or topic
DRS is licensed by this sketch; those fields remain unresolved.

A topic can mark perspective, beneficiary or a discourse frame rather than
coreference. Likewise, nominalized activities in `For Bob, running and sleeping
are mutually exclusive` require activity denotations and exclusivity semantics.
Do not guess a topic equality, turn activities into Bob's properties, or infer
exactly-one from at-most-one. The 491 ProverQA initial-for outer occurrences are
prioritized input opportunities, not 491 instances of one resolved construction.

**First divergence.** For a final stop the relevant check is rule-local meaning
preservation. For topic/supplement inputs, omitted dependency or modifier content
is a semantic mismatch even if the remainder parses. No new observed Explain
localization is asserted; preserved raw provenance/root output alone cannot
recover an unrecorded internal producer.

## C12b. Indirect report, direct quote and passive attribution

**Existing indirect-report contract.** `Bob says that Anne is red` is an
indirect report, **not itself a quotation**. Candidate categories are
`that:S[em]/S[dcl]`, `says:(S[dcl]\NP)/S[em]` and names NP. Forward application
forms the intensional complement; says consumes it; Bob completes the clause.
With `K=λw.red_w(Anne)`, the reporting meaning is schematically
`λK Qs.Qs(λx.say(x,K))`. The complementizer declares an intensional parameter;
this is not ordinary extensional application that asserts K on its own.

**Unit 4.** `[ | say(Bob,K)]` asserts the matrix attitude. Its content is Reported
with source chain say(Bob), not an Asserted red(Anne) fact. Factive knows uses the
project's separate Presupposed-content convention, not automatic ordinary
assertion; nested and negated attitudes must retain their enclosing commitments.
This section does not revise the existing claim exporter or its nested rules.

**Direct quotation unresolved beyond bounded attribution guards.** In
`Bob says, "I am red"`, quoted I needs the quoted speaker's context, not the
outer narrator. A quoted title is a name, and a quoted fragment may not denote
a proposition. Existing fronted/inverted-report guards protect some report
boundaries; they do not establish a general direct-quotation/indexical semantics.
Dropping quote marks or inventing a missing proposition is not fidelity.

**Exact NatLang blockers (source ledger 801b9a8).** Preserve these full inputs:

| Verified input | Units 2/3 obligation | Unit 4 boundary; unresolved contract |
|---|---|---|
| Alan is also said to be very kind. | Proposed passive raising `said:(S[pss]\NP)/(S[to]\NP)`; preserve also and very, not just kind. | Alan is the embedded subject, not the reporter. Implicit source, additive presupposition and degree content remain unresolved; do not invent an omitted speaker. |
| Bob is known to be rough and green. | Proposed passive raising known with one shared embedded subject and both adjectives. | Knowledge holder omission plus factive projection need a contract. An empty holders array is schema permission, not semantics. Bob is not thereby the knower. |
| A young someone is red in thought but green in ideas. | Indefinite/modifier, PP-qualified predicates and contrast; thought is nominal here. | No speech report follows from the word thought. Keep PP/metaphorical content and contrast unresolved; literal colors alone are not complete gold. |

Locators respectively: `CWA/NatLang/meta-test.jsonl:288`, record
`AttNonegNatLang-CWA-161`, `sentences.sent1`/presented sentence 2;
`CWA/NatLang/meta-train.jsonl:60`, `AttNonegNatLang-CWA-1374`, `sentences.sent1`;
and `CWA/NatLang/meta-train.jsonl:149`, `AttNonegNatLang-CWA-647`,
`sentences.sent7`. The blocked ledger retains hashes and exact theory spans.
These are already verified selected inputs, not a new source scan or runnable
gold. Physical repetition counts do not supply independent semantic controls.

## Primary-source comparison and next acceptance obligation

[Boxer 2008](https://aclanthology.org/W08-2222/) supplies useful separation of
lexical construction from resolution and an event-role treatment (§2.2), as
retained in [REFERENCES](../REFERENCES.md). Adapting event roles would require a
declared ontology change here. Its quote deletion in one text (§4) is no evidence
of quotation fidelity; reject that shortcut. This section relies on the retained
paper account, not a new PDF verification or upstream execution.

The pinned [ccg2lambda event templates, lines1086–1098](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_event.yaml#L1086-L1098)
were inspected locally: unary passive contributes an event and Acc participant;
a PP-taking passive adds F(e). They demonstrate a typed event-role interface,
not this project's binary relation or an automatically invented agent.
The [by template, lines1655–1659](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_event.yaml#L1655-L1659)
uses Subj(e) in a section explicitly for rebanked parsers. Do not infer that its
category was offered in the local original CCGbank or import its PP meaning into
our Q-valued PP interface unchanged. Pattern `|` is upstream matching notation,
not a new combinator. The 2015 paper's factive-projection exclusion (footnote4)
also leaves our passive knowledge-holder and Presupposed policy unresolved.

Next steps are independent 2–3-row controls **per resolved semantic family**:
role-reversed/overt-agent passive, agentless passive including negation, then
separately settled progressive/modal/topic/quotation contracts. The NatLang rows
stay blocked until their full modifiers and holder/PP semantics are specified.
No incomplete constraint is an exact DRS, and no parse-coverage gain establishes
the ProverQA construction fidelity gate.
