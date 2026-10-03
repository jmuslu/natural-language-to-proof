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

**Runners.** `run.py <model> <effort> <n> <workers>`: `codex exec --ephemeral --sandbox read-only` in a fresh empty temp dir, so Codex's agent system prompt (~16k input tokens) is always in the loop. `run_gemini.py <model> <config> [pace] [n]`: direct `generateContent` at temperature 0, with `thinkingLevel` or `thinkingBudget` set from `<config>`. Both resume from where they stopped and write to `results/`. `analyze.py` prints Wilson 95% intervals, confusion, token use.

**Results: PARTIAL SNAPSHOT 2026-10-03T14:49Z, runs in progress** (cells are correct/answered)

| model / config (runner) | n | overall | d0 | d1 | d2 | d3 | d4 | d5 | T | F | U | invalid |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| gpt-5.5 / low (Codex) | 109/120 | 108/109 (99.1%) | 20/20 | 20/20 | 19/19 | 17/17 | 14/15 | 18/18 | 34/34 | 36/37 | 38/38 | 0 |
| gemini-3.1-flash-lite / budget0 (Gemini API) | 3/120 | 2/3 (66.7%) | – | 1/1 | 1/1 | 0/1 | – | – | 0/1 | 1/1 | 1/1 | 0 |
| gemma-4-26b-a4b-it / minimal (Gemini API) | 3/120 | 2/3 (66.7%) | – | 1/1 | 1/1 | 0/1 | – | – | 0/1 | 1/1 | 1/1 | 0 |

**Caveats.** With n=20 per depth the intervals are wide (20/20 still has a 95% CI of [83.9, 100]). Each question gets one sample. The Codex runs also carry about 16k tokens of agent prompt, which the Gemini calls don't have, so the two runners are not like-for-like. The Gemini rows above are 3-question smoke tests.

**Rerun.** Put `GEMINI_API_KEY=...` in `~/.config/nl2proof/gemini.env` (or the environment); it is never stored here. Run `python3 run.py gpt-5.5 low 120 4`, `python3 run_gemini.py gemma-4-26b-a4b-it minimal 5`, then `python3 analyze.py`. `sample.py` rebuilds the sample from the full dataset at `~/data/proofwriter/` (not included).

**Attribution.** `sample.jsonl` holds 120 questions from ProofWriter (Tafjord, Dalvi & Clark, 2021, *ProofWriter: Generating Implications, Proofs, and Abductive Statements over Natural Language*, Findings of ACL), from the Allen Institute for AI, licensed CC BY 4.0. The questions are unmodified apart from field selection.
