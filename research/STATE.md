# Research state

- Phase: D solver hardening and E comparisons; A/B/C complete and pushed, F generated benchmark ready, G audits documented.
- Last commit: `abf7364`; preparing separate graph-capability gate commit. Branch `astra/research`.
- Next three actions:
  1. Commit/push the passing19-case oracle gate separately, then fix the reproduced malformed-DRS crash and Horn deadline overrun.
  2. Integrate ProofWriter-only domain policy and register/run the64-case retraction executable; run Python checks and full gates.
  3. Seal parser caches by benchmark, measure B policies, then C graph and residual-translation pilots and full A/B/C/D comparisons.
- Parser jobs: session69989 runs `bash research/run-parser-caches.sh`;480 items each default/POS, outputs `research/runs/phase-d/parses-{default,pos}.jsonl`. At latest check52/47 records, still ProverQA. Binary snapshotted.
- Gates: graph-capability-gate complete1138 Haskell checks/11 suites,19 negative+2 positive oracle clients, all Explain checks.
- D: original38 Python checks; audit regressions currently RED:8 malformed-condition errors and10ms Horn join takes0.983s. Domain adapter17green. Prover pilot12 B zero coverage for all policies.
- E: all raw baselines complete. Current Prover low90/high89 of120; FOLIO low92 versus historicalhigh99; Pronto low116 versus historicalhigh120. Graph prompt reviewed; llm hardening and independent audit before calls.
- F: production graph64/64 exact labels/support, rawlow63/64; benchmark adapter registration pending.
- G: restored Threading loses pronoun coverage; Alternatives modifier/head asymmetry; SEAMS audit includes scoped-claim caveat.
- Open: parser semantic errors, beam/cap completeness, benchmark domain conventions, fallback translation quality, costs and paired comparisons. No main/tag changes.
