-- Independent corpus-free object-gap restriction controls; expected red proposal.
module Main (main) where
import qualified Data.Set as Set
import Harness
import NL2Proof.Provenance
import NL2Proof.Semantics.Lambda
import NL2Proof.Syntax.CCGBank (CCat,parseCCGCat)
import NL2Proof.Syntax.CCGParse (Rules(..))
import NL2Proof.Syntax.CCGSemParse
import NL2Proof.Syntax.CCGSupertag (buildPOSModel,buildTagModel)
import NL2Proof.Syntax.Tokenize (casedTokens)
cc :: String -> CCat
cc = either error id . parseCCGCat
mini :: String -> SemModel
mini rel = (defaultSemModel tags poses rules Set.empty) {smAlpha=0,smSeenRules=False}
 where
  obs=[("every","NP[nb]/N","DT"),("a","NP[nb]/N","DT")
      ,("dog","N","NN"),("Mira","NP","NNP")
      ,("that",rel,"WDT"),("likes","(S[dcl]\\NP)/NP","VBZ")
      ,("is","(S[dcl]\\NP)/(S[adj]\\NP)","VBZ")
      ,("quiet","S[adj]\\NP","JJ"),("red","S[adj]\\NP","JJ")]
  tags=buildTagModel [(w,cc c)|(w,c,_)<-obs]
  poses=buildPOSModel [(w,p)|(w,_,p)<-obs]
  rules=Rules [(cc "NP",cc "S/(S\\NP)")] []
objectModel, subjectModel :: SemModel
objectModel=mini "(NP\\NP)/(S[dcl]/NP)"
subjectModel=mini "(NP\\NP)/(S[dcl]\\NP)"
roots m t=spRoots(semParse m (SourceId "object-relative-independent") (casedTokens 0 t))
atom n=App(pred1 n)(Var "x")
relation=apply(pred2 "like")[entity "Mira",Var "x"]
exact m text expected=let rs=roots m text in not(null rs)&&all ((==canonicalAC expected).canonicalAC.ssSem) rs
main=runChecks "relative-next-proposal"
 [expect "observed object-relative category gets N restriction alternative"
   (any ((==cc "(N\\N)/(S[dcl]/NP)").lxCat) (lexicalSigns objectModel 2 "that"))
 ,expect "universal places object gap in restrictor with correct argument order"
   (exact objectModel "Every dog that Mira likes is quiet"
      (TForall "x" TyE (TImp (TAnd(atom "dog") relation)(atom "quiet"))))
 ,expect "existential uses one shared object witness"
   (exact objectModel "A dog that Mira likes is quiet"
      (TExists "x" TyE (TAnd(atom "dog")(TAnd relation(atom "quiet")))))
 ,expect "subject-relative control retains subject restriction"
   (exact subjectModel "Every dog that is red is quiet"
      (TForall "x" TyE (TImp (TAnd(atom "dog")(atom "red"))(atom "quiet"))))
 ,expect "subject-only evidence does not invent object-gap reading"
   (null(roots subjectModel "Every dog that Mira likes is quiet"))
 ,expect "object-only evidence does not invent subject-gap reading"
   (null(roots objectModel "Every dog that is red is quiet"))]
