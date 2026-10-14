# Research state

- Phase: C production algebra + D solver/export integration; A/B complete and pushed. E baselines active.
- Last commit: `7afac4d` (pushed, oracle gate18 negatives); prior B `24c3cc2`. Branch `astra/research`.
- Next three actions:
  1. Commit/push verified C algebra + D infrastructure checkpoint; all gates passed1138, Python38.
  2. Snapshot compiled persistent parser and collect gold-free caches on all four120-item benchmark samples.
  3. Evaluate Horn/FOL with top/skeptical/credulous policies, then generate C graph prompts and fallback experiments.
- Parser caches: `bash research/run-parser-caches.sh` for all480 sample items twice (default/POS), outputs `research/runs/phase-d/parses-{default,pos}.jsonl`; one model load per condition.
- Running jobs: inventory agent FOLIO-low complete92/120; contemporaneous ProverQA-high session94974 and ProntoQA-low session61855, outputs `research/runs/phase-e-baselines/`. Root phase-cd gates complete green; logs `research/runs/phase-cd/`. Parser caches still active.
- C candidate:53/53 properties/regressions, old Substrate114/114 compatibility; production integration complete, full gates pending. F64 generated benchmark matches independent expected outcomes; raw F run queued with inventory agent.
- D candidate: Python solver/runner38/38; Haskell exporter22/22, shared reading API and Explain migration complete. z3-solver4.15.3.0 in research/.venv.
- B results: default exact86.7% theory/90.5% q/32 whole; POS93.0%/95.6%/65 whole of120. 0 converted-wrong,16 typed/rejected bad meanings; round repaired, kind no JJ remains unsupported. Real-corpus8/8.
- Open questions: retained wrong coordination alternatives; beam/cap completeness, FOL vs signed Horn benchmark conventions, graph source/capability binding. No main/tag changes.
