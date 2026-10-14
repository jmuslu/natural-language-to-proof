{-# LANGUAGE DataKinds #-}

-- | This executable adapts deterministic synthetic benchmark fixtures to the
-- production Genealogy API. It exists to test admission/withdrawal independently
-- of English parsing; it never reads gold labels or implements another algebra.
module Main (main) where

import Control.Monad (foldM)
import Data.List (find, nub, sort)
import qualified Data.Map.Strict as M
import Data.Maybe (fromMaybe)

import NL2Proof.Bench.JSON
import NL2Proof.DRT.Canonical
import NL2Proof.DRT.Types
import NL2Proof.Genealogy
import NL2Proof.Provenance
import NL2Proof.Verify.ClaimKind (assertedClaims)
import NL2Proof.Verify.Oracle
import NL2Proof.Verify.Reported

need :: String -> JValue -> Either String JValue
need key value = maybe (Left ("missing " ++ key)) Right (field key value)

string :: JValue -> Either String String
string (JStr value) = Right value
string _ = Left "expected string"

array :: JValue -> Either String [JValue]
array (JArr values) = Right values
array _ = Left "expected array"

integer :: JValue -> Either String Int
integer (JNum value)
  | value >= 0, value <= 100000, fromIntegral (round value :: Int) == value = Right (round value)
integer _ = Left "expected nonnegative bounded integer"

bool :: JValue -> Either String Bool
bool (JBool value) = Right value
bool _ = Left "expected boolean"

getString :: String -> JValue -> Either String String
getString key value = need key value >>= string

getInt :: String -> JValue -> Either String Int
getInt key value = need key value >>= integer

getList :: String -> JValue -> Either String [JValue]
getList key value = need key value >>= array

getInts :: String -> JValue -> Either String [Int]
getInts key value = getList key value >>= traverse integer

pv :: String -> Prov
pv source = ProvLex (SourceId source) (Span 0 1) "synthetic evidence"

-- The benchmark explicitly authors whole assertion boxes, never upgrades an
-- embedded/parser-returned CanonCond. This is a fixture oracle, not world truth.
asDRS :: Prov -> CanonCond -> DRS
asDRS p c = DRS [] [fromCond c]
  where
    fromTerm (CConstT name) = DConst name
    fromTerm (CRefT (CRef i)) = DRef (Ref ("fixture" ++ show i))
    fromBox (Canonical us cs) = DRS [(Ref ("fixture" ++ show i),p) | CRef i <- us] (map fromCond cs)
    fromCond k = case k of
      CanPred name terms -> CPred name (map fromTerm terms) p
      CanEq a b -> CEq (fromTerm a) (fromTerm b) p
      CanNot box -> CNot (fromBox box) p
      CanImp a b -> CImp (fromBox a) (fromBox b) p
      CanOr a b -> COr (fromBox a) (fromBox b) p
      CanAtt name terms box -> CAtt name (map fromTerm terms) (fromBox box) p
      CanPresup box -> CPresup (fromBox box) p

claim :: String -> M.Map Int JValue -> [Int] -> Int -> Either String CanonCond
claim entity nodes seen i
  | i `elem` seen = Left "cyclic rule syntax"
  | otherwise = do
      node <- maybe (Left "unknown node reference") Right (M.lookup i nodes)
      case field "rule" node of
        Just rule -> do
          target <- getInt "target" rule
          antecedents <- getInts "antecedents" rule
          cs <- traverse (claim entity nodes (i:seen)) antecedents
          conclusion <- claim entity nodes (i:seen) target
          pure (CanImp (Canonical [] cs) (Canonical [] [conclusion]))
        Nothing -> do
          name <- getString "atom" node
          negative <- need "negative" node >>= bool
          let atom = CanPred name [CConstT entity]
          pure (if negative then CanNot (Canonical [] [atom]) else atom)

admit :: M.Map Int CanonCond -> Genealogy -> JValue -> Either String Genealogy
admit claims graph seed = do
  i <- getInt "node" seed
  content <- maybe (Left "seed references absent node") Right (M.lookup i claims)
  kind <- getString "kind" seed
  source <- getString "source" seed
  holders <- getList "holders" seed >>= traverse string
  let provenance = pv source
      authored = asDRS provenance content
      target = NodeId i
  case kind of
    "oracle" -> case assertedClaims authored of
      [(assertion,_)] -> case confirm (Oracle source "synthetic fixture verification" (const True) (const True)) assertion of
        Just token -> Right (addConfirmedNode target provenance token graph)
        Nothing -> Left "fixture oracle refused assertion"
      _ -> Left "fixture does not assert one condition"
    "asserted" -> case assertedClaims authored of
      [(assertion,_)] -> Right (addAssertedNode target provenance assertion graph)
      _ -> Left "fixture does not assert one condition"
    "reported" -> do
      if null holders then Left "report requires attribution" else Right ()
      let reportedDRS = foldr (\holder box -> DRS [] [CAtt "say" [DConst holder] box provenance]) authored holders
          (_, reports, _, _) = splitClaims reportedDRS
      case find (\r -> reportedContent r == content && length (reportedChain r) == length holders) reports of
        Just report -> Right (addReportedNode target report graph)
        Nothing -> Left "authored report did not preserve content and chain"
    "presupposed" -> case splitClaims (DRS [] [CPresup authored provenance]) of
      (_,_,[presupposition],_) -> Right (addPresupposedNode target presupposition graph)
      _ -> Left "authored presupposition did not preserve content"
    "translated" -> Right (addTranslatedNode target "synthetic-model" content provenance graph)
    _ -> Left ("unknown evidence kind: " ++ kind)

addEdge :: M.Map Int CanonCond -> Genealogy -> JValue -> Either String Genealogy
addEdge claims graph edge = do
  target <- getInt "target" edge
  antecedents <- getInts "antecedents" edge
  if null antecedents || any (`M.notMember` claims) (target:antecedents)
    then Left "invalid inference references"
    else Right (addJustification (derivation (NodeId target) "authored benchmark rule" (map NodeId antecedents)) graph)

className :: EvidenceClass -> String
className kind = case kind of
  OracleConfirmed _ -> "oracle"
  AssertedUnconfirmed -> "asserted"
  ReportedEvidence _ -> "reported"
  PresupposedEvidence -> "presupposed"
  LLMTranslatedEvidence _ -> "translated"

-- Keep sources and classes correlated within each sufficient environment.
environments :: Support Evidence -> JValue
environments label = JArr
  [JObj [("sources", strings sources),("classes", strings classes)]
  | (sources,classes) <- sort
      [(sort (nub [name | e <- env, SourceId name <- evidenceSources e]),
        sort (nub (map (className . evidenceClass) env)))
      | env <- supportEnvironments label]]
  where strings = JArr . map JStr

solve :: JValue -> Either String JValue
solve input = do
  identifier <- getString "id" input
  fixture <- need "fixture" input
  entity <- getString "entity" fixture
  nodeList <- getList "nodes" fixture
  nodePairs <- traverse (\n -> do i <- getInt "id" n; pure (i,n)) nodeList
  let nodes = M.fromList nodePairs
  if M.size nodes /= length nodeList then Left "duplicate node id" else Right ()
  claims <- traverseWithKeyEither (claim entity nodes []) nodes
  seeds <- getList "seeds" fixture
  edges <- getList "edges" fixture
  withdrawn <- getList "withdraw" fixture >>= traverse string
  query <- getInt "query" fixture
  opposite <- getInt "opposite" fixture
  if any (`M.notMember` claims) [query,opposite] then Left "unknown query node" else Right ()
  let bare = foldl (\g (i,c) -> addNode (Node (NodeId i) c (pv "structure")) Unknown g) emptyGenealogy (M.toList claims)
  seeded <- foldM (admit claims) bare seeds
  linked <- foldM (addEdge claims) seeded edges
  let graph = foldl (\g source -> fst (withdrawSource (SourceId source) g)) linked withdrawn
      labels = supportLabels graph
      q = M.findWithDefault supportZero (NodeId query) labels
      n = M.findWithDefault supportZero (NodeId opposite) labels
      supported = not . null . supportEnvironments
      established = any (all ((== "oracle") . className . evidenceClass)) . supportEnvironments
      qs = supported q; ns = supported n; qg = established q; ng = established n
      answer | qs && ns = "Conflict"
             | qg = "Established"
             | qs = "WeakOnly"
             | otherwise = "Unsupported"
  pure $ JObj [("id",JStr identifier),("label",JStr answer)
    ,("query_supported",JBool qs),("query_grounded",JBool qg)
    ,("opposite_supported",JBool ns),("opposite_grounded",JBool ng)
    ,("query_environments",environments q),("opposite_environments",environments n)]
  where
    traverseWithKeyEither f = M.traverseWithKey (\i _ -> f i)

process :: String -> String
process line = renderJSON $ case parseJSON line of
  Left err -> JObj [("error",JStr err)]
  Right input -> case solve input of
    Left err -> JObj [("id",fromMaybe JNull (field "id" input)),("error",JStr err)]
    Right result -> result

main :: IO ()
main = interact (unlines . map process . filter (not . null) . lines)
