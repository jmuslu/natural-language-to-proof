{-# LANGUAGE DataKinds #-}
module PresupposedConfirm where

import NL2Proof.Verify.ClaimKind
import NL2Proof.Verify.Oracle

-- Presupposed content has no public promotion path to asserted confirmation.
promoted :: Oracle -> Claim 'Presupposed -> Maybe Confirmed
promoted oracle presupposed = confirm oracle presupposed
