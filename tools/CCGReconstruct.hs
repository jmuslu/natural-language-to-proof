-- | Run the combinatory rule set over real CCGbank @.auto@ derivations and
-- measure how many whole sentences reconstruct: every binary node's children
-- combine (per 'NL2Proof.Syntax.CCGRules') to that node's gold category.
--
-- This is the sentence-granularity external check behind Layer 2's test-case
-- generator. The GRAMMAR coverage tool measures rule /types/; this measures
-- whether real derivations go through end to end, which is what a test-case
-- generator over corpus sentences actually needs.
--
-- Reads @.auto@ file paths from argv (let the shell expand a glob), so it needs
-- no directory-listing dependency beyond @base@. Corpus files stay outside the
-- repo; nothing here embeds their content.
--
-- Usage: @ccg-reconstruct FILE.auto [FILE.auto ...]@
module Main (main) where

import Data.List (foldl', sortBy)
import qualified Data.Map.Strict as M
import Data.Ord (comparing, Down(..))
import System.Environment (getArgs)
import System.IO (hPutStrLn, stderr)

import NL2Proof.Syntax.CCGDeriv

data Acc = Acc
  { aSents      :: !Int
  , aSentsFull  :: !Int
  , aLineFail   :: !Int
  , aBin        :: !Int
  , aBinOK      :: !Int
  , aBinUncov   :: !Int
  , aUnary      :: !Int
  , aBadCat     :: !Int
  , aArity      :: !Int
  , aUncovByPar :: M.Map String Int  -- uncovered binary nodes, keyed by parent cat
  }

emptyAcc :: Acc
emptyAcc = Acc 0 0 0 0 0 0 0 0 0 M.empty

tally :: Acc -> AutoNode -> Acc
tally acc0 node =
  let vs   = verdicts node
      full = fullyReconstructed node
      acc1 = acc0 { aSents = aSents acc0 + 1
                  , aSentsFull = aSentsFull acc0 + (if full then 1 else 0) }
  in foldl' bump acc1 (zipVerdicts node vs)
  where
    bump a (v, mParent) = case v of
      VLeaf            -> a
      VUnary           -> a { aUnary = aUnary a + 1 }
      VBinaryOK        -> a { aBin = aBin a + 1, aBinOK = aBinOK a + 1 }
      VBinaryUncovered -> a { aBin = aBin a + 1, aBinUncov = aBinUncov a + 1
                            , aUncovByPar = maybe id (\p -> M.insertWith (+) p 1) mParent
                                              (aUncovByPar a) }
      VBadCat _        -> a { aBadCat = aBadCat a + 1 }
      VArity _         -> a { aArity = aArity a + 1 }

-- | Pair each pre-order verdict with the parent category of the node it came
-- from (for reporting where uncovered binary nodes concentrate).
zipVerdicts :: AutoNode -> [NodeVerdict] -> [(NodeVerdict, Maybe String)]
zipVerdicts n vs = zip vs (preorderCats n)
  where
    preorderCats (AutoLeaf c _)    = [Just c]
    preorderCats (AutoTree c kids) = Just c : concatMap preorderCats kids

processLine :: Acc -> String -> Acc
processLine acc line
  | take 3 line == "ID=" = acc
  | all (`elem` " \t\r") line = acc
  | otherwise = case parseAuto line of
      Right node -> tally acc node
      Left _     -> acc { aLineFail = aLineFail acc + 1 }

pct :: Int -> Int -> String
pct _ 0 = "n/a"
pct k tot =
  let tenths = round (1000 * fromIntegral k / fromIntegral tot :: Double) :: Int
  in show (fromIntegral tenths / 10 :: Double) ++ "%"

main :: IO ()
main = do
  files <- getArgs
  if null files
    then hPutStrLn stderr "usage: ccg-reconstruct FILE.auto [FILE.auto ...]"
    else do
      acc <- foldl' (\ioAcc f -> do
                        a <- ioAcc
                        s <- readFile f
                        return (foldl' processLine a (lines s)))
                    (return emptyAcc) files
      report (length files) acc

report :: Int -> Acc -> IO ()
report nFiles a = do
  putStrLn "== CCG derivation reconstruction over real .auto sentences (external check) =="
  putStrLn ("files              : " ++ show nFiles)
  putStrLn ("sentences parsed   : " ++ show (aSents a)
            ++ "   (line parse failures: " ++ show (aLineFail a) ++ ")")
  putStrLn ("fully reconstructed: " ++ show (aSentsFull a) ++ "/" ++ show (aSents a)
            ++ " (" ++ pct (aSentsFull a) (aSents a) ++ ")")
  putStrLn ""
  putStrLn ("binary nodes       : " ++ show (aBin a))
  putStrLn ("  covered          : " ++ show (aBinOK a) ++ " (" ++ pct (aBinOK a) (aBin a) ++ ")")
  putStrLn ("  uncovered        : " ++ show (aBinUncov a) ++ " (" ++ pct (aBinUncov a) (aBin a) ++ ")")
  putStrLn ("unary nodes        : " ++ show (aUnary a)
            ++ "   (type-changing / type-raising; accepted as corpus-attested)")
  putStrLn ("category parse errs: " ++ show (aBadCat a))
  putStrLn ("arity anomalies    : " ++ show (aArity a))
  putStrLn ""
  putStrLn "uncovered binary nodes by parent category (top 20):"
  mapM_ (\(p, n) -> putStrLn ("  " ++ pad 26 p ++ show n))
        (take 20 (sortBy (comparing (Down . snd)) (M.toList (aUncovByPar a))))
  where
    pad k s = s ++ replicate (max 1 (k - length s)) ' '
