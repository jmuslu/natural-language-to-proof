{-# LANGUAGE DataKinds #-}
module ClaimKindCoerce where
import Data.Coerce (coerce)
import NL2Proof.Verify.ClaimKind
leaked :: Claim 'Embedded -> Claim 'Asserted
leaked = coerce
