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
  , chartParseMulti
  , chartParseScored
  , derivesRoot
  ) where

import Data.List (sortBy)
import Data.Ord (comparing, Down(..))
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

-- | CKY over one category per word (the gold supertags). See 'chartParseMulti'.
chartParse :: Int -> Rules -> [CCat] -> Set.Set CCat
chartParse cap rules = chartParseMulti cap rules . map (: [])

-- | CKY over a /set of candidate categories per word/, returning every category
-- derivable for the whole span. Passing singletons recovers gold-supertag parsing
-- ('chartParse'); passing a supertagger's top-k per word gives from-words parsing.
-- @cap@ bounds categories per cell so lexical ambiguity, unary closure (type-raising
-- can chain) and spurious composition ambiguity cannot blow up; the Set only grows,
-- so closure terminates. Cells are @Set CCat@ (dedupe), keyed by @(from,to)@ word
-- boundaries.
chartParseMulti :: Int -> Rules -> [[CCat]] -> Set.Set CCat
chartParseMulti cap rules cellsIn =
  M.findWithDefault Set.empty (0, n) table
  where
    n = length cellsIn
    leafArr = M.fromList (zip [0 ..] cellsIn)

    table :: M.Map (Int, Int) (Set.Set CCat)
    table = M.fromList
      [ ((i, j), cell i j)
      | len <- [1 .. n], i <- [0 .. n - len], let j = i + len ]

    cell i j
      | j == i + 1 = closeUnary (capSet (Set.fromList (leafArr M.! i)))
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

-- | Scored (Viterbi) CKY with a real beam. Each word carries scored candidate
-- categories (log-probabilities from the supertagger); a derivation's score is the
-- sum of its parts, unary type-change costs a fixed penalty, and each cell keeps only
-- the top-@beam@ categories by score. Unlike the arbitrary @cap@ of 'chartParseMulti',
-- the beam retains the *most probable* categories, so it makes parsing both faster
-- and more accurate on ambiguous, longer sentences. Returns the whole-span categories
-- with their best scores, highest first.
chartParseScored :: Int -> Rules -> [[(CCat, Double)]] -> [(CCat, Double)]
chartParseScored beam rules cellsIn =
  sortByScore (M.toList (M.findWithDefault M.empty (0, n) table))
  where
    n = length cellsIn
    leafArr = M.fromList (zip [0 ..] cellsIn)
    unaryPenalty = 1.0

    sortByScore = sortBy (comparing (Down . snd))
    beamCell m = M.fromList (take beam (sortByScore (M.toList m)))

    table :: M.Map (Int, Int) (M.Map CCat Double)
    table = M.fromList
      [ ((i, j), cell i j)
      | len <- [1 .. n], i <- [0 .. n - len], let j = i + len ]

    cell i j
      | j == i + 1 = beamCell (closeUnary (M.fromListWith max (leafArr M.! i)))
      | otherwise  = beamCell $ closeUnary $ M.fromListWith max
          [ (p, sl + sr)
          | k <- [i + 1 .. j - 1]
          , (l, sl) <- M.toList (M.findWithDefault M.empty (i, k) table)
          , (r, sr) <- M.toList (M.findWithDefault M.empty (k, j) table)
          , p <- combine l r
                 ++ [ pc | (lc, rc, pc) <- rBinTC rules, unifiable l lc, unifiable r rc ]
          ]

    -- unary closure keeping the best score per category. Type-change rules are a
    -- finite set of concrete (from,to) pairs and each step subtracts a penalty, so
    -- the reachable set is finite and scores are monotone non-increasing: once a
    -- category is present its score cannot improve, so size-stability terminates.
    closeUnary m0 = go (0 :: Int) m0
      where
        go it m
          | it > 6 = m
          | otherwise =
              let adds = M.fromListWith max
                    [ (to, s - unaryPenalty)
                    | (fr, to) <- rUnary rules, (c, s) <- M.toList m, unifiable c fr ]
                  m' = M.unionWith max m adds
              in if M.size m' == M.size m then m' else go (it + 1) m'

-- | Does the sentence derive a category unifying with its gold root?
-- 'Nothing' if leaves or root could not be parsed (sentence skipped).
derivesRoot :: Int -> Rules -> AutoNode -> Maybe Bool
derivesRoot cap rules node = do
  ls <- leafCats node
  rc <- rootCat node
  if null ls
    then Nothing
    else Just (any (`unifiable` rc) (Set.toList (chartParse cap rules ls)))
