# ProverQA acceptance denominator proposal

Snapshot: branch `c409f22`, all current fidelity files and the sealed
[fused-integration report](../runs/fused-integration/fresh.json). This is a
reviewable evaluation specification, not an executed sample or gate decision.
The owner target remains >=90% selected exact with near-zero wrong-but-typed;
new model/answer benchmark launches remain paused. No threshold is weakened and
no observed failure is relabeled by this document.

## Current evidence and duplication

Selecting rows by `origin.benchmark == ProverQA` across current gold gives
**53 rows, 52 distinct texts and 25 construction labels**. All53 IDs occur in the
frozen154 diagnostic report. “If a cat is nimble, then it is agile.” appears as
both `prover-conditional_initial-1` and `prover-nested-binding-1`; it is one text,
not two independent construction observations. Preserve both historical rows for
regression but count the text once in coverage accounting.

| Existing metadata partition | Rows | Exact | Wrong-but-typed | No-parse | Incomplete |
|---|---:|---:|---:|---:|---:|
| Legacy metadata absent | 49 | 22 | 5 | 21 | 1 |
| proverqa-strict-english-v1 | 2 | 0 | 1 | 1 | 0 |
| proverqa-controlled-v1 | 2 | 0 | 0 | 2 | 0 |

Type-failure/error are zero here. These are frozen diagnostic counts, not pooled
acceptance: legacy49 contains disclosed, differing quantifier conventions.
Overall bookkeeping is22/6/24/1, but no acceptance rate is inferred from it.
Authored reflexive distractor/negative controls and other benchmarks do not enter
this ProverQA-origin count; they remain important regression controls.

The sealed report cases SHA256 is
`782106d3f9c39e3a96f6039657151d4795c17e6be47d06051e3f4fe4d4c85822`;
binary SHA256 is
`3436b48ecf20b756593c9a679e3b1b0e488ee631eaeaf61cc09f9a69705383a8`.
Its entire154-case score is not a ProverQA denominator. Subsequent source trials
must retain their own binary/case identities and must not silently replace these
snapshot counts.

## Existing minimum-example crosswalk

IDs below abbreviate the common `prover-` prefix except reflexive IDs. A pair
means two different texts, not proof of population coverage. Adaptations remain
valid diagnostics of the retained construction, not original-wording observations.

| Semantic family | Existing case suffixes | Independent example accounting and gap |
|---|---|---|
| Named adjective | subject_copula-1/-2 | Two; broader adjective senses not covered |
| Lexical intransitive | unclassified-1/-2 | Two matures instances; does not cover residual lexical frames |
| Negated intransitive | subject_do-1/-2 | Two work instances; lexical/argument variants missing |
| Lexical have + existential object | subject_have-1/-2; transitive-have-1/-2/-3 | Five distinct texts, overlapping one semantic family; not five families |
| Negated transitive + indefinite object | transitive-negative-1/-2/-3 | Three including have; object witness correctly under NOT |
| Negative predicative nominal | transitive-nominal-1/-2/-3 | Three; no identity witness; positive dedicated pair still missing |
| Named initial conditional/pronoun | conditional_initial-2 | One; add at least one other direct case |
| Indefinite initial conditional/shared binder | conditional_initial-1 = nested-binding-1; nested-binding-2 | Two unique texts; duplicate cat row not extra; second simplified from passive |
| Initial conditional explicit XOR consequence | nested-xor-1/-2 | Two named-subject cases; indefinite binding plus XOR still missing |
| Initial conditional declared inclusive consequence | nested-or-1/-2 | Two; one named, one adapted person-restricted nominal antecedent; subtype pair thin |
| Initial conditional overt or both | overt-or-both-1/-2 | Two; true surface either marker does not mean exclusive logic |
| Initial conditional AND antecedent | nested-and-1/-2 | Two; adjective versus nominal/mixed subtype only one each |
| Initial conditional OR antecedent | nested-ante-or-1/-2 | Two adapted AND→OR contrasts; no original-population frequency established |
| Ground either predicate | vp_either_or-1/-2 | Two different subtype cases (mixed noun/adjective versus adjective); convention explicit |
| Initial either with explicit not both | sentence_either_or-1/-2 | Two; both preserve full exclusion |
| Topical universal XOR | for_topic-1/-2 | Two human-restricted cases; not all topical pronoun/hedge patterns |
| Universal nominal + transitive predicate | universal_nominal-1 | One; add second independent transitive case |
| Modified universal nominal + adjective | universal_nominal-2 | One; add second, preserving head/modifier order |
| Everyone + OR, empty diagnostic restriction | quantified_pronoun_or_relative-1/-2 | Two historical controls; no strict-person certification |
| Everyone who restriction | who-restriction-1/-2 | Two strict-person examples, separately versioned from historical everyone |
| Final conditional/pronoun | conditional_final-1/-2 | Two under declared named coreference |
| Episodic singular indefinite subject | existential_nominal-1/-2 | Two; generic-indefinite rules remain a separate unfilled family |
| Named local reflexive | reflexive-named-1/-2 | Two Prover-derived texts, second extracted from conditional scope |
| Universal local reflexive | reflexive-quantified-1/-2 | Two adapted local clauses; original relative/conditional nesting removed |
| Full written titled-name reference | name-title-1/-2 | Two; does not settle abbreviation segmentation or alias semantics |

This table refines outer labels into semantic obligations; its row count is not
a complete semantic-family denominator. Existing labels alone all have2–3 rows,
but universal_nominal and conditional_initial each hide distinct thin subtypes.
Adding easy lexical variants cannot substitute for those missing scope cases.

## Missing inventory scope

[CONSTRUCTIONS](CONSTRUCTIONS.md) fixes the local population at17,345 occurrences
(17,285 distinct surfaces), 1,500 records across easy/medium/hard, including theory
and stripped questions. Its outer counts and overlapping cues are different
quantities. Initial-if5,279 and quantified-pronoun+who959 prioritize nested scope;
not-both4,146, or-both776 and not-necessarily-both145 cannot share one gold policy.

The [residual frame audit](sections/proverqa-frames.md) identifies249 occurrences
in narrow surface patterns;3,542 of the original3,791 remain outside that bounded
audit. Even identified patterns are not yet complete meanings. Missing gold
families include bare abstract objects (values tradition/stability:50 audited
occurrences), manner modification (thinks28, works25, listens12), light verbs27,
PP complements (collaborates21; cares for16/about12; listens to6), locatives15,
aspectual stay11, idioms13, mixed lexical/copular coordination, possessives and
particles. These narrow counts are not full-family frequencies.

Modal auxiliaries, not necessarily both, passive/control/gerund meanings, temporal
and generic force, mass/abstract referents, subsective modification and collective
readings require independent contracts before scored gold. Retain their input
membership as unresolved. A singleton attested particle family cannot supply
2–3 independent observed examples by duplicating it; seek further original inputs
or label additional authored controls as controls. Do not flatten these families
into atoms to fill the denominator.

## Proposed two-part acceptance evidence

**A. Construction acceptance panel.** Freeze semantic-family IDs, joint scopes,
contract IDs and specific member hashes before evaluation. Require2–3 distinct,
independently authored examples per validated family, including scope/status
contrasts. Record family→case mappings and missing/ambiguous families explicitly;
do not declare a closed complete inventory while residuals remain. Deduplicate
identical English for coverage, but retain regression IDs historically. Give
strict-person everyone corrected cases new IDs/version after independent review;
never allow both empty/person restriction merely to match the parser. Follow
[SEMANTIC_CONTRACTS](SEMANTIC_CONTRACTS.md) for domain/either/order policies.

Report each family's outcomes; do not let high-frequency easy atoms mask failures
in rare claim-boundary or scope constructions. This panel tests construction
coverage but its hand-picked overall percentage is not a population estimate.
“Near-zero” needs a recorded numerical policy before the acceptance run; the
reviewed recommendation is zero observed wrong-but-typed in this panel, with
population uncertainty separately reported. This proposal does not retrospectively
invent an owner tolerance or declare current rows passing.

**B. Independent representative audit.** A concrete proposed first draw is50
input occurrences from each of six strata (easy/medium/hard × theory/question),
300 total, sampled uniformly without replacement *within stratum*. This is a
bounded review workload, not a claim that300 guarantees a desired precision.
Prerecord actual N_h values from original input-role manifests, frame hashes,
selection algorithm/seed and all selected locators before parser observation.
Current unique-cache first-role representatives cannot supply correct occurrence
strata by themselves. No draw has been made by this document.

Author gold from the original selected English, with no simplifications, labels
or parser-derived alternatives. Record nested semantic families and ambiguity
independently. Keep already-seen or duplicate texts with disclosed exposure and
sampling multiplicity; their population occurrence weight is legitimate but they
do not become independent semantic evidence. Do not reject/resample a selected
item because it is difficult, failed, ambiguous or lacks a schema contract.
Additional rare-family diagnostics belong in A, not as undisclosed additions to B.

For N=17,345 and stratum size n_h, the design-weighted exact estimate is
`sum_h (N_h / N) * (E_h / n_h)`. Apply the same weights to wrong-but-typed and all
other outcomes; report raw strata counts and appropriate design-based uncertainty.
Do not weight overlapping cue counts or claim simple binomial independence for
repeated items. The representative audit and construction panel are separate
results, never summed into one denominator.

Representation-unresolved selected cases remain in the audit accounting as
unresolved-gold, separate from actual runner no-parse/error statuses. Preserve
any available parser result without inventing a meaning label. For a conservative
certifiable exact lower bound, unresolved cases contribute zero certified exact
mass; report their mass explicitly. Their unknown wrong-but-typed rate must not
be reported zero. Actual no-parse/type/incomplete/instrumentation failures remain
in fixed denominators. A failed transport batch is unusable evidence, not a
smaller successful sample.

Before any gate decision, independent review must establish contract coherence,
coverage of validated construction families, complete missing-case accounting,
valid population weighting and enough evidence for the requested claim. Neither
A≥90% alone nor a favorable B point estimate can hide a systematic wrong meaning
or an omitted family. The coordinator records the >=90%/near-zero decision and
all release gates; this proposal does not itself certify or authorize a restart.
