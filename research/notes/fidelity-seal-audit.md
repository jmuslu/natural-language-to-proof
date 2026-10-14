# Independent replay seal audit

Full-access shell verified in astra/fidelity-seal-audit at1eb363e. Own this note
and test/fidelity/test_replay_integrity.py only. Root ignored helper inspected
read-only; no parser, corpus, benchmark or model process launched.

Actual coordination-integration fresh report currently names154 frozen cases,
154 observations with154 unique request IDs. Frozen-case bytes match its stored
cases_sha256; case IDs equal observation IDs; binary bytes match binary_sha256.
This is evidence the inspected artifacts presently agree, not proof that the
replay helper enforces their agreement. No raw inputs were dumped.

## Findings from direct helper inspection

The helper checks binary and selected source hashes using Python assert; it does
not hash observation bytes, inspect frozen cases_sha256, verify exact frozen
request coverage, or reject duplicate observation IDs before dictionary overwrite.
It skips absent current datasets and permits duplicate current gold IDs, allowing
silent denominator changes. Its output stores current gold hashes and binary
hash, but not observation hash, producer report hash, scorer/helper hash, or
complete producer-source manifest. It filters producer hashes to src/ and Export,
so replay can use a changed scorer without recording its own version. Gold
changes can be legitimate rescoring, but must be distinguished from changes to
producer evidence and acceptance membership.

The report itself is a locally mutable trust anchor; hashing its dependencies
cannot defend against an adversary rewriting every hash together. Proposed
seal is accidental-change detection with explicit provenance, not a signature or
proof of authenticity. A reviewed immutable commit/independent manifest is needed
for stronger provenance. Never describe locally self-consistent hashes as
cryptographic proof that a binary actually produced these observations.

Prediction before independent tests: intact synthetic fixture, missing required
observation and changed request text behave appropriately; response tampering,
duplicate observation, corrupt frozen cases, missing frozen observation concealed
by current subset, duplicate current ID, and -O binary tampering incorrectly pass.
The tests invoke the actual helper in temporary invented workspaces; they do
not reproduce helper logic. Source/binary fixtures are never compiled/executed.
Expected3 PASS/6 FAIL among9 tests. Full fixture meanings authored independently.

Observed:9 tests,3 PASS and6 FAIL exactly predicted. Response mutation changed
an exact synthetic case into no-parse and replay still exited0; these tests
establish acceptance of changed cache evidence, not corruption of the actual
154-row cache. Test file remains an explicit expected-red audit outside release
checks until coordinator repairs the local helper. No existing tests weakened.

## Concrete minimal fix proposal, for reviewer/root before implementation

1. Replace assert with explicit exceptions for mandatory integrity checks,
   including source/binary mismatch and ID/text binding; Python -O must not
   disable the boundary. Missing expected dataset must reject unless an explicit
   versioned subset manifest was intentionally supplied.
2. At evidence production record observation SHA256 alongside binary, all source
   hashes and frozen input cases SHA256. Verify the recorded observation path,
   frozen-case bytes and observation bytes before parsing/scoring. Existing runs
   without that digest are legacy-unsealed; a retrospective digest alone cannot
   prove producer binding. Audit against existing immutable records then label
   the new snapshot seal time and its weaker origin honestly.
3. Require unique IDs separately in frozen cases, observations and current gold
   across all requested datasets. Verify exact frozen request ID/text coverage
   before allowing a requested current subset. Extra rows/duplicate IDs may not
   disappear through dict construction. Each request/response ID must agree.
4. Permit changed gold only as explicit rescoring: current ID/text pairs must
   match sealed requests; record old/new gold digests and explicit membership/
   contract manifest, with compatible partitions enforced. Gold updates do not
   license changed observations. Do not conflate preserved historical numbers
   with newly rescored output.
5. Write replay output with producer report hash, observation/frozen-case hashes,
   current binary/source hashes, current scorer/helper hashes, each current gold
   digest, exact dataset membership and semantic-contract panels. Source changes
   capable of affecting parsing invalidate cache; scorer changes require a new
   replay artifact/version but not necessarily a new parser run. Report both
   producer and replay identities instead of pretending same binary implies same
   scoring semantics.

A manifest listing mandatory source paths is also needed for strong drift
checks: merely iterating report.source_sha256 trusts a potentially incomplete
report. Current41 hashes are an observed list, not proof every dependency was
hashed. Build flags/environment/external CCGbank lexicon are outside current
source/binary/gold claims; document those residual trust assumptions separately.
No need to expose raw/licensed data to hash it. This audit does not authorize a
fresh corpus load; coordinator may repair tooling and preserve the legacy cache
as diagnostically useful but not falsely fully sealed historical evidence.

## Reviewed hardening implementation

Root authorized portable verifier after review; original6-failure evidence above
is preserved. No actual historical report/observation was edited. New
`replay_integrity.verify_replay(root, report_path, datasets, *, required_sources=None,
retrospective_seal=None, helper_paths=())` returns verified snapshot `cases`,
`observations`, and `manifest`. The caller scores only those returned snapshots,
not files reread later. Dataset mapping is explicit and mandatory; missing paths
fail. Full frozen coverage remains mandatory even for a selected current subset.

Default source inventory is every current src/**/*.hs plus Export.hs and must
exactly match producer parser-source membership, catching added/deleted paths.
An explicit required_sources override is recorded as narrower caller-selected
scope, never silently represented as default verification. Every producer digest
has a checked lowercase64hex shape; every current parser digest must agree.
Python assert is absent. Report/observation/case bytes are hashed before JSON
loading; duplicate IDs, wrong texts, response-ID mismatch and duplicate dataset
paths fail before scoring. Metadata never enters parser requests.

`audit_legacy_seal(root,report_path,audit_note)` returns, but does not write, a
retrospective record. It requires a nonempty independent-audit note; caller must
retain that audit evidence and explicitly write/select the record. Verification
never invokes it automatically. The seal binds current report/frozen-case/
observation bytes, timestamp and `producer_binding:false`; it does not claim
original producer binding. Missing producer digest without this separately
supplied labeled record fails. New producer reports add observations_sha256 in
fidelity.py immediately after writing observation bytes; no scoring code changes.

Replay manifest includes producer report hash, observation and frozen-case
hashes, binary hash, complete recorded and verified parser-source hashes,
current gold path/hash/ordered IDs/contracts, selected and frozen membership,
and hashes of verifier/current scorer plus explicitly supplied wrapper paths.
Callers must pass their local helper in helper_paths and retain the manifest
with replay results. Semantic-policy coherence and acceptance sampling remain
separate reviewed obligations, not self-certified by these hashes.

Validation predictions before implementation were the same original tamper
rejections plus positive legitimate rescoring/subset paths. Initial hardening21
controls pass; expanded24 controls pass, including mocked producer execution
(the subprocess is mocked, no parser launched), cross-dataset ID duplication
and missing audit note. Final digest-shape negative raises suite to25. Existing
fidelity contract18 and edge11 tests pass. No corpus/model runs, no sourcecache
regeneration, no changes to observed semantic scoring or historical results.

Final validation result: all25 replay integrity tests PASS, including subprocess
runs under Python -O and rejection of malformed recorded scorer digests.
