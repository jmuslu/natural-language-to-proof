-- | Hand-tagged chart regression: conditional delimiters must not add a
-- consequent assertion. No licensed corpus or benchmark data is loaded.
module Main (main) where
import qualified Data.Set as Set
import Harness
import NL2Proof.Pipeline
import NL2Proof.Provenance
import NL2Proof.Semantics.CCGSem
import NL2Proof.Semantics.Lambda
import NL2Proof.Syntax.CCGBank (CCat, parseCCGCat)
import NL2Proof.Syntax.CCGParse (Rules(..))
import NL2Proof.Syntax.CCGSemParse
import NL2Proof.Syntax.CCGSupertag (buildPOSModel, buildTagModel)

cc :: String -> CCat
cc = either error id . parseCCGCat
model :: SemModel
model = (defaultSemModel tags pos (Rules [] []) Set.empty)
  { smAlpha = 0, smSeenRules = False }
  where
    obs = [("Bob","NP","NNP"),("is","(S[dcl]\\NP)/(S[adj]\\NP)","VBZ")
          ,("red","S[adj]\\NP","JJ"),("big","S[adj]\\NP","JJ")
          ,("if","(S/S)/S[dcl]","IN"),("then","S/S","RB")
          ,("and","conj","CC"),(",",",",","),(".",".",".")]
    tags = buildTagModel [(w,cc c) | (w,c,_) <- obs]
    pos = buildPOSModel [(w,p) | (w,_,p) <- obs]
forms :: String -> [Term]
forms txt = [f | s <- prSentences (runPipelineWith (CCGBankParser model)
                      (SourceId "conditional-duplication") txt)
               , r <- srReadings s, Just f <- [rrForm r]]
p, q :: Term
p = App (pred1 "red") (entity "Bob")
q = App (pred1 "big") (entity "Bob")
checkAll :: String -> String -> Term -> Check
checkAll label txt expected = checkAllowed label txt [expected]
checkAllowed :: String -> String -> [Term] -> Check
checkAllowed label txt expected =
 let got = forms txt
 in if not (null got) && all ((`elem` map canonicalAC expected) . canonicalAC) got
    then ok label else bad label (show (map pretty got))
main :: IO ()
main = runChecks "conditional-duplication"
 [checkAll "comma then introduces no extra assertion in ANY reading"
   "If Bob is red, then Bob is big." (TImp p q)
 ,checkAll "if with comma but no then remains implication"
   "If Bob is red, Bob is big." (TImp p q)
 ,checkAll "if then without comma remains implication"
   "If Bob is red then Bob is big." (TImp p q)
 ,checkAll "nested antecedent modifiers do not coordinate by comma"
   "If Bob is red, if Bob is big, Bob is red." (TImp p (TImp q p))
 ,checkAllowed "explicit coordination retains only genuine scope alternatives"
   "If Bob is red, then Bob is big and Bob is red."
   [TImp p (TAnd q p), TAnd (TImp p q) p]
 ,checkAll "plain comma clause coordination is retained"
   "Bob is red, Bob is big." (TAnd p q)
 ,checkAll "explicit and coordination is retained"
   "Bob is red and Bob is big." (TAnd p q)]
