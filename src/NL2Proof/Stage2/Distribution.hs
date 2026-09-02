-- | Finite probability distributions over candidate readings.
--
-- The foundation of Stage 2. Everything probabilistic in this stage is a `Dist`
-- over Stage 1 objects, which keeps the probabilistic layer strictly /on top of/
-- the discrete core rather than mixed into it.
--
-- Deliberately a list of pairs rather than a `Map`: order is preserved so that
-- rendering is stable and ties break deterministically by original position.
-- Duplicate keys are merged on construction, so a `Dist` is always in normal
-- form.
--
-- __On floating point.__ Weights are `Double`, so normalization is approximate.
-- 'isNormalized' exists so tests can assert closeness rather than equality, and
-- nothing in this module branches on exact equality of probabilities.
module NL2Proof.Stage2.Distribution
  ( -- * Construction
    Dist
  , fromWeights
  , uniform
  , certain
  , softmax
    -- * Inspection
  , toPairs
  , toMap
  , support
  , prob
  , total
  , isNormalized
  , argmax
  , ranked
  , entropy
    -- * Transformation
  , mapDist
  , filterDist
  , reweight
  , marginalize
    -- * Rendering
  , renderDist
  ) where

import Data.List (sortOn)
import qualified Data.Map.Strict as M

--------------------------------------------------------------------------------
-- Construction
--------------------------------------------------------------------------------

-- | A normalized distribution: weights sum to 1 (up to floating error), no
-- duplicate keys, no zero-or-negative weights.
newtype Dist a = Dist [(a, Double)]
  deriving (Eq, Show)

-- | Build from arbitrary non-negative weights.
--
-- Merges duplicate keys, drops non-positive weights, then normalizes. Returns
-- 'Nothing' when nothing survives — an empty distribution is not a
-- distribution, and making that a 'Maybe' rather than an empty list stops
-- downstream code from silently dividing by zero.
fromWeights :: Ord a => [(a, Double)] -> Maybe (Dist a)
fromWeights ws
  | null kept || s <= 0 = Nothing
  | otherwise           = Just (Dist [(k, w / s) | (k, w) <- kept])
  where
    usable = [(k, w) | (k, w) <- ws, w > 0, not (isNaN w)]
    summed = M.fromListWith (+) usable

    -- Walk the caller's keys in first-appearance order and pick up each merged
    -- weight once, so the result is ordered by the caller's candidate order
    -- rather than by the Map's key order. Rendering and tie-breaking both
    -- depend on that.
    kept = go M.empty (map fst usable)
      where
        go _ [] = []
        go seen (k : ks)
          | k `M.member` seen = go seen ks
          | otherwise =
              case M.lookup k summed of
                Just w  -> (k, w) : go (M.insert k () seen) ks
                Nothing -> go (M.insert k () seen) ks

    s = sum (map snd kept)

-- | Equal probability over the given candidates.
uniform :: Ord a => [a] -> Maybe (Dist a)
uniform xs = fromWeights [(x, 1) | x <- xs]

-- | All mass on one candidate.
certain :: a -> Dist a
certain x = Dist [(x, 1)]

-- | Boltzmann / softmax over scores, with inverse temperature @alpha@.
--
-- @alpha = 0@ gives the uniform distribution; larger @alpha@ sharpens toward the
-- top-scoring candidate. This is the standard RSA speaker form, and it is here
-- rather than in "NL2Proof.Stage2.RSA" because scoring-then-normalizing is
-- generic.
--
-- Scores are shifted by their maximum before exponentiating, which changes
-- nothing mathematically and avoids overflow on large scores.
softmax :: Ord a => Double -> [(a, Double)] -> Maybe (Dist a)
softmax alpha scored
  | null scored = Nothing
  | otherwise   = fromWeights [(k, exp (alpha * (v - hi))) | (k, v) <- scored]
  where
    hi = maximum (map snd scored)

--------------------------------------------------------------------------------
-- Inspection
--------------------------------------------------------------------------------

toPairs :: Dist a -> [(a, Double)]
toPairs (Dist ps) = ps

support :: Dist a -> [a]
support = map fst . toPairs

prob :: Eq a => Dist a -> a -> Double
prob d x = sum [p | (k, p) <- toPairs d, k == x]

-- | Map view, for @O(log n)@ lookup instead of 'prob''s linear scan.
--
-- Needed in practice, not hypothetically: RSA's recursion queries the
-- lower-level listener once per (utterance, meaning) pair, so a linear 'prob'
-- makes the depth-1 listener @O(|M|^2 |U|)@ in list steps. With 256 models that
-- was slow enough to matter.
toMap :: Ord a => Dist a -> M.Map a Double
toMap = M.fromList . toPairs

total :: Dist a -> Double
total = sum . map snd . toPairs

-- | Within @1e-9@ of summing to 1.
isNormalized :: Dist a -> Bool
isNormalized d = abs (total d - 1) < 1e-9

-- | Highest-probability candidate. Ties break toward the earlier candidate,
-- which is why insertion order is preserved.
argmax :: Dist a -> Maybe a
argmax d = case ranked d of
  ((x, _) : _) -> Just x
  []           -> Nothing

-- | Candidates by descending probability, ties by original position.
ranked :: Dist a -> [(a, Double)]
ranked d = map snd (sortOn key (zip [0 :: Int ..] (toPairs d)))
  where
    key (i, (_, p)) = (negate p, i)

-- | Shannon entropy in bits. @0@ for a point mass, @log2 n@ for uniform over
-- @n@. Used to measure whether a pragmatic layer actually sharpened anything.
entropy :: Dist a -> Double
entropy d = negate (sum [p * logBase 2 p | (_, p) <- toPairs d, p > 0])

--------------------------------------------------------------------------------
-- Transformation
--------------------------------------------------------------------------------

-- | Push forward along a function, summing the mass of collisions.
--
-- This is the operation that makes "two readings that agree on the thing we care
-- about" combine, and it is how a distribution over readings becomes a
-- distribution over, say, canonical forms.
mapDist :: Ord b => (a -> b) -> Dist a -> Dist b
mapDist f d =
  case fromWeights [(f k, p) | (k, p) <- toPairs d] of
    Just d' -> d'
    -- Unreachable: the input is normalized, so at least one weight is positive.
    Nothing -> Dist []

-- | Condition on a predicate and renormalize. 'Nothing' when nothing survives.
filterDist :: Ord a => (a -> Bool) -> Dist a -> Maybe (Dist a)
filterDist f d = fromWeights [(k, p) | (k, p) <- toPairs d, f k]

-- | Multiply by a weighting function and renormalize — a Bayesian update where
-- the function is a likelihood.
reweight :: Ord a => (a -> Double) -> Dist a -> Maybe (Dist a)
reweight f d = fromWeights [(k, p * f k) | (k, p) <- toPairs d]

-- | Total mass assigned to candidates satisfying a predicate.
marginalize :: (a -> Bool) -> Dist a -> Double
marginalize f d = sum [p | (k, p) <- toPairs d, f k]

--------------------------------------------------------------------------------
-- Rendering
--------------------------------------------------------------------------------

-- | Descending by probability, three decimal places.
renderDist :: (a -> String) -> Dist a -> String
renderDist showIt d =
  unlines
    [ "  " ++ pct p ++ "  " ++ showIt k | (k, p) <- ranked d ]
  where
    pct p =
      let n = round (p * 1000) :: Int
          (whole, frac) = n `divMod` 10
      in pad 3 (show whole) ++ "." ++ show frac ++ "%"
    pad n str = replicate (n - length str) ' ' ++ str
