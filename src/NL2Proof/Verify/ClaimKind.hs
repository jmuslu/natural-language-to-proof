{-# LANGUAGE DataKinds #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE RoleAnnotations #-}

-- | Claims indexed by how the text commits to them: 'Asserted', 'Reported'
-- (attributed to someone under an attitude verb), 'Presupposed' (the
-- complement of a factive verb), or 'Embedded' (mentioned inside a negation,
-- conditional or disjunction, and so not committed to at all).
--
-- "NL2Proof.Verify.Oracle".'NL2Proof.Verify.Oracle.confirm' accepts only the
-- asserted index. 'assertedClaims' is the only admission path: it extracts
-- whole root conditions from a supplied DRS, never their nested contents.
-- Bare hypotheses may be inspected with the oracle's @check@ without creating
-- confirmation tokens.
--
-- The constructor is not exported, so the index of a claim cannot be changed
-- by re-wrapping it. Its nominal role also forbids @Data.Coerce@ reindexing.
-- This witnesses structural top-levelness in the supplied DRS, not source
-- authenticity: callers can author a DRS, just as they can author text.
module NL2Proof.Verify.ClaimKind
  ( ClaimKind(..)
  , Claim
  , claimCond
  , assertedClaims
  , reportedClaim
  , presupposedClaim
  , embeddedClaim
  ) where

import NL2Proof.DRT.Canonical
import NL2Proof.DRT.Types
import NL2Proof.Provenance (Prov)

-- | How the text commits to a claim.
data ClaimKind = Asserted | Reported | Presupposed | Embedded

-- | A canonical claim with its commitment index.
type role Claim nominal
newtype Claim (k :: ClaimKind) = MkClaim CanonCond
  deriving (Eq, Ord, Show)

-- | The claim's content. Reading it never changes its index.
claimCond :: Claim k -> CanonCond
claimCond (MkClaim c) = c

-- | Structural witnesses for the whole, top-level non-presupposed conditions.
-- Canonicalize the complete box once, preserving shared referent identities.
-- In particular a negative claim stays negative and a rule stays a rule.
assertedClaims :: DRS -> [(Claim 'Asserted, Prov)]
assertedClaims d =
  [ (MkClaim k, condProv c)
  | (c, k) <- zip (drsConds d) (canonConds (canonicalize d))
  , case c of CPresup _ _ -> False; _ -> True
  ]

-- | A claim the text attributes to someone. Built by
-- "NL2Proof.Verify.Reported" from attitude boxes.
reportedClaim :: CanonCond -> Claim 'Reported
reportedClaim = MkClaim

-- | A claim the text presupposes (a factive complement).
presupposedClaim :: CanonCond -> Claim 'Presupposed
presupposedClaim = MkClaim

-- | A condition the text mentions but does not assert: one found inside a
-- top-level negation, conditional or disjunction (@red(cat)@ in @"The cat is
-- not red"@ or @"If the cat is red, ..."@). Built by
-- "NL2Proof.Verify.Reported".'NL2Proof.Verify.Reported.splitClaims'.
embeddedClaim :: CanonCond -> Claim 'Embedded
embeddedClaim = MkClaim
