-- Independent bounded interface obligations, intentionally red before source work.
module Main (main) where
import qualified Data.Set as Set
import qualified Data.Map as Map
import Harness
import NL2Proof.Pipeline
import NL2Proof.Provenance
import NL2Proof.Semantics.CCGSem
import NL2Proof.Semantics.Lambda
import NL2Proof.Syntax.CCGBank (CCat, parseCCGCat)
import NL2Proof.Syntax.CCGParse (Rules(..))
import NL2Proof.Syntax.CCGSemParse
import NL2Proof.Syntax.CCGSupertag (buildPOSModel, buildTagModel)
import NL2Proof.DRT.Build (toDRS)
import NL2Proof.DRT.Canonical
import NL2Proof.Verify.ClaimKind (claimCond)
import NL2Proof.Verify.Reported (splitClaims)
import NL2Proof.Bench.Export (drsJSON)
import NL2Proof.Bench.JSON

cc :: String -> CCat
cc = either error id . parseCCGCat
model :: SemModel
model = (defaultSemModel tags poses (Rules [] []) Set.empty)
  {smAlpha=0,smSeenRules=False}
 where
  obs=[("Bob","NP","NNP"),("is","(S[dcl]\\NP)/(S[adj]\\NP)","VBZ")
      ,("red","S[adj]\\NP","JJ"),("big","S[adj]\\NP","JJ")
      ,("either","(S[adj]\\NP)/(S[adj]\\NP)","RB")
      ,("or","conj","CC"),("and","conj","CC"),(".",".",".")]
  tags=buildTagModel [(w,cc c)|(w,c,_)<-obs]
  poses=buildPOSModel [(w,p)|(w,_,p)<-obs]
source :: SourceId
source=SourceId "either-independent-control"
red,big,disj,conj :: Term
red=App (pred1 "red") (entity "Bob")
big=App (pred1 "big") (entity "Bob")
disj=TOr red big
conj=TAnd red big
fallback :: Prov
fallback=ProvLex source (Span 0 6) "either"
plain :: Prov
plain=ProvLex source (Span 0 2) "or"
-- Exported flags in DRS preorder, independently fixed per clause.
markers :: JValue -> [(Bool,Bool)]
markers j@(JObj xs)= own ++ concatMap (markers.snd) xs
 where own=case (field "tag" j,field "either" j,field "either_scope_ambiguous" j) of
        (Just (JStr "or"),Just (JBool e),Just (JBool a))->[(e,a)]
        _->[]
markers (JArr xs)=concatMap markers xs
markers _=[]
checkSentence :: String -> Term -> [(Bool,Bool)] -> Bool
checkSentence text expected flags = length ss==1 && all matchesSentence ss
 where
  ss=prSentences(runPipelineWith (CCGBankParser model) source text)
  atom name=CanPred name [CConstT "Bob"]
  -- Independently fixed boxes/claim preorder; no lowering function as oracle.
  (root,embedded)=if expected==conj then ([atom "red",atom "big"],[])
    else let names=if expected==disj then ["red","big"] else ["big","red"]
             atoms=map atom names
         in ([CanOr (Canonical [] [head atoms]) (Canonical [] [last atoms])],atoms)
  target=Canonical [] root
  partition d=let(a,r,p,e)=splitClaims d
              in (map (claimCond.fst) a,null r,null p,map claimCond e)
  matches d=canonicalize d==target && partition d==(root,True,True,embedded)
            && markers(drsJSON d)==flags
  matchesSentence s=not(null(srReadings s)) && maybe False matches(srDRS s)
      && all (maybe False matches . rrDRS) (srReadings s)
reject :: String -> Bool
reject text=all (null.srReadings) (prSentences(runPipelineWith (CCGBankParser model) source text))
main :: IO ()
main=runChecks "either-interface-proposal"
 [expect "plain OR: every DRS/claim and no marker" (checkSentence "Bob is red or big." disj [(False,False)])
 ,expect "plain AND: every DRS/claim" (checkSentence "Bob is red and big." conj [])
 ,expect "paired either adjective OR: inclusive DRS, local marker" (checkSentence "Bob is either red or big." disj [(True,False)])
 ,expect "paired reversed adjective OR: inclusive DRS, local marker" (checkSentence "Bob is either big or red." (TOr big red) [(True,False)])
 ,expect "unpaired either is not erased" (reject "Bob is either red.")
 ,expect "either with AND cannot discharge" (reject "Bob is either red and big.")
 ,expect "repeated either cannot share a single OR" (reject "Bob is either either red or big.")
 ,expect "either reservation prerequisite" (isClosedClass "either")
 ,expectEq "single OR fallback historically marks either" [(True,False)] (markers(drsJSON(toDRS Map.empty fallback disj)))
 ,expectEq "two OR fallback honestly abstains" [(False,True),(False,True)]
    (markers(drsJSON(toDRS Map.empty fallback (TImp disj disj))))
 ,expectEq "required clause-local lowering: only antecedent either" [(True,False),(False,False)]
    (markers(drsJSON(toDRS Map.empty fallback (TImp disj disj))))
 ]
