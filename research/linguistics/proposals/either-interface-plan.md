# Ordinary either/or: pairing and operator provenance

Proposal only, base fedfbfd. No production implementation authorized here. This is separate from the deferred corrective `but` envelope, not-both ellipsis, and the frozen operator gold 01263e9 (outside accepted173).

## Evidence and priority

The four-benchmark operator audit is in `operator-gold-audit.md`. ProverQA has 1468 occurrences of either without a recognized exclusion suffix; that is a surface inventory bucket, NOT proof of inclusive intent. Explicit not-both has 4146 occurrences and remains a separate, higher-frequency ellipsis obligation. FOLIO sample has 19 VP either/or occurrences (13 distinct), four initial either occurrences (two distinct). Pronto restriction OR and ProofWriter controlled OR need no either semantics. Implementing ordinary pairing must not pretend to solve the exclusion suffixes.

Accepted selected cache `research/runs/everyone-closed-integration/fresh.json` retains no-parse for prover-vp_either_or-1/2, prover-sentence_either_or-1/2, prover-nested-xor-1/2 and prover-nested-or-1/2. These statuses do not isolate a lexical blocker by themselves. Historical Explain evidence in `negation-conditionals-disjunction.md` records offered VP-modifier and N/N categories, no semantic root, and open-class either predicates. Do not invent an observed sentence-initial S/S offer.

Source audit:

* `Pipeline.processCCG` sends cased tokens to semParse without removing either. `provIndexFor` indexes predicate/entity constants, not logical operator occurrences.
* `CCGSem.closedClassWords`/closed table do not reserve or interpret either. N/N fallthrough can create an unwanted predicate; identity admission without construction licensing would silently erase unpaired either.
* `CCGSemParse` has a genuine `CoordMark`/`CoordApply` edge, `pendingCoordinator` identifies that edge (not a descendant), and packing-aware `CoordList` preserves explicit operator edges. This is the right pairing boundary.
* `DRT.Build.toDRS` gives every TOr the full fallback provenance. `Bench.Export.ambiguousEitherProvs` detects shared either-bearing provenance and sets either=false, either_scope_ambiguous=true. This is honest abstention, not a local annotation solution.
* `bench/reasoning/solver.py` uses XOR for either=true only under explicit `or_semantics='proverqa'`; inclusive mode uses OR. The linguistic DRS and an input surface marker must not inherit that benchmark policy as an English universal. Never change solver/gold silently to make an either control pass.

## Learner derivation and independent meaning

STUDY_PLAN Unit2: adjective/VP category X = S[adj]\\NP (or a genuinely offered finite VP), with semantic type e→t. In `Bob is either red or big`, pair the literal marker occurrence with the same-category explicit `or` edge. The underlying connective is λQ:e→t.λP:e→t.λx:e.(P x ∨ Q x). Applying the coordinated predicate to Bob yields red(Bob) ∨ big(Bob). There is no both-exclusion term.

Unit3: intended DRS is an OR of two singleton predicate boxes; OR is asserted, both predicates are embedded, no reported or presupposed claims. The surface either flag belongs to this OR. `Bob is red or big` has the same truth conditions but no flag. Not-both means ¬(P∧Q), permits neither, and is neither this formula nor automatically XOR. Explicit OR plus explicit not-both would yield (P∨Q)∧¬(P∧Q), only after independently licensed composition.

Unit4: in `If Mira is either tall or quiet, then Mira is red or young`, root implication is asserted; antecedent OR, its predicates, consequent OR, its predicates are embedded in preorder. Only the antecedent OR carries either. The independently authored TT/TF/FT conditional controls in 01263e9 fix these marker locations. Shared fallback ambiguity is not their intended annotation.

## Bounded syntactic interface (candidate for review, not source approval)

First tranche only direct binary predicate coordination. Exact surface `either` (case-insensitive) must have an actually offered X/X category, X exactly an admissible S[adj]\\NP or S[dcl]\\NP with a common subject slot and matching features/type. Do not synthesize categories, repair N/N to VP, or enable sentence-initial S/S without separate evidence and controls. Reserve the word globally so unsupported senses honestly abstain; determiner `either book`, pronoun `either`, and `on either side` remain outside this tranche.

Use an occurrence certificate, not a new logical predicate or free identity:

1. A lexical pending marker records source/span, original offered category, X, and semantic type. It has no ordinary lexical identity reading that can reach a root.
2. Only direct forward application of this pending X/X to an unmarked plain X creates `EitherLeft(marker, operandSpan, X, operandTerm)`. Pending states reject ordinary application, composition, raising, coordination other than the closing rule, punctuation erasure and root acceptance. Exactly one marker; repeated markers cannot share an edge.
3. Closing rule is only existing CoordApply with this EitherLeft on the left and a direct explicit `or` CoordMark on the right. Match X/features/semantic types; require disjoint ordered contiguous lexical spans (apart from ordinary whitespace), actual same-source marker/edge, and no unmatched marker in either operand. Do not close on AND, comma, a descendant OR, or an outer OR reached by composition. For this first tranche disallow an operand with existing list certificate; mixed/nested/list cases wait for an explicit extension.
4. Build the usual typed OR of the two original operands, preserving existing conditional/fused/nominal invariants. Pair identity is `(source, either span, or span, operand spans, category)`. Include pending state AND completed pair evidence in packing. Full root coverage is required; unmatched either cannot vanish through structural punctuation.
5. The completed evidence is immutable, survives subject/copula application, and must reach occurrence-aware lowering below. Unsupported transformations reject the candidate rather than clear its pair evidence. Only punctuation and this explicit direct application envelope are in tranche1; raising/composition/distribution and mixed nesting need further tests. A certificate cannot authorize semantic changes outside its exact operator occurrence.

An alternative parse where either attaches to an already coordinated X is rejected in tranche1. This sacrifices derivations, not input fidelity: the licensed direct EitherLeft derivation suffices for the bounded examples. Do not admit both paths unless both preserve the same pairing and every retained reading meets the contract. Sentence-initial, nominal, multi-item, gapping and shared-marker nested coordination stay explicitly deferred.

## Required lowering interface: a real second seam

A SSign flag alone is insufficient. Ordinary beta normalization, canonicalAC and coordination rebuilding destroy naive term paths or merge structurally equal terms. `Map Term Prov` is unsound when identical OR formulas occur in different clauses; counting source occurrences or searching the sentence for either is also unsound. Current ProvIndex only indexes constants.

Proposed interface contract: semantic construction creates a unique operator occurrence key at the explicit OR edge; its annotation is `{or edge provenance, optional paired either provenance}`. An annotated semantic derivation must carry this key through substitution, normalization and DRS lowering. `COr` receives provenance belonging to that key, retaining the original marker span; unrelated COr receives no marker. Occurrence keys must not be keyed by normalized formula equality, and packing must distinguish different attachments. Beta duplication must copy occurrence evidence explicitly; elimination must not attach evidence to another node. Any annotation-losing transformation returns an incomplete/residual result, not an apparently precise marker.

This is a contract/API boundary, not a claim that the current Term API supports it. Before implementation, choose and review either an annotated-term evaluator or a restricted replay evaluator whose supported combinators prove preservation and whose unsupported operations abstain. Do not put fake predicate markers in terms, unwrap term shapes to guess provenance, or override shared-fallback abstention globally. No broad Term constructor proliferation is authorized by this proposal. The bounded lexical rule must land only together with demonstrated correct lowering for its envelope; otherwise it creates misleading precise XOR inputs.

## Comparisons and tests

Verified local reference map `REFERENCES.md` documents Bos2008's category-driven lexical semantics and separate discourse resolution. This supports separating compositional OR from pragmatic exclusion; it is not evidence that Boxer implements this exact certificate. No Boxer execution is claimed.

Pinned ccg2lambda YAML a68cb264413791150011c347c64a7b35e2f7270d, locally cached under root research/runs/linguistics-sources/ccg2lambda/en/semantic_templates_en_emnlp2015.yaml, has selected VP-modifier/N/N identity templates at609–617. Their identity term alone does not enforce an OR partner or localize DRS provenance. Sentence OR at102–106 is AND in that snapshot and is explicitly rejected as a semantic reference. Neither system was run.

`test/EitherInterfaceProposalSpec.hs` exercises public miniature Pipeline selected and EVERY retained DRS/claims; no CCGbank/model load. Separate direct lowering checks expose shared fallback conservatism and the missing local-interface information. The last direct lowering check intentionally asks the old API for information it cannot express: its red result is an interface lower bound, not evidence a lexical fix failed. Expected reds remain visible, never registered as a passing acceptance suite.

Before source approval add public conditional TT/TF/FT all-reading controls using the independent seven-row gold (without changing it), plus mixed edges, negation, reports, repeated markers, NP choice senses, bare N/N, punctuation and branch-attachment negatives. The miniature predicate tranche alone does not authorize those extensions. Root must freeze new membership before any corpus observation; no representative fidelity claim follows from synthetic success.
