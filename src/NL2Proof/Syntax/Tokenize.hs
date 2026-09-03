-- | Sentence splitting, tokenization, and the lexical lattice, with exact
-- character spans.
--
-- Spans are the foundation of the traceability requirement: every atomic clause
-- in the formal output must be traceable back to its source text span. If token
-- spans are wrong, every provenance tag built on top of them is wrong, so this
-- module keeps offsets exact rather than approximate -- punctuation is excluded
-- from a token's span, not merely stripped from its text.
--
-- == Segmentation is search, not a preprocessing step
--
-- Multi-word lexicon entries make segmentation ambiguous. @"does not"@ can be
-- one lexical unit or two; a fused compound entry like @"red dragon"@ competes
-- with an adjective applied to a noun over the same two words. Settling that
-- before parsing settles it with strictly less information than the parser has,
-- and settles it without a record.
--
-- So this module does not settle it. It emits a 'Lattice' -- every lexicon
-- match over every range of words, all of them kept -- and
-- "NL2Proof.Syntax.CCG" parses the lattice directly. Competing segmentations
-- become competing derivations, which the candidate-set machinery already
-- handles: they surface as 'NL2Proof.Trace.ParseAmbiguity' with a logged
-- 'NL2Proof.Trace.Decision', exactly like any other ambiguity.
module NL2Proof.Syntax.Tokenize
  ( -- * Tokens and sentences
    Token(..)
  , Sentence(..)
  , splitSentences
  , rawTokens
  , joinTokens
    -- * The lexical lattice
  , Lattice(..)
  , latEnd
  , sentenceLattice
  , uncoveredTokens
  , latticeForks
  ) where

import Data.Char (isAlphaNum, isSpace, toLower)
import Data.List (dropWhileEnd)
import qualified Data.Map as M

import NL2Proof.Provenance

-- | A token: lower-cased text plus the span of the original characters it came
-- from.
data Token = Token
  { tokText :: String
  , tokSpan :: Span
  }
  deriving (Eq, Show)

-- | A sentence: its span in the document, and its raw text.
data Sentence = Sentence
  { sentSpan :: Span
  , sentText :: String
  }
  deriving (Eq, Show)

-- | Split a document on @.@, @!@, @?@. Spans are relative to the whole document,
-- so downstream provenance is document-global.
splitSentences :: String -> [Sentence]
splitSentences src = filter (not . null . sentText) (map trim (go 0 src))
  where
    isTerm c = c `elem` ".!?"

    go i cs = case break isTerm cs of
      (chunk, []) ->
        [Sentence (Span i (i + length chunk)) chunk | not (all isSpace chunk)]
      (chunk, term : rest) ->
        let len = length chunk + 1
        in Sentence (Span i (i + len)) (chunk ++ [term]) : go (i + len) rest

    -- Pull the span start forward past leading whitespace so a sentence's span
    -- begins at its first real character.
    trim (Sentence (Span a b) s) =
      let lead = length (takeWhile isSpace s)
      in Sentence (Span (a + lead) b) (dropWhileEnd isSpace (dropWhile isSpace s))

-- | Whitespace tokenization. @base@ is the document offset of the first
-- character of @str@.
rawTokens :: Int -> String -> [Token]
rawTokens base str = go base str
  where
    go _ [] = []
    go i (c : rest)
      | isSpace c = go (i + 1) rest
    go i cs =
      let (word, rest) = break isSpace cs
          -- Exclude surrounding punctuation from the span, not just the text,
          -- so the span points at the characters the token actually is.
          pre   = length (takeWhile (not . isAlphaNum) word)
          core  = dropWhileEnd (not . isAlphaNum) (drop pre word)
          tok   = Token (map toLower core) (Span (i + pre) (i + pre + length core))
          toks  = if null core then [] else [tok]
      in toks ++ go (i + length word) rest

--------------------------------------------------------------------------------
-- The lexical lattice
--------------------------------------------------------------------------------

-- | Candidate lexical units over one sentence, indexed by raw-token range.
--
-- Nodes are raw-token boundaries, @0@ through 'latEnd'; a unit spanning
-- @(i, j)@ is an edge from node @i@ to node @j@, with @j@ exclusive. There is at
-- most one unit per range, because the range determines the text -- lexical
-- /ambiguity/ of a unit is a list of 'NL2Proof.Syntax.Lexicon.Entry' and lives
-- in the lexicon, not here.
--
-- What lives here is /segmentation/ ambiguity: two units whose ranges overlap,
-- competing for the same words. Both are kept. 'latticeForks' finds them.
--
-- Whitespace boundaries are taken as given, which is why nodes are word indices
-- rather than character offsets. That is a fact about this language, not a
-- simplification: segmentation ambiguity in English is about how many words a
-- lexical unit spans, never about where a word ends. A lattice over character
-- offsets is what a language without whitespace needs, and it would cost a
-- factor of @(chars per word)^3@ in the parser for nothing here.
data Lattice = Lattice
  { latRaw   :: [Token]
    -- ^ Whitespace tokenization, one 'Token' per word. Diagnostics, display and
    -- provenance fallbacks use these; the parser does not.
  , latUnits :: M.Map (Int, Int) Token
    -- ^ Every lexicon match, keyed by its @(from, to)@ raw-token range. A
    -- single-word match is a @(i, i + 1)@ unit.
  }
  deriving (Eq, Show)

-- | The end node of the whole sentence, which is the raw-token count.
latEnd :: Lattice -> Int
latEnd = length . latRaw

-- | Build a sentence's lattice: record every lexicon match over every range of
-- at most @maxPhrase@ words, and choose nothing.
--
-- The predicate is @inLexicon@ over the active lexicon; it is passed in rather
-- than imported so this module stays independent of the fragment.
sentenceLattice :: (String -> Bool) -> Int -> Sentence -> Lattice
sentenceLattice known maxPhrase s = Lattice raw units
  where
    raw = rawTokens (spanStart (sentSpan s)) (sentText s)
    n = length raw
    units =
      M.fromList
        [ ((i, i + len), unit)
        | i <- [0 .. n - 1]
        , len <- [1 .. maxPhrase]
        , i + len <= n
        , let unit = joinTokens (take len (drop i raw))
        , known (tokText unit)
        ]

-- | Glue adjacent raw tokens into one unit: single-spaced text, union of spans.
--
-- The span is a union, so a multi-word unit's span covers the whitespace between
-- its words. That is correct -- the unit really is those characters -- and it is
-- the only place a span is wider than the characters of a single word.
joinTokens :: [Token] -> Token
joinTokens ts = Token (unwords (map tokText ts)) (foldr1 spanUnion (map tokSpan ts))

-- | Raw tokens that no unit covers.
--
-- This is the honest notion of "unknown word" under a lattice, and it differs
-- from asking whether each raw token is a lexicon key: @"not"@ is not a key in
-- the fragment, but the @"does not"@ unit covers it, so it is not unknown. A
-- token covered by nothing breaks every path through the lattice, which is why
-- it is worth reporting on its own rather than leaving it to a bare parse
-- failure.
uncoveredTokens :: Lattice -> [Token]
uncoveredTokens l =
  [ t
  | (i, t) <- zip [0 :: Int ..] (latRaw l)
  , not (any (\(a, b) -> a <= i && i < b) (M.keys (latUnits l)))
  ]

-- | Distinct units whose ranges overlap: the segmentation forks the lattice is
-- preserving, in range order.
--
-- Containment counts. A multi-word unit competing with its own parts is the
-- ordinary case and the one a greedy longest-match pass resolved silently, so
-- excluding it would miss the whole point.
latticeForks :: Lattice -> [(Token, Token)]
latticeForks l =
  [ (u, v)
  | (k1@(a, b), u) <- M.toList (latUnits l)
  , (k2@(c, d), v) <- M.toList (latUnits l)
  , k1 < k2
  , a < d && c < b
  ]
