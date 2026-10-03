# ProverQA (hard) raw-text LLM baseline

Condition A/B raw-text baseline for the "small model + graph context vs large model on raw text" test (method of `../proofwriter/`): the model sees the problem as plain English, no graph, no tools.

**Benchmark.** ProverQA (Qi et al., 2025, *Large Language Models Meet Symbolic Provers for Logical Reasoning Evaluation*, ICLR): first-order-logic problems generated with a symbolic prover and verbalised by an LLM, with distractor facts/rules; labels True/False/Uncertain; easy/medium/hard. We use **hard** (`dev/hard.json`, 500 items, 6–9-step proofs by design) from `huggingface.co/datasets/opendatalab/ProverQA` (ungated). The dataset card gives no explicit license (it says sources are MIT/WordNet and the data is for research); we commit only this 120-item sample, with attribution.

**Sample** (`sample.py` → `sample.jsonl`): 120 hard items, 40 per label, seed 20261003, stratified by gold-proof steps (count of `conclusion:` in `reasoning`; Uncertain items have shorter partial proofs) into 3–6 / 7 / 8–9, 40 per bucket. Items 1–60 are balanced the same way.

**Prompt** (Gemini; Codex prepends the "Do NOT use any tools ..." paragraph):
```
Facts and rules:
{context}

Question: Based only on the facts and rules above, is the following statement true, false, or uncertain?
Statement: {statement}

Answer with exactly one word: True, False, or Uncertain. Uncertain means it cannot be proven true or false from the given facts and rules.
```
**Runners** (shared, `../common/`): `run_codex.py proverqa gpt-5.5 high 120 3` (Codex CLI, fresh empty dir, `--sandbox read-only --ephemeral`, prompt with the "Do NOT use any tools ..." preamble of `../proofwriter/run.py`); `run_gemini.py proverqa <model> <config> <pace> <n>` (Gemini API, temperature 0, same prompt without the preamble). `analyze.py proverqa [--write] [-v]` re-scores from the raw replies. Scoring (`../common/scoring.py`): **strict** = reply trimmed of `.*\`"'` must be exactly one label word; **lenient** = case-insensitive, markdown stripped, an "Answer:"-style marker wins, else the last label word; Unknown synonyms map to Uncertain; ambiguous/no label = invalid.

**Results** (cells correct/answered; overall with Wilson 95% CI; `(k/120)` = partial run on the first k items):
<!-- table -->
| model / config | n | overall [95% CI] | steps 3-6 | steps 7 | steps 8-9 | True | False | Uncertain | invalid |
|---|---|---|---|---|---|---|---|---|---|
| gpt-5.5 / high (71/120) | 71 | 57/71 = 80.3% [70, 88] | 20/24 | 17/23 | 20/24 | 15/22 | 17/24 | 25/25 | 0 |
| (with leniency) | 71 | 57/71 = 80.3% [70, 88] | 20/24 | 17/23 | 20/24 | 15/22 | 17/24 | 25/25 | 0 |
| gemini-3.1-flash-lite / budget0 (48/120) | 48 | 28/48 = 58.3% [44, 71] | 9/14 | 8/17 | 11/17 | 7/14 | 3/16 | 18/18 | 0 |
| (with leniency) | 48 | 28/48 = 58.3% [44, 71] | 9/14 | 8/17 | 11/17 | 7/14 | 3/16 | 18/18 | 0 |
| gemma-4-26b-a4b-it / minimal (13/120) | 13 | 4/13 = 30.8% [13, 58] | 3/5 | 0/2 | 1/6 | 0/2 | 2/7 | 2/4 | 8 |
| (with leniency) | 13 | 9/13 = 69.2% [42, 87] | 4/5 | 1/2 | 4/6 | 2/2 | 3/7 | 4/4 | 0 |
<!-- /table -->

**Findings.** TBD

**Attribution.** `sample.jsonl` holds 120 items from ProverQA hard (Qi et al. 2025, OpenDataLab, `opendatalab/ProverQA`), unmodified apart from field selection. Full data in `~/data/proverqa/` (not committed).
