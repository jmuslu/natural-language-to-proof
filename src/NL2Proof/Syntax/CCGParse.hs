-- | Whole-sentence bottom-up CCG parsing over real @.auto@ sentences.
--
-- The pieces existed separately: 'NL2Proof.Syntax.CCGRules.combine' (application,
-- composition, coordination, punctuation) and the learned type-change inventory
-- ('NL2Proof.Syntax.CCGTypeChange'). This module __folds them into one parse path__
-- — the open item the findings log named — and runs a CKY chart over a sentence.
--
-- __What it measures, stated precisely.__ Parsing decomposes into supertagging
-- (assign each word a category) and combination (compose them to a root). This
-- module measures the __combination__ half on whole sentences, given the /gold/
-- supertags from CCGbank: does the rule set + type-change inventory actually derive
-- a real sentence bottom-up to (a category unifying with) its gold root? That is an
-- external check on the grammar as a whole, not on isolated @parent --> children@
-- pairs (which `ccg-grammar-coverage` already covers) and not given the gold tree
-- (which `ccg-reconstruct` needs). Using gold supertags is the honest, tractable
-- scope: it isolates the combinatory question from lexical ambiguity, and is stated
-- as such rather than dressed up as full from-words parsing.
module NL2Proof.Syntax.CCGParse
  ( Rules(..)
  , rulesFrom
  , leafCats
  , rootCat
  , chartParse
  , derivesRoot
  ) where

-- Lazy Data.Map (not .Strict): the CKY table is defined by lazy self-reference
-- (cells read the table at smaller spans), which a value-strict fromList would turn
-- into a black hole (<<loop>>). Same reason CCG.hs uses the lazy map.
import qualified Data.Map as M
import qualified Data.Set as Set

import NL2Proof.Syntax.CCGBank (CCat, parseCCGCat)
import NL2Proof.Syntax.CCGRules (combine, unifiable)
import NL2Proof.Syntax.CCGTypeChange (TypeChange(..), inducements, normalizeTC)
import NL2Proof.Syntax.CCGDeriv (AutoNode(..), nodeCat)

-- | The type-change rules folded into the parser, learned from training trees.
data Rules = Rules
  { rUnary :: [(CCat, CCat)]        -- ^ child -> parent (type-change / type-raising)
  , rBinTC :: [(CCat, CCat, CCat)]  -- ^ left,right -> parent (binary changes the
                                    --   combinators do not license: e.g. some
                                    --   punctuation attachment / apposition)
  }

-- | Induce the type-change inventory from training @.auto@ trees, the same way
-- 'ccg-typechange-coverage' does (@normalizeTC id@ over 'inducements'). Kept as a
-- learned set so the parser never hard-codes a rule the corpus does not attest.
rulesFrom :: [AutoNode] -> Rules
rulesFrom trees =
  let tcs = Set.toList (Set.fromList (map (normalizeTC id) (concatMap inducements trees)))
  in Rules { rUnary = [ (a, b)    | TCUnary a b    <- tcs ]
           , rBinTC = [ (a, b, c) | TCBinary a b c <- tcs ] }

-- | Gold leaf categories in left-to-right order; 'Nothing' if any leaf category
-- fails to parse (the sentence is then skipped, not silently mis-parsed).
leafCats :: AutoNode -> Maybe [CCat]
leafCats = traverse parse1 . collect
  where
    collect (AutoLeaf c _)    = [c]
    collect (AutoTree _ kids) = concatMap collect kids
    parse1 s = either (const Nothing) Just (parseCCGCat s)

-- | The gold root category (the top node's category).
rootCat :: AutoNode -> Maybe CCat
rootCat n = either (const Nothing) Just (parseCCGCat (nodeCat n))

-- | CKY over the gold supertags, returning every category derivable for the whole
-- span. @cap@ bounds categories per cell so unary closure (type-raising can chain)
-- and spurious composition ambiguity cannot blow up; the Set only grows, so closure
-- terminates. Cells are @Set CCat@ (dedupe), keyed by @(from,to)@ word boundaries.
chartParse :: Int -> Rules -> [CCat] -> Set.Set CCat
chartParse cap rules leaves =
  M.findWithDefault Set.empty (0, n) table
  where
    n = length leaves
    leafArr = M.fromList (zip [0 ..] leaves)

    table :: M.Map (Int, Int) (Set.Set CCat)
    table = M.fromList
      [ ((i, j), cell i j)
      | len <- [1 .. n], i <- [0 .. n - len], let j = i + len ]

    cell i j
      | j == i + 1 = closeUnary (Set.singleton (leafArr M.! i))
      | otherwise  = closeUnary $ capSet $ Set.fromList
          [ p
          | k <- [i + 1 .. j - 1]
          , l <- Set.toList (M.findWithDefault Set.empty (i, k) table)
          , r <- Set.toList (M.findWithDefault Set.empty (k, j) table)
          , p <- combine l r
                 ++ [ pc | (lc, rc, pc) <- rBinTC rules, unifiable l lc, unifiable r rc ]
          ]

    capSet s
      | Set.size s > cap = Set.fromList (take cap (Set.toList s))
      | otherwise        = s

    closeUnary s0 = capSet (fixpoint s0)
      where
        fixpoint s =
          let s' = Set.union s (Set.fromList
                     [ to | (fr, to) <- rUnary rules
                          , c <- Set.toList s, unifiable c fr ])
          in if Set.size s' == Set.size s || Set.size s' >= cap then s' else fixpoint s'

-- | Does the sentence derive a category unifying with its gold root?
-- 'Nothing' if leaves or root could not be parsed (sentence skipped).
derivesRoot :: Int -> Rules -> AutoNode -> Maybe Bool
derivesRoot cap rules node = do
  ls <- leafCats node
  rc <- rootCat node
  if null ls
    then Nothing
    else Just (any (`unifiable` rc) (Set.toList (chartParse cap rules ls)))
