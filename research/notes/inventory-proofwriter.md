# ProofWriter inventory recovery, 2026-10-14

Prediction recorded in coordinator LOG before measurement: repaired extraction should cover all 110 physical JSONL files, preserve source-unit totals except explicit sentence expansion, and leave no unexpected controlled template. Unmatched paraphrases remain visible.

Commands already run in the original worktree before isolation:

- `python3 research/linguistics/inventory-proofwriter.py summarize --work research/runs/linguistics/proofwriter --output research/linguistics/proofwriter-counts.json`
- `python3 research/runs/linguistics/proofwriter/check_inventory.py`
- Read-only manifest and sum assertions against the aggregate JSON.

Results: 110/110 paths, 702,271 physical records, 13,247,543 sentence occurrences, 172,834 unique strings. 156 occurrences/12 strings remain unclassified. All controlled inputs match an explicit pattern. Five tests pass. Zero remaining theory reconstruction mismatches. No benchmark, model, LLM or CCGbank process launched. This result supports extraction integrity, not semantic fidelity.

Isolation handoff: branch astra/inventory-proofwriter; only inventory-proofwriter.py, proofwriter-counts.json, sections/proofwriter.md and this note belong to this worker. Other copied modifications are untouched.

Prediction before final static validation: Python compilation, aggregate-sum assertions, 110 manifest entries, and whitespace checks should pass; no corpus reload is needed. The immutable prior five extraction tests can be run using the read-only original test file against this worktree's script.

Final static validation passed: Python compile; all 5 existing inventory integrity tests; whitespace diff check; 110 manifest entries; occurrence/unique sum assertions. Prediction held. No new source data load.
