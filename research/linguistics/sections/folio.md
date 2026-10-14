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
