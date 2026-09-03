-- | CCG derivation: signs, combinatory rules, and a CKY parser.
--
-- The parser returns __all__ derivations rather than one. This is deliberate and
-- is the architecture's central discipline showing up at the smallest scale:
-- parsing is /search/, and search produces a candidate set. Collapsing that set
-- to a single reading is a separate step, performed elsewhere, and logged as a
-- 'NL2Proof.Trace.Decision'.
--
-- A parser that silently returns its first parse has already made that decision
-- and thrown away the record of it — which is exactly the conflation of search
-- with verification that ARCHITECTURE.md forbids.
module NL2Proof.Syntax.CCG
  ( -- * Signs
    Sign(..)
  , signWellTyped
  , renderSign
    -- * Combinatory rules
  , Rule
  , fwdApp
  , bwdApp
  , fwdComp
  , bwdComp
  , applicationRules
  , allRules
  , combine
    -- * Parsing
  , lexicalSigns
  , lexicalSpans
  , parseWith
  , parse
    -- * Fusion helper
  , dedupeByMeaning
  ) where

import Data.List (nubBy)
import qualified Data.Map as M

import NL2Proof.Provenance
import NL2Proof.Semantics.Lambda
import NL2Proof.Syntax.Category
import NL2Proof.Syntax.Lexicon
import NL2Proof.Syntax.Tokenize

--------------------------------------------------------------------------------
-- Signs
--------------------------------------------------------------------------------

-- | A CCG sign: category, meaning, and the derivation that produced it.
--
-- The provenance field is not an afterthought bolted onto the parser — it grows
-- with the derivation, one 'ProvRule' node per combinator application, so a
-- finished sign carries its whole @how@-provenance tree.
data Sign = Sign
  { sCat  :: Cat
  , sSem  :: Term
  , sProv :: Prov
  }
  deriving (Eq, Show)

-- | Does this sign's meaning inhabit the type its category demands?
signWellTyped :: Sign -> Bool
signWellTyped s = typeOf [] (sSem s) == Right (catTy (sCat s))

renderSign :: Sign -> String
renderSign s = show (sCat s) ++ " : " ++ pretty (normalize (sSem s))

--------------------------------------------------------------------------------
-- Combinatory rules
--------------------------------------------------------------------------------

-- | A binary combinatory rule over adjacent signs. Returns every result the rule
-- licenses, which is zero or one for the rules below.
type Rule = Sign -> Sign -> [Sign]

-- | Forward application, @X\/Y  Y  =>  X@.
fwdApp :: Rule
fwdApp (Sign (res :/ arg) f p1) (Sign c x p2)
  | arg == c = [Sign res (App f x) (provRule ">" [p1, p2])]
fwdApp _ _ = []

-- | Backward application, @Y  X\\Y  =>  X@.
bwdApp :: Rule
bwdApp (Sign c x p2) (Sign (res :\ arg) f p1)
  | arg == c = [Sign res (App f x) (provRule "<" [p2, p1])]
bwdApp _ _ = []

-- | Forward composition, @X\/Y  Y\/Z  =>  X\/Z@.
--
-- Not in 'applicationRules'. This fragment has no coordination and no
-- type-raising, so composition adds only spurious ambiguity — derivations that
-- differ in shape but not in meaning. Kept because Stage 2 will need it, and
-- because leaving it defined-but-unused documents the choice.
fwdComp :: Rule
fwdComp (Sign (x :/ y) f p1) (Sign (y' :/ z) g p2)
  | y == y' =
      [ Sign (x :/ z)
             (Lam v (catTy z) (App f (App g (Var v))))
             (provRule ">B" [p1, p2])
      ]
  where
    v = fresh (freeVars f ++ freeVars g) "z"
fwdComp _ _ = []

-- | Backward composition, @Y\\Z  X\\Y  =>  X\\Z@. Also not enabled by default.
bwdComp :: Rule
bwdComp (Sign (y' :\ z) g p2) (Sign (x :\ y) f p1)
  | y == y' =
      [ Sign (x :\ z)
             (Lam v (catTy z) (App f (App g (Var v))))
             (provRule "<B" [p2, p1])
      ]
  where
    v = fresh (freeVars f ++ freeVars g) "z"
bwdComp _ _ = []

-- | The default rule set: application only.
applicationRules :: [Rule]
applicationRules = [fwdApp, bwdApp]

-- | Application plus composition.
allRules :: [Rule]
allRules = [fwdApp, bwdApp, fwdComp, bwdComp]

-- | Every way the given rules let two adjacent signs combine.
combine :: [Rule] -> Sign -> Sign -> [Sign]
combine rules l r = concatMap (\rule -> rule l r) rules

--------------------------------------------------------------------------------
-- Parsing
--------------------------------------------------------------------------------

-- | Lexical lookup for one candidate unit. A unit with no entry yields an empty
-- list, which makes every derivation through it fail — reported as a diagnostic
-- by the caller rather than raised as an error here.
lexicalSigns :: Lexicon -> SourceId -> Token -> [Sign]
lexicalSigns lexicon src tok =
  [ Sign (entryCat e) (entrySem e) prov | e <- lookupWord lexicon (tokText tok) ]
  where
    prov = ProvLex src (tokSpan tok) (tokText tok)

-- | Lexical signs for every unit in a lattice, keyed by the same raw-token
-- range. Ranges with no entry are absent rather than present-and-empty.
lexicalSpans :: Lexicon -> SourceId -> Lattice -> M.Map (Int, Int) [Sign]
lexicalSpans lexicon src l =
  M.filter (not . null) (M.map (lexicalSigns lexicon src) (latUnits l))

-- | CKY over a lattice of candidate lexical spans.
--
-- Two things differ from textbook CKY over a token list, and they are the same
-- thing twice: cells are keyed by @(from, to)@ node pairs rather than
-- @(start, length)@, and a lexical unit is a /base case at its own span/ rather
-- than only at width one. That generalization is the whole of what admits
-- multi-word entries without a segmentation pass in front of the parser. The
-- @"does not"@ unit fills cell @(1, 3)@ directly; if @"does"@ and @"not"@ also
-- had entries, their derivation would fill @(1, 3)@ alongside it and both would
-- be returned.
--
-- Complexity is unchanged at @O(n^3)@ in words, because the node set is still
-- word boundaries. The lattice widens what can fill a cell, not how many cells
-- there are.
--
-- The table is defined by lazy self-reference: @cell@ reads @table@ for strictly
-- shorter spans, and @table@ is built from @cell@. This relies on 'Data.Map'
-- being lazy in its values.
parseWith :: [Rule] -> Int -> M.Map (Int, Int) [Sign] -> Cat -> [Sign]
parseWith rules n lexSpans goal =
  [ s | s <- M.findWithDefault [] (0, n) table, sCat s == goal ]
  where
    table :: M.Map (Int, Int) [Sign]
    table =
      M.fromList
        [ ((i, i + len), cell i (i + len))
        | len <- [1 .. n]
        , i <- [0 .. n - len]
        ]

    cell i j =
      M.findWithDefault [] (i, j) lexSpans
        ++ [ s
           | k <- [i + 1 .. j - 1]
           , l <- M.findWithDefault [] (i, k) table
           , r <- M.findWithDefault [] (k, j) table
           , s <- combine rules l r
           ]

-- | Parse a sentence lattice to the goal category using application only.
parse :: Lexicon -> SourceId -> Lattice -> Cat -> [Sign]
parse lexicon src l =
  parseWith applicationRules (latEnd l) (lexicalSpans lexicon src l)

--------------------------------------------------------------------------------
-- Fusion helper
--------------------------------------------------------------------------------

-- | Collapse derivations that differ in shape but agree on category and meaning.
--
-- This is a __fusion-side__ operation and is offered as a helper, not applied by
-- the parser. Before verification two derivations with the same meaning are
-- distinct objects: if one source is later retracted, the other must survive
-- independently, which is impossible once they have been merged.
--
-- The retained representative is the first derivation found, so its provenance
-- tree is the one that survives — another reason this is a lossy step.
dedupeByMeaning :: [Sign] -> [Sign]
dedupeByMeaning = nubBy same
  where
    same a b =
      sCat a == sCat b
        && alphaEq (normalize (sSem a)) (normalize (sSem b))
