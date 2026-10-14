# Particle implementation plan

Full-access shell works; new isolated branch based on astra/research 990760f.
Old unmerged worktree preserved. Own proposal, standalone test and notes only.

Prediction before corpus-free execution: seven construction positives/provenance
checks should fail before the new span mechanism; ordinary walk and fourteen
negative escape controls should pass (15/22). The test uses only miniature
hand-built tag/POS dictionaries and public parser APIs. No corpus/model loading,
new frozen gold, or answer benchmark. Negative controls prohibit introduction
of give_up; they do not assert no other independent reading can exist.

Observed: 15/22 pass, seven expected red construction/provenance cases, matching
the prediction. Initial test compilation needed a Haskell layout correction;
no expected meaning changed. Build command: `ghc -isrc -itest -outputdir
/tmp/astra-particle-plan test/ParticleLicensingProposalSpec.hs -o
/tmp/astra-particle-plan/check`; running it exits 1 for the documented reds.
No claim that the branch passes implementation gates. Reviewer must approve
plan and controls before production edits.

Implementation phase prediction before source edit: add DRS/claim, score,
competing-offer, boundary/repeated-input and feature controls. Construction
positives remain red; competing ordinary transitive sense may expose a mini
fixture issue (lowercase up is not a rigid proper name). No production fix
will weaken the established gold.

## Bounded implementation candidate

Before source change, expanded controls measured 22/34 pass and 12 expected
construction failures. The ordinary-alternative control was corrected to use
an independently named object Ada (lowercase up offered NP has no rigid-name
meaning); expected give(Raul,Ada) is independent of particle semantics.

The candidate adds particleLexeme in CCGSem, a finite/base sense/category
license with the existing unary template, and a single immutable particleSeeds
list in CCGSemParse. Both catCell and semantic cell consume it before closure
and pruning. Both source leaves, original categories and separate log scores
are recorded; total score is their sum. Existing one-token alternatives and
all sign fields remain intact. No global up entry, term rewriting, text rewrite,
new private chart export, or transitive-object deletion is introduced.

Focused final controls: 35/35 pass, including independent positive/negative
DRS and claims, nonzero source-score conservation with competing offers, exact
certificate category/span assertions, repeated sentence offsets, feature and
continuation escape controls. Source reviewed locally with git diff; whitespace
check passes. Frozen particle gold untouched. No CCGbank/model load or answer
benchmark launched; root must review and perform full fresh fidelity/gates.

Focused regression results so far: reflexives 21/21, conditional duplication
14/14, lexical punctuation 139/139. Additional composition/fused/coordination
checks are recorded below when complete. Initial loop guessed three suite
filenames incorrectly; rerun uses actual discovered names, not skipped gates.

Remaining focused regressions all pass: CompositionFeatureSpec exits 0; fused
relative 89/89; coordination diagnosis 24/24. No full-suite or fresh corpus
fidelity claim is made by this worker.
