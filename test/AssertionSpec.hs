{-# LANGUAGE DataKinds #-}

-- | What the text asserts: only the top-level conditions of the main box.
--
-- A condition found under a negation, in either half of a conditional, in a
-- disjunct, in a universal's restrictor or nuclear scope, or under a negated
-- attitude is /mentioned/ by the text, not asserted by it. It must not enter
-- the claim table as a fact, because every fact becomes a genealogy premise
-- and an oracle may confirm it: @"The cat is not red"@ would otherwise yield a
-- grounded @red(cat)@ the text denies.
--
-- The rule is checked three ways: end to end on both front ends, structurally
-- over hand-built boxes of every subordinate kind (including those no
-- front end can yet produce, such as @either ... or@), and at the oracle
-- boundary (genealogy grounding, fusion, mechanical entailment) under an oracle
-- that confirms everything it is asked.
module Main (main) where

import qualified Data.Set as Set

import Harness
import NL2Proof.DRT.Build (Discourse(..))
import NL2Proof.DRT.Canonical
import NL2Proof.DRT.Types
import NL2Proof.Fusion
import NL2Proof.Genealogy
import NL2Proof.Pipeline
import NL2Proof.Provenance
import NL2Proof.Syntax.CCGBank (CCat, parseCCGCat)
import NL2Proof.Syntax.CCGParse (Rules(..))
import NL2Proof.Syntax.CCGSemParse
import NL2Proof.Syntax.CCGSupertag (buildPOSModel, buildTagModel)
import NL2Proof.Syntax.Lexicon (attitudeLexicon)
import NL2Proof.Verify.ClaimKind
import NL2Proof.Verify.Claims
import NL2Proof.Verify.Oracle
import NL2Proof.Verify.Reported

main :: IO ()
main = runChecks "assertion"
  (positiveChecks ++ endToEndChecks ++ handChecks ++ structuralChecks ++ invariantChecks
   ++ oracleChecks ++ embeddedChecks)

--------------------------------------------------------------------------------
-- Fixtures
--------------------------------------------------------------------------------

cc :: String -> CCat
cc s = either error id (parseCCGCat s)

-- | A miniature tag dictionary (no licensed data), as in the intensional suite.
mini :: SemModel
mini = (defaultSemModel tm pm rs Set.empty) { smAlpha = 0, smSeenRules = False }
  where
    obs =
      [ ("the", "NP[nb]/N"), ("All", "NP[nb]/N")
      , ("cat", "N"), ("dog", "N"), ("things", "N")
      , ("is", "(S[dcl]\\NP)/(S[adj]\\NP)"), ("are", "(S[dcl]\\NP)/(S[adj]\\NP)")
      , ("Is", "(S[q]/(S[adj]\\NP))/NP")
      , ("red", "S[adj]\\NP"), ("big", "S[adj]\\NP"), ("happy", "S[adj]\\NP")
      , ("red", "N/N")
      , ("not", "(S\\NP)\\(S\\NP)"), ("not", "(S[adj]\\NP)/(S[adj]\\NP)")
      , ("did", "(S[dcl]\\NP)/(S[b]\\NP)")
      , ("If", "(S/S)/S[dcl]"), ("then", "S/S"), ("something", "NP"), ("it", "NP")
      , ("and", "conj"), ("or", "conj")
      , ("that", "S[em]/S[dcl]")
      , ("say", "(S[b]\\NP)/S[em]"), ("said", "(S[dcl]\\NP)/S[em]")
      , ("Bob", "N"), (",", ","), (".", "."), ("?", ".")
      ]
    names = ["Bob"]
    tm = buildTagModel [ (w, cc c) | (w, c) <- obs ]
    pm = buildPOSModel [ (w, if w `elem` names then "NNP" else "XX") | (w, _) <- obs ]
    rs = Rules { rUnary = [(cc "N", cc "NP")], rBinTC = [] }

ccg :: ParserChoice
ccg = CCGBankParser mini

hand :: ParserChoice
hand = HandLexicon attitudeLexicon

drsOfText :: ParserChoice -> String -> DRS
drsOfText p t = dscDRS (prDiscourse (runPipelineWith p (SourceId "t") t))

tableOf :: ParserChoice -> String -> ClaimTable
tableOf p = claimsOfDRS "test" . drsOfText p

factClaims :: ClaimTable -> [CanonCond]
factClaims = map factClaim . ctFacts

reportedClaims :: ClaimTable -> [CanonCond]
reportedClaims = map reportedContent . ctReported

pc :: String -> [String] -> CanonCond
pc p as = CanPred p (map CConstT as)

pr :: String -> Int -> CanonCond
pr p i = CanPred p [CRefT (CRef i)]

box :: [CanonCond] -> Canonical
box = Canonical []

boxR :: [Int] -> [CanonCond] -> Canonical
boxR us = Canonical (map CRef us)

-- | The asserted facts of a text must be exactly @want@, and none of @never@.
assertsExactly :: ParserChoice -> String -> [CanonCond] -> [CanonCond] -> [Check]
assertsExactly p t want never =
  [ expectEq ("asserted claims of " ++ show t) want (factClaims ct)
  , expectEq ("...none of the embedded literals asserted: " ++ show t)
      [] (filter (`elem` factClaims ct) never)
  ]
  where ct = tableOf p t

--------------------------------------------------------------------------------
-- 1. Positive controls
--------------------------------------------------------------------------------

positiveChecks :: [Check]
positiveChecks =
  assertsExactly ccg "the cat is red." [pc "red" ["cat"]] []
  ++ assertsExactly ccg "the cat is red and the dog is big." [pc "red" ["cat"], pc "big" ["dog"]] []
  ++ [ expectEq "a top-level attitude is still asserted, and its content reported"
         ([CanAtt "say" [CConstT "Bob"] (box [pc "red" ["cat"]])], [pc "red" ["cat"]])
         (let ct = tableOf ccg "Bob said that the cat is red." in (factClaims ct, reportedClaims ct))
     ]

--------------------------------------------------------------------------------
-- 2. End to end (CCGbank path)
--------------------------------------------------------------------------------

redCat, bigDog, happyBob, sayRed :: CanonCond
redCat = pc "red" ["cat"]
bigDog = pc "big" ["dog"]
happyBob = pc "happy" ["Bob"]
sayRed = CanAtt "say" [CConstT "Bob"] (box [redCat])

endToEndChecks :: [Check]
endToEndChecks =
  assertsExactly ccg "the cat is not red." [CanNot (box [redCat])] [redCat]
  ++ assertsExactly ccg "Bob did not say that the cat is red." [CanNot (box [sayRed])] [sayRed, redCat]
  ++ [ expectEq "'Bob did not say that P': no reported P"
         [] (reportedClaims (tableOf ccg "Bob did not say that the cat is red.")) ]
  ++ assertsExactly ccg "If the cat is red then Bob is happy."
       [CanImp (box [redCat]) (box [happyBob])] [redCat, happyBob]
  ++ assertsExactly ccg "If the cat is red , Bob is happy."
       [CanImp (box [redCat]) (box [happyBob])] [redCat, happyBob]
  ++ assertsExactly ccg "If something is red then it is big."
       [CanImp (boxR [0] [pr "thing" 0, pr "red" 0]) (box [pr "big" 0])]
       [pr "thing" 0, pr "red" 0, pr "big" 0]
  ++ assertsExactly ccg "the cat is red or the dog is big."
       [CanOr (box [redCat]) (box [bigDog])] [redCat, bigDog]
  ++ assertsExactly ccg "All red things are big."
       [CanImp (boxR [0] [pr "red" 0, pr "thing" 0]) (box [pr "big" 0])]
       [pr "red" 0, pr "thing" 0, pr "big" 0]
  ++ assertsExactly ccg "If Bob said that the cat is red then the dog is big."
       [CanImp (box [sayRed]) (box [bigDog])] [sayRed, redCat, bigDog]
  ++ [ expectEq "a question asserts nothing (facts, reports, presuppositions)"
         ([], [], 0)
         (let ct = tableOf ccg "Is the cat red?"
          in (factClaims ct, reportedClaims ct, length (ctPresupposed ct)))
     ]

--------------------------------------------------------------------------------
-- 3. End to end (hand lexicon): 'no' and 'every'
--------------------------------------------------------------------------------

handChecks :: [Check]
handChecks =
  assertsExactly hand "No student sleeps."
    [CanNot (boxR [0] [pr "student" 0, pr "sleep" 0])] [pr "student" 0, pr "sleep" 0]
  ++ assertsExactly hand "Every student smiles."
       [CanImp (boxR [0] [pr "student" 0]) (box [pr "smile" 0])] [pr "student" 0, pr "smile" 0]
  ++ assertsExactly hand "John does not love Mary."
       [CanNot (box [pc "love" ["john", "mary"]])] [pc "love" ["john", "mary"]]
  ++ assertsExactly hand "John does not say that Mary smiles"
       [CanNot (box [CanAtt "say" [CConstT "john"] (box [pc "smile" ["mary"]])])]
       [CanAtt "say" [CConstT "john"] (box [pc "smile" ["mary"]]), pc "smile" ["mary"]]

--------------------------------------------------------------------------------
-- 4. Structural: hand-built boxes of every subordinate kind
--------------------------------------------------------------------------------

p0 :: Prov
p0 = ProvLex (SourceId "s") (Span 0 1) "x"

lit :: String -> [String] -> Condition
lit p as = CPred p (map DConst as) p0

litR :: String -> String -> Condition
litR p r = CPred p [DRef (Ref r)] p0

drs :: [Condition] -> DRS
drs = DRS []

drsU :: [String] -> [Condition] -> DRS
drsU us = DRS [ (Ref u, p0) | u <- us ]

structuralChecks :: [Check]
structuralChecks =
  [ expectEq "either ... or: one disjunction, neither disjunct"
      [CanOr (box [redCat]) (box [bigDog])]
      (structural (drs [COr (drs [lit "red" ["cat"]]) (drs [lit "big" ["dog"]]) p0]))
  , expectEq "no cat is red: ~[x | cat(x), red(x)], restrictor and scope not asserted"
      [CanNot (boxR [0] [pr "cat" 0, pr "red" 0])]
      (structural (drs [CNot (drsU ["x"] [litR "cat" "x", litR "red" "x"]) p0]))
  , expectEq "every red thing is big: one rule"
      [CanImp (boxR [0] [pr "red" 0, pr "thing" 0]) (box [pr "big" 0])]
      (structural (drs [CImp (drsU ["x"] [litR "red" "x", litR "thing" "x"]) (drs [litR "big" "x"]) p0]))
  , expectEq "double negation: ~~red(cat) stays whole (no positive red(cat))"
      [CanNot (box [CanNot (box [redCat])])]
      (structural (drs [CNot (drs [CNot (drs [lit "red" ["cat"]]) p0]) p0]))
  , expectEq "an attitude inside a disjunct: nothing reported, nothing asserted but the disjunction"
      ([CanOr (box [sayRed]) (box [bigDog])], [])
      (let ct = claimsOfDRS "s" (drs [COr (drs [CAtt "say" [DConst "Bob"] (drs [lit "red" ["cat"]]) p0])
                                           (drs [lit "big" ["dog"]]) p0])
       in (factClaims ct, reportedClaims ct))
  , expectEq "a presupposition box nested under negation is not asserted either"
      [CanNot (box [CanPresup (box [redCat])])]
      (structural (drs [CNot (drs [CPresup (drs [lit "red" ["cat"]]) p0]) p0]))
  , expectEq "top-level conditions are asserted in order, nested ones are not"
      [redCat, CanNot (box [bigDog]), happyBob]
      (structural (drs [lit "red" ["cat"], CNot (drs [lit "big" ["dog"]]) p0, lit "happy" ["Bob"]]))
  ]
  where structural = factClaims . claimsOfDRS "s"

--------------------------------------------------------------------------------
-- 5. The invariant: facts are exactly the top-level non-presupposition conditions
--------------------------------------------------------------------------------

corpus :: [(ParserChoice, String)]
corpus =
  [ (ccg, t) | t <-
      [ "the cat is red.", "the cat is red and the dog is big.", "the cat is not red."
      , "Bob did not say that the cat is red.", "If the cat is red then Bob is happy."
      , "If something is red then it is big.", "the cat is red or the dog is big."
      , "All red things are big.", "Bob said that the cat is not red."
      , "If Bob said that the cat is red then the dog is big."
      , "the cat is red. If the cat is red then Bob is happy." ] ]
  ++ [ (hand, t) | t <-
      [ "No student sleeps.", "Every student smiles.", "John does not love Mary."
      , "Every student who reads a book smiles.", "John does not say that Mary smiles"
      , "Mary knows that John smiles" ] ]

invariantChecks :: [Check]
invariantChecks =
  [ expectEq "facts == top-level conditions minus presuppositions, for every corpus text" []
      [ t | (p, t) <- corpus
          , let d = drsOfText p t
          , factClaims (claimsOfDRS "c" d) /= [ k | k <- canonConds (canonicalize d), not (isPresup k) ] ]
  , expect "the corpus is not vacuous: every text produced a DRS with conditions"
      (all (\(p, t) -> not (null (drsConds (drsOfText p t)))) corpus)
  ]
  where
    isPresup (CanPresup _) = True
    isPresup _             = False

--------------------------------------------------------------------------------
-- 6. The oracle boundary
--------------------------------------------------------------------------------

-- | Confirms anything it is asked about: the worst case for leakage.
credulous :: Oracle
credulous = Oracle "credulous" "everything" (const True) (const True)

-- | Every claim that could become Confirmed from a text: grounded genealogy
-- nodes, the fused base, and its mechanical closure.
reachable :: ClaimTable -> [CanonCond]
reachable ct =
  [ nodeClaim n | i <- Set.toList (grounded g), Just n <- [nodeAt g i] ]
    ++ fusedClaims base ++ entailedFrom base
  where
    g = genealogyOf credulous ct
    base = fuse (confirmAll credulous (factClaims ct))

oracleChecks :: [Check]
oracleChecks =
  [ expectEq ("nothing embedded reaches Confirmed, any path: " ++ show t) []
      (filter (`elem` reachable (tableOf p t)) never)
  | (p, t, never) <-
      [ (ccg, "the cat is not red.", [redCat])
      , (ccg, "Bob did not say that the cat is red.", [sayRed, redCat])
      , (ccg, "If the cat is red then Bob is happy.", [redCat, happyBob])
      , (ccg, "the cat is red or the dog is big.", [redCat, bigDog])
      , (ccg, "All red things are big.", [pr "red" 0, pr "thing" 0, pr "big" 0])
      , (ccg, "If something is red then it is big.", [pr "thing" 0, pr "red" 0, pr "big" 0])
      , (hand, "No student sleeps.", [pr "student" 0, pr "sleep" 0])
      , (hand, "John does not love Mary.", [pc "love" ["john", "mary"]])
      ]
  ]
  ++
  [ expect "control: the rule stays usable whole; with its antecedent asserted, entailment detaches it"
      (happyBob `elem` entailedFrom (fuse (confirmAll credulous
         (factClaims (tableOf ccg "the cat is red. If the cat is red then Bob is happy.")))))
  , expect "control: an asserted literal is reachable" (redCat `elem` reachable (tableOf ccg "the cat is red."))
  ]

--------------------------------------------------------------------------------
-- 7. Embedded claims: kept for inspection, indexed so they cannot be confirmed
--------------------------------------------------------------------------------

embeddedOf :: ParserChoice -> String -> [CanonCond]
embeddedOf p = map claimCond . ctEmbedded . tableOf p

embeddedChecks :: [Check]
embeddedChecks =
  [ expectEq "embedded: the cat is not red" [redCat] (embeddedOf ccg "the cat is not red.")
  , expectEq "embedded: both halves of a conditional" [redCat, happyBob]
      (embeddedOf ccg "If the cat is red then Bob is happy.")
  , expectEq "embedded: a negated attitude and its content" [sayRed, redCat]
      (embeddedOf ccg "Bob did not say that the cat is red.")
  , expectEq "embedded: none for plain assertions or a top-level report" [[], []]
      [embeddedOf ccg "the cat is red and the dog is big.", embeddedOf ccg "Bob said that the cat is red."]
  , expectEq "an embedded claim is a genealogy node only when also asserted at the top level" []
      [ t | (p, t) <- corpus, let d = drsOfText p t, let ct = claimsOfDRS "c" d
          , let g = genealogyOf credulous ct
          , let ns = [ nodeClaim n | i <- nodeIds g, Just n <- [nodeAt g i] ]
          , any (\e -> e `elem` ns && e `notElem` canonConds (canonicalize d)) (map claimCond (ctEmbedded ct)) ]
  , expect "...as in 'the cat is red. If the cat is red then Bob is happy.': red(cat) is both"
      (let ct = tableOf ccg "the cat is red. If the cat is red then Bob is happy."
       in redCat `elem` map claimCond (ctEmbedded ct) && redCat `elem` factClaims ct
          && happyBob `notElem` factClaims ct)
  , expect "the explicit route still exists: asCandidate, then an oracle"
      (map confClaim [ c | Just c <- map (confirm credulous . asCandidate) (ctEmbedded (tableOf ccg "the cat is not red.")) ]
         == [redCat])
  ]
