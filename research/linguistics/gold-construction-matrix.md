# Construction gold coverage after the frozen190 expansion

This is a **gold/provenance audit**, not a parser result, new acceptance panel or
claim of construction completeness. Snapshot: accepted `82efe8d`; frozen190
cases SHA-256
`ee8f3aef38b6925cc626da95d2bf65e6b3a7eb9baa342a5d021ca9cc8c23e564`.
The panel has 190 IDs, 188 distinct texts and 81 construction labels. Metadata
calls 159 rows benchmark-adapted (ProverQA59, ProntoQA47, ProofWriter31, FOLIO22)
and 31 authored-control. These labels **overstate independent source coverage**
if taken literally: several benchmark-adapted rows are disclosed authored
contrasts, or reuse the same underlying sentence. All committed fixture files
also include four hand controls outside190; these add no benchmark observations.

Read only existing gold, origin/adaptation fields, [CONSTRUCTIONS](CONSTRUCTIONS.md),
[PROVER_ACCEPTANCE](PROVER_ACCEPTANCE.md), the reviewed acceptance-panel proposal
`fd5ebb6`, and these seven reviewed learner sections (branch copies if pending
integration). No source input was reloaded, no fixture changed, and no parser
output determined this audit.

| Learner section | Reviewed commit | Construction obligations |
|---|---|---|
| design-names-nominals.md | f19b0fa | C1–C2 reference, definites and nominal predication |
| design-quantifiers.md | c5745e7 | C3 force, domain, bare plural, existential there |
| design-operators.md | fd5290d | C4/C5/C7 negation, binding, OR/XOR/neither |
| design-relatives-coordination.md | 56bea1b | C6/C8 coordination level and relative gaps |
| design-particles-reflexives.md | 1142e7d | C9/C10 lexical particles, PP and reflexive scope |
| design-passives-modals-punctuation.md | 8918229 | C11/C12 voice/aspect/modal and commitment boundaries |
| design-natural-residuals.md | 0c86989 | C13 cardinality, compounds, possession, causal/degree/reporting |

## What counts as independent coverage here

**E**: distinct unchanged presented sentences, allowing only a disclosed fixed
query-wrapper removal. **D**: distinct source sentences with disclosed adaptations
that preserve the semantic subconstruction being tested. **C**: an authored
contrast, including renaming/quantifier substitution from the same source. **A**:
explicitly authored controls without a claim of benchmark sentence provenance.
E/D support source-derived local examples; C/A remain useful controls but do not
supply another source observation. A pair qualifies only for its named narrow
subconstruction, not every semantic variant of an outer family. Independence
here means different underlying sentence instances and no parser-derived gold;
it is **not statistical independence** of correlated generator outputs. Different
sentences in one record remain concentrated evidence, explicitly noted below.

Two duplicates must not supply extra examples: `prover-conditional_initial-1`
=`prover-nested-binding-1`; `pronto-rule-and-2`=`pronto-nested-plural-and-1`.
Keep all historical IDs/scores; deduplicate only this descriptive coverage audit.
Different source fields for repeated text do not create independent meanings.

IDs below are exact unless a suffix range is shown. “2E” means two available
source sentences, not two exact **parser** results. Count and case-shape gaps are
kept visible even when the learner section now provides a worked derivation.

## C1–C5: reference, predication, quantifiers and binding

| Narrow construction | Existing evidence | Coverage decision / remaining obligation |
|---|---|---|
| C1 named adjective, positive | `prover-subject_copula-1/2`, `pronto-adjective-1/2`, `pw-atom-copular-1/2` | ≥2E across benchmarks; diversity does not settle all adjective senses. |
| C1 titled/multiword rigid name | `prover-name-title-1/2` | 2E from distinct Prover records; abbreviation/alias policy is separate from ordinary NP coverage. |
| C1 definite animal/compound NP | PW transitive rows replace definite NPs by names | No dedicated2–3 source controls of the retained definite/compound wording. Description-constant policy, uniqueness and accommodation must be explicit. |
| C2 named positive nominal | `prover-positive-nominal-1/2/3`; `pronto-nominal-1/2`; `pw-atom-nominal-1/2` | ≥2E per listed benchmark family; Prover's declared extensional occupation contract is not unrestricted nominal identity. |
| C2 named negative nominal | `prover-transitive-nominal-1/2/3`, `pronto-negative-1/2`, `pw-atom-nominal-neg-1/2` | ≥2E; gold present even where production is unsupported. Keep NOT over property, no identity witness. |
| C2 universal nominal classification | `folio-extended-universal-1/2/3`; Pronto every/each positive nominal examples | 3E FOLIO; no evidence that mixed modifiers, negative complements and all universal forms are implemented. |
| C3 bare plural: nominal/adjectival/negative | `pronto-bare-1/2/3`; `pw-universal-bare-1/2` | Broad bare-plural family has ≥2E; each Pronto polarity/predicate subtype has only one here. PW two examples share a record and modifier-first structural convention. |
| C3 every versus each | `pronto-every-1/2`, `pronto-each-1/2` | 2E each surface determiner, but each pair mixes nominal/adjective or positive/negative subtypes; no claim of2per cross-product. Each pair's two sentences share a source record. |
| C3 explicit modified universal adjective | `prover-universal_nominal-2`; `pw-universal-explicit-1/2` | Only1E Prover;2E PW, separate conjunct-order convention. Add second Prover source preserving modifier/head. |
| C3 universal transitive scope | `prover-universal_nominal-1` | Only1E (fixed wrapper removed); at least one independent same-family source needed. |
| C3 episodic indefinite subject | `prover-existential_nominal-1/2` | 2D, with modifiers/relative/frame removed; no2unchanged full-source examples or generic-indefinite coverage. |
| C3 positive some | `folio-some-2/3` | 2E from different FOLIO records. Nominal complement morphology/ontology remains separate. |
| C3 negative some | `folio-some-not-1/2` | 1D plus1C (not inserted into positive birds source); not2independent negative source sentences. |
| C3 no determiner | `folio-no-1/2` | One underlying source (`folio-val-65`, context3), second is lexical contrast. Need second negative-quantifier source with modifiers retained/declared. |
| C3 at-least-one relation | `folio-atleast-one-1/2` | One extracted antecedent (`folio-val-128`, context4); Mary is renamed John. Not2source observations; ≥2/at-most/exact counting absent. |
| C3 Everyone strict person, standalone | `prover-person-pronoun-1/2`; `authored-everyone-closed-1/2/3` | 2E connective-bearing sources,3A simple positive/negative; no2source simple nonconnective sentences. Historical unrestricted Everyone rows cannot certify this person contract. |
| C3 Someone standalone | `prover-person-pronoun-3/4` | 2A only; person/existential and negation scope fixed in gold, source pair missing. |
| C3 Something standalone | `authored-something-domain-1/2/3/4` | 4A only under controlled-entity-existential-v1; not ordinary thing-restricted English coverage. |
| C3 there / generic indefinite | No panel gold | Learner there derivation is a proposal, not fixture coverage. Expletive licensing, number/definite cases and generic force need separate contracts. |
| C4 finite intransitive | `prover-unclassified-1/2` | 2E, same record and verb matures; residual3,791 cannot be represented by this pair. |
| C4 do-not intransitive | `prover-subject_do-1/2` | 2D, both work after deleting hard. Add unchanged manner-bearing examples before claiming full original frame. |
| C4 positive/negative grounded transitive | `pw-atom-transitive-1/2`, `pw-atom-transitive-neg-1/2` | 2D each; replacing definite animal NPs tests roles/negation but not original descriptions. |
| C4 negative indefinite object | `prover-transitive-negative-1/2/3` | 3E; nonspecific object under NOT. Different specific-object readings require a separate contract. |
| C4 lexical have + object | `prover-transitive-have-1/2/3`, `prover-subject_have-1/2` | 3E plus2D; not a family of possessive pronouns/genitives or arbitrary have auxiliaries. |
| C5 ground initial conditional | `pw-cond-ground-1/2`, `pw-cond-ground-coord-1/2` | 2E simple and2E AND antecedent; original source/proposition boundaries retained. |
| C5 named conditional + pronoun | `prover-conditional_initial-2` plus nested named connective examples |1D simple uncoordinated case; nested sources do not replace a second same-interface control. |
| C5 indefinite/pronoun binding | duplicated cat row once + `prover-nested-binding-2`; `pw-binding-someone-1/2/3` | Prover1E+1D, latter simplified passive; PW3E under strict-English with person restriction. |
| C5 object-anaphor consequent | `folio-extended-conditional-anaphora-1/2` | 2E in one FOLIO record, barks/jumps and negative/positive object use; do not count as two records. |
| C5 relational generic binding | `pw-binding-relation-1/2/3` | 3D from distinct inputs; name substitution isolates binding, not definite semantics. Distractor binding represented. |
| C5 final conditional | `prover-conditional_final-1/2` | 2D with subordinate predicates replaced; full original content remains outside gold. |
| C5 witnesses under NOT/OR antecedent | Python counterexamples, no corresponding2–3 benchmark-derived sentence fixtures | Accessibility is unit-tested but source-conditioned full DRS/claim examples still missing. |

## C6–C10: coordination, relatives, particles and reflexives

| Narrow construction | Existing evidence | Coverage decision / remaining obligation |
|---|---|---|
| C6 named nominal predicate AND | `pronto-ground-and-1/2` | 2E; shared individual across both predicates. |
| C6 universal coordinated consequence | `pronto-rule-and-1/2/3`, `pronto-nested-plural-and-1/2/3` | Enough distinct sources for broad consequence coordination; first plural row duplicates rule-and-2. Every/each/bare subtypes not all2each. |
| C6 separate subjects and sentence comma list | `pronto-coordination-2/3/4`; `pronto-coordination-5/6/7` | 3E each, from distinct source instances; preserve distinct subjects and final-list NOT scope. |
| C6 mixed lexical/copular VP | `folio-mixed-vp-1/2` |1E+1D from distinct inputs; only one each positive/negative variant. Original second source's temporal/idiomatic material is not covered. |
| C6 NP distributive/collective and argument cluster | No dedicated panel gold | Worked learner derivations are authored illustrations only. Shared object witness versus separate witnesses and collective readings need explicit controls/contracts. |
| C7 ground OR list | `pronto-ground-or-1/2/3` | 3E, two in one source record; FOLIO Yuri OR pair is authored same-source lexical permutation, not extra source coverage. |
| C7 VP either / explicit sentence XOR | `prover-vp_either_or-1/2`; `prover-sentence_either_or-1/2` |2E each broad family; VP mixed nominal/adjective versus adjective-only has one each. Sentence XOR two subjects come from one record. |
| C7 conditional XOR / overt or-both | `prover-nested-xor-1/2`; `prover-overt-or-both-1/2` |2E each, distinct records. Surface either flag and logic are separate fields/contracts. |
| C7 conditional ordinary inclusive OR | `prover-nested-or-1/2` |1E+1D; expert replaced by tall in second. Named and quantified scope each have one. |
| C7 conditional AND / OR antecedent | `prover-nested-and-1/2`; `prover-nested-ante-or-1/2` | AND2E; OR rows are two constructed AND→OR contrasts, not attested OR source instances. |
| C7 bare not-both / neither-nor / independent nested either markers | `operator-not-both-1/2`, `operator-neither-nor-1/2`, `operator-nested-markers-1/2/3` |2A/2A/3A respectively; full scope/marker gold exists but no source-derived set. No source grammar support follows from presence of gold. |
| C7 not necessarily both / mutually exclusive | No full panel gold | Modal force, at-most-one versus exactly-one and activity types unsettled; cannot borrow XOR boxes. |
| C8 subject relative AND/OR restriction | `pronto-restrict-and-1/2`, `pronto-restrict-or-1/2` |2E each, each pair from same record; keep restriction before quantifier scope. |
| C8 multi-item restriction + AND consequence | `pronto-nested-or-and-1/2/3`, `pronto-nested-and-and-1/2/3` |3E each from distinct records. These supply nested scope rather than isolated easy atoms. |
| C8 relative negative consequent | `pronto-nested-negative-1/2`; `pronto-nested-negative-3` + `pronto-coordination-1` |2E OR-restrictor and2E AND-restrictor cases; no need duplicate easy family just to increase counts. |
| C8 strict Everyone who | `prover-who-restriction-1/2`; `authored-everyone-closed-4/5/6` |2E plus3A; negative-relative source example missing, authored control present. |
| C8 negative restrictive relative | `folio-mixed-relative-neg-1/2/3` |Two underlying inputs, first All and second Some are adapted; No is constructed from second. No2–3 independent sources per quantifier subtype. Numeric/location/service/vague quantity replaced, not solved. |
| C8 predicative nominal relative | `folio-extended-predicative-relative-1/2` |1E+1C from same input; second cats/jump contrast is not independent source evidence. |
| C8 active object-gap | `authored-object-relative-*` (three rows) |3A only. Existing439-distinct FOLIO sample audit found no finite active object-relative; do not invent an attested source. |
| C9 give-up | `particle-source-raul`, `particle-authored-ada`, `particle-authored-negation` |1E+2A, fixed-effort sense. Multiple names/negation are useful but not three benchmark sources. |
| C9 stand-out | `particle-next-authored-1/2/3` |3A only under fixed comparison/noticing sense; no source pair or general particle coverage. |
| C9 PP arguments/adjuncts, separated particles | No complete panel family | Inventory cues cannot select roles/senses. Attached modifiers and role/scope contract required before gold. |
| C10 named reflexive | `reflexive-named-1/2/3` |1E+2D from distinct Prover/PW inputs; extraction omits conditional/resultative content. Local role identity covered, original envelopes not. |
| C10 quantified reflexive | `reflexive-quantified-1/2` |2D from distinct inputs; original conditional/relative removed. Two authored distraction/negative controls do not restore original nesting. |
| C10 ordinary pronoun discourse/exempt reflexive | Conditional controls above; one authored distraction | No dedicated2–3 full discourse-source cases; contextual ambiguity, salience/agreement and exempt readings not resolved by local reflexive template. |

## C11–C13: absent or blocked full contracts

| Construction | Existing gold/source evidence | Missing decision or finite next step |
|---|---|---|
| Passive-by / agentless passive | No admitted panel rows; C11 learner derivations are proposed abstractions | Independently choose relational/event interface, preserve agent/patient and implicit-agent scope; then2–3 source cases per form. Source-defined implicit report holder is not automatically an existential agent. |
| Progressive / gerund / modal / habitual | No admitted panel rows | Event/time/activity/world semantics and claim exporter unsettled; do not flatten can or progressive to realized action. Pronto ed-like properties are not evidence of passive construction. |
| Topic / supplements | `prover-for_topic-1/2` are2E human-restricted XOR diagnostics | Not two general topical cases. Generic topic argument, supplementary projection and activity predication remain open outside their narrow historical interpretation. |
| Final punctuation | Present in almost every fixture; authored hand controls | Incidental final stops do not provide source contrasts for abbreviations, lists, supplements or quotations. Titled-name and sentence-list controls address their specific boundaries. |
| Active indirect report | `folio-report-1/2`, plus `hand-report` outside190 | Authored-only; no independent source pair. Factive/nested/negated report scope has unit controls, not2–3 benchmark-derived full sentences in this panel. |
| Passive said/known, nominal thought | NatLang blocked ledger801b9a8, three complete verified sentences | Not runnable gold. Retain also/very, implicit report/knowledge source, factive projection, and PP/metaphorical thought/ideas; no invented omitted source or adjective-only simplification. |
| Direct quotes / quoted titles | No dedicated full fixture family | Indexicals/quotation content versus name/fragment must be distinguished; indirect-report gold is not quotation gold. |
| Cardinality ≥2, at-most, exactly | At-least-one pair is one extracted source | Witness distinctness, upper bounds and scope; learner cardinality examples are authored proposals, not source gold. |
| Compounds/nonintersective modifiers | Adaptations remove several hard modifiers | Compound relation, subsective/privative/temporal modifier meaning; N/N intersection is not a universal policy. |
| Genitives/relational nouns | Lexical have and child antecedent controls only | Owner/head identity, definiteness, anaphora and scope. Have-object gold does not certify her/his or relational noun semantics. |
| Causal/degree/scalar/temporal expressions | No complete family in190 | Explicit relation/scale/time and claim policy before gold; no dropping because/very/always to get an easy atom. |

## Prioritized actionable gaps

Frequency order uses **within-benchmark** inventories, not summed incompatible
population units or overlapping cues. The source-copy prohibition and current
fidelity gate remain in force; these are next design/authoring tasks, not launches.

1. **Complete high-frequency scope subfamilies already having clear contracts.**
   Prover initial-if5,279, pronouns5,714 and explicit not-both4,146 make named versus
   indefinite binding + nested OR/XOR important. Existing AND→OR contrasts and
   simple named conditional are thin: obtain two unchanged independent antecedent-OR
   inputs and two additional quantified/XOR or named-simple cases preserving all
   modifiers. Source candidates must be verified from inventory locators before
   new gold; existing simplified hard/260, hard/280 and hard/168 sources identify
   omitted-content obligations, not automatically admissible new rows.
2. **Fill genuinely thin C3 source families, not more names in filled C2.**
   Prover universal_nominal418 contains only one transitive and one modified
   adjectival example. Add1–2 independent unchanged cases of each. FOLIO no,
   negative-some, at-least-one and predicative-relative each need another source
   rather than another renaming of val65/163/128/197. Preserve removed restrictions;
   if their contracts are unresolved, block them explicitly rather than simplify.
3. **Restore original referential/lexical content in controlled ProofWriter.**
   Transitives2,162,712 and negative transitives372,811 physical occurrences are
   high-frequency, but current role controls replace definite animal compounds
   with names. Author2–3 independently sourced definite-object/subject controls
   under the declared description-constant policy; separate compound head/role
   interpretation and retain shared-object identity. This is a missing gold
   obligation even though transitive role order already has controls.
4. **Settle high-frequency natural-language contracts before adding rows.**
   Prover PP/particle4,120, possessive1,600, ing1,523 and passive721 are overlapping
   cues. PW NatLang relative102,260/coordination91,240 outer occurrences and
   attribution32,684 overlapping cue occurrences are not automatic controlled
   clauses. Prioritize the compact known-to passive ledger input, then said with
   modifiers; source holder/factive policy is the blocker. Modal/degree/causal
   contracts stay blocked, not zero-cost new gold.
5. **Use bounded source search only where gold is authored-only.** Give-up has
   one real source, stand-out none; object-relative none in the audited FOLIO
   sample. Keep authored controls, but seek a second give-up occurrence with a
   reviewed full envelope and appropriate sources for object-gap/neither/marker
   families only under separately authorized input inspection. Do not mislabel
   controls as retrieved corpus sentences. Pronto's47rows already contain robust
   nested/list examples; every/each polarity subtypes and mixed joint profiles
   deserve audit before adding redundant simple named adjectives.

## Contract and acceptance separation

There are139 legacy-unversioned rows. Remaining51 span strict-English14,
strict-English-person-v1 10, operator-surface-scope-v1 7,
controlled-entity-existential-v1 4, four separate three-row contracts (nominal
classification, give-up, Pronto property, stand-out), and two two-row Prover
contracts (strict-English and controlled). These are metadata partitions, not
one consistent semantic policy. In particular, source-grounded Everyone+OR with
historical empty restriction cannot certify strict person-domain readings, and
thing-restricted lexical something differs from controlled entity-only gold.

Gold coverage, production support and representative acceptance are three axes.
A source-derived2–3-row family can be entirely no-parse; an authored-only case can
be exact without establishing source coverage. This audit neither relabels existing
statuses nor fills unresolved gold using observed parser meanings. Canonical
numbering, binder uniqueness, condition/claim order, duplicate occurrence policy,
OR-marker paths and report/presupposition partitions must be independently fixed;
structural admission is not proof of semantic correctness.

The frozen190 set is deliberately diagnostic, not probability-sampled. The
reviewed representative-panel proposal `fd5ebb6` specifies a separate800-occurrence
Prover population draw with a frozen coherent contract and unresolved-case
handling. It has not been executed by this audit. Neither159 provenance labels,
188unique texts,81labels nor this matrix is a valid ≥90% acceptance denominator.
The owner gate remains closed; phasesB–H/model launches remain blocked as stated.
