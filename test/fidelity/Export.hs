-- | Meaning-fidelity observation seam. This executable exists to exercise the
-- actual Pipeline, Canonical and Claims APIs without sending evaluator gold to
-- the parser or reimplementing their semantics in a scoring script. It emits
-- scoped meanings and ordered claim tables; it never asks an oracle or solver.
module Main (main) where

import Control.Exception (SomeException, evaluate, try)
import qualified Data.Map as M
import Data.Maybe (isJust)
import Data.List (nub)
import System.Environment (getArgs)
import System.Exit (exitFailure)
import System.IO (hFlush, hPutStrLn, isEOF, stderr, stdout)

import NL2Proof.Bench.Export (drsJSON, traceJSON)
import NL2Proof.Bench.JSON
import NL2Proof.DRT.Build (dscDRS)
import NL2Proof.DRT.Canonical
import NL2Proof.DRT.Types (DRS)
import NL2Proof.Pipeline
import NL2Proof.Provenance (SourceId(..))
import NL2Proof.Semantics.Lambda (pretty)
import NL2Proof.Syntax.CCG (Sign(..))
import NL2Proof.Syntax.CCGSemParse
import NL2Proof.Syntax.CCGSupertag (TagModel(..))
import NL2Proof.Syntax.Lexicon (attitudeLexicon)
import NL2Proof.Verify.ClaimKind (claimCond)
import NL2Proof.Verify.Claims
import NL2Proof.Verify.Reported

main :: IO ()
main = do
  args <- getArgs
  let eitherFlags = filter (`elem` ["--either-policy=legacy-disabled", "--either-policy=surface-inclusive-v1"]) args
      nominalFlags = filter (`elem` ["--nominal-nouns=known-only", "--nominal-nouns=context-unknown"]) args
  if length args /= length (nub args) || length nominalFlags > 1 || length eitherFlags > 1
    then die "duplicate or conflicting options" else pure ()
  if any (`notElem` ["--hand", "--pos-backoff", "--nominal-nouns=known-only", "--nominal-nouns=context-unknown", "--either-policy=legacy-disabled", "--either-policy=surface-inclusive-v1"]) args
    then die "usage: nl2proof-fidelity-json [--hand | --pos-backoff] [--nominal-nouns=known-only|context-unknown] [--either-policy=legacy-disabled|surface-inclusive-v1]"
    else pure ()
  if "--hand" `elem` args && "--pos-backoff" `elem` args
    then die "hand and POS modes are separate front ends"
    else pure ()
  if "--hand" `elem` args && not (null nominalFlags)
    then die "hand parser does not accept nominal policy" else pure ()
  if "--hand" `elem` args && not (null eitherFlags)
    then die "hand parser does not accept either policy" else pure ()
  if "--either-policy=surface-inclusive-v1" `elem` args
    then die "surface-inclusive-v1 unavailable: runtime either interface is not integrated" else pure ()
  let execution = if null eitherFlags then ImplicitLegacy else ExplicitLegacy
      policy = if "--nominal-nouns=context-unknown" `elem` args then ContextUnknownNouns else KnownNounsOnly
  choice <- if "--hand" `elem` args then pure (HandLexicon attitudeLexicon) else do
    dir <- ccgbankDataDir
    hPutStrLn stderr "loading CCGbank parser model for meaning fidelity"
    (model,trainingCount) <- loadSemModel dir
    _ <- evaluate (M.size (tmWord (smTags model)))
    if trainingCount == 0 then die "no CCGbank training trees found" else pure ()
    pure (CCGBankParser model {smPOSBackoff="--pos-backoff" `elem` args, smNominalPolicy=policy})
  loop execution choice
  where die message = hPutStrLn stderr message >> exitFailure

data EitherExecution = ImplicitLegacy | ExplicitLegacy

loop :: EitherExecution -> ParserChoice -> IO ()
loop execution choice = do
  eof <- isEOF
  if eof then pure () else do
    line <- getLine
    let parsed = parseJSON line
        ident = either (const JNull) (maybe JNull id . field "id") parsed
        errorJSON message = JObj [("id",ident),("error",JStr message),("execution",executionJSON execution choice)]
        rendered = renderJSON (either errorJSON id (parsed >>= observe execution choice))
    forced <- try (evaluate (length rendered)) :: IO (Either SomeException Int)
    case forced of
      Left err -> putStrLn (renderJSON (errorJSON (show err)))
      Right _ -> putStrLn rendered
    hFlush stdout
    loop execution choice

observe :: EitherExecution -> ParserChoice -> JValue -> Either String JValue
observe execution choice request = do
  fields <- maybe (Left "request must be an object") Right (obj request)
  let keys = map fst fields
  if length keys /= length (nub keys) || any (`notElem` ["id","text"]) keys
    then Left "request accepts unique id and text only; gold is evaluator-side"
    else pure ()
  ident <- required "id"
  text <- required "text"
  let result = runPipelineWith choice (SourceId ("fidelity:" ++ ident)) text
      sentences = prSentences result
      nParsed = length (filter (isJust . srChosen) sentences)
      nTyped = length (filter (isJust . srForm) sentences)
      nDRS = length (filter (isJust . srDRS) sentences)
  pure $ JObj
    [ ("schema",JNum 1), ("id",JStr ident), ("execution",executionJSON execution choice)
    , ("sentence_count",count (length sentences))
    , ("parsed_sentences",count nParsed), ("typed_sentences",count nTyped)
    , ("drs_sentences",count nDRS)
    , ("selected",if nDRS == 0 then JNull else meaningJSON (dscDRS (prDiscourse result)))
    , ("readings",JArr [readingJSON s i r | (s,sentence) <- zip [0..] sentences,
                                           (i,r) <- zip [0..] (srReadings sentence)])
    , ("trace",traceJSON (prTrace result))
    , ("scope",JStr "selected is discourse-resolved; returned alternatives are sentence-local")
    ]
  where required key = maybe (Left (key ++ " must be a string")) Right (field key request >>= str)

executionJSON :: EitherExecution -> ParserChoice -> JValue
executionJSON execution choice = JObj ([("schema",JStr schema),("parser",JStr parser),("nominal_nouns",JStr policy)] ++ extra)
  where
    (schema,extra) = case execution of
      ImplicitLegacy -> ("nominal-policy-v1",[])
      ExplicitLegacy -> ("parser-policy-v2",[("either_policy",JStr "legacy-disabled")])
    (parser,policy) = case choice of
      HandLexicon _ -> ("hand","not-applicable")
      CCGBankParser model -> (if smPOSBackoff model then "pos" else "default",
        case smNominalPolicy model of KnownNounsOnly -> "known-only"; ContextUnknownNouns -> "context-unknown")

count :: Int -> JValue
count = JNum . fromIntegral

readingJSON :: Int -> Int -> ReadingResult -> JValue
readingJSON sentence index reading = JObj
  [ ("sentence_id",count sentence), ("index",count index)
  , ("typed",JBool (isJust (rrForm reading)))
  , ("category",JStr (show (sCat (rrSign reading))))
  , ("form",maybe JNull (JStr . pretty) (rrForm reading))
  , ("score",maybe JNull JNum (rrScore reading))
  , ("meaning",maybe JNull meaningJSON (rrDRS reading))
  , ("trace",traceJSON (rrTrace reading))
  ]

meaningJSON :: DRS -> JValue
meaningJSON drs = JObj
  [ ("drs",canonicalJSON (canonicalize drs))
  , ("claims",claimsJSON (claimsOfDRS "fidelity observation" drs))
  , ("disjunctions",JArr (disjunctions [] (drsJSON drs)))
  ]

canonicalJSON :: Canonical -> JValue
canonicalJSON (Canonical universe conditions) = JObj
  [("universe",JArr (map (JStr . show) universe)), ("conditions",JArr (map conditionJSON conditions))]

conditionJSON :: CanonCond -> JValue
conditionJSON condition = JObj $ case condition of
  CanPred name args -> [("tag",JStr "pred"),("name",JStr name),("args",JArr (map termJSON args))]
  CanEq a b -> [("tag",JStr "eq"),("left",termJSON a),("right",termJSON b)]
  CanNot body -> [("tag",JStr "not"),("body",canonicalJSON body)]
  CanImp a b -> [("tag",JStr "imp"),("left",canonicalJSON a),("right",canonicalJSON b)]
  CanOr a b -> [("tag",JStr "or"),("left",canonicalJSON a),("right",canonicalJSON b)]
  CanAtt verb holders body -> [("tag",JStr "att"),("verb",JStr verb),
    ("holders",JArr (map termJSON holders)),("body",canonicalJSON body)]
  CanPresup body -> [("tag",JStr "presup"),("body",canonicalJSON body)]

termJSON :: CTerm -> JValue
termJSON (CRefT ref) = JObj [("ref",JStr (show ref))]
termJSON (CConstT name) = JObj [("const",JStr name)]

claimsJSON :: ClaimTable -> JValue
claimsJSON table = JObj
  [ ("universe",JArr (map (JStr . show) (ctUniverse table)))
  , ("asserted",JArr (map (conditionJSON . factClaim) (ctFacts table)))
  , ("reported",JArr [JObj [("condition",conditionJSON (reportedContent r)),
      ("chain",JArr (map attributionJSON (reportedChain r)))] | r <- ctReported table])
  , ("presupposed",JArr (map (conditionJSON . claimCond . presupposedClaim') (ctPresupposed table)))
  , ("embedded",JArr (map (conditionJSON . claimCond) (ctEmbedded table)))
  ]

attributionJSON :: Attribution -> JValue
attributionJSON a = JObj [("verb",JStr (attVerb a)),("holders",JArr (map termJSON (attHolders a))),
                          ("factive",JBool (attFactive a))]

-- Canonical intentionally drops provenance. Preserve either-localization as a
-- separately comparable annotation from the existing production DRS exporter.
disjunctions :: [JValue] -> JValue -> [JValue]
disjunctions path box = concat
  [ visit (path ++ [JStr "conditions",count i]) condition
  | (i,condition) <- zip [0..] (array (field "conditions" box)) ]
  where
    visit at condition =
      [ JObj [("path",JArr at),("either",boolean "either" condition),
               ("scope_ambiguous",boolean "either_scope_ambiguous" condition)]
      | field "tag" condition == Just (JStr "or") ]
      ++ concat [maybe [] (disjunctions (at ++ [JStr key])) (field key condition)
                | key <- ["body","left","right"]]
    boolean key value = maybe (JBool False) id (field key value)
    array (Just (JArr values)) = values
    array _ = []
