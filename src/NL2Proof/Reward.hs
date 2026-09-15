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
-- == The scalar is not the reward
--
-- 'rwScore' is a linear collapse of the coordinates below under
-- 'defaultWeights'. It is __stipulated__, in the same sense the weights are, and
-- three of its properties are worth stating plainly — each is a fact about the
-- collapse rather than about the design:
--
-- 1. __It is extensive.__ On disjoint claim sets the score of the union is the
--    sum of the scores, so it is unbounded in the number of claims and carries
--    no per-claim cost. Combined with @wUncovered = 0@, over-generation is free:
--    appending claims no oracle covers leaves it unchanged.
--
-- 2. __It never reads provenance, so it does not depend on the input.__ It is a
--    function of the claim multiset and the verdicts alone. Two extractions that
--    ground the same claims score identically whether one accounts for the whole
--    source text or for six characters of it.
--
-- 3. __It factors through the idempotent quotient.__ 'NL2Proof.Fusion.fusedClaims'
--    is a set, and per TRACE.md P5.2 that quotient is precisely what erases
--    corroboration. So the scalar cannot express "two derivations agree", which
--    is the one provability-shaped signal
--    "NL2Proof.Genealogy".'NL2Proof.Genealogy.corroboratedNodes' argues is safe.
--
-- Property 1 is not fixable by reweighting, and that is worth being exact about.
-- The scalar is blind to over-generation __exactly when__ @wUncovered = 0@ — the
-- same condition 'adUncoveredIsZero' /requires/, for the independent and correct
-- reason that penalising an uninstrumented domain trains the policy away from
-- the tooling rather than away from the error. So no weight table satisfies the
-- requirement and escapes the blindness. The escape is a __denominator__, which
-- is a coordinate and not a weight.
--
-- Hence: the coordinates are reported separately and they are the object. A
-- training run should learn a function over them; that function is not expected
-- to be linear, and writing one here would be a guess wearing the clothes of a
-- design.
--
-- == The coordinates, and what makes each admissible
--
-- /Admissible/ means: not something the system establishes about a claim on its
-- own. There are two admissible sources, and they are genuinely two:
--
-- * __the oracle__, which is external to the system — 'rwConfirmed',
--   'rwRefuted', 'rwUncovered'
-- * __provenance__, which is /determined by the input/ — 'rwGroundedSpan',
--   'rwCorroborated'
--
-- Provenance qualifies for the same reason the oracle does, by a different
-- route. A 'NL2Proof.Provenance.Prov' tree is built by the parser out of the
-- source token's own span; nothing downstream can assert one. So a
-- provenance-derived number is a fact about the /relation between output and
-- input/, and it cannot be inflated without actually consuming more input. That
-- is what lets these coordinates supply the input-dependence the verdict
-- coordinates structurally cannot.
--
-- They are also not redundant with one another. 'rwCorroborated' pays for the
-- same claim arriving twice by different routes; 'rwNovel' pays for claims that
-- do /not/ follow from the others. Those pull in opposite directions, which is
-- the shape of a trade-off rather than of a scale — another reason a single
-- number is the wrong container.
--
-- == What this module still cannot fix
--
-- Extraction faithfulness, in the strong sense. The coordinates bound the
-- /material/ correspondence between output and input: 'rwGroundedSpan' says
-- which characters the grounded claims were derived from, so an extraction that
-- ignores most of the source is now distinguishable from one that does not. They
-- do not bound /semantic/ correspondence. A policy that derives a true claim from
-- the right characters and means something else by it still scores well, and no
-- internal mechanism supplies that check. See ARCHITECTURE.md's standing
-- limitations; this is the one that narrows and does not close.
module NL2Proof.Reward
  ( -- * Reward
    Reward(..)
  , score
  , scoreWith
  , scoreOver
    -- * Derived rates
  , rwYield
  , rwGroundedShare
  , rwSourceCoverage
    -- * Vector-valued reward (defer scalarization)
  , rewardCoordinates
  , dominates
  , paretoFrontier
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
import NL2Proof.Provenance
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
  , rwOffered   :: Int
    -- ^ Premises offered to an oracle. __The denominator.__ Reported because
    -- every count above is meaningless as a measure of quality without it: 3
    -- confirmations out of 4 offered and 3 out of 400 are the same numerator.
  , rwCorroborated :: Int
    -- ^ Grounded claims reached by more than one /distinct/ derivation, via
    -- 'NL2Proof.Genealogy.corroboratedNodes'. Distinctness is load-bearing —
    -- see that function for why counting mere repetition would be an exploit
    -- rather than a signal.
  , rwNovel     :: Int
    -- ^ Confirmed claims that do __not__ follow mechanically from the rest of
    -- the confirmed base. Content the oracle had to supply, as opposed to content
    -- already implied by what it supplied elsewhere. This is the discovery-facing
    -- coordinate, and it is the one 'rwCorroborated' trades against.
  , rwSourceSpan :: Int
    -- ^ Characters in the source text, when the caller supplies the extent.
    -- @0@ means "not supplied", and 'rwSourceCoverage' returns 'Nothing' rather
    -- than pretending the coverage is total.
  , rwOfferedSpan :: Int
    -- ^ Characters the offered claims were derived from, overlaps counted once.
  , rwGroundedSpan :: Int
    -- ^ Characters the __grounded__ claims were derived from. The input-side
    -- coordinate: it cannot be raised without deriving from more of the input.
  , rwScore     :: Double
    -- ^ The stipulated linear collapse. Read the module header before treating
    -- this as the reward; three of its blind spots are named there.
  }
  deriving (Eq, Show)

score :: Fused -> Genealogy -> Reward
score = scoreWith defaultWeights

-- | 'scoreOver' with no source extent, so 'rwSourceCoverage' is 'Nothing'.
scoreWith :: Weights -> Fused -> Genealogy -> Reward
scoreWith w = scoreOver w Nothing

-- | Score against an optional source extent.
--
-- The extent is a 'NL2Proof.Provenance.Span' and nothing more. That matters,
-- because this module's narrow signature /is/ its enforcement mechanism: an
-- interval of naturals cannot encode a typing judgement or a proof, so widening
-- the domain by this much admits the input-side evidence without admitting any
-- of the internal evidence the design excludes.
scoreOver :: Weights -> Maybe Span -> Fused -> Genealogy -> Reward
scoreOver w extent f g =
  Reward
    { rwConfirmed = nConfirmed
    , rwEntailed = nEntailed
    , rwRefuted = nRefuted
    , rwUncovered = nUncovered
    , rwUngrounded = nUngrounded
    , rwOffered = length premiseIds
    , rwCorroborated = nCorroborated
    , rwNovel = nNovel
    , rwSourceSpan = maybe 0 spanWidth extent
    , rwOfferedSpan = spanCoverage (spansOf (nodeIds g))
    , rwGroundedSpan = spanCoverage (spansOf (S.toList gr))
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

    -- Content the oracle had to supply: a confirmed claim that the rest of the
    -- confirmed base does not already entail. Quadratic in the base, which is
    -- fine at these sizes and is the honest way to ask the question — each claim
    -- has to be withheld to find out whether it was needed.
    nNovel =
      length
        [ c
        | c <- base
        , c `notElem` entailedFrom (withoutClaim c f)
        ]

    -- Only PREMISES are scored for verdicts. A derived node was never offered
    -- to an oracle, so asking whether it is covered is a category error; its
    -- standing comes from its antecedents, which is what 'grounded' computes.
    premiseIds = nub [jTarget j | j <- gJusts g, null (jAntecedents j)]
    nRefuted = length [i | i <- premiseIds, verdictOf g i == Refuted]
    nUncovered = length [i | i <- premiseIds, verdictOf g i == Unknown]

    gr = grounded g
    nUngrounded = length [i | i <- nodeIds g, not (i `S.member` gr)]

    -- Corroboration counts only where it can matter: a claim reached twice but
    -- grounded nowhere is not evidence of anything.
    nCorroborated =
      length
        [ ()
        | (_, is) <- corroboratedNodes g
        , any (`S.member` gr) is
        ]

    spansOf is =
      [ sp
      | i <- is
      , Just n <- [nodeAt g i]
      , Just sp <- [provSpan (nodeProv n)]
      ]

--------------------------------------------------------------------------------
-- Derived rates
--------------------------------------------------------------------------------

-- | Confirmed premises as a fraction of premises offered. @0@ when none were
-- offered.
--
-- This is the coordinate that makes over-generation visible: appending claims no
-- oracle covers leaves 'rwScore' untouched and lowers this.
rwYield :: Reward -> Double
rwYield r
  | rwOffered r == 0 = 0
  | otherwise = fromIntegral (rwConfirmed r) / fromIntegral (rwOffered r)

-- | Grounded input characters as a fraction of the input characters drawn on.
-- @0@ when nothing was drawn on. This is /precision/ over source material.
rwGroundedShare :: Reward -> Double
rwGroundedShare r
  | rwOfferedSpan r == 0 = 0
  | otherwise = fromIntegral (rwGroundedSpan r) / fromIntegral (rwOfferedSpan r)

-- | Grounded input characters as a fraction of the whole source. /Recall/ over
-- source material, and 'Nothing' when the caller did not supply the extent.
--
-- 'rwGroundedShare' alone is maximised by extracting one easy claim and stopping;
-- this is the coordinate that says so.
rwSourceCoverage :: Reward -> Maybe Double
rwSourceCoverage r
  | rwSourceSpan r == 0 = Nothing
  | otherwise = Just (fromIntegral (rwGroundedSpan r) / fromIntegral (rwSourceSpan r))

--------------------------------------------------------------------------------
-- Vector-valued reward: the Pareto frontier over the coordinates
--------------------------------------------------------------------------------

-- $vectorReward
-- 'rwScore' is one linear collapse of the coordinates, and it deliberately omits
-- 'rwCorroborated' and 'rwNovel' — because those two are anti-correlated by
-- construction (a heavily corroborated claim is near-definitionally already
-- implied by the base; a genuinely novel claim structurally cannot be
-- corroborated yet), so any fixed positive weight on both picks a corner and the
-- policy farms whichever coordinate is cheaper. The honest object is therefore
-- not a bigger weighted sum but the /vector/ of coordinates and the Pareto
-- frontier over it: compare candidates by dominance, and defer scalarization
-- (the "train toward the frontier" direction, and the precedent for treating a
-- coordinate as non-tunable that 'wUncovered' already sets). This takes no
-- position on how corroboration trades against novelty — that is exactly the
-- choice a scalar would smuggle in, and the choice this leaves to an external
-- fitness function (the same one Layer 5's graph-trust question needs).

-- | The value-bearing reward coordinates, oriented so higher is better on every
-- axis (refuted enters negated). Includes 'rwCorroborated' and 'rwNovel', which
-- 'rwScore' omits. Zero-valued coordinates ('rwUncovered', 'rwUngrounded') are
-- excluded: they carry no value by design, so they must not enter a dominance
-- comparison.
rewardCoordinates :: Reward -> [Double]
rewardCoordinates r =
  map fromIntegral
    [ rwConfirmed r, rwEntailed r, negate (rwRefuted r), rwCorroborated r, rwNovel r ]

-- | Pareto dominance: @a@ dominates @b@ iff it is at least as good on every
-- reward coordinate and strictly better on at least one. A corroboration-heavy
-- and a novelty-heavy reward are /incomparable/ (neither dominates) — the correct
-- treatment of two objectives that trade off, and the thing a linear sum
-- destroys by forcing a ranking.
dominates :: Reward -> Reward -> Bool
dominates a b = and (zipWith (>=) ca cb) && or (zipWith (>) ca cb)
  where { ca = rewardCoordinates a; cb = rewardCoordinates b }

-- | The non-dominated set — the reward Pareto frontier over a candidate pool.
-- Scalarization is deferred: everything here is a legitimate optimum for /some/
-- trade-off between the coordinates, and choosing among them is the external
-- decision the design refuses to bake into a weight.
paretoFrontier :: [Reward] -> [Reward]
paretoFrontier rs = [ r | r <- rs, not (any (`dominates` r) rs) ]

--------------------------------------------------------------------------------
-- Admissibility
--------------------------------------------------------------------------------

-- | A self-check on the reward function: does it satisfy the constraints the
-- design requires of it?
--
-- Exists so the constraints are executable. A weight table that violates them
-- compiles, runs, and quietly trains the wrong thing.
data Admissibility = Admissibility
  { adUncoveredIsZero    :: Bool
    -- ^ Uncovered claims must contribute exactly zero.
  , adRefutedIsNegative  :: Bool
    -- ^ Guessing must cost more than silence.
  , adConfirmedDominates :: Bool
    -- ^ Direct confirmation must be worth at least as much as inherited
    -- grounding, or the policy is rewarded for laundering claims through
    -- entailment instead of getting them checked.
  , adOverGenerationFree :: Bool
    -- ^ __Not an independent check, and not a failure.__ It holds exactly when
    -- 'adUncoveredIsZero' holds, because both say @wUncovered == 0@. Reported so
    -- the consequence travels with the requirement: the weight table that
    -- correctly refuses to penalise an uninstrumented domain is the same weight
    -- table under which emitting uncovered claims costs nothing. No reweighting
    -- separates them; only a denominator does, and 'rwYield' is it.
  , adAllOk              :: Bool
  }

admissibility :: Weights -> Admissibility
admissibility w =
  Admissibility
    { adUncoveredIsZero = z
    , adRefutedIsNegative = n
    , adConfirmedDominates = d
    , adOverGenerationFree = z
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
    , "  (consequence) over-generation is free: "
        ++ show (adOverGenerationFree a) ++ " -- see rwYield"
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
    , "  offered:    " ++ show (rwOffered r)
        ++ "  yield " ++ show (rwYield r)
    , "  corrob.:    " ++ show (rwCorroborated r)
        ++ "  (grounded claims via distinct derivations)"
    , "  novel:      " ++ show (rwNovel r)
        ++ "  (confirmed and not implied by the rest)"
    , "  spans:      grounded " ++ show (rwGroundedSpan r)
        ++ " of " ++ show (rwOfferedSpan r) ++ " drawn on"
        ++ ", share " ++ show (rwGroundedShare r)
    , "  coverage:   " ++ maybe "unknown (no source extent given)" show
        (rwSourceCoverage r)
    ]
