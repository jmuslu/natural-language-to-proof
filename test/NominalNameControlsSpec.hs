-- Independent future acceptance controls. Default includes known reds on v1.
-- No corpus load. Run against frozen v1 via its src directory on -i path.
module Main (main) where
import qualified Data.Map.Strict as M
import qualified Data.Set as S
import System.Environment (getArgs)
import Harness
import NL2Proof.DRT.Canonical
import NL2Proof.Pipeline
import NL2Proof.Provenance
import NL2Proof.Syntax.CCGBank (CCat,parseCCGCat)
import NL2Proof.Syntax.CCGParse (Rules(..))
import NL2Proof.Syntax.CCGSemParse
import NL2Proof.Syntax.CCGSupertag
import NL2Proof.Verify.ClaimKind (claimCond)
import NL2Proof.Verify.Reported (splitClaims)

cc :: String -> CCat
cc = either error id . parseCCGCat
model :: String -> [(String,Int)] -> SemModel
model nameCategory poses = (defaultSemModel tags pos (Rules [] []) S.empty)
 {smAlpha=0,smSeenRules=False}
 where
  entries = [("Ari",nameCategory,"NNP"),("animal","N","NN"),("cats","N","NNS")
    ,("a","NP[nb]/N","DT"),("an","NP[nb]/N","DT")
    ,("is","(S[dcl]\\NP)/NP","VBZ"),(".",".",".")
    ,("sees","(S[dcl]\\NP)/NP","VBZ")
    ,("says","(S[dcl]\\NP)/S[dcl]","VBZ")
    ,("not","(S[dcl]\\NP)\\(S[dcl]\\NP)","RB")]
  tags=buildTagModel [(w,cc c)|(w,c,_)<-entries]
  POSModel original=buildPOSModel [(w,p)|(w,_,p)<-entries]
  pos=POSModel (M.insert "Ari" (M.fromList poses) original)

sentence :: SemModel -> String -> SentenceResult
sentence m text=case prSentences (runPipelineWith (CCGBankParser m) (SourceId "independent-name-controls") text) of
 [one]->one
 _->error "one input sentence required"

-- Intended DRS and status are authored independently from lexical outputs.
positive :: [Check]
positive=concat
 [let result=sentence (model sourceCat [("NNP",4)]) "Ari is an animal."
      atom=CanPred "animal" [CConstT "Ari"]
      wanted=Canonical [] [atom]
  in [expectEq (sourceCat++" name subject exact direct classification")
       (Just wanted) (canonicalize <$> srDRS result)
     ,expect (sourceCat++" all readings preserve named classification")
       (not(null(srReadings result)) && all ((==Just wanted).fmap canonicalize.rrDRS) (srReadings result))
     ,expect (sourceCat++" only one Asserted classification atom")
       (case srDRS result of
         Nothing->False
         Just d->let (as,rs,ps,es)=splitClaims d
                 in map (claimCond.fst) as==[atom] && null rs && null ps && null es)]
 | sourceCat<-["NP","N"]]

blocked :: String -> SemModel -> String -> Check
blocked label m text=expect label (null (srReadings (sentence m text)))

boundaries :: [Check]
boundaries=
 [blocked "NNP majority plus rare NN must not certify" (model "NP" [("NNP",100),("NN",1)]) "Ari is an animal."
 ,blocked "NNP majority plus rare JJ must not certify" (model "NP" [("NNP",100),("JJ",1)]) "Ari is an animal."
 ,blocked "initial unknown capital does not certify" (model "NP" []) "Ari is an animal."
 ,blocked "NNPS plural-name evidence deferred" (model "NP" [("NNPS",4)]) "Ari is an animal."
 ,blocked "unknown plural-looking capital deferred" (model "NP" []) "Gorpuses is an animal."
 ,blocked "bare plural generic is not a certified name" (model "NP" [("NNP",4)]) "Cats is an animal."
 ,blocked "orphan nominal VP does not admit root" (model "NP" [("NNP",4)]) "Is an animal."
 ,blocked "nominal subject fragment is not a clause" (model "NP" [("NNP",4)]) "Ari."
 ,blocked "unsupported reporting embedding cannot release Complete" (model "NP" [("NNP",4)]) "Ari says Ari is an animal."
 ,blocked "unsupported postnominal negation cannot release Complete" (model "NP" [("NNP",4)]) "Ari is an animal not."
 ,blocked "referential equative fallback remains absent" (model "NP" [("NNP",4)]) "Ari is Ari."
 ,blocked "bare nominal complement remains uncertified" (model "NP" [("NNP",4)]) "Ari is animal."
 ,blocked "lowercase noun evidence blocks even if truecase disabled" contraryLower "Ari is an animal."
 ,expectEq "ordinary article object retains existential witness"
   (Just (Canonical [CRef 0]
     [CanPred "animal" [CRefT(CRef 0)],CanPred "see" [CConstT "Ari",CRefT(CRef 0)]]))
   (canonicalize <$> srDRS (sentence (model "NP" [("NNP",4)]) "Ari sees an animal."))
 ,blocked "expletive NP cannot become a rigid name" (model "NP[expl]" [("NNP",4)]) "Ari is an animal."
 ,expectEq "ordinary named object preserves rigid identity"
   (Just (Canonical [] [CanPred "see" [CConstT "Ari",CConstT "Ari"]]))
   (canonicalize <$> srDRS (sentence (model "NP" [("NNP",4)]) "Ari sees Ari."))
 ,expectEq "initial unknown status remains NameOrOther" NameOrOther
   (nameStatus (model "NP" []) True "Ari")
 ,expectEq "noninitial unknown NameOnly is not positive POS evidence" NameOnly
   (nameStatus (model "NP" []) False "Ari")]
 where
  m=model "NP" [("NNP",4)]
  POSModel ps=smPOS m
  contraryLower=m {smTruecase=False, smPOS=POSModel(M.insert "ari" (M.singleton "NN" 1) ps)}

main :: IO ()
main=do
 args<-getArgs
 runChecks "nominal name independent controls"
   (case args of ["--boundaries"]->boundaries;["--positive"]->positive;_->positive++boundaries)
