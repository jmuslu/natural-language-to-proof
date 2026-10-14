# FOLIO explicit-agent passive gold audit

2026-10-14. Full-access shell verified; read STATE then ASTRA_GOAL. Isolated
astra/folio-passive-gold from 579db46. Own this note and, only if meanings are
settled, new test/fidelity/folio-passive-controls.jsonl. No existing gold/source
or root-file changes.

Prediction before source inspection: the sample's three occurrences of Family
History written by may be repeated text rather than three independent passive
sentences. Other explicit-by inputs may carry tense, degree or modal obligations.
Read id/context/statement only, preserve whole sentences, and do not adopt the
learner card's illustrative tense abstraction as source gold. No parser, model,
answer benchmark or CCGbank load. Block unresolved representations rather than
force executable references. Authored contrasts, if useful, remain separate.

## Bounded input audit

The committed FOLIO sample has 120 records, 744 input units and 439 distinct
surfaces. Its SHA256 is
`23ba94be7ce19de4f1345cd6849b1d916b1d65636b44548a22a6f7fc2b66561d`, matching
`research/linguistics/sections/folio.md` and `other-counts.json`.
A case-insensitive whole-word `by` filter over input-only context lines and
statement fields finds **52 occurrences / 32 distinct strings**. These are cue
counts, not 32 agentive passive constructions. The filter includes the brand
Baked by Melissa, noun modifiers such as a design by Max, instrument/method and
comparison uses. No labels, formulas, answers or proofs were inspected.

### Three exact source targets, with unresolved full contracts

Source: `bench/folio/sample.jsonl`; line numbers below are one-based JSONL lines,
context indices zero-based newline-delimited input units. None was rewritten.

| Exact input | All matching locators in this sample | Semantic obligation before executable gold |
|---|---|---|
| Family History is written by Dani Shapiro. | line35 `folio-val-187` context[4]; line48 `folio-val-185` context[4]; line63 `folio-val-186` context[4] | One distinct simple named-agent passive, repeated across three related records. Book/title patient, named author agent. Choose a justified bibliographic authorship-state versus writing-event/current-result reading, with present/passive semantics retained. A direct write(author,book) abstraction is not automatically the full source meaning. |
| Harry Potter was published by New Vessel Press. | line40 `folio-val-151` statement | Explicit past passive: publication patient/title and publisher agent. Must retain was/past, publication event/result interpretation and title reference; do not replace it by an unqualified present publish relation. |
| Orchestras are led by conductors. | line51 `folio-val-38` context[6]; line75 `folio-val-37` context[6] | Generic plural subjects/agents and leadership relation. Not automatically every orchestra is led by every conductor, or an arbitrary single existential conductor shared by all orchestras. Generic force, agent dependence and tense/aspect need a coherent contract. |

The first row supplies **one**, not three, independent source texts. The latter
two do not complete a family of three simple named-agent present passives.
Distinct occurrence locators are retained for verification, not counted as new
meanings. Source assertions and query inputs are interpreted linguistically;
no query truth label was read or assumed.

Other inspected by-bearing candidates do not give a safe shortcut: ranked highly
retains degree and a ranking institution; loved by tourists/children introduces
bare-plural agent force; students working in the lab adds a reduced progressive
restriction; made by Japanese game companies adds compound/generic-agent meaning;
published-by modifiers inside book descriptions are reduced relatives. These
are separate envelopes, not license to discard modifiers and keep a convenient
passive kernel. This bounded scan does not establish that no suitable examples
exist outside the audited sample.

## Expected structure before any observations

The independent commitments are clear enough to specify **constraints**, but
constraints are not full exact-reference DRS/claim tables:

- With explicit by-agent, the named author/publisher must occupy the agent role,
  and the book/title the patient/theme role. Do not insert an additional implicit
  agent existential. Do not reinterpret the title's words as separate common-noun
  assertions. In the generic case, both participant quantifier dependencies need
  explicit binding before any witness can be licensed.
- Under a future event analysis, a publication example might bind an event and
  time with publication/agent/theme/precedence conditions. Merely naming these
  predicates is not an approved event/time ontology: choose reference time,
  event interval and result-state commitments independently first. The current
  DRS's ability to encode arbitrary predicates is syntactic capacity, not
  evidence for those meanings or their exactness.
- Positive matrix source sentences would have asserted **approved complete
  content**, not Reported status simply because they use passive voice. No
  explicit speech/knowledge source occurs in these three sentences. However,
  description presuppositions, generic interiors and temporal conditions cannot
  be assigned final statuses until their representation is fixed.

Unit2 candidate route for the simple overt-agent frame is
`by:PP/NP`, `V:(S[pss]\NP)/PP`, and
`is:(S[dcl]\NP)/(S[pss]\NP)` followed by the subject NP. These are proposed
analyses, not observed CCGbank offers. The PP must be a licensed by-agent slot;
a generic PP identity cannot distinguish agents from instruments or authorship
noun modifiers. Unit3 must retain the chosen state/event/time interpretation,
not simply erase auxiliary features. Unit4 must give a full independent DRS and
claim table for that contract before any producer observation or score.

The accepted learner card
`research/linguistics/sections/design-passives-modals-punctuation.md` explicitly
labels its Bob/Anne direct chase relation a tense/event abstraction for authored
illustrations only. It is not an approved source-level bibliographic, past
publication or generic leadership contract. Gold matrix `fbf436e` correctly
leaves passive-by/agentless source gold open. Existing references to Boxer event
roles and ccg2lambda event continuations motivate a design; they do not supply
this project's missing representation by themselves.

## Proposed single-source bibliographic contract, not admitted yet

Reviewer confirmed there is no already approved general authorship contract, but
this one sentence can motivate a separately reviewed **present bibliographic
attribution** interpretation. Proposal ID: `folio-bibliographic-authorship-v1`.
The title denotes the work constant `Family History`; `Dani Shapiro` denotes the
person. `author(a,w)` means that a is an author of work w in the bibliographic
attribution at the evaluation context. It is not the predicate for a writing
event, ongoing writing, a publication event, sole authorship, or a date. Present
*is written by* is interpreted as the stative bibliographic attribution under
this explicitly selected reading; that interpretation must be independently
approved rather than silently generalized to all present passives.

Under this proposed reading alone, the intended DRS is
`[ | author(Dani Shapiro, Family History)]`; its one relation is Asserted, root
universe empty, and Reported/Presupposed/Embedded empty. The named author is
explicit, so no anonymous agent is added. This ordinary assertion does not make
the speaker's statement oracle-confirmed. Treating the title as a rigid name
requires the bibliographic context; this contract does not assert uniqueness or
general existence principles for arbitrary definite descriptions.

Proposed Unit3 meanings for the Unit2 route above, with q=(e→t)→t, are
`written_by=λA Q.Q(λw.A(λa.author(a,w))) : q→q→t`, a construction-licensed
by-agent carrier, and a present bibliographic-state auxiliary preserving this
relation. Applying the author NP first and work NP second yields the intended
relation. These are **new proposed meanings**, not existing parser behavior or
observed lexical offers. The type alone cannot decide that a sentence is in
this bibliographic sense. Scope, sense and name licensing must remain evidenced.

The sample's same source paragraph identifies the title as a novel; this audit
uses that English context only, never its supplied formalization. Even if this
single-source contract is approved later, it supplies only one independent
reference. It does not solve *was published*, generic orchestras, or the other
blocked envelopes. Until the contract is approved, the DRS above is a transparent
proposal, not a runnable gold row or measured exact result.

## Clearly authored future contrasts, not admitted fixtures

`Mira is praised by Nora.` versus `Nora is praised by Mira.` would isolate role
reversal once a complete present-passive contract is approved. An authored
`Mira was praised by Nora.` contrasts the tense obligation rather than serving
as an interchangeable present example. These three strings are **authored**, not
retrieved FOLIO inputs, and are not executable gold. No new fixture is created
just to give the source family a count of three. They cannot substitute for
additional unchanged independent benchmark sentences.

## Disposition and validation

No runnable `test/fidelity/folio-passive-controls.jsonl` is emitted: the blockers
are semantic-contract decisions, not failed parsing. No gold, score, first
Explain divergence, model confidence or implementation failure is claimed.
No existing fixture or denominator changes. The task's approved fallback is
this exact-source blocker record, preserving the useful inventory evidence.

Validation before commit will recheck the three source strings and all six
locators against the same opaque sample digest, reconcile the 32/52 by-cue count,
and check that only this owned note is staged. No parser or exporter is involved.
Independent review requested after the concrete note commit.

Validation result: all three exact source texts and six occurrence locators match;
52/32 cue totals reproduced, English novel context verified, source hash unchanged.
No proposed fixture exists, and diff check is clean. Reviewer's preliminary
feedback distinguishes a possible new bibliographic contract from an established
one; final concrete-note review follows commit. No parser/model/source changes.

## Approved narrow gold follow-up

Reviewer approved 8cac3c4's ledger and the single-source bibliographic contract:
author(Dani Shapiro, Family History), no writing event/date/sole-authorship or
anonymous agent. Coordinator authorized one exact source row plus two independent
explicitly authored book-title/named-author contrasts under that same contract.
This supersedes only the earlier decision to emit no fixture; the source audit
and past/generic/degree blockers remain unchanged.

Prediction before authoring/checks: the three complete references should have one
Asserted author(author-person,work-title) atom, empty root universe and no other
claim classes. Source repeats count as one benchmark example; authored rows add
no source observations. Name/title constants preserve full case-sensitive text.
No parser observations, source implementation or root membership changes.

The new source row retains the full unchanged sentence and verified context[5]
novel/title cue, used for title disambiguation only. It does not import the year
or novel predicate into the isolated sentence's reference. Two authored examples
use Amber Road/Mira Cole and Winter Map/Nora Vale as explicitly declared work-title
and person pairs; they are authored controls, not independent benchmark records.
All three references were authored directly, with no exporter claim derivation.

Checks passed: exact source and title-context strings/hash, three strict gold
canonical/schema validations using root validator SHA256
98682bb1d2e8dfa9ce16af2d30206383f8dd1fb7fa8e155e3376567bf5997dac,
no existing fixture ID/text collisions, explicit one-source/two-authored origins,
and clean diff. Validator only: no evaluate_case, producer or parser invocation.
Proposed fixture SHA256 before independent final review:
f5a09b9ceb5f34c658ab013b1e78cccb8de76557b263298c749be4ba9a479e7d.
Review requested before freeze; past/generic/degree source rows stay blocked.

Reviewer approved all three meanings before observations, with this explicit
limitation: producer requests contain only id/text, not title_context or
authorship_context. The fixture measures a declared-context interpretation while
that context is unavailable in runtime input; it does not certify unconditional
isolated-English disambiguation or a context-aware parser. Gold metadata must
never be transmitted as a runtime sense hint. This qualification is also included
in every row's notes. The fixture is a separate contract diagnostic, not strict
representative acceptance evidence.

Final metadata qualification preserves all three DRS/claim values; strict schema
checks passed again and project_request verified id/text only for every row.
Final frozen fixture SHA256:
94039010092a4bece4b473c1dc41b8ea48124f9f79709ab21555c0b4a9ba97a7.
