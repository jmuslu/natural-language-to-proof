-- | Run the verified CCGbank category classifier
-- ('NL2Proof.Syntax.CCGBank') over the real extracted lexicon and report the
-- representability split, weighted both by distinct (word, category) entries and
-- by corpus frequency.
--
-- This is the "measured" companion to the unit tests: the same 'classify' the
-- test suite pins on known categories is run here across the whole corpus, so
-- the aggregate numbers come out of verified code rather than a re-implementation
-- in another language.
--
-- Input is the LEX file shipped with CCGbank (LDC2005T13), one entry per line:
--
-- > word   category   count   p(cat|word)   p(word|cat)
--
-- Usage: @ccgbank-report [PATH]@  (PATH defaults to the 00-24 lexicon).
module Main (main) where

import Data.List (foldl', sortBy)
import qualified Data.Map.Strict as M
import Data.Ord (comparing, Down(..))
import System.Environment (getArgs)
import System.IO (hPutStrLn, stderr)

import NL2Proof.Syntax.CCGBank

defaultPath :: FilePath
defaultPath =
  "/home/gram/ccgbank/ccgbank_1_1/data/LEX/CCGbank.00-24.lexicon"

-- | One entry from the LEX file: word, category, corpus count. The word is
-- kept for readability of the format even though the tally only needs the
-- category and count.
data LexEntry = LexEntry String String Int

leCount :: LexEntry -> Int
leCount (LexEntry _ _ n) = n

parseLine :: String -> Maybe LexEntry
parseLine line = case words line of
  (w : c : n : _) -> case reads n of
    [(k, "")] -> Just (LexEntry w c k)
    _         -> Nothing
  _ -> Nothing

-- | The bucket a category falls into, as a stable label for tallying.
bucketLabel :: Representability -> String
bucketLabel RepresentableAsIs = "representable-as-is"
bucketLabel (NeedsFeature _)  = "needs-feature"
bucketLabel (NeedsNewAtom _)  = "needs-new-atom"
bucketLabel (Malformed _)     = "malformed"

data Tally = Tally
  { tByBucketEntries :: M.Map String Int      -- distinct (word,cat) entries per bucket
  , tByBucketTokens  :: M.Map String Int      -- corpus-frequency-weighted per bucket
  , tNewAtoms        :: M.Map String Int      -- new atom -> distinct entries needing it
  , tFeatures        :: M.Map String Int      -- feature -> distinct entries using it
  , tMalformed       :: [String]              -- up to a few malformed category strings
  , tConjNonTrailing :: Int                   -- categories with [conj] not at the end
  }

emptyTally :: Tally
emptyTally = Tally M.empty M.empty M.empty M.empty [] 0

bump :: Ord k => k -> Int -> M.Map k Int -> M.Map k Int
bump k n = M.insertWith (+) k n

step :: Tally -> LexEntry -> Tally
step t (LexEntry _ cat cnt) =
  let r     = classify cat
      lbl   = bucketLabel r
      t1    = t { tByBucketEntries = bump lbl 1   (tByBucketEntries t)
                , tByBucketTokens  = bump lbl cnt (tByBucketTokens t)
                }
      t2    = case r of
                NeedsNewAtom as -> t1 { tNewAtoms = foldr (\a -> bump a 1) (tNewAtoms t1) as }
                _               -> t1
      t3    = case parseCCGCat cat of
                Right c -> t2 { tFeatures = foldr (\(Feat f) -> bump f 1) (tFeatures t2)
                                              (featsOf c) }
                Left _  -> t2
      t4    = case r of
                Malformed _ | length (tMalformed t3) < 12 ->
                  t3 { tMalformed = cat : tMalformed t3 }
                _ -> t3
      t5    = if conjNonTrailing cat then t4 { tConjNonTrailing = tConjNonTrailing t4 + 1 } else t4
  in t5

-- | Does the category contain a @[conj]@ that is not the final feature token?
-- Validates the parser's simplifying assumption that @[conj]@ is always trailing.
conjNonTrailing :: String -> Bool
conjNonTrailing s =
  let idx = indices "[conj]" s
  in any (\i -> i + length "[conj]" /= length s) idx
  where
    indices needle hay =
      [ i | i <- [0 .. length hay - length needle]
          , take (length needle) (drop i hay) == needle ]

pct :: Int -> Int -> String
pct _ 0 = "n/a"
pct k tot =
  let tenths = round (1000 * fromIntegral k / fromIntegral tot :: Double) :: Int
  in show (fromIntegral tenths / 10 :: Double) ++ "%"

main :: IO ()
main = do
  args <- getArgs
  let path = case args of (p : _) -> p; [] -> defaultPath
  contents <- readFile path
  let entries = [ e | Just e <- map parseLine (lines contents) ]
      t       = foldl' step emptyTally entries
      totalE  = length entries
      totalT  = sum (map leCount entries)
      order   = ["representable-as-is", "needs-feature", "needs-new-atom", "malformed"]
  hPutStrLn stderr ("read " ++ show totalE ++ " entries from " ++ path)
  putStrLn "== CCGbank lexicon representability (verified classifier over real corpus) =="
  putStrLn ("source          : " ++ path)
  putStrLn ("distinct (word,category) entries : " ++ show totalE)
  putStrLn ("total corpus token occurrences    : " ++ show totalT)
  putStrLn ""
  putStrLn "bucket                 distinct-entries          corpus-tokens"
  mapM_ (\lbl ->
           let e = M.findWithDefault 0 lbl (tByBucketEntries t)
               k = M.findWithDefault 0 lbl (tByBucketTokens t)
           in putStrLn (pad 22 lbl
                        ++ pad 12 (show e) ++ pad 10 ("(" ++ pct e totalE ++ ")")
                        ++ pad 12 (show k) ++ "(" ++ pct k totalT ++ ")"))
        order
  putStrLn ""
  putStrLn "new atoms required (distinct entries needing each):"
  mapM_ (\(a, n) -> putStrLn ("  " ++ pad 8 a ++ show n))
        (sortBy (comparing (Down . snd)) (M.toList (tNewAtoms t)))
  putStrLn ""
  putStrLn "feature inventory (distinct entries using each), top 25:"
  mapM_ (\(f, n) -> putStrLn ("  " ++ pad 10 ("[" ++ f ++ "]") ++ show n))
        (take 25 (sortBy (comparing (Down . snd)) (M.toList (tFeatures t))))
  putStrLn ""
  putStrLn ("categories with a non-trailing [conj] (parser-assumption check): "
            ++ show (tConjNonTrailing t))
  putStrLn ""
  putStrLn "sample malformed category strings (if any):"
  mapM_ (\c -> putStrLn ("  " ++ c)) (tMalformed t)
  where
    pad n s = s ++ replicate (max 1 (n - length s)) ' '
