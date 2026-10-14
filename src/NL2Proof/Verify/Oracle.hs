{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE UndecidableInstances #-}

-- | Stage 2 of the substrate pipeline: verification against an __external__
-- domain oracle.
--
-- == Why this module exists at all
--
-- The whole system is built to feed a reinforcement-learning loop. That imposes
-- one hard constraint, and it is the reason this module is separate from
-- everything upstream:
--
-- > A system cannot use its own internal consistency checks as the reward signal
-- > for the step that produces the claims in the first place.
--
-- Type-checking and provability are internal. Rewarding them measures
-- self-agreement, not truth, and an RL policy will find and exploit the gap —
-- drifting toward claims that are easy to type and easy to prove rather than
-- claims that are faithful to the source. So truth enters the system at exactly
-- one place: an oracle that is not part of the system.
--
-- == 'Unknown' is not 'Refuted', and the distinction is the scope boundary
--
-- Oracle coverage is __binary per domain__. A physics engine can settle claims
-- about trajectories and has nothing to say about monetary policy. Collapsing
-- "outside my domain" into "false" would manufacture exactly the truth-grounding
-- this design refuses to manufacture, so 'Verdict' has three cases and
-- 'Unknown' is a first-class outcome.
--
-- Where no oracle exists for a domain, __this system cannot supply
-- truth-grounding for that domain__. That is inherent, not a gap that closes with
-- more engineering. An uncovered claim can still be extracted, typed, traced and
-- stored; it just never contributes to reward.
--
-- == The gate is a type, not a comment
--
-- 'Confirmed' is abstract: its constructor is not exported, and 'confirm' is the
-- only way to make one. So "fusion only ever sees oracle-confirmed claims" is
-- enforced by the module system rather than asserted in a doc comment, and
-- "NL2Proof.Fusion" cannot be misused even by accident.
module NL2Proof.Verify.Oracle
  ( -- * Verdicts
    Verdict(..)
  , isConfirmed
  , renderVerdict
    -- * Oracles
  , Oracle(..)
  , check
  , covers
    -- * Confirmation tokens
  , Confirmed
  , confClaim
  , confOracle
  , Confirmable
  , confirm
  , confirmAll
    -- * Coverage reporting
  , Coverage(..)
  , coverage
  , renderCoverage
  ) where

import Data.List (nub, partition)

import GHC.TypeLits (ErrorMessage(..), TypeError)

import NL2Proof.DRT.Canonical
import NL2Proof.Verify.ClaimKind

--------------------------------------------------------------------------------
-- Verdicts
--------------------------------------------------------------------------------

-- | What an oracle says about a claim.
--
-- Three cases, not two. 'Unknown' means __this oracle does not cover this
-- claim__ — a statement about the oracle's domain, not about the claim's truth.
data Verdict
  = Confirmed
    -- ^ The oracle asserts the claim holds.
  | Refuted
    -- ^ The oracle asserts the claim fails.
  | Unknown
    -- ^ Outside the oracle's domain. Contributes nothing, in either direction.
  deriving (Eq, Ord, Show)

isConfirmed :: Verdict -> Bool
isConfirmed Confirmed = True
isConfirmed _         = False

renderVerdict :: Verdict -> String
renderVerdict Confirmed = "confirmed"
renderVerdict Refuted   = "refuted"
renderVerdict Unknown   = "no coverage"

--------------------------------------------------------------------------------
-- Oracles
--------------------------------------------------------------------------------

-- | An external decision procedure for some domain.
--
-- The two functions are deliberately separate. 'oracleCovers' is the domain
-- boundary and 'oracleHolds' is the verdict inside it; fusing them into a single
-- @CanonCond -> Bool@ would make "outside my domain" indistinguishable from
-- "false", which is the one confusion this whole design exists to prevent.
--
-- A real oracle is a physics engine, a backtesting engine, or a database of
-- settled measurements: its answers do not depend on this pipeline. The 'Oracle'
-- record is the seam where one gets plugged in. "NL2Proof.Verify.External" reads
-- externally checked run receipts through that seam; the language test fixtures
-- still use toy oracles to exercise plumbing.
data Oracle = Oracle
  { oracleName   :: String
  , oracleDomain :: String
    -- ^ Human-readable statement of what this oracle can settle. Recorded so an
    -- uncovered claim can be reported against a named boundary rather than
    -- silently dropped.
  , oracleCovers :: CanonCond -> Bool
  , oracleHolds  :: CanonCond -> Bool
  }

covers :: Oracle -> CanonCond -> Bool
covers = oracleCovers

check :: Oracle -> CanonCond -> Verdict
check o c
  | not (oracleCovers o c) = Unknown
  | oracleHolds o c        = Confirmed
  | otherwise              = Refuted

--------------------------------------------------------------------------------
-- Confirmation tokens
--------------------------------------------------------------------------------

-- | Evidence that a specific oracle confirmed a specific claim.
--
-- __The constructor is not exported.__ 'confirm' is the only way to obtain one,
-- so a 'Confirmed' value cannot be forged and downstream stages that demand one
-- are structurally unable to run on unverified input.
-- Positional fields are deliberate. Exported record selectors would permit
-- @token { confClaim = uncheckedClaim }@ outside this module even with the
-- constructor hidden. Ordinary accessor functions keep the token immutable.
data Confirmed = MkConfirmed CanonCond String
  deriving (Eq, Show)

confClaim :: Confirmed -> CanonCond
confClaim (MkConfirmed claim _) = claim

confOracle :: Confirmed -> String
confOracle (MkConfirmed _ oracle) = oracle

-- | What 'confirm' accepts: structural top-level assertion witnesses only.
-- Bare conditions can be inspected with 'check', but cannot issue tokens.
-- The other claim kinds have instances only to produce readable errors; the class
-- method is not exported, so no other instance can be written to work around
-- it.
class Confirmable c where
  assertedCond :: c -> CanonCond

instance Confirmable (Claim 'Asserted) where
  assertedCond = claimCond

instance TypeError ('Text "A reported claim cannot be confirmed: being reported is not evidence."
                    ':$$: 'Text "Use check to inspect a hypothesis without creating an assertion token.")
      => Confirmable (Claim 'Reported) where
  assertedCond = claimCond

instance TypeError ('Text "A presupposed claim cannot be confirmed directly."
                    ':$$: 'Text "Use check to inspect a hypothesis without creating an assertion token.")
      => Confirmable (Claim 'Presupposed) where
  assertedCond = claimCond

instance TypeError ('Text "An embedded claim cannot be confirmed: the text does not assert it."
                    ':$$: 'Text "It occurs under a negation, a conditional or a disjunction; confirm the whole"
                    ':$$: 'Text "top-level condition; use check for nonpromoting hypothesis inspection.")
      => Confirmable (Claim 'Embedded) where
  assertedCond = claimCond

-- | 'Just' exactly when the oracle confirms the claim. 'Refuted' and 'Unknown'
-- both give 'Nothing' — they are different facts about the claim but the same
-- fact about whether it may proceed. Accepts asserted claims only
-- ('Confirmable').
confirm :: Confirmable c => Oracle -> c -> Maybe Confirmed
confirm o x = case check o c of
  Confirmed -> Just (MkConfirmed c (oracleName o))
  _         -> Nothing
  where c = assertedCond x

confirmAll :: Oracle -> [Claim 'Asserted] -> [Confirmed]
confirmAll o cs = [x | Just x <- map (confirm o) cs]

--------------------------------------------------------------------------------
-- Coverage reporting
--------------------------------------------------------------------------------

-- | How much of a claim set an oracle could speak to at all.
--
-- 'covUncovered' is the number that matters for scoping a domain: it is the
-- share of the extraction that this design can never ground, and it should be
-- read before deciding whether the RL loop closes for that domain.
data Coverage = Coverage
  { covOracle    :: String
  , covConfirmed :: [CanonCond]
  , covRefuted   :: [CanonCond]
  , covUncovered :: [CanonCond]
  }

coverage :: Oracle -> [CanonCond] -> Coverage
coverage o cs =
  Coverage
    { covOracle = oracleName o
    , covConfirmed = [c | c <- inDomain, oracleHolds o c]
    , covRefuted = [c | c <- inDomain, not (oracleHolds o c)]
    , covUncovered = outDomain
    }
  where
    (inDomain, outDomain) = partition (oracleCovers o) (nub cs)

renderCoverage :: Coverage -> String
renderCoverage cov =
  unlines
    [ "oracle:     " ++ covOracle cov
    , "  confirmed: " ++ show (length (covConfirmed cov))
    , "  refuted:   " ++ show (length (covRefuted cov))
    , "  uncovered: " ++ show (length (covUncovered cov))
        ++ "  <- cannot be grounded by this oracle, in either direction"
    ]
