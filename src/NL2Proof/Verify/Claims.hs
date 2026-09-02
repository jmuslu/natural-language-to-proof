-- | The verification stage's claim table: atomic claims with their derivations
-- retained in full.
--
-- == Salvaged, and re-scoped
--
-- This is what used to be @Collapse.Provenance@ on the @provenance-mode@ branch.
-- The code survives the refactor almost unchanged; what changed is its
-- position. It was one of three alternative /dispositions/ a caller could pick.
-- It is now a mandatory /stage/, because the pipeline downstream of it needs
-- exactly what it provides:
--
-- * an external oracle can reverse an earlier answer, so the derivation record
--   has to still be there when it does ("NL2Proof.Genealogy")
-- * 'NL2Proof.Fusion' deduplicates, and a deduplication performed before
--   verification would destroy that record
--
-- So retention is no longer a preference to be traded against compactness. It is
-- a precondition for the stage after next.
--
-- == Claim identity versus claim derivation
--
-- 'factClaim' says /what/ is claimed and 'factProv' says /how it was derived/.
-- Two facts may share a claim and remain separate facts — 'factId' is what makes
-- them distinguishable objects, and without it a @['Fact']@ would be a set of
-- claims and the whole point would be lost.
--
-- Detecting convergence and merging on convergence are different operations, and
-- only the first belongs here. 'convergentClaims' surfaces them;
-- "NL2Proof.Fusion" merges them, later, and only once an oracle has spoken.
--
-- == Two granularities of retraction, and why both are kept
--
-- 'retractSource' drops every fact whose derivation touches a source. That is
-- __source-level and coarse__: it answers "what if this document is unreliable".
--
-- 'NL2Proof.Genealogy.retract' answers a different and sharper question: "this
-- specific oracle answer reversed — what lost its support?" It is node-level, and
-- it is precise because it recomputes grounded support rather than following
-- edges downward.
--
-- Both are wanted. A retracted /document/ and a reversed /measurement/ are
-- different events, and conflating them would make one of the two answers wrong.
-- 'genealogyOf' is the bridge: it turns this table into the graph the precise
-- version operates on.
module NL2Proof.Verify.Claims
  ( -- * Claims
    Fact(..)
  , ClaimTable(..)
  , claimsOf
  , retainingStrategy
    -- * Queries
  , factSources
  , factSpan
  , factDerivation
  , sourcesOf
  , factsFrom
  , convergentClaims
    -- * Source-level retraction (coarse)
  , retractSource
  , retractionImpact
    -- * Bridge to the genealogy (precise)
  , genealogyOf
    -- * Rendering
  , renderFact
  , renderClaimTable
  ) where

import Data.List (nub, sort)

import NL2Proof.Collapse.Class
import NL2Proof.DRT.Canonical
import NL2Proof.DRT.Types
import NL2Proof.Genealogy
import NL2Proof.Provenance
import NL2Proof.Verify.Oracle

--------------------------------------------------------------------------------
-- Claims
--------------------------------------------------------------------------------

-- | One atomic claim together with the derivation that produced it.
data Fact = Fact
  { factId    :: Int
    -- ^ Position in the original condition order. Stable, and unique per fact
    -- even when claims coincide.
  , factClaim :: CanonCond
    -- ^ /What/ is claimed, provenance-free. Shared by convergent facts.
  , factProv  :: Prov
    -- ^ /How/ it was derived: the full derivation tree, retained.
  }
  deriving (Eq, Show)

-- | The retained claim table for a selected reading.
data ClaimTable = ClaimTable
  { ctUniverse  :: [CRef]
  , ctFacts     :: [Fact]
    -- ^ __Not deduplicated.__ Order preserved. This is load-bearing: see the
    -- module header.
  , ctRationale :: String
    -- ^ Carried through from the 'Selection', so the record of /why this
    -- reading/ survives alongside the record of how each fact was derived.
  }
  deriving (Eq, Show)

-- | Flatten the chosen DRS into facts, pairing each condition's canonical claim
-- with its untouched provenance tree.
--
-- The two traversals are deliberately parallel rather than fused:
-- 'canonicalize' strips provenance and 'drsConditionProvs' collects it, and
-- zipping them re-associates the two halves. Both walk conditions in the same
-- order, and neither reorders or drops anything, so the zip is total on both
-- sides.
claimsOf :: Selection -> ClaimTable
claimsOf sel =
  ClaimTable
    { ctUniverse = canonUniverse canon
    , ctFacts =
        [ Fact i claim prov
        | (i, claim, prov) <- zip3 [0 ..] (flattenClaims canon) provs
        ]
    , ctRationale = selRationale sel
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

retainingStrategy :: CollapseStrategy ClaimTable
retainingStrategy =
  CollapseStrategy
    { strategyName = "verification"
    , strategyDoc =
        "Derivation-preserving. Retains the full how-provenance tree for every"
          ++ " atomic claim and performs NO deduplication: two independent"
          ++ " derivations of the same claim remain two distinct facts. That is"
          ++ " what makes retraction possible at all, and it is a precondition"
          ++ " for the fusion stage rather than a preference. Output is strictly"
          ++ " larger than the fused form."
    , applyStrategy = claimsOf
    }

--------------------------------------------------------------------------------
-- Queries
--------------------------------------------------------------------------------

factSources :: Fact -> [SourceId]
factSources = provSources . factProv

factSpan :: Fact -> Maybe Span
factSpan = provSpan . factProv

-- | The fact's derivation as an indented tree — the @how@, in full.
factDerivation :: Fact -> String
factDerivation = renderProvTree . factProv

sourcesOf :: ClaimTable -> [SourceId]
sourcesOf = sort . nub . concatMap factSources . ctFacts

factsFrom :: SourceId -> ClaimTable -> [Fact]
factsFrom s ct = [f | f <- ctFacts ct, s `elem` factSources f]

-- | Claims supported by more than one derivation.
--
-- These are exactly the facts fusion will merge — later, and only after an
-- oracle has spoken. Surfacing them here rather than merging them is what keeps
-- "two derivations agree" distinguishable from "one derivation said it once",
-- and that distinction is the one safe use of a provability-style signal (see
-- 'NL2Proof.Genealogy.convergentNodes').
convergentClaims :: ClaimTable -> [(CanonCond, [Fact])]
convergentClaims ct =
  [ (claim, group)
  | claim <- nub (map factClaim (ctFacts ct))
  , let group = [f | f <- ctFacts ct, factClaim f == claim]
  , length group > 1
  ]

--------------------------------------------------------------------------------
-- Source-level retraction
--------------------------------------------------------------------------------

-- | Drop every fact whose derivation touches the given source.
--
-- Coarse by design: it answers "this document turned out to be unreliable",
-- where the right response really is to distrust everything that used it. A
-- derivation that /used/ a retracted source is not trustworthy just because some
-- other derivation of the same claim exists — that other derivation is a
-- separate 'Fact' and survives on its own.
--
-- For the sharper question — one oracle answer reversed — use
-- 'NL2Proof.Genealogy.retract' via 'genealogyOf'.
retractSource :: SourceId -> ClaimTable -> ClaimTable
retractSource s ct =
  ct { ctFacts = [f | f <- ctFacts ct, s `notElem` factSources f] }

-- | @(before, after, lost)@ fact counts for retracting a source. For reporting
-- how much of a conclusion rested on one document.
retractionImpact :: SourceId -> ClaimTable -> (Int, Int, Int)
retractionImpact s ct = (before, after, before - after)
  where
    before = length (ctFacts ct)
    after = length (ctFacts (retractSource s ct))

--------------------------------------------------------------------------------
-- Bridge to the genealogy
--------------------------------------------------------------------------------

-- | Turn a claim table into a genealogy, asking the oracle about each fact.
--
-- Every fact becomes a __premise__ node carrying the oracle's verdict. Derived
-- nodes are added afterwards by whatever does the deriving; this function only
-- establishes the grounded floor.
--
-- Note what is deliberately /not/ done: convergent facts are not merged, so a
-- claim with two derivations becomes two nodes with the same 'nodeClaim'. That
-- is what lets 'NL2Proof.Genealogy.convergentNodes' see the convergence and what
-- lets one of the two be retracted without the other.
genealogyOf :: Oracle -> ClaimTable -> Genealogy
genealogyOf o ct =
  foldl add emptyGenealogy (zip (map NodeId [0 ..]) (ctFacts ct))
  where
    add g (i, f) =
      addJustification (premise i "oracle-premise")
        (addNode (Node i (factClaim f) (factProv f)) (check o (factClaim f)) g)

--------------------------------------------------------------------------------
-- Rendering
--------------------------------------------------------------------------------

renderFact :: Fact -> String
renderFact f =
  "#" ++ show (factId f) ++ "  " ++ renderCanonCond (factClaim f)
    ++ "\n      sources: " ++ show (factSources f)
    ++ "\n      span:    " ++ maybe "?" show (factSpan f)
    ++ "\n      derived: " ++ renderProvInline (factProv f)

renderClaimTable :: ClaimTable -> String
renderClaimTable ct =
  unlines $
    [ "claim table (verification stage)"
    , "  universe:  " ++ unwords (map show (ctUniverse ct))
    , "  facts:     " ++ show (length (ctFacts ct)) ++ " (no deduplication)"
    , "  sources:   " ++ show (sourcesOf ct)
    , "  rationale: " ++ ctRationale ct
    , ""
    ]
      ++ map renderFact (ctFacts ct)
      ++ case convergentClaims ct of
           [] -> ["", "  no convergent claims"]
           cs ->
             "" : "  convergent claims (fusion will merge these, after the oracle):"
               : [ "    " ++ renderCanonCond claim ++ " <- "
                     ++ show (length g) ++ " derivations from "
                     ++ show (sort (nub (concatMap factSources g)))
                 | (claim, g) <- cs
                 ]
