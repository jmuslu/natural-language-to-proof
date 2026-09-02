-- | Stage 4 of the substrate pipeline: the reinforcement-learning reward signal.
--
-- == The one constraint this module exists to enforce
--
-- > A system cannot use its own internal consistency checks as the reward signal
-- > for the step that produces the claims in the first place.
--
-- Type-checking and provability-in-isolation are internal. Rewarding either
-- measures self-agreement, and an RL policy will exploit the gap: there is a
-- cheaper path to reward than faithful extraction, namely drifting toward claims
-- that happen to be easy to type or easy to prove.
--
-- So the reward has exactly two admissible sources:
--
-- 1. __Direct oracle confirmation__ — an external procedure said so.
-- 2. __Mechanical entailment from an already-confirmed base__ — inherited
--    grounding, via 'NL2Proof.Fusion.entailedFrom'.
--
-- and one inadmissible one, spelled out because it is the tempting one:
--
-- * anything the system can establish about a claim on its own.
--
-- == How that is enforced rather than asserted
--
-- 'score' takes a 'Fused' and a 'Genealogy' and __has no access to a typing
-- judgement or a proof search__. It cannot read 'NL2Proof.Semantics.Lambda.typeOf'
-- because it never sees a 'NL2Proof.Semantics.Lambda.Term'. The signature is the
-- enforcement mechanism; the test suite pins the consequences, including that
-- adding arbitrarily many well-typed unverified claims never moves the score.
--
-- == Uncovered is scored at zero, not penalised
--
-- A claim no oracle covers gets nothing, in either direction. Penalising it
-- would train the policy away from domains that merely lack instrumentation,
-- which is a fact about the tooling and not about the claim. Rewarding it would
-- be manufacturing grounding. Zero is the only defensible value, and
-- 'rwUncovered' reports the count so the size of the ungrounded remainder stays
-- visible.
--
-- == What this module cannot fix
--
-- Extraction faithfulness. Nothing here checks that a confirmed claim is what
-- the source text actually said — only that it is true. A policy that extracts
-- true-but-unfaithful claims scores well. The oracle bounds the /truth/ of the
-- output and says nothing about its /correspondence/ to the input, and no
-- internal mechanism supplies that. See ARCHITECTURE.md's standing limitations;
-- this is the one that does not close.
module NL2Proof.Reward
  ( -- * Reward
    Reward(..)
  , score
  , scoreWith
    -- * Weights
  , Weights(..)
  , defaultWeights
    -- * Admissibility
  , Admissibility(..)
  , admissibility
  , renderAdmissibility
    -- * Rendering
  , renderReward
  ) where

import Data.List (nub)
import qualified Data.Set as S

import NL2Proof.Fusion
import NL2Proof.Genealogy
import NL2Proof.Verify.Oracle

--------------------------------------------------------------------------------
-- Weights
--------------------------------------------------------------------------------

-- | Reward weights. __Stipulated__, in the same sense as the glue-logic cue
-- weights: these numbers encode a guess and are the thing a real training run
-- would replace. The /structure/ — which categories exist and which contribute
-- zero — is not stipulated and is what the checks pin down.
data Weights = Weights
  { wConfirmed :: Double
  , wEntailed  :: Double
  , wRefuted   :: Double
    -- ^ Negative. A refuted claim is a wrong answer the oracle caught, and it
    -- must cost more than silence, or the policy learns to guess.
  , wUncovered :: Double
    -- ^ __Must be zero.__ Not a tunable. 'admissibility' checks it.
  }
  deriving (Eq, Show)

defaultWeights :: Weights
defaultWeights =
  Weights
    { wConfirmed = 1.0
    , wEntailed = 0.5
    , wRefuted = -1.0
    , wUncovered = 0.0
    }

--------------------------------------------------------------------------------
-- Reward
--------------------------------------------------------------------------------

data Reward = Reward
  { rwConfirmed :: Int
    -- ^ Claims an oracle confirmed directly.
  , rwEntailed  :: Int
    -- ^ Claims that follow mechanically from the confirmed base, and were not
    -- themselves confirmed. Grounding inherited, not manufactured.
  , rwRefuted   :: Int
  , rwUncovered :: Int
    -- ^ Premises that were offered to an oracle and fell outside its domain.
    -- Extracted, well-formed, traced — and ungroundable. Contributes zero. This
    -- is the size of the remainder the design cannot reach, and the number to
    -- read before deciding whether the RL loop closes for a domain.
  , rwUngrounded :: Int
    -- ^ Nodes in the genealogy with no grounded support: unsupported, or
    -- supported only around a cycle. Also zero-valued, and reported separately
    -- because a large number here means the extraction is producing claims that
    -- rest on nothing.
  , rwScore     :: Double
  }
  deriving (Eq, Show)

score :: Fused -> Genealogy -> Reward
score = scoreWith defaultWeights

scoreWith :: Weights -> Fused -> Genealogy -> Reward
scoreWith w f g =
  Reward
    { rwConfirmed = nConfirmed
    , rwEntailed = nEntailed
    , rwRefuted = nRefuted
    , rwUncovered = nUncovered
    , rwUngrounded = nUngrounded
    , rwScore =
        wConfirmed w * fromIntegral nConfirmed
          + wEntailed w * fromIntegral nEntailed
          + wRefuted w * fromIntegral nRefuted
          + wUncovered w * fromIntegral nUncovered
    }
  where
    base = fusedClaims f

    nConfirmed = length base
    nEntailed = length [c | c <- nub (entailedFrom f), c `notElem` base]

    -- Only PREMISES are scored for verdicts. A derived node was never offered
    -- to an oracle, so asking whether it is covered is a category error; its
    -- standing comes from its antecedents, which is what 'grounded' computes.
    premiseIds = nub [jTarget j | j <- gJusts g, null (jAntecedents j)]
    nRefuted = length [i | i <- premiseIds, verdictOf g i == Refuted]
    nUncovered = length [i | i <- premiseIds, verdictOf g i == Unknown]

    gr = grounded g
    nUngrounded = length [i | i <- nodeIds g, not (i `S.member` gr)]

--------------------------------------------------------------------------------
-- Admissibility
--------------------------------------------------------------------------------

-- | A self-check on the reward function: does it satisfy the constraints the
-- design requires of it?
--
-- Exists so the constraints are executable. A weight table that violates them
-- compiles and runs and quietly trains the wrong thing, which is precisely the
-- failure mode that motivated the refactor.
data Admissibility = Admissibility
  { adUncoveredIsZero    :: Bool
    -- ^ Uncovered claims must contribute exactly zero.
  , adRefutedIsNegative  :: Bool
    -- ^ Guessing must cost more than silence.
  , adConfirmedDominates :: Bool
    -- ^ Direct confirmation must be worth at least as much as inherited
    -- grounding, or the policy is rewarded for laundering claims through
    -- entailment instead of getting them checked.
  , adAllOk              :: Bool
  }

admissibility :: Weights -> Admissibility
admissibility w =
  Admissibility
    { adUncoveredIsZero = z
    , adRefutedIsNegative = n
    , adConfirmedDominates = d
    , adAllOk = z && n && d
    }
  where
    z = wUncovered w == 0
    n = wRefuted w < 0
    d = wConfirmed w >= wEntailed w

renderAdmissibility :: Admissibility -> String
renderAdmissibility a =
  unlines
    [ "reward admissibility"
    , "  uncovered scores zero:      " ++ show (adUncoveredIsZero a)
    , "  refuted is penalised:       " ++ show (adRefutedIsNegative a)
    , "  confirmation >= entailment: " ++ show (adConfirmedDominates a)
    , "  admissible:                 " ++ show (adAllOk a)
    ]

--------------------------------------------------------------------------------
-- Rendering
--------------------------------------------------------------------------------

renderReward :: Reward -> String
renderReward r =
  unlines
    [ "reward " ++ show (rwScore r)
    , "  confirmed:  " ++ show (rwConfirmed r)
    , "  entailed:   " ++ show (rwEntailed r) ++ "  (inherited grounding)"
    , "  refuted:    " ++ show (rwRefuted r)
    , "  uncovered:  " ++ show (rwUncovered r) ++ "  (scores zero, by design)"
    , "  ungrounded: " ++ show (rwUngrounded r) ++ "  (no support, or cyclic)"
    ]
