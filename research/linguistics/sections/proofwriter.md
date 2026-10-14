## ProofWriter: all 110 physical files

The inventory covers the local `proofwriter-dataset-V2020.12.3` release: **110 JSONL files, 702,271 records, 13,247,543 sentence occurrences and 172,834 globally unique sentence strings**. The aggregate and complete per-file manifest (paths, byte sizes, SHA256, records, original source units and expanded sentences) are in [`proofwriter-counts.json`](../proofwriter-counts.json). These are input frequencies, not parse coverage or meaning-fidelity scores.

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
