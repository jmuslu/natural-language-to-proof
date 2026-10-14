# Research findings — working decision document

Status: B/C/F measured; D/E comparisons active, G audits complete except ranking. This is not the final synthesis.
Results are from branch `astra/research`; commands/predictions are in `LOG.md`.

## Meaning and oracle admission

Bounded semantic repairs hold on 29 hand-written tests and the licensed-model
probes: restrictive subject relatives, argument-cluster coordination's selected
meaning, endomorphic feature preservation, named/definite antecedents, normalized
reporting verbs, and factive complements listed only as Presupposed. The full
suite grew from 1,016 to 1,063 checks across nine suites; no existing assertion was
removed to hide a failure. The discourse fixture changed its middle sentence to
preserve its original frontier comparison, while a new check retains the original
Mary example and exposes the restored Ref-only Threading limitation.

Only top-level DRS assertion witnesses may request token-producing confirmation.
Raw conditions, removed promotion functions, altered Fact content and phantom-index
coercion are rejected. This establishes a structural API boundary. It does not
establish source authenticity or correctness of a caller-authored DRS.

A later scope audit found a real counterexample: separately canonicalized true
documents ∃x.P(x) and ∃y.(P(y)→q) can have different witnesses, yet their extracted
conditions both used r0 and mechanical fusion derived false q. The fixed oracle
boundary refuses any condition with free canonical references. Thirty scope
checks and a ten-control finite-model probe pass, including closed quantified
claims and rejection before an oracle predicate is consulted. Contextual claims
remain visible but cannot get confirmation tokens through this bare-condition
interface. Full-box existential reasoning belongs in the scoped solver. This
restriction reduces oracle coverage and is necessary for the current API.

The comma-quotation guard rejects extensional readings of recognized VERB+NP or
NP+VERB suffixes. `The cat is red, boasted Bob` now abstains on the real model;
it does not assert red(cat). Named/definite speakers and ordinary adjective lists
have regressions. Arbitrary quotation punctuation, adverbial tails and dialogue
remain outside this bounded guard.

Some well-typed meanings are still wrong. `Bob likes and Anne hates the cat` has
a correct selected reading and a second reading with intransitive likes(Bob).
`Bob likes the cat and the dog` retains a spurious cat dog alternative. Ranked
selection is a hypothesis; neither typing nor high score proves meaning fidelity.

## POS backoff: measurable gain, incomplete repair

The paired experiment uses the **first 120 OWA depth-5 development theories**:
2,244 theory sentence occurrences (2,124 distinct) and 2,560 questions. This is a
fixed diagnostic prefix, not a representative random sample or a held-out final test.
All conditions use the same items and default search settings.

| Measure | Baseline | Repaired default | Optional POS backoff |
|---|---:|---:|---:|
| Exact theory sentence coverage | 86.7% | 86.7% | 93.0% |
| Exact question coverage | 90.5% | 90.5% | 95.6% |
| Entire theory exact | 32/120 | 32/120 | 65/120 |
| No-root failures, 4,804 occurrences | 524 | 524 | 255 |
| Typed DRSs rejected by reference conversion | 16 | 16 | 16 |
| Converted-but-wrong meanings | 0 | 0 | 0 |

Percentages are the coverage driver's rounded output, not reconstructed exact
numerators. Eight rejected DRSs mix a conditional with a spurious top-level fact;
eight have an incorrect nested-conditional shape. Zero converted-but-wrong outputs
must not be confused with zero wrong well-typed meanings.

The loaded dictionary has adjective evidence for round, but none for kind. The
flag therefore repairs round and leaves kind unsupported. This contradicts the
initial prediction that both words would be repaired. Known NN/NNS/JJ evidence
adds missing noun/adjective categories; it does not infer an unseen word's POS,
contextual word sense or verb valency. Search scores rank these candidates without
conferring evidence strength.

**Current recommendation:** keep `--pos-backoff` opt-in. The gain is useful on this
slice, but evidence does not justify a blanket default or nominal-to-adjective
coercion for kind. Reproduce with `bash research/run-phase-b.sh`; local raw outputs
remain ignored under `research/runs/phase-b/`.

## See-that: retain a logged conservative sense policy

Perceptual see-that is factive; supervisory/ensure readings need not be. A global
lemma-level switch would conflate them. The default remains attributed and logs
`see-sense`, with the factive alternative visible. The original real-model example
failed to parse; the repaired complement-category attestation now parses it as
see(Bob, [red(cat)]) with red(cat) Reported, never asserted.

**Current recommendation:** retain this conservative unresolved default until a
sense distinction is supported by data. This is a limitation in disambiguation,
not a claim that perception is non-factive. Primary sources: [Dietz, §3](https://link.springer.com/article/10.1007/s11098-017-0929-y)
and [Voinov 2013](https://www.cambridge.org/core/journals/language-and-cognition/article/abs/seeing-is-trying-the-relation-of-visual-perception-to-attemptive-modality-in-the-worlds-languages/A0F8846B72AEB95F3A22E02B614CB86B).

## Strength and exact retraction

Production Genealogy and Fusion now implement minimal antichains of evidence sets:
union across alternative proofs, pairwise union along conjunctive proofs, followed
by removal of redundant supersets. Evidence classes stay attached to each path.
An oracle-only path grounds a claim; a remaining report, presupposition or translated
path stays weak. A bare `Verdict.Confirmed` cannot create such a path: an actual
confirmation capability is required. Graph derivations assume valid supplied rules;
they do not themselves mint oracle tokens or establish source authenticity.

The 53-check production suite covers all 20 antichains over three evidence tokens,
8,000 triples per ternary law, 32,768 cyclic-graph valuations and 32,768 withdrawal
configurations. All pass, as do the original 114 substrate checks. The five reproduced
old support-query regressions are fixed. Optimized property runtime was 6.62 seconds,
21,760 KiB maximum RSS. Independent binary alternatives produce exactly 1,024 minimal
environments at ten pairs: exact provenance can grow exponentially and has no hidden
cap. See `STRENGTH.md` for proof sketches, alternatives rejected and API limits.

Fusion now preserves per-claim oracle alternatives and refuses to flatten existential
consequents during mechanical detachment. It remains intentionally weaker than a full
FOL solver. Source-dependent rules must be represented as evidence dependencies in the
graph; a free-text rule name alone does not capture a source dependency.

## Restored modules: keep diagnostic-only

On ten hand-authored discourse cases (27 sentences, all parsed), flat resolution
resolved 10/12 pronouns; the two intended scope barriers stayed unresolved.
Committed Threading resolved 3/12 and Permissive 5/12, with no gains over flat.
Both lose named/definite candidates; later antecedents can fall off the modeled
frontier. The modifier/scope generator also has an object/subject inconsistency:
a three-modifier stack produced four object candidates but only one subject
candidate, and unknown fake defaults to Intersective. Merely wiring these modules
would not repair those meanings. Details and reproducible drivers: `RESTORED.md`.

**Recommendation:** do not wire either restored subsystem into the default Pipeline.
Keep the small diagnostic modules while these concrete defects remain visible;
probabilistic ranking and solver reading-policy measurements are still pending.

## Solver measurements and remaining decisions

The optional research backends use signed Horn closure and Z34.15.3.0 scoped FOL.
Both distinguish failed inference from logical Unknown, preserve residual scopes,
and label every proof as conditional on asserted-unconfirmed premises. An explicit
ProofWriter-only adapter removes narrowly localized person/thing antecedent guards;
it strengthens the rule under the benchmark's unsorted-domain convention and is
not a general meaning-preserving rewrite. Unknown abstains on binary ProntoQA.

The first12 ProverQA operational pilot has0/12 answers under both backends and all
three reading policies; this is not the final120-item estimate. Horn top has six
unsupported queries and six incomplete queries; Z3 has six partial theories and
six incomplete queries. Non-top aggregation has nine combination-cap abstentions
and three disagreements. A proof checker cannot repair these upstream failures.

Two independent audit failures are fixed: malformed non-object DRS conditions no
longer crash either backend, and Horn checks its cooperative resource budget inside
joins and support minimization. The regression that previously took0.983s with a
10ms budget now passes a generous250ms scheduler allowance. Budget exhaustion
abstains without emitting partial support as if it were complete.

## Raw-model controls and generated guarantees

The owner corrected the initial provider/quota assumption. Primary weak-model C/D
conditions now use gemini-3.1-flash-lite budget0 and gemma-4-26b-a4b-it minimal,
paired against their own saved raw baselines and GPT-5.5 high. Those graph runs
are pending. GPT-5.5 low/high is only an effort comparison and cannot test the
weak-versus-strong model claim.

Low/high below refer to reasoning effort on the same gpt-5.5 model, not different
model sizes. Fresh ProverQA low scores90/120 (75.0%, Wilson95%66.6–81.9); contemporaneous
high scores89/120. Their paired discordances are low-only4/high-only3, exact
McNemar p=1.0. The historical high run scored90/120 with a different CLI prompt
overhead, so the contemporaneous comparison is the primary effort control.

Fresh FOLIO low scores92/120 versus historical high99/120 (low-only1/high-only8,
p=.0391); fresh ProntoQA low116/120 versus historical high120/120 (0/4,p=.125).
These historical comparisons are descriptive, with possible invocation drift and
FOLIO label noise. Condition C/D comparisons and complete cost tables are pending.

The source-withdrawal benchmark has64 deterministic authored cases in eight
families. Production Genealogy gets64/64 labels and64/64 exact, class-correlated
source support records. Raw low-effort answering gets63/64 labels, strict=lenient,
with one factive Conflict→WeakOnly error. Thus this small designed suite does not
show a broad raw-model accuracy deficit. It does show an executable support and
withdrawal specification: cycles, alternatives, conjunctions, source-dependent
rules, reports, presuppositions and translations have checked behavior.

This graph comparison uses authored structured admissions; it does not measure
English parsing. The cases are not independent population draws. Raw input tokens
total925514 (876544 cached), output3360 (2901 reasoning), all64 calls first-attempt,
no errors or tools. The original graph subprocess evaluation took0.071s. The five
benchmark tests pass against the registered production executable.

Fallback comparisons, final risk–coverage figures, merge guide and next three
priorities remain pending D/E completion. Source and typing guarantees must not
be read as an English meaning guarantee: ProverQA's first graph prompt already
contains noun-coerced names and wrongly composed phrasal/reflexive expressions.
