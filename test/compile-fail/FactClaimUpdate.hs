module FactClaimUpdate where
import NL2Proof.DRT.Canonical
import NL2Proof.Verify.Claims
leaked :: Fact -> CanonCond -> Fact
leaked fact c = fact { factClaim = c }
