{-# LANGUAGE DataKinds #-}
module EmbeddedConfirm where

import NL2Proof.Verify.ClaimKind
import NL2Proof.Verify.Claims
import NL2Proof.Verify.Oracle

-- A condition from under a negation, a conditional or a disjunction is not
-- asserted: confirming it straight from the claim table (so that "the cat is
-- not red" would yield a token for red(cat)) must not typecheck.
leaked :: Oracle -> ClaimTable -> [Maybe Confirmed]
leaked oracle ct = map (confirm oracle) (ctEmbedded ct)
