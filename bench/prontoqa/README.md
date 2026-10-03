# ProntoQA raw-text LLM baseline

Condition A/B raw-text baseline for the "small model + graph context vs large model on raw text" test (method of `../proofwriter/`): the model sees the problem as plain English, no graph, no tools.

**Benchmark.** ProntoQA (Saparov & He, 2023, *Language Models Are Greedy Reasoners*, ICLR): synthetic fictional ontologies ("Every yumpus is a dumpus"), one entity, True/False questions answered by a modus-ponens chain. We use the 5-hop, fictional-ontology dev set (500 items) as released by Logic-LM (Pan et al., 2023; `github.com/teacherpeterpan/Logic-LLM`, `data/ProntoQA/dev.json`, MIT), which was generated with the official ProntoQA generator (Apache-2.0) and is the usual "hardest" ProntoQA split. (The official ProntoQA-OOD release has only "Prove: X" items, always provable, so it has no True/False labels.)

**Sample** (`sample.py` → `sample.jsonl`): 120 items, 60 True / 60 False, all 5 hops (counted from the gold explanation), seed 20261003; items 1–60 are themselves 30/30 balanced, so a run cut at n=60 is still balanced.

**Prompt** (Gemini; Codex prepends the "Do NOT use any tools ..." paragraph):
```
Facts and rules:
{context}

Question: Based only on the facts and rules above, is the following statement true or false?
Statement: {statement}

Answer with exactly one word: True or False.
```
**Runners** (shared, `../common/`): `run_codex.py prontoqa gpt-5.5 high 120 3` (Codex CLI, fresh empty dir, `--sandbox read-only --ephemeral`, prompt with the "Do NOT use any tools ..." preamble of `../proofwriter/run.py`); `run_gemini.py prontoqa <model> <config> <pace> <n>` (Gemini API, temperature 0, same prompt without the preamble). `analyze.py prontoqa [--write] [-v]` re-scores from the raw replies. Scoring (`../common/scoring.py`): **strict** = reply trimmed of `.*\`"'` must be exactly one label word; **lenient** = case-insensitive, markdown stripped, an "Answer:"-style marker wins, else the last label word; Unknown synonyms map to Uncertain; ambiguous/no label = invalid.

**Results** (cells correct/answered; overall with Wilson 95% CI; `(k/120)` = partial run on the first k items):
<!-- table -->
| model / config | n | overall [95% CI] | hops 5 | True | False | invalid |
|---|---|---|---|---|---|---|
| gpt-5.5 / high | 120 | 120/120 = 100.0% [97, 100] | 120/120 | 60/60 | 60/60 | 0 |
| (with leniency) | 120 | 120/120 = 100.0% [97, 100] | 120/120 | 60/60 | 60/60 | 0 |
| gemma-4-31b-it / minimal | 120 | 120/120 = 100.0% [97, 100] | 120/120 | 60/60 | 60/60 | 0 |
| (with leniency) | 120 | 120/120 = 100.0% [97, 100] | 120/120 | 60/60 | 60/60 | 0 |
| gemini-3.1-flash-lite / budget0 | 120 | 96/120 = 80.0% [72, 86] | 96/120 | 39/60 | 57/60 | 0 |
| (with leniency) | 120 | 96/120 = 80.0% [72, 86] | 96/120 | 39/60 | 57/60 | 0 |
| gemma-4-26b-a4b-it / minimal | 120 | 109/120 = 90.8% [84, 95] | 109/120 | 49/60 | 60/60 | 0 |
| (with leniency) | 120 | 109/120 = 90.8% [84, 95] | 109/120 | 49/60 | 60/60 | 0 |
<!-- /table -->
gemini-3.5-flash / high is missing because its free-tier daily request quota ran out (see `../README.md`).

**Findings.** Saturated for large and mid-size models: gpt-5.5 (high) and gemma-4-31b without thinking both score 120/120. Only the small models leave room: gemini-3.1-flash-lite 80.0% and gemma-4-26b-a4b 90.8%, and their errors are nearly all True→False (21/24 and 11/11). They miss the 5-hop chain and fall back on the distractor property ("Numpuses are sour" vs "Tumpuses are not sour"), the same under-chaining seen on ProofWriter. All replies were a single word, so strict and lenient scores are identical. Use this benchmark as a CCG/graph sanity check (the fictional-ontology syntax is very regular), not to measure the large-vs-small gap.

**Attribution.** `sample.jsonl` holds 120 items from ProntoQA (Saparov & He 2023; Apache-2.0) via the Logic-LM release (Pan et al. 2023, *Logic-LM*, Findings of EMNLP; MIT), unmodified apart from field selection. Full data in `~/data/prontoqa/` (not committed).
