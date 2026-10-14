# Explicit nominal policy in fidelity observations and replay

Proposal only, against accepted research2d1cae6. Nominal v2 sourcea4846ca has
separate reviewer approval for a default-preserving trial; it does not activate
the unknown interpretation by default. No exporter, scorer or verifier changes
are included here. The original v2 document's absent-constructor discussion is
historical: typed constructors and direct tests now exist. Manually constructed
packing controls establish identity preservation, not proof that lexical
provenance was honestly minted; actual miniature parsing controls independently
exercise trusted lexical admission.

## Minimal configuration contract

Use one small JSON `execution` object in every exporter response, producer report
and verified replay manifest:

```json
{"schema":1,"parser":"default","nominal_nouns":"known-only"}
```

Allowed parser values are the existing `default`, `pos`, `hand`. Allowed nominal
values are exactly `known-only`, `context-unknown`, `not-applicable`. Schema is
an integer1, never a Boolean. Exact keys and enum values are validated. Hand must
use not-applicable; default/pos must use either known-only or context-unknown.
This front-end field prevents claiming a hand or POS observation as the default
CCG parser. It is not a hash or evidence of authentic execution.

The proposed exporter option is `--nominal-nouns=known-only` or
`--nominal-nouns=context-unknown`, mutually exclusive and unique. Absence preserves
KnownNounsOnly for CCG parsing. Hand refuses any explicit nominal option;
its effective response is not-applicable. Configuration errors fail before model
loading. The exporter computes the effective execution object once from its
validated invocation and actual ParserChoice/model; both successful observations
and errors echo it. Never copy configuration from request/gold metadata. Request
schema remains exactly id/text; no gold or extra mode key enters parser requests.

The scorer gets an optional `--nominal-nouns` choice. Omission selects known-only
for default/pos, not-applicable for hand; explicit hand nominal selection fails.
For CCG runs it passes the explicit selected flag, even known-only, and records
the effective object. Old invocation syntax therefore preserves semantics; a new
scorer requires a protocol-capable exporter and fails if echoes are absent. It
does not silently downgrade on an old binary. Before scoring or writing an
acceptance report it checks every response execution object equals the selected
invocation object, including error responses. A mismatch is protocol failure,
not no-parse, wrong-but-typed or a denominator exclusion. No scoring logic or
gold interpretation changes.

## Replay binding and historical compatibility

Extend `verify_replay` with optional `expected_execution=None`. New reports with
execution metadata require every frozen response to carry an identical validated
object. Producer parser must match its execution.parser. Replay manifest echoes
that object; the existing report/observation hashes bind its bytes. If caller
supplies expected_execution, require exact equality with the sealed object.
Thus an explicitly requested enabled panel cannot silently reuse a known-only
cache. Even subset replay validates every frozen response before selecting rows.
Hash the updated verifier and scorer as today. Hash equality alone cannot check
mode consistency: synthetic controls intentionally refresh hashes after editing
mode metadata. This does not provide adversarial authenticity against rewriting
all mutually consistent artifacts; the existing seal caveat remains.

Old frozen reports/responses lack mode evidence. Retain their existing historical
replay path only when *both* report and all frozen responses omit execution and
expected_execution is absent; report manifest execution as null with explicit
`execution_binding: legacy-unrecorded`. This is historical compatibility, not
inference that the mode was known-only from a binary hash or output. A partial
missing/mixed declaration fails. Explicit known-only or enabled requests against
such legacy evidence fail rather than upgrading it retrospectively. Existing
retrospective observation seals remain separately labeled and cannot establish
a mode that was not recorded. Historical scores/gold files are never rewritten.

For new protocol evidence use `execution_binding: producer-declared-consistent`;
this does not claim authenticated process execution. Policy claims remain
orthogonal to source/binary/environment binding and independent fidelity.

## Required checks before implementation review closes

The independent synthetic file test_nominal_policy_protocol.py exercises known
positive, enabled manifest, mixed echoes, report relabeling, missing echoes,
unknown enum, Boolean schema, front-end mismatch and invalid hand/unknown pairing.
Rejection cases run normal Python and python -O; no asserts implement validation.
It is intentionally red on the old verifier and is not a registered acceptance
suite until implementation lands. Reuses only synthetic integrity fixture setup,
not its verification algorithm; all expected mode relations are independently
stated here.

Additional implementation tests must cover duplicate/conflicting flags and hand
errors before loading; actual exporter echoes on successful and error responses;
scorer explicit flag propagation and rejection before scoring; expected_execution
mismatch; historical unrecorded labeling and rejection of explicit requested
mode; default/pos allowed combinations; null/extra-key protocol rejection. Test
exporter request-only validation remains intact. These are pending obligations,
not claimed tested by the nine replay controls.

After separately approved implementation and default gates, coordinator may
perform a separately sealed enabled fidelity measurement. Record both policy and
all-retained/selected meaning outcomes; keep panels and denominators separate.
No model training, answer benchmark, fresh corpus load or measurement is
authorized by this proposal or performed by this worker.
