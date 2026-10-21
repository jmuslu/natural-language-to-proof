-- | @nl2proof-explain@: every stage of the pipeline for one sentence (or a
-- short text), side by side, for checking hand derivations against the
-- system.
--
-- > nl2proof-explain "Bob says that the cat is not red."
-- > nl2proof-explain                 -- REPL; the CCGbank model is loaded once
-- > nl2proof-explain --all-readings --stage=deriv --hand "..."
--
-- Sections: 1 tokens + supertags, 2 derivation, 3 lambda, 4 DRS, 5 claims,
-- 6 failures / notes, 7 support graph.
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
--
-- Section 7 is the evidence view of the whole text: every admitted claim as a
-- node of a 'G.Genealogy' (through the typed admission functions), detachment
-- justifications licensed by 'F.detachable', and the support labels and
-- source withdrawals the library computes. The tool adds no support rule of
-- its own; it only relabels each provenance leaf with its sentence number, so
-- that a sentence is a withdrawable source.
module Main (main) where

import Control.Exception (SomeException, evaluate, try)
import Control.Monad (when)
import Data.Char (isSpace)
import Data.List (find, intercalate, isPrefixOf, nub, sortOn)
import qualified Data.Map as M
import GHC.Clock (getMonotonicTime)
import System.Environment (getArgs)
import System.Exit (exitFailure, exitSuccess)
import System.IO (hFlush, hPutStrLn, isEOF, stderr, stdout)
import Text.Printf (printf)

import NL2Proof.DRT.Build
import NL2Proof.DRT.Canonical (CanonCond(..), Canonical(..), renderCanonCond)
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
import qualified NL2Proof.Fusion as F
import qualified NL2Proof.Genealogy as G
import NL2Proof.Verify.ClaimKind (claimCond)
import NL2Proof.Verify.Oracle (Confirmed, Oracle(..), Verdict(Unknown), confirm)
import NL2Proof.Verify.Reported

--------------------------------------------------------------------------------
-- Options
--------------------------------------------------------------------------------

data Stage = STags | SDeriv | SLambda | SDrs | SClaims | SGraph
  deriving (Eq, Show)

stageName :: Stage -> String
stageName st = case st of
  STags -> "tags"
  SDeriv -> "deriv"
  SLambda -> "lambda"
  SDrs -> "drs"
  SClaims -> "claims"
  SGraph -> "graph"

-- | Which oracle section 7 consults. 'OracleNone' grounds nothing.
-- 'OracleConfirmAsserted' is an in-process test oracle that covers and holds
-- every condition; it is offered only top-level asserted claims, through
-- 'confirm', which itself abstains on open (context-bound) conditions.
data OracleMode = OracleNone | OracleConfirmAsserted
  deriving (Eq, Show)

oracleModeName :: OracleMode -> String
oracleModeName m = case m of
  OracleNone -> "none"
  OracleConfirmAsserted -> "confirm-asserted"

parseOracleMode :: String -> Maybe OracleMode
parseOracleMode s = case s of
  "none" -> Just OracleNone
  "confirm-asserted" -> Just OracleConfirmAsserted
  _ -> Nothing

-- | "s3" or "3" -> 3 (sentences are numbered from 1).
parseSentenceNo :: String -> Maybe Int
parseSentenceNo s = case dropWhile (== 's') (take 1 s) ++ drop 1 s of
  ds | not (null ds), all (`elem` ['0' .. '9']) ds, length ds < 7, read ds > (0 :: Int) -> Just (read ds)
  _ -> Nothing

data Opts = Opts
  { oAll   :: Bool
  , oStage :: Maybe Stage
  , oHand  :: Bool
  , oPOSBackoff :: Bool
  , oEitherPolicy :: Maybe EitherPolicy
  , oNominalPolicy :: Maybe NominalNounPolicy
  , oOracle :: Maybe OracleMode
  , oRetract :: [Int]
  , oText  :: [String]
  }

usage :: String
usage = unlines
  [ "usage: nl2proof-explain [--all-readings] [--stage=tags|deriv|lambda|drs|claims|graph] [--hand] [--pos-backoff] [--either-policy=POLICY] [--nominal-policy=POLICY] [--oracle=MODE] [--retract=sN ...] [TEXT]"
  , ""
  , "  TEXT            a sentence or short text; omitted: interactive REPL (:q quits)"
  , "  --all-readings  every reading (and every candidate supertag), selected one marked"
  , "  --stage=S       only one section: tags, deriv, lambda, drs, claims or graph"
  , "  --hand          hand-written fragment lexicon (attitudeLexicon) instead of CCGbank"
  , "  --pos-backoff   experimental POS-dictionary lexical backoff (CCGbank only)"
  , "  --either-policy=legacy-disabled|surface-inclusive-v1 (CCGbank only; default disabled)"
  , "  --nominal-policy=known-only|context-unknown (CCGbank only; default known-only)"
  , "  --oracle=none|confirm-asserted  section 7 oracle (default none: nothing is grounded);"
  , "                  confirm-asserted confirms every closed top-level asserted claim"
  , "  --retract=sN    section 7: withdraw sentence N as a source and show the graph again"
  , "                  (repeatable)"
  , ""
  , "CCGbank: $CCGBANK_DIR, else ~/ccgbank/ccgbank_1_1/data (sections 02-21)."
  , "REPL commands: :q quit, :all toggle --all-readings, :stage=S or :stage=all,"
  , "  :oracle=MODE (or :oracle MODE), :retract N (adds sN), :retract none, :help"
  ]

parseStage :: String -> Maybe (Maybe Stage)
parseStage s = case s of
  "tags"   -> Just (Just STags)
  "deriv"  -> Just (Just SDeriv)
  "lambda" -> Just (Just SLambda)
  "drs"    -> Just (Just SDrs)
  "claims" -> Just (Just SClaims)
  "graph"  -> Just (Just SGraph)
  "all"    -> Just Nothing
  _        -> Nothing

parseOpts :: [String] -> Either String Opts
parseOpts = go (Opts False Nothing False False Nothing Nothing Nothing [] [])
  where
    go o []
      | oHand o, Just _ <- oEitherPolicy o = Left "--either-policy is incompatible with --hand"
      | oHand o, Just _ <- oNominalPolicy o = Left "--nominal-policy is incompatible with --hand"
      | otherwise = Right o { oText = reverse (oText o), oRetract = reverse (oRetract o) }
    go o (a : as)
      | a == "--all-readings" = go o { oAll = True } as
      | a == "--hand" = go o { oHand = True } as
      | a == "--pos-backoff" = go o { oPOSBackoff = True } as
      | "--either-policy=" `isPrefixOf` a = case oEitherPolicy o of
          Just _ -> Left "duplicate --either-policy"
          Nothing -> case drop 16 a of
            "legacy-disabled" -> go o { oEitherPolicy = Just EitherLegacyDisabled } as
            "surface-inclusive-v1" -> go o { oEitherPolicy = Just EitherSurfaceInclusiveV1 } as
            value -> Left ("unknown either policy: " ++ value)
      | "--nominal-policy=" `isPrefixOf` a = case oNominalPolicy o of
          Just _ -> Left "duplicate --nominal-policy"
          Nothing -> case drop 17 a of
            "known-only" -> go o { oNominalPolicy = Just KnownNounsOnly } as
            "context-unknown" -> go o { oNominalPolicy = Just ContextUnknownNouns } as
            value -> Left ("unknown nominal policy: " ++ value)
      | "--oracle=" `isPrefixOf` a = case oOracle o of
          Just _ -> Left "duplicate --oracle"
          Nothing -> case parseOracleMode (drop 9 a) of
            Just m -> go o { oOracle = Just m } as
            Nothing -> Left ("unknown oracle mode: " ++ drop 9 a)
      | "--retract=" `isPrefixOf` a = case parseSentenceNo (drop 10 a) of
          Just k | k `elem` oRetract o -> Left ("duplicate --retract=s" ++ show k)
                 | otherwise -> go o { oRetract = k : oRetract o } as
          Nothing -> Left ("--retract expects a sentence number such as s2, not: " ++ drop 10 a)
      | "--stage=" `isPrefixOf` a = case parseStage (drop 8 a) of
          Just st -> go o { oStage = st } as
          Nothing -> Left ("unknown stage: " ++ drop 8 a)
      | a == "--help" || a == "-h" = Left ""
      | "--" `isPrefixOf` a = Left ("unknown flag: " ++ a)
      | otherwise = go o { oText = a : oText o } as

-- Shared by the real CLI and corpus-free option/configuration controls.
configureModel :: Opts -> SemModel -> SemModel
configureModel opts model = model
  { smPOSBackoff = oPOSBackoff opts
  , smEitherPolicy = maybe EitherLegacyDisabled id (oEitherPolicy opts)
  , smNominalPolicy = maybe KnownNounsOnly id (oNominalPolicy opts)
  }

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
        pure (CCGBankParser (configureModel opts m))
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
            | ":oracle" `isPrefixOf` l -> case parseOracleMode (trim (drop 1 (dropWhile (\c -> c /= '=' && c /= ' ') l))) of
                Just m -> putStrLn ("oracle " ++ oracleModeName m) >> loop o { oOracle = Just m }
                Nothing -> putStrLn "usage: :oracle none|confirm-asserted" >> loop o
            | ":retract" `isPrefixOf` l -> case trim (drop 8 l) of
                v | v `elem` ["none", "clear"] -> putStrLn "retract: none" >> loop o { oRetract = [] }
                v | Just k <- parseSentenceNo v -> do
                      let rs = nub (oRetract o ++ [k])
                      putStrLn ("retract: " ++ unwords [ 's' : show r | r <- rs ])
                      loop o { oRetract = rs }
                _ -> putStrLn "usage: :retract N (withdraw sentence N; repeatable) or :retract none" >> loop o
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
explain choice o text = unlines (executionLines ++ concat (perSentence ++ [discourseDRS, claims, failures, graph]))
  where
    -- Identify the actual parser, never a requested option that was not applied.
    executionLines = case choice of
      CCGBankParser model
        | not (null (policyLines model)) -> header "EXECUTION POLICY" : policyLines model
      _ -> []
    policyLines model =
      [ "  either-policy: surface-inclusive-v1 (optional inclusive construction)"
      | smEitherPolicy model == EitherSurfaceInclusiveV1 ]
      ++ [ "  nominal-policy: context-unknown (context-licensed unknown common nouns)"
         | smNominalPolicy model == ContextUnknownNouns ]
    pr = runPipelineWith choice (SourceId "input") text
    srs = prSentences pr
    multi = length srs > 1
    xs = [ explainSentence choice o r | r <- srs ]
    want st = maybe True (== st) (oStage o)

    perSentence =
      [ (if multi && oStage o /= Just SGraph then ["", "### sentence " ++ show k ++ "/" ++ show (length srs) ++ ": "
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

    graph
      | not (want SGraph) || null srs = []
      | otherwise = "" : header "7. SUPPORT GRAPH (Genealogy support labels, Fusion.detachable)"
                       : supportGraphLines o pr

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
    readings = map (mkReading choice r) shown
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
      | any ((== OriginLoweringFailure) . diagKind) (traceDiagnostics (srTrace r)) =
          [ "  stage: origin lowering -- typed selected reading has no DRS" ]
            ++ [ "  " ++ l | d <- traceDiagnostics (srTrace r), diagKind d == OriginLoweringFailure
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

mkReading :: ParserChoice -> SentenceResult -> H.Sign -> Reading
mkReading choice r s = Reading s tree form drs
  where
    tree = case choice of
      CCGBankParser m -> replayCCG m (srTokens r) s
      HandLexicon lx  -> replayHand lx s
    shared = find ((== s) . rrSign) (srReadings r)
    -- The same translated reading feeds display and solver export. Replaying
    -- syntax for the tree above never reconstructs a second semantic meaning.
    form = case shared of
      Just reading -> case rrForm reading of
        Just nf -> Right nf
        Nothing -> Left (intercalate "; " (map diagMsg (traceDiagnostics (rrTrace reading))))
      Nothing -> Left "candidate absent from shared pipeline readings"
    drs = shared >>= rrDRS

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
    | gloss == "proper name" -> "proper name (CCGSem.nameItem; POS/casing policy, see name-lexicon decision)"
    | otherwise -> "open-class template (CCGSem, by category shape): " ++ gloss

shortSource :: String -> String
shortSource s
  | "closed-class (structural)" `isPrefixOf` s = "[closed: structural]"
  | "closed-class" `isPrefixOf` s = "[closed]"
  | "proper name" `isPrefixOf` s = "[name]"
  | "open-class" `isPrefixOf` s = "[open template]"
  | otherwise = "[hand]"

--------------------------------------------------------------------------------
-- 7. Support graph
--------------------------------------------------------------------------------

-- | The in-process test oracle behind @--oracle=confirm-asserted@. It covers
-- and confirms whatever it is asked; what keeps the result honest is what it
-- is asked and how: only top-level asserted claims are offered, through
-- 'confirm', whose coverage check abstains on open (context-bound)
-- conditions. Reported, presupposed and embedded content cannot be offered to
-- it at all ('confirm' rejects those claim kinds at compile time).
testOracle :: Oracle
testOracle = Oracle
  { oracleName = "explain-test"
  , oracleDomain = "every closed top-level asserted claim of the input (a test oracle, not a source of truth)"
  , oracleCovers = const True
  , oracleHolds = const True
  }

sentenceSource :: Int -> SourceId
sentenceSource k = SourceId ('s' : show k)

-- | Relabel every provenance leaf with the sentence whose span covers it, so
-- that each sentence is a separate withdrawable source. A leaf outside every
-- sentence keeps its source.
relabelProv :: [(Int, Span)] -> Prov -> Prov
relabelProv spans = go
  where
    go p = case p of
      ProvLex src sp w -> ProvLex (case [ k | (k, s) <- spans, spanCovers s sp ] of
                                     (k : _) -> sentenceSource k
                                     [] -> src) sp w
      ProvRule r ks -> ProvRule r (map go ks)

relabelDRS :: (Prov -> Prov) -> DRS -> DRS
relabelDRS f (DRS us cs) = DRS [ (r, f p) | (r, p) <- us ] (map cond cs)
  where
    box = relabelDRS f
    cond c = case c of
      CPred n ts p -> CPred n ts (f p)
      CEq a b p -> CEq a b (f p)
      CNot d p -> CNot (box d) (f p)
      CImp a b p -> CImp (box a) (box b) (f p)
      COr a b p -> COr (box a) (box b) (f p)
      CAtt v hs d p -> CAtt v hs (box d) (f p)
      CPresup d p -> CPresup (box d) (f p)

detachRule :: String
detachRule = "modus ponens, Fusion.detachable"

-- | Section 7. Claims come from 'splitClaims' on the discourse DRS (the same
-- split as section 5); each distinct claim is one node, and repeated
-- admissions of it are alternative evidence at that node. Rules detach by
-- 'F.detachable' over all admitted claims, as 'G.derivation' justifications
-- from the rule node and its antecedent nodes; 'G.supportLabels' then decides
-- every label and 'G.withdrawSource' every retraction.
supportGraphLines :: Opts -> PipelineResult -> [String]
supportGraphLines o pr =
  [ "  legend: GROUNDED = some support set is oracle-confirmed evidence only; WEAK = supported, but every set needs unconfirmed, reported or presupposed evidence"
  , "  oracle: " ++ oracleLine ]
  ++ [ "  sentences (each is a source):" ]
  ++ [ "    " ++ padR 4 ('s' : show k) ++ show (sentText (srSentence r))
         ++ (if srDRS r == Nothing then "   UNPARSED (no DRS; see section 6)" else "")
     | (k, r) <- zip [1 :: Int ..] srs ]
  ++ [ "  partial: " ++ show (length unparsed) ++ " sentence(s) unparsed; their claims are missing, so the conclusions below are partial"
     | not (null unparsed) ]
  ++ graphBody graph0 [] Nothing
  ++ [ "  embedded mentions (inside ~, =>, OR; never evidence by themselves): "
         ++ intercalate ", " (nub [ renderCanonCond (claimCond e) | e <- es ])
     | not (null es) ]
  ++ certifiedLines []
  ++ retractionLines
  where
    srs = prSentences pr
    nSent = length srs
    spans = [ (k, sentSpan (srSentence r)) | (k, r) <- zip [1 :: Int ..] srs ]
    unparsed = [ k | (k, r) <- zip [1 :: Int ..] srs, srDRS r == Nothing ]
    (as, rs, ps, es) = splitClaims (relabelDRS (relabelProv spans) (dscDRS (prDiscourse pr)))
    mode = maybe OracleNone id (oOracle o)

    oracleLine = case mode of
      OracleNone -> "none -- no claim is offered to an oracle, so nothing is grounded (try --oracle=confirm-asserted)"
      OracleConfirmAsserted ->
        "confirm-asserted -- test oracle '" ++ oracleName testOracle ++ "' via Oracle.confirm: "
          ++ show (length tokens) ++ " of " ++ show (length as) ++ " top-level asserted claim(s) confirmed"
          ++ (if length tokens < length as then " (the rest are open, context-bound conditions: confirm abstains)" else "")

    -- One node per distinct claim, numbered in order of first admission.
    admittedClaims = nub ([ claimCond c | (c, _) <- as ] ++ map reportedContent rs
                           ++ map (claimCond . presupposedClaim') ps)
    idOf = M.fromList (zip admittedClaims (map G.NodeId [0 ..]))
    nid c = M.findWithDefault (G.NodeId (-1)) c idOf

    tokens :: [(CanonCond, Confirmed, [SourceId])]
    tokens = [ (claimCond c, t, provSources p)
             | mode == OracleConfirmAsserted, (c, p) <- as, Just t <- [confirm testOracle c] ]

    admitted = foldl (flip ($)) G.emptyGenealogy $
         [ G.addAssertedNode (nid (claimCond c)) p c | (c, p) <- as ]
      ++ [ G.addConfirmedNode (nid (claimCond cl)) p t
         | mode == OracleConfirmAsserted, (cl, p) <- as, Just t <- [confirm testOracle cl] ]
      ++ [ G.addReportedNode (nid (reportedContent r)) r | r <- rs ]
      ++ [ G.addPresupposedNode (nid (claimCond (presupposedClaim' x))) x | x <- ps ]

    graph0 = detachAll admitted (length admittedClaims)

    -- Add one detachment justification at a time until none is new. Every
    -- detached condition is a subcondition of an existing claim, so this ends.
    detachAll g next =
      let claimIds = M.fromList [ (G.nodeClaim n, G.nodeId n) | n <- M.elems (G.gNodes g) ]
          pending = [ (c, ants)
                  | n <- M.elems (G.gNodes g), rule@(CanImp a _) <- [G.nodeClaim n]
                  , c <- F.detachable (M.keys claimIds) rule
                  , Just antes <- [mapM (`M.lookup` claimIds) (canonConds a)]
                  , let ants = G.nodeId n : antes
                  , case M.lookup c claimIds of
                      Just t -> G.derivation t detachRule ants `notElem` G.gJusts g
                      Nothing -> True ]
          provOf ants = provRule "detachment" [ G.nodeProv n | a <- ants, Just n <- [G.nodeAt g a] ]
      in case pending of
           [] -> g
           ((c, ants) : _) -> case M.lookup c claimIds of
             Just t -> detachAll (G.addJustification (G.derivation t detachRule ants) g) next
             Nothing ->
               let t = G.NodeId next
               in detachAll (G.addJustification (G.derivation t detachRule ants)
                               (G.addNode (G.Node t c (provOf ants)) Unknown g)) (next + 1)

    derivedOnly g = [ n | n <- M.elems (G.gNodes g), G.nodeClaim n `notElem` admittedClaims ]
    admittedNodes g = [ n | n <- M.elems (G.gNodes g), G.nodeClaim n `elem` admittedClaims ]

    -- The node list, once for the text and once after withdrawal (marks).
    graphBody g withdrawn marks =
      (if null (admittedNodes g) then ["  admitted claims: (none)"]
       else "  admitted claims:" : concatMap (nodeLines g withdrawn marks True) (admittedNodes g))
      ++ (if null (derivedOnly g) then ["  derived by detachment: (none)"]
          else ("  derived by detachment (" ++ detachRule ++ "):") : concatMap (nodeLines g withdrawn marks False) (derivedOnly g))

    nodeLines g withdrawn marks isAdmitted n =
      [ "    " ++ padR 4 (show i) ++ renderCanonCond (G.nodeClaim n) ++ "   [" ++ status ++ "]"
          ++ maybe "" (\f -> f i) marks ]
      ++ [ "          evidence  " ++ e | isAdmitted, e <- evidenceOf withdrawn (G.nodeClaim n) ]
      ++ [ "          also derived from " ++ ants | isAdmitted, ants <- derivs ]
      ++ [ "          from      " ++ ants | not isAdmitted, ants <- derivs ]
      ++ [ "          support   " ++ renderSourceSets envs
         , "          sets      " ++ renderEnvs envs ]
      where
        i = G.nodeId n
        envs = supportEnvironments (G.supportOf g i)
        status
          | G.isGrounded g i = "GROUNDED"
          | not (null envs) = "WEAK"
          | otherwise = "UNSUPPORTED"
        derivs = [ intercalate " + " (map (renderNodeRef g) (G.jAntecedents j))
                 | j <- G.justificationsFor g i, not (null (G.jAntecedents j)) ]

    -- What was admitted at a node, from the admission inputs themselves.
    evidenceOf withdrawn c =
      [ ev (provSources p) "asserted-unconfirmed" | (cl, p) <- as, claimCond cl == c ]
      ++ [ ev srcs ("oracle-confirmed (" ++ oracleName testOracle ++ ")") | (c', _, srcs) <- tokens, c' == c ]
      ++ [ ev (provSources (reportedProv r)) ("reported, source chain "
             ++ intercalate " > " (map renderAttribution (reportedChain r)))
         | r <- rs, reportedContent r == c ]
      ++ [ ev (provSources (presupposedProv x)) "presupposed"
         | x <- ps, claimCond (presupposedClaim' x) == c ]
      where
        ev srcs what = sentencesOf srcs ++ " " ++ what
          ++ (if any (`elem` map sentenceSource withdrawn) srcs then "   (withdrawn)" else "")

    sentencesOf srcs = case [ s | s@(SourceId ('s' : d : _)) <- srcs, d `elem` ['0' .. '9'] ] of
      [] -> "(no sentence source)"
      ss -> intercalate "+" (map show (nub ss))

    renderNodeRef g a = show a ++ maybe "" (\n -> case G.nodeClaim n of
                                                    CanImp _ _ -> " (rule)"
                                                    _ -> "") (G.nodeAt g a)

    renderSourceSets envs = case supportEnvironments (supportFromEnvironments (map (concatMap G.evidenceSources) envs)) of
      [] -> "(none: no sufficient set of sources)"
      sets -> intercalate " | " [ "{" ++ intercalate ", " (map show ss) ++ "}" | ss <- sets ]

    renderEnvs envs
      | null envs = "(none)"
      | otherwise = intercalate " | " [ "{" ++ intercalate ", " (map renderToken env) ++ "}" | env <- envs ]
    renderToken e = show (G.evidenceNode e) ++ ":" ++ classShort (G.evidenceClass e) ++ "@" ++ sentencesOf (G.evidenceSources e)
    classShort k = case k of
      G.OracleConfirmed _ -> "oracle"
      G.AssertedUnconfirmed -> "asserted"
      G.ReportedEvidence _ -> "reported"
      G.PresupposedEvidence -> "presupposed"
      G.LLMTranslatedEvidence _ -> "translated"

    -- Fusion's certified view: the oracle's Confirmed tokens (those whose
    -- sources are not withdrawn), fused and closed by detachment. Printed as a
    -- cross-check: its claims should be exactly the graph's grounded ones.
    certifiedLines withdrawn
      | mode /= OracleConfirmAsserted = []
      | otherwise =
          [ "  certified base (Fusion.fuse over the Confirmed tokens, closed by Fusion.entailedWithSupport):" ]
          ++ (if M.null entailed then ["    (empty)"] else
               [ "    " ++ renderCanonCond c ++ (if F.fusedContains fused c then "   confirmed" else "   entailed")
               | c <- M.keys entailed ])
          ++ [ "  NOTE: Fusion and the graph disagree on: " ++ intercalate ", " (map renderCanonCond diff)
             | not (null diff) ]
      where
        fused = F.fuse [ t | (_, t, srcs) <- tokens, not (any (`elem` map sentenceSource withdrawn) srcs) ]
        entailed = F.entailedWithSupport fused
        g = if null withdrawn then graph0 else graphR
        groundedClaims = [ G.nodeClaim n | n <- M.elems (G.gNodes g), G.isGrounded g (G.nodeId n) ]
        diff = [ c | c <- nub (groundedClaims ++ M.keys entailed)
                   , (c `elem` groundedClaims) /= M.member c entailed ]

    -- Retraction ------------------------------------------------------------
    (valid, missing) = (filter (<= nSent) (oRetract o), filter (> nSent) (oRetract o))
    (graphR, changes) = foldl step (graph0, []) valid
      where step (g, cs) k = let (g', ch) = G.withdrawSource (sentenceSource k) g in (g', cs ++ [ch])
    lostSupport = nub (concatMap G.scLostSupport changes)
    lostGround = nub (concatMap G.scLostGrounding changes)
    survived = [ i | i <- nub (concatMap G.scSurvived changes), i `notElem` lostSupport
                   , not (null (supportEnvironments (G.supportOf graphR i))) ]
    retractionLines
      | null (oRetract o) = []
      | otherwise =
          [ "", "  -- after withdrawing " ++ intercalate ", " (map (show . sentenceSource) (oRetract o))
                  ++ " (Genealogy.withdrawSource)" ]
          ++ [ "  " ++ show (sentenceSource k) ++ ": no such sentence (the text has " ++ show nSent ++ "); nothing withdrawn"
             | k <- missing ]
          ++ [ "  lost all support:               " ++ refs lostSupport
             , "  lost grounding:                 " ++ refs lostGround
             , "  survived (independent support): " ++ refs survived ]
          ++ graphBody graphR valid (Just mark)
          ++ certifiedLines valid
    refs [] = "(none)"
    refs is = intercalate ", " [ show i ++ " " ++ maybe "?" (renderCanonCond . G.nodeClaim) (G.nodeAt graph0 i) | i <- is ]
    mark i
      | i `elem` lostSupport = "  <- LOST SUPPORT"
      | i `elem` lostGround = "  <- LOST GROUNDING (still supported)"
      | i `elem` survived = "  <- SURVIVED (independent support)"
      | otherwise = ""

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
