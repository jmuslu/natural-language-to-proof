# Research log (append only)

## 2026-10-13 — A0: orientation and baseline prediction

Read ASTRA_GOAL.md fully, then STUDY_PLAN.md, README.md, bench/README.md,
bench/proofwriter/README.md, Pipeline.hs, CCGSemParse.hs, CCGSem.hs,
Intensional.hs, DRT/{Build,Canonical,Types}.hs, Verify/{Reported,ClaimKind,Oracle}.hs,
Genealogy.hs, Fusion.hs, Provenance.hs, and tools/Explain.hs in that order.
Starting head: `4843c52`; clean `astra/research`; no AGENTS.md in repo or ancestors.
Only explicit file staging and origin astra/research pushes will be used.

Prediction (before execution): all existing gates pass. Known deviations reproduce:
composition drops [dcl]; punctuation attaches low; argument-cluster coordination and
relative clauses fail; round/kind lack predicative readings; cross-sentence it remains
unresolved; factives list complements twice; added stays unstemmed; NP coordination
has a second spurious reading. The extra boast quotation admits an unsafe assertion;
see-that remains reported. This shows passing current tests is necessary but insufficient.

Exact command: `bash research/run-phase-a.sh`.
Results: pending. Outputs: research/runs/phase-a/ (ignored; no corpus dumps committed).
Interpretation: pending. Commit: Phase A checkpoint pending.

## 2026-10-13 — A1: static audit (not an experiment)

The existing graph computes Boolean least-fixed-point groundedness and exact node-verdict
retraction. Source lineage alone does not retain alternative minimal supports. Static
inspection also found rrSurvived includes never-grounded downstream nodes and
survivesRetractionOf can report survival for an absent node; test these in Phase C.

Oracle admission has three further paths to audit beside bare CanonCond: exported
assertedClaim, exported asCandidate, and an inferred phantom role on Claim. Planned
repair: nominal role, structural root witnesses from a whole DRS, and typed witnesses
retained in Fact. Bare oracle check remains hypothesis inspection without a confirmation
token. A structural witness cannot authenticate a caller-built DRS; state this limit.

No experiment was run for these findings; implementation and regression results pending.
Commit: Phase A checkpoint pending.

## 2026-10-13 — A2: benchmark hygiene audit (read only)

The saved GPT-5.5/high runs contain 120 successful, unique matching sample IDs in each
benchmark: ProofWriter 120 correct, ProntoQA 120, FOLIO 99, ProverQA 90. The only saved
low-effort GPT baseline is ProofWriter (119/120). These are inventory results, not
new model trials. Future conditions must preserve item pairing and report CLI prompt
overhead in costs. ProverQA sample rows contain conclusion_fol as well as labels;
inference/prompt input MUST whitelist id/context/statement (ProofWriter uses its
corresponding text fields). Gold logic is evaluation-only and cannot substitute for
parser output. A DRS containing UNSUPPORTED placeholders is not a complete theory.
All-readings results are bounded by the parser search beam, never exhaustive English.
Commit: Phase A checkpoint pending.

## 2026-10-13 — A0 gate results

`cabal build all`, `cabal test all`, `bash scripts/check-oracle-boundary.sh`,
and `bash scripts/check-explain.sh` all passed at source head 4843c52. Counts:
core 386, substrate 114, CCGbank 116, CCG semantics 75, external receipts 44,
readings/discourse 130, intensional 94, assertion 57: 1,016 total. Oracle boundary:
12 negative and 2 positive cases. Explain: 3 hand and 5 real CCGbank cases.
Prediction held for gates. Full deviation batch is still running from the already
built executable. The first checkpoint changes research documentation/ignores only.
Commit: `research: record orientation and passing baseline gates`.

## 2026-10-14 UTC / 2026-10-13 New York — B7/B5 regression prediction

Prediction (before execution): six deliberately invalid admission clients compile
against the baseline: bare CanonCond confirmation, extraction from Embedded,
Data.Coerce reindexing, assertedClaim wrapping, asCandidate escalation, and Fact
content record mutation. Three added factive tests should fail: a matrix factive
must not also Report its complement, and a factive under a report must preserve
exactly its outer-source attribution without duplicate inner-factive reporting.
Commands: `bash research/runs/oracle-repair/red.sh` (isolated GHC outputs), and
`runghc -isrc -itest test/IntensionalSpec.hs > research/runs/oracle-repair/factive-red.log 2>&1`.
These are regression probes, not licensed-data experiments. Results pending.
Commit: pending Phase B oracle/claim repair.

## 2026-10-13 — B1: bindable named antecedents, prediction

The Phase A executable is still finishing its independent corpus batch. With all
baseline gates passed and checkpoint e5af86d pushed, prepare disjoint Phase B
regressions in parallel. No cabal rebuild will replace the baseline executable.

Prediction: `runghc -isrc -itest test/CCGSemSpec.hs > research/runs/b1-pronouns-red.log 2>&1`
will fail the new cross-sentence definite/name tests and pass existing 75 checks.
Top-level direct entity arguments should become discourse binding candidates without
adding existential variables or changing claim identity. Constants inside reports,
negation, conditionals, disjunction or presupposition remain inaccessible. Recency
uses lexical spans and duplicate names collapse; every choice logs alternatives.
Local donkey binding retains its existing rule; this repair targets cross-sentence
resolution. SDRT has a Ref-only ranking and will require an explicit Phase G decision.
Result: pending. Commit: Phase B semantic repair pending.

## 2026-10-13 — B-semantics red prediction

Prediction before execution: the new hand-authored semantic-repair suite fails for
restrictive relatives, automatic argument-cluster raising, exact feature retention,
past-tense report lemmas, see-sense logging and the inverted quotation safety guard.
Existing type/ordinary coordination/default-backoff checks should remain green.
Exact command: `runghc -isrc -itest test/SemanticRepairSpec.hs > research/runs/phase-b/semantics-red.log 2>&1`.
Result: pending. Commit: pending Phase B semantics checkpoint.

## 2026-10-13 — C0: independent strength-algebra prototype prediction

Phase C algebra design proceeds while Phase B source repairs are prepared; it touches
only this log, STRENGTH.md, and ignored scratch files. This is an independent prerequisite,
not a switch away from the ordered Phase B work. No production API is changed.

Prediction, before execution: normalized finite antichains of evidence-token sets form
an absorptive commutative idempotent semiring (PosBool in minimal DNF). All 20 labels
over three tokens satisfy all laws across 8,000 triples. Filtering environments that
use revoked tokens commutes with both semiring operations, and graph label closure
agrees with Boolean closure under every valuation on all three-node unary graphs.
A separate strongest-class/source-label pair loses correlation after oracle-source
retraction, whereas token-labelled alternatives retain the surviving report's class.
Boolean and Viterbi scalars cannot encode source identity, although their full graphs
can support correct recomputation. This is an information comparison, not a claim
that numerical semirings are algebraically invalid.

Exact commands (repo root):
`runghc -iresearch/runs/strength-design research/runs/strength-design/StrengthPrototypeSpec.hs > research/runs/strength-design/prototype.log 2>&1`
`runghc -isrc research/runs/strength-design/GenealogyRegressionSpec.hs > research/runs/strength-design/genealogy-red.log 2>&1`

Prediction for the second command: all five intended-behavior regressions fail against
the current Genealogy API: absent-node survival, never-grounded survival, survivor
reporting, unconfirmed independence, and nested-alternative independence. These red
tests are saved for migration, not installed as failing release gates.
Results and interpretation: pending. Commit: future Phase C implementation checkpoint.

B7/B5 red result: all six admission clients compiled, reproducing all predicted
holes (including Data.Coerce with the constructor hidden). IntensionalSpec passed
94/97, with exactly the three new factive checks failing. The nested factive
incorrectly reported red(cat) through both [say(Alice), know(Bob)] and [say(Alice)].
Prediction held. Fix underway; full logs are in research/runs/oracle-repair/.

## 2026-10-13 — A0 deviation results and Phase A completion

`bash research/run-phase-a.sh` exited 0. Every Known deviations row reproduced:
< Bx (without the space) loses [dcl]; punctuation attaches to red; non-constituent
coordination, round/kind and relative clause fail at parsing; the two-sentence
pronoun yields big(?it_0); know duplicates red(cat) as Reported and Presupposed;
added stays added; NP coordination has two meanings, the second containing
like(Bob, cat dog). The boast quote dangerously asserts BOTH red(cat) and
boasted(cat, Bob). The prediction for see-that did NOT hold: the real-corpus
`Bob sees that the cat is red.` fails parsing rather than returning Reported.
This is a lexical/parse coverage issue as well as a lexical-class decision.
Corpus load: 39,604 trees / 44,210 forms, 81.1s. Full hand-written probes and
explain output remain in the ignored phase-a run directory.

## 2026-10-13 — B1 red result and implementation prediction

Pronoun regression run exited 1: 81/87 passed, exactly six new named/definite
binding failures; all previous 75 checks and all six conservative accessibility
checks passed. Prediction held. Implement general DTerm antecedents, without
changing DRS logical content or local donkey resolution. Prediction: rerunning
`runghc -isrc -itest test/CCGSemSpec.hs > research/runs/b1-pronouns-green.log 2>&1`
will pass 87/87; `runghc -isrc -itest test/ReadingsDiscourseSpec.hs >
research/runs/b1-threading.log 2>&1` will retain 130/130 after adapter migration.
Commit: Phase B semantic repair pending.

C0 initial execution result: the Genealogy command exited 1 with exactly 0/5 passing;
all five intended bugs reproduced as predicted. The algebra command exited 1 before
executing checks because scratch test constants zero/one lacked an Int type annotation.
This is a test-harness compile error, not an algebra counterexample. Added the explicit
`Support Int` annotation; production code remains untouched.

Prediction before rerun: all 27 algebra/fixture/graph checks pass unchanged.
Exact command: `runghc -iresearch/runs/strength-design research/runs/strength-design/StrengthPrototypeSpec.hs > research/runs/strength-design/prototype.log 2>&1`.
Result: pending. Commit: future Phase C implementation checkpoint.

## 2026-10-14 UTC / 2026-10-13 New York — B7/B5 repair verification prediction

Prediction: all six invalid clients now fail for their intended admission reason;
old boundary positives/negatives still behave as before; four impacted suites pass
with counts substrate 114, external 44, assertion 57, intensional 97. Matrix
factive content is Presupposed only; nested factive content remains attributed once
to the enclosing report. Bare `check` still inspects hypotheses without producing
confirmation tokens. Shared semantic edits may require fixture lemma updates.
Commands: `bash research/runs/oracle-repair/green.sh`;
`NL2PROOF_BUILD="$PWD/research/runs/oracle-repair/legacy-gate" bash scripts/check-oracle-boundary.sh > research/runs/oracle-repair/legacy-gate.log 2>&1`;
`runghc -isrc -itest test/SubstrateSpec.hs > research/runs/oracle-repair/substrate-green.log 2>&1`;
`runghc -isrc -itest test/ExternalSpec.hs > research/runs/oracle-repair/external-green.log 2>&1`;
`runghc -isrc -itest test/AssertionSpec.hs > research/runs/oracle-repair/assertion-green.log 2>&1`;
`runghc -isrc -itest test/IntensionalSpec.hs > research/runs/oracle-repair/intensional-green.log 2>&1`.
Results pending. Commit: pending Phase B repair.

## 2026-10-13 — B8: ProofWriter backoff baseline prediction

Prediction: the unchanged baseline will interpret roughly 80–90% of sentences
exactly on the first 120 OWA-d5 dev theories, with round/kind accounting for most
lexical failures and few (<1%) converted-but-wrong meanings. This is a fixed prefix
diagnostic sample, not a representative accuracy estimate. Include questions.
Use the binary already built at 4843c52; copy it before concurrent source repair
rebuilds so the baseline is immutable. Exact commands:
`cp "$(cabal list-bin proofwriter-coverage)" research/runs/phase-a/proofwriter-baseline`
`PROOFWRITER_DIR=/home/gram/data/proofwriter research/runs/phase-a/proofwriter-baseline --owa --split dev --limit 120 --questions --examples 0 --check-context 0 +RTS -N2 -RTS > research/runs/b8-baseline.log 2>&1`
Before/after flag comparison will use exactly this same fixed slice and parameters.
Result: pending. Commit: Phase B coverage evaluation pending.

B-semantics red result: 4/18 passed, 14 failed exactly in predicted repair areas.
The handcrafted unsafe quote returned a well-typed asserted reading, validating that
this is a semantic safety test rather than mere missing-tag coverage. Real baseline
also asserts red(cat) and boasted(cat,Bob) via comma VP coordination. The real sees-that
sentence fails because its explicit-that category is pruned by the tagger; study-plan
reported output was stale. No production source changed before this red run.

B7 first verification: substrate 114/114 and external receipts 44/44 passed.
The new negative-case runner stopped at ExtractedEmbeddedConfirm because GHC
qualified CanonCond with its module in the diagnostic. Rejection itself was
correct; fix the scratch diagnostic matcher to allow qualification and rerun
`bash research/runs/oracle-repair/green.sh`. Prediction: all six reject for the
intended reason. This changes no release gate.

B7/B5 verification result: six new invalid clients all rejected for the intended
reason. The existing boundary gate remained green (12 negative + 2 positive).
Substrate 114/114, external 44/44 and assertion 57/57 passed. All three new factive
checks passed. Intensional remained 94/97 because concurrent repairs changed two
lemma expectations (noted -> note; fixtures now migrated) and made the existing
report-box anaphora barrier test unexpectedly resolve `it` in "Bob said that a cat
is red. Alice likes it." The latter was reported to the pronoun repair owner,
not weakened or deleted. Final integrated rerun pending that fix.

C0 final result: rerun exited 0, 27/27 checks passed. All 20 normalized labels over
three tokens passed ternary laws across 8,000 triples, binary laws across 400 pairs,
and Boolean/retraction homomorphism checks across 3,200 pair/valuation combinations.
All 32,768 graph/seed/valuation configurations matched Boolean closure; all 32,768
withdrawal configurations matched recomputation; 4,096 graph/seed configurations were
insertion-order independent. The oracle/report retraction correlation fixture behaved
as predicted. Genealogy's separate intended-red command remained 0/5.

Interpretation: the finite support algebra works as specified; it does not establish
parser faithfulness or soundness of arbitrary graph justifications. Tests cover all
small unary graphs plus one conjunctive fixture, not all possible hypergraphs. These
results are recorded in STRENGTH.md; production migration is still pending.
Commit: future Phase C implementation checkpoint.

## 2026-10-13 — C1: multiplicity boundary prediction

A review of the candidate comparison found a qualification worth testing explicitly:
there is no general Viterbi-semiring homomorphism from this absorptive label algebra.
It deliberately identifies repeated uses of one token, while numerical multiplication
does not. Prediction: report*report remains the same antichain, but a stipulated
Viterbi weight 3/10 becomes 9/100 when multiplied by itself. Source withdrawal removes
the whole support in both cases. Existing C0 mixed oracle/report fixtures do not
exercise repeated factors and remain valid; their per-environment weight evaluation
must not be advertised as a general Viterbi projection.
Exact command: `runghc -iresearch/runs/strength-design research/runs/strength-design/CandidateComparisonSpec.hs > research/runs/strength-design/candidate-comparison.log 2>&1`.
Result: pending. Commit: future Phase C implementation checkpoint.

## 2026-10-13 — B-semantics first repair / POS red prediction

Prediction before execution: repaired relative, coordination, feature, lemma, quote and
see-decision tests pass; exactly the two newly added POS-backoff behavior checks fail
because the new flag is currently inert. Safe quote readings should survive the guard.
Exact command: `runghc -isrc -itest test/SemanticRepairSpec.hs > research/runs/phase-b/semantics-pos-red.log 2>&1`.
Result: pending. Commit: pending.

C1 result: exited 0, 3/3 checks passed. Repeated report evidence remains one antichain
atom, direct Viterbi multiplication is 9/100, and withdrawal removes the support.
Prediction held. STRENGTH.md explicitly excludes a general Viterbi homomorphism and
records that C0's edge-order test compares original with reversed order, alongside
the algebraic order-independence argument. No production files changed.
Commit: future Phase C implementation checkpoint.

B-semantics first repair result: 21/24 checks passed. The two POS checks failed as
predicted. One additional failure was an equivalent conjunction association in the
existential-relative expected term; the harness now compares canonicalAC, matching
the parser's documented associativity/commutativity normalization. No semantic fix
was needed for that third case. Enabled the already-red-tested POS branch afterward.

## 2026-10-13 — B-semantics local green prediction

Prediction before execution: all 24 semantic-repair checks now pass. POS backoff adds
only missing N/N, N, or predicative-adjective categories with dictionary POS support,
below existing tag scores, and logs use. It remains off by default.
Exact command: `runghc -isrc -itest test/SemanticRepairSpec.hs > research/runs/phase-b/semantics-green.log 2>&1`.
Result: pending. Commit: pending.

## 2026-10-13 — B1 integration findings and revised prediction

The named-antecedent implementation passed 87/87 CCG semantics checks, but the
130-check discourse suite returned 128/130. Its frontier fixture used Mary as a
neutral middle sentence precisely because names were previously unbindable. Mary
is now a legitimate, more recent antecedent; that test assumption is obsolete.
Retain all frontier assertions using a universal middle sentence (no accessible
individual), and add an explicit check on the original Mary discourse demonstrating
the current Ref-only SDRT limitation. This is a fixture correction, not deletion
of a failing assertion.

The intensional suite also caught `it` incorrectly resolving to the preceding
report's holder Bob after report-internal cat was correctly excluded. Add a
conservative compatibility heuristic: `it` excludes attitude holders (personal
participants); `they` can still refer to them. This is a logged antecedent
selection heuristic, not a proof of animacy, and names elsewhere have no inferred
agreement features.

Prediction before rerun: existing accessibility regression is restored, all new
named bindings hold, and explicit original-Mary comparison records divergence.
Commands: `runghc -isrc -itest test/CCGSemSpec.hs > research/runs/b1-pronouns-final.log 2>&1`;
`runghc -isrc -itest test/ReadingsDiscourseSpec.hs > research/runs/b1-threading-final.log 2>&1`;
`runghc -isrc -itest test/IntensionalSpec.hs > research/runs/b1-intensional-final.log 2>&1`.
Commit: Phase B repair pending.

B-semantics local green result: all 24 checks passed. The quote test confirms both
unsafe-reading rejection and retention of a supported whole-root attribution.

## 2026-10-13 — B-semantics real-model integration prediction

Prediction before execution: all seven optional corpus checks pass: relative restriction,
nonconstituent coordination, inverted quote fail-closed behavior, sees-that attribution
and sense logging, added→add, and optional round/kind backoff. This is stronger than
handcrafted lexical tests because corpus seen-pair and learned-raising constraints apply.
Exact command: `runghc -isrc -itest test/SemanticRepairSpec.hs --corpus > research/runs/phase-b/semantics-corpus.log 2>&1`.
Result: pending. Commit: pending.

## 2026-10-13 — B-semantics restrictive/nonrestrictive boundary prediction

Prediction before execution: 25/26 local checks pass, and the new nonrestrictive-comma
regression fails. Punctuation absorption currently lets the new restrictive entry
silently reinterpret `Every cat, which is red, is big`; this must abstain until a
separate nonrestrictive semantics exists. Negated restrictive relative should pass.
Exact command: `runghc -isrc -itest test/SemanticRepairSpec.hs > research/runs/phase-b/semantics-relative-red.log 2>&1`.
Result: pending. Commit: pending.

## 2026-10-14 UTC / 2026-10-13 New York — B independent meaning-safety audit prediction

Prediction (before run): the new restrictive relative implementation also accepts
comma-marked nonrestrictive relatives because punctuation can be dropped, yielding
cat-and-red -> big for "Every cat, which is red, is big." despite nonrestrictives
being declared unsupported. A second targeted structural probe predicts neuter
`it` can resolve to the addressee Alice in tell(Bob,Alice,K), since only the first
attitude argument is excluded; no content inside K should escape. This may be
an additional heuristic limitation, not an oracle-token bypass.
Command: `runghc -isrc -itest research/runs/audit/MeaningSafety.hs > research/runs/audit/meaning-safety.log 2>&1`.
The probe uses only miniature hand-authored fixtures. Results pending.

## 2026-10-13 — B1 integrated result; B8 baseline result

B1 reruns passed: CCG semantics 87/87, readings/discourse 131/131 (one additional
explicit limitation check), intensional 97/97. No original test assertion was
deleted. The modified frontier fixture replaces a formerly unbindable named
individual with a universal; the original Mary example is now separately tested.

B8 immutable baseline completed on 120 OWA dev theories: 2,244 theory-sentence
occurrences (2,124 distinct), 2,560 questions. Theory sentence exact 86.7%, fact
exact 89.7%, rule exact 82.8%, question exact 90.5%, whole theory exact 32/120
(26.7%). Across theory+question occurrences: 524 no-root failures and 16 DRS
conversion failures; zero converted-but-wrong outputs. The lexical blockers were
round and kind as predicted. Excluding their sentences, exact interpretation was
99.7%; 31/34 blocker-free theories exact. These are diagnostic-prefix results,
not end-to-end question-answering results.

Prediction: adding the POS backoff will improve exact coverage substantially;
the unflagged repaired parser should remain near this baseline. New unknown
syntactic categories must never count as evidence or confer oracle confirmation.
Commands will be logged before post-repair comparison execution.
Commit: Phase B repair/evaluation pending.

The optional corpus suite and nonrestrictive red run both stopped at a Haskell test
syntax error (one extra closing parenthesis in each optional lemma/sense assertion).
No behavior was measured. Corrected those test expressions. Prediction unchanged:
local 25/26 with the nonrestrictive case red; corpus 7/7.
Exact rerun commands:
`runghc -isrc -itest test/SemanticRepairSpec.hs > research/runs/phase-b/semantics-relative-red.log 2>&1`
`runghc -isrc -itest test/SemanticRepairSpec.hs --corpus > research/runs/phase-b/semantics-corpus.log 2>&1`.

Independent audit result: both predictions held. Both punctuated and unpunctuated
relative sentences produced `forall x. cat(x) & red(x) -> big(x)`. The punctuation
case is a silent restrictive reading of a declared-unsupported nonrestrictive.
The discourse probe asserted big(Alice), with a Decision choosing Alice over Bob
and no diagnostic. Suggested minimal fixes were sent to owners: abstain on
comma-marked relatives, and include tell's addressee in the personal participant
exclusion for neuter it. No audit source edits were made.
Commit: pending owners' fixes and integrated gates.

## 2026-10-13 — B1 addressee audit prediction

Independent audit reproduced a gap in the new compatibility heuristic: tell's
addressee Alice remained eligible for it although its holder Bob was excluded.
Extend the same personal-participant rule to every attitude argument, and add
regressions that it stays unresolved while they can still select the addressee.
Prediction: `runghc -isrc -itest test/CCGSemSpec.hs > research/runs/b1-participants.log 2>&1`
passes 89/89. This extends a conservative pronoun heuristic, not logical facts.
Commit: Phase B repair pending.

B-semantics restrictive/nonrestrictive red result: 25/26 passed; the new comma
regression alone failed, as predicted. Added a sentence-level rejection with a
relative-safety Decision for comma-followed that/which/who. Restrictive entries never
license supplementary content; currently the whole unsupported sentence abstains.

## 2026-10-13 — B-semantics boundary green prediction

Prediction before execution: all 26 local semantic checks pass, including the new
nonrestrictive boundary, while ordinary/negated restrictive clauses remain supported.
Exact command: `runghc -isrc -itest test/SemanticRepairSpec.hs > research/runs/phase-b/semantics-green.log 2>&1`.
Result: pending. Commit: pending.

## 2026-10-13 — B integrated gate prediction

After failing-first fixes for all nine items (including conservative alternatives
for open decisions), prediction: `bash research/run-gates.sh phase-b-gates` passes
all suites without reducing any existing count, plus 26 semantic repair checks;
the explain gate preserves invariants 3 and 4. Compilation may reveal consumers
of the typed assertion API not covered by targeted runghc suites. All participants
have been asked to freeze production changes during the build.
Result: pending. Commit: Phase B checkpoint pending.

## 2026-10-13 — B-semantics literature decision (read only)

Perceptual `see that P` is factive; treating every occurrence of lemma see as factive
is not warranted by a category that also admits supervisory/ensure readings. Current
recommendation: retain attribution until sense is identified, log `see-sense`, and
never assert its complement. This is a conservative representation policy, not the
claim that perceptual see is linguistically non-factive. The model also needed the
lemma-attested explicit-that tag restored after the inflection-specific beam pruned it.

Primary sources checked:
- Kiparsky & Kiparsky (1970), *Fact*, §§2 and 5: assertion differs from presupposition;
  some predicates allow both factive and non-factive constructions.
  https://rotom.github.io/files/kiparskykiparsky70.pdf
- Christina H. Dietz (online 2017; 2018 volume), *Reasons and factive emotions*, §3,
  explicitly treats perceptual seeing-that as factive and knowledge-entailing.
  https://link.springer.com/article/10.1007/s11098-017-0929-y
- Vitaly Voinov (2013), *Seeing is trying*, Language and Cognition 5(1):61–80,
  distinguishes supervisory `See that you do this today` from other see constructions.
  Publisher: https://www.cambridge.org/core/journals/language-and-cognition/article/abs/seeing-is-trying-the-relation-of-visual-perception-to-attemptive-modality-in-the-worlds-languages/A0F8846B72AEB95F3A22E02B614CB86B
  Full text passage verified in the author's indexed upload:
  https://www.researchgate.net/publication/263734373_%27Seeing%27_is_%27trying%27_The_relation_of_visual_perception_to_attemptive_modality_in_the_world%27s_languages

B-semantics boundary green result: all 26 local checks passed.

## 2026-10-13 — B-quote determiner-suffix adversarial prediction

Prediction before execution: the current inverted-proper-name guard rejects the Bob
quote but leaks a conjunction for `The cat is red, boasted the dog.` because the suffix
NP is definite rather than a name. A normal comma adjective list remains supported.
Forward-order suffixes are checked with an additional intransitive boasted fixture;
without reporting evidence they are ambiguous with independent clause coordination.
Exact command:
`ghc -ignore-dot-ghci -isrc -itest test/SemanticRepairSpec.hs -e 'let tm = smTags mini; m = mini {smTags = tm {tmWord = M.insertWith (++) "boasted" [(cc "S[dcl]\\NP",1)] (tmWord tm)}} in mapM_ (\s -> putStrLn (s ++ " => " ++ maybe "NO PARSE" pretty (srForm (run m s)))) ["The cat is red, boasted Bob.","The cat is red, boasted the dog.","The cat is red, Bob boasted.","The cat is red, the dog boasted.","The cat is red, big."]' > research/runs/phase-b/quote-suffix-probe.log 2>&1`.
Result: pending. Commit: pending.

## 2026-10-14 UTC / 2026-10-13 New York — E/A-low operational pilot (parallel preparation)

Justification for phase ordering: existing raw-text condition A is independent of
Phase B repairs. Preparing missing low-effort baselines while B gates run reduces
idle time without using changed parser output or making a thesis claim.

Input-boundary inspection: bench/{proverqa,folio,prontoqa}/spec.py prompt_body reads
only `context` and `statement`; common/spec.py adds fixed task instructions.
Labels, conclusion_fol, premises_fol and explanations never enter model input.
common/run_codex.py is unchanged and uses a fresh empty directory, ephemeral,
read-only sandbox, no-tools task prompt. No Gemini credentials are accessed.

Prediction: the first ProverQA item returns one valid label, with usage metadata
and zero tool items; this tests availability, not accuracy. All three missing
low-effort result files currently have zero successful IDs. Command:
`python3 bench/common/run_codex.py proverqa gpt-5.5 low 1 1 > research/runs/phase-e-baselines/proverqa-pilot.log 2>&1`.
Result pending. Same model, different effort: this is not a model-size comparison.
Commit: summary pending completion.

B-quote suffix probe result: proper-name inversion safely abstained; definite-NP
inversion and both forward-order suffixes leaked an asserted red(cat) conjunction.
Ordinary comma adjective coordination remained correct. Prediction held. These
suffixes will all be treated as quote-shaped; the deliberately conservative cost is
abstention on ambiguous independent comma clauses that match NP+VERB.

## 2026-10-13 — B-quote suffix regression prediction

Prediction before execution: 27/29 local checks pass. The two new aggregate quote
checks fail (definite inversion; named/definite forward suffix), reproducing the probe.
Exact command: `runghc -isrc -itest test/SemanticRepairSpec.hs > research/runs/phase-b/semantics-quote-red.log 2>&1`.
Result: pending. Commit: pending.

B-semantics optional corpus run was stopped after about 190 seconds of interpreted
model loading with no check output. No integration result is claimed. Parent will
batch corpus verification with optimized post-build Explain/coverage executables;
this avoids a redundant slow corpus load during integrated gates.

E/A-low pilot result: ProverQA-hard-245 returned False (strict valid), matching its
label, in 9.24 seconds on first attempt, zero tool items. Usage: 14,494 input,
1,408 cached input, 159 output including 152 reasoning tokens. Prediction held.
This single item is operational evidence only.

## 2026-10-14 UTC / 2026-10-13 New York — E/A-low ProverQA full sample prediction

Prediction: low effort on the existing 120-item ProverQA-hard sample will have
lower or equal strict accuracy than the saved high-effort 90/120, with most errors
on provable items answered Uncertain. Expect valid labels and zero tool activity.
Command: `python3 research/runs/phase-e-baselines/run_guarded.py proverqa > research/runs/phase-e-baselines/proverqa-full.log 2>&1`.
The guard launches the unchanged command
`python3 bench/common/run_codex.py proverqa gpt-5.5 low 120 2`, resuming successful
IDs (including the pilot), and stops its own process group promptly upon any new
error row or tool use. It does not change the child model, tools or sandbox policy.
On a usage limit, inspect only returned error metadata and wait for its reset.
Results pending; no empirical comparison claim until paired analysis.

B-quote suffix regression red result: 27/29 passed; both new quote regressions failed
as predicted. Extended the guard using the already-built category chart: the suffix
must be VERB+NP or NP+VERB, with verb POS and a chart-licensed NP beginning with a
name/determiner/pronoun. Only whole-root attributed meanings survive. This bounded
recognizer does not claim to cover arbitrary speech reports or quotation syntax.

## 2026-10-13 — B-quote suffix green prediction

Prediction before execution: all 29 local checks pass after the guard extension,
including safe attributed quotations and ordinary comma adjective coordination.
Exact command: `runghc -isrc -itest test/SemanticRepairSpec.hs > research/runs/phase-b/semantics-green.log 2>&1`.
Result: pending. Commit: pending.

B-quote suffix green result: all 29 semantic-repair checks passed. Targeted source
whitespace check also passed. Parent owns full cabal/compile-fail/explain gates and
real-model coverage comparison before commit. No commit or push by semantic agent.

Implementation limits for synthesis: restrictive subject relatives only (object-gap
and comma-marked supplementary clauses abstain); global type raising remains off but
transitive-verb/coordinator/new-NP clusters enable learned raising; morphology is a
finite conservative lexical normalization, not a complete English lemmatizer; POS
backoff relies on dictionary NN/NNS/JJ evidence and cannot infer truly unseen-word POS
or verb valency; quotation safety covers detected comma VERB+NP / NP+VERB suffixes,
not arbitrary quotation punctuation, addressees, adverbial tails, or dialogue context.
A successful parse/typecheck outside those bounded constructions remains a semantic
hypothesis, not proof that English was translated faithfully.

## 2026-10-13 — B integrated final repair gates prediction

The earlier integrated gates passed, but the quote-suffix guard was extended
after its build. Prediction: the final integrated source passes all nine suites,
the original oracle gate and Explain gate. Exact command:
`bash research/run-gates.sh phase-b-final-gates > research/runs/phase-b-final-gates-driver.log 2>&1`.
Raw new benchmark result directories are now ignored to prevent accidental bulk
data commits; tracked saved baselines remain tracked. Commit: pending.

## 2026-10-13 — D solver environment prediction

Prediction: an isolated Python environment can install pinned z3-solver 4.15.3.0
without modifying system packages. This is preparation independent of B gates.
Exact command: `python3 -m venv research/.venv && research/.venv/bin/pip install z3-solver==4.15.3.0`.
No benchmark results are implied by successful installation. Commit: pending.

## 2026-10-13 — B real-corpus verification prediction

Prediction: the seven optional corpus regression checks pass; Explain confirms
restricted relatives, coordinated verb clusters, repaired lemma/see-that, named
antecedents and factive-only presupposition, while quote suffixes abstain safely.
Default coverage may improve slightly; optional dictionary-POS backoff should repair
round/kind and raise exact coverage without adding converted-but-wrong readings on
the identical fixed diagnostic prefix (120 theories, 2,560 questions). This does
not establish unseen-text accuracy. Exact command: `bash research/run-phase-b.sh`.
The script snapshots compiled binaries after build success and runs:
`research/runs/phase-b/semantic-repair --corpus`,
`research/runs/phase-b/nl2proof-explain --all-readings < research/phase-a-inputs.txt`,
`PROOFWRITER_DIR=/home/gram/data/proofwriter research/runs/phase-b/proofwriter-coverage --owa --split dev --limit 120 --questions --examples 10 --check-context 0 +RTS -N2 -RTS`,
and the same coverage command with `--pos-backoff`. Each output is local/ignored.
Commit: pending.

## 2026-10-13 — C2: production-facing tests-first prediction

Added test/StrengthSpec.hs before migrating the implementation. It imports the future
Support API from existing Provenance, capability-backed and weak admission from
Genealogy, exact source withdrawal, and provenance-preserving Fusion. It covers the
scratch algebra laws, evidence class/source correlation, five known graph bugs,
existing cyclic graph semantics, oracle-capability admission, and rule provenance.
A new compile-fail/GenealogyVerdict.hs rejects public Verdict as a capability.
No existing production file or cabal registration is changed while B gates run.

Prediction: the new suite cannot compile yet because the intended public Support and
admission functions do not exist. This establishes the missing implementation; C0's
five runtime red regressions already establish the incorrect current behaviors.
Exact command: `runghc -isrc -itest test/StrengthSpec.hs > research/runs/strength-design/production-red.log 2>&1`.
Result: pending. Commit: future Phase C implementation checkpoint.

C2 red result: exited 1 as predicted; Support is not exported by the current
Provenance module, so the new production-facing suite cannot compile. Existing
behavioral failures remain established by C0. The new test suite also includes the
Fusion existential-consequent detachment regression before its implementation fix.
Commit: future Phase C implementation checkpoint.

### 2026-10-14 Phase B POS corpus discrepancy: prediction

Optimized semantic-repair --corpus passed six checks and failed the round/kind backoff existence check. Prediction: the training POS dictionary lacks JJ evidence for at least one item (the miniature intentionally supplied JJ); if both have JJ, inspect seen-pair/beam loss. Commands: `python3 research/runs/phase-b/probe-pos.py > research/runs/phase-b/pos-evidence.log`; `printf '%s\n' 'The cat is round.' 'The cat is kind.' ':q' | research/runs/phase-b/nl2proof-explain --pos-backoff --all-readings > research/runs/phase-b/explain-pos-diagnosis.log 2>&1`. Aggregate POS/category counts only; no corpus sentences printed.

## 2026-10-13 — D inference contract red prediction

Installed z3-solver 4.15.3.0 in research/.venv successfully; no system packages changed.
Official Z3 quantifier documentation notes quantified reasoning is incomplete and
may diverge: https://microsoft.github.io/z3guide/docs/logic/Quantifiers/ . Therefore
unknown/timeout must be distinct from the benchmark's logical Unknown.

Prediction: the newly written 31 inference-contract tests fail import because the
solver does not exist yet. They cover signed Horn versus FOL contraposition,
partial-theory abstention, scoping, hearsay/presupposition exclusion, alternative
support, contradiction and reading policies. Exact command:
`research/.venv/bin/python -m unittest discover -s bench/reasoning -p test_solver.py -v > research/runs/d-solver-red.log 2>&1`.
Commit: pending D implementation.

## 2026-10-13 — C3: isolated integration candidate prediction

Prepared candidate copies of the three owned modules only under ignored
research/runs/strength-design/candidate/NL2Proof/ so Phase B's source/gates remain
stable. New production-facing tests precede this candidate. The implementation makes
Genealogy abstract; raw Verdict bookkeeping cannot mint oracle evidence. It carries
weak classes, nested source chains, exact source revocations, and antichain closure.
Fusion retains per-claim oracle evidence alternatives and implication/rule supports,
and refuses to flatten existential consequents.

Prediction before compilation/execution: the candidate compiles, all StrengthSpec
checks pass, and the Verdict capability compile-fail case rejects for type mismatch.
Exact commands:
`ghc -O1 -iresearch/runs/strength-design/candidate -isrc -itest -outputdir research/runs/strength-design/candidate-build test/StrengthSpec.hs -o research/runs/strength-design/strength-spec > research/runs/strength-design/candidate-build.log 2>&1`
`research/runs/strength-design/strength-spec > research/runs/strength-design/candidate-test.log 2>&1`
`ghc -fno-code -iresearch/runs/strength-design/candidate -isrc -outputdir research/runs/strength-design/negative-build test/compile-fail/GenealogyVerdict.hs > research/runs/strength-design/negative.log 2>&1`
Results: pending. Existing production files remain unchanged.

D inference red result: import failed for missing solver as predicted; no assertions
were executed. Implemented signed Horn closure and scoped FOL backend with explicit
unsupported/timeout/contradiction results. Prediction: all 31 test methods pass.
Exact command: `research/.venv/bin/python -m unittest discover -s bench/reasoning -p test_solver.py -v > research/runs/d-solver-green.log 2>&1`.

### 2026-10-14 Phase B POS corpus discrepancy: result and corrected regression scope

Prediction confirmed. Aggregate licensed training evidence: round has JJ=1 (N/N), NN=23, VB=3, VBP=1, NNP=1; kind has NN=102, RB=2, NNP=1, JJ=0. Optimized Explain (85.9-second model load) selects `round(cat)` with a `pos-backoff` decision and fails to parse `The cat is kind.` No runtime policy changed. The optional corpus test is split into round-repair and kind-abstention regressions, recording the honest negative result instead of inventing adjective evidence. The miniature test is relabelled to make its deliberately supplied JJ evidence explicit. Also corrected normalized-lemma documentation and two shadowed local variable names in the quote guard (no behavior change).

Prediction: all 29 corpus-free semantic repairs remain green after these description-only source/test changes. Exact command: `runghc -isrc -itest test/SemanticRepairSpec.hs > research/runs/phase-b/semantics-release.log 2>&1`. The parent's full release gate will compile the optional corpus test; existing optimized trace establishes its revised two outcomes without another redundant model load.

E baseline reuse caveat (metadata inspection, no new model trial): ProverQA item245
has 16,861 input tokens in saved high versus 14,494 in the new low pilot, despite
identical task-prompt code and zero tool use in both. CLI/agent overhead changed
since the historical high snapshot. Report costs as recorded; an effort-only
causal claim would require contemporaneous high reruns if the result hinges on it.

B integrated and real-corpus results: all nine suites passed (1,063 checks),
original oracle boundary and Explain gates passed. Optional real-corpus suite was
6/7: the anticipated repair of both round/kind failed. Dictionary inspection and
optimized Explain showed round has JJ evidence and is repaired, whereas kind has
no JJ evidence and still abstains. Tests now describe this negative result instead
of weakening the POS criterion. No meaning policy changed after this diagnosis.

On the same 120 OWA depth-5 dev theories (2,244 theory occurrences, 2,560 questions),
default exact coverage remains 86.7% theory / 90.5% questions / 32/120 whole theories.
POS flag reaches 93.0% / 95.6% / 65/120. No-root failures fall from 524 to 255 over
4,804 occurrences; 16 typed but rejected DRS conversions remain (8 mixed top-level
conditional forms, 8 nested-conditional forms). Zero converted-but-wrong outputs
in both conditions. This last denominator must not conceal the typed semantic
errors caught by the converter; typechecking alone does not certify translation.
Prediction held for round coverage but failed for kind. Selected argument-cluster
coordination is correct, yet a second reading drops the object of likes; selected
NP coordination is correct, yet a second reading invents cat dog. Both remain
explicit limitations for skeptical inference. Commit: pending.

## 2026-10-13 — B release checkpoint gate prediction

Prediction: all required gates pass after only warning/documentation fixes and a
corpus assertion split reflecting the measured negative kind result. Exact command:
`bash research/run-gates.sh phase-b-release > research/runs/phase-b-release-driver.log 2>&1`.
The hand-written suite remains 29 checks; original tests have not been removed.
D independent inference-contract suite passes all 31 tests in 0.606 seconds.

Phase B local release checks: 29/29 passed. Applied study documentation with the measured POS negative result, scoped quotation/relative coverage, the retained lower-ranked coordination error, corrected generalized-quantifier NP types, and closed oracle admission description. The long Explain transcript is explicitly historical; current feature preservation is stated above it. README quotation guarantee is bounded and permits abstention.

### C3 result — candidate production overlay, 2026-10-14

The candidate overlay compiled successfully. `StrengthSpec` passed **45/45**
checks, including the production APIs' exhaustive 20-label algebra laws, 32,768
cyclic graph/valuation cases, 32,768 source-withdrawal/recomputation cases, and
4,096 edge-order cases. All five previously observed graph regressions are now
covered by passing production-facing assertions. The verdict-forgery fixture was
rejected exactly at `addConfirmedNode`: expected `Confirmed`, actual `Verdict`.
Logs: `research/runs/strength-design/candidate-build.log`, `candidate-test.log`,
`negative.log`. Existing production sources remain unchanged pending the B gate
checkpoint. This confirms the isolated candidate, not the final integrated build.

E/A-low ProverQA run completed: 120/120 successful unique rows, no error rows,
zero tool use; guard exited normally. Item-level accuracy and cost analysis follows.

## 2026-10-14 UTC / 2026-10-13 New York — E/A-low FOLIO prediction

Prediction: low-effort accuracy on the fixed FOLIO sample will not exceed saved
high (99/120); uncertainty and known label-noise items will account for substantial
errors. Expect 120 successful strict-valid answers without tools. Command:
`python3 research/runs/phase-e-baselines/run_guarded.py folio > research/runs/phase-e-baselines/folio-full.log 2>&1`.
Underlying unchanged runner: `python3 bench/common/run_codex.py folio gpt-5.5 low 120 2`.
Results pending. No labels or FOL annotations enter the prompt.

## 2026-10-14 UTC / 2026-10-13 New York — E/A-high contemporaneous ProverQA control prediction

Prediction: fresh high effort will equal or exceed the new low baseline, with
input overhead close to new low rather than historical high. This measures
same-model effort, never model size. Parent authorized this contemporaneous
control because saved-high input overhead changed. Command:
`python3 research/runs/phase-e-baselines/run_guarded.py proverqa current-high > research/runs/phase-e-baselines/proverqa-high-current.log 2>&1`.
The scratch driver imports and invokes unchanged bench/common/run_codex.call,
with the identical context/statement-only prompt, model gpt-5.5, effort high,
120 fixed items, two workers, same isolated read-only CLI policy. Results go only
to ignored research/runs/phase-e-baselines/proverqa-high-current.jsonl; saved high
is not overwritten. Combined with FOLIO-low, at most four Codex calls run at once.
Guard behavior is unchanged. Results pending.

## 2026-10-14 UTC / 2026-10-13 New York — E ProverQA-low saved-result analysis prediction

Prediction: rescoring confirms all 120 rows as strict-valid with no operational
failures; low accuracy is at most historical high (90/120), primarily from
Uncertain answers on provable items. Command:
`python3 research/runs/phase-e-baselines/summarize.py proverqa > research/runs/phase-e-baselines/proverqa-low-summary.jsonl`.
Reports Wilson intervals, paired exact McNemar against historical high and raw
usage totals/means; interpret comparison cautiously because of overhead drift.

## 2026-10-13 — B final corpus expectation confirmation

Prediction: the corrected eight optional corpus checks all pass, with round repaired
and kind explicitly still unsupported. No lowering of the POS condition is involved.
Exact command: `$(cabal list-bin semantic-repair) --corpus > research/runs/phase-b/corpus-release.log 2>&1`.

E ProverQA-low analysis result: 90/120 correct (75.0%) under both strict and
lenient scoring, Wilson 95% [66.56%,81.89%], valid-answer coverage 120/120.
No API errors or tool use. Of 30 errors, 28 are Uncertain on provable items.
Historical high is also90/120: both correct87, both wrong27, low-only3,
high-only3, exact paired McNemar p=1.0. Mean low tokens: input14,460.78,
output175.01, reasoning167.62; historical high: input16,924.68, output326.03,
reasoning318.48. Predictions held at equality and for the error pattern.
This is an observed effort-baseline comparison, not evidence for graph benefit.
Detailed aggregate: research/runs/phase-e-baselines/proverqa-low-summary.jsonl.
Commit: summary pending completion of all baseline conditions.

### C4 prediction — bridge compatibility and source identity edge cases, 2026-10-14

Prediction: the candidate typed `Claims.genealogyOf` bridge preserves all existing
Substrate behavior when synthetic confirmed fixtures use actual oracle tokens.
Eight new Strength checks should pass for duplicate reports, stale inference
invalidation, shared speakers across distinct documents, independent confirmations
on one node, and exact loss/survivor reports. Existing production remains frozen.
This also checks warnings on the candidate modules. Commands:

```
ghc -O1 -Wall -Wcompat -Wincomplete-record-updates -Wincomplete-uni-patterns -Wredundant-constraints -iresearch/runs/strength-design/candidate -isrc -itest -outputdir research/runs/strength-design/candidate-build test/StrengthSpec.hs -o research/runs/strength-design/strength-spec > research/runs/strength-design/candidate-build-c4.log 2>&1
research/runs/strength-design/strength-spec > research/runs/strength-design/candidate-test-c4.log 2>&1
ghc -O1 -iresearch/runs/strength-design/candidate -isrc -itest -outputdir research/runs/strength-design/substrate-build research/runs/strength-design/SubstrateCandidateSpec.hs -o research/runs/strength-design/substrate-spec > research/runs/strength-design/substrate-build.log 2>&1
research/runs/strength-design/substrate-spec > research/runs/strength-design/substrate-test.log 2>&1
```

### 2026-10-14 Phase D scoped exporter: prediction before implementation

The new 17-check export suite specifies gold-field rejection, escaped JSON round trips, scoped negation/implication, residual attitudes/presuppositions/opaque terms, discourse freshening, query isolation, partial-context incompleteness, and a total theory/query cap. Prediction: the first run fails to compile because the shared all-reading Pipeline API (`ReadingResult`, `srReadings`) and JSON renderer do not yet exist. This is the test-first API checkpoint; Phase B source remains frozen until its commit. Exact command: `runghc -isrc -itest test/ExportSpec.hs > research/runs/phase-d/export-red.log 2>&1`.

B release result: all nine suites (1,063 checks), original oracle-boundary gate,
and all eight Explain smoke cases passed. Build produced no new warnings. Phase B
checkpoint now ready; six additional negative fixtures were separately confirmed
to reject for their intended reasons and will join the gate in its own next commit.

Phase B checkpoint: `24c3cc2`, pushed to origin astra/research.

## 2026-10-13 — Separate oracle-gate strengthening prediction

Reason for changing the gate: the original twelve negative cases did not cover
bare CanonCond confirmation, extracted embedded literals, Data.Coerce index
forging, removed arbitrary promotion helpers, or Fact-content record updates.
These six cases were red before the B repair and green individually afterward.
The gate now includes all six and verifies their intended diagnostic category;
no prior case or positive consumer is removed. Prediction: all release gates
pass, with eighteen negative boundary checks and two positive consumers.
Exact command: `bash research/run-gates.sh oracle-gate-strengthening > research/runs/oracle-gate-strengthening-driver.log 2>&1`.
The gate change will be committed separately, as required by ASTRA_GOAL §0.6.

## 2026-10-14 UTC / 2026-10-13 New York — D export audit (read only, concurrent with E baselines)

Strict export whitelist admits only id/context/statement. Query boxes stay separate
from premises, cross-context existential references become residuals, and the
combined theory/query Cartesian budget is explicit. Two draft issues were sent
to the export owner before integration: every COr currently receives sentence-wide
fallback provenance, so detecting `either` from that provenance can falsely make
multiple separate ors exclusive; and simpleChar rejects legitimate multiword rigid
constants (e.g. bald eagle) as opaque. Recommend scoped XOR evidence or explicit
ambiguous-scope residual, and accepting plain spaced names while retaining opaque
term rejection. No test or model trial was run for this static audit.

### C5 prediction — label growth and runtime, 2026-10-14

Prediction: the conjunction of n independent binary evidence alternatives has
exactly 2^n minimal environments, each with n tokens. This measures the known
exponential limit, not an accuracy benefit; no approximation or silent cap is
introduced. Measure n=1,2,4,6,8,10 and wall time/maximum RSS of the compiled public
53-check property suite. Commands (candidate overlay; production still frozen):

```
ghc -O1 -iresearch/runs/strength-design/candidate -isrc -outputdir research/runs/strength-design/growth-build research/runs/strength-design/LabelGrowth.hs -o research/runs/strength-design/label-growth > research/runs/strength-design/growth-build.log 2>&1
research/runs/strength-design/label-growth > research/runs/strength-design/label-growth.log 2>&1
/usr/bin/time -f 'elapsed_seconds=%e maximum_rss_kb=%M' -o research/runs/strength-design/strength-resources.log research/runs/strength-design/strength-spec > research/runs/strength-design/candidate-timed.log 2>&1
```

### C4 result — compatibility preserved, 2026-10-14

Expanded Strength checks pass **53/53**; rebuilt candidate code reports no new
warnings under the repository warning flags. The candidate typed Claims bridge
and adjusted token-backed Substrate fixtures compile and pass the existing suite.
No production source was edited during the B checkpoint. New class/source and
stale-edge assertions passed without implementation changes; they exercise the
candidate's planned invariants rather than hiding a discovered regression.

Phase D initial red result: fails exactly at missing `ReadingResult`, as predicted. Read-only audit identified sentence-wide `either` provenance: multiple COr nodes sharing that provenance cannot each become XOR. Added explicit XOR-scope residual metadata (inclusive semantics remains intact), regression cases for ambiguous same-sentence and distinct-sentence markers, and support for plain multiword rigid names such as bald eagle while rejecting function-form stringified arguments. No experiment rerun before the shared backend API exists.

## 2026-10-13 — D/E runner hygiene prediction

Prediction: seven new runner tests fail to import the absent runner. They ensure
only id/context/statement reach inference, abstentions remain in the end-to-end
accuracy denominator, exact McNemar uses paired identical IDs, and reading mass
is normalized stably. Exact command:
`research/.venv/bin/python -m unittest discover -s bench/reasoning -p test_runner.py -v > research/runs/d-runner-red.log 2>&1`.

### C5 result — exactness has exponential space cost, 2026-10-14

The optimized public Strength suite again passes 53/53; `/usr/bin/time` measured
6.62 s wall time and maximum RSS 21,760 KiB on this shared host. Label growth is
exactly 2^n with n tokens per environment: n=1,2,4,6,8,10 produced
2,4,16,64,256,1024 environments. CPU times were respectively
0.000201,0.000037,0.000130,0.000789,0.006453,0.076034 s. First-use and runtime noise
make tiny times non-monotonic; no inference of calibrated scaling is warranted.
The environment count confirms the documented exponential limit. Results and the
concrete weak-versus-grounded example are in STRENGTH.md. Logs: label-growth.log,
strength-resources.log, candidate-timed.log under research/runs/strength-design/.

D/E runner red result: missing module import failed as predicted. Implemented the
whitelisted persistent parser runner, immutable cache fingerprints, solver policy
runner, coverage/precision/accuracy, Wilson and exact paired McNemar. Prediction:
all 38 Python methods pass, including the existing solver contract. Exact command:
`research/.venv/bin/python -m unittest discover -s bench/reasoning -p 'test_*.py' -v > research/runs/d-python-green.log 2>&1`.

Oracle-gate strengthening result: all eighteen negative fixtures rejected for
the expected reasons; two positive consumers compiled. Build, all nine suites
and Explain gate passed. The corrected optional real-corpus suite also passed
8/8; kind remains unsupported as explicitly tested. Python D/E contract tests
passed38/38. Gate-only checkpoint ready.

Gate-strengthening checkpoint: `7afac4d`, pushed to origin astra/research. Source freeze released for C/D integration.

### C6 prediction — production integration, 2026-10-14

B and the separate oracle gate checkpoint are now pushed and production edits
released by the coordinator. Copied the already-tested Provenance/Genealogy/Fusion
candidate and minimal typed Claims bridge; migrated existing Substrate fixtures to
actual confirmation tokens. Prediction: production sources preserve the candidate
results, Strength53/53 and Substrate114/114; the verdict-forgery negative still
fails for the expected token/verdict type mismatch. Exact commands (reusing private
object directories, now importing production `src` only):

```
ghc -O1 -Wall -Wcompat -Wincomplete-record-updates -Wincomplete-uni-patterns -Wredundant-constraints -isrc -itest -outputdir research/runs/strength-design/candidate-build test/StrengthSpec.hs -o research/runs/strength-design/strength-spec > research/runs/strength-design/production-build.log 2>&1
research/runs/strength-design/strength-spec > research/runs/strength-design/production-test.log 2>&1
ghc -O1 -isrc -itest -outputdir research/runs/strength-design/substrate-build test/SubstrateSpec.hs -o research/runs/strength-design/substrate-spec > research/runs/strength-design/substrate-production-build.log 2>&1
research/runs/strength-design/substrate-spec > research/runs/strength-design/substrate-production-test.log 2>&1
ghc -fno-code -isrc -outputdir research/runs/strength-design/negative-build test/compile-fail/GenealogyVerdict.hs > research/runs/strength-design/negative-production.log 2>&1
```

The coordinator separately registers the suite and owns all mandatory integrated
gates, STATE, commits, and push. This integration does not change the gate script.

### 2026-10-14 Phase D shared backend and exporter: green-run prediction

After B and oracle-gate checkpoints were pushed, implemented `ReadingResult`/`srReadings` through the existing Pipeline backend. Selected fields still use the first candidate, while every alternative receives its own type check, normalized form, local resolution/projection, score and notes. Added the base-only JSON serializer and persistent gold-free exporter. Prediction: all 22 export checks pass; all 29 semantic repair checks remain unchanged. Exact commands: `runghc -isrc -itest test/ExportSpec.hs > research/runs/phase-d/export-green.log 2>&1`; `runghc -isrc -itest test/SemanticRepairSpec.hs > research/runs/phase-d/semantic-regression.log 2>&1`. A compiler failure is an implementation issue, not a measured language result.

D integration refactor: Explain now consumes shared per-reading Pipeline normal
forms and DRSs instead of reimplementing the alternative-reading DRS conversion.
Prediction: existing Explain gate outputs retain their semantics, while every
displayed/exported alternative has one translation path. Full integrated gate
command will be recorded once both agents declare stable. No admission policy
change is intended by this refactor.

### C6 result — production targeted checks, 2026-10-14

Production-source builds succeeded, Strength passed **53/53**, and Substrate passed
**114/114**. The GenealogyVerdict fixture failed for the intended `Confirmed` token
versus `Verdict` mismatch. No compatibility fix was needed after copying the tested
candidate. Production logs are `production-{build,test}.log`,
`substrate-production-{build,test}.log`, and `negative-production.log` under
research/runs/strength-design/. Full combined gates remain coordinator-owned.

Phase D shared export green result: 22/22 export checks and 29/29 semantic repairs passed; `git diff --check` clean. Prediction for the persistent-process smoke: four request lines produce four JSON response lines, the third rejects the unwhitelisted label key, and the fourth succeeds after that error. The first query's cross-context existential anaphor is incomplete/residual; the second context and query are complete. Exact command: `runghc -isrc tools/ParseJSON.hs --hand < research/runs/phase-d/export-smoke.jsonl > research/runs/phase-d/export-smoke-output.jsonl 2> research/runs/phase-d/export-smoke-stderr.log`; validation: `python3 research/runs/phase-d/check-export-smoke.py`.

Phase D persistent smoke passed: four JSONL responses, third rejects label, fourth succeeds; context existential query remains residual; simple context/query are complete. Output and validator are ignored under research/runs/phase-d.

## 2026-10-13 — C/D integrated release gate prediction

Prediction: all existing suites plus Strength53 and Export22 pass (1,138 checks),
along with the eighteen-case oracle boundary and eight-case Explain gate. Shared
all-reading translation should preserve selected behavior; the new source-bound
support algebra should retain old114 Substrate checks with token-backed fixtures.
Exact command: `bash research/run-gates.sh phase-cd > research/runs/phase-cd-driver.log 2>&1`.
The additional GenealogyVerdict compile-fail fixture already rejects individually;
it will join the release script in another separate gate-strengthening commit.
Python contract command: `research/.venv/bin/python -m unittest discover -s bench/reasoning -p 'test_*.py' -v > research/runs/d-python-integrated.log 2>&1`.

## 2026-10-13 21:29 America/New_York — E/A-low ProntoQA prediction

Prediction: the fixed 120 five-hop fictional ProntoQA items will remain near the
saved high-effort ceiling (120/120), with strict-valid outputs and zero tool use.
Command (to start once FOLIO-low exits):
`python3 research/runs/phase-e-baselines/run_guarded.py prontoqa > research/runs/phase-e-baselines/prontoqa-full.log 2>&1`.
Underlying unchanged runner: `python3 bench/common/run_codex.py prontoqa gpt-5.5 low 120 2`.
No labels or explanations enter prompt_body; only context and statement. The
contemporaneous ProverQA-high run remains independent; total concurrency stays4.
Results pending.

## 2026-10-13 21:29 America/New_York — E FOLIO-low analysis prediction

Prediction: the completed run will have full operational/valid-label coverage;
low strict accuracy will not exceed historical high's99/120. Command after
completion: `python3 research/runs/phase-e-baselines/summarize.py folio > research/runs/phase-e-baselines/folio-low-summary.jsonl`.
Report strict/lenient, coverage, answered precision, end-to-end accuracy, Wilson,
paired exact McNemar and token usage. FOLIO's known label-noise caveat remains.

E FOLIO-low result: 120 successful unique first-attempt rows, zero tools/errors,
100% valid-answer coverage. Strict and lenient accuracy92/120=76.67%, Wilson95%
[68.34%,83.33%]; answered precision and end-to-end accuracy are the same because
coverage is complete. Historical high99/120; paired both-correct91,both-wrong20,
low-only1,high-only8, exact McNemar p=.0390625. Mean low tokens input14,283.775,
output77.042,reasoning70.225; historical high input16,704.225,output170.408,
reasoning163. Prediction held. The historical reference's overhead drift and
FOLIO label noise preclude treating this as a clean causal effort estimate.
ProntoQA-low now active; contemporaneous ProverQA-high continues independently.
Commit: baseline summary pending final conditions.

### F0 prediction — generated guarantee benchmark tests first, 2026-10-14

Approved protocol:64 synthetic items,8 families, seed20261013; Established,
WeakOnly, Unsupported, Conflict. Conflict denotes attributed evidence on both
polarities, not oracle truth or explosion. The model sees only protocol+narrative;
the graph adapter sees only structured fixtures; gold is independent template case
analysis. Before generator/adapter implementation, the new tests should fail at
missing `generate` import, establishing a red target. Command:

```
python3 -m unittest discover -s bench/retraction -p 'test_*.py' > research/runs/strength-design/retraction-red.log 2>&1
```

No model calls or parser-fidelity claim are part of this structured admission test.

### 2026-10-14 Phase G Threading/SDRT evidence: prediction

Compare unchanged flat discourse against Committed and Permissive Threading on ten handcrafted texts, using the hand attitude lexicon plus a transparent definite-determiner fixture (no corpus model load). Prediction: both SDRT policies regress named/definite antecedents because their rankings contain Ref only; Committed additionally loses antecedents after coordinating interludes, and last-edge-only Permissive loses them by four sentences. Neither should leak referents through negation or attitude barriers. This is a capability/safety probe, not an estimate of natural-discourse accuracy. Exact command: `runghc -isrc research/runs/phase-g/ThreadingProbe.hs > research/runs/phase-g/threading.jsonl 2> research/runs/phase-g/threading.stderr`.

### 2026-10-14 Phase G Alternatives/Modifier evidence: prediction

Probe five handwritten sentences with the hand fragment plus explicitly intersective fake/gun fixtures to expose the existing class table's limitation. Prediction: Every student reads a book generates two closed, typed scope readings; relatives and negative quantifiers remain one; the ancient/Chinese/red stack generates unlicensed fused alternatives as well as its licensed Chinese-dragon candidate. `classifyModifier fake` defaults Intersective, so annotation alone cannot correct the deliberately supplied intersective fake-gun meaning. Generated well-typed alternatives are not asserted facts or validated lexical readings. Exact command: `runghc -isrc research/runs/phase-g/AlternativesProbe.hs > research/runs/phase-g/alternatives.jsonl 2> research/runs/phase-g/alternatives.stderr`.

Phase G Threading result: all27 sentences in10 authored texts parsed;12 pronouns total. Flat resolves10 and preserves the2 intended negation/report barriers. Committed resolves3, losing7 resolutions across6 texts; Permissive resolves5, losing5 across5 texts. Neither improves a case. The Alternatives probe initially failed to compile because composition operators adjacent to JStr were read as module qualification; corrected without changing its hypothesis. Drivers are now preserved as research/probe-threading.hs and research/probe-alternatives.hs for reproducibility. Prediction unchanged for the five Alternatives cases. Exact rerun: `runghc -isrc research/probe-alternatives.hs > research/runs/phase-g/alternatives.jsonl 2> research/runs/phase-g/alternatives.stderr`.

Phase G Alternatives first result: scope predictions2/1/1 confirmed and all returned forms closed/typed. The subject modifier-stack prediction was wrong: both stack/fake subject examples returned only the surface reading. Inspection explains why: modifierChains collects every unary predicate on the variable, including the intransitive verb sleep, then treats the final predicate as noun head; the actual noun fails its all-modifiers test. Add matched object-position controls. Prediction: `John sees an ancient Chinese red dragon` generates4 candidates (surface plus3 fusions, only Chinese-dragon fusion class-licensed); `John sees a fake gun` generates2, fake classified Intersective with unlicensed fusion. Exact command: `runghc -isrc research/probe-alternatives.hs > research/runs/phase-g/alternatives-seven.jsonl 2> research/runs/phase-g/alternatives-seven.stderr`.

## 2026-10-13 — D/E gold-free benchmark parser cache prediction

Prediction: the ProverQA-hard and FOLIO samples have many residual sentences;
ProofWriter coverage improves with POS backoff, while ProntoQA invented words
remain a dictionary coverage problem. Skeptical enumeration may hit its explicit
64-pair cap on ambiguous theories. No solver or accuracy result is inferred from
parse success. Each inference request contains exactly id/context/statement;
labels/gold FOL never cross the parser process boundary.
Exact command: `bash research/run-parser-caches.sh`. It snapshots the built
`nl2proof-parse-json` executable and runs
`research/.venv/bin/python bench/reasoning/run.py parse --bench all --limit 120 --binary research/runs/phase-d/parser --output research/runs/phase-d/parses-default.jsonl`
and the same command with `--pos-backoff --output research/runs/phase-d/parses-pos.jsonl`.
The four fixed sample files have globally unique string IDs. Each cache fingerprints
the exact request and executable/configuration. ProverQA is processed first.

### F0 result and F1 prediction — independent fixtures versus production graph, 2026-10-14

F0 failed as expected at `ModuleNotFoundError: generate`. Implemented the seeded
generator, gold-isolated prompt, and new adapter using production Genealogy with
typed authored DRS admission. Prediction: all64 independently specified template
outcomes agree with production labels, class-correlated source environments and
both groundedness booleans; four Python tests pass, including prompt isolation and
unknown-class fail-closed behavior. Query polarity doubles the four withdrawal
regimes in each family; this is64 designed cases, not64 independent random draws.
Commands:

```
ghc -O1 -Wall -Wcompat -Wincomplete-record-updates -Wincomplete-uni-patterns -Wredundant-constraints -isrc -outputdir research/runs/strength-design/retraction-build tools/RetractionBench.hs -o research/runs/strength-design/retraction-bench > research/runs/strength-design/retraction-build.log 2>&1
python3 bench/retraction/generate.py --seed 20261013 --output bench/retraction/sample.jsonl
RETRACTION_BENCH_BIN="$PWD/research/runs/strength-design/retraction-bench" python3 -m unittest discover -s bench/retraction -p 'test_*.py' > research/runs/strength-design/retraction-tests.log 2>&1
```

Phase G Alternatives follow-up confirmed the object-position control predictions: scope counts2/1/1 on quantifier/relative/negation probes; subject modifier stacks1 each; object Chinese stack4 alternatives with only Chinese fusion licensed; object fake fixture2 with fake still Intersective/unlicensed fusion. All seven cases' returned terms are closed and type t. Preserved both drivers and exact case/metric/command recommendations in research/RESTORED.md. Recommendation: no default SDRT/Threading integration, no unvalidated coupling/ranking admission; preserve scope generation as a bounded opt-in experiment.

### F1 result and F2 prediction — local scoring and graph artifact, 2026-10-14

F1 passes all4 tests, including exact64/64 template outcomes. The adapter compiles
with no own warnings; the JSON dependency emits its existing renderJSON shadowing
warning. The shared lenient scorer is hardcoded to True/False/Uncertain, so this
four-label benchmark needs local parsing. Added parser tests first: the run below
should fail at missing score import, then pass5/5 after local implementation.
Prediction: graph evaluator emits64 correct labels and64 exact support records;
all families8/8. Model prompts/sample are now frozen for the raw baseline.

```
RETRACTION_BENCH_BIN="$PWD/research/runs/strength-design/retraction-bench" python3 -m unittest discover -s bench/retraction -p 'test_*.py' > research/runs/strength-design/retraction-score-red.log 2>&1
```

F2 red result: expected missing `score` import. Implemented local four-label
parser and graph output evaluator. Follow-up commands under the same prediction:

```
RETRACTION_BENCH_BIN="$PWD/research/runs/strength-design/retraction-bench" python3 -m unittest discover -s bench/retraction -p 'test_*.py' > research/runs/strength-design/retraction-final-tests.log 2>&1
python3 bench/retraction/evaluate_graph.py --binary research/runs/strength-design/retraction-bench --output bench/retraction/results/graph.jsonl > research/runs/strength-design/retraction-graph-summary.json
python3 bench/retraction/score.py bench/retraction/results/graph.jsonl > research/runs/strength-design/retraction-graph-score.json
```

### F2 result — graph benchmark and scoring ready, 2026-10-14

All5 tests pass (0.154s), including all64 independent exact support records. Graph
label score64/64, support/class/source score64/64, all8 families8/8; subprocess
evaluation0.071111s. Label mix: Established18, WeakOnly20, Unsupported18, Conflict8.
Sample is66021 bytes of locally authored synthetic data. Five checks are seeded
reproducibility/family balance; gold-isolated prompts; template-vs-production exact
outputs; malformed admission fail-closed; generic four-label strict/lenient scoring.
Graph raw outcomes live in ignored bench/retraction/results/graph.jsonl; summaries
in research/runs/strength-design/retraction-graph-{summary,score}.json. README
records commands, caveats, and the pending raw-model comparison. No parser-fidelity
or independent-sampling accuracy claim follows from these designed fixtures.

### 2026-10-14 Phase G/D sortal-policy probe: prediction

CCGSem sortal constants are `person` and `thing`; Bench.ProofWriter's comparison adapter removes positive bound sortals while the general Python backends retain them. Predict that `red(Bob)` plus `person(x) & red(x) -> big(x)` gives Unknown in both Horn and FOL without person(Bob), while explicitly removing this benchmark-domain guard yields True. This is a strengthening dataset convention, not general English-equivalent normalization. Audit only newline-terminated cache records and their gold-free DRSs; no benchmark labels or gold logic opened. Early caches currently contain ProverQA, so do not apply ProofWriter policy to them. Exact command: `research/.venv/bin/python research/runs/phase-g/domain-probe.py > research/runs/phase-g/domain-probe.log`.

C/D integrated gate result: build passed; all eleven suites (1,138 checks) passed;
eighteen negative oracle checks and two positive consumers passed; all eight
Explain cases passed after shared-reading refactor. Python38 tests passed. One
nonfunctional name-shadow warning remains in JSON serializer, tracked for cleanup.
Core C and scoped D infrastructure are ready for checkpoint; benchmark/cache and
fallback experiments remain active, with no empirical accuracy claim from tests.

### 2026-10-14 01:35 UTC — Phase E contemporaneous high complete; F raw pilot suite prediction
Contemporaneous ProverQA-high finished120/120 with no operational/tool guard errors. Prediction for rescoring: high will match or beat low90/120; current input overhead should be close to low, not historical high. Command: `python3 research/runs/phase-e-baselines/summarize.py proverqa > research/runs/phase-e-baselines/proverqa-current-summary.jsonl`.
F64 raw weak model prediction before calls: weakest cases will be retraction through conjunctive supports, cycles, and weak-versus-oracle boundaries; expect below exact graph64/64 despite explicit protocol. Prompt inspected: bench/retraction/spec.py reads only context/statement, no fixture or label. Command: `python3 research/runs/phase-e-baselines/run_guarded.py retraction > research/runs/phase-e-baselines/retraction-low.log 2>&1`; wrapper calls unchanged `python3 bench/common/run_codex.py retraction gpt-5.5 low 64 2`, stopping on error/tool use. Existing Pronto low uses2calls; F uses2 (total<=4). Common lenient parser is unsuitable for F labels; final scoring will use bench/retraction/score.py.

### D-audit0 prediction — malformed JSON and inner-loop resource bounds, 2026-10-14

Independent read-only review of the Python solver/runner after38 green tests.
Prediction from source inspection: non-object conditions or query conditions raise
uncaught AttributeError instead of an abstaining unsupported result; Horn joins
check the deadline only before a whole rule and can significantly exceed1ms even
on25 facts with a three-variable body. A2s outer subprocess deadline bounds the
probe. Expected correct FOL controls: nonempty-domain universal-to-existential
entailment True; reversing forall/exists cannot be proved True. Also inspect the
ProntoQA Unknown mapping (policy question: Uncertain is off its two-label space).
No production edits. Command:

```
research/.venv/bin/python research/runs/solver-audit/audit.py > research/runs/solver-audit/audit.log 2>&1
```

C/D checkpoint: `abf7364`, pushed to origin astra/research.

## 2026-10-13 — Separate graph-capability gate strengthening prediction

The new graph admission API requires an actual Confirmed capability, while an
ordinary Verdict constructor must remain insufficient. Add the already checked
GenealogyVerdict fixture to the oracle gate, without changing/removing prior cases.
Prediction: nineteen negative checks, two positive consumers, and every other
release gate pass. Exact command:
`bash research/run-gates.sh graph-capability-gate > research/runs/graph-capability-gate-driver.log 2>&1`.
This gate change will be its own commit per ASTRA_GOAL §0.6.

## 2026-10-13 — D solver operational pilot prediction

Prediction: the first twelve fixed ProverQA-hard items have low parser+solver
coverage, especially under skeptical/capped enumeration; classical disjunction
support alone will not overcome lexical/structural gaps. This is an operational
pilot, not a powered empirical comparison. The first twelve complete parser
records were sealed into an independent cache with their original fingerprints.
Exact command: `research/.venv/bin/python bench/reasoning/matrix.py --parses research/runs/phase-d/proverqa-pilot12.jsonl --out-dir research/runs/phase-d/pilot12 --benches proverqa --limit 12 --timeout-ms 2000 > research/runs/phase-d/pilot12-driver.log 2>&1`.

### 2026-10-14 01:39 UTC — Phase E graph/translation runner red prediction
Prediction: pure tests for label/gold prompt isolation, unsupported-scope residuals, scoped translation validation/freshening, retained parser successes, hash-resume checks, and hybrid routing/cost will fail because llm.py is absent. No C or translation model calls authorized yet; first render is reviewed by root. Exact command after writing tests: `research/.venv/bin/python -m unittest discover -s bench/reasoning -p test_llm.py > research/runs/phase-e-baselines/llm-red.log 2>&1`. Fresh high result contradicts predicted improvement:89/120 vs low90/120, paired highonly3/lowonly4,p1; current high and low input means identical14460.7833, output311.8083vs175.0083; all120 rows firstattempt/noerrors/tools.

### 2026-10-14 Phase D explicit domain-policy tests: red prediction

The gold-free control confirms strict Unknown versus explicit-policy True for both signed Horn and Z3. The current cache audit contains no ProofWriter records yet, so no real ProofWriter policy comparison is claimed. Add17 tests before production adapter implementation: strict identity, scoped positive guard removal with localized quantifier provenance, preserved consequences/facts/negative/nested/modal content, nonempty range-restricted bodies, immutable input and auditable removed-guard decisions, and signed solver effects. Prediction: import fails because domain.py does not exist. Exact command: `research/.venv/bin/python -m unittest discover -s bench/reasoning -p test_domain.py -v > research/runs/phase-g/domain-red.log 2>&1`.

### D-audit0 result and D-audit1 prediction, 2026-10-14

All8 malformed-condition probes raised uncaught AttributeError as predicted (two
backends × scalar/null/list theory conditions and scalar query). FOL controls pass:
nonempty-domain entailment True; invalid quantifier reversal Unknown. ProntoQA
maps Unknown to Uncertain, outside its allowed True/False labels; this is flagged
as a coverage-policy question, not a soundness counterexample. The1ms Horn probe
returned resource-limit in0.002238s, likely before the large join; this does not
establish the suspected inner-loop overrun. Give the same25-fact/3-variable rule a
10ms allowance to reach the join, bounding the entire probe at2s. Prediction:
substantial overrun because the nested match loops do not check the deadline.

```
timeout 2s research/.venv/bin/python research/runs/solver-audit/timeout_case.py 10 > research/runs/solver-audit/timeout-10ms.log 2>&1
```

## 2026-10-13 — D malformed condition regression prediction

Independent audit found non-object conditions escaping as AttributeError in both
backends. Prediction: the new regression errors before an explicit DRS condition
shape check; valid FOL/Horn cases remain unchanged. Exact command:
`research/.venv/bin/python -m unittest discover -s bench/reasoning -p test_solver.py -v > research/runs/d-malformed-red.log 2>&1`.

Phase D domain-policy red result: import failure at missing domain module, as predicted. Implemented only the new domain.py module; general solver, Pipeline and cache sources are unchanged. Prediction: all17 domain tests pass, including explicit Horn/Z3 Unknown-to-signed-proof changes and scope-preservation negatives. Exact command: `research/.venv/bin/python -m unittest discover -s bench/reasoning -p test_domain.py -v > research/runs/phase-g/domain-green.log 2>&1`.

### F-score audit prediction, 2026-10-14

A read-through found a local lenient-scoring ambiguity: an explicit marker may
currently accept the first of two competing labels in the same answer segment.
Added `Final answer: Established / Unsupported -> None` to the existing test;
expect red, then restrict a marker's answer segment to one distinct label. This
changes scoring only, not the frozen sample or model prompt. Commands:

```
RETRACTION_BENCH_BIN="$PWD/research/runs/strength-design/retraction-bench" python3 -m unittest discover -s bench/retraction -p 'test_*.py' > research/runs/strength-design/retraction-marker-red.log 2>&1
```

Malformed-condition red result: eight subtest errors from AttributeError, as
predicted. A second audit reproduced a72x Horn timeout overrun during a cubic
join (25 facts,10ms budget,0.723s elapsed), because checks occurred only between
rules. Prediction: the new25-fact regression also fails a generous250ms bound
before loop-internal budget checks. Exact command:
`research/.venv/bin/python -m unittest discover -s bench/reasoning -p test_solver.py -v > research/runs/d-resource-red.log 2>&1`.

F-score red result: the new ambiguity assertion failed as predicted (Established
was accepted). Updated only the local scorer to reject multiple labels in the
last marked answer segment. Prediction for rerun: all5 tests pass, including this
additional assertion; graph score remains64/64 because graph replies are exact.

```
RETRACTION_BENCH_BIN="$PWD/research/runs/strength-design/retraction-bench" python3 -m unittest discover -s bench/retraction -p 'test_*.py' > research/runs/strength-design/retraction-marker-fixed.log 2>&1
python3 bench/retraction/score.py bench/retraction/results/graph.jsonl > research/runs/strength-design/retraction-graph-score.json
```

### D-audit1 result and F-score audit result, 2026-10-14

The10ms Horn join probe completed in0.722886s with resource-limit: roughly72× its
stated budget. This establishes delayed resource enforcement inside one rule,
not a logically incorrect answer. Reported to coordinator with the malformed-
condition crashes; no root solver/runner production files edited by this agent.

The local F scorer's marked-answer ambiguity fix passes all5 tests. Graph strict
and lenient outcomes remain64/64. No frozen narrative or sample changed. The
scorer now rejects competing labels after an explicit answer marker as documented.

### 2026-10-14 01:48 UTC — graph runner green attempt and Pronto/F scoring prediction
Red runner test failed with expected ModuleNotFoundError for llm.py. Implemented explicit graph projections, scoped translation validation, whole-sentence replacement, fresh binding names, and routed-cost hybrid. Prediction: `research/.venv/bin/python -m unittest discover -s bench/reasoning -p test_llm.py > research/runs/phase-e-baselines/llm-green.log 2>&1` should pass19 semantic tests (no model calls); first concrete prompt rendering may expose backend/export incompatibilities. Command: `research/.venv/bin/python bench/reasoning/llm.py prepare --bench proverqa --parses research/runs/phase-d/parses-default.jsonl --backend z3 --or-semantics proverqa --limit 1 --output research/runs/phase-e-baselines/proverqa-graph-prompt-pilot.jsonl`. Pronto finished120/120 no errors/tools. Prediction remains near ceiling strict120 or119; command `python3 research/runs/phase-e-baselines/summarize.py prontoqa > research/runs/phase-e-baselines/prontoqa-low-summary.jsonl`.

### 2026-10-14 01:39 UTC — baseline completion; F scoring prediction; timestamp correction
The previous two runner entries used manually advanced timestamps01:39/01:48; wall clock is now2026-10-14 01:39 UTC, and those entries actually preceded this entry. Sequence, commands and predictions remain correct; subsequent logs use datetime UTC. Graph tests18/18 green (prediction said19, actual count18), first prompt prepared successfully. Pronto low116/120, four True→False errors, versus savedhigh120/120; paired exactp.125, zeroerrors/tools, allfirstattempt; inputmean14321.0417/output26.55. Raw F finished64/64, zeroerrors/tools. Before local scoring prediction: explicit protocol probably makes raw accuracy high, but conjunction/retraction weakness may remain. Exact command: `python3 bench/retraction/score.py bench/retraction/results/results_gpt-5.5__low.jsonl > research/runs/phase-e-baselines/retraction-low-summary.json`.

Phase D domain adapter green:17/17 tests passed (including Horn and Z3 signed controls). Phase G six-seam decision audit written to research/SEAMS.md using existing B/C/D/G measurements. Added a static caveat that bare CanonCond confirmation/fusion does not carry the surrounding ctUniverse; the whole-DRS exporter avoids losing binding scope. No new claim of a production exploit or corpus domain-policy improvement is made. Initial cache snapshot15 ProverQA records contained3 direct bound sortals,0 ProofWriter; only gold-free structures inspected.

### 2026-10-14 01:40 UTC — graph runner hardening prediction
Code review found a binary-label prompt bug (Pronto false incorrectly also described as neither), missing legacy ProofWriter label adapter, and translation schema accepting model provenance. Before fixes, extend tests for binary labels, strict duplicate/provenance rejection, retained-scope alignment, and explicit abstain/translation routing; predict these expose failures. Exact command: `research/.venv/bin/python -m unittest discover -s bench/reasoning -p test_llm.py > research/runs/phase-e-baselines/llm-hardening-red.log 2>&1`. F raw scored63/64 strict=lenient, sole factive Conflict→WeakOnly; family conjunction/cycles/rules each8/8 falsifies predicted main weaknesses. No model calls in hardening.

### 2026-10-14 01:40 UTC — graph hardening green prediction
Hardening red21tests exposed binary-label wording, accepting model provenance, and absent explicit fallback API (2failures/1error). Fixed these and duplicate-key validation; ProofWriter legacy labels covered. Prediction:22tests pass, and regenerated first Prover prompt preserves prior premises/residuals while adding query-reading counts. Commands: `research/.venv/bin/python -m unittest discover -s bench/reasoning -p test_llm.py > research/runs/phase-e-baselines/llm-hardening-green.log 2>&1`; `research/.venv/bin/python bench/reasoning/llm.py prepare --bench proverqa --parses research/runs/phase-d/parses-default.jsonl --backend z3 --or-semantics proverqa --limit 1 --output research/runs/phase-e-baselines/proverqa-graph-prompt-pilot.jsonl`. No model calls.

## 2026-10-14 — graph capability gate result

All four gates passed on the graph-capability-gate run:1138 Haskell checks in11
suites,19 negative oracle clients and2 positive clients, all Explain checks. The
isolated gate change adds the already-rejected GenealogyVerdict regression so a
bare Verdict can never substitute for a sealed Confirmed witness. Prediction held;
this strengthens the gate and changes no production behavior. This gate-only
checkpoint follows abf7364; solver audit fixes and Phase F remain unstaged.
