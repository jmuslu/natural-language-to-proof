-- | Read a checked receipt snapshot, offer named run propositions, emit JSON.
-- runghc -isrc tools/ExternalOracle.hs RECEIPTS.tsv RUN_ID...
module Main (main) where

import Control.Exception (IOException, evaluate, try)
import System.Environment (getArgs)
import System.Exit (die)
import System.IO (IOMode(ReadMode), hGetContents, hSetEncoding, utf8, withFile)

import NL2Proof.Verify.External

main :: IO ()
main = do
  args <- getArgs
  case args of
    path : runIds -> do
      result <- try (withFile path ReadMode $ \handle -> do
        hSetEncoding handle utf8
        input <- hGetContents handle
        _ <- evaluate (length input)
        pure input) :: IO (Either IOException String)
      case result of
        Left _ -> die "external-oracle: cannot read receipt snapshot"
        Right input -> case parseReceipts input >>= (\book -> evaluateReceipts book runIds) of
          Left why -> die ("external-oracle: " ++ why)
          Right ev -> putStrLn (renderEvaluation ev)
    _ -> die "usage: external-oracle RECEIPTS.tsv [RUN_ID ...]"
