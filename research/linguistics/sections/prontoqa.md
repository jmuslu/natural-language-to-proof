## ProntoQA: complete local presented-input inventory

This audit covers **80 extracted JSON files, 65,600 records, 819,128 sentence
occurrences and 177,560 distinct strings** in the local ProntoQA acquisition.
The 79 JSON members of `generated_ood_data.zip` are byte-identical to extracted
copies and are not counted again. Counts include demonstrations, their queries,
and test queries; they are not restricted to the 120-item answer benchmark.
`prontoqa-inventory.json` records file hashes, per-file counts, role breakdowns,
and all 47 joint family/feature profiles. No raw sentence corpus is committed.

The executable audit is `inventory-prontoqa.py`. It reads only presented theory
and query fields for counting; answer/proof fields do not determine any labels.
It strips exactly the attested `Prove: ` and LogicLM query wrappers, preserving
sentence punctuation and rejecting unknown wrapper/schema shapes. Full-stop
sentence splitting is appropriate for this acquisition's generated text; this
is not a general English sentence segmenter.

| Input role | Records | Sentence occurrences |
|---|---:|---:|
| OOD demonstration theory | 57,200 | 638,133 |
| OOD demonstration query | 57,200 | 57,200 |
| OOD test theory | 7,900 | 106,735 |
| OOD test query | 7,900 | 7,900 |
| LogicLM theory | 500 | 8,660 |
| LogicLM query | 500 | 500 |

Theory/query records in a pair overlap: sum either record column half, not all
six rows. Distinct strings are deduplicated globally, not summed across files.

### Outer constructions, in occurrence order

The examples below are authored schematic illustrations. `P`, `Q` stand for
unary properties, not literal dataset words. A predicate position permits
article+noun, bare adjective, negation, and homogeneous coordination/list forms.
Features below specify which of those variants actually occur.

| Exclusive outer family | Schematic form | Occurrences | Distinct strings |
|---|---|---:|---:|
| Single named clause | Alex is a dax / red / not red. | 266,759 | 37,289 |
| Every/each universal | Every dax is red. | 185,426 | 30,878 |
| Bare-plural universal | Daxes are red. | 184,577 | 24,756 |
| Restrictive-relative universal | Everything that is a dax and red is blue. | 176,850 | 80,550 |
| Named sentence coordination | Alex is red and Max is blue. | 5,516 | 4,087 |
| Unmatched | Retained explicitly by recognizer | 0 | 0 |
| **Total** | | **819,128** | **177,560** |

All observed query sentences fall into the two named families. Repeated copulas
separate sentence coordination from coordinated predicates under one copula.
The outer recognizer is anchored to the entire sentence; noun/adjective surface
slots are intentionally lexical rather than inferred from benchmark answers.
The word-level matcher is permissive: zero unmatched means complete **surface
inventory**, not proved semantic unambiguity or parser fidelity.

### Overlapping features and location

| Feature | Sentence occurrences |
|---|---:|
| Predicate article+noun | 503,067 |
| Predicate bare adjective/property | 363,871 |
| Relative restriction article+noun | 176,850 |
| Relative restriction bare adjective/property | 155,864 |
| Predicate `and` | 149,937 |
| Relative restriction `and` | 128,988 |
| Relative restriction `or` | 47,862 |
| Predicate negation | 47,529 |
| Predicate `or` | 17,932 |
| Sentence `and` | 5,516 |
| Both `and` and `or` somewhere in sentence | 862 |
| Any internal comma | 54,022 |
| Relative restriction comma list | 28,166 |
| Predicate comma list | 25,430 |
| Sentence comma list | 798 |

These are presence counts, not operator-token counts, and must not be added to
estimate a denominator. In the JSON, `consequent_*` means the predicate position
of a rule or named clause; named clauses do not thereby acquire implication
semantics. The mixed-connective feature likewise does not license an arbitrary
scope or precedence: the 47 complete joint profiles retain the restriction,
predicate, and sentence positions. A comma within the first coordinated
sentence's predicate is not counted as sentence-level punctuation.

The earlier generic suffix heuristic reported 22,143 passive candidates. The
new audit accounts for every occurrence: `wooden` 7,392, `red` 7,394, `muffled`
7,357. These are predicative property vocabulary in the inspected generator,
not evidence for an `S[pss]` passive template. No transitive verb, reflexive,
particle/PP, explicit existential, attitude complement, or sentence-level `or`
is observed in these anchored families. This is an acquisition-specific result,
not a claim about every mode of the upstream generator.

### Generator evidence and semantic obligations

The inspected upstream revision is
[`asaparov/prontoqa@0a6412b`](https://github.com/asaparov/prontoqa/tree/0a6412b6fddf46324a1cb96e066dd7b3d89b87d6).
The source was inspected, not executed or used to obtain answer labels.
[`syntax.py`](https://github.com/asaparov/prontoqa/blob/0a6412b6fddf46324a1cb96e066dd7b3d89b87d6/syntax.py)
`formula_to_np` (lines49–112) constructs every/each, bare plurals, and
`everything that is` restrictions; its `randrange(1)` plural branch never emits
`all`. `formula_to_clause` (151–215) renders a universally quantified
implication, while its coordination branch (330–381) distinguishes shared-subject
predicate coordination from sentence coordination. `formula_to_vp_arg`
(121–149) handles article-noun/adjective lists. The property vocabulary in
[`run_experiment.py`](https://github.com/asaparov/prontoqa/blob/0a6412b6fddf46324a1cb96e066dd7b3d89b87d6/run_experiment.py)
(356–368) explains the suffix false positives. The repository revision is
supporting template evidence, not proof of the historical revision that produced
each acquired file; file SHA256s fix the actual counted acquisition.

For STUDY_PLAN Unit2, the high-frequency obligations are named `NP` versus
predicative `N`/`S[adj]`, determiners, universal bare plurals, relativizers, and
category-preserving coordination. Unit3 must retain subject sharing and operator
scope: `Every dax is red` means `forall x.(dax(x) -> red(x))`; the bare-plural
form has that reading in this controlled domain, without making it a global
English rule. `Everything that is a dax or red is blue` has a disjunctive
restriction, distinct from a disjunctive consequent. Article+noun predication
must yield `dax(alex)`, not identity with an introduced indefinite individual.
ProntoQA `or` is the inspected generator's FOL disjunction; ProverQA's exclusive
`either...or` policy must not leak into it.

For Unit4, ground assertions and universal implications enter Asserted at the
top level. Conditions inside a restriction, implication consequent, negation,
or disjunction are not independently asserted; there is no reporting source,
factive presupposition, or oracle confirmation licensed by these templates.
The construction-family design and independent gold must decide the concrete
canonical DRS representation and first Explain divergence. **This inventory
does not score fidelity or certify the ProverQA release gate.** No model,
answer benchmark, or CCGbank load was launched for this audit.

Reproduce from the local acquisition:

```sh
python3 research/linguistics/inventory-prontoqa.py \
  --data "$HOME/data/prontoqa" \
  --output /tmp/prontoqa-inventory.json
```

The script runs authored controls for relative operator location, predicate
versus sentence comma lists, and rejection of unsupported sentence shapes, then
checks occurrence conservation across role/family/profile/file partitions.
