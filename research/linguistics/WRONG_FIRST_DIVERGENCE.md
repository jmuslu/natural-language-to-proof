# First divergences in the accepted 26 wrong readings

Snapshot: accepted noun-lemma commit `169c761`; this diagnostic changes no gold,
status, source, denominator, or acceptance contract. All 26 `wrong_but_typed`
rows in `research/runs/noun-lemma-integration/fresh.json` were replayed once,
in report order, through its frozen `explain-accepted --all-readings` binary.
Only sentence text entered Explain. The shared slot wrapper controlled the one
CCGbank load. Predictions were written in the accompanying note before launch.

The Explain binary SHA-256 is
`1952e455cd12f3faec823b7dab01cd1bb2b36d1b99bbe5b84f71c18f85ff8a74`.
Its manifest's source hashes were checked against `169c761`; the cases hash
`27e2f67dbf30397ca62345363bcb503d676297bbcd078d9d4da6685b019e92f6`
was checked against the accepted report. Explain and fidelity are different
executables; this is not a claim their binary hashes match.

Evidence is retained in the ignored `research/runs/wrong-first-divergence/`:
`manifest.json` preserves the frozen source manifest, report/cases hashes and
ordered input identities; `explain.log` contains every reading and stage;
`claim-comparison.json` records output hashes, per-case offsets and comparisons.
All four selected claim groups match the sealed canonical JSON when rendered
with the canonical condition syntax: **26/26**. This checks selected asserted
DRS conditions and embedded claim structure/order, not byte equality of the
pretty DRS or a separate equality check of its root universe. The original
observations, contracts and metadata remain unchanged.

## Earliest mismatch in a compatible reconstruction

Line numbers below identify case starts in `explain.log`. Stage 1 lists offered
categories. As documented in `tools/Explain.hs`, internal categories are not
retained by the pipeline: stages 2/3 replay recorded rules over lexical candidates
and retain a replay whose root meaning matches the pipeline root. Thus the table
reports **compatible reconstructed categories and leaf meanings**, not the unique
original chart choices or a retained producer witness. Root meanings and the
26/26 selected-claim comparison remain direct evidence. Source inspection
establishes what the replay's lexical templates do, not which candidate originally
produced the root. These reconstructions locate plausible early mismatches;
original-chart first divergence remains unverified without retained witnesses.

| Case IDs (log lines) | Compatible reconstructed route and resulting mismatch |
|---|---|
| pronto-bare-1 (1), pronto-bare-2 (184), pronto-bare-3 (358) | Reconstructed subject NP proper-name term lifts Jompuses/Wumpuses as constants. Ground predication replaces bare-plural generic scope. The N alternative does not establish an exact reading. |
| pronto-rule-and-2 (582), pronto-nested-plural-and-1 (3772), pronto-nested-plural-and-2 (4005), pronto-nested-plural-and-3 (4238) | Reconstructed Gorpuses/Impuses/Dumpuses NP name terms produce ground coordinated predicates. First two IDs share sentence text; this is four frozen rows, not four independent sentences. |
| prover-subject_do-1 (815), pw-atom-transitive-neg-2 (2421) | Dean/Bill reconstructed N terms `dean(x)`/`bill(x)` become generic NP through unary type-change. This replaces the intended individual with a universal restriction before negation is built. Colin remains a proper name in the latter case. |
| prover-quantified_pronoun_or_relative-1 (1133), prover-quantified_pronoun_or_relative-2 (1293), prover-who-restriction-1 (4825) | Everyone reconstructed N `everyone(x)` becomes generic NP. The relative case preserves its driven restriction, but adds the wrong everyone predicate. Neither historical unrestricted nor strict person-domain contracts licenses `everyone(x)`. |
| pw-cond-generic-coord-1 (2585), pw-cond-generic-coord-2 (2817) | Closed NP something explicitly introduces `thing(x)` under existence; the gold contract uses an unrestricted binder. This is a domain-contract discrepancy already in the leaf term, not an inferred pronoun-binding failure. It does not authorize erasing restrictions on the noun things. |
| prover-existential_nominal-1 (1458) | Excels reconstructed `S[adj]\\NP` leaf retains `excels(x)`; the whole reconstructed category is S[adj]. Reading 2 has `S[pss]\\NP` and `excel(x)`, giving S[pss]. This does **not** demonstrate a correctly categorized finite intransitive reading; changing selection to passive on matching output alone would not repair construction fidelity. |
| folio-some-2 (1617), folio-some-not-2 (1932) | Reconstructed birds N is correctly normalized to `bird`; reconstructed hawks `S[adj]\\NP` remains `hawks`. Adjectival copula composition carries that predicate into the existential/negative scope. The noun lemma hook is not the reconstructed predicate path. |
| folio-extended-universal-3 (4611) | Reconstructed monkeys N is correctly normalized to `monkey`; mammals `S[adj]\\NP` remains `mammals`. Alternative N[num] monkeys is separate from the repaired plain-N reading. |
| folio-some-3 (1806), folio-no-1 (2161), folio-no-2 (2289), folio-extended-universal-1 (4471) | Plain N pets/animals/humans still have surface predicates; cows/alligators, where present, select adjective predicates. Unchanged N terms establish absence of normalization, but the trace does not expose rejected noun/base evidence sets: the exact licensing failure remains unknown. |
| prover-universal_nominal-2 (964) | Thriving N/N prepends `thriving(x)` to frogs N `frogs(x)`: modifier-first order and remaining noun morphology both differ. The reason frogs fails the noun evidence gate is not established by this trace. |
| pw-universal-bare-2 (3042), pw-universal-explicit-1 (3173) | Cold/blue/young N/N meanings prepend their predicates to the nominal property; people yields person. The reconstructed conjuncts agree extensionally with gold but differ in structural order. Scores remain wrong; no sorting or gold rewrite is proposed. |
| pw-universal-explicit-2 (3500) | Reconstructed kind is N, **not** N/N. Stage 2 coordinates N kind with N red things, yielding kind/red/thing order under All. This reconstructed result is an order discrepancy, but reading 2 instead coordinates quantified NP meanings, producing separate universal implications. Treating all readings as harmless modifier permutations would be false. |

## Consequences for the next source proposal

1. Bare-plural versus rigid-name licensing is the largest observed scope-harm
   group (seven rows, six texts); Dean/Bill show the opposite direction. A
   category/origin-aware contextual proposal needs independent red controls in
   both directions. The trace alone does not justify capitalization overrides.
2. Nominal complements and finite verb categories need faithful category
   licensing, not broader noun suffix stripping or selection by output match.
   Hawks/mammals and excels have compatible reconstructed category evidence,
   not retained original lexical-choice witnesses. Preserve the
   noun repair already observed on bird/monkey. Missing POS-gate evidence for
   pets/animals/humans/frogs must be obtained from lexical evidence inspection,
   not guessed from these outputs.
3. Quantified pronoun meanings require explicit contract partitions and
   construction rules. The reconstructed everyone-as-noun route is wrong under both relevant policies;
   something's thing restriction is a distinct policy question. Keep pure
   structural-order failures separate from truth-conditional scope harm.

These are diagnostic priorities, not implementation approval, population
frequencies, or a new benchmark. The 26-row selection is conditioned on already
wrong outputs and cannot estimate construction prevalence or the 90% gate.
No new model, answer benchmark, source change or gold correction occurred.
