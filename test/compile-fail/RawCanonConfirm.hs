module RawCanonConfirm where
import NL2Proof.DRT.Canonical
import NL2Proof.Verify.Oracle
leaked :: Oracle -> CanonCond -> Maybe Confirmed
leaked = confirm
