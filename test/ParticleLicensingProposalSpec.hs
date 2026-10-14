-- Corpus-free independent acceptance controls, frozen red before implementation.
module Main (main) where
import qualified Data.Set as Set
import Data.List (sort, isInfixOf)
import Harness
import NL2Proof.Pipeline
import NL2Proof.DRT.Canonical
import NL2Proof.Verify.ClaimKind (claimCond)
import NL2Proof.Verify.Reported (splitClaims)
import NL2Proof.Semantics.CCGSem (Stipulation(..))
import NL2Proof.Provenance
import NL2Proof.Semantics.Lambda
import NL2Proof.Syntax.CCGBank (CCat, parseCCGCat, eraseFeatures)
import NL2Proof.Syntax.CCG (sProv)
import NL2Proof.Syntax.CCGParse (Rules(..))
import NL2Proof.Syntax.CCGSemParse
import NL2Proof.Syntax.CCGSupertag (buildPOSModel, buildTagModel)
import NL2Proof.Syntax.Tokenize (casedTokens, Token(..))

cc :: String -> CCat
cc = either error id . parseCCGCat
mini :: String -> String -> SemModel
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
base :: SemModel
base = mini "S[dcl]\\NP" "(S\\NP)\\(S\\NP)"
roots :: SemModel -> String -> [SSign]
roots m text = spRoots (semParse m (SourceId "particle-contract") (casedTokens 0 text))
atom :: String -> Term
atom name = App (pred1 "give_up") (entity name)
exact :: SemModel -> String -> Term -> Bool
exact m text want = let rs = roots m text in not (null rs)
  && all ((==canonicalAC want) . canonicalAC . ssSem) rs
noSense :: SemModel -> String -> Bool
noSense m text = all (not . isInfixOf "give_up" . show . ssSem) (roots m text)
conserved :: String -> Bool
conserved text = not (null rs) && all ((==expected) . sort . provLeaves . ssProv) rs
  where
    rs = roots base text
    expected = sort [(SourceId "particle-contract",tokSpan t,tokText t)
                    | t <- casedTokens 0 text]
drsClaims :: Bool -> Bool
drsClaims negative = case prSentences (runPipelineWith (CCGBankParser base)
    (SourceId "particle-contract") text) of
  [r] -> case srDRS r of
    Just d -> let (as,rs,ps,es) = splitClaims d
              in canonicalize d == Canonical [] [condition]
                 && map (claimCond . fst) as == [condition]
                 && null rs && null ps
                 && map claimCond es == if negative then [a] else []
    Nothing -> False
  _ -> False
  where
    text = if negative then "Raul does not give up." else "Raul gives up."
    a = CanPred "give_up" [CConstT "Raul"]
    condition = if negative then CanNot (Canonical [] [a]) else a
competing :: SemModel
competing = base { smTags = buildTagModel
  [(w,cc c) | (w,c) <- [("Raul","NP"),("Ada","NP"),("gives","S[dcl]\\NP")
    ,("gives","(S[dcl]\\NP)/NP"),("up","(S\\NP)\\(S\\NP)")
    ,("up","NP"),(".",".")]] }
scoreEvidence :: Bool
scoreEvidence = not (null rs) && expected < 0
  && all (\r -> abs (ssScore r - expected) < 1e-9) rs
  where
    rs = filter ((==canonicalAC (atom "Raul")) . canonicalAC . ssSem)
         (roots competing "Raul gives up")
    score w cat = sum [s | (c,s) <- offeredTags competing False w, c == cc cat]
    expected = score "Raul" "NP" + score "gives" "S[dcl]\\NP"
               + score "up" "(S\\NP)\\(S\\NP)"
certificateEvidence :: Bool
certificateEvidence = let rs = roots base "Raul gives up"
  in not (null rs) && all (any (\(st,pv) -> stKind st == "particle-source-certificate"
       && stChoice st == "S[dcl]\\NP + (S\\NP)\\(S\\NP)"
       && provLeaves pv == [(SourceId "particle-contract",Span 5 10,"gives")
                          ,(SourceId "particle-contract",Span 11 13,"up")]) . ssNotes) rs
boundary :: Bool
boundary = all (\r -> maybe True (not . isInfixOf "give_up" . show) (srForm r)) $
  prSentences (runPipelineWith (CCGBankParser base) (SourceId "boundary") "Raul gives. Up.")
main :: IO ()
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
  , expect "positive DRS and claim status" (drsClaims False)
  , expect "negative DRS and claim barrier" (drsClaims True)
  , expect "source lexical scores conserved" scoreEvidence
  , expect "original categories and exact source occurrences recorded" certificateEvidence
  , expect "ordinary competing transitive sense retained"
      (any ((==canonicalAC (App (App (pred2 "give") (entity "Raul")) (entity "Ada"))) . canonicalAC . ssSem)
        (roots competing "Raul gives Ada"))
  , expect "licensed sense remains among competing offers"
      (any ((==canonicalAC (atom "Raul")) . canonicalAC . ssSem) (roots competing "Raul gives up"))
  , expect "sentence boundary not crossed" boundary
  , expect "repeated sentences preserve distinct offsets"
      (let rs = prSentences (runPipelineWith (CCGBankParser base) (SourceId "repeat")
                    "Raul gives up. Ada gives up.")
       in map srForm rs == [Just (atom "Raul"),Just (atom "Ada")]
          && case map srChosen rs of
            [Just a,Just b] -> provLeaves (sProv a) ==
                 [(SourceId "repeat",Span 0 4,"Raul"),(SourceId "repeat",Span 5 10,"gives")
                 ,(SourceId "repeat",Span 11 13,"up"),(SourceId "repeat",Span 13 14,".")]
               && provLeaves (sProv b) ==
                 [(SourceId "repeat",Span 15 18,"Ada"),(SourceId "repeat",Span 19 24,"gives")
                 ,(SourceId "repeat",Span 25 27,"up"),(SourceId "repeat",Span 27 28,".")]
            _ -> False)
  ] ++
  [ expect label (noSense model text) | (label,model,text) <-
    [("feature-bearing subject not accepted",mini "S[dcl]\\NP[expl]" "(S\\NP)\\(S\\NP)","Raul gives up.")
    ,("base feature on finite form not accepted",mini "S[b]\\NP" "(S\\NP)\\(S\\NP)","Raul gives up.")
    ,("featured particle not accepted",mini "S[dcl]\\NP" "(S[dcl]\\NP)\\(S[dcl]\\NP)","Raul gives up.")
    ,("reversed tokens",base,"Raul up gives.")
    ,("doubled particle",base,"Raul gives up up.")
    ,("absent particle",base,"Raul gives.")
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
