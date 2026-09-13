-- | Ingest the real CCGbank lexicon into provenance-tagged entries and report the
-- split, weighted by distinct (word, category) pairs and by corpus frequency.
--
-- The "measured" companion to the CCGLexicon unit tests: the same `ingest` the
-- tests pin on known categories is run across the whole extracted lexicon, so the
-- numbers come from verified code. Crucially it also asserts the load-bearing (if
-- weak) property on real data: every Built entry's synthesised skeleton clears
-- `skeletonWellTyped` -- i.e. the synthesiser produces a well-typed meaning for
-- every representable corpus category. A non-zero "ill-typed" count would be a
-- real bug in the synthesiser.
--
-- Usage: @ccg-lexicon-ingest [--json] [PATH]@ (defaults to the 00-24 lexicon).
-- With @--json@ it emits a machine-readable artifact (the same measured numbers)
-- so downstream stages consume a real handoff rather than scraping the report.
module Main (main) where

import Data.List (foldl', intercalate, sortBy)
import qualified Data.Map.Strict as M
import Data.Ord (comparing, Down(..))
import System.Environment (getArgs)
import System.IO (hPutStrLn, stderr)

import NL2Proof.Syntax.CCGLexicon

defaultPath :: FilePath
defaultPath = "/home/gram/ccgbank/ccgbank_1_1/data/LEX/CCGbank.00-24.lexicon"

data Acc = Acc
  { aBuilt :: !Int,  aBuiltTok :: !Int
  , aRule  :: !Int,  aRuleTok  :: !Int  -- handled by a combinatory rule (coordination)
  , aUnrep :: !Int,  aUnrepTok :: !Int
  , aBad   :: !Int,  aBadTok   :: !Int
  , aIllTyped :: !Int              -- Built entries whose skeleton fails typeOf (should be 0)
  , aNewAtoms :: M.Map String Int  -- unrepresentable atoms -> distinct entries needing them
  }

emptyAcc :: Acc
emptyAcc = Acc 0 0 0 0 0 0 0 0 0 M.empty

step :: Acc -> (String, String, Int) -> Acc
step acc (word, cat, cnt) = case ingest "CCGbank" word cat of
  Built pe ->
    acc { aBuilt = aBuilt acc + 1, aBuiltTok = aBuiltTok acc + cnt
        , aIllTyped = aIllTyped acc + (if skeletonWellTyped pe then 0 else 1) }
  RuleHandled _ ->
    acc { aRule = aRule acc + 1, aRuleTok = aRuleTok acc + cnt }
  Unrepresentable atoms ->
    acc { aUnrep = aUnrep acc + 1, aUnrepTok = aUnrepTok acc + cnt
        , aNewAtoms = foldr (\a -> M.insertWith (+) a 1) (aNewAtoms acc) atoms }
  Unparseable _ ->
    acc { aBad = aBad acc + 1, aBadTok = aBadTok acc + cnt }

parseLine :: String -> Maybe (String, String, Int)
parseLine line = case words line of
  (w : c : n : _) -> case reads n of [(k, "")] -> Just (w, c, k); _ -> Nothing
  _ -> Nothing

pct :: Int -> Int -> String
pct _ 0 = "n/a"
pct k tot = let t = round (1000 * fromIntegral k / fromIntegral tot :: Double) :: Int
            in show (fromIntegral t / 10 :: Double) ++ "%"

-- | Minimal JSON string escaper (atom keys include ':' ',' '"').
jstr :: String -> String
jstr s = '"' : concatMap esc s ++ "\""
  where esc '"' = "\\\""; esc '\\' = "\\\\"; esc c = [c]

jsonReport :: FilePath -> Int -> Int -> Acc -> String
jsonReport path nT tokT a = "{\n"
  ++ f "source" (jstr path) ++ ",\n"
  ++ f "distinct_entries" (show nT) ++ ",\n"
  ++ f "token_occurrences" (show tokT) ++ ",\n"
  ++ f "built" (show (aBuilt a)) ++ ",\n"
  ++ f "built_pct_types" (pctNum (aBuilt a) nT) ++ ",\n"
  ++ f "built_pct_tokens" (pctNum (aBuiltTok a) tokT) ++ ",\n"
  ++ f "rule_handled" (show (aRule a)) ++ ",\n"
  ++ f "rule_handled_pct_types" (pctNum (aRule a) nT) ++ ",\n"
  ++ f "unrepresentable" (show (aUnrep a)) ++ ",\n"
  ++ f "unparseable" (show (aBad a)) ++ ",\n"
  ++ f "ill_typed" (show (aIllTyped a)) ++ ",\n"
  ++ "  \"atoms_blocking\": {" ++ atoms ++ "}\n}"
  where
    f k v = "  " ++ jstr k ++ ": " ++ v
    atoms = intercalate ", "
      [ jstr at ++ ": " ++ show n
      | (at, n) <- sortBy (comparing (Down . snd)) (M.toList (aNewAtoms a)) ]
    pctNum _ 0 = "null"
    pctNum k tot = let t = round (1000 * fromIntegral k / fromIntegral tot :: Double) :: Int
                   in show (fromIntegral t / 10 :: Double)

main :: IO ()
main = do
  args <- getArgs
  let jsonMode = "--json" `elem` args
      path = case filter (/= "--json") args of (p : _) -> p; [] -> defaultPath
  contents <- readFile path
  let entries = [e | Just e <- map parseLine (lines contents)]
      a = foldl' step emptyAcc entries
      nT = length entries
      tokT = sum [c | (_, _, c) <- entries]
  hPutStrLn stderr ("ingested " ++ show nT ++ " lexicon entries from " ++ path)
  if jsonMode then putStrLn (jsonReport path nT tokT a) else humanReport path nT tokT a

humanReport :: FilePath -> Int -> Int -> Acc -> IO ()
humanReport _path nT tokT a = do
  putStrLn "== CCGbank lexicon ingestion (provenance-tagged entries, verified skeletons) =="
  putStrLn ("distinct (word,category) entries : " ++ show nT)
  putStrLn ("total corpus token occurrences    : " ++ show tokT)
  putStrLn ""
  putStrLn ("built (representable, corpus-attested) : " ++ show (aBuilt a)
            ++ " (" ++ pct (aBuilt a) nT ++ " types, " ++ pct (aBuiltTok a) tokT ++ " tokens)")
  putStrLn ("rule-handled (coordination, not lexical): " ++ show (aRule a)
            ++ " (" ++ pct (aRule a) nT ++ " types, " ++ pct (aRuleTok a) tokT ++ " tokens)")
  putStrLn ("unrepresentable (conj-fn/punct atoms)   : " ++ show (aUnrep a)
            ++ " (" ++ pct (aUnrep a) nT ++ " types, " ++ pct (aUnrepTok a) tokT ++ " tokens)")
  putStrLn ("unparseable                             : " ++ show (aBad a)
            ++ " (" ++ pct (aBad a) nT ++ " types)")
  putStrLn ""
  putStrLn ("Built entries with an ill-typed skeleton (MUST be 0): " ++ show (aIllTyped a))
  putStrLn ""
  putStrLn "atoms blocking representability (distinct entries needing each):"
  mapM_ (\(at, n) -> putStrLn ("  " ++ pad 8 at ++ show n))
        (sortBy (comparing (Down . snd)) (M.toList (aNewAtoms a)))
  where
    pad n s = s ++ replicate (max 1 (n - length s)) ' '
