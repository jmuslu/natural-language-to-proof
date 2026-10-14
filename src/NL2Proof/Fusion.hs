-- | Stage 3 of the substrate pipeline: fusion of oracle-confirmed claims.
--
-- == This is bookkeeping, not verification
--
-- 'compress' is @sort@ then @dedup@ over 'CanonCond' — syntactic equality up to
-- referent renaming. That is strictly finer than "entails the same
-- proposition", and the gap does not close by improving the implementation:
-- @~(P | Q)@ and @~P & ~Q@ are logically equivalent, produce different
-- 'CanonCond' shapes, and will never merge.
--
-- So reading this stage as establishing anything is a mistake. It removes
-- duplicate storage; truth was settled upstream.
--
-- == Preserve the confirmation alternatives
--
-- Claims share storage, but their support labels retain each independent oracle
-- confirmation. Withdrawing one oracle removes just those environments. Repeated
-- copies of the same oracle/claim identity are idempotent, not corroboration.
-- The claim table and genealogy keep the richer extraction provenance upstream.
--
-- == The gate
--
-- 'fuse' takes @['Confirmed']@, and 'NL2Proof.Verify.Oracle.Confirmed' has no
-- exported constructor. Feeding this stage unverified claims is a type error, not
-- a mistake to be careful about.
module NL2Proof.Fusion
  ( -- * Fused output
    Fused
  , fusedClaims
  , fusedOracles
  , fusedDropped
  , fusedSupport
  , withoutOracle
  , fuse
  , fusedContains
  , withoutClaim
    -- * Box-level compression
  , compress
  , compressionRatio
    -- * Mechanical entailment over a confirmed base
  , entailedFrom
  , entailedWithSupport
  , detachable
    -- * Rendering
  , renderFused
  ) where

import Data.List (nub, sort)
import qualified Data.Map.Strict as M

import NL2Proof.DRT.Canonical
import NL2Proof.Provenance
import NL2Proof.Verify.Oracle

--------------------------------------------------------------------------------
-- Fused output
--------------------------------------------------------------------------------

-- | Deduplicated confirmed claims with their alternative oracle dependencies.
--
-- 'fusedDropped' exists for the same reason it did on the old branch: drift you
-- have measured is different in kind from drift you have decided not to look at.
-- Abstract and positional: neither construction nor exported record updates can
-- introduce an unconfirmed claim. Only 'fuse' constructs a base; 'withoutClaim'
-- can weaken one for novelty checks.
data Fused = MkFused
  (M.Map CanonCond (Support (String, CanonCond))) [String] Int
  deriving (Eq, Show)

-- | Sorted, deduplicated claims, each confirmed by an oracle.
fusedClaims :: Fused -> [CanonCond]
fusedClaims (MkFused claims _ _) = M.keys claims

-- | Oracles contributing to the original confirmed base, except withdrawn ones.
fusedOracles :: Fused -> [String]
fusedOracles (MkFused _ oracles _) = oracles

fusedDropped :: Fused -> Int
fusedDropped (MkFused _ _ dropped) = dropped

-- | Minimal alternative sets of (oracle, exact claim) confirmation identities.
-- These explanatory identities are not Confirmed capabilities: only fuse can
-- construct the certified base from the actual capabilities.
fusedSupport :: Fused -> CanonCond -> Support (String, CanonCond)
fusedSupport (MkFused claims _ _) c = M.findWithDefault supportZero c claims

fuse :: [Confirmed] -> Fused
fuse cs = MkFused kept (sort (nub (map confOracle cs))) (length cs - M.size kept)
  where
    kept = M.fromListWith supportPlus
      [(confClaim c, supportAtom (confOracle c, confClaim c)) | c <- cs]

-- | Weakening cannot introduce an unconfirmed claim.
withoutClaim :: CanonCond -> Fused -> Fused
withoutClaim claim (MkFused claims oracles dropped) =
  MkFused (M.delete claim claims) oracles dropped

-- | Withdraw one oracle's contributions; independent confirmations survive.
withoutOracle :: String -> Fused -> Fused
withoutOracle oracle (MkFused claims oracles dropped) =
  MkFused (M.filter (/= supportZero) (M.map (supportWithout ((== oracle) . fst)) claims))
    (filter (/= oracle) oracles) dropped

fusedContains :: Fused -> CanonCond -> Bool
fusedContains (MkFused claims _ _) c = M.member c claims

--------------------------------------------------------------------------------
-- Box-level compression
--------------------------------------------------------------------------------

-- | Sort and deduplicate conditions at every depth, returning the compressed
-- form and the number of nodes removed.
--
-- Sorting is by the derived 'Ord' on 'CanonCond': an arbitrary but stable total
-- order. Stability is the requirement, not meaningfulness — the point is that the
-- same content always lands in the same shape.
compress :: Canonical -> (Canonical, Int)
compress c = (compressed, canonSize c - canonSize compressed)
  where
    compressed = go c

    go (Canonical us cs) = Canonical (dedupe us) (dedupe (map deeper cs))

    -- Nested boxes are compressed too, otherwise a duplicate inside a negation
    -- would survive and two equivalent readings would compare unequal.
    deeper (CanNot x)   = CanNot (go x)
    deeper (CanImp a b) = CanImp (go a) (go b)
    deeper (CanOr a b)  = CanOr (go a) (go b)
    deeper (CanAtt v as k) = CanAtt v as (go k)
    deeper (CanPresup k) = CanPresup (go k)
    deeper k            = k

-- | Compressed size as a fraction of original size. @1.0@ means nothing dropped.
compressionRatio :: Canonical -> Double
compressionRatio c
  | original == 0 = 1.0
  | otherwise = fromIntegral (canonSize kept) / fromIntegral original
  where
    (kept, _) = compress c
    original = canonSize c

dedupe :: Ord a => [a] -> [a]
dedupe = squash . sort
  where
    squash (a : b : rest)
      | a == b    = squash (a : rest)
      | otherwise = a : squash (b : rest)
    squash xs     = xs

--------------------------------------------------------------------------------
-- Mechanical entailment over a confirmed base
--------------------------------------------------------------------------------

-- | Consequences derivable from the fused base by modus ponens, to closure.
--
-- This is the second admissible reward source: a claim that follows mechanically
-- from an already-confirmed base inherits its grounding, without ever needing an
-- oracle of its own.
--
-- __Deliberately weak, and sound.__ One rule only. A full prover is not wanted
-- here, because "a proof was found" is exactly the signal the standing
-- limitations forbid rewarding on its own.
entailedFrom :: Fused -> [CanonCond]
entailedFrom = M.keys . entailedWithSupport

-- | Every material-implication proof retains the rule's confirmation and all
-- premise confirmations. Alternatives sum; conjunctive requirements multiply.
-- This proves a consequence from certified premises without minting a new
-- Confirmed capability. The finite antichain fixed point terminates on cycles.
entailedWithSupport :: Fused -> M.Map CanonCond (Support (String, CanonCond))
entailedWithSupport (MkFused initial _ _) = go initial
  where
    go old =
      let new = M.unionWith supportPlus old $ M.fromListWith supportPlus
            [(c, supportTimes ruleSupport (foldl supportTimes supportOne
                   [M.findWithDefault supportZero p old | p <- canonConds antecedent]))
            | (rule@(CanImp antecedent _), ruleSupport) <- M.toList old
            , c <- detachable (M.keys old) rule]
      in if new == old then old else go new

-- | Modus ponens on one condition, with its side condition made explicit.
--
-- @CanImp a b@ detaches to @b@'s conditions when every condition of @a@ is in the
-- base — __and when neither box binds a referent__.
--
-- That second requirement is not a technicality. In DRT a duplex condition whose
-- antecedent box has a non-empty universe is a __universal quantification__, not
-- a material implication. Detaching from it without producing a witness would be
-- unsound: from "every student reads a book" and "student(r0)" you may conclude
-- something, but not by treating the duplex as @P -> Q@ over closed formulas.
-- Both boxes must bind no referent. An existential consequent cannot be
-- flattened into free literals either; that would lose the existential scope.
-- The incompleteness is accepted; a scoped FOL backend handles those cases.
detachable :: [CanonCond] -> CanonCond -> [CanonCond]
detachable base (CanImp a b)
  | null (canonUniverse a)
  , null (canonUniverse b)
  , all (`elem` base) (canonConds a)
  = canonConds b
detachable _ _ = []

--------------------------------------------------------------------------------
-- Rendering
--------------------------------------------------------------------------------

renderFused :: Fused -> String
renderFused f =
  unlines $
    [ "fused: " ++ show (length (fusedClaims f)) ++ " confirmed claim(s), "
        ++ show (fusedDropped f) ++ " redundant confirmation(s) dropped"
    , "oracles: " ++ show (fusedOracles f)
    ]
      ++ [ "  " ++ renderCanonCond c | c <- fusedClaims f ]
