# Bounded negative nominal predication

The reviewed rule in `17a17f9`, with preregistration `0613299`, extends the
occurrence-certified nominal construction to **is not a/an N**. It uses the
actual closed-class backward `not` entry, one certified crossed composition,
and the existing noun and subject origins. No global `not: N/N`, unknown-name
promotion, new default noun policy or unguarded source-pair exception is added.
See the [construction proposal](proposals/NOMINAL_NEGATION_PLAN.md) and
[pre-observation predictions](../notes/nominal-negation-trial.md).

For a named subject, the intended meaning is `NOT(N(name))`: NOT is Asserted;
the positive atom is Embedded; the root universe is empty. For a universal
subject, negation stays in the consequent, below the subject quantifier. The
frozen panel has no direct universal negative nominal example, so that scope
claim rests on independent controls rather than an invented panel denominator.

## Fixed-input results

Both comparisons retain the independently frozen 190 IDs/188 texts. Each row
compares the new rule against the **same execution policy** before the rule.
The totals mix explicitly separate semantic contracts and are diagnostic only.

| Policy | Before: exact / wrong / no-parse / incomplete | After | New exact cases |
|---|---|---|---|
| Default `known-only` | 63 / 32 / 94 / 1 | 65 / 32 / 92 / 1 | Colin is not a bird; Nora is not a dancer |
| Optional `context-unknown` | 68 / 32 / 89 / 1 | 73 / 32 / 84 / 1 | The same two, plus Sam is not a rompus; Polly is not a dumpus; Dave is not an ostrich |

Each gain has exactly one retained reading, matching the independent DRS and
claim table. Every other case retains its selected meaning, status and complete
retained-reading objects: 188 default cases and 185 optional cases. There are
no trace-only differences, new wrong-but-typed cases or exact regressions.
Preexisting optional gains are not counted as gains from negation. The default
policy remains `known-only`.

The provisional default prediction was three gains; Dave remained no-parse.
Its optional-policy gain establishes policy dependence. The subsequent
[bounded lexical audit](proposals/nominal-negation-evidence.md) identifies a
necessary default admission blocker: Dave has positive proper-name POS evidence,
but ostrich has no noun evidence in the loaded snapshot. Sam/rompus and
Polly/dumpus have the same noun-evidence barrier. This does not establish every
chart or offered-category condition, or rule out additional independent blockers. Adalynn and Bodhi
remain no-parse under both policies. These are limitations, not permission to
relax name or noun guards.

## Checks and evidence

All 31 Haskell suites pass, including 119 added semantic/origin controls
(48 public scope/boundary checks and 71 actual-origin/escape checks), bringing
the check count to 1,970. Build, oracle boundary, Explain and four hand fidelity
controls pass. All 97 Python checks run without skips: 95 pass and the two
previous gold-admission-policy expected failures remain unchanged. Independent
review approved the source, default results and optional results before landing.

The same candidate binary is used for both policies. All 2,000 ordered training
paths have identical statuses/content hashes before and after (1,875 readable,
125 missing), matching the previous paired trial. Missing inputs remain a
limitation on claims about the complete CCGbank corpus. Optional execution is
explicitly recorded and echoed; it is not inferred from the binary.

| Artifact | SHA-256 |
|---|---|
| Frozen 190 cases | `ee8f3aef38b6925cc626da95d2bf65e6b3a7eb9baa342a5d021ca9cc8c23e564` |
| Candidate binary | `dcba130c1c9696af547b43b70a60b4aa7db00e403eb2ef7406c579420d8e4691` |
| Default observations | `136c351e22b3dba1a8d3611a17ce18c5edc234b4a80ce7f4c1aac93942f93ddf` |
| Optional observations | `ea05f1a1b8b1859f65ae3c73a227d7c34a0f7376fb76f8380e73d3470dca66fd` |

Local evidence is preserved under `research/runs/nominal-negation-integration`
and `research/runs/nominal-negation-context-unknown`; input fingerprints,
comparisons, producer observations, gate logs and optional seal remain local.
Explain's general compatible reconstruction is still not proof of its original
selected witness; actual-origin tests and retained producer provenance provide
the bounded construction evidence here.

The ProverQA starter remains 10/24 exact and is not a representative panel.
The representative >=90% exact/near-zero wrong gate remains closed. No answer
benchmark or LLM run follows from these results. A separately frozen 202-case
extension adds 12 reviewed source examples; it has not been observed by this
trial and does not change any number above.
