# Multi-hop reasoning: protocol and evidence

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

## Measured development checkpoint

`dev-v2-a`, 2026-09-15: exact model `minimax/minimax-m2.7` at the explicitly
configured OpenRouter endpoint. Three two-hop chain episodes: one entailed,
one refuted, one unknown. Prompt unchanged from `proof-proposer-v1`.

| Arm | Raw labels correct | Supported answers / 2 answerable | Correct raw unknowns | Calls | Charged tokens |
|---|---:|---:|---:|---:|---:|
| One-shot | 3/3 | 2/2 | 1 | 3 | 9,883 |
| Generic self-review | 3/3 | 1/2 | 1 | 6 | 17,739 |
| Verified repair | 3/3 | 2/2 | 1 | 3 | 7,112 |

All 12 calls completed, with 34,734 charged tokens and no budget overruns or
false assertions. The self-review arm twice retained nonchronological premise
references on one episode. The verified arm's initial proofs already passed,
so **this run contains no successful repair and no evidence of improvement over
one-shot**. Different first proposals use independent model samples; three tasks
cannot separate sampling variation from method effects. Two access smoke tests
used another 117 tokens, outside this experiment.

Offline replay reconstructed all nine episode/arm records with zero verification
differences or integrity errors. Original artifacts are retained under ignored
`corpus/runtime/reasoning/dev-v2-a/` on the research host.

- Dataset SHA256: `16f03b28ebe15b7a0adb1827036571b97aef278786ddce2444ee93ad0c232163`
- Prompt SHA256: `be83bf0c2fd36590753356cdb4846ea18a88a5e5718076b3b3fa46ac9ec93115`

The next frozen pilot uses 15 test episodes across depths 4/6/8 and all five
topologies, the same prompt, and 48,000-token / two-call / 120-second ceilings per
arm/episode (4,096 output tokens per call). Test responses are evaluation data;
any later tuning needs fresh held-out seeds/compositions.
