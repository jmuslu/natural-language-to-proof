-- | Demo: run the fragment's evaluation set through the discrete core, then run
-- one case all the way through verification, fusion and scoring.
--
-- The oracle here is a whitelist. It settles nothing about the world and exists
-- only to show that the seams line up — a real oracle is a physics engine, a
-- backtesting engine, or something else whose answers do not depend on this
-- pipeline. See ARCHITECTURE.md.
module Main (main) where

import qualified Data.Map as M

import NL2Proof.Collapse.Class
import NL2Proof.DRT.Build
import NL2Proof.DRT.Canonical
import NL2Proof.DRT.Types
import NL2Proof.Fragment
import NL2Proof.Fusion
import NL2Proof.Genealogy
import NL2Proof.Pipeline
import NL2Proof.Provenance
import NL2Proof.Reward
import NL2Proof.Semantics.Lambda
import NL2Proof.Syntax.Tokenize
import NL2Proof.Trace
import NL2Proof.Verify.Claims
import NL2Proof.Verify.Oracle

main :: IO ()
main = do
  putStrLn "natural-language-to-proof"
  putStrLn "stage 1: discrete semantic core"
  mapM_ demo fragmentCases
  substrate

demo :: FragmentCase -> IO ()
demo c = do
  putStrLn ""
  putStrLn (replicate 78 '=')
  putStrLn (caseId c ++ "  [" ++ caseKind c ++ "]")
  putStrLn (replicate 78 '-')
  putStrLn ("text: " ++ show (caseText c))
  putStrLn ""

  let res = runFragment (SourceId "demo") (caseText c)

  mapM_ showSentence (prSentences res)

  putStrLn "discourse DRS (after anaphora resolution):"
  putStr (unlines (map ("  " ++) (drsBoxLines (dscDRS (prDiscourse res)))))

  case prSelection res of
    Nothing -> putStrLn "selection: none (nothing parsed)"
    Just sel -> do
      putStrLn
        ( "selection: " ++ show (selectionCandidateCount sel)
            ++ " candidate(s), " ++ selRationale sel
        )
      putStrLn ("  sources: " ++ show (selectionSources sel))
      putStrLn ("  spans:   " ++ show (selectionSpans sel))

  putStrLn ""
  putStr (renderTrace (prTrace res))
  putStrLn ("note: " ++ caseNotes c)

showSentence :: SentenceResult -> IO ()
showSentence r = do
  putStrLn
    ( "  [" ++ show (sentSpan (srSentence r)) ++ "] words: "
        ++ unwords (map tokText (srTokens r))
    )
  case [tokText u | u <- M.elems (latUnits (srLattice r)), ' ' `elem` tokText u] of
    []    -> pure ()
    multi -> putStrLn ("      multi-word units: " ++ unwords (map show multi))
  putStrLn ("      derivations: " ++ show (length (srParses r)))
  case srForm r of
    Nothing -> putStrLn "      form: <none>"
    Just f  -> putStrLn ("      form: " ++ pretty f)
  case srDRS r of
    Nothing -> pure ()
    Just d ->
      putStrLn
        ( "      conditions: " ++ show (length (drsConds d))
            ++ ", referents: " ++ show (length (drsUniverse d))
        )
  -- One condition's full how-provenance, to show what is being carried.
  case srDRS r >>= firstCondProv of
    Nothing -> pure ()
    Just p  -> putStrLn ("      provenance of first condition: " ++ renderProvInline p)
  where
    firstCondProv d = case drsConditionProvs d of
      (p : _) -> Just p
      []      -> Nothing

--------------------------------------------------------------------------------
-- Stages 2 to 4, on one case
--------------------------------------------------------------------------------

-- | Covers unary predicates and confirms a fixed whitelist. Plumbing, not
-- physics: it demonstrates the interface, and every number below is a fact about
-- this whitelist rather than about the world.
demoOracle :: Oracle
demoOracle =
  Oracle
    { oracleName = "whitelist"
    , oracleDomain = "unary predicates drawn from a fixed list"
    , oracleCovers = \c -> case c of
        CanPred _ [_] -> True
        _             -> False
    , oracleHolds = \c -> case c of
        CanPred n _ -> n `elem` ["student", "book", "arrive", "smile"]
        _           -> False
    }

substrate :: IO ()
substrate = do
  putStrLn ""
  putStrLn (replicate 78 '=')
  putStrLn "stages 2-4: verification, fusion, reward"
  putStrLn (replicate 78 '=')
  case [c | c <- fragmentCases, caseId c == "anaphora"] of
    [] -> putStrLn "  (no anaphora case found)"
    (c : _) -> do
      putStrLn ("text: " ++ show (caseText c))
      putStrLn ""
      case prSelection (runFragment src (caseText c)) of
        Nothing -> putStrLn "  nothing parsed, so nothing to verify"
        Just sel -> do
          let table = claimsOf sel
              claims = map factClaim (ctFacts table)
              g = genealogyOf demoOracle table
              fused = fuse (confirmAll demoOracle claims)

          putStrLn "-- stage 2: claims retained, then offered to the oracle"
          putStr (renderCoverage (coverage demoOracle claims))
          putStrLn ""
          putStr (renderGenealogy g)

          putStrLn ""
          putStrLn "-- stage 3: fusion, over confirmed claims only"
          putStr (renderFused fused)

          putStrLn ""
          putStrLn "-- stage 4: reward"
          putStr (renderReward (score fused g))
          putStr (renderAdmissibility (admissibility defaultWeights))

          putStrLn ""
          putStrLn "-- and the same text under an oracle that covers nothing"
          let blind = demoOracle { oracleName = "blind", oracleCovers = const False }
              gb = genealogyOf blind table
              fb = fuse (confirmAll blind claims)
          putStr (renderReward (score fb gb))
  where
    src = SourceId "demo"
