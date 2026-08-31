-- | Stage 2 end to end: a Stage 1 reading in, a ranked distribution over
-- readings out.
--
-- Order of operations, and the separation matters:
--
-- 1. __Generate__ ("NL2Proof.Stage2.Alternatives") — enumerate the readings
--    Stage 1 declined to produce. Discrete; commits to nothing.
-- 2. __Fingerprint__ ("NL2Proof.Stage2.Fingerprint") — describe each reading
--    structurally, so readings can be compared without word vectors.
-- 3. __Rank__ ("NL2Proof.Stage2.RSA") — a distribution over readings.
-- 4. __Hand off__ — the distribution feeds
--    'NL2Proof.Collapse.Class.selectBy'. Stage 2 does __not__ collapse; it
--    scores. Collapsing stays a logged decision in the collapse backend.
--
-- == Retracted: "RSA amplifies the prior"
--
-- What the implementation actually does on this fragment, from a bias sweep
-- rather than from expectation:
--
-- @
-- surfaceBias   L0(surface)   L1(surface)   sharpening
--         1.0         0.500         0.500      0.0000 bits
--         1.5         0.600         0.641      0.0291 bits
--         2.0         0.667         0.731      0.0776 bits
--         4.0         0.800         0.886      0.2104 bits
-- @
--
-- The pragmatic layer does sharpen — but every bit of it derives from the
-- prior's asymmetry propagating through the speaker model. __At @bias = 1.0@ the
-- sharpening is exactly zero.__
--
-- __That generalisation was wrong, and this model is the reason why.__ The
-- sweep above only shows that /in this setup/ the prior is the sole asymmetry.
-- It is, because the lexicon here is symmetric by construction: the ambiguous
-- form is compatible with every reading at weight 1, and each paraphrase pins
-- exactly one, at equal cost. With nothing else to differentiate readings, only
-- the prior can. That is a property of the construction, not of RSA.
--
-- The reference-game test disproves the general claim on its own: there the
-- implicature appears under a __uniform__ prior, driven entirely by an
-- asymmetric lexicon.
--
-- == What was actually missing: informativity
--
-- RSA's engine is informativity, and this pipeline gave the recursion no way to
-- measure it. 'NL2Proof.Stage2.Model' supplies it, and with real semantics the
-- asymmetry is __derived__:
--
-- @
-- reading                      truth set   informativity
-- forall x exists y (surface)   137\/256      0.902 bits
-- exists y forall x (inverse)   119\/256      1.105 bits
-- @
--
-- The inverse reading __entails__ the surface reading and not conversely, checked
-- over all 256 models rather than assumed. A world-based RSA over that then
-- produces a genuine scalar implicature with a uniform prior:
--
-- @
-- paraphraseCost   L0(inverse)   L1(inverse)
--            0.0         0.869         0.808
--            1.0         0.869         0.835
--            2.0         0.869         0.853
-- @
--
-- Hearing the ambiguous form lowers the probability that the __stronger__ reading
-- was meant, because a speaker who meant it could have said so unambiguously.
-- The implicature weakens as the paraphrase gets more expensive, which is the
-- right direction and a useful sanity check.
--
-- Note the structural consequence of the entailment: since inverse @|=@ surface,
-- the ambiguous sentence is logically __equivalent__ to the surface reading, so
-- @P(surface | ambiguous) = 1@ necessarily. The live question is only whether the
-- strengthened reading also holds. Scope "ambiguity" of this shape is therefore
-- scalar strengthening, not a choice between exclusive alternatives — which is
-- why the mutually-exclusive framing this module started with could not have
-- worked.
--
-- What survives from the original note: for the __coupling__ case all readings
-- share a quantifier signature and the surface prior treats them identically, so
-- sharpening there is exactly @0@ and the fingerprint kernel does the work
-- instead ('NL2Proof.Stage2.Fingerprint.contentSimilarity' separates them at
-- @0.575@). Two mechanisms, two jobs.
module NL2Proof.Stage2.Pipeline
  ( -- * Readings
    Reading(..)
  , Utterance(..)
  , Stage2Result(..)
    -- * Running
  , runStage2
  , runStage2On
    -- * Reporting
  , renderStage2Result
  ) where

import Data.List (intercalate)

import NL2Proof.Provenance
import NL2Proof.Semantics.Lambda
import NL2Proof.Stage2.Alternatives
import NL2Proof.Stage2.Distribution
import NL2Proof.Stage2.Fingerprint
import NL2Proof.Stage2.RSA
import NL2Proof.Syntax.Lexicon
import NL2Proof.Trace

--------------------------------------------------------------------------------
-- Readings
--------------------------------------------------------------------------------

-- | One candidate reading, with everything needed to rank and explain it.
data Reading = Reading
  { readingIndex     :: Int
    -- ^ Position in the candidate list. Distributions range over these rather
    -- than over 'Term's, so no 'Ord' is needed on 'Fingerprint'.
  , readingTerm      :: Term
  , readingScope     :: String
    -- ^ Quantifier-prefix signature. What actually distinguishes scope readings.
  , readingPrint     :: Fingerprint
  , readingIsSurface :: Bool
    -- ^ Is this the reading Stage 1 produced?
  }

-- | Utterances in the RSA model.
--
-- The ambiguous form is what was actually said; the unambiguous paraphrases are
-- the alternatives a speaker could have used instead, which is what gives RSA
-- something to reason about at all.
data Utterance
  = Ambiguous
  | Unambiguous Int
  deriving (Eq, Ord, Show)

data Stage2Result = Stage2Result
  { s2Readings   :: [Reading]
  , s2Literal    :: Maybe (Dist Int)
    -- ^ @L0@: the prior restricted to compatible readings.
  , s2Pragmatic  :: Maybe (Dist Int)
    -- ^ @L1@. On this fragment, equal to 's2Literal' — see the module note.
  , s2Sharpening :: Maybe Double
    -- ^ Entropy reduction from @L0@ to @L1@, in bits. Zero here, deliberately
    -- surfaced rather than suppressed.
  , s2Trace      :: Trace
  }

--------------------------------------------------------------------------------
-- Running
--------------------------------------------------------------------------------

-- | Run Stage 2 over a Stage 1 term using the fragment lexicon.
runStage2 :: Prov -> Term -> Stage2Result
runStage2 = runStage2On fragmentLexicon

-- | Run Stage 2 with an explicit lexicon, which supplies the modifier test that
-- coupling generation needs.
runStage2On :: Lexicon -> Prov -> Term -> Stage2Result
runStage2On lexicon prov surface =
  Stage2Result
    { s2Readings = readings
    , s2Literal = l0
    , s2Pragmatic = l1
    , s2Sharpening = sharpening 1 model Ambiguous
    , s2Trace = diagnostics
    }
  where
    -- Stage 1's lexicon already answers "does this word have an N/N reading",
    -- which is exactly the test coupling generation needs.
    isModifier = isModifierWord lexicon

    cands = alternatives isModifier surface

    readings =
      [ Reading
          { readingIndex = i
          , readingTerm = t
          , readingScope = scopeSignature t
          , readingPrint = fingerprint t
          , readingIsSurface = alphaEq t surface
          }
      | (i, t) <- zip [0 ..] cands
      ]

    indices = map readingIndex readings
    termAt i = maybe surface readingTerm (lookupReading i)
    lookupReading i = case [r | r <- readings, readingIndex r == i] of
      (r : _) -> Just r
      []      -> Nothing

    -- Ambiguous is compatible with every reading. Each paraphrase pins exactly
    -- one. This is the symmetry described in the module note.
    compat Ambiguous _         = 1
    compat (Unambiguous j) i    = if i == j then 1 else 0

    model =
      RSAModel
        { rsaUtterances = Ambiguous : map Unambiguous indices
        , rsaMeanings = indices
        , rsaLexicon = compat
        , rsaPrior = \i -> surfaceScopePrior surfaceBias surface (termAt i)
        , rsaCost = utteranceCost
        , rsaAlpha = 1
        }

    -- Stipulated. Named and exposed here rather than buried so it is obvious
    -- what is doing the work.
    surfaceBias = 2.0

    -- Paraphrases are marked forms, so they cost more than just saying it. The
    -- value is stipulated too, and because it is uniform across paraphrases it
    -- cannot break the symmetry.
    utteranceCost Ambiguous       = 0
    utteranceCost (Unambiguous _) = 1

    l0 = literalListener model Ambiguous
    l1 = pragmaticListener 1 model Ambiguous

    diagnostics
      | length readings <= 1 = mempty
      | otherwise =
          flag
            Diagnostic
              { diagKind = ScopeAmbiguity
              , diagMsg =
                  show (length readings) ++ " readings generated: "
                    ++ intercalate " | " [readingScope r | r <- readings]
              , diagProv = prov
              }

--------------------------------------------------------------------------------
-- Reporting
--------------------------------------------------------------------------------

renderStage2Result :: Stage2Result -> String
renderStage2Result r =
  unlines $
    [ "readings: " ++ show (length (s2Readings r)) ]
      ++ [ "  [" ++ show (readingIndex x) ++ "]"
             ++ (if readingIsSurface x then " (surface)" else "          ")
             ++ "  " ++ readingScope x
             ++ "\n        " ++ pretty (readingTerm x)
         | x <- s2Readings r
         ]
      ++ [ "" ]
      ++ section "L0 (literal listener)" (s2Literal r)
      ++ section "L1 (pragmatic listener)" (s2Pragmatic r)
      ++ [ "sharpening: "
             ++ maybe "n/a" (\d -> show (roundTo 4 d) ++ " bits") (s2Sharpening r)
         , ""
         , renderTrace (s2Trace r)
         ]
  where
    section label Nothing  = [label ++ ": (none)"]
    section label (Just d) = (label ++ ":") : lines (renderDist showIdx d)
    showIdx i = "reading " ++ show i

    roundTo :: Int -> Double -> Double
    roundTo n x = fromIntegral (round (x * f) :: Integer) / f
      where f = 10 ^^ n
