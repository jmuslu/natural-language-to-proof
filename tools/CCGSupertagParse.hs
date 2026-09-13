-- | From-words CCG parsing: supertag each raw word, then chart-parse the candidates.
--
-- Completes the parsing story one rung past 'ccg-parse-coverage' (which is given the
-- gold supertags): here a frequency supertagger ('CCGSupertag'), trained on the
-- /train/ split only, offers each word its top-k categories, and the chart
-- ('CCGParse.chartParseMulti') combines them. Reports, on held-out test sentences,
-- the numbers that must be read together and never conflated:
--
--   * OOV rate and average supertag ambiguity (categories offered per word);
--   * __oracle inclusion@k__ — is the gold category among a word's top-k tags? Per
--     word, and per sentence (all words covered). This is the ceiling: a parse
--     cannot recover a category the tagger never offered;
--   * __from-words parse coverage__ — a spanning derivation reaches the gold root.
--
-- Usage: @ccg-supertag-parse FILE.auto [...] [--k N] [--max-len N]@
module Main (main) where

import Data.List (foldl')
import System.Environment (getArgs)
import System.IO (hPutStrLn, stderr)

import NL2Proof.Syntax.CCGDeriv (AutoNode, parseAuto)
import NL2Proof.Syntax.CCGParse (Rules, rulesFrom, rootCat, chartParseMulti)
import NL2Proof.Syntax.CCGRules (unifiable)
import NL2Proof.Syntax.CCGSupertag
  (TagModel, buildTagModel, leafPairs, supertag, isOOV, oracleIncluded)

catCap :: Int
catCap = 200

data Acc = Acc
  { aSents      :: !Int   -- test sentences within the length bound
  , aWords      :: !Int
  , aOOV        :: !Int
  , aTags       :: !Int   -- total candidate tags offered (for average ambiguity)
  , aWordOracle :: !Int   -- words whose gold cat is in top-k
  , aSentOracle :: !Int   -- sentences where every word's gold cat is in top-k
  , aParsed     :: !Int   -- from-words derivation reaches the gold root
  , aTooLong    :: !Int
  }

emptyAcc :: Acc
emptyAcc = Acc 0 0 0 0 0 0 0 0

readTrees :: FilePath -> IO [AutoNode]
readTrees f = do
  s <- readFile f
  let keep line = not (null line) && take 3 line /= "ID=" && not (all (`elem` " \t\r") line)
  pure [ t | line <- lines s, keep line, Right t <- [parseAuto line] ]

score :: Int -> Int -> TagModel -> Rules -> Acc -> AutoNode -> Acc
score k maxLen tm rules acc tree =
  let pairs = leafPairs tree
      ws    = map fst pairs
      golds = map snd pairs
      n     = length ws
  in if n == 0 || n > maxLen
       then acc { aTooLong = aTooLong acc + (if n > maxLen then 1 else 0) }
       else
         let cells       = map (supertag tm k) ws
             oovs        = length (filter (isOOV tm) ws)
             wordOK      = length [ () | (w, g) <- pairs, oracleIncluded tm k w g ]
             allCovered  = wordOK == n
             tags        = sum (map length cells)
             parsedRoot  = case rootCat tree of
               Nothing -> False
               Just rc -> any (`unifiable` rc)
                              (foldr (:) [] (chartParseMulti catCap rules cells))
         in acc { aSents = aSents acc + 1
                , aWords = aWords acc + n
                , aOOV = aOOV acc + oovs
                , aTags = aTags acc + tags
                , aWordOracle = aWordOracle acc + wordOK
                , aSentOracle = aSentOracle acc + (if allCovered then 1 else 0)
                , aParsed = aParsed acc + (if parsedRoot then 1 else 0) }

pct :: Int -> Int -> String
pct _ 0 = "n/a"
pct x tot =
  let t = round (1000 * fromIntegral x / fromIntegral tot :: Double) :: Int
  in show (fromIntegral t / 10 :: Double) ++ "%"

avg :: Int -> Int -> String
avg _ 0 = "n/a"
avg x tot =
  let t = round (100 * fromIntegral x / fromIntegral tot :: Double) :: Int
  in show (fromIntegral t / 100 :: Double)

main :: IO ()
main = do
  argv <- getArgs
  let (files, k, maxLen) = parseArgs argv
  if null files
    then hPutStrLn stderr "usage: ccg-supertag-parse FILE.auto [...] [--k N] [--max-len N]"
    else do
      trees <- concat <$> mapM readTrees files
      let idx   = zip [0 :: Int ..] trees
          test  = [ t | (i, t) <- idx, i `mod` 5 == 0 ]
          train = [ t | (i, t) <- idx, i `mod` 5 /= 0 ]
          tm    = buildTagModel (concatMap leafPairs train)
          rules = rulesFrom train
          acc   = foldl' (score k maxLen tm rules) emptyAcc test
      hPutStrLn stderr ("loaded " ++ show (length trees) ++ " trees from "
                        ++ show (length files) ++ " file(s)")
      putStrLn "== from-words parse coverage (supertagger + chart, external check) =="
      putStrLn ("k (tags/word)                : " ++ show k)
      putStrLn ("max sentence length (words)  : " ++ show maxLen)
      putStrLn ("train / test trees           : " ++ show (length train)
                ++ " / " ++ show (length test))
      putStrLn ""
      putStrLn ("test sentences (<= max-len)  : " ++ show (aSents acc)
                ++ "  (skipped over length: " ++ show (aTooLong acc) ++ ")")
      putStrLn ("words                        : " ++ show (aWords acc)
                ++ "  (OOV: " ++ pct (aOOV acc) (aWords acc) ++ ")")
      putStrLn ("avg supertag ambiguity       : " ++ avg (aTags acc) (aWords acc)
                ++ " tags/word")
      putStrLn ""
      putStrLn ("oracle inclusion @k (word)   : " ++ pct (aWordOracle acc) (aWords acc)
                ++ "   <- ceiling: gold tag offered")
      putStrLn ("oracle inclusion @k (sent)   : " ++ pct (aSentOracle acc) (aSents acc)
                ++ "   <- all words covered")
      putStrLn ("from-words parse to gold root: " ++ show (aParsed acc)
                ++ " (" ++ pct (aParsed acc) (aSents acc) ++ " of sentences)")
  where
    parseArgs = go [] 4 25
      where
        go fs k m ("--k" : v : rest)       = case reads v of [(x,"")] -> go fs x m rest; _ -> go fs k m rest
        go fs k m ("--max-len" : v : rest) = case reads v of [(x,"")] -> go fs k x rest; _ -> go fs k m rest
        go fs k m (x : rest)               = go (fs ++ [x]) k m rest
        go fs k m []                       = (fs, k, m)
