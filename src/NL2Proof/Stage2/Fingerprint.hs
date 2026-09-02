-- | Structural fingerprints of readings, and a similarity kernel over them.
--
-- == What this is, and what it is not
--
-- ARCHITECTURE.md's Stage 2 names DisCoCat as the graded, similarity-based
-- disambiguation mechanism, composing distributional word vectors along the same
-- syntax tree as the Montague derivation. __This module is not that.__ Real
-- distributional semantics needs a corpus and a vector store; this project has
-- neither, and is committed to `base` plus `containers`.
--
-- What it is instead: a fingerprint over the /structure/ of a reading, and a
-- kernel over fingerprints. That buys graded comparison honestly, without
-- pretending to word meanings it does not have. It is the right shape to swap a
-- real vector source into later — 'similarity' is the only thing callers depend
-- on — but the current signal is structural, not distributional, and calling it
-- otherwise would be overclaiming.
--
-- == Why it is useful anyway
--
-- The discriminating case is scope. Two readings of @"Every student reads a
-- book"@ have __identical__ predicate content and __different__ quantifier
-- structure. A bag-of-predicates comparison says they are the same; a fingerprint
-- that separates content from structure says they agree on what is being talked
-- about and disagree on how it is quantified. That is exactly the distinction a
-- ranking layer needs, and exactly what a word-vector model would blur.
module NL2Proof.Stage2.Fingerprint
  ( -- * Fingerprints
    Fingerprint(..)
  , fingerprint
  , fingerprintDRS
    -- * Similarity
  , similarity
  , contentSimilarity
  , structuralSimilarity
    -- * Rendering
  , renderFingerprint
  ) where

import Data.List (intercalate, sort)
import qualified Data.Map.Strict as M

import NL2Proof.DRT.Canonical
import NL2Proof.DRT.Types (DRS)
import NL2Proof.Semantics.Lambda

--------------------------------------------------------------------------------
-- Fingerprints
--------------------------------------------------------------------------------

-- | A structural signature of a reading.
--
-- Split into a __content__ half (which predicates, applied how often, to how
-- many arguments) and a __structure__ half (quantifier prefix, connectives,
-- nesting depth, variable sharing). Keeping them separate is what makes
-- 'contentSimilarity' and 'structuralSimilarity' independently meaningful.
data Fingerprint = Fingerprint
  { fpPredicates  :: M.Map String Int
    -- ^ Predicate symbol to occurrence count. The content half.
  , fpArities     :: M.Map Int Int
    -- ^ Argument count to occurrence count.
  , fpQuantifiers :: [String]
    -- ^ Quantifier prefix in order, e.g. @["forall","exists"]@. Order matters —
    -- it is the whole scope distinction.
  , fpConnectives :: M.Map String Int
  , fpDepth       :: Int
    -- ^ Maximum nesting depth.
  , fpSharing     :: Int
    -- ^ How many variables occur in more than one predicate. A crude measure of
    -- how interconnected the reading is.
  }
  deriving (Eq, Show)

-- | Fingerprint a lambda term. Expects a normalized, closed term.
fingerprint :: Term -> Fingerprint
fingerprint t =
  Fingerprint
    { fpPredicates  = counts (predOccurrences t)
    , fpArities     = counts (map snd (predArities t))
    , fpQuantifiers = quantPrefix t
    , fpConnectives = counts (connectives t)
    , fpDepth       = depth t
    , fpSharing     = sharing t
    }

-- | Fingerprint a DRS, by way of its provenance-free canonical form.
--
-- Routed through "NL2Proof.DRT.Canonical" so that two DRSs differing only in
-- referent naming or provenance fingerprint identically — the same reason that
-- module exists.
fingerprintDRS :: DRS -> Fingerprint
fingerprintDRS d =
  Fingerprint
    { fpPredicates  = counts (canonPredOccurrences c)
    , fpArities     = counts (canonArities c)
    , fpQuantifiers = canonQuantShape c
    , fpConnectives = counts (canonConnectives c)
    , fpDepth       = canonDepth c
    , fpSharing     = 0  -- referents are already canonical; sharing is implicit
    }
  where
    c = canonicalize d

counts :: Ord a => [a] -> M.Map a Int
counts = M.fromListWith (+) . map (\x -> (x, 1))

--------------------------------------------------------------------------------
-- Term traversals
--------------------------------------------------------------------------------

predOccurrences :: Term -> [String]
predOccurrences = map fst . predArities

-- | Every predicate application, as @(symbol, arity)@.
predArities :: Term -> [(String, Int)]
predArities = go
  where
    go term = case term of
      App{} -> case spine term of
        (Con c _, args) -> (c, length args) : concatMap go args
        (h, args)       -> go h ++ concatMap go args
      TAnd a b      -> go a ++ go b
      TOr a b       -> go a ++ go b
      TImp a b      -> go a ++ go b
      TEq a b       -> go a ++ go b
      TNot a        -> go a
      Lam _ _ b     -> go b
      TForall _ _ b -> go b
      TExists _ _ b -> go b
      Var{}         -> []
      Con{}         -> []

-- | Quantifier prefix in source order, descending through the body only.
--
-- Note this walks the whole term, not just the outermost prefix, so a quantifier
-- inside a restrictor is included. That is intended: it is part of the reading's
-- structure even when it is not part of its top-level scope.
quantPrefix :: Term -> [String]
quantPrefix = go
  where
    go term = case term of
      TForall _ _ b -> "forall" : go b
      TExists _ _ b -> "exists" : go b
      TNot a        -> "not" : go a
      TAnd a b      -> go a ++ go b
      TOr a b       -> go a ++ go b
      TImp a b      -> go a ++ go b
      Lam _ _ b     -> go b
      _             -> []

connectives :: Term -> [String]
connectives = go
  where
    go term = case term of
      TAnd a b      -> "and" : go a ++ go b
      TOr a b       -> "or"  : go a ++ go b
      TImp a b      -> "imp" : go a ++ go b
      TNot a        -> "not" : go a
      TEq a b       -> "eq"  : go a ++ go b
      TForall _ _ b -> go b
      TExists _ _ b -> go b
      Lam _ _ b     -> go b
      App f a       -> go f ++ go a
      Var{}         -> []
      Con{}         -> []

depth :: Term -> Int
depth = go
  where
    go term = case term of
      TAnd a b      -> 1 + max (go a) (go b)
      TOr a b       -> 1 + max (go a) (go b)
      TImp a b      -> 1 + max (go a) (go b)
      TEq a b       -> 1 + max (go a) (go b)
      TNot a        -> 1 + go a
      TForall _ _ b -> 1 + go b
      TExists _ _ b -> 1 + go b
      Lam _ _ b     -> 1 + go b
      App f a       -> 1 + max (go f) (go a)
      Var{}         -> 0
      Con{}         -> 0

-- | Variables appearing as an argument to more than one predicate.
sharing :: Term -> Int
sharing t = length [v | (v, n) <- M.toList tally, n > 1]
  where
    tally = M.fromListWith (+) [(v, 1 :: Int) | v <- argVars t]

    argVars = go
      where
        go term = case term of
          App{} -> case spine term of
            (Con _ _, args) -> [v | Var v <- args] ++ concatMap go args
            (h, args)       -> go h ++ concatMap go args
          TAnd a b      -> go a ++ go b
          TOr a b       -> go a ++ go b
          TImp a b      -> go a ++ go b
          TEq a b       -> go a ++ go b
          TNot a        -> go a
          Lam _ _ b     -> go b
          TForall _ _ b -> go b
          TExists _ _ b -> go b
          Var{}         -> []
          Con{}         -> []

--------------------------------------------------------------------------------
-- Canonical traversals
--------------------------------------------------------------------------------

canonPredOccurrences :: Canonical -> [String]
canonPredOccurrences = map fst . canonPredArities

canonPredArities :: Canonical -> [(String, Int)]
canonPredArities (Canonical _ cs) = concatMap go cs
  where
    go (CanPred p as) = [(p, length as)]
    go (CanEq _ _)    = []
    go (CanNot x)     = canonPredArities x
    go (CanImp a b)   = canonPredArities a ++ canonPredArities b
    go (CanOr a b)    = canonPredArities a ++ canonPredArities b

canonArities :: Canonical -> [Int]
canonArities = map snd . canonPredArities

canonQuantShape :: Canonical -> [String]
canonQuantShape (Canonical us cs) =
  replicate (length us) "ref" ++ concatMap go cs
  where
    go (CanNot x)   = "not" : canonQuantShape x
    go (CanImp a b) = "imp" : canonQuantShape a ++ canonQuantShape b
    go (CanOr a b)  = "or"  : canonQuantShape a ++ canonQuantShape b
    go _            = []

canonConnectives :: Canonical -> [String]
canonConnectives (Canonical _ cs) = concatMap go cs
  where
    go (CanNot x)   = "not" : canonConnectives x
    go (CanImp a b) = "imp" : canonConnectives a ++ canonConnectives b
    go (CanOr a b)  = "or"  : canonConnectives a ++ canonConnectives b
    go _            = []

canonDepth :: Canonical -> Int
canonDepth (Canonical _ cs) = 1 + maximum (0 : map go cs)
  where
    go (CanNot x)   = canonDepth x
    go (CanImp a b) = max (canonDepth a) (canonDepth b)
    go (CanOr a b)  = max (canonDepth a) (canonDepth b)
    go _            = 0

--------------------------------------------------------------------------------
-- Similarity
--------------------------------------------------------------------------------

-- | Weighted Jaccard over two count maps: @sum of minima / sum of maxima@.
--
-- Ranges over @[0,1]@, is @1@ exactly when the multisets are equal, and is
-- symmetric. Chosen over cosine because these are counts rather than directions,
-- and over plain set Jaccard because repeated predicates carry information.
jaccard :: Ord k => M.Map k Int -> M.Map k Int -> Double
jaccard a b
  | denom == 0 = 1  -- both empty: vacuously identical
  | otherwise  = fromIntegral numer / fromIntegral denom
  where
    ks = M.keys (M.union a b)
    at m k = M.findWithDefault 0 k m
    numer = sum [min (at a k) (at b k) | k <- ks]
    denom = sum [max (at a k) (at b k) | k <- ks]

-- | Agreement on /what is talked about/: predicates and their arities.
--
-- Deliberately blind to structure. Two scope readings of one sentence score
-- @1.0@ here, which is the correct answer to "are these about the same thing".
contentSimilarity :: Fingerprint -> Fingerprint -> Double
contentSimilarity x y =
  0.75 * jaccard (fpPredicates x) (fpPredicates y)
    + 0.25 * jaccard (fpArities x) (fpArities y)

-- | Agreement on /how it is put together/: quantifier order, connectives,
-- depth, sharing.
--
-- Quantifier order is compared as a sequence, not a set, so the two scope
-- readings score below @1.0@ here even though their content is identical. That
-- asymmetry between the two halves is the useful signal.
structuralSimilarity :: Fingerprint -> Fingerprint -> Double
structuralSimilarity x y =
  0.5 * seqSim (fpQuantifiers x) (fpQuantifiers y)
    + 0.2 * jaccard (fpConnectives x) (fpConnectives y)
    + 0.2 * ratio (fpDepth x) (fpDepth y)
    + 0.1 * ratio (fpSharing x) (fpSharing y)
  where
    seqSim as bs
      | null as && null bs = 1
      | length as /= length bs = 0.5 * jaccard (counts as) (counts bs)
      | otherwise =
          let agree = length [() | (a, b) <- zip as bs, a == b]
          in fromIntegral agree / fromIntegral (length as)

    ratio a b
      | a == 0 && b == 0 = 1
      | otherwise        = fromIntegral (min a b) / fromIntegral (max a b)

-- | Overall similarity, content weighted over structure.
--
-- Content dominates because two readings of the same sentence /are/ mostly the
-- same thing; structure is the tiebreaker that separates them. In @[0,1]@,
-- symmetric, and @1.0@ exactly for identical fingerprints.
similarity :: Fingerprint -> Fingerprint -> Double
similarity x y = 0.65 * contentSimilarity x y + 0.35 * structuralSimilarity x y

--------------------------------------------------------------------------------
-- Rendering
--------------------------------------------------------------------------------

renderFingerprint :: Fingerprint -> String
renderFingerprint fp =
  intercalate "  "
    [ "preds{" ++ commas [k ++ ":" ++ show n | (k, n) <- M.toList (fpPredicates fp)] ++ "}"
    , "quants[" ++ unwords (fpQuantifiers fp) ++ "]"
    , "conn{" ++ commas [k ++ ":" ++ show n | (k, n) <- M.toList (fpConnectives fp)] ++ "}"
    , "depth=" ++ show (fpDepth fp)
    , "shared=" ++ show (fpSharing fp)
    ]
  where
    commas = intercalate "," . sort
