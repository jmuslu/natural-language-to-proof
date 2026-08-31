-- | Stage 2 test suite: probabilistic augmentation.
--
-- Kept separate from @Spec.hs@ on purpose. Stage 1 "is meant to stop changing",
-- so its 348 checks should stay a stable number that means the same thing over
-- time. Adding Stage 2 assertions to it would make that number drift and destroy
-- its value as a signal.
--
-- The load-bearing test here is 'referenceGameChecks'. RSA has a known published
-- result on the two-object reference game, so pinning the recursion against it
-- means every /other/ number this stage reports can be read as a fact about the
-- model setup rather than a possible bug in the implementation.
module Main (main) where

import qualified Data.Map.Strict as M

import Harness
import NL2Proof.Fragment
import NL2Proof.Provenance
import NL2Proof.Semantics.Lambda
import NL2Proof.Stage2.Alternatives
import NL2Proof.Stage2.Distribution
import NL2Proof.Stage2.Fingerprint
import NL2Proof.Stage2.Model
import NL2Proof.Stage2.Modifier
import NL2Proof.Stage2.Pipeline
import NL2Proof.Stage2.RSA
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
-- Asserted rather than described, because an earlier version of the Pipeline
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
       ])
