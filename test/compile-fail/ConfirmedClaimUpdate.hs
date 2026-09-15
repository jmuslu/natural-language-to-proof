module ConfirmedClaimUpdate where

import NL2Proof.DRT.Canonical
import NL2Proof.Verify.Oracle

forged :: Confirmed -> Confirmed
forged token = token { confClaim = CanPred "unchecked" [] }
