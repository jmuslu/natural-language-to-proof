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
| gpt-5.5 / high | 120 | 90/120 = 75.0% [67, 82] | 30/40 | 32/40 | 28/40 | 26/40 | 25/40 | 39/40 | 0 |
| (with leniency) | 120 | 90/120 = 75.0% [67, 82] | 30/40 | 32/40 | 28/40 | 26/40 | 25/40 | 39/40 | 0 |
| gemma-4-31b-it / minimal | 120 | 83/120 = 69.2% [60, 77] | 27/40 | 27/40 | 29/40 | 29/40 | 17/40 | 37/40 | 0 |
| (with leniency) | 120 | 83/120 = 69.2% [60, 77] | 27/40 | 27/40 | 29/40 | 29/40 | 17/40 | 37/40 | 0 |
| gemini-3.1-flash-lite / budget0 | 120 | 61/120 = 50.8% [42, 60] | 18/40 | 19/40 | 24/40 | 15/40 | 8/40 | 38/40 | 0 |
| (with leniency) | 120 | 61/120 = 50.8% [42, 60] | 18/40 | 19/40 | 24/40 | 15/40 | 8/40 | 38/40 | 0 |
| gemma-4-26b-a4b-it / minimal | 120 | 37/120 = 30.8% [23, 40] | 13/40 | 15/40 | 9/40 | 4/40 | 6/40 | 27/40 | 73 |
| (with leniency) | 120 | 82/120 = 68.3% [60, 76] | 29/40 | 28/40 | 25/40 | 24/40 | 20/40 | 38/40 | 0 |
<!-- /table -->
gemini-3.5-flash / high is missing because its free-tier daily request quota ran out (see `../README.md`).

**Findings.** Real headroom even at the top: gpt-5.5 (high, mean 318 reasoning tokens) gets 75.0% [67, 82]. Uncertain is 39/40, but True is 26/40 and False 25/40, and 28 of its 30 errors are "Uncertain" on provable items. In about half of its True/False misses (14/29, against 9/51 among its hits) the gold proof reads a bare "either A or B" as exclusive. Some of the gap is therefore a convention mismatch, which the graph would need to encode (XOR) to match gold. gemma-4-31b gets 69.2%. flash-lite reaches 50.8% (False 8/40, with 24 False→Uncertain). gemma-26b scores 30.8% strict because 73/120 replies ignore "exactly one word" and write visible chain-of-thought; scored leniently it reaches 68.3%, so a small model that reasons out loud closes most of the gap. Depth bucket (3–6/7/8–9) has no clear effect at n=40.

**Attribution.** `sample.jsonl` holds 120 items from ProverQA hard (Qi et al. 2025, OpenDataLab, `opendatalab/ProverQA`), unmodified apart from field selection. Full data in `~/data/proverqa/` (not committed).
