-- | Sentence splitting and tokenization, with exact character spans.
--
-- Spans are the foundation of the traceability requirement: every atomic clause
-- in the formal output must be traceable back to its source text span,
-- independent of output mode. If token spans are wrong, every provenance tag
-- built on top of them is wrong, so this module keeps offsets exact rather than
-- approximate — punctuation is excluded from a token's span, not merely stripped
-- from its text.
module NL2Proof.Syntax.Tokenize
  ( Token(..)
  , Sentence(..)
  , splitSentences
  , tokenizeSentence
  , rawTokens
  , mergePhrases
  ) where

import Data.Char (isAlphaNum, isSpace, toLower)
import Data.List (dropWhileEnd)

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

-- | Tokenize a sentence, merging multi-word lexicon entries.
--
-- The predicate is @inLexicon@ over the active lexicon; it is passed in rather
-- than imported so this module stays independent of the fragment.
tokenizeSentence :: (String -> Bool) -> Int -> Sentence -> [Token]
tokenizeSentence known maxPhrase s =
  mergePhrases known maxPhrase (rawTokens (spanStart (sentSpan s)) (sentText s))

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

-- | Greedily merge runs of tokens that form a single lexicon key, longest match
-- first, so @"does not"@ becomes one token.
mergePhrases :: (String -> Bool) -> Int -> [Token] -> [Token]
mergePhrases known maxPhrase = go
  where
    go [] = []
    go ts@(t : rest) =
      case [ n
           | n <- [maxPhrase, maxPhrase - 1 .. 2]
           , n <= length ts
           , known (joinText (take n ts))
           ] of
        (n : _) ->
          let grp = take n ts
          in Token (joinText grp) (foldr1 spanUnion (map tokSpan grp)) : go (drop n ts)
        [] -> t : go rest

    joinText = unwords . map tokText
