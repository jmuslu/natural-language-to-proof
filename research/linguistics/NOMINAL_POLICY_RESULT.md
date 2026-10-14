# Paired nominal-policy fidelity result

The bounded optional policy repairs five sentences in a fixed 190-case diagnostic,
with no selected-meaning regression. **KnownNounsOnly remains the default.** This
result does not certify representative ProverQA fidelity or reopen model and
answer-benchmark launches.

## Fixed comparison

The [preregistered plan](proposals/NOMINAL_POLICY_MEASUREMENT.md) was reviewed
before either policy output. Both runs used accepted source `d83adaa`, the same
binary, the same 190 independently specified gold rows, the default parser with
POS backoff disabled, a 600-second timeout, and identical ordered training-file
snapshots. The 190 rows contain 188 distinct texts and separate semantic
contracts; aggregate counts are diagnostics, not an acceptance score.

| Explicit nominal policy | Exact | Wrong but typed | No parse | Incomplete |
|---|---:|---:|---:|---:|
| known-only | 63 | 32 | 94 | 1 |
| context-unknown | 68 | 32 | 89 | 1 |

[Compact aggregate results](nominal-policy-result.json) retain fixed construction,
semantic-contract, benchmark-versus-authored and old173/new17 partitions.

Every prior exact case remains exact. Five no-parse cases become exact; all 185
other selected meanings and statuses are unchanged. No case becomes newly wrong.

| Case | Independently specified meaning | Licensed change |
|---|---|---|
| pronto-nominal-1 | yumpus of the named subject | Context-licensed complement; existing attested name |
| pronto-nominal-2 | yumpus of the named subject | Context-licensed complement; existing attested name |
| pronto-every-1 | Every wumpus is an impus | Subject and complement noun hypotheses bound to their occurrences |
| pronto-each-2 | Each yumpus is a dumpus | Subject and complement noun hypotheses bound to their occurrences |
| prover-positive-nominal-1 | archaeologist(Abraham) | Existing attested name with context-licensed complement |

The two universal cases and two named nonce complements were directional
hypotheses. The Abraham case belonged to the preregistered named control family;
its trace records the same bounded complement admission. No unknown-name
exception was introduced. The named classification predicates are Asserted; universal
antecedent/consequent atoms remain Embedded under the Asserted implication.

## Retained readings and trace qualification

All nine preregistered targets were checked against the unchanged independent
gold across every returned reading. Six targets, including already-exact Arthur,
have one exact reading each; three remain unparsed. No target has a retained
wrong-but-typed alternative. Five cases change retained meanings.

Three additional cases change **trace annotations only**: `pronto-every-2`,
`pronto-each-1`, and `reflexive-quantified-2` acquire inferred noun-capability
notes for tumpus, yumpus and hedgehog. Their reading counts, meanings, selected
statuses and existing scope/reflexive decisions are unchanged. Thus five semantic
changes must not be reported as only five changed full reading objects.

## Denominator and provenance

The 190-case baseline extends the prior 173 with seventeen independently reviewed
rows: three Pronto negative-adjective source cases, four authored controlled
Something cases, three authored stand-out cases, and seven authored operator
cases. Before enabling the policy, the old 173 outcomes were unchanged; the new
seventeen contained three exact, seven wrong-but-typed and seven no-parse cases.
Those new failures are denominator expansion, not a source regression. They do
not establish population coverage or complete construction coverage.

Ignored evidence is under `research/runs/expanded190-baseline` and
`research/runs/expanded190-context-unknown`. Both retain invocation, execution
schema `nominal-policy-v1`, before/after snapshots for all 2,000 candidate training
paths, source and binary hashes, producer observations, reports, timing and a
completion seal. Baseline time was93.70s with177,664KiB peak RSS; optional time
was93.68s with176,384KiB peak RSS. The same1,875 files were readable;125 paths were missing.
Independent review verified these artifacts and the complete comparison.

- Cases SHA256: `ee8f3aef38b6925cc626da95d2bf65e6b3a7eb9baa342a5d021ca9cc8c23e564`.
- Binary SHA256: `5fb8272a294621f315df69a168f2ec340930f26710648701c55b607b9bb0dba5`.
- Known-only observations: `7217d0d7872bcc920c9ea1bf8957500f469d1d0347a6a8a589a14b60ac52f724`.
- Context-unknown observations: `34a2a761c28739be5b416e11b94b6a826734f43ad6b69f65f93553e390a68cd8`.

The 86,788 Pronto structural opportunities remain an inventory count, not 86,788
successful parses. This small diagnostic supports keeping the option available
for further controlled fidelity work. It does not justify enabling it by default
or treating type-correct unknown nouns as universally faithful interpretations.
