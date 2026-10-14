-- Corpus-free independent acceptance controls; intentionally red before implementation.
module Main (main) where
import qualified Data.Set as Set
import Data.List (sort, isInfixOf)
import Harness
import NL2Proof.Provenance
import NL2Proof.Semantics.Lambda
import NL2Proof.Syntax.CCGBank (parseCCGCat, eraseFeatures)
import NL2Proof.Syntax.CCGParse (Rules(..))
import NL2Proof.Syntax.CCGSemParse
import NL2Proof.Syntax.CCGSupertag (buildPOSModel, buildTagModel)
import NL2Proof.Syntax.Tokenize (casedTokens, Token(..))

cc = either error id . parseCCGCat
mini headTag upTag = (defaultSemModel tags poses (Rules [] []) Set.empty)
  { smAlpha = 0, smSeenRules = False, smBeam = 100 }
  where
    obs = [("Raul","NP","NNP"),("Ada","NP","NNP")
      ,("gives",headTag,"VBZ"),("give","S[b]\\NP","VB")
      ,("up",upTag,"RP"),("walks","S[dcl]\\NP","VBZ")
      ,("gave","S[dcl]\\NP","VBD"),("down",upTag,"RP")
      ,("does","(S[dcl]\\NP)/(S[b]\\NP)","VBZ")
      ,("not","(S\\NP)/(S\\NP)","RB")
      ,("Every","NP[nb]/N","DT"),("runner","N","NN")
      ,("a","NP[nb]/N","DT"),("seat","N","NN")
      ,("hill","N","NN"),("to","PP/NP","IN")
      ,("early","(S\\NP)\\(S\\NP)","RB")
      ,(".",".",".")]
    tags = buildTagModel [(w,cc c) | (w,c,_) <- obs]
    poses = buildPOSModel [(w,p) | (w,_,p) <- obs]
base = mini "S[dcl]\\NP" "(S\\NP)\\(S\\NP)"
roots m text = spRoots (semParse m (SourceId "particle-contract") (casedTokens 0 text))
atom name = App (pred1 "give_up") (entity name)
exact m text want = let rs = roots m text in not (null rs)
  && all ((==canonicalAC want) . canonicalAC . ssSem) rs
noSense m text = all (not . isInfixOf "give_up" . show . ssSem) (roots m text)
conserved text = not (null rs) && all ((==expected) . sort . provLeaves . ssProv) rs
  where
    rs = roots base text
    expected = sort [(SourceId "particle-contract",tokSpan t,tokText t)
                    | t <- casedTokens 0 text]
main = runChecks "particle-licensing-proposal" $
  [ expect "named lexical sense" (exact base "Raul gives up." (atom "Raul"))
  , expect "independent name" (exact base "Ada gives up." (atom "Ada"))
  , expect "negative scope with base head" (exact base "Raul does not give up." (TNot (atom "Raul")))
  , expect "one universal subject scope" (exact base "Every runner gives up."
      (TForall "x" TyE (TImp (App (pred1 "runner") (Var "x")) (App (pred1 "give_up") (Var "x")))))
  , expect "seen-pair pruning admits reviewed span" (exact
      (base { smSeenRules=True, smSeen=Set.singleton (cc "NP",eraseFeatures (cc "S[dcl]\\NP")) })
      "Raul gives up" (atom "Raul"))
  , expect "two original leaves plus subject and punctuation survive" (conserved "Raul gives up.")
  , expect "negated derivation conserves every leaf" (conserved "Raul does not give up.")
  , expect "ordinary intransitive retains its own lexical meaning"
      (exact base "Raul walks." (App (pred1 "walk") (entity "Raul")))
  ] ++
  [ expect label (noSense model text) | (label,model,text) <-
    [("absent particle",base,"Raul gives.")
    ,("wrong particle",base,"Raul gives down.")
    ,("wrong head lemma",base,"Raul walks up.")
    ,("past morphology not licensed",base,"Raul gave up.")
    ,("intervening NP",base,"Raul gives Ada up.")
    ,("transitive continuation not deleted",base,"Raul gives up a seat.")
    ,("PP continuation not deleted",base,"Raul gives up to Ada.")
    ,("event adverb not deleted",base,"Raul gives up early.")
    ,("transitive-only head cannot lose object",mini "(S[dcl]\\NP)/NP" "(S\\NP)\\(S\\NP)","Raul gives up.")
    ,("adjectival head incompatible",mini "S[adj]\\NP" "(S\\NP)\\(S\\NP)","Raul gives up.")
    ,("passive head incompatible",mini "S[pss]\\NP" "(S\\NP)\\(S\\NP)","Raul gives up.")
    ,("directional particle category incompatible",mini "S[dcl]\\NP" "((S\\NP)\\(S\\NP))/NP","Raul gives up a hill.")
    ,("nominal particle category incompatible",mini "S[dcl]\\NP" "NP","Raul gives up.")
    ,("PR not silently substituted for original tag",mini "S[dcl]\\NP" "PR","Raul gives up.")
    ] ]
