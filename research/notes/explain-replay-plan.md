# Concrete Explain shared-replay plan

2026-10-14 restart: shell works fullaccess. Assigned worktree absent initially;
created astra/explain-replay-plan from research990760f, preserving queued FOLIO
worktree and coordinator dirt. Reviewed existing409d3ab audit and current source.
Own proposal, tests and this note only; no shared source/cabal modifications.

Prediction before execution: independent production meaning fixtures pass for
ordinary/list/fused/reflexive/conditional cases. Existing Explain replay fails
list and fused positives and accepts forbidden conditional/composed-reflexive
provenances despite matching root meaning. Test runner changes only the module
header of a temporary Explain copy to expose private functions; semantic code is
identical. Tiny authored tag/POS models only: no CCGbank load or answer/model run.
Command: python3 test/run-explain-replay-proposal.py. This is an expected-red,
unregistered proposal suite; no claim release gates are green follows from it.

Result: expected-red exit1,10/14PASS and4FAIL. Production fixture meanings all
pass. Missing current replay for final-OR list and fused restriction reproduced.
Conditional forged path and composite-reflexive-governor forged path absent from
production but accepted by current Explain. Strong reflexive case shares the
legal path's final meaning, proving root equality is insufficient for local guard
legality. No assertion that forged conditional is production output. Prediction
held. Temporary compile directory/binary cleaned automatically; no generated
artifacts or model/cache edits committed.

Concrete proposal EXPLAIN_SHARED_REPLAY_API.md specifies shared context, raw
annotated leaves, guarded unary/binary and local root operations, read-only list
views, complete opaque identity, safe renderer integration and explicit witness
limits. Full derivation retention/large parser refactor excluded. Static diff
check passes; changes confined to own proposal2tests/notes. Reviewer requested.
