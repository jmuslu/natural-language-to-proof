-- | A provenance-free view of a DRS, with referents canonically renamed.
--
-- Shared, because __both__ dispositions need it — for opposite reasons:
--
-- * "NL2Proof.Fusion" uses it as its /output/. Strip provenance, then compress:
--   structurally equal claims become one.
-- * "NL2Proof.Verify.Claims" uses it as claim /identity/. Two facts are "the
--   same claim" exactly when their canonical forms are equal — which is what
--   lets it detect that two derivations converged while still keeping them
--   apart.
--
-- So the shared part is stripping and renaming. What happens next is not shared,
-- and is not here.
--
-- Note what this module deliberately does __not__ do: no sorting, no
-- deduplication, no merging. Condition order is preserved exactly. Those are
-- compression steps, they are lossy, and they belong to fusion. A
-- \"canonical form\" that silently deduplicated would make the verification
-- stage impossible to build on top of it.
module NL2Proof.DRT.Canonical
  ( -- * Canonical forms
    CRef(..)
  , CTerm(..)
  , CanonCond(..)
  , Canonical(..)
    -- * Construction
  , canonicalize
  , allRefsIn
    -- * Inspection
  , canonSize
  , canonConditionCount
  , canonPredicates
    -- * Rendering
  , renderCanonical
  , renderCanonCond
  , renderCTerm
  ) where

import Data.List (intercalate, nub)
import qualified Data.Map as M

import NL2Proof.DRT.Types

--------------------------------------------------------------------------------
-- Canonical forms
--------------------------------------------------------------------------------

-- | A referent, renamed to its position in a deterministic traversal. Two DRSs
-- that differ only in their choice of variable names produce equal 'CRef's.
newtype CRef = CRef Int
  deriving (Eq, Ord)

instance Show CRef where
  show (CRef i) = "r" ++ show i

data CTerm
  = CRefT CRef
  | CConstT String
  deriving (Eq, Ord)

instance Show CTerm where
  show = renderCTerm

-- | A condition with its provenance removed.
--
-- 'Ord' is derived and is what fusion's sort relies on. It is an arbitrary
-- but stable total order — the point is determinism, not meaningfulness.
data CanonCond
  = CanPred String [CTerm]
  | CanEq CTerm CTerm
  | CanNot Canonical
  | CanImp Canonical Canonical
  | CanOr Canonical Canonical
  | -- | An attitude report @verb(holders, K)@; @K@ is reported, not asserted.
    CanAtt String [CTerm] Canonical
  | CanPresup Canonical
  deriving (Eq, Ord)

instance Show CanonCond where
  show = renderCanonCond

data Canonical = Canonical
  { canonUniverse :: [CRef]
  , canonConds    :: [CanonCond]
  }
  deriving (Eq, Ord)

instance Show Canonical where
  show = renderCanonical

--------------------------------------------------------------------------------
-- Construction
--------------------------------------------------------------------------------

-- | Every referent the DRS mentions: universe members at all depths, plus any
-- referent appearing only in an argument position.
--
-- The second half matters. A sentence-local DRS whose anaphor has been resolved
-- against the discourse context contains a @DRef@ to a referent declared in an
-- earlier box, so universe traversal alone would miss it and the renaming would
-- be partial.
allRefsIn :: DRS -> [Ref]
allRefsIn d = nub (go d)
  where
    go (DRS us cs) = map fst us ++ concatMap cond cs

    cond (CPred _ as _) = [r | DRef r <- as]
    cond (CEq a b _)    = [r | DRef r <- [a, b]]
    cond (CNot x _)     = go x
    cond (CImp a b _)   = go a ++ go b
    cond (COr a b _)    = go a ++ go b
    cond (CAtt _ as k _) = [r | DRef r <- as] ++ go k
    cond (CPresup k _)  = go k

-- | Strip provenance and renumber referents by first appearance.
--
-- Structure-preserving: same universes, same conditions, same order.
canonicalize :: DRS -> Canonical
canonicalize top = go top
  where
    renaming = M.fromList (zip (allRefsIn top) (map CRef [0 ..]))

    -- Total by construction: 'allRefsIn' collected every referent the structure
    -- mentions, so this lookup cannot miss.
    rn r = M.findWithDefault (CRef 0) r renaming

    go (DRS us cs) = Canonical (map (rn . fst) us) (map cond cs)

    cterm (DRef r)   = CRefT (rn r)
    cterm (DConst c) = CConstT c

    cond (CPred p as _) = CanPred p (map cterm as)
    cond (CEq a b _)    = CanEq (cterm a) (cterm b)
    cond (CNot x _)     = CanNot (go x)
    cond (CImp a b _)   = CanImp (go a) (go b)
    cond (COr a b _)    = CanOr (go a) (go b)
    cond (CAtt v as k _) = CanAtt v (map cterm as) (go k)
    cond (CPresup k _)  = CanPresup (go k)

--------------------------------------------------------------------------------
-- Inspection
--------------------------------------------------------------------------------

-- | Referents plus conditions, at all depths. Comparing this before and after a
-- compression step is how fusion measures what it discarded.
canonSize :: Canonical -> Int
canonSize (Canonical us cs) = length us + sum (map go cs)
  where
    go (CanNot x)   = 1 + canonSize x
    go (CanImp a b) = 1 + canonSize a + canonSize b
    go (CanOr a b)  = 1 + canonSize a + canonSize b
    go (CanAtt _ _ k) = 1 + canonSize k
    go (CanPresup k) = 1 + canonSize k
    go _            = 1

-- | Top-level conditions only.
canonConditionCount :: Canonical -> Int
canonConditionCount = length . canonConds

canonPredicates :: Canonical -> [String]
canonPredicates (Canonical _ cs) = nub (concatMap go cs)
  where
    go (CanPred p _) = [p]
    go (CanEq _ _)   = []
    go (CanNot x)    = canonPredicates x
    go (CanImp a b)  = canonPredicates a ++ canonPredicates b
    go (CanOr a b)   = canonPredicates a ++ canonPredicates b
    go (CanAtt v _ k) = v : canonPredicates k
    go (CanPresup k) = canonPredicates k

--------------------------------------------------------------------------------
-- Rendering
--------------------------------------------------------------------------------

renderCTerm :: CTerm -> String
renderCTerm (CRefT r)   = show r
renderCTerm (CConstT c) = c

renderCanonCond :: CanonCond -> String
renderCanonCond (CanPred p []) = p
renderCanonCond (CanPred p as) =
  p ++ "(" ++ intercalate ", " (map renderCTerm as) ++ ")"
renderCanonCond (CanEq a b)    = renderCTerm a ++ " = " ++ renderCTerm b
renderCanonCond (CanNot x)     = "~" ++ renderCanonical x
renderCanonCond (CanImp a b)   = renderCanonical a ++ " => " ++ renderCanonical b
renderCanonCond (CanOr a b)    = renderCanonical a ++ " OR " ++ renderCanonical b
renderCanonCond (CanAtt v as k) =
  v ++ "(" ++ intercalate ", " (map renderCTerm as ++ [renderCanonical k]) ++ ")"
renderCanonCond (CanPresup k)  = "presup " ++ renderCanonical k

-- | Single-line set-like notation, so two canonical forms can be compared by eye.
renderCanonical :: Canonical -> String
renderCanonical (Canonical us cs) =
  "[" ++ unwords (map show us) ++ " | " ++ intercalate "; " (map renderCanonCond cs) ++ "]"
