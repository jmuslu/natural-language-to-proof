# Fidelity observation contract edge audit

2026-10-14; isolated `astra/fidelity-audit` worktree. Full-access shell commands
succeeded. Owned files are this note and `test/fidelity/test_contract_edges.py`;
production scorer, gold and other workers' files are untouched. No parser,
licensed corpus, solver, benchmark or model process was launched.

Static review of `integral_number`, `observation_error`, `matches`, and exporter
`JNum` fields identified three independently observable contract holes. The seven
new regression methods deliberately include failing evidence rather than marking
failures expected or weakening assertions. Coordinator must repair and run gates
before merging/pushing this branch. These are wire-contract tests, not linguistic
fidelity estimates.

## Reproduction

`python3 -m unittest discover -s test/fidelity -p 'test_contract_edges.py'`
ran seven tests: two methods passed, five failed (four assertion failures,
including two subtests in one method, and two OverflowErrors). This initial
command was a direct reproduction of the static findings; no claim is made that
it was a preregistered performance experiment. Prediction for the proposed
repair: all seven methods pass, with the existing 18 methods unchanged.

1. A valid JSON integer with 401 decimal digits reaches `math.isfinite`, which
   converts it to float and raises `OverflowError`. A negative integer of this
   size in a count likewise crashes rather than returning per-case `error`.
   Such a failure prevents a report and loses the error denominator entirely.
2. Python equality treats `True == 1` and `False == 0`. Selected disjunction
   annotations with numeric flags are therefore called `exact` against boolean
   gold. A boolean False path index likewise equals integer zero. This is not
   the already-tested count coercion: nested selected meaning has no equivalent
   field-type check. All three malformed values currently score exact.
3. `selected={'drs': None, 'claims': None}` satisfies the top-level key check and
   becomes `wrong_but_typed`, even though there is no exported DRS/claim payload
   to compare. This belongs in instrumentation `error`, not semantic failure.

Passing controls establish two constraints on a repair: annotation index `0.0`
remains accepted (production uses JNum for these indices too), and six evaluated
responses, one per outcome, retain n=6, exact_rate=1/6 and one error in the same
construction denominator. The latter extends the existing five-status summary
check to include an actual evaluated instrumentation error.

## Precise proposed changes for coordinator

- Replace the integer predicate with
  `type(value) is int or (type(value) is float and math.isfinite(value) and value.is_integer())`.
  Python integers are always finite; booleans must remain rejected. Retain the
  existing nonnegative and ordering checks. This fixes overflow without imposing
  an undocumented arbitrary JSON integer limit. If the protocol later restricts
  integer range/index sequence, specify and test that separately.
- Make nested observation comparisons distinguish JSON booleans from numbers.
  A small recursive equality predicate can compare dictionaries by exact keys,
  lists in order, booleans only against booleans, and JSON int/float numerically
  (retaining the production integral float representation). Use it for each
  expected top-level meaning component in `matches`; observed top-level exporter
  metadata may remain additional, as today. Keep `first_difference` aligned so
  it reports boolean/number mismatches rather than returning no difference.
  Prefer an explicit annotation-shape check classifying malformed flags/indices
  as `error` as well, but at minimum these must never be `exact`.
- In `observation_error`, require selected `drs` and `claims` values to be objects
  before semantic comparison. Extend wire-shape validation as a separately
  reviewed change if needed. **Do not call the strict gold validator on all
  observed meanings as a shortcut:** an exporter-visible scope or claim-status
  error can be a real wrong-but-typed semantic output, which must stay measured
  rather than getting relabeled as an instrumentation error. Existing malformed
  universe-scope regression intentionally scores wrong-but-typed.

## Remaining boundary and denominator distinctions

A well-formed zero-parse response is no_parse; malformed counts/metadata or a
non-object selected payload is error. Both remain in construction denominators.
Type failure is distinct from neither root parsing nor malformed observations.
No exact primary result may be inferred from an exact retained alternative.

Request/response ID mismatch, duplicate JSON keys, missing/extra response rows,
non-JSON output, nonzero child exit, and timeout currently abort the whole harness
before report generation. That is a fail-closed batch protocol failure, not a
zero denominator score or permission to omit an input. Root should preserve the
failed batch as unusable; an optional future per-case transport-error design must
not guess ID alignment or compare against another case's gold. This audit does
not request weakening those batch checks.

Returned-reading semantic shape and aggregate consistency deserve a separate
exporter-aware audit: typed=True can legitimately coexist with no DRS when DRS
construction fails, and selected meanings are discourse-resolved whereas
alternatives are sentence-local. Do not add an equality constraint between the
selected meaning and one alternative without proving it against that contract.

## Bounded patch review follow-up

Independent reviewer accepted `c01b770`; coordinator requested four additional
contracts before integrating the bounded patch. The scorer is unchanged here.
New methods require nested extra-key differences and boolean/number differences
to produce a meaningful `first_difference`, while accepting additional exporter
metadata only at the meaning's top level. A free-reference scope defect inside
otherwise object-shaped meaning must remain wrong_but_typed, not error.

Against the unpatched scorer, all 11 methods ran: four pass and seven fail
(six assertion failures including subtests, two errors). The two added diagnostic
methods reproduce missing first-difference output; the two preservation controls
pass. The approved bounded proposal should fix all failures without gold-scope
validation of observed outputs. Coordinator owns that implementation and its
post-patch validation; this branch continues to provide red regression evidence.
