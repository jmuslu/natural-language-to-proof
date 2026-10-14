{-# LANGUAGE DataKinds #-}
module ExtractedEmbeddedConfirm where
import NL2Proof.Verify.ClaimKind
import NL2Proof.Verify.Oracle
leaked :: Oracle -> Claim 'Embedded -> Maybe Confirmed
leaked oracle = confirm oracle . claimCond
