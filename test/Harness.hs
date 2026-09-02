-- | A minimal test harness.
--
-- Dependency-free on purpose. The toolchain here is a bare GHC bindist with no
-- package manager, and Stage 1 needs nothing beyond @base@ and @containers@;
-- pulling in a test framework would be the project's first external dependency
-- and would buy very little over this.
--
-- Lives on @main@ and is shared so that each mode branch's @test\/ModeSpec.hs@
-- can use it without copying it or editing anything shared.
module Harness
  ( Check(..)
  , ok
  , bad
  , expect
  , expectEq
  , runChecks
  ) where

import Control.Monad (unless)
import System.Exit (exitFailure)

data Check = Check
  { chkName :: String
  , chkOk   :: Bool
  , chkNote :: String
  }

ok :: String -> Check
ok n = Check n True ""

bad :: String -> String -> Check
bad n why = Check n False why

expect :: String -> Bool -> Check
expect n True  = ok n
expect n False = bad n "expected True"

expectEq :: (Eq a, Show a) => String -> a -> a -> Check
expectEq n want got
  | want == got = ok n
  | otherwise   = bad n ("expected " ++ show want ++ ", got " ++ show got)

-- | Report every check, then exit non-zero if any failed.
runChecks :: String -> [Check] -> IO ()
runChecks label checks = do
  mapM_ report checks
  putStrLn ""
  putStrLn
    ( label ++ ": " ++ show (total - failed) ++ "/" ++ show total
        ++ " checks passed"
        ++ (if failed == 0 then "" else ", " ++ show failed ++ " FAILED")
    )
  unless (failed == 0) exitFailure
  where
    total = length checks
    failed = length [c | c <- checks, not (chkOk c)]

    report c
      | chkOk c   = putStrLn ("ok   " ++ chkName c)
      | otherwise = putStrLn ("FAIL " ++ chkName c ++ "\n       " ++ chkNote c)
