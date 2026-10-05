module ReportedChainUpdate where

import NL2Proof.Verify.Reported

-- Laundering a report by deleting its attribution chain must not typecheck.
laundered :: Reported -> Reported
laundered r = r { reportedChain = [] }
