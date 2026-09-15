module ConfirmedConstructor where

import NL2Proof.DRT.Canonical
import NL2Proof.Verify.Oracle

forged :: Confirmed
forged = MkConfirmed (CanPred "unchecked" []) "invented-oracle"
