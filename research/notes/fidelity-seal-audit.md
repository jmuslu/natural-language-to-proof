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
