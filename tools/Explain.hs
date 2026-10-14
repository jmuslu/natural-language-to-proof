-- | @nl2proof-explain@: every stage of the pipeline for one sentence (or a
-- short text), side by side, for checking hand derivations against the
-- system.
--
-- > nl2proof-explain "Bob says that the cat is not red."
-- > nl2proof-explain                 -- REPL; the CCGbank model is loaded once
-- > nl2proof-explain --all-readings --stage=deriv --hand "..."
--
-- Sections: 1 tokens + supertags, 2 derivation, 3 lambda, 4 DRS, 5 claims,
-- 6 failures / notes.
--
-- Nothing here decides anything. The selected reading, its normal form, its
-- DRS and the trace come from 'runPipelineWith' unchanged. The one thing the
-- pipeline does not keep is the category at each internal derivation node
-- (its provenance tree records only rule names), so this tool rebuilds the
-- categories by replaying the recorded rules over the lexical candidates with
-- the library's own combinators ('combineNamed', 'unarySem', 'composeTerm',
-- 'coordTerm', 'applyIntensional'), and keeps a replay only if it ends in
-- exactly the parser's root meaning. If no replay matches, it says so and
-- prints the raw provenance tree instead.
module Main (main) where

import Control.Exception (SomeException, evaluate, try)
import Control.Monad (when)
import Data.Char (isSpace)
import Data.List (intercalate, isPrefixOf, nub, sortOn)
import qualified Data.Map as M
import GHC.Clock (getMonotonicTime)
import System.Environment (getArgs)
import System.Exit (exitFailure, exitSuccess)
import System.IO (hFlush, hPutStrLn, isEOF, stderr, stdout)
import Text.Printf (printf)

import NL2Proof.DRT.Build
import NL2Proof.DRT.Canonical (renderCanonCond)
import NL2Proof.DRT.Types
import NL2Proof.Pipeline
import NL2Proof.Provenance
import NL2Proof.Semantics.CCGSem
import NL2Proof.Semantics.Intensional (applyIntensional, isIntensionalTerm, liftsTo)
import NL2Proof.Semantics.Lambda
import qualified NL2Proof.Syntax.CCG as H
import NL2Proof.Syntax.CCGBank (CCat(..), Dir(..), Feat(..))
import NL2Proof.Syntax.CCGParse (Rules(..))
import NL2Proof.Syntax.CCGRules
  (Combinator(..), allCombinators, combineNamed, isCoordinator, isPunct, unifiable)
import NL2Proof.Syntax.CCGSemParse
import NL2Proof.Syntax.CCGSupertag (TagModel(..))
import NL2Proof.Syntax.Category (catTy)
import NL2Proof.Syntax.Lexicon (Entry(..), Lexicon, attitudeLexicon, lookupWord)
import NL2Proof.Syntax.Tokenize
import NL2Proof.Trace
import NL2Proof.Verify.ClaimKind (claimCond)
import NL2Proof.Verify.Reported

--------------------------------------------------------------------------------
-- Options
--------------------------------------------------------------------------------

data Stage = STags | SDeriv | SLambda | SDrs | SClaims
  deriving (Eq, Show)

stageName :: Stage -> String
stageName st = case st of
  STags -> "tags"
  SDeriv -> "deriv"
  SLambda -> "lambda"
  SDrs -> "drs"
  SClaims -> "claims"

data Opts = Opts
  { oAll   :: Bool
  , oStage :: Maybe Stage
  , oHand  :: Bool
  , oPOSBackoff :: Bool
  , oText  :: [String]
  }

usage :: String
usage = unlines
  [ "usage: nl2proof-explain [--all-readings] [--stage=tags|deriv|lambda|drs|claims] [--hand] [--pos-backoff] [TEXT]"
  , ""
  , "  TEXT            a sentence or short text; omitted: interactive REPL (:q quits)"
  , "  --all-readings  every reading (and every candidate supertag), selected one marked"
  , "  --stage=S       only one section: tags, deriv, lambda, drs or claims"
  , "  --hand          hand-written fragment lexicon (attitudeLexicon) instead of CCGbank"
  , "  --pos-backoff   experimental POS-dictionary lexical backoff (CCGbank only)"
  , ""
  , "CCGbank: $CCGBANK_DIR, else ~/ccgbank/ccgbank_1_1/data (sections 02-21)."
  , "REPL commands: :q quit, :all toggle --all-readings, :stage=S or :stage=all, :help"
  ]

parseStage :: String -> Maybe (Maybe Stage)
parseStage s = case s of
  "tags"   -> Just (Just STags)
  "deriv"  -> Just (Just SDeriv)
  "lambda" -> Just (Just SLambda)
  "drs"    -> Just (Just SDrs)
  "claims" -> Just (Just SClaims)
  "all"    -> Just Nothing
  _        -> Nothing

parseOpts :: [String] -> Either String Opts
parseOpts = go (Opts False Nothing False False [])
  where
    go o [] = Right o { oText = reverse (oText o) }
    go o (a : as)
      | a == "--all-readings" = go o { oAll = True } as
      | a == "--hand" = go o { oHand = True } as
      | a == "--pos-backoff" = go o { oPOSBackoff = True } as
      | "--stage=" `isPrefixOf` a = case parseStage (drop 8 a) of
          Just st -> go o { oStage = st } as
          Nothing -> Left ("unknown stage: " ++ drop 8 a)
      | a == "--help" || a == "-h" = Left ""
      | "--" `isPrefixOf` a = Left ("unknown flag: " ++ a)
      | otherwise = go o { oText = a : oText o } as

--------------------------------------------------------------------------------
-- Main
--------------------------------------------------------------------------------

main :: IO ()
main = do
  args <- getArgs
  opts <- case parseOpts args of
    Right o -> pure o
    Left "" -> putStr usage >> exitSuccess
    Left e -> hPutStrLn stderr e >> hPutStr' usage >> exitFailure
  choice <-
    if oHand opts
      then pure (HandLexicon attitudeLexicon)
      else do
        dir <- ccgbankDataDir
        hPutStrLn stderr ("loading CCGbank lexicon from " ++ dir ++ " (sections 02-21) ...")
        t0 <- getMonotonicTime
        (m, ntrees) <- loadSemModel dir
        _ <- evaluate (M.size (tmWord (smTags m)))
        t1 <- getMonotonicTime
        when (ntrees == 0) $ do
          hPutStrLn stderr ("FAILURE (stage: lexicon): no CCGbank trees found under " ++ dir
            ++ "/AUTO. Set CCGBANK_DIR, or use --hand.")
          exitFailure
        hPutStrLn stderr (printf "  %d trees, %d word forms, loaded in %.1fs"
          ntrees (M.size (tmWord (smTags m))) (t1 - t0))
        pure (CCGBankParser m { smPOSBackoff = oPOSBackoff opts })
  if null (oText opts)
    then repl choice opts
    else explainSafe choice opts (unwords (oText opts))
  where
    hPutStr' = hPutStrLn stderr

repl :: ParserChoice -> Opts -> IO ()
repl choice = loop
  where
    loop o = do
      putStr "explain> " >> hFlush stdout
      eof <- isEOF
      if eof then putStrLn "" else do
        l <- trim <$> getLine
        case l of
          ":q" -> pure ()
          ":quit" -> pure ()
          ":help" -> putStr usage >> loop o
          ":all" -> do
            putStrLn ("all-readings " ++ (if oAll o then "off" else "on"))
            loop o { oAll = not (oAll o) }
          _ | ":stage=" `isPrefixOf` l -> case parseStage (drop 7 l) of
                Just st -> putStrLn ("stage " ++ maybe "all" stageName st) >> loop o { oStage = st }
                Nothing -> putStrLn ("unknown stage: " ++ drop 7 l) >> loop o
            | null l -> loop o
            | otherwise -> explainSafe choice o l >> putStrLn "" >> loop o
    trim = reverse . dropWhile isSpace . reverse . dropWhile isSpace

-- | Render fully before printing, so a library 'error' anywhere becomes a
-- reported failure rather than a crash halfway through the output.
explainSafe :: ParserChoice -> Opts -> String -> IO ()
explainSafe choice o text = do
  r <- try (let s = explain choice o text in evaluate (length s) >> pure s)
  case r of
    Right s -> putStr s
    Left e -> putStr (unlines
      [ header "6. FAILURES"
      , "  stage: internal -- an exception was raised while explaining this text:"
      , "  " ++ show (e :: SomeException) ])

--------------------------------------------------------------------------------
-- Rendering a whole text
--------------------------------------------------------------------------------

header :: String -> String
header t = "== " ++ t ++ " " ++ replicate (max 3 (72 - length t)) '='

explain :: ParserChoice -> Opts -> String -> String
explain choice o text = unlines (concat (perSentence ++ [discourseDRS, claims, failures]))
  where
    pr = runPipelineWith choice (SourceId "input") text
    srs = prSentences pr
    multi = length srs > 1
    xs = [ explainSentence choice o r | r <- srs ]
    want st = maybe True (== st) (oStage o)

    perSentence =
      [ (if multi then ["", "### sentence " ++ show k ++ "/" ++ show (length srs) ++ ": "
                          ++ show (sentText (srSentence r))] else [])
          ++ seTags x ++ seDeriv x ++ seLambda x ++ seDRS x
      | (k, r, x) <- zip3 [1 :: Int ..] srs xs ]

    dscBox = dscDRS (prDiscourse pr)
    discourseDRS
      | multi, want SDrs =
          [ "", header "4b. DISCOURSE DRS (all sentences, anaphora resolved)" ]
            ++ map ("  " ++) (drsBoxLines dscBox)
      | otherwise = []

    claims
      | not (want SClaims) = []
      | null srs = []
      | all (\r -> srDRS r == Nothing) srs, oStage o == Nothing = []
      | all (\r -> srDRS r == Nothing) srs = ["", header "5. CLAIMS", "  (no DRS: nothing to split)"]
      | otherwise =
          [ "", header "5. CLAIMS (Verify.Reported.splitClaims)" ]
            ++ (if all (null . seAltClaims) xs then [] else ["  [selected reading]"])
            ++ claimLines dscBox
            ++ concatMap seAltClaims xs

    failures =
      let fs = concat [ map (prefix k) (seFailures x) | (k, x) <- zip [1 :: Int ..] xs ]
          ns = concat [ map (prefix k) (seNotes x) | (k, x) <- zip [1 :: Int ..] xs ]
                 ++ map ("  " ++) (concatMap (lines . renderDiagnostic) (traceDiagnostics (dscTrace (prDiscourse pr))))
                 ++ map ("  " ++) (concatMap (lines . renderDecision) (traceDecisions (dscTrace (prDiscourse pr))))
          prefix k l = if multi then "  [s" ++ show k ++ "] " ++ drop 2 l else l
      in case oStage o of
           Just _ | null fs -> []
           Just _ -> ["", header "6. FAILURES"] ++ fs
           Nothing ->
             ["", header "6. FAILURES / NOTES"]
               ++ (if null fs then ["  failures: none (lexicon, parse and meaning all succeeded)"] else fs)
               ++ (if null ns || oStage o /= Nothing then [] else "  notes (logged decisions and diagnostics):" : ns)

--------------------------------------------------------------------------------
-- One sentence
--------------------------------------------------------------------------------

data SentenceExplain = SentenceExplain
  { seTags      :: [String]
  , seDeriv     :: [String]
  , seLambda    :: [String]
  , seDRS       :: [String]
  , seAltClaims :: [String]
  , seFailures  :: [String]
  , seNotes     :: [String]
  }

-- | A lexical leaf, front-end neutral.
data Leaf = Leaf
  { lfWord   :: String
  , lfSpan   :: Span
  , lfCat    :: String
  , lfCatTy  :: Maybe Ty
  , lfTerm   :: Maybe Term   -- ^ Nothing for coordinators and punctuation
  , lfSource :: String
  , lfScore  :: Maybe Double
  }

-- | A derivation tree with the category (and meaning) at every node.
data DT
  = DLex Leaf
  | DRule String String (Maybe Term) [DT]   -- ^ rule label, category, meaning, children

dtLeaves :: DT -> [Leaf]
dtLeaves (DLex l) = [l]
dtLeaves (DRule _ _ _ ks) = concatMap dtLeaves ks

-- | One root reading, explained.
data Reading = Reading
  { rdSign  :: H.Sign
  , rdTree  :: Maybe DT
  , rdForm  :: Either String Term   -- ^ type-checked normal form, or why not
  , rdDRS   :: Maybe DRS
  }

explainSentence :: ParserChoice -> Opts -> SentenceResult -> SentenceExplain
explainSentence choice o r = SentenceExplain
  { seTags = section STags (header "1. TOKENS + SUPERTAGS") tagLines
  , seDeriv = section SDeriv (header "2. DERIVATION") derivLines
  , seLambda = section SLambda (header "3. LAMBDA") lambdaLines
  , seDRS = section SDrs (header "4. DRS (sentence-local, after local anaphora and presupposition projection)") drsLines
  , seAltClaims = altClaims
  , seFailures = failureLines
  , seNotes = noteLines
  }
  where
    want st = maybe True (== st) (oStage o)
    section st h ls
      | want st, not (null ls) = "" : h : ls
      | otherwise = []

    parses = srParses r
    nReadings = length parses
    shown = if oAll o then parses else take 1 parses
    readings = [ mkReading choice r s (if k == 0 then srDRS r else Nothing) | (k, s) <- zip [0 :: Int ..] shown ]
    selTree = case readings of { (rd : _) -> rdTree rd; [] -> Nothing }
    selLeaves = maybe [] dtLeaves selTree

    lexFailed = not (null (srUnknown r))
    parseFailed = not lexFailed && null parses
    meaningFailed = not (null parses) && srForm r == Nothing

    tag :: Int -> String
    tag k = if nReadings > 1 && oAll o
              then "reading " ++ show (k + 1) ++ "/" ++ show nReadings
                     ++ (if k == 0 then " [SELECTED]" else "")
              else ""

    -- 1. Tokens and supertags ------------------------------------------------
    tagLines = case choice of
      CCGBankParser m -> ccgTagLines m
      HandLexicon lx  -> handTagLines lx

    ccgTagLines m =
      [ "  " ++ padR 12 (tokText t) ++ chosenStr i t ls
          ++ concat [ "\n" ++ alt | oAll o, alt <- altLines m i t ls ]
      | (i, t, ls) <- zip3 [0 :: Int ..] (srTokens r) (lexsOf m) ]
      ++ [ "  (" ++ show nAlt ++ " further interpretable categories not shown; --all-readings lists them)"
         | not (oAll o), let nAlt = sum [ max 0 (length ls - 1) | ls <- lexsOf m ], nAlt > 0 ]
      where
        chosenStr _ t ls = case [ l | l <- selLeaves, lfSpan l == tokSpan t ] of
          (l : _) -> padR 26 (lfCat l) ++ maybe "" (printf "logP %6.2f") (lfScore l)
                       ++ "   " ++ shortSource (lfSource l)
          [] -> case ls of
            (LexSign c it s : _) -> padR 26 (show c) ++ printf "logP %6.2f" s ++ "   "
                                      ++ shortSource (itemSource m (tokText t) it) ++ "  (best tag; no selected derivation)"
            [] -> "NO INTERPRETABLE CATEGORY"
        altLines m' i t ls =
          [ "      " ++ mark c it ++ " " ++ padR 26 (show c) ++ printf "logP %6.2f" s ++ "   " ++ shortSource (itemSource m' (tokText t) it)
          | LexSign c it s <- ls ]
          ++ take 10 dropped
          ++ [ "      ... " ++ show (length dropped - 10) ++ " more offered tags without a meaning" | length dropped > 10 ]
          where
            usedCat = [ lfCat l | l <- selLeaves, lfSpan l == tokSpan t ]
            mark c it
              | [show c] == usedCat, lookupSel == Just (itemSource m' (tokText t) it) = "*  "
              | otherwise = "alt"
            lookupSel = case [ lfSource l | l <- selLeaves, lfSpan l == tokSpan t ] of { (x : _) -> Just x; [] -> Nothing }
            isName = any (\(LexSign _ it _) -> case it of { LexTerm _ "proper name" _ -> True; _ -> False }) ls
            dropped =
              [ "      --- " ++ padR 26 (show c) ++ printf "logP %6.2f" s ++ "   "
                  ++ (if isName && isN c then "read as the proper name NP above (CCGSem.nameItem)"
                      else "offered by the tagger, no meaning (dropped)")
              | (c, s) <- offeredTags m' (i == 0) (tokText t)
              , show c `notElem` [ show c' | LexSign c' _ _ <- ls ] ]
            isN (CAtom "N" _) = True
            isN _ = False

    lexsOf m = [ lexicalSigns m i (tokText t) | (i, t) <- zip [0 ..] (srTokens r) ]

    handTagLines lx =
      [ "  " ++ padR 12 (tokText u) ++ chosen ++ concat [ "\n" ++ a | oAll o, a <- alts ]
      | u <- sortOn tokSpan (M.elems (latUnits (srLattice r)) ++ srUnknown r)
      , let es = lookupWord lx (tokText u)
            chosen = case [ l | l <- selLeaves, lfSpan l == tokSpan u ] of
              (l : _) -> padR 26 (lfCat l) ++ shortSource (lfSource l)
              [] -> case es of
                (e : _) -> padR 26 (show (entryCat e)) ++ entryGloss e ++ "  (no selected derivation)"
                [] -> "NOT IN THE HAND LEXICON"
            alts = [ "      alt " ++ padR 26 (show (entryCat e)) ++ entryGloss e | length es > 1, e <- es ]
      ]

    -- 2. Derivation ----------------------------------------------------------
    derivLines
      | null parses = []
      | otherwise =
          [ "  rules: > < forward/backward application, >B <B composition, >Bx <Bx crossed"
          , "         composition, >T <T type-raising, TC unary type-change, conj/coord"
          , "         coordination, punct punctuation absorption; '= ...' is the node's meaning" ]
            ++ concat
              [ (if null (tag k) then [] else ["", "  -- " ++ tag k])
                  ++ case rdTree rd of
                       Just dt -> map ("  " ++) (renderDT dt)
                       Nothing ->
                         [ "  (could not replay the recorded rules to the root meaning; raw provenance:)" ]
                           ++ map ("  " ++) (lines (renderProvTree (H.sProv (rdSign rd))))
              | (k, rd) <- zip [0 ..] readings ]
            ++ [ "  (" ++ show (nReadings - 1) ++ " other reading(s); --all-readings shows them)"
               | nReadings > 1, not (oAll o) ]

    -- 3. Lambda --------------------------------------------------------------
    lambdaLines
      | null parses = []
      | otherwise =
          concat
            [ ("  leaves (category, Montague type catTy, lexical term, where it came from)"
                 ++ (if null (tag k) then "" else ", " ++ tag k) ++ ":")
                : concatMap leafLines (maybe [] dtLeaves (rdTree rd))
            | (k, rd) <- zip [0 ..] readings ]
            ++ concat
              [ [ "", "  β-normal form" ++ (if null (tag k) then "" else " (" ++ tag k ++ ")") ++ ":" ]
                  ++ case rdForm rd of
                       Right nf -> [ "    " ++ pretty nf
                                   , "    : " ++ either renderTypeError showTy (typeOf [] nf)
                                       ++ "   (category " ++ show (H.sCat (rdSign rd)) ++ ")" ]
                       Left why -> [ "    " ++ pretty (normalize (H.sSem (rdSign rd)))
                                   , "    TYPE ERROR: " ++ why ]
              | (k, rd) <- zip [0 ..] readings ]

    leafLines l =
      [ "    " ++ padR 10 (lfWord l) ++ padR 24 (lfCat l) ++ maybe "(no type)" showTy (lfCatTy l)
      , "      term  " ++ maybe "(structural: no meaning of its own; the coordination or punctuation rule consumes it)"
                                (\t -> pretty t ++ termTy t) (lfTerm l)
      , "      from  " ++ lfSource l ]
      where
        termTy t = case (typeOf [] t, lfCatTy l) of
          (Right ty, Just cty) | ty == cty -> ""
          (Right ty, _) -> "   [term type " ++ showTy ty ++ ": intensional parameter lifted]"
          (Left e, _) -> "   [ill-typed: " ++ renderTypeError e ++ "]"

    -- 4. DRS -----------------------------------------------------------------
    drsLines = concat
      [ (if null (tag k) then [] else ["  -- " ++ tag k])
          ++ maybe ["  (no DRS)"] (map ("  " ++) . drsBoxLines) (rdDRS rd)
      | (k, rd) <- zip [0 ..] readings, srForm r /= Nothing || k > 0 ]

    -- 5. Claims of non-selected readings (the selected one is the text's) ----
    altClaims
      | not (want SClaims) = []
      | otherwise = concat
          [ ("  [" ++ tag k ++ "]") : maybe ["  (no DRS)"] claimLines (rdDRS rd)
          | (k, rd) <- drop 1 (zip [0 ..] readings) ]

    -- 6. Failures and notes ---------------------------------------------------
    failureLines
      | lexFailed =
          [ "  stage: lexicon -- no interpretable lexical entry for "
              ++ intercalate ", " (map (show . tokText) (srUnknown r)) ]
            ++ concatMap lexWhy (srUnknown r)
            ++ [ "  stopped: no parse is attempted without a meaning for every word" ]
      | parseFailed =
          [ "  stage: parse -- no derivation to S with a meaning" ]
            ++ case choice of
                 CCGBankParser m
                   | syntacticParse m (srTokens r) ->
                       [ "  the category-only parse does reach S, so the grammar derives the string but"
                       , "  no derivation survives the semantic layer (a combination with no semantic"
                       , "  operation, an S[em] root, or a cell beam dropped it)" ]
                   | otherwise ->
                       [ "  the category-only parse does not reach S either: the supertagger's"
                       , "  categories do not combine (wrong tags, or a construction the rules lack)" ]
                 HandLexicon _ -> [ "  the application-only hand parser found no derivation to S" ]
      | meaningFailed =
          [ "  stage: meaning -- the selected derivation's term does not have its category's type" ]
            ++ [ "  " ++ l | d <- traceDiagnostics (srTrace r), diagKind d == TypeCheckFailure
                           , l <- lines (renderDiagnostic d) ]
      | nReadings > 1 =
          [ "  ambiguity: " ++ show nReadings ++ " readings with distinct meanings; reading 1 selected by "
              ++ maybe "the first-candidate rule" id
                   (case [ decWhy d | d <- traceDecisions (srTrace r), decKind d == "parse-selection" ] of
                      (w : _) -> Just w
                      [] -> Nothing)
          , "  (not resolved linguistically; --all-readings shows every reading)" ]
      | otherwise = []

    lexWhy t = case choice of
      CCGBankParser m ->
        let i = length (takeWhile ((/= tokSpan t) . tokSpan) (srTokens r))
            offered = offeredTags m (i == 0) (tokText t)
        in [ "    " ++ show (tokText t) ++ ": the tagger offered "
               ++ (if null offered then "nothing" else intercalate ", " (map (show . fst) (take 8 offered))
                     ++ (if length offered > 8 then ", ..." else ""))
               ++ "; none has a closed-class entry or an open-class template" ]
      HandLexicon _ -> [ "    " ++ show (tokText t) ++ ": not in the hand lexicon (try without --hand)" ]

    noteLines =
      [ "  " ++ l | d <- traceDecisions (srTrace r), decKind d /= "parse-selection"
                  , l <- lines (renderDecision d) ]
      ++ [ "  " ++ l | d <- traceDiagnostics (srTrace r)
                     , diagKind d `notElem` [TypeCheckFailure, ParseAmbiguity, NoParse]
                     , l <- lines (renderDiagnostic d) ]

--------------------------------------------------------------------------------
-- Readings: replay, type check, DRS
--------------------------------------------------------------------------------

mkReading :: ParserChoice -> SentenceResult -> H.Sign -> Maybe DRS -> Reading
mkReading choice r s pipelineDRS = Reading s tree form drs
  where
    tree = case choice of
      CCGBankParser m -> replayCCG m (srTokens r) s
      HandLexicon lx  -> replayHand lx s
    form = case typeOf [] (H.sSem s) of
      Right t | t == catTy (H.sCat s) -> Right (normalize (H.sSem s))
              | otherwise -> Left ("meaning has type " ++ showTy t ++ " but category "
                                     ++ show (H.sCat s) ++ " demands " ++ showTy (catTy (H.sCat s)))
      Left e -> Left (renderTypeError e)
    -- The selected reading's DRS is the pipeline's own. Others are built with
    -- the same exported steps the pipeline's back end runs.
    drs = case (pipelineDRS, form) of
      (Just d, _) -> Just d
      (Nothing, Right nf) -> Just (localDRS choice r s nf)
      _ -> Nothing

localDRS :: ParserChoice -> SentenceResult -> H.Sign -> Term -> DRS
localDRS choice r s nf = case choice of
  HandLexicon lx ->
    fst (projectPresuppositions (toDRS (buildProvIndex lx (H.sProv s)) (H.sProv s) nf))
  CCGBankParser m ->
    let toks = srTokens r
        spans = [ sp | (_, sp, _) <- provLeaves (H.sProv s) ]
        idx = M.fromList
          [ (c, ProvLex (SourceId "input") (tokSpan t) (tokText t))
          | (i, t) <- zip [0 ..] toks, tokSpan t `elem` spans
          , LexSign _ (LexTerm tm _ _) _ <- lexicalSigns m i (tokText t)
          , c <- constNames tm ]
        (d1, _) = resolveLocalAnaphora idx (toDRS idx (H.sProv s) nf)
    in fst (projectPresuppositions d1)

-- | A chart candidate during replay.
data Cand = Cand
  { cCat    :: CCat
  , cSem    :: Term
  , cCoord  :: Maybe String
  , cStruct :: Maybe String
  , cTree   :: DT
  }

finish :: Term -> Term
finish = simplifyConj . normalize

-- | Replay a CCGbank-parser root's provenance tree. Each node's candidates are
-- those its recorded rule licenses over its children's candidates, with the
-- semantic operation 'NL2Proof.Syntax.CCGSemParse' attaches to that rule. A
-- replay counts only if it ends in the root's own meaning.
replayCCG :: SemModel -> [Token] -> H.Sign -> Maybe DT
replayCCG m toks s =
  case [ cTree c | c <- go (H.sProv s), unifiable (cCat c) (CAtom "S" [])
                 , canonicalAC (cSem c) == target ] of
    (t : _) -> Just t
    [] -> Nothing
  where
    target = canonicalAC (H.sSem s)

    go p = dedupe (node p)
    dedupe cs = M.elems (M.fromListWith (\_ old -> old)
                  [ ((show (cCat c), canonicalAC (cSem c), cCoord c, cStruct c), c) | c <- cs ])

    node (ProvLex _ sp w) =
      case [ i | (i, t) <- zip [0 :: Int ..] toks, tokSpan t == sp ] of
        (i : _) -> [ leafCand w sp c it sc | LexSign c it sc <- lexicalSigns m i w ]
        [] -> []
    node (ProvRule (RuleName rn) [p])
      | "unary " `isPrefixOf` rn =
          let tgt = drop 6 rn
          in [ Cand to (finish (f (cSem x))) Nothing Nothing
                    (DRule (unaryLabel fr to) (show to) (Just (finish (f (cSem x)))) [cTree x])
             | x <- go p, cCoord x == Nothing, cStruct x == Nothing
             , (fr, to) <- nub (rUnary (smRules m)), show to == tgt
             , unifiable (cCat x) fr
             , Just (f, _) <- [unarySem (cCat x) to] ]
    node (ProvRule (RuleName rn) [pl, pr]) =
      [ c | l <- go pl, r <- go pr
          , (comb, out) <- combineNamed allCombinators (cCat l) (cCat r)
          , show comb == rn
          , Just c <- [semComb comb out l r] ]
    node _ = []

    leafCand w sp c it sc = case it of
      LexTerm tm _ _ ->
        Cand c (finish tm) Nothing Nothing
          (DLex (Leaf w sp (show c) (semTy c) (Just (finish tm)) (itemSource m w it) (Just sc)))
      LexStructural _ ->
        Cand c (Con w TyT) Nothing (Just w)
          (DLex (Leaf w sp (show c) (semTy c) Nothing (itemSource m w it) (Just sc)))

-- | The semantic operation of each combinator, as in
-- 'NL2Proof.Syntax.CCGSemParse' (whose own copy is not exported).
semComb :: Combinator -> CCat -> Cand -> Cand -> Maybe Cand
semComb comb out l r = sem >>= emGuard
  where
    plain x = cCoord x == Nothing && cStruct x == Nothing
    kids = [cTree l, cTree r]
    mk tm coord = let t = finish tm in Cand out t coord Nothing (DRule (combLabel comb) (show out) (Just t) kids)

    sem = case comb of
      FwdApp   | plain l, plain r -> Just (mk (applyIntensional (cSem l) (cSem r)) Nothing)
      BwdApp   | plain l, plain r -> Just (mk (applyIntensional (cSem r) (cSem l)) Nothing)
      FwdComp  | plain l, plain r -> compose (cSem l) (cSem r) (argOf r)
      FwdXComp | plain l, plain r -> compose (cSem l) (cSem r) (argOf r)
      BwdComp  | plain l, plain r -> compose (cSem r) (cSem l) (argOf l)
      BwdXComp | plain l, plain r -> compose (cSem r) (cSem l) (argOf l)
      CoordMark
        | Just w <- cStruct l, isCoordinator (cCat l), plain r -> Just (mk (cSem r) (Just w))
      CoordApply
        | plain l, Just w <- cCoord r, Just op <- coordinatorOp w
        , Just ty <- semTy out, Just tm <- coordTerm op ty (cSem l) (cSem r) -> Just (mk tm Nothing)
      PunctRight
        | isPunct (cCat r), Just _ <- cStruct r, cStruct l == Nothing -> Just (keep l)
      PunctLeft
        | isPunct (cCat l), Just _ <- cStruct l, cStruct r == Nothing, cCoord r == Nothing -> Just (keep r)
      _ -> Nothing

    keep x = x { cTree = DRule (combLabel comb) (show (cCat x)) (Just (cSem x)) kids }
    argOf x = case cCat x of
      CSlash _ _ z _ -> semTy z
      _              -> Nothing
    compose f g (Just zTy) = Just (mk (composeTerm zTy f g) Nothing)
    compose _ _ Nothing = Nothing

    emGuard x
      | cStruct x == Nothing
      , any mentionsEm [cCat l, cCat r, cCat x] || any (isIntensionalTerm . cSem) [l, r]
      , Just ty <- semTy (cCat x) =
          case typeOf [] (cSem x) of
            Right t | t `liftsTo` ty -> Just x
            _                        -> Nothing
      | otherwise = Just x

mentionsEm :: CCat -> Bool
mentionsEm (CAtom "S" fs)   = Feat "em" `elem` fs
mentionsEm (CAtom _ _)      = False
mentionsEm (CSlash _ a b _) = mentionsEm a || mentionsEm b

combLabel :: Combinator -> String
combLabel c = case c of
  FwdApp     -> ">"
  BwdApp     -> "<"
  FwdComp    -> ">B"
  BwdComp    -> "<B"
  FwdXComp   -> ">Bx"
  BwdXComp   -> "<Bx"
  CoordMark  -> "conj"
  CoordApply -> "coord"
  PunctRight -> "punct"
  PunctLeft  -> "punct"

unaryLabel :: CCat -> CCat -> String
unaryLabel fr to = case to of
  CSlash d1 _ (CSlash d2 _ _ _) _ | d1 /= d2 -> if d1 == Fwd then ">T" else "<T"
  _ -> "TC " ++ show fr ++ " => " ++ show to

-- | Replay a hand-parser root: the hand rules build the whole sign, so the
-- replay is the rules themselves.
replayHand :: Lexicon -> H.Sign -> Maybe DT
replayHand lx s =
  case [ t | (sg, t) <- go (H.sProv s), alphaEq (normalize (H.sSem sg)) target ] of
    (t : _) -> Just t
    [] -> Nothing
  where
    target = normalize (H.sSem s)
    go p = case p of
      ProvLex _ sp w ->
        [ (H.Sign (entryCat e) (entrySem e) p
          , DLex (Leaf w sp (show (entryCat e)) (Just (catTy (entryCat e))) (Just (normalize (entrySem e)))
                       ("hand lexicon entry (Syntax.Lexicon): " ++ entryGloss e) Nothing))
        | e <- lookupWord lx w ]
      ProvRule (RuleName rn) [pl, pr] | Just rule <- lookup rn handRules ->
        [ (sg, DRule rn (show (H.sCat sg)) (Just (normalize (H.sSem sg))) [tl, tr])
        | (l, tl) <- go pl, (r, tr) <- go pr, sg <- rule l r ]
      _ -> []
    handRules = [(">", H.fwdApp), ("<", H.bwdApp), (">B", H.fwdComp), ("<B", H.bwdComp)]

-- | Where a CCGbank-path lexical meaning comes from (mirrors the branch in
-- 'lexicalSigns').
itemSource :: SemModel -> String -> LexItem -> String
itemSource _ w it = case it of
  LexStructural g -> "closed-class (structural): " ++ g
  LexTerm _ gloss _
    | isClosedClass w || all (`elem` ".,;:!?\"'()") w ->
        "closed-class entry (CCGSem table, keyed by word+category): " ++ gloss
    | gloss == "proper name" -> "proper name (CCGSem.nameItem; POS dictionary says NNP)"
    | otherwise -> "open-class template (CCGSem, by category shape): " ++ gloss

shortSource :: String -> String
shortSource s
  | "closed-class (structural)" `isPrefixOf` s = "[closed: structural]"
  | "closed-class" `isPrefixOf` s = "[closed]"
  | "proper name" `isPrefixOf` s = "[name]"
  | "open-class" `isPrefixOf` s = "[open template]"
  | otherwise = "[hand]"

--------------------------------------------------------------------------------
-- Pretty-printing
--------------------------------------------------------------------------------

renderDT :: DT -> [String]
renderDT = go "" ""
  where
    go first rest t = case t of
      DLex l -> [ first ++ "[lex] " ++ lfCat l ++ "  " ++ show (lfWord l) ]
      DRule rule c sem ks ->
        (first ++ "[" ++ rule ++ "] " ++ c ++ "  " ++ show (surface t))
          : [ rest ++ "|     = " ++ pretty m | Just m <- [sem], not (null ks) ]
          ++ concat [ go (rest ++ (if lastK then "`- " else "+- ")) (rest ++ (if lastK then "   " else "|  ")) k
                    | (j, k) <- zip [1 :: Int ..] ks, let lastK = j == length ks ]
    surface t = unwords (map lfWord (dtLeaves t))

claimLines :: DRS -> [String]
claimLines d =
  [ "  rule: only top-level conditions of the main box are asserted; whatever sits inside"
  , "        ~, =>, OR, an attitude box (K) or a presupposition box is not."
  , "  Asserted:" ] ++ orNone [ "    " ++ renderCanonCond (claimCond c) | (c, _) <- as ]
  ++ [ "  Reported:" ] ++ orNone
       [ "    " ++ renderCanonCond (reportedContent rp) ++ "    source chain: "
           ++ intercalate " > " (map renderAttribution (reportedChain rp))
       | rp <- rs ]
  ++ [ "  Presupposed:" ] ++ orNone [ "    " ++ renderCanonCond (claimCond (presupposedClaim' p)) | p <- ps ]
  ++ [ "  Embedded (not asserted, cannot reach an oracle):" ]
  ++ orNone [ "    " ++ renderCanonCond (claimCond e) | e <- es ]
  where
    (as, rs, ps, es) = splitClaims d
    orNone [] = ["    (none)"]
    orNone xs = xs

showTy :: Ty -> String
showTy t = case show t of
  ('(' : s) | not (null s), last s == ')', balanced (init s) -> init s
  s -> s
  where
    balanced = all (>= 0) . scanl (\n c -> if c == '(' then n + 1 else if c == ')' then n - 1 else n) (0 :: Int)

padR :: Int -> String -> String
padR n s = s ++ replicate (max 1 (n - length s)) ' '
