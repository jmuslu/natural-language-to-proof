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
| model / config | proofwriter | prontoqa | folio | proverqa |
|---|---|---|---|---|
| gpt-5.5 / high | 100.0% (100.0%) n=120 | 100.0% (100.0%) n=120 | 82.5% (82.5%) n=120 | 75.0% (75.0%) n=120 |
| gemini-3.5-flash / high | 100.0% (100.0%) n=20 | – | – | – |
| gemma-4-31b-it / minimal | 65.0% (65.0%) n=120 | 100.0% (100.0%) n=120 | 77.5% (77.5%) n=120 | 69.2% (69.2%) n=120 |
| gemini-3.1-flash-lite / budget0 | 62.5% (62.5%) n=120 | 80.0% (80.0%) n=120 | 67.5% (67.5%) n=120 | 50.8% (50.8%) n=120 |
| gemma-4-26b-a4b-it / minimal | 50.0% (57.5%) n=120 | 90.8% (90.8%) n=120 | 64.2% (67.5%) n=120 | 30.8% (68.3%) n=120 |
<!-- /table -->

**ProofWriter column** (scored by `proofwriter/scoring.py`): gpt-5.5 high is 120/120 and the three small models are complete; the gemini-3.5-flash cell is a partial slice (n=20, not a uniform sample). Gemini Pro is not on the free tier, so ProofWriter's large Gemini reference is Flash with high thinking on partial depth slices (36/36 at depth 3–5 with leniency; see `proofwriter/README.md`).

**gemini-3.5-flash (high thinking) is missing** on prontoqa/folio/proverqa. Its free-tier daily request quota (`GenerateRequestsPerDayPerProjectPerModel-FreeTier`) had already been used up by the ProofWriter runs, and only a single request went through all day, so it has no results. Rerun after the quota resets: `python3 common/run_gemini.py <bench> gemini-3.5-flash high 6 60`. The other four models are complete at n=120. gpt-5.5 runs through Codex with ~16k tokens of agent prompt; the others are plain API calls (not like-for-like, as in ProofWriter).

**Verdict.** **ProverQA-hard gives the best headroom** for the graph-context experiment. The large model is clearly below ceiling (gpt-5.5 75%), small models without thinking lose another 25–45 points under strict scoring (flash-lite 51%, gemma-26b 31%), and every model fails the same way, answering Uncertain on items that are provable. That is the gap that derived facts in context should close. One caveat: ProverQA reads a bare "either A or B" as exclusive, so the graph has to encode that convention. FOLIO also has headroom (gpt-5.5 82.5%, small models 64–68%), but some of its ceiling is v0.0 label noise (13 items wrong for every model), and the human-written English is harder for the CCG front end. ProntoQA is saturated (gpt-5.5 and gemma-31b both 100%) and is useful only as a parsing sanity check, and like ProofWriter it leaves room only for the smallest models.
