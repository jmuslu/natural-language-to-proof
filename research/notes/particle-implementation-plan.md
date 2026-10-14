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
