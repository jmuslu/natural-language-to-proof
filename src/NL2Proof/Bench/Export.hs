-- | Scoped, gold-free parser export. A bounded Cartesian product is assembled
-- by the same DRT discourse operations used by the ordinary pipeline. Nothing
-- in this module flattens subordinate conditions or produces oracle evidence.
module NL2Proof.Bench.Export
  ( exportRequest
  , drsJSON
  , drsResiduals
  , traceJSON
  , provenanceJSON
  ) where

import Data.Char (isAlphaNum, toLower)
import Data.List (groupBy, intercalate, isPrefixOf, nub)
import Data.Maybe (isJust)

import NL2Proof.Bench.JSON
import NL2Proof.DRT.Build
import NL2Proof.DRT.Types
import NL2Proof.Pipeline
import NL2Proof.Provenance
import NL2Proof.Semantics.Lambda (isAnaphorName, pretty)
import NL2Proof.Syntax.CCG (Sign(..))
import NL2Proof.Syntax.CCGSemParse (SemModel(..))
import NL2Proof.Syntax.Tokenize (Sentence(..))
import NL2Proof.Trace

-- | Strict request whitelist: no labels, gold logic or arbitrary configuration.
-- A context array is joined in order with newlines; character spans in exported
-- context provenance refer to that exact joined text.
exportRequest :: ParserChoice -> Int -> JValue -> Either String JValue
exportRequest choice cap value = do
  fields <- maybe (Left "request must be an object") Right (obj value)
  let keys = map fst fields
  if length keys /= length (nub keys) then Left "duplicate request key" else pure ()
  if any (`notElem` ["id", "context", "statement"]) keys
    then Left "request accepts only id, context, statement" else pure ()
  ident <- stringField "id"
  statement <- stringField "statement"
  context <- case field "context" value of
    Just (JStr text) -> Right text
    Just (JArr texts) -> intercalate "\n" <$> mapM
      (maybe (Left "context array must contain only strings") Right . str) texts
    _ -> Left "context must be a string or string array"
  if cap < 1 || cap > 64 then Left "max combinations must be between 1 and 64"
    else Right (exportText choice cap ident context statement)
  where
    stringField key = maybe (Left (key ++ " must be a string")) Right (field key value >>= str)

exportText :: ParserChoice -> Int -> String -> String -> String -> JValue
exportText choice cap ident context statement = JObj
  [ ("schema", JNum 1)
  , ("id", JStr ident)
  , ("context", documentJSON contextResult)
  , ("statement", documentJSON statementResult)
  , ("theories", JArr (map theoryJSON grouped))
  , ("truncated", JBool truncated)
  , ("search", JObj
      [ ("beam_limited", JBool (isJust beam))
      , ("beam", maybe JNull (JNum . fromIntegral) beam)
      , ("max_combinations", JNum (fromIntegral cap))
      , ("returned_combinations", JNum (fromIntegral (length selected)))
      , ("scope", JStr "all returned candidate meanings; parser search is not exhaustive English ambiguity")
      ])
  , ("residuals", strings
      (["combination-cap" | truncated]
        ++ ["statement-must-have-exactly-one-sentence" | length querySentences /= 1]
        ++ ["statement-no-reading" | [q] <- [querySentences], null (srReadings q)]))
  ]
  where
    beam = case choice of CCGBankParser model -> Just (smBeam model); HandLexicon _ -> Nothing
    contextResult = runPipelineWith choice (SourceId (ident ++ ":context")) context
    statementResult = runPipelineWith choice (SourceId (ident ++ ":statement")) statement
    contextSentences = prSentences contextResult
    querySentences = prSentences statementResult
    options r = case srReadings r of
      [] -> [(-1, Nothing)]
      rs -> [(i, Just reading) | (i, reading) <- zip [0 :: Int ..] rs]
    queryOptions = case querySentences of
      [q] -> map Just (options q)
      _ -> [Nothing]
    -- Lazy cap+1: no unbounded product is materialized. The limit is over
    -- theory/query pairs together, not 64 of each independently.
    combinations = [(cs,q) | cs <- sequence (map options contextSentences), q <- queryOptions]
    probed = take (cap + 1) combinations
    truncated = length probed > cap
    selected = take cap probed
    grouped = groupBy (\(a,_) (b,_) -> map fst a == map fst b) selected
    theoryJSON [] = JNull -- groupBy never yields this case
    theoryJSON rows@((chosen,_):_) =
      let accepted = [(d, sProv (rrSign r)) | (_,Just r) <- chosen, Just d <- [rrDRS r]]
          discourse = runDiscourse accepted
          box = dscDRS discourse
          missing = ["context-sentence-" ++ show i ++ "-no-typed-reading"
                    | (i,(_,mr)) <- zip [0 :: Int ..] chosen, maybe True (not . isJust . rrDRS) mr]
          residuals = missing ++ drsResiduals box
          tr = foldMap (maybe mempty rrTrace . snd) chosen <> dscTrace discourse
      in JObj
        [ ("choice_indices", ints (map fst chosen))
        , ("drs", drsJSON box)
        , ("complete", JBool (null residuals))
        , ("residuals", strings residuals)
        , ("trace", traceJSON tr)
        , ("queries", JArr [queryJSON box qi qr | (_,Just (qi,qr)) <- rows])
        ]
    queryJSON _ i Nothing = JObj
      [("choice_indices",ints [i]),("drs",JNull),("complete",JBool False)
      ,("residuals",strings ["statement-no-typed-reading"]),("trace",traceJSON mempty)]
    queryJSON ctx i (Just reading) = case rrDRS reading of
      Nothing -> JObj
        [("choice_indices",ints [i]),("drs",JNull),("complete",JBool False)
        ,("residuals",strings ["statement-no-typed-reading"]),("trace",traceJSON (rrTrace reading))]
      Just local ->
        -- These are precisely extendDiscourse's freshening/resolution steps.
        -- Do not merge the query into the premises. If a pronoun resolves to a
        -- context-bound existential, drsResiduals reports an unbound reference:
        -- the initial solver interface has no shared assignment environment.
        let (fresh,_) = freshenAgainst (drsRefs ctx) local
            (resolved,tr) = resolveAnaphora ctx fresh (sProv (rrSign reading))
            residuals = drsResiduals resolved
        in JObj
          [("choice_indices",ints [i]),("drs",drsJSON resolved)
          ,("complete",JBool (null residuals)),("residuals",strings residuals)
          ,("trace",traceJSON (rrTrace reading <> tr))]

documentJSON :: PipelineResult -> JValue
documentJSON result = JObj
  [ ("text", JStr (prText result))
  , ("sentences", JArr (zipWith sentenceJSON [0..] (prSentences result)))
  , ("selected_drs", drsJSON (dscDRS (prDiscourse result)))
  , ("trace", traceJSON (prTrace result))
  ]

sentenceJSON :: Int -> SentenceResult -> JValue
sentenceJSON i result = JObj
  [ ("id", JNum (fromIntegral i))
  , ("text", JStr (sentText (srSentence result)))
  , ("span", spanJSON (sentSpan (srSentence result)))
  , ("readings", JArr (zipWith readingJSON [0..] (srReadings result)))
  , ("trace", traceJSON (srTrace result))
  ]

readingJSON :: Int -> ReadingResult -> JValue
readingJSON i reading = JObj
  [ ("index", JNum (fromIntegral i))
  , ("category", JStr (show (sCat (rrSign reading))))
  , ("form", maybe JNull (JStr . pretty) (rrForm reading))
  , ("drs", maybe JNull drsJSON (rrDRS reading))
  , ("type_valid", JBool (isJust (rrForm reading)))
  , ("score", maybe JNull JNum (rrScore reading))
  , ("score_role", JStr "parser ranking only; not evidence strength")
  , ("trace", traceJSON (rrTrace reading))
  , ("prov", provenanceJSON (sProv (rrSign reading)))
  , ("residuals", strings (maybe ["type-check-failure"] drsResiduals (rrDRS reading)))
  ]

-- | Scoped structure, preserving universes and every condition constructor.
drsJSON :: DRS -> JValue
drsJSON root = boxJSON root
  where
    ambiguous = ambiguousEitherProvs root
    boxJSON (DRS universe conditions) = JObj
      [ ("universe", strings [show r | (r,_) <- universe])
      , ("universe_provenance", JArr
          [JObj [("ref",JStr (show r)),("prov",provenanceJSON p)] | (r,p) <- universe])
      , ("conditions", JArr (map conditionJSON conditions))
      , ("xor_residuals", strings
          ["ambiguous-either-scope" | any (`elem` ambiguous) (orProvs (DRS universe conditions))])
      ]
    conditionJSON condition = JObj (body condition ++ [("prov", provenanceJSON (condProv condition))])
    body (CPred name args _) = [("tag",JStr "pred"),("name",JStr name),("args",JArr (map termJSON args))]
    body (CEq left right _) = [("tag",JStr "eq"),("left",termJSON left),("right",termJSON right)]
    body (CNot box _) = [("tag",JStr "not"),("body",boxJSON box)]
    body (CImp left right _) = [("tag",JStr "imp"),("left",boxJSON left),("right",boxJSON right)]
    body (COr left right prov) =
      [("tag",JStr "or"),("left",boxJSON left),("right",boxJSON right)
      ,("either",JBool (hasEither prov && prov `notElem` ambiguous))
      ,("either_scope_ambiguous",JBool (prov `elem` ambiguous))]
    body (CAtt verb holders box _) =
      [("tag",JStr "att"),("verb",JStr verb),("holders",JArr (map termJSON holders)),("body",boxJSON box)]
    body (CPresup box _) = [("tag",JStr "presup"),("body",boxJSON box)]
    termJSON (DRef ref) = JObj [("ref",JStr (show ref))]
    termJSON (DConst name) = JObj [("const",JStr name)]

-- Current toDRS uses the full sentence fallback provenance for each COr.
-- Shared provenance cannot localize either among several disjunctions. Keep
-- inclusive meaning available, but require the XOR consumer to abstain there.
ambiguousEitherProvs :: DRS -> [Prov]
ambiguousEitherProvs box =
  let ps = orProvs box
  in nub [p | p <- ps, hasEither p, length (filter (== p) ps) > 1]

hasEither :: Prov -> Bool
hasEither = any (\(_,_,word) -> map toLower word == "either") . provLeaves

orProvs :: DRS -> [Prov]
orProvs (DRS _ conditions) = concatMap visit conditions
  where
    visit (COr left right p) = p : orProvs left ++ orProvs right
    visit (CImp left right _) = orProvs left ++ orProvs right
    visit (CNot box _) = orProvs box
    visit (CAtt _ _ box _) = orProvs box
    visit (CPresup box _) = orProvs box
    visit _ = []

-- | Residuals have semantic consequences, not merely display warnings. A
-- complete Boolean solver answer must not treat them as ordinary predicates.
-- Implication antecedent universes bind variables in both halves (DRT duplex).
drsResiduals :: DRS -> [String]
drsResiduals = nub . box []
  where
    box outer (DRS universe conditions) = concatMap (condition (map fst universe ++ outer)) conditions
    condition env cond = case cond of
      CPred name args _ -> ["unsupported-condition:" ++ name | "UNSUPPORTED[" `isPrefixOf` name]
        ++ concatMap (term env) args
      CEq left right _ -> term env left ++ term env right
      CNot sub _ -> box env sub
      CImp left right _ -> box env left ++ box (map fst (drsUniverse left) ++ env) right
      COr left right _ -> box env left ++ box env right
      CAtt _ holders sub _ -> "attitude" : concatMap (term env) holders ++ box env sub
      CPresup sub _ -> "presupposition" : box env sub
    term env (DRef ref) = ["unbound-ref:" ++ show ref | ref `notElem` env]
    term _ (DConst name)
      | isAnaphorName name = ["unresolved-anaphor:" ++ name]
      | null name || not (all simpleChar name) = ["opaque-argument:" ++ name]
      | otherwise = []
    simpleChar c = isAlphaNum c || c `elem` "_-' "

traceJSON :: Trace -> JValue
traceJSON trace = JObj
  [("decisions",JArr (map decision (traceDecisions trace)))
  ,("diagnostics",JArr (map diagnostic (traceDiagnostics trace)))]
  where
    decision d = JObj
      [("kind",JStr (decKind d)),("choice",JStr (decChoice d))
      ,("alternatives",strings (decAlternatives d)),("why",JStr (decWhy d))
      ,("prov",provenanceJSON (decProv d))]
    diagnostic d = JObj
      [("kind",JStr (show (diagKind d))),("message",JStr (diagMsg d))
      ,("prov",provenanceJSON (diagProv d))]

-- | Compact source mapping; full derivation shape is represented by rule names
-- plus its ordered lexical leaves, rather than duplicating huge trees per atom.
provenanceJSON :: Prov -> JValue
provenanceJSON prov = JObj
  [("sources",strings (map show (provSources prov)))
  ,("span",maybe JNull spanJSON (provSpan prov))
  ,("rules",strings (map show (provRuleNames prov)))
  ,("leaves",JArr
      [JObj [("source",JStr (show src)),("span",spanJSON sp),("text",JStr text)]
      | (src,sp,text) <- provLeaves prov])]

spanJSON :: Span -> JValue
spanJSON (Span start end) = ints [start,end]

strings :: [String] -> JValue
strings = JArr . map JStr

ints :: [Int] -> JValue
ints = JArr . map (JNum . fromIntegral)
