module ReportedConstructor where

import NL2Proof.Verify.Reported

-- Forging a report (here: stripping its attribution chain) must not be
-- possible outside the module.
forged :: Reported -> Reported
forged r = MkReported (reportedClaim' r) [] (reportedProv r)
