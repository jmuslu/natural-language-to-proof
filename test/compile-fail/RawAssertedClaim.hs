{-# LANGUAGE DataKinds #-}
module RawAssertedClaim where
import NL2Proof.Verify.ClaimKind
leaked :: Claim 'Embedded -> Claim 'Asserted
leaked = assertedClaim . claimCond
