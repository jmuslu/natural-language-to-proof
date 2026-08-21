-- | __truth-mode__ collapse: lossy canonical compression.
--
-- Only the final logical content matters. Different sentences that entail the
-- same proposition compress to one canonical form. This is lossy /by design and
-- correctly so/ — it is what feeds the proof stage, and a proof checker does not
-- care which document a hypothesis arrived in.
--
-- == What is thrown away, precisely
--
-- 1. __Derivation trees.__ The @how@-provenance is reduced to @why@: a set of
--    'SourceId's. After this, "these two conditions came from different
--    sentences" is unrecoverable.
-- 2. __Duplicate conditions.__ Two independent assertions of the same
--    proposition become one. This is the step that makes retraction impossible,
--    and it is the whole reason provenance-mode exists as a separate branch.
-- 3. __Condition order.__ Conditions are sorted into a canonical order, so
--    surface order stops being observable.
--
-- What is retained: 'tfSources', so you still know /which/ sources are involved,
-- and 'tfDropped', so the loss is __measured__ rather than assumed away. Per the
-- methodology notes, drift you have measured is different in kind from drift you
-- have decided not to look at.
--
-- == The seam
--
-- This module is the only thing on this branch that @main@ does not have. If a
-- change here requires editing anything upstream of
-- "NL2Proof.Collapse.Class", the seam is in the wrong place — do not fork the
-- core to accommodate a mode.
module NL2Proof.Collapse.Truth
  ( -- * Output
    TruthForm(..)
    -- * Compression
  , compress
  , collapseTruth
  , truthStrategy
    -- * Comparison
  , sameProposition
  , compressionRatio
    -- * Rendering
  , renderTruthForm
  ) where

import Data.List (sort)

import NL2Proof.Collapse.Class
import NL2Proof.DRT.Canonical
import NL2Proof.DRT.Types
import NL2Proof.Provenance

--------------------------------------------------------------------------------
-- Output
--------------------------------------------------------------------------------

-- | The canonical compressed form of a selected reading.
data TruthForm = TruthForm
  { tfForm :: Canonical
    -- ^ Provenance-free, sorted, deduplicated. Equality on this field /is/
    -- propositional identity as far as this pipeline is concerned.
  , tfSources :: [SourceId]
    -- ^ @why@-provenance: which sources are involved. Not which condition came
    -- from which — that is exactly what was discarded.
  , tfDropped :: Int
    -- ^ Nodes removed by compression. The measured size of the loss.
  }
  deriving (Eq, Show)

--------------------------------------------------------------------------------
-- Compression
--------------------------------------------------------------------------------

-- | Sort and deduplicate conditions at every depth, returning the compressed
-- form and the number of nodes removed.
--
-- Sorting is by the derived 'Ord' on 'CanonCond': an arbitrary but stable total
-- order. Stability is the requirement, not meaningfulness — the point is that
-- the same content always lands in the same shape.
compress :: Canonical -> (Canonical, Int)
compress c = (compressed, canonSize c - canonSize compressed)
  where
    compressed = go c

    go (Canonical us cs) = Canonical (dedupe us) (dedupe (map deeper cs))

    -- Nested boxes are compressed too, otherwise a duplicate inside a negation
    -- would survive and two equivalent readings would compare unequal.
    deeper (CanNot x)   = CanNot (go x)
    deeper (CanImp a b) = CanImp (go a) (go b)
    deeper (CanOr a b)  = CanOr (go a) (go b)
    deeper k            = k

    dedupe :: Ord a => [a] -> [a]
    dedupe = squash . sort
      where
        squash (a : b : rest)
          | a == b    = squash (a : rest)
          | otherwise = a : squash (b : rest)
        squash xs     = xs

-- | Collapse a 'Selection' to its canonical propositional content.
--
-- Note that 'selRejected' is read only for its count, via
-- 'selectionDecision' in 'runStrategy'. truth-mode does not keep the rejected
-- readings: they are alternative propositions, and it has committed to one.
collapseTruth :: Selection -> TruthForm
collapseTruth sel =
  TruthForm
    { tfForm = form
    , tfSources = sort (drsSources chosen)
    , tfDropped = dropped
    }
  where
    chosen = selChosen sel
    (form, dropped) = compress (canonicalize chosen)

truthStrategy :: CollapseStrategy TruthForm
truthStrategy =
  CollapseStrategy
    { strategyName = "truth-mode"
    , strategyDoc =
        "Lossy canonical compression. Discards derivation trees (how-provenance"
          ++ " reduced to why), duplicate conditions, and condition order."
          ++ " Retains the source set and a node count of what was dropped."
          ++ " Retraction of an individual source is NOT supported: once two"
          ++ " assertions of one proposition have merged, they cannot be"
          ++ " separated again."
    , applyStrategy = collapseTruth
    }

--------------------------------------------------------------------------------
-- Comparison
--------------------------------------------------------------------------------

-- | Do these two collapse to the same proposition?
--
-- Source sets are deliberately ignored. That is the defining property of
-- truth-mode: the same claim from two different documents is /one/ claim.
sameProposition :: TruthForm -> TruthForm -> Bool
sameProposition a b = tfForm a == tfForm b

-- | Compressed size as a fraction of original size. @1.0@ means nothing was
-- dropped.
compressionRatio :: TruthForm -> Double
compressionRatio tf
  | original == 0 = 1.0
  | otherwise = fromIntegral (canonSize (tfForm tf)) / fromIntegral original
  where
    original = canonSize (tfForm tf) + tfDropped tf

--------------------------------------------------------------------------------
-- Rendering
--------------------------------------------------------------------------------

renderTruthForm :: TruthForm -> String
renderTruthForm tf =
  unlines
    [ "truth-mode form: " ++ renderCanonical (tfForm tf)
    , "  sources:  " ++ show (tfSources tf)
    , "  dropped:  " ++ show (tfDropped tf) ++ " node(s)"
    , "  retained: " ++ show (canonSize (tfForm tf)) ++ " node(s)"
    ]
