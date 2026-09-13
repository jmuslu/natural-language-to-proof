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
import NL2Proof.Syntax.CCGParse (Rules, rulesFrom, rootCat, chartParseScored)
import NL2Proof.Syntax.CCGRules (unifiable)
import NL2Proof.Syntax.CCGSupertag
  (TagModel, buildTagModel, leafPairs, supertagScored, isOOV)

-- Parser configuration bundled so `score` stays readable.
data Cfg = Cfg { cBeta :: Double, cKmax :: Int, cBeam :: Int, cMaxLen :: Int
               , cParse :: Bool, cMaxTest :: Int }  -- cMaxTest 0 = no cap

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

score :: Cfg -> TagModel -> Rules -> Acc -> AutoNode -> Acc
score cfg tm rules acc tree =
  let pairs = leafPairs tree
      ws    = map fst pairs
      n     = length ws
  in if n == 0 || n > cMaxLen cfg
       then acc { aTooLong = aTooLong acc + (if n > cMaxLen cfg then 1 else 0) }
       else
         let scored      = map (supertagScored tm (cBeta cfg) (cKmax cfg)) ws
             cats        = map (map fst) scored
             oovs        = length (filter (isOOV tm) ws)
             wordOK      = length [ () | (g, cs) <- zip (map snd pairs) cats, g `elem` cs ]
             allCovered  = wordOK == n
             tags        = sum (map length cats)
             parsedRoot  = cParse cfg && case rootCat tree of
               Nothing -> False
               Just rc -> any (\(c, _) -> c `unifiable` rc)
                              (chartParseScored (cBeam cfg) rules scored)
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
  let (files, cfg) = parseArgs argv
  if null files
    then hPutStrLn stderr ("usage: ccg-supertag-parse FILE.auto [...] "
                           ++ "[--beta B] [--k N] [--beam N] [--max-len N] [--no-parse]")
    else do
      trees <- concat <$> mapM readTrees files
      let idx    = zip [0 :: Int ..] trees
          test0  = [ t | (i, t) <- idx, i `mod` 5 == 0 ]
          test   = if cMaxTest cfg > 0 then take (cMaxTest cfg) test0 else test0
          train  = [ t | (i, t) <- idx, i `mod` 5 /= 0 ]
          tm     = buildTagModel (concatMap leafPairs train)
          rules = rulesFrom train
          acc   = foldl' (score cfg tm rules) emptyAcc test
      hPutStrLn stderr ("loaded " ++ show (length trees) ++ " trees from "
                        ++ show (length files) ++ " file(s)")
      putStrLn "== from-words parse coverage (supertagger + scored beam chart, external check) =="
      putStrLn ("beta (adaptive tag beam)     : " ++ show (cBeta cfg))
      putStrLn ("kmax (tags/word cap)         : " ++ show (cKmax cfg))
      putStrLn ("chart beam (cats/cell)       : " ++ show (cBeam cfg))
      putStrLn ("max sentence length (words)  : " ++ show (cMaxLen cfg))
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
      putStrLn ("oracle inclusion (word)      : " ++ pct (aWordOracle acc) (aWords acc)
                ++ "   <- ceiling: gold tag offered")
      putStrLn ("oracle inclusion (sent)      : " ++ pct (aSentOracle acc) (aSents acc)
                ++ "   <- all words covered")
      if cParse cfg
        then putStrLn ("from-words parse to gold root: " ++ show (aParsed acc)
                       ++ " (" ++ pct (aParsed acc) (aSents acc) ++ " of sentences)")
        else putStrLn "from-words parse to gold root: (skipped, --no-parse)"
  where
    parseArgs args = go args (Cfg 0.01 20 40 25 True 0)
      where
        go ("--beta" : v : rest) c     = case reads v of [(x,"")] -> go rest c{cBeta=x};    _ -> go rest c
        go ("--k" : v : rest) c        = case reads v of [(x,"")] -> go rest c{cKmax=x};    _ -> go rest c
        go ("--beam" : v : rest) c     = case reads v of [(x,"")] -> go rest c{cBeam=x};    _ -> go rest c
        go ("--max-len" : v : rest) c  = case reads v of [(x,"")] -> go rest c{cMaxLen=x};  _ -> go rest c
        go ("--max-test" : v : rest) c = case reads v of [(x,"")] -> go rest c{cMaxTest=x}; _ -> go rest c
        go ("--no-parse" : rest) c     = go rest c{cParse=False}
        go (x : rest) c                = let (fs, c') = go rest c in (x : fs, c')
        go [] c                        = ([], c)
