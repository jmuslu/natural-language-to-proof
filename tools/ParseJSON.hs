-- | Persistent JSONL parser process: one licensed model load, one response per
-- whitelisted request. Diagnostics go to stderr; stdout contains JSON only.
module Main (main) where

import Control.Exception (SomeException, evaluate, try)
import qualified Data.Map as M
import System.Environment (getArgs)
import System.Exit (exitFailure)
import System.IO (hFlush, hPutStrLn, isEOF, stderr, stdout)
import Text.Read (readMaybe)

import NL2Proof.Bench.Export
import NL2Proof.Bench.JSON
import NL2Proof.Pipeline
import NL2Proof.Syntax.CCGSemParse
import NL2Proof.Syntax.CCGSupertag (TagModel(..))
import NL2Proof.Syntax.Lexicon (attitudeLexicon)

data Options = Options Bool Bool Int

main :: IO ()
main = do
  args <- getArgs
  Options hand pos cap <- either die pure (options (Options False False 64) args)
  choice <- if hand then pure (HandLexicon attitudeLexicon) else do
    dir <- ccgbankDataDir
    hPutStrLn stderr "loading CCGbank parser model"
    (model,count) <- loadSemModel dir
    _ <- evaluate (M.size (tmWord (smTags model)))
    if count == 0 then die "no CCGbank training trees found" else pure ()
    hPutStrLn stderr ("parser ready: " ++ show count ++ " trees")
    pure (CCGBankParser model {smPOSBackoff=pos})
  loop choice cap
  where
    die message = hPutStrLn stderr message >> exitFailure

options :: Options -> [String] -> Either String Options
options o [] = Right o
options (Options _ pos cap) ("--hand":rest) = options (Options True pos cap) rest
options (Options hand _ cap) ("--pos-backoff":rest) = options (Options hand True cap) rest
options (Options hand pos _) ("--max-combinations":value:rest)
  | Just cap <- readMaybe value, cap >= 1, cap <= 64 = options (Options hand pos cap) rest
options _ _ = Left "usage: nl2proof-parse-json [--hand] [--pos-backoff] [--max-combinations 1..64]"

loop :: ParserChoice -> Int -> IO ()
loop choice cap = do
  eof <- isEOF
  if eof then pure () else do
    line <- getLine
    let response = either errorJSON id (parseJSON line >>= exportRequest choice cap)
        rendered = renderJSON response
    forced <- try (evaluate (length rendered)) :: IO (Either SomeException Int)
    case forced of
      Left err -> putStrLn (renderJSON (errorJSON (show err)))
      Right _ -> putStrLn rendered
    hFlush stdout
    loop choice cap

errorJSON :: String -> JValue
errorJSON message = JObj [("schema",JNum 1),("error",JStr message)]
