{-# LANGUAGE DataKinds #-}
module ReportedAccessors where

import NL2Proof.DRT.Canonical
import NL2Proof.Verify.ClaimKind
import NL2Proof.Verify.Oracle
import NL2Proof.Verify.Reported

-- Reports can be inspected.
inspectReport :: Reported -> (Claim 'Reported, CanonCond, [Attribution], Maybe CTerm, Maybe String)
inspectReport r =
  (reportedClaim' r, reportedContent r, reportedChain r, reportedSource r, reportedVerb r)

-- The legitimate path: promote to an unconfirmed candidate, then ask an oracle.
checkCandidate :: Oracle -> Reported -> Maybe Confirmed
checkCandidate oracle r = confirm oracle (asCandidate (reportedClaim' r))

-- Asserted claims, indexed or bare, are confirmable as before.
checkAsserted :: Oracle -> CanonCond -> (Maybe Confirmed, Maybe Confirmed)
checkAsserted oracle c = (confirm oracle c, confirm oracle (assertedClaim c))
