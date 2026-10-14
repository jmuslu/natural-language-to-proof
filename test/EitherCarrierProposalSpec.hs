-- Existing public lowering boundary observations, not a mock carrier implementation.
module Main(main) where
import qualified Data.Map.Strict as M
import Harness
import NL2Proof.Provenance
import NL2Proof.Semantics.Lambda
import NL2Proof.DRT.Build(toDRS)
import NL2Proof.DRT.Types
src=SourceId "independent-carrier-controls"
e=ProvLex src (Span 0 6) "either"
o1=ProvLex src (Span 11 13) "or"
o2=ProvLex src (Span 25 27) "or"
whole=provRule "sentence" [e,o1,o2]
p=App(pred1 "red")(Var "x")
q=App(pred1 "blue")(Var "x")
-- Equal OR meanings at distinct syntactic locations; first paired, second plain.
f=TForall "x" TyE (TImp (TOr p q) (TNot(TOr p q)))
d=toDRS M.empty whole f
main=runChecks "either-carrier-proposal" $ case d of
 DRS [] [CImp (DRS refs [COr left right pa]) (DRS [] [CNot (DRS [] [COr left2 right2 pb]) pn]) pi]->
  [expect "universal referent lives in antecedent only" (map fst refs==[Ref "x"])
  ,expect "branches reference same antecedent witness"
    (case (left,right) of
      (DRS [] [CPred "red" [DRef(Ref "x")] _],DRS [] [CPred "blue" [DRef(Ref "x")] _])->True
      _->False)
  ,expect "identical OR formulas can occupy distinct nested scopes"
    (left==left2&&right==right2)
  ,expect "legacy OR fallback aliases both occurrence provenances" (pa==whole&&pb==whole)
  ,expect "legacy fallback cannot uniquely pair either to one OR"
    (provLeaves pa==provLeaves pb&&length(provLeaves pa)==3)
  ,expect "non-OR scope provenance remains intact" (pn==whole&&pi==whole)
  ,expect "root has no leaked antecedent atoms" (length(drsConds d)==1)]
 _->[expect "independent universal/OR/NOT box shape" False]
