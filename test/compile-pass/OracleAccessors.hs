module OracleAccessors where

import NL2Proof.DRT.Canonical
import NL2Proof.Fusion
import NL2Proof.Verify.Oracle

-- Accessors keep their original types; certified values can still be inspected.
inspectToken :: Confirmed -> (CanonCond, String)
inspectToken token = (confClaim token, confOracle token)

inspectFused :: Fused -> ([CanonCond], [String], Int)
inspectFused fused = (fusedClaims fused, fusedOracles fused, fusedDropped fused)

removeCertifiedClaim :: CanonCond -> Fused -> Fused
removeCertifiedClaim = withoutClaim
