-- Independent future construction controls; miniature dictionary, no corpus.
module Main (main) where
import qualified Data.Set as Set
import Harness
import NL2Proof.DRT.Canonical
import NL2Proof.Pipeline
import NL2Proof.Provenance
import NL2Proof.Syntax.CCGBank (parseCCGCat)
import NL2Proof.Syntax.CCGParse (Rules(..))
import NL2Proof.Syntax.CCGSemParse
import NL2Proof.Syntax.CCGSupertag (buildTagModel,buildPOSModel)
import NL2Proof.Syntax.Tokenize (casedTokens)
import NL2Proof.Verify.ClaimKind (claimCond)
import NL2Proof.Verify.Reported (splitClaims)

cc = either error id . parseCCGCat
mini = (defaultSemModel (buildTagModel [(w,cc c)|(w,c,_)<-entries])
  (buildPOSModel [(w,p)|(w,_,p)<-entries]) (Rules [] []) Set.empty)
  {smAlpha=0,smSeenRules=False}
 where
  entries = [("every","NP[nb]/N","DT"),("a","NP[nb]/N","DT"),
          ("an","NP[nb]/N","DT"),("is","(S[dcl]\\NP)/NP","VBZ"),
          ("is","(S[dcl]\\NP)/(S[adj]\\NP)","VBZ"),(".",".","."),
          ("and","conj","CC"),("or","conj","CC"),
          ("that","(NP\\NP)/(S[dcl]\\NP)","WDT"),
          ("Mira","NP","NNP"),("Nora","NP","NNP")]
       ++ [(w,"N","NN")|w<-["cat","animal","mammal"]]
       ++ [(w,c,"JJ")|w<-["red","quiet"],c<-["N/N","S[adj]\\NP"]]
p name=CanPred name [CRefT(CRef 0)]
box=Canonical []
result text=case prSentences(runPipelineWith(CCGBankParser mini)(SourceId "property-plan")text) of
 [s]->s
 _->error "one fixture sentence required"
check text restriction consequence embedded =
 let wanted=Canonical [] [whole]
     whole=CanImp(Canonical [CRef 0] restriction)(box consequence)
     s=result text
     status=case srDRS s of
       Just d->let(as,rs,ps,es)=splitClaims d in
          map(claimCond.fst)as==[whole] && map claimCond es==embedded && null rs && null ps
       _->False
 in [expectEq ("selected independent property meaning: "++text) (Just wanted)(canonicalize <$> srDRS s)
    ,expect ("whole implication Asserted, nested properties Embedded: "++text) status
    ,expect ("all retained meanings faithful: "++text)
       (not(null(srReadings s)) && all ((==Just wanted).fmap canonicalize.rrDRS)(srReadings s))]
completed text=any isComplete (spRoots(semParse mini(SourceId "property-plan")(casedTokens 0 text)))
 where isComplete s=case ssNominal s of NominalComplete{}->True;NominalNamedComplete{}->True;_->False
main=runChecks "nominal-property independent future controls"
 (check "Every cat is an animal." [p "cat"] [p "animal"] [p "cat",p "animal"]
 ++check "Every red cat is an animal." [p "cat",p "red"] [p "animal"] [p "cat",p "red",p "animal"]
 ++check "Every cat is a red animal." [p "cat"] [p "animal",p "red"] [p "cat",p "animal",p "red"]
 ++check "Every cat is an animal and mammal." [p "cat"] [p "animal",p "mammal"] [p "cat",p "animal",p "mammal"]
 ++let disj=CanOr(box[p "animal"])(box[p "mammal"])
    in check "Every cat is an animal or mammal." [p "cat"] [disj] [p "cat",disj,p "animal",p "mammal"]
 ++check "Every cat that is red is an animal." [p "cat",p "red"] [p "animal"] [p "cat",p "red",p "animal"]
 ++check "Every cat is an animal that is quiet." [p "cat"] [p "animal",p "quiet"] [p "cat",p "animal",p "quiet"]
 ++[expect ("unsupported frame cannot gain nominal completion: "++text) (not(completed text))
     |text<-["Every cat is red.","Mira is Nora.","A cat is an animal.",
             "Every cat is a Mira.","Every cat is every animal.",
             "Mira says every cat is an animal."]])
