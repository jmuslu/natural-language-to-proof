# Explain list replay audit

2026-10-14 full-access shell verified, clean astra/explain-list-audit at c409f22.
Owned proposal EXPLAIN_LIST_REPLAY.md and this note only. Read tools/Explain.hs,
Pipeline conversion, and pending coordination source via git show4c37c66. No
source edits, tests, parser runs, CCGbank loads, models or benchmark launches.

Static finding: Explain local Cand/semComb lacks CoordList and treats commas as
AND; pending production coordinateList can reinterpret certified edges as OR.
Root equality/fallback is honest, while mkReading obtains authoritative meaning
and DRS from Pipeline. Fused sentence-local leaf pairing is unavailable to replay;
reflexive/conditional guards also differ even when root terms happen to match.

Recommendation: factor shared sentence-leaf/unary/binary replay operations from
production, wrapping actual state instead of duplicating certificate logic. Keep
root/provenance/target checks, show list repair as semantic step, diagnose replay
failure separately from linguistic error. Root Sign erases internal evidence:
compatible reconstruction cannot be advertised as exact original derivation.
Exact original would require compact witness retention through Pipeline, with
memory review, not an Explain-only rewrite. Corpus-free acceptance ideas included;
no test or measured renderer failure is claimed. git diff --check passes.
