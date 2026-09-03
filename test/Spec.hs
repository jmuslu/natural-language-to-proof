-- | Stage 1 test suite.
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

import Data.Char (toLower)
import Data.List (isInfixOf, nub, sort)
import qualified Data.Map as M

import Harness
import NL2Proof.Collapse.Class
import NL2Proof.DRT.Build
import NL2Proof.DRT.Canonical
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
-- 7. Multi-word entries and the lexical lattice
--------------------------------------------------------------------------------

-- | A multi-word entry is a unit of the /parse/, not of a tokenization done in
-- front of it.
--
-- Two facts here that have to be kept apart. The raw tokens are still words, so
-- @"does"@ and @"not"@ both appear among them. The chosen derivation uses the
-- @"does not"@ unit and neither part on its own. A greedy longest-match pass
-- made the first of those false, which is precisely what made it lossy: a word
-- absorbed into a phrase had no representation left.
multiwordChecks :: [Check]
multiwordChecks =
  case caseById "negation" of
    Nothing -> [bad "multiword: negation case present" "case not found"]
    Just c ->
      let rs = prSentences (runCase c)
          raw = concatMap (map tokText . srTokens) rs
          units = concatMap (map tokText . M.elems . latUnits . srLattice) rs
          leaves =
            [ w
            | r <- rs
            , Just s <- [srChosen r]
            , (_, _, w) <- provLeaves (sProv s)
            ]
      in [ expect
             "multiword: the words are still words"
             (["does", "not"] `isInfixOf` raw)
         , expect
             "multiword: \"does not\" is a candidate unit"
             ("does not" `elem` units)
         , expect
             "multiword: and bare \"does\" is not, having no entry"
             ("does" `notElem` units)
         , expect
             "multiword: the derivation uses the unit"
             ("does not" `elem` leaves)
         , expect
             "multiword: and not its parts"
             ("does" `notElem` leaves && "not" `notElem` leaves)
         , expect
             "multiword: no uncovered words"
             (null (concatMap srUnknown rs))
         , expectEq
             "multiword: no fork, since the parts have no entries"
             0
             (length (concatMap (latticeForks . srLattice) rs))
         ]

--------------------------------------------------------------------------------
-- 7b. Segmentation ambiguity, preserved rather than resolved
--------------------------------------------------------------------------------

-- | A lexicon in which a fused compound competes with its own parts.
--
-- This is the case a greedy longest-match pass cannot represent, and the reason
-- the lattice is not merely hygiene. A fused subkind can /only/ be written as a
-- multi-word entry, so adding @"red dragon"@ as an @N@ under greedy matching
-- deletes the iterated-intersection reading of the same two words before the
-- parser sees it. That is the bad failure mode rather than the loud one: not no
-- parse, but one parse, with the other meaning gone and nothing recording it.
fusedLexicon :: Lexicon
fusedLexicon =
  mkLexicon
    [ ("a", lookupWord fragmentLexicon "a")
    , ("red", [adjEntry "red"])
    , ("dragon", [nounEntry "dragon"])
    , ("red dragon", [nounEntry "red_dragon"])
    , ("sleeps", [ivEntry "sleep"])
    ]

latticeChecks :: [Check]
latticeChecks =
  expectEq "lattice: match window derived from the lexicon" 2
    (maxPhraseLength fusedLexicon)
    : case prSentences p of
        [r] ->
          let conss = map (sort . nub . constNames . normalize . sSem) (srParses r)
          in [ expectEq "lattice: both segmentations reach S" 2 (length (srParses r))
             , expect
                 "lattice: the compound reading survives"
                 (["red_dragon", "sleep"] `elem` conss)
             , expect
                 "lattice: and so does iterated intersection"
                 (["dragon", "red", "sleep"] `elem` conss)
             , expectEq
                 "lattice: the fork is logged before the parser runs"
                 2
                 (length (latticeForks (srLattice r)))
             , expect
                 "lattice: as a diagnostic"
                 (SegmentationAmbiguity `elem` diagKinds (prTrace p))
             , expect
                 "lattice: the parse ambiguity is reported too"
                 (ParseAmbiguity `elem` diagKinds (prTrace p))
             , expect
                 "lattice: and the collapse names one alternative"
                 ( [1] == [ length (decAlternatives d)
                          | d <- traceDecisions (prTrace p)
                          , decKind d == "parse-selection"
                          ]
                 )
             , expect "lattice: no uncovered words" (null (srUnknown r))
             ]
        rs ->
          [ bad "lattice: one sentence" ("got " ++ show (length rs)) ]
  where
    p = runPipeline fusedLexicon testSource "A red dragon sleeps."

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
-- 13. Canonical view (shared by both dispositions)
--------------------------------------------------------------------------------

-- | The shared provenance-free view must be blind to provenance and to variable
-- naming, and must __not__ compress. Compression is fusion's job; if it happened
-- here, the verification stage could not be built on top of this module.
canonicalChecks :: [Check]
canonicalChecks =
  [ expectEq
      "canonical: blind to provenance (same text, different sources)"
      (canonOf (SourceId "A") "John loves Mary.")
      (canonOf (SourceId "B") "John loves Mary.")
  , expectEq
      "canonical: blind to referent naming"
      (canonicalize (DRS [(Ref "x", pv)] [CPred "student" [DRef (Ref "x")] pv]))
      (canonicalize (DRS [(Ref "zzz", pv)] [CPred "student" [DRef (Ref "zzz")] pv]))
  , expect
      "canonical: distinguishes genuinely different content"
      (canonOf testSource "John loves Mary." /= canonOf testSource "Mary smiles.")
  , -- The load-bearing one: two assertions of the same proposition stay two
    -- conditions here. Fusion collapses them; this module must not.
    expectEq
      "canonical: does NOT deduplicate repeated claims"
      2
      (canonConditionCount (canonOf testSource "John loves Mary. John loves Mary."))
  , expectEq
      "canonical: preserves condition order"
      [CanPred "student" [CRefT (CRef 0)], CanPred "arrive" [CRefT (CRef 0)]]
      (canonConds (canonOf testSource "A student arrived."))
  , expectEq
      "canonical: allRefsIn finds referents that only appear as arguments"
      [Ref "q"]
      (allRefsIn (DRS [] [CPred "smile" [DRef (Ref "q")] pv]))
  , expectEq
      "canonical: universe survives canonicalization"
      [CRef 0]
      (canonUniverse (canonOf testSource "A student arrived."))
  , expect
      "canonical: nested boxes are canonicalized too"
      (case canonConds (canonOf testSource "No student sleeps.") of
         [CanNot inner] -> canonUniverse inner == [CRef 0]
         _              -> False)
  ]
  where
    pv = ProvLex testSource (Span 0 1) "w"
    canonOf s t = canonicalize (dscDRS (prDiscourse (runFragment s t)))

--------------------------------------------------------------------------------
-- Main
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 14. Discourse merge soundness: referents must be discourse-unique
--------------------------------------------------------------------------------

-- | 'mergeDRS' is only sound when the two universes are disjoint, and referent
-- names come from the lambda terms, so two sentences of the __same shape__ arrive
-- with the same names. Before 'freshenAgainst' was applied in
-- 'extendDiscourse', @"A student arrived. A professor walks."@ merged to
--
-- > | x x          |
-- > | student(x)   |
-- > | arrive(x)    |
-- > | professor(x) |
-- > | walk(x)      |
--
-- one individual who is both. That is a soundness bug, not a modelling
-- limitation, and none of the other 348 checks could see it: no case in the
-- fragment has two same-shaped existential sentences.
--
-- These checks exist so that gap cannot reopen. The texts are written here rather
-- than added to 'fragmentCases' because they are regression fixtures for one
-- property, not evaluation cases with expected logical forms.
freshnessChecks :: [Check]
freshnessChecks =
  concatMap perText
    [ "A student arrived. A professor walks."
    , "A student arrived. A student arrived."
    , "A student arrived. A professor walks. A student arrived."
    , "A student arrived. She smiles."
    , "No student sleeps. She smiles."
    , "Every student reads a book. A professor walks."
    ]
    ++
    [ -- The collision case, spelled out.
      expectEq "freshness: two same-shaped existentials get distinct referents"
        2 (length (nub (accessibleRefs (discourseOf collide))))
    , expect "freshness: and the student is not the professor"
        (let d = discourseOf collide
             refOf pr = [r | CPred p [DRef r] _ <- drsConds d, p == pr]
         in refOf "student" /= refOf "professor"
              && not (null (refOf "student"))
              && not (null (refOf "professor")))

    , -- Freshening happens at the merge, not in 'toDRS': the sentence-local
      -- DRSs are untouched, so a sentence read on its own still reads the same.
      expect "freshness: sentence-local DRSs are left alone"
        (all (\r -> maybe True ((== [Ref "x"]) . accessibleRefs) (srDRS r))
             (prSentences (runFragment testSource collide)))

    , -- Renaming is alpha-conversion, so provenance must survive it. A renamed
      -- referent that could not be traced back to its words would be a worse bug
      -- than the one being fixed.
      expect "freshness: every renamed referent still names the source"
        (all (\(_, pr) -> provSources pr == [testSource])
             (drsUniverse (discourseOf collide)))
    , expect "freshness: and still reaches a real span in the text"
        (all (\(_, pr) -> maybe False (inText collide) (provSpan pr))
             (drsUniverse (discourseOf collide)))

    , -- No collision means no work: an empty substitution is the cheap witness.
      expectEq "freshness: freshenAgainst is identity when nothing collides"
        [] (snd (freshenAgainst [Ref "z"] (fst (freshenAgainst [] (bare "A student arrived.")))))
    , expect "freshness: and renames exactly the colliding referent when there is one"
        (case freshenAgainst [Ref "x"] (bare "A student arrived.") of
           (_, [(Ref "x", Ref new)]) -> new /= "x"
           _                         -> False)
    , expect "freshness: the fresh name avoids names already in play"
        (case freshenAgainst [Ref "x", Ref "x2"] (bare "A student arrived.") of
           (_, [(_, r)]) -> r `notElem` [Ref "x", Ref "x2"]
           _             -> False)

    , -- 'mapRefs' is structural: it must not add, drop or reshape anything.
      expect "freshness: mapRefs preserves size"
        (let d = bare "Every student reads a book."
         in drsSize (mapRefs (\(Ref r) -> Ref (r ++ "!")) d) == drsSize d)
    , expect "freshness: mapRefs reaches referents inside subordinate boxes"
        (let d = bare "No student sleeps."
         in all (\(Ref r) -> "!" `isInfixOf` r)
                (drsRefs (mapRefs (\(Ref r) -> Ref (r ++ "!")) d)))
    , expect "freshness: mapRefs leaves constants alone"
        (let d = bare "John loves Mary."
         in drsConstants (mapRefs (\(Ref r) -> Ref (r ++ "!")) d) == drsConstants d)

    , -- The anaphora cases must be untouched, which is why Stage 1's count did
      -- not move when this was fixed.
      expect "freshness: the anaphora case still resolves to the student"
        (any (\d -> decKind d == "anaphora")
             (traceDecisions (prTrace (runFragment testSource "A student arrived. She smiles."))))
    ]
  where
    collide = "A student arrived. A professor walks."

    perText txt =
      [ expectEq ("freshness: no duplicate referent names in " ++ show txt)
          (length u) (length (nub u))
      ]
      where
        u = drsRefs (discourseOf txt)

    discourseOf txt = dscDRS (prDiscourse (runFragment testSource txt))

    bare txt =
      case [d | r <- prSentences (runFragment testSource txt), Just d <- [srDRS r]] of
        (d : _) -> d
        []      -> emptyDRS

    inText txt (Span a b) = a >= 0 && b <= length txt && a <= b

--------------------------------------------------------------------------------
-- Assembly
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
    , latticeChecks
    , concatMap provenanceChecks fragmentCases
    , anaphoraChecks
    , concatMap collapseChecks fragmentCases
    , lambdaChecks
    , couplingChecks
    , canonicalChecks
    , freshnessChecks
    , recencyChecks
    ]

--------------------------------------------------------------------------------
-- 15. Recency is surface position, not universe order
--------------------------------------------------------------------------------

-- | 'recencyOrdered' must read spans, not the shape of the universe list.
--
-- The universe is built by 'addRef', which conses, so its order is the reverse
-- of construction. Reversing it back gives recency only while /outermost/
-- coincides with /leftmost/, which holds only because Stage 1's transitive verb
-- always gives the subject wide scope. These checks pin the ordering to the one
-- thing scope permutation cannot move.
--
-- Built by hand rather than through the pipeline, so that a universe in an order
-- Stage 1 would never produce can be handed in directly. @Stage2Spec.hs@ section
-- 14 does the same thing with a real scope-permuted reading.
recencyChecks :: [Check]
recencyChecks =
  [ expectEq
      "recency: later span first, whatever order the universe is in"
      [Ref "b", Ref "a"]
      (recencyOrdered forwards)
  , expectEq
      "recency: and the same answer with the universe reversed"
      [Ref "b", Ref "a"]
      (recencyOrdered backwards)
  , expect
      "recency: which is the property construction order does not have"
      (reverse (accessibleRefs forwards) /= reverse (accessibleRefs backwards))
  , expectEq
      "recency: a referent with no lexical provenance ranks last"
      [Ref "b", Ref "a", Ref "nowhere"]
      (recencyOrdered (DRS (drsUniverse backwards ++ [(Ref "nowhere", noSpan)]) []))
  , expectEq
      "recency: equal spans fall back to universe order, latest first"
      [Ref "late", Ref "early"]
      (recencyOrdered (DRS [(Ref "early", at 0 4), (Ref "late", at 0 4)] []))
  ]
  where
    at a b = ProvLex testSource (Span a b) (replicate (b - a) 'w')
    noSpan = provRule "no-leaves" []
    forwards = DRS [(Ref "a", at 2 9), (Ref "b", at 22 26)] []
    backwards = DRS [(Ref "b", at 22 26), (Ref "a", at 2 9)] []

main :: IO ()
main = runChecks "stage 1 core" allChecks
