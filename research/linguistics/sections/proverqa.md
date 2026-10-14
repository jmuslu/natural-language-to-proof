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
