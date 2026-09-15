# Multi-hop reasoning: protocol and evidence

The financial objective is to compose testable alpha hypotheses from participant
constraints and incentives, through positioning and order flow, to conditional
price responses and an executable signal after costs. Logical composition checks
are one part of this process. Uncertain economic links require explicit empirical
targets, dependent-evidence accounting, and independent confirmation; a valid
proof under supplied rules does not establish those rules in markets.

## Components

| Component | Contract |
|---|---|
| `agentic-qr/shared/reasoning/client.py` | One pinned model/endpoint; bounded calls, tokens, time; durable usage reservations; no generated-code execution |
| `corpus/reasoning/benchmark.py` | Seeded finite typed worlds; separate exhaustive Horn reference evaluator |
| `corpus/reasoning/engine.py` | Checks only proposed steps against trusted signed fact receipts and explicit task rules |
| `corpus/reason.py` | Structural composition; singleton claim types bind predicate, arguments, and polarity |
| `corpus/retract.py` | Evidence genealogy; withdrawal removes exactly the conclusions losing all supplied support |
| `corpus/reasoning/run.py` | Shared prompts/caps, repair ablations, scoring, usage records, strict offline replay |
| `corpus/reasoning/ledger.py` | Binds proof leaves to current or historical run-validation receipts; fingerprints rule/evidence dependencies |

Rules are assumptions of the supplied world. A valid proof establishes a
consequence under those rules and receipts. Faithful extraction of arbitrary
language, empirical rule attestation, and discovery of missing world evidence
are separate research tasks. The checker performs no search for an omitted
opposing derivation; the generated benchmark's independent reference rejects
inconsistent queried worlds. Direct opposing receipts are detected even if a
proposal omits them.

## Frozen task distribution

`typed-worlds-v2` uses controlled functional text, explicit types, and signed
facts. All worlds contain positive and negative paths to the query, with
unavailable gates at random positions. Decoy bindings and disconnected branches
balance total and per-entity missing-evidence counts. Fact/rule IDs, order,
entity-map order, and predicate-map order are randomized.

The previous draft allowed perfect label guessing from root position and the
presence of a negative terminal rule. It was replaced before any model benchmark
calls. A regression now constructs identical task graphs with all three answers,
different authoritative receipt assignments, and identical shallow count
statistics. This blocks the identified shortcuts; it does not prove that all
possible shortcuts are absent. Retained proof validity is the primary evidence
of successful composition.

- Development: depths 2–3; chains and conjunctive branches; 12 full episodes.
- Test: depths 4, 6, 8; chains, branches, relational joins, alternative support,
  and unsupported cycles; 45 full episodes, one per depth/topology/answer cell.
- A 15-episode test pilot spans all depths and topologies; each answer appears at
  every depth. It remains a small exploratory sample.
- The reference exhaustively grounds typed rules and saturates the finite world.
  Gold answers, closure, and witnesses are withheld from model input and feedback.

## Comparisons and metrics

All arms use the same initial prompt, model, tasks, and resource ceilings:

1. `one_shot`: one proposal, retained as the cheaper reference.
2. `self_refine`: generic independent review within the remaining caps.
3. `verified_repair`: checker errors followed by a replacement proposal; stops
   once the supplied answer is accepted, including an explicit abstention.

Arm order rotates across episodes. Optional refinement failure preserves the
last syntactically usable answer under the same policy for every arm. Selection
does not consult the reference answer or proof validity.

Report raw answer accuracy, supported correct answers, answer coverage, correct
unknowns, raw/certified false assertions, repairs, calls, charged tokens, elapsed
time, and budget overruns. Unknown is abstention: accepting its JSON does not
prove that no derivation exists and earns no supported-answer credit. Matched
ceilings do not mean identical compute consumed; actual usage is retained.
Zero certified errors alone measures the admission boundary and says little
about how often the proposer finds the right proof.

## Run and replay

Configure `REASONING_BASE_URL`, `REASONING_API_KEY`, and `REASONING_MODEL`, or
explicitly select an existing service's configuration in memory. The latter
does not install, restart, or send messages to that service.

Controlled comparisons should explicitly set `REASONING_EFFORT` and
`REASONING_TIMEOUT_SECONDS`; omitted effort uses the endpoint default. The
`reasoning.configured_run` wrapper accepts `--reasoning-effort` and
`--request-timeout`. The client records the requested setting and optional
provider reasoning-token usage, with no silent effort fallback. It cannot attest
that an intermediary honored the requested effort. Reasoning usage is a subset
of completion usage, not an additional charge.

```sh
PYTHONPATH=corpus python3 -m reasoning.run \
  --oracle-repo ~/projects --run-dir corpus/runtime/reasoning/dev-v2-a \
  --split dev --count 3 --arms one_shot self_refine verified_repair \
  --service caveman-strategy-core --role generator \
  --max-tokens 24000 --max-output-tokens 4096 --max-calls 2 --max-seconds 100

PYTHONPATH=corpus python3 -m reasoning.run \
  --run-dir corpus/runtime/reasoning/dev-v2-a --replay
```

Each episode/arm has those cumulative caps. The full run is also bounded by its
episode and arm counts; the example permits at most 18 paid calls and 216,000
charged-token ceiling across nine pairs. Provider work already dispatched cannot
be canceled by a local timeout, and unknown usage is charged conservatively.

Ignored artifacts contain the immutable private dataset, code/prompt/config
hashes, full responses, proof checks, selected answers, transport reservation and
reconciliation records, and summaries. Credentials are never logged. `--resume`
requires identical settings and reconciled durable evidence; orphan paid
attempts after a crash cause refusal before new calls. `--replay` makes no model
calls and reconstructs proof checks, scores, and token/call totals rather than
trusting stored metrics.

## Research progression

Develop prompts only on development episodes, freeze them before test calls,
and treat any inspected test response as consumed evaluation data. Failures
become versioned development residuals; subsequent effectiveness claims need
fresh held-out seeds/compositions. Extend this protocol to controlled-language
extraction, corpus retrieval, authoritative domain receipts, and reward only with
an independently specified target for each transition.

## Receipt-backed proofs

A task fact can declare `"oracle":{"kind":"passes_validation","run_id":"..."}`.
Its run must be a declared `validation_run` entity, and the predicate signature
must be `"passes_validation":["validation_run"]`. The adapter reads the journal;
fact text, model-written verdicts, and source attribution cannot supply evidence.
Complete refutation supports the explicitly negative run-validation atom;
missing evidence supports neither polarity.

```sh
PYTHONPATH=corpus python3 -m reasoning.ledger \
  --journal corpus/runtime/oracle.sqlite --task /path/task.json \
  --proposal /path/proposal.json --report corpus/runtime/proof_report.json
```

Task rules remain caller-supplied assumptions. Reports include their task hash,
proposal hash, evidence snapshot hash, journal revisions and observation times,
and the checked consequence. Recheck after evidence/rule revisions; a previous
artifact does not certify the current state. `--as-of` uses historical evidence.

The connected `corpus/pipeline.py` also accepts `--proof-task` and
`--proof-proposal` together. It rechecks journal-backed leaves and writes
`proof_report.json`; rejected or malformed input replaces any stale successful
report and makes the CLI exit unsuccessfully.

## Measured model checkpoints

All runs below used the same `typed-worlds-v2` data and `proof-proposer-v1`
prompt, through the existing OpenRouter connection. Model IDs are explicit;
there was no automatic model substitution. Development used three two-hop
episodes, one per answer, at 24,000 tokens / two calls / 100 seconds per arm.
Test used 15 episodes at depths 4/6/8 and all five topologies, with 48,000 tokens /
two calls / 120 seconds per arm. Every call allowed 4,096 output tokens.

| Split / exact model | Arm | Raw correct | Supported / answerable | Correct raw unknowns | Calls | Charged tokens |
|---|---|---:|---:|---:|---:|---:|
| Dev / `minimax/minimax-m2.7` | One-shot | 3/3 | 2/2 | 1 | 3 | 9,883 |
| Dev / MiniMax | Self-review | 3/3 | 1/2 | 1 | 6 | 17,739 |
| Dev / MiniMax | Verified repair | 3/3 | 2/2 | 1 | 3 | 7,112 |
| Dev / `openai/gpt-5.5` | One-shot | 3/3 | 2/2 | 1 | 3 | 5,277 |
| Dev / GPT-5.5 | Self-review | 3/3 | 2/2 | 1 | 6 | 10,911 |
| Dev / GPT-5.5 | Verified repair | 3/3 | 2/2 | 1 | 3 | 5,333 |
| Dev / `openai/gpt-5.4-mini` | One-shot | 2/3 | 0/2 | 0 | 3 | 5,087 |
| Dev / GPT-5.4-mini | Self-review | 1/3 | 1/2 | 0 | 6 | 10,437 |
| Dev / GPT-5.4-mini | Verified repair | 3/3 | 2/2 | 1 | 5 | 8,493 |
| Test / MiniMax | One-shot | 9/15 | 5/10 | 4 | 15 | 83,475 |
| Test / MiniMax | Self-review | 7/15 | 2/10 | 3 | 23 | 119,234 |
| Test / MiniMax | Verified repair | 9/15 | 6/10 | 3 | 15 | 85,966 |
| Test / GPT-5.5 | One-shot | 15/15 | 10/10 | 5 | 15 | 46,464 |
| Test / GPT-5.5 | Self-review | 15/15 | 10/10 | 5 | 30 | 96,193 |
| Test / GPT-5.5 | Verified repair | 15/15 | 10/10 | 5 | 16 | 50,751 |
| Test / GPT-5.4-mini | One-shot | 6/15 | 0/10 | 2 | 15 | 41,295 |
| Test / GPT-5.4-mini | Self-review | 6/15 | 0/10 | 3 | 30 | 85,750 |
| Test / GPT-5.4-mini | Verified repair | 7/15 | 0/10 | 5 | 26 | 74,408 |

These historical requests **omitted reasoning effort**. Official model defaults
currently differ: [GPT-5.4-mini](https://developers.openai.com/api/docs/models/gpt-5.4-mini)
defaults to `none`, while [GPT-5.5](https://developers.openai.com/api/docs/models/gpt-5.5)
defaults to `medium`. The OpenRouter behavior was not independently attested.
Thus the table measures those endpoint configurations, not a matched-effort
comparison or the smaller model's reasoning ceiling. Later runs must request
matched effort explicitly and report the returned usage.

Under that omitted-effort configuration, the smaller model's development success
did **not** generalize to longer chains: none of its test proposals supplied a
valid supported answer. Its test raw false
assertions were 7/4/2 across the three arms; all were rejected. GPT-5.5 completed
all answerable test proofs, including one successful feedback repair, with no
aggregate improvement over its one-shot result. MiniMax's verified arm had no
successful repairs. Its final transport status was error in 5/7/6 test pairs,
often because generation exhausted the output allowance before usable assistant
text. This run cannot separate that limitation from reasoning difficulty.

All six runs replayed with zero verification differences or integrity errors
against their recorded source versions;
all had zero certified false assertions and zero budget overruns. MiniMax used
a 60-second request timeout; the explicit GPT connection wrapper used 30 seconds.
Recorded response times and transport events permit inspection of that difference.
Independent first samples per arm and this small sample size limit causal method
comparisons. These are finite synthetic composition results, not evidence of
frontier-level general reasoning or alpha discovery. Inspected test tasks are now
consumed evaluation data; later tuning needs fresh seeds and compositions.
Strict replay checks source hashes: use the recorded historical code when
replaying these runs after a client or runner change; never rewrite old hashes
to make them match new code.

Artifacts under ignored `corpus/runtime/reasoning/` are `dev-v2-a`, `test-v2-a`,
`dev-gpt55-a`, `test-gpt55-a`, `dev-gpt54mini-a`, and `test-gpt54mini-a`.
The six runs charged 763,808 tokens in total; two prior access smokes used 117
additional tokens. Immutable run configs record model/endpoint, full dataset,
source code and prompt hashes, caps, and exact responses.

- Development dataset SHA256: `16f03b28ebe15b7a0adb1827036571b97aef278786ddce2444ee93ad0c232163`
- Prompt SHA256: `be83bf0c2fd36590753356cdb4846ea18a88a5e5718076b3b3fa46ac9ec93115`
