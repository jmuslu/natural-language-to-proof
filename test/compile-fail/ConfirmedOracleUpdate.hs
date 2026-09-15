module ConfirmedOracleUpdate where

import NL2Proof.Verify.Oracle

forged :: Confirmed -> Confirmed
forged token = token { confOracle = "different-oracle" }
