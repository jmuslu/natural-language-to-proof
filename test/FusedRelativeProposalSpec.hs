-- | Independent red specification for fused indefinite-pronoun relatives.
-- Run: runghc -isrc -itest test/FusedRelativeProposalSpec.hs
-- No corpus/model load. These authored adjective controls isolate quantifier
-- restriction from nominal copulas. Not a release suite until reviewed/repaired.
module Main (main) where

import qualified Data.Set as Set
import Harness
import NL2Proof.DRT.Canonical
import NL2Proof.Pipeline
import NL2Proof.Provenance
import NL2Proof.Semantics.CCGSem
import NL2Proof.Syntax.CCGBank (CCat, parseCCGCat)
import NL2Proof.Syntax.CCGParse (Rules(..))
import NL2Proof.Syntax.CCGSemParse
import NL2Proof.Syntax.CCGSupertag (buildPOSModel, buildTagModel)
import NL2Proof.Verify.ClaimKind (claimCond)
import NL2Proof.Verify.Reported (splitClaims)

cc :: String -> CCat
cc = either error id . parseCCGCat
mini :: SemModel
mini = (defaultSemModel tags poses rules Set.empty)
  { smAlpha = 0, smSeenRules = False }
  where
    entries = [("everything","NP","NN"),("something","NP","NN")
      ,("someone","NP","NN"),("Every","NP[nb]/N","DT"),("cat","N","NN")
      ,("that","(NP\\NP)/(S[dcl]\\NP)","WDT")
      ,("who","(NP\\NP)/(S[dcl]\\NP)","WP")
      ,("is","(S[dcl]\\NP)/(S[adj]\\NP)","VBZ")
      ,("red","S[adj]\\NP","JJ"),("blue","S[adj]\\NP","JJ")
      ,("big","S[adj]\\NP","JJ"),("cold","S[adj]\\NP","JJ")
      ,("not","(S\\NP)\\(S\\NP)","RB")
      ,("and","conj","CC"),("or","conj","CC"),(".",".",".")]
    tags = buildTagModel [(w,cc c) | (w,c,_) <- entries]
    poses = buildPOSModel [(w,p) | (w,_,p) <- entries]
    rules = Rules [(cc "N",cc "NP")] []

sentence :: String -> SentenceResult
sentence text = case prSentences (runPipelineWith (CCGBankParser mini)
                         (SourceId "fused-relative-proposal") text) of
  [s] -> s
  _ -> error "expected one sentence"

atom :: String -> CanonCond
atom name = CanPred name [CRefT (CRef 0)]
red, blue, big, cold, person, catAtom :: CanonCond
red=atom "red"; blue=atom "blue"; big=atom "big"; cold=atom "cold"
person=atom "person"; catAtom=atom "cat"
neg :: CanonCond -> CanonCond
neg p = CanNot (Canonical [] [p])
alt :: CanonCond -> CanonCond -> CanonCond
alt p q = CanOr (Canonical [] [p]) (Canonical [] [q])
rule :: [CanonCond] -> [CanonCond] -> CanonCond
rule lhs rhs = CanImp (Canonical [CRef 0] lhs) (Canonical [] rhs)

-- Each row supplies its own Asserted/Embedded table; no claim splitter computes
-- expected allocation. Universal restriction OR binds r0 outside both branches.
data Case = Case String Canonical [CanonCond] [CanonCond]
cases :: [Case]
cases =
 [ universal "Everything that is red is big." [red] [big] [red,big]
 , universal "Everything that is red or blue is big and cold."
     [alt red blue] [big,cold] [alt red blue,red,blue,big,cold]
 , universal "Everything that is not red is big."
     [neg red] [big] [neg red,red,big]
 , existential "Something that is red is big." [red,big] [red,big] []
 , existential "Something that is red or blue is cold."
     [alt red blue,cold] [alt red blue,cold] [red,blue]
 , existential "Something that is red is not big."
     [red,neg big] [red,neg big] [big]
 , existential "Someone who is red is big."
     [person,red,big] [person,red,big] []
 , existential "Someone who is red and blue is cold."
     [person,red,blue,cold] [person,red,blue,cold] []
 , existential "Someone who is red is not big."
     [person,red,neg big] [person,red,neg big] [big]
 ]
  where
    universal text lhs rhs embedded =
      let whole=rule lhs rhs in Case text (Canonical [] [whole]) [whole] embedded
    existential text conditions asserted embedded =
      Case text (Canonical [CRef 0] conditions) asserted embedded

checkCase :: Case -> [Check]
checkCase (Case text intended asserted embedded) =
 let s=sentence text
     claimsOK = case srDRS s of
       Just drs -> let (as,rs,ps,es)=splitClaims drs
                  in map (claimCond . fst) as == asserted
                     && map claimCond es == embedded && null rs && null ps
       _ -> False
 in [expectEq ("selected scoped DRS: "++text) (Just intended)
       (canonicalize <$> srDRS s)
    ,expect ("independent claim status: "++text) claimsOK
    ,expect ("all returned readings retain the scoped DRS: "++text)
       (not (null (srReadings s))
        && all ((==Just intended) . fmap canonicalize . rrDRS) (srReadings s))]

main :: IO ()
main = runChecks "KNOWN fused-relative restriction gap" $
  concatMap checkCase cases ++
  [expect "everything must be reserved, not an open-class predicate"
      (isClosedClass "everything")
  ,expectEq "existing determiner+noun relative retains restriction scope"
      (Just (Canonical [] [rule [catAtom,red] [big]]))
      (canonicalize <$> srDRS (sentence "Every cat that is red is big."))
  ,expect "fused head cannot consume an arbitrary noun as relative restriction"
      (null (srReadings (sentence "Everything cat is red.")))
  ,expect "relative property cannot stand as an unlicensed bare subject"
      (null (srReadings (sentence "That is red is big.")))]
