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

Reviewer found argparse last-value behavior could bypass exporter duplicate
rejection. Added SingleEitherPolicy argparse action: repeated/conflicting new
policy options fail during argument parsing, including separate/= spellings and
accepted abbreviation aliases. No historical nominal-option behavior changed.
Independent four-spelling prelaunch test asserts exit2, no subprocess, no report.
Focused actual-exporter suite now20/20 PASS normally and under python-O. No new
corpus loads. Carrier/chart integration and actual origin-failure diagnostic
fixture remain active work; this correction does not claim vertical completion.

Vertical follow-up remains active, awaiting committed chart/carrier dependencies.
Coordinator rejected adding a public Pipeline API solely for tests; actual failure
wire regression will use GHCI module context/private backEnd, chart-minted roots
and a deliberate origin snapshot mutation, not manually constructing failure.
Future exporter wiring must set/echo the actual SemModel.smEitherPolicy enum;
changing protocol validation alone is never enabled parsing. Per-reading
origin_failure field will be conditional on Just rrOriginFailure, so legacy
success objects remain byte-compatible. The root-selected failure must retain
form/typed=true/meaning=null plus truthful origin-lowering reason and index.

Vertical integration checkpoint: source dependencies are committed kernel
66422d6, layout179bd67, assemblyb589913, chart e0609c4, lowerer925beaf and
carrier c8e9dde (cherry-picked without edits). Before checks, prediction: explicit
policy can now set the actual model enum and emit enabled metadata truthfully;
legacy execution remains exact v1; actual snapshot rejection retains typed form
without DRS, preserves position, and emits origin failure rather than pretending
type checking failed. The actual exporter is a fidelity observer only: no solver
or legacy ProverQA XOR consumer is invoked. This does not authorize another
consumer to interpret inclusive surface markers as exclusive disjunction.

Replaced staged unavailable rejection after dependency integration. Explicit v2
metadata reads smEitherPolicy, which main configures from the requested option.
Conditional origin_failure appears only on rejected active readings; its detail
is the actual Pipeline OriginFailure. Existing aggregate type_failure partition
is deliberately unchanged for parsed/typed but DRS-missing observations.

Independent actual-wire control uses a temporary renamed test fixture module,
GHCI private Pipeline context, an actual chart root and deliberate ssSem snapshot
mutation. No public test-only API or fabricated ReadingResult is introduced.
It checks enabled public success with local either=true, actual loop error echo,
failed reading index0 typed=true/form present/meaning null with
ChartOriginFailure OrSnapshotMismatch and OriginLoweringFailure trace, and later
valid reading index1. No corpus loads. Focused20/20 passed; full suite follows.

Build qualification: cabal link failed because the root-owned cabal file does
not yet register new OrOccurrence. The ensuing installed-library undefined
symbol also invalidated the concurrent full/optimized test attempts (not a
semantic failure); logs retained /tmp/either-vertical-build.log,
/tmp/either-vertical-all.log and /tmp/either-vertical-optimized.log. Root notified.
Building the actual exporter directly with ghc -isrc into /tmp instead; module
context tests hide installed nl2proof so they compile the exact source modules.
No cabal edits made. Re-run outcomes below supersede these failed attempts.
Direct exporter build succeeded. Cabal-installed dynamic library remained
unusable until coordinator registration, so actual module probes explicitly use
GHC -package-env - with local src/test paths (global containers only); hiding an
installed package inside cabal exec was insufficient. Optimized focused suite
20/20 PASS (/tmp/either-vertical-optimized-final2.log), no skips/expected failures.
Full Python suite131/131 PASS with both exporter variables pointed to the
source-built actual binary (/tmp/either-vertical-all-final2.log), no skips or
expected failures. Coordinator requested internal ExplicitLegacy rename to
ExplicitPolicy because both explicit modes now use it; this is wire-neutral.
Rename-focused20/20 PASS (/tmp/either-vertical-rename.log). Names hardening
checkpoint e6408b0 now cherry-picked unchanged as7d7a4a5; final direct build and
focused wire regression rerun follows that exact dependency.
