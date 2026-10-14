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

## Bounded implementation candidate (after c90f2d5 review)

Resumed full-access shell in this isolated branch; merged accepted d83adaa before
source edits. Only owned CCGSemParse, independent negation tests and these
proposal/notes changed. No cabal, export/scorer, shared state or gold edits.

Prediction before source: the four independent nominal clauses (12 semantic,
all-retained-reading and claim checks) remain red on accepted source; exact
source-frame implementation should make them green without changing ordinary
adjective or argument-indefinite negation. Baseline observed0/12. The additional
origin suite was authored before source; after correcting a test-only reserved
Haskell identifier its baseline fails to compile because the new API is absent.
That API-red is not counted as a passing semantic baseline.

Implementation uses a second NegativeNominalCertificate constructor sharing all
positive fields, with typed closed-not occurrence evidence. This preserves the
original positive constructor API and uses the total nominalNegation helper in
all shared paths. The private ClosedNotChoice is minted alongside the actual
selected closed lexical entry, never recovered from a note or lambda shape.
The mandatory duplicate not and copula share one frame. Exactly BwdXComp is
allowed before direct property application; source-pair evidence is required
for both original not composition and composed NP application. Complete keeps
all noun/name origins and negator evidence; packing distinguishes certificates.
No global not category, existential contraction, NP inversion or default-policy
change. A dedicated negative stipulation states the actual composition route.

Focused results before final regression completion:48/48 semantic/boundary/
existing-operator checks;60/60 origin/source-pair/packing/escape controls. Both
KnownNounsOnly and ContextUnknownNouns check known named/universal clauses;
unknown common nouns are tested only under the existing opt-in rule. The
all-reading checks require nonempty readings and Just the exact DRS for every
reading, including embedded claim status. Unknown names remain blocked.
Reviewer inspected live source and found no blocker; approval remains contingent
on final committed snapshot and full suites, then coordinator fresh fidelity,
Explain and all integration gates. No corpus gain is asserted here.

Final local validation: `cabal test all --offline --test-show-details=failures`
passed all29 registered suites. Current final source was compiled after its last
edit. Standalone semantic controls48/48 pass; final origin controls71/71 pass,
including two actual minted negative frames with identical not meaning retained
separately by packing and complete/active-role escapes against ordinary signs.
`git diff --check` is clean. New standalone suites remain unregistered because
cabal is coordinator-owned; run both explicitly until root registers them.
Full logs are copied into ignored research/runs/nominal-negation-local/ for
coordinator preservation before worktree cleanup. No source fidelity or coverage
measurement was run locally; reviewed candidate still requires root fresh gates.
