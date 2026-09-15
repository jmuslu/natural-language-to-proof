module FusedClaimUpdate where

import NL2Proof.DRT.Canonical
import NL2Proof.Fusion

forged :: Fused -> Fused
forged fused = fused { fusedClaims = [CanPred "unchecked" []] }
