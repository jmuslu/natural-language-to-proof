-- Independent red controls for a POS/category/base-attested regular noun rule.
-- No licensed corpus is loaded and no production implementation is bundled.
module Main (main) where
import qualified Data.Set as Set
import Harness
import NL2Proof.Semantics.CCGSem
import NL2Proof.Semantics.Lambda
import NL2Proof.Syntax.CCGBank (parseCCGCat)
import NL2Proof.Syntax.CCGParse (Rules(..))
import NL2Proof.Syntax.CCGSemParse
import NL2Proof.Syntax.CCGSupertag (buildPOSModel,buildTagModel)

cc = either error id . parseCCGCat
model observations = (defaultSemModel
  (buildTagModel [(w,cc c) | (w,c,_) <- observations])
  (buildPOSModel [(w,p) | (w,_,p) <- observations]) (Rules [] []) Set.empty)
  {smAlpha=0,smSeenRules=False}
terms observations word = [normalize t | sign <- lexicalSigns (model observations) 1 word,
  lxCat sign == cc "N", LexTerm t _ _ <- [lxItem sign]]
noun word = normalize (Lam "x" TyE (App (pred1 word) (Var "x")))
expectN label observations word expected = expectEq label [noun expected] (terms observations word)
base = [("lantern","N","NN"),("lanterns","N","NNS"),
        ("garden","N","NN"),("gardens","N","NNS")]
main = runChecks "noun-lemma-proposal"
  [ expectN "attested regular noun lanterns shares singular predicate" base "lanterns" "lantern"
  , expectN "independent regular noun gardens shares singular predicate" base "gardens" "garden"
  , expectN "singular noun remains unchanged" base "lantern" "lantern"
  , expectN "missing singular dictionary evidence does not invent lemma"
      [("lanterns","N","NNS")] "lanterns" "lanterns"
  , expectN "singular s-final noun is not stripped"
      [("glass","N","NN"),("glas","N","NN")] "glass" "glass"
  , expectN "verb POS cannot license nominal singularization"
      [("lanterns","N","VBZ"),("lantern","N","NN")] "lanterns" "lanterns"
  , expectN "NN-only surface does not license plural normalization"
      [("cranes","N","NN"),("crane","N","NN")] "cranes" "cranes"
  , expectN "axes excluded despite competing attested axe ax axis"
      [("axes","N","NNS"),("axe","N","NN"),("ax","N","NN"),("axis","N","NN")]
      "axes" "axes"
  , expectN "bases excluded despite attested base basis"
      [("bases","N","NNS"),("base","N","NN"),("basis","N","NN")]
      "bases" "bases"
  , expectN "all es endings excluded even when crane singular is valid"
      [("cranes","N","NNS"),("crane","N","NN")] "cranes" "cranes"
  , expectN "news shape excluded even with synthetic NN new evidence"
      [("news","N","NNS"),("new","N","NN")] "news" "news"
  , expectN "species excluded despite synthetic specie evidence"
      [("species","N","NNS"),("specie","N","NN")] "species" "species"
  , expectN "multiword noun token retains compound identity"
      [("bald eagles","N","NNS"),("bald eagle","N","NN")]
      "bald eagles" "bald eagles"
  , expectN "hyphenated compound not singularized"
      [("sea-birds","N","NNS"),("sea-bird","N","NN")]
      "sea-birds" "sea-birds"
  , expectN "capitalized plural token cannot trigger lowercase noun hook"
      [("Lanterns","N","NNS"),("lantern","N","NN")]
      "Lanterns" "lanterns"
  , expectN "plural noun plus adjective evidence is ambiguous"
      [("gardens","N","NNS"),("gardens","N","JJ"),("garden","N","NN")]
      "gardens" "gardens"
  , expectN "plural noun plus singular noun evidence is ambiguous"
      [("gardens","N","NNS"),("gardens","N","NN"),("garden","N","NN")]
      "gardens" "gardens"
  , expectN "plural noun plus verb evidence is ambiguous"
      [("gardens","N","NNS"),("gardens","N","VBZ"),("garden","N","NN")]
      "gardens" "gardens"
  , expectN "singular base plus verb evidence is ambiguous"
      [("gardens","N","NNS"),("garden","N","NN"),("garden","N","VB")]
      "gardens" "gardens"
  , expectN "minority name evidence blocks noun normalization"
      [("gardens","N","NNS"),("gardens","N","NNS"),("gardens","N","NNP"),
       ("garden","N","NN")] "gardens" "gardens"
  , expectEq "proper name keeps s and written case"
      (Just (canonicalAC (Lam "P" tyPred1 (App (Var "P") (entity "James")))))
      (case nameItem "James" of LexTerm t _ _ -> Just (canonicalAC t); _ -> Nothing)
  , expectEq "verbal excels already has correct base lemma" "excel" (verbLemma "excels")
  , expectEq "reporting normalization retains added key" "add" (reportingLemma "Added")
  , expectEq "explicit-that set uses shared reporting key" (Set.singleton "add")
      (smThatAttested (model [("added","(S[dcl]\\NP)/S[em]","VBD")]))
  , expectEq "noun evidence does not add an attitude attestation" Set.empty
      (smThatAttested (model base))
  , expectEq "ambiguous adjective excels must not be globally rewritten"
      (Just (canonicalAC (normalize (Lam "Q" tyGQ (App (Var "Q")
        (Lam "x" TyE (App (pred1 "excels") (Var "x"))))))))
      (case openTemplate "excels" (cc "S[adj]\\NP") of
        Just (LexTerm t _ _) -> Just (canonicalAC (normalize t)); _ -> Nothing)
  ]
