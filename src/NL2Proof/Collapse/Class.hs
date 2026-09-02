-- | The handoff from search to disposition: a chosen reading, the readings it
-- was chosen over, and the rule that broke the tie.
--
-- __This is the seam.__ Everything upstream — tokenizing, CCG derivation, lambda
-- composition, type checking, DRS construction, anaphora resolution — produces
-- candidates and commits to nothing. Everything downstream disposes of them:
--
-- * "NL2Proof.Verify.Claims" retains every derivation, because an oracle can
--   reverse itself and retraction needs the record
-- * "NL2Proof.Fusion" collapses the survivors, but only after an oracle has
--   spoken
--
-- If a change to a downstream stage requires editing anything upstream of here,
-- that is a signal the seam is in the wrong place, not a reason to fork the
-- core.
--
-- == Why 'Selection' exists
--
-- ARCHITECTURE.md: the pipeline must explicitly collapse a candidate set to one
-- selected proposition, and
--
-- > That collapse is a decision, not a derivation, and should be logged as such.
--
-- A function of type @[DRS] -> DRS@ cannot honour that. It discards the
-- alternatives as it runs and leaves no evidence a choice occurred, so its
-- output is indistinguishable from a derived result. 'Selection' is the
-- reification of the choice: it carries the rejected candidates alongside the
-- chosen one, so that "this was selected from five readings by a stated
-- heuristic" survives into the output.
--
-- Hence 'CollapseStrategy' consumes a 'Selection', never a bare 'DRS'.
module NL2Proof.Collapse.Class
  ( -- * Selection
    Selection(..)
  , selectOnly
  , selectBy
  , selectionCandidateCount
  , selectionDecision
    -- * Strategies
  , CollapseStrategy(..)
  , runStrategy
    -- * Mode-independent folds
  , selectionSources
  , selectionSpans
  ) where

import Data.List (sortOn)

import NL2Proof.DRT.Types
import NL2Proof.Provenance
import NL2Proof.Trace

--------------------------------------------------------------------------------
-- Selection
--------------------------------------------------------------------------------

-- | One chosen candidate, plus the candidates that were rejected to choose it.
data Selection = Selection
  { selChosen       :: DRS
  , selRejected     :: [DRS]
    -- ^ Kept, not discarded. An empty list means the choice was forced.
  , selRationale    :: String
    -- ^ The heuristic or rule that selected 'selChosen'. State it explicitly.
  , selProv         :: Prov
  }
  deriving (Eq, Show)

-- | A selection with no alternatives: the candidate set had exactly one member,
-- so no decision was actually made.
--
-- This is the honest constructor for the common Stage 1 case. It is distinct from
-- a one-of-many selection precisely so that "unambiguous" and "disambiguated"
-- do not look alike downstream.
selectOnly :: DRS -> Prov -> Selection
selectOnly d p =
  Selection
    { selChosen = d
    , selRejected = []
    , selRationale = "unique candidate; no choice required"
    , selProv = p
    }

-- | Select from a candidate set by a scoring function, highest score winning.
--
-- Ties are broken by original position, and the rationale records the scoring
-- function's name so the decision is reconstructible.
selectBy :: String -> (DRS -> Double) -> [DRS] -> Prov -> Maybe Selection
selectBy _ _ [] _ = Nothing
selectBy name score cands p =
  case sortOn (\(i, d) -> (negate (score d), i)) (zip [0 :: Int ..] cands) of
    [] -> Nothing
    ((_, best) : rest) ->
      Just
        Selection
          { selChosen = best
          , selRejected = map snd rest
          , selRationale =
              if null rest
                then "unique candidate; no choice required"
                else "highest score under " ++ name
          , selProv = p
          }

selectionCandidateCount :: Selection -> Int
selectionCandidateCount s = 1 + length (selRejected s)

-- | Project a 'Selection' into the trace log. Both modes should call this, so
-- that the record of the collapse exists regardless of what the collapse
-- produced.
selectionDecision :: Selection -> Decision
selectionDecision s =
  Decision
    { decKind = "collapse"
    , decChoice = show (drsSize (selChosen s)) ++ "-node DRS"
    , decAlternatives = [show (drsSize d) ++ "-node DRS" | d <- selRejected s]
    , decWhy = selRationale s
    , decProv = selProv s
    }

--------------------------------------------------------------------------------
-- Strategies
--------------------------------------------------------------------------------

-- | A named disposition producing some stage-specific artifact @a@.
--
-- @a@ is left open on purpose. Fusion instantiates it at a canonical normal
-- form; verification at something carrying the derivation forest. Both are
-- 'CollapseStrategy', so the pipeline that feeds them is written once.
data CollapseStrategy a = CollapseStrategy
  { strategyName :: String
  , strategyDoc  :: String
    -- ^ What this strategy preserves and what it throws away. Required, not
    -- decorative: a lossy strategy that does not say what it loses cannot be
    -- audited.
  , applyStrategy :: Selection -> a
  }

-- | Run a strategy, returning its artifact together with the decision record.
--
-- Returning both is the point: a strategy cannot be run in a way that produces
-- the artifact but not the log.
runStrategy :: CollapseStrategy a -> Selection -> (a, Decision)
runStrategy strat sel = (applyStrategy strat sel, selectionDecision sel)

--------------------------------------------------------------------------------
-- Mode-independent folds
--------------------------------------------------------------------------------

-- | Sources behind the chosen candidate. Available in both modes.
selectionSources :: Selection -> [SourceId]
selectionSources = drsSources . selChosen

-- | Source spans behind the chosen candidate's conditions, in source order.
--
-- This is the traceability requirement, and it holds in __both__ modes: every
-- atomic clause is traceable to a span regardless of whether the derivation tree
-- above it was retained.
selectionSpans :: Selection -> [Span]
selectionSpans =
  sortOn spanStart
    . concatMap (maybe [] (: []) . provSpan)
    . drsConditionProvs
    . selChosen
