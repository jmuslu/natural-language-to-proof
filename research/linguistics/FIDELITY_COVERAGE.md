# Independent fidelity coverage and the ProverQA gate

This static audit covers the 85 starter rows plus 10 nested ProverQA, 12 nested
ProntoQA and seven reflexive rows reviewed for integration on 2026-10-14. It
assesses what the authored meanings test, not whether the parser passes them.
[CONSTRUCTIONS](CONSTRUCTIONS.md) defines acquisition scope and frequencies;
[DESIGN](DESIGN.md) defines semantic obligations. Neither a surface bucket nor a
lexical cue supplies a gold reading. No answer labels, hidden formulas, parser
outputs or model calls supplied this coverage audit.

## What the 114 rows actually contain

| Fixture file | Rows | Construction labels | Important qualification |
|---|---:|---:|---|
| proverqa.jsonl | 24 | 12 | Two per outer-family label, with simplified cases and missing modal family |
| proverqa-nested.jsonl | 10 | 5 | Two per nested group; four adaptations, six unchanged inputs |
| proofwriter.jsonl | 24 | 12 | Controlled fragment, original definite animal NPs partly replaced with names |
| prontoqa.jsonl | 25 | 11 | Nominal/universal/relative/coordination controls |
| prontoqa-nested.jsonl | 12 | 4 | Three per group; negative-consequent group mixes AND/OR restrictions |
| folio.jsonl | 12 | 6 | Ten sample-derived examples plus two authored speech controls |
| reflexives.jsonl | 7 | 3 | Four ProverQA-derived, one ProofWriter-derived, two authored controls |

There are **114 rows, 112 distinct texts and 52 distinct construction labels**.
Cross-file construction labels overlap, so the label column cannot be summed.
The repeated texts are “If a cat is nimble, then it is agile.” and “Gorpuses are
lorpuses and wumpuses.” Keep their useful regression identities, but do not count
them as independent coverage or additional population evidence.

Origins partition into 38 ProverQA, 37 ProntoQA, 25 ProofWriter and ten FOLIO
benchmark-derived rows plus four authored controls. ProverQA has 37 distinct
texts; ProntoQA has 36. An adaptation is not an untouched population observation.
The 114-row pooled result, even if perfect, cannot establish a ProverQA gate.

## Frequency crosswalk and remaining semantic gaps

Counts below retain their inventory kind: **outer** buckets are exclusive by
recognizer precedence; **cues** overlap. A gold group need not cover all sentences
counted under either. Presence of two rows does not establish that every scope,
argument or lexical subtype within the group has two examples.

| Inventory evidence | Current bounded gold | Remaining gap |
|---|---|---|
| Prover initial-if outer 5,279; explicit not-both inside initial-if cue 2,836 | Two conditional explicit-XOR consequents, including punctuation contrast | Relational consequents, indefinite-binding XOR, multiple nested operators remain untested |
| Prover initial-if pronoun cue 5,160; indefinite conditional cue 455 | Two shared-antecedent rows and two inclusive consequents | Cat row repeats starter; someone row was simplified from passive; plural, possessive and relational binding missing |
| Prover explicit or-both cue 776 (302 inside initial-if) | Two inclusive-consequent readings, neither explicitly says or both | Need overt or-both controls distinct from bare-either interpretation convention |
| Prover conjunction/disjunction inside initial-if | Two antecedent conjunction and two antecedent disjunction rows | OR antecedents were authored AND-to-OR contrasts; no untouched occurrence frequency established for that group |
| Prover quantified-pronoun+who cue 959 | Starter everyone predicates only | No actual restrictive who pair; object relatives and scope contrast missing |
| Prover copula+a/an cue 1,180 (654 initial-if) | Mixed nominal cases inside nested antecedents | Dedicated positive/negative/quantified nominal controls incomplete; modification order/intersectivity separate |
| Prover short do outer 2,308; residual outer 3,791 | Two work negations, two matures intransitives | True transitive negation, PP attachment, phrasal verbs, titled names and lexical arity not represented by these four |
| Prover short have outer 632 | Two degree possession rows | Auxiliary versus lexical have, plural possession and nested object scope missing; lemma controls alone are not meaning gold |
| Prover reflexive cue 117 | Two Prover named and two quantified local reflexives | Relative/conditional scope stripped in adaptations; distractor and negation controls authored, not population evidence |
| Prover modal outer 139; not-necessarily-both cue 145 | None | Modal representation unresolved; cannot flatten to action or XOR and call exact |
| Pronto relative restriction AND cue 128,988; OR cue 47,862; predicate AND cue 149,937 | Three AND-restriction/conjunctive-consequent and three OR-restriction/conjunctive-consequent | These joint-profile frequencies are not the marginal cue counts; full profile audit still needed |
| Pronto predicate negation cue 47,529 | Three relative-negative cases: two OR restriction, one AND restriction | Add second AND-restriction negative-consequent case; do not claim three examples of each semantic family |
| Pronto sentence AND cue 5,516; 47 complete joint surface profiles | Ground/shared-subject predicate controls and nested rule cases | Sentence coordination with distinct subjects, sentence comma lists, and profile-to-gold crosswalk incomplete |
| ProofWriter transitive outer 2,162,712; generic conditional 1,001,985; coordinated generic 915,052 | Positive/negative ground relation and adjective generic pairs | Definite NPs, someone/they, relational antecedent/consequent shared arguments still missing |
| ProofWriter NatLang relative outer 102,260; coordination 91,240; attribution cue 32,684 | One adapted local reflexive, no NatLang scoped pairs | Relative, mixed coordination, attribution, habitual/modal/causal meanings remain unvalidated |
| FOLIO universal outer 117; initial-if 114; relative cue 83; AND cue 85 | Existentials/no/ordinary OR only, plus authored say controls | Universal, conditional, relative and mixed VP pairs missing from this snapshot |
| FOLIO passive cue 80; numeral cue 124; modal cue 26 | No matching gold | Voice/control, cardinality/arithmetic, temporal/modal contracts remain outstanding |

The earlier [85-row audit](../notes/gold-coverage.md) remains a historical
crosswalk; new local reflexive and nested connective gold closes some of its
missing cells, not all. Particle/PP, genuine relatives in ProverQA, independent
attitude/factive contrasts, multiword names, punctuation attribution, and broad
natural-language semantic refinement remain open. Later gold additions should
be audited as separate snapshots rather than silently included in these totals.

## Finite next authoring tranche

This is a bounded work queue, **not** a declaration of a finite complete English
grammar. Each row requests 2–3 independently reviewed examples per named semantic
family, ordinarily one direct instance, one scope/binding contrast and one
blocking neighbor. Existing examples count only when their complete semantics
fit; changed-text contrasts must remain flagged as adaptations.

| Priority | Benchmark | Families to author next | New rows requested |
|---|---|---|---:|
| 1 | ProverQA | Subject who-relative restriction; conditional indefinite-binding XOR; overt or-both consequent | 2–3 each (6–9) |
| 2 | ProverQA | Negated transitive with two arguments; lexical have with object witness; predicative nominal under negation | 2–3 each (6–9) |
| 3 | ProverQA | Multiword/titled name; attested lexical transitive frame; particle versus directional PP | 2–3 each (6–9) |
| 4 | ProofWriter | Someone/they generic binder; relational conditional binding; retained definite-description NP | 2–3 each (6–9), definites after contract |
| 5 | ProntoQA | AND-relative/negative consequent; distinct-subject sentence conjunction; sentence comma-list coordination | One additional first-family case plus 2–3 each other (5–7) |
| 6 | FOLIO | Restrictive relative with negation; mixed lexical/copular VP conjunction; universal implication | 2–3 each (6–9) |

Total planned additions: 35–52, conditional on input attestation and representation
review. A negative finding remains a finding: do not invent population frequency
or import another benchmark's frame to fill an empty cell. This tranche does not
resolve modals, hedged exclusion, subsective modifiers, temporal recurrence,
passives/control, cardinality, mass nouns, causal operators or full discourse
presupposition. Maintain an explicit unresolved register for these while their
contracts are developed; do not delete or rewrite source complexity to close it.

For each authoring group, reviewer checks Units 2/3/4 category derivation,
Montague meaning and scoped DRS/claims, plus the Boxer/ccg2lambda adopt/adapt/reject
comparison. Copying a published template is not independent gold. In particular,
restriction attachment, shared-witness coordination and modal barriers must
survive the chosen semantic type interface.

## Proposed evidence contract for the >=90% ProverQA gate

This operationalizes the owner's existing target; it does not authorize new
answer benchmarks or revise that target. The following is a proposal for review
before the gate evaluation, not a claim that current evidence satisfies it.

1. **Fix the target and denominator before evaluation.** Use local dev
   easy/medium/hard input occurrences (17,345) as the stated population, keeping
   theory/query and difficulty strata. Construction regression gold remains a
   separate diagnostic panel. Never substitute the pooled four-benchmark score,
   a count of labels, any-reading success or a curated easy-case average.
2. **Complete the semantic mapping, retaining unresolved membership.** Map each
   sampled sentence to all nested constructions and a complete joint profile;
   an exclusive outer label alone is insufficient. Need at least 2–3 independent
   gold cases per validated semantic family, including scope contrasts. Audit
   all residual profile types; unresolved/representation-blocked cases cannot be
   silently excluded or relabeled no-parse success. Overlapping cue counts cannot
   be used as additive weights. This inventory work remains unfinished today.
3. **Keep regression coverage and estimation separate.** A finite independent
   regression panel prevents easy-family domination by reporting each family,
   including rare high-risk scope/claim-status cases. To support an occurrence
   fidelity claim, preregister an input-only, reproducible stratified sample
   with known selection probabilities, preserve original wording, hand-author
   its meanings before parser observation, and retain every sampled item.
   Weight disjoint strata by actual occurrence mass, not overlapping feature
   counts. Exclude diagnostic adaptations from that population estimator.
4. **Require exact selected meanings.** Compute exact/all-fixed-cases and all
   per-family rates, alongside occurrence-weighted exact only if the sampling
   design supports it. Wrong-but-typed, no-parse, type failure, incomplete and
   instrumentation errors all stay in denominators. Report uncertainty for the
   estimator. Unknown semantic gold prevents certification of affected cases;
   preserve a conservative lower bound treating unresolved mass as non-exact,
   never infer their exactness from neighboring easy examples.
5. **Make near-zero explicit before running.** Recommend zero observed
   wrong-but-typed in the independent construction acceptance panel, including
   no assertion promotion under negation, implication or attitude, and publish
   weighted wrong-but-typed plus uncertainty in the representative audit.
   Zero observations is not proof of a zero population rate. Any alternative
   numerical near-zero tolerance must be recorded before inspecting scores;
   do not tune it after results. The >=90% exact threshold cannot excuse a
   systematic semantic error in one family or claim-boundary regression.
6. **Review denominator stability and all gates.** Reviewer verifies source
   locators, allowed-reading independence, duplicate texts, adaptations,
   unresolved registers and all retained wrong alternatives. Fresh results must
   identify binary/source/gold hashes and use the same frozen definition of
   exactness. Require construction acceptance, representative evidence adequate
   to the claimed scope, and release gates; the coordinator explicitly records
   the gate decision before any Phase E/model/answer benchmark restart.

The current 114 cases are a development and semantic regression panel. They are
not a probability sample; frequencies cannot make their average representative.
No population confidence interval, population 90% claim or launch authorization
follows from this audit. Gate remains closed pending the missing evidence.
