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
  , parseWith
  , parse
    -- * Truth-mode helper
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

-- | Lexical lookup: one list of candidate signs per token. An unknown token
-- yields an empty list, which makes the whole parse fail — reported as a
-- diagnostic by the caller rather than raised as an error here.
lexicalSigns :: Lexicon -> SourceId -> Token -> [Sign]
lexicalSigns lexicon src tok =
  [ Sign (entryCat e) (entrySem e) prov | e <- lookupWord lexicon (tokText tok) ]
  where
    prov = ProvLex src (tokSpan tok) (tokText tok)

-- | CKY over a sequence of per-token candidate sign lists.
--
-- The table is defined by lazy self-reference: @cell@ reads @table@ for shorter
-- spans, and @table@ is built from @cell@. This relies on 'Data.Map' being lazy
-- in its values.
parseWith :: [Rule] -> [[Sign]] -> Cat -> [Sign]
parseWith rules tokenSigns goal =
  [ s | s <- M.findWithDefault [] (0, n) table, sCat s == goal ]
  where
    n = length tokenSigns

    table :: M.Map (Int, Int) [Sign]
    table =
      M.fromList
        [ ((i, len), cell i len)
        | len <- [1 .. n]
        , i <- [0 .. n - len]
        ]

    lexAt = M.fromList (zip [0 :: Int ..] tokenSigns)

    cell i 1   = M.findWithDefault [] i lexAt
    cell i len =
      [ s
      | k <- [1 .. len - 1]
      , l <- M.findWithDefault [] (i, k) table
      , r <- M.findWithDefault [] (i + k, len - k) table
      , s <- combine rules l r
      ]

-- | Parse a token sequence to the goal category using application only.
parse :: Lexicon -> SourceId -> [Token] -> Cat -> [Sign]
parse lexicon src toks =
  parseWith applicationRules (map (lexicalSigns lexicon src) toks)

--------------------------------------------------------------------------------
-- Truth-mode helper
--------------------------------------------------------------------------------

-- | Collapse derivations that differ in shape but agree on category and meaning.
--
-- This is a __truth-mode__ operation and is offered as a helper, not applied by
-- the parser. In provenance-mode two derivations with the same meaning are
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
