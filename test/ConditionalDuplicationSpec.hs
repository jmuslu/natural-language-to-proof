-- | Hand-tagged chart regression: conditional delimiters must not add a
-- consequent assertion. No licensed corpus or benchmark data is loaded.
module Main (main) where
import qualified Data.Set as Set
import System.Environment (getArgs)
import Harness
import NL2Proof.Pipeline
import NL2Proof.Provenance
import NL2Proof.Semantics.CCGSem
import NL2Proof.Semantics.Intensional (applyIntensional, attitudeVerb, complementizer)
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
          ,("says","(S[dcl]\\NP)/S[em]","VBZ"),("that","S[em]/S[dcl]","IN")
          ,("or","conj","CC"),("and","conj","CC"),(",",",",","),(".",".",".")]
    tags = buildTagModel [(w,cc c) | (w,c,_) <- obs]
    pos = buildPOSModel [(w,p) | (w,_,p) <- obs]
forms :: String -> [Term]
forms = formsWith model
formsWith :: SemModel -> String -> [Term]
formsWith m txt = [f | s <- prSentences (runPipelineWith (CCGBankParser m)
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
report :: Term -> Term
report body = normalize (App (applyIntensional (attitudeVerb "say")
  (applyIntensional complementizer body))
  (Lam "P" tyPred1 (App (Var "P") (entity "Bob"))))
checkContains :: String -> String -> Term -> Check
checkContains label txt expected = expect label
  (canonicalAC expected `elem` map canonicalAC (forms txt))
raisedModel :: SemModel
raisedModel = model { smTypeRaise = True, smUnaryPenalty = -1
  , smRules = Rules [(cc "S/S",cc "S/(S\\(S/S))")
                    ,(cc "S[dcl]",cc "S\\(S/S)")] [] }
main :: IO ()
main = do
 args <- getArgs
 if args == ["--raising-audit"]
  then runChecks "KNOWN unresolved clause-raising reversal"
    [expect "all raised conditional readings retain implication direction"
      (let fs = formsWith raisedModel "If Bob is red, then Bob is big."
       in not (null fs) && all ((==canonicalAC (TImp p q)) . canonicalAC) fs)]
  else runChecks "conditional-duplication" checks
checks :: [Check]
checks =
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
 ,checkAll "completed inner conditional leaves outer antecedent obligation pending"
   "If if Bob is red then Bob is big, then Bob is red." (TImp (TImp p q) p)
 ,expect "raised conditional preserves boundary obligation"
   (let fs = formsWith raisedModel "If Bob is red, then Bob is big."
    in canonicalAC (TImp p q) `elem` map canonicalAC fs
       && all (\f -> case f of TAnd _ _ -> False; _ -> True) fs)
 ,checkAll "explicit and between open modifiers remains allowed"
   "If Bob is red and if Bob is big then Bob is red."
   (TAnd (TImp p p) (TImp q p))
 ,checkAll "explicit or between open modifiers remains allowed"
   "If Bob is red or if Bob is big then Bob is red."
   (TOr (TImp p p) (TImp q p))
 ,checkContains "completed conditional remains comma-coordinateable"
   "If Bob is red then Bob is big, Bob is red." (TAnd (TImp p q) p)
 ,checkContains "completed conditional inside report does not poison outer comma"
   "Bob says that if Bob is red then Bob is big, Bob is red."
   (TAnd (report (TImp p q)) p)
 ,checkAll "conditional delimiter inside report cannot assert extra consequent"
   "Bob says that if Bob is red, then Bob is big." (report (TImp p q))
 ,checkAll "plain comma clause coordination is retained"
   "Bob is red, Bob is big." (TAnd p q)
 ,checkAll "explicit and coordination is retained"
   "Bob is red and Bob is big." (TAnd p q)]
