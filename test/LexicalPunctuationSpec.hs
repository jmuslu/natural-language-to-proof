-- | Surface text cannot vanish merely because a tagger offers punctuation.
-- Independent lexical and miniature semantic controls; no licensed corpus.
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

structural :: LexItem -> Bool
structural (LexStructural _) = True
structural _ = False

mini :: String -> SemModel
mini orCategory = (defaultSemModel tags poses (Rules [] []) Set.empty)
  { smAlpha=0, smSeenRules=False }
  where
    observations = [("Bob","NP","NNP"),("is","(S[dcl]\\NP)/(S[adj]\\NP)","VBZ")
      ,("red","S[adj]\\NP","JJ"),("big","S[adj]\\NP","JJ")
      ,("OR",orCategory,"CC"),("or","conj","CC"),("and","conj","CC")
      ,(",",",",","),(".",".",".")]
    tags=buildTagModel [(w,cc c) | (w,c,_) <- observations]
    poses=buildPOSModel [(w,p) | (w,_,p) <- observations]

forms :: SemModel -> String -> [Term]
forms model text = [t | s <- prSentences (runPipelineWith (CCGBankParser model)
  (SourceId "punctuation-contract") text), r <- srReadings s, Just t <- [rrForm r]]

only :: Term -> [Term] -> Bool
only expected actual = not (null actual) && all ((==canonicalAC expected) . canonicalAC) actual

main :: IO ()
main = runChecks "lexical-punctuation" $
  [expect ("nonpunctuation never structurally disappears: " ++ show word ++ " / " ++ category)
      (not (any structural (closedEntries 0 word (cc category))))
  | word <- ["OR","or","AND","not","Alice","123","3.14","can't","well-known"
            ,"α","猫","e\x0301","$","+","=","🙂"," ","","-LRB-"]
  , category <- [".",",",":",";","LRB","RRB"]] ++
  [expect ("actual punctuation retains structural admission: " ++ show word)
      (any structural (closedEntries 0 word (cc category)))
  | (word,category) <- [(".","."),(",",","),(":",":"),(";",";")
      ,("(","LRB"),(")","RRB"),("[","LRB"),("]","RRB")
      ,("\"","."),("'","."),("-","."),("--","."),("—",".")
      ,("“","."),("”","."),("‘","."),("’","."),("…","."),("。",".")]] ++
  [expect "alphabetic OR offered punctuation cannot yield a silently conjunctive clause"
      (null (forms (mini ".") "Bob is red, OR big."))
  ,expect "lowercase overt or retains disjunction"
      (only disjunction (forms (mini "conj") "Bob is red or big."))
  ,expect "uppercase overt OR with actual conj tag retains disjunction"
      (only disjunction (forms (mini "conj") "Bob is red OR big."))
  ,expect "overt and retains conjunction"
      (only conjunction (forms (mini "conj") "Bob is red and big."))
  ,expect "real sentence-final punctuation preserves the proposition"
      (only red (forms (mini "conj") "Bob is red."))
  ,expect "reserved copula under its real category keeps lexical semantics"
      (not (null (closedEntries 0 "is" (cc "(S[dcl]\\NP)/(S[adj]\\NP)"))))]
  where
    red=App (pred1 "red") (entity "Bob")
    big=App (pred1 "big") (entity "Bob")
    disjunction=TOr red big
    conjunction=TAnd red big
