{-# LANGUAGE DataKinds #-}

-- | Algebraic laws and evidence-withdrawal behavior. Exhaustive finite models
-- exercise the public production operations, including cyclic justifications.
module Main (main) where

import Data.List (subsequences, sort)
import qualified Data.Map.Strict as M
import qualified Data.Set as S

import Harness
import NL2Proof.DRT.Canonical
import NL2Proof.DRT.Types
import NL2Proof.Fusion
import NL2Proof.Genealogy
import NL2Proof.Provenance
import NL2Proof.Verify.ClaimKind (Claim, ClaimKind(Asserted), assertedClaims)
import NL2Proof.Verify.Oracle
import NL2Proof.Verify.Reported

labels :: [Support Int]
labels = S.toList $ S.fromList $ map supportFromEnvironments
  (subsequences (subsequences [0,1,2]))

valuations :: [S.Set Int]
valuations = map S.fromList (subsequences [0,1,2])

algebraChecks :: [Check]
algebraChecks =
  [ expectEq "exactly 20 labels over three tokens" 20 (length labels)
  , expect "plus associativity: 8000 triples" $ and [p (p a b) c == p a (p b c) | a <- labels, b <- labels, c <- labels]
  , expect "times associativity: 8000 triples" $ and [m (m a b) c == m a (m b c) | a <- labels, b <- labels, c <- labels]
  , expect "left distributivity: 8000 triples" $ and [m a (p b c) == p (m a b) (m a c) | a <- labels, b <- labels, c <- labels]
  , expect "right distributivity: 8000 triples" $ and [m (p a b) c == p (m a c) (m b c) | a <- labels, b <- labels, c <- labels]
  , expect "plus/times commutativity: 400 pairs" $ and [p a b == p b a && m a b == m b a | a <- labels, b <- labels]
  , expect "identities and annihilation" $ and [p a z == a && p z a == a && m a o == a && m o a == a && m a z == z && m z a == z | a <- labels]
  , expect "plus/times idempotence" $ and [p a a == a && m a a == a | a <- labels]
  , expect "both absorption laws" $ and [p a (m a b) == a && m a (p a b) == a | a <- labels, b <- labels]
  , expect "normalization preserves minimal antichains" $ and [supportFromEnvironments (supportEnvironments a) == a && antichain a | a <- labels]
  , expect "Boolean projection: 3200 pairs/valuations" $ and [supportHolds v (p a b) == (supportHolds v a || supportHolds v b) && supportHolds v (m a b) == (supportHolds v a && supportHolds v b) | a <- labels, b <- labels, v <- valuations]
  , expect "withdrawal commutes with both operations" $ and [r v (p a b) == p (r v a) (r v b) && r v (m a b) == m (r v a) (r v b) | a <- labels, b <- labels, v <- valuations]
  , expect "withdrawals commute and are idempotent" $ and [r v (r w a) == r (S.union v w) a && r v (r v a) == r v a | a <- labels, v <- valuations, w <- valuations]
  , expect "empty environment differs from absence of support" $ o /= z && all (\v -> supportHolds v o && not (supportHolds v z)) valuations
  ]
  where
    p = supportPlus; m = supportTimes
    z, o :: Support Int
    z = supportZero; o = supportOne
    r v = supportWithout (`S.member` v)
    antichain a = and [not (S.fromList x `S.isProperSubsetOf` S.fromList y) | x <- supportEnvironments a, y <- supportEnvironments a]

pv :: String -> Prov
pv src = ProvLex (SourceId src) (Span 0 1) "w"

cl :: Int -> CanonCond
cl n = CanPred ("p" ++ show n) [CConstT "a"]

fixtureDRS :: [CanonCond] -> DRS
fixtureDRS = fromBox . Canonical []
  where
    fromRef (CRef i) = Ref ("fixture" ++ show i)
    fromTerm (CRefT r) = DRef (fromRef r)
    fromTerm (CConstT n) = DConst n
    fromBox (Canonical us cs) = DRS [(fromRef r, pv "fixture") | r <- us] (map fromCond cs)
    fromCond c = case c of
      CanPred p ts -> CPred p (map fromTerm ts) (pv "fixture")
      CanEq a b -> CEq (fromTerm a) (fromTerm b) (pv "fixture")
      CanNot d -> CNot (fromBox d) (pv "fixture")
      CanImp a b -> CImp (fromBox a) (fromBox b) (pv "fixture")
      CanOr a b -> COr (fromBox a) (fromBox b) (pv "fixture")
      CanAtt v ts d -> CAtt v (map fromTerm ts) (fromBox d) (pv "fixture")
      CanPresup d -> CPresup (fromBox d) (pv "fixture")

assertion :: CanonCond -> Claim 'Asserted
assertion c = case assertedClaims (fixtureDRS [c]) of
  [(a,_)] -> a
  _ -> error "test fixture must assert one whole condition"

certificate :: String -> CanonCond -> Confirmed
certificate name c = case confirm (Oracle name "test fixture" (const True) (const True)) (assertion c) of
  Just token -> token
  Nothing -> error "test oracle unexpectedly refused fixture"

cert :: Int -> String -> Genealogy -> Genealogy
cert i src = addConfirmedNode (NodeId i) (pv src) (certificate "test-oracle" (cl i))

raw :: Int -> Genealogy -> Genealogy
raw i = addNode (Node (NodeId i) (cl i) (pv ("s" ++ show i))) Unknown

edge :: Int -> [Int] -> Genealogy -> Genealogy
edge target sources = addJustification (derivation (NodeId target) "test inference" (map NodeId sources))

supported :: Genealogy -> Int -> Bool
supported g i = not (null (supportEnvironments (supportOf g (NodeId i))))

bothSupport :: Genealogy
bothSupport = edge 3 [0,1] . edge 2 [0] . edge 2 [1]
            . raw 3 . raw 2 . cert 1 "B" . cert 0 "A" $ emptyGenealogy

report :: Reported
report = reportFrom "report-doc"

reportFrom :: String -> Reported
reportFrom doc = case splitClaims d of
  (_, [_outer,r], _, _) -> r
  _ -> error "test fixture must expose nested report"
  where
    d = DRS [] [CAtt "say" [DConst "Anne"]
         (DRS [] [CAtt "say" [DConst "Bob"]
           (DRS [] [CPred "p0" [DConst "a"] (pv doc)]) (pv doc)]) (pv doc)]

presup :: Presupposed
presup = case splitClaims d of
  (_, _, [p], _) -> p
  _ -> error "test fixture must expose presupposition"
  where d = DRS [] [CPresup (DRS [] [CPred "p0" [DConst "a"] (pv "presup-doc")]) (pv "presup-doc")]

admissionChecks :: [Check]
admissionChecks =
  [ expect "Verdict Confirmed cannot create strong evidence" $ not (isGrounded forged (NodeId 0))
  , expect "setVerdict cannot create strong evidence" $ not (isGrounded (setVerdict (NodeId 0) Confirmed (raw 0 emptyGenealogy)) (NodeId 0))
  , expect "capability-backed premise is strongly supported" $ isGrounded confirmed (NodeId 0)
  , expect "replacing node content invalidates the old certificate" $ not (isGrounded replaced (NodeId 0))
  , expect "revoked certificate cannot be resurrected by a bare verdict" $ not (isGrounded revived (NodeId 0))
  , expect "asserted-unconfirmed, reported, presupposed, and translated evidence stay weak" $ all (\g -> supported g 0 && not (isGrounded g (NodeId 0))) weakGraphs
  , expect "nested reporting preserves both sources" $ all (\s -> not (supported (fst (withdrawSource (SourceId s) reportedGraph)) 0)) ["speaker:Anne", "speaker:Bob", "report-doc"]
  , expect "new evidence from a revoked source stays disabled" $ not (supported (addReportedNode (NodeId 0) report revokedReport) 0)
  , expect "duplicate hearsay is idempotent and stays weak" $ supportLabels reportedGraph == supportLabels (addReportedNode (NodeId 0) report reportedGraph) && not (isGrounded reportedGraph (NodeId 0))
  , expect "changing antecedent content invalidates its incident inference" $ not (isGrounded changedAntecedent (NodeId 1))
  , expect "changing target content invalidates its old inference" $ not (isGrounded changedTarget (NodeId 1))
  ]
  where
    forged = addJustification (premise (NodeId 0) "forged verdict")
           (addNode (Node (NodeId 0) (cl 0) (pv "A")) Confirmed emptyGenealogy)
    confirmed = cert 0 "A" emptyGenealogy
    replaced = addNode (Node (NodeId 0) (cl 99) (pv "A")) Confirmed confirmed
    revived = setVerdict (NodeId 0) Confirmed (setVerdict (NodeId 0) Refuted confirmed)
    derived = edge 1 [0] . raw 1 . cert 0 "A" $ emptyGenealogy
    changedAntecedent = addNode (Node (NodeId 0) (cl 99) (pv "A")) Confirmed derived
    changedTarget = addNode (Node (NodeId 1) (cl 99) (pv "A")) Confirmed derived
    reportedGraph = addReportedNode (NodeId 0) report emptyGenealogy
    revokedReport = fst (withdrawSource (SourceId "speaker:Bob") reportedGraph)
    weakGraphs =
      [ addAssertedNode (NodeId 0) (pv "asserted-doc") (assertion (cl 0)) emptyGenealogy
      , reportedGraph
      , addPresupposedNode (NodeId 0) presup emptyGenealogy
      , addTranslatedNode (NodeId 0) "test-model" (cl 0) (pv "translation-doc") emptyGenealogy
      ]

retractionChecks :: [Check]
retractionChecks =
  [ expectEq "independent alternatives keep exact minimal environments" [[NodeId 0],[NodeId 1]] (sort (independentSupports bothSupport (NodeId 2)))
  , expect "conjunction needs both sources" $ not (supported afterA 3)
  , expect "independent alternative survives source withdrawal" $ supported afterA 2 && isGrounded afterA (NodeId 2)
  , expect "withdrawing both sources removes their descendants" $ not (supported afterBoth 2) && not (supported afterBoth 3)
  , expect "source withdrawal is order-independent" $ supportLabels afterBoth == supportLabels afterReverse
  , expect "source withdrawal is idempotent" $ supportLabels afterA == supportLabels (fst (withdrawSource (SourceId "A") afterA))
  , expect "nonexistent node cannot survive" $ not (survivesRetractionOf (NodeId 0) (NodeId 99) unsupported)
  , expect "never-grounded node cannot survive" $ not (survivesRetractionOf (NodeId 0) (NodeId 2) unsupported)
  , expectEq "survivor report excludes never-grounded downstream" [] (rrSurvived (retractionReport (NodeId 0) unsupported))
  , expect "unconfirmed premises are not independent strong supports" $ not (hasIndependentSupport unconfirmed (NodeId 2))
  , expect "nested alternatives preserve independent support" $ hasIndependentSupport nested (NodeId 3)
  , expect "oracle withdrawal preserves report support but removes strong support" $ supported mixedAfter 2 && not (isGrounded mixedAfter (NodeId 2))
  , expect "reported rule taints an otherwise oracle-supported derivation" $ supported weakRule 2 && not (isGrounded weakRule (NodeId 2))
  , expect "withdrawal of rule evidence removes that conclusion" $ not (supported (fst (withdrawSource (SourceId "rule-doc") weakRule)) 2)
  , expect "same speaker across documents retains separate document dependencies" $ supported afterDoc 1 && not (supported afterDoc 0)
  , expect "speaker withdrawal reaches every dependent document" $ not (supported afterSpeaker 0) && not (supported afterSpeaker 1)
  , expect "oracle alternatives on one node survive separate oracle withdrawal" $ isGrounded afterOneOracle (NodeId 0) && not (isGrounded afterTwoOracles (NodeId 0))
  , expectEq "withdrawal report distinguishes all-support loss and surviving alternatives" (SupportChange [NodeId 0,NodeId 3] [NodeId 0,NodeId 3] [NodeId 2]) (snd (withdrawSource (SourceId "A") bothSupport))
  , expectEq "weak survivor reports lost grounding without lost support" (SupportChange [NodeId 0] [NodeId 0,NodeId 2] [NodeId 2]) (snd (withdrawSource (SourceId "A") mixed))
  ]
  where
    documents = addReportedNode (NodeId 1) (reportFrom "doc2") . addReportedNode (NodeId 0) (reportFrom "doc1") $ emptyGenealogy
    afterDoc = fst (withdrawSource (SourceId "doc1") documents)
    afterSpeaker = fst (withdrawSource (SourceId "speaker:Bob") documents)
    oracleAlternatives = addConfirmedNode (NodeId 0) (pv "B") (certificate "B" (cl 0)) . addConfirmedNode (NodeId 0) (pv "A") (certificate "A" (cl 0)) $ emptyGenealogy
    afterOneOracle = fst (withdrawSource (SourceId "oracle:A") oracleAlternatives)
    afterTwoOracles = fst (withdrawSource (SourceId "oracle:B") afterOneOracle)
    afterA = fst (withdrawSource (SourceId "A") bothSupport)
    afterBoth = fst (withdrawSource (SourceId "B") afterA)
    afterReverse = fst (withdrawSource (SourceId "A") (fst (withdrawSource (SourceId "B") bothSupport)))
    unsupported = edge 2 [0,1] . raw 2 . raw 1 . cert 0 "A" $ emptyGenealogy
    unconfirmed = edge 2 [0] . edge 2 [1] . raw 2
                . addAssertedNode (NodeId 1) (pv "B") (assertion (cl 1))
                . addAssertedNode (NodeId 0) (pv "A") (assertion (cl 0)) $ emptyGenealogy
    nested = edge 3 [2] . edge 3 [0] . edge 2 [0] . edge 2 [1]
           . raw 3 . raw 2 . cert 1 "B" . cert 0 "A" $ emptyGenealogy
    mixed = edge 2 [0] . edge 2 [1] . raw 2 . cert 0 "A"
          . addReportedNode (NodeId 1) report $ emptyGenealogy
    mixedAfter = fst (withdrawSource (SourceId "A") mixed)
    weakRule = edge 2 [0,1] . raw 2 . cert 0 "A"
             . addTranslatedNode (NodeId 1) "rule-translator" (CanImp (Canonical [] [cl 0]) (Canonical [] [cl 2])) (pv "rule-doc") $ emptyGenealogy

fusionChecks :: [Check]
fusionChecks =
  [ expectEq "fusion retains independent oracle alternatives" 2 (length (supportEnvironments (fusedSupport base (cl 0))))
  , expect "fusion oracle withdrawal keeps independent confirmation" $ fusedContains (withoutOracle "A" base) (cl 0)
  , expect "fusion losing both oracles drops the claim" $ not (fusedContains (withoutOracle "B" (withoutOracle "A" base)) (cl 0))
  , expect "fusion implication proof includes rule and premise confirmations" $ M.lookup (cl 1) (entailedWithSupport theory) == Just (supportTimes (fusedSupport theory (cl 0)) (fusedSupport theory implication))
  , expect "fusion removing rule oracle withdraws derived conclusion" $ cl 1 `notElem` entailedFrom (withoutOracle "rule" theory)
  , expect "fusion does not detach a consequent's existential witness as a free literal" $ null (detachable [cl 0] existential)
  ]
  where
    base = fuse [certificate "A" (cl 0), certificate "B" (cl 0)]
    implication = CanImp (Canonical [] [cl 0]) (Canonical [] [cl 1])
    theory = fuse [certificate "fact" (cl 0), certificate "rule" implication]
    existential = CanImp (Canonical [] [cl 0]) (Canonical [CRef 0] [CanPred "q" [CRefT (CRef 0)]])

type Edge = (Int, Int)

smallGraph :: [Edge] -> S.Set Int -> Genealogy
smallGraph edges seeds = foldr (\(a,b) -> edge b [a]) nodes edges
  where nodes = foldr (\i -> if i `S.member` seeds then cert i ("s" ++ show i) else raw i) emptyGenealogy [0,1,2]

booleanClosure :: [Edge] -> S.Set Int -> S.Set Int
booleanClosure edges = go
  where go old = let new = S.union old (S.fromList [b | (a,b) <- edges, a `S.member` old])
                 in if new == old then old else go new

cyclicChecks :: [Check]
cyclicChecks =
  [ expect "512 graphs x 8 seed sets x 8 valuations agree with Boolean closure" $ all agrees cases
  , expect "512 graphs x 8 seed sets x 8 source withdrawals equal recomputation" $ all retracts cases
  , expect "512 graphs x 8 seed sets are independent of edge reversal" $ and [supportLabels (smallGraph e s) == supportLabels (smallGraph (reverse e) s) | e <- graphs, s <- valuations]
  ]
  where
    graphs = subsequences [(a,b) | a <- [0,1,2], b <- [0,1,2]]
    cases = [(e,s,v,smallGraph e s) | e <- graphs, s <- valuations, v <- valuations]
    agrees (e,s,v,g) = S.fromList [i | i <- [0,1,2], any (all (\evidence -> let NodeId n = evidenceNode evidence in n `S.member` v)) (supportEnvironments (supportOf g (NodeId i)))] == booleanClosure e (S.intersection s v)
    retracts (e,s,v,g) = supportLabels (foldr (\i acc -> fst (withdrawSource (SourceId ("s" ++ show i)) acc)) g (S.toList v)) == supportLabels (smallGraph e (s `S.difference` v))

main :: IO ()
main = runChecks "strength" (algebraChecks ++ admissionChecks ++ retractionChecks ++ fusionChecks ++ cyclicChecks)
