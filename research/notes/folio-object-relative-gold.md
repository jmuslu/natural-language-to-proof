# FOLIO object-relative attestation and independent controls

2026-10-14 full-access shell verified in clean assigned worktree. Initial read-only
scan of all explicit who/whom/whose/which/that inputs finds subject relatives,
complementizers, demonstratives and two important neighboring families: infinitival
restaurants to try and reduced passive jobs offered by the university. A finite
active object-gap relative is not established by that scan; zero-marker relatives
need the remaining full input review. No parser outputs/labels/formulas/proofs,
models, corpus loads or benchmarks consulted. Own fixture and notes only.

## Completed input audit and negative finding

Reviewed every unique English input string, not just explicit relative markers:
the120 committed FOLIO items contain744 units/439distinct strings. Inspection was
in two sorted, indexed batches0–219 and220–438, taking only context lines and
statement strings. This also checks potential zero-relative-marker cases missed
by a who/that regex. No finite active object-gap relative was identified in this
sample. This is a bounded manual sample finding, not a theorem about all FOLIO.
Sample SHA256:23ba94be7ce19de4f1345cd6849b1d916b1d65636b44548a22a6f7fc2b66561d.
No existing gold or parser outcome supplies the attestation judgment; existing
fixture texts were checked only to avoid duplicate authored controls.

Important neighboring evidence is preserved rather than hidden:

- folio-val-109 context1 and statement0 both contain the infinitival object-gap
  fragment “restaurants to try”. The first lies inside a purpose/frequency-rich
  who-relative under All; the second inside a disjunctive predication. Those are
  two occurrences of the same infinitival fragment, not two finite active
  object-relative templates. They do not assert an actual try event/relation.
- folio-val-157 context1 has jobs offered by the university; related sample
  inputs have students instructed by a professor, books published by a press,
  and roses given out on TV. These are reduced passive relatives: head as
  syntactic passive subject/patient, not a finite active clause with an object
  gap after an overt subject. Treat their passive role contract separately.
- who lost to a named player has a subject gap despite containing a lexical
  relation; that have mines likewise has a subject gap, not an object gap.
  A clause inside an object NP is not automatically an object-relative clause.

No original source sentence has been shortened/reworded and then labelled an
attested finite-object-relative example. A passive-to-active paraphrase would
introduce a new syntactic construction and cannot establish its original frequency.
The full infinitival examples need purpose/control, habitual frequency and modal
semantics beyond the current canonical gold schema; no flattening to actual
try(person,restaurant) is accepted. Their gold remains explicitly blocked here.

## Independent authored panel, separate denominator

The three rows in folio-object-relatives.jsonl are deliberately **authored controls**,
not benchmark-adapted cases. Every origin is exactly kind:authored-control, with
no FOLIO item/file origin invented. Administrative filename describes the task,
not data provenance. All construction labels start AUTHORED.; IDs start authored-;
notes explicitly exclude them from FOLIO source-derived/population denominators.
The coordinator must evaluate this file as a separate authored-control panel and
must not count it as2–3 recovered FOLIO object-relative examples. FOLIO-source
finite-active-object-relative gold count from this task is **zero**.

All rows use semantics_contract strict-English. New diagnostic texts are:
Every dog that Mira likes is quiet; Some dogs that Nora does not chase are calm;
No dog that Mira likes is red. They provide universal restriction, negative
object-relative under existential, and negative-determiner scope. There are3
distinct controls and no duplicate text in existing fidelity JSONL files.

## Units2/3/4 contract

Unit2 finite active object relativizer: `(N\N)/(S[dcl]/NP)`. The clause Mira
likes has an overt subject and missing object; raise Mira:NP to S/(S\NP), then
compose with likes:(S[dcl]\NP)/NP to form S[dcl]/NP, preserving its dcl feature.
The relativizer turns that gap clause into N\N and combines with dog:N before
the determiner NP[nb]/N. Object-relative does **not** use the subject-gap
`(N\N)/(S[dcl]\NP)` category. Feature-sensitive raising/composition and extraction
licensing are proposed requirements, not a claim the current parser derives them.
The negative clause Nora does not chase likewise leaves the object slot open;
not negates chase(Nora,x), without exchanging subject and gap roles.

Unit3 q=(e→t)→t. Relative R is
λV N x.N(x)∧V(lift(x)) : (q→t)→(e→t)→e→t, but V now takes an **object** GQ.
Mira likes has meaning λO.O(λy.like(Mira,y)); its gap closure gives
λx.like(Mira,x), not like(x,Mira). The negative counterpart is
λO.O(λy.¬chase(Nora,y)). Apply Every/Some/No to the restricted noun, retaining
the reviewed existential/universal/negative determiner meanings.

Unit4 independently authored meanings:

1. `[ | [x | dog(x),like(Mira,x)] ⇒ [ | quiet(x)]]`: only implication Asserted;
   dog/like/quiet Embedded. There is no existential main-box dog.
2. `[x | dog(x), ¬[ | chase(Nora,x)], calm(x)]`: dog, negated box, calm Asserted;
   chase Embedded. x binds from the main description through its inner negative
   box; the object-gap relation does not create another witness.
3. `[ | ¬[x | dog(x),like(Mira,x),red(x)]]`: only outer negation Asserted;
   all three inner predicates Embedded. No dog existence or positive like fact
   is promoted. Reported/Presupposed are empty in all3 controls.

Claim tables were explicitly listed from these judgments, not generated with the
production splitter. Schema validation checks reference legality, not semantic
truth. These controlled present-tense meanings follow the existing direct-predicate
fragment and are not a proposed treatment of infinitival purpose or passive events.

## Boxer and ccg2lambda comparison

[Bos2008](https://aclanthology.org/W08-2222.pdf) supports separating combinatory
construction, argument roles and DRT accessibility. Adopt the role/scope discipline;
adapt its event semantics only with an explicit representation contract. A
relative head's patient role does not prove active-object extraction syntax.

[Mineshima et al.2015 §2/Fig3](https://aclanthology.org/D15-1244.pdf) motivates the
NP restriction interface. The pinned [ccg2lambda2015 templates](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_emnlp2015.yaml)
contain separate subject-/object-gap relative categories. Adopt their distinction
and binding intent; adapt to the project's one-slot q with N-level restriction,
not a blind NP-modifier transplant. Do not import a finite template for restaurants
to try or erase the missing purpose/modal contribution. Existing REFERENCES.md
records the primary-source comparison; no upstream system was run.

## Validation and limits

Counts reproduce120/744/439 and exactly2restaurants-to-try occurrences at the
locators above. Three gold rows pass validate_case schema/accessibility validation,
strict-English and authored-only origin assertions; explicit DRS/claim tables
retain intended object order and scope. No parser, corpus loader or benchmark was
launched. git diff --check passes. Reviewer approval is required before parsing;
absence and schema success do not imply implementation completion.
