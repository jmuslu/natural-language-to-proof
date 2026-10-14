-- Corpus-free observation controls for the proposed derivation-witness boundary.
-- These test actual projection/packing loss, not a mock implementation of witnesses.
module Main(main) where
import qualified Data.Set as Set
import Harness
import NL2Proof.Provenance
import NL2Proof.Semantics.CCGSem(Stipulation(..))
import NL2Proof.Semantics.Lambda
import qualified NL2Proof.Syntax.CCG as H
import NL2Proof.Syntax.Category(Cat(S))
import NL2Proof.Syntax.CCGBank(parseCCGCat)
import NL2Proof.Syntax.CCGParse(Rules(..))
import NL2Proof.Syntax.CCGSemParse
import NL2Proof.Syntax.CCGSupertag(buildTagModel,buildPOSModel)
import NL2Proof.Syntax.Tokenize(casedTokens)
cc = either error id . parseCCGCat
model=(defaultSemModel tags poses (Rules [] []) Set.empty){smAlpha=0,smSeenRules=False}
 where
  obs=[("Mira","NP","NNP"),("gives","S[dcl]\\NP","VBZ"),("up","(S\\NP)\\(S\\NP)","RP")]
  tags=buildTagModel[(w,cc c)|(w,c,_)<-obs]
  poses=buildPOSModel[(w,p)|(w,_,p)<-obs]
rs=spRoots(semParse model (SourceId "witness-boundary") (casedTokens 0 "Mira gives up"))
-- For these sentence roots ccatToCat gives S, as in Pipeline.toSign.
project s=H.Sign S (ssSem s) (ssProv s)
sameProjection a b=H.sSem(project a)==H.sSem(project b)&&H.sProv(project a)==H.sProv(project b)
main=runChecks "explain-replay-interface" $ case rs of
 []->[expect "independent particle fixture has a root" False]
 r:_->let
   note=Stipulation "independent-origin-control" "distinct observed origin" [] "test-only counterexample"
   changed=r{ssNotes=[(note,ssProv r)]}
   alternative=r{ssProv=provRule "test-only-distinct-path" [ssProv r]}
   scoreChanged=r{ssScore=ssScore r+1}
   chosen xs=map ssProv(packCell 10 xs)
   in
   [expect "fixture meaning independent of rendering"
     (canonicalAC(ssSem r)==canonicalAC(App(pred1 "give_up")(entity "Mira")))
   ,expect "projection cannot distinguish altered origin notes"
     (ssNotes r/=ssNotes changed && sameProjection r changed)
   ,expect "projection cannot distinguish altered parser score"
     (ssScore r/=ssScore scoreChanged && sameProjection r scoreChanged)
   ,expect "packing keeps earlier equal-score candidate provenance"
     (chosen[r,alternative]==[ssProv r])
   ,expect "reversing equal-score candidates reverses retained provenance"
     (chosen[alternative,r]==[ssProv alternative])
   ,expect "higher score chooses its own provenance not earlier witness"
     (chosen[r,alternative{ssScore=ssScore r+1}]==[ssProv alternative])]
