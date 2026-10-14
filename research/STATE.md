# Research state

- Owner override (2026-10-14): Phase E primary weak C/D models are gemini-3.1-flash-lite budget0 and gemma-4-26b-a4b-it minimal via bench/common/run_gemini.py, against each own saved raw120 and GPT-5.5 high. GPT low/high is effort-only, not weak/strong. Small-model Gemini free quota is usable; throttle and back off429, logquota failures. Key only sourced insidecallprocess, neverprinted.
- Phase: D solver hardening and E comparisons; A/B/C complete and pushed, F generated benchmark ready, G audits documented.
- Last commit: `185691c`; preparing tested scoped-admission/D/F/G integration checkpoint. Branch `astra/research`.
- Next three actions:
  1. Commit/push validated source integration; stop GPT primary-C jobs preserving partial outputs and adapt provider runner for the two specified small models.
  2. Verify own small-model raw120 baselines; run throttled Gemini/Gemma C/D on sealed caches with paired reports.
  3. Seal parser caches by benchmark, measure B policies, then C graph and residual-translation pilots and full A/B/C/D comparisons.
- Parser jobs: session69989 runs `bash research/run-parser-caches.sh`;480 items each default/POS, outputs `research/runs/phase-d/parses-{default,pos}.jsonl`. Rolling default/POS collection; latest checkpoint113/101 records, still ProverQA. Binary snapshotted.
- Gates: graph-capability-gate complete1138 Haskell checks/11 suites,19 negative+2 positive oracle clients, all Explain checks.
- D: solver/runner/domain/currentLLM84 tests green; retraction cabal5/5. Prover pilot12 B zero coverage for all policies.
- E: C pilot12 scored7/12; translation pilot still active. All raw baselines complete. Current Prover low90/high89 of120; FOLIO low92 versus historicalhigh99; Pronto low116 versus historicalhigh120. Graph prompt reviewed; llm hardening and independent audit before calls.
- F: production graph64/64 exact labels/support, rawlow63/64; registered executable built and5/5 tests green.
- G: restored Threading loses pronoun coverage; Alternatives modifier/head asymmetry; SEAMS audit includes scoped-claim caveat.
- Scope release blocker repaired: central closed-condition oracle guard;30 focused scope checks + finite countermodel/regressions, full gates passed.
- Open: parser semantic errors, beam/cap completeness, benchmark domain conventions, fallback translation quality, costs and paired comparisons. No main/tag changes.
- Diagnostic Explain batch: `python3 research/runs/prover-meaning-audit/run.py`, three gold-free lexical/meaning controls; output explain.log.
- Full gates passed: `bash research/run-gates.sh scoped-reasoning`, driver/logs under research/runs/scoped-reasoning*. Haskell source frozen.
- Full ProverQA B default matrix active: sealed proverqa-default120.jsonl, output research/runs/phase-d/proverqa-default-matrix/. POS sealing pending120complete records.
- Sealed complete120 caches ready: proverqa-default120, proverqa-pos120, folio-default120 under research/runs/phase-d. DefaultProver B matrix41079 active; C12030735 active; translation pilot1907 active.
- Gemini owner correction supersedes ASTRA_GOAL §1 quota/model note. inventory agent stopping GPT Cjobs and adapting provider runner; strength_design updating baseline manifests.
