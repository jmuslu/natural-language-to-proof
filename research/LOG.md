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

## 2026-10-14 — solver audit green prediction

The cubic-join regression failed as predicted (0.983s for10ms). Added explicit
condition-object validation and cooperative Horn budget checks inside joins, head
emission and support minimization;100000-entry intermediate caps return resource-
limit. Exact Haskell support algebra is unchanged; Python never truncates a label
and answers from it. Prediction: all solver, runner and domain checks pass, with
the10ms regression finishing below the generous250ms scheduler allowance. Command:
`research/.venv/bin/python -m unittest discover -s bench/reasoning -p 'test_*.py' -v > research/runs/d-audit-green.log 2>&1`.

### 2026-10-14 01:42 UTC — hybrid control identity prediction
Before final source freeze, check that distinct hybrid policies have distinct config hashes and that cross-sentence existential repair is rejected while shadowed implication scopes stay distinct. Predict current hybrid hash test fails (it copies routed row hash); scope controls should pass. Exact command: `research/.venv/bin/python -m unittest discover -s bench/reasoning -p test_llm.py > research/runs/phase-e-baselines/llm-identity-red.log 2>&1`.

### 2026-10-14 01:42 UTC — hybrid identity green prediction
25tests: only predicted policy/config collision failed; cross-sentence repair rejection and shadowed bindings passed. Hybrid now hashes both source configs, fallback and implementation, with explicit domain_policy=strict in E configs. Prediction: same25tests pass. Exact command: `research/.venv/bin/python -m unittest discover -s bench/reasoning -p test_llm.py > research/runs/phase-e-baselines/llm-identity-green.log 2>&1`. Root solver fix green; awaiting independent audit clearance before the authorized fixed12 pilots.

## 2026-10-14 — D runner integration prediction

Solver audits now green:79 Python tests total including current LLM/domain tests.
Before integrating the explicit ProofWriter domain adapter, two runner regressions
require wrong-benchmark refusal plus logged normalization, and binary ProntoQA
Unknown to remain abstention rather than count an off-label Uncertain as answered.
Prediction: both fail before wiring. Command:
`research/.venv/bin/python -m unittest discover -s bench/reasoning -p test_runner.py -v > research/runs/d-runner-red.log 2>&1`.
Also recording completed pilot12 result: all backends/policies returned0/12 coverage;
Horn top6 unsupported query+6 incomplete query, Z3 top6 partial theory+6 incomplete
query; non-top9 reading-cap+3 disagreement. Ranking thresholds add no coverage.
This operational prefix supports no whole-benchmark accuracy claim.

Runner integration red:2 failures as predicted. Wired opt-in normalization with
benchmark guard and per-variant decisions; recorded domain source hash and request
hash in B/matrix rows for exact B/C joining. Binary logical Unknown now abstains.
Prediction: all Python tests green; new cabal retraction executable builds and
passes5 production graph checks. Commands:
`research/.venv/bin/python -m unittest discover -s bench/reasoning -p 'test_*.py' -v > research/runs/d-runner-green.log 2>&1`
`cabal build nl2proof-retraction-bench > research/runs/f-cabal-build.log 2>&1`
`RETRACTION_BENCH_BIN="$(cabal list-bin nl2proof-retraction-bench)" research/.venv/bin/python -m unittest discover -s bench/retraction -p 'test_*.py' -v > research/runs/f-cabal-tests.log 2>&1`.

### 2026-10-14 01:43 UTC — translator context scope prediction
Independent strength audit found translation_prompt omitted the enclosing universe for retained parser roots. This cannot authorize model refs across scopes (validator closes each translation), but loses meaning in the supplied context. Prediction: new retained-universe prompt test fails. Command: `research/.venv/bin/python -m unittest discover -s bench/reasoning -p test_llm.py > research/runs/phase-e-baselines/llm-universe-red.log 2>&1`.

### 2026-10-14 01:43 UTC — translator universe green prediction
New test failed as expected with missing retained_universe. Added explicit root universe to translation payload. Prediction:26tests green, command `research/.venv/bin/python -m unittest discover -s bench/reasoning -p test_llm.py > research/runs/phase-e-baselines/llm-universe-green.log 2>&1`.

### 2026-10-14 01:44 UTC — scoped CanonCond countermodel prediction

Prediction: separately canonicalized existential documents lose their local witness environment at the bare-condition confirmation/fusion interface. A hand finite model with P(a), not P(b), and false zero-arity q satisfies both `exists x.P(x)` and `exists y.(P(y) implies q)`. Truth-computing document-local oracles with assignments r0=a and r0=b will each confirm their own condition, but fusing those tokens will detach false q after both local refs become r0. Joint canonicalization (r0/r1), rigid constants, and an oracle rejecting open conditions should block the path. This is an interface scope counterexample, not a claim that the current ground external-receipt oracle is affected. Production source unchanged.

Exact command: `runghc -isrc research/probe-claim-scope.hs > research/runs/phase-g/claim-scope.log 2>&1`.

### LLM-audit0 prediction — prompt isolation and unknown retry cost, 2026-10-14

Read-only audit of llm.py/test_llm.py. No additional gold-flow or lexical-scope
blocker found. The missing B request_hash is already being repaired by root; no
duplicate repro. Inventory corrected translation-prompt universe omission during
review. Prediction for mock-only probe: gold sentinel absent from both prompts;
external context reference in a translated query rejected; one successful mock
attempt with `usage=None` currently marked total_attempt_usage_known=True, which
should instead be unknown. No real model call and no production edits. Command:

```
research/.venv/bin/python research/runs/solver-audit/llm_audit.py > research/runs/solver-audit/llm_audit.log 2>&1
```

### 2026-10-14 01:44 UTC — usage completeness metadata prediction
Independent audit found first-attempt success with missing usage is incorrectly marked total_attempt_usage_known. Predict new mocked missing-usage test fails; exact command `research/.venv/bin/python -m unittest discover -s bench/reasoning -p test_llm.py > research/runs/phase-e-baselines/llm-usage-red.log 2>&1`. No model calls; no other pilot blocker found.

### 2026-10-14 01:44 UTC — usage completeness green prediction
Missing-usage regression failed as predicted; corrected known-cost flag to require reported numeric input/output usage and firstattempt. Record per-item graph preparation and cached-parser latency separately from model latency; no invented retry totals. Prediction:27tests pass. Command `research/.venv/bin/python -m unittest discover -s bench/reasoning -p test_llm.py > research/runs/phase-e-baselines/llm-usage-green.log 2>&1`.

### 2026-10-14 01:44 UTC — paired hybrid label-integrity prediction
Root review requests scored hybrid rows reject mismatching labels even with identical gold-free request hashes. Predict added test fails. Command `research/.venv/bin/python -m unittest discover -s bench/reasoning -p test_llm.py > research/runs/phase-e-baselines/llm-label-red.log 2>&1`.

### 2026-10-14 01:44 UTC — hybrid scored-label green prediction
Scored-label test failed as expected; added label integrity check after gold-free request identity, labels never enter model prompt. Prediction28tests pass; `research/.venv/bin/python -m unittest discover -s bench/reasoning -p test_llm.py > research/runs/phase-e-baselines/llm-label-green.log 2>&1`.

### 2026-10-14 01:45 UTC — Phase E fixed12 C/translation pilot predictions
Independent audit clear;28semantic/isolation/routing tests green. Root approved fixed first12 Prover IDs on sealed cache. Prediction C outputs12 valid labels without tools; graph may underperform raw because first selected parses include wrong meanings (e.g. settles down analyzed as a universal rule and reflexive treated as noun), which remain exposed without hand correction. Translation may yield at least9/12 schema-valid responses but cannot repair retained wrong parses; expect much higher output cost than raw baseline and remaining residuals/abstentions. Pilots are operational/exploratory and excluded from main120 cost/accuracy condition; future full120 uses distinct cache/config. No labels/gold enter request projections.
Commands:
`research/.venv/bin/python bench/reasoning/llm.py call --bench proverqa --parses research/runs/phase-d/proverqa-pilot12.jsonl --backend z3 --or-semantics proverqa --limit 12 --mode graph --output research/runs/phase-e-baselines/proverqa-c-pilot12-raw.jsonl > research/runs/phase-e-baselines/proverqa-c-pilot12.log 2>&1`
`research/.venv/bin/python bench/reasoning/llm.py call --bench proverqa --parses research/runs/phase-d/proverqa-pilot12.jsonl --backend z3 --or-semantics proverqa --limit 12 --mode translate --output research/runs/phase-e-baselines/proverqa-translate-pilot12-raw.jsonl > research/runs/phase-e-baselines/proverqa-translate-pilot12.log 2>&1`
Each condition sequential, total2 concurrent Codex calls; stop on first operational/tool error (common.call retries internally3; final-attempt usage limitation explicitly recorded). Source hashes: {'bench/reasoning/llm.py': '7038764db1b669e251b7fef4eac0094d369ef9cfe8782a342f0c1663e740deff', 'bench/reasoning/run.py': '3ad4f0a163a046ed0e1e8764084f769937ac6d42dbed1e4d31badf6a6fbeccab', 'bench/reasoning/solver.py': 'eab61f2f3f830be69fa120b4417add5d41140e3a930640e296fdb3c5edb9aebb', 'research/runs/phase-d/proverqa-pilot12.jsonl': 'a3f97e6bd487aef0bdeaa0ba7f801bf978efed65fd404de771925a6b7c93077b'}

### 2026-10-14 01:47 UTC — scoped condition oracle regression RED prediction

The countermodel reproduced exactly: all nine probe checks passed, including false q derived from two true separately scoped documents. The existing external receipt oracle accepts rigid run IDs, so this demonstrates the reusable API hazard rather than an observed receipt failure. Root authorized a minimal closed-condition boundary at Oracle.check/covers, keeping contextual claims extracted for inspection. Prediction: new scope-oracle checks fail on open predicates, misplaced binders, coverage and genealogy; closed quantified/negative/attitude conditions should already inspect successfully. The last partial-oracle regression may terminate the old implementation when it wrongly consults an oracle on an open condition.

Exact command: `runghc -isrc -itest test/ScopeOracleSpec.hs > research/runs/phase-g/scope-oracle-red.log 2>&1`.

## 2026-10-14 — real ProverQA meaning diagnosis prediction

The first graph prompt exposes Abdullahlike proper names as noun restrictions and
phrasal/reflexive expressions as unrelated predicates. Prediction: Explain first
diverges at lexical category/meaning selection (bare N→NP universal coercion),
not in the Python solver. Diagnostic sentences are `Abdullah settles down.`,
`Abdullah does not express himself freely.`, and a rigid/simple `Bob is red.`
control. Run one persistent already-built Explain process with --all-readings,
all stages, through `python3 research/runs/prover-meaning-audit/run.py`; output
`research/runs/prover-meaning-audit/explain.log`. No benchmark labels supplied.

### 2026-10-14 01:51 UTC — closed-condition oracle GREEN prediction

Red result: all13 open-condition regressions failed, ten closed controls plus two structural/quantified controls passed, genealogy/coverage failed, then the partial oracle was incorrectly forced. Implemented scope-aware freeCanonRefs in Canonical and central closed-condition guard in Oracle.covers/check (coverage uses covers too). Antecedent binders extend into the consequent; disjunction/negation bindings do not escape. Existing contextual claim extraction stays intact. Kept the existential anaphora e2e fixture with expected abstention and added a rigid positive control. Countermodel probe now expects admission blocked while still checking that both full documents and honest local oracle predicates are true. Prediction:28 scope checks,10 countermodel checks and existing substrate/assertion/intensional/strength suites pass; any other assumptions about open oracle inputs will surface explicitly.

Exact commands: `runghc -isrc -itest test/ScopeOracleSpec.hs > research/runs/phase-g/scope-oracle-green.log 2>&1`; `runghc -isrc research/probe-claim-scope.hs > research/runs/phase-g/claim-scope-green.log 2>&1`; `runghc -isrc -itest test/SubstrateSpec.hs > research/runs/phase-g/substrate-scope.log 2>&1`; `runghc -isrc -itest test/AssertionSpec.hs > research/runs/phase-g/assertion-scope.log 2>&1`; `runghc -isrc -itest test/IntensionalSpec.hs > research/runs/phase-g/intensional-scope.log 2>&1`; `runghc -isrc -itest test/StrengthSpec.hs > research/runs/phase-g/strength-scope.log 2>&1`.

### 2026-10-14 01:46 UTC — partial translation pilot structural check prediction
First completed translation response is available. Before inspecting its content, predict it validates strict schema and freshening but may leave unsupported sentences unresolved; no gold/labels used. Exact command `research/.venv/bin/python research/runs/phase-e-baselines/check_translation_pilot.py > research/runs/phase-e-baselines/translation-pilot-interim.json`. Script validates each currently completed raw response against sealed corresponding parser/request graph and reports only counts/reasons/usage, not benchmark gold.

### 2026-10-14 01:47 UTC — C fixed12 pilot scoring prediction
C completed12 responses, allfirstattempt/noerrors/tools. Before joining gold, predict12validlabels and no clear gain over raw due sparse/wrong parses. Translation remainsactive (first3completed). Exact command: `research/.venv/bin/python bench/reasoning/llm.py score --bench proverqa --parses research/runs/phase-d/proverqa-pilot12.jsonl --backend z3 --or-semantics proverqa --limit 12 --mode graph --raw research/runs/phase-e-baselines/proverqa-c-pilot12-raw.jsonl --output research/runs/phase-e-baselines/proverqa-c-pilot12-scored.jsonl > research/runs/phase-e-baselines/proverqa-c-pilot12-summary.json`. These are operational/exploratory pilot metrics, not main paired120 conclusions.

### E-report0 prediction — heterogeneous results analysis tests first, 2026-10-14

Add a reproducible manifest-driven analysis tool, reusing existing Wilson and exact
paired statistics. Predictions/tests cover legacy ProofWriter Boolean labels and
Unknown spelling; strict/lenient differences; errors/tools; translation JSON versus
stored inference; gold/request identity; pending versus attempted items; duplicate
IDs; exact paired discordance; retry unknown cost; cached/reasoning subsets; zero
LLM cost on B routes; missing usage. Before implementation, expect import failure.
No model calls or inference inputs are changed. Command:

```
research/.venv/bin/python -m unittest discover -s bench/reasoning -p 'test_report.py' > research/runs/solver-audit/report-red.log 2>&1
```

### 2026-10-14 01:55 UTC — scoped oracle result and final targeted controls

The initial green run passed28/28 scope checks,10/10 countermodel controls,115/115 substrate checks,57/57 assertion and97/97 intensional checks. Independent read-only audit found no binder escape: antecedent-to-consequent scope is preserved, other branch/local binders do not escape, and closed token admission plus Fusion's empty-universe detachment condition blocks the counterexample. Added two direct suite controls to retain actual cross-document fusion rejection and positive token creation for every closed non-presupposed fixture. Prediction: all30 scope checks pass; no production behavior changed after the preceding green run. Strength's antichain checks are still running in the separately logged run.

Exact command: `runghc -isrc -itest test/ScopeOracleSpec.hs > research/runs/phase-g/scope-oracle-final.log 2>&1`.

## 2026-10-14 — scoped-admission and D/F integration gates prediction

Scope closure repair passes focused controls; Haskell sources are now stable.
Prediction: all prior1138 Haskell checks remain (one existential oracle expectation
becomes explicit abstention), one rigid substrate control plus30 scope checks give
1169 checks over12 suites. The19-negative/2-positive oracle gate and Explain pass.
F executable and independent Python tests are additionally validated. Command:
`bash research/run-gates.sh scoped-reasoning > research/runs/scoped-reasoning-driver.log 2>&1`.

### 2026-10-14 01:58 UTC — closed-condition oracle final targeted result

ScopeOracleSpec passes30/30 after the two extra integration controls. The standalone honest countermodel regression passes10/10. Substrate115/115, Assertion57/57 and Intensional97/97 pass; production sources are stable for the root integration gates. STUDY_PLAN, STRENGTH and SEAMS now distinguish structural assertion witnesses from closed standalone propositions and state the intentional existential-claim abstention. No DRS parser/export behavior was changed. Independent audit confirms the binder scope rules and notes that differing canonical numbering of closed formulas may miss deduplication but does not extrude a free witness.

### E-report0 result and E-report1 prediction, 2026-10-14

Tests failed as expected at missing report import. Implemented manifest-driven
normalization/cost/reporting with benchmark-specific parsers and reused paired and
Wilson helpers. Prediction: all12 new tests pass; pending runs withhold paired
claims, duplicate or mismatched identities reject, and retry costs remain unknown.

```
research/.venv/bin/python -m unittest discover -s bench/reasoning -p 'test_report.py' > research/runs/solver-audit/report-tests.log 2>&1
```

### 2026-10-14 02:00 UTC — duplicate interpreted Strength run superseded

Stopped the redundant interpreted `runghc -isrc -itest test/StrengthSpec.hs` process during its exhaustive graph/antichain tail at root request. All printed checks were green; this is cancellation, not a failed test result. Root's mandatory optimized integration gate now runs the same complete suite and supersedes this incomplete duplicate. Final scope-case read-only review found all Condition constructors represented: pred/equality, not, imp antecedent/consequent, independent or branches, attitude holder/body and presupposition. Nested negative sibling leakage and reverse implication binding have explicit negative controls.

## 2026-10-14 — Explain diagnosis result

Prediction held, with a more specific lexical failure: the selected reading of
`Abdullah settles down.` uses Abdullah:N/N, settles:N and down:S[adj]\NP; bare-
noun universal coercion yields ∀x.(abdullah(x)∧settles(x)→down(x)). Two other
returned readings still treat down as an argument noun. The reflexive/adverbial
query similarly becomes an unintended quantified object. The simple Bob control
parses correctly. Therefore solver upgrades alone cannot establish English meaning
fidelity. The cached original parses and experimental policy are retained unchanged,
not hand-corrected using labels. Diagnostic run completed successfully.

### 2026-10-14 01:49 UTC — ProverQA main C120 prediction
C pilot12 is operationally valid (12labels,zeroerrors/tools,7correct); root authorizes main120 now while translation pilot finishes. Policy and prompt unchanged. Updated prediction before full labels: C may trail raw A90/120 because known lexical meaning errors and sparse parsing are supplied as graph premises; query-specific proof is explicitly disclosed, not oracle grounding. Main uses sealed complete first120 cache and a fresh condition/config; earlier12 are excluded as operational pilot. Command: `research/.venv/bin/python bench/reasoning/llm.py call --bench proverqa --parses research/runs/phase-d/proverqa-default120.jsonl --backend z3 --or-semantics proverqa --limit 120 --mode graph --output research/runs/phase-e-baselines/proverqa-c120-raw.jsonl > research/runs/phase-e-baselines/proverqa-c120.log 2>&1`. This condition sequential plus translation sequential =2concurrent calls. Final retryusage limitations and all code/prompt/cache hashes recorded in rows.

## 2026-10-14 — full ProverQA B matrix prediction

Sealed the first120 complete default parser records in sample order into
research/runs/phase-d/proverqa-default120.jsonl; the source stream had137records,
so no partial line was included. Prediction: both backends have low (<20%)
coverage, non-top further loses answers to combination caps, exclusive-or helps
only where lexical scope is accepted. Fixed thresholds should mostly abstain
because product masses shrink on multi-sentence theories. Command:
`research/.venv/bin/python bench/reasoning/matrix.py --parses research/runs/phase-d/proverqa-default120.jsonl --out-dir research/runs/phase-d/proverqa-default-matrix --benches proverqa --limit 120 --timeout-ms 2000 > research/runs/phase-d/proverqa-default-matrix.log 2>&1`.

### 2026-10-14 01:50 UTC — main C120 setup retry
Initial setup returned FileNotFoundError before any model call: sealed-cache readiness message preceded completion of decoding/writing. Root clarified matrix-log creation is completion marker; it now exists beside sealed120cache. Prediction/protocol unchanged; rerun exact command `research/.venv/bin/python bench/reasoning/llm.py call --bench proverqa --parses research/runs/phase-d/proverqa-default120.jsonl --backend z3 --or-semantics proverqa --limit 120 --mode graph --output research/runs/phase-e-baselines/proverqa-c120-raw.jsonl > research/runs/phase-e-baselines/proverqa-c120.log 2>&1`. Setupfailure costzero.

### E-report1 result and E-report2 prediction, 2026-10-14

All12 analysis tests pass. Root requests descriptive observed-top-mass curves:
these rank already-saved predictions by their uncalibrated mass within returned
readings, retaining ties and unanswered cases without choosing a threshold. Add
controls for ties, missing/out-of-range mass, and no answered predictions; expected
red import failure before implementation. Also require absent usage aggregates to
remain null instead of zero, and malformed usage to remain unknown. These are
analysis-only checks; no inference inputs or policy thresholds change.

```
research/.venv/bin/python -m unittest discover -s bench/reasoning -p 'test_report.py' > research/runs/solver-audit/report-curve-red.log 2>&1
```

### 2026-10-14 02:05 UTC — first five real ProofWriter domain-policy prediction

The default cache has reached ProofWriter. Fixed selection: the first five complete newline-terminated cache rows with the source-ID segment `-OWA-D5-`, preserving cache order. The sample adapter keeps original theory/question IDs; other benchmarks use their own named prefixes. No sample rows, labels or gold formulas are read by this probe. Prediction: at least one top theory contains a localized positive bound person/thing guard eligible for the explicit policy; some strict Unknown outcomes may become signed proofs, while parse/query incompleteness remains unchanged. The adapter may have no effect when guards lack localized provenance or the retained rules are outside its fragment. Both Horn and Z3 use the same top returned meaning and 2000ms limit. Report transitions and decisions only, never accuracy.

Exact command: `research/.venv/bin/python research/probe-domain-policy.py research/runs/phase-d/parses-default.jsonl --limit 5 > research/runs/phase-g/domain-cache-default-first5.log 2>&1`.

### E-report2 red result and green prediction, 2026-10-14

New tests fail at the missing risk_coverage import as expected. Added curves at all
unique valid observed masses, preserving ties and the selected-sample denominator;
none can restore already-abstained answers. Added inverted Wilson intervals for
selective risk, explicit descriptive/uncalibrated wording, dependency hashes, and
null/unknown aggregates for absent or malformed token usage. Prediction:16tests pass.

```
research/.venv/bin/python -m unittest discover -s bench/reasoning -p 'test_report.py' > research/runs/solver-audit/report-curve-tests.log 2>&1
```

### E-report2 result and E-report3 saved-output analysis prediction, 2026-10-14

All16 analysis tests pass. Analyze four complete baseline pairs and the operational
ProverQA C pilot12 only. Prediction: strict fresh low scores reproduce90/120 Prover,
92/120 FOLIO,116/120 ProntoQA; historical PW low119/120, fresh Prover high89/120,
pilot C7/12. Historical runs remain explicitly marked and pilot results excluded
from main conclusions. No thresholds are tuned, and no inference/model calls occur.
Create manifests from these declared paths, then run each through report.py; this
also verifies actual legacy/schema compatibility and identical selected IDs.

```
research/.venv/bin/python research/runs/phase-e-reports/run-initial.py > research/runs/phase-e-reports/initial.log 2>&1
```

### 2026-10-14 01:51 UTC — first five real ProofWriter domain-policy result

The fixed first5 completed default-parser ProofWriter records contain24 direct bound sortals, all24 eligible from exact localized quantifier cues. Every top theory is partial. Both Horn and Z3 abstain on all5 under strict semantics. With the explicit ProofWriter policy, both still abstain4 and prove False for AttNoneg-OWA-D5-283-Q4. This is a gold-free answer transition only, not an accuracy result. The successful prediction was guard applicability; no complete Unknown case was present in this tiny prefix. Driver research/probe-domain-policy.py and raw research/runs/phase-g/domain-cache-default-first5.log preserve the selection and commands. SEAMS records the result.

Timestamp correction: several preceding scope-audit headings used manually entered minute labels ahead of the actual clock (01:47 through02:05). The append order and prediction-before-command order are unchanged. Filesystem completion times were scope red01:45:25, initial scope green01:46:12, final30-check scope01:47:43, and first5 domain probe01:51:19 UTC. Future headings use the system clock automatically.

## 2026-10-14 — primary B/D policy before full-matrix results

Primary B and routed D use top reading, strict domain semantics, ProverQA Z3 with
localized exclusive either/or, FOLIO Z3 inclusive, and ProofWriter/ProntoQA signed
Horn inclusive. D takes any non-abstain B output, otherwise the unchanged C row.
Here operational confidence means the solver accepted its premises/query and
answer policy, not calibrated English correctness or oracle evidence. All other
reading/backend/POS/domain choices are reported as secondary conditions; no
maximum-accuracy selection defines the main result. Full Prover matrix is still
running; this choice follows the fragments, not scored outcomes.

The first cache seal announcement preceded asynchronous completion and caused one
C setup FileNotFoundError before any model call. It was retried after the completed
file/matrix-start marker. New `research/seal-parser-cache.py` writes a temporary
file and atomically renames only after all expected IDs/input hashes are validated.
Commands sealing the next caches (no new inference):
`python3 research/seal-parser-cache.py research/runs/phase-d/parses-pos.jsonl proverqa research/runs/phase-d/proverqa-pos120.jsonl`
`python3 research/seal-parser-cache.py research/runs/phase-d/parses-default.jsonl folio research/runs/phase-d/folio-default120.jsonl`.

### E-report3 result and primary policy record, 2026-10-14

All five saved-output reports complete and match predicted strict counts; strict
and lenient agree throughout, with120/120 answered on each full raw baseline.
Prover low90 versus historical high90 has3discordances each direction (exact
paired p=1); versus current high89 has4low-only/3high-only (p=1). FOLIO low92
versus historical high99 has1low-only/8high-only (p=.0390625, unadjusted exploratory,
with historical run confounding). Pronto low116/high120 has0/4 (p=.125); historical
PW119/120 has0/1 (p=1). Pilot C7/12 versus low9/12 has2/0 (p=.5), excluded main.
Outputs and source manifests: research/runs/phase-e-reports/*-report.json and
*-manifest.json. All these rows report one attempt and token usage; old raw rows
lack request hashes and therefore have only ID/label identity verification.

Root has prespecified main B/D before the full matrix results: top reading and
strict domain throughout; Z3/proverqa disjunction for ProverQA, Z3/inclusive for
FOLIO, Horn/inclusive for ProofWriter and ProntoQA. D uses B's nonabstaining answer,
otherwise C. Solver acceptance is operational admission, not English meaning
truth. All other matrix policies and the ProofWriter adapter are secondary; none
will be selected by best score. Reports may describe observed mass curves, but
cannot tune or choose a threshold.

### 2026-10-14 01:53 UTC — pinned plotting dependency prediction

Matplotlib is absent from research/.venv (Python3.12.3). Install only pinned Matplotlib3.10.7 in this existing research environment, recording resolved versions for reproducibility. Prediction: installation succeeds without system-package changes; SVG/PDF generation will use its noninteractive Agg backend. No benchmark results are plotted until complete default/POS matrix reports arrive.

Exact command: `research/.venv/bin/python -m pip install matplotlib==3.10.7 > research/runs/phase-g/plotting-install.log 2>&1`.

### E-report4 coverage-interval prediction, 2026-10-14

Inspection found run.summarize supplies Wilson intervals for accuracy/precision but
not coverage. Add a separate analysis helper retaining those counts and adding a
coverage interval over the full selected denominator. A four-row, two-answered,
one-correct fixture must distinguish coverage .5, precision .5 and accuracy .25;
its coverage interval should be approximately [.15004,.84996]. Expected red before
the helper exists. Also expose descriptive route/reason/strength counts for D
reporting, without changing inference.

```
research/.venv/bin/python -m unittest discover -s bench/reasoning -p 'test_report.py' > research/runs/solver-audit/report-coverage-red.log 2>&1
```

## 2026-10-14 — integration results and checkpoint prediction

scoped-reasoning full gates passed:12 Haskell suites,19 oracle rejection clients
and2 positive clients, all Explain checks. Expected1169 assertions: previous1138
plus30 scope controls and one rigid substrate control. Focused retraction executable
tests passed5/5. Before committing the stable scope/D/F/G integration, rerun the
committed Python solver/runner/domain/report suites (LLM experimental files are
kept unstaged while their calls retain frozen source hashes). Prediction75/75.
Command:
`research/.venv/bin/python -m unittest discover -s bench/reasoning -p 'test_*.py' -v > research/runs/scoped-python-all.log 2>&1`.
The all-files working-tree run also includes28 experimental LLM tests, so expects
103 total. No inference source changes accompany this verification.

### E-report4 red result and green prediction, 2026-10-14

The new import fails as expected. Coverage now gets its own Wilson interval, and
saved route/reason/strength counts are exposed for interpretation. Prediction:
all17 tests pass, and rerunning saved-output reports changes only those added
fields and implementation hashes; all scores, cost counts and paired tests persist.

```
research/.venv/bin/python -m unittest discover -s bench/reasoning -p 'test_report.py' > research/runs/solver-audit/report-coverage-tests.log 2>&1
research/.venv/bin/python research/runs/phase-e-reports/run-initial.py > research/runs/phase-e-reports/initial-final.log 2>&1
```

### E-report4 result, 2026-10-14

All17 report tests pass. Regenerated baseline/pilot reports preserve every score
and paired count; coverage intervals and descriptive route/reason/strength counts
are now included. Root's concurrent checkpoint briefly observed the intentional
red import window before this green run; that is resolved. Report/test sources
are frozen for the checkpoint. No model calls were made by this analysis work.

### 2026-10-14 01:54 UTC — FOLIO main C120 prediction
Root sealed complete default FOLIO120 and authorizes graph condition with existing fixed policy; no observed errors/tools on active calls. Prediction C may not exceed raw A92/120 because broader English leaves residuals and accepted wrong readings; expect fewer useful query proofs than controlled synthetic text. No prompt tuning based on pilot labels. Command `research/.venv/bin/python bench/reasoning/llm.py call --bench folio --parses research/runs/phase-d/folio-default120.jsonl --backend z3 --or-semantics inclusive --limit 120 --mode graph --output research/runs/phase-e-baselines/folio-c120-raw.jsonl > research/runs/phase-e-baselines/folio-c120.log 2>&1`. Three sequential conditions concurrent at most3CLIcalls (ProverC,FOLIOC,translationpilot). Current code hashes frozen until these conditions scored.

## 2026-10-14 — owner correction: primary weak/strong contrast

Owner overrides the original Gemini quota note: small models have usable free
quota and complete raw120 baselines. Primary C/D must use gemini-3.1-flash-lite
(budget0) and gemma-4-26b-a4b-it (minimal), compared paired against each own raw
baseline and GPT-5.5 high. GPT low/high is only an effort control; no model-strength
claim will use it. Stop further GPT graph collection, preserve completed exploratory
rows, and adapt the existing Gemini runner with throttle/backoff429 and explicit
quota-failure logging. Key will only be sourced within the requesting process;
never read, print or store it in artifacts. STATE updated before continuing.

### 2026-10-14 01:55 UTC — USER model steering; stop GPT graph main conditions
User specifies primary weak models gemini-3.1-flash-lite/budget0 and gemma-4-26b-a4b-it/minimal via common/run_gemini.py; earlier quota assumption was wrong. Stopped own GPT Prover/FOLIO runner process trees with SIGTERM and preserve completed partial rows as exploratory; in-flight unfinished calls may have unreported cost. Translationpilot finished12 and will score under preserved original source before provider changes. Snapshots llm.py/run.py/solver.py saved under ignored research/runs/phase-e-baselines/gpt-code-snapshot. No key file read or key printed; future provider process will source owner envfile before import.

## 2026-10-14 — checkpoint verification concurrency correction

The all-files Python run caught a concurrent test-first report edit: the new
coverage-interval test imported score_summary before its implementation landed.
This was one import error (88 tests), not an inference failure; the agent completed
that addition and reports17/17. The owner has meanwhile redirected the active
LLM harness to real small-model C/D; those unfinished files remain unstaged.
Prediction: the stable checkpoint's76 Python tests pass. Exact command:
`PYTHONPATH=bench/reasoning research/.venv/bin/python -m unittest test_solver test_runner test_domain test_report -v > research/runs/scoped-python-committed.log 2>&1`.

### 2026-10-14 01:55 UTC — preserved GPT exploratory conditions scoring prediction
Stopped GPT Prover main after25completedrows, FOLIO after3; bothzeroerrors/tools, one in-flight call each mayhaveunreportedcost. Translationpilot12complete. Beforegoldjoin predict translation has highvalidity butlowcoverage due residuals; GPT Cpartials exploratory only, likely notimprovement. Commands (same frozen implementation):
`research/.venv/bin/python bench/reasoning/llm.py score --bench proverqa --parses research/runs/phase-d/proverqa-pilot12.jsonl --backend z3 --or-semantics proverqa --limit 12 --mode translate --raw research/runs/phase-e-baselines/proverqa-translate-pilot12-raw.jsonl --output research/runs/phase-e-baselines/proverqa-translate-pilot12-scored.jsonl > research/runs/phase-e-baselines/proverqa-translate-pilot12-summary.json`
`research/.venv/bin/python bench/reasoning/llm.py score --bench proverqa --parses research/runs/phase-d/proverqa-default120.jsonl --backend z3 --or-semantics proverqa --limit 25 --mode graph --raw research/runs/phase-e-baselines/proverqa-c120-raw.jsonl --output research/runs/phase-e-baselines/proverqa-c120-scored.jsonl > research/runs/phase-e-baselines/proverqa-c120-summary.json`
`research/.venv/bin/python bench/reasoning/llm.py score --bench folio --parses research/runs/phase-d/folio-default120.jsonl --backend z3 --or-semantics inclusive --limit 3 --mode graph --raw research/runs/phase-e-baselines/folio-c120-raw.jsonl --output research/runs/phase-e-baselines/folio-c120-scored.jsonl > research/runs/phase-e-baselines/folio-c120-summary.json`

### E-primary-small-model reporting correction and prediction, 2026-10-14

The owner clarified the primary weak models: Gemini3.1 Flash-Lite at budget0 and
Gemma4 26B A4B at minimal effort, both through Gemini. GPT5.5 low/high is retained
only as an effort control, not a weak/strong model comparison. Existing raw120
outputs for both requested small models are historical. Prediction: the new
manifest report reproduces supplied ProverQA61/120 and37/120, FOLIO81/120 and77/120;
all fresh C/D conditions remain explicitly pending with no paired claims. Gemini
usage aliases should normalize prompt/candidate tokens, while multi-attempt costs
remain lower bounds. Optional Gemma31B has duplicate retry rows in three benches,
so it is omitted from these primary reports rather than silently deduplicated.
No inference or model calls are performed. Source/test freeze remains in effect.

```
research/.venv/bin/python research/runs/phase-e-reports/run-primary.py > research/runs/phase-e-reports/primary-baselines.log 2>&1
```

Stable checkpoint verification result:76/76 Python checks passed, plus5/5 generated
retraction checks. Full Haskell gates passed1169 checks/12 suites,19 negative+2
positive oracle clients and Explain. This checkpoint integrates the closed-scope
oracle repair, budget/malformed-input solver fixes, optional benchmark domain
adapter, standalone scoring, deterministic F benchmark and G seam probes.
LLM provider adaptation and plotting are intentionally still in progress and
untracked; they will receive their own verified checkpoint. All datasets, caches
and model replies remain local/ignored.

### 2026-10-14 01:55 UTC — plotting smoke and incomplete-report rejection prediction

Pinned Matplotlib3.10.7 installed successfully in research/.venv with resolved versions recorded in research/requirements-figures.txt. New plot-risk-coverage.py consumes report.py JSON only, requires matched complete default/POS matrices and request identities, plots all observed threshold curves for every policy, and annotates zero-answer points without imputing precision. Prediction: a hand-generated24-run plotting fixture writes SVG/PDF in ignored research/runs/figure-smoke; a copy with pending IDs is rejected without a final plot. No real partial benchmark is plotted.

Exact commands: `research/.venv/bin/python research/runs/figure-smoke/make-fixture.py`; `research/.venv/bin/python research/plot-risk-coverage.py research/runs/figure-smoke/report.json --out-dir research/runs/figure-smoke > research/runs/figure-smoke/render.log 2>&1`; `research/.venv/bin/python research/plot-risk-coverage.py research/runs/figure-smoke/incomplete.json --out-dir research/runs/figure-smoke/rejected > research/runs/figure-smoke/reject.log 2>&1`.

### E-primary-small-model baseline result, 2026-10-14

Primary historical raw reports match all supplied strict scores. Format compliance
is a large issue for Gemma26: ProverQA strict37/120 with47 answered, but lenient82/120;
FOLIO77 strict/81 lenient with116 strict answered; ProofWriter60/69 with103 strict
answered; ProntoQA109/109 with120 answered. Flash-Lite is61,81,75,96 respectively
under both parsers with120 answers each. Therefore a strict-score advantage alone
cannot establish improved reasoning; every C/D comparison retains both parsers.
Gemma final-attempt-only retry costs affect7 Prover rows(10retries),5 FOLIO(5),
26 ProofWriter(37),6 ProntoQA(7); Flash-Lite has8 PW retry rows(8). Reports mark
those total costs unknown and keep their reported usage as a lower bound.
C/D zero completed rows are pending, not observed zero accuracy, and paired claims
are withheld. Inventory plans primary files <bench>-flash-lite-c120-scored.jsonl
and <bench>-gemma26b-c120-scored.jsonl under research/runs/phase-e-baselines.
The old GPT C main was interrupted at25 Prover/3 FOLIO records and remains an
exploratory partial run with possible unreported in-flight cost; it is not primary.

### 2026-10-14 01:56 UTC — plotting smoke visual inspection prediction

Synthetic24-run plotting smoke succeeded, producing61KiB SVG and26KiB PDF in ignored output. Re-render the same synthetic chart to a temporary PNG only for visual inspection (final research/figures stays SVG/PDF only). Prediction: all six facets, labels, zero-answer annotations and eight legend styles remain legible with no clipping.

Exact command: `research/.venv/bin/python research/runs/figure-smoke/preview.py > research/runs/figure-smoke/preview.log 2>&1`.

### 2026-10-14 01:57 UTC — plotting smoke result

The synthetic24-run figure rendered successfully (61KiB SVG,26KiB PDF), with60 zero-answer threshold points omitted and explicitly annotated. Visual inspection of the ignored PNG preview confirmed all six facets, labels and legend are legible with no clipping. The deliberately incomplete report exited1 with `incomplete run; refusing a final figure`; no rejected output directory was created. Final figures remain pending complete default/POS matrix reports. No inference code or benchmark predictions changed.

### 2026-10-14 01:57 UTC — Gemini/Gemma provider adapter red prediction
Implement primary user-selected weak models via unchanged common/run_gemini.call, requiring pre-sourced environment before lazyimport (never unit-test with realkey/module). Predictions: new mock-only tests fail for absent provider adapter, provider-specific hashes/usage aliases, DailyQuota stop, and8s scheduling. Also protect PWlenient Unknown normalization while sourceversionchanges for newprimary. Exact command: `research/.venv/bin/python -m unittest discover -s bench/reasoning -p test_llm.py > research/runs/phase-e-baselines/llm-gemini-red.log 2>&1`. No actual Gemini request beforegreen and rootprotocol.

## 2026-10-14 — remaining B matrix predictions

Default/POS caches have passed all ProofWriter records (444/401 total), and the
sealed FOLIO default120 cache is complete. Predict FOLIO remains low coverage with
Z3 at least as expressive as Horn, ProofWriter gains some proof coverage under the
explicit domain policy, and POS improves coverage without proving English fidelity.
Ranking-mass filtering will sacrifice much coverage on ambiguous long theories.
No chosen backend/policy depends on these forthcoming labels. Commands for the
next sequential default batch:
`research/.venv/bin/python bench/reasoning/matrix.py --parses research/runs/phase-d/folio-default120.jsonl --out-dir research/runs/phase-d/folio-default-matrix --benches folio --limit 120 --timeout-ms 2000 > research/runs/phase-d/folio-default-matrix.log 2>&1`
`python3 research/seal-parser-cache.py research/runs/phase-d/parses-default.jsonl proofwriter research/runs/phase-d/proofwriter-default120.jsonl`
`research/.venv/bin/python bench/reasoning/matrix.py --parses research/runs/phase-d/proofwriter-default120.jsonl --out-dir research/runs/phase-d/proofwriter-default-matrix --benches proofwriter --limit 120 --timeout-ms 2000 > research/runs/phase-d/proofwriter-default-matrix.log 2>&1`
`research/.venv/bin/python bench/reasoning/matrix.py --parses research/runs/phase-d/proofwriter-default120.jsonl --out-dir research/runs/phase-d/proofwriter-default-domain-matrix --benches proofwriter --domain-policy proofwriter --limit 120 --timeout-ms 2000 > research/runs/phase-d/proofwriter-default-domain-matrix.log 2>&1`.

### E-provider-usage prediction, 2026-10-14

Primary Google documentation (accessed2026-10-14) defines promptTokenCount as
including cachedContentTokenCount; candidatesTokenCount and thoughtsTokenCount
are separate output counters; totalTokenCount includes prompt, tool-use prompts,
thoughts and candidates. Source: https://ai.google.dev/api/generate-content#UsageMetadata.
Existing report already aliases basic Gemini fields but lacks native-field
aggregates, tool-input accounting and reported-total consistency diagnostics.
Tests will preserve original usage dictionaries, count cache/thoughts exactly once,
retain authoritative reported totals if components disagree, and keep retry totals
unknown. Prediction before fix: basic aliases pass but native counters, tool totals
and inconsistent-total cases fail. No provider calls/key access.

```
research/.venv/bin/python -m unittest discover -s bench/reasoning -p 'test_report.py' > research/runs/solver-audit/report-provider-red.log 2>&1
```

### 2026-10-14 01:57 UTC — Gemini/Gemma adapter green prediction
35tests red with3failures/4errors as predicted. Implemented lazy env-required provider adapter, native usage retention/validity, explicit no-tools API request guard, provider-specific preamble/hash, DailyQuota errorrows with unknownattemptcount,8s startspacing and throttlemetadata, plus PWlenient mapping. Prediction:35mock-only tests pass; exact command `research/.venv/bin/python -m unittest discover -s bench/reasoning -p test_llm.py > research/runs/phase-e-baselines/llm-gemini-green.log 2>&1`. No module import using realkey or network in tests.

### E-provider-usage red result and green prediction, 2026-10-14

Of22 tests,18 pass and four fail at the expected absent fields/ignored native total.
Added visible-output and tool-input counters, raw numeric provider aggregates,
reported versus computed totals, discrepancy IDs, and missing-component counts;
input records remain untouched. Prediction: all22 tests pass. Then refresh saved
baseline reports and compare every empirical Gemini native total with its component
sum; expect equality on ordinary text rows, while retry costs remain incomplete.

```
research/.venv/bin/python -m unittest discover -s bench/reasoning -p 'test_report.py' > research/runs/solver-audit/report-provider-tests.log 2>&1
research/.venv/bin/python research/runs/phase-e-reports/run-primary.py > research/runs/phase-e-reports/primary-provider.log 2>&1
```

### 2026-10-14 01:58 UTC — three answered FOLIO errors: first-divergence audit prediction

Root reports completed default FOLIO Z3 top3/120 answered, all three wrong; policy and inference source remain frozen. Prediction: at least one false proof originates in a well-typed but unfaithful premise/query meaning (scope, lexical role or negation), rather than missing premises alone. A valid proof from faithfully represented accepted premises remains monotonic despite other missing content; missing text cannot by itself excuse a wrong signed proof. Inspect every answered item and its saved proof support, original text, selected lambda forms and complete scoped DRS. Labels are used only for this post-inference diagnosis, never sent to a parser/model or used to change predictions. No new CCG load planned.

Exact command: `research/.venv/bin/python research/runs/phase-g/audit-folio-answers.py > research/runs/phase-g/folio-answered-audit.log 2>&1`.

### 2026-10-14 01:58 UTC — PRIMARY Flash-Lite/Gemma26 fixed12 C pilot predictions
Root authorizes specified primary weak models now;35mocktests green and same reviewed graphprompt. Prediction: bothAPI pilots return12responses with nativeusage/no tools, though Gemma may give non-strict answer formatting (savedrawstrict37/120vslenient82/120). Semantic graph errors may harm both; do not tune based on labels. Pace8s minimum startinterval/model, one sequentialworker/model, two modelsparallel. Ownerkey is only sourced insideexecutionprocess with shelltracingdisabled; nokeyfilecontents/keyoutput requested. Exact commands, each inside `set +x; set -a; source /home/gram/.config/nl2proof/gemini.env; set +a; exec ...`:
`research/.venv/bin/python bench/reasoning/llm.py call --bench proverqa --parses research/runs/phase-d/proverqa-pilot12.jsonl --backend z3 --or-semantics proverqa --limit 12 --mode graph --provider gemini --model gemini-3.1-flash-lite --effort budget0 --pace-seconds 8 --output research/runs/phase-e-baselines/proverqa-flash-lite-c-pilot12-raw.jsonl > research/runs/phase-e-baselines/proverqa-flash-lite-c-pilot12.log 2>&1`
`research/.venv/bin/python bench/reasoning/llm.py call --bench proverqa --parses research/runs/phase-d/proverqa-pilot12.jsonl --backend z3 --or-semantics proverqa --limit 12 --mode graph --provider gemini --model gemma-4-26b-a4b-it --effort minimal --pace-seconds 8 --output research/runs/phase-e-baselines/proverqa-gemma26b-c-pilot12-raw.jsonl > research/runs/phase-e-baselines/proverqa-gemma26b-c-pilot12.log 2>&1`
Firstdailyquota/error stops scheduling; commonAPIcall honors retryDelay and exponentialbackoff on429. Pilots excluded from main120 cost/metrics.

### E-provider-usage result and completed-default-matrix reporting prediction, 2026-10-14

All22 report tests pass. Across960 primary historical Gemini rows (two models ×
four benchmarks ×120), native totalTokenCount agrees with the sum of reported
prompt, candidate, thought and tool-input counters on every row. No input/output
component is missing. Native/provider totals are preserved; multi-attempt costs
remain lower bounds. Missing thoughts fields remain unreported rather than zero.

Root reports completed default ProverQA/FOLIO matrices. Prediction for analysis:
all18 Prover configurations have zero answers, so every observed-mass selective
risk is undefined. FOLIO Horn has no answers; Z3 top/skeptical has3 wrong answers
and credulous1 wrong answer, so nonempty retained subsets have risk1. No threshold
selection occurs. Report all configurations with explicit parser/backend/reading/
domain/disjunction/mass metadata. Do not report the still-running PW matrix yet.

```
research/.venv/bin/python research/runs/phase-e-reports/run-matrix.py --benches proverqa folio --parser-variant default > research/runs/phase-e-reports/default-matrices.log 2>&1
```

### 2026-10-14 01:59 UTC — prospective top-cache projection equivalence prediction
Root observed fullcacheholds~3GB/modelprocess despite Cusingfirst theory/query. Beforechangingloader, predict pruningonlynonfirsttheories/queries preserves exact graph, prompt, promptHash, requestHash and sourcecache/configmetadata for all12sealedpilot records. Allsentence readings/counts, search/truncatedflags preserved. Exact command `research/.venv/bin/python research/runs/phase-e-baselines/check_top_projection.py > research/runs/phase-e-baselines/top-projection-equivalence.json`. No networkcalls; source remainsfrozen until currentpilots scored.

### E-default-matrix report result and primary-manifest update prediction, 2026-10-14

Completed reports include all18 default ProverQA policies and12 FOLIO policies,
with120 validated request hashes per run and no pending items. ProverQA mass is0
for every item because each complete document has at least one unparsed sentence;
all curves therefore have one observed threshold and zero answers. FOLIO observed
masses are0,.5329501403555674,1; all nonempty retained subsets have risk1. Higher
mass does not rescue English correctness on this sample.

Update primary manifests to declared Flash-Lite/Gemma26B C paths and analogous D
paths, add the prespecified B outputs when present, and raw-small versus raw-strong
paired counts. Expected existing A scores unchanged; completed B Prover0/0 and
FOLIO3answered/0correct, PW Horn37answered/22correct; missing C/D remain pending.
The D target names are proposed output paths, not fabricated results. Command:

```
research/.venv/bin/python research/runs/phase-e-reports/run-primary.py > research/runs/phase-e-reports/primary-baselines-with-b.log 2>&1
```

### 2026-10-14 02:00 UTC — FOLIO three-answer audit result

All three first divergences occur in selected lambda semantics, before DRS lowering or solver: folio-val-121 treats Some as predicate some(x), generic-universalizes both premises and query, and Z3 correctly chains the wrong universals (supportp0,p1; True vs Uncertain). folio-val-163 turns never into positive never(x), also universalizes Some and keeps hawk/hawks and lands/land distinct; it returns two-countermodel Unknown vs False. folio-val-15 turns four sides into a generic universally quantified four(y)&sides(y), losing cardinal semantics and the bridge to four-sided; Unknown vs True. All exported pairs complete=true/residuals=[], so structural completeness is not English fidelity. Items121 and15 have mass1, retained by .8/.95 thresholds with zero selective precision. Prediction supported for the signed false proof; the other two wrong answers are incorrect Unknowns from semantic loss. No dataset-noise explanation or new source/policy mutation. SEAMS records bounded exact examples/IDs; primary FINDINGS draft note at research/runs/phase-g/folio-findings-note.md.

### E-primary-manifest B/raw result, 2026-10-14

Updated manifests now resolve completed primary B files and retain planned C/D
paths with pending placeholders. Primary B is0/120 answered on ProverQA,3/120
answered with0 correct on FOLIO,37/120 answered with22 correct on ProofWriter;
ProntoQA remains pending. Raw small/strong paired results expose the scoring
sensitivity: Gemma26 versus current GPT-high on ProverQA has strict discordances
4small-only/56strong-only, but lenient9/16 (exact paired p=.22952). Versus historical
GPT-high the lenient discordances are7/15 (p=.13380). Flash-Lite versus current
GPT-high has8/36 under both parsers (p=.00002545). These remain historical/fresh
and provider/prompt-confounded raw comparisons, not evidence for graph assistance.
Primary C/D paired claims remain withheld while those runs are pending.

### 2026-10-14 02:00 UTC — GPT translation pilot residual diagnosis prediction
Pilot0/12correct with1answered is known; beforeexamining reasoncounts, predict mostabstentionspartialtheory fromuntranslatedsentences, with fewer schema/merge rejections. Exact command `python3 research/runs/phase-e-baselines/summarize_translation.py > research/runs/phase-e-baselines/proverqa-translate-pilot12-diagnosis.json`. This characterizes archivedeffortcontrol, not primaryweak evidence; no prompt changes/no calls.

## 2026-10-14 — default B results and POS/Pronto batch prediction

Default ProverQA completed120: zero answers for both backends, all three reading
policies, inclusive/exclusive disjunction and every fixed mass threshold. Z3top:
73partial-theory,45incomplete-query,2no-reading; non-top89combination-cap,
29disagreement,2no-reading. Predictionlowcoverage held at its limiting case;
no answered precision exists and D routes every item to C. Default FOLIO:
Horn0 answers; Z3top/skeptical3answered0correct; credulous1answered0correct.
The three errors have concrete lexical/quantifier failures, not demonstrated
label noise. Agent is documenting exact bounded cases. Full default cache480
complete; POS469 at last check, through all ProofWriter.

Prediction for remaining defaultPronto and POS: POS may recover queries/theories
but does not repair phrasal/reflexive, some/never/cardinality semantics. Prover
coverage should remain very low. Pronto may gain signed-Horn proofs yet binary
logical Unknown must abstain. Sequential commands in the next batch:
`research/.venv/bin/python bench/reasoning/matrix.py --parses research/runs/phase-d/proverqa-pos120.jsonl --out-dir research/runs/phase-d/proverqa-pos-matrix --benches proverqa --limit 120 --timeout-ms 2000 > research/runs/phase-d/proverqa-pos-matrix.log 2>&1`
For each bench folio,proofwriter,prontoqa: seal with
`python3 research/seal-parser-cache.py research/runs/phase-d/parses-pos.jsonl BENCH research/runs/phase-d/BENCH-pos120.jsonl`, then
`research/.venv/bin/python bench/reasoning/matrix.py --parses research/runs/phase-d/BENCH-pos120.jsonl --out-dir research/runs/phase-d/BENCH-pos-matrix --benches BENCH --limit 120 --timeout-ms 2000 > research/runs/phase-d/BENCH-pos-matrix.log 2>&1`.
Also PW POS domain:
`research/.venv/bin/python bench/reasoning/matrix.py --parses research/runs/phase-d/proofwriter-pos120.jsonl --out-dir research/runs/phase-d/proofwriter-pos-domain-matrix --benches proofwriter --domain-policy proofwriter --limit 120 --timeout-ms 2000 > research/runs/phase-d/proofwriter-pos-domain-matrix.log 2>&1`.
DefaultPronto sealing/matrix uses those same Pronto commands with pos replaced by default.

### 2026-10-14 02:01 UTC — paired plot provenance identity smoke prediction

Completed default report metadata matches the planned schema. Default/POS reports reuse run names, so embedded plot provenance keys now include parser variant to preserve both source hashes and zero-answer counts. Prediction: splitting the synthetic24-run fixture into two12-run reports with identical run names still plots24 conditions and retains24 distinct embedded source identities; no matrix is omitted.

Exact command: `research/.venv/bin/python research/plot-risk-coverage.py research/runs/figure-smoke/default.json research/runs/figure-smoke/pos.json --out-dir research/runs/figure-smoke/paired > research/runs/figure-smoke/paired.log 2>&1`.

### 2026-10-14 02:02 UTC — Flash pilot scoring and Gemma per-minute backoff
Flash12responses complete allfirstattempt/noerrors/tools; observed nativepromptinput5149–24653tokens andoutput2–3tokens. Gemma6complete; item58 required2attempts, item31 returned500 then429InputTokensPerModelPerMinute-FreeTier with44s retryDelay honored bycommonrunner. No dailyquota/reset assumption; no repeatedmanualcalls. Beforegoldjoin predictFlash12strictvalidlabels butsemantic gainuncertain/likelynegative with wrongselectedparses. Exact command `research/.venv/bin/python bench/reasoning/llm.py score --bench proverqa --parses research/runs/phase-d/proverqa-pilot12.jsonl --backend z3 --or-semantics proverqa --limit 12 --mode graph --provider gemini --model gemini-3.1-flash-lite --effort budget0 --pace-seconds 8 --raw research/runs/phase-e-baselines/proverqa-flash-lite-c-pilot12-raw.jsonl --output research/runs/phase-e-baselines/proverqa-flash-lite-c-pilot12-scored.jsonl > research/runs/phase-e-baselines/proverqa-flash-lite-c-pilot12-summary.json`.

### Gemini-adapter independent audit prediction, 2026-10-14

Read-only source review finds the env check precedes lazy common-provider import,
and the provider prompt receives only id/prompt with the Gemini preamble policy.
Prediction for isolated mocks: no environment key causes no provider import or
fallback file read; a dummy environment plus mocked post transmits only the safe
prompt. Two possible operational gaps need reproduction: a429 retryDelay1s causes
an internal2s wait (outer8s pacing does not cover retries); resuming after an error
appends a second row for the same ID, while scoring rejects duplicates. A separate
Horn fixture predicts known p(a), p→q facts yield q(a) through solver.answer but no
C consequences when the English query has no parse. No real credentials are read,
no key is printed, all HTTP calls and sleeps are mocked, no models are called.

```
research/.venv/bin/python research/runs/solver-audit/provider_audit.py > research/runs/solver-audit/provider-audit.log 2>&1
```

## 2026-10-14 — query-independent Horn context regression prediction

Independent C audit finds that an unparsed query suppresses all Horn consequences,
even when its theory has a supported p→q proof. This needlessly removes graph
context from the residual-query fallback. Add a query=None closure-only mode to
the same Horn loop: expose derived facts/supports while always abstaining on the
missing query. No new solver, sentinel predicate or Z3 grounding enumeration.
Prediction: two new regressions fail before the hook (unsupported instead of
closure-only/contradiction); existing query-bearing inference is unchanged. Command:
`PYTHONPATH=bench/reasoning research/.venv/bin/python -m unittest test_solver -v > research/runs/d-queryless-red.log 2>&1`.

Queryless Horn red result: both new tests failed as predicted. The same loop now
accepts query=None to expose closure-only facts while always leaving answer=None;
contradictions/resource limits retain fail-closed behavior. Prediction: all83
solver/runner/domain/report checks pass; query-bearing B semantics unchanged.
Command: `PYTHONPATH=bench/reasoning research/.venv/bin/python -m unittest test_solver test_runner test_domain test_report -v > research/runs/d-queryless-green.log 2>&1`.

### Gemini-adapter independent audit result, 2026-10-14

Mock controls pass for missing-env import rejection, env-only provider import with
fallback-file access forbidden, and actual common-provider payload containing only
the safe prompt without the sentinel gold label. No network calls or credential
file reads occurred. Reproduced:429 retryDelay1s requests a2s internal sleep before
the second post, outside the outer8s pacing; an error row followed by resumed success
creates2 raw rows for1 ID, which the scorer's duplicate guard rejects. Both issues
were sent to root/inventory before main120. The Horn queryless C gap is also
confirmed: C emits no consequences, while the existing solver derives glow(Ada)
from blue(Ada) plus the implication with exact support[p0,p1]. Root is adding a
queryless hook to the same closure implementation; inventory will keep the query
status incomplete while exposing conditional, asserted-unconfirmed consequences.

## 2026-10-14 — owner redirect: constructions and meaning fidelity

Owner overrides phase order: no new benchmark/LLM runs; already-running jobs may
finish and outputs are retained. Construction inventory across generated datasets,
Boxer/ccg2lambda category/template comparison, learner-facing DESIGN, and a
hand-checked per-construction canonical DRS/claim-table gold set now precede more
A/C/D runs. Wrong-but-typed count is the primary metric. Implement general rules
in frequency order without fidelity regressions; C/D stay paused until ProverQA
fidelity is>=90% exact and near-zero wrong-but-typed. Amendment recorded in
ASTRA_GOAL §3 and STATE. Agents redirected to inventory, published design, and
fidelity runner respectively. Existing queued launches are being disabled.

Operational pause: suspended only the batch-parent bashPID124795 (SIGSTOP),
leaving its already-running ProverPOS matrix child124800 active. A watcher will
remove the stopped parent after the child exits, preventing its queued FOLIO/PW/
Pronto matrices from launching. DefaultPronto already-running child124903 continues
to completion. This is queue cancellation, not an inference failure.

### 2026-10-14 02:08 UTC — OWNER redirect: all model work quiescent; linguistic inventory next
Owner pauses new benchmark/LLM runs and prioritizes construction inventory, compiler design and translation fidelity. Allcalls nowfinished/stopped: GPT graphpartials25Prover+3FOLIO archived; GPT translation12complete; Flash primarypilot12complete; Gemma primarypilot12complete, attempts[1,1,2,1,1,1,4,2,2,1,2,2], nofinalerrorrow. LastGemma24,653-input item succeeded afterone429retry, so no15k singlepromptlimit assumption is warranted. Flashstrictpilot1correct/3valid/12; authoritative lenient report requested separately toseparateformatting fromreasoning. Solverhash changed duringGemmapilot forHornclosurehook, so stockhash-strictscore cannotreplay; report.py mayrescore raw labels independently againstsamplewithoutnewinference. No model sessions remainactive; no newkeyaccess.
Known deferred operational repairs: enforce minspacing oncommonGemini internalretries, retainallfailedattemptcost whenresuming into uniqueID resultfiles, and compact repeatednestedprovenance whilepreserving semanticDRS/provenance roots; do notlaunch newpilots ormain120 untilownerresumes experiments. Top-cache prospective pruning equality passed12/12 butproductionloader unchanged. Provideradapter source remains35testsgreen. Datasetmetadata returnedtoroot; exhaustive linguistic split pending.

### Meaning-fidelity harness contract prediction, 2026-10-14

Owner redirects work to linguistic meaning fidelity; new model/benchmark inference
is paused. Root authorizes a gold-free exporter and manual-gold evaluator under
test/fidelity. First contract tests require: gold/request separation, complete scope
and claim-kind equality, preserved duplicates/order, wrong selected versus correct
alternative distinction, separate no-parse/type-failure/incomplete categories,
scoped gold validation, and optional either annotations. Prediction: initial import
fails before implementation. Four authored hand controls will later test actual
pipeline integration; expected gold is written independently, never captured from
parser output or derived with production splitClaims.

```
python3 -m unittest discover -s test/fidelity -p 'test_fidelity.py' > research/runs/solver-audit/fidelity-contract-red.log 2>&1
```

## 2026-10-14T02:11:17.089499+00:00 — ProofWriter exhaustive input inventory prediction

Prediction: the110 local ProofWriter JSONL files will expose a small closed family of controlled forms, plus a substantially more varied NatLang paraphrase layer. Stage/add and depth-extension files duplicate inputs; therefore physical occurrences and global distinct text counts must both be reported, with standard/stage/abduct and CWA/OWA separated. NatLang sentences are the presented surface, not their synthetic triple/rule paraphrases. Read only theory, sentences/mappings, triples/rules text, question/abduction question text and record metadata; never use answer/proof/representation fields to classify constructions. Exclude allInferences, proofDetails, abduction answers. First extract a local SQLite count DB, validate surface reconstruction, then classify unique text and inspect every unresolved family. Exact commands: `python3 research/linguistics/inventory-proofwriter.py extract --root /home/gram/data/proofwriter/proofwriter-dataset-V2020.12.3 --work research/runs/linguistics/proofwriter`; `python3 research/linguistics/inventory-proofwriter.py summarize --work research/runs/linguistics/proofwriter --output research/linguistics/proofwriter-counts.json`. No model or benchmark execution.

### 2026-10-14T02:12:22Z — Primary-source linguistic design audit (read-only)

Read Bos2008 and Mineshima etal.2015 papers, plus official ccg2lambda English
templates at a68cb264413791150011c347c64a7b35e2f7270d and template/category
selection code. No new benchmark, LLM, parser-model load or production edit.
Research notes: research/linguistics/REFERENCES.md and TEMPLATE_COMPARISON.md.
The notes distinguish published mechanisms from our proposed gold: two-slot NP
restriction, feature-sensitive voice, local reflexive binding, shared-witness
coordination, particles/PP and punctuation. Static source counterexamples include
sentence-or conjoining, arity-only erasure fallback, different never scope in
2015/event files, and flat modal conjunction. No upstream runtime claim is made.
Downloaded reference files stay ignored under research/runs/linguistics-sources/.
Attempted delegated Boxer child at owner's request; tool rejected thread limit;
continued both source audits directly. No experiment prediction required for
source reading/writing alone; future acceptance probes must log predictions.

### 2026-10-14 — generated-language extraction and construction clustering prediction

Owner confirms all usage resets may be used; work continues autonomously. All three
specialist child spawns hit the runtime four-agent limit; existing agents remain
active. Prediction: ProverQA has a small outer clause grammar but a much richer VP
lexicon than ProntoQA. Inventory will count every available input occurrence and
unique surface separately, including ProntoQA demonstrations, excluding solution
fields. FOLIO uses its existing120 sample, preserving premise boundaries. Coarse
construction counts alone cannot establish semantic correctness: nested operators
and lexical constructions will also be counted. Unclassified forms stay explicit.
Command: `python3 research/linguistics/inventory-other.py --data /home/gram/data --work research/runs/linguistics/other --output research/linguistics/other-counts.json`.

### Meaning-fidelity contract red result and first green prediction, 2026-10-14

The initial10 tests fail at the absent fidelity module as predicted. Implemented
structural gold validation and evaluation, strict id/text projection, a Haskell
observation executable reusing production Canonical/Claims, and four independently
authored hand controls: rigid fact, whole negation, shared existential witness,
and attributed report. Prediction:10 Python contracts pass; GHC compiles with
-Wall -Werror; the hand pipeline matches all4 scoped DRS/claim-table expectations.
No licensed data or model inference is required for these controls.

```
python3 -m unittest discover -s test/fidelity -p 'test_fidelity.py' > research/runs/solver-audit/fidelity-contract-tests.log 2>&1
ghc -O1 -Wall -Werror -isrc -outputdir research/runs/fidelity/build test/fidelity/Export.hs -o research/runs/fidelity/fidelity-json > research/runs/fidelity/build.log 2>&1
python3 test/fidelity/run.py --cases test/fidelity/hand-controls.jsonl --binary research/runs/fidelity/fidelity-json --parser hand --output research/runs/fidelity/hand-controls-report.json --require-exact > research/runs/fidelity/hand-controls.log 2>&1
```

### 2026-10-14T02:14:54Z — Name N/NP diagnosis prediction

Prediction: default corpus lexical assignment will lose an already-NP proper
name because names accepts only offered N. Unseen initial capitals may retain
both rigid and generic common-noun readings; ordinary initial capitals with
attested lower-case evidence should remain non-name. Batch hand-authored minimal
controls for benchmark names and one observed ProverQA sentence, no new benchmark.
Command: `dist-newstyle/build/x86_64-linux/ghc-9.4.7/nl2proof-0.1.0.0/x/nl2proof-explain/build/nl2proof-explain/nl2proof-explain --all-readings < research/runs/linguistics-names/explain-input.txt > research/runs/linguistics-names/explain-before.log 2>&1`.

### Fidelity exporter build correction and control prediction

The first direct `-Wall -Werror` build stopped on an existing `Bench/JSON.hs:31` name-shadowing warning before compiling the exporter. This is an instrumentation build failure, not a parser result. Prediction remains four authored hand controls exact; retry with the repository's non-fatal warning policy and inspect all new exporter warnings.

Commands:

```sh
ghc -O1 -Wall -isrc -outputdir research/runs/fidelity/build test/fidelity/Export.hs -o research/runs/fidelity/fidelity-json > research/runs/fidelity/build.log 2>&1
python3 test/fidelity/run.py --cases test/fidelity/hand-controls.jsonl --binary research/runs/fidelity/fidelity-json --parser hand --output research/runs/fidelity/hand-controls-report.json --require-exact > research/runs/fidelity/hand-controls.log 2>&1
```

Inventory extraction audit: interrupted the initial local-only extraction after
several minutes; traceback identified repeated pathlib.relative_to in every
sentence as unnecessary overhead. Hoisted per-file paths. A shortest-sentence
audit also exposed Dr./Mr. abbreviation fragments: inventory now preserves those
abbreviations, independently of the production tokenizer's punctuation splitting.
Prediction: rerun completes quickly with intact titled names. Same command as
above; this is input-language analysis, not a new answer benchmark.

### Fidelity exporter and hand-control result

The exporter now compiles without new warnings (renamed its local training-tree count to avoid shadowing). All four independently authored hand controls are exact on the selected DRS **and** claim table; all four also have an exact returned reading. No parse/type/incomplete/error cases occurred. This checks the measurement seam, not benchmark coverage. Artifacts: `research/runs/fidelity/hand-controls-report.json`, `.observations.jsonl`, `.stderr.log`; build/control logs adjacent. Gold was specified before executing the parser.

### Fidelity schema and parser-boundary hardening prediction

The optional disjunction metadata currently checks shape only; prediction: a path pointing to a predicate or using a negative index is wrongly accepted. Add red tests requiring actual disjunction targets and unique paths, then reject malformed annotations. Separately, the Haskell protocol is expected already to reject extra gold keys and duplicate keys while still responding to a subsequent clean request. Commands:

```sh
python3 -m unittest discover -s test/fidelity -p 'test_fidelity.py' > research/runs/fidelity/schema-path-red.log 2>&1
python3 -m unittest discover -s test/fidelity -p 'test_fidelity.py' > research/runs/fidelity/schema-path-green.log 2>&1
python3 research/runs/fidelity/check-protocol.py > research/runs/fidelity/protocol.log 2>&1
```

### 2026-10-14T02:17:34.636098+00:00 — ProofWriter inventory integrity checks prediction

Prediction: extraction retains the NatLang presented sentence once despite multiple synthetic mappings; questions and abduction targets remain inputs while labels/proofs/abducted answers cannot affect output. Punctuation expansion preserves occurrence mass and remains idempotent, including overlap with an existing sentence. Controlled examples cover pronoun binding/ellipsis/negative transitive/birds modal without erasing their surface cues. Exact command: `python3 research/runs/linguistics/proofwriter/check_inventory.py > research/runs/linguistics/proofwriter/check-inventory.log 2>&1`.

### 2026-10-14T02:18:06Z — Name diagnosis result and test-first prediction

Default corpus Explain loaded39604 trees in83.5s. Legend at sentence start is
truecased to a common noun and yields a generic universal; inside If Legend it
yields the rigid constant. Brecken/Abdullah have both rigid and generic readings,
with rigid selected in the copular controls. White things/Cats stay ordinary.
The direct-NP omission is a separate source defect, not the explanation of all
three benchmark names. Initial prediction was partly confirmed; corpus names
here did not require direct-NP recovery. Explain also labels every name as
POS-NNP even when capitalization fallback supplies it; fix wording honestly.

Root approved bounded name N/NP repair and gloss correction. Prediction for
preimplementation tests: POS-licensed direct NP/NP[nb] lexical, composition, DRS
and claims cases fail; existing N→NP and casing/common-word controls pass.
Command: `runghc -isrc -itest test/NameSemSpec.hs > research/runs/linguistics-names/test-red.log 2>&1`.

### 2026-10-14T02:18:50.269676+00:00 — ProofWriter punctuation authority repair prediction

Validation exposed thousands of NatLang dictionary/theory mismatches: `sentences` often replaces sentence stops with semicolons, but some semicolons are genuine. Prediction: aligning each mapped text unit against normalized `theory`, allowing only period/semicolon alternatives at matching positions, will recover exact presented punctuation without changing words, order, or roles; any unmatched record must remain explicit. After the currently running extraction completes, rebuild only files with reconstruction mismatches, then count punctuation-delimited sentences. Exact commands: `python3 research/linguistics/inventory-proofwriter.py repair-surface --root /home/gram/data/proofwriter/proofwriter-dataset-V2020.12.3 --work research/runs/linguistics/proofwriter > research/runs/linguistics/proofwriter/repair-surface.log 2>&1`; rerun the already recorded summarize command.

### 2026-10-14T02:19:01Z — Name repair red result and green prediction

Before source edits NameSemSpec passed15/26, failed11 exactly in licensed
already-NP lexical/composition/DRS/claim cases; controls passed. Minimal repair
now admits ordinary NP and NP[nb] only through existing NameStatus policy,
preserves the category/score, and records actual POS versus capitalization
license in a name-lexicon Decision. Expletive/thr/conj NP remain excluded.
Explain's generic source gloss no longer falsely claims POS-NNP for unseen names.
Prediction: all26 focused checks now pass; existing semantic-repair and CCGSem
regressions remain green. Legend ambiguity remains unresolved and its desired
rigid gold is not weakened.
Commands: `runghc -isrc -itest test/NameSemSpec.hs > research/runs/linguistics-names/test-green.log 2>&1`; `runghc -isrc -itest test/SemanticRepairSpec.hs > research/runs/linguistics-names/repair-regression.log 2>&1`; `runghc -isrc -itest test/CCGSemSpec.hs > research/runs/linguistics-names/ccgsem-regression.log 2>&1`.

### Fidelity boundary hardening result and ProntoQA gold plan

The annotation red tests reproduced both flaws (a predicate accepted as an OR marker target, and malformed universe raising TypeError). Fixed validation without changing the schema; 12 contract tests pass. The live hand exporter rejects extra gold fields and duplicate request keys and then successfully parses the following clean request (`research/runs/fidelity/protocol.log`).

Input-only inspection of ProntoQA source contexts identifies these actual forms: named nominal/adjectival/negative copulas; bare-plural and Every/Each universals; Everything-relative conjunction/disjunction restrictors; ground and universal predicate conjunction; ground three-way predicate disjunction. No answer, proof, or solver labels are used to author meanings. Predicate nominals will be direct unary classification, not fresh existential equality; names retain written case; fictional ontology plural nouns use singular predicate lemmas. Bare plurals receive the benchmark's generic universal reading. Relative Everything has no additional artificial thing restriction. Three-way disjunction permits both associations, explicitly enumerated before parsing. Prediction: current corpus parser has substantial no-parse/typed-wrong failures on fictional words and copular nominals; selected exactness will be far below the four hand controls, and POS may improve availability without ensuring meaning.

Gold-authoring and validation (all semantic values entered manually in the script, source read only to verify text references):

```sh
python3 research/runs/fidelity/author-pronto.py
python3 -m unittest discover -s test/fidelity -p 'test_fidelity.py' > research/runs/fidelity/pronto-schema-tests.log 2>&1
```

Default/POS measurement commands, to run after building one frozen executable and coordinating with production parser work:

```sh
python3 test/fidelity/run.py --cases test/fidelity/prontoqa.jsonl --binary research/runs/fidelity/fidelity-json --parser default --output research/runs/fidelity/pronto-default-report.json
python3 test/fidelity/run.py --cases test/fidelity/prontoqa.jsonl --binary research/runs/fidelity/fidelity-json --parser pos --output research/runs/fidelity/pronto-pos-report.json
```

### 2026-10-14 — owner-authorized concurrency configuration and resume continuity

Owner requests more effective parallel work and authorizes changing local Codex
configuration or supplying a server command. Set only
`agents.max_concurrent_threads_per_session = 8` in the existing user config; parsed
TOML equality verified every unrelated setting unchanged. `codex features list`
loads the resulting config successfully. `--strict-config features list` is not a
supported CLI combination (exit1), so that invocation is not a strict validation.
A real fourth-subagent attempt (`fidelity_audit`) still received agent thread limit
reached. Thus the active runtime still has3 subagent slots, despite the requested
new local limit. Goal amendment and STATE retain same-task continuation, all usage
resets, file ownership, and the benchmark pause across a possible CLI resume.

Root inventory initial aggregate: ProverQA17,345 input sentence occurrences and
17,285 unique surfaces; ProntoQA819,128 and177,560; FOLIO120sample744 premises/query
units and439 unique surfaces. Outer families are provisional, not a claim of
complete semantic coverage; nested operators and VP lexical constructions next.
All pre-redirect solver matrices finished and queued new runs were canceled.

### 2026-10-14T02:20:20.914770+00:00 — Inventory integrity result

All5 mock/text-only integrity checks pass. Extended aggregate records separate physical variant/world/split counts, per-file SHA256, standard120 sentence frequencies, and global distinct strings. No empirical parser/model result is inferred from surface family coverage.

### Manual ProntoQA construction gold ready

`test/fidelity/prontoqa.jsonl` now contains 25 exact source sentences across 11 construction groups, each with 2–3 examples. Full manual DRS and independent claim lists pass scope/schema validation; all 12 runner contract tests pass. Source lookup in `research/runs/fidelity/author-pronto.py` only verifies input strings and item references. No parser observation, answer label, or proof chain entered any expectation. The generation script is a local authoring aid, not a production semantics implementation. README records direct predicative-nominal classification, singular fictional-noun lemmas, bare-plural universal reading, unrestricted Everything, and predeclared disjunction associations. Default/POS baseline awaits a stable build snapshot coordinated with the category-repair worker.

### 2026-10-14T02:20:38Z — Name repair targeted results

NameSemSpec26/26, SemanticRepairSpec29/29, CCGSemSpec89/89 pass after the
bounded source repair. Prediction held. General licensing policy and Legend's
known wrong-but-typed initial reading remain unchanged. NAMES.md records the
corpus first-divergence table, typed derivation, DRS/claims, source choice and a
separate unimplemented document-evidence proposal. No benchmark rerun occurred.
Source stable for parent integration build/gates and optimized corpus controls.

### 2026-10-14 inventory recovery after coordinator refresh
Prediction before measurement: repaired ProofWriter extraction covers all 110 physical JSONL files; summarization will preserve source counts apart from explicit multi-sentence expansion. Existing ProverQA/ProntoQA/FOLIO totals should reproduce. These are text inventories, not answer benchmarks or model launches. Commands: `python3 research/linguistics/inventory-proofwriter.py summarize --work research/runs/linguistics/proofwriter --output research/linguistics/proofwriter-counts.json`; `python3 research/runs/linguistics/proofwriter/check_inventory.py`; `python3 research/linguistics/inventory-other.py --data /home/gram/data --work research/runs/linguistics/other-refresh --output research/linguistics/other-counts.json`. Raw text remains in ignored research/runs.

### 2026-10-14T02:42:43.684994+00:00 — Independent bounded name repair review

Prediction before execution: `cabal test name-sem --test-show-details=direct` should retain all 26 passing hand-authored checks. The change preserves POS/casing licensing and category scores while adding ordinary NP/NP[nb] name meanings; it does not resolve initial Legend truecasing or bare-object semantics. No model or answer benchmark is launched. Review will also inspect lexical decision provenance and add a focused check if current tests omit its contract.

### 2026-10-14 — full-access coordinator recovery and integration prediction

Owner-authorized restart resolves bwrap namespace failures: branch/status/rg reads succeed. Four stalled specialists resumed, with shell checks, and a fifth ProverQA gold specialist spawned; this proves at least five worker slots, not the configured maximum. All uncommitted work is preserved. No new model or answer benchmark launch is authorized before the fidelity gate.

Prediction before integration checks: preserved name repair adds 26 passing checks to the prior 1,169 Haskell checks; fidelity runner contract tests and hand controls stay green. Required commands: `cabal build all`, `cabal test all`, `scripts/check-oracle-boundary.sh`, `scripts/check-explain.sh`; logs under `research/runs/recovery-gates/`. These are build/regression gates, not answer benchmarks.

Name review baseline result: 26/26 passed. Trace inspection found an invented common-noun alternative even under NameOnly. Root authorized a metadata-only correction. Prediction before red check: `runghc -isrc -itest test/NameSemSpec.hs` will pass 28/30 and fail the two new factual-alternatives checks; score/evidence checks should pass. Intended change records actual open lexical candidates only for NameOrOther and no alternatives for a forced NameOnly candidate. These are lexical alternatives, not proof that another whole-sentence reading exists.

### 2026-10-14 — independent fidelity scorer hardening prediction

Prediction before tests: new contract mutations exposing omitted inclusive-OR annotations, claim references absent from the DRS, and malformed observation counts will fail against the current scorer. After focused fixes these checks and preserved existing contracts will pass. Commands: `python3 -m unittest discover -s test/fidelity -p 'test_fidelity.py'`; fixture validation via `validate_case` only. No parser, benchmark, solver, or model launch. Expected meanings remain independently authored; Pronto OR annotations explicitly encode its documented inclusive semantics.

### 2026-10-14T02:44:00.292441+00:00 — construction design Explain prediction

Prediction: closed `if`/`not`, adjective copula, simple `all` and the bounded
subject-relative repair will preserve their fragment meaning; predicative nominal,
`each`/`some`/`everything`, reflexive, particle, passive/progressive auxiliary and
modal gaps will first appear at tags/lexical meanings/derivation, before DRS or
claim extraction. Fictional plurals may be mistaken for rigid names. This is a
small hand-authored linguistic diagnostic, not an answer benchmark or model run.
Use an immutable copy of the existing Explain executable, SHA256 `701f94da16be317c070765c7002a8460e55497a41b48bf0bcfa5027deb84b07d`;
its original compiled source snapshot is not inferred from current source hashes.
Exact command: `research/runs/linguistics-design/explain-frozen --all-readings < research/runs/linguistics-design/input.txt > research/runs/linguistics-design/explain.log 2>&1`.

Name trace red result: predicted 28/30 passed, with exactly the two new alternatives checks failing. Implemented only factual lexical-alternative metadata. Prediction before green check: `runghc -isrc -itest test/NameSemSpec.hs` should pass 30/30 with all existing DRS/claim expectations unchanged.

Name review green result: `runghc -isrc -itest test/NameSemSpec.hs` passed 30/30, matching the prediction. `git diff --check` passed. Existing licensed N/NP repair, 26 original semantic/scope controls, casing policy, and category scores are preserved. Updated STUDY_PLAN repaired-seams table and NAMES with bounded repair and remaining initial Legend failure. No answer benchmark/model/LLM launch; no commit from specialist. Root owns full build/release gates.

Result: red phase produced two expected failures (missing OR annotations and invalid claim references) plus the malformed-count TypeError, confirming the prediction. After fixes, all 16 scorer contracts pass; all four hand controls and 25 Pronto fixtures validate. Inclusive annotations were added only from independently documented Pronto meaning and authored gold paths. Malformed observations now remain `error` in the denominator. No canonical sequencing restriction, parser/Haskell edit, or benchmark/model launch was introduced.

### 2026-10-14 — owner parallel ownership refinement and pending checks

Coordinator alone now owns STATE, LOG, cabal configuration, shared production source and commits. Eight concurrent specialists accepted; worker outputs use isolated gold/proposal/section files. Inventory is split by benchmark in successive available slots; root merges sections. Existing name metadata edits completed before the ownership change are frozen for coordinator review.

Predictions before checks: ProofWriter summary reconciles all110 file manifests, role/family/file totals and reports any controlled-unexpected rows; `python3 research/linguistics/test_inventory.py` should preserve five integrity checks. ProverQA 24 authored rows (12 outer families, two each) should pass `PYTHONPATH=test/fidelity python3 -c 'from fidelity import read_jsonl,validate_case; rows=read_jsonl("test/fidelity/proverqa.jsonl"); [validate_case(x) for x in rows]; print(len(rows))'`; this cannot establish population fidelity and modal coverage remains blocked. FOLIO roughly12 independently authored existential/negated-existential/relational cases should pass the analogous schema command on test/fidelity/folio.jsonl; temporal never and unsupported cardinality are explicitly gaps. No parser answers/model runs are launched by these validations.

### 2026-10-14 — isolated worktree transition and memory preflight

Owner supersedes shared-worker editing with isolated astra/<name> worktrees. All workers frozen pending transfer; root preserves full dirty tree. No CCGbank loader is active (`ps` inspected). Prediction: one frozen Explain corpus load on a compact sentence will fit below10GiB; measure actual peak with `/usr/bin/time -v -o research/runs/recovery-gates/explain-rss.txt research/runs/linguistics-design/explain-frozen --stage=claims "Bob is red." > research/runs/recovery-gates/explain-rss-output.txt 2>&1`. Limit will be floor(10GiB / measured peak), capped conservatively if needed; no other corpus load until recorded. Existing cache files preferred.

First integration build passed, oracle boundary passed, Explain smoke passed; cabal test hit concurrently added name trace red tests, so failed name-sem while other suites passed. Worker fixed trace and reports30/30 focused tests; rerun full gates on frozen snapshot. Fidelity hardened contracts17/17, FOLIO12 and Prover24 schema validations passed independently, still no population gate evidence.

### 2026-10-14 — memory measurement and frozen integration result

Frozen Explain corpus load completed successfully in85.21s, peak RSS163,072KiB (166,985,728 bytes), no swap. floor(10,000,000,000 /166,985,728)=59 load-only slots; actual admission is conservatively capped at2 because parsing larger sentences can exceed the measured load and the15GiB machine also runs agents/builds. Shared flock token directory `/home/gram/astra-wt/.ccgbank-slots`, limit2. Prefer sealed caches; all new corpus-loading commands must use scripts/with-ccgbank-slot.py.

Frozen build and all13 Haskell suites now pass (1,199 checks expected from prior1,169+name30). Re-run oracle and Explain gates after final metadata source change; run17 fidelity contract checks and hand controls. Prediction: boundary and smoke gates stay green and4/4 hand controls remain exact.

### 2026-10-14 — live fidelity protocol catches synthetic-test gap

Hand4 controls returned4 instrumentation errors: exporter JNum renders integral counts/indices as JSON1.0, while reviewer hardening wrongly demanded Python int. Prediction: add wire-format regression first (fails), accept only finite mathematically integral int/float excluding bool/negative/fractional/nonfinite, then all18 contracts and hand4 exact pass. Production exporter need not change.

### 2026-10-14 — reviewed foundation checkpoint

Final frozen gates pass: cabal build all, all13 suites1199checks, oracle negatives/positive clients, Explain smoke. Fidelity wire regression red then green18/18; hand4/4 exact. Bounded name repair independently approved against source template and30 controls, without claiming Legend fixed. Foundation stages only listed repair/harness/Pronto/reference/operations files; unfinished inventory/gold/design/provider/solver/report artifacts preserved. Integration is not a resume-gate claim.

### 2026-10-14 — baseline for serial branch integration

Foundation d88b1e5 pushed after all gates. Restart runtime initially listed root only; eight specialist spawns now accepted with working full-access shells. Preparing one frozen current-binary corpus fidelity observation over existing Pronto25+Prover24+FOLIO12+PW24 diagnostic inputs (85 total), gold stays outside parser. This is construction translation fidelity, not an answer benchmark. Prediction: Pronto and Prover remain far below90% and wrong-but-typed persists; no gate inferred. Frozen observations will be replayed after each documentation/gold merge with exact id/text and executable hash checks, avoiding redundant CCGbank loads; any source/fixture text change invalidates relevant cache.
Command: `python3 scripts/with-ccgbank-slot.py python3 test/fidelity/run.py --cases research/runs/integration-fidelity/initial-cases.jsonl --binary research/runs/integration-fidelity/fidelity-frozen --parser default --output research/runs/integration-fidelity/initial-default.json`.

### 2026-10-14 — serial merge1: ProofWriter inventory

Reviewer approves4f14434 as surface inventory, not semantic completeness. Merged with --no-commit; original overlapping untracked files moved intact into ignored integration-preserved. Root also stages shared input-only inventory helper and aggregate counts (raw example strings removed from committed aggregate, originals retained in ignored snapshot), plus five extraction contract tests. Prediction: all build/regression gates stay green, five extraction checks pass, fidelity scores unchanged because no production semantics changed. Final merged-result verification uses frozen85-input observations when ready and hand4 controls.

Merge1 verification passed: build,1199 Haskell checks/13 suites, oracle boundary, Explain smoke,18 fidelity contracts, hand4/4 exact, five extraction tests. Frozen85-input default result21exact/24wrong/40no-parse; replay unchanged after inventory merge. Per-dataset Pronto3/5/17, Prover7/8/9, FOLIO2/5/5, ProofWriter9/6/9 (exact/wrong/no-parse). These initial gold snapshots are diagnostic; independent later gold corrections can change score without a parser change, explicitly recorded by gold hashes. Source/binary-identical replay is required after each pure-doc/gold merge; semantics changes invalidate cache. The merge1 Explain gate and initial baseline together used at most2 loaders; future Explain gates also go through the shared token wrapper.

### 2026-10-14 — serial integration inventory-proverqa (b6278c2)

Reviewer-approved branch only; overlapping untracked artifacts preserved under ignored integration-preserved. Prediction: unchanged production semantics preserve current fixed-input parser observations; gold representation corrections may change exact score and are identified by fixture hashes. Commands: git merge --no-ff --no-commit astra/inventory-proverqa; cabal build all; cabal test all; scripts/check-oracle-boundary.sh; token-wrapped scripts/check-explain.sh;18 fidelity contracts; sealed source/binary-checked replay; live hand4. Logs research/runs/serial-merges/inventory-proverqa.

Result inventory-proverqa: all merged-result gates passed,18 scorer contracts, sealed fidelity replay and4/4 live hand controls. No model or answer benchmark launch; gate remains unmet.

### 2026-10-14 — serial integration inventory-prontoqa (d0c8436)

Reviewer-approved branch only; overlapping untracked artifacts preserved under ignored integration-preserved. Prediction: unchanged production semantics preserve current fixed-input parser observations; gold representation corrections may change exact score and are identified by fixture hashes. Commands: git merge --no-ff --no-commit astra/inventory-prontoqa; cabal build all; cabal test all; scripts/check-oracle-boundary.sh; token-wrapped scripts/check-explain.sh;18 fidelity contracts; sealed source/binary-checked replay; live hand4. Logs research/runs/serial-merges/inventory-prontoqa.

Result inventory-prontoqa: all merged-result gates passed,18 scorer contracts, sealed fidelity replay and4/4 live hand controls. No model or answer benchmark launch; gate remains unmet.

### 2026-10-14 — serial integration inventory-folio (634bc10)

Reviewer-approved branch only; overlapping untracked artifacts preserved under ignored integration-preserved. Prediction: unchanged production semantics preserve current fixed-input parser observations; gold representation corrections may change exact score and are identified by fixture hashes. Commands: git merge --no-ff --no-commit astra/inventory-folio; cabal build all; cabal test all; scripts/check-oracle-boundary.sh; token-wrapped scripts/check-explain.sh;18 fidelity contracts; sealed source/binary-checked replay; live hand4. Logs research/runs/serial-merges/inventory-folio.

Result inventory-folio: all merged-result gates passed,18 scorer contracts, sealed fidelity replay and4/4 live hand controls. No model or answer benchmark launch; gate remains unmet.

### 2026-10-14 — serial integration gold-folio (169165e)

Reviewer-approved branch only; overlapping untracked artifacts preserved under ignored integration-preserved. Prediction: unchanged production semantics preserve current fixed-input parser observations; gold representation corrections may change exact score and are identified by fixture hashes. Commands: git merge --no-ff --no-commit astra/gold-folio; cabal build all; cabal test all; scripts/check-oracle-boundary.sh; token-wrapped scripts/check-explain.sh;18 fidelity contracts; sealed source/binary-checked replay; live hand4. Logs research/runs/serial-merges/gold-folio.

Result gold-folio: all merged-result gates passed,18 scorer contracts, sealed fidelity replay and4/4 live hand controls. No model or answer benchmark launch; gate remains unmet.

### 2026-10-14 — serial integration gold-proverqa (43ac355)

Reviewer-approved branch only; overlapping untracked artifacts preserved under ignored integration-preserved. Prediction: unchanged production semantics preserve current fixed-input parser observations; gold representation corrections may change exact score and are identified by fixture hashes. Commands: git merge --no-ff --no-commit astra/gold-proverqa; cabal build all; cabal test all; scripts/check-oracle-boundary.sh; token-wrapped scripts/check-explain.sh;18 fidelity contracts; sealed source/binary-checked replay; live hand4. Logs research/runs/serial-merges/gold-proverqa.

Result gold-proverqa: all merged-result gates passed,18 scorer contracts, sealed fidelity replay and4/4 live hand controls. No model or answer benchmark launch; gate remains unmet.

### 2026-10-14 — serial integration gold-proofwriter (727aa46)

Reviewer-approved branch only; overlapping untracked artifacts preserved under ignored integration-preserved. Prediction: unchanged production semantics preserve current fixed-input parser observations; gold representation corrections may change exact score and are identified by fixture hashes. Commands: git merge --no-ff --no-commit astra/gold-proofwriter; cabal build all; cabal test all; scripts/check-oracle-boundary.sh; token-wrapped scripts/check-explain.sh;18 fidelity contracts; sealed source/binary-checked replay; live hand4. Logs research/runs/serial-merges/gold-proofwriter.

Result gold-proofwriter: all merged-result gates passed,18 scorer contracts, sealed fidelity replay and4/4 live hand controls. No model or answer benchmark launch; gate remains unmet.

### 2026-10-14 — serial integration design-names (34277a5)

Reviewer-approved branch only; overlapping untracked artifacts preserved under ignored integration-preserved. Prediction: unchanged production semantics preserve current fixed-input parser observations; gold representation corrections may change exact score and are identified by fixture hashes. Commands: git merge --no-ff --no-commit astra/design-names; cabal build all; cabal test all; scripts/check-oracle-boundary.sh; token-wrapped scripts/check-explain.sh;18 fidelity contracts; sealed source/binary-checked replay; live hand4. Logs research/runs/serial-merges/design-names.

Result design-names: all merged-result gates passed,18 scorer contracts, sealed fidelity replay and4/4 live hand controls. No model or answer benchmark launch; gate remains unmet.

### 2026-10-14 — serial integration design-operators (e4dceb6)

Reviewer-approved branch only; overlapping untracked artifacts preserved under ignored integration-preserved. Prediction: unchanged production semantics preserve current fixed-input parser observations; gold representation corrections may change exact score and are identified by fixture hashes. Commands: git merge --no-ff --no-commit astra/design-operators; cabal build all; cabal test all; scripts/check-oracle-boundary.sh; token-wrapped scripts/check-explain.sh;18 fidelity contracts; sealed source/binary-checked replay; live hand4. Logs research/runs/serial-merges/design-operators.

Result design-operators: all merged-result gates passed,18 scorer contracts, sealed fidelity replay and4/4 live hand controls. No model or answer benchmark launch; gate remains unmet.

### 2026-10-14 — serial integration design-relatives (4d3e569)

Reviewer-approved branch only; overlapping untracked artifacts preserved under ignored integration-preserved. Prediction: unchanged production semantics preserve current fixed-input parser observations; gold representation corrections may change exact score and are identified by fixture hashes. Commands: git merge --no-ff --no-commit astra/design-relatives; cabal build all; cabal test all; scripts/check-oracle-boundary.sh; token-wrapped scripts/check-explain.sh;18 fidelity contracts; sealed source/binary-checked replay; live hand4. Logs research/runs/serial-merges/design-relatives.

Result design-relatives: all merged-result gates passed,18 scorer contracts, sealed fidelity replay and4/4 live hand controls. No model or answer benchmark launch; gate remains unmet.

### 2026-10-14 — serial integration design-particles (6142c34)

Reviewer-approved branch only; overlapping untracked artifacts preserved under ignored integration-preserved. Prediction: unchanged production semantics preserve current fixed-input parser observations; gold representation corrections may change exact score and are identified by fixture hashes. Commands: git merge --no-ff --no-commit astra/design-particles; cabal build all; cabal test all; scripts/check-oracle-boundary.sh; token-wrapped scripts/check-explain.sh;18 fidelity contracts; sealed source/binary-checked replay; live hand4. Logs research/runs/serial-merges/design-particles.

Result design-particles: all merged-result gates passed,18 scorer contracts, sealed fidelity replay and4/4 live hand controls. No model or answer benchmark launch; gate remains unmet.

### 2026-10-14 — bounded quantifier integration prediction

All original inventory/gold/design serial merges pushed through407eb4b. Full-access shells and eight resumed specialist tasks verified. Reviewed some/no/each repair should remove spurious open-class determiner meanings without changing existing definite identities. Modifier order change rejected after bald eagle identifier regression; old1199 checks preserved. Next commands: merge astra/design-quantifiers without commit, register24 direct checks, cabal build/test all, oracle and token-wrapped Explain,18 scorer contracts, fresh85-case fidelity and hand4. Expect improvements in some/no/each only; no claim of meeting ProverQA gate. Source change invalidates old sealed parse replay.

Result: merged build and14 suites pass (original1199 plus24 quantifier checks); oracle boundary, Explain,18 contracts, hand4/4 pass. Fresh85 inputs:22 exact/23 wrong-but-typed/40 no-parse, versus21/24/40 on the same current gold replay. Only pronto-each-1 changes wrong→exact; no status regressions. ProverQA stays7 exact/8 wrong/9 no-parse of24. Direct lexical correctness does not resolve competing corpus constructions. Independent modifier-order known failures remain outside release suites explicitly documented, not newly hidden regressions. Gate remains closed. Logs research/runs/quantifier-integration; fresh source/binary sealed for subsequent doc/gold replay.

### 2026-10-14 — consolidated linguistic deliverables

Prediction: assembling reviewed four-benchmark CONSTRUCTIONS and family DESIGN does not change production observations. DESIGN ties category derivations, Montague meanings, DRS/claim commitments and first divergences to Units2/3/4; comparisons retain adoption limits. Counts disclose unresolved ProverQA/FOLIO frames and physical ProofWriter110 scope. Commands: full build/test, oracle, token-wrapped Explain,18 contracts, source/binary-checked fidelity replay, hand4. No model/answerbenchmark.

Result: consolidated deliverables pass all release gates,14 suites/1223 checks,18 fidelity contracts, live hand4 and unchanged-source sealed replay22/23/40. All local Markdown links resolve. STUDY_PLAN records bounded determiner repair and unresolved conditional/reflexive/bare-plural errors. No new answerbenchmark/model.

### 2026-10-14 — fidelity wire edge contract repair

Reviewer approved dcb6043 independent11 edge tests. Prediction: current scorer fails7 methods: integer overflow, bool-as-number equality and uninformative nested differences, malformed selected object shape. Repair must retain1.0 wire counts, permit extra top-level metadata, count all6 outcomes, and keep semantic scope defects wrong-but-typed. First merge red tests and run them, then bounded scorer repair; full gates/replay/hand before push.

### 2026-10-14 — expanded independent fidelity before gold integration

Prediction: bounded quantifier repair will not fix nested relative/name selection or reflexive-locality failures. Combine85 currentstarter rows plus29 independently reviewed nestedProver10/nestedPronto12/reflexive7 rows authored before parser observation. Run token-wrapped test/fidelity/run.py with expanded-quantifier-fidelity/cases.jsonl and sealed quantifier-integration/fidelity-quantifiers, default parser, fresh.json output.114 rows, all failures retained, no model/answerbenchmark; this provides current-source observations for serial gold-branch merges without repeated corpus loading.

Result: independent edge tests reproduced7 failing methods before repair; all29 contracts pass after bounded patch and reviewer approval514a238. Build,14 Haskell suites/1223 checks, oracle, Explain, live hand4 and sealed85 fidelity replay pass; scores unchanged22/23/40. No semantic scope validation added to observed meanings.

### 2026-10-14 — reviewed lexical have inflection and residual inventory

Prediction: independent ec72a6d12 direct controls reproduce5 has→ha failures, fixed by single licensed irregular have/has entry in verbLemma. Names,nouns,adjectives and perfect auxiliary category remain unchanged. Reviewed residual inventory refines249 of3791 prior unmatched occurrences as syntactic tails only, not fidelity. Merge one branch, run redcontrols, add one entry/registersuite, fullgates and fresh114 independentconstruction rows before push. No model/answerbenchmark.

Expanded quantifier-only result:114 gold rows score22 exact/35 wrong-but-typed/57 no-parse, no instrumentation/type/incomplete errors. Added rows preserve observed failures; caches research/runs/expanded-quantifier-fidelity are sealed against source/binary hashes. Coverage audit identifies112 unique texts (two repeated across starter/nested families);114 is a regression-row count, not a representative benchmark denominator or gate estimate.

Result: has→have red controls7/12 before repair,12/12 after. All15 suites/1235 checks, build, oracle, Explain,29 fidelity contracts and hand4/4 pass. Fresh114 rows improve22/35/57 to24 exact/33 wrong/57 no-parse. Only prover-subject_have-1 and -2 change wrong→exact; no status regressions. Starter ProverQA now9/24 exact, still no gate claim. Raw/aggregate outputs ignored research/runs/has-integration. Reviewed residual surface counts integrated separately from semantic improvement.

### 2026-10-14 — nominal copula integration prediction

Reviewer approved3cfa8f5 typed lexical elaboration, including coordinated positive predicates, stable equative fallback, neutral deferral and reserved-symbol hardening. Prediction: source-only39/40 corrected40 checks pass, while9 surface and4 admission controls require root lexical/Pipeline wiring. Merge branch alone, run current reds; wire exact nominal is/are category, reject unresolved reserved builtin after normalization before DRS, register53 controls, preserve ordinary arbitrary equality witnesses/accessibility. Fresh114 construction fidelity must not trade no-parse for newly wrong typed cases; evaluate before any push. All full release gates required.

Nominal admission follow-through: add two resolved attitude-status controls before release (say→Reported, know→Presupposed only; complement never Asserted), beyond the four unresolved-operator rejection controls. Prediction:55 focused checks pass; guards must protect both resolved and unresolved paths.

Resolved-status test initially failed54/55 because its direct toDRS fixture omitted the production post-DRS projectPresuppositions step; splitClaims correctly excludes factive Reported duplication but expects that projected box. Correct the fixture to execute that real pipeline step, retaining exact Presupposed expectation; no production relaxation. Rerun complete tests and release gates.

Nominal result/rejection:55 focused checks and16 suites pass, oracle/contracts/hand pass, but Explain fails6 checks and114 fidelity worsens24/33/57→33/67/14. Decomposition:15 no-parse→exact,6 exact→wrong,28 no-parse→wrong. Six regressions are bare-generic adjective NPs selected as universal equatives; other errors expose unresolved relatives/names. Reviewer0d4e374 rejects landing. Preserve complete candidate including rootwiring/cabal/tests in LOCAL astra/nominal-candidate91645ae (not pushed); research/runs/nominal-quarantine has hash-verified snapshot. Initial merge abort refused modified new test; after verified backup restored only nine explicit candidate paths and aborted. Every unrelated dirty file hash remained identical. Root production restored04a85b8; no gate/gold weakening.

### 2026-10-14 — conditional comma-boundary integration prediction

Reviewed01a4933 tracks pending conditional and actual licensed raising through chart packing; prevents commaCoordApply on pending clause modifiers, preserves ordinary coordination. Prediction: remove duplicate-consequent alternatives and improve binding gold, no exact→wrong/newlytypedwrong trade. Existing independent reversed implication under synthetic raising remains explicit known failure; do not claim fixed. Merge branchalone (includes10 approved nestedProver gold), run14controls/fullgates, fresh114 scoring; no nominal source accompanies experiment. No model/answerbenchmark.

Conditional first merged result: all16suites/1249checks,oracle,Explain,29contracts,hand4 pass. Fresh114 improves24/33/57→27/30/57; exactly starterconditional_initial-1 and both nestedbinding cases wrong→exact, no status regressions. Before release replace human-readable gloss role seed with exact closed lexical key(if,(S/S)/S[dcl]) per specialist assessment; prediction: same114 outcomes, wording no longer controls syntax. Repeat affected build/tests and required gates/freshsource fidelity after this final source change.

Final conditional result: exact lexical-key seed preserves all114 case results byte-for-byte at scored-case level27exact/30wrong/57noparse. Build,16suites/1249checks,oracle,Explain,29contracts and hand4 pass on final source. Starter ProverQA10/24exact; nestedbinding2/2 nowexact. Known synthetic raised-direction failure retained explicitly. This fixes spurious consequence assertion in the measured cases, not general conditional completeness.

### 2026-10-14 — approved FOLIO extension baseline

Prediction:7 independent gold rows from b89930c (3universal,2conditional object anaphora,2predicative relatives) retain substantial current limitations. Reviewer approved English/DRS before parsing. Token-wrapped test/fidelity/run.py cases from gold-folio-extended branch, sealed conditional binary, default parser, outputs research/runs/folio-extended-baseline. Local fidelity only; no answerbenchmark/model. Source stays fixed during reviewed documentation/gold integration queue.

### 2026-10-14 — serial integration gold-nested-prontoqa (5f23bb2)

Reviewer-approved branch only; overlapping untracked artifacts preserved under ignored integration-preserved. Prediction: unchanged production semantics preserve current fixed-input parser observations; gold representation corrections may change exact score and are identified by fixture hashes. Commands: git merge --no-ff --no-commit astra/gold-nested-prontoqa; cabal build all; cabal test all; scripts/check-oracle-boundary.sh; token-wrapped scripts/check-explain.sh;29 fidelity contracts; sealed source/binary-checked replay; live hand4. Logs research/runs/serial-merges/gold-nested-prontoqa.

Result gold-nested-prontoqa: all merged-result gates passed,29 scorer contracts, sealed fidelity replay and4/4 live hand controls. No model or answer benchmark launch; gate remains unmet.

### 2026-10-14 — serial integration gold-reflexives (500e157)

Reviewer-approved branch only; overlapping untracked artifacts preserved under ignored integration-preserved. Prediction: unchanged production semantics preserve current fixed-input parser observations; gold representation corrections may change exact score and are identified by fixture hashes. Commands: git merge --no-ff --no-commit astra/gold-reflexives; cabal build all; cabal test all; scripts/check-oracle-boundary.sh; token-wrapped scripts/check-explain.sh;29 fidelity contracts; sealed source/binary-checked replay; live hand4. Logs research/runs/serial-merges/gold-reflexives.

FOLIO extension result:7 independently approved rows score0exact/2wrong/5no-parse on unchanged accepted conditional source. No semantic/type/instrumentation cases excluded. Observations sealed research/runs/folio-extended-baseline; replay verifies same binary and each source hash before incorporating these cases once their gold branch is merged.

Result gold-reflexives: all merged-result gates passed,29 scorer contracts, sealed fidelity replay and4/4 live hand controls. No model or answer benchmark launch; gate remains unmet.

### 2026-10-14 — serial integration fidelity-coverage-next (5e69ab2)

Reviewer-approved branch only; overlapping untracked artifacts preserved under ignored integration-preserved. Prediction: unchanged production semantics preserve current fixed-input parser observations; gold representation corrections may change exact score and are identified by fixture hashes. Commands: git merge --no-ff --no-commit astra/fidelity-coverage-next; cabal build all; cabal test all; scripts/check-oracle-boundary.sh; token-wrapped scripts/check-explain.sh;29 fidelity contracts; sealed source/binary-checked replay; live hand4. Logs research/runs/serial-merges/fidelity-coverage-next.

Result fidelity-coverage-next: all merged-result gates passed,29 scorer contracts, sealed fidelity replay and4/4 live hand controls. No model or answer benchmark launch; gate remains unmet.

### 2026-10-14 — serial integration proofwriter-residual (b910abd)

Reviewer-approved branch only; overlapping untracked artifacts preserved under ignored integration-preserved. Prediction: unchanged production semantics preserve current fixed-input parser observations; gold representation corrections may change exact score and are identified by fixture hashes. Commands: git merge --no-ff --no-commit astra/proofwriter-residual; cabal build all; cabal test all; scripts/check-oracle-boundary.sh; token-wrapped scripts/check-explain.sh;29 fidelity contracts; sealed source/binary-checked replay; live hand4. Logs research/runs/serial-merges/proofwriter-residual.

Result proofwriter-residual: all merged-result gates passed,29 scorer contracts, sealed fidelity replay and4/4 live hand controls. No model or answer benchmark launch; gate remains unmet.

### 2026-10-14 — serial integration gold-folio-extended (b89930c)

Reviewer-approved branch only; overlapping untracked artifacts preserved under ignored integration-preserved. Prediction: unchanged production semantics preserve current fixed-input parser observations; gold representation corrections may change exact score and are identified by fixture hashes. Commands: git merge --no-ff --no-commit astra/gold-folio-extended; cabal build all; cabal test all; scripts/check-oracle-boundary.sh; token-wrapped scripts/check-explain.sh;29 fidelity contracts; sealed source/binary-checked replay; live hand4. Logs research/runs/serial-merges/gold-folio-extended.

Result gold-folio-extended: all merged-result gates passed,29 scorer contracts, sealed fidelity replay and4/4 live hand controls. No model or answer benchmark launch; gate remains unmet.

### 2026-10-14 — serial integration nominal-licensing (8ecc681)

Reviewer-approved branch only; overlapping untracked artifacts preserved under ignored integration-preserved. Prediction: unchanged production semantics preserve current fixed-input parser observations; gold representation corrections may change exact score and are identified by fixture hashes. Commands: git merge --no-ff --no-commit astra/nominal-licensing; cabal build all; cabal test all; scripts/check-oracle-boundary.sh; token-wrapped scripts/check-explain.sh;29 fidelity contracts; sealed source/binary-checked replay; live hand4. Logs research/runs/serial-merges/nominal-licensing.

Result nominal-licensing: all merged-result gates passed,29 scorer contracts, sealed fidelity replay and4/4 live hand controls. No model or answer benchmark launch; gate remains unmet.

### 2026-10-14 — bounded reflexive integration prediction

Independent review approved candidate5f2d513 for integration experiment. Fixed121gold rows/119texts baseline27exact32wrong62no-parse; prediction: seven local-reflexive wrong readings become exact or honest abstentions, without exact regressions elsewhere. Reserve standard reflexives, license singular finite/base lexical direct-object binding only, preserve claim boundaries. Commands: merge --no-ff --no-commit astra/reflexive-implementation; register21controls; cabal build all; cabal test all; oracle; token-wrapped Explain and fresh default-parser121;29 Python contracts; hand4. Logs research/runs/reflexive-integration. No model/answerbenchmark. Reject on meaning regressions; independent result review before landing.

Reflexive result: all17 Haskell suites (1270 checks),29 scorer contracts, build/oracle/Explain and4/4 hand controls pass. Fresh fixed121/119texts:27exact32wrong62no-parse→34exact25wrong62no-parse. Exactly7local reflexive rows wrong→exact, no other status changes and no instrumentation/type/incomplete exclusions. Source/binary/gold hashes and per-case outputs in research/runs/reflexive-integration; prediction holds. Independent final review requested before landing. No model/answerbenchmark; Prover gate still closed.

Independent reviewer verified all fresh source/binary/case hashes, the seven exact selected DRS+claim tables and unchanged remainder, then approved reflexive landing. Explicit staging contains only reviewed implementation, suite registration, learner docs/inventory follow-up and state/log; unrelated dirty files remain untouched.

### 2026-10-14 — independently reviewed gold extension diagnostic

Prediction:28 new rows (9transitives,2titlednames,4relatives/orboth,7Prontocoordination,6PWbinding) retain substantial name/scope/nominal/coordination limitations on accepted reflexive61f52d8. Gold was source-checked and reviewed before this parse. Historical121 remains frozen; strict-English person-restricted rows must be reported separately from controlled-domain fixtures, never pooled for acceptance. Commands: token-wrapped test/fidelity/run.py --cases research/runs/gold-extension-baseline/cases.jsonl --binary research/runs/reflexive-integration/fidelity-reflexive --parser default --output research/runs/gold-extension-baseline/fresh.json. Branch hashes pinned in manifest.json. This is local construction fidelity, no answerbenchmark/model.

### 2026-10-14 — serial integration fidelity-contract-review (f3567ff)

Reviewer-approved branch only; overlapping untracked artifacts preserved under ignored integration-preserved. Prediction: unchanged production semantics preserve current fixed-input parser observations; gold representation corrections may change exact score and are identified by fixture hashes. Commands: git merge --no-ff --no-commit astra/fidelity-contract-review; cabal build all; cabal test all; scripts/check-oracle-boundary.sh; token-wrapped scripts/check-explain.sh;scorer contracts (counts and explicit expected failures in contracts.log); sealed source/binary-checked replay; live hand4. Logs research/runs/serial-merges/fidelity-contract-review.

Gold extension result (separate contracts, no pooled acceptance): {"compatible-extension-diagnostic": {"exact": 6, "wrong_but_typed": 0, "no_parse": 11, "type_failure": 0, "incomplete": 1, "error": 0}, "proverqa-strict-english-v1": {"exact": 0, "wrong_but_typed": 1, "no_parse": 1, "type_failure": 0, "incomplete": 0, "error": 0}, "proverqa-controlled-v1": {"exact": 0, "wrong_but_typed": 0, "no_parse": 2, "type_failure": 0, "incomplete": 0, "error": 0}, "strict-English": {"exact": 6, "wrong_but_typed": 0, "no_parse": 0, "type_failure": 0, "incomplete": 0, "error": 0}}. Historical121 remains34/25/62. Logs sealed gold-extension-baseline; no model/answerbenchmark. Prediction of unresolved limitations holds.

Result fidelity-contract-review: all merged-result gates passed,scorer contracts (counts and explicit expected failures in contracts.log), sealed fidelity replay and4/4 live hand controls. No model or answer benchmark launch; gate remains unmet.

### 2026-10-14 — serial integration gold-prover-names (69688d8)

Reviewer-approved branch only; overlapping untracked artifacts preserved under ignored integration-preserved. Prediction: unchanged production semantics preserve current fixed-input parser observations; gold representation corrections may change exact score and are identified by fixture hashes. Commands: git merge --no-ff --no-commit astra/gold-prover-names; cabal build all; cabal test all; scripts/check-oracle-boundary.sh; token-wrapped scripts/check-explain.sh;scorer contracts (counts and explicit expected failures in contracts.log); sealed source/binary-checked replay; live hand4. Logs research/runs/serial-merges/gold-prover-names.

Result gold-prover-names: all merged-result gates passed,scorer contracts (counts and explicit expected failures in contracts.log), sealed fidelity replay and4/4 live hand controls. No model or answer benchmark launch; gate remains unmet.

### 2026-10-14 — serial integration gold-prover-transitives (eb7b4f3)

Reviewer-approved branch only; overlapping untracked artifacts preserved under ignored integration-preserved. Prediction: unchanged production semantics preserve current fixed-input parser observations; gold representation corrections may change exact score and are identified by fixture hashes. Commands: git merge --no-ff --no-commit astra/gold-prover-transitives; cabal build all; cabal test all; scripts/check-oracle-boundary.sh; token-wrapped scripts/check-explain.sh;scorer contracts (counts and explicit expected failures in contracts.log); sealed source/binary-checked replay; live hand4. Logs research/runs/serial-merges/gold-prover-transitives.

Result gold-prover-transitives: all merged-result gates passed,scorer contracts (counts and explicit expected failures in contracts.log), sealed fidelity replay and4/4 live hand controls. No model or answer benchmark launch; gate remains unmet.

### 2026-10-14 — serial integration gold-prover-relatives (4eb9d18)

Reviewer-approved branch only; overlapping untracked artifacts preserved under ignored integration-preserved. Prediction: unchanged production semantics preserve current fixed-input parser observations; gold representation corrections may change exact score and are identified by fixture hashes. Commands: git merge --no-ff --no-commit astra/gold-prover-relatives; cabal build all; cabal test all; scripts/check-oracle-boundary.sh; token-wrapped scripts/check-explain.sh;scorer contracts (counts and explicit expected failures in contracts.log); sealed source/binary-checked replay; live hand4. Logs research/runs/serial-merges/gold-prover-relatives.

Result gold-prover-relatives: all merged-result gates passed,scorer contracts (counts and explicit expected failures in contracts.log), sealed fidelity replay and4/4 live hand controls. No model or answer benchmark launch; gate remains unmet.

### 2026-10-14 — serial integration gold-pronto-coordination (ef73c92)

Reviewer-approved branch only; overlapping untracked artifacts preserved under ignored integration-preserved. Prediction: unchanged production semantics preserve current fixed-input parser observations; gold representation corrections may change exact score and are identified by fixture hashes. Commands: git merge --no-ff --no-commit astra/gold-pronto-coordination; cabal build all; cabal test all; scripts/check-oracle-boundary.sh; token-wrapped scripts/check-explain.sh;scorer contracts (counts and explicit expected failures in contracts.log); sealed source/binary-checked replay; live hand4. Logs research/runs/serial-merges/gold-pronto-coordination.

Result gold-pronto-coordination: all merged-result gates passed,scorer contracts (counts and explicit expected failures in contracts.log), sealed fidelity replay and4/4 live hand controls. No model or answer benchmark launch; gate remains unmet.

### 2026-10-14 — serial integration gold-proofwriter-binding (f8bd7b3)

Reviewer-approved branch only; overlapping untracked artifacts preserved under ignored integration-preserved. Prediction: unchanged production semantics preserve current fixed-input parser observations; gold representation corrections may change exact score and are identified by fixture hashes. Commands: git merge --no-ff --no-commit astra/gold-proofwriter-binding; cabal build all; cabal test all; scripts/check-oracle-boundary.sh; token-wrapped scripts/check-explain.sh;scorer contracts (counts and explicit expected failures in contracts.log); sealed source/binary-checked replay; live hand4. Logs research/runs/serial-merges/gold-proofwriter-binding.

Result gold-proofwriter-binding: all merged-result gates passed,scorer contracts (counts and explicit expected failures in contracts.log), sealed fidelity replay and4/4 live hand controls. No model or answer benchmark launch; gate remains unmet.

### 2026-10-14 — serial integration coordination-diagnosis (889a1ce)

Reviewer-approved branch only; overlapping untracked artifacts preserved under ignored integration-preserved. Prediction: unchanged production semantics preserve current fixed-input parser observations; gold representation corrections may change exact score and are identified by fixture hashes. Commands: git merge --no-ff --no-commit astra/coordination-diagnosis; cabal build all; cabal test all; scripts/check-oracle-boundary.sh; token-wrapped scripts/check-explain.sh;scorer contracts (counts and explicit expected failures in contracts.log); sealed source/binary-checked replay; live hand4. Logs research/runs/serial-merges/coordination-diagnosis.

### 2026-10-14 — FOLIO mixed gold baseline before core feature trial

Reviewer approved b19d2e7 five strict-English diagnostic rows before parser observation:3relative/negative-quantifier scope contrasts (not3examples per refined scope),2mixed VP clauses;1exact input and4disclosed adaptations. Prediction: existing nominal/relative gaps leave most non-exact. Token-wrapped test/fidelity/run.py --cases research/runs/folio-mixed-baseline/cases.jsonl --binary research/runs/reflexive-integration/fidelity-reflexive --parser default --output research/runs/folio-mixed-baseline/fresh.json. No model/answerbenchmark; these form a separate strict diagnostic extension, historical121 untouched.

Result coordination-diagnosis: all merged-result gates passed,scorer contracts (counts and explicit expected failures in contracts.log), sealed fidelity replay and4/4 live hand controls. No model or answer benchmark launch; gate remains unmet.

FOLIOmixed baseline result5rows:1exact/3wrong/1no-parse; no exclusions. Sealed acceptedreflexive source/binary in folio-mixed-baseline. These strict-English diagnostic rows remain separate from historical121. Prediction of mostly non-exact held.

### 2026-10-14 — serial integration gold-folio-mixed (b19d2e7)

Reviewer-approved branch only; overlapping untracked artifacts preserved under ignored integration-preserved. Prediction: unchanged production semantics preserve current fixed-input parser observations; gold representation corrections may change exact score and are identified by fixture hashes. Commands: git merge --no-ff --no-commit astra/gold-folio-mixed; cabal build all; cabal test all; scripts/check-oracle-boundary.sh; token-wrapped scripts/check-explain.sh;scorer contracts (counts and explicit expected failures in contracts.log); sealed source/binary-checked replay; live hand4. Logs research/runs/serial-merges/gold-folio-mixed.

Result gold-folio-mixed: all merged-result gates passed,scorer contracts (counts and explicit expected failures in contracts.log), sealed fidelity replay and4/4 live hand controls. No model or answer benchmark launch; gate remains unmet.

### 2026-10-14 — symmetric composition feature trial

Reviewed candidatef761082 changes four composition rules: specialize the surviving argument when its whole category equals the matched inner result, symmetric to existing result specialization. No subterm-wide bareS unification. Prediction before integration: prevent finite clauses entering adjective slots and the exposed relative matrix-negation error; preserve all exact gold and claim barriers. Existing17suites1270checks +16new directcontrols passed worker; fused prospective overlay89/89 is dependency evidence only. Root commands: git merge --no-ff --no-commit astra/composition-features; register16controls; cabal build all; cabal test all; oracle; token Explain + fresh154/152texts;42scorerchecks(2documentedexpectedfailures);hand4. Frozen cases and baseline in research/runs/composition-integration. Contract panels remain separate; no pooled population/acceptance claim, no model/answerbenchmark. Reviewer must inspect fresh results before landing.

Composition result:18Haskell suites1286checks,42Pythonchecks40pass2documentedexpectedfailures,build/oracle/Explain/hand4 allpass. Frozen154/152texts keeps47exact; three FOLIOnegative-relative wrong→no-parse, no other statuschanges (26wrong80noparse1incomplete). Historical121unchanged34/25/62; strict-English11 becomes7exact0wrong4no-parse; othercontractpartitionsunchanged. Prediction of removing feature-invalid scope paths with no exact regressions holds; no new coverage claim. Reviewer independently verified source/binary/case hashes, actual zero-parse outputs, allgatelogs and approved landing. Fusedcandidate prospective89/89 remains separate future evidence, not acceptedproduction.

### 2026-10-14 — serial integration fused-relatives (fa15a45)

Reviewer-approved branch only; overlapping untracked artifacts preserved under ignored integration-preserved. Prediction: unchanged production semantics preserve current fixed-input parser observations; gold representation corrections may change exact score and are identified by fixture hashes. Commands: git merge --no-ff --no-commit astra/fused-relatives; cabal build all; cabal test all; scripts/check-oracle-boundary.sh; token-wrapped scripts/check-explain.sh;scorer contracts (counts and explicit expected failures in contracts.log); sealed source/binary-checked replay; live hand4. Logs research/runs/serial-merges/fused-relatives.

Result fused-relatives: all merged-result gates passed,scorer contracts (counts and explicit expected failures in contracts.log), sealed fidelity replay and4/4 live hand controls. No model or answer benchmark launch; gate remains unmet.

### 2026-10-14 — source trial fused-relative-implementation (80204c5)

Prediction: reviewed bounded construction improves intended scoped meanings without exact regressions or new wrong-but-typed cases. Frozen154/152texts and semantic contracts retained; previous accepted binary composition-integration. Commands: merge --no-ff --no-commit astra/fused-relative-implementation; register fused-relative; cabal build all; cabal test all; oracle; token-wrapped Explain and fresh154; scorer contracts; hand4. Evidence research/runs/fused-integration. Independent result review before commit/push; no model/answerbenchmark.

Fused result:19suites1375checks including89independent fusedcontrols,42Pythonchecks(40pass2documentedxfail),build/oracle/Explain/hand4allpass. Fresh154 statuses47exact26wrong80no-parse1incomplete unchanged from corebaseline; selectedDRS/claimobjects also allidentical. No benchmark-gold gain; prediction of improvement did not hold on this panel, while no-regression prediction held. Nominal-heavy relatives remain blocked. Reviewer verified every source hash and binary/cases hashes and approved bounded capability landing based on89 independent scope/locality/packing controls, without claiming coverage or opening modelgate.

### 2026-10-14 — source trial lexical-punctuation (ae680d2)

Prediction: reviewed bounded construction improves intended scoped meanings without exact regressions or new wrong-but-typed cases. Frozen154/152texts and semantic contracts retained; previous accepted binary fused-integration. Commands: merge --no-ff --no-commit astra/lexical-punctuation; register lexical-punctuation; cabal build all; cabal test all; oracle; token-wrapped Explain and fresh154; scorer contracts; hand4. Evidence research/runs/punctuation-integration. Independent result review before commit/push; no model/answerbenchmark.

Result lexical-punctuation ae680d2: all20 Haskell suites1514 checks, build/oracle/Explain/hand4 passed;42 Python40pass2 documented expected failures. Fresh154 remains47exact26wrong80no-parse1incomplete; selected DRS/claim objects also identical. Reviewer independently verified source/binary hashes and landing approved (notes4c74ebc). Prevents lexical words being silently discarded as punctuation; no measured fidelity gain or gate reopening.

Coordination pre-fresh prediction (operator specialist, before launch): frozen154 remains47exact26wrong80no-parse1incomplete; only direct list-OR target pronto-ground-or-2 remains blocked by nominal gaps. Comma-only restrictions and conditional boundaries preserve AND/implication. This trial checks nonregression and independently authored24 controls, not expected population coverage gain.

### 2026-10-14 — source trial coordination-implementation (4c37c66)

Prediction: reviewed bounded construction improves intended scoped meanings without exact regressions or new wrong-but-typed cases. Frozen154/152texts and semantic contracts retained; previous accepted binary punctuation-integration. Commands: merge --no-ff --no-commit astra/coordination-implementation; register coordination-list; cabal build all; cabal test all; oracle; token-wrapped Explain and fresh154; scorer contracts; hand4. Evidence research/runs/coordination-integration. Independent result review before commit/push; no model/answerbenchmark.

Result coordination4c37c66: all21 Haskell suites1538 checks; build/oracle/Explain/hand4;42Python40pass2xfail. Fresh154 statuses and selected objects identical punctuation baseline47/26/80/1, matching preregistered no-gain prediction. Independent reviewer verified source/binary hashes and approved landing. Added worker notes-only3ab0f72 prediction content explicitly, source unchanged. Explain replay fallback limitation documented in DESIGN/STUDY_PLAN. Primary FINDINGS now reflects paused D/E and current linguistic checkpoint. No model/answerbenchmark launched.

### 2026-10-14 — serial integration fidelity-contract-reporting (736e090)

Reviewer-approved branch only; overlapping untracked artifacts preserved under ignored integration-preserved. Prediction: unchanged production semantics preserve current fixed-input parser observations; gold representation corrections may change exact score and are identified by fixture hashes. Commands: git merge --no-ff --no-commit astra/fidelity-contract-reporting; cabal build all; cabal test all; scripts/check-oracle-boundary.sh; token-wrapped scripts/check-explain.sh;scorer contracts (counts and explicit expected failures in contracts.log); sealed source/binary-checked replay; live hand4. Logs research/runs/serial-merges/fidelity-contract-reporting.

Result fidelity-contract-reporting: all merged-result gates passed,scorer contracts (counts and explicit expected failures in contracts.log), sealed fidelity replay and4/4 live hand controls. No model or answer benchmark launch; gate remains unmet.

### 2026-10-14 — next narrow nominal investigation prediction

Worker nominal-universal-trial will first test explicit Every/each + lexical noun subjects and positive a/an + lexical noun predicates without name/bare-generic admission. Prediction: current grammar fails independently authored direct property predication; a provenance-bound captured noun property may repair this fragment without equative existential witnesses. Review concrete transitions before worker implementation; root fresh fidelity and all gates remain mandatory. No model/answerbenchmark launch.

### 2026-10-14 — serial integration semantic-contract-panels (743ef4f)

Reviewer-approved branch only; overlapping untracked artifacts preserved under ignored integration-preserved. Prediction: unchanged production semantics preserve current fixed-input parser observations; gold representation corrections may change exact score and are identified by fixture hashes. Commands: git merge --no-ff --no-commit astra/semantic-contract-panels; cabal build all; cabal test all; scripts/check-oracle-boundary.sh; token-wrapped scripts/check-explain.sh;scorer contracts (counts and explicit expected failures in contracts.log); sealed source/binary-checked replay; live hand4. Logs research/runs/serial-merges/semantic-contract-panels.

### 2026-10-14 — independent positive nominal gold baseline

Gold678571e authored and independently reviewed (notes4f91b06) before observation: three exact ProverQA English occupational/status predications under explicit present-context extensional contract. Prediction: accepted coordination binary lacks faithful nominal copula, so no new exact results expected; score all3 outcomes without weakening meanings. Command: token-wrapped fidelity runner on workerproverqa-positive-nominals.jsonl with frozen research/runs/coordination-integration/fidelity-candidate, output positive-nominals-baseline/report.json. This is local construction fidelity, not an answerbenchmark or model launch.

Result semantic-contract-panels: all merged-result gates passed,scorer contracts (counts and explicit expected failures in contracts.log), sealed fidelity replay and4/4 live hand controls. No model or answer benchmark launch; gate remains unmet.

### 2026-10-14 — serial integration linguistic-findings (f85e31b)

Reviewer-approved branch only; overlapping untracked artifacts preserved under ignored integration-preserved. Prediction: unchanged production semantics preserve current fixed-input parser observations; gold representation corrections may change exact score and are identified by fixture hashes. Commands: git merge --no-ff --no-commit astra/linguistic-findings; cabal build all; cabal test all; scripts/check-oracle-boundary.sh; token-wrapped scripts/check-explain.sh;scorer contracts (counts and explicit expected failures in contracts.log); sealed source/binary-checked replay; live hand4. Logs research/runs/serial-merges/linguistic-findings.

Runtime verification after owner restart: collaboration.list_agents shows coordinator plus eight specialists simultaneously running, each own isolated worktree. This verifies eight actual worker slots, not32. Shells fullaccess and original uncommitted unrelatedwork preserved. Positive nominal three-case baseline completed; compact outcomes [('prover-positive-nominal-1', 'no_parse'), ('prover-positive-nominal-2', 'no_parse'), ('prover-positive-nominal-3', 'no_parse')].

Result linguistic-findings: all merged-result gates passed,scorer contracts (counts and explicit expected failures in contracts.log), sealed fidelity replay and4/4 live hand controls. No model or answer benchmark launch; gate remains unmet.

### 2026-10-14 — serial integration modifier-order (e765ca9)

Reviewer-approved branch only; overlapping untracked artifacts preserved under ignored integration-preserved. Prediction: unchanged production semantics preserve current fixed-input parser observations; gold representation corrections may change exact score and are identified by fixture hashes. Commands: git merge --no-ff --no-commit astra/modifier-order; cabal build all; cabal test all; scripts/check-oracle-boundary.sh; token-wrapped scripts/check-explain.sh;scorer contracts (counts and explicit expected failures in contracts.log); sealed source/binary-checked replay; live hand4. Logs research/runs/serial-merges/modifier-order.

Replay integrity audit5894cd0 found6 synthetic failures in ignoredhelper, while current154file/hash/ID evidence remains consistent. Stopped newcachedreplay deliberately; modifier-order merge remains staged with priorgates passed, no commitpush. Portable reviewedverifier/producerhash repair underway. Earlier release evidence is not relabeled corrupt; do not call retrospective hashes producer seals.

### 2026-10-14 — replay hardening validation prediction

Prediction: explicit verifier rejects synthetic tampering/duplicates/missing frozen evidence and remains active under python-O; real audited154 snapshot passes without changing selected results or contract counts. Coordinator adapter binds all14 indexed fixtures (no optional skip), labels historical121 mixed, and records verifier/scorer/helper/hash provenance. Older report lacks producer observation digest: create only an explicitly retrospective audited snapshot after independent actualcache review, never retrofit producer seal. Resume pending modifier-order only after reviewer approves implementation and actual154verification; no parser/model launch for this check.

Result replayhardening026c173: reviewed verifier+coordinator adapter validate actual154 in ordinary and python-O modes, dataset case objects identical to prior linguistic-findings replay. Explicit retrospective seal producer_binding=false; report SHA de4c23d69241751b38a02474534dfff107e3892893d1873e0ebeeec7f8680a04, observations SHA5433d30930f9d8548a787443543967d6ce75700b48196be9c22c51855bff9185. Actual indexed gold membership bound. Modifier-order all prior merged-result gates remain passing; hand4 nowpassed,49Python47pass2xfail. Completing reviewed documentation merge; redproposal tests remain explicitly unregistered/knownfailures, no source or gold changes.

### 2026-10-14 — serial integration fidelity-seal-audit (026c173)

Reviewer-approved branch only; overlapping untracked artifacts preserved under ignored integration-preserved. Prediction: unchanged production semantics preserve current fixed-input parser observations; gold representation corrections may change exact score and are identified by fixture hashes. Commands: git merge --no-ff --no-commit astra/fidelity-seal-audit; cabal build all; cabal test all; scripts/check-oracle-boundary.sh; token-wrapped scripts/check-explain.sh;scorer contracts (counts and explicit expected failures in contracts.log); sealed source/binary-checked replay; live hand4. Logs research/runs/serial-merges/fidelity-seal-audit.

### 2026-10-14 — expanded independent construction gold baseline167

All13 additions reviewed before observation: nominal678571e(3), strictperson ec3605e(4), authoredobjectrelatives b0d8bb6(3), particleb649e61(3). Frozen fixture hashes/IDs in expanded-gold167/fixture-manifest.json. Prediction: original154 meanings/statuses unchanged under same accepted parser; positive nominal3 stayno-parse, unsupported particle/objectrelative/person-domain readings expose errors without goldweakening. Existing closed Someone scope may succeed. No pooled acceptance; separately report declaredcontracts/authored vs source membership. Command: token-wrapped fidelity run on frozen167 with copied accepted coordinationbinary, reviewed producerdigest field now active; output expanded-gold167/fresh.json. Local construction fidelity only, no answerbenchmark/model launch.

Result fidelity-seal-audit: all merged-result gates passed,scorer contracts (counts and explicit expected failures in contracts.log), sealed fidelity replay and4/4 live hand controls. No model or answer benchmark launch; gate remains unmet.

Expanded167 baseline independently approved reviewf599b96: original154 statuses+selectedobjects identical; new13 add2exact Someone and11no-parse. Totals49/26/91/1 are diagnosticbookkeeping only. Producerobservationsdigest nowpresent; verified fullsnapshot may supply explicit currentfixture subsets. Per-merge dataset-membership.json tracked in replaymanifest, currentgold must equalindex. Goldfiles added to requestedmembership only in their own reviewedmerge, no silentdenominator change.

### 2026-10-14 — serial integration name-ambiguity (bd30b1d)

Reviewer-approved branch only; overlapping untracked artifacts preserved under ignored integration-preserved. Prediction: unchanged production semantics preserve current fixed-input parser observations; gold representation corrections may change exact score and are identified by fixture hashes. Commands: git merge --no-ff --no-commit astra/name-ambiguity; cabal build all; cabal test all; scripts/check-oracle-boundary.sh; token-wrapped scripts/check-explain.sh;scorer contracts (counts and explicit expected failures in contracts.log); sealed source/binary-checked replay; live hand4. Logs research/runs/serial-merges/name-ambiguity.

### 2026-10-14 — first-divergence inspection for13 newgold rows

Prediction: two Someone adjective controls retain correct person-restricted witness/scope; remaining nominal/objectrelative/particle/complexEveryone examples fail at lexical-category or composition stages before DRS. Inspect actual offered gives/up categories before assuming a particle template is syntactically available. Token-wrapped copied accepted Explain executable, one13sentence REPL batch, all stages; source/binary/inputIDs recorded expanded-gold167/explain-manifest.json. No source edit or model/answerbenchmark launch; two sharedloader tokens enforced.

Result name-ambiguity: all merged-result gates passed,scorer contracts (counts and explicit expected failures in contracts.log), sealed fidelity replay and4/4 live hand controls. No model or answer benchmark launch; gate remains unmet.

### 2026-10-14 — serial integration particle-contract (38e20a1)

Reviewer-approved branch only; overlapping untracked artifacts preserved under ignored integration-preserved. Prediction: unchanged production semantics preserve current fixed-input parser observations; gold representation corrections may change exact score and are identified by fixture hashes. Commands: git merge --no-ff --no-commit astra/particle-contract; cabal build all; cabal test all; scripts/check-oracle-boundary.sh; token-wrapped scripts/check-explain.sh;scorer contracts (counts and explicit expected failures in contracts.log); sealed source/binary-checked replay; live hand4. Logs research/runs/serial-merges/particle-contract.

Result particle-contract: all merged-result gates passed,scorer contracts (counts and explicit expected failures in contracts.log), sealed fidelity replay and4/4 live hand controls. No model or answer benchmark launch; gate remains unmet.

### 2026-10-14 — serial integration acceptance-manifest (29c6524)

Reviewer-approved branch only; overlapping untracked artifacts preserved under ignored integration-preserved. Prediction: unchanged production semantics preserve current fixed-input parser observations; gold representation corrections may change exact score and are identified by fixture hashes. Commands: git merge --no-ff --no-commit astra/acceptance-manifest; cabal build all; cabal test all; scripts/check-oracle-boundary.sh; token-wrapped scripts/check-explain.sh;scorer contracts (counts and explicit expected failures in contracts.log); sealed source/binary-checked replay; live hand4. Logs research/runs/serial-merges/acceptance-manifest.

Follow-up lexical availability check: first Explain batch showed best tags only and explicitly hid alternatives, so it cannot establish absence of the proposed gives/give intransitive category. Prediction: full offered/interpretable category lists will distinguish a genuine missing licensed frame from ranking and semantic composition gaps. Reuse exact copied accepted Explain binary for4 focused rows with --all-readings --stage=tags, one lockedload; preserve both logs, no claiming absence from top-tag display.

Result acceptance-manifest: all merged-result gates passed,scorer contracts (counts and explicit expected failures in contracts.log), sealed fidelity replay and4/4 live hand controls. No model or answer benchmark launch; gate remains unmet.

### 2026-10-14 — serial integration explain-list-audit (409d3ab)

Reviewer-approved branch only; overlapping untracked artifacts preserved under ignored integration-preserved. Prediction: unchanged production semantics preserve current fixed-input parser observations; gold representation corrections may change exact score and are identified by fixture hashes. Commands: git merge --no-ff --no-commit astra/explain-list-audit; cabal build all; cabal test all; scripts/check-oracle-boundary.sh; token-wrapped scripts/check-explain.sh;scorer contracts (counts and explicit expected failures in contracts.log); sealed source/binary-checked replay; live hand4. Logs research/runs/serial-merges/explain-list-audit.

Result explain-list-audit: all merged-result gates passed,scorer contracts (counts and explicit expected failures in contracts.log), sealed fidelity replay and4/4 live hand controls. No model or answer benchmark launch; gate remains unmet.

### 2026-10-14 — serial integration quantifier-priorities (e07ec3f)

Reviewer-approved branch only; overlapping untracked artifacts preserved under ignored integration-preserved. Prediction: unchanged production semantics preserve current fixed-input parser observations; gold representation corrections may change exact score and are identified by fixture hashes. Commands: git merge --no-ff --no-commit astra/quantifier-priorities; cabal build all; cabal test all; scripts/check-oracle-boundary.sh; token-wrapped scripts/check-explain.sh;scorer contracts (counts and explicit expected failures in contracts.log); sealed source/binary-checked replay; live hand4. Logs research/runs/serial-merges/quantifier-priorities.

### 2026-10-14 — nominal-universal source preflight

Source8e2a6ad reviewed fortrial; test directEvery/each lexicalN+a/anN with existingstrictPOS capability before relaxing it. Prediction:59focusedchecks establish intended directproperty meanings, but frozen167 may show no coveragegain because lexical/nesting/name restrictions remain; require zero exactregressions and zero newlywrong selections. Worker may build its own fidelity executable and run one locked167preflight against samefrozeninputs, no benchmark/LLM. Preserve source/binary/case/observationsdigests. This never substitutes for rootmerged fullgates/freshset beforelanding.

Result quantifier-priorities: all merged-result gates passed,scorer contracts (counts and explicit expected failures in contracts.log), sealed fidelity replay and4/4 live hand controls. No model or answer benchmark launch; gate remains unmet.

### 2026-10-14 — serial integration particle-licensing (c69ec8e)

Reviewer-approved branch only; overlapping untracked artifacts preserved under ignored integration-preserved. Prediction: unchanged production semantics preserve current fixed-input parser observations; gold representation corrections may change exact score and are identified by fixture hashes. Commands: git merge --no-ff --no-commit astra/particle-licensing; cabal build all; cabal test all; scripts/check-oracle-boundary.sh; token-wrapped scripts/check-explain.sh;scorer contracts (counts and explicit expected failures in contracts.log); sealed source/binary-checked replay; live hand4. Logs research/runs/serial-merges/particle-licensing.

Result particle-licensing: all merged-result gates passed,scorer contracts (counts and explicit expected failures in contracts.log), sealed fidelity replay and4/4 live hand controls. No model or answer benchmark launch; gate remains unmet.

### 2026-10-14 — serial integration nominal-envelope (458565d)

Reviewer-approved branch only; overlapping untracked artifacts preserved under ignored integration-preserved. Prediction: unchanged production semantics preserve current fixed-input parser observations; gold representation corrections may change exact score and are identified by fixture hashes. Commands: git merge --no-ff --no-commit astra/nominal-envelope; cabal build all; cabal test all; scripts/check-oracle-boundary.sh; token-wrapped scripts/check-explain.sh;scorer contracts (counts and explicit expected failures in contracts.log); sealed source/binary-checked replay; live hand4. Logs research/runs/serial-merges/nominal-envelope.

Result nominal-envelope: all merged-result gates passed,scorer contracts (counts and explicit expected failures in contracts.log), sealed fidelity replay and4/4 live hand controls. No model or answer benchmark launch; gate remains unmet.

### 2026-10-14 — serial integration abbreviation-design (95a40cd)

Reviewer-approved branch only; overlapping untracked artifacts preserved under ignored integration-preserved. Prediction: unchanged production semantics preserve current fixed-input parser observations; gold representation corrections may change exact score and are identified by fixture hashes. Commands: git merge --no-ff --no-commit astra/abbreviation-design; cabal build all; cabal test all; scripts/check-oracle-boundary.sh; token-wrapped scripts/check-explain.sh;scorer contracts (counts and explicit expected failures in contracts.log); sealed source/binary-checked replay; live hand4. Logs research/runs/serial-merges/abbreviation-design.

Result abbreviation-design: all merged-result gates passed,scorer contracts (counts and explicit expected failures in contracts.log), sealed fidelity replay and4/4 live hand controls. No model or answer benchmark launch; gate remains unmet.

### 2026-10-14 — serial integration prover-occurrence-strata (698a187)

Reviewer-approved branch only; overlapping untracked artifacts preserved under ignored integration-preserved. Prediction: unchanged production semantics preserve current fixed-input parser observations; gold representation corrections may change exact score and are identified by fixture hashes. Commands: git merge --no-ff --no-commit astra/prover-occurrence-strata; cabal build all; cabal test all; scripts/check-oracle-boundary.sh; token-wrapped scripts/check-explain.sh;scorer contracts (counts and explicit expected failures in contracts.log); sealed source/binary-checked replay; live hand4. Logs research/runs/serial-merges/prover-occurrence-strata.

### 2026-10-14 — continuation runtime and nominal preflight

Read STATE then ASTRA_GOAL; full-access shell commands succeed without sandbox overrides. Runtime list_agents confirms root plus eight simultaneously running specialists after followup_task restarts. New tasks use isolated branches/worktrees and disjoint proposal/test/notes ownership. No configuration-cap inference. Existing serial docs/gold queue continues; no second coordinator merge.

Nominal-universal8e2a6ad authorized preflight completed89.03s: all167 statuses and selected meanings unchanged (49exact26wrong91no-parse1incomplete), zero coverage gain. Candidate source and binary manifests checked by worker; independent reviewer verifying evidence before root merged-result trial. Source remains frozen. No model or answer-benchmark launches.

Result prover-occurrence-strata: all merged-result gates passed,scorer contracts (counts and explicit expected failures in contracts.log), sealed fidelity replay and4/4 live hand controls. No model or answer benchmark launch; gate remains unmet.

### 2026-10-14 — serial integration prover-positive-nominals (678571e)

Reviewer-approved branch only; overlapping untracked artifacts preserved under ignored integration-preserved. Prediction: unchanged production semantics preserve current fixed-input parser observations; gold representation corrections may change exact score and are identified by fixture hashes. Commands: git merge --no-ff --no-commit astra/prover-positive-nominals; cabal build all; cabal test all; scripts/check-oracle-boundary.sh; token-wrapped scripts/check-explain.sh;scorer contracts (counts and explicit expected failures in contracts.log); sealed source/binary-checked replay; live hand4. Logs research/runs/serial-merges/prover-positive-nominals.

Result prover-positive-nominals: all merged-result gates passed,scorer contracts (counts and explicit expected failures in contracts.log), sealed fidelity replay and4/4 live hand controls. No model or answer benchmark launch; gate remains unmet.

### 2026-10-14 — serial integration prover-person-gold (ec3605e)

Reviewer-approved branch only; overlapping untracked artifacts preserved under ignored integration-preserved. Prediction: unchanged production semantics preserve current fixed-input parser observations; gold representation corrections may change exact score and are identified by fixture hashes. Commands: git merge --no-ff --no-commit astra/prover-person-gold; cabal build all; cabal test all; scripts/check-oracle-boundary.sh; token-wrapped scripts/check-explain.sh;scorer contracts (counts and explicit expected failures in contracts.log); sealed source/binary-checked replay; live hand4. Logs research/runs/serial-merges/prover-person-gold.

Result prover-person-gold: all merged-result gates passed,scorer contracts (counts and explicit expected failures in contracts.log), sealed fidelity replay and4/4 live hand controls. No model or answer benchmark launch; gate remains unmet.

### 2026-10-14 — serial integration folio-object-relative-gold (b0d8bb6)

Reviewer-approved branch only; overlapping untracked artifacts preserved under ignored integration-preserved. Prediction: unchanged production semantics preserve current fixed-input parser observations; gold representation corrections may change exact score and are identified by fixture hashes. Commands: git merge --no-ff --no-commit astra/folio-object-relative-gold; cabal build all; cabal test all; scripts/check-oracle-boundary.sh; token-wrapped scripts/check-explain.sh;scorer contracts (counts and explicit expected failures in contracts.log); sealed source/binary-checked replay; live hand4. Logs research/runs/serial-merges/folio-object-relative-gold.

Independent reviewer bb18e0b verified nominal preflight39source/Export hashes against frozen8e2a6ad, copied accepted Python tools, binary/cases/observations, and identical167selected objects/statuses; observations are byte-identical to accepted baseline. Root trial remains required. Reviewer approved DESIGN expanded-gold/first-divergence section; clarified independent particle gold already frozen and concrete implementation review still required.

Result folio-object-relative-gold: all merged-result gates passed,scorer contracts (counts and explicit expected failures in contracts.log), sealed fidelity replay and4/4 live hand controls. No model or answer benchmark launch; gate remains unmet.

### 2026-10-14 — serial integration particle-gold (b649e61)

Reviewer-approved branch only; overlapping untracked artifacts preserved under ignored integration-preserved. Prediction: unchanged production semantics preserve current fixed-input parser observations; gold representation corrections may change exact score and are identified by fixture hashes. Commands: git merge --no-ff --no-commit astra/particle-gold; cabal build all; cabal test all; scripts/check-oracle-boundary.sh; token-wrapped scripts/check-explain.sh;scorer contracts (counts and explicit expected failures in contracts.log); sealed source/binary-checked replay; live hand4. Logs research/runs/serial-merges/particle-gold.

Result particle-gold: all merged-result gates passed,scorer contracts (counts and explicit expected failures in contracts.log), sealed fidelity replay and4/4 live hand controls. No model or answer benchmark launch; gate remains unmet.

### 2026-10-14 — source trial token-boundaries (821ea12)

Prediction: tokenizer changes fix boundary controls; bounded nominal v1 fixes authored scoped controls. Neither is predicted to change the frozen167 statuses or selected meanings; any exact regression or new wrong-but-typed case blocks landing. Frozen167 cases and separate semantic contracts retained; previous accepted binary expanded-gold167. Commands: merge --no-ff --no-commit astra/token-boundaries; register token-boundaries; cabal build all; cabal test all; oracle; token-wrapped Explain and fresh167; scorer contracts; hand4. Evidence research/runs/token-boundaries-integration. Independent result review before commit/push; no model/answerbenchmark.

### 2026-10-14 — tokenizer integrated release

Tokenizer821ea12 merged with37 independent controls. All22Haskell suites(1575checks),77Python(75pass,2documentedexpectedfailures), build/oracle/Explain andhand4 pass. Fresh167 retains every status and selected meaning:49exact26wrong91no-parse1incomplete. Observationdigest identical to accepted expanded167. Reviewer independently verified source,binary,cases,observations and approved landing. No coverage gain or gate opening. Evidence research/runs/token-boundaries-integration; replay adapter and serialhandbinary now use this newsourcecache. Reviewed DESIGN expandedgold/first-divergence account included.

### 2026-10-14 — source trial nominal-universal-trial (8e2a6ad)

Prediction: tokenizer changes fix boundary controls; bounded nominal v1 fixes authored scoped controls. Neither is predicted to change the frozen167 statuses or selected meanings; any exact regression or new wrong-but-typed case blocks landing. Frozen167 cases and separate semantic contracts retained; previous accepted binary token-boundaries-integration. Commands: merge --no-ff --no-commit astra/nominal-universal-trial; register nominal-universal; cabal build all; cabal test all; oracle; token-wrapped Explain and fresh167; scorer contracts; hand4. Evidence research/runs/nominal-universal-integration. Independent result review before commit/push; no model/answerbenchmark.

### 2026-10-14 — bounded nominal universal release

Nominal8e2a6ad merged without source changes;59 independent controls registered. All23Haskell suites(1634checks), build/oracle/Explain,77Python(75pass2existingexpectedfailures),hand4 pass. Fresh16789.05s retains49exact26wrong91no-parse1incomplete and every selected object; observations digest identical to tokenizer baseline. Independent reviewer rehashed candidate binary/source/cases/observations and approved landing. No measured corpus gain; Pronto POS inventory independently explains v1 necessary-gate failure on all86788 matching surface opportunities in observed snapshot. DESIGN and STUDY_PLAN scoped updates reviewed. Next particle then further bounded source trials; model/benchmark gate closed.

### 2026-10-14 — source trial particle-implementation-plan (c8b34c4)

Prediction: Licensed adjacent give-up is predicted to repair the three independently frozen particle cases; preserve every other exact result and introduce no new wrong-but-typed case. Actual survival and selected readings remain unmeasured. Frozen167 cases and separate semantic contracts retained; previous accepted binary nominal-universal-integration. Commands: merge --no-ff --no-commit astra/particle-implementation-plan; register particle-lexeme; cabal build all; cabal test all; oracle; token-wrapped Explain and fresh167; scorer contracts; hand4. Evidence research/runs/particle-integration. Independent result review before commit/push; no model/answerbenchmark.

Particle integration compatibility: initialize new nominal role to NominalPlain on the complete particle span, as reviewer prescribed; no pending nominal capability is minted.

### 2026-10-14 — particle release result

Prediction held: three independent give-up controls change no-parse→exact, all164other statuses and selected objects unchanged. Frozen16752exact26wrong88no-parse1incomplete; one source sentence and two authored controls, no population extrapolation. All24Haskell suites(1669checks),build/oracle/Explain,77Python75pass2existingexpectedfailures,hand4 pass. Reviewer61a7638 independently verified source,binary,cases,observations and each changed DRS/claim boundary. Only merged-source adaptation beyondc8b34c4 is NominalPlain initialization. ASTRA operational cap paragraph clarified historical8 vs owner32 and observed9running, without claiming tested32capacity. No model/benchmarklaunch.

Prediction for accepted59955b6 targetedparticle Explain diagnostics: Pipeline meanings match threeexact particle gold; separate derivation replay may fail to reconstruct span seed and must report honest fallback. Frozen Explainbinary/source manifest copied to particle-integration before nextsourcebuild. Specialist writes outputs in ownignoredruns, underglobaltoken; no model/benchmark.

### 2026-10-14 — source trial lemma-fidelity-plan (0c1da37)

Prediction: Eligible plain-N plural readings should use the independently specified singular predicate, preserving scope and all exact cases. Actual dictionary eligibility is unknown; no promise that all seven noun-error rows improve. Any new wrong or exact regression blocks landing. Frozen167 cases and separate semantic contracts retained; previous accepted binary particle-integration. Commands: merge --no-ff --no-commit astra/lemma-fidelity-plan; register noun-lemma; cabal build all; cabal test all; oracle; token-wrapped Explain and fresh167; scorer contracts; hand4. Evidence research/runs/noun-lemma-integration. Independent result review before commit/push; no model/answerbenchmark.

### 2026-10-14 — bounded noun lemma release

Noun0c1da37 merged unchanged. All25Haskell suites(1702checks),build/oracle/Explain,77Python(75pass2existingexpectedfailures),hand4 pass. Reviewer independently verified source/binary/cases/observations and three selected deltas: birds→bird in folio-some-2 and folio-some-not-2, monkeys→monkey in folio-extended-universal-3. Bindings/operators/claimstatus preserved; consequent hawks/mammals remainunmatched, so zeroexactgain and all167statuses52/26/88/1 unchanged. Allother selectedobjects unchanged. Prediction of bounded lexicalnormalization holds only where actuallicense fires; broader seven-casegain was explicitlynotpredicted. Evidence noun-lemma-integration.

### 2026-10-14 — expanded173 accepted baseline prediction

Before Everyone source merge, measure unchanged accepted169c761 on frozen173 SHA327dd14c96bb4e2c375f4f9f46025de28dfc7fca9b9e149c85f986345d1d1f3a, independently frozen/reviewed48d86af beforeobservations. Prediction original167 statuses+selectedobjects identical to noun-lemma-integration; six new strictperson authored controls expose current Everyone gap, no prior outcome assumption. Command: token-wrapped test/fidelity/run.py --cases research/runs/expanded173-baseline/cases.jsonl --binary research/runs/expanded173-baseline/fidelity-candidate --parser default --output research/runs/expanded173-baseline/fresh.json. Membership stays167 until newfixturemerge; no model/answerbenchmark.

Also freeze accepted169c761 Explainbinary+source manifest in noun-lemma-integration for one26-wrong-case first-divergence diagnostic. Prediction selectedwrong meanings match currentcache; actual category causes remain unknown pending trace. Worker uses one token-wrapped batch, no goldchanges.

### 2026-10-14 — serial integration pronto-nominal-coverage-plan (0faf6b8)

Reviewer-approved branch only; overlapping untracked artifacts preserved under ignored integration-preserved. Prediction: unchanged production semantics preserve current fixed-input parser observations; gold representation corrections may change exact score and are identified by fixture hashes. Commands: git merge --no-ff --no-commit astra/pronto-nominal-coverage-plan; cabal build all; cabal test all; scripts/check-oracle-boundary.sh; token-wrapped scripts/check-explain.sh;scorer contracts (counts and explicit expected failures in contracts.log); sealed source/binary-checked replay; live hand4. Logs research/runs/serial-merges/pronto-nominal-coverage-plan.

### 2026-10-14 — memory-bounded concurrency adjustment

Sixteen CPUs visible,13.5GiB availableRAM and no swap use. Recorded Explain peak163072KiB; later bounded lexical extraction peak263936KiB is larger. floor(10,000,000,000/(263936*1024))=37, so raise conservative global reader/loader tokens2→3, still far below measured memorybound. This permits independent acceptedbaseline, requiredExplaingate and targetedfirst-divergence batch concurrently. Shared flockwrapper retained; processes already waiting under oldlimit may continue using2. No model/answerbenchmark launch or gate relaxation.

Result pronto-nominal-coverage-plan: all merged-result gates passed,scorer contracts (counts and explicit expected failures in contracts.log), sealed fidelity replay and4/4 live hand controls. No model or answer benchmark launch; gate remains unmet.

Expanded173 baseline independentreview7bacc19: accepted169c761original167statuses/selectedobjects unchanged; sixauthoredEveryone additions allwrong due everyone(x) instead ofperson, otherdeclaredscope intact. Baseline52exact32wrong88no-parse1incomplete is diagnosticdenominatorexpansion, notregression. Reviewed173frozen fixture nowusedforEveryone source trial; newdataset enters explicitmembership onlyafterfixturemerge. ProntoPOSaudit2d1cae6 pushed allgates whilebaseline sourcedidenticalHaskell.

### 2026-10-14 — source trial everyone-closed-plan (ecd75dd)

Prediction: Exact offered-NP Everyone should receive strict person-restricted universal meaning, while reserved unsupported shapes fail closed rather than lexicalizing everyone(x). Legacy unrestricted and strict-person panels stay separate and unchanged; gains and wrong-to-no-parse outcomes must be distinguished. Frozen173 cases and separate semantic contracts retained; previous accepted binary expanded173-baseline. Commands: merge --no-ff --no-commit astra/everyone-closed-plan; register everyone-closed; cabal build all; cabal test all; oracle; token-wrapped Explain and fresh173; scorer contracts; hand4. Evidence research/runs/everyone-closed-integration. Independent result review before commit/push; no model/answerbenchmark.

### 2026-10-14 — Everyone NP release

Independent final review approved landing: all26 Haskell suites (1720checks), build/oracle/Explain, hand4 and77 Python contracts (75pass,2existing expected failures). Frozen173 improves52/32/88/1 to59exact25wrong88no-parse1incomplete. Six independent authored strict-person controls and prover-who-restriction-1 change wrong→exact. Two legacy unrestricted-domain cases change only everyone→person restriction and remain wrong under unchanged gold; all164 other selected meanings unchanged. Prediction holds for licensed NP paths, with no exact regression/new wrong. Binary b939e551ca9741cc877337f1c4c8b66d8a50be8b709b64d03a9b3e9342f98c0f; observations73d13a81846ae6e9e22534e6af7fbcccb2802a1897921923725542e07ffc684c. Separate contracts retained; mixed diagnostic does not open benchmark gate. Replay/hand pointers updated to everyone-closed-integration. Shell fullaccess verified and runtime root+8 running observed again after refresh.
