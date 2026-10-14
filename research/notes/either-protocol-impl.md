# Either protocol implementation candidate

Full-access shell verified. Isolated astra/either-protocol-impl from579db46.
Cherry-picked reviewed5c187c9 as b85fe29, retaining reviewed proposal/test files
absent on base; no root dirty files assumed. Actual exporter test/fidelity/Export.hs,
not tools/FidelityJSON.hs; coordinator corrected ownership and approved verifier
ownership. No scoring/gold-admission changes beyond exact reviewed dependency.

Implementation prediction: the11 independent protocol tests turn green as schema,
CLI metadata and existing replay exact-object validation accept v2. That does not
prove runtime either support. Actual exporter supports explicit legacy-disabled
only; surface-inclusive-v1 fails before loading with an honest unavailable-route
error. No enabled echo can be emitted by this binary. Operator agrees; downstream
proverqa marker→XOR consumer incompatibility remains a blocker to future enablement.

Offline exporter build passes. Full Python discovery at this checkpoint129 tests
all PASS, zero skips/expected failures, both exporter environment variables set.
Then added an actual v2 metadata-renderer/error-path probe using GHC against the
exporter module: it constructs only configuration fields and feeds a malformed
request, never parses a sentence or loads a model. Focused19 protocol tests all
PASS including that probe and built exporter hand/error/invalid/enabled-unavailable
checks. A separate optimized-Python focused run is pending. No claim of actual
CCG v2 parsing follows from metadata-only probes or mocked enabled wire results.

Existing replay implementation already validates every frozen execution object
through fidelity.validate_execution and compares exact expected_execution, so no
verifier source edit is needed. Old v1 bytes/meaning path retained; explicit
legacy-disabled emits v2; enabled startup fails with no stdout before load.
Comparator/admission functions (evaluate_case, observation_error, summarize,
validate_case, validate_meaning) are AST-identical to reviewed5c187c9 dependency.

Future enabled integration needs names' EitherPolicy/smEitherPolicy and relatives'
rrOriginFailure accessor. Root specifically requires actual emitted per-reading
origin-lowering diagnosis while retaining typed form/candidate and absent DRS.
Current aggregate calls this type_failure; preserving that historical partition
must not misdescribe it as failed typing. Added synthetic count/retained-reading
control, but actual origin-failure emission is NOT implemented/tested before the
carrier dependency exists. No enabled runtime or downstream proverqa XOR
consumer compatibility is claimed; those remain explicit blockers.

Optimized `python3 -O` focused protocol run also19/19 PASS with actual exporter
and GHC renderer/error probe enabled (17.297 seconds). Implementation commit is
staged protocol capability only, deliberately fail-closed for enabled execution.
