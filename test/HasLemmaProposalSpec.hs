-- | Authored category-boundary and composition tests for has -> have.
-- Standalone proposal: no CCGbank load and no production change is bundled.
module Main (main) where

import Harness
import NL2Proof.Semantics.CCGSem
import NL2Proof.Semantics.Lambda
import NL2Proof.Syntax.CCGBank (CCat, parseCCGCat)

cc :: String -> CCat
cc = either error id . parseCCGCat

term :: Maybe LexItem -> Maybe Term
term (Just (LexTerm t _ _)) = Just t
term _ = Nothing

meaning :: String -> String -> Maybe Term
meaning word category = term (openTemplate word (cc category))

same :: String -> Term -> Maybe Term -> Check
same label want got = expectEq label (Just (canonicalAC (normalize want)))
  (canonicalAC . normalize <$> got)

liftName :: String -> Term
liftName name = Lam "P" tyPred1 (App (Var "P") (entity name))

transitive :: String -> Term
transitive relation = Lam "O" tyGQ (Lam "Q" tyGQ
  (App (Var "Q") (Lam "x" TyE
    (App (Var "O") (Lam "y" TyE
      (apply (pred2 relation) [Var "x",Var "y"]))))))

possession :: Maybe Term
possession = do
  verb <- meaning "has" "(S[dcl]\\NP)/NP"
  noun <- meaning "kite" "N"
  det <- case [t | (word,c,LexTerm t _ _) <- closedTable 0
                , word == "a", c == cc "NP[nb]/N"] of
    t:_ -> Just t
    [] -> Nothing
  pure (apply verb [App det noun,liftName "Mira"])

main :: IO ()
main = runChecks "has-lemma-proposal"
  [ expectEq "reviewed irregular has normalizes to have" "have" (verbLemma "has")
  , expectEq "shared reporting/attestation key lowercases Has" "have" (reportingLemma "Has")
  , same "finite transitive has uses have relation" (transitive "have")
      (meaning "has" "(S[dcl]\\NP)/NP")
  , same "base have retains have relation" (transitive "have")
      (meaning "have" "(S[b]\\NP)/NP")
  , same "has under offered base category shares lexical key" (transitive "have")
      (meaning "has" "(S[b]\\NP)/NP")
  , same "Mira has a kite binds one object with have" (TExists "x" TyE
      (TAnd (App (pred1 "kite") (Var "x"))
            (apply (pred2 "have") [entity "Mira",Var "x"]))) possession
  , same "proper-name James constant preserves final s" (liftName "James")
      (term (Just (nameItem "James")))
  , same "singular common noun glass preserves final s"
      (Lam "x" TyE (App (pred1 "glass") (Var "x"))) (meaning "glass" "N")
  , same "synthetic noun has bypasses verbal normalization"
      (Lam "x" TyE (App (pred1 "has") (Var "x"))) (meaning "has" "N")
  , same "synthetic adjective has bypasses verbal normalization"
      (Lam "Q" tyGQ (App (Var "Q") (Lam "x" TyE
        (App (pred1 "has") (Var "x"))))) (meaning "has" "S[adj]\\NP")
  , expectEq "perfect-auxiliary category gets no possessive template" Nothing
      (meaning "has" "(S[dcl]\\NP)/(S[pt]\\NP)")
  , expect "offered finite transitive term remains category-typed" $ case
      meaning "has" "(S[dcl]\\NP)/NP" of
        Just t -> Just (typeOf [] t) == fmap Right (semTy (cc "(S[dcl]\\NP)/NP"))
        Nothing -> False
  ]
