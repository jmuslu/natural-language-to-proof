# Explicit either execution binding, preserving nominal-policy-v1

Design only. This plan changes no parser, exporter, scorer, gold, existing cache
or default190 behavior. It complements the reviewed either vertical-interface
work; it does not authorize its implementation or enable it by default.

## Two exact schemas, no implicit mode upgrades

Preserve the existing object unchanged:

```json
{"schema":"nominal-policy-v1","parser":"default","nominal_nouns":"known-only"}
```

A new **explicit** either invocation uses:

```json
{"schema":"parser-policy-v2","parser":"default","nominal_nouns":"known-only","either_policy":"surface-inclusive-v1"}
```

Schema tags are exact strings, never numeric versions. Each schema accepts only
its exact keys. v1 retains existing parser/nominal combinations, including hand
with nominal_nouns=not-applicable. v2 parser is default or pos; nominal_nouns is
known-only or context-unknown; either_policy is exactly legacy-disabled or
surface-inclusive-v1. v2 hand is invalid: this first vertical path depends on
CCG occurrence/category evidence, not the hand front end. Do not add nullable
mode fields or infer hand behavior by an arbitrary default.

Absent `--either-policy`, the exporter and driver preserve v1 invocation/echo
bytes and effective legacy-disabled parser behavior. They do not pretend v1
historical evidence explicitly recorded an either policy. Explicit
`--either-policy=legacy-disabled` emits v2 with the declared disabled mode;
explicit `--either-policy=surface-inclusive-v1` emits v2 with the enabled mode.
The driver accepts the corresponding separate option/value spelling and forwards
the exact exporter flag. Either flag combined with --hand, duplicate/conflicting
either options, or an unknown mode fails before loading any model. The nominal
option remains independent; no hidden coupling to ContextUnknownNouns.

This is backward compatibility with existing v1 consumers/artifacts, not silent
translation of v1 into v2. Old v1-only consumers must reject v2 rather than ignore
the new field; reviewed new validators recognize both schemas independently.

## Meaning of the two runtime choices

Legacy-disabled retains current default behavior and all existing lexical/scope
choices. Surface-inclusive-v1 selects only the reviewed, occurrence-bound either
vertical path: actual paired marker/OR edge and scoped inclusive disjunction.
It does not mean context-free XOR, all-English-disjunction recovery, or permission
to erase parenthetical material. Explicit exclusion such as but-not-both requires
its independently represented NOT/AND content; it cannot be manufactured from
the presence of either or from a benchmark convention.

The option applies coherently to a whole process/run. Never inspect case IDs,
benchmark origin, gold disjunction annotations, semantics_contract metadata or
expected status to select it per sentence. Parser requests remain exactly id/text.
An enabled result conflicting with exclusive benchmark gold remains wrong under
that contract and is reported in its existing partition. Do not relabel gold,
introduce an equivalence exception or drop those cases to advertise improvement.

## Invocation → producer → replay contract

Exporter startup validates flags and records the effective configuration alongside
its actual ParserChoice/model. Response construction uses that effective state,
not an echoed user JSON value. Every success AND parser/request-error response
carries the complete execution object; forced-rendering exception paths do too.
Configuration errors before startup produce a nonzero exit, not a synthetic
successful report. v1 success/error objects remain v1 when no either flag appears.

Driver validates every response object against its selected process configuration
BEFORE evaluate_case or any successful report write. Any absent, unknown, mixed,
extra-key or conflicting echo is a hard protocol failure, not no-parse or a case
excluded from denominator. Report execution equals invocation and echoes.
Existing scorer comparison, canonical claims, statuses and gold validation remain
unchanged. Driver records complete argument vector and usual binary/source/cases/
observations digests; v2 field is included in hashed report/observation bytes.

Replay validates the schema-specific object, producer parser agreement, and every
frozen response before selecting any current subset. A caller's expected_execution
must match EXACTLY, including schema and either mode. v1 cannot satisfy a requested
v2 legacy-disabled or enabled contract: identical meanings or a familiar binary
hash do not record an unobserved configuration. Existing missing-execution
artifacts remain legacy-unrecorded and satisfy no explicit requested mode.
Mixed absence or mixed v1/v2 responses fail. Retrospective seals never manufacture
a missing policy declaration. The verified manifest preserves the actual object
and existing producer-declared-consistent/legacy-unrecorded labels; no mode
upgrading or field deletion before hashing/comparison.

Examples: an explicitly enabled producer report with one disabled response fails
even if their selected formulas happen to match; a subset excluding that row
still fails. A recorded enabled cache cannot serve a disabled expected request.
Two separately consistent disabled/enabled reports may be compared only with
identical frozen cases/source/environment and explicit policy partitions.

## Independent controls and implementation obligations

`test_either_protocol_proposal.py` contains11 synthetic tests. Existing v1
validation/replay/invocation remain unchanged. Future positive controls require
both v2 modes to validate/replay and enabled CLI to forward its exact flag and
record the echoed object while requests stay id/text. Negative controls cover
v1 smuggling, invalid v2 enums/schema/hand, legacy missing modes, v1-to-v2 upgrade,
mixed frozen responses under subset replay, and error-echo mismatch before scoring.
These tests use nonexecutable fixture bytes and mocked subprocess output, never
an actual exporter/model launch. They are independent desired API/wire assertions,
not a local implementation of the proposed validator.

On current code the v2-positive controls are intentionally red; several v2
negative controls pass solely because v2 is unknown. Do not claim those passes
prove correct mode pairing. After implementation, rerun all tests normally and
under python -O and require both positive modes; otherwise rejection-only tests
could conceal a validator that rejects everything.

Additional required implementation checks before release:

- Actual built exporter v1 hand success/error echoes and invalid either/hand,
  duplicate/conflicting and unknown flags rejected before any load.
- Corpus-free miniature model harness exercising actual default/pos mode-derived
  v2 success/error response generation. No tests may pass merely by comparing
  Python True and numeric1 or by supplying a hand-written echo to itself.
- Explicit disabled CLI propagation, enabled/disabled report mismatches, missing
  echoes, partial v1/v2 declaration and all frozen coverage checked under subsets.
- Default release gates and unchanged190 selected meanings/statuses plus explicit
  source/binary/environment binding before any separately authorized enabled run.
  Old invocation must remain v1; default evidence is not silently replaced by an
  enabled cache. No population/model-launch gate opens from protocol completion.

The model-side enum/field and constructor ownership belong to the either vertical
worker; this proposal does not add shared source flags. Coordinate one typed
policy interface before exporter edits. Any source version change between runs
needs a new comparison record; no new gold-based runtime selection shortcut.
