{-# LANGUAGE LambdaCase #-}

-- | Provenance tagging.
--
-- /Every/ DRS box, discourse referent, and semantic
-- condition carries a provenance tag from day one, even though Stage 1 only
-- exercises the logical-content half. Retrofitting this later is expensive;
-- including it now is cheap.
--
-- The key design decision: 'Prov' is a __tree__, not a flat source tag. That
-- makes the two dispositions two different /folds over one shared structure/
-- rather than two different data models:
--
-- * fusion       collapses it   ('provSources' — @why@-provenance)
-- * verification preserves it   (the whole tree — @how@-provenance)
--
-- @how@-provenance is strictly more informative than @why@-provenance.
--
-- What a tree cannot do is answer reachability, which is what retraction needs;
-- "NL2Proof.Genealogy" is the graph for that, and the two coexist.
module NL2Proof.Provenance
  ( -- * Sources and spans
    SourceId(..)
  , Span(..)
  , spanUnion
  , spanCovers
  , spanWidth
  , spanCoverage
    -- * Derivation trees
  , RuleName(..)
  , Prov(..)
  , provRule
    -- * Folds
    -- $folds
  , provLeaves
  , provSources
  , provSpan
  , provSurface
  , provRuleNames
  , provDepth
  , provSize
    -- * Minimal alternative support
  , Support
  , supportZero
  , supportOne
  , supportAtom
  , supportFromEnvironments
  , supportEnvironments
  , supportPlus
  , supportTimes
  , supportWithout
  , supportHolds
    -- * Rendering
  , renderProvInline
  , renderProvTree
  ) where

import Data.List (intercalate, nub, sortOn)
import qualified Data.Set as S

--------------------------------------------------------------------------------
-- Sources and spans
--------------------------------------------------------------------------------

-- | Identifier for a source document, utterance, or speaker.
--
-- This is the coarse unit of retraction: if a @SourceId@ is found unreliable,
-- every conclusion whose derivation tree touches it must be locatable. The
-- fine-grained unit is a 'NL2Proof.Genealogy.NodeId', for when a single oracle
-- answer reverses rather than a whole document being distrusted.
newtype SourceId = SourceId String
  deriving (Eq, Ord)

instance Show SourceId where
  show (SourceId s) = s

-- | Half-open character offsets @[start, end)@ into the original source text.
data Span = Span
  { spanStart :: !Int
  , spanEnd   :: !Int
  }
  deriving (Eq, Ord)

instance Show Span where
  show (Span a b) = show a ++ ":" ++ show b

-- | Smallest span covering both arguments.
spanUnion :: Span -> Span -> Span
spanUnion (Span a b) (Span c d) = Span (min a c) (max b d)

-- | @spanCovers outer inner@ — does @outer@ contain @inner@?
spanCovers :: Span -> Span -> Bool
spanCovers (Span a b) (Span c d) = a <= c && d <= b

spanWidth :: Span -> Int
spanWidth (Span a b) = b - a

-- | Characters covered by a set of spans, counting overlaps __once__.
--
-- Deliberately not @sum . map spanWidth@. Spans overlap, and for a coverage
-- measure the difference between the two is the difference between /how much of
-- the input is accounted for/ and /how much was said about it/ — which is
-- exactly the distinction a reward signal has to keep, since the second is
-- inflatable by repetition and the first is not.
--
-- Empty spans contribute nothing. The result is @0@ for no spans, so a caller
-- dividing by it must guard.
spanCoverage :: [Span] -> Int
spanCoverage =
  sum . map spanWidth . merge . sortOn spanStart . filter ((> 0) . spanWidth)
  where
    merge (Span a b : Span c d : rest)
      | c <= b    = merge (Span a (max b d) : rest)
      | otherwise = Span a b : merge (Span c d : rest)
    merge xs = xs

--------------------------------------------------------------------------------
-- Derivation trees
--------------------------------------------------------------------------------

-- | Name of the rule that produced a derived node (a CCG combinator, a DRS
-- construction step, an anaphora resolution).
newtype RuleName = RuleName String
  deriving (Eq, Ord)

instance Show RuleName where
  show (RuleName r) = r

-- | @how@-provenance: the full derivation tree.
data Prov
  = -- | A lexical leaf: which source, which characters, which surface form.
    ProvLex SourceId Span String
  | -- | A derived node: which rule, over which sub-derivations.
    ProvRule RuleName [Prov]
  deriving (Eq, Ord)

instance Show Prov where
  show = renderProvInline

-- | Convenience constructor.
provRule :: String -> [Prov] -> Prov
provRule = ProvRule . RuleName

--------------------------------------------------------------------------------
-- Folds
--------------------------------------------------------------------------------

-- $folds
-- The two output modes are distinguished purely by /which of these folds they
-- apply/. Nothing else in the pipeline differs.

-- | All lexical leaves, in derivation order.
provLeaves :: Prov -> [(SourceId, Span, String)]
provLeaves = \case
  ProvLex s sp w -> [(s, sp, w)]
  ProvRule _ ks  -> concatMap provLeaves ks

-- | @why@-provenance: which sources could have produced this result.
--
-- This is the fusion-side fold — it discards /how/ and keeps only /whether/.
-- Two derivations from the same source become indistinguishable here, which is
-- exactly the lossiness fusion wants and verification forbids.
provSources :: Prov -> [SourceId]
provSources = nub . map (\(s, _, _) -> s) . provLeaves

-- | The covering source span.
--
-- Implements the traceability requirement: every atomic clause in the formal
-- output is traceable back to its source text span, independent of mode.
provSpan :: Prov -> Maybe Span
provSpan p = case map (\(_, sp, _) -> sp) (provLeaves p) of
  []       -> Nothing
  (x : xs) -> Just (foldr spanUnion x xs)

-- | The surface string this derivation came from, reassembled in source order.
provSurface :: Prov -> String
provSurface =
  unwords . map (\(_, _, w) -> w) . sortOn (\(_, sp, _) -> sp) . provLeaves

-- | Every rule applied anywhere in the derivation.
provRuleNames :: Prov -> [RuleName]
provRuleNames = \case
  ProvLex{}     -> []
  ProvRule r ks -> r : concatMap provRuleNames ks

-- | Height of the derivation tree.
provDepth :: Prov -> Int
provDepth = \case
  ProvLex{}     -> 1
  ProvRule _ ks -> 1 + maximum (0 : map provDepth ks)

-- | Total node count. A crude but useful measure of how much verification
-- retains that fusion throws away.
provSize :: Prov -> Int
provSize = \case
  ProvLex{}     -> 1
  ProvRule _ ks -> 1 + sum (map provSize ks)

--------------------------------------------------------------------------------
-- Rendering
--------------------------------------------------------------------------------

-- | Compact single-line form.
renderProvInline :: Prov -> String
renderProvInline = \case
  ProvLex s sp w -> show w ++ "@" ++ show s ++ "[" ++ show sp ++ "]"
  ProvRule r ks  -> show r ++ "(" ++ intercalate ", " (map renderProvInline ks) ++ ")"

-- | Indented derivation tree, one node per line.
renderProvTree :: Prov -> String
renderProvTree = unlines . go 0
  where
    go n = \case
      ProvLex s sp w ->
        [pad n ++ "lex " ++ show w ++ " @" ++ show s ++ "[" ++ show sp ++ "]"]
      ProvRule r ks -> (pad n ++ show r) : concatMap (go (n + 1)) ks
    pad n = replicate (2 * n) ' '

--------------------------------------------------------------------------------
-- Minimal alternative support
--------------------------------------------------------------------------------

-- | PosBool in minimal DNF: each inner set is a sufficient environment and the
-- outer set holds independent alternatives. Subsumed environments are removed.
-- This finite absorptive semiring preserves exact source-withdrawal distinctions,
-- not proof multiplicity or numerical confidence. The constructor is hidden to
-- preserve normalization; see research/STRENGTH.md for laws and termination.
newtype Support a = Support (S.Set (S.Set a))
  deriving (Eq, Ord, Show)

supportFromEnvironments :: Ord a => [[a]] -> Support a
supportFromEnvironments = normalize . S.fromList . map S.fromList

normalize :: Ord a => S.Set (S.Set a) -> Support a
normalize candidates = Support $ S.filter minimal candidates
  where
    minimal candidate = not $ any (`S.isProperSubsetOf` candidate) candidates

supportEnvironments :: Support a -> [[a]]
supportEnvironments (Support envs) = map S.toAscList (S.toAscList envs)

supportZero :: Support a
supportZero = Support S.empty

supportOne :: Support a
supportOne = Support (S.singleton S.empty)

supportAtom :: a -> Support a
supportAtom = Support . S.singleton . S.singleton

supportPlus :: Ord a => Support a -> Support a -> Support a
supportPlus (Support a) (Support b) = normalize (S.union a b)

supportTimes :: Ord a => Support a -> Support a -> Support a
supportTimes (Support a) (Support b) = normalize $ S.fromList
  [ S.union x y | x <- S.toList a, y <- S.toList b ]

-- | Reject entire derivations requiring disabled evidence. Removing individual
-- atoms from environments would turn invalid derivations into unconditional ones.
supportWithout :: (a -> Bool) -> Support a -> Support a
supportWithout disabled (Support envs) = Support $ S.filter (not . any disabled) envs

supportHolds :: Ord a => S.Set a -> Support a -> Bool
supportHolds active (Support envs) = any (`S.isSubsetOf` active) envs
