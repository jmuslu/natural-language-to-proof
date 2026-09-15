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
-- == And bookkeeping is only safe here because verification already happened
--
-- Merging two assertions of one claim destroys the fact that there were two.
-- Upstream of an oracle that would be catastrophic — independent corroboration
-- is information, and "two sources agree" must stay distinguishable from "one
-- source said it once" while truth is still undecided.
--
-- Downstream of the oracle it is safe, and for a precise reason: truth was
-- already settled in stage 2, so collapsing multiplicity here is only avoiding
-- storing the same confirmed fact five times. Nothing is being /established/ by
-- the merge.
--
-- The ordering is load-bearing. Verification needs retention; fusion needs
-- collapse; and they have to happen in that order, because a collapse performed
-- first destroys the derivation record that retraction depends on
-- ("NL2Proof.Genealogy").
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
  , fuse
  , fusedContains
  , withoutClaim
    -- * Box-level compression
  , compress
  , compressionRatio
    -- * Mechanical entailment over a confirmed base
  , entailedFrom
  , detachable
    -- * Rendering
  , renderFused
  ) where

import Data.List (nub, sort)

import NL2Proof.DRT.Canonical
import NL2Proof.Verify.Oracle

--------------------------------------------------------------------------------
-- Fused output
--------------------------------------------------------------------------------

-- | A deduplicated set of confirmed claims, with the loss measured.
--
-- 'fusedDropped' exists for the same reason it did on the old branch: drift you
-- have measured is different in kind from drift you have decided not to look at.
-- Abstract and positional: neither construction nor exported record updates can
-- introduce an unconfirmed claim. Only 'fuse' constructs a base; 'withoutClaim'
-- can weaken one for novelty checks.
data Fused = MkFused [CanonCond] [String] Int
  deriving (Eq, Show)

-- | Sorted, deduplicated claims, each confirmed by an oracle.
fusedClaims :: Fused -> [CanonCond]
fusedClaims (MkFused claims _ _) = claims

-- | Oracles contributing to the original confirmed base.
fusedOracles :: Fused -> [String]
fusedOracles (MkFused _ oracles _) = oracles

-- | Redundant confirmations removed by fusion.
fusedDropped :: Fused -> Int
fusedDropped (MkFused _ _ dropped) = dropped

fuse :: [Confirmed] -> Fused
fuse cs = MkFused kept (sort (nub (map confOracle cs))) (length cs - length kept)
  where
    kept = dedupe (map confClaim cs)

-- | Remove a claim from a certified base. This can only discard confirmation,
-- never introduce it; reward uses it to ask whether the rest entails a claim.
withoutClaim :: CanonCond -> Fused -> Fused
withoutClaim claim (MkFused claims oracles dropped) =
  MkFused (filter (/= claim) claims) oracles dropped

fusedContains :: Fused -> CanonCond -> Bool
fusedContains f c = c `elem` fusedClaims f

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
entailedFrom f = go (fusedClaims f)
  where
    go base =
      let new = nub [c | c <- concatMap (detachable base) base, c `notElem` base]
      in if null new then base else go (base ++ new)

-- | Modus ponens on one condition, with its side condition made explicit.
--
-- @CanImp a b@ detaches to @b@'s conditions when every condition of @a@ is in the
-- base — __and when @a@ binds no referent__.
--
-- That second requirement is not a technicality. In DRT a duplex condition whose
-- antecedent box has a non-empty universe is a __universal quantification__, not
-- a material implication. Detaching from it without producing a witness would be
-- unsound: from "every student reads a book" and "student(r0)" you may conclude
-- something, but not by treating the duplex as @P -> Q@ over closed formulas.
-- So the guard is @null (canonUniverse a)@ and the incompleteness is accepted.
detachable :: [CanonCond] -> CanonCond -> [CanonCond]
detachable base (CanImp a b)
  | null (canonUniverse a)
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
