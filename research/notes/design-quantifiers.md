# Quantifier design specialist, 2026-10-14

Scope: proposal and standalone red specification only. No production, shared gold, cabal, LOG or STATE edits. No corpus/model/benchmark process.

Read snapshot closedTable/closedClassWords/openTemplate/unarySem, DRT Build/Canonical, existing gold, cached Pronto default/POS observations, and cached Explain examples. Reviewed pinned ccg2lambda 2015 YAML directly and Boxer 2008 publisher PDF. Cache evidence is historical and does not assert behavior of a later branch.

Prediction before standalone red check: all seven checks fail on this snapshot because some/no/each are neither reserved nor supplied determiner entries; the modifier template emits modifier before noun. Command: `runghc -isrc test/QuantifierProposalSpec.hs`. This test imports semantics only and loads no CCGbank corpus. Test failures are the proposed acceptance contract, not a release-gate regression.

Full-access resume verified shell and preserved transferred unrelated dirt. Recreated missing proposal at research/linguistics/proposals/quantifiers-determiners.md. Read current gold directly from astra/gold-folio (no=negated existential) rather than trusting stale transferred files. Standalone command executed: seven expected FAILs, exit1; no corpus load. Proposal explicitly separates determiner repair from nominal copula/lemma dependencies, flags scope/status and N/N semantic licensing, and makes no current corpus fidelity claim. Ready for independent review; no shared source edits authorized or performed.
