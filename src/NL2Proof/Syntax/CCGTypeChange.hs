-- | CCGbank's type-changing rules, treated as a first-class, /learnable/ rule
-- class — and, crucially, measured for generalisation rather than memorisation.
--
-- The combinatory rules ('NL2Proof.Syntax.CCGRules') reproduce ~99.8% of binary
-- rule /firings/ but leave a residue: CCGbank also uses __type-changing rules__
-- that are not pure application/composition — unary changes (@N -> NP@, reduced
-- relatives @S[pss]\\NP -> NP\\NP@, the @TOP@ root) and binary punctuation- or
-- coordination-mediated category changes (@, NP -> (S\\NP)\\(S\\NP)@;
-- @conj S[em] -> S[dcl][conj]@). These are lexicalised, not derivable, so the
-- honest way to handle them is to /learn the inventory from the corpus/.
--
-- The soundness hazard is obvious and is exactly the one this whole project
-- exists to avoid: inducing rules from a corpus and then \"validating\" them on
-- the same corpus is self-agreement — coverage would be ~100% by construction
-- and would mean nothing. So this module is built for a __train/test split__:
-- induce the type-change inventory from training sections, then measure coverage
-- on a __held-out__ section. Generalisation to unseen sentences is the real
-- signal; the held-out section is the external check.
--
-- Coverage is reported as a three-way split kept deliberately separate:
--
--   * __combinator__ — a binary node reproduced by the (generalising)
--     combinatory rules; needs no memorised rule at all;
--   * __type-change (known)__ — a node explained by a type-change rule that was
--     seen in training (generalising memorisation: the same rule recurs on
--     unseen sentences);
--   * __unexplained__ — a node needing a type-change /not/ seen in training: the
--     genuine productive residue.
--
-- A rule set can be matched either exactly or up to feature erasure; comparing
-- the two quantifies how much of the generalisation comes from abstracting over
-- features versus from the rule inventory itself.
module NL2Proof.Syntax.CCGTypeChange
  ( TypeChange(..)
  , normalizeTC
  , inducements
  , buildRuleSet
  , NodeClass(..)
  , classifyTree
  ) where

import qualified Data.Set as Set

import NL2Proof.Syntax.CCGBank (CCat, parseCCGCat)
import NL2Proof.Syntax.CCGRules (combine, unifiable)
import NL2Proof.Syntax.CCGDeriv (AutoNode(..), nodeCat)

-- | A type-changing rule: the child category (unary) or two child categories
-- (binary) that CCGbank rewrites to a parent category by something other than a
-- combinatory rule.
data TypeChange
  = TCUnary CCat CCat        -- ^ child -> parent
  | TCBinary CCat CCat CCat  -- ^ left, right -> parent
  deriving (Eq, Ord, Show)

-- | Apply a per-category normaliser (e.g. 'eraseFeatures' or 'id') to every
-- category in a rule. Used to build/query a rule set exactly or feature-erased.
normalizeTC :: (CCat -> CCat) -> TypeChange -> TypeChange
normalizeTC f (TCUnary c p)    = TCUnary (f c) (f p)
normalizeTC f (TCBinary a b p) = TCBinary (f a) (f b) (f p)

pcat :: String -> Maybe CCat
pcat = either (const Nothing) Just . parseCCGCat

-- | Is a binary node reproduced by the combinatory rules? (features matter here,
-- so this always uses the raw, un-normalised child categories.)
combinatorCovers :: CCat -> CCat -> CCat -> Bool
combinatorCovers a b parent = any (unifiable parent) (combine a b)

-- | The type-changing rules a derivation attests: every unary node, and every
-- binary node the combinators do /not/ already cover. Combinator-covered binary
-- nodes are deliberately excluded — they are not type-changes.
inducements :: AutoNode -> [TypeChange]
inducements = go
  where
    go (AutoLeaf _ _) = []
    go (AutoTree c kids) = here ++ concatMap go kids
      where
        here = case (pcat c, mapM (pcat . nodeCat) kids) of
          (Just parent, Just kcs) -> mk parent kcs
          _                       -> []
        mk parent [k]    = [TCUnary k parent]
        mk parent [a, b]
          | combinatorCovers a b parent = []
          | otherwise                   = [TCBinary a b parent]
        mk _ _ = []

-- | Build a rule set from training trees under a given normaliser (@id@ for
-- exact, 'eraseFeatures' for feature-generalised).
buildRuleSet :: (CCat -> CCat) -> [AutoNode] -> Set.Set TypeChange
buildRuleSet norm = Set.fromList . map (normalizeTC norm) . concatMap inducements

-- | The verdict at one node when classifying a held-out tree against a trained
-- rule set.
data NodeClass
  = NCLeaf
  | NCCombinator        -- ^ binary node reproduced by the combinators
  | NCTypeChangeKnown   -- ^ explained by a type-change rule seen in training
  | NCUnexplained       -- ^ needs a type-change not seen in training
  | NCParseErr
  deriving (Eq, Ord, Show)

-- | Classify every node of a held-out tree (pre-order) against a trained rule
-- set, using @norm@ (which must match the one the set was built with) for
-- type-change lookups. Combinator coverage always uses the raw categories.
classifyTree :: (CCat -> CCat) -> Set.Set TypeChange -> AutoNode -> [NodeClass]
classifyTree norm rules = go
  where
    go (AutoLeaf _ _) = [NCLeaf]
    go (AutoTree c kids) = here : concatMap go kids
      where
        here = case (pcat c, mapM (pcat . nodeCat) kids) of
          (Just parent, Just kcs) -> cls parent kcs
          _                       -> NCParseErr
        cls parent [k]
          | TCUnary (norm k) (norm parent) `Set.member` rules = NCTypeChangeKnown
          | otherwise                                         = NCUnexplained
        cls parent [a, b]
          | combinatorCovers a b parent                              = NCCombinator
          | TCBinary (norm a) (norm b) (norm parent) `Set.member` rules = NCTypeChangeKnown
          | otherwise                                                = NCUnexplained
        cls _ _ = NCParseErr
