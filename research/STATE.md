# Research state

- Phase: A, all baseline gates passed; known-deviation batch loading/running.
- Last commit: `4843c52` (starting specification); branch `astra/research`.
- Required reading completed in specification order, including every listed source module and Explain.hs.
- Next three actions:
  1. Finish exec session 36258 and inspect research/runs/phase-a/deviations.log; record each deviation.
  2. Prepare and run Phase B failing regressions in isolated runghc/ghc processes, with predictions logged first.
  3. Implement disjoint oracle, pronoun, and CCG repairs; run all gates before each implementation push.
- Running jobs: Phase A runner active in exec session 36258; output in `research/runs/phase-a/` (ignored).
- Open questions: oracle admission also exposes candidate constructors/coercion; graph strength is currently Boolean reachability plus deduplication, not a graded algebra. No solver installed. No changes to main/tags authorized.
