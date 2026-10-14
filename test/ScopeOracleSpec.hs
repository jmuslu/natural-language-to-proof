-- The oracle/fusion API receives one canonical condition, so it may only
-- confirm conditions whose referents are all bound inside that condition.
module Main (main) where

import Harness
import NL2Proof.DRT.Canonical
import NL2Proof.DRT.Types
import NL2Proof.Fusion
import NL2Proof.Genealogy
import NL2Proof.Provenance
import NL2Proof.Verify.ClaimKind
import NL2Proof.Verify.Claims
import NL2Proof.Verify.Oracle

r0, r1 :: CRef
r0 = CRef 0
r1 = CRef 1

p, q :: CRef -> CanonCond
p r = CanPred "P" [CRefT r]
q r = CanPred "Q" [CRefT r]

pv :: Prov
pv = ProvLex (SourceId "scope-oracle") (Span 0 1) "fixture"

-- Preserve the exact reference numbers by declaring all fixture refs in the
-- root. These outer bindings are deliberately not carried by a bare claim.
fixture :: CanonCond -> DRS
fixture cond = DRS [(Ref "r0", pv), (Ref "r1", pv)] [fromCond cond]
  where
    ref (CRef i) = Ref ("r" ++ show i)
    arg (CRefT r) = DRef (ref r)
    arg (CConstT name) = DConst name
    nested (Canonical us cs) = DRS [(ref r, pv) | r <- us] (map fromCond cs)
    fromCond c = case c of
      CanPred name args -> CPred name (map arg args) pv
      CanEq a b -> CEq (arg a) (arg b) pv
      CanNot k -> CNot (nested k) pv
      CanImp a b -> CImp (nested a) (nested b) pv
      CanOr a b -> COr (nested a) (nested b) pv
      CanAtt name args k -> CAtt name (map arg args) (nested k) pv
      CanPresup k -> CPresup (nested k) pv

credulous :: Oracle
credulous = Oracle "credulous" "test-only accepts every condition" (const True) (const True)

empty :: [CanonCond] -> Canonical
empty = Canonical []

bound :: CRef -> [CanonCond] -> Canonical
bound r = Canonical [r]

openExamples :: [(String, CanonCond)]
openExamples =
  [ ("positive root existential atom", p r0)
  , ("equality has free left reference", CanEq (CRefT r0) (CConstT "a"))
  , ("equality has free right reference", CanEq (CConstT "a") (CRefT r0))
  , ("negation inherits outer reference", CanNot (empty [p r0]))
  , ("material implication inherits outer reference", CanImp (empty [p r0]) (empty [q r0]))
  , ("consequent binder cannot bind antecedent", CanImp (empty [p r0]) (bound r0 [q r0]))
  , ("antecedent binder does not bind unrelated consequent ref", CanImp (bound r0 [p r0]) (empty [q r1]))
  , ("left disjunct binder does not bind right", CanOr (bound r0 [p r0]) (empty [q r0]))
  , ("right disjunct binder does not bind left", CanOr (empty [p r0]) (bound r0 [q r0]))
  , ("negative inner binder does not bind sibling", CanNot (empty [CanNot (bound r0 [p r0]), q r0]))
  , ("attitude holder is free", CanAtt "say" [CRefT r0] (bound r1 [p r1]))
  , ("attitude body has free reference", CanAtt "say" [CConstT "Bob"] (empty [p r0]))
  , ("presupposition body has free reference", CanPresup (empty [p r0]))
  ]

closedExamples :: [(String, CanonCond)]
closedExamples =
  [ ("rigid positive atom", CanPred "P" [CConstT "a"])
  , ("zero-arity proposition", CanPred "flag" [])
  , ("rigid equality", CanEq (CConstT "a") (CConstT "a"))
  , ("antecedent binder scopes over consequent", CanImp (bound r0 [p r0]) (empty [q r0]))
  , ("nested consequent existential may use antecedent binder", CanImp (bound r0 [p r0])
      (bound r1 [CanPred "R" [CRefT r0, CRefT r1]]))
  , ("existential under negation stays closed", CanNot (bound r0 [p r0]))
  , ("separate disjunct binders stay local", CanOr (bound r0 [p r0]) (bound r1 [q r1]))
  , ("nested material implication closed by enclosing existential", CanNot (bound r0
      [CanImp (empty [p r0]) (empty [q r0])]))
  , ("attitude rigid holder and closed existential content", CanAtt "say" [CConstT "Bob"] (bound r0 [p r0]))
  , ("closed presupposition inspectable but not assertable", CanPresup (bound r0 [p r0]))
  ]

main :: IO ()
main = runChecks "scope-oracle" $
  [ expect ("open: " ++ label) (check credulous c == Unknown && not (covers credulous c)
      && null (confirmAll credulous (map fst (assertedClaims (fixture c)))))
  | (label, c) <- openExamples ]
  ++ [ expect ("closed: " ++ label) (check credulous c == Confirmed && covers credulous c)
     | (label, c) <- closedExamples ]
  ++ [ expect "closed universal can receive token but cannot detach without instantiation"
       (let c = CanImp (bound r0 [p r0]) (empty [q r0])
            ts = confirmAll credulous (map fst (assertedClaims (fixture c)))
        in length ts == 1 && entailedFrom (fuse ts) == [c])
     , expect "open conditions remain extracted as truthful contextual claims"
       (length (ctFacts (claimsOfDRS "scope test" (fixture (p r0)))) == 1)
     , expect "open claim has neither confirmed verdict nor grounded genealogy seed"
       (let g = genealogyOf credulous (claimsOfDRS "scope test" (fixture (p r0)))
        in verdictOf g (NodeId 0) == Unknown && not (isGrounded g (NodeId 0)))
     , expect "coverage puts open condition outside oracle domain"
       (let cov = coverage credulous [p r0, CanPred "P" [CConstT "a"]]
        in covUncovered cov == [p r0] && covConfirmed cov == [CanPred "P" [CConstT "a"]])
     , expect "closed non-presupposed controls receive immutable confirmation tokens"
       (all (\(_, c) -> case c of
          CanPresup _ -> True
          _ -> length (confirmAll credulous (map fst (assertedClaims (fixture c)))) == 1)
         closedExamples)
     , expect "separately scoped truthful local oracles cannot derive false closed q"
       (let localP = p r0
            target = CanPred "q" []
            localRule = CanImp (empty [localP]) (empty [target])
            -- In the finite model P(a), not P(b), not q, the first
            -- document uses witness a and the second witness b.
            firstOracle = Oracle "witness-a" "P(a)" (== localP) (== localP)
            secondOracle = Oracle "witness-b" "P(b) implies q, vacuously" (== localRule) (== localRule)
            first = confirmAll firstOracle (map fst (assertedClaims (fixture localP)))
            second = confirmAll secondOracle (map fst (assertedClaims (fixture localRule)))
        in null first && null second && target `notElem` entailedFrom (fuse (first ++ second)))
     , expect "open rejection does not evaluate a partial oracle predicate"
       (check (Oracle "partial" "closed only" (error "covers forced") (error "holds forced")) (p r0) == Unknown)
     ]
