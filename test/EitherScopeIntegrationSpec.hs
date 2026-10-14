-- Actual public chart/Pipeline integration plus isolated constructor/kernel controls.
-- Map prefixing in the component controls is explicit; chart tests use real assembly.
module Main (main) where
import qualified Data.Map.Strict as M
import qualified Data.Set as Set
import Data.Maybe (isJust,isNothing)
import NL2Proof.Pipeline
import NL2Proof.Syntax.CCGSemParse
import NL2Proof.Syntax.CCGSupertag (buildTagModel,buildPOSModel)
import NL2Proof.Syntax.CCGParse (Rules(..))
import NL2Proof.Syntax.CCGBank (parseCCGCat)
import NL2Proof.Syntax.Tokenize (casedTokens,Token(..))
import qualified NL2Proof.DRT.Types as D
import Harness
import NL2Proof.Semantics.CCGSem
import NL2Proof.Semantics.Lambda
import NL2Proof.Semantics.OrOccurrence
import NL2Proof.DRT.Build (toDRS)
import NL2Proof.DRT.Canonical
import NL2Proof.Verify.Reported (splitClaims)
import NL2Proof.Verify.ClaimKind (claimCond)
import NL2Proof.Provenance

vp :: String -> Term
vp p=Lam "S" tyGQ (App (Var "S") (pred1 p))
atom :: String -> Term -> Term
atom=App . pred1
named :: Term
named=Lam "P" tyPred1 (App (Var "P") (entity "Mira"))
quant :: String -> Term
quant kind=Lam "P" tyPred1 (bind (App (Var "P") x))
 where
  x=Var "x"; noun=atom "cat" x
  bind=case kind of
   "every"->TForall "x" TyE . TImp noun
   "no"->TNot . TExists "x" TyE . TAnd noun
   _->TExists "x" TyE . TAnd noun
pair :: Maybe CoordLayout
pair=coordTermLocated CoordOr (tyGQ~>TyT) (vp "quiet") (vp "tall")
runSubject :: Term -> Either Failure (Result (Int,Bool))
runSubject subject=case pair of
 Nothing->Left InvalidOrigins
 Just l->let t=App(clTerm l)subject
             origins=M.singleton (0:clOperatorPath l) (1,True)
         in dispatch [] PairedActive t (passiveEvidence [] t origins)
right :: Either a b -> (b->Bool) -> Bool
right (Right r) f=f r
right _ _=False
scope :: String -> Term -> [Int] -> Bool
scope kind want path=right (runSubject(quant kind)) $ \r->
 alphaEq (resultTerm r) want && snd(evidenceSnapshot(resultEvidence r))==M.singleton path (1,True)

claimsMatch :: Result (Int,Bool) -> Bool
claimsMatch r=canonicalize d==Canonical [] [o] && map (claimCond.fst) as==[o]
 && null rs && null ps && map claimCond es==[p,q]
 where
 d=toDRS M.empty (ProvLex (SourceId "scope") (Span 0 1) "fixture") (resultTerm r)
 (as,rs,ps,es)=splitClaims d
 p=CanPred "quiet" [CConstT "Mira"];q=CanPred "tall" [CConstT "Mira"]
 o=CanOr (Canonical [] [p]) (Canonical [] [q])

main :: IO ()
main=runChecks "either-scope-integration" $ chartChecks ++
 [expect "reviewed81703a1 named inclusive formula and exact DRS/claims"
   (right(runSubject named)(\r->alphaEq(resultTerm r)(TOr(atom "quiet" mira)(atom "tall" mira)) && claimsMatch r))
 ,expect "every subject outside introduced OR" (scope "every" (TForall "x" TyE(TImp cat pq)) [0,1])
 ,expect "a subject introduces one shared witness" (scope "a" (TExists "x" TyE(TAnd cat pq)) [0,1])
 ,expect "no subject keeps OR inside negative existential" (scope "no" (TNot(TExists "x" TyE(TAnd cat pq))) [0,0,1])
 ,expect "OR under outer NOT transports occurrence without changing polarity" underNot
 ,expect "identical OR child formulas retain three independent origins" repeated
 ,expect "same-term marked and unmarked active keys differ" differentKeys
 ,expect "failed child evidence cannot activate" failed
 ,expect "ordinary mode preserves term despite failed evidence" ordinaryFailed
 ]
 where
 x=Var "x";mira=entity "Mira";cat=atom "cat" x;pq=TOr(atom "quiet" x)(atom "tall" x)

underNot :: Bool
underNot=case pair of
 Nothing->False
 Just l->let t=TNot(App(clTerm l)named);m=M.singleton([0,0]++clOperatorPath l)(1,True)
  in right(dispatch [] PairedActive t(passiveEvidence [] t m)) $ \r->
   alphaEq(resultTerm r)(TNot(TOr(atom "quiet"(entity "Mira"))(atom "tall"(entity "Mira"))))
   && snd(evidenceSnapshot(resultEvidence r))==M.singleton [0](1,True)

repeated :: Bool
repeated=case pair of
 Nothing->False
 Just child->case coordTermLocated CoordOr (tyGQ~>TyT)(clTerm child)(clTerm child) of
  Nothing->False
  Just parent->let t=App(clTerm parent)named
                   m=M.fromList[(0:clOperatorPath parent,(3,False))
                    ,(0:(clLeftPath parent++clOperatorPath child),(1,True))
                    ,(0:(clRightPath parent++clOperatorPath child),(2,False))]
    in right(dispatch [] PairedActive t(passiveEvidence [] t m)) $ \r->
       snd(evidenceSnapshot(resultEvidence r))==M.fromList[([],(3,False)),([0],(1,True)),([1],(2,False))]

differentKeys :: Bool
differentKeys=case pair of
 Nothing->False
 Just l->let t=App(clTerm l)named
             run flag=dispatch [] PairedActive t(passiveEvidence [] t(M.singleton(0:clOperatorPath l)(1,flag)))
  in case(run True,run False)of
   (Right a,Right b)->resultTerm a==resultTerm b && resultKey a/=resultKey b
   _->False
failed,ordinaryFailed :: Bool
failed=case pair of
 Nothing->False
 Just l->let t=App(clTerm l)named in case dispatch [] PairedActive t(passiveEvidence [] t (M.empty::M.Map Path (Int,Bool))) of
  Left UnavailableOrigin->True
  _->False
ordinaryFailed=case pair of
 Nothing->False
 Just l->let t=App(clTerm l)named in right(dispatch [] Ordinary t(passiveEvidence [] t(M.empty::M.Map Path (Int,Bool)))) $ \r->
  resultTerm r==simplifyConj(normalize t) && evidenceFailure(resultEvidence r)/=Nothing


-- Actual chart -> normalization -> Pipeline -> occurrence-aware DRT lowering.
-- Miniature dictionaries are lexical evidence fixtures, not copied constructors.
chartModel :: SemModel
chartModel=(defaultSemModel tags poses (Rules [] []) Set.empty)
 {smAlpha=0,smSeenRules=False,smEitherPolicy=EitherSurfaceInclusiveV1}
 where
 cc=either error id . parseCCGCat
 entries=[("Mira","NP","NNP"),("Noel","NP","NNP")
  ,("Every","NP[nb]/N","DT"),("No","NP[nb]/N","DT"),("A","NP[nb]/N","DT")
  ,("cat","N","NN"),("is","(S[dcl]\\NP)/(S[adj]\\NP)","VBZ")
  ,("either","(S[adj]\\NP)/(S[adj]\\NP)","RB")
  ,("quiet","S[adj]\\NP","JJ"),("tall","S[adj]\\NP","JJ")
  ,("young","S[adj]\\NP","JJ"),("red","S[adj]\\NP","JJ")
  ,("or","conj","CC"),("and","conj","CC"),(".",".",".")]
 tags=buildTagModel[(w,cc c)|(w,c,_)<-entries]
 poses=buildPOSModel[(w,p)|(w,_,p)<-entries]
chartSource :: SourceId
chartSource=SourceId "actual-either-integration"
chartSentences :: String -> [SentenceResult]
chartSentences=prSentences . runPipelineWith(CCGBankParser chartModel)chartSource
ors :: D.DRS -> [Prov]
ors (D.DRS _ conditions)=concatMap go conditions
 where
 go(D.COr a b p)=p:ors a++ors b
 go(D.CImp a b _)=ors a++ors b
 go(D.CNot a _)=ors a
 go _=[]
actual :: String -> Term -> Bool -> Bool
actual text expected marked=case chartSentences text of
 [sentence]->not(null(srReadings sentence))
   && fmap canonicalAC(srForm sentence)==Just(canonicalAC expected)
   && all check(srReadings sentence)
 _->False
 where
 expectedLeaves=[(chartSource,tokSpan t,tokText t)|t<-casedTokens 0 text,tokText t `elem` ["either","or"]]
 check reading=isNothing(rrOriginFailure reading) && fmap canonicalAC(rrForm reading)==Just(canonicalAC expected)
  && case rrDRS reading of
   Nothing->False
   Just d->case ors d of
    [p]->if marked then provLeaves p==expectedLeaves
                    else not("paired-or-occurrence" `elem` map show(provRuleNames p))
    _->False
namedGold :: Bool
namedGold=case chartSentences "Mira is either quiet or tall." of
 [sentence]->case srDRS sentence of
  Just d->let (as,rs,ps,es)=splitClaims d
              ;p=CanPred "quiet"[CConstT "Mira"];q=CanPred "tall"[CConstT "Mira"]
              ;o=CanOr(Canonical[][p])(Canonical[][q])
          in canonicalize d==Canonical[][o] && map(claimCond.fst)as==[o]
             && null rs && null ps && map claimCond es==[p,q]
  _->False
 _->False
chartChecks :: [Check]
chartChecks=
 [expect "actual marked named Pipeline + local origin"(actual "Mira is either quiet or tall." namedWant True)
 ,expect "actual second independently authored named Pipeline"(actual "Noel is either young or red."
    (TOr(atom "young"(entity "Noel"))(atom "red"(entity "Noel"))) True)
 ,expect "actual unmarked inclusive control"(actual "Mira is quiet or tall." namedWant False)
 ,expect "actual independent81703a1 DRS and claims" namedGold
 ,expect "actual every subject shared above OR"(actual "Every cat is either quiet or tall." (TForall "x" TyE(TImp cat pq)) True)
 ,expect "actual indefinite subject has one witness"(actual "A cat is either quiet or tall." (TExists "x" TyE(TAnd cat pq)) True)
 ,expect "actual no subject keeps OR under negative existential"(actual "No cat is either quiet or tall." (TNot(TExists "x" TyE(TAnd cat pq))) True)
 ,expect "actual every DRS and whole-implication assertion" (quantClaims "Every" everyDRS [imp] [catC,orC,pC,qC])
 ,expect "actual indefinite DRS and one witness assertions" (quantClaims "A" body [catC,orC] [pC,qC])
 ,expect "actual no DRS and negative assertion barrier" (quantClaims "No" noDRS [neg] [catC,orC,pC,qC])
 ,expect "actual roots with same term and different origin do not pack together" duplicateRoots
 ,expect "actual root rejects stale semantic evidence" staleRoot
 ] ++ [expect("actual lexical guard rejects "++text)(null(spRoots(semParse chartModel chartSource(casedTokens 0 text))))
       |text<-["Mira is either quiet.","Mira is either quiet and tall.","Mira is either either quiet or tall.","Mira is either quiet or tall but not both."]]
 where
 x=Var "x";cat=atom "cat" x;pq=TOr(atom "quiet" x)(atom "tall" x)
 namedWant=TOr(atom "quiet"(entity "Mira"))(atom "tall"(entity "Mira"))
 ref=CRefT(CRef 0)
 catC=CanPred "cat"[ref];pC=CanPred "quiet"[ref];qC=CanPred "tall"[ref]
 orC=CanOr(Canonical[][pC])(Canonical[][qC])
 body=Canonical[CRef 0][catC,orC]
 imp=CanImp(Canonical[CRef 0][catC])(Canonical[][orC])
 everyDRS=Canonical[][imp]
 neg=CanNot body
 noDRS=Canonical[][neg]
duplicateRoots :: Bool
duplicateRoots=case(get chartSource,get(SourceId "independent-source"))of
 (a:_,b:_)->ssSem a==ssSem b && length(packCell 20[a,b])==2
 _->False
 where get src=spRoots(semParse chartModel src(casedTokens 0 "Mira is either quiet or tall."))
staleRoot :: Bool
staleRoot=case spRoots(semParse chartModel chartSource(casedTokens 0 "Mira is either quiet or tall."))of
 root:_->case pairedOrOrigins(root{ssSem=atom "quiet"(entity "Mira")})of Left _->True;_->False
 _->False

quantClaims :: String -> Canonical -> [CanonCond] -> [CanonCond] -> Bool
quantClaims subject expected asserted embedded=case chartSentences(subject++" cat is either quiet or tall.")of
 [sentence]->case srDRS sentence of
  Just d->let (as,rs,ps,es)=splitClaims d
          in canonicalize d==expected && map(claimCond.fst)as==asserted
             && null rs && null ps && map claimCond es==embedded
  _->False
 _->False
