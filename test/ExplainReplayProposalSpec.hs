-- | Independent replay acceptance controls for the existing Explain renderer.
-- The runner exposes a temporary unchanged-meaning copy of its private functions.
module ExplainReplayProposalSpec (main) where
import Data.Maybe (isJust, isNothing)
import qualified Data.Set as Set
import qualified ExplainReplayUnderTest as E
import Harness
import NL2Proof.Provenance
import NL2Proof.Semantics.Lambda
import qualified NL2Proof.Syntax.CCG as H
import NL2Proof.Syntax.CCGBank (CCat, parseCCGCat)
import NL2Proof.Syntax.CCGParse (Rules(..))
import NL2Proof.Syntax.CCGSemParse
import NL2Proof.Syntax.CCGSupertag (buildPOSModel, buildTagModel)
import NL2Proof.Syntax.Category (Cat(S))
import NL2Proof.Syntax.Tokenize (Token(..), casedTokens)
cc :: String -> CCat
cc = either error id . parseCCGCat
model :: SemModel
model = (defaultSemModel tags poses (Rules [] []) Set.empty)
  { smAlpha=0, smSeenRules=False }
 where
  obs=[("Mira","NP","NNP"),("everything","NP","NN")
      ,("that","(NP\\NP)/(S[dcl]\\NP)","WDT")
      ,("is","(S[dcl]\\NP)/(S[adj]\\NP)","VBZ")
      ,("red","S[adj]\\NP","JJ"),("blue","S[adj]\\NP","JJ")
      ,("calm","S[adj]\\NP","JJ")
      ,("defends","(S[dcl]\\NP)/NP","VBZ")
      ,("defend","(S[b]\\NP)/NP","VB"),("herself","NP","PRP")
      ,("does","(S[dcl]\\NP)/(S[b]\\NP)","VBZ")
      ,("if","(S/S)/S[dcl]","IN"),("then","S/S","RB")
      ,("and","conj","CC"),("or","conj","CC"),(",",",",",")]
  tags=buildTagModel [(w,cc c)|(w,c,_)<-obs]
  poses=buildPOSModel [(w,p)|(w,_,p)<-obs]
src :: SourceId
src=SourceId "independent-replay-controls"
roots :: String -> [SSign]
roots txt=spRoots(semParse model src (casedTokens 0 txt))
asSign :: SSign -> H.Sign
asSign s=H.Sign S (ssSem s) (ssProv s)
at :: String -> Term -> Term
at name=App (pred1 name)
mira :: Term
mira=entity "Mira"
fixture :: String -> String -> [Term] -> [Check]
fixture label txt want=
 [expect (label++": production satisfies independently specified meaning")
   (not(null rs)&&all ((`elem` map canonicalAC want).canonicalAC.ssSem) rs)
 ,expect (label++": every retained root has legal compatible replay")
   (not(null rs)&&all (isJust.E.replayCCG model toks.asSign) rs)]
 where rs=roots txt;toks=casedTokens 0 txt
leaf :: [Token] -> Int -> Prov
leaf ts i=let t=ts!!i in ProvLex src (tokSpan t) (tokText t)
rule :: String -> Prov -> Prov -> Prov
rule n a b=provRule n [a,b]
conditionalText :: String
conditionalText="If Mira is red, then Mira is blue"
conditionalForgery :: H.Sign
conditionalForgery=H.Sign S (TAnd (TImp red blue) blue) provenance
 where
  l=leaf(casedTokens 0 conditionalText)
  red=at "red" mira;blue=at "blue" mira
  clause a b c=rule "BwdApp" (l a) (rule "FwdApp" (l b) (l c))
  open=rule "FwdApp" (l 0) (clause 1 2 3)
  coordinated=rule "CoordApply" open (rule "CoordMark" (l 4) (l 5))
  provenance=rule "FwdApp" coordinated (clause 6 7 8)
reflexiveText :: String
reflexiveText="Mira does defend herself"
reflexiveForgery :: H.Sign
reflexiveForgery=H.Sign S (apply (pred2 "defend") [mira,mira])
  (rule "BwdApp" (l 0) (rule "BwdApp" (rule "FwdComp" (l 1) (l 2)) (l 3)))
 where l=leaf(casedTokens 0 reflexiveText)
main :: IO ()
main=runChecks "explain-replay-proposal" $
 concat
 [fixture "ordinary predicate" "Mira is red" [at "red" mira]
 ,fixture "certified final-OR list" "Mira is red, blue, or calm"
    [TOr (at "red" mira) (TOr (at "blue" mira) (at "calm" mira)),
     TOr (TOr (at "red" mira) (at "blue" mira)) (at "calm" mira)]
 ,fixture "fused restriction" "Everything that is red is blue"
    [TForall "x" TyE (TImp (at "red" (Var "x")) (at "blue" (Var "x")))]
 ,fixture "local reflexive" "Mira defends herself" [apply (pred2 "defend") [mira,mira]]
 ,fixture "conditional boundary" conditionalText [TImp (at "red" mira) (at "blue" mira)]]
 ++[expect "conditional forged path is absent from production"
      (all ((/=H.sProv conditionalForgery).ssProv)(roots conditionalText))
   ,expect "same-term replay must reject unlicensed conditional coordination"
      (isNothing(E.replayCCG model (casedTokens 0 conditionalText) conditionalForgery))
   ,expect "composed reflexive governor forged path is absent from production"
      (not(null(roots reflexiveText))&&all ((/=H.sProv reflexiveForgery).ssProv)(roots reflexiveText))
   ,expect "same-term replay must reject composed reflexive governor"
      (isNothing(E.replayCCG model (casedTokens 0 reflexiveText) reflexiveForgery))]
