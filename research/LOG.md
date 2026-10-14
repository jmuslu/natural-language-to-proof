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
