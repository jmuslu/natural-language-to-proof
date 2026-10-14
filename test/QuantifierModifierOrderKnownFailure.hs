-- Known structural fidelity failure, deliberately outside cabal release suites.
-- Run: runghc -isrc test/QuantifierModifierOrderKnownFailure.hs
-- Expected until repaired: prints observed reverse modifier order, exits 1.
-- Truth conditions agree for these intersective adjectives; canonical DRS
-- fidelity additionally requires noun head then modifiers in surface order.
module Main (main) where

import Control.Monad (unless)
import System.Exit (exitFailure)
import NL2Proof.Semantics.CCGSem
import NL2Proof.Semantics.Lambda
import NL2Proof.Syntax.CCGBank (parseCCGCat)

main :: IO ()
main = do
  let modifier word = case openTemplate word (either error id (parseCCGCat "N/N")) of
        Just (LexTerm t _ _) -> t
        _ -> error ("Missing modifier template: " ++ word)
      -- Independently intended reading of "blue young cats".
      expected = ["cat", "blue", "young"]
      term = normalize (App (App (modifier "blue")
                  (App (modifier "young") (pred1 "cat"))) (entity "Mira"))
      atoms (TAnd left right) = atoms left ++ atoms right
      atoms t = [word | word <- ["cat", "blue", "young"],
                        alphaEq t (App (pred1 word) (entity "Mira"))]
      observed = atoms term
      -- Check all leaves as well as predicate order, never discard unknown terms.
      leaves (TAnd left right) = leaves left + leaves right
      leaves _ = 1 :: Int
      ok = leaves term == length expected && observed == expected
  putStrLn ("Expected noun then surface modifiers: " ++ show expected)
  putStrLn ("Observed composed predicate order: " ++ show observed)
  putStrLn (if ok then "PASS multi-modifier structural fidelity"
                 else "FAIL known multi-modifier structural fidelity")
  unless ok exitFailure
