-- | Corpus-free, test-first contract for local direct-object reflexives.
-- Expected meanings are independently reduced; no production rule is copied here.
-- Not in cabal until coordinator review; current production should fail it.
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

mini :: String -> SemModel
mini reflexTag = (defaultSemModel tags poses rules Set.empty)
  { smAlpha = 0, smSeenRules = False }
  where
    obs = [("Amara","NP","NNP"),("Anne","NP","NNP")
      ,("cat","N","NN"),("Every","NP[nb]/N","DT")
      ,("defends","(S[dcl]\\NP)/NP","VBZ")
      ,("grooms","(S[dcl]\\NP)/NP","VBZ")
      ,("defend","(S[b]\\NP)/NP","VB")
      ,("does","(S[dcl]\\NP)/(S[b]\\NP)","VBZ")
      ,("not","(S\\NP)\\(S\\NP)","RB")
      ,("herself",reflexTag,"PRP"),("itself",reflexTag,"PRP")
      ,("is","(S[dcl]\\NP)/(S[adj]\\NP)","VBZ")
      ,("red","S[adj]\\NP","JJ"),(".",".",".")]
    tags = buildTagModel [(w,cc c) | (w,c,_) <- obs]
    poses = buildPOSModel [(w,p) | (w,_,p) <- obs]
    rules = Rules [(cc "N",cc "NP")] []

forms :: SemModel -> String -> [Maybe Term]
forms m text = map srForm . prSentences $
  runPipelineWith (CCGBankParser m) (SourceId "reflexive-proposal") text

same :: Term -> Maybe Term -> Bool
same want = maybe False ((==canonicalAC want) . canonicalAC)

atom :: String -> Term -> Term -> Term
atom p x y = App (App (pred2 p) x) y

main :: IO ()
main = runChecks "reflexive-proposal" checks

checks :: [Check]
checks =
  [ expect "reserved reflexive cannot become a noun or rigid name"
      (all isClosedClass ["himself","herself","itself","themselves"])
  , expect "closed diagonal entry exists and inhabits category type"
      (not (null entries) && all coherent entries)
  , expect "named subject binds reflexive from offered NP"
      (forms (mini "NP") "Amara defends herself." `matches` [named])
  , expect "reflexive offered N does not undergo generic universal"
      (forms (mini "N") "Amara defends herself." `matches` [named])
  , expect "quantified subject scopes once over diagonal relation"
      (forms (mini "NP") "Every cat grooms itself." `matches` [quantified])
  , expect "negation contains local diagonal relation"
      (forms (mini "NP") "Amara does not defend herself." `matches` [TNot named])
  , expect "preceding named subject cannot capture the reflexive"
      (forms (mini "NP") "Anne is red. Amara defends herself."
        `matches` [App (pred1 "red") (entity "Anne"),named])
  , expect "no returned named reading retains reflexive noun universal"
      (let rs = concatMap srReadings . prSentences $
                   runPipelineWith (CCGBankParser (mini "NP"))
                     (SourceId "reflexive-readings") "Amara defends herself."
       in not (null rs) && all (same named . rrForm) rs)
  ] ++
  [ expect ("unsupported offered reflexive category fails closed: " ++ c)
      (null (lexicalSigns (mini c) 2 "herself"))
  | c <- ["NP[expl]","NP[thr]","N/N","PP","S[dcl]\\NP"] ]
  where
    named = atom "defend" (entity "Amara") (entity "Amara")
    quantified = TForall "x" TyE
      (TImp (App (pred1 "cat") (Var "x")) (atom "groom" (Var "x") (Var "x")))
    cat = cc "(S[dcl]\\NP)\\((S[dcl]\\NP)/NP)"
    entries = closedEntries 2 "herself" cat
    coherent (LexTerm t _ _) = case semTy cat of
      Just ty -> typeOf [] t == Right ty
      Nothing -> False
    coherent _ = False
    matches got want = length got == length want && and (zipWith same want got)
