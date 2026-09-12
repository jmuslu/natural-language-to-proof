-- | CCG combinatory rules over feature-annotated categories, with the feature
-- unification that CCGbank's own derivations require.
--
-- The repo's core parser ('NL2Proof.Syntax.CCG') combines bare 'Cat's by
-- /exact equality/ (@arg == c@). That is correct for the hand-written 9-case
-- fragment, which has no features, but it cannot reproduce CCGbank: the corpus's
-- highest-frequency rules combine an under-specified argument slot with a
-- specified category (a @(S\\NP)\\(S\\NP)@ adverbial modifying an
-- @S[dcl]\\NP@; an @NP[nb]/N@ determiner yielding a bare @NP@). This module
-- supplies the feature-aware combination those rules need, over the 'CCat' type
-- from 'NL2Proof.Syntax.CCGBank'.
--
-- __This is the external-check version of "does the rule set work".__ The rules
-- and the unification policy here are validated not by the system's own metric
-- but against CCGbank's @GRAMMAR@ file — 3,471 linguist-annotated
-- @parent --> children@ instances — via @tools/CCGGrammarCoverage.hs@. The
-- corpus says what the parent category is; this module either reproduces it or
-- is measured as not covering that rule. Nothing self-certifies.
--
-- Schema choices made here (see the findings log, tagged @[stipulated]@):
--
--   * __Unification is underspecification-as-wildcard.__ An empty feature list
--     unifies with any feature (@S@ unifies with @S[dcl]@); two non-empty lists
--     unify iff equal. This matches CCGbank usage and is the only policy under
--     which the corpus's top rules combine at all. The alternative, strict
--     equality, is what the core parser does and is exactly what fails here.
--   * __Ground unification, no variable binding.__ @GRAMMAR@ categories are
--     ground (no @S_1@-style variables), so reproducing an attested parent needs
--     no binding propagation. A generative parser emitting novel categories
--     would need it; that is deferred, not done.
module NL2Proof.Syntax.CCGRules
  ( -- * Unification
    unifiable
  , featCompat
    -- * Coordination / punctuation helpers
  , isCoordinator
  , isPunct
  , hasConj
  , stripConjFeat
  , addConjFeat
    -- * Combinators
  , Combinator(..)
  , combinatorName
  , allCombinators
  , combineNamed
  , combine
  ) where

import Data.List (nub, sort)

import NL2Proof.Syntax.CCGBank (CCat(..), Dir(..), Feat(..))

--------------------------------------------------------------------------------
-- Unification (ground, underspecification-as-wildcard)
--------------------------------------------------------------------------------

-- | Do two categories unify? Same slash structure and atom names, with feature
-- lists compatible under 'featCompat'.
unifiable :: CCat -> CCat -> Bool
unifiable (CAtom n1 f1) (CAtom n2 f2) =
  n1 == n2 && featCompat f1 f2
unifiable (CSlash d1 r1 a1 f1) (CSlash d2 r2 a2 f2) =
  d1 == d2 && featCompat f1 f2 && unifiable r1 r2 && unifiable a1 a2
unifiable _ _ = False

-- | Feature compatibility: an empty (under-specified) list unifies with
-- anything; two specified lists unify iff they are the same set.
featCompat :: [Feat] -> [Feat] -> Bool
featCompat [] _ = True
featCompat _ [] = True
featCompat a b  = norm a == norm b
  where norm = sort . nub

--------------------------------------------------------------------------------
-- Coordination and punctuation helpers
--------------------------------------------------------------------------------

-- | Punctuation atoms that appear as categories in CCGbank.
isPunct :: CCat -> Bool
isPunct (CAtom n _) = n `elem` [".", ",", ":", ";", "LRB", "RRB"]
isPunct _           = False

-- | A coordinator: the lexical @conj@ category, or a comma/semicolon acting as
-- one (CCGbank analyses @, NP@ -> @NP[conj]@ as coordination).
isCoordinator :: CCat -> Bool
isCoordinator (CAtom "conj" _) = True
isCoordinator (CAtom "," _)    = True
isCoordinator (CAtom ";" _)    = True
isCoordinator _                = False

-- | Does the outermost node carry the @[conj]@ marker?
hasConj :: CCat -> Bool
hasConj (CAtom _ fs)       = Feat "conj" `elem` fs
hasConj (CSlash _ _ _ fs)  = Feat "conj" `elem` fs

-- | Remove a @[conj]@ marker from the outermost node.
stripConjFeat :: CCat -> CCat
stripConjFeat (CAtom n fs)       = CAtom n (filter (/= Feat "conj") fs)
stripConjFeat (CSlash d r a fs)  = CSlash d r a (filter (/= Feat "conj") fs)

-- | Add a @[conj]@ marker to the outermost node (idempotent).
addConjFeat :: CCat -> CCat
addConjFeat c
  | hasConj c = c
addConjFeat (CAtom n fs)      = CAtom n (fs ++ [Feat "conj"])
addConjFeat (CSlash d r a fs) = CSlash d r a (fs ++ [Feat "conj"])

--------------------------------------------------------------------------------
-- Combinators
--------------------------------------------------------------------------------

-- | The combinatory rules this module supplies.
data Combinator
  = FwdApp         -- ^ @X/Y  Y      => X@
  | BwdApp         -- ^ @Y    X\\Y    => X@
  | FwdComp        -- ^ @X/Y  Y/Z     => X/Z@
  | BwdComp        -- ^ @Y\\Z X\\Y    => X\\Z@
  | FwdXComp       -- ^ @X/Y  Y\\Z    => X\\Z@ (forward crossed)
  | BwdXComp       -- ^ @Y/Z  X\\Y    => X/Z@ (backward crossed)
  | CoordMark      -- ^ @conj X       => X[conj]@ (also comma/semicolon)
  | CoordApply     -- ^ @X    Y[conj] => X@ when X unifies with Y
  | PunctRight     -- ^ @X    p       => X@ (p punctuation)
  | PunctLeft      -- ^ @p    X       => X@
  deriving (Eq, Ord, Show, Enum, Bounded)

combinatorName :: Combinator -> String
combinatorName = show

allCombinators :: [Combinator]
allCombinators = [minBound .. maxBound]

-- | Apply one combinator to an ordered pair of adjacent categories.
step :: Combinator -> CCat -> CCat -> [CCat]
step FwdApp l r = case l of
  CSlash Fwd x y _ | unifiable y r -> [x]
  _ -> []
step BwdApp l r = case r of
  CSlash Bwd x y _ | unifiable y l -> [x]
  _ -> []
step FwdComp l r = case (l, r) of
  (CSlash Fwd x y _, CSlash Fwd y' z _) | unifiable y y' -> [CSlash Fwd x z []]
  _ -> []
step BwdComp l r = case (l, r) of
  (CSlash Bwd y z _, CSlash Bwd x y' _) | unifiable y y' -> [CSlash Bwd x z []]
  _ -> []
step FwdXComp l r = case (l, r) of
  (CSlash Fwd x y _, CSlash Bwd y' z _) | unifiable y y' -> [CSlash Bwd x z []]
  _ -> []
step BwdXComp l r = case (l, r) of
  (CSlash Fwd y z _, CSlash Bwd x y' _) | unifiable y y' -> [CSlash Fwd x z []]
  _ -> []
step CoordMark l r
  | isCoordinator l = [addConjFeat r]
  | otherwise       = []
step CoordApply l r
  | hasConj r, unifiable l (stripConjFeat r) = [l]
  | otherwise                                = []
step PunctRight l r
  | isPunct r = [l]
  | otherwise = []
step PunctLeft l r
  | isPunct l = [r]
  | otherwise = []

-- | Every category the given combinator set licenses for the pair, tagged with
-- the combinator that produced it.
combineNamed :: [Combinator] -> CCat -> CCat -> [(Combinator, CCat)]
combineNamed combs l r = [ (c, out) | c <- combs, out <- step c l r ]

-- | Every category the full combinator set licenses for the pair.
combine :: CCat -> CCat -> [CCat]
combine l r = [ out | (_, out) <- combineNamed allCombinators l r ]
