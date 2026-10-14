-- | Independent boundary contracts on the existing tokenizer. This proposal
-- performs no parse or corpus load. Green invariants and proposed red controls
-- are separate; default execution is intentionally not a passing release gate.
module Main (main) where

import System.Environment (getArgs)
import Harness
import NL2Proof.Provenance (Span(..))
import NL2Proof.Syntax.Tokenize

sentences :: String -> [String] -> String -> Check
sentences label want source = expectEq label want (map sentText (splitSentences source))

tokens :: String -> [Token] -> Int -> String -> Check
tokens label want offset source = expectEq label want (casedTokens offset source)

main :: IO ()
main = do
  args <- getArgs
  runChecks "abbreviation-boundary-proposal" (case args of
    ["--invariants"] -> invariants
    ["--bounded"] -> bounded
    ["--deferred"] -> deferred
    _ -> invariants ++ bounded ++ deferred)

invariants :: [Check]
invariants =
  [ sentences "ordinary full stops remain sentence boundaries"
      ["Ada is kind.","Bob is red."] "Ada is kind. Bob is red."
  , sentences "ordinary question and exclamation remain terminal"
      ["Is Ada kind?","Bob is red!"] "Is Ada kind? Bob is red!"
  , sentences "empty whitespace is not a sentence" [] " \n\t "
  , sentences "unpunctuated final text is retained" ["Ada is kind"] "Ada is kind"
  , sentences "isolated title does not invent a following name" ["Dr."] "Dr."
  , sentences "comma quote plus reporting suffix remains intact"
      ["\"Ada is kind,\" Bob said."] "\"Ada is kind,\" Bob said."
  , tokens "ordinary terminal period remains its own cased token"
      [Token "Ada" (Span 0 3),Token "works" (Span 4 9),Token "." (Span 9 10)]
      0 "Ada works."
  , tokens "internal apostrophe remains in a word"
      [Token "Ada's" (Span 0 5),Token "book" (Span 6 10)] 0 "Ada's book"
  , tokens "internal hyphen remains in a word"
      [Token "well-respected" (Span 0 14)] 0 "well-respected"
  , expectEq "ordinary adjacent-sentence spans remain document-global"
      [Sentence (Span 2 13) "Ada is red.",Sentence (Span 15 26) "Bob is big."]
      (splitSentences "  Ada is red.  Bob is big.")
  ]

bounded :: [Check]
bounded =
  [ sentences "titled negative name is one sentence"
      ["Dr. Marlon is not analytical."] "Dr. Marlon is not analytical."
  , sentences "full titled name remains within one sentence"
      ["Dr. Yareli Hernandez is empathetic."] "Dr. Yareli Hernandez is empathetic."
  , sentences "honorific class is not a benchmark person list"
      ["Prof. Zorlan is kind."] "Prof. Zorlan is kind."
  , sentences "a title does not suppress the later genuine period"
      ["Dr. Ada is kind.","Bob is red."] "Dr. Ada is kind. Bob is red."
  , sentences "a genuine period before a title still separates clauses"
      ["Bob is red.","Dr. Ada is kind."] "Bob is red. Dr. Ada is kind."
  , expectEq "titled sentence offsets include title punctuation exactly"
      [Sentence (Span 2 18) "Dr. Iris is red.",Sentence (Span 20 32) "Ari is kind."]
      (splitSentences "  Dr. Iris is red.  Ari is kind.")
  , sentences "digit-dot-digit remains internal to the written number"
      ["Pi is 3.14.","Ada is kind."] "Pi is 3.14. Ada is kind."
  , sentences "two numeric components do not create a phantom sentence"
      ["The version is 1.2."] "The version is 1.2."
  , tokens "honorific abbreviation has an exact complete token span"
      [Token "Dr." (Span 0 3),Token "Marlon" (Span 4 10),Token "is" (Span 11 13)
      ,Token "not" (Span 14 17),Token "analytical" (Span 18 28),Token "." (Span 28 29)]
      0 "Dr. Marlon is not analytical."
  , tokens "decimal token keeps internal period without swallowing terminal period"
      [Token "Pi" (Span 0 2),Token "is" (Span 3 5),Token "3.14" (Span 6 10),Token "." (Span 10 11)]
      0 "Pi is 3.14."
  , tokens "abbreviation token offsets respect caller base"
      [Token "Dr." (Span 13 16),Token "Ada" (Span 17 20),Token "." (Span 20 21)]
      13 "Dr. Ada."
  , sentences "closing quote remains attached to its terminated sentence"
      ["\"Ada is kind.\"","Bob is red."] "\"Ada is kind.\" Bob is red."
  , sentences "closing bracket remains attached rather than starting a new sentence"
      ["(Ada is kind.)","Bob is red."] "(Ada is kind.) Bob is red."
  , sentences "question exclamation cluster is one terminator"
      ["Really?!","Ada is kind."] "Really?! Ada is kind."
  , expectEq "trimmed final fragment span matches its exact text"
      [Sentence (Span 2 12) "Ada is red"] (splitSentences "  Ada is red   ")
  ]

-- These require a separate segmentation/quote-context design review. They are
-- target readings of these complete examples, NOT an unconditional abbreviation
-- suppression rule. Ambiguous neighboring examples are documented in the note.
deferred :: [Check]
deferred =
  [ sentences "internal initialism stops are not independent sentences"
      ["U.S. labs work."] "U.S. labs work."
  , sentences "final initialism period can also end a sentence"
      ["Ada lives in the U.S.","Bob works."] "Ada lives in the U.S. Bob works."
  , sentences "final initialism period can precede a capitalized continuation"
      ["The U.S. Navy works."] "The U.S. Navy works."
  , tokens "initialism is one lexical token including its abbreviation periods"
      [Token "U.S." (Span 0 4),Token "labs" (Span 5 9),Token "work" (Span 10 14),Token "." (Span 14 15)]
      0 "U.S. labs work."
  , sentences "quoted exclamation and reporting suffix stay in one attribution unit"
      ["\"Stop!\" Ada said."] "\"Stop!\" Ada said."
  , sentences "quoted exclamation with outer final period stays one unit"
      ["Ada said \"Stop!\"."] "Ada said \"Stop!\"."
  ]
