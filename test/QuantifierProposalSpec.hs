-- Standalone acceptance specification for the reviewed quantifier repair.
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
        ++ [(w ++ " retains established determiner meaning", entryIs w meaning)
           | (w, meaning) <- [("a", someTerm), ("an", someTerm), ("all", eachTerm), ("every", eachTerm)]]
        ++ [(w ++ " rejects incompatible category " ++ category,
               null (closedEntries 0 w (cc category)))
           | w <- ["some", "no", "each"], category <- ["NP/N", "N/N", "N", "NP"]]
        ++ [("some with negative scope keeps existential outside negation",
               entryWith "some" negativeScope someNegative)
           ,("no with negative scope negates the whole existential",
               entryWith "no" negativeScope (TNot someNegative))]
  mapM_ (\(name, ok) -> putStrLn ((if ok then "PASS " else "FAIL ") ++ name)) checks
  unless (all snd checks) exitFailure
  where
    x = Var "x"
    noun = pred1 "cat"
    scope = pred1 "red"
    someTerm = TExists "x" TyE (TAnd (App noun x) (App scope x))
    eachTerm = TForall "x" TyE (TImp (App noun x) (App scope x))
    cc s = either error id (parseCCGCat s)
    negativeScope = Lam "y" TyE (TNot (App scope (Var "y")))
    someNegative = TExists "x" TyE (TAnd (App noun x) (TNot (App scope x)))
    entryIs w = entryWith w scope
    entryWith w predicate expected = any (matches predicate expected) (closedEntries 0 w (cc "NP[nb]/N"))
    matches predicate expected (LexTerm t _ _) = alphaEq (normalize (apply t [noun, predicate])) expected
    matches _ _ _ = False
