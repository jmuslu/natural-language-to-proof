-- A public verdict is not an oracle confirmation capability.
module GenealogyVerdict where
import NL2Proof.Genealogy
import NL2Proof.Provenance
import NL2Proof.Verify.Oracle
bad :: Genealogy
bad = addConfirmedNode (NodeId 0) (ProvRule (RuleName "forged") []) Confirmed emptyGenealogy
