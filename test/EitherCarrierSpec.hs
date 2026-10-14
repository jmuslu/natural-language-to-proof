module Main(main) where
import qualified Data.Map.Strict as M
import Harness
import NL2Proof.Provenance
import NL2Proof.Semantics.Lambda
import NL2Proof.DRT.Build
import NL2Proof.DRT.Types
import NL2Proof.DRT.Canonical(canonicalize)
src=SourceId "carrier-independent"
leaf a b w=ProvLex src (Span a b) w
or1=leaf 10 12 "or"
or2=leaf 30 32 "or"
either1=leaf 0 6 "either"
either2=leaf 20 26 "either"
paired e o=provRule "paired-or-occurrence" [e,o]
plain o=provRule "or-occurrence" [o]
fallback=provRule "sentence" [either1,or1,either2,or2]
x=Var "x"
p=App(pred1 "red") x
q=App(pred1 "blue") x
term=TForall "x" TyE (TImp (TOr p q) (TNot(TOr p q)))
origins a b=M.fromList[([0,0],a),([0,1,0],b)]
run=toDRSWithOrOrigins M.empty fallback term
orProvs (DRS _ cs)=concatMap cond cs
 where
  cond(COr a b pv)=pv:orProvs a++orProvs b
  cond(CImp a b _)=orProvs a++orProvs b
  cond(CNot a _)=orProvs a
  cond _=[]
checkPair label a b=case run(origins a b) of
 Left _->[expect(label++": successful lowering") False]
 Right d->
  [expect(label++": independent operator occurrence order") (orProvs d==[a,b])
  ,expect(label++": scoped meaning matches legacy box shape")
    (canonicalize d==canonicalize(toDRS M.empty fallback term))]
main=runChecks "either-carrier" $
 concat[checkPair "TT" (paired either1 or1)(paired either2 or2)
       ,checkPair "TF" (paired either1 or1)(plain or2)
       ,checkPair "FT" (plain or1)(paired either2 or2)]++
 [expect "missing antecedent origin rejected at exact path"
   (run(M.singleton[0,1,0](plain or2))==Left(MissingOrOrigin[0,0]))
 ,expect "surplus origin rejected rather than ignored"
   (run(M.insert[9](plain or1)(origins(plain or1)(plain or2)))==Left(UnconsumedOrOrigin[9]))
 ,expect "pre-normal rather than final paths rejected"
   (run(M.fromList[([0],plain or1),([1,0],plain or2)])==Left(MissingOrOrigin[0,0]))
 ,expect "legacy remains whole-provenance fallback"
   (orProvs(toDRS M.empty fallback term)==[fallback,fallback])
 ,expect "active attitude rejected before deindexing"
   (let att=apply(Con "say" (TyE ~> (TyS ~> TyT) ~> TyT))
          [entity "Mira",Lam "w" TyS (TOr (App(pred1 "red")(entity "Mira")) (App(pred1 "blue")(entity "Mira")))]
    in toDRSWithOrOrigins M.empty fallback att M.empty==Left(UnsupportedOrAttitude[]))
 ,expect "unsupported active lambda rejected"
   (toDRSWithOrOrigins M.empty fallback (Lam "x" TyE p) M.empty==Left(UnsupportedOrTerm[]))]
