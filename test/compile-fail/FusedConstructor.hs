module FusedConstructor where

import NL2Proof.DRT.Canonical
import NL2Proof.Fusion

forged :: Fused
forged = Fused [CanPred "unchecked" []] ["invented-oracle"] 0
