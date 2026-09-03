-- | Stage 2 test suite: probabilistic augmentation.
--
-- Kept separate from @Spec.hs@ on purpose. Stage 1 "is meant to stop changing",
-- so its check count should stay a stable number that means the same thing over
-- time. Adding Stage 2 assertions to it would make that number drift and destroy
-- its value as a signal.
--
-- The load-bearing test here is 'referenceGameChecks'. RSA has a known published
-- result on the two-object reference game, so pinning the recursion against it
-- means every /other/ number this stage reports can be read as a fact about the
-- model setup rather than a possible bug in the implementation.
module Main (main) where

import Data.List (isInfixOf, nub, sort)
import qualified Data.Map.Strict as M

import Harness
import NL2Proof.Fragment
import NL2Proof.Pipeline
import NL2Proof.Provenance
import NL2Proof.Semantics.Lambda
import NL2Proof.Stage2.Alternatives
import NL2Proof.Stage2.Distribution
import NL2Proof.Stage2.Fingerprint
import NL2Proof.Stage2.Model
import NL2Proof.Stage2.Modifier
import NL2Proof.Stage2.Pipeline
import NL2Proof.Stage2.RSA
import NL2Proof.DRT.Build
import NL2Proof.DRT.Types
import NL2Proof.Syntax.Tokenize
import NL2Proof.Syntax.Lexicon
import NL2Proof.Stage2.SDRT
import NL2Proof.Stage2.Threading
import NL2Proof.Trace

--------------------------------------------------------------------------------
-- Fixtures
--------------------------------------------------------------------------------

pv :: Prov
pv = ProvLex (SourceId "stage2") (Span 0 1) "x"

caseTerm :: String -> Term
caseTerm i = case caseById i >>= headOf . caseForms of
  Just t  -> t
  Nothing -> error ("no such case: " ++ i)
  where
    headOf (x : _) = Just x
    headOf []      = Nothing

near :: Double -> Double -> Bool
near a b = abs (a - b) < 1e-9

--------------------------------------------------------------------------------
-- 1. Distributions
--------------------------------------------------------------------------------

distChecks :: [Check]
distChecks =
  [ expect "dist: fromWeights normalizes"
      (maybe False isNormalized (fromWeights [('a', 3), ('b', 1)]))
  , expectEq "dist: weights become proportions"
      (Just 0.75) (fmap (`prob` 'a') (fromWeights [('a', 3), ('b', 1)]))
  , expectEq "dist: duplicate keys merge" (Just 1)
      (fmap (length . toPairs) (fromWeights [('a', 1), ('a', 1)]))
  , expectEq "dist: non-positive weights dropped" (Just ['a'])
      (fmap support (fromWeights [('a', 1), ('b', 0), ('c', -1)]))
  , expectEq "dist: all-zero weights give Nothing" Nothing
      (fmap support (fromWeights [('a', 0)]))
  , expectEq "dist: empty gives Nothing" Nothing
      (fmap support (fromWeights ([] :: [(Char, Double)])))
  , expect "dist: NaN weights dropped"
      (fmap support (fromWeights [('a', 1), ('b', 0 / 0)]) == Just ['a'])
  , expectEq "dist: insertion order preserved" (Just "ba")
      (fmap support (fromWeights [('b', 1), ('a', 1)]))
  , expect "dist: uniform entropy is log2 n"
      (maybe False (near 2 . entropy) (uniform "abcd"))
  , expect "dist: point mass has zero entropy" (near 0 (entropy (certain 'a')))
  , expectEq "dist: argmax picks the largest" (Just 'b')
      (fromWeights [('a', 1), ('b', 5)] >>= argmax)
  , expectEq "dist: argmax ties break to the earlier candidate" (Just 'a')
      (fromWeights [('a', 1), ('b', 1)] >>= argmax)
  , expectEq "dist: mapDist sums colliding mass" (Just 1.0)
      (fmap (\d -> prob (mapDist (const ()) d) ()) (fromWeights [('a', 1), ('b', 1)]))
  , expect "dist: filterDist renormalizes"
      (maybe False isNormalized (fromWeights [('a', 1), ('b', 1)] >>= filterDist (== 'a')))
  , expectEq "dist: filtering everything out gives Nothing" Nothing
      (fmap support (fromWeights [('a', 1)] >>= filterDist (const False)))
  , expect "dist: reweight is a Bayesian update"
      (maybe False (near 0.5 . (`prob` 'a'))
        (fromWeights [('a', 1), ('b', 2)] >>= reweight (\c -> if c == 'a' then 2 else 1)))
  , expectEq "dist: marginalize sums a subset" (Just 1.0)
      (fmap (marginalize (const True)) (fromWeights [('a', 1), ('b', 1)]))
  , -- alpha = 0 must flatten the softmax completely, since exp(0 * x) = 1.
    expect "dist: softmax at alpha=0 is uniform"
      (maybe False (near 0.5 . (`prob` 'a')) (softmax 0 [('a', 100), ('b', 1)]))
  , expect "dist: softmax at high alpha concentrates"
      (maybe False ((> 0.99) . (`prob` 'a')) (softmax 10 [('a', 5), ('b', 1)]))
  , expect "dist: softmax survives large scores without overflowing"
      (maybe False isNormalized (softmax 1 [('a', 10000), ('b', 9999)]))
  ]

--------------------------------------------------------------------------------
-- 2. Scope alternatives
--------------------------------------------------------------------------------

scopeChecks :: [Check]
scopeChecks =
  [ expectEq "alt: quantified sentence yields both scopings" 2
      (length (scopeAlternatives (caseTerm "quantified")))
  , expect "alt: the surface reading comes first"
      (case scopeAlternatives (caseTerm "quantified") of
         (t : _) -> alphaEq t (caseTerm "quantified")
         []      -> False)
  , expectEq "alt: the two scopings differ in prefix, not content"
      ["forall x exists y", "exists y forall x"]
      (map scopeSignature (scopeAlternatives (caseTerm "quantified")))
  , -- A quantifier trapped in a relative clause restrictor must not be lifted:
    -- doing so would change what the universal quantifies over.
    expectEq "alt: relative-clause quantifier is not lifted" 1
      (length (scopeAlternatives (caseTerm "relative-clause")))
  , expectEq "alt: nothing is re-scoped across negation" 1
      (length (scopeAlternatives (caseTerm "negative-quantifier")))
  , expectEq "alt: a single quantifier yields one reading, not n!" 1
      (length (scopeAlternatives (caseTerm "anaphora")))
  , expectEq "alt: a quantifier-free term yields itself" 1
      (length (scopeAlternatives (caseTerm "transitive")))
  , expect "alt: every generated reading is closed"
      (all (null . freeVars) (scopeAlternatives (caseTerm "quantified")))
  , expect "alt: every generated reading is well-typed"
      (all wellTyped (scopeAlternatives (caseTerm "quantified")))
  , expect "alt: unscope and relinearize round-trip"
      (let t = caseTerm "quantified"
           s = unscope t
       in alphaEq (relinearize (scopeQuants s) (scopeCore s)) t)
  , -- The dependency constraint is the reason permutation is safe at all.
    expect "alt: validOrder rejects a restrictor depending on a later binder"
      (not (validOrder
              [ Quant QExists "y" (App (pred2 "owns") (Var "x") `App` Var "y")
              , Quant QForall "x" (App (pred1 "person") (Var "x"))
              ]))
  , expect "alt: validOrder accepts the same pair in dependency order"
      (validOrder
         [ Quant QForall "x" (App (pred1 "person") (Var "x"))
         , Quant QExists "y" (App (pred2 "owns") (Var "x") `App` Var "y")
         ])
  ]

--------------------------------------------------------------------------------
-- 3. Modifier classes
--------------------------------------------------------------------------------

-- | The stratification exists because treating all modifiers alike
-- over-generates. These checks pin the behavioural consequences of each class,
-- not just the class labels.
modifierChecks :: [Check]
modifierChecks =
  [ expectEq "mod: chinese is classificatory" Classificatory (classifyModifier "chinese")
  , expectEq "mod: red is intersective" Intersective (classifyModifier "red")
  , expectEq "mod: unknown words default to intersective, as Stage 1 assumes"
      Intersective (classifyModifier "wibbly")
  , expect "mod: only classificatory modifiers may fuse with a head"
      (all (\c -> mayFuseWithHead c == (c == Classificatory)) [minBound .. maxBound])
  , expect "mod: privative modifiers do not preserve head truth"
      (not (preservesHeadTruth Privative))
  , expect "mod: every other class preserves head truth"
      (all preservesHeadTruth [Intersective, Classificatory, Subsective])
  , expect "mod: only intersective modifiers reorder freely"
      (all (\c -> reorderable c == (c == Intersective)) [minBound .. maxBound])
  , -- Layers must be ordered, or "resolvable at a lower layer" means nothing.
    expect "mod: intersective is the easiest layer"
      (all (\c -> modifierLayer Intersective <= modifierLayer c) [minBound .. maxBound])
  , expect "mod: privative and subsective need the hardest layer"
      (modifierLayer Privative == 3 && modifierLayer Subsective == 3)
  , expect "mod: classificatory sits strictly between the two"
      (modifierLayer Intersective < modifierLayer Classificatory
         && modifierLayer Classificatory < modifierLayer Privative)
  , expect "mod: every class has a description"
      (all (not . null . classDescription) [minBound .. maxBound])
  , expect "mod: genuinely ambiguous modifiers are recorded, not silently decided"
      (not (null ambiguousModifiers)
         && all (\(w, why) -> M.member w fragmentModifierClasses && not (null why))
                ambiguousModifiers)
  ]

--------------------------------------------------------------------------------
-- 4. Coupling alternatives
--------------------------------------------------------------------------------

-- | The space is built, then narrowed. These assert both halves: every fusion is
-- generated, and the licensing evidence needed to narrow them is attached rather
-- than applied.
couplingChecks :: [Check]
couplingChecks =
  [ expectEq "coupling: surface plus one candidate per modifier, none suppressed"
      4 (length cands)
  , expect "coupling: the surface reading comes first and is unfused"
      (case cands of
         (c : _) -> alphaEq (ccTerm c) (caseTerm "coupling")
                      && ccModifier c == Nothing && ccLayer c == 0
         []      -> False)
  , expect "coupling: chinese_dragon is generated"
      (any (\t -> "chinese_dragon" `elem` constNames t) couplings)
  , -- No preemptive pruning: implausible fusions are generated too, so they can
    -- be down-weighted explicitly rather than silently never existing.
    expect "coupling: implausible fusions ARE generated, not suppressed"
      (all (\q -> any (\t -> q `elem` constNames t) couplings)
           ["ancient_dragon", "red_dragon"])
  , expect "coupling: exactly one candidate is licensed by its modifier class"
      (length [c | c <- cands, ccModifier c /= Nothing, ccLicensed c] == 1)
  , expect "coupling: and it is the classificatory one"
      (case [c | c <- cands, ccModifier c /= Nothing, ccLicensed c] of
         [c] -> ccModifier c == Just "chinese" && ccClass c == Just Classificatory
         _   -> False)
  , expect "coupling: unlicensed candidates still carry their class as evidence"
      (all (\c -> ccClass c == Just Intersective && not (ccLicensed c))
           [c | c <- cands, ccModifier c `elem` [Just "ancient", Just "red"]])
  , expect "coupling: every fused candidate records its head"
      (all (\c -> ccHead c == Just "dragon") [c | c <- cands, ccModifier c /= Nothing])
  , expect "coupling: the licensed candidate sits at layer 2"
      (all (\c -> ccLayer c == 2)
           [c | c <- cands, ccLicensed c, ccModifier c /= Nothing])
  , expect "coupling: the fused reading drops the separate conjunct"
      (case filter (\t -> "chinese_dragon" `elem` constNames t) couplings of
         (t : _) -> "chinese" `notElem` constNames t
         []      -> False)
  , expect "coupling: all candidates stay closed and well-typed"
      (all (\t -> null (freeVars t) && wellTyped t) couplings)
  , expectEq "coupling: a sentence with no modifier stack yields itself" 1
      (length (couplingAlternatives (const True) (caseTerm "transitive")))
  ]
  where
    cands = couplingCandidates (const True) (caseTerm "coupling")
    couplings = couplingAlternatives (const True) (caseTerm "coupling")

--------------------------------------------------------------------------------
-- 5. Fingerprints
--------------------------------------------------------------------------------

-- | The discriminating property: two scope readings agree completely on content
-- and disagree on structure. A bag-of-predicates comparison cannot see the
-- difference; splitting the fingerprint in half can.
fingerprintChecks :: [Check]
fingerprintChecks =
  [ expect "fp: a fingerprint is identical to itself"
      (near 1 (similarity fpA fpA))
  , expect "fp: similarity is symmetric"
      (near (similarity fpA fpB) (similarity fpB fpA))
  , expect "fp: similarity stays within [0,1]"
      (all (\(x, y) -> let s = similarity x y in s >= 0 && s <= 1)
           [(x, y) | x <- allPrints, y <- allPrints])
  , expect "fp: scope readings have IDENTICAL content"
      (near 1 (contentSimilarity fpA fpB))
  , expect "fp: scope readings have DIFFERENT structure"
      (structuralSimilarity fpA fpB < 1)
  , expect "fp: so overall similarity is high but not 1"
      (let s = similarity fpA fpB in s > 0.7 && s < 1)
  , -- Coupling is the mirror image, and the reason both halves are needed.
    expect "fp: coupling readings differ in CONTENT, where RSA cannot help"
      (contentSimilarity fpCoup0 fpCoup1 < 1)
  , expect "fp: unrelated sentences score below related ones"
      (similarity fpA fpUnrelated < similarity fpA fpB)
  , expectEq "fp: quantifier prefix is recorded in order"
      ["forall", "exists"] (fpQuantifiers fpA)
  , expectEq "fp: the inverse reading records the reversed prefix"
      ["exists", "forall"] (fpQuantifiers fpB)
  , expect "fp: predicate counts are captured"
      (M.lookup "student" (fpPredicates fpA) == Just 1)
  , expect "fp: variable sharing is detected"
      (fpSharing fpA > 0)
  , expect "fp: rendering is non-empty"
      (not (null (renderFingerprint fpA)))
  ]
  where
    readingsQ = scopeAlternatives (caseTerm "quantified")
    fpA = fingerprint (head' readingsQ)
    fpB = fingerprint (readingsQ !! 1)
    coup = couplingAlternatives (const True) (caseTerm "coupling")
    fpCoup0 = fingerprint (head' coup)
    fpCoup1 = fingerprint (coup !! 1)
    fpUnrelated = fingerprint (caseTerm "intransitive")
    allPrints = [fpA, fpB, fpCoup0, fpCoup1, fpUnrelated]
    head' (x : _) = x
    head' []      = error "empty readings"

--------------------------------------------------------------------------------
-- 6. RSA against a known published result
--------------------------------------------------------------------------------

-- | The classic two-object reference game.
--
-- Two referents: @r1@ has only a hat; @r2@ has a hat /and/ glasses. Two words:
-- @"hat"@ is true of both, @"glasses"@ only of @r2@. Uniform prior, no costs.
--
-- The literal listener hearing @"hat"@ is undecided (both referents have hats).
-- The pragmatic listener infers @r1@: a speaker meaning @r2@ would have said
-- @"glasses"@, because that word is unambiguous. This implicature is the standard
-- worked example in the RSA literature, which makes it the right thing to pin the
-- recursion against.
referenceGameChecks :: [Check]
referenceGameChecks =
  [ expect "rsa: literal listener hearing 'hat' is undecided"
      (maybe False (near 0.5 . (`prob` "r1")) (literalListener game "hat"))
  , expect "rsa: literal listener hearing 'glasses' is certain"
      (maybe False (near 1 . (`prob` "r2")) (literalListener game "glasses"))
  , -- The implicature. This is the check the rest of the stage leans on.
    expect "rsa: pragmatic listener hearing 'hat' infers the hat-only referent"
      (maybe False ((> 0.6) . (`prob` "r1")) (pragmaticListener 1 game "hat"))
  , expect "rsa: and that is a strict improvement over the literal listener"
      (case (literalListener game "hat", pragmaticListener 1 game "hat") of
         (Just l0, Just l1) -> prob l1 "r1" > prob l0 "r1"
         _                  -> False)
  , expect "rsa: the pragmatic layer reduces entropy here"
      (maybe False (> 0) (sharpening 1 game "hat"))
  , expect "rsa: speaker meaning r2 prefers the unambiguous word"
      (case speaker 1 game "r2" of
         Just d  -> prob d "glasses" > prob d "hat"
         Nothing -> False)
  , expect "rsa: all listener distributions are normalized"
      (all (maybe False isNormalized)
           [ literalListener game "hat", literalListener game "glasses"
           , pragmaticListener 1 game "hat", pragmaticListener 2 game "hat" ])
  , expect "rsa: an utterance compatible with nothing gives Nothing"
      (literalListener game "umbrella" == Nothing)
  , expect "rsa: depth 0 is exactly the literal listener"
      (pragmaticListener 0 game "hat" == literalListener game "hat")
  , expect "rsa: alpha=0 makes the speaker indifferent"
      (case speaker 1 game { rsaAlpha = 0 } "r2" of
         Just d  -> near (prob d "hat") (prob d "glasses")
         Nothing -> False)
  ]
  where
    game =
      RSAModel
        { rsaUtterances = ["hat", "glasses", "umbrella"]
        , rsaMeanings = ["r1", "r2"]
        , rsaLexicon = \u m -> case (u, m) of
            ("hat", _)          -> 1
            ("glasses", "r2")   -> 1
            _                   -> 0
        , rsaPrior = uniformPrior
        , rsaCost = noCost
        , rsaAlpha = 1
        }

--------------------------------------------------------------------------------
-- 7. RSA on scope: the measured finding
--------------------------------------------------------------------------------

-- | RSA cannot break a symmetry the prior does not already break.
--
-- Asserted rather than described, because the Pipeline
-- documentation claimed the sharpening was zero across the board and a bias sweep
-- disproved it. These checks are what stop that claim drifting again.
scopeRankingChecks :: [Check]
scopeRankingChecks =
  [ expect "scope: a uniform prior yields exactly zero sharpening"
      (maybe False (near 0) (sharpening 1 (scopeModel 1.0) Nothing))
  , expect "scope: a biased prior yields positive sharpening"
      (maybe False (> 0) (sharpening 1 (scopeModel 2.0) Nothing))
  , expect "scope: sharpening grows with the bias"
      (case (sharpening 1 (scopeModel 1.5) Nothing, sharpening 1 (scopeModel 4.0) Nothing) of
         (Just a, Just b) -> b > a
         _                -> False)
  , expect "scope: the pragmatic layer amplifies the prior's preference"
      (case ( literalListener (scopeModel 2.0) Nothing
            , pragmaticListener 1 (scopeModel 2.0) Nothing ) of
         (Just l0, Just l1) -> prob l1 0 > prob l0 0 && prob l0 0 > 0.5
         _                  -> False)
  , expect "scope: with a uniform prior the surface reading gets no edge"
      (maybe False (near 0.5 . (`prob` 0)) (literalListener (scopeModel 1.0) Nothing))
  ]
  where
    surface = caseTerm "quantified"
    cands = scopeAlternatives surface
    idx = [0 .. length cands - 1]

    scopeModel bias =
      RSAModel
        { rsaUtterances = Nothing : map Just idx
        , rsaMeanings = idx
        , rsaLexicon = \u i -> case u of
            Nothing -> 1
            Just j  -> if i == j then 1 else 0
        , rsaPrior = \i -> surfaceScopePrior bias surface (cands !! i)
        , rsaCost = \u -> case u of
            Nothing -> 0
            Just _  -> 1
        , rsaAlpha = 1
        }

--------------------------------------------------------------------------------
-- 8. The Stage 2 pipeline
--------------------------------------------------------------------------------

pipelineChecks :: [Check]
pipelineChecks =
  concat
    [ [ expect (caseId c ++ ": stage 2 produces at least the surface reading")
          (any readingIsSurface (s2Readings (runStage2 pv t)))
      , expect (caseId c ++ ": every reading is closed and well-typed")
          (all (\r -> null (freeVars (readingTerm r)) && wellTyped (readingTerm r))
               (s2Readings (runStage2 pv t)))
      , expect (caseId c ++ ": listener distributions are normalized")
          (all (maybe True isNormalized)
               [s2Literal (runStage2 pv t), s2Pragmatic (runStage2 pv t)])
      ]
    | c <- fragmentCases
    , t <- take 1 (caseForms c)
    ]
    ++ [ expectEq "pipeline: quantified yields exactly 2 readings" 2
           (length (s2Readings (runStage2 pv (caseTerm "quantified"))))
       , expectEq "pipeline: coupling yields 4 readings, none pruned away" 4
           (length (s2Readings (runStage2 pv (caseTerm "coupling"))))
       , expectEq "pipeline: unambiguous sentences yield 1 reading" 1
           (length (s2Readings (runStage2 pv (caseTerm "transitive"))))
       , expect "pipeline: multiple readings raise ScopeAmbiguity"
           (ScopeAmbiguity
              `elem` map diagKind (traceDiagnostics (s2Trace (runStage2 pv (caseTerm "quantified")))))
       , expect "pipeline: a single reading raises nothing"
           (null (traceDiagnostics (s2Trace (runStage2 pv (caseTerm "transitive")))))
       , expect "pipeline: coupling sharpening is exactly zero, as the prior is symmetric"
           (maybe False (near 0) (s2Sharpening (runStage2 pv (caseTerm "coupling"))))
       , expect "pipeline: quantified sharpening is positive"
           (maybe False (> 0) (s2Sharpening (runStage2 pv (caseTerm "quantified"))))
       , expect "pipeline: the surface reading is favoured on the quantified case"
           (case s2Pragmatic (runStage2 pv (caseTerm "quantified")) of
              Just d  -> argmax d == Just 0
              Nothing -> False)
       , expect "pipeline: rendering is non-empty"
           (not (null (renderStage2Result (runStage2 pv (caseTerm "quantified")))))
       , expect "pipeline: Stage 1 output is never modified, only extended"
           (all (\c -> case take 1 (caseForms c) of
                   [t] -> case s2Readings (runStage2 pv t) of
                            (r : _) -> alphaEq (readingTerm r) t
                            []      -> False
                   _   -> True)
                fragmentCases)
       ]

--------------------------------------------------------------------------------
-- 9. Finite models: derived informativity and entailment
--------------------------------------------------------------------------------

-- | The fix for the improper RSA setup. Informativity is RSA's engine and it
-- needs semantics; these checks assert the asymmetry is *derived* rather than
-- stipulated.
modelChecks :: [Check]
modelChecks =
  [ expectEq "model: signature is read off the term"
      (Signature ["student", "book"] ["read"] []) sig
  , expectEq "model: enumeration matches the predicted count"
      (toInteger (length models)) (modelCount 2 sig)
  , expectEq "model: 256 models at domain size 2" 256 (length models)
  , expect "model: a tautology is true in every model"
      (length (truthSet models (TOr p (TNot p))) == length models)
  , expect "model: a contradiction is true in none"
      (null (truthSet models (TAnd p (TNot p))))
  , expect "model: a contradiction has no finite informativity"
      (informativity models (TAnd p (TNot p)) == Nothing)
  , expect "model: a tautology carries zero information"
      (maybe False (near 0) (informativity models (TOr p (TNot p))))
  , -- The derived asymmetry. This is the whole point of the module.
    expect "model: the inverse reading entails the surface reading"
      (entails models inverse surface)
  , expect "model: the surface reading does NOT entail the inverse"
      (not (entails models surface inverse))
  , expect "model: so the inverse reading is strictly stronger"
      (strictlyStronger models inverse surface)
  , expect "model: the stronger reading is true in strictly fewer models"
      (length (truthSet models inverse) < length (truthSet models surface))
  , expect "model: and is therefore strictly more informative"
      (case (informativity models surface, informativity models inverse) of
         (Just a, Just b) -> b > a
         _                -> False)
  , expect "model: a reading is equivalent to itself"
      (equivalent models surface surface)
  , expect "model: entailment is reflexive but not symmetric here"
      (entails models surface surface && not (equivalent models surface inverse))
  , -- Consequence of the entailment: the ambiguous form adds nothing over the
    -- weaker reading, so scope ambiguity of this shape is scalar strengthening
    -- rather than a choice between exclusive alternatives.
    expect "model: the ambiguous form is equivalent to the weaker reading"
      (equivalent models (TOr surface inverse) surface)
  ]
  where
    surface = caseTerm "quantified"
    inverse = case scopeAlternatives surface of
      (_ : x : _) -> x
      _           -> error "expected two scope readings"
    sig = signatureOf surface
    models = enumerateModels 2 sig
    -- Quantified, so it needs no constant: the signature derived from the
    -- reading has none, and a term mentioning an uninterpreted constant
    -- correctly evaluates to Nothing rather than to a truth value.
    p = TForall "z" TyE (App (pred1 "student") (Var "z"))

--------------------------------------------------------------------------------
-- 10. Order theory: chain vs antichain
--------------------------------------------------------------------------------

-- | Scope and coupling ambiguity are different order-theoretic situations, and
-- the difference decides how each can be ranked.
--
-- Measured over 524,288 models at domain size 2 for coupling and 256 for scope;
-- these checks use domain size 1 to stay fast, where the same relations hold.
orderChecks :: [Check]
orderChecks =
  [ -- Scope: a CHAIN. The stronger reading entails the weaker.
    expect "order: scope readings are comparable (a chain)"
      (let ms = modelsFor scopeRs
       in comparableIn ms (scopeRs !! 0) (scopeRs !! 1))
  , expect "order: and strictly so, in one direction only"
      (let ms = modelsFor scopeRs
       in strictlyStronger ms (scopeRs !! 1) (scopeRs !! 0))

  , -- Coupling: an ANTICHAIN. Every pair incomparable.
    expect "order: coupling readings are pairwise INCOMPARABLE (an antichain)"
      (let ms = modelsFor coupRs
       in and [ not (comparableIn ms (coupRs !! i) (coupRs !! j))
              | i <- idxC, j <- idxC, i < j ])

  , -- Incomparable is not the same as disjoint, and conflating them would
    -- mis-model the ranking problem.
    expect "order: but their truth sets OVERLAP, so it is not a partition"
      (let ms = modelsFor coupRs
           sizes = sum [length (truthSet ms r) | r <- coupRs]
           union = length [m | m <- ms, any (\r -> holds m r) coupRs]
       in sizes > union)

  , -- Informativity differs, which is what gives RSA something to exploit.
    expect "order: coupling readings differ in informativity"
      (let ms = modelsFor coupRs
           infos = [informativity ms r | r <- coupRs]
       in length (nubOn infos) > 1)
  , expect "order: the fully intersective reading is the most informative"
      (let ms = modelsFor coupRs
           n0 = length (truthSet ms (coupRs !! 0))
       in all (\i -> n0 <= length (truthSet ms (coupRs !! i))) idxC)
  ]
  where
    scopeRs = scopeAlternatives (caseTerm "quantified")
    coupRs = couplingAlternatives (const True) (caseTerm "coupling")
    idxC = [0 .. length coupRs - 1]

    modelsFor rs = enumerateModels 1 (signatureOf (foldr1 TAnd rs))
    holds m r = evalTerm m M.empty r == Just True
    comparableIn ms a b = entails ms a b || entails ms b a
    nubOn = foldr (\x acc -> if x `elem` acc then acc else x : acc) []

--------------------------------------------------------------------------------
-- 11. SDRT: relations, the right frontier, and accessibility
--------------------------------------------------------------------------------

-- | The point of SDRT is that relation choice changes what a later sentence can
-- refer to. These checks pin that down, and pin down the example that *cannot*
-- show it -- which is the trap worth having a regression for.
sdrtChecks :: [Check]
sdrtChecks =
  [ -- Inventory: the kind split is what drives everything else.
    expectEq "sdrt: four coordinating relations" 4
      (length [r | r <- allRelations, relationKind r == Coordinating])
  , expectEq "sdrt: four subordinating relations" 4
      (length [r | r <- allRelations, relationKind r == Subordinating])
  , expect "sdrt: every relation has a layer in 1..3"
      (all (\r -> relationLayer r >= 1 && relationLayer r <= 3) allRelations)
  , expect "sdrt: Narration is layer 1, cued from the surface"
      (relationLayer Narration == 1)
  , expect "sdrt: Explanation is layer 3, needs inference"
      (relationLayer Explanation == 3)
  , expect "sdrt: every relation glosses its own kind"
      (all (not . null . relationGloss) allRelations)

  , -- The right frontier.
    expectEq "sdrt: a subordinating relation leaves the parent open"
      [Label 2, Label 1] (rightFrontier (joined Elaboration))
  , expectEq "sdrt: a coordinating relation closes the parent"
      [Label 2] (rightFrontier (joined Narration))
  , expect "sdrt: isOpen agrees with the frontier"
      (isOpen (joined Elaboration) (Label 1)
         && not (isOpen (joined Narration) (Label 1)))

  , -- THE payoff: same two DRSs, different relation, different accessibility.
    expectEq "sdrt: under Elaboration the earlier referent stays accessible"
      [Ref "x"] (sdrsAccessible (joined Elaboration))
  , expectEq "sdrt: under Narration it does not"
      [] (sdrsAccessible (joined Narration))
  , expect "sdrt: so relation choice changes downstream anaphora"
      (sdrsAccessible (joined Elaboration) /= sdrsAccessible (joined Narration))

  , -- And the flat monoid cannot express the difference at all.
    expect "sdrt: mergeDRS is identical under both relations"
      (accessibleRefs (mergeDRS (duDRS k1) (duDRS k2))
         == accessibleRefs (mergeDRS (duDRS k1) (duDRS k2)))
  , expect "sdrt: and it keeps the referent regardless, so it cannot discriminate"
      (accessibleRefs (mergeDRS (duDRS k1) (duDRS k2)) == [Ref "x"])

  , -- The trap. A universally quantified first unit has an EMPTY top-level
    -- universe, so it contributes nothing whether open or closed, and the two
    -- relations give identical results. Using it to demonstrate SDRT would make
    -- the layer look inert.
    expect "sdrt: a duplex-only first unit cannot discriminate the relations"
      (sdrsAccessible (joinedWith badK1 Elaboration)
         == sdrsAccessible (joinedWith badK1 Narration))
  , expectEq "sdrt: because its accessible set is empty either way"
      [] (sdrsAccessible (joinedWith badK1 Elaboration))
  , expect "sdrt: even though the frontier genuinely differs"
      (rightFrontier (joinedWith badK1 Elaboration)
         /= rightFrontier (joinedWith badK1 Narration))

  , -- Climbing: a coordinating edge is skipped but climbed THROUGH, so a
    -- subordinating ancestor above it stays open. Easy to get wrong by stopping
    -- at the first coordinating edge.
    expectEq "sdrt: climbs through a coordinating edge to a subordinating ancestor"
      [Label 3, Label 1] (rightFrontier threeChain)

  , -- Glue: builds the space, prunes nothing.
    expect "sdrt: glue assigns positive mass to every relation"
      (maybe False (\d -> length (support d) == length allRelations) (glue k1 k2))
  , expect "sdrt: glue is normalized"
      (maybe False isNormalized (glue k1 k2))
  , expect "sdrt: with no cues, Continuation is the least committal default"
      (maybe False (\d -> argmax d == Just Continuation) (glue k1 k2))
  , expectEq "sdrt: and no cues fire on that pair" [] (detectCues k1 k2)

  , -- Cues that do fire.
    expect "sdrt: generic-then-specific is detected"
      (GenericThenSpecific `elem` detectCues badK1 k2)
  , expect "sdrt: and it favours Instance"
      (maybe False (\d -> argmax d == Just Instance) (glue badK1 k2))
  , expect "sdrt: a shared predicate is detected"
      (any isShared (detectCues k1 sameVerb))
  , expect "sdrt: cue weights never reach zero, so nothing is pruned by a cue"
      (all (\c -> all (\r -> cueWeight c r > 0) allRelations)
           [GenericThenSpecific, NewReferent, SharedPredicate "p", Connective "then"])

  , -- The connective path exists but cannot fire yet, and that is a lexicon gap
    -- rather than an SDRT gap. Asserted so the gap is visible.
    expect "sdrt: a connective-led sentence still fails to parse (lexicon gap)"
      (null [d | Just d <- [drsOf "Then Mary smiles."]])
  , expect "sdrt: but the connective cue is defined and weighted"
      (cueWeight (Connective "then") Narration > cueWeight (Connective "then") Elaboration)
  ]
  where
    k1 = mkUnit 1 "A student arrived."
    k2 = mkUnit 2 "Mary smiles."
    badK1 = mkUnit 1 "Every student reads a book."
    -- Must actually share a predicate with k1, whose predicates are
    -- {student, arrive}. "Mary reads a book" shares none; "Susan arrived"
    -- shares `arrive`.
    sameVerb = mkUnit 3 "Susan arrived."

    joined rel = joinedWith k1 rel
    joinedWith a rel = attach rel (Label 1) k2 (addRoot a emptySDRS)

    -- K1 --Elaboration--> K2 --Narration--> K3
    threeChain =
      attach Narration (Label 2) (mkUnit 3 "Mary smiles.")
        (attach Elaboration (Label 1) k2 (addRoot k1 emptySDRS))

    isShared (SharedPredicate _) = True
    isShared _                   = False

mkUnit :: Int -> String -> DiscourseUnit
mkUnit i txt =
  DiscourseUnit (Label i) (dscDRS (prDiscourse (runFragment sdrtSrc txt))) (toks txt)
  where
    toks =
      concatMap
        ( map tokText
            . latRaw
            . sentenceLattice
                (inLexicon fragmentLexicon)
                (maxPhraseLength fragmentLexicon)
        )
        . splitSentences

-- | 'Nothing' when the text produced no conditions at all, i.e. nothing parsed.
drsOf :: String -> Maybe DRS
drsOf txt =
  let d = dscDRS (prDiscourse (runFragment sdrtSrc txt))
  in if null (drsConds d) then Nothing else Just d

sdrtSrc :: SourceId
sdrtSrc = SourceId "sdrt"

--------------------------------------------------------------------------------
-- 12. The SDRT tie-in: threading that actually consults the frontier
--------------------------------------------------------------------------------

-- | Section 11 checks that the frontier is computed correctly. These checks ask
-- whether anything /uses/ it, which is a different question: a correctly computed
-- frontier that nothing consults has no observable effect.
--
-- Two facts do most of the work:
--
-- * the fragment corpus __cannot__ show a divergence, because both of its
--   multi-sentence cases are two sentences long
-- * a three-sentence discourse __does__, and under 'Committed' the divergence is
--   a lost resolution rather than a different one
threadingChecks :: [Check]
threadingChecks =
  [ -- Structure. The threader builds the graph it claims to build.
    expectEq "threading: three segments become three units" 3
      (length (labelsInOrder (thSDRS threeCommitted)))
  , expectEq "threading: and two edges" 2
      (length (sdrsEdges (thSDRS threeCommitted)))
  , expect "threading: the first unit has no attachment site"
      (null (stFrontier (head (thSteps threeCommitted))))
  , expect "threading: and no relation"
      (stRelation (head (thSteps threeCommitted)) == Nothing)

  , -- The off-by-one. K2 attaches to K1, so K1's referent is offered to K2
    -- whatever relation is chosen at that step: accessibility flows from the
    -- left argument of a relation to its right one.
    expectEq "threading: unit 2 is offered the referent from unit 1"
      [Ref "x"] (map rkRef (stRanked (thSteps threeCommitted !! 1)))
  , expect "threading: at full mass, since no earlier edge exists to hedge over"
      (all ((== 1) . rkMass) (stRanked (thSteps threeCommitted !! 1)))

  , -- With no cues firing, glue defaults to Continuation, which is
    -- coordinating. So committed threading closes K1 and unit 3 gets nothing.
    expectEq "threading: with no cues the chosen relation is Continuation"
      (Just Continuation) (stRelation (thSteps threeCommitted !! 1))
  , expect "threading: which is coordinating"
      (relationKind Continuation == Coordinating)
  , expect "threading: so under Committed unit 3 is offered no antecedent"
      (null (stRanked (thSteps threeCommitted !! 2)))

  , -- Marginal keeps it, graded. Elaboration always retains positive mass, so
    -- the referent is never deleted -- only ranked below certainty.
    expectEq "threading: under Marginal unit 3 is still offered the referent"
      [Ref "x"] (map rkRef (stRanked (thSteps threeMarginal !! 2)))
  , expect "threading: but at less than full mass"
      (case stRanked (thSteps threeMarginal !! 2) of
         (r : _) -> rkMass r > 0 && rkMass r < 1
         []      -> False)
  , expect "threading: and the mass is exactly the subordinating mass"
      (case ( stRanked (thSteps threeMarginal !! 2)
            , stRelDist (thSteps threeMarginal !! 1) ) of
         ((r : _), Just d) ->
           abs ( rkMass r
                   - sum [ m | (rel, m) <- ranked d
                             , relationKind rel == Subordinating ] ) < 1e-9
         _ -> False)
  , expect "threading: licensed only by subordinating relations"
      (case stRanked (thSteps threeMarginal !! 2) of
         (r : _) -> not (null (rkLicensors r))
                      && all ((== Subordinating) . relationKind) (rkLicensors r)
         []      -> False)

  , -- The consequence for the pronoun, which is the whole point.
    expect "threading: flat threading resolves the third-sentence pronoun"
      (flatResolved threeSent)
  , expect "threading: Committed threading does not -- a strict loss"
      (not (sdrtResolved Committed threeSent))
  , expect "threading: Marginal threading does"
      (sdrtResolved Marginal threeSent)
  , expectEq "threading: so Committed diverges from flat on exactly one anaphor"
      1 (length (compareThreading Committed (segsOf threeSent)))
  , expectEq "threading: and the divergence is a loss, not a different choice"
      [Nothing] (map dvSDRT (compareThreading Committed (segsOf threeSent)))
  , expectEq "threading: while Marginal diverges nowhere"
      [] (compareThreading Marginal (segsOf threeSent))

  , -- Forcing a subordinating relation restores it even under Committed. This
    -- is the check that the loss above is about the stipulated cue weights and
    -- not about the frontier code being broken.
    expect "threading: a generic-then-specific cue picks a subordinating relation"
      (fmap relationKind (stRelation (thSteps genericLed !! 1))
         == Just Subordinating)
  , expect "threading: so Committed leaves the earlier unit open there"
      (stFrontier (thSteps genericLed !! 2) == [Label 2, Label 1])
  , expect "threading: and logs the attachment site it picked from the two"
      (any (\d -> decKind d == "sdrt-attachment")
           (traceDecisions (thTrace genericLed)))

  , -- The corpus. Both multi-sentence cases have two segments, so the only
    -- parent is always on the pre-attachment frontier and no relation choice can
    -- change anything. Neither policy may regress the existing suite.
    expectEq "threading: no divergence on any fragment case under Committed"
      [] (concat [ compareThreading Committed (segsOf (caseText c))
                 | c <- fragmentCases ])
  , expectEq "threading: nor under Marginal"
      [] (concat [ compareThreading Marginal (segsOf (caseText c))
                 | c <- fragmentCases ])
  , expect "threading: and that is because no case has three segments"
      (all (\c -> length (segsOf (caseText c)) <= 2) fragmentCases)
  , expect "threading: the anaphora case still resolves under both policies"
      (sdrtResolved Committed anaphoraCase && sdrtResolved Marginal anaphoraCase)
  , expect "threading: the blocked case still fails under both, as it should"
      (not (sdrtResolved Committed blockedCase)
         && not (sdrtResolved Marginal blockedCase))

  , -- Decisions are logged, with alternatives, per the tracing contract.
    expect "threading: relation choice is logged as a decision with alternatives"
      (case [ d | d <- traceDecisions (thTrace threeCommitted)
                , decKind d == "sdrt-relation" ] of
         (d : _) -> length (decAlternatives d) == length allRelations - 1
         []      -> False)
  , expect "threading: the anaphora decision names the frontier heuristic"
      (any (\d -> decKind d == "anaphora"
                    && "right frontier" `isInfixOf` decWhy d)
           (traceDecisions (thTrace threeMarginal)))
  , expect "threading: and the Marginal heuristic reports the mass it used"
      (any (\d -> decKind d == "anaphora" && "mass" `isInfixOf` decWhy d)
           (traceDecisions (thTrace threeMarginal)))
  , expect "threading: a closed frontier is diagnosed, not silently dropped"
      (any (\g -> diagKind g == UnresolvedAnaphor
                    && "coordinating" `isInfixOf` diagMsg g)
           (traceDiagnostics (thTrace threeCommitted)))

  , -- The flat merge of the threaded units is the flat discourse DRS, which is
    -- what makes the two comparable at all: the graph is additional structure,
    -- not a different DRS.
    expect "threading: Marginal threading reproduces the flat discourse conditions"
      (drsConds (threadedDRS threeMarginal)
         == drsConds (dscDRS (prDiscourse (runFragment thrSrc threeSent))))
  ]
  where
    threeSent = "A student arrived. Mary smiles. She reads a book."
    genericSent = "Every student reads a book. Mary smiles. She sleeps."
    anaphoraCase = "A student arrived. She smiles."
    blockedCase = "No student sleeps. She smiles."

    threeCommitted = threadDiscourse Committed (segsOf threeSent)
    threeMarginal = threadDiscourse Marginal (segsOf threeSent)
    genericLed = threadDiscourse Committed (segsOf genericSent)

-- | The segments of a text, as Stage 1 produces them.
segsOf :: String -> [Segment]
segsOf txt = segmentsOf thrSrc (runFragment thrSrc txt)

-- | Did flat threading give some anaphor an antecedent, with none left over?
flatResolved :: String -> Bool
flatResolved txt = resolvedIn (dscTrace (prDiscourse (runFragment thrSrc txt)))

-- | Same question under SDRT threading.
sdrtResolved :: Policy -> String -> Bool
sdrtResolved policy txt =
  resolvedIn (thTrace (threadDiscourse policy (segsOf txt)))

resolvedIn :: Trace -> Bool
resolvedIn tr =
  any (\d -> decKind d == "anaphora") (traceDecisions tr)
    && not (any (\g -> diagKind g == UnresolvedAnaphor) (traceDiagnostics tr))

thrSrc :: SourceId
thrSrc = SourceId "thread"

--------------------------------------------------------------------------------
-- 13. What kind of object is the frontier mass?
--------------------------------------------------------------------------------

-- | Section 12's graded frontier raises the question of what kind of measure the
-- mass is, since that decides how it may be combined with the RSA posterior.
-- These checks pin the answer, and the answer is that two things have to hold
-- before the question is even well posed.
--
-- First, the mass is indexed by 'Ref', so 'Ref' has to be discourse-unique —
-- otherwise the index conflates distinct individuals and any measure computed
-- over it is measuring a phantom. 'NL2Proof.DRT.Types.freshenAgainst' provides
-- that; @Spec.hs@ section 14 holds the soundness checks.
--
-- Second, with a correct index the focal family is __not__ nested, so the mass is
-- provably not a possibility distribution. The cheap nestedness test returns the
-- opposite answer under a colliding index, which is why the first condition is
-- not a technicality.
muChecks :: [Check]
muChecks =
  [ -- 1. Where the collision was. Segment-local DRSs still share names, which is
    -- correct -- each sentence is alpha-equivalent to itself -- and the merge is
    -- where disjointness has to be established.
    expectEq "mu: two same-shaped existentials are still locally both x"
      [Ref "x", Ref "x"]
      (map (head . accessibleRefs . segDRS) (take 2 (segsOf collide)))
  , expectEq "mu: but the merged universe now has two distinct referents"
      (2, 2)
      (let u = accessibleRefs (dscDRS (prDiscourse (runFragment thrSrc collide)))
       in (length (nub u), length u))
  , expect "mu: so the student is not the professor"
      (let d = dscDRS (prDiscourse (runFragment thrSrc collide))
           refOf p = [r | CPred q [DRef r] _ <- drsConds d, q == p]
       in refOf "student" /= refOf "professor")
  , expect "mu: and the anaphora decision does not offer a choice against itself"
      (all (\d -> decChoice d `notElem` decAlternatives d)
           [ d | d <- traceDecisions (prTrace (runFragment thrSrc collideAna))
               , decKind d == "anaphora" ])
  , expect "mu: SDRT threading freshens too, so units never share a referent"
      (let rs = concatMap (drsRefs . duDRS) (unitsInOrder (thSDRS collideThreaded))
       in length rs == length (nub rs))

  , -- 2. The payoff. With a correct index the focal family is NOT nested, so mu
    -- is not a possibility distribution and the t-norm route closes on the
    -- merits rather than being left open. Both indexings now agree, which is the
    -- concrete sense in which the fix made Ref honest.
    expect "mu: Ref-indexed focal sets are NOT nested"
      (not (nestedUnder refIndexed))
  , expect "mu: (Label, Ref)-indexed focal sets are NOT either"
      (not (nestedUnder pairIndexed))
  , expectEq "mu: and the two indexings now see the same focal family"
      (4, 4) (length (focalFamily refIndexed), length (focalFamily pairIndexed))
  , expect "mu: the crossing pair is two referents at different depths"
      (let sets = focalFamily pairIndexed
       in any (\(a, b) -> not (all (`elem` b) a) && not (all (`elem` a) b))
              [(a, b) | a <- sets, b <- sets])

  , -- 2b. And the sharpest consequence: consonance holds at ONE free edge as a
    -- theorem, because frontier(sub) = frontier(coord) + {parent} gives exactly
    -- two nested focal sets. It fails at TWO. The implementation runs at one free
    -- edge, so it sits in the only regime where the possibility reading is
    -- available -- and that regime is the truncation. The truncation and the
    -- possibility reading stand or fall together, and the truncation has to go.
    expect "mu: at one free edge the focal family is nested, always"
      (let s1 = focalAt collideFour 4 1 in length s1 == 2 && nestedSets s1)
  , expect "mu: at two free edges it is not"
      (let s2 = focalAt collideFour 4 2 in length s2 == 4 && not (nestedSets s2))
  , expect "mu: so mu is a possibility distribution only under the truncation"
      (nestedSets (focalAt collideFour 4 1)
         && not (nestedSets (focalAt collideFour 4 2)))

  , -- 2c. The two-valued deflation was itself an artefact of one free edge. With
    -- two, mu is genuinely graded across referents.
    expect "mu: two free edges give two distinct masses, not one"
      (case fullMarginalAt (thSDRS collideFourM) 4 of
         Just rs -> length (nub (map rkMass rs)) == 2
         Nothing -> False)
  , expect "mu: and the truncation deletes the deeper of the two candidates"
      (case (stRanked (thSteps collideFourM !! 3), fullMarginalAt (thSDRS collideFourM) 4) of
         (t, Just f) -> length t == 1 && length f == 2
         _           -> False)

  , -- 3. mu is two-valued at one free edge, so "graded ranking" oversells it.
    -- Every offered referent is either fully open (mass 1) or open only under a
    -- subordinating last edge (mass P(sub)). One global degree of freedom.
    expectEq "mu: at one free edge mu takes at most two distinct values" True
      (length (nub [rkMass r | st <- thSteps threeM, r <- stRanked st]) <= 2)
  , expect "mu: and the non-unit value is exactly the subordinating mass"
      (case [rkMass r | r <- stRanked (thSteps threeM !! 2)] of
         (v : _) -> abs (v - subMassAt threeM 1) < 1e-9
         []      -> False)

  , -- 4. The one-edge truncation is not a small perturbation: at four segments
    -- it DELETES a referent the full marginal keeps at ~0.488. So "Marginal
    -- deletes nothing" holds at one uncertain edge and fails past it.
    expect "mu: at 4 segments the truncation offers nothing for K4"
      (null (stRanked (thSteps fourM !! 3)))
  , expect "mu: while the full marginal keeps the referent"
      (case fullMarginalAt (thSDRS fourM) 4 of
         Just (r : _) -> rkRef r == Ref "x" && rkMass r > 0.4
         _            -> False)
  , expect "mu: so the truncation can delete, which is what Marginal was for"
      (null (stRanked (thSteps fourM !! 3))
         && maybe False (not . null) (fullMarginalAt (thSDRS fourM) 4))
  , expect "mu: at 3 segments truncated and full agree exactly"
      (case (stRanked (thSteps threeM !! 2), fullMarginalAt (thSDRS threeM) 3) of
         ((a : _), Just (b : _)) -> abs (rkMass a - rkMass b) < 1e-9
         _                       -> False)
  , expect "mu: multiset multiplicity is unobservable at one free edge"
      (all ((<= 1) . length) [rkLicensors r | r <- stRanked (thSteps threeM !! 2)]
         || all (\r -> length (rkLicensors r) == length (nub (rkLicensors r)))
                (stRanked (thSteps threeM !! 2)))
  , expect "mu: fullMarginalAt refuses rather than blowing up on long discourses"
      (fullMarginalAt (thSDRS threeM) 9 == Nothing)

  , -- 5. There is no joint space for mu and the RSA posterior to live in, which
    -- is upstream of every question about combination rules. mu is indexed by
    -- Ref; readings are indexed by an Int over scope permutations and couplings.
    expect "mu: readings are indexed by Int, not by Ref"
      (all (>= 0) (map readingIndex (s2Readings (runStage2 pv (caseTerm "quantified")))))
  , expect "mu: and no reading's constants name a discourse referent"
      (null [ ()
            | rd <- s2Readings (runStage2 pv (caseTerm "quantified"))
            , v <- constNames (readingTerm rd)
            , v `elem` map show (concatMap (map rkRef . stRanked) (thSteps threeM))
            ])
  ]
  where
    collide = "A student arrived. A professor walks."
    collideAna = "A student arrived. A professor walks. She smiles."
    threeSent = "A student arrived. Mary smiles. She reads a book."
    fourSent = "A student arrived. Mary smiles. John sleeps. She reads a book."

    threeM = threadDiscourse Marginal (segsOf threeSent)
    fourM = threadDiscourse Marginal (segsOf fourSent)
    collideThreaded = threadDiscourse Marginal (segsOf collideThree)
    collideFour = "A student arrived. A professor walks. Mary smiles. She reads a book."
    collideFourM = threadDiscourse Marginal (segsOf collideFour)

    -- The focal family for unit @k@ with @m@ trailing edges free, on the
    -- committed topology. Same construction 'fullMarginalAt' marginalises over.
    focalAt txt k m =
      let s0 = thSDRS (threadDiscourse Committed (segsOf txt))
          units = unitsInOrder s0
          parents = [p | (_, p, _) <- sdrsEdges s0]
          committed = [r | (r, _, _) <- sdrsEdges s0]
          nEdges = k - 2
          freeIx = [nEdges - m .. nEdges - 1]
          labelsFor rho =
            [ maybe (committed !! i) id (lookup i (zip freeIx rho))
            | i <- [0 .. length committed - 1]
            ]
          built rho =
            foldl (\acc (rel, p, u) -> attach rel p u acc)
              (addRoot (head units) emptySDRS)
              (zip3 (labelsFor rho) (take nEdges parents) (take nEdges (drop 1 units)))
      in nub [ sort (accessibleOn (built rho) (rightFrontier (built rho)))
             | rho <- sequence (replicate m allRelations)
             ]

    nestedSets sets =
      and [all (`elem` b) a || all (`elem` a) b | a <- sets, b <- sets]

    -- The focal family {acc(S[rho])} over both edges of the colliding text,
    -- under the two candidate index sets.
    refIndexed = False
    pairIndexed = True

    focalFamily byPair =
      nub [ accOf byPair [a, b] | a <- allRelations, b <- allRelations ]

    nestedUnder byPair =
      let sets = focalFamily byPair
      in and [all (`elem` y) x || all (`elem` x) y | x <- sets, y <- sets]

    accOf byPair labels =
      let th = threadDiscourse Committed (segsOf collideThree)
          s0 = thSDRS th
          units = unitsInOrder s0
          parents = [p | (_, p, _) <- sdrsEdges s0]
          built =
            foldl (\acc (rel, p, u) -> attach rel p u acc)
              (addRoot (head units) emptySDRS)
              (zip3 labels (take 2 parents) (take 2 (drop 1 units)))
          fr = rightFrontier built
      in sort
           (nub   -- accessibleOn nubs, so Ref-indexing must too
              [ if byPair then show l ++ ":" ++ show r else show r
              | l <- fr
              , Just u <- [unitAt built l]
              , r <- accessibleRefs (duDRS u)
              ])

    collideThree = "A student arrived. A professor walks. Mary smiles."

    subMassAt th i =
      case stRelDist (thSteps th !! i) of
        Just d  -> sum [m | (r, m) <- ranked d, relationKind r == Subordinating]
        Nothing -> 0

--------------------------------------------------------------------------------
-- Main
--------------------------------------------------------------------------------

main :: IO ()
main =
  runChecks
    "stage 2 augmentation"
    (concat
       [ distChecks
       , scopeChecks
       , modifierChecks
       , couplingChecks
       , fingerprintChecks
       , referenceGameChecks
       , scopeRankingChecks
       , pipelineChecks
       , modelChecks
       , orderChecks
       , sdrtChecks
       , threadingChecks
       , muChecks
       ])
