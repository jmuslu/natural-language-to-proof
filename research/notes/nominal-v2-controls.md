# Independent unknown-nominal v2 red controls

Full-access shell verified. Requested worktree initially absent; created
astra/nominal-v2-controls from research990760f, preserving open-nouns38b260d.
Own this note, NOMINAL_OPEN_NOUNS_V2_CONTROLS proposal, and
NominalOpenNounV2Spec.hs only. Frozen v1 source8e2a6ad is read-only in its existing
nominal-universal-trial worktree; no implementation change or root gate change.

Prediction before checks: four unknown/mixed nominal sentence rows each fail
selected/status/all-readings (12 expected red assertions); known cat/animal
control passes3;9 unsupported/POS boundary checks and7 origin/escape checks pass.
Total34 checks:22 PASS/12 FAIL. Hypothetical v2 unknown admission is not claimed
implemented; v1's rejecting unknown POS remains its approved behavior.

Exact corpus-free command:
`runghc -i/home/gram/astra-wt/nominal-universal-trial/src -itest test/NominalOpenNounV2Spec.hs`
The source worktree HEAD/source cleanliness must remain8e2a6ad when reproducing;
this branch intentionally does not import or commit v1 production files.
No CCGbank loading, new model or answer benchmark.

Initial execution returned19/31 PASS with12 expected failures; initial total34
prediction had an arithmetic mistake (15 sentence +9 boundary +7 origin =31).
All four positive unknown/mixed rows absent exactly as predicted, known row and
all boundaries pass. Added three independently necessary guards: subject NN+JJ,
subject NN+NNP with known complement, and complement offered only NP to reject
category invention. Prediction before second run:22/34 PASS,12 expected FAIL.

Second execution22/34 PASS,12 expected red exactly as corrected prediction.
Frozen source worktree HEAD still8e2a6ad, src diff clean. Pending capability vs
plain packing is covered; known-vs-inferred origin class is absent from v1 API
and therefore explicitly deferred as a required future direct test, not falsely
claimed tested. Existing v1 unknown rejection must remain an explicit v1-policy
control when a separately reviewed v2 policy exists. No current test weakened.

Reviewer requested explicit alphabetic/lowercase and prior-only controls.
Prediction before extension run: dax2, dax-blicket, dAx,123 receive no new route;
prior-only dax/blicket have no tmWord entry or POS but actual offered N (fixture
precondition passes). Three independently required semantic checks for their
context-licensed reading remain red on frozen v1. Expected42 checks:27 PASS,
15 FAIL. Added no source change or test-expected relaxation.

Extended result27/42 PASS,15 expected FAIL as predicted. Explicit prior-only
precondition passes; all4 spelling guards pass against frozen v1. Proposal now
specifies a single default-v1 model policy enum and a shared typed noun-origin
payload inside existing NominalRole, carrying known/inferred subject/complement
contexts through completion and existing packing. No added all-sign boolean,
source implementation, fake POS, Q unwrapping or altered old negative assertion.
Future origin-sum tests are explicitly pending API introduction, not claimed run.
