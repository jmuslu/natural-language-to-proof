# Abbreviation boundary design notes

2026-10-14. Full-access shell verified: pwd returned the assigned
/home/gram/astra-wt/abbreviation-design and branch astra/abbreviation-design.
Read prior bd30b1d name diagnosis from the old name-ambiguity worktree, plus
current Tokenize.hs. Own proposal, standalone test and this note only.

No parser/model/benchmark/CCGbank call. Tests call only splitSentences and
casedTokens on manually authored strings with independent expected boundaries.
Prediction before execution:10 existing invariants pass;15 bounded proposals
and6 deferred initialism/quote proposals expose current failures. Groups remain
separate; this is not a registered green release gate.

Commands:
```
runghc -isrc -itest test/AbbreviationBoundaryProposalSpec.hs --invariants
runghc -isrc -itest test/AbbreviationBoundaryProposalSpec.hs --bounded
runghc -isrc -itest test/AbbreviationBoundaryProposalSpec.hs --deferred
```

Results matched prediction: invariants 10/10 pass (exit 0), bounded 0/15
pass (exit 1), deferred 0/6 pass (exit 1). These are known proposed reds,
not a release regression suite or evidence of a production fix.

Restart confirmed full-access pwd and preserved both partial files. Read
STATE.md then ASTRA_GOAL.md. Finished the owned proposal with intended
Units 2/3/4 meanings, sealed first divergence, and architectural Boxer /
ccg2lambda comparison; no claim about untested external tokenizer behavior.

Recommendation: independently review local span/numeric/terminator fixes;
honorific suppression requires an explicit input or ambiguity contract.
Initialisms and attribution quotes remain deferred. No source implementation,
semantic gain, parser load, or gold modification is included.
