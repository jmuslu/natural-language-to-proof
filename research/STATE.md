# Research state

- Phase: OWNER REDIRECT — construction inventories, learner-facing category/meaning design, independent meaning fidelity gold. Original ASTRA_GOAL remains active; saved usage resets authorized without asking again.
- Branch: astra/research only. Last pushed d88b1e5; reviewed foundation checkpoint pushed (licensed N/NP repair, fidelity exporter/scorer, Pronto gold). Preserve remaining provider/report/solver/plot work.
- Next three actions:
  1. Foundation d88b1e5 pushed; ProofWriter inventory4f14434 verified with all gates and fidelity replay; commit/push now, then other approved branches one at a time.
  2. Assemble CONSTRUCTIONS.md from four benchmark sections and DESIGN.md from construction-family proposals. Retain unresolved/unsupported counts; ProverQA is LLM-verbalized, not proven finite English templates.
  3. Integrate independent Prover/FOLIO/ProofWriter gold, resolve representation conventions before template implementation; reviewer checks gold + Boxer/ccg2lambda. Implement general rules in frequency order, measuring exact/wrong-but-typed/no-parse without dropping failures.
- Fidelity gate: NO new model/answer benchmark/LLM runs. ProverQA >=90% exact and near-zero wrong-but-typed required before Phase E; current diagnostic sets do not certify this gate. Existing jobs may finish/save; old solver processes no longer active at recovery inspection.
- Gates: frozen cabal build all and all13 test suites pass (1199 checks); oracle boundary and Explain smoke pass. Fidelity18 contract tests pass; live hand4/4 exact. Reviewer synthetic-int protocol regression repaired using finite integral JSON numbers, with live wire regression.
- Parallelism: eight specialists actually accepted concurrently, not a claim of32 verified. Full-access restart resolves bwrap failure. Workers use isolated /home/gram/astra-wt/<name> worktrees and astra/<name> branches, own notes only, explicit commits. Root alone STATE/LOG/cabal/integration/push. Current branches: inventory-{proverqa,prontoqa,proofwriter,folio}, gold-{proverqa,folio,proofwriter}, design-{operators,quantifiers,relatives,particles,names}, review. Remove each worktree after merge/abandonment, preserving transferred dirt.
- Memory: Explain CCGbank load peak163072KiB,85.21s, no swap. 10GB formula floor59; effective cap2 to allow larger parse/build memory. Every corpus-loading process must use `python3 /home/gram/nl2proof-astra/scripts/with-ccgbank-slot.py COMMAND`; shared locks /home/gram/astra-wt/.ccgbank-slots. Prefer sealed root research/runs caches. Default diagnostic85-input load finished21exact/24wrong/40no-parse; Prover7/24exact. Sealed replay and source hashes in research/runs/integration-fidelity. No corpus process active.
- Recovery artifacts: research/runs/recovery-gates/; original dirty snapshot safely copied to research/runs/worktree-transfer/ (manifest40files), and needed artifacts copied into each worktree. Some branches contain unrelated copied dirt: never stage it indiscriminately.
- Scope: explicit staging, predictions before experiments, gates before push origin astra/research; no secrets/raw datasets/main/tags. Sole coordinator this session.

- Active serial integration: inventory-proverqa (b6278c2), preserve dirty work; all gates/fidelity passed in research/runs/serial-merges/inventory-proverqa; committing/pushing now.

- Active serial integration: inventory-prontoqa (d0c8436), preserve dirty work; all gates/fidelity passed in research/runs/serial-merges/inventory-prontoqa; committing/pushing now.

- Active serial integration: inventory-folio (634bc10), preserve dirty work; all gates/fidelity passed in research/runs/serial-merges/inventory-folio; committing/pushing now.

- Active serial integration: gold-folio (169165e), preserve dirty work; all gates/fidelity passed in research/runs/serial-merges/gold-folio; committing/pushing now.

- Active serial integration: gold-proverqa (43ac355), preserve dirty work; all gates/fidelity passed in research/runs/serial-merges/gold-proverqa; committing/pushing now.

- Active serial integration: gold-proofwriter (727aa46), preserve dirty work; all gates/fidelity passed in research/runs/serial-merges/gold-proofwriter; committing/pushing now.

- Active serial integration: design-names (34277a5), preserve dirty work; all gates/fidelity passed in research/runs/serial-merges/design-names; committing/pushing now.

- Active serial integration: design-operators (e4dceb6), preserve dirty work; all gates/fidelity passed in research/runs/serial-merges/design-operators; committing/pushing now.

- Active serial integration: design-relatives (4d3e569), preserve dirty work; all gates/fidelity passed in research/runs/serial-merges/design-relatives; committing/pushing now.
