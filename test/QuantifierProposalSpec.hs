-- Standalone red specification for the reviewed quantifier proposal.
-- No corpus or parser model is loaded. Run: runghc -isrc test/QuantifierProposalSpec.hs
module Main (main) where

import Control.Monad (unless)
import System.Exit (exitFailure)
import NL2Proof.Semantics.CCGSem
import NL2Proof.Semantics.Lambda
import NL2Proof.Syntax.CCGBank (parseCCGCat)

main :: IO ()
main = do
  let checks = [(w ++ " is reserved", isClosedClass w) | w <- ["some", "no", "each"]]
        ++ [(w ++ " determiner has intended normal form", entryIs w meaning)
           | (w, meaning) <- [("some", someTerm), ("no", TNot someTerm), ("each", eachTerm)]]
        ++ [("intersective restriction emits noun head before modifier", modifierOrder)]
  mapM_ (\(name, ok) -> putStrLn ((if ok then "PASS " else "FAIL ") ++ name)) checks
  unless (all snd checks) exitFailure
  where
    x = Var "x"
    noun = pred1 "cat"
    scope = pred1 "red"
    someTerm = TExists "x" TyE (TAnd (App noun x) (App scope x))
    eachTerm = TForall "x" TyE (TImp (App noun x) (App scope x))
    cc s = either error id (parseCCGCat s)
    entryIs w expected = any (matches expected) (closedEntries 0 w (cc "NP[nb]/N"))
    matches expected (LexTerm t _ _) = alphaEq (normalize (apply t [noun, scope])) expected
    matches _ _ = False
    modifierOrder = case openTemplate "red" (cc "N/N") of
      Just (LexTerm t _ _) -> alphaEq (normalize (apply t [noun, entity "Mira"]))
        (TAnd (App noun (entity "Mira")) (App scope (entity "Mira")))
      _ -> False
