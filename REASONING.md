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
| `corpus/reasoning/scaffold.py` | Bounded local typed joins and model-selected rule applications; separately labeled deterministic search |
| `corpus/reasoning/scaffold_run.py` | Explicit-effort comparisons, current-state prompts, work accounting, paired scores and replay |
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

The original proof-proposal runner compares three arms with the same initial
prompt, model, tasks and resource ceilings:

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

## Local rule applications and explicit search

The consumed mini failures often mismatched subjects, omitted conjunction gates,
or invented premise IDs. The local tool admits checked leaves and exposes only
currently enabled one-rule applications with exact bindings. The proposer selects
application IDs and chooses when/how to finish; the tool assembles chronological
proof steps and the independent engine checks the result. All rules remain task
assumptions. Counters bound joins, scans, applications, views and proof size.

`deterministic_search` explicitly consumes the same frontier without a model.
On 18 consumed development/old-test worlds it solved all labels, supplying 12
proofs and six complete-search unknowns, with zero model calls. These finite
symbolic worlds already have an inexpensive solver. Any scaffold improvement
measures tool-assisted planning/assembly, not frontier-level model intelligence.

The new `local-applications-v2` prompt uses the current task, checked state and
last action feedback. A no-call 45-world development preflight found that full
transcript accumulation could require a single conservative reservation of
110,541 tokens; compact state reduced the maximum to 25,529. This is reservation
accounting, not measured model tokens or a guarantee the full run fits. Provider
usage reconciles each reservation; unknown usage retains the conservative charge.

The comparison has one-shot, verified-repair, scaffold and deterministic arms.
Per world/arm ceilings are 96,000 tokens, 16 calls, 180 seconds and 16 scaffold
rounds; request timeout is 60 seconds with no retries. Development allowed 4,096
output tokens per call; the final test allows 8,192 for both models, as explained below.
One-shot deliberately uses one call. Both model IDs explicitly request `medium`;
actual calls/tokens and reported reasoning tokens remain separate outcomes.
Paired raw/support discordance records improvements and regressions on identical
worlds. Unknown is abstention unless the separate symbolic search saturates.

Development used six depth-2/3 worlds from
`2026-09-15-scaffold-effort-dev-v1`. Both models' one-shot and scaffold arms
supplied four of four answerable proofs and two correct unknowns. Mini's repair
arm supplied three proofs: one premise mismatch was followed by 4,096 reasoning
tokens and no assistant text. GPT-5.5's repair arm supplied all four proofs.
Mini one-shot/repair/scaffold charged 12,671/18,488/50,628 tokens;
GPT-5.5 charged 11,350/11,238/52,094. All 48 records replayed with zero differences
or integrity errors; no certified false assertion or budget overrun occurred.
Thus scaffolding did not improve on direct proofs in this small development set.

Based on that development output exhaustion, the final test raises the same
output cap to 8,192 for both models. Other caps, code and prompts stay fixed.
The test uses all 45 depth/topology/answer cells from
`2026-09-15-scaffold-effort-test-v1`, unused before protocol freeze. Source,
prompt, configuration and dataset hashes are retained. A single writer lock and
reconciled paid-attempt ledger prevent silently restarting interrupted work.
Replay reconstructs each tool action, final proof, local work and paid accounting.

```sh
PYTHONPATH=corpus python3 -m reasoning.scaffold_run \
  --oracle-repo ../agentic-qr --run-dir corpus/runtime/reasoning/scaffold-mini-medium-dev-v1 \
  --split dev --seed 2026-09-15-scaffold-effort-dev-v1 --count 6 \
  --connection-service caveman-strategy-core --model openai/gpt-5.4-mini \
  --reasoning-effort medium --request-timeout 60
PYTHONPATH=corpus python3 -m reasoning.scaffold_run \
  --run-dir corpus/runtime/reasoning/scaffold-mini-medium-dev-v1 --replay
```

## Completed explicit-medium test, including endpoint refusals

The frozen comparison covered `openai/gpt-5.4-mini` and `openai/gpt-5.5` on the
same 45 worlds: depths 4/6/8, five topologies, and three gold outcomes.
There are 30 answerable worlds and 15 unknowns. Each model has 180 unique
episode/arm records. Independent audits reproduce both summaries, all prompt and
source bindings, proofs, tool actions and usage ledgers, with zero integrity
errors or verification differences. Settings were not tuned during these tests.

Mini completed normally. GPT-5.5 encountered **23 HTTP 402 endpoint refusals**
from episode 38 onward: eight one-shot, seven verified and eight scaffold pairs.
The retained artifacts contain the status, empty text and absent usage, but no
message establishing the specific account/credit cause. These are service errors,
not model-generated malformed answers. All failures remain in the full test
denominators; this interruption prevents a clean model-capability comparison.

| Model | Arm | Raw correct | Supported proofs | Correct unknowns | Calls | Charged tokens | Reported reasoning subset |
|---|---|---:|---:|---:|---:|---:|---:|
| GPT-5.4-mini | One-shot | 45/45 | 24/30 | 15/15 | 45 | 155,618 | 30,718 |
| GPT-5.4-mini | Verified repair | 45/45 | 30/30 | 15/15 | 52 | 188,498 | 38,998 |
| GPT-5.4-mini | Scaffold | 37/45 | 18/30 | 15/15 | 192 | 1,006,313 | 144,144 |
| GPT-5.5 | One-shot | 37/45 | 22/30 | 12/15 | 45 | 256,756 | 11,519 |
| GPT-5.5 | Verified repair | 38/45 | 26/30 | 12/15 | 48 | 255,008 | 12,935 |
| GPT-5.5 | Scaffold | 37/45 | 25/30 | 12/15 | 243 | 1,302,860 | 59,746 |
| Symbolic search, each run | Deterministic | 45/45 | 30/30 | 15/15 | 0 | 0 | Unavailable |

Within the verified arm, mini started with 24/30 valid proofs and repaired all
six rejected cases using seven extra calls. The separate one-shot arm uses
independent initial samples, so its aggregate difference is not itself a count
of repaired proofs.

Mini's scaffold stopped on its own in all 45 worlds: eight premature unknowns
on answerable tasks and four asserted finishes without a derivation caused its
support deficit. There were no
cap or transport stops. Three unknown-candidate rejections occurred in one case.
The tool therefore did not improve mini's result despite substantially greater
token use. Supplied local applications do not ensure that a model selects or
finishes them correctly.

GPT-5.5's verified arm started with 23 valid proofs and repaired three invalid
proofs in three extra calls; four answerable cases and three unknowns ended with HTTP 402
errors. Its scaffold had 37 caller finishes and eight transport stops, with no
premature unknowns or unsupported asserted finishes. One malformed action was
corrected during a successfully completed episode. The one-shot arm also had
three correct labels whose proofs were rejected.

As a **post hoc diagnostic**, the 37 worlds completed by all GPT-5.5 arms contain
25 answerable cases and 12 unknowns. On those same worlds, both models' verified
arms supply 25/25 proofs; one-shot supplies mini 20/25 and GPT-5.5 22/25, while
scaffold supplies mini 15/25 and GPT-5.5 25/25. This service-complete subset was
selected after observing the refusals, is not randomly missing, and does not
replace the full test or establish general model parity.

Paired support counts retain improvements and regressions on identical worlds:

| Model / scaffold comparator | Both supported | Scaffold only | Comparator only | Neither |
|---|---:|---:|---:|---:|
| Mini / one-shot | 14 | 4 | 10 | 17 |
| Mini / verified repair | 18 | 0 | 12 | 15 |
| GPT-5.5 / one-shot | 22 | 3 | 0 | 20 |
| GPT-5.5 / verified repair | 25 | 0 | 1 | 19 |

Each row spans 45 worlds. Neither includes the 15 gold unknowns, which cannot
earn proof credit. GPT-5.5's differences also reflect the timing of service
refusals; they do not isolate a policy effect.

Charged tokens are **local budget accounting**, not a vendor invoice.
All 289 mini calls have provider usage, totaling 1,350,429 tokens. GPT-5.5 has
313 provider-accounted calls totaling 1,367,211 tokens plus 23 refusals whose
unknown usage retains 447,413 conservatively reserved tokens. Its local charged
total is therefore 1,814,624; the extra reservation is not established consumption.
Conservative estimates are not guaranteed invoice or tokenization bounds, and
the recorded refusals do not establish whether those requests were billed.
Reported reasoning tokens are a subset of completion tokens, already included
in provider usage. There were zero certified false assertions, token/output
overrun flags or observed episode/request time-limit exceedances.
The two runs overlapped; their elapsed times are descriptive, not a controlled model-speed comparison.
The legacy `transport_elapsed_seconds` summary field includes local overhead
between responses. Independent audits also retain the sum of request-event times.
Symbolic CPU work is counted explicitly; its elapsed time was not measured here.

The HTTP refusals exposed a dispatch defect: this frozen runner continued with
later tasks after an unrecoverable endpoint response. The subsequent runner
change interrupts the run on recorded HTTP 401/402/403, retains partial metrics,
and refuses automatic resume of that fatal event. It does not rerun or rewrite
this experiment. No further paid test was launched.

**Conclusion within this test:** checked repair is a useful simpler path for
mini, and the supplied finite rule worlds are already exactly solvable without
a model. This is evidence for bounded proof composition under supplied rules,
not faithful extraction of arbitrary text, induction of economic mechanisms,
frontier parity, or discovered alpha. These inspected test worlds are now consumed
evaluation data. Any later tuning needs a fresh distribution or held-out seed.

Full records and independent audits stay under ignored
`corpus/runtime/reasoning/scaffold-mini-medium-test-v1/` and
`corpus/runtime/reasoning/scaffold-55-medium-test-v1/`.

Their exact source checkpoint is NL `29787a0` with QR `618baad`; strict replay
must use those versions after the subsequent runner change. Run the commands
below from that source checkout, with an absolute path to the retained run
directory if using a separate worktree. Never alter stored source hashes to
make current code pass historical replay.

```sh
PYTHONPATH=corpus python3 -m reasoning.scaffold_run \
  --run-dir corpus/runtime/reasoning/scaffold-mini-medium-test-v1 --replay
PYTHONPATH=corpus python3 -m reasoning.scaffold_run \
  --run-dir corpus/runtime/reasoning/scaffold-55-medium-test-v1 --replay
```

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

## Historical omitted-effort checkpoints

Earlier runs used `typed-worlds-v2`/`proof-proposer-v1` through OpenRouter, with
reasoning effort omitted. Official defaults differ:
[GPT-5.4-mini](https://developers.openai.com/api/docs/models/gpt-5.4-mini) defaults
to `none`, [GPT-5.5](https://developers.openai.com/api/docs/models/gpt-5.5) to
`medium`; intermediary behavior was not independently attested. These results
cannot establish a matched-effort model comparison or mini's reasoning ceiling.

The 15-world historical test used depths 4/6/8 and five topologies, with ten
answerable worlds; per-arm caps were 48,000 tokens, two calls, 4,096 output tokens
per call and 120 seconds. Request timeouts were 60 seconds for MiniMax and 30
for the explicit GPT wrapper.

| Exact model | Supported one-shot / self-review / verified | Raw correct, same arms |
|---|---|---|
| `minimax/minimax-m2.7` | 5 / 2 / 6 of 10 | 9 / 7 / 9 of 15 |
| `openai/gpt-5.5` | 10 / 10 / 10 of 10 | 15 / 15 / 15 of 15 |
| `openai/gpt-5.4-mini` | 0 / 0 / 0 of 10 | 6 / 6 / 7 of 15 |

MiniMax frequently exhausted output before usable text; GPT-5.5 repaired one
proof. All six development/test runs historically replayed with zero integrity
errors, verification differences, certified false assertions or budget overruns.
Together they charged 763,808 tokens; access smokes used 117 additional tokens.
All are consumed development evidence. Their immutable configs retain exact
development caps, source/prompt/data hashes, responses and accounting.

Artifacts are `dev-v2-a`, `test-v2-a`, `dev-gpt55-a`, `test-gpt55-a`,
`dev-gpt54mini-a`, and `test-gpt54mini-a` under ignored `corpus/runtime/reasoning/`.
Strict replay requires their recorded historical code; never rewrite old hashes
to fit changed client or runner sources.
