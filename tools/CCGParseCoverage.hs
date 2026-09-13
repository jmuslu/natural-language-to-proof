-- | Measure whole-sentence bottom-up parse coverage over real @.auto@ sentences.
--
-- Folds the combinatory rules ('CCGRules.combine') and the learned type-change
-- inventory ('CCGParse') into one CKY parse and asks, for each /test/ sentence:
-- given the gold supertags, does the grammar derive a category unifying with the
-- gold root? Rules are induced from a disjoint /train/ split (every 5th tree is
-- test), so the type-change inventory is not fit to the sentences it is scored on.
-- This is the external check on the grammar as a whole; using gold supertags is the
-- stated, honest scope (it isolates combination from lexical ambiguity).
--
-- Usage: @ccg-parse-coverage FILE.auto [FILE.auto ...] [--max-len N]@
module Main (main) where

import Data.List (foldl')
import System.Environment (getArgs)
import System.IO (hPutStrLn, stderr)

import NL2Proof.Syntax.CCGDeriv (AutoNode, parseAuto)
import NL2Proof.Syntax.CCGParse (Rules, rulesFrom, leafCats, derivesRoot)

catCap :: Int
catCap = 200

data Acc = Acc
  { aConsidered :: !Int   -- test sentences within the length bound, leaves+root parseable
  , aParsed     :: !Int   -- derived a category unifying with the gold root
  , aTooLong    :: !Int   -- skipped: over the length bound
  , aSkipped    :: !Int   -- skipped: leaves/root unparseable
  }

emptyAcc :: Acc
emptyAcc = Acc 0 0 0 0

readTrees :: FilePath -> IO [AutoNode]
readTrees f = do
  s <- readFile f
  let keep line = not (null line) && take 3 line /= "ID=" && not (all (`elem` " \t\r") line)
  pure [ t | line <- lines s, keep line, Right t <- [parseAuto line] ]

wordLen :: AutoNode -> Maybe Int
wordLen = fmap length . leafCats

score :: Int -> Rules -> Acc -> AutoNode -> Acc
score maxLen rules acc tree = case wordLen tree of
  Nothing -> acc { aSkipped = aSkipped acc + 1 }
  Just n
    | n > maxLen -> acc { aTooLong = aTooLong acc + 1 }
    | otherwise  -> case derivesRoot catCap rules tree of
        Nothing    -> acc { aSkipped = aSkipped acc + 1 }
        Just True  -> acc { aConsidered = aConsidered acc + 1, aParsed = aParsed acc + 1 }
        Just False -> acc { aConsidered = aConsidered acc + 1 }

pct :: Int -> Int -> String
pct _ 0 = "n/a"
pct k tot =
  let tenths = round (1000 * fromIntegral k / fromIntegral tot :: Double) :: Int
  in show (fromIntegral tenths / 10 :: Double) ++ "%"

main :: IO ()
main = do
  argv <- getArgs
  let (files, maxLen) = parseArgs argv
  if null files
    then hPutStrLn stderr "usage: ccg-parse-coverage FILE.auto [...] [--max-len N]"
    else do
      trees <- concat <$> mapM readTrees files
      let idx      = zip [0 :: Int ..] trees
          test     = [ t | (i, t) <- idx, i `mod` 5 == 0 ]
          train    = [ t | (i, t) <- idx, i `mod` 5 /= 0 ]
          rules    = rulesFrom train
          acc      = foldl' (score maxLen rules) emptyAcc test
      hPutStrLn stderr ("loaded " ++ show (length trees) ++ " trees from "
                        ++ show (length files) ++ " file(s)")
      putStrLn "== whole-sentence bottom-up parse coverage (external check on the grammar) =="
      putStrLn ("train trees (rule induction) : " ++ show (length train))
      putStrLn ("test trees                   : " ++ show (length test))
      putStrLn ("max sentence length (words)  : " ++ show maxLen)
      putStrLn ""
      putStrLn ("considered (<= max-len)      : " ++ show (aConsidered acc))
      putStrLn ("parsed to gold root          : " ++ show (aParsed acc)
                ++ " (" ++ pct (aParsed acc) (aConsidered acc) ++ " of considered)")
      putStrLn ("skipped, over length bound   : " ++ show (aTooLong acc))
      putStrLn ("skipped, unparseable cats    : " ++ show (aSkipped acc))
  where
    parseArgs = go [] 40
      where
        go fs n ("--max-len" : v : rest) = case reads v of [(k, "")] -> go fs k rest; _ -> go fs n rest
        go fs n (x : rest)               = go (fs ++ [x]) n rest
        go fs n []                       = (fs, n)
