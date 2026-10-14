# Canonical-reference admission for independently authored gold

Reviewed design based on accepted `b2e5dc4`, now a bounded implementation
candidate awaiting final source review. The gold-only helper is wired through
validate_case; observation/scorer/exporter behavior and fixtures are unchanged.
The two original rejection assertions now pass unchanged; only their
expectedFailure decorators were removed. Independent regressions live in
`test/fidelity/test_gold_canonical_admission_proposal.py`.

## Two different contracts

1. **Canonical first occurrence:** `DRT/Canonical.hs` collects distinct references
   in deterministic traversal order and assigns r0, r1, … . A self-contained
   canonical gold DRS should therefore introduce first occurrences in exactly
   that order. Reject r9-first, r01, skipped numbers and reversed declaration
   order; never silently rename or sort the hand-authored fixture.
2. **Unique gold declaration:** within one gold DRS, declare each canonical
   identity at most once, including nested and disjoint sibling boxes. This is
   an additional **gold-admission policy**, not an invariant of canonicalize.
   Canonicalize maps repeated source identities to the same canonical name and
   preserves the original universe lists, so it can export duplicate declarations.
   The corpus-free executable check in the ignored audit bundle confirms
   `[r0 | ~[r0 | sleep(r0)]]` is a possible canonicalizer result.

The policy is justified for reviewed, self-contained fixtures because one global
canonical identity should designate one introducing binder, with subsequent uses
controlled by DRS accessibility. An intended fresh nested/sibling witness needs
a fresh identity. Repeating an enclosing declaration obscures whether the author
intended reuse, accidental shadowing or a new witness. If repeated introduction
has an independently justified discourse meaning later, review a separate explicit
admission contract; do not reinterpret these strict fixtures by local shadowing.

This policy does not say all possible canonicalizer output is bad, redefine DRT,
or repair the production canonicalizer. Observations may contain contextual/free
references or duplicate introductions; their structural mismatch remains
`wrong_but_typed` under the existing protocol. Do not turn them into protocol
errors merely because reviewed gold has stronger requirements.

## Exact traversal and boundary

Run the existing schema, accessibility and claim-reference checks first. Then,
for each independently allowed gold reading, traverse **its DRS only**:

- Visit the complete universe list before visiting conditions in list order.
- Predicate arguments and equality terms retain written order.
- For negation/presupposition, traverse the body; for implication/disjunction,
  traverse left then right. This is numbering order, not permission for
  disjunct/negation witnesses to escape their existing accessibility boundaries.
- For attitudes, visit holders before the body.
- On every new reference identity require the exact string `rN`, with N equal
  to the number of distinct references already encountered. Repeated argument
  occurrences are legal; repeated declarations are rejected separately.

Reset both sets for each alternative reading and each fixture. Do not traverse
claim copies as new declarations: asserted/embedded/reported/presupposed arrays
reuse structures and identifiers derived from the same DRS. Existing validation
still checks root universe retention, schema, claim-reference membership and
explicit disjunction annotation coverage. This change neither computes the
expected claim classification nor certifies the manual claim labels as correct.

The helper returns control without mutating input. The reviewed implementation
exposes validate_gold_references, called from `validate_case` after ordinary
meaning validation, with reading index and path in its error. Do not call it on observations in evaluate_case, matches,
first_difference, response validation or replay comparison. Do not normalize
values, merge alternatives, remove fixtures, or change denominators/statuses.

## Independent controls and fixture audit

The new controls cover both requested rejections plus disjoint sibling
redeclaration, root-declaration order versus argument-use order, repeated terms,
equality, attitude holders, shared numbering across presupposition/negation,
disjunction numbering versus accessibility, claim copies and independent allowed
readings. A valid no-binder case remains valid. Noncanonical and duplicate-binder
observations still score wrong-but-typed. Existing free-reference rejection is
not weakened. The original prototype tests now exercise production validate_case directly;
no duplicate prototype or recursive validation wrapper remains.

Read-only fixture audit at branch base:

| Audited set | Rows | Allowed readings | Strict-prototype failures |
|---|---:|---:|---:|
| All 20 tracked `test/fidelity/*.jsonl` files | 177 | 185 | 0 |
| Frozen expanded190 panel | 190 | 198 | 0 |

The first set includes four hand controls; the expanded panel is a separately
frozen population. They overlap and must not be added. The expanded bytes match
SHA-256 `ee8f3aef38b6925cc626da95d2bf65e6b3a7eb9baa342a5d021ca9cc8c23e564`
in `expanded190-preparation/freeze.json`. The audit records every file hash,
row/reading count and error list in ignored
`research/runs/gold-canonical-admission/audit.json`. It reads gold only, without
observing any parser result or changing a fixture. No semantic score is inferred
from admission success.

## Review and implementation boundary (original plan)

Keep both original expected-failure assertions while this is a proposal. After
independent approval and actual production wiring, remove only the expectedFailure
decorators if their unchanged assertions pass for the intended reasons, and
retain explicit regression tests that observations still receive existing
statuses. That is resolution of a reviewed gold policy, not deleting failing
requirements to make a test count green. Root owns the integration and gates.
The initial proposal contained no production patch; subsequent bounded wiring
was explicitly authorized after review. No corpus/model/benchmark launch occurs.

Validation of this proposal: full Python discovery ran 111 tests (107 passed,
2 skipped, the original 2 expected failures); all 14 new prototype controls pass.
All audited fixture bytes were rechecked unchanged after validation. The two
skips are not silently counted as passes. No production admission fix is claimed.

## Bounded implementation checkpoint

After reviewer approval of d1ef6a9 and explicit coordinator source authorization,
validate_gold_references is called only from validate_case, after each reading's
existing validate_meaning. Original expected-failure assertions were invoked
unchanged and passed before their two decorators were removed. The unique test
file now calls production validation directly; its historical acceptance check
was replaced by the already reviewed rejection assertion, not a recursive helper.
No changes to observation_error, evaluate_case, matches, summarize, exporter or
fixtures were made.

The full suite with NOMINAL_PROTOCOL_EXPORTER bound to the accepted
nominal-policy-integration/fidelity-candidate passes **111/111**, with zero skips
and zero expected failures. The binary hash was checked against its accepted
fresh.json: `5fb8272a294621f315df69a168f2ec340930f26710648701c55b607b9bb0dba5`.
Its protocol checks use hand mode and invalid flags only; no CCGbank load occurs.
Both noncanonical and duplicate-declaration observation controls still return
wrong_but_typed, not error. All177 committed gold rows and frozen190 rows pass
production admission with every byte hash unchanged; current root's20fixture
files were independently checked too. This admits fixtures, not semantic claims.
Final source review and coordinator integration gates remain required.
