# Construction inventory and fidelity work order

This is an inventory of the **presented input text**, with occurrence and distinct
surface counts. It is not parser coverage, semantic accuracy, or evidence that
the ProverQA fidelity gate is met. Frequencies include nested constructions;
exclusive outer buckets and overlapping cues have different denominators.

| Acquisition | Physical input files | Input records | Sentence occurrences | Distinct surfaces |
|---|---:|---:|---:|---:|
| ProverQA local dev easy/medium/hard | 3 | 1,500 | 17,345 | 17,285 |
| ProofWriter all stored variants/worlds | 110 | 702,271 | 13,247,543 | 172,834 |
| ProntoQA extracted acquisition | 80 | 65,600 | 819,128 | 177,560 |
| FOLIO committed 120-item sample | 1 | 120 | 744 | 439 |

These acquisitions differ: repetitions across ProofWriter staged/abductive files
and Pronto demonstrations are counted, while FOLIO is a sample and ProverQA's
advertised training partition is absent. No cross-dataset pooled percentage is
meaningful without stating a sampling target. File manifests/hashes fix local
scope; source-generator inspection is supporting evidence, not provenance proof.

ProntoQA's anchored surface inventory is complete for its local acquisition.
ProofWriter accounts for every physical file but retains156 occurrences/12 strings
outside its surface buckets and broad natural-language paraphrase groups needing
semantic refinement. ProverQA uses LLM verbalization: finite generated logical
skeletons do not establish finite English templates;3,791 lexical/frame occurrences
remain unresolved. FOLIO has238 residual occurrences/137 unique strings, with a
hand-audited sample of non-template constructions rather than exhaustive analysis.
These gaps stay visible and cannot be certified by a convenient atom-only gold set.

Read [DESIGN](DESIGN.md) for categories, terms, DRS/claim status and first
divergences, and the [independent gold coverage audit](../notes/gold-coverage.md)
for cases still needed. Inventory priorities are conditional internals/names,
predicative nominals and determiner meanings, relative restrictions, connective
scope/binding, relational frames, particles/reflexives and feature-sensitive VPs.
A large outer family is not permission to substitute an easy subclass.

The sections below are assembled from independently owned, reviewed benchmark
sections. Reproduction scripts produce aggregates; raw corpora and caches stay
outside version control. No labels, proof chains or hidden logical forms define
these sentence classifications.

## ProverQA: recovered surface inventory and unresolved frame audit

Scope: all locally available `dev/easy.json`, `dev/medium.json`, and
`dev/hard.json` (500 records each); the advertised training partition is absent
locally. Inputs contain **17,345 sentence occurrences, 17,285 distinct surfaces**:
15,845 theory sentences and 1,500 stripped questions. Difficulty totals including
questions are easy 2,529, medium 5,367, hard 9,449.

The local dataset card describes LLM translation of generated logical skeletons.
Thus the logical operator inventory is finite, but **an exhaustive finite English
template grammar has not been recovered**. Counts below are surface diagnostics,
not parser or semantic fidelity. Do not relabel the unmatched bucket with an
unrestricted lexical-verb catch-all and report it as recovered coverage.

### Outer families (exclusive, sum 17,345)

| Surface family | Occurrences | Distinct surfaces |
|---|---:|---:|
| Initial `if` conditional | 5,279 | 5,279 |
| Unclassified lexical/syntactic frame | 3,791 | 3,773 |
| Short subject + do-support | 2,308 | 2,299 |
| Short subject + copula | 1,607 | 1,591 |
| Noninitial `either` | 1,511 | 1,509 |
| Quantified pronoun / relative-headed subject | 983 | 982 |
| Short subject + have | 632 | 621 |
| Initial `for` topic | 491 | 489 |
| Initial universal nominal | 418 | 418 |
| Short subject + modal | 139 | 139 |
| Initial `either` | 123 | 122 |
| Final `if` conditional | 39 | 39 |
| Initial indefinite nominal | 24 | 24 |

These names describe recognizer precedence, not linguistic analyses. Initial `if`
wins even with a coordinated consequent. The shared key `existential_nominal`
means an initial indefinite surface, not proven existential force: generic
`A computer program that ... will ...` requires a separate interpretation.
Noninitial `either` does not prove VP-level attachment. Short-subject patterns do
not reliably handle titled names.

### Nested and overlapping cues

| Cue | All occurrences | Inside initial-if sentences |
|---|---:|---:|
| `he` / `she` / `they` | 5,714 | 5,160 |
| Explicit `not both` | 4,146 | 2,836 |
| `do/does/did not` | 2,439 | 26 |
| Copula + `a/an` | 1,180 | 654 |
| `who` | 1,074 | 14 |
| Quantified pronoun + `who` | 959 | 11 |
| Explicit `or both` | 776 | 302 |
| Negated copula | 562 | 6 |
| `if someone/anyone/somebody/anybody` | 504 | 455 |
| `that` candidate | 194 | 3 |
| Reflexive pronoun | 117 | 43 |
| `give up` inflection candidate | 8 | 5 |

`Not necessarily both` occurs 145 times, `not necessary` seven times, and
`mutually exclusive` 57 times. There are 1,468 sentences with `either` but without
any recognized explicit exclusion cue (`not both`, `mutually exclusive`,
`but not simultaneously`, `exactly one`). That is an audit bucket, not an
inclusive-or gold label. Cue counts overlap and must not be added. A `that`
token need not be a relative; pronoun occurrence does not establish coreference.
Three narrow particle patterns were checked: `give up` has eight matches;
`look up` and `carry out` have zero. This is not a complete phrasal-verb inventory.

The broader shared feature audit finds 4,120 sentences with a PP/particle token,
1,523 with an `-ing` candidate, 721 with a passive candidate, 406 with an
attitude/report verb candidate, and 1,600 with a possessive candidate. These are
review priorities, not validated semantic constructions.

### Explicit unmatched audit

The 3,791 residual occurrences partition into 3,602 with one capitalized token
followed by an `s`-ending lowercase token, 22 with one capitalized token followed
by another lowercase token, and 167 other shapes. The first group often resembles
name + finite lexical verb, but its token regex cannot establish part of speech,
arity, or particle/argument-PP/adjunct/idiom status. All 3,791 therefore remain
**unresolved at the construction-template level**. Inspection of the first 15
sorted examples in the final bucket found possessive subjects, titled/multiword
names, abbreviation punctuation, coordination and lexical verbs. This was an
illustrative inspection, not a random or exhaustive manual audit.

### Consequences for gold and implementation order

Start with shared foundations: names/titled names as NP, lexical frames,
negation and pronoun binding, then initial conditionals and nested disjunctions.
A conditional containing `not both` needs implication plus exclusion in its
consequent; neither branch becomes a top-level asserted fact. Distinguish exclusive
`not both` from weaker `not necessarily both`; never rewrite every `either` to XOR.
Retain modal and attitude content rather than flattening it to an asserted atom.
Names, N/NP, nominal predicates, PP/particle attachment, relative restriction,
reflexive identity and coordination each need independent gold.

Frequencies select work but do not permit less faithful meanings. Use at least
two or three hand-checked cases per validated construction, with scope and
claim-status contrasts. The 3,791 residual occurrences cannot be certified by one
broad “lexical verb” gold group. A 90% result on curated gold must name its
denominator; it does not establish 90% of this dataset's construction inventory.

### Reproduction and limitations

`inventory-proverqa.py --root /home/gram/data/proverqa` reads context and question
fields only, never `nl2fol`, answer, proof, or conclusion fields. This refinement
used `--cache` to stream the existing unique-sentence cache read-only, preserving
occurrence multiplicities; it reproduced both totals and every outer count.
Role/file totals above come from `other-counts.json`: a cache's first representative
role cannot reconstruct theory/query frequencies.

Sentence segmentation uses the shared punctuation heuristic with protected
`Dr.`, `Mr.`, `Ms.`, `Mrs.`, and `Prof.` abbreviations. New abbreviations or
punctuation may invalidate boundaries. This remains a surface audit, not complete
nested construction extraction. Source hashes and broad features are retained
in `other-counts.json`; prediction, command and results are in
`research/notes/inventory-proverqa.md`. No new parser, solver, benchmark or model
run was launched.


## ProofWriter: all 110 physical files

The inventory covers the local `proofwriter-dataset-V2020.12.3` release: **110 JSONL files, 702,271 records, 13,247,543 sentence occurrences and 172,834 globally unique sentence strings**. The aggregate and complete per-file manifest (paths, byte sizes, SHA256, records, original source units and expanded sentences) are in [`proofwriter-counts.json`](proofwriter-counts.json). These are input frequencies, not parse coverage or meaning-fidelity scores.

### Counting contract

Each physical record contributes its presented premises, ordinary questions and abduction questions once. Standard, staged and abductive variants remain separate: their repetitions measure the stored corpus, not independent observations. Theory sentences repeated in staged records therefore increase occurrence counts. Global unique strings are whitespace-normalized and retain punctuation and case. Unique counts across partitions overlap and must not be added.

For controlled inputs, extraction reads `triples[*].text`, `rules[*].text`, `questions[*].question` and `abductions[*].question`. It excludes labels, formal representations, proofs, inference targets and abduction answer facts. For NatLang records it reads the presented `sentences` aligned to `theory`; mappings identify source roles, never authorize a synthetic replacement of the English meaning. Unmapped new stage facts are retained.

The recovered initial audit had 5,312 theory reconstruction mismatches caused by punctuation differences between NatLang mappings and the presented theory. The existing alignment repair preserves authoritative theory punctuation; zero reconstruction mismatches remain. Splitting 881 distinct multi-sentence source units (6,698 occurrences) at punctuation followed by whitespace adds 7,130 sentences. Fragments are retained. Source-unit counts remain in the manifest. This delimiter rule is explicit, not a general abbreviation-aware sentence tokenizer.

| Input role | Sentence occurrences |
|---|---:|
| `abduction_question` | 328,890 |
| `premise_fact` | 7,187,577 |
| `premise_rule` | 4,040,020 |
| `question` | 1,691,056 |

| Stored variant | Files | Records | Sentence occurrences | Unique strings within variant |
|---|---:|---:|---:|---:|
| abduct | 22 | 59,649 | 1,119,465 | 118,390 |
| stage | 38 | 463,341 | 8,058,438 | 171,536 |
| standard | 50 | 179,281 | 4,069,640 | 171,962 |

The worlds are CWA: 44 files / 6,294,707 sentences and OWA: 66 files / 6,952,836 sentences. Surface layers are 12,787,061 controlled sentence occurrences and 460,482 paraphrase occurrences. A paraphrase may happen to match a controlled surface pattern; family labels and source layers are separate.

### Outer construction families in occurrence order

Controlled families are explicit anchored surface grammar patterns. `PW.NL.*` families are ordered diagnostic groupings by lexical cues: conditional, attribution, causal, relative, quantified/generic, coordination, modal/habitual, copular, lexical predicate. They are not mutually exclusive semantic constructions; precedence assigns one outer bucket and the overlapping feature table retains other cues. In particular, a relative cue can contain an attitude, and a modal paraphrase must not inherit its hidden synthetic fact.

| Family ID | Surface shape | Occurrences | Unique strings |
|---|---|---:|---:|
| `PW.ATOM.COPULAR` | Ground/name subject + copula + adjective (positive) | 5,689,297 | 266 |
| `PW.ATOM.TRANSITIVE` | Ground subject + transitive verb + ground object | 2,162,712 | 616 |
| `PW.COND.GENERIC` | If generic someone/something antecedent, then consequent | 1,001,985 | 20,056 |
| `PW.COND.GENERIC.COORD` | If generic antecedent conjunction, then consequent | 915,052 | 75,898 |
| `PW.ATOM.COPULAR.NEG` | Ground/name subject + copula + not + adjective | 829,487 | 266 |
| `PW.UNIVERSAL.BARE` | Bare adjective(s) people/things are adjective | 597,392 | 6,360 |
| `PW.UNIVERSAL.EXPLICIT` | All adjective(s) people/things are adjective | 590,281 | 6,319 |
| `PW.ATOM.TRANSITIVE.NEG` | Ground subject + do-support negation + transitive predicate | 372,811 | 616 |
| `PW.COND.GROUND` | If ground antecedent, then ground consequent | 367,824 | 21,062 |
| `PW.COND.GROUND.COORD` | If ground antecedent conjunction, then consequent | 321,762 | 36,318 |
| `PW.NL.RELATIVE` | Paraphrase containing who/that/which relative-like dependency | 102,260 | 909 |
| `PW.NL.COORDINATION` | Other paraphrase with and/but/yet/or or comma coordination cue | 91,240 | 2,123 |
| `PW.NL.GENERIC.PLURAL` | Paraphrase with a bare plural person/thing/individual subject | 45,202 | 222 |
| `PW.NL.CONDITIONAL.FRONT` | Paraphrase with fronted if/when/whenever/once condition | 39,022 | 234 |
| `PW.NL.ATTRIBUTION` | Paraphrase with explicit speech/belief/knowledge/evidential wording | 28,152 | 444 |
| `PW.NL.GENERIC.INDEFINITE` | Paraphrase with an indefinite person/thing/individual subject | 28,126 | 135 |
| `PW.NL.CAUSAL` | Paraphrase with because/since/causal connective | 20,248 | 335 |
| `PW.NL.COPULAR` | Other paraphrase containing finite copular predication | 14,250 | 281 |
| `PW.NL.CONDITIONAL.POST` | Paraphrase with noninitial if/when/whenever/unless condition | 13,558 | 235 |
| `PW.NL.MODAL.HABITUAL` | Other paraphrase with modal/frequency/tendency wording | 7,214 | 32 |
| `PW.NL.QUANTIFIED` | Paraphrase beginning an explicit universal/negative quantifier | 4,822 | 18 |
| `PW.NL.NONCOPULAR` | Other paraphrase with an identifiable finite lexical-verb frame | 4,464 | 53 |
| `UNCLASSIFIED` | Input outside the explicit surface patterns; manual review required | 156 | 12 |
| `PW.ATOM.NOMINAL` | Ground subject + copula + indefinite nominal predicate | 142 | 8 |
| `PW.ATOM.NOMINAL.NEG` | Ground subject + copula + not + indefinite nominal predicate | 56 | 8 |
| `PW.ATOM.MODAL.NEG` | Ground subject + cannot + intransitive predicate (birds variant) | 18 | 4 |
| `PW.ATOM.MODAL` | Ground subject + can + intransitive predicate (birds variant) | 10 | 4 |

`PW.ATOM.INTRANSITIVE` and `.NEG` are implemented inventory patterns with zero observed occurrences, rather than evidence of absent intransitive language inside paraphrases. `UNCLASSIFIED` remains **156 occurrences / 12 strings**. The unresolved strings comprise missing-copula fragments, an association/reflexive idiom and possessive lexical predication (for example, “His red cheeks glowed.”). No unmatched input is silently dropped or relabeled as understood.

### Nested constructions and meaning hazards

The following overlapping frequencies measure lexical/surface cues, not independently verified parses. They can exceed a parent family count and cannot be summed to get corpus size.

| Cue | Occurrences | Unique strings |
|---|---:|---:|
| `transitive_lexicon` | 4,023,858 | 116,587 |
| `conditional` | 2,659,203 | 153,803 |
| `existential_wording` | 1,965,857 | 96,272 |
| `pronoun` | 1,772,407 | 78,241 |
| `negation` | 1,702,332 | 59,186 |
| `coordination_and` | 1,473,294 | 115,546 |
| `sortal_people_things` | 1,296,039 | 13,343 |
| `generic_human_variable` | 996,920 | 48,121 |
| `generic_thing_variable` | 958,477 | 48,055 |
| `multiword_entity` | 896,419 | 23,440 |
| `clause_coordination` | 853,147 | 96,054 |
| `comma` | 663,325 | 13,714 |
| `explicit_quantifier` | 619,369 | 6,641 |
| `adjective_coordination_ellipsis` | 472,603 | 17,326 |
| `relative_cue` | 128,546 | 1,204 |
| `habitual_or_hedged` | 85,754 | 774 |
| `modal` | 85,223 | 702 |
| `comparative_or_degree` | 74,818 | 1,215 |
| `coordination_other` | 45,348 | 1,062 |
| `attribution` | 32,684 | 487 |
| `causal` | 23,910 | 407 |
| `relational_preposition` | 10,272 | 24 |
| `reflexive` | 1,564 | 34 |
| `parenthesis_or_quote` | 296 | 6 |

These counts give a concrete implementation order, subject to fidelity controls:

1. Name/definite NP and copular adjective predicates; transitive argument order; explicit negation and do-support. The first two positive atom families alone dominate occurrences, but their tiny unique sets do not justify lexical memorization.
2. Generic conditional binding (`someone`/`something` with `they`/`it`), conjunction and omitted repeated copulas; distinguish ground conditionals. Never let an antecedent variable become a new unrelated consequent referent.
3. Explicit and bare generic adjective restrictions with `people`/`things`. The intended DRS must distinguish genuine sortal restrictions from conventions imposed by the synthetic generator; the English alone does not justify deleting a restriction.
4. Paraphrase relatives, attribution, causal wording, modals/habituals, reflexives and multiword predicates/entities. `runs through` and multiword entities need categories and argument structure, not token deletion. Attribution has 32,684 cue-bearing occurrences and must remain protected from assertion promotion even when a paraphrase maps to a synthetic fact.

Use these IDs in the independent hand-checked gold and the learner design. CCGbank categories and derivations belong to STUDY_PLAN Unit 2; category-to-Montague templates to Unit 3; implication binding, negation and Asserted/Reported/Presupposed/Embedded status to Unit 4. See the coordinator’s DESIGN document for construction semantics and first Explain divergences. The inventory itself cannot certify any intended DRS or authorize the 90% ProverQA gate.

### Reproduction and integrity

The existing extractor and repair are preserved in `inventory-proofwriter.py`. Raw rows, the SQLite database, exhaustive skeletons and unresolved-input audit remain under ignored `research/runs/linguistics/proofwriter/`; only aggregates and compact examples are in the JSON artifact. Recovered data can be summarized with:

```sh
python3 research/linguistics/inventory-proofwriter.py summarize \
  --work research/runs/linguistics/proofwriter \
  --output research/linguistics/proofwriter-counts.json
```

The current manifest exactly matches all 110 local JSONL paths, with no missing or extra files. Family, per-file, role and surface-layer occurrence sums all equal 13,247,543. The controlled-unexpected audit is empty. Five existing extraction tests pass: gold independence/stage addition, presented NatLang selection, punctuation alignment, multi-sentence expansion/idempotence, and surface-template distinctions. This is an integrity audit of recovered counts; source hashes were retained from extraction, not recomputed in the recovery pass. There is no claim that every NatLang construction has been semantically recovered.


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


# FOLIO sample: measured surface inventory and audited exceptions

This section audits English inputs in the committed 120-item FOLIO sample. Each
newline-delimited context premise and each query is one input unit, preserving
abbreviations such as *Symphony No. 9* and decimal numbers. Repeated contexts
across questions count repeatedly; unique strings provide the distinct surface
count. No label or supplied formula is used. These are sample counts, not counts
for the full FOLIO release or estimates from a random sample.

Reproduce with `python3 research/linguistics/inventory-folio.py`. The shared
`inventory-other.py` functions define bucket precedence and lexical cues. The
22 manually selected exact exemplars in the specialist script are separately
audited, construction-bearing inputs. Their counts are **only occurrences of
those exact exemplars**, not complete frequencies of their semantic constructions.

Sample: 120 items; 744 units; 439 unique strings.
Roles: {'premise': 624, 'query': 120}
SHA256: 23ba94be7ce19de4f1345cd6849b1d916b1d65636b44548a22a6f7fc2b66561d

Outer surface buckets (mutually exclusive by precedence)

| Diagnostic | Occurrences | Unique strings |
|---|---:|---:|
| `unclassified` | 238 | 137 |
| `universal_nominal` | 117 | 69 |
| `conditional_initial` | 114 | 65 |
| `subject_copula` | 88 | 55 |
| `existential_nominal` | 47 | 31 |
| `negative_quantifier` | 23 | 14 |
| `bare_plural_generic` | 20 | 10 |
| `vp_either_or` | 19 | 13 |
| `subject_have` | 18 | 9 |
| `conditional_final` | 17 | 8 |
| `quantified_pronoun_or_relative` | 11 | 6 |
| `vp_neither_nor` | 10 | 7 |
| `subject_do` | 7 | 6 |
| `existential_there` | 5 | 3 |
| `sentence_either_or` | 4 | 2 |
| `biconditional` | 3 | 1 |
| `subject_modal` | 3 | 3 |

Overlapping lexical cues (not constructions)

| Diagnostic | Occurrences | Unique strings |
|---|---:|---:|
| `particle_or_pp` | 366 | 216 |
| `punctuation_internal` | 173 | 90 |
| `negation` | 159 | 100 |
| `conditional` | 136 | 75 |
| `gerund_candidate` | 124 | 77 |
| `numeral` | 124 | 67 |
| `possessive` | 120 | 65 |
| `coord_and` | 85 | 49 |
| `relative` | 83 | 44 |
| `passive_candidate` | 80 | 46 |
| `coord_or` | 72 | 40 |
| `either` | 37 | 23 |
| `modal` | 26 | 18 |
| `existential_there` | 10 | 5 |
| `only` | 7 | 5 |
| `biconditional` | 4 | 2 |
| `never` | 1 | 1 |

Hand-audited exact exemplars

| Construction or exception | Occurrences | First input reference (zero-based index) |
|---|---:|---|
| graded quantity | 2 | `folio-val-25:premise:5` |
| currency comparison | 3 | `folio-val-93:premise:8` |
| temporal adjunct + passive particle | 2 | `folio-val-164:premise:0` |
| reduced relative + passive | 2 | `folio-val-112:premise:2` |
| restrictive relative + negation | 2 | `folio-val-74:premise:1` |
| infinitival attitude | 3 | `folio-val-47:premise:4` |
| infinitival preference | 1 | `folio-val-96:query:0` |
| impersonal cost + infinitive | 2 | `folio-val-106:premise:0` |
| possession + cross-sentence anaphora | 2 | `folio-val-106:premise:4` |
| explicit relational from adjunct | 2 | `folio-val-181:premise:2` |
| explicit relational to adjunct | 1 | `folio-val-181:query:0` |
| mixed VP coordination | 1 | `folio-val-197:query:0` |
| passive particle + goal | 1 | `folio-val-203:query:0` |
| passive by-agent | 3 | `folio-val-187:premise:4` |
| reduced passive modifier | 3 | `folio-val-187:premise:5` |
| proper name + negative predication | 2 | `folio-val-164:premise:4` |
| quotation-delimited proper name | 1 | `folio-val-22:premise:4` |
| superlative quantified comparison | 1 | `folio-val-67:query:0` |
| negative existential + nested relatives | 2 | `folio-val-112:premise:3` |
| fronted biconditional + pronoun | 1 | `folio-val-22:premise:2` |
| fragment enumeration | 2 | `folio-val-10:premise:1` |
| input typo | 1 | `folio-val-200:query:0` |

## What lies outside generated templates

The unclassified bucket contains 238/744 occurrences (32.0%) and 137/439 unique
strings (31.2%). That is a limitation of the surface classifier, not a parser
failure rate. Many unclassified strings are ordinary clauses with multiword
names. Conversely, a classified clause may contain unsupported semantic material.
For example, the fronted biconditional at `folio-val-22:premise:2` enters
`conditional_initial`, while the biconditional cue correctly marks it as containing
*if and only if*. Outer counts must not substitute for scoped construction counts.

The hand audit identifies the following additional work for Units 2/3/4:

- **Clause and VP types:** infinitival preference/attitude (*Koalas love to
  sleep*, *James wants to have a long vacation*) require `S[to]` complements and
  subject control; asserting sleeping or possessing a vacation would be wrong.
  Passive clauses and reduced passives require `S[pss]`, preserving the patient
  and optional by-agent. A reduced modifier such as *written in 2003* contributes
  a restriction within the NP, not a detached assertion about an invented subject.
- **Names, particles, and adjuncts:** *Breaking Bad* is a multiword NP, not a
  gerund predicate. *Loaned out to* and *given out on TV* combine particles with
  distinct goal/location adjuncts. *Flies from LGA* and *flies to LGA* must retain
  different relations. One undifferentiated PP bucket cannot establish this.
- **Quantification and comparison:** *many*, monetary comparisons, superlatives,
  temporal quantification, and negated existentials exceed unary Horn templates.
  *There are no mountain ranges ... that have mines which have been donated*
  places existential and relative content under negation; none is independently
  Asserted. No cardinality or numeric ordering follows from treating numbers as
  ordinary individual names.
- **Binding and composition:** possessives and *His dad* require discourse
  antecedents; isolated sentences cannot recover all intended references.
  *KiKi barks and is a dog* coordinates unlike-looking VPs with a shared subject.
  Restrictive relatives must bind the head argument through their clause, while
  appositive and reduced relatives require separate attachment/scope review.
- **Input exceptions:** `[BG]` is source annotation, not a semantic predicate;
  quote-delimited titles are names. The enumeration fragment at
  `folio-val-10:premise:1` is not a complete clause. *foes not play* at
  `folio-val-200:query:0` is an apparent typo; preserve it in an input audit and
  record any repair explicitly rather than silently treating it as *does*.

The cue counts deliberately retain known false positives: *Boeing 707* matches
`gerund_candidate`; *1984 is printed text* matches `passive_candidate` although
*printed* can modify the nominal; *only children* matches `only` without an
only-if operator. `relative` includes any *that*, not solely relative pronouns,
and `numeral` includes years, names, measurements and cardinalities. No listed
cue is a proof of a CCG category or a semantic operator. No reflexive/attitude
cue count was found by these particular patterns; that does not establish absence
of control, desire, anaphora or implicit attribution.

## Remaining gate

The sample's frequency recovery is reproducible at the input-unit, outer-bucket,
and cue levels. The exact semantic inventory is **not complete**: audit all 439
unique inputs for nested scopes, attachment, lexical senses, multiword names and
fragments; split the 137 unclassified strings into actual constructions; then
supply two or three independent DRS/claim examples per construction. The 22
hand-audited exemplars establish required design cases, not a substitute for that
work. No parser fidelity or benchmark accuracy is claimed in this section.
