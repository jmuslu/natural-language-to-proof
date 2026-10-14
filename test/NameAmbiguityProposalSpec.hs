-- | Corpus-free evidence/segmentation controls for a proposed name-policy
-- revision. No parser or CCGbank loader is called. Proposed checks intentionally
-- remain red until a reviewed implementation exists; do not register as a gate.
module Main (main) where

import qualified Data.Set as Set
import System.Environment (getArgs)
import Harness
import NL2Proof.Provenance (Span(..))
import NL2Proof.Semantics.CCGSem (LexItem(..))
import NL2Proof.Semantics.Lambda
import NL2Proof.Syntax.CCGBank (CCat, parseCCGCat)
import NL2Proof.Syntax.CCGParse (Rules(..))
import NL2Proof.Syntax.CCGSemParse
import NL2Proof.Syntax.CCGSupertag (buildPOSModel, buildTagModel)
import NL2Proof.Syntax.Tokenize (Sentence(..), splitSentences)

cc :: String -> CCat
cc = either error id . parseCCGCat

model :: SemModel
model = makeModel observations

makeModel :: [(String,String,String)] -> SemModel
makeModel rows = (defaultSemModel
  (buildTagModel [(w,cc c) | (w,c,_) <- rows])
  (buildPOSModel [(w,p) | (w,_,p) <- rows])
  (Rules [(cc "N",cc "NP")] []) Set.empty)
  { smAlpha = 0, smSeenRules = False }

observations :: [(String,String,String)]
observations =
  [ ("Iris","NP","NNP"), ("Ari","N","NNP"), ("Roberts","NP","NNPS")
  , ("Dean","NP","NNP"), ("dean","N","NN")
  , ("Legend","NP","NNP"), ("legend","N","NN")
  , ("White","NP","NNP"), ("white","N/N","JJ")
  , ("cats","N","NNS"), ("red","S[adj]\\NP","JJ")
  , ("American","NP","NNP"), ("American","NP","NNP")
  , ("American","NP","NNP"), ("American","S[adj]\\NP","JJ")
  , ("is","(S[dcl]\\NP)/(S[adj]\\NP)","VBZ")
  ]

nameTerms :: SemModel -> Int -> String -> [Term]
nameTerms m i w = [t | s <- lexicalSigns m i w, LexTerm t "proper name" _ <- [lxItem s]]

rigid :: String -> Term
rigid n = Lam "P" tyPred1 (App (Var "P") (entity n))

main :: IO ()
main = do
  args <- getArgs
  runChecks "name-ambiguity-proposal" (case args of
    ["--evidence"] -> evidence
    ["--proposed"] -> proposed
    _ -> evidence ++ proposed)

-- These preserve the existing bounded name-meaning repair and expose the
-- available evidence without turning it into a claim of identity certainty.
evidence :: [Check]
evidence =
  [ expect "POS-licensed direct NP keeps the rigid name meaning"
      (rigid "Iris" `elem` nameTerms model 0 "Iris")
  , expect "POS-licensed N keeps the accepted lexical NP lifting"
      (rigid "Ari" `elem` nameTerms model 0 "Ari")
  , expect "NNPS name remains possible despite final s"
      (rigid "Roberts" `elem` nameTerms model 0 "Roberts")
  , expectEq "known lower-case common role is not forced to a name"
      NotName (nameStatus model False "dean")
  , expectEq "attested common plural is not forced to a name"
      NotName (nameStatus model True "Cats")
  , expectEq "unseen sentence-initial name-shaped word is uncertain"
      NameOrOther (nameStatus model True "Zorlan")
  , expectEq "unseen plural-looking word is likewise uncertain without number evidence"
      NameOrOther (nameStatus model True "Gorpuses")
  , expectEq "independently attested NNS supplies stronger plural evidence"
      NotName (nameStatus (makeModel (("gorpuses","N","NNS"):observations)) True "Gorpuses")
  , expect "name analysis of a demonym remains available but is not the only linguistic use"
      (not (null (nameTerms model 1 "American")))
  , expect "rigid and generic readings are both type t despite distinct truth conditions"
      (let a = App (pred1 "red") (entity "Zorlan")
           b = TForall "x" TyE (TImp (App (pred1 "zorlan") (Var "x")) (App (pred1 "red") (Var "x")))
       in typeOf [] a == Right TyT && typeOf [] b == Right TyT && not (alphaEq a b))
  , expectEq "ordinary sentence boundaries remain separate"
      ["Iris is red.","Ari is kind."]
      (map sentText (splitSentences "Iris is red. Ari is kind."))
  , expectEq "an isolated title abbreviation remains a fragment, not a fabricated person"
      ["Dr."] (map sentText (splitSentences "Dr."))
  ]

-- These are intended preimplementation failures: lexical alternatives must not
-- disappear because majority POS or initial truecasing chose another role.
-- Retaining an alternative alone does NOT authorize automatic fact admission.
proposed :: [Check]
proposed =
  [ expect "initial common-role homograph retains independently attested name evidence"
      (not (null (nameTerms model 0 "Dean")))
  , expect "initial common-noun homograph retains independently attested name evidence"
      (not (null (nameTerms model 0 "Legend")))
  , expect "initial adjective homograph retains name evidence for syntax to distinguish"
      (not (null (nameTerms model 0 "White")))
  , expect "attested adjectival category survives majority name POS"
      (any (\s -> lxCat s == cc "S[adj]\\NP") (lexicalSigns model 1 "American"))
  , expectEq "unseen noninitial capitalization alone does not certify identity"
      NameOrOther (nameStatus model False "Zorlan")
  , expectEq "title period does not split the following full referring span"
      ["Dr. Yareli Hernandez is empathetic."]
      (map sentText (splitSentences "Dr. Yareli Hernandez is empathetic."))
  , expectEq "negative title clause is not a successful suffix plus failed Dr fragment"
      ["Dr. Marlon is not analytical."]
      (map sentText (splitSentences "Dr. Marlon is not analytical."))
  , expectEq "title rule is general across honorifics and invented names"
      ["Prof. Zorlan is kind."] (map sentText (splitSentences "Prof. Zorlan is kind."))
  , expectEq "abbreviation handling preserves following real sentence boundary"
      ["Dr. Iris is red.","Ari is kind."]
      (map sentText (splitSentences "Dr. Iris is red. Ari is kind."))
  , expectEq "abbreviation-aware spans preserve exact document offsets"
      [Sentence (Span 2 18) "Dr. Iris is red.",Sentence (Span 20 32) "Ari is kind."]
      (splitSentences "  Dr. Iris is red.  Ari is kind.")
  ]
