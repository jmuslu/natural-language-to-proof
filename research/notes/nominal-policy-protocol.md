# Nominal policy protocol design and independent red controls

Full-access shell works. Isolated branch from accepted research2d1cae6;
coordinator dirty/staged files untouched. Own proposal, this note and standalone
synthetic protocol tests only. Nominal v2 a4846ca remains frozen for the separately
reviewed default trial. No production implementation or exporter invocation.

Prediction before checks: current verifier accepts internally inconsistent mode
metadata because mode has no protocol contract yet. Of9 new tests, consistent
known-mode fixture passes; enabled manifest binding and7 rejection tests fail.
Each rejection checks ordinary Python and python -O. Hashes are refreshed by the
fixture so these are independent metadata-semantic checks, not repeated digest
mutation checks. Existing replay fixture provides only synthetic sources,
nonexecutable binary bytes and manually authored meaning; no parser is invoked.

Final standalone command `python3 test/fidelity/test_nominal_policy_protocol.py`
ran9 tests:1 positive PASS and8 expected red tests (15 assertion failures because
7 rejection tests each run normal and optimized Python). The manifest lacks the
mode; all7 internally inconsistent declarations remain accepted by the current
pre-protocol verifier, exactly as predicted. Initial run also discovered the
imported base fixture's tests; changed to module-qualified import so final run
contains only the intended9 controls. No production code changed. Proposal
specifies legacy-unrecorded behavior and pending exporter/scorer/consumer-mode
controls honestly as additional implementation obligations.

Coordinator authorized isolated implementation after review; fidelity.py ownership
clarified as main invocation/report plumbing only, semantic comparator untouched.
Merged accepted f8871d5 then frozen v2a4846ca dependency; import-only conflict in
CCGSemParse resolved as union of required imports, no new parser behavior.
Prediction:9 independent red controls become green after strict mode checks and
manifest binding; historical fixtures remain accepted as explicitly unrecorded.
Add exporter hand success/error and invalid-option controls without corpus load,
scorer subprocess-mocked invocation checks, and consumer/subset legacy controls.

Reviewer caught actual-wire JNum1 serialization as1.0 versus strict Python int.
Approved protocol revision: execution.schema is exact string nominal-policy-v1.
No shared JSON serializer or existing top-level schema change. Actual-exporter
tests now call validate_execution (not Python numeric equality alone). Initial
full Python run had one old producer-mock missing echo; root authorized updating
only that test's local mocked response metadata, keeping legacy fixtures/digest
assertions unchanged.

Final exporter build succeeds offline. Full Python discovery with
NOMINAL_PROTOCOL_EXPORTER set to this built candidate:97 tests, OK,
2 preexisting expected failures, no skipped tests (77.550 seconds). Includes
actual hand exporter success/error wire validation and invalid flags rejected
before model loading; valid default/POS×known/enabled invocation uses subprocess
mocks, not a real CCG model. Seven original tamper families and invalid schema
variants also reject under python -O. Explicit consumer mode, all-frozen checks
under subset replay, and legacy-unrecorded behavior pass. No optional legacy mode
is inferred from binary/output. Comparator/gold-validator ASTs are identical to
the pre-change versions: evaluate_case, observation_error, summarize,
validate_case and validate_meaning. git diff --check clean.

Final implementation edits only Export.hs, fidelity.py protocol helper/main,
replay_integrity.py and owned tests/docs. run.py remains its original delegator.
Dependency merge contains reviewed v2 source; implementation commit adds no
CCGSemParse change. No corpus loads, new model/answer benchmark or enabled-v2
measurement. Coordinator must bind policy in its actual invocation/manifests
before any opt-in measurement.
