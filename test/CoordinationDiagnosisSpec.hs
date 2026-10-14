-- | Corpus-free punctuation/coordination controls, separating list meaning
-- from nominal-copula and unseen-word failures. Red tests are proposal evidence.
module Main (main) where
import qualified Data.Set as Set
import Harness
import NL2Proof.DRT.Canonical
import NL2Proof.Verify.ClaimKind (claimCond)
import NL2Proof.Verify.Reported (splitClaims, reportedContent, reportedVerb)
import NL2Proof.Pipeline
import NL2Proof.Provenance
import NL2Proof.Trace (decKind, traceDecisions)
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
  -- Known-red lexical admission control, separate from list-certificate casing:
  -- deleting the explicit OR/conj observation below makes unseen uppercase OR
  -- receive a punctuation prior and disappear through PunctLeft. The retained
  -- all-AND reading is wrong; this candidate does not repair lexical admission.
  obs=[("Bob","NP","NNP"),("cat","N","NN"),("a","NP[nb]/N","DT")
      ,("every","NP[nb]/N","DT"),("that","(N\\N)/(S[dcl]\\NP)","WDT")
      ,("is","(S[dcl]\\NP)/(S[adj]\\NP)","VBZ")
      ,("red","S[adj]\\NP","JJ"),("big","S[adj]\\NP","JJ")
      ,("young","S[adj]\\NP","JJ"),("kind","S[adj]\\NP","JJ")
      ,("not","(S[adj]\\NP)/(S[adj]\\NP)","RB")
      ,("says","(S[dcl]\\NP)/S[em]","VBZ"),("that","S[em]/S[dcl]","IN")
      ,("if","(S/S)/S[dcl]","IN"),("then","S/S","RB")
      ,("and","conj","CC"),("or","conj","CC"),("OR","conj","CC"),(",",",",","),(".",".",".")]
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
main=runChecks "coordination-diagnosis" (meaningChecks ++ scopedChecks)
meaningChecks :: [Check]
meaningChecks =
 [check "adjective AND independent of nominal copula" "Bob is red and big." [TAnd (red b) (big b)]
 ,check "adjective OR independent of nominal copula" "Bob is red or big." [TOr (red b) (big b)]
 ,check "three explicit ORs preserve associations" "Bob is red or big or young." (ors (red b) (big b) (young b))
 ,check "comma AND list preserves conjunction" "Bob is red, big, and young." [TAnd (red b) (TAnd (big b) (young b))]
 ,check "comma OR list means three alternatives" "Bob is red, big, or young." (ors (red b) (big b) (young b))
 ,check "uppercase final OR retains three alternatives" "Bob is red, big, OR young." (ors (red b) (big b) (young b))
 ,expect "uppercase final OR records the comma-list repair"
   ("comma-list" `elem` map decKind (traceDecisions (prTrace
     (runPipelineWith (CCGBankParser model) (SourceId "coord-uppercase") "Bob is red, big, OR young."))))
 ,check "comma OR without Oxford comma means three alternatives" "Bob is red, big or young." (ors (red b) (big b) (young b))
 ,check "explicit AND is not rewritten by following OR" "Bob is red and big, or young."
   [TOr (TAnd (red b) (big b)) (young b),TAnd (red b) (TOr (big b) (young b))]
 ,check "earlier OR alone cannot change a trailing comma into OR" "Bob is red or big, young."
   [TAnd (TOr (red b) (big b)) (young b),TOr (red b) (TAnd (big b) (young b))]
 ,check "explicit OR is not rewritten by following AND" "Bob is red or big, and young."
   [TAnd (TOr (red b) (big b)) (young b),TOr (red b) (TAnd (big b) (young b))]
 ,expect "comma between incompatible overt chains retains both atomic scopes"
   (canonicalAC (TAnd (TAnd (red b) (big b)) (TOr (young b) (predAt "kind" b)))
     `elem` map canonicalAC (forms "Bob is red and big, young or kind."))
 ,check "existential OR list shares one subject witness" "A cat is red, big, or young."
   [TExists "x" TyE (TAnd (predAt "cat" x) o)|o<-ors (red x) (big x) (young x)]
 ,check "relative restrictor OR list stays inside universal antecedent"
   "Every cat that is red, big, or young is kind."
   [TForall "x" TyE (TImp (TAnd (predAt "cat" x) o) (predAt "kind" x))|o<-ors (red x) (big x) (young x)]
 ]


-- Independent canonical boxes and claim lists; no production lowering or
-- claim traversal constructs expected values.
type Gold = (Canonical,[CanonCond],[CanonCond],[CanonCond])
atom :: String -> CTerm -> CanonCond
atom n t=CanPred n [t]
k :: [CanonCond] -> Canonical
k=Canonical []
listGold :: CanonCond -> CanonCond -> CanonCond -> [(CanonCond,[CanonCond])]
listGold a b c=
 [(CanOr (k [a]) (k [CanOr (k [b]) (k [c])]),[a,CanOr (k [b]) (k [c]),b,c])
 ,(CanOr (k [CanOr (k [a]) (k [b])]) (k [c]),[CanOr (k [a]) (k [b]),a,b,c])]
scoped :: String -> String -> [Gold] -> Check
scoped label txt wants = expect label (not (null ds) && all matches ds)
 where
  ds = [d | s <- prSentences (runPipelineWith (CCGBankParser model) (SourceId "coord-scoped") txt)
          , r <- srReadings s, Just d <- [rrDRS r]]
  matches d =
    let (as,rs,ps,es) = splitClaims d
        actual = (canonicalize d,map (claimCond . fst) as,map reportedContent rs,map claimCond es)
    in null ps && all ((==Just "say") . reportedVerb) rs && actual `elem` wants
scopedChecks :: [Check]
scopedChecks =
 [scoped "named list has one OR asserted and all branches embedded"
   "Bob is red, big, or young." [(k[o],[o],[],e)|(o,e)<-named]
 ,scoped "existential witness remains shared outside OR"
   "A cat is red, big, or young."
   [(Canonical [CRef 0] [cat,o],[cat,o],[],e)|(o,e)<-bound]
 ,scoped "relative OR is embedded in universal antecedent"
   "Every cat that is red, big, or young is kind."
   [(k[i],[i],[],cat:o:e++[atom "kind" ref])|(o,e)<-bound,
      let i=CanImp (Canonical [CRef 0] [cat,o]) (k[atom "kind" ref])]
 ,scoped "negative final member preserves NOT barrier"
   "Bob is red, big, or not young."
   [(k[o],[o],[],e++[atom "young" bob])|(o,e)<-listGold (atom "red" bob) (atom "big" bob) (CanNot (k[atom "young" bob]))]
 ,scoped "report preserves list as reported whole rather than asserted branches"
   "Bob says that Bob is red, big, or young."
   [(k[a],[a],[o],[])|(o,_)<-named,let a=CanAtt "say" [bob] (k[o])]
 ,let o=CanOr (k[atom "red" bob,atom "big" bob]) (k[atom "young" bob])
      o2=CanOr (k[atom "big" bob]) (k[atom "young" bob])
  in scoped "mixed explicit AND OR keeps scope-specific claims"
   "Bob is red and big, or young."
   [(k[o],[o],[],[atom "red" bob,atom "big" bob,atom "young" bob]),
    (k[atom "red" bob,o2],[atom "red" bob,o2],[],[atom "big" bob,atom "young" bob])]
 ,scoped "ordinary completed clause commas retain conjunction"
   "Bob is red, Bob is big, Bob is young."
   [(k[atom "red" bob,atom "big" bob,atom "young" bob],
     [atom "red" bob,atom "big" bob,atom "young" bob],[],[])]
 ,let o=CanOr (k[atom "red" bob]) (k[atom "big" bob])
      a=CanAtt "say" [bob] (k[o])
      a2=CanAtt "say" [bob] (k[o,atom "young" bob])
  in scoped "report application seals inner list before outer comma"
   "Bob says that Bob is red or big, Bob is young."
   [(k[a,atom "young" bob],[a,atom "young" bob],[o],[]),
    (k[a2],[a2],[o,atom "young" bob],[])]
 ,let n=CanNot (k[atom "red" bob])
      o=CanOr (k[atom "big" bob]) (k[atom "young" bob])
  in scoped "negated clause and independent OR clause preserve barriers"
   "Bob is not red, Bob is big or young."
   [(k[n,o],[n,o],[],[atom "red" bob,atom "big" bob,atom "young" bob])]
 ,scoped "conditional consequence list cannot escape implication"
   "If Bob is red then Bob is big, young, or kind."
   [(k[i],[i],[],atom "red" bob:o:e)|(o,e)<-listGold (atom "big" bob) (atom "young" bob) (atom "kind" bob),
     let i=CanImp (k[atom "red" bob]) (k[o])]
 ]
 where
  bob=CConstT "Bob"
  ref=CRefT (CRef 0)
  cat=atom "cat" ref
  named=listGold (atom "red" bob) (atom "big" bob) (atom "young" bob)
  bound=listGold (atom "red" ref) (atom "big" ref) (atom "young" ref)
