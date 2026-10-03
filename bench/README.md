# Raw-text LLM baselines across logical-reasoning benchmarks

Condition A/B of the "small model + graph context vs large model on raw text" experiment: each model sees the problem as plain English (no graph, no tools) and answers with one label word. Method, prompts and scoring follow `proofwriter/`; the three newer benchmarks share `common/` (Codex + Gemini runners, `scoring.py` strict/lenient parser, `analyze.py`, `summary.py`). Each has its own README with sources, licenses, prompt and per-stratum tables.

| benchmark | source / split | labels | sample |
|---|---|---|---|
| `proofwriter/` | ProofWriter OWA depth-5 meta-test | T/F/Unknown | 120, 20 per depth 0–5 |
| `prontoqa/` | ProntoQA 5-hop fictional (Logic-LM dev) | T/F | 120, all 5-hop |
| `folio/` | FOLIO v0.0 validation (human-written FOL) | T/F/Uncertain | 120, by premise count |
| `proverqa/` | ProverQA **hard** dev | T/F/Uncertain | 120, by proof steps 3–6/7/8–9 |

**Strict accuracy (lenient in parentheses)**, n = items answered (first-n prefix of each sample is itself balanced):
<!-- table -->
| model / config | prontoqa | folio | proverqa |
|---|---|---|---|
| gpt-5.5 / high | 100.0% (100.0%) n=120 | 82.5% (82.5%) n=120 | 75.0% (75.0%) n=120 |
| gemini-3.5-flash / high | – | – | – |
| gemma-4-31b-it / minimal | 100.0% (100.0%) n=33 | 75.0% (75.0%) n=36 | 65.6% (65.6%) n=32 |
| gemini-3.1-flash-lite / budget0 | 80.0% (80.0%) n=120 | 67.5% (67.5%) n=120 | 50.8% (50.8%) n=120 |
| gemma-4-26b-a4b-it / minimal | 90.8% (90.8%) n=120 | 58.3% (61.7%) n=60 | 28.6% (70.1%) n=77 |
<!-- /table -->

**Verdict.** TBD
