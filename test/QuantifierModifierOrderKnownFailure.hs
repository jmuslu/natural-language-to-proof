-- Known structural fidelity failure, deliberately outside cabal release suites.
-- Run: runghc -isrc test/QuantifierModifierOrderKnownFailure.hs
-- Expected until repaired: reports single/multiple modifier order mismatches, exits 1.
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
      -- Independently intended canonical convention; not copied from parser.
      cases = [("red cats", ["cat", "red"],
                   App (App (modifier "red") (pred1 "cat")) (entity "Mira")),
               ("blue young cats", ["cat", "blue", "young"],
                   App (App (modifier "blue")
                      (App (modifier "young") (pred1 "cat"))) (entity "Mira"))]
      atoms (TAnd left right) = atoms left ++ atoms right
      atoms t = [word | word <- ["cat", "red", "blue", "young"],
                        alphaEq t (App (pred1 word) (entity "Mira"))]
      -- Check all leaves, never discard unknown terms when deciding success.
      leaves (TAnd left right) = leaves left + leaves right
      leaves _ = 1 :: Int
      check (name, expected, raw) = do
        let term = normalize raw
            observed = atoms term
            ok = leaves term == length expected && observed == expected
        putStrLn (name ++ ": expected " ++ show expected ++ ", observed " ++ show observed)
        putStrLn ((if ok then "PASS " else "FAIL known ") ++ "modifier structural fidelity")
        pure ok
  results <- mapM check cases
  unless (and results) exitFailure
