{-# LANGUAGE DataKinds #-}
module ReportedAccessors where

import NL2Proof.DRT.Canonical
import NL2Proof.DRT.Types
import NL2Proof.Verify.ClaimKind
import NL2Proof.Verify.Oracle
import NL2Proof.Verify.Reported

-- Reports can be inspected without changing their commitment kind.
inspectReport :: Reported -> (Claim 'Reported, CanonCond, [Attribution], Maybe CTerm, Maybe String)
inspectReport r =
  (reportedClaim' r, reportedContent r, reportedChain r, reportedSource r, reportedVerb r)

-- Explicit hypothesis inspection never manufactures a confirmation token.
checkHypothesis :: Oracle -> Reported -> Verdict
checkHypothesis oracle r = check oracle (reportedContent r)

-- Only witnesses extracted at the structural root are confirmable.
checkAsserted :: Oracle -> DRS -> [Confirmed]
checkAsserted oracle d = confirmAll oracle (map fst (assertedClaims d))

-- Embedded claims remain inspectable without assertion admission.
inspectEmbedded :: Oracle -> Claim 'Embedded -> (CanonCond, Verdict)
inspectEmbedded oracle e = (claimCond e, check oracle (claimCond e))
