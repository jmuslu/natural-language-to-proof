-- | Corpus-free punctuation/coordination controls, separating list meaning
-- from nominal-copula and unseen-word failures. Red tests are proposal evidence.
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
  { smAlpha=0, smSeenRules=False }
 where
  obs=[("Bob","NP","NNP"),("cat","N","NN"),("a","NP[nb]/N","DT")
      ,("every","NP[nb]/N","DT"),("that","(N\\N)/(S[dcl]\\NP)","WDT")
      ,("is","(S[dcl]\\NP)/(S[adj]\\NP)","VBZ")
      ,("red","S[adj]\\NP","JJ"),("big","S[adj]\\NP","JJ")
      ,("young","S[adj]\\NP","JJ"),("kind","S[adj]\\NP","JJ")
      ,("and","conj","CC"),("or","conj","CC"),(",",",",","),(".",".",".")]
  tags=buildTagModel [(w,cc c)|(w,c,_)<-obs]
  pos=buildPOSModel [(w,p)|(w,_,p)<-obs]
forms :: String -> [Term]
forms txt=[f|s<-prSentences(runPipelineWith (CCGBankParser model) (SourceId "coord-diagnosis") txt)
             ,r<-srReadings s,Just f<-[rrForm r]]
predAt :: String -> Term -> Term
predAt n x=App (pred1 n) x
ors :: Term -> Term -> Term -> [Term]
ors p q r=[TOr (TOr p q) r,TOr p (TOr q r)]
check :: String -> String -> [Term] -> Check
check label txt expected=let got=forms txt in
 if not(null got) && all ((`elem` map canonicalAC expected).canonicalAC) got
 then ok label else bad label (show(map pretty got))
x,b :: Term
x=Var "x"
b=entity "Bob"
red,big,young :: Term -> Term
red=predAt "red"
big=predAt "big"
young=predAt "young"
main :: IO ()
main=runChecks "coordination-diagnosis"
 [check "adjective AND independent of nominal copula" "Bob is red and big." [TAnd (red b) (big b)]
 ,check "adjective OR independent of nominal copula" "Bob is red or big." [TOr (red b) (big b)]
 ,check "three explicit ORs preserve associations" "Bob is red or big or young." (ors (red b) (big b) (young b))
 ,check "comma AND list preserves conjunction" "Bob is red, big, and young." [TAnd (red b) (TAnd (big b) (young b))]
 ,check "comma OR list means three alternatives" "Bob is red, big, or young." (ors (red b) (big b) (young b))
 ,check "comma OR without Oxford comma means three alternatives" "Bob is red, big or young." (ors (red b) (big b) (young b))
 ,check "explicit AND is not rewritten by following OR" "Bob is red and big, or young."
   [TOr (TAnd (red b) (big b)) (young b),TAnd (red b) (TOr (big b) (young b))]
 ,check "explicit OR is not rewritten by following AND" "Bob is red or big, and young."
   [TAnd (TOr (red b) (big b)) (young b),TOr (red b) (TAnd (big b) (young b))]
 ,check "existential OR list shares one subject witness" "A cat is red, big, or young."
   [TExists "x" TyE (TAnd (predAt "cat" x) o)|o<-ors (red x) (big x) (young x)]
 ,check "relative restrictor OR list stays inside universal antecedent"
   "Every cat that is red, big, or young is kind."
   [TForall "x" TyE (TImp (TAnd (predAt "cat" x) o) (predAt "kind" x))|o<-ors (red x) (big x) (young x)]
 ]
