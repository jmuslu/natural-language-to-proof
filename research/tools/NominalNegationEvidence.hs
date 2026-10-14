{-# LANGUAGE BangPatterns #-}
-- Bounded training-file evidence audit. No SemModel is built and no sentences
-- are parsed. parseAuto reads one annotated tree at a time, exactly as loader.
module Main (main) where

import Control.Exception (IOException, try)
import Control.Monad (foldM, unless)
import Data.Char (toLower)
import Data.List (foldl')
import qualified Data.Map.Strict as M
import qualified Data.Set as S
import System.Directory (doesFileExist)
import System.Environment (getArgs)
import System.Exit (die)
import System.IO
import System.Process (readProcess)
import NL2Proof.Bench.JSON
import NL2Proof.Syntax.CCGDeriv (AutoNode(..), nodeCat, parseAuto, leafHeaders)
import NL2Proof.Syntax.CCGBank (parseCCGCat, eraseFeatures)
import NL2Proof.Syntax.CCGSupertag (leafPairs)
import NL2Proof.Syntax.CCGSemParse (ccgbankTrainFiles)

type Counts = M.Map String (M.Map String Int)
data Acc = Acc { pos :: !Counts, tags :: !Counts, accepted :: !Int,
                 rejected :: !Int, skipped :: !Int, pairs :: !(M.Map (String,String) Int) } deriving (Eq, Show)
empty :: Acc
empty = Acc M.empty M.empty 0 0 0 M.empty
names :: [String]
names = ["Dave","Colin","Nora","Sam","Polly","Adalynn","Bodhi"]
nouns :: [String]
nouns = ["ostrich","bird","dancer","rompus","dumpus","libertarian","environmentalist"]
keys :: S.Set String
keys = S.fromList (names ++ map (map toLower) names ++ nouns ++ ["is","not","a","an"])

-- Exactly the loader's binaryPairs traversal and feature erasure, retaining
-- only four preregistered source pairs. Counts are diagnostic; smSeen uses set
-- membership. Parent category/semantic validity is not checked by that loader.
sourcePairs :: [(String,String)]
sourcePairs = map (\(a,b)->(erased a,erased b))
  [("(S[dcl]\\NP)/NP","(S\\NP)\\(S\\NP)")
  ,("NP[nb]/N","N"),("(S[dcl]\\NP)/NP","NP[nb]"),("NP","S[dcl]\\NP")]
erased :: String -> String
erased = either error (show . eraseFeatures) . parseCCGCat
binaryPairs :: AutoNode -> [(String,String)]
binaryPairs (AutoLeaf _ _) = []
binaryPairs (AutoTree _ kids) = here ++ concatMap binaryPairs kids
 where
  here=case kids of
   [a,b] | Right ca<-parseCCGCat(nodeCat a), Right cb<-parseCCGCat(nodeCat b)
     -> [(show(eraseFeatures ca),show(eraseFeatures cb))]
   _ -> []
addPair :: M.Map (String,String) Int -> (String,String) -> M.Map (String,String) Int
addPair m p | p `elem` sourcePairs = M.insertWith (+) p 1 m
            | otherwise = m

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
        (foldl' addPair (pairs a) (binaryPairs tree))

-- Match lookupForm exactly: tag membership, not POS membership, triggers it.
effective :: Bool -> Bool -> Counts -> String -> String
effective truecase initial ts w
  | truecase && initial && lw /= w && M.member lw ts = lw
  | otherwise = w
  where lw = map toLower w

counts :: Counts -> String -> M.Map String Int
counts m w = M.findWithDefault M.empty w m
nnponly :: M.Map String Int -> Bool
nnponly cs = not (M.null cs) && all (\(p,n) -> p == "NNP" && n > 0) (M.toList cs)
eligible :: Bool -> Bool -> Acc -> String -> Bool
eligible tc initial a w = nnponly (counts (pos a) w)
  && nnponly (counts (pos a) (effective tc initial (tags a) w))
  && all (\(p,n) -> p == "NNP" && n > 0) (M.toList (counts (pos a) (map toLower w)))

num :: Int -> JValue
num = JNum . fromIntegral
countJSON :: M.Map String Int -> JValue
countJSON = JObj . map (\(k,n) -> (k,num n)) . M.toAscList
summary :: Acc -> JValue
summary a = JObj
  [("schema",num 1),("audited_truecase",JBool True),("subject_initial",JBool True)
  ,("accepted_trees",num (accepted a)),("rejected_lines",num (rejected a)),("skipped_lines",num (skipped a))
  ,("keys",JArr [JObj [("form",JStr w),("pos",countJSON (counts (pos a) w))
       ,("categories",countJSON (counts (tags a) w)),("tag_member",JBool (M.member w (tags a)))] | w <- S.toAscList keys])
  ,("dictionary_conditions",JArr [JObj [("written",JStr w)
       ,("effective",JStr (effective True True (tags a) w))
       ,("c77ad00_dictionary_pass_on_observed_inputs",JBool (eligible True True a w))] | w <- names])
  ,("source_pairs",JArr [JObj [("left",JStr l),("right",JStr r)
      ,("count",num(M.findWithDefault 0 (l,r) (pairs a)))] | (l,r)<-sourcePairs])
  ,("noun_dictionary_conditions",JArr [JObj [("form",JStr w)
      ,("known_noun_POS_gate",JBool (any (`M.member` counts (pos a) w) ["NN","NNS"]
        && not(any (`M.member` counts (pos a) w) ["JJ","JJR","JJS","NNP","NNPS"])))
      ,("no_observed_POS",JBool(M.null(counts (pos a) w)))]|w<-nouns])
  ,("scope",JStr "Dictionary evidence only. Missing/unreadable inputs prevent a definitive complete-corpus absence or unopposed claim; actual lexical origin and full clause eligibility not established.")]

-- Keep only preregistered-key and four source-pair aggregates, never raw tree lines or a complete lexicon.
scanHandle :: Handle -> Acc -> IO Acc
scanHandle h !a = do
  eof <- hIsEOF h
  if eof then pure a else do
    line <- hGetLine h
    let !next = addLine keys a line
    scanHandle h next

scanFile :: Handle -> (Acc,Int,Int,Int) -> FilePath -> IO (Acc,Int,Int,Int)
scanFile manifest (a,readN,missingN,errorN) path = do
  exists <- doesFileExist path
  if not exists then do
    hPutStrLn manifest (renderJSON (JObj [("path",JStr path),("status",JStr "missing")]))
    pure (a,readN,missingN+1,errorN)
  else do
    result <- try (do
      before <- takeWhile (/= ' ') <$> readProcess "sha256sum" [path] ""
      next <- withFile path ReadMode (\h -> scanHandle h a)
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
      lower = addLine wanted a (leaf "N" "NN" "ari")
      pairTree = "(<T S[dcl] 0 2> " ++ leaf "NP[nb]/N" "DT" "an" ++ " " ++ leaf "N" "NN" "animal" ++ ")"
      pa = addLine wanted empty pairTree
      pairKey=(erased "NP[nb]/N",erased "N")
      pairBad=addLine wanted empty (init pairTree)
      nested=AutoTree "S" [AutoTree "NP" [AutoLeaf "NP[nb]/N" "a",AutoLeaf "N" "bird"],AutoLeaf "S[dcl]\\NP" "runs"]
      checks =
        [("accepted original tree contributes source pair",M.lookup pairKey (pairs pa)==Just 1)
        ,("invalid tree contributes no pair",M.null(pairs pairBad))
        ,("pair erases features like loader",pairKey==("NP/N","N"))
        ,("nested and root binary pairs retained",length(binaryPairs nested)==2)
        ,("unrequested pairs never retained",M.null(addPair M.empty ("N","N")))
        ,("counts repeated accepted names", counts (pos a) "Ari" == M.singleton "NNP" 2)
        ,("invalid tree contributes neither POS nor tags", rejected a == 1 && counts (tags a) "Ari" == M.singleton "N" 2)
        ,("ID and blank skipped", skipped a == 2 && accepted a == 3)
        ,("non-target omitted", M.notMember "Other" (pos a))
        ,("exact loader trailing-token POS behavior", counts (pos b) "ari" == M.singleton "JJ" 1)
        ,("exact loader trailing-token tag behavior", M.notMember "ari" (tags b))
        ,("positive NNP-only", eligible True True a "Ari")
        ,("truecase uses lowercase tags", effective True True (tags lower) "Ari" == "ari")
        ,("noninitial keeps written", effective True False (tags lower) "Ari" == "Ari")
        ,("truecase off keeps written", effective False True (tags lower) "Ari" == "Ari")
        ,("POS alone does not trigger truecase", effective True True (tags b) "Ari" == "Ari")
        ,("lowercase contrary evidence blocks", not (eligible False True lower "Ari"))
        ,("empty evidence not NNP-only", not (nnponly M.empty))
        ,("rare contrary POS blocks", not (nnponly (M.fromList [("NNP",100),("JJ",1)])))
        ,("zero count rejected", not (nnponly (M.singleton "NNP" 0)))
        ,("NNPS deferred", not (nnponly (M.singleton "NNPS" 2)))]
  mapM_ (\(label,ok) -> putStrLn ((if ok then "PASS " else "FAIL ") ++ label)) checks
  unless (all snd checks) (die "self-test failed")
  putStrLn (show (length checks) ++ " synthetic checks passed")

main :: IO ()
main = do
  args <- getArgs
  case args of
    ["--self-test"] -> selfTest
    [dir,manifestPath] -> do
      (a,readN,missingN,errorN) <- withFile manifestPath WriteMode $ \manifest ->
        foldM (scanFile manifest) (empty,0,0,0) (ccgbankTrainFiles dir)
      putStrLn (renderJSON (JObj [("files_read",num readN),("files_missing",num missingN)
        ,("files_unreadable_or_changed",num errorN),("evidence",summary a)]))
    _ -> die "usage: runghc -isrc research/tools/NominalNegationEvidence.hs --self-test | DATA_DIR MANIFEST_JSONL"
