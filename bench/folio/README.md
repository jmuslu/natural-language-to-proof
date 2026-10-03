# FOLIO raw-text LLM baseline

Condition A/B raw-text baseline for the "small model + graph context vs large model on raw text" test (method of `../proofwriter/`): the model sees the problem as plain English, no graph, no tools.

**Benchmark.** FOLIO (Han et al., 2022, *FOLIO: Natural Language Reasoning with First-Order Logic*): expert-written stories of natural-language premises with a conclusion labelled True/False/Uncertain (plus FOL annotations, unused here). Source: `github.com/Yale-LILY/FOLIO` `data/v0.0/folio-validation.jsonl` (204 items, 73 stories), CC BY-SA 4.0. The newer v2 on Hugging Face (`yale-nlp/FOLIO`) is gated, so we use the public v0.0 validation set; v0.0 is known to contain some label noise.

**Sample** (`sample.py` → `sample.jsonl`): 120 items, 40 per label, seed 20261003, stratified by number of premises (FOLIO has no hop annotation): 10 / 14 / 16 per label with 2–4 / 5 / 6–9 premises; 62 distinct stories. Items 1–60 are balanced the same way.

**Prompt** (Gemini; Codex prepends the "Do NOT use any tools ..." paragraph):
```
Premises:
{premises, one per line}

Question: Based only on the premises above, is the following statement true, false, or uncertain?
Statement: {conclusion}

Answer with exactly one word: True, False, or Uncertain. Uncertain means it cannot be proven true or false from the given premises.
```
**Runners** (shared, `../common/`): `run_codex.py folio gpt-5.5 high 120 3` (Codex CLI, fresh empty dir, `--sandbox read-only --ephemeral`, prompt with the "Do NOT use any tools ..." preamble of `../proofwriter/run.py`); `run_gemini.py folio <model> <config> <pace> <n>` (Gemini API, temperature 0, same prompt without the preamble). `analyze.py folio [--write] [-v]` re-scores from the raw replies. Scoring (`../common/scoring.py`): **strict** = reply trimmed of `.*\`"'` must be exactly one label word; **lenient** = case-insensitive, markdown stripped, an "Answer:"-style marker wins, else the last label word; Unknown synonyms map to Uncertain; ambiguous/no label = invalid.

**Results** (cells correct/answered; overall with Wilson 95% CI; `(k/120)` = partial run on the first k items):
<!-- table -->
| model / config | n | overall [95% CI] | premises 2-4 | premises 5 | premises 6-9 | True | False | Uncertain | invalid |
|---|---|---|---|---|---|---|---|---|---|
| gpt-5.5 / high | 120 | 99/120 = 82.5% [75, 88] | 28/30 | 33/42 | 38/48 | 31/40 | 32/40 | 36/40 | 0 |
| (with leniency) | 120 | 99/120 = 82.5% [75, 88] | 28/30 | 33/42 | 38/48 | 31/40 | 32/40 | 36/40 | 0 |
| gemma-4-31b-it / minimal | 120 | 93/120 = 77.5% [69, 84] | 24/30 | 34/42 | 35/48 | 33/40 | 33/40 | 27/40 | 0 |
| (with leniency) | 120 | 93/120 = 77.5% [69, 84] | 24/30 | 34/42 | 35/48 | 33/40 | 33/40 | 27/40 | 0 |
| gemini-3.1-flash-lite / budget0 | 120 | 81/120 = 67.5% [59, 75] | 25/30 | 28/42 | 28/48 | 28/40 | 22/40 | 31/40 | 0 |
| (with leniency) | 120 | 81/120 = 67.5% [59, 75] | 25/30 | 28/42 | 28/48 | 28/40 | 22/40 | 31/40 | 0 |
| gemma-4-26b-a4b-it / minimal | 120 | 77/120 = 64.2% [55, 72] | 25/30 | 28/42 | 24/48 | 22/40 | 23/40 | 32/40 | 4 |
| (with leniency) | 120 | 81/120 = 67.5% [59, 75] | 25/30 | 28/42 | 28/48 | 25/40 | 24/40 | 32/40 | 0 |
<!-- /table -->
gemini-3.5-flash / high is missing because its free-tier daily request quota ran out (see `../README.md`).

**Findings.** gpt-5.5 is not at ceiling (82.5% [75, 88]). Most of its misses (15/21) are True/False items answered Uncertain, and 13 items are wrong for all four models, which fits FOLIO v0.0's known label noise. The real ceiling is probably about 90%. gemma-4-31b (no thinking) is close to it at 77.5%. The small models score 67.5% (flash-lite) and 64.2%/67.5% (gemma-26b strict/lenient), a 15-pt gap to gpt-5.5, and they fail the same way, by answering Uncertain on provable items (flash-lite: 27 of 39 errors). Premise count barely predicts difficulty (6–9 premises: 58–79% for every model).

**Attribution.** `sample.jsonl` holds 120 items from the FOLIO v0.0 validation set (Han et al. 2022, Yale LILY Lab), licensed CC BY-SA 4.0; this sample is shared under the same license. Full data in `~/data/folio/` (not committed).
