# Composition preserves both endomorphic feature dependencies

Full-access shell verified in isolated astra/composition-features. Own CCGRules,
standalone CompositionFeatureSpec and this note only. No corpus/model launch.

Prediction before red controls: four composition rules propagate matched
features to their surviving result only, leaving an endomorphic input generic.
Thus is:(S[dcl]\NP)/(S[adj]\NP) plus not:(S\NP)\(S\NP) falsely returns
(S[dcl]\NP)\(S\NP), accepting finite is-red as an adjectival input. Expected
independent controls fail four argument specializations and a local finite-input
rejection; genuine adjective input and unrelated-category guards must survive.

Mathematical contract: for composition X/Y with Y'/Z, unify Y,Y'. If X==Y,
propagate that unifier to X (existing behavior); independently, if Z==Y',
propagate it to Z. The latter equality is the whole right functor's explicit
endomorphism. Backward/crossed variants are identical up to slash order. Do not
substitute every atom named S or assume features in different subcategories
co-vary. Feature erasure preserves the same simply typed f(g(z)) composition;
only the fine syntactic input constraint becomes more informative. A matched
explicit adj cannot later accept an explicit dcl. Existing underspecified input
compatibility remains, and unrelated outputs/arguments remain unchanged.

Red14 result: five failures exactly predicted. Implemented four symmetric
surviving-argument specializations, no new unification rule or semantic template.
Green14 pass; added actual crossed-composition term type check and correct
matrix BwdXComp(is,not:VP\VP) control. All16 pass. This is a local category
scope guard, not a claim to have passed the complete fused-relative mini suite.
Fused worker supplied exact badtrace and confirmed correct output must be VP\AP.

Prediction before full corpus-free compatibility suite: existing category tests
and scope/semantic suites remain passing; any difference is investigated as a
regression, not silently relabeled. Command: cabal test all --offline
--test-show-details=direct; log research/runs/composition-features/tests.log.
Build/test currently running while source candidate is sent for review.
