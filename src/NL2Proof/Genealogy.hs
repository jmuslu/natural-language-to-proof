{-# LANGUAGE DataKinds #-}

-- | Addressable claims and exact alternative evidence support. Labels are the
-- least fixed point of the antichain semiring in Provenance: conjunction combines
-- required evidence and alternatives retain independent sufficient environments.
-- Unseeded cycles remain unsupported. Weak evidence never creates oracle evidence.
--
-- A justification is a supplied inference, not a proof checker. Callers supplying
-- arbitrary derivations are responsible for their validity. Oracle seeds require
-- a Confirmed capability; graph conclusions never mint Confirmed or a Fused base.
module NL2Proof.Genealogy
  ( NodeId(..), Node(..), Justification(..), premise, derivation
  , Genealogy, gNodes, gJusts, gVerdicts
  , emptyGenealogy, addNode, addJustification, nodeAt, nodeIds, verdictOf, setVerdict
  , Evidence, EvidenceClass(..), evidenceNode, evidenceClaim, evidenceClass, evidenceSources, evidenceProv
  , addConfirmedNode, addAssertedNode, addReportedNode, addPresupposedNode, addTranslatedNode
  , supportLabels, supportOf, grounded, isGrounded, justificationsFor, supportingJustifications
  , antecedentsOf, dependents, premisesUnder
  , independentSupports, hasIndependentSupport, convergentNodes, corroboratedNodes
  , retract, RetractionReport(..), retractionReport, survivesRetractionOf
  , SupportChange(..), withdrawSource
  , renderGenealogy, renderRetractionReport
  ) where

import Data.List (nub, sort)
import qualified Data.Map.Strict as M
import qualified Data.Set as S

import NL2Proof.DRT.Canonical
import NL2Proof.Provenance
import NL2Proof.Verify.ClaimKind (Claim, ClaimKind(Asserted), claimCond)
import NL2Proof.Verify.Oracle
import NL2Proof.Verify.Reported

newtype NodeId = NodeId Int deriving (Eq, Ord)
instance Show NodeId where show (NodeId i) = "n" ++ show i

data Node = Node { nodeId :: NodeId, nodeClaim :: CanonCond, nodeProv :: Prov }
  deriving (Eq, Show)

data Justification = Justification
  { jTarget :: NodeId, jRule :: String, jAntecedents :: [NodeId] }
  deriving (Eq, Show)

premise :: NodeId -> String -> Justification
premise target rule = Justification target rule []

derivation :: NodeId -> String -> [NodeId] -> Justification
derivation = Justification

-- | Descriptive classes, not capabilities: no admission function accepts this
-- enum. Only addConfirmedNode may construct an OracleConfirmed evidence value.
data EvidenceClass
  = OracleConfirmed String
  | AssertedUnconfirmed
  | ReportedEvidence [Attribution]
  | PresupposedEvidence
  | LLMTranslatedEvidence String
  deriving (Eq, Ord, Show)

-- | Immutable evidence tied to its node and exact claim. The hidden positional
-- constructor prevents class/claim/source record updates. Oracle evidence is
-- minted only from an actual Confirmed capability.
data Evidence = Evidence NodeId CanonCond EvidenceClass [SourceId] Prov
  deriving (Eq, Ord, Show)

evidenceNode :: Evidence -> NodeId
evidenceNode (Evidence i _ _ _ _) = i

evidenceClaim :: Evidence -> CanonCond
evidenceClaim (Evidence _ c _ _ _) = c

evidenceClass :: Evidence -> EvidenceClass
evidenceClass (Evidence _ _ k _ _) = k

evidenceSources :: Evidence -> [SourceId]
evidenceSources (Evidence _ _ _ ss _) = ss

evidenceProv :: Evidence -> Prov
evidenceProv (Evidence _ _ _ _ p) = p

isOracleEvidence :: Evidence -> Bool
isOracleEvidence e = case evidenceClass e of OracleConfirmed _ -> True; _ -> False

-- Positional and abstract: exported accessors cannot mutate certified seeds or
-- replace the content of a node underneath its evidence.
data Genealogy = Graph
  (M.Map NodeId Node) [Justification] (M.Map NodeId Verdict)
  (M.Map NodeId [Evidence]) (S.Set SourceId)

gNodes :: Genealogy -> M.Map NodeId Node
gNodes (Graph ns _ _ _ _) = ns

gJusts :: Genealogy -> [Justification]
gJusts (Graph _ js _ _ _) = js

gVerdicts :: Genealogy -> M.Map NodeId Verdict
gVerdicts (Graph _ _ vs _ _) = vs

emptyGenealogy :: Genealogy
emptyGenealogy = Graph M.empty [] M.empty M.empty S.empty

-- | Record a node and diagnostic verdict, with no oracle capability. Replacing
-- a node drops its local evidence; changing its claim also invalidates incident
-- justifications, whose logical meaning depended on the previous node content.
addNode :: Node -> Verdict -> Genealogy -> Genealogy
addNode n v (Graph ns js vs es revoked) =
  Graph (M.insert i n ns) validJusts (M.insert i v vs) (M.delete i es) revoked
  where
    i = nodeId n
    changed = maybe False ((/= nodeClaim n) . nodeClaim) (M.lookup i ns)
    validJusts = if changed then filter (\j -> jTarget j /= i && i `notElem` jAntecedents j) js else js

addJustification :: Justification -> Genealogy -> Genealogy
addJustification j (Graph ns js vs es revoked) =
  Graph ns (if j `elem` js then js else js ++ [j]) vs es revoked

nodeAt :: Genealogy -> NodeId -> Maybe Node
nodeAt g i = M.lookup i (gNodes g)

nodeIds :: Genealogy -> [NodeId]
nodeIds = M.keys . gNodes

verdictOf :: Genealogy -> NodeId -> Verdict
verdictOf g i = M.findWithDefault Unknown i (gVerdicts g)

-- | Refuting/uncovering revokes local oracle evidence. Setting a bare Confirmed
-- verdict does not manufacture or revive a capability. Weak testimony remains
-- attributable even when an oracle disagrees with it.
setVerdict :: NodeId -> Verdict -> Genealogy -> Genealogy
setVerdict i v (Graph ns js vs es revoked) =
  Graph ns js (M.insert i v vs) es' revoked
  where es' = if v == Confirmed then es else M.adjust (filter (not . isOracleEvidence)) i es

-- Same-claim admissions add alternative evidence. Distinct claim replacement
-- goes through addNode so stale certificates and incident edges cannot survive.
installEvidence :: NodeId -> CanonCond -> Prov -> EvidenceClass -> [SourceId] -> Verdict -> Genealogy -> Genealogy
installEvidence i c p kind sources verdict g =
  case prepared of
    Graph ns js vs es revoked ->
      addJustification (premise i "evidence") $ Graph
        (M.insert i (Node i c p) ns) js (M.insert i keptVerdict vs)
        (M.insertWith (\new old -> nub (old ++ new)) i [ev] es) revoked
  where
    same = maybe False ((== c) . nodeClaim) (nodeAt g i)
    prepared = if same then g else addNode (Node i c p) verdict g
    keptVerdict = if same && verdict == Unknown then verdictOf g i else verdict
    ev = Evidence i c kind (sort (nub (sources ++ provSources p))) p

addConfirmedNode :: NodeId -> Prov -> Confirmed -> Genealogy -> Genealogy
addConfirmedNode i p token =
  installEvidence i (confClaim token) p (OracleConfirmed (confOracle token))
    [SourceId ("oracle:" ++ confOracle token)] Confirmed

addAssertedNode :: NodeId -> Prov -> Claim 'Asserted -> Genealogy -> Genealogy
addAssertedNode i p c = installEvidence i (claimCond c) p AssertedUnconfirmed [] Unknown

addReportedNode :: NodeId -> Reported -> Genealogy -> Genealogy
addReportedNode i r = installEvidence i (reportedContent r) (reportedProv r)
  (ReportedEvidence (reportedChain r)) speakers Unknown
  where speakers = [SourceId ("speaker:" ++ renderCTerm h) | a <- reportedChain r, h <- attHolders a]

addPresupposedNode :: NodeId -> Presupposed -> Genealogy -> Genealogy
addPresupposedNode i p = installEvidence i (claimCond (presupposedClaim' p)) (presupposedProv p) PresupposedEvidence [] Unknown

addTranslatedNode :: NodeId -> String -> CanonCond -> Prov -> Genealogy -> Genealogy
addTranslatedNode i model c p = installEvidence i c p (LLMTranslatedEvidence model) [] Unknown

activeEvidence :: Genealogy -> NodeId -> [Evidence]
activeEvidence (Graph ns _ _ es revoked) i =
  [e | e <- M.findWithDefault [] i es
     , Just n <- [M.lookup i ns], evidenceClaim e == nodeClaim n
     , all (`S.notMember` revoked) (evidenceSources e)]

-- | Least fixed point on a finite inventory of evidence. Empty antecedents
-- denote evidence premises, never the unconditional multiplicative identity.
supportLabels :: Genealogy -> M.Map NodeId (Support Evidence)
supportLabels g = go (M.fromList [(i,supportZero) | i <- nodeIds g])
  where
    go old = let next = M.mapWithKey (step old) old
             in if next == old then old else go next
    step old i previous = foldl supportPlus previous
      [ if null (jAntecedents j)
          then foldl supportPlus supportZero (map supportAtom (activeEvidence g i))
          else foldl supportTimes supportOne
                 [M.findWithDefault supportZero a old | a <- jAntecedents j]
      | j <- justificationsFor g i ]

supportOf :: Genealogy -> NodeId -> Support Evidence
supportOf g i = M.findWithDefault supportZero i (supportLabels g)

strongSupport :: Support Evidence -> Bool
strongSupport = any (all isOracleEvidence) . supportEnvironments

supportedIds :: M.Map NodeId (Support Evidence) -> S.Set NodeId
supportedIds = M.keysSet . M.filter (not . null . supportEnvironments)

strongIds :: M.Map NodeId (Support Evidence) -> S.Set NodeId
strongIds = M.keysSet . M.filter strongSupport

grounded :: Genealogy -> S.Set NodeId
grounded = strongIds . supportLabels

isGrounded :: Genealogy -> NodeId -> Bool
isGrounded g i = i `S.member` grounded g

justificationsFor :: Genealogy -> NodeId -> [Justification]
justificationsFor g i = [j | j <- gJusts g, jTarget j == i]

supportingJustifications :: Genealogy -> NodeId -> [Justification]
supportingJustifications g i =
  [j | j <- justificationsFor g i
     , if null (jAntecedents j) then any isOracleEvidence (activeEvidence g i)
       else all (`S.member` gr) (jAntecedents j)]
  where gr = grounded g

antecedentsOf :: Genealogy -> NodeId -> [NodeId]
antecedentsOf g = S.toList . close S.empty . (: [])
  where
    close seen [] = seen
    close seen (i:rest)
      | i `S.member` seen = close seen rest
      | otherwise = close (S.insert i seen) (concatMap jAntecedents (justificationsFor g i) ++ rest)

dependents :: Genealogy -> NodeId -> [NodeId]
dependents g i0 = S.toList (S.delete i0 (close S.empty [i0]))
  where
    close seen [] = seen
    close seen (i:rest)
      | i `S.member` seen = close seen rest
      | otherwise = close (S.insert i seen) ([jTarget j | j <- gJusts g, i `elem` jAntecedents j] ++ rest)

-- | Structural ancestry for inspection, not a minimal-support calculation.
premisesUnder :: Genealogy -> NodeId -> [NodeId]
premisesUnder g i = [a | a <- antecedentsOf g i, any (null . jAntecedents) (justificationsFor g a)]

-- | Minimal active oracle environments projected to premise-node identities.
-- Nested alternatives remain separate; unsupported premises do not contribute.
-- Independence here concerns node retraction. Use the full evidence labels for
-- source independence: two different nodes may depend on the same document.
independentSupports :: Genealogy -> NodeId -> [[NodeId]]
independentSupports g i = supportEnvironments $ supportFromEnvironments
  [map evidenceNode env | env <- supportEnvironments (supportOf g i), all isOracleEvidence env]

hasIndependentSupport :: Genealogy -> NodeId -> Bool
hasIndependentSupport g i = or
  [not (S.null a) && not (S.null b) && S.null (S.intersection a b)
  | (k,a) <- zip [0 :: Int ..] supports, (l,b) <- zip [0 ..] supports, k < l]
  where supports = map S.fromList (independentSupports g i)

convergentNodes :: Genealogy -> [(CanonCond, [NodeId])]
convergentNodes g = [(c,map nodeId ns) | (c,ns) <- claimGroups g, length ns > 1]

corroboratedNodes :: Genealogy -> [(CanonCond, [NodeId])]
corroboratedNodes g = [(c,map nodeId ns) | (c,ns) <- claimGroups g, length (nub (map nodeProv ns)) > 1]

claimGroups :: Genealogy -> [(CanonCond, [Node])]
claimGroups g = [(c,[n | n <- ns, nodeClaim n == c]) | c <- nub (map nodeClaim ns)]
  where ns = M.elems (gNodes g)

-- | Revoke this node's direct evidence, then report exact losses of strong
-- support. Independently derived support for the node may survive.
retract :: NodeId -> Genealogy -> (Genealogy, [NodeId])
retract i g@(Graph ns js vs es revoked) =
  (after,S.toList (grounded g `S.difference` grounded after))
  where after = Graph ns js (M.insert i Refuted vs) (M.delete i es) revoked

data SupportChange = SupportChange
  { scLostSupport :: [NodeId]
  , scLostGrounding :: [NodeId]
  , scSurvived :: [NodeId]
  } deriving (Eq, Show)

-- | Source revocations persist in the returned graph. The report distinguishes
-- losing every environment from losing the final oracle-only environment.
withdrawSource :: SourceId -> Genealogy -> (Genealogy, SupportChange)
withdrawSource source g@(Graph ns js vs es revoked) = (after,change)
  where
    after = Graph ns js vs es (S.insert source revoked)
    beforeLabels = supportLabels g
    afterLabels = supportLabels after
    change = SupportChange
      (S.toList (supportedIds beforeLabels `S.difference` supportedIds afterLabels))
      (S.toList (strongIds beforeLabels `S.difference` strongIds afterLabels))
      [i | i <- S.toList (supportedIds afterLabels), M.lookup i beforeLabels /= M.lookup i afterLabels]

data RetractionReport = RetractionReport
  { rrTarget :: NodeId, rrGroundedBefore :: Int, rrGroundedAfter :: Int
  , rrLost :: [NodeId], rrDownstream :: [NodeId], rrSurvived :: [NodeId]
  }

retractionReport :: NodeId -> Genealogy -> RetractionReport
retractionReport i g = RetractionReport i (S.size before) (S.size after) lost down
  [d | d <- down, d `S.member` before, d `S.member` after]
  where
    (g',lost) = retract i g
    before = grounded g; after = grounded g'
    down = dependents g i

survivesRetractionOf :: NodeId -> NodeId -> Genealogy -> Bool
survivesRetractionOf target subject g = isGrounded g subject && isGrounded (fst (retract target g)) subject

renderGenealogy :: Genealogy -> String
renderGenealogy g = unlines $
  ["nodes:"] ++
  ["  " ++ show (nodeId n) ++ (if nodeId n `S.member` gr then " [grounded]" else " [unconfirmed]")
     ++ "  " ++ renderCanonCond (nodeClaim n) ++ "  [" ++ renderVerdict (verdictOf g (nodeId n)) ++ "]"
  | n <- M.elems (gNodes g)] ++
  ["justifications:"] ++
  ["  " ++ show (jTarget j) ++ " <- " ++ jRule j ++ if null (jAntecedents j) then " (premise)" else " " ++ show (jAntecedents j)
  | j <- gJusts g] ++ ["grounded: " ++ show (S.toList gr)]
  where gr = grounded g

renderRetractionReport :: RetractionReport -> String
renderRetractionReport r = unlines
  ["retracting " ++ show (rrTarget r)
  ,"  grounded: " ++ show (rrGroundedBefore r) ++ " -> " ++ show (rrGroundedAfter r)
  ,"  lost (precise):      " ++ show (rrLost r)
  ,"  downstream (coarse): " ++ show (rrDownstream r)
  ,"  survived downstream: " ++ show (rrSurvived r)]
