-- | Discourse Representation Structures, provenance-tagged throughout.
--
-- Every referent in a universe and every condition in a box carries a 'Prov'.
-- Per ARCHITECTURE.md this is done from day one even though Stage 1 only
-- exercises the logical-content half, because retrofitting it later is expensive
-- and including it now is cheap.
--
-- Accessibility ('accessibleRefs') is the top-level universe only. Referents
-- introduced inside a negated, implicational, or disjunctive box are /not/
-- accessible from outside it — which is why @"No student sleeps. She smiles."@
-- correctly fails to resolve its pronoun.
module NL2Proof.DRT.Types
  ( -- * Structures
    Ref(..)
  , DTerm(..)
  , Condition(..)
  , DRS(..)
    -- * Construction
  , emptyDRS
  , mergeDRS
  , addRef
  , addCondition
    -- * Inspection
  , condProv
  , drsRefs
  , accessibleRefs
  , drsConditionProvs
  , drsAllProvs
  , drsSources
  , drsPredicates
  , drsConstants
  , anaphorConstants
  , drsSize
    -- * Substitution
  , substConst
  , substConstDRS
    -- * Rendering
  , renderDTerm
  , renderDRS
  , drsBoxLines
  ) where

import Data.List (intercalate, nub)

import NL2Proof.Provenance
import NL2Proof.Semantics.Lambda (isAnaphorName)

--------------------------------------------------------------------------------
-- Structures
--------------------------------------------------------------------------------

-- | A discourse referent.
newtype Ref = Ref String
  deriving (Eq, Ord)

instance Show Ref where
  show (Ref r) = r

-- | An argument position: a referent, or a constant (a proper name, or an
-- as-yet-unresolved anaphor).
data DTerm
  = DRef Ref
  | DConst String
  deriving (Eq, Ord)

instance Show DTerm where
  show = renderDTerm

data Condition
  = CPred String [DTerm] Prov
  | CEq DTerm DTerm Prov
  | CNot DRS Prov
  | -- | Duplex condition: @antecedent => consequent@.
    CImp DRS DRS Prov
  | COr DRS DRS Prov
  deriving (Eq, Show)

-- | A DRS box: a universe of referents, and a list of conditions.
data DRS = DRS
  { drsUniverse :: [(Ref, Prov)]
  , drsConds    :: [Condition]
  }
  deriving (Eq, Show)

--------------------------------------------------------------------------------
-- Construction
--------------------------------------------------------------------------------

emptyDRS :: DRS
emptyDRS = DRS [] []

-- | Union of universes and concatenation of conditions, preserving order.
--
-- This is plain DRS merge. It is /not/ the collapse step: merging two boxes from
-- the same discourse keeps every provenance tag intact, whereas collapsing is
-- where truth-mode discards them.
mergeDRS :: DRS -> DRS -> DRS
mergeDRS (DRS u1 c1) (DRS u2 c2) = DRS (u1 ++ u2) (c1 ++ c2)

instance Semigroup DRS where
  (<>) = mergeDRS

instance Monoid DRS where
  mempty = emptyDRS

addRef :: Ref -> Prov -> DRS -> DRS
addRef r p d = d { drsUniverse = (r, p) : drsUniverse d }

addCondition :: Condition -> DRS -> DRS
addCondition c d = d { drsConds = drsConds d ++ [c] }

--------------------------------------------------------------------------------
-- Inspection
--------------------------------------------------------------------------------

condProv :: Condition -> Prov
condProv (CPred _ _ p) = p
condProv (CEq _ _ p)   = p
condProv (CNot _ p)    = p
condProv (CImp _ _ p)  = p
condProv (COr _ _ p)   = p

-- | Every referent, including those in subordinate boxes.
drsRefs :: DRS -> [Ref]
drsRefs (DRS us cs) = map fst us ++ concatMap go cs
  where
    go (CNot d _)   = drsRefs d
    go (CImp a b _) = drsRefs a ++ drsRefs b
    go (COr a b _)  = drsRefs a ++ drsRefs b
    go _            = []

-- | Referents an anaphor in a /following/ sentence may pick up.
--
-- Top-level universe only. Subordinate boxes are inaccessible, which is the
-- standard DRT constraint and the reason this is a separate function from
-- 'drsRefs' rather than a filter over it.
accessibleRefs :: DRS -> [Ref]
accessibleRefs = map fst . drsUniverse

-- | Provenance of every condition, at every depth.
drsConditionProvs :: DRS -> [Prov]
drsConditionProvs (DRS _ cs) = concatMap go cs
  where
    go c = condProv c : case c of
      CNot d _   -> drsConditionProvs d
      CImp a b _ -> drsConditionProvs a ++ drsConditionProvs b
      COr a b _  -> drsConditionProvs a ++ drsConditionProvs b
      _          -> []

-- | Every provenance tag in the structure: referents and conditions, all depths.
--
-- This is the handle the two collapse modes grab. provenance-mode keeps these
-- trees; truth-mode reduces them with 'provSources' or discards them.
drsAllProvs :: DRS -> [Prov]
drsAllProvs (DRS us cs) = map snd us ++ concatMap go cs
  where
    go c = condProv c : case c of
      CNot d _   -> drsAllProvs d
      CImp a b _ -> drsAllProvs a ++ drsAllProvs b
      COr a b _  -> drsAllProvs a ++ drsAllProvs b
      _          -> []

-- | Which sources this structure draws on. The @why@-provenance of a whole DRS.
drsSources :: DRS -> [SourceId]
drsSources = nub . concatMap provSources . drsAllProvs

-- | Every predicate symbol used, at every depth.
drsPredicates :: DRS -> [String]
drsPredicates (DRS _ cs) = nub (concatMap go cs)
  where
    go (CPred p _ _) = [p]
    go (CEq _ _ _)   = []
    go (CNot d _)    = drsPredicates d
    go (CImp a b _)  = drsPredicates a ++ drsPredicates b
    go (COr a b _)   = drsPredicates a ++ drsPredicates b

-- | Every constant appearing in an argument position, at every depth.
drsConstants :: DRS -> [String]
drsConstants (DRS _ cs) = nub (concatMap go cs)
  where
    go (CPred _ as _) = [c | DConst c <- as]
    go (CEq a b _)    = [c | DConst c <- [a, b]]
    go (CNot d _)     = drsConstants d
    go (CImp a b _)   = drsConstants a ++ drsConstants b
    go (COr a b _)    = drsConstants a ++ drsConstants b

-- | Constants still marked as unresolved anaphors.
anaphorConstants :: DRS -> [String]
anaphorConstants = filter isAnaphorName . drsConstants

-- | Referents plus conditions, at every depth. Used to check that a collapse
-- preserved or reduced structure as intended.
drsSize :: DRS -> Int
drsSize (DRS us cs) = length us + sum (map go cs)
  where
    go (CNot d _)   = 1 + drsSize d
    go (CImp a b _) = 1 + drsSize a + drsSize b
    go (COr a b _)  = 1 + drsSize a + drsSize b
    go _            = 1

--------------------------------------------------------------------------------
-- Substitution
--------------------------------------------------------------------------------

substConst :: String -> DTerm -> DTerm -> DTerm
substConst name new t = case t of
  DConst c | c == name -> new
  _                    -> t

-- | Replace a constant everywhere it appears in argument position. Anaphora
-- resolution is exactly this, with @name@ an anaphor placeholder and @new@ the
-- chosen antecedent.
substConstDRS :: String -> DTerm -> DRS -> DRS
substConstDRS name new (DRS us cs) = DRS us (map go cs)
  where
    s = substConst name new
    go (CPred p as p') = CPred p (map s as) p'
    go (CEq a b p')    = CEq (s a) (s b) p'
    go (CNot d p')     = CNot (substConstDRS name new d) p'
    go (CImp a b p')   = CImp (substConstDRS name new a) (substConstDRS name new b) p'
    go (COr a b p')    = COr (substConstDRS name new a) (substConstDRS name new b) p'

--------------------------------------------------------------------------------
-- Rendering
--------------------------------------------------------------------------------

renderDTerm :: DTerm -> String
renderDTerm (DRef (Ref r)) = r
renderDTerm (DConst c)     = c

-- | ASCII box notation.
renderDRS :: DRS -> String
renderDRS = unlines . drsBoxLines

drsBoxLines :: DRS -> [String]
drsBoxLines (DRS us cs) =
  [bar, row universeLine, bar] ++ map row body ++ [bar]
  where
    universeLine = unwords [show r | (r, _) <- us]
    body = concatMap condLines cs

    width = maximum (1 : map length (universeLine : body))
    bar = "+" ++ replicate (width + 2) '-' ++ "+"
    row s = "| " ++ s ++ replicate (width - length s) ' ' ++ " |"

    condLines (CPred p [] _) = [p]
    condLines (CPred p as _) =
      [p ++ "(" ++ intercalate ", " (map renderDTerm as) ++ ")"]
    condLines (CEq a b _) = [renderDTerm a ++ " = " ++ renderDTerm b]
    condLines (CNot d _)  = "NOT:" : indent (drsBoxLines d)
    condLines (CImp a b _) = indent (drsBoxLines a) ++ ["  =>"] ++ indent (drsBoxLines b)
    condLines (COr a b _)  = indent (drsBoxLines a) ++ ["  OR"] ++ indent (drsBoxLines b)

    indent = map ("  " ++)
