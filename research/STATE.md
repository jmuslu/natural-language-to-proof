# Research state

- Phase: B complete; separate oracle-gate strengthening; A complete. Independent C design, D solver, E raw baselines active.
- Last commit: `24c3cc2` (pushed); branch `astra/research`. Required reading complete.
- Next three actions:
  1. Commit/push gate-only checkpoint (all gates passed); then integrate C production algebra.
  2. Release agents to production C algebra and D exporter once gate checkpoint is pushed.
  3. Integrate persistent parser export with Python Horn/Z3 backends and measure B/C/D benchmark conditions.
- Results: B default theory exact86.7%, POS93.0%; whole32/120 versus65/120; zero converted-wrong but16 typed/rejected bad DRSs. POS repairs round, not kind (no JJ evidence). Corpus6/7 before expectation correction; local29/29. D inference31/31 green.
- Optional corpus verification complete8/8; `research/runs/phase-b/corpus-release.log`. Python D/E tests38/38.
- Running jobs: root `bash research/run-gates.sh oracle-gate-strengthening`, logs `research/runs/oracle-gate-strengthening/`. Inventory agent ProverQA-low complete90/120; fresh ProverQA-high session94974 and FOLIO-low session43060, then ProntoQA, logs `research/runs/phase-e-baselines/`. Other B corpus/coverage/Explain jobs complete. Strength agent new tests prepared, existing source frozen until checkpoints. Semantics agent B doc updates and D exporter new files only.
- Tools: research/.venv z3-solver4.15.3.0 installed successfully.
- Open questions: retained spurious coordination readings, dictionary-POS limits, source capability binding in graph, FOL versus signed Horn semantics. No main/tag changes.
