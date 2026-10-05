{-# LANGUAGE DataKinds #-}
module ClaimKindConstructor where

import NL2Proof.Verify.ClaimKind

-- Re-indexing a reported claim as asserted by re-wrapping its content must
-- not be possible; 'asCandidate' is the only (logged-by-name) route.
reindexed :: Claim 'Reported -> Claim 'Asserted
reindexed r = MkClaim (claimCond r)
