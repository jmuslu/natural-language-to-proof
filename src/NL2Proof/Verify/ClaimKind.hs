{-# LANGUAGE DataKinds #-}
{-# LANGUAGE KindSignatures #-}

-- | Claims indexed by how the text commits to them: 'Asserted', 'Reported'
-- (attributed to someone under an attitude verb), 'Presupposed' (the
-- complement of a factive verb), or 'Embedded' (mentioned inside a negation,
-- conditional or disjunction, and so not committed to at all).
--
-- The index is a phantom type (@DataKinds@, @KindSignatures@; both ship with
-- GHC). "NL2Proof.Verify.Oracle".'NL2Proof.Verify.Oracle.confirm' accepts only
-- the asserted index, so handing it a reported claim is a compile error, not a
-- runtime check. The only way from another index to 'Asserted' is
-- 'asCandidate', which yields an /unconfirmed/ top-level candidate: it still
-- has to go through an oracle like anything else.
--
-- The constructor is not exported, so the index of a claim cannot be changed
-- by re-wrapping it.
module NL2Proof.Verify.ClaimKind
  ( ClaimKind(..)
  , Claim
  , claimCond
  , assertedClaim
  , reportedClaim
  , presupposedClaim
  , embeddedClaim
  , asCandidate
  ) where

import NL2Proof.DRT.Canonical

-- | How the text commits to a claim.
data ClaimKind = Asserted | Reported | Presupposed | Embedded

-- | A canonical claim with its commitment index.
newtype Claim (k :: ClaimKind) = MkClaim CanonCond
  deriving (Eq, Ord, Show)

-- | The claim's content. Reading it never changes its index.
claimCond :: Claim k -> CanonCond
claimCond (MkClaim c) = c

-- | A claim the text asserts.
assertedClaim :: CanonCond -> Claim 'Asserted
assertedClaim = MkClaim

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

-- | Promote a reported or presupposed claim to a top-level /candidate/. That
-- is all it does: the result is unconfirmed and can only become
-- 'NL2Proof.Verify.Oracle.Confirmed' through an oracle. Being reported is not
-- evidence.
asCandidate :: Claim k -> Claim 'Asserted
asCandidate (MkClaim c) = MkClaim c
