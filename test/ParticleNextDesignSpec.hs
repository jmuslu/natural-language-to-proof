-- Independent corpus-free red controls for a proposed lexical sense extension.
module Main (main) where
import qualified Data.Set as Set
import Data.List (isInfixOf)
import Harness
import NL2Proof.Provenance
import NL2Proof.Semantics.Lambda
import NL2Proof.Syntax.CCGBank (CCat,parseCCGCat)
import NL2Proof.Syntax.CCGParse (Rules(..))
import NL2Proof.Syntax.CCGSemParse
import NL2Proof.Syntax.CCGSupertag (buildTagModel,buildPOSModel)
import NL2Proof.Syntax.Tokenize (casedTokens)
cc :: String -> CCat
cc = either error id . parseCCGCat
model :: String -> String -> SemModel
model headCat particleCat = (defaultSemModel tm pm (Rules [] []) Set.empty)
  {smAlpha=0,smSeenRules=False}
  where
    obs = [("Noel","NP","NNP"),("Mira","NP","NNP"),("Ada","NP","NNP")
      ,("stands",headCat,"VBZ"),("stand","S[b]\\NP","VB")
      ,("out",particleCat,"RP"),("up",particleCat,"RP")
      ,("walks","S[dcl]\\NP","VBZ"),("stood","S[dcl]\\NP","VBD")
      ,("does","(S[dcl]\\NP)/(S[b]\\NP)","VBZ")
      ,("not","(S\\NP)/(S\\NP)","RB"),("from","PP/NP","IN")
      ,(".",".",".")]
    tm=buildTagModel [(w,cc c) | (w,c,_)<-obs]
    pm=buildPOSModel [(w,p) | (w,_,p)<-obs]
base :: SemModel
base=model "S[dcl]\\NP" "(S\\NP)\\(S\\NP)"
roots :: SemModel -> String -> [SSign]
roots m=spRoots . semParse m (SourceId "stand-out-control") . casedTokens 0
want :: String -> Term
want name=App (pred1 "stand_out_noticeable") (entity name)
exact :: String -> Term -> Bool
exact text term=let rs=roots base text in not(null rs)
  && all ((==canonicalAC term).canonicalAC.ssSem) rs
safe :: SemModel -> String -> Bool
safe m text=all (not.isInfixOf "stand_out_noticeable".show.ssSem) (roots m text)
main :: IO ()
main=runChecks "particle-next-design" $
  [expect "licensed noticeability span" (exact "Noel stands out." (want "Noel"))
  ,expect "independent name" (exact "Mira stands out." (want "Mira"))
  ,expect "negative scope over whole lexeme" (exact "Mira does not stand out." (TNot(want "Mira")))
  ,expect "ordinary unary stand retained" (exact "Noel stands." (App (pred1 "stand") (entity "Noel")))
  ] ++ [expect label (safe m txt) | (label,m,txt)<-
    [("absent particle",base,"Noel stands.")
    ,("wrong particle",base,"Noel stands up.")
    ,("wrong head",base,"Noel walks out.")
    ,("past morphology excluded",base,"Noel stood out.")
    ,("separated object excluded",base,"Noel stands Ada out.")
    ,("comparison PP not deleted",base,"Noel stands out from Ada.")
    ,("transitive-only origin excluded",model "(S[dcl]\\NP)/NP" "(S\\NP)\\(S\\NP)","Noel stands out.")
    ,("noun head origin excluded",model "N" "(S\\NP)\\(S\\NP)","Noel stands out.")
    ,("literal directional PP category excluded",model "S[dcl]\\NP" "((S\\NP)\\(S\\NP))/NP","Noel stands out Ada.")
    ,("noun particle origin excluded",model "S[dcl]\\NP" "N","Noel stands out.")
    ,("PR not invented",model "S[dcl]\\NP" "PR","Noel stands out.")
    ,("adjective feature excluded",model "S[adj]\\NP" "(S\\NP)\\(S\\NP)","Noel stands out.")
    ]]
