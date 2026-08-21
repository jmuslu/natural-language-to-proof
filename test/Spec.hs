-- | Stage 1 test suite.
--
-- Dependency-free by design: the toolchain here is a bare GHC bindist with no
-- package manager, and Stage 1 needs nothing beyond @base@ and @containers@.
-- Adding a test framework would be the project's first external dependency and
-- would buy very little over a few hundred lines of asserts.
--
-- The suite asserts more than "the derived form matches the expected form". It
-- also checks the properties Stage 1 is supposed to /guarantee/, because those
-- are what later stages will silently rely on:
--
-- * the lexicon is type-coherent with its own categories
-- * every token's span actually points at that token in the source
-- * every DRS condition carries provenance reaching a real source span
-- * DRT accessibility blocks the anaphora it is supposed to block
-- * the fragment is unambiguous — exactly one derivation per sentence
module Main (main) where

import Control.Monad (unless)
import Data.Char (toLower)
import Data.List (isInfixOf, nub, sort)
import System.Exit (exitFailure, exitSuccess)

import NL2Proof.Collapse.Class
import NL2Proof.DRT.Build
import NL2Proof.DRT.Types
import NL2Proof.Fragment
import NL2Proof.Pipeline
import NL2Proof.Provenance
import NL2Proof.Semantics.Lambda
import NL2Proof.Syntax.CCG
import NL2Proof.Syntax.Category
import NL2Proof.Syntax.Lexicon
import NL2Proof.Syntax.Tokenize
import NL2Proof.Trace

--------------------------------------------------------------------------------
-- Harness
--------------------------------------------------------------------------------

data Check = Check
  { chkName :: String
  , chkOk   :: Bool
  , chkNote :: String
  }

ok :: String -> Check
ok n = Check n True ""

bad :: String -> String -> Check
bad n why = Check n False why

expect :: String -> Bool -> Check
expect n True  = ok n
expect n False = bad n "expected True"

expectEq :: (Eq a, Show a) => String -> a -> a -> Check
expectEq n want got
  | want == got = ok n
  | otherwise   = bad n ("expected " ++ show want ++ ", got " ++ show got)

--------------------------------------------------------------------------------
-- Fixtures
--------------------------------------------------------------------------------

testSource :: SourceId
testSource = SourceId "test"

runCase :: FragmentCase -> PipelineResult
runCase c = runFragment testSource (caseText c)

--------------------------------------------------------------------------------
-- 1. Lexicon coherence
--------------------------------------------------------------------------------

-- | The syntax-semantics correspondence, checked rather than asserted: a lexical
-- entry's meaning must inhabit the semantic type its CCG category demands.
--
-- This is the single most valuable test in the file. It catches the entire class
-- of bug where an entry's lambda term is subtly the wrong shape — which would
-- otherwise surface much later as an unparseable sentence with no obvious cause.
lexiconChecks :: [Check]
lexiconChecks =
  [ let entries = lookupWord fragmentLexicon w
    in case [ e | e <- entries, typeOf [] (entrySem e) /= Right (catTy (entryCat e)) ] of
         [] -> ok ("lexicon type-coherent: " ++ show w)
         (e : _) ->
           bad
             ("lexicon type-coherent: " ++ show w)
             ( "category " ++ show (entryCat e) ++ " demands "
                 ++ show (catTy (entryCat e)) ++ " but meaning has "
                 ++ either renderTypeError show (typeOf [] (entrySem e))
             )
  | w <- lexiconKeys fragmentLexicon
  ]
    ++ [ expect "lexicon is non-empty" (not (null (lexiconKeys fragmentLexicon)))
       , expect
           "every lexicon key is lower-cased"
           (all (\k -> k == map toLower k) (lexiconKeys fragmentLexicon))
       ]

--------------------------------------------------------------------------------
-- 2. Logical forms
--------------------------------------------------------------------------------

formChecks :: FragmentCase -> [Check]
formChecks c =
  expectEq
    (caseId c ++ ": sentence count")
    (length (caseForms c))
    (length (prSentences c'))
    : concat
      [ [ case srForm r of
            Nothing ->
              bad label ("no logical form derived; diagnostics: " ++ diagSummary r)
            Just got
              | alphaEq got want -> ok label
              | otherwise ->
                  bad label ("expected " ++ pretty want ++ ", got " ++ pretty got)
        ]
      | (i, r, want) <- zip3 [0 :: Int ..] (prSentences c') (caseForms c)
      , let label = caseId c ++ ": form of sentence " ++ show i
      ]
  where
    c' = runCase c
    diagSummary r = show (map diagKind (traceDiagnostics (srTrace r)))

--------------------------------------------------------------------------------
-- 3. Determinism / unambiguity of the fragment
--------------------------------------------------------------------------------

-- | Stage 1 is meant to be "fully deterministic and solved". Concretely: every
-- sentence in the fragment has exactly one CCG derivation to S.
--
-- If this ever fails, the fragment has grown a genuine ambiguity and the
-- 'ParseAmbiguity' path is now live — which is fine, but it means Stage 1 is no
-- longer the unambiguous baseline the later stages assume.
ambiguityChecks :: FragmentCase -> [Check]
ambiguityChecks c =
  [ expectEq
      (caseId c ++ ": exactly one derivation for sentence " ++ show i)
      1
      (length (srParses r))
  | (i, r) <- zip [0 :: Int ..] (prSentences (runCase c))
  ]

--------------------------------------------------------------------------------
-- 4. Type checking
--------------------------------------------------------------------------------

typeChecks :: FragmentCase -> [Check]
typeChecks c =
  [ expect
      (caseId c ++ ": chosen derivation well-typed, sentence " ++ show i)
      (maybe False signWellTyped (srChosen r))
  | (i, r) <- zip [0 :: Int ..] (prSentences (runCase c))
  ]
    ++ [ expect
           (caseId c ++ ": no type-check failures")
           (TypeCheckFailure `notElem` diagKinds (prTrace (runCase c)))
       ]

diagKinds :: Trace -> [DiagKind]
diagKinds = map diagKind . traceDiagnostics

--------------------------------------------------------------------------------
-- 5. Diagnostics
--------------------------------------------------------------------------------

diagnosticChecks :: FragmentCase -> [Check]
diagnosticChecks c =
  expectEq
    (caseId c ++ ": diagnostic kinds")
    (sort (nub (caseDiags c)))
    (sort (nub (diagKinds (prTrace c'))))
    : [ expect (caseId c ++ ": parsed without NoParse") (NoParse `notElem` diagKinds (prTrace c')) ]
  where
    c' = runCase c

--------------------------------------------------------------------------------
-- 6. Tokenizer spans -- the traceability foundation
--------------------------------------------------------------------------------

-- | Slicing a token's span out of the original text must reproduce that token.
--
-- Every provenance tag in the system is built on these offsets, so if this is
-- wrong then all downstream traceability is quietly wrong too. Worth checking
-- directly rather than trusting.
spanChecks :: FragmentCase -> [Check]
spanChecks c =
  concat
    [ [ let sliced = map toLower (slice (tokSpan t) (caseText c))
        in expectEq
             (caseId c ++ ": span of " ++ show (tokText t) ++ " points at itself")
             (tokText t)
             sliced
      ]
    | r <- prSentences (runCase c)
    , t <- srTokens r
    ]

slice :: Span -> String -> String
slice (Span a b) = take (b - a) . drop a

--------------------------------------------------------------------------------
-- 7. Multi-word lexical entries
--------------------------------------------------------------------------------

multiwordChecks :: [Check]
multiwordChecks =
  case caseById "negation" of
    Nothing -> [bad "multiword: negation case present" "case not found"]
    Just c ->
      let toks = concatMap srTokens (prSentences (runCase c))
      in [ expect
             "multiword: \"does not\" merged into one token"
             ("does not" `elem` map tokText toks)
         , expect
             "multiword: bare \"does\" not left behind"
             ("does" `notElem` map tokText toks)
         ]

--------------------------------------------------------------------------------
-- 8. Provenance
--------------------------------------------------------------------------------

-- | Every condition in the discourse DRS must carry provenance that reaches a
-- real span inside the source text, and that names the source it came from.
provenanceChecks :: FragmentCase -> [Check]
provenanceChecks c =
  [ expect
      (caseId c ++ ": every condition has a source span")
      (all (\p -> provSpan p /= Nothing) provs)
  , expect
      (caseId c ++ ": every condition span lies inside the text")
      (all inBounds provs)
  , expect
      (caseId c ++ ": every condition names the source")
      (all (\p -> provSources p == [testSource]) provs)
  , expect
      (caseId c ++ ": every referent has provenance reaching the source")
      (all (\p -> provSources p == [testSource]) refProvs)
  , expect
      (caseId c ++ ": provenance trees are non-trivial (some rule applied)")
      (any (\p -> provSize p > 1) provs)
  , expectEq
      (caseId c ++ ": discourse draws only on the declared source")
      [testSource]
      (drsSources drs)
  ]
    ++ [ expect
           (caseId c ++ ": condition surface words occur in the text: " ++ w)
           (w `isInfixOf` map toLower (caseText c))
       | p <- provs
       , (_, _, w) <- provLeaves p
       ]
  where
    drs = dscDRS (prDiscourse (runCase c))
    provs = drsConditionProvs drs
    refProvs = map snd (drsUniverse drs)

    inBounds p = case provSpan p of
      Nothing         -> False
      Just (Span a b) -> a >= 0 && b <= length (caseText c) && a <= b

--------------------------------------------------------------------------------
-- 9. Anaphora and accessibility
--------------------------------------------------------------------------------

anaphoraChecks :: [Check]
anaphoraChecks = resolved ++ blocked ++ accessibility
  where
    resolved = case caseById "anaphora" of
      Nothing -> [bad "anaphora case present" "not found"]
      Just c ->
        let p = runCase c
            drs = dscDRS (prDiscourse p)
            decs = [d | d <- traceDecisions (prTrace p), decKind d == "anaphora"]
        in [ expectEq "anaphora: no unresolved anaphors remain" [] (anaphorConstants drs)
           , expectEq "anaphora: exactly one resolution decision" 1 (length decs)
           , expect
               "anaphora: the resolution decision states its heuristic"
               (all (not . null . decWhy) decs)
           , expect
               "anaphora: smile applies to the student referent"
               (any (isSmileOnRef drs) (drsConds drs))
           ]

    -- After resolution, smile's argument must be a referent, not the ?she
    -- constant it started as.
    isSmileOnRef _ (CPred "smile" [DRef _] _) = True
    isSmileOnRef _ _                          = False

    blocked = case caseById "blocked-anaphora" of
      Nothing -> [bad "blocked-anaphora case present" "not found"]
      Just c ->
        let p = runCase c
            drs = dscDRS (prDiscourse p)
            decs = [d | d <- traceDecisions (prTrace p), decKind d == "anaphora"]
        in [ expect
               "blocked-anaphora: anaphor stays unresolved"
               (not (null (anaphorConstants drs)))
           , expect
               "blocked-anaphora: UnresolvedAnaphor raised"
               (UnresolvedAnaphor `elem` diagKinds (prTrace p))
           , expectEq "blocked-anaphora: no resolution decision made" 0 (length decs)
           ]

    -- The referent introduced by "No student" exists, but under negation, so it
    -- is invisible to accessibility. This is the DRT constraint that makes the
    -- blocked case correct rather than merely broken.
    accessibility = case caseById "negative-quantifier" of
      Nothing -> [bad "negative-quantifier case present" "not found"]
      Just c ->
        let drs = dscDRS (prDiscourse (runCase c))
        in [ expectEq "accessibility: nothing accessible at top level" [] (accessibleRefs drs)
           , expect
               "accessibility: but a referent does exist inside the negated box"
               (not (null (drsRefs drs)))
           ]

--------------------------------------------------------------------------------
-- 10. Collapse contract
--------------------------------------------------------------------------------

collapseChecks :: FragmentCase -> [Check]
collapseChecks c = case prSelection (runCase c) of
  Nothing -> [bad (caseId c ++ ": selection produced") "prSelection was Nothing"]
  Just sel ->
    [ expectEq
        (caseId c ++ ": Stage 1 offers a single candidate")
        1
        (selectionCandidateCount sel)
    , expectEq
        (caseId c ++ ": no rejected candidates to record")
        0
        (length (selRejected sel))
    , expect
        (caseId c ++ ": selection states its rationale")
        (not (null (selRationale sel)))
    , expect
        (caseId c ++ ": selection spans are in source order")
        (let ss = map spanStart (selectionSpans sel) in ss == sort ss)
    , expectEq
        (caseId c ++ ": selection sources match the declared source")
        [testSource]
        (selectionSources sel)
    , expect
        (caseId c ++ ": the collapse is logged as a decision")
        (not (null (decWhy (selectionDecision sel))))
    ]

--------------------------------------------------------------------------------
-- 11. Lambda calculus properties
--------------------------------------------------------------------------------

lambdaChecks :: [Check]
lambdaChecks =
  [ -- Substituting x for y under a binder on x must rename the binder. A naive
    -- implementation returns \x. x here, which is a different function.
    expect
      "subst avoids variable capture"
      (alphaEq
         (subst "y" (Var "x") (Lam "x" TyE (Var "y")))
         (Lam "w" TyE (Var "x")))
  , expect
      "subst capture-avoidance is not vacuous"
      (not (alphaEq
              (subst "y" (Var "x") (Lam "x" TyE (Var "y")))
              (Lam "x" TyE (Var "x"))))
  , expect
      "normalize is idempotent on the fragment's forms"
      (all (\t -> normalize (normalize t) == normalize t) allForms)
  , expect
      "alphaEq is reflexive on the fragment's forms"
      (all (\t -> alphaEq t t) allForms)
  , expect
      "every expected form is a well-typed proposition"
      (all wellTyped allForms)
  , expect
      "typeOf rejects applying a predicate to a predicate"
      (case typeOf [] (App (pred1 "p") (pred1 "q")) of
         Left Mismatch{} -> True
         _               -> False)
  , expect
      "typeOf rejects a non-propositional conjunct"
      (case typeOf [] (TAnd (entity "john") (entity "mary")) of
         Left NotProp{} -> True
         _              -> False)
  , expect
      "typeOf reports unbound variables"
      (case typeOf [] (Var "loose") of
         Left (Unbound "loose") -> True
         _                      -> False)
  , expectEq
      "catTy maps NP to a generalized quantifier"
      tyGQ
      (catTy NP)
  , expectEq
      "catTy maps a transitive verb to GQ -> GQ -> t"
      (tyGQ ~> tyGQ ~> TyT)
      (catTy ((S :\ NP) :/ NP))
  ]
  where
    allForms = concatMap caseForms fragmentCases

--------------------------------------------------------------------------------
-- 12. Coupling detection
--------------------------------------------------------------------------------

couplingChecks :: [Check]
couplingChecks = case caseById "coupling" of
  Nothing -> [bad "coupling case present" "not found"]
  Just c ->
    let p = runCase c
        ds = [d | d <- traceDiagnostics (prTrace p), diagKind d == ModifierCoupling]
    in [ expectEq "coupling: exactly one modifier stack flagged" 1 (length ds)
       , expect
           "coupling: the flag names all three modifiers"
           (all (\w -> any (\d -> w `isInfixOf` diagMsg d) ds) ["ancient", "chinese", "red"])
       , expect
           "coupling: the flag points at the head noun"
           (any (\d -> "dragon" `isInfixOf` diagMsg d) ds)
       , expect
           "coupling: flagging does not suppress the compositional reading"
           (any ((/= Nothing) . srForm) (prSentences p))
       ]
      ++ [ expect
             "coupling: an unmodified noun is not flagged"
             (null
                [ d
                | d <- traceDiagnostics (prTrace (runFragment testSource "John loves Mary."))
                , diagKind d == ModifierCoupling
                ])
         ]

--------------------------------------------------------------------------------
-- Main
--------------------------------------------------------------------------------

allChecks :: [Check]
allChecks =
  concat
    [ lexiconChecks
    , concatMap formChecks fragmentCases
    , concatMap ambiguityChecks fragmentCases
    , concatMap typeChecks fragmentCases
    , concatMap diagnosticChecks fragmentCases
    , concatMap spanChecks fragmentCases
    , multiwordChecks
    , concatMap provenanceChecks fragmentCases
    , anaphoraChecks
    , concatMap collapseChecks fragmentCases
    , lambdaChecks
    , couplingChecks
    ]

main :: IO ()
main = do
  mapM_ report allChecks
  let failures = [c | c <- allChecks, not (chkOk c)]
      total = length allChecks
  putStrLn ""
  putStrLn
    ( show (total - length failures) ++ "/" ++ show total ++ " checks passed"
        ++ (if null failures then "" else ", " ++ show (length failures) ++ " FAILED")
    )
  unless (null failures) exitFailure
  exitSuccess
  where
    report c
      | chkOk c   = putStrLn ("ok   " ++ chkName c)
      | otherwise = putStrLn ("FAIL " ++ chkName c ++ "\n       " ++ chkNote c)
