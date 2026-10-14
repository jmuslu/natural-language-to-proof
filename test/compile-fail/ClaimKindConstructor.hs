{-# LANGUAGE DataKinds #-}
module ClaimKindConstructor where

import NL2Proof.Verify.ClaimKind

-- Re-indexing a reported claim as asserted by re-wrapping its content must
-- not be possible; only structural extraction creates assertion witnesses.
reindexed :: Claim 'Reported -> Claim 'Asserted
reindexed r = MkClaim (claimCond r)
