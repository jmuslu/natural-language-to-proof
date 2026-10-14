# Meaning fidelity

These checks compare English with **manually specified scoped meanings and claim
tables**. They do not compare a solver's answer with a benchmark label. Gold never
enters the parser process: `Export.hs` accepts only `{"id":"...","text":"..."}`.
It calls the production `Pipeline`, `canonicalize`, and `claimsOfDRS` APIs.

`hand-controls.jsonl` contains four authored instrumentation controls. They use the
hand lexicon's lowercase entity constants and are evaluated with `--parser hand`.
Construction regressions adapted from benchmark language belong in separate files;
retain item references and describe adaptations without copying external datasets.
Do not create expectations by saving the current parser's output.

`prontoqa.jsonl` contains 25 isolated original input sentences from the local
Logic-LM and ProntoQA-OOD releases, with file/item/field/sentence references. The
11 construction groups each have two or three examples. These are diagnostic
examples selected to cover constructions, not a random benchmark sample. No
answer labels or generated proof chains are included or used as meaning gold.
ProntoQA attribution and source licenses are documented in
[`bench/prontoqa/README.md`](../../bench/prontoqa/README.md).

For this controlled ontology fragment, copular nominals directly classify the
subject (`Max is a yumpus` means `yumpus(Max)`), names retain their written case,
and ontology plural nouns use singular predicate lemmas. Predicative `a/an` does
not introduce an extra individual linked by equality. Bare plurals take the
generic universal reading specified by this benchmark. `Everything that ...`
quantifies over the domain without adding an artificial `thing` predicate.
Conjoined predicates share the same subject witness. Three-way disjunction gold
lists both binary associations before any parser run, preserving each reading's
distinct embedded-claim traversal. These are explicit representation conventions;
they are not selected to match a parser output.

## Gold format

Each JSONL row has `id`, `construction`, `text`, `origin`, and a nonempty `gold`
array. `notes` should explain the intended reading and any fragment assumptions.
An origin has `kind: "authored-control"` or `kind: "benchmark-adapted"`; for adapted
cases also record `benchmark`, `item_id`, and the construction-preserving changes.
Each allowed gold reading contains **both** an explicit DRS and an independently
specified claim table:

```json
{
  "id": "example",
  "construction": "existential",
  "text": "A student smiles.",
  "origin": {"kind": "authored-control"},
  "gold": [{
    "drs": {
      "universe": ["r0"],
      "conditions": [
        {"tag":"pred","name":"student","args":[{"ref":"r0"}]},
        {"tag":"pred","name":"smile","args":[{"ref":"r0"}]}
      ]
    },
    "claims": {
      "universe": ["r0"],
      "asserted": [
        {"tag":"pred","name":"student","args":[{"ref":"r0"}]},
        {"tag":"pred","name":"smile","args":[{"ref":"r0"}]}
      ],
      "reported": [], "presupposed": [], "embedded": []
    }
  }],
  "notes": "The same existential witness is a student and smiles."
}
```

Terms are exactly `{"ref":"r0"}` or `{"const":"John"}`. Canonical references use
`r0`, `r1`, … in the production canonicalizer's first-occurrence order. Constants
and predicate names are case sensitive. A box has `universe` and `conditions`.
Supported condition shapes are:

| tag | Additional fields |
| --- | --- |
| `pred` | `name`, `args` |
| `eq` | `left` term, `right` term |
| `not`, `presup` | `body` box |
| `imp`, `or` | `left` box, `right` box |
| `att` | `verb`, `holders` terms, `body` box |

Implication antecedent binders are accessible in its consequent. Binders inside
negation, one disjunct, or an attitude box cannot escape to siblings. Gold DRS
scope is validated before parsing. Claim references must occur somewhere in the full gold DRS. This checks reference
integrity without deriving the expected classification. Claim conditions are inspected with their full
DRS: an embedded or reported condition may refer to a binder from that DRS. The
claim table must retain the exact root universe. Its four arrays preserve order
and multiplicity; asserted conditions, presupposed conditions, and embedded
conditions use the condition shapes above. A reported entry has this shape:

```json
{"condition":{"tag":"pred","name":"smile","args":[{"const":"Mary"}]},
 "chain":[{"verb":"say","holders":[{"const":"John"}],"factive":false}]}
```

The attribution chain is ordered from outermost source to innermost source.
Do not derive the expected table by calling the production claim splitter; that
would hide classification bugs. For genuine ambiguity, list each independently
justified acceptable full meaning in `gold`, before observing the parser. This
array is not a place to accumulate wrong outputs until a case passes.

`Canonical` intentionally strips provenance and does not distinguish `or` from
an `either`-marked disjunction. Every gold reading containing a disjunction must therefore explicitly require
production-exporter annotations:

```json
"disjunctions": [
  {"path":["conditions",0],"either":true,"scope_ambiguous":false}
]
```

Nested paths continue through `body`, `left`, or `right` and `conditions`, then a
condition index. Its ordered value must match. Paths must cover every `or` condition in preorder,
including nested disjunctions. Specify the surface `either` marker independently
from inclusive or exclusive truth conditions: inclusive OR may have `either: true`.
The intended unambiguous attachment requires `scope_ambiguous: false`. Exclusive
meaning must be represented in the full DRS, not inferred from this marker. Paths must be unique and point to actual `or` conditions; negative
indices are invalid. With no disjunction, the field may be omitted or set to `[]`.
It records the existing exporter marker; it does not certify a universal linguistic
interpretation of “either”, and it never changes the canonical representation.

## Outcomes

The primary result compares the **selected, discourse-resolved meaning** against
the full DRS and claim table of an allowed reading:

- `exact`: both structures match, plus any required annotations.
- `wrong_but_typed`: every selected sentence produced a typed DRS, but meaning or
  claim classification differs. Unsupported semantic placeholders remain here;
  they are not relabeled as parse failures.
- `no_parse`: no sentence produced a selected root derivation, or no sentence was
  recognized.
- `type_failure`: all sentences parsed but at least one selected meaning failed
  type checking or DRS construction.
- `incomplete`: some sentences parsed and others did not. A matching retained
  fragment cannot make an incomplete document exact.
- `error`: the observation process explicitly reported an exception, or its
  response has malformed counts, selected-meaning shape, or reading metadata.
  Counts must be nonnegative integers satisfying DRS ≤ typed ≤ parsed ≤ total;
  missing counts are instrumentation errors, never parse failures.

All categories remain in the denominator, with counts per construction. This is
exact structural fidelity: condition order and multiplicity matter, as required
by `Canonical`; logically equivalent rewrites may still fail. It is not an
independent theorem of semantic equivalence or a population accuracy estimate.

For a single-sentence case, `any_reading_exact` separately records whether a
returned typed alternative matches gold. It does not replace the primary selected
result. For multiple sentences this secondary result is undefined: sentence-local
alternatives are not silently treated as resolved discourse alternatives. Parser
search is bounded, so failure to find a reading does not prove its impossibility.

## Run

```bash
cabal build nl2proof-fidelity-json
python3 -m unittest discover -s test/fidelity -p 'test_fidelity.py'
python3 test/fidelity/run.py \
  --cases test/fidelity/hand-controls.jsonl \
  --binary "$(cabal list-bin nl2proof-fidelity-json)" --parser hand \
  --output research/runs/fidelity/hand-controls-report.json --require-exact
```

For corpus-backed runs use `--parser default` or `--parser pos`; the executable
loads the same local licensed model as `nl2proof-parse-json`. Neither training data
nor learned data is stored here. `--require-exact` makes a regression command fail
unless every case is exact; omit it when measuring documented open failures.

Execution policy is explicit. For a corpus-backed diagnostic, the driver accepts
`--nominal-nouns known-only` (the unchanged default) or
`--nominal-nouns context-unknown` (the bounded experimental noun policy).
The hand parser rejects either nominal-policy option. This option controls
lexical admission; it does not change the independent gold or comparison rules.
The active research gate and reviewed measurement plan still govern launches.

Every current exporter response, including errors, echoes an `execution` object
with schema `nominal-policy-v1`, parser and nominal-noun policy. The producer
checks that echo against its invocation before scoring; replay checks it against
the report across every frozen response, including responses outside a requested
subset. A consumer can also require `expected_execution`. Historical reports
without this protocol remain explicitly legacy-unrecorded: a binary hash does
not establish their execution policy. Run all contract tests with
`NOMINAL_PROTOCOL_EXPORTER` set to the built exporter path to include real
hand-parser success/error and invalid-flag checks without loading CCGbank.

The report contains case and executable hashes, relevant source hashes, per-case
first differences and selected meanings. Full gold-free observations and parser
stderr are saved beside it. Reports belong under ignored `research/runs/`, not in
the fixture directory. No model API or solver is called by this harness.

## Semantic contract partitions

A case may declare evaluation-only metadata in either form:

```json
"semantics_contract": "person-generic-rule-v1"
```

```json
"semantics_contract": {"id": "person-generic-rule-v1", "policy": "retain person restrictions"}
```

The string or object `id` must be a nonempty, non-whitespace string. Other object
fields document policy; the scorer does not interpret or enforce their content.
IDs are preserved exactly, not inferred from text or benchmark names. Metadata
is optional; absence becomes `semantics_contract_id: null` in the evaluated row.
Explicit null or malformed metadata is rejected before invoking the executable.
Only `id` and `text` are projected as sentence requests; neither semantic-contract policy nor gold is sent. Execution configuration is supplied separately through explicit CLI options.

Reports retain their existing aggregate and per-construction counts, adding
`by_semantics_contract`: a list of partitions ordered with null first, then IDs
lexically. Each partition contains `semantics_contract_id`, all six outcome
counts, fixed `n`, exact rate, any-reading diagnostic and its own per-construction
counts. A list keeps legacy null separate from any user-declared string ID.
Missing contract metadata in older evaluated results is treated as legacy null.

`aggregation_scope` is `empty`, `legacy_unversioned`, `single_declared_contract`
or `mixed_contracts`. Every summary explicitly sets
`certifies_acceptance_panel: false`: these counts are diagnostics. Historical
unversioned gold can itself contain incompatible disclosed policies, and a
shared declared ID does not prove consistency, source independence or adequate
construction coverage. Do not pool incompatible expectations for acceptance.
The `--require-exact` exit check is unchanged: it requires every input row exact
as a regression check, **not** certification of a coherent panel or permission to
restart benchmarks/models.

This is minimal public reporting support for
[SEMANTIC_CONTRACTS](../../research/linguistics/SEMANTIC_CONTRACTS.md), not the full
sidecar-manifest proposal. It does not enforce panel membership/hashes, migrate
historical gold, add alternative readings, resolve same-English policy conflicts
or produce population estimates. Independent review and versioned membership
remain necessary. Scoring structures and all failure denominators are unchanged.
