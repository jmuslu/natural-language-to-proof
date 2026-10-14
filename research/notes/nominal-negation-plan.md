# Bounded nominal negation plan

Created isolated astra/nominal-negation-plan from accepted fedfbfd. Full-access
shell verified; name candidate remains frozen. Own proposal/test/notes only.
No production source changes, CCGbank load, model or benchmark execution.

Read current vpNot subject-over-negation contract, nominal certificate/active
roles and source-category pair checks, plus CONSTRUCTIONS frequency tables.
Prediction before tests:12 independent negative nominal acceptance checks red
because v2 only certificates adjacent is+a/an;18 boundary/ordinary route checks
should pass. Known-name cases additionally depend on the separate name candidate.
Run against accepted fedfbfd first, then the frozen657af1d source to distinguish
name dependency from still-missing negation. Expected gold DRS/status authored
independently, not derived from parser outputs.

Results: accepted fedfbfd yielded0/12 positive checks (12expected reds) and
18/18 initial boundary checks. Existing category/operator proof controls6/6pass:
source and internal BwdXComp derivations, type, named meaning, universal scope,
and distinction from NOT-wide universal.

The comparison command aimed at the frozen name worktree failed imports after
root landed1b9fc27 and removed that old worktree; this was an infrastructure
failure, not a parse/fidelity observation. Fast-forwarded this isolated branch
to accepted1b9fc27 (no edits to shared production source). On accepted names,
the same12 negative-nominal checks remain red. Added explicit forward-only-not
rejection; final boundary suite19/19passes. This isolates still-missing nominal
negation from the now-accepted named-subject dependency.

Commands for current accepted base:
```
runghc -isrc -itest test/NominalNegationPlanSpec.hs --positive
runghc -isrc -itest test/NominalNegationPlanSpec.hs --boundaries
runghc -isrc -itest test/NominalNegationPlanSpec.hs --operator
```
Positive mode intentionally exits1. Other modes pass. Default includes all37
checks with12known reds; never register it as a green release suite yet.

Recommendation: one exact backward crossed copula+not transition, reusing the
existing subject-over-not VP operator, with typed is/not/article occurrence
certificate. No global property-not category or generic pending-composition
permission. Parent/reviewer must approve before any source implementation.
Pronto47,529 predicate-negation and Prover562 negative-copula totals are not
nominal intersections; no recovered-count forecast or new inventory scan.
