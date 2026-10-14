-- Independent red acceptance controls; no corpus/model load.
-- runghc -isrc -itest test/NominalUniversalProposalSpec.hs
module Main (main) where
import qualified Data.Set as Set
import Harness
import NL2Proof.DRT.Canonical
import NL2Proof.Pipeline
import NL2Proof.Provenance
import NL2Proof.Syntax.CCGBank (parseCCGCat)
import NL2Proof.Syntax.CCGParse (Rules(..))
import NL2Proof.Syntax.CCGSemParse
import NL2Proof.Syntax.CCGSupertag (buildPOSModel, buildTagModel)
import NL2Proof.Verify.ClaimKind (claimCond)
import NL2Proof.Verify.Reported (splitClaims)

mini :: SemModel
mini = (defaultSemModel tags poses (Rules [] []) Set.empty)
 { smAlpha=0, smSeenRules=False }
 where
  cc = either error id . parseCCGCat
  entries = [("every","NP[nb]/N","DT"),("each","NP[nb]/N","DT")
   ,("a","NP[nb]/N","DT"),("an","NP[nb]/N","DT")
   ,("is","(S[dcl]\\NP)/NP","VBZ"),(".",".",".")]
   ++ [(n,"N","NN") | n <- ["cat","animal","dog","mammal","artist","teacher"]]
  tags=buildTagModel [(w,cc c) | (w,c,_) <- entries]
  poses=buildPOSModel [(w,p) | (w,_,p) <- entries]

checks :: String -> String -> String -> [Check]
checks text subj predicate =
 let p name = CanPred name [CRefT (CRef 0)]
     whole = CanImp (Canonical [CRef 0] [p subj]) (Canonical [] [p predicate])
     wanted = Canonical [] [whole]
     s = case prSentences (runPipelineWith (CCGBankParser mini)
                  (SourceId "nominal-universal-independent") text) of
           [one] -> one
           _ -> error "expected one sentence"
     status = case srDRS s of
       Just d -> let (as,rs,ps,es)=splitClaims d
                 in map (claimCond . fst) as == [whole]
                   && map claimCond es == [p subj,p predicate]
                   && null rs && null ps
       _ -> False
 in [expectEq ("exact universal classification: "++text)
       (Just wanted) (canonicalize <$> srDRS s)
    ,expect ("independent Asserted/Embedded allocation: "++text) status
    ,expect ("all returned readings classify under one quantifier: "++text)
       (not (null (srReadings s)) && all
          ((==Just wanted) . fmap canonicalize . rrDRS) (srReadings s))]

main :: IO ()
main = runChecks "universal nominal independent proposal"
 (checks "Every cat is an animal." "cat" "animal"
 ++ checks "Each dog is a mammal." "dog" "mammal"
 ++ checks "Every artist is a teacher." "artist" "teacher")
