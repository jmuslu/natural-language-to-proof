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
  , recencyOrdered
  , drsConditionProvs
  , drsAllProvs
  , drsSources
  , drsPredicates
  , drsConstants
  , anaphorConstants
  , drsSize
    -- * Substitution and alpha-conversion
  , substConst
  , substConstDRS
  , mapRefs
  , freshenAgainst
    -- * Rendering
  , renderDTerm
  , renderDRS
  , drsBoxLines
  ) where

import Data.Maybe (fromMaybe)
import Data.List (intercalate, nub, sortBy)

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
-- where fusion discards them.
--
-- == Precondition: the universes must be disjoint
--
-- This is the standard side condition on DRS merge and it is __not enforced
-- here__, because @mergeDRS@ is also used on boxes that were built to share
-- names on purpose. Violating it is unsound rather than merely confusing:
-- concatenating @[x]@ with @[x]@ produces one universe in which every condition
-- from both boxes constrains the /same/ variable, so two distinct individuals
-- get identified.
--
-- Concretely, without enforcement at the discourse level,
-- @"A student arrived. A professor walks."@ merges to
--
-- > | x x          |
-- > | student(x)   |
-- > | arrive(x)    |
-- > | professor(x) |
-- > | walk(x)      |
--
-- which asserts one individual is both. Referent names come from the lambda
-- terms, and two sentences of the same shape get the same name, so the collision
-- is the common case rather than a corner one.
--
-- 'freshenAgainst' discharges the precondition, and
-- 'NL2Proof.DRT.Build.extendDiscourse' applies it at the one place that merges
-- boxes from different sentences.
mergeDRS :: DRS -> DRS -> DRS
mergeDRS (DRS u1 c1) (DRS u2 c2) = DRS (u1 ++ u2) (c1 ++ c2)

instance Semigroup DRS where
  (<>) = mergeDRS

instance Monoid DRS where
  mempty = emptyDRS

-- | Introduce a referent.
--
-- Conses, so the universe ends up in reverse construction order. That is a
-- plumbing choice and __nothing semantic may be read off it__: see
-- 'recencyOrdered' for why, and for the ordering that is safe to read.
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
--
-- The result is in __construction order__, which carries no linguistic meaning.
-- For an ordering that does, use 'recencyOrdered'.
accessibleRefs :: DRS -> [Ref]
accessibleRefs = map fst . drsUniverse

-- | The accessible referents ordered by the surface position of the words that
-- introduced them, latest first. This is /recency/.
--
-- __Recency is computed from spans, not from the shape of the universe list__,
-- and keeping those apart is the entire reason this function exists next to
-- 'accessibleRefs'.
--
-- Construction order is the composite of two unrelated implementation choices:
-- 'addRef' conses, so within one sentence the __outermost__ quantifier lands
-- first, and 'mergeDRS' appends, so earlier sentences land first. Reversing that
-- list gives the right answer for the sentences Stage 1 currently produces — but
-- only for the cross-sentence half by design. The within-sentence half is a
-- coincidence resting on a third fact: the transitive verb entry always gives
-- the subject wide scope, which makes /outermost/ coincide with /leftmost/.
--
-- "NL2Proof.Stage2.Alternatives".'NL2Proof.Stage2.Alternatives.scopeAlternatives'
-- permutes exactly that. Under an object-wide reading the nesting inverts, the
-- cons order inverts with it, and a reversal would rank the subject as the more
-- recent of the two — wrongly, and with nothing in the anaphora code mentioning
-- scope, so nothing would flag it.
--
-- Surface position does not move when scope permutes. Ordering by it is
-- therefore invariant under precisely the change that breaks the reversal, and
-- it says what recency means rather than arranging for it.
--
-- A referent whose provenance reaches no lexical leaf has no position and ranks
-- last. Equal positions fall back to construction order, latest first.
recencyOrdered :: DRS -> [Ref]
recencyOrdered (DRS us _) = [r | (_, _, r) <- sortBy laterFirst keyed]
  where
    keyed = [(provSpan p, i, r) | (i, (r, p)) <- zip [0 :: Int ..] us]
    laterFirst (sp1, i1, _) (sp2, i2, _) = compare sp2 sp1 <> compare i2 i1

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
-- This is the handle both dispositions grab. Verification keeps these trees;
-- fusion reduces them with 'provSources' or discards them.
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

-- | Rename every referent, at every depth.
--
-- Alpha-conversion for boxes. Mechanical: it is a /translation/, not a decision,
-- so nothing is logged and no provenance is added. Each referent keeps the
-- provenance it already had, so a renamed referent can still be traced to the
-- words that introduced it — which is the whole reason renaming is safe to do
-- silently.
mapRefs :: (Ref -> Ref) -> DRS -> DRS
mapRefs f (DRS us cs) = DRS [(f r, p) | (r, p) <- us] (map goC cs)
  where
    goC c = case c of
      CPred n as p -> CPred n (map goT as) p
      CEq a b p    -> CEq (goT a) (goT b) p
      CNot d p     -> CNot (mapRefs f d) p
      CImp a b p   -> CImp (mapRefs f a) (mapRefs f b) p
      COr a b p    -> COr (mapRefs f a) (mapRefs f b) p

    goT t = case t of
      DRef r   -> DRef (f r)
      DConst c -> DConst c

-- | Rename the referents of a DRS so that none of them occurs in @taken@,
-- discharging 'mergeDRS''s disjointness precondition.
--
-- Returns the freshened DRS and the substitution actually applied, with identity
-- mappings omitted — so an empty list means there was no collision, which is the
-- common case and worth being able to check cheaply.
--
-- Renames at __every__ depth, not just the top universe. Only top-level
-- collisions are unsound (a referent inside a negated or implicational box is
-- bound by that box), but renaming everything makes the post-merge invariant
-- "all referent names in the discourse are distinct" hold outright, which is far
-- easier to assert than "distinct where it matters".
freshenAgainst :: [Ref] -> DRS -> (DRS, [(Ref, Ref)])
freshenAgainst taken d = (mapRefs rename d, [p | p@(a, b) <- pairs, a /= b])
  where
    mine = nub (drsRefs d)
    pairs = assign (taken ++ mine) mine

    assign _ [] = []
    assign avoid (r : rs)
      | r `notElem` taken = (r, r) : assign avoid rs
      | otherwise =
          let r' = firstFree avoid r
          in (r, r') : assign (r' : avoid) rs

    rename r = fromMaybe r (lookup r pairs)

    -- Numeric suffixes, skipping anything already in play. The fragment already
    -- produces names like @x1@ from the lambda terms, so a suffix scheme that
    -- did not check for collisions would reintroduce the bug it is fixing.
    firstFree avoid (Ref b) =
      head [Ref c | n <- [(2 :: Int) ..], let c = b ++ show n, Ref c `notElem` avoid]

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
