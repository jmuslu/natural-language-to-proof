module FusedOracleUpdate where

import NL2Proof.Fusion

forged :: Fused -> Fused
forged fused = fused { fusedOracles = ["invented-oracle"] }
