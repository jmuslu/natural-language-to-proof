## ProverQA residual lexical frames: bounded manual refinement

This refines, rather than replaces, the 3,791 unresolved occurrences / 3,773
distinct sentences in the ProverQA outer inventory. Input-only cache totals remain
17,345 / 17,285. No parser output, model, solver or answer benchmark was used.
The earlier 3,602 / 22 / 167 token-shape split is not linguistic coverage.

A manual review of predicate-tail types and representative sentences identifies
**249 occurrences / 247 distinct surfaces** in narrow, fully anchored patterns;
**3,542 occurrences / 3,526 surfaces remain outside that audit**. This is 6.57%
of residual occurrences, not 6.57% exact meaning. The audited patterns establish
outer construction candidates; lexical meaning, tense/aspect, noun-phrase force,
reference and DRS fidelity still need independent gold. No pattern declares a
successful parse or contributes an “exact” fidelity score.

### Narrow audited forms (exclusive)

Names below are authored placeholders. Each pattern allows a single capitalized
name followed by an enumerated predicate tail and final period, except the two
explicit subject patterns. The script is the complete finite list; no unrestricted
verb or arbitrary remainder is accepted. Review covered the listed tail types,
not manual semantic annotation of all 249 sentence instances.

| Construction and representative authored form | Occurrences | Distinct | Review finding |
|---|---:|---:|---|
| `Alex values tradition / stability` | 50 | 48 | Transitive V plus bare abstract nominal; bare noun is not automatically a universally quantified NP. |
| `Alex thinks critically / creatively` | 28 | 28 | Intransitive V plus manner adverb; not propositional belief content. |
| `Alex takes risks / responsibility` | 27 | 27 | Surface V+NP, but light-verb/idiomatic meanings require lexical review. |
| `Alex works hard / independently` | 25 | 25 | Intransitive V plus adverb; do not interpret adverb as object. |
| `Alex collaborates with experts / peers` | 21 | 21 | Prepositional complement; implicit plurality/reciprocity needs a convention. |
| `Alex cares for patients / plants` | 16 | 16 | Prepositional construction distinct from `cares about`; do not erase `for`. |
| `Alex lives near the coast / in the forest` | 15 | 15 | Locative PP; scope/argument-versus-adjunct choice remains open. |
| `Alex thinks outside the box` | 13 | 13 | Idiom; literal containment relation is not a justified meaning. |
| `Alex listens actively / carefully` | 12 | 12 | Intransitive V plus manner adverb. |
| `Alex cares about nature / others` | 12 | 12 | Prepositional attitude/concern construction; not an asserted property of nature/others. |
| `Alex stays calm / healthy` | 11 | 11 | Predicative adjective after aspectual linking verb; retain persistence meaning. |
| `Alex listens to opera / podcasts` | 6 | 6 | Prepositional complement; nominal interpretation is not generic universal quantification. |
| `Dr. Alex Reed does not develop new treatments` | 4 | 4 | Title + one/two name tokens; negated transitive clause. Recognizer also admits two other reviewed object phrases. |
| `Alex shares recipes or respects tradition` | 3 | 3 | Shared-subject lexical VP disjunction; other reviewed tail uses `appreciates ... or learns about ...`. |
| `Alex values privacy or is introverted` | 2 | 2 | Lexical and copular VP disjunction; do not coordinate NP object with adjective directly. |
| `Alex's work is not viral / relationship is not spontaneous` | 2 | 2 | Possessive subject with negated predication; Alex is possessor, not the predication's subject. |
| `Alex gives up` | 1 | 1 | Particle idiom without overt object; plain give's transitive frame is wrong. |
| `Alex stands out` | 1 | 1 | Particle construction; not simply a locative PP. |
| **Remaining outside narrow audit** | **3,542** | **3,526** | Explicitly unresolved. |
| **Residual total** | **3,791** | **3,773** | Counts preserve cache multiplicity. |

These are manually specified surface families, not recovered generator templates.
Some singleton families cannot yet supply 2–3 independent observed examples in this
residual bucket; authored gold controls must be labelled as such, or source
instances sought elsewhere in the input corpus. Frequency order must not silently
replace low-frequency but meaning-changing particle/possessive cases with a generic
verb template.

### Broader candidate cues (overlapping, not a partition)

| Cue in residual sentences | Occurrences | Distinct |
|---|---:|---:|
| Preposition/particle token from explicit list | 611 | 608 |
| `and` or `or` | 360 | 360 |
| Any apostrophe/pronominal possessive | 285 | 284 |
| Initial title (`Dr.`, `Mr.`, `Mrs.`, `Ms.`, `Prof.`) | 133 | 133 |
| Initial `takes/makes/gives/has/does` after simple name | 126 | 126 |
| Initial `thinks/believes/knows/says/understands/hopes/wants` | 104 | 104 |
| Initial `becomes/stays/remains/seems/appears` | 76 | 76 |
| Selected complement-taking verb followed by `-ing` token | 44 | 44 |
| `up/out/off/back/away` | 17 | 16 |
| Initial possessive subject | 12 | 12 |

The initial-title and initial-possessive buckets reveal failures of the previous
short-subject outer recognizer, including ordinary negated/copular clauses hidden
inside its residual. Candidate particle tokens include locatives and `up to date`;
17 is not a phrasal-verb count. Coordination tokens cannot determine whether the
conjuncts are NPs, VPs or clauses. The PP list is explicit and incomplete, and
`-ing` cannot determine gerund versus participle versus noun.

The most common second tokens after simple names are `values` (167), `enjoys`
(94), `pursues` (88), `studies` (79), `makes` (73), `lives` (71), `works` (69),
`explores` and `loves` (53 each). These are lexical review priorities, not POS tags
or valency counts. `lives a private life`, `lives abroad`, and `lives in ...`
require different surface analyses. `enjoys music` and `enjoys experimenting with
food` cannot share an unexamined object template. A verb-shaped second token does
not establish a unary predicate.

### Source check and representation consequences

The [ProverGen source entry point](https://github.com/opendatalab/ProverGen/blob/main/logic_skeleton_translator.py)
inspected 2026-10-14 initializes `Translator`, calls `translate_rules_and_facts`,
then adds distracting rules and generates problems. Its default model argument is
Meta-Llama-3.1-70B-Instruct; the [project documentation](https://github.com/opendatalab/ProverGen#step-2-logic-skeleton-translation-)
describes LLM natural-language translation. This is source inspection only: none
of these components was launched. It does not reveal a finite deterministic
English template set. No instance's logical mapping or answer was used to infer a
frame in this refinement.

For future design, Unit 2 must distinguish `S\NP`, `(S\NP)/NP`, and PP-taking
categories, plus title/name and possessive-NP structures. Unit 3 must not turn an
arbitrary object phrase into a unary atom to fit benchmark labels. Unit 4 must
retain negation/disjunction boxes and avoid asserting each disjunct separately.
The independent gold should expose exactly these choices, especially light verbs,
abstract/mass nouns, gerunds, aspect and phrasal predicates. Counts alone cannot
resolve an intentional predicate ontology.

### Reproduction

```
python3 research/linguistics/inventory-proverqa-frames.py --cache /home/gram/nl2proof-astra/research/runs/linguistics/other-refresh/proverqa-unique.jsonl
```

Cache SHA-256: `bb4787e94e99f97f41f5aa0045e307aa05043ce769d5d2cc2a627e8b4013269e`.
Only cache `text` and `count` fields are accessed. Printed output contains counts,
rule labels and head-token frequencies, not full sentence listings. Sentence
segmentation inherits the earlier cache and is not independently validated here.
No raw cache or bulk derived text is committed.
