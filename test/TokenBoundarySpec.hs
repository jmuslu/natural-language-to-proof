module Main (main) where

import Harness
import NL2Proof.Provenance (Span(..))
import NL2Proof.Syntax.Tokenize

sent :: String -> String -> [String] -> Check
sent label input expected = expectEq label expected (map sentText (splitSentences input))
tok :: String -> String -> [String] -> Check
tok label input expected = expectEq label expected (map tokText (casedTokens 0 input))

main :: IO ()
main = runChecks "token-boundaries" $
  [ expectEq "trim final span" [Sentence (Span 2 12) "Ada is red"]
      (splitSentences "  Ada is red   ")
  , expectEq "trim unpunctuated second span"
      [Sentence (Span 1 5) "Ada.",Sentence (Span 7 10) "Bob"]
      (splitSentences " Ada.  Bob \n")
  , sent "decimal internal stop" "Pi is 3.14. Ada works." ["Pi is 3.14.","Ada works."]
  , sent "multiple numeric components" "Version 1.2.3 works." ["Version 1.2.3 works."]
  , tok "decimal plus terminal stop" "3.14." ["3.14", "."]
  , tok "numeric components token" "1.2.3" ["1.2.3"]
  , expectEq "offset decimal tokens"
      [Token "Pi" (Span 7 9),Token "3.14" (Span 10 14),Token "." (Span 14 15)]
      (casedTokens 7 "Pi 3.14.")
  , sent "mixed terminator cluster" "Really?! Ada works!?!" ["Really?!","Ada works!?!"]
  , sent "repeated terminators" "Ada!! Bob??" ["Ada!!","Bob??"]
  , expectEq "cluster spans" [Sentence (Span 2 8) "What?!",Sentence (Span 10 14) "Yes!"]
      (splitSentences "  What?!  Yes!")
  , sent "ordinary stops" "Ada. Bob! Cat?" ["Ada.","Bob!","Cat?"]
  , sent "empty whitespace" " \n\t" []
  , sent "unpunctuated fragment" "Ada" ["Ada"]
  , sent "dot needs left digit" "a.3" ["a.","3"]
  , sent "dot needs right digit" "3.a" ["3.","a"]
  , sent "consecutive decimal dots unchanged" "1..2" ["1.",".","2"]
  , tok "leading decimal dot unchanged" ".5" [".","5"]
  , tok "trailing decimal dot unchanged" "5." ["5","."]
  , sent "mixed cluster dot quote boundaries" "What?!.'" ["What?!",".","'"]
  , sent "dot at start" ".3" [".","3"]
  , sent "dot at end" "3." ["3."]
  , sent "space after dot breaks adjacency" "3. 14" ["3.","14"]
  , sent "space before dot breaks adjacency" "3 .14" ["3 .","14"]
  , sent "dots not folded into cluster" "What?!. Bob" ["What?!",".","Bob"]
  , sent "dot does not collect following question" "Ada.?" ["Ada.","?"]
  , sent "ellipsis remains unchanged" "Ada..." ["Ada.",".","."]
  , sent "honorific deliberately unchanged" "Dr. Ada." ["Dr.","Ada."]
  , sent "initialism deliberately unchanged" "U.S. labs." ["U.","S.","labs."]
  , tok "apostrophe and hyphen preserved" "Ada's well-known book." ["Ada's","well-known","book","."]
  , tok "trailing quote retained" "'Ada'" ["'","Ada","'"]
  , tok "nondigit dot remains punctuation" "a.3 3.a" ["a",".","3","3",".","a"]
  , tok "question cluster still individual lexical punctuation" "What?!" ["What","?","!"]
  , expectEq "raw token behavior preserved" [Token "3.14" (Span 2 6)] (rawTokens 2 "3.14.")
  ] ++
  [ expect ("sentence exact source slice: " ++ show input)
      (all (\(Sentence (Span a b) s) -> take (b-a) (drop a input) == s) (splitSentences input))
  | input <- ["  Ada is red   ","  Pi is 3.14.  Bob?! \n","Version 1.2.3"," \n\t"]
  ]
