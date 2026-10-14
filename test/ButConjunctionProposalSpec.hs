-- Direct semantic-combinator red controls: NO parser/model/corpus is loaded.
module Main (main) where
import qualified Data.Map as M
import Harness
import NL2Proof.DRT.Build (toDRS)
import NL2Proof.DRT.Canonical
import NL2Proof.Provenance
import NL2Proof.Semantics.CCGSem
import NL2Proof.Semantics.Lambda
import NL2Proof.Syntax.CCGBank (CCat, parseCCGCat)
import NL2Proof.Syntax.CCGSemParse
import NL2Proof.Verify.ClaimKind (claimCond)
import NL2Proof.Verify.Reported (splitClaims)

cc :: String -> CCat
cc = either error id . parseCCGCat
src :: SourceId
src = SourceId "but-independent"
leaf :: Int -> String -> Prov
leaf n word = ProvLex src (Span n (n + length word)) word
sign :: String -> Term -> Prov -> SSign
sign category meaning provenance = SSign
 { ssCat=cc category, ssSem=meaning, ssProv=provenance, ssScore=0
 , ssCoord=Nothing, ssStructural=Nothing, ssOpenConditional=False
 , ssConditionalRaised=False, ssList=Nothing, ssFused=FusedPlain, ssNotes=[] }
marker :: SSign
marker = (sign "conj" (Con "but" TyT) (leaf 20 "but")) {ssStructural=Just "but"}
join :: String -> SSign -> SSign -> Maybe SSign
-- Current export surface has no context-aware but API. This intentionally
-- incomplete lexical-prerequisite adapter makes the positives red now. Merely
-- adding but:conj will make negative controls fail: replace this adapter with
-- the reviewed occurrence API before claiming implementation acceptance.
join category l r = case closedEntries 0 "but" (cc "conj") of
 [] -> Nothing
 _ -> do
  ty <- semTy (cc category)
  tm <- coordTerm TAnd ty (ssSem l) (ssSem r)
  pure (sign category tm (provRule "proposed-contrast" [ssProv l,ssProv marker,ssProv r]))

p :: String -> Term -> Term
p name x = App (pred1 name) x
vp :: String -> Term
vp name = Lam "Q" tyGQ (App (Var "Q") (pred1 name))
bob :: Term
bob = entity "Bob"
clause :: String -> Int -> SSign
clause name n = sign "S[dcl]" (p name bob)
 (provRule "BwdApp" [leaf n "Bob", provRule "FwdApp" [leaf (n+4) "is",leaf (n+7) name]])
rightVP :: String -> SSign
rightVP name = sign "S[adj]\\NP" (vp name) (leaf 24 name)
claimsCheck :: String -> Maybe Term -> Canonical -> [CanonCond] -> Check
claimsCheck label term box asserted = expect label $ case term of
 Nothing -> False
 Just tm -> let d=toDRS M.empty (leaf 0 "fixture") (normalize tm)
                (as,rs,ps,es)=splitClaims d
            in canonicalize d==box && map (claimCond.fst) as==asserted && null rs && null ps && null es
main :: IO ()
main = runChecks "but-conjunction-proposal-expected-red"
 [claimsCheck "independent named target boxes and claims are representable"
    (Just (TAnd (p "tall" bob) (p "quiet" bob))) named namedAtoms
 ,claimsCheck "independent single-witness target boxes and claims are representable"
    (Just (TExists "x" TyE (TAnd (p "person" (Var "x"))
      (TAnd (p "tall" (Var "x")) (p "quiet" (Var "x"))))))
    (Canonical [CRef 0] existentialAtoms) existentialAtoms
 ,expect "RED lexical but:conj needs explicit structural entry" (not (null (closedEntries 0 "but" (cc "conj"))))
 ,claimsCheck "RED full-clause but asserts both independent predicates"
    (ssSem <$> join "S[dcl]" (clause "tall" 0) (clause "quiet" 24)) named namedAtoms
 ,claimsCheck "RED adjectival VP but preserves shared named subject"
    ((\s -> App (ssSem s) (Lam "P" (TyFun TyE TyT) (App (Var "P") bob))) <$>
      join "S[adj]\\NP" (sign "S[adj]\\NP" (vp "tall") (leaf 0 "tall")) (rightVP "quiet")) named namedAtoms
 ,claimsCheck "RED existential VP but keeps one person witness"
    ((\s -> App (ssSem s) (Lam "P" (TyFun TyE TyT)
      (TExists "x" TyE (TAnd (p "person" (Var "x")) (App (Var "P") (Var "x")))))) <$>
      join "S[adj]\\NP" (sign "S[adj]\\NP" (vp "tall") (leaf 0 "tall")) (rightVP "quiet"))
    (Canonical [CRef 0] existentialAtoms) existentialAtoms
 ,expect "exceptive NP but entry remains rejected" (null (closedEntries 0 "but" (cc "(NP\\NP)/NP")))
 ,expect "corrective negative left must not become ordinary contrast"
    (absent (join "S[dcl]" ((clause "tall" 0) {ssSem=TNot (p "tall" bob),ssProv=provRule "not" [leaf 0 "not",ssProv(clause "tall" 4)]}) (clause "quiet" 24)))
 ,expect "not-both tail remains rejected after prerequisite"
    (absent (join "S[dcl]" ((clause "tall" 0) {ssSem=TOr (p "tall" bob) (p "quiet" bob),ssProv=provRule "CoordApply" [leaf 0 "either",leaf 10 "or"]})
      (sign "S[dcl]" (TNot (TAnd (p "tall" bob) (p "quiet" bob))) (provRule "ellipsis-not-both" [leaf 24 "not",leaf 28 "both"]))))
 ]
 where
  namedAtoms=[CanPred "tall" [CConstT "Bob"],CanPred "quiet" [CConstT "Bob"]]
  named=Canonical [] namedAtoms
  existentialAtoms=[CanPred "person" [CRefT (CRef 0)],CanPred "tall" [CRefT (CRef 0)],CanPred "quiet" [CRefT (CRef 0)]]
  absent Nothing=True
  absent _=False
