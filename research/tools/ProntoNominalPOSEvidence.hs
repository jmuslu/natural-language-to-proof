{-# LANGUAGE BangPatterns #-}
-- Adapted from the bounded NominalNameEvidence extractor; exact parseAuto
-- accepted-line/leafHeaders/leafPairs and training partition contract retained.
-- Bounded training-file evidence audit. No SemModel is built and no sentences
-- are parsed. parseAuto reads one annotated tree at a time, exactly as loader.
module Main (main) where

import Control.Exception (IOException, try)
import Control.Monad (foldM, unless)
import Data.List (foldl')
import qualified Data.Map.Strict as M
import qualified Data.Set as S
import System.Directory (doesFileExist)
import System.Environment (getArgs)
import System.Exit (die)
import System.IO
import System.Process (readProcess)
import NL2Proof.Bench.JSON
import NL2Proof.Syntax.CCGDeriv (parseAuto, leafHeaders)
import NL2Proof.Syntax.CCGSupertag (leafPairs)
import NL2Proof.Syntax.CCGSemParse (ccgbankTrainFiles)

type Counts = M.Map String (M.Map String Int)
data Acc = Acc { pos :: !Counts, tags :: !Counts, accepted :: !Int,
                 rejected :: !Int, skipped :: !Int } deriving (Eq, Show)
empty :: Acc
empty = Acc M.empty M.empty 0 0 0
bump :: S.Set String -> Counts -> (String,String) -> Counts
bump wanted m (w,v)
  | S.member w wanted = M.insertWith (M.unionWith (+)) w (M.singleton v 1) m
  | otherwise = m

addLine :: S.Set String -> Acc -> String -> Acc
addLine wanted a line
  | null line || take 3 line == "ID=" = a { skipped = skipped a + 1 }
  | otherwise = case parseAuto line of
      Left _ -> a { rejected = rejected a + 1 }
      Right tree -> Acc
        (foldl' (bump wanted) (pos a) [(w,p) | (_,p,w) <- leafHeaders line])
        (foldl' (bump wanted) (tags a) [(w,show c) | (w,c) <- leafPairs tree])
        (accepted a + 1) (rejected a) (skipped a)

counts :: Counts -> String -> M.Map String Int
counts m w = M.findWithDefault M.empty w m

num :: Int -> JValue
num = JNum . fromIntegral
countJSON :: M.Map String Int -> JValue
countJSON = JObj . map (\(k,n) -> (k,num n)) . M.toAscList
summary :: S.Set String -> Acc -> JValue
summary wanted a = JObj
  [("schema",num 1),("interior_tokens",JBool True)
  ,("accepted_trees",num (accepted a)),("rejected_lines",num (rejected a)),("skipped_lines",num (skipped a))
  ,("keys",JArr [JObj [("form",JStr w),("pos",countJSON (counts (pos a) w))
       ,("categories",countJSON (counts (tags a) w))] | w <- S.toAscList wanted])
  ,("scope",JStr "Bounded exact-key counts from parseAuto-accepted training lines; not offered categories, a trained model, a parse or a fidelity measurement.")]

-- Keep only requested-key aggregates, never raw tree lines or a full lexicon.
scanHandle :: S.Set String -> Handle -> Acc -> IO Acc
scanHandle wanted h !a = do
  eof <- hIsEOF h
  if eof then pure a else do
    line <- hGetLine h
    let !next = addLine wanted a line
    scanHandle wanted h next

scanFile :: S.Set String -> Handle -> (Acc,Int,Int,Int) -> FilePath -> IO (Acc,Int,Int,Int)
scanFile wanted manifest (a,readN,missingN,errorN) path = do
  exists <- doesFileExist path
  if not exists then do
    hPutStrLn manifest (renderJSON (JObj [("path",JStr path),("status",JStr "missing")]))
    pure (a,readN,missingN+1,errorN)
  else do
    result <- try (do
      before <- takeWhile (/= ' ') <$> readProcess "sha256sum" [path] ""
      next <- withFile path ReadMode (\h -> scanHandle wanted h a)
      after <- takeWhile (/= ' ') <$> readProcess "sha256sum" [path] ""
      unless (before == after) (ioError (userError "input changed while scanning"))
      pure (next,before)) :: IO (Either IOException (Acc,String))
    case result of
      Left _ -> do
        hPutStrLn manifest (renderJSON (JObj [("path",JStr path),("status",JStr "unreadable_or_changed")]))
        pure (a,readN,missingN,errorN+1)
      Right (next,digest) -> do
        hPutStrLn manifest (renderJSON (JObj [("path",JStr path),("status",JStr "read"),("sha256",JStr digest)]))
        pure (next,readN+1,missingN,errorN)

selfTest :: IO ()
selfTest = do
  let wanted = S.fromList ["Ari","ari"]
      leaf c p w = "(<L " ++ c ++ " " ++ p ++ " " ++ p ++ " " ++ w ++ " " ++ c ++ ">)"
      good = leaf "N" "NNP" "Ari"
      bad = "(<T S 0 1> " ++ good -- valid leaf header inside unclosed tree
      a = foldl' (addLine wanted) empty ["", "ID=1",good,good,bad,leaf "N" "NN" "Other"]
      trailing = good ++ " " ++ leaf "N" "JJ" "ari"
      b = addLine wanted empty trailing
      checks =
        [("counts repeated accepted target", counts (pos a) "Ari" == M.singleton "NNP" 2)
        ,("invalid tree contributes neither POS nor tags", rejected a == 1 && counts (tags a) "Ari" == M.singleton "N" 2)
        ,("ID and blank skipped", skipped a == 2 && accepted a == 3)
        ,("non-target omitted", M.notMember "Other" (pos a))
        ,("exact loader trailing-token POS behavior", counts (pos b) "ari" == M.singleton "JJ" 1)
        ,("exact loader trailing-token tag behavior", M.notMember "ari" (tags b))]
  mapM_ (\(label,ok) -> putStrLn ((if ok then "PASS " else "FAIL ") ++ label)) checks
  unless (all snd checks) (die "self-test failed")
  putStrLn (show (length checks) ++ " synthetic checks passed")

main :: IO ()
main = do
  args <- getArgs
  case args of
    ["--self-test"] -> selfTest
    [dir,keyPath,manifestPath] -> do
      requested <- lines <$> readFile keyPath
      unless (not (null requested) && all (\w -> not (null w) && all (\c -> c /= ' ' && c /= '\t' && c /= '\r') w) requested)
        (die "expected nonempty exact keys, one per line")
      let wanted = S.fromList requested
      (a,readN,missingN,errorN) <- withFile manifestPath WriteMode $ \manifest ->
        foldM (scanFile wanted manifest) (empty,0,0,0) (ccgbankTrainFiles dir)
      putStrLn (renderJSON (JObj [("files_read",num readN),("files_missing",num missingN)
        ,("files_unreadable_or_changed",num errorN),("evidence",summary wanted a)]))
    _ -> die "usage: runghc -isrc research/tools/ProntoNominalPOSEvidence.hs --self-test | DATA_DIR KEYS_TXT MANIFEST_JSONL"
