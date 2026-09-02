-- | Rational Speech Act reasoning: the probabilistic mapping from an utterance
-- to a distribution over readings.
--
-- Bayesian listener\/speaker reasoning over candidate readings, giving a graded
-- ranking before anything is offered for verification.
--
-- __This is not a verifier and must not be read as one.__ It ranks candidates by
-- how a rational speaker would have chosen among them; whether a candidate is
-- /true/ is settled later and elsewhere, by "NL2Proof.Verify.Oracle". Treating a
-- high pragmatic posterior as evidence would be exactly the self-agreement the
-- reward signal is built to exclude.
--
-- == The recursion
--
-- Standard, and implemented generically over any utterance and meaning types:
--
-- * @L0(m | u)@ — literal listener: prior, restricted to meanings the lexicon
--   says @u@ is compatible with.
-- * @S_k(u | m)@ — speaker: softmax over @log L_{k-1}(m | u) - cost(u)@, scaled
--   by rationality @alpha@.
-- * @L_k(m | u)@ — pragmatic listener: Bayes over @S_k@ against the prior.
--
-- Depth @k = 0@ is the literal listener. Each further level reasons about the
-- level below. 'pragmaticListener' takes @k@ explicitly rather than fixing it,
-- because a latency budget decides how deep it can afford to go — @k = 1@ by
-- default, with escalation only when the candidate set is genuinely contested.
--
-- == What is stipulated
--
-- The prior and the costs are __stipulated, not learned__. There is no corpus
-- here. A prior favouring surface scope is a modelling assumption, and the
-- honest way to hold it is as a stated heuristic that the disagreement log can
-- later contradict — not as a fact about English. 'RSAModel' therefore takes them
-- as fields rather than hard-coding them, and 'surfaceScopePrior' is documented
-- as the assumption it is.
module NL2Proof.Stage2.RSA
  ( -- * Model
    RSAModel(..)
  , rsaModel
    -- * The recursion
  , literalListener
  , speaker
  , speakerFrom
  , listenerTable
  , pragmaticListener
    -- * Priors and costs
  , surfaceScopePrior
  , complexityCost
  , uniformPrior
  , noCost
    -- * Diagnostics
  , sharpening
  ) where

import qualified Data.Map.Strict as M

import NL2Proof.Semantics.Lambda (Term)
import NL2Proof.Stage2.Alternatives (scopeSignature)
import NL2Proof.Stage2.Distribution

--------------------------------------------------------------------------------
-- Model
--------------------------------------------------------------------------------

-- | An RSA model over utterances @u@ and meanings @m@.
--
-- Generic in both, so the same recursion serves a scope-ambiguity model, a
-- reference game, or a word-sense model. The test suite exercises it on the
-- classic reference game precisely because that has a known published answer.
data RSAModel u m = RSAModel
  { rsaUtterances :: [u]
  , rsaMeanings   :: [m]
  , rsaLexicon    :: u -> m -> Double
    -- ^ Literal compatibility in @[0,1]@. @0@ means "cannot mean this"; @1@
    -- means fully compatible. Graded values are allowed, which is how a soft
    -- lexicon differs from a boolean one.
  , rsaPrior      :: m -> Double
    -- ^ Prior over meanings. Stipulated — see the module note.
  , rsaCost       :: u -> Double
    -- ^ Utterance cost. Higher cost makes a speaker less likely to choose it.
  , rsaAlpha      :: Double
    -- ^ Speaker rationality. @0@ makes the speaker uniform; larger sharpens
    -- toward the utterance that best conveys the meaning.
  }

-- | Model with a uniform prior, no costs, and @alpha = 1@.
rsaModel :: [u] -> [m] -> (u -> m -> Double) -> RSAModel u m
rsaModel us ms compat =
  RSAModel
    { rsaUtterances = us
    , rsaMeanings = ms
    , rsaLexicon = compat
    , rsaPrior = uniformPrior
    , rsaCost = noCost
    , rsaAlpha = 1
    }

--------------------------------------------------------------------------------
-- The recursion
--------------------------------------------------------------------------------

-- | @L0(m | u)@ — the prior restricted to compatible meanings, renormalized.
--
-- 'Nothing' when the utterance is compatible with nothing in the meaning set,
-- which is a real condition worth surfacing rather than smoothing over: it says
-- the candidate set is wrong, not that the answer is uncertain.
literalListener :: Ord m => RSAModel u m -> u -> Maybe (Dist m)
literalListener model u =
  fromWeights [ (m, rsaLexicon model u m * rsaPrior model m) | m <- rsaMeanings model ]

-- | @S_k(u | m)@ — softmax over how well each utterance conveys @m@ to the
-- listener one level down, minus its cost.
--
-- Utterances the level-below listener assigns zero probability to are dropped
-- rather than given @log 0 = -inf@, which keeps the softmax finite.
speaker :: (Ord u, Ord m) => Int -> RSAModel u m -> m -> Maybe (Dist u)
speaker k model = speakerFrom model (listenerTable (k - 1) model)

-- | The lower-level listener, one entry per utterance, with each distribution
-- pre-converted to a 'M.Map' for @O(log n)@ lookup.
--
-- Hoisting this out of 'speaker' is a real fix, not tidying. 'pragmaticListener'
-- calls 'speaker' once per meaning, and the naive version rebuilt the entire
-- lower-level listener inside every one of those calls, giving
-- @O(|M|^2 |U|)@ listener evaluations with a further linear 'prob' scan inside.
-- At 256 models that was slow enough to hang an interpreted run. Computed once,
-- it is @O(|M| |U|)@ with @log|M|@ lookups, which is what makes a depth budget
-- a real choice rather than a formality.
listenerTable :: (Ord u, Ord m) => Int -> RSAModel u m -> [(u, M.Map m Double)]
listenerTable k model =
  [ (u, toMap d) | u <- rsaUtterances model, Just d <- [listenerAt k model u] ]

speakerFrom
  :: (Ord u, Ord m) => RSAModel u m -> [(u, M.Map m Double)] -> m -> Maybe (Dist u)
speakerFrom model table m = softmax (rsaAlpha model) scored
  where
    scored =
      [ (u, log p - rsaCost model u)
      | (u, tbl) <- table
      , Just p <- [M.lookup m tbl]
      , p > 0
      ]

-- | @L_k(m | u)@ — Bayes: prior times the probability that a speaker with
-- meaning @m@ would have chosen @u@.
pragmaticListener :: (Ord u, Ord m) => Int -> RSAModel u m -> u -> Maybe (Dist m)
pragmaticListener k model u
  | k <= 0    = literalListener model u
  | otherwise =
      fromWeights
        [ (m, rsaPrior model m * pu)
        | m <- rsaMeanings model
        , Just sd <- [speakerFrom model table m]
        , let pu = prob sd u
        , pu > 0
        ]
  where
    -- Built once for the whole comprehension, not once per meaning.
    table = listenerTable (k - 1) model

-- | Internal dispatch so 'speaker' and 'pragmaticListener' can recurse through
-- each other without duplicating the base case.
listenerAt :: (Ord u, Ord m) => Int -> RSAModel u m -> u -> Maybe (Dist m)
listenerAt k model
  | k <= 0    = literalListener model
  | otherwise = pragmaticListener k model

--------------------------------------------------------------------------------
-- Priors and costs
--------------------------------------------------------------------------------

uniformPrior :: m -> Double
uniformPrior _ = 1

noCost :: u -> Double
noCost _ = 0

-- | Prior favouring the reading whose quantifier prefix matches surface order.
--
-- __This is a stated heuristic, not a fact about English.__ Surface scope is the
-- more frequent reading across many constructions, but the preference is
-- construction-sensitive and the strength here (@bias@) is stipulated. It is a
-- field of 'RSAModel' rather than baked into the recursion precisely so it can be
-- replaced when the disagreement log says it is wrong.
--
-- @surfaceScopePrior bias surface@ gives weight @bias@ to any reading whose scope
-- signature equals @surface@'s, and @1@ to the rest.
surfaceScopePrior :: Double -> Term -> Term -> Double
surfaceScopePrior bias surface candidate
  | scopeSignature candidate == scopeSignature surface = bias
  | otherwise                                          = 1

-- | Cost proportional to a size measure — the usual stand-in for "longer and
-- more complex utterances are dispreferred".
complexityCost :: Double -> (u -> Int) -> u -> Double
complexityCost perUnit size u = perUnit * fromIntegral (size u)

--------------------------------------------------------------------------------
-- Diagnostics
--------------------------------------------------------------------------------

-- | Entropy reduction from the literal to the pragmatic listener, in bits.
--
-- Positive means the pragmatic layer sharpened the distribution; zero means it
-- earned nothing. Worth measuring rather than assuming: CRSA's own real-dialogue
-- results barely beat single-turn RSA, so a pragmatic layer that adds depth
-- without adding information is a live possibility, not a hypothetical.
sharpening :: (Ord u, Ord m) => Int -> RSAModel u m -> u -> Maybe Double
sharpening k model u = do
  l0 <- literalListener model u
  lk <- pragmaticListener k model u
  pure (entropy l0 - entropy lk)
