# Learner design and source-comparison audit

Audited accepted `f8871d5`, read-only, against existing reference material. No
production behavior, shared documentation, corpus load or external-system run
changed. Recommendations below are corrections for coordinator integration,
not claims that missing constructions now work.

## Evidence boundary

Directly inspected the retained primary-source files under coordinator
`research/runs/linguistics-sources/ccg2lambda/`, pinned by REFERENCES to
`a68cb264413791150011c347c64a7b35e2f7270d`. Exact locations below use line numbers
in those retained files and their matching pinned source. Existing Bos2008 and
Mineshima2015 paper accounts are in REFERENCES.md:8–51 and
TEMPLATE_COMPARISON.md; no locally extracted full papers were found in that source
directory. Their paper-specific claims are therefore checked for consistency
with the prior retrieved account, **not independently reverified against PDFs**.
The local CCGbank manual exists at
`~/ccgbank/ccgbank_1_1/doc/CCGbankManual.pdf`; neither pdftotext nor Python pypdf
is available in this shell. No installation or broad literature search was made.
Its §3.7.6/p.53 claim remains prior-audit evidence, not a new manual verification.

## Supported source comparisons

| Current claim | Exact inspected source | Judgment and limit |
| --- | --- | --- |
| Shared-subject VP conjunction | 2015 YAML87–90 | Supported: the subject continuation wraps both VP applications at one individual. This is not collective NP semantics. |
| Relative restriction slot | 2015 YAML566–573 | Supported for subject and object gaps: the relative strengthens the first predicate argument of NP. Do not copy into one-slot Q. |
| Sentence-or rule uses conjunction | 2015 YAML102–106 | Supported literally. It is a counterexample to wholesale import, not evidence that every upstream OR derivation is wrong. |
| PR entries target rebanked parses | event YAML1155–1159,1181–1190 | Supported by the section heading and typed entries. Does not prove original local CCGbank offers PR. |
| Higher-order particle entry discards content | event YAML1189–1190 | Supported: body V(Q,K) ignores E and R. No generic fallback should be adopted from it. |
| Last matching semantic rule wins | README207; semantic_index.py38–61 | Supported: matching rules append in order and pop chooses last. Matching pattern and interface still matter. |
| Person-restricted Everyone comparison | 2015 YAML192–194 | More precise than the current broad attribution: the source uses _people(x) and two NP slots. Mapping _people to project person is a declared lexical/ontology adaptation, not a verbatim template import. |

All YAML references denote the pinned English files linked in
[REFERENCES](../REFERENCES.md#official-implementation-pinned-separately-from-the-paper).
Bos separation of construction/resolution, event-role treatment and lack of
semantic-gold evaluation are accurately qualified in DESIGN587–617 relative to
REFERENCES. No new unsupported claim of upstream fidelity or execution was found.
Do not turn this consistency check into an independent paper replication.

## Concrete corrections, in learner-impact order

1. **Explain provenance promises are too strong.** STUDY_PLAN14,37 and390 imply
   every internal node and lexical choice is recovered. Replace with:
   “When compatible replay succeeds, display its categories and meanings; this
   is a reconstruction constrained by recorded provenance and root meaning, not
   necessarily the original lexical derivation. On fallback, raw provenance and
   authoritative Pipeline formula/DRS/claims remain; leaf-term tables may be empty.”
   Link the reviewed EXPLAIN_SHARED_REPLAY_API proposal. Accepted59955b6 particle
   evidence in that branch actually exhibits all three fallbacks, rather than
   merely predicting them. No shared-source refactor is implied by this wording.
2. **Meaning does not come for free from syntax.** STUDY_PLAN378 and381 reduce
   lexical choice to categories. Replace with: “Given licensed lexical meanings
   and valid guarded transitions, combinators compose those meanings. Category,
   POS, lexical identity, features and construction state constrain interpretation;
   successful typing alone does not establish fidelity.” DESIGN23–31 and70–95
   already give the stronger account. Unit3 exercise2 should explicitly hold
   lexical choices and licenses fixed before calling derivational ambiguity
   harmless; the wrong-valency reading in DESIGN274–280 is not such ambiguity.
3. **Explain failure stage is not guaranteed first linguistic divergence.**
   STUDY_PLAN354 should distinguish parser diagnostics, replay failure boundary,
   and an independently established first mismatch against gold. DESIGN70–76 and
   §5 already make this distinction. A root DRS mismatch alone does not identify
   the first lexical cause. Do not upgrade historical/source-inferred diagnoses
   into fresh observed traces.
4. **Historical construction-card status needs a nearby pointer.** C2 says the
   present copula table is adjective-only (DESIGN133), while851–882 describes an
   implemented bounded nominal route. Add “General named/embedded nominal
   predication remains unsupported; see the direct-universal checkpoint for the
   implemented narrow exception.” C10's implemented construction then calls its
   category proposed (398); replace proposed with “derived by the bounded
   reanalysis, not asserted to be the original lexical CCGbank category.”
5. **Tighten Everyone attribution.** DESIGN940 should cite the exact 2015
   YAML192–194 person-sort analogue and distinguish _people/person and NP*/Q.
   Bos2008 is broad methodological context; the existing evidence does not
   establish that paper specifies this exact Everyone lexical entry.
6. **Make the research pause visible beside executable exercises.** Unit2
   exercise4 currently instructs a coverage launch. Add a note that the exercise
   is a learner recipe, not permission during the active fidelity gate; use
   sealed outputs unless the coordinator authorizes the diagnostic. This follows
   owner instructions already preserved in DESIGN11–14, not a new approval rule.

## Construction-card completeness

“Present” below means a documented specification, not implementation success.
A single worked family member does not settle every variant listed in its card.

| Card | Already useful for Units2/3/4 | Missing or ambiguous field to add |
| --- | --- | --- |
| C1 names/definites | Categories, applications, lifted name, DRS/status; NAMES trace pointer | Add one explicit definite-constant DRS and mark uniqueness/accommodation limitation alongside it. |
| C2 predicative nominals | Proposed categories, term types, applications, positive/negative boxes | Cross-link current bounded implementation and its guard divergence; do not label the whole family implemented. |
| C3 quantifiers/bare plurals/there | Determiner terms and three scoped boxes | There lacks a complete worked token derivation and expletive term; bare-plural diagnosis remains historical. Separate these subfamilies. |
| C4 lexical verbs/negation | Argument order, auxiliary type, scope and claims | Supply one full do+not composition preserving S[b]/S[dcl], with observed versus proposed label; not all has senses share possession meaning. |
| C5 conditional binding | Fronted/postposed types, direction, dynamic antecedent box | Add a stepwise generic-pronoun accessibility derivation; implication alone is not a complete implementation of binding. |
| C6 conjunction | N/NP/VP/S meanings and shared witness | Add NP and argument-cluster category trees; distinguish wrong lexical alternative from harmless derivational ambiguity. |
| C7 OR/XOR/neither | VP term, OR/XOR/negative boxes and status | Either and neither/nor still lack full licensed lexical categories/derivations. Label as unresolved interfaces, not done templates. |
| C8 relatives | Subject-gap derivation, typed restriction, scoped DRS | Object-gap direction and pronoun-relative cases need separate worked cards; authored object gold does not establish FOLIO attestation. |
| C9 particles/PP | Two representation choices and scope; accepted give-up checkpoint | Add measured seed replay limitation and the two-token construction step; PP, separated particles and idioms remain separate unimplemented obligations. |
| C10 reflexives/pronouns | Derived local operator, argument identity, scope and guard | Replace stale proposed wording; separate ordinary pronoun resolution and exempt reflexive limits. |
| C11 passive/progressive/modal | Feature distinctions, intended roles/operator barriers | No complete agentless/passive-by derivation, progressive ontology or modal export schema. Explicitly keep these unresolved rather than inventing boxes. |
| C12 punctuation/topic/quote | Final punctuation, topic sketch, attitude claim distinctions | Topic and supplement constructions lack a full typed derivation/DRS policy; quotation/report distinction must not imply every quote is indirect speech. |
| C13 natural residuals | Useful inventory of cardinality, compounds, possession, causal/degree obligations | These are backlog rows, not complete construction cards: each needs 2–3 independent controls, categories, full terms, scoped boxes/status and evidence-labeled divergence before implementation. |

DESIGN's §5 is intentionally a historical evidence ledger. Most cards have no
fresh per-construction Explain localization; record “not yet measured” rather
than filling that column by intuition. Link a source/binary-sealed observation
when one exists. The diagnostic denominator and literal-English versus controlled
semantics contract must travel with every reported exact/wrong/no-parse result.

## Suggested integration order

First repair the three learner claims about replay, compositionality and failure
localization. Then add the nearby status pointers and exact Everyone citation.
Expand C3/C7/C11/C12/C13 only alongside independently reviewed construction work;
unsupported details should remain explicit open questions. Existing prior-source
adopt/adapt/reject judgments can remain with the evidence qualifications above.
