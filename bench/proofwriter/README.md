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
**Runners.** `run.py <model> <effort> <n> <workers>`: `codex exec --ephemeral --sandbox read-only` in a fresh empty temp dir, so Codex's agent system prompt (~16k input tokens) is always in the loop. `run_gemini.py <model> <config> [pace] [n] [depths]`: direct `generateContent` at temperature 0, with `thinkingLevel` or `thinkingBudget` set from `<config>`; the optional `depths` filter (e.g. `3,4,5`) is for tiny free-tier quotas. Both resume by skipping only rows without an `error` field (API-error rows are retried) and write to `results/`. `probe.py <model> <effort>` is a one-call Codex model check. `analyze.py` prints Wilson 95% intervals, confusion, token use (`-v` prints depth>=3 failures); `analyze_gemini.py` is the Gemini-specific view.

**Scoring: strict vs. with leniency** (`scoring.py`; both analyzers use it; no model is re-run, only the saved `raw` is re-parsed). *Strict* (headline): after trimming `.*`"'` and whitespace the reply must be exactly `True`/`False`/`Unknown`; anything else is invalid and counts as wrong.
- *With leniency* (`lenient_parse`): lowercase; strip `**`, `` ` ``, `#`, quotes. If an answer marker exists (`Answer:`, `Final answer:`, `The answer is`, `**Answer**`), take the label right after the last one; otherwise take the last label word. `uncertain`, `cannot/can't be determined`, `not enough information`, `undetermined`, `neither` (incl. `neither true nor false`) mean Unknown; yes/no are never mapped. No label, or two different labels in the sentence holding the chosen one (e.g. `True or False`), stays invalid. Strict-valid replies parse identically.
- Why: told to answer in one word, gemma-4-26b-a4b-it replied with a worked explanation 17/120 times, e.g. `To determine if the statement "The cow does not see the bald eagle" is true, false, or unknown, we must analyze the provided facts and rules.\n\n1.  **Identify facts about the cow's vision:**…` ending in `False`. Strict scores that wrong although the verdict is right; leniency separates formatting failure from reasoning failure. All 20 strict-invalid replies (17 gemma-4-26b, 3 gemini-3-flash-preview) were checked by eye: each lenient parse is the reply's own final verdict (`python3 scoring.py` lists them).

**Results: SNAPSHOT 2026-10-03T16:57Z** (cells are correct/answered; overall has Wilson 95% CI; gpt-5.5, gemini-3.1-flash-lite, gemma-4-26b-a4b-it and gemma-4-31b-it are complete at 120/120, the Flash-with-high-thinking rows are partial slices; `python3 scoring.py table` regenerates the rows)

| model / config (runner) | status | overall [95% CI] | d0 | d1 | d2 | d3 | d4 | d5 | T | F | U | invalid | leniency changed (inv→correct / inv→wrong) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| gpt-5.5 / low (Codex) | complete | 119/120 = 99.2% [95.4, 99.9] | 20/20 | 20/20 | 20/20 | 20/20 | 19/20 | 20/20 | 40/40 | 39/40 | 40/40 | 0 |  |
| gpt-5.5 / low (with leniency) | complete | 119/120 = 99.2% [95.4, 99.9] | 20/20 | 20/20 | 20/20 | 20/20 | 19/20 | 20/20 | 40/40 | 39/40 | 40/40 | 0 | 0 / 0 |
| gpt-5.5 / high (Codex) | complete | 120/120 = 100.0% [96.9, 100.0] | 20/20 | 20/20 | 20/20 | 20/20 | 20/20 | 20/20 | 40/40 | 40/40 | 40/40 | 0 |  |
| gpt-5.5 / high (with leniency) | complete | 120/120 = 100.0% [96.9, 100.0] | 20/20 | 20/20 | 20/20 | 20/20 | 20/20 | 20/20 | 40/40 | 40/40 | 40/40 | 0 | 0 / 0 |
| gemini-3.1-flash-lite / budget0 (Gemini API) | complete | 75/120 = 62.5% [53.6, 70.6] | 20/20 | 15/20 | 12/20 | 8/20 | 11/20 | 9/20 | 24/40 | 17/40 | 34/40 | 0 |  |
| gemini-3.1-flash-lite / budget0 (with leniency) | complete | 75/120 = 62.5% [53.6, 70.6] | 20/20 | 15/20 | 12/20 | 8/20 | 11/20 | 9/20 | 24/40 | 17/40 | 34/40 | 0 | 0 / 0 |
| gemma-4-26b-a4b-it / minimal (Gemini API) | complete | 60/120 = 50.0% [41.2, 58.8] | 20/20 | 11/20 | 9/20 | 6/20 | 8/20 | 6/20 | 14/40 | 12/40 | 34/40 | 17 |  |
| gemma-4-26b-a4b-it / minimal (with leniency) | complete | 69/120 = 57.5% [48.6, 66.0] | 20/20 | 14/20 | 11/20 | 7/20 | 11/20 | 6/20 | 19/40 | 14/40 | 36/40 | 0 | 9 / 8 |
| gemma-4-31b-it / minimal (Gemini API) | complete | 78/120 = 65.0% [56.1, 72.9] | 20/20 | 18/20 | 13/20 | 10/20 | 9/20 | 8/20 | 24/40 | 16/40 | 38/40 | 0 |  |
| gemma-4-31b-it / minimal (with leniency) | complete | 78/120 = 65.0% [56.1, 72.9] | 20/20 | 18/20 | 13/20 | 10/20 | 9/20 | 8/20 | 24/40 | 16/40 | 38/40 | 0 | 0 / 0 |
| gemini-3-flash-preview / high (Gemini API) | partial 20/120 | 17/20 = 85.0% [64.0, 94.8] | – | – | – | 17/20 | – | – | 6/7 | 5/7 | 6/6 | 3 |  |
| gemini-3-flash-preview / high (with leniency) | partial 20/120 | 20/20 = 100.0% [83.9, 100.0] | – | – | – | 20/20 | – | – | 7/7 | 7/7 | 6/6 | 0 | 3 / 0 |
| gemini-3.5-flash / high (Gemini API) | partial 20/120 | 20/20 = 100.0% [83.9, 100.0] | 1/1 | 6/6 | 6/6 | 1/1 | 2/2 | 4/4 | 10/10 | 4/4 | 6/6 | 0 |  |
| gemini-3.5-flash / high (with leniency) | partial 20/120 | 20/20 = 100.0% [83.9, 100.0] | 1/1 | 6/6 | 6/6 | 1/1 | 2/2 | 4/4 | 10/10 | 4/4 | 6/6 | 0 | 0 / 0 |
| gemini-3.6-flash / high (Gemini API) | partial 10/120 | 10/10 = 100.0% [72.2, 100.0] | – | – | – | – | 10/10 | – | 3/3 | 2/2 | 5/5 | 0 |  |
| gemini-3.6-flash / high (with leniency) | partial 10/120 | 10/10 = 100.0% [72.2, 100.0] | – | – | – | – | 10/10 | – | 3/3 | 2/2 | 5/5 | 0 | 0 / 0 |
| gemini-3.7-flash / high (Gemini API) | partial 6/120 | 6/6 = 100.0% [61.0, 100.0] | – | – | – | – | – | 6/6 | 2/2 | 2/2 | 2/2 | 0 |  |
| gemini-3.7-flash / high (with leniency) | partial 6/120 | 6/6 = 100.0% [61.0, 100.0] | – | – | – | – | – | 6/6 | 2/2 | 2/2 | 2/2 | 0 | 0 / 0 |
| gemini-3.8-flash / high (Gemini API) | partial 3/120 | 3/3 = 100.0% [43.8, 100.0] | – | 1/1 | 1/1 | 1/1 | – | – | 1/1 | 1/1 | 1/1 | 0 |  |
| gemini-3.8-flash / high (with leniency) | partial 3/120 | 3/3 = 100.0% [43.8, 100.0] | – | 1/1 | 1/1 | 1/1 | – | – | 1/1 | 1/1 | 1/1 | 0 | 0 / 0 |

**Findings.** gpt-5.5 via Codex scores 119/120 at low effort and 120/120 at high, so ProofWriter OWA-d5 is saturated for frontier models. Only gpt-5.5 is available on Codex with a ChatGPT subscription, so the low/high rows compare effort levels, not model sizes.
- **Small models without thinking** (all three complete at n=120): gemini-3.1-flash-lite 62.5%, gemma-4-31b-it 65.0%, gemma-4-26b-a4b-it 50.0% strict (57.5% with leniency: of its 17 explained answers 9 had the right verdict and 8 the wrong one). All three are perfect at depth 0 (20/20) and fall to 30–55% at depth 3–5 (flash-lite 8/11/9, gemma-31b 10/9/8, gemma-26b 6/8/6 of 20, strict).
- **Their main failure is answering Unknown on provable items.** Of the 80 True/False items, they answer Unknown on 44% (gemma-26b, 35/80), 48% (flash-lite, 38/80) and 50% (gemma-31b, 40/80) under strict scoring; that is 97–100% of flash-lite's and gemma-31b's True/False errors. Unknown items themselves hold at 34–38/40. The models stop chaining before the proof is complete, which is the gap derived facts in context should close.
- **Large Gemini reference.** Gemini Pro is not available on the free tier, so the large Gemini reference is Flash with high thinking, run on partial depth slices under free-tier quota. At depth 3–5, gemini-3-flash-preview (d3), 3.6-flash (d4) and 3.7-flash (d5) get 36/36 with leniency (33/36 strict: the 3 preview misses are correct verdicts after a worked explanation); adding 3.5-flash and 3.8-flash, 44/44 with leniency. Flash with thinking, like gpt-5.5 high (120/120), shows no depth effect, so the headroom on ProofWriter is in small models without thinking.

**Caveats.** With n=20 per depth the intervals are wide (20/20 still has a 95% CI of [83.9, 100]). Each question gets one sample. The Codex runs also carry about 16k tokens of agent prompt, which the Gemini calls don't have, so the two runners are not like-for-like. Partial Gemini rows are not uniform samples of the 120 (some were run with a depth filter under free-tier quota), so compare them only within a depth column.

**Rerun.** Put `GEMINI_API_KEY=...` in `~/.config/nl2proof/gemini.env` (or the environment); it is never stored here. Run `python3 run.py gpt-5.5 low 120 4`, `python3 run_gemini.py gemma-4-26b-a4b-it minimal 5`, then `python3 analyze.py`. `sample.py` rebuilds the sample from the full dataset at `~/data/proofwriter/` (not included).

**Attribution.** `sample.jsonl` holds 120 questions from ProofWriter (Tafjord, Dalvi & Clark, 2021, *ProofWriter: Generating Implications, Proofs, and Abductive Statements over Natural Language*, Findings of ACL), from the Allen Institute for AI, licensed CC BY 4.0. The questions are unmodified apart from field selection.
