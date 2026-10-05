{-# LANGUAGE DataKinds #-}
module ReportedConfirm where

import NL2Proof.Verify.ClaimKind
import NL2Proof.Verify.Oracle

-- A reported claim is not evidence: asking the oracle to confirm it directly
-- (so that "Bob said P" would yield a token for P) must not typecheck.
promoted :: Oracle -> Claim 'Reported -> Maybe Confirmed
promoted oracle reported = confirm oracle reported
