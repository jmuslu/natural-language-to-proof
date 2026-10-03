# ProofWriter raw-text LLM baseline (conditions A/B)

Raw-text baseline for the "small model + graph context vs large model raw text" benchmark: each model gets the ProofWriter theory as plain English and must answer True/False/Unknown with no graph, no tools.

**Sample** (`sample.py` → `sample.jsonl`): OWA depth-5 `meta-test` split, 120 questions, 20 per proof depth 0–5, labels 40 True / 40 False / 40 Unknown, at most one question per theory, `random.Random(20261003)`.

**Prompt** (`run.py`; `run_gemini.py` sends the same text minus the first paragraph, since a plain API call has no tools):
```
Do NOT use any tools, do NOT run commands, and do NOT read any files. This is a pure reading-comprehension logic question; answer from the text below only.

Facts and rules:
{theory}

Question: Based only on the facts and rules above, is the following statement true?
Statement: {question}

Answer with exactly one word: True, False, or Unknown. Unknown means it cannot be proven true or false from the given facts and rules (open-world).
```
Parsing is strict: the reply, after trimming `.*`"'` and whitespace, must be exactly `True`/`False`/`Unknown`; anything else counts as invalid (wrong).

**Runners.** `run.py <model> <effort> <n> <workers>`: `codex exec --ephemeral --sandbox read-only` in a fresh empty temp dir, so Codex's agent system prompt (~16k input tokens) is always in the loop. `run_gemini.py <model> <config> [pace] [n] [depths]`: direct `generateContent` at temperature 0, with `thinkingLevel` or `thinkingBudget` set from `<config>`; the optional `depths` filter (e.g. `3,4,5`) is for tiny free-tier quotas. Both resume by skipping only rows without an `error` field (API-error rows are retried) and write to `results/`. `probe.py <model> <effort>` is a one-call Codex model check. `analyze.py` prints Wilson 95% intervals, confusion, token use (`-v` prints depth>=3 failures); `analyze_gemini.py` is the Gemini-specific view.

**Results: SNAPSHOT 2026-10-03T15:13Z** (cells are correct/answered; overall has Wilson 95% CI; Gemini runs were still in progress)

| model / config (runner) | status | overall [95% CI] | d0 | d1 | d2 | d3 | d4 | d5 | T | F | U | invalid |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| gpt-5.5 / low (Codex) | complete | 119/120 = 99.2% [95.4, 99.9] | 20/20 | 20/20 | 20/20 | 20/20 | 19/20 | 20/20 | 40/40 | 39/40 | 40/40 | 0 |
| gpt-5.5 / high (Codex) | complete | 120/120 = 100.0% [96.9, 100.0] | 20/20 | 20/20 | 20/20 | 20/20 | 20/20 | 20/20 | 40/40 | 40/40 | 40/40 | 0 |
| gemini-3.1-flash-lite / budget0 (Gemini API) | complete | 75/120 = 62.5% [53.6, 70.6] | 20/20 | 15/20 | 12/20 | 8/20 | 11/20 | 9/20 | 24/40 | 17/40 | 34/40 | 0 |
| gemma-4-26b-a4b-it / minimal (Gemini API) | partial 117/120 | 60/117 = 51.3% [42.3, 60.2] | 20/20 | 11/20 | 9/20 | 6/19 | 8/20 | 6/18 | 14/39 | 12/38 | 34/40 | 16 |
| gemma-4-31b-it / minimal (Gemini API) | partial 32/120 | 20/32 = 62.5% [45.3, 77.1] | 3/3 | 7/8 | 4/6 | 3/4 | 2/6 | 1/5 | 5/11 | 4/8 | 11/13 | 0 |
| gemini-3-flash-preview / high (Gemini API) | partial 7/120 | 6/7 = 85.7% [48.7, 97.4] | – | – | – | 6/7 | – | – | 3/3 | 0/1 | 3/3 | 1 |
| gemini-3.5-flash / high (Gemini API) | partial 20/120 | 20/20 = 100.0% [83.9, 100.0] | 1/1 | 6/6 | 6/6 | 1/1 | 2/2 | 4/4 | 10/10 | 4/4 | 6/6 | 0 |
| gemini-3.6-flash / high (Gemini API) | partial 10/120 | 10/10 = 100.0% [72.2, 100.0] | – | – | – | – | 10/10 | – | 3/3 | 2/2 | 5/5 | 0 |
| gemini-3.7-flash / high (Gemini API) | partial 6/120 | 6/6 = 100.0% [61.0, 100.0] | – | – | – | – | – | 6/6 | 2/2 | 2/2 | 2/2 | 0 |
| gemini-3.8-flash / high (Gemini API) | partial 3/120 | 3/3 = 100.0% [43.8, 100.0] | – | 1/1 | 1/1 | 1/1 | – | – | 1/1 | 1/1 | 1/1 | 0 |

**Findings so far.** gpt-5.5 via Codex scores 119/120 at low effort and 120/120 at high, so ProofWriter OWA-d5 is saturated for frontier models. Only gpt-5.5 is available on Codex with a ChatGPT subscription, so the low/high rows compare effort levels, not model sizes. Small-model numbers come from the Gemini/Gemma rows: gemini-3.1-flash-lite (no thinking) gets 62.5% and gemma-4-26b-a4b-it about 51%, both perfect at depth 0 and falling to roughly 30-55% at depth 3-5, with the deficit concentrated in True/False (Unknown holds at 85%).

**Caveats.** With n=20 per depth the intervals are wide (20/20 still has a 95% CI of [83.9, 100]). Each question gets one sample. The Codex runs also carry about 16k tokens of agent prompt, which the Gemini calls don't have, so the two runners are not like-for-like. Partial Gemini rows are not uniform samples of the 120 (some were run with a depth filter under free-tier quota), so compare them only within a depth column.

**Rerun.** Put `GEMINI_API_KEY=...` in `~/.config/nl2proof/gemini.env` (or the environment); it is never stored here. Run `python3 run.py gpt-5.5 low 120 4`, `python3 run_gemini.py gemma-4-26b-a4b-it minimal 5`, then `python3 analyze.py`. `sample.py` rebuilds the sample from the full dataset at `~/data/proofwriter/` (not included).

**Attribution.** `sample.jsonl` holds 120 questions from ProofWriter (Tafjord, Dalvi & Clark, 2021, *ProofWriter: Generating Implications, Proofs, and Abductive Statements over Natural Language*, Findings of ACL), from the Allen Institute for AI, licensed CC BY 4.0. The questions are unmodified apart from field selection.
