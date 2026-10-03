-- | Parsing CCGbank @.auto@ derivation trees, and checking whether the
-- combinatory rule set ('NL2Proof.Syntax.CCGRules') reconstructs each node.
--
-- This is the infrastructure for Layer 2's /second/ generator: test cases over
-- real sentences instead of the hand-written 9-case fixture. An @.auto@ line is
-- a fully bracketed gold derivation; parsing it gives a tree whose every node
-- carries the linguist-assigned category. Walking that tree and asking, at each
-- binary node, whether @combine@ of the children's categories yields the node's
-- category is the whole-sentence version of the @GRAMMAR@ coverage check — the
-- corpus is again the external oracle, now at the granularity of real sentences.
--
-- The @.auto@ leaf format embeds a predicate-argument category that itself
-- contains parentheses, so tree structure cannot be tokenised by splitting on
-- @(@ / @)@ naively. The tokeniser here treats everything inside a @<...>@
-- header as opaque and only @(@ / @)@ /outside/ a header as structural.
module NL2Proof.Syntax.CCGDeriv
  ( -- * Derivation trees
    AutoNode(..)
  , nodeCat
  , parseAuto
  , leafHeaders
    -- * Reconstruction check
  , NodeVerdict(..)
  , verdicts
  , fullyReconstructed
  ) where

import NL2Proof.Syntax.CCGBank (parseCCGCat)
import NL2Proof.Syntax.CCGRules (combine, unifiable)

--------------------------------------------------------------------------------
-- Trees
--------------------------------------------------------------------------------

-- | A node of a CCGbank derivation: a leaf (@<L …>@, category + surface word)
-- or an internal node (@<T …>@, category + children).
data AutoNode
  = AutoLeaf String String       -- ^ category, word
  | AutoTree String [AutoNode]   -- ^ category, children
  deriving (Eq, Show)

nodeCat :: AutoNode -> String
nodeCat (AutoLeaf c _) = c
nodeCat (AutoTree c _) = c

--------------------------------------------------------------------------------
-- Tokeniser + parser
--------------------------------------------------------------------------------

data Tok = TOpen | TClose | THeader String
  deriving (Eq, Show)

-- | Tokenise an @.auto@ line. @(@ and @)@ outside a @<…>@ header are structural;
-- everything between @<@ and the next @>@ is one opaque header string (so the
-- parenthesised predarg category inside a leaf header is not mis-split).
tokenize :: String -> Either String [Tok]
tokenize = go
  where
    go [] = Right []
    go (c : cs)
      | c == '('  = (TOpen :)  <$> go cs
      | c == ')'  = (TClose :) <$> go cs
      | c == '<'  = case break (== '>') cs of
                      (hdr, '>' : rest) -> (THeader hdr :) <$> go rest
                      _                 -> Left "unterminated <...> header"
      | c == ' '  = go cs
      | c == '\t' = go cs
      | c == '\n' = go cs
      | c == '\r' = go cs
      | otherwise = Left ("unexpected character outside header: " ++ [c])

-- | Parse a single derivation tree from an @.auto@ line.
parseAuto :: String -> Either String AutoNode
parseAuto s = do
  toks <- tokenize s
  (node, _rest) <- pNode toks
  -- An .auto line is a single tree; any trailing tokens are outer-spacing
  -- artefacts and are tolerated rather than treated as a parse error.
  Right node

pNode :: [Tok] -> Either String (AutoNode, [Tok])
pNode (TOpen : THeader h : rest) =
  case words h of
    ("L" : cat : _) -> case rest of
      (TClose : rest') -> Right (AutoLeaf cat (leafWord h), rest')
      _                -> Left "leaf not closed by ')'"
    ("T" : cat : _) -> do
      (kids, rest') <- pChildren rest
      Right (AutoTree cat kids, rest')
    _ -> Left ("header is neither leaf nor tree: " ++ h)
pNode ts = Left ("expected '(' '<...>' at: " ++ show (take 3 ts))

pChildren :: [Tok] -> Either String ([AutoNode], [Tok])
pChildren (TClose : rest) = Right ([], rest)
pChildren ts = do
  (n, rest)   <- pNode ts
  (ns, rest') <- pChildren rest
  Right (n : ns, rest')

-- | Every leaf of an @.auto@ line as @(category, POS, word)@, in surface order.
--
-- 'AutoLeaf' keeps only category and word; the POS field is needed separately by
-- the tag dictionary that decides which words are proper names
-- ('NL2Proof.Syntax.CCGSupertag.POSModel'). Lines that fail to tokenise yield
-- no leaves rather than an error, matching how the tools skip unparsable lines.
leafHeaders :: String -> [(String, String, String)]
leafHeaders s = case tokenize s of
  Left _     -> []
  Right toks -> [ (c, pos, w) | THeader h <- toks, ("L" : c : pos : _ : w : _) <- [words h] ]

-- | The surface word of a leaf header @L cat modpos pos word predarg@ (5th field).
leafWord :: String -> String
leafWord h = case words h of
  (_ : _ : _ : _ : w : _) -> w
  _                       -> ""

--------------------------------------------------------------------------------
-- Reconstruction check
--------------------------------------------------------------------------------

-- | The verdict at one node of a derivation tree.
data NodeVerdict
  = VLeaf              -- ^ lexical base case
  | VUnary            -- ^ a unary type-changing / type-raising node (accepted as
                      --   corpus-attested; not a binary-combinator obligation)
  | VBinaryOK         -- ^ children combine to this node's category
  | VBinaryUncovered  -- ^ a binary node no combinator reproduces
  | VBadCat String    -- ^ a category on this node failed to parse
  | VArity Int        -- ^ an internal node with an unexpected child count
  deriving (Eq, Show)

-- | Every node's verdict, in pre-order.
verdicts :: AutoNode -> [NodeVerdict]
verdicts (AutoLeaf _ _) = [VLeaf]
verdicts (AutoTree c kids) = here : concatMap verdicts kids
  where
    here = case kids of
      [_]     -> VUnary
      [a, b]  -> binVerdict c a b
      other   -> VArity (length other)

binVerdict :: String -> AutoNode -> AutoNode -> NodeVerdict
binVerdict parent a b =
  case (parseCCGCat (nodeCat a), parseCCGCat (nodeCat b), parseCCGCat parent) of
    (Right la, Right ra, Right pc)
      | any (unifiable pc) (combine la ra) -> VBinaryOK
      | otherwise                          -> VBinaryUncovered
    (Left e, _, _) -> VBadCat e
    (_, Left e, _) -> VBadCat e
    (_, _, Left e) -> VBadCat e

-- | Does every binary node in this tree reconstruct, with no parse or arity
-- errors? (Unary nodes and leaves never block reconstruction.)
fullyReconstructed :: AutoNode -> Bool
fullyReconstructed = all ok . verdicts
  where
    ok VBinaryUncovered = False
    ok (VBadCat _)      = False
    ok (VArity _)       = False
    ok _                = True
