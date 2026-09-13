-- | Train/test measurement of the type-changing rule class
-- ('NL2Proof.Syntax.CCGTypeChange').
--
-- Induces the type-change inventory from TRAIN @.auto@ files and measures node
-- coverage on a HELD-OUT set of TEST @.auto@ files, so the number reported is
-- generalisation to unseen sentences, not memorisation of the training corpus.
-- Reports the three-way split (combinator / known-type-change / unexplained) and
-- the sentence-level full-reconstruction rate, under both exact and
-- feature-erased rule matching so the value of feature generalisation is visible.
--
-- Usage (a literal @--@ separates train files from test files; the shell expands
-- the globs):
--
-- >  ccg-typechange-coverage TRAIN.auto ... -- TEST.auto ...
module Main (main) where

import Data.List (foldl')
import qualified Data.Set as Set
import System.Environment (getArgs)
import System.IO (hPutStrLn, stderr)

import NL2Proof.Syntax.CCGBank (CCat, eraseFeatures)
import NL2Proof.Syntax.CCGDeriv (AutoNode, parseAuto)
import NL2Proof.Syntax.CCGTypeChange
  (TypeChange, normalizeTC, inducements, NodeClass(..), classifyTree)

type RuleSet = Set.Set TypeChange

parseTree :: String -> Maybe AutoNode
parseTree line
  | take 3 line == "ID=" = Nothing
  | all (`elem` " \t\r") line = Nothing
  | otherwise = either (const Nothing) Just (parseAuto line)

treesFromFiles :: [FilePath] -> IO [AutoNode]
treesFromFiles files = do
  chunks <- mapM (fmap (\s -> [t | Just t <- map parseTree (lines s)]) . readFile) files
  return (concat chunks)

-- Counts over classified nodes, plus sentence-level full reconstruction.
data Counts = Counts
  { cLeaf :: !Int, cComb :: !Int, cKnown :: !Int, cUnexpl :: !Int, cErr :: !Int
  , cSents :: !Int, cSentsFull :: !Int }

emptyCounts :: Counts
emptyCounts = Counts 0 0 0 0 0 0 0

tallyTree :: (CCat -> CCat) -> RuleSet -> Counts -> AutoNode -> Counts
tallyTree norm rules acc tree =
  let vs   = classifyTree norm rules tree
      full = all (\v -> v /= NCUnexplained && v /= NCParseErr) vs
      acc1 = acc { cSents = cSents acc + 1
                 , cSentsFull = cSentsFull acc + (if full then 1 else 0) }
  in foldl' bump acc1 vs
  where
    bump a NCLeaf            = a { cLeaf = cLeaf a + 1 }
    bump a NCCombinator      = a { cComb = cComb a + 1 }
    bump a NCTypeChangeKnown = a { cKnown = cKnown a + 1 }
    bump a NCUnexplained     = a { cUnexpl = cUnexpl a + 1 }
    bump a NCParseErr        = a { cErr = cErr a + 1 }

pct :: Int -> Int -> String
pct _ 0 = "n/a"
pct k tot =
  let tenths = round (1000 * fromIntegral k / fromIntegral tot :: Double) :: Int
  in show (fromIntegral tenths / 10 :: Double) ++ "%"

report :: String -> Counts -> IO ()
report label c = do
  let internal = cComb c + cKnown c + cUnexpl c + cErr c  -- non-leaf nodes
  putStrLn ("-- " ++ label ++ " --")
  putStrLn ("  internal nodes    : " ++ show internal)
  putStrLn ("  combinator        : " ++ show (cComb c) ++ " (" ++ pct (cComb c) internal ++ ")")
  putStrLn ("  type-change known : " ++ show (cKnown c) ++ " (" ++ pct (cKnown c) internal ++ ")")
  putStrLn ("  UNEXPLAINED       : " ++ show (cUnexpl c) ++ " (" ++ pct (cUnexpl c) internal ++ ")")
  putStrLn ("  parse errors      : " ++ show (cErr c))
  putStrLn ("  sentences         : " ++ show (cSents c))
  putStrLn ("  fully reconstructed (combinators + known type-changes): "
            ++ show (cSentsFull c) ++ " (" ++ pct (cSentsFull c) (cSents c) ++ ")")

main :: IO ()
main = do
  args <- getArgs
  let (trainFiles, testFiles) = case break (== "--") args of
        (tr, _ : te) -> (tr, te)
        (tr, [])     -> (tr, [])
  if null trainFiles || null testFiles
    then hPutStrLn stderr "usage: ccg-typechange-coverage TRAIN.auto ... -- TEST.auto ..."
    else do
      trainTrees <- treesFromFiles trainFiles
      let exactRules  = Set.fromList (map (normalizeTC id)            (concatMap inducements trainTrees))
          erasedRules = Set.fromList (map (normalizeTC eraseFeatures) (concatMap inducements trainTrees))
      hPutStrLn stderr ("trained on " ++ show (length trainTrees) ++ " sentences from "
                        ++ show (length trainFiles) ++ " files; "
                        ++ show (Set.size exactRules) ++ " exact / "
                        ++ show (Set.size erasedRules) ++ " feature-erased type-change rules")
      testTrees <- treesFromFiles testFiles
      let exactCounts  = foldl' (tallyTree id            exactRules)  emptyCounts testTrees
          erasedCounts = foldl' (tallyTree eraseFeatures erasedRules) emptyCounts testTrees
      putStrLn "== Type-change rule class: held-out (train/test) coverage =="
      putStrLn ("train files: " ++ show (length trainFiles)
                ++ "   test files: " ++ show (length testFiles))
      putStrLn ("exact type-change rules: " ++ show (Set.size exactRules)
                ++ "   feature-erased: " ++ show (Set.size erasedRules))
      putStrLn ""
      report "EXACT rule matching" exactCounts
      putStrLn ""
      report "FEATURE-ERASED rule matching" erasedCounts
      putStrLn ""
      putStrLn ("The UNEXPLAINED rows are the honest residue: held-out nodes needing "
                ++ "a type-change not seen in training. Anything else is generalisation "
                ++ "(combinators) or generalising memorisation (known rules).")
