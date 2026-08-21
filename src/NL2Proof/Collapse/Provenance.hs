-- | __provenance-mode__ collapse: derivation-preserving.
--
-- The derivation path matters, not just the resulting proposition.
--
-- > Two claims that happen to collapse to the same proposition right now must
-- > remain independently traceable back to their source, in case one source is
-- > later retracted or found unreliable.
--
-- That sentence from ARCHITECTURE.md is the entire specification of this module,
-- and 'retractSource' is the reason it is a specification rather than a
-- preference. Retraction is only possible if the facts were never merged. So
-- this collapse __does not deduplicate__, and that is the one thing it must
-- never be "optimized" into doing.
--
-- == Relationship to truth-mode
--
-- Both modes run the same upstream pipeline and both use
-- "NL2Proof.DRT.Canonical". They use it differently:
--
-- * @truth-mode@ uses the canonical form as its /output/ — collapse equal
--   propositions into one.
-- * this module uses it as claim /identity/ only — 'factClaim' says /what/ is
--   claimed, 'factProv' says /how it was derived/. Two facts may share a
--   'factClaim' and remain separate 'Fact's. Detecting convergence
--   ('convergentClaims') and merging on convergence are different operations,
--   and only the first belongs here.
--
-- @how@-provenance (the full derivation tree) is strictly more informative than
-- @why@-provenance (just which sources could have produced the result). This
-- module keeps the former; truth-mode keeps only the latter.
module NL2Proof.Collapse.Provenance
  ( -- * Output
    Fact(..)
  , ProvenanceForm(..)
    -- * Collapse
  , collapseProvenance
  , provenanceStrategy
    -- * Provenance queries
  , factSources
  , factSpan
  , factDerivation
  , sourcesOf
  , factsFrom
  , convergentClaims
    -- * Retraction
  , retractSource
  , retractionImpact
    -- * Rendering
  , renderFact
  , renderProvenanceForm
  ) where

import Data.List (nub, sort)

import NL2Proof.Collapse.Class
import NL2Proof.DRT.Canonical
import NL2Proof.DRT.Types
import NL2Proof.Provenance

--------------------------------------------------------------------------------
-- Output
--------------------------------------------------------------------------------

-- | One atomic claim together with the derivation that produced it.
--
-- 'factId' exists so two facts with an identical 'factClaim' are still
-- distinguishable objects. Without it, a @[Fact]@ would be a set of claims and
-- the whole point would be lost.
data Fact = Fact
  { factId    :: Int
    -- ^ Position in the original condition order. Stable, and unique per fact
    -- even when claims coincide.
  , factClaim :: CanonCond
    -- ^ /What/ is claimed, provenance-free. Shared by convergent facts.
  , factProv  :: Prov
    -- ^ /How/ it was derived: the full derivation tree, retained in full.
  }
  deriving (Eq, Show)

-- | The derivation-preserving collapse of a selected reading.
data ProvenanceForm = ProvenanceForm
  { pfUniverse :: [CRef]
  , pfFacts    :: [Fact]
    -- ^ __Not deduplicated.__ Order preserved. This is load-bearing.
  , pfRationale :: String
    -- ^ Carried through from the 'Selection', so the record of /why this
    -- reading/ survives alongside the record of how each fact was derived.
  }
  deriving (Eq, Show)

--------------------------------------------------------------------------------
-- Collapse
--------------------------------------------------------------------------------

-- | Flatten the chosen DRS into facts, pairing each condition's canonical claim
-- with its untouched provenance tree.
--
-- The two traversals are deliberately parallel rather than fused:
-- 'canonicalize' strips provenance and 'drsConditionProvs' collects it, and
-- zipping them re-associates the two halves. Both walk conditions in the same
-- order, and neither reorders or drops anything, so the zip is total on both
-- sides.
collapseProvenance :: Selection -> ProvenanceForm
collapseProvenance sel =
  ProvenanceForm
    { pfUniverse = canonUniverse canon
    , pfFacts =
        [ Fact i claim prov
        | (i, claim, prov) <- zip3 [0 ..] (flattenClaims canon) provs
        ]
    , pfRationale = selRationale sel
    }
  where
    chosen = selChosen sel
    canon = canonicalize chosen
    provs = drsConditionProvs chosen

-- | Claims in the same order 'drsConditionProvs' walks conditions: each node,
-- then its children.
flattenClaims :: Canonical -> [CanonCond]
flattenClaims (Canonical _ cs) = concatMap go cs
  where
    go c = c : case c of
      CanNot x   -> flattenClaims x
      CanImp a b -> flattenClaims a ++ flattenClaims b
      CanOr a b  -> flattenClaims a ++ flattenClaims b
      _          -> []

provenanceStrategy :: CollapseStrategy ProvenanceForm
provenanceStrategy =
  CollapseStrategy
    { strategyName = "provenance-mode"
    , strategyDoc =
        "Derivation-preserving. Retains the full how-provenance tree for every"
          ++ " atomic claim and performs NO deduplication: two independent"
          ++ " derivations of the same proposition remain two distinct facts."
          ++ " This is what makes retractSource possible. Nothing is discarded,"
          ++ " so the output is strictly larger than truth-mode's."
    , applyStrategy = collapseProvenance
    }

--------------------------------------------------------------------------------
-- Provenance queries
--------------------------------------------------------------------------------

-- | Sources appearing anywhere in this fact's derivation.
factSources :: Fact -> [SourceId]
factSources = provSources . factProv

-- | Source span this fact traces back to.
factSpan :: Fact -> Maybe Span
factSpan = provSpan . factProv

-- | The fact's derivation as an indented tree — the @how@, in full.
factDerivation :: Fact -> String
factDerivation = renderProvTree . factProv

sourcesOf :: ProvenanceForm -> [SourceId]
sourcesOf = sort . nub . concatMap factSources . pfFacts

-- | Facts whose derivation draws on the given source.
factsFrom :: SourceId -> ProvenanceForm -> [Fact]
factsFrom s pf = [f | f <- pfFacts pf, s `elem` factSources f]

-- | Claims supported by more than one independent derivation.
--
-- These are exactly the facts truth-mode would have merged. Surfacing them
-- rather than merging them is the difference between the two modes: independent
-- corroboration is /information/, and a mode that collapses it cannot tell
-- "two sources agree" from "one source said it once".
convergentClaims :: ProvenanceForm -> [(CanonCond, [Fact])]
convergentClaims pf =
  [ (claim, group)
  | claim <- nub (map factClaim (pfFacts pf))
  , let group = [f | f <- pfFacts pf, factClaim f == claim]
  , length group > 1
  ]

--------------------------------------------------------------------------------
-- Retraction
--------------------------------------------------------------------------------

-- | Drop every fact whose derivation touches the given source.
--
-- __This is the operation truth-mode cannot support.__ Once two assertions of a
-- proposition have been merged into one canonical condition, there is no way to
-- withdraw one of them; here, a claim corroborated by a second source survives
-- the retraction of the first.
--
-- Facts are dropped rather than re-derived: a derivation that /used/ a retracted
-- source is not trustworthy just because some other derivation of the same claim
-- exists. That other derivation is a separate 'Fact' and survives on its own.
retractSource :: SourceId -> ProvenanceForm -> ProvenanceForm
retractSource s pf =
  pf { pfFacts = [f | f <- pfFacts pf, s `notElem` factSources f] }

-- | @(before, after, lost)@ fact counts for retracting a source. For reporting
-- how much of a conclusion rested on one document.
retractionImpact :: SourceId -> ProvenanceForm -> (Int, Int, Int)
retractionImpact s pf = (before, after, before - after)
  where
    before = length (pfFacts pf)
    after = length (pfFacts (retractSource s pf))

--------------------------------------------------------------------------------
-- Rendering
--------------------------------------------------------------------------------

renderFact :: Fact -> String
renderFact f =
  "#" ++ show (factId f) ++ "  " ++ renderCanonCond (factClaim f)
    ++ "\n      sources: " ++ show (factSources f)
    ++ "\n      span:    " ++ maybe "?" show (factSpan f)
    ++ "\n      derived: " ++ renderProvInline (factProv f)

renderProvenanceForm :: ProvenanceForm -> String
renderProvenanceForm pf =
  unlines $
    [ "provenance-mode form"
    , "  universe:  " ++ unwords (map show (pfUniverse pf))
    , "  facts:     " ++ show (length (pfFacts pf)) ++ " (no deduplication)"
    , "  sources:   " ++ show (sourcesOf pf)
    , "  rationale: " ++ pfRationale pf
    , ""
    ]
      ++ map renderFact (pfFacts pf)
      ++ case convergentClaims pf of
           [] -> ["", "  no convergent claims"]
           cs ->
             "" : "  convergent claims (truth-mode would merge these):"
               : [ "    " ++ renderCanonCond claim ++ " <- "
                     ++ show (length g) ++ " independent derivations from "
                     ++ show (sort (nub (concatMap factSources g)))
                 | (claim, g) <- cs
                 ]
