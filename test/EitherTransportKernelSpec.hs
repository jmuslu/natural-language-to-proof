module Main (main) where
import qualified Data.Map.Strict as M
import Harness
import NL2Proof.Semantics.Lambda
import NL2Proof.Semantics.CCGSem (coordTerm)
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
main=runChecks "either-transport-kernel" $ assemblyChecks ++ vpWrapperChecks ++
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

-- Actual production VP coordination wrapper: GQ->t, not predicate pointwise OR.
-- The independent path [0,1,0] is Lam subject / App argument / Lam entity.
vpWrapperChecks :: [Check]
vpWrapperChecks=case coordTerm TOr (tyGQ ~> TyT) (vp "red") (vp "big") of
 Nothing->[bad "production VP coordination exists" "coordTerm returned Nothing"]
 Just coordinated->
  [expect "actual coordTerm VP has GQ->t type and known wrapper origin"
     (typeOf [] coordinated==Right(tyGQ ~> TyT) && right(active [] coordinated (orig[([0,1,0],(10,True))]))(const True))
  ,expect "actual shared-subject wrapper transports OR through a named subject"
     (check coordinated named (TOr(red bob)(big bob)) [])
  ,expect "actual shared-subject wrapper keeps one existential outside OR"
     (check coordinated existential (TExists "x" TyE(TAnd(thing x)(TOr(red x)(big x)))) [0,1])
  ,expect "actual shared-subject wrapper keeps universal outside OR"
     (check coordinated universal (TForall "x" TyE(TImp(thing x)(TOr(red x)(big x)))) [0,1])
  ]
 where
  x=Var "x"
  bob=entity "Bob"
  red=App(pred1 "red")
  big=App(pred1 "big")
  thing=App(pred1 "thing")
  vp name=Lam "S" tyGQ(App(Var "S")(Lam "x" TyE(App(pred1 name)x)))
  named=Lam "P" tyPred1(App(Var "P")bob)
  existential=Lam "P" tyPred1(TExists "x" TyE(TAnd(thing x)(App(Var "P")x)))
  universal=Lam "P" tyPred1(TForall "x" TyE(TImp(thing x)(App(Var "P")x)))
  check coordinated subject expected path=
   right(active [](App coordinated subject)(orig[([0,0,1,0],(10,True))])) $ \r->
     alphaEq(resultTerm r)expected && snd(evidenceSnapshot(resultEvidence r))==orig[(path,(10,True))]

assemblyChecks :: [Check]
assemblyChecks=
 [expect "assembly prefixes actual children and keeps active origin" (right built (\ev->right(dispatch [] PairedActive combined ev)(\r->snd(evidenceSnapshot(resultEvidence r))==combinedMap)))
 ,expect "assembly rejects wrong inserted child snapshot" (left StaleEvidence(assembleEvidence [] PairedActive combined [([0],a,passiveEvidence [] b one),([1],b,eb)] M.empty))
 ,expect "assembly rejects wrong child embedding" (left InvalidEmbedding(assembleEvidence [] PairedActive combined [([1],a,ea)] M.empty))
 ,expect "assembly rejects overlapping child prefixes" (left InvalidEmbedding(assembleEvidence [] PairedActive combined [([],combined,passiveEvidence [] combined combinedMap),([0],a,ea)] M.empty))
 ,expect "assembly rejects introduced/child origin collision" (left OriginCollision(assembleEvidence [] PairedActive combined inputs(orig[([0],(99,False))])))
 ,expect "assembly rejects missing introduced outer OR" (left InvalidOrigins(assembleEvidence [] PairedActive(TOr a b) inputs M.empty))
 ,expect "assembly certifies introduced outer OR separately" (right(assembleEvidence [] PairedActive(TOr a b) inputs(orig[([],(30,False))]))(\ev->right(dispatch [] PairedActive(TOr a b)ev)(\r->snd(evidenceSnapshot(resultEvidence r))==M.insert[](30,False)combinedMap)))
 ,expect "active assembly rejects unavailable ordinary child" (left UnavailableOrigin(assembleEvidence [] PairedActive combined [([0],a,passiveEvidence [] a M.empty),([1],b,eb)] M.empty))
 ,expect "ordinary unavailable assembly retains every original child" (let badInputs=[([0],a,passiveEvidence [] a M.empty),([1],b,eb)]
    in right(assembleEvidence [] Ordinary combined badInputs M.empty)(\ev->evidenceInputs ev==badInputs && evidenceFailure ev==Just UnavailableOrigin && right(dispatch [] Ordinary combined ev)(\r->resultTerm r==combined && evidenceInputs(resultEvidence r)==badInputs) && left UnavailableOrigin(dispatch [] PairedActive combined ev)))
 ,expect "assembly cannot reset active child to ordinary or pending" (right(active []a one)(\r->all(\mode->left InvalidModeTransition(assembleEvidence [] mode combined [([0],a,resultEvidence r),([1],b,eb)]M.empty))[Ordinary,PairedPending]))
 ,expect "assembly cannot reset pending child to ordinary" (right(dispatch [] PairedPending a ea)(\r->left InvalidModeTransition(assembleEvidence [] Ordinary combined [([0],a,resultEvidence r),([1],b,eb)]M.empty)))
 ,expect "ordinary incomplete assembly keeps production normalization/key" (right(assembleEvidence [] Ordinary(TAnd a a)[([0],a,ea),([1],a,ea)]M.empty)(\ev->right(dispatch [] Ordinary(TAnd a a)ev)(\r->resultTerm r==simplifyConj(normalize(TAnd a a)) && resultKey r==OrdinaryKey(canonicalAC a))))
 ]
 where
  ea=passiveEvidence [] a one
  eb=passiveEvidence [] b(orig[([],(20,False))])
  combined=TImp a b
  inputs=[([0],a,ea),([1],b,eb)]
  combinedMap=orig[([0],(10,True)),([1],(20,False))]
  built=assembleEvidence [] PairedActive combined inputs M.empty
