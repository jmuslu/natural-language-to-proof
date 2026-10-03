-- | How much of ProofWriter does the CCGbank parser turn into correct logic?
--
-- For every theory sentence: tokenize -> CCGbank supertag + semantic chart ->
-- lambda term -> type check to t -> DRS (+ donkey anaphora) -> ProofWriter
-- triple/rule form -> compare with the gold representation in the @meta@ file.
-- Reported per split: % parsed, % typed, % DRS built, % exactly matching gold
-- (facts and rules separately; negated and multi-premise rules separately),
-- and the share of theories in which /every/ sentence matches. Failures are
-- bucketed by the first stage that failed, with examples.
--
-- Data: ProofWriter V2020.12.3 (AllenAI, CC BY 4.0) under @$PROOFWRITER_DIR@
-- (default @~/data/proofwriter@); CCGbank under @$CCGBANK_DIR@ (default
-- @~/ccgbank/ccgbank_1_1/data@). Neither is in the repository.
--
-- A sentence's DRS does not depend on the sentences around it (only discourse
-- anaphora does, and the comparison is per sentence), so each distinct sentence
-- is parsed once and its outcome counted for every occurrence. @--check-context
-- N@ re-runs the first N theories as whole texts and verifies that the
-- per-sentence statements agree with the cached ones.
--
-- Usage:
--   proofwriter-coverage [--owa] [--split train|dev|test]... [--limit N]
--                        [--questions] [--syntax] [--examples K] [--check-context N]
--                        [--debug SENTENCE]...
--   parser overrides:    [--alpha A] [--beam N] [--no-truecase] [--no-seen-rules]
--                        [--type-raise]   (all off = the tagger of ccg-supertag-parse)
module Main (main) where

import Control.Concurrent (forkIO, getNumCapabilities, newEmptyMVar, putMVar, takeMVar)
import Control.Monad (forM_, when)
import Data.Char (toLower)
import Data.List (foldl', isPrefixOf, sortBy)
import qualified Data.Map.Strict as M
import Data.Ord (comparing, Down(..))
import System.CPUTime (getCPUTime)
import System.Environment (getArgs, lookupEnv)
import System.IO (hFlush, hPutStrLn, stderr, stdout)
import Text.Printf (printf)

import NL2Proof.Bench.ProofWriter
import NL2Proof.Pipeline
import NL2Proof.Provenance (SourceId(..), renderProvInline)
import NL2Proof.Semantics.CCGSem (unarySem)
import NL2Proof.Semantics.Lambda (pretty)
import NL2Proof.Syntax.CCGParse (Rules(..))
import NL2Proof.Syntax.CCGSemParse
import NL2Proof.Syntax.Tokenize (Token(..), casedTokens)
import NL2Proof.Trace

--------------------------------------------------------------------------------
-- Options
--------------------------------------------------------------------------------

data Opts = Opts
  { oOWA       :: Bool
  , oSplits    :: [String]
  , oLimit     :: Int
  , oQuestions :: Bool
  , oSyntax    :: Bool
  , oExamples  :: Int
  , oContext   :: Int
  , oDebug     :: [String]
  , oModel     :: SemModel -> SemModel
    -- ^ Parser configuration overrides from the command line.
  }

parseOpts :: [String] -> Opts
parseOpts = go (Opts False [] 0 False False 3 20 [] id)
  where
    go o ("--owa" : r) = go o { oOWA = True } r
    go o ("--split" : s : r) = go o { oSplits = oSplits o ++ [s] } r
    go o ("--limit" : n : r) = go o { oLimit = read n } r
    go o ("--questions" : r) = go o { oQuestions = True } r
    go o ("--syntax" : r) = go o { oSyntax = True } r
    go o ("--examples" : n : r) = go o { oExamples = read n } r
    go o ("--check-context" : n : r) = go o { oContext = read n } r
    go o ("--debug" : t : r) = go o { oDebug = oDebug o ++ [t] } r
    go o ("--alpha" : a : r) = go (cfg o (\m -> m { smAlpha = read a })) r
    go o ("--beam" : b : r) = go (cfg o (\m -> m { smBeam = read b })) r
    go o ("--no-truecase" : r) = go (cfg o (\m -> m { smTruecase = False })) r
    go o ("--no-seen-rules" : r) = go (cfg o (\m -> m { smSeenRules = False })) r
    go o ("--type-raise" : r) = go (cfg o (\m -> m { smTypeRaise = True })) r
    go o (_ : r) = go o r
    go o [] = o { oSplits = if null (oSplits o) then ["train"] else oSplits o }
    cfg o f = o { oModel = f . oModel o }

--------------------------------------------------------------------------------
-- Per-sentence outcome
--------------------------------------------------------------------------------

data Kind = KFact | KRule | KQuestion
  deriving (Eq, Ord, Show)

data Outcome = Outcome
  { ocParsed    :: !Bool
  , ocTyped     :: !Bool
  , ocDRS       :: !Bool
  , ocConverted :: !Bool
  , ocExact     :: !Bool
  , ocAmbiguous :: !Bool
  , ocDecisions :: ![String]   -- ^ decision kinds logged (deduped per sentence)
  , ocBucket    :: !(Maybe (String, String))
    -- ^ (failure bucket, example line) when not exact
  }

-- | Evaluate an outcome completely, so it no longer refers to the parse (chart,
-- trace) it was computed from.
forceOutcome :: Outcome -> Outcome
forceOutcome o =
  length (concat (ocDecisions o)) `seq`
  maybe () (\(a, b) -> length a `seq` length b `seq` ()) (ocBucket o) `seq` o

-- | Map in parallel over N worker threads (base only: forkIO + MVar), each
-- result forced to normal form by @force@ inside its worker.
parMapIO :: Int -> (a -> b) -> (b -> b) -> [a] -> IO [b]
parMapIO nWorkers f force xs = do
  let chunks = chunk (max 1 ((length xs + nWorkers - 1) `div` nWorkers)) xs
  vars <- mapM (\c -> do
                   v <- newEmptyMVar
                   _ <- forkIO (let ys = map (force . f) c in forceList ys `seq` putMVar v ys)
                   pure v) chunks
  concat <$> mapM takeMVar vars
  where
    chunk _ [] = []
    chunk k ys = let (a, b) = splitAt k ys in a : chunk k b
    forceList = foldr seq ()

evaluate :: Opts -> SemModel -> String -> Statement -> Outcome
evaluate opts m text gold =
  case prSentences res of
    [r] -> judge r
    rs  -> failAt ("sentence split: " ++ show (length rs) ++ " sentences") ""
  where
    res = runPipelineWith (CCGBankParser m) (SourceId "pw") text
    goldN = normalizeStatement gold
    failAt b detail = Outcome False False False False False False [] (Just (b, detail))

    judge r =
      let diags = traceDiagnostics (srTrace r)
          decs = dedupe (map decKind (traceDecisions (srTrace r)))
          amb = any ((== ParseAmbiguity) . diagKind) diags
          parsed = maybe False (const True) (srChosen r)
          typed = maybe False (const True) (srForm r)
          drsOk = maybe False (const True) (srDRS r)
          conv = maybe (Left "no DRS") drsToStatement (srDRS r)
          exact = either (const False) ((== goldN) . normalizeStatement) conv
          bucket
            | not (null (srUnknown r)) =
                Just ( "no interpretable category for: "
                         ++ unwords (map (map toLower . tokText) (srUnknown r))
                     , text )
            | not parsed =
                Just ( "no root derivation" ++ syntaxNote
                     , text )
            | not typed = Just ("type check failure", text ++ "  " ++ firstDiag TypeCheckFailure diags)
            | Left e <- conv =
                Just ("DRS does not convert: " ++ generalise e, text ++ "  form: " ++ maybe "" pretty (srForm r))
            | Right st <- conv, not exact =
                Just ( "converted, wrong meaning: " ++ difference goldN (normalizeStatement st)
                     , text ++ "\n        gold: " ++ renderStatement goldN
                         ++ "\n        got:  " ++ renderStatement (normalizeStatement st) )
            | otherwise = Nothing
          syntaxNote
            | oSyntax opts =
                if syntacticParse m (casedTokens 0 text)
                  then " (category-only parser does reach S)"
                  else " (category-only parser does not reach S either)"
            | otherwise = ""
      in Outcome parsed typed drsOk (either (const False) (const True) conv) exact amb decs bucket

    firstDiag k ds = case [ diagMsg d | d <- ds, diagKind d == k ] of
      (x : _) -> x
      []      -> ""

    dedupe = foldr (\x acc -> if x `elem` acc then acc else x : acc) []

    -- Strip referent names out of a conversion error so errors group.
    generalise e = unwords [ if any (`isPrefixOf` w) ["x", "\"x", "?"] then "_" else w | w <- words e ]

difference :: Statement -> Statement -> String
difference (Fact _) (Rule _ _) = "fact read as rule"
difference (Rule _ _) (Fact _) = "rule read as fact"
difference (Fact a) (Fact b) = atomDiff a b
difference (Rule ba ha) (Rule bb hb)
  | ha /= hb && ba /= bb = "body and head differ"
  | ha /= hb = "head differs: " ++ atomDiff ha hb
  | length ba /= length bb = "premise count differs"
  | otherwise = "body differs"

atomDiff :: Atom -> Atom -> String
atomDiff a b
  | atPol a /= atPol b = "polarity"
  | atRel a /= atRel b = "relation"
  | atSubj a /= atSubj b = "subject"
  | otherwise = "object"

--------------------------------------------------------------------------------
-- Aggregation
--------------------------------------------------------------------------------

-- | Counts for one population of sentences.
data Row = Row { rN, rParsed, rTyped, rDRS, rConv, rExact, rAmb, rAmbExact :: !Int }

emptyRow :: Row
emptyRow = Row 0 0 0 0 0 0 0 0

addRow :: Row -> Outcome -> Row
addRow r o = Row
  { rN = rN r + 1
  , rParsed = rParsed r + b (ocParsed o)
  , rTyped = rTyped r + b (ocTyped o)
  , rDRS = rDRS r + b (ocDRS o)
  , rConv = rConv r + b (ocConverted o)
  , rExact = rExact r + b (ocExact o)
  , rAmb = rAmb r + b (ocAmbiguous o)
  , rAmbExact = rAmbExact r + b (ocAmbiguous o && ocExact o)
  }
  where b x = if x then 1 else 0

pct :: Int -> Int -> String
pct _ 0 = "   n/a"
pct x n = printf "%5.1f%%" (100 * fromIntegral x / fromIntegral n :: Double)

printRow :: String -> Row -> IO ()
printRow label r =
  printf "  %-26s %7d %s %s %s %s %s   (ambiguous %d, of which exact %d)\n"
    label (rN r) (pct (rParsed r) (rN r)) (pct (rTyped r) (rN r)) (pct (rDRS r) (rN r))
    (pct (rConv r) (rN r)) (pct (rExact r) (rN r)) (rAmb r) (rAmbExact r)

--------------------------------------------------------------------------------
-- Main
--------------------------------------------------------------------------------

main :: IO ()
main = do
  opts <- parseOpts <$> getArgs
  pwDir <- do
    d <- lookupEnv "PROOFWRITER_DIR"
    h <- lookupEnv "HOME"
    pure (maybe (maybe "." id h ++ "/data/proofwriter") id d)
  cdir <- ccgbankDataDir
  hPutStrLn stderr ("training CCGbank model from " ++ cdir ++ " (sections 02-21)")
  (model0, ntrees) <- loadSemModel cdir
  let model = oModel opts model0
  hPutStrLn stderr ("  " ++ show ntrees ++ " trees")
  printf "parser: beta %.3f, k %d, beam %d, alpha %.1f, truecase %s, seen-rules %s (%d pairs), type-raising %s\n"
    (smBeta model) (smKmax model) (smBeam model) (smAlpha model) (show (smTruecase model))
    (show (smSeenRules model)) (length (smSeen model)) (show (smTypeRaise model))
  forM_ (oDebug opts) (debugSentence model)
  let world = if oOWA opts then "OWA" else "CWA"
  forM_ (if null (oDebug opts) then oSplits opts else []) $ \split -> do
    let path = pwDir ++ "/proofwriter-dataset-V2020.12.3/" ++ world ++ "/depth-5/meta-" ++ split ++ ".jsonl"
    hPutStrLn stderr ("reading " ++ path)
    txt <- readFile path
    let ls0 = filter (not . null) (lines txt)
        ls = if oLimit opts > 0 then take (oLimit opts) ls0 else ls0
        theories = [ t | l <- ls, Right t <- [parseTheory l] ]
        bad = length ls - length theories
    when (bad > 0) (hPutStrLn stderr ("  " ++ show bad ++ " lines failed to parse"))
    runSplit opts model (world ++ " depth-5 " ++ split) theories
    hFlush stdout

runSplit :: Opts -> SemModel -> String -> [Theory] -> IO ()
runSplit opts model label theories = do
  let items th = [ (KFact, s) | s <- thFacts th ] ++ [ (KRule, s) | s <- thRules th ]
                 ++ (if oQuestions opts then [ (KQuestion, s) | s <- thQuestions th ] else [])
      distinct = M.fromList [ (s, ()) | th <- theories, (_, s) <- items th ]
  caps <- getNumCapabilities
  outs <- parMapIO caps (\(t, g) -> evaluate opts model t g) forceOutcome (M.keys distinct)
  let cache = M.fromList (zip (M.keys distinct) outs)
      occ = [ (k, g, cache M.! s) | th <- theories, (k, s@(_, g)) <- items th ]
      rowFor p = foldl' addRow emptyRow [ o | (k, g, o) <- occ, p k g ]
      facts = rowFor (\k _ -> k == KFact)
      rules = rowFor (\k _ -> k == KRule)
      rulesNeg = rowFor (\k g -> k == KRule && statementNegated g)
      rulesPos = rowFor (\k g -> k == KRule && not (statementNegated g))
      rulesMulti = rowFor (\k g -> k == KRule && statementPremises g > 1)
      rulesSingle = rowFor (\k g -> k == KRule && statementPremises g == 1)
      allTheory = rowFor (\k _ -> k /= KQuestion)
      qs = rowFor (\k _ -> k == KQuestion)
      qsNeg = rowFor (\k g -> k == KQuestion && statementNegated g)
      theoryOK th = all (\s -> ocExact (cache M.! s)) [ s | (k, s) <- items th, k /= KQuestion ]
      nOK = length (filter theoryOK theories)
  printf "\n== %s: %d theories, %d theory sentences (%d distinct)\n"
    label (length theories) (rN allTheory) (M.size distinct)
  printf "  %-26s %7s %6s %6s %6s %6s %6s\n" "" "n" "parsed" "typed" "DRS" "conv" "EXACT"
  printRow "facts" facts
  printRow "rules" rules
  printRow "  rules with negation" rulesNeg
  printRow "  rules without negation" rulesPos
  printRow "  multi-premise rules" rulesMulti
  printRow "  single-premise rules" rulesSingle
  printRow "all theory sentences" allTheory
  when (oQuestions opts) $ do
    printRow "questions" qs
    printRow "  negated questions" qsNeg
  printf "  whole theory exact (every fact and rule): %d / %d = %s\n"
    nOK (length theories) (pct nOK (length theories))

  -- Logged decisions, by kind, over sentence occurrences.
  let decCounts = M.fromListWith (+) [ (d, 1 :: Int) | (k, _, o) <- occ, k /= KQuestion, d <- ocDecisions o ]
  putStrLn "  decisions logged (sentence occurrences carrying at least one):"
  forM_ (M.toList decCounts) $ \(d, c) -> printf "    %-18s %d\n" d c

  -- Failure buckets over occurrences, with distinct-sentence examples.
  let fails = [ (b, ex) | (_, _, o) <- occ, Just (b, ex) <- [ocBucket o] ]
      counts = M.fromListWith (+) [ (b, 1 :: Int) | (b, _) <- fails ]
      examples = M.fromListWith (\new old -> old ++ [ e | e <- new, e `notElem` old ])
                   [ (b, [ex]) | (b, ex) <- fails ]
      ranked = sortBy (comparing (Down . snd)) (M.toList counts)
  printf "  failure buckets (%d failing occurrences):\n" (length fails)
  forM_ ranked $ \(b, c) -> do
    printf "    %6d  %s\n" c b
    forM_ (take (oExamples opts) (M.findWithDefault [] b examples)) $ \e ->
      putStrLn ("          e.g. " ++ e)

  -- Which words are over-represented in sentences with no root derivation:
  -- per word, sentence occurrences containing it and the share that fail.
  let wordsOf t = dedupeW (map (map toLower . tokText) (casedTokens 0 t))
      dedupeW = foldr (\x acc -> if x `elem` acc then acc else x : acc) []
      perWord = M.fromListWith (\(a, b) (c, d) -> (a + c, b + d))
        [ (w, (1 :: Int, if noRoot o then 1 else 0 :: Int))
        | (_, _, o, t) <- occT, w <- wordsOf t ]
      noRoot o = maybe False (("no root" `isPrefixOf`) . fst) (ocBucket o)
      occT = [ (k, g, cache M.! s, t) | th <- theories, (k, s@(t, g)) <- items th, k /= KQuestion ]
      worst = take 8 (sortBy (comparing (Down . rate)) [ x | x@(_, (n, _)) <- M.toList perWord, n >= 20 ])
      rate (_, (n, f)) = fromIntegral f / fromIntegral n :: Double
  putStrLn "  words by share of their sentences with no root derivation (>= 20 occurrences):"
  forM_ worst $ \(w, (nn, f)) -> printf "    %-10s %6d sentences, %5.1f%% no root derivation\n" w nn (100 * fromIntegral f / fromIntegral nn :: Double)

  -- A descriptive slice of the same run (not a different parser): "blocker"
  -- words are detected generically as those whose sentences almost never get
  -- a root derivation; report accuracy on what does not contain them.
  let blockers = [ w | (w, (nn, f)) <- M.toList perWord, nn >= 20, f * 4 >= nn * 3 ]
      hasBlocker t = any (`elem` blockers) (wordsOf t)
      rest = foldl' addRow emptyRow [ o | (_, _, o, t) <- occT, not (hasBlocker t) ]
      clean th = not (any (\(k, (t, _)) -> k /= KQuestion && hasBlocker t) (items th))
      cleanTh = filter clean theories
      cleanOK = length (filter theoryOK cleanTh)
  printf "  blocker words (>= 20 sentences, >= 75%% with no root derivation): %s\n" (unwords blockers)
  printRow "sentences without blockers" rest
  printf "  theories without blockers: %d, whole theory exact: %d = %s\n"
    (length cleanTh) cleanOK (pct cleanOK (length cleanTh))

  -- Context-independence check.
  when (oContext opts > 0) $ do
    let sample = take (oContext opts) theories
        check th =
          let ss = [ s | (k, s) <- items th, k /= KQuestion ]
              res = runPipelineWith (CCGBankParser model) (SourceId (thId th))
                      (unwords (map fst ss))
              got = [ fmap normalizeStatement (maybe (Left "") drsToStatement (srDRS r))
                    | r <- prSentences res ]
              want = [ evaluateConv s | s <- ss ]
          in length got == length want && and (zipWith sameConv got want)
        evaluateConv (t, _) =
          let r = runPipelineWith (CCGBankParser model) (SourceId "pw") t
          in case prSentences r of
               [x] -> fmap normalizeStatement (maybe (Left "") drsToStatement (srDRS x))
               _   -> Left "split"
        sameConv (Right a) (Right b) = a == b
        sameConv (Left _) (Left _) = True
        sameConv _ _ = False
        okN = length (filter check sample)
    printf "  context check: %d / %d whole-theory runs agree sentence-by-sentence with standalone runs\n"
      okN (length sample)

-- | Show every stage for one sentence: offered and interpretable readings per
-- token, root meanings with scores, the chosen form, DRS, conversion, trace.
debugSentence :: SemModel -> String -> IO ()
debugSentence m text = do
  t0 <- getCPUTime
  let sp0 = semParse m (SourceId "t") (casedTokens 0 text)
      n = length (spRoots sp0)
  length (concat (spLexical sp0)) `seq` pure ()
  tl <- getCPUTime
  spMaxCats sp0 `seq` pure ()
  tc <- getCPUTime
  n `seq` pure ()
  t1 <- getCPUTime
  printf "   lexical %.3fs, category pass %.3fs, rest %.3fs\n"
    (fromIntegral (tl - t0) / 1e12 :: Double) (fromIntegral (tc - tl) / 1e12 :: Double)
    (fromIntegral (t1 - tc) / 1e12 :: Double)
  printf "== %s  (%d root meanings, %.2fs; max %d categories/cell; %d meaningful unary rules)\n" (show text) n
    (fromIntegral (t1 - t0) / 1e12 :: Double) (spMaxCats sp0) (length [ () | (a, b) <- rUnary (smRules m), Just _ <- [unarySem a b] ])
  let toks = casedTokens 0 text
      sp = semParse m (SourceId "debug") toks
  forM_ (zip3 [0 :: Int ..] toks (spLexical sp)) $ \(i, t, ls) -> do
    printf "  [%d] %-10s name=%s offered=%d\n" i (tokText t)
      (show (nameStatus m (i == 0) (tokText t))) (length (offeredTags m (i == 0) (tokText t)))
    forM_ (offeredTags m (i == 0) (tokText t)) $ \(c, sc) ->
      printf "        %7.2f %s%s\n" sc (show c)
        (if any (\l -> lxCat l == c) ls then "  *" else "")
    forM_ [ l | l <- ls, lxCat l `notElem` map fst (offeredTags m (i == 0) (tokText t)) ] $ \l ->
      printf "        %7.2f %s  * (name)\n" (lxScore l) (show (lxCat l))
  putStrLn ("  syntactic (category-only) parse reaches S: " ++ show (syntacticParse m toks))
  forM_ (take 4 (spRoots sp)) $ \r -> do
    printf "  root %7.2f %s : %s\n" (ssScore r) (show (ssCat r)) (pretty (ssSem r))
    putStrLn ("       " ++ renderProvInline (ssProv r))
  let res = runPipelineWith (CCGBankParser m) (SourceId "debug") text
  forM_ (prSentences res) $ \r -> do
    putStr (renderSentenceResult r)
    putStrLn ("  convert: " ++ either id renderStatement (maybe (Left "no DRS") drsToStatement (srDRS r)))
    putStr (renderTrace (srTrace r))
