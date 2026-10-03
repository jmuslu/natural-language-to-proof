-- | The CCGbank parser's semantic layer and its Pipeline integration.
--
-- Runs without the licensed corpus: the parser is given a miniature tag
-- dictionary built from hand-listed @(word, category)@ observations, so what is
-- tested is the semantic layer (closed-class entries, open-class templates,
-- combinator semantics, donkey binding, definite descriptions, conversion to
-- ProofWriter form) and the ambiguity/decision discipline — not CCGbank's
-- statistics. Expected forms are compared with 'alphaEq', as in the core suite.
module Main (main) where

import Data.List (isInfixOf)
import qualified Data.Set as Set

import Harness
import NL2Proof.Bench.JSON
import NL2Proof.Bench.ProofWriter
import NL2Proof.DRT.Build (describeIota, resolveLocalAnaphora)
import NL2Proof.DRT.Types
import NL2Proof.Pipeline
import NL2Proof.Provenance
import NL2Proof.Semantics.CCGSem
import NL2Proof.Semantics.Lambda
import NL2Proof.Syntax.CCGBank (CCat(..), parseCCGCat)
import NL2Proof.Syntax.CCGParse (Rules(..))
import NL2Proof.Syntax.CCGSemParse
import NL2Proof.Syntax.CCGSupertag (buildPOSModel, buildTagModel)
import NL2Proof.Syntax.Lexicon (fragmentLexicon)
import NL2Proof.Syntax.Tokenize
import NL2Proof.Trace

main :: IO ()
main = runChecks "ccgsem"
  (closedChecks ++ templateChecks ++ combinatorChecks ++ termChecks
   ++ tokenChecks ++ sentenceChecks ++ disciplineChecks ++ goldChecks)

--------------------------------------------------------------------------------
-- Fixtures
--------------------------------------------------------------------------------

cc :: String -> CCat
cc s = either error id (parseCCGCat s)

-- | A miniature "CCGbank": each observation once, so every listed category is
-- offered. Smoothing and the seen-rules constraint are off (there is no corpus
-- to smooth toward or to have seen rules in).
mini :: SemModel
mini = (defaultSemModel tm pm rs Set.empty) { smAlpha = 0, smSeenRules = False }
  where
    obs =
      [ ("the", "NP[nb]/N"), ("All", "NP[nb]/N"), ("all", "NP[nb]/N")
      , ("cow", "N"), ("dog", "N"), ("eagle", "N"), ("bald", "N/N")
      , ("is", "(S[dcl]\\NP)/(S[adj]\\NP)"), ("are", "(S[dcl]\\NP)/(S[adj]\\NP)")
      , ("does", "(S[dcl]\\NP)/(S[b]\\NP)")
      , ("not", "(S\\NP)\\(S\\NP)"), ("not", "(S[adj]\\NP)/(S[adj]\\NP)")
      , ("big", "S[adj]\\NP"), ("red", "S[adj]\\NP"), ("red", "N/N")
      , ("round", "S[adj]\\NP"), ("cold", "S[adj]\\NP"), ("cold", "N/N"), ("cold", "N")
      , ("green", "N/N"), ("quiet", "S[adj]\\NP"), ("smart", "S[adj]\\NP")
      , ("Anne", "N")
      , ("likes", "(S[dcl]\\NP)/NP"), ("sees", "(S[dcl]\\NP)/NP")
      , ("chase", "(S[b]\\NP)/NP")
      , ("If", "(S/S)/S[dcl]"), ("if", "(S/S)/S[dcl]"), ("then", "S/S")
      , ("something", "NP"), ("someone", "NP"), ("it", "NP"), ("they", "NP")
      , ("things", "N"), ("people", "N"), ("and", "conj"), (",", ","), (".", ".")
      ]
    tm = buildTagModel [ (w, cc c) | (w, c) <- obs ]
    pm = buildPOSModel [ (w, if w == "Anne" then "NNP" else "XX") | (w, _) <- obs ]
    rs = Rules { rUnary = [(cc "N", cc "NP")], rBinTC = [] }

run :: String -> SentenceResult
run t = case prSentences (runPipelineWith (CCGBankParser mini) (SourceId "t") t) of
  [r] -> r
  rs  -> error ("expected one sentence, got " ++ show (length rs))

formOf :: String -> Maybe Term
formOf = srForm . run

statementOf :: String -> Either String Statement
statementOf t = maybe (Left "no DRS") drsToStatement (srDRS (run t))

decisionKinds :: SentenceResult -> [String]
decisionKinds = map decKind . traceDecisions . srTrace

diagKinds :: SentenceResult -> [DiagKind]
diagKinds = map diagKind . traceDiagnostics . srTrace

x_ :: Term
x_ = Var "x"

the :: [String] -> Term
the ps = iota (Lam "x" TyE (foldr1 TAnd [ App (pred1 p) x_ | p <- ps ]))

expectForm :: String -> String -> Term -> Check
expectForm name text want = case formOf text of
  Just got | alphaEq got want -> ok name
           | otherwise -> bad name ("got " ++ pretty got ++ ", want " ++ pretty want)
  Nothing -> bad name "no form (no parse or type failure)"

expectStmt :: String -> String -> Statement -> Check
expectStmt name text want = case statementOf text of
  Right got | normalizeStatement got == normalizeStatement want -> ok name
            | otherwise -> bad name ("got " ++ renderStatement got)
  Left e -> bad name ("did not convert: " ++ e)

fact :: String -> String -> String -> Pol -> Statement
fact a r b p = Fact (Atom a r b p)

atom :: String -> String -> String -> Pol -> Atom
atom = Atom

--------------------------------------------------------------------------------
-- 1. Closed-class entries
--------------------------------------------------------------------------------

closedChecks :: [Check]
closedChecks =
  [ case [ (w, c) | (w, c, LexTerm t _ _) <- closedTable 0, typeOf [] t /= maybe (Left (Unbound "?")) Right (semTy c) ] of
      [] -> ok "every closed-class entry inhabits semTy of its category"
      xs -> bad "every closed-class entry inhabits semTy of its category" (show xs)
  , expect "closed-class words include the determiners, copula, negation, if/then, and, pronouns, sortals"
      (all isClosedClass ["the", "all", "is", "are", "not", "does", "if", "then", "and", "something", "someone", "it", "they", "things", "people"])
  , expect "closed-class lookup is case-insensitive (The, If, All)"
      (all isClosedClass ["The", "If", "All"])
  , expectEq "'is' has no entry as a transitive verb (closed class never falls through)"
      0 (length (closedEntries 0 "is" (cc "(S[dcl]\\NP)/NP")))
  , expectEq "'not' has entries for exactly the three VP-negation categories"
      3 (length [ () | ("not", _, _) <- closedTable 0 ])
  , expect "'not' carries a scope stipulation"
      (all (\(_, _, it) -> case it of LexTerm _ _ (Just st) -> stKind st == "scope"; _ -> False)
           [ e | e@("not", _, _) <- closedTable 0 ])
  , expect "punctuation is structural under any punctuation category"
      (closedEntries 0 "," (cc ",") == [LexStructural "punctuation \",\""])
  , expect "pronouns at different positions are different anaphors"
      (constNames (lexTerm (closedEntries 2 "it" (cc "NP"))) /= constNames (lexTerm (closedEntries 7 "it" (cc "NP"))))
  ]
  where
    lexTerm (LexTerm t _ _ : _) = t
    lexTerm _                   = Con "none" TyT

--------------------------------------------------------------------------------
-- 2. Open-class templates
--------------------------------------------------------------------------------

templateChecks :: [Check]
templateChecks =
  [ tmplTyped "N" "N", tmplTyped "N/N" "N/N", tmplTyped "S[adj]\\NP" "S[adj]\\NP"
  , tmplTyped "S[dcl]\\NP" "S[dcl]\\NP", tmplTyped "(S[dcl]\\NP)/NP" "(S[dcl]\\NP)/NP"
  , tmplTyped "(S[b]\\NP)/NP" "(S[b]\\NP)/NP"
  , expect "no template for PP/NP (uninterpreted, not an opaque constant)"
      (openTemplate "of" (cc "PP/NP") == Nothing)
  , expect "no template for (S\\NP)\\(S\\NP) adverbs"
      (openTemplate "quickly" (cc "(S\\NP)\\(S\\NP)") == Nothing)
  , expect "adjective predicate keeps its form" (predOf "big" "S[adj]\\NP" == ["big"])
  , expect "finite verb predicate is lemmatised" (predOf "chases" "(S[dcl]\\NP)/NP" == ["chase"])
  , expect "a verb mis-tagged S[b] is lemmatised the same way" (predOf "likes" "(S[b]\\NP)/NP" == ["like"])
  , expectEq "lemma3sg likes" "like" (lemma3sg "likes")
  , expectEq "lemma3sg chases" "chase" (lemma3sg "chases")
  , expectEq "lemma3sg watches" "watch" (lemma3sg "watches")
  , expectEq "lemma3sg kisses" "kiss" (lemma3sg "kisses")
  , expectEq "lemma3sg leaves -ss alone" "miss" (lemma3sg "miss")
  , expect "name item is NP-typed and keeps case"
      (case nameItem "Anne" of
         LexTerm t _ _ -> typeOf [] t == Right tyGQ && "Anne" `elem` constNames t
         _ -> False)
  ]
  where
    tmplTyped name c = case openTemplate "w" (cc c) of
      Just (LexTerm t _ _) | Just ty <- semTy (cc c), typeOf [] t == Right ty -> ok ("template well-typed: " ++ name)
      _ -> bad ("template well-typed: " ++ name) "missing or ill-typed"
    predOf w c = case openTemplate w (cc c) of
      Just (LexTerm t _ _) -> constNames t
      _ -> []

--------------------------------------------------------------------------------
-- 3. Combinator semantics
--------------------------------------------------------------------------------

combinatorChecks :: [Check]
combinatorChecks =
  [ expect "VP coordination keeps one subject quantifier (Partee-Rooth lowering)"
      (case coordTerm TAnd (tyGQ ~> TyT) vp1 vp2 of
         Just c -> alphaEq (simplifyConj (normalize (App c something)))
                     (TExists "x" TyE (TAnd (App (pred1 "thing") x_)
                        (TAnd (App (pred1 "big") x_) (App (pred1 "red") x_))))
         Nothing -> False)
  , expect "modifier coordination is pointwise and well-typed"
      (case coordTerm TAnd (tyPred1 ~> tyPred1) m1 m2 of
         Just c -> typeOf [] c == Right (tyPred1 ~> tyPred1)
         Nothing -> False)
  , expect "coordination at a type not ending in t is refused"
      (case coordTerm TAnd TyE vp1 vp2 of { Nothing -> True; Just _ -> False })
  , expect "comma and 'and' coordinate as conjunction, 'or' as disjunction"
      (fmap (\f -> f t1 t2) (coordinatorOp ",") == Just (TAnd t1 t2)
         && fmap (\f -> f t1 t2) (coordinatorOp "or") == Just (TOr t1 t2)
         && maybe True (const False) (coordinatorOp "but"))
  , expect "N -> NP is the generic universal, with a bare-np stipulation"
      (case unarySem (cc "N") (cc "NP") of
         Just (f, Just st) -> stKind st == "bare-np"
           && alphaEq (normalize (App (f (pred1 "dog")) (pred1 "bark")))
                      (TForall "x" TyE (TImp (App (pred1 "dog") x_) (App (pred1 "bark") x_)))
         _ -> False)
  , expect "type-raising has meaning \\f. f(a) and no stipulation"
      (case unarySem (cc "NP") (cc "S/(S\\NP)") of
         Just (f, Nothing) -> typeOf [] (f something) == Right ((tyGQ ~> TyT) ~> TyT)
         _ -> False)
  , expect "a learned type-change with no fixed meaning gets none"
      (case unarySem (cc "S[pss]\\NP") (cc "NP\\NP") of { Nothing -> True; Just _ -> False })
  , expect "composition has the composed-over argument's type"
      (typeOf [] (composeTerm tyGQ (Lam "p" TyT (Var "p")) (Lam "q" tyGQ (App (Var "q") (pred1 "big"))))
         == Right (tyGQ ~> TyT))
  ]
  where
    vp p = Lam "S" tyGQ (App (Var "S") (Lam "x" TyE (App (pred1 p) x_)))
    vp1 = vp "big"
    vp2 = vp "red"
    m p = Lam "P" tyPred1 (Lam "x" TyE (TAnd (App (pred1 p) x_) (App (Var "P") x_)))
    m1 = m "cold"
    m2 = m "green"
    something = Lam "P" tyPred1 (TExists "x" TyE (TAnd (App (pred1 "thing") x_) (App (Var "P") x_)))
    t1 = Con "a" TyT
    t2 = Con "b" TyT

--------------------------------------------------------------------------------
-- 4. Term-level helpers
--------------------------------------------------------------------------------

termChecks :: [Check]
termChecks =
  [ expect "simplifyConj flattens and drops repeated conjuncts"
      (simplifyConj (TAnd (TAnd a b) (TAnd a c)) == TAnd a (TAnd b c))
  , expect "canonicalAC identifies conjunct orders" (canonicalAC (TAnd a b) == canonicalAC (TAnd b a))
  , expect "canonicalAC does not identify different connectives"
      (canonicalAC (TAnd a b) /= canonicalAC (TOr a b))
  , expectEq "describeIota names a description by its content, in order"
      "bald eagle" (describeIota (Lam "x" TyE (TAnd (App (pred1 "bald") x_) (App (pred1 "eagle") x_))))
  , expect "iota is typed (e -> t) -> e" (typeOf [] (the ["cow"]) == Right TyE)
  ]
  where
    a = App (pred1 "a") (entity "j")
    b = App (pred1 "b") (entity "j")
    c = App (pred1 "c") (entity "j")

--------------------------------------------------------------------------------
-- 5. Tokens
--------------------------------------------------------------------------------

tokenChecks :: [Check]
tokenChecks =
  [ expectEq "casedTokens keeps case and splits punctuation"
      ["All", "cold", ",", "green", "things", "are", "quiet", "."]
      (map tokText (casedTokens 0 "All cold, green things are quiet."))
  , expect "casedTokens spans point at their text"
      (all (\t -> slice (tokSpan t) src == tokText t) (casedTokens 0 src))
  ]
  where
    src = "If Anne is big, then Anne is red."
    slice (Span i j) s = take (j - i) (drop i s)

--------------------------------------------------------------------------------
-- 6. ProofWriter-style sentences, end to end
--------------------------------------------------------------------------------

sentenceChecks :: [Check]
sentenceChecks =
  [ expectForm "definite + predicative adjective" "The cow is big."
      (App (pred1 "big") (the ["cow"]))
  , expectStmt "  ... as a ProofWriter fact" "The cow is big." (fact "cow" "is" "big" Pos)
  , expectForm "proper name" "Anne is big." (App (pred1 "big") (entity "Anne"))
  , expectStmt "transitive verb with a modified definite object" "The cow likes the bald eagle."
      (fact "cow" "likes" "bald eagle" Pos)
  , expectForm "do-support negation, subject wide scope" "The cow does not chase the dog."
      (TNot (apply (pred2 "chase") [the ["cow"], the ["dog"]]))
  , expectStmt "  ... as a negated fact" "The cow does not chase the dog."
      (fact "cow" "chases" "dog" Neg)
  , expectForm "conditional with indefinite antecedent and pronoun" "If something is big then it is red."
      (TImp (TExists "x" TyE (TAnd (App (pred1 "thing") x_) (App (pred1 "big") x_)))
            (App (pred1 "red") (mkAnaphor "it_5")))
  , expectStmt "  ... donkey-bound into a ProofWriter rule" "If something is big then it is red."
      (Rule [atom "something" "is" "big" Pos] (atom "something" "is" "red" Pos))
  , expect "  ... and the binding is a logged anaphora decision"
      ("anaphora" `elem` decisionKinds (run "If something is big then it is red."))
  , expectForm "universal determiner over modified sortal noun" "All red things are big."
      (TForall "x" TyE (TImp (TAnd (App (pred1 "red") x_) (App (pred1 "thing") x_)) (App (pred1 "big") x_)))
  , expectStmt "  ... as a rule over 'something'" "All red things are big."
      (Rule [atom "something" "is" "red" Pos] (atom "something" "is" "big" Pos))
  , expectStmt "bare plural (people -> someone)" "Red people are big."
      (Rule [atom "someone" "is" "red" Pos] (atom "someone" "is" "big" Pos))
  , expect "  ... and the generic reading is a logged bare-np decision"
      ("bare-np" `elem` decisionKinds (run "Red people are big."))
  , expectStmt "comma-listed modifiers" "All cold, green things are quiet."
      (Rule [atom "something" "is" "cold" Pos, atom "something" "is" "green" Pos]
            (atom "something" "is" "quiet" Pos))
  , expectStmt "adjective coordination with negation (NAF premise)"
      "If someone is cold and not round then they are smart."
      (Rule [atom "someone" "is" "cold" Pos, atom "someone" "is" "round" Neg]
            (atom "someone" "is" "smart" Pos))
  , expect "  ... and the negation scope is a logged decision"
      ("scope" `elem` decisionKinds (run "If someone is cold and not round then they are smart."))
  , expectStmt "multi-premise rule over definites"
      "If the cow likes the dog and the dog is big then the dog sees the cow."
      (Rule [atom "cow" "likes" "dog" Pos, atom "dog" "is" "big" Pos] (atom "dog" "sees" "cow" Pos))
  , expectStmt "pronoun inside the antecedent binds to the antecedent's indefinite"
      "If something likes the cow and it is big then the cow is red."
      (Rule [atom "something" "likes" "cow" Pos, atom "something" "is" "big" Pos]
            (atom "cow" "is" "red" Pos))
  , expectStmt "names in a conditional" "If Anne is big then Anne is red."
      (Rule [atom "Anne" "is" "big" Pos] (atom "Anne" "is" "red" Pos))
  , expect "the hand-lexicon path is unchanged by the parser choice"
      (map (fmap pretty . srForm) (prSentences (runPipelineWith (HandLexicon fragLex) (SourceId "t") "John loves Mary."))
         == map (fmap pretty . srForm) (prSentences (runFragment (SourceId "t") "John loves Mary.")))
  ]
  where
    fragLex = fragmentLexicon

--------------------------------------------------------------------------------
-- 7. Ambiguity, failure and anaphora discipline
--------------------------------------------------------------------------------

disciplineChecks :: [Check]
disciplineChecks =
  [ expect "two distinct root meanings raise ParseAmbiguity and log a parse-selection decision"
      (let r = run "All cold, green things are quiet."
       in length (srParses r) >= 2
            && ParseAmbiguity `elem` diagKinds r && "parse-selection" `elem` decisionKinds r)
  , expect "the rejected reading is recorded among the decision's alternatives"
      (let r = run "All cold, green things are quiet."
       in any (\d -> decKind d == "parse-selection" && length (decAlternatives d) == length (srParses r) - 1)
              (traceDecisions (srTrace r)))
  , expect "a word with no interpretable category is reported, not guessed"
      (let r = run "The cow is zzyzx of the dog."
       in null (srParses r) && NoParse `elem` diagKinds r)
  , expect "unparsable sentence contributes no DRS" (srDRS (run "The cow the dog.") == Nothing)
  , expect "local anaphora: no preceding accessible referent leaves the anaphor for the discourse"
      (let d = DRS [] [CPred "red" [DConst "?it_0"] (ProvLex (SourceId "t") (Span 0 2) "it")]
           (d', tr) = resolveLocalAnaphora mempty d
       in d' == d && null (traceDecisions tr))
  , expect "every parse decision names its tie-break"
      (all (\d -> not (null (decWhy d))) (traceDecisions (srTrace (run "All cold, green things are quiet."))))
  , expect "the chosen sentence meaning type-checks to t"
      (all (\t -> maybe True wellTyped (formOf t))
           ["The cow is big.", "If something is big then it is red.", "All red things are big."])
  ]

--------------------------------------------------------------------------------
-- 8. Gold representation and conversion
--------------------------------------------------------------------------------

goldChecks :: [Check]
goldChecks =
  [ expectEq "parse a gold fact" (Right (fact "cow" "is" "big" Pos)) (parseRepr "(\"cow\" \"is\" \"big\" \"+\")")
  , expectEq "parse a gold rule with NAF premise"
      (Right (Rule [atom "something" "is" "cold" Pos, atom "something" "is" "round" Neg]
                   (atom "something" "is" "smart" Pos)))
      (parseRepr "(((\"something\" \"is\" \"cold\" \"+\") (\"something\" \"is\" \"round\" \"~\")) -> (\"something\" \"is\" \"smart\" \"+\"))")
  , expect "normalisation lemmatises relations and treats bodies as sets"
      (normalizeStatement (Rule [atom "a" "likes" "b" Pos, atom "a" "is" "c" Pos] (atom "a" "sees" "b" Pos))
         == normalizeStatement (Rule [atom "a" "is" "c" Pos, atom "a" "like" "b" Pos] (atom "a" "see" "b" Pos)))
  , expect "a top-level indefinite does not convert"
      (either ("top-level" `isInfixOf`) (const False)
         (drsToStatement (DRS [(Ref "x", pv)] [CPred "thing" [DRef (Ref "x")] pv, CPred "big" [DRef (Ref "x")] pv])))
  , expect "an unresolved anaphor does not convert"
      (either ("anaphor" `isInfixOf`) (const False) (drsToStatement (DRS [] [CPred "big" [DConst "?it_3"] pv])))
  , expect "an unsorted rule variable does not convert"
      (either ("sortal" `isInfixOf`) (const False)
         (drsToStatement (DRS [] [CImp (DRS [(Ref "x", pv)] [CPred "big" [DRef (Ref "x")] pv])
                                        (DRS [] [CPred "red" [DRef (Ref "x")] pv]) pv])))
  , expectEq "JSON: nested object, array, escapes"
      (Right (JObj [("a", JArr [JNum 1, JStr "x\"y", JBool True, JNull])]))
      (parseJSON "{\"a\": [1, \"x\\\"y\", true, null]}")
  , expect "parseTheory reads id, facts and rules"
      (case parseTheory theoryLine of
         Right th -> thId th == "T1" && length (thFacts th) == 1 && length (thRules th) == 1
         Left _ -> False)
  ]
  where
    pv = ProvLex (SourceId "t") (Span 0 1) "x"
    theoryLine = concat
      [ "{\"id\":\"T1\",\"triples\":{\"triple1\":{\"text\":\"The cow is big.\","
      , "\"representation\":\"(\\\"cow\\\" \\\"is\\\" \\\"big\\\" \\\"+\\\")\"}},"
      , "\"rules\":{\"rule1\":{\"text\":\"Big things are red.\","
      , "\"representation\":\"(((\\\"something\\\" \\\"is\\\" \\\"big\\\" \\\"+\\\")) -> (\\\"something\\\" \\\"is\\\" \\\"red\\\" \\\"+\\\"))\"}}}" ]
