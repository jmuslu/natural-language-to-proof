-- | A frequency (unigram) supertagger: assign each word its candidate CCG
-- categories, so the chart parser can run from raw words rather than gold supertags.
--
-- This is the standard lexical baseline for CCG supertagging, made honest about what
-- it is: for each word it offers the categories that word was attested with in
-- training, most-frequent first; for an out-of-vocabulary word it backs off to the
-- global category prior. It is deterministic and corpus-attested (no learned
-- weights, no features beyond the word), which is a real model and the right first
-- rung — not a neural supertagger, and labelled as such. Trained on the /train/
-- split only, so measuring parse coverage on held-out sentences is leakage-free.
--
-- The number that bounds everything downstream is __oracle inclusion__: if the gold
-- category is not among a word's top-k offered tags, no parse can recover it. The
-- tool reports it alongside parse coverage so the two are never conflated.
module NL2Proof.Syntax.CCGSupertag
  ( TagModel(..)
  , leafPairs
  , buildTagModel
  , supertag
  , supertagScored
  , scoreCounts
  , isOOV
    -- * Part-of-speech tag dictionary
  , POSModel(..)
  , buildPOSModel
  , posCounts
  , oracleIncluded
  ) where

import qualified Data.Map.Strict as M
import Data.List (sortBy)
import Data.Ord (comparing, Down(..))

import NL2Proof.Syntax.CCGBank (CCat, parseCCGCat)
import NL2Proof.Syntax.CCGDeriv (AutoNode(..))

data TagModel = TagModel
  { tmWord  :: M.Map String [(CCat, Int)]  -- ^ per-word categories, desc by count
  , tmPrior :: [(CCat, Int)]               -- ^ global category prior, desc by count
  }

-- | (word, category) pairs from a gold tree's leaves; skips leaves whose category
-- string does not parse (so the model is never seeded with a malformed category).
leafPairs :: AutoNode -> [(String, CCat)]
leafPairs (AutoLeaf c w) = either (const []) (\cc -> [(w, cc)]) (parseCCGCat c)
leafPairs (AutoTree _ ks) = concatMap leafPairs ks

-- | Build the model from training (word, category) observations.
buildTagModel :: [(String, CCat)] -> TagModel
buildTagModel pairs = TagModel wordTab priorTab
  where
    wordCounts =
      foldr (\(w, c) -> M.insertWith (M.unionWith (+)) w (M.singleton c 1)) M.empty pairs
    wordTab  = M.map (sortBy (comparing (Down . snd)) . M.toList) wordCounts
    globalCounts = foldr (\(_, c) -> M.insertWith (+) c 1) M.empty pairs
    priorTab = sortBy (comparing (Down . snd)) (M.toList globalCounts)

-- | Top-k candidate categories for a word; unigram backoff to the global prior for
-- an out-of-vocabulary word.
supertag :: TagModel -> Int -> String -> [CCat]
supertag tm k w = case M.lookup w (tmWord tm) of
  Just cs -> take k (map fst cs)
  Nothing -> take k (map fst (tmPrior tm))

-- | Adaptive-beam supertags with scores: keep the categories whose count is within
-- a factor @beta@ of the word's most frequent category (the standard CCG β-beam --
-- fewer tags for confident words, more for ambiguous ones), capped at @kmax@, each
-- paired with its log-probability @log(count / word_total)@. OOV backs off to the
-- global prior. Scores let the chart run a Viterbi beam over derivations instead of
-- an arbitrary cap.
supertagScored :: TagModel -> Double -> Int -> String -> [(CCat, Double)]
supertagScored tm beta kmax w =
  scoreCounts beta kmax (M.findWithDefault (tmPrior tm) w (tmWord tm))

-- | The β-beam and log-probability scoring of 'supertagScored', over an explicit
-- count list (sorted descending by count). Exposed so a caller that merges two
-- count lists (e.g. a sentence-initial word with its lower-cased form) scores
-- them by exactly the same rule.
scoreCounts :: Double -> Int -> [(CCat, Int)] -> [(CCat, Double)]
scoreCounts beta kmax cs0 =
  let cs = sortBy (comparing (Down . snd)) cs0
  in case cs of
    [] -> []
    ((_, mx) : _) ->
      let total  = fromIntegral (sum (map snd cs)) :: Double
          thresh = beta * fromIntegral mx
      in take kmax [ (c, log (fromIntegral n / total))
                   | (c, n) <- cs, fromIntegral n >= thresh, total > 0 ]

isOOV :: TagModel -> String -> Bool
isOOV tm w = not (M.member w (tmWord tm))

-- | Was the gold category offered among the word's top-k tags? (Exact category
-- match: gold and lexicon categories come from the same CCGbank vocabulary.)
oracleIncluded :: TagModel -> Int -> String -> CCat -> Bool
oracleIncluded tm k w gold = gold `elem` supertag tm k w

--------------------------------------------------------------------------------
-- Part-of-speech tag dictionary
--------------------------------------------------------------------------------

-- | Per-word POS counts from CCGbank leaves (the gold Penn POS field). Used for
-- one thing only: deciding whether a word is a proper name (NNP\/NNPS), which the
-- category alone cannot tell (CCGbank tags a lone name @N@ and a bare plural @N@
-- alike, and only the POS distinguishes the @N -> NP@ name reading).
newtype POSModel = POSModel (M.Map String (M.Map String Int))

buildPOSModel :: [(String, String)] -> POSModel
buildPOSModel pairs =
  POSModel (foldr (\(w, p) -> M.insertWith (M.unionWith (+)) w (M.singleton p 1)) M.empty pairs)

-- | A word's POS counts, most frequent first; empty if the word is unseen.
posCounts :: POSModel -> String -> [(String, Int)]
posCounts (POSModel m) w =
  sortBy (comparing (Down . snd)) (M.toList (M.findWithDefault M.empty w m))
