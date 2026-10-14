-- | Proper names need lexical evidence as well as a usable N/NP category.
-- Hand-authored dictionary controls are independent of licensed corpus data.
module Main (main) where

import Data.List (isInfixOf)
import qualified Data.Set as Set
import System.Environment (getArgs)

import Harness
import NL2Proof.DRT.Canonical
import NL2Proof.Pipeline
import NL2Proof.Provenance
import NL2Proof.Semantics.CCGSem
import NL2Proof.Semantics.Lambda
import NL2Proof.Syntax.CCGBank (CCat, parseCCGCat)
import NL2Proof.Syntax.CCGParse (Rules(..))
import NL2Proof.Syntax.CCGSemParse
import NL2Proof.Syntax.CCGSupertag (buildPOSModel, buildTagModel)
import NL2Proof.Verify.ClaimKind (claimCond)
import NL2Proof.Verify.Reported (splitClaims)

main :: IO ()
main = do
  args <- getArgs
  if args == ["--corpus"]
    then do
      dir <- ccgbankDataDir
      (model, _) <- loadSemModel dir
      runChecks "name-sem-corpus" (corpusChecks model)
    else runChecks "name-sem" checks

cc :: String -> CCat
cc = either error id . parseCCGCat

mini :: SemModel
mini = (defaultSemModel tags poses rules Set.empty)
  { smAlpha = 0, smSeenRules = False }
  where
    observations =
      [ ("Ari", "N", "NNP"), ("Iris", "NP", "NNP")
      , ("Theodora", "NP[nb]", "NNP"), ("Roberts", "NP", "NNPS")
      , ("plain", "NP", "NN"), ("legend", "N", "NN")
      , ("White", "N", "NNP"), ("white", "N/N", "JJ")
      , ("cats", "N", "NNS"), ("Cloud", "N", "NNP"), ("cloud", "N", "NN")
      , ("Expletive", "NP[expl]", "NNP"), ("Dummy", "NP[thr]", "NNP")
      , ("Pending", "NP[conj]", "NNP")
      , ("red", "S[adj]\\NP", "JJ"), ("big", "S[adj]\\NP", "JJ")
      , ("is", "(S[dcl]\\NP)/(S[adj]\\NP)", "VBZ")
      , ("are", "(S[dcl]\\NP)/(S[adj]\\NP)", "VBP")
      , ("not", "(S\\NP)\\(S\\NP)", "RB")
      , ("likes", "(S[dcl]\\NP)/NP", "VBZ"), (".", ".", ".") ]
    tags = buildTagModel [(w,cc c) | (w,c,_) <- observations]
    poses = buildPOSModel [(w,p) | (w,_,p) <- observations]
    rules = Rules [(cc "N",cc "NP")] []

sentence :: SemModel -> String -> SentenceResult
sentence model txt = case prSentences
    (runPipelineWith (CCGBankParser model) (SourceId "name-test") txt) of
  [result] -> result
  _ -> error "expected one sentence"

forms :: SemModel -> String -> [Term]
forms model = foldr collect [] . srReadings . sentence model
  where collect reading acc = maybe acc (:acc) (rrForm reading)

expectedName :: String -> Term
expectedName n = Lam "P" tyPred1 (App (Var "P") (entity n))

nameTerms :: Int -> String -> [(CCat,Term)]
nameTerms index w =
  [(lxCat sign,term) | sign <- lexicalSigns mini index w
                    , LexTerm term gloss _ <- [lxItem sign]
                    , gloss == "proper name"]

formCheck :: String -> String -> Term -> Check
formCheck label txt want = case srForm (sentence mini txt) of
  Just got | canonicalAC got == canonicalAC want -> ok label
           | otherwise -> bad label ("got " ++ pretty got)
  Nothing -> bad label "no parsed meaning"

nameNotes :: Int -> String -> [Stipulation]
nameNotes index w =
  [note | sign <- lexicalSigns mini index w
        , LexTerm _ "proper name" (Just note) <- [lxItem sign]]

checks :: [Check]
checks =
  [ expect "forced licensed name records no invented lexical alternative"
      (let notes = nameNotes 0 "Iris"
       in not (null notes) && all (null . stAlternatives) notes)
  , expect "ambiguous initial capital records only actual open lexical alternatives"
      (let notes = nameNotes 0 "Zorlan"
           actual = [show (lxCat sign) ++ ": " ++ gloss
                    | sign <- lexicalSigns mini 0 "Zorlan"
                    , LexTerm _ gloss _ <- [lxItem sign], gloss /= "proper name"]
       in not (null notes) && not (null actual)
          && all ((==actual) . stAlternatives) notes)
  , expect "POS-licensed name trace identifies dictionary evidence"
      (all (isInfixOf "majority POS NNP" . stWhy) (nameNotes 0 "Iris"))
  , expect "direct NP name preserves offered category score"
      ([lxScore sign | sign <- lexicalSigns mini 0 "Iris"] ==
       [score | (category,score) <- offeredTags mini True "Iris", category == cc "NP"])
  , expect "direct NP name has licensed NP meaning"
      ((cc "NP",expectedName "Iris") `elem` nameTerms 0 "Iris")
  , expect "non-bare NP name retains its syntactic feature"
      ((cc "NP[nb]",expectedName "Theodora") `elem` nameTerms 0 "Theodora")
  , expect "NNPS also licenses an already-NP name"
      ((cc "NP",expectedName "Roberts") `elem` nameTerms 0 "Roberts")
  , expect "existing N-tagged name still lifts to NP"
      ((cc "NP",expectedName "Ari") `elem` nameTerms 0 "Ari")
  , formCheck "already-NP subject composes by ordinary application"
      "Iris is red." (App (pred1 "red") (entity "Iris"))
  , formCheck "already-NP object keeps argument order"
      "Ari likes Iris." (apply (pred2 "like") [entity "Ari",entity "Iris"])
  , formCheck "repeated name denotes one rigid constant"
      "Iris likes Iris." (apply (pred2 "like") [entity "Iris",entity "Iris"])
  , formCheck "NP feature does not change name meaning"
      "Theodora is red." (App (pred1 "red") (entity "Theodora"))
  , expect "all returned readings of a POS-licensed name preserve its denotation"
      (let actual = forms mini "Iris is red."
           want = canonicalAC (App (pred1 "red") (entity "Iris"))
       in not (null actual) && all ((==want) . canonicalAC) actual)
  , expect "each name lexical term inhabits its category type"
      (and [typeOf [] term == Right ty
           | w <- ["Ari","Iris","Theodora","Roberts"]
           , (category,term) <- nameTerms 0 w, Just ty <- [semTy category]])
  , expect "direct NP becomes a constant, without an existential witness"
      (fmap canonicalize (srDRS (sentence mini "Iris is red.")) ==
        Just (Canonical [] [CanPred "red" [CConstT "Iris"]]))
  , expect "positive name sentence asserts exactly the rigid atom"
      (case srDRS (sentence mini "Iris is red.") of
        Just drs -> let (as,rs,ps,es) = splitClaims drs
                    in map (claimCond . fst) as == [CanPred "red" [CConstT "Iris"]]
                       && null rs && null ps && null es
        Nothing -> False)
  , expect "negated name atom remains embedded under whole assertion"
      (case srDRS (sentence mini "Iris is not red.") of
        Just drs -> let (as,rs,ps,es) = splitClaims drs
                        atom = CanPred "red" [CConstT "Iris"]
                    in map (claimCond . fst) as == [CanNot (Canonical [] [atom])]
                       && map claimCond es == [atom] && null rs && null ps
        Nothing -> False)
  , expectEq "NP alone is not evidence of a proper name"
      NotName (nameStatus mini False "plain")
  , expect "ordinary NP token does not acquire a rigid name"
      (null (nameTerms 2 "plain"))
  , expectEq "initial ordinary plural remains non-name"
      NotName (nameStatus mini True "Cats")
  , expect "capitalized ordinary plural has no name candidate"
      (null (nameTerms 0 "Cats"))
  , expectEq "initial adjective uses lower-case dictionary evidence"
      NotName (nameStatus mini True "White")
  , formCheck "sentence-initial adjective still modifies common noun"
      "White cats are red."
      (TForall "x" TyE (TImp
        (TAnd (App (pred1 "white") (Var "x")) (App (pred1 "cats") (Var "x")))
        (App (pred1 "red") (Var "x"))))
  , expectEq "known lower-case common noun is not forced to a name"
      NotName (nameStatus mini True "Legend")
  , expectEq "capitalized proper/common homograph remains conservatively truecased"
      NotName (nameStatus mini True "Cloud")
  , expectEq "unseen initial capital remains explicitly ambiguous"
      NameOrOther (nameStatus mini True "Zorlan")
  , expectEq "existing noninitial capitalization policy is preserved"
      NameOnly (nameStatus mini False "Zorlan")
  , expect "expletive category is not reinterpreted as a name"
      (null (nameTerms 0 "Expletive"))
  , expect "dummy there category is not reinterpreted as a name"
      (null (nameTerms 0 "Dummy"))
  , expect "pending conjunction category is not made into an independent name"
      (null (nameTerms 0 "Pending"))
  ]

-- Only compact hand-authored controls are committed. The real dictionary is
-- loaded locally and never dumped. Legend's unresolved initial ambiguity is
-- documented in research/linguistics/NAMES.md, not given incorrect gold here.
corpusChecks :: SemModel -> [Check]
corpusChecks model =
  [ expect ("default corpus rigid top reading: " ++ n)
      (fmap canonicalAC (srForm (sentence model (n ++ " is red."))) ==
        Just (canonicalAC (App (pred1 "red") (entity n))))
  | n <- ["Bob","Brecken","Abdullah"] ]
  ++ [ expect "default corpus initial ordinary plural has no name candidate"
       (nameStatus model True "Cats" == NotName)
     , expect "default corpus initial adjective has no name candidate"
       (nameStatus model True "White" == NotName)
     ]
