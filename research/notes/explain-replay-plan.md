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

## Accepted particle diagnostic prediction (before load)

Full-access shell verified; merged accepted59955b6 into own isolated branch.
Frozen Explain binary and every source manifest hash verified against this tree.
Binary SHA256 e6d60f06e822f0d02a3f2bba2885ec0d7918f706f80953dee02ff96ad6f0bc54.
Only frozen particle texts: Raul gives up.; Ada gives up.; Raul does not give up.
Prediction: Pipeline returns give_up(Raul), give_up(Ada), NOT give_up(Raul),
with the negative atom Embedded and negation Asserted. Explain's independent
leaf replay likely cannot recover the two-token seed and prints raw provenance;
this is a diagnostic prediction, not an observation or a linguistic error.
Run one REPL load through root scripts/with-ccgbank-slot.py, --all-readings,
stdin research/runs/explain-particle-audit/input.txt; stdout/stderr retained
there. No new model or answer benchmark.

Before corpus-free rerun: adding two independent particle fixtures predicts
18 checks: production positive/negative pass, renderer both fail, leaving
12 passes and six expected red renderer controls. No production source edits.

Observed result: frozen Explain exited0, reports39,604trees/44,210wordforms
loaded83.6s. All three print exactly predicted normal forms and DRS/claims;
negation is Asserted and its positive atom Embedded. Each prints the explicit
raw-provenance fallback, preserving particle-lexeme:give_up with both source
leaves. No Pipeline failures. Lambda leaf tables are empty and tag tables say
"best tag; no selected derivation": these are renderer reconstruction limits,
not missing selected Pipeline semantics.

First replay obstruction from accepted source: Explain.hs541–545 admits a
two-child ProvRule only when show(combinator)==recorded rule;
particle-lexeme:give_up is a span-seed construction, not any combinator.
Its node has no candidate; ancestors cannot reconstruct. Positive seed spans
are Raul5:13 and Ada4:12, negative14:21; source categories are S[dcl]\NP
or S[b]\NP with (S\NP)\(S\NP). This diagnosis combines actual fallback
output with source inspection; current renderer itself emits no first-node
diagnostic. No linguistic first divergence from declared particle gold was
observed in these three examples. This does not imply general particle coverage.

Corpus-free rerun prediction held:12/18PASS,6expectedFAIL. All seven
independent production fixture meanings pass; failures remain renderer-only.
Ignored evidence: research/runs/explain-particle-audit/{input.txt,manifest.json,
stdout.txt,stderr.txt,proposal-tests.log,evidence-sha256.json}. Preserve before
worktree cleanup. stdout SHA256: f4184c9a627828c218a841d9b892ee4ad3b5c23a04d661981ece6f977a26997a
