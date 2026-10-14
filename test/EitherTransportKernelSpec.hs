module Main (main) where
import qualified Data.Map.Strict as M
import Harness
import NL2Proof.Semantics.Lambda
import NL2Proof.Semantics.OrOccurrence

type Origin=(Int,Bool)
p,q,a,b :: Term
p=Con "P" TyT
q=Con "Q" TyT
a=TOr p q
b=TOr q p
orig :: [(Path,Origin)] -> M.Map Path Origin
orig=M.fromList
one :: M.Map Path Origin
one=orig[([],(10,True))]
active :: Ctx -> Term -> M.Map Path Origin -> Either Failure (Result Origin)
active ctx t m=dispatch ctx PairedActive t(passiveEvidence ctx t m)
right :: Either a b -> (b->Bool) -> Bool
right (Right x) f=f x
right _ _=False
left :: Eq a => a -> Either a b -> Bool
left want(Left got)=want==got
left _ _=False
ordinary :: Term -> M.Map Path Origin -> Bool
ordinary t m=right(dispatch [] Ordinary t(passiveEvidence [] t m)) $ \r->
 resultTerm r==simplifyConj(normalize t) && resultKey r==OrdinaryKey(canonicalAC(simplifyConj(normalize t)))
main :: IO ()
main=runChecks "either-transport-kernel" $
 [expect ("ordinary production output/key unchanged: "++label)(ordinary t m)
 |(label,t,m)<-
  [("plain",a,orig[([],(1,False))])
  ,("duplicate OR",TAnd a a,orig[([0],(1,False)),([1],(2,False))])
  ,("flatten",TAnd(TAnd a p)q,orig[([0,0],(1,False))])
  ,("reorder",TAnd b a,orig[([0],(1,False)),([1],(2,False))])
  ,("beta duplicate",App(Lam "x" TyT(TImp(Var "x")(Var "x")))a,orig[([1],(1,False))])
  ,("beta discard",App(Lam "x" TyT p)a,orig[([1],(1,False))])
  ,("missing origins",a,M.empty)]] ++
 [expect "TF identical formula occurrences remain distinct" (right(active [](TImp a a)(orig[([0],(10,True)),([1],(20,False))]))
    (\r->snd(evidenceSnapshot(resultEvidence r))==orig[([0],(10,True)),([1],(20,False))]))
 ,expect "FT and TF active keys differ" (case(active [](TImp a a)(orig[([0],(10,True)),([1],(20,False))]),active [](TImp a a)(orig[([0],(10,False)),([1],(20,True))]))of
    (Right x,Right y)->resultKey x/=resultKey y; _->False)
 ,expect "ordinary keys ignore different origin maps" (case(dispatch [] Ordinary a(passiveEvidence [] a one),dispatch [] Ordinary a(passiveEvidence [] a(orig[([],(20,False))])))of
    (Right x,Right y)->resultKey x==resultKey y; _->False)
 ,expect "ordinary keys ignore availability, preserving existing ties" (case(dispatch [] Ordinary a(passiveEvidence [] a one),dispatch [] Ordinary a(passiveEvidence [] a M.empty))of
    (Right x,Right y)->resultKey x==resultKey y && resultTerm x==resultTerm y; _->False)
 ,expect "ordinary root winner unchanged for ties and availability order" (all sameWinner [False,True])
 ,expect "pending and completed states cannot pack together" (case(dispatch [] PairedPending a(passiveEvidence [] a one),active [] a one)of
    (Right x,Right y)->resultKey x/=resultKey y; _->False)
 ,expect "active evidence cannot downgrade to ordinary or pending" (right(active [] a one)(\r->all(\mode->left InvalidModeTransition(dispatch [] mode(resultTerm r)(resultEvidence r)))[Ordinary,PairedPending]))
 ,expect "pending evidence cannot downgrade to ordinary" (right(dispatch [] PairedPending a(passiveEvidence [] a one))(\r->left InvalidModeTransition(dispatch [] Ordinary(resultTerm r)(resultEvidence r))))
 ,expect "active beta identity moves origin to root" (right(active [](App(Lam "x" TyT(Var "x"))a)(orig[([1],(10,True))]))
    (\r->resultTerm r==a && snd(evidenceSnapshot(resultEvidence r))==one))
 ,expect "capture avoidance uses production subst" (let t=App(Lam "x" TyT(Lam "y" TyT(Var "x")))(TOr(Var "y")q)
    in right(active [("y",TyT)]t(orig[([1],(10,True))]))(\r->resultTerm r==normalize t && freeVars(resultTerm r)==["y"] && snd(evidenceSnapshot(resultEvidence r))==orig[([0],(10,True))]))
 ,expect "shadowing preserves body origin" (let t=App(Lam "x" TyT(Lam "x" TyT a))p
    in right(active []t(orig[([0,0,0],(10,True))]))(\r->resultTerm r==normalize t && snd(evidenceSnapshot(resultEvidence r))==orig[([0],(10,True))]))
 ,expect "active marked beta duplication rejected" (left UnsupportedBetaUse(active [](App(Lam "x" TyT(TImp(Var "x")(Var "x")))a)(orig[([1],(10,True))])))
 ,expect "active marked beta deletion rejected" (left UnsupportedBetaUse(active [](App(Lam "x" TyT p)a)(orig[([1],(10,True))])))
 ,expect "active conjunction rewrite rejected" (left UnsupportedConjunctionRewrite(active [](TAnd a a)(orig[([0],(10,True)),([1],(20,False))])))
 ,expect "passive failure retains original snapshot and cannot activate" (let t=TAnd a a;m=orig[([0],(10,False)),([1],(20,False))]
    in right(dispatch [] Ordinary t(passiveEvidence []t m))(\r->evidenceSnapshot(resultEvidence r)==(t,m) && evidenceFailure(resultEvidence r)==Just UnsupportedConjunctionRewrite && left UnavailableOrigin(dispatch [] PairedActive(resultTerm r)(resultEvidence r))))
 ,expect "stale available snapshot rejected" (left StaleEvidence(dispatch [] PairedActive b(passiveEvidence [] a one)))
 ,expect "missing inner OR origin cannot activate" (left UnavailableOrigin(active [](TOr a b)(orig[([],(30,False)),([0],(10,True))])))
 ,expect "forged predicate origin cannot activate" (left UnavailableOrigin(active [] p one))
 ,expect "illtyped active input rejected" (left UnavailableOrigin(active [](TOr(entity "Bob")q)one))
 ,expect "negation/binder paths preserved" (let t=TExists "z" TyE(TNot a);m=orig[([0,0],(10,True))]
    in right(active []t m)(\r->resultTerm r==t && snd(evidenceSnapshot(resultEvidence r))==m))
 ,expect "outer plain OR cannot inherit inner marker" (let m=orig[([],(30,False)),([0],(10,True)),([1],(20,False))]
    in right(active [](TOr a b)m)(\r->snd(evidenceSnapshot(resultEvidence r))==m))
 ]

-- Same Map selection policy as the root: preserve existing score/tie winner.
-- This tests dispatcher keys; it is not a chart-search integration test.
sameWinner :: Bool -> Bool
sameWinner reverseOrder = oldWinner==newWinner
 where
  records0=[(a,one,2::Int,0::Int),(a,M.empty,2,1),(b,orig[([],(20,False))],1,2)]
  records=if reverseOrder then reverse records0 else records0
  choose new old=if fst new>fst old then new else old
  oldWinner=M.fromListWith choose [(canonicalAC(simplifyConj(normalize t)),(score,ident))|(t,_,score,ident)<-records]
  newWinner=M.fromListWith choose [(key,(score,ident))|(t,m,score,ident)<-records,
      Right r<-[dispatch [] Ordinary t(passiveEvidence [] t m)],OrdinaryKey key<-[resultKey r]]
