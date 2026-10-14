module Main(main) where
import qualified Data.Map.Strict as M
import qualified Data.Set as Set
import Data.Maybe(isJust,isNothing)
import NL2Proof.Pipeline
import NL2Proof.Syntax.CCGSemParse
import NL2Proof.Syntax.CCGSupertag(buildTagModel,buildPOSModel)
import NL2Proof.Syntax.CCGParse(Rules(..))
import NL2Proof.Syntax.CCGBank(parseCCGCat)
import NL2Proof.Syntax.Tokenize(casedTokens)
import qualified NL2Proof.Syntax.CCG as H
import Harness
import NL2Proof.Provenance
import NL2Proof.Semantics.Lambda
import NL2Proof.DRT.Build
import NL2Proof.DRT.Types
import NL2Proof.DRT.Canonical(canonicalize)
import NL2Proof.Verify.Reported(splitClaims)
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
main=runChecks "either-carrier" $ pipelineChecks ++
 concat[checkPair "TT" (paired either1 or1)(paired either2 or2)
       ,checkPair "TF" (paired either1 or1)(plain or2)
       ,checkPair "FT" (plain or1)(paired either2 or2)]++
 [expect "missing antecedent origin rejected at exact path"
   (run(M.singleton[0,1,0](plain or2))==Left(MissingOrOrigin[0,0]))
 ,expect "surplus origin rejected rather than ignored"
   (run(M.insert[9](plain or1)(origins(plain or1)(plain or2)))==Left(UnconsumedOrOrigin[9]))
 ,expect "pre-normal rather than final paths rejected"
   (run(M.fromList[([0],plain or1),([1,0],plain or2)])==Left(MissingOrOrigin[0,0]))
 ,expect "only whole implication asserted; nested operators and atoms embedded"
   (case run(origins(plain or1)(plain or2)) of
      Right d -> let (as,rs,ps,es)=splitClaims d
                 in length as==1 && null rs && null ps && length es==7
      Left _ -> False)
 ,expect "legacy remains whole-provenance fallback"
   (orProvs(toDRS M.empty fallback term)==[fallback,fallback])
 ,expect "active attitude rejected before deindexing"
   (let att=apply(Con "say" (TyE ~> (TyS ~> TyT) ~> TyT))
          [entity "Mira",Lam "w" TyS (TOr (App(pred1 "red")(entity "Mira")) (App(pred1 "blue")(entity "Mira")))]
    in toDRSWithOrOrigins M.empty fallback att M.empty==Left(UnsupportedOrAttitude[]))
 ,expect "unsupported active lambda rejected"
   (toDRSWithOrOrigins M.empty fallback (Lam "x" TyE p) M.empty==Left(UnsupportedOrTerm[]))]

-- Public Pipeline success controls; same actual chart-minted fixture is reused
-- by the private module-context failure harness recorded in the notes.
fixtureText="Bob is either red or big."
fixtureSource=SourceId "carrier-pipeline"
fixtureModel=(defaultSemModel tags poses (Rules [] []) Set.empty)
  {smAlpha=0,smSeenRules=False,smEitherPolicy=EitherSurfaceInclusiveV1}
 where
  cc=either error id . parseCCGCat
  entries=[("Bob","NP","NNP"),("is","(S[dcl]\\NP)/(S[adj]\\NP)","VBZ")
    ,("either","(S[adj]\\NP)/(S[adj]\\NP)","RB")
    ,("red","S[adj]\\NP","JJ"),("big","S[adj]\\NP","JJ")
    ,("or","conj","CC"),(".",".",".")]
  tags=buildTagModel[(w,cc c)|(w,c,_)<-entries]
  poses=buildPOSModel[(w,p)|(w,_,p)<-entries]
fixtureRoots=spRoots(semParse fixtureModel fixtureSource(casedTokens 0 fixtureText))
pipelineChecks=ordinaryChecks ++ case prSentences(runPipelineWith(CCGBankParser fixtureModel)fixtureSource fixtureText) of
 [sentence]->
  [expect "public enabled Pipeline retains typed DRS for every root"
    (not(null(srReadings sentence))&&all(\r->isJust(rrForm r)&&isJust(rrDRS r)&&isNothing(rrOriginFailure r))(srReadings sentence))
  ,expect "public enabled Pipeline carries exact operator-only leaves"
    (all(\r->case rrDRS r of
      Just d->map provLeaves(orProvs d)==[[(fixtureSource,Span 7 13,"either"),(fixtureSource,Span 18 20,"or")]]
      Nothing->False)(srReadings sentence))
  ,expect "public selected form is inclusive, with no exclusion conjunct"
    (fmap canonicalAC(srForm sentence)==Just(canonicalAC(TOr(App(pred1 "red")(entity "Bob"))(App(pred1 "big")(entity "Bob")))))]
 _->[expect "public Pipeline one sentence fixture" False]

ordinaryChecks=
 [expect "enabled Ordinary preserves exact disabled reading observations"
   (snapshot fixtureModel==snapshot(fixtureModel{smEitherPolicy=EitherLegacyDisabled}))]
 where
  snapshot model=[[(H.sSem(rrSign r),H.sProv(rrSign r),rrForm r,rrDRS r,rrScore r,rrTrace r,rrOriginFailure r)
                  |r<-srReadings sentence]
                 |sentence<-prSentences(runPipelineWith(CCGBankParser model)fixtureSource "Bob is red or big.")]
