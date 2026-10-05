{-# LANGUAGE DataKinds #-}
module PresupposedConfirm where

import NL2Proof.Verify.ClaimKind
import NL2Proof.Verify.Oracle

-- Presupposed content must also become a candidate before an oracle sees it.
promoted :: Oracle -> Claim 'Presupposed -> Maybe Confirmed
promoted oracle presupposed = confirm oracle presupposed
