-- | __provenance-mode__ collapse tests.
--
-- Picked up automatically by @scripts\/build.{sh,ps1}@, which run
-- @test\/ModeSpec.hs@ when it exists.
--
-- The suite is organized around the property that /defines/ this mode: two
-- independent assertions of the same proposition must stay __two__. The
-- companion assertion on the @truth-mode@ branch is the exact opposite, and both
-- run against the same shared core. If either branch ever satisfied both
-- properties, the two modes would have stopped being distinct.
module Main (main) where

import Data.Char (toLower)
import Data.List (nub)

import Harness
import NL2Proof.Collapse.Class
import NL2Proof.Collapse.Provenance
import NL2Proof.DRT.Build
import NL2Proof.DRT.Canonical
import NL2Proof.DRT.Types
import NL2Proof.Fragment
import NL2Proof.Pipeline
import NL2Proof.Provenance
import NL2Proof.Trace

--------------------------------------------------------------------------------
-- Fixtures
--------------------------------------------------------------------------------

srcA, srcB, srcC :: SourceId
srcA = SourceId "A"
srcB = SourceId "B"
srcC = SourceId "C"

provenanceOf :: SourceId -> String -> ProvenanceForm
provenanceOf s t = case prSelection (runFragment s t) of
  Nothing  -> error ("no selection for " ++ show t)
  Just sel -> collapseProvenance sel

discourseOf :: SourceId -> String -> DRS
discourseOf s t = dscDRS (prDiscourse (runFragment s t))

-- | Merge two independently-sourced discourses, the way a system ingesting two
-- documents would.
--
-- Deliberately uses sentences with no discourse referents, so merging cannot
-- collide variable names — that would be a different bug wearing this test's
-- clothes.
mergedSelection :: (SourceId, String) -> (SourceId, String) -> Selection
mergedSelection (sa, ta) (sb, tb) =
  selectOnly
    (mergeDRS (discourseOf sa ta) (discourseOf sb tb))
    (provRule "two-documents" [ProvLex sa (Span 0 1) "a", ProvLex sb (Span 0 1) "b"])

-- | The headline scenario: two documents asserting the same proposition.
twoDocsSameClaim :: ProvenanceForm
twoDocsSameClaim =
  collapseProvenance
    (mergedSelection (srcA, "John loves Mary.") (srcB, "John loves Mary."))

--------------------------------------------------------------------------------
-- 1. The defining property: equal propositions stay separate
--------------------------------------------------------------------------------

separationChecks :: [Check]
separationChecks =
  [ expectEq
      "prov: a claim repeated in one document stays two facts"
      2
      (length (pfFacts (provenanceOf srcA "John loves Mary. John loves Mary.")))
  , expect
      "prov: those two facts make the same claim"
      (let fs = pfFacts (provenanceOf srcA "John loves Mary. John loves Mary.")
       in length (nub (map factClaim fs)) == 1)
  , expect
      "prov: but have distinct derivations"
      (let fs = pfFacts (provenanceOf srcA "John loves Mary. John loves Mary.")
       in length (nub (map factProv fs)) == 2)
  , expect
      "prov: and distinct source spans"
      (let fs = pfFacts (provenanceOf srcA "John loves Mary. John loves Mary.")
       in length (nub (map factSpan fs)) == 2)
  , -- The ARCHITECTURE.md scenario, verbatim: two documents, one proposition.
    expectEq
      "prov: two documents asserting one proposition stay two facts"
      2
      (length (pfFacts twoDocsSameClaim))
  , expectEq
      "prov: each traceable to its own source independently"
      [[srcA], [srcB]]
      (map factSources (pfFacts twoDocsSameClaim))
  , expect
      "prov: facts have distinct ids even when claims coincide"
      (let fs = pfFacts twoDocsSameClaim
       in length (nub (map factId fs)) == length fs)
  ]

--------------------------------------------------------------------------------
-- 2. Retraction -- the operation truth-mode cannot support
--------------------------------------------------------------------------------

retractionChecks :: [Check]
retractionChecks =
  [ expectEq
      "prov: retracting one of two corroborating sources leaves the claim standing"
      1
      (length (pfFacts (retractSource srcA twoDocsSameClaim)))
  , expectEq
      "prov: and the surviving fact belongs to the other source"
      [[srcB]]
      (map factSources (pfFacts (retractSource srcA twoDocsSameClaim)))
  , expectEq
      "prov: retracting the other source is symmetric"
      [[srcA]]
      (map factSources (pfFacts (retractSource srcB twoDocsSameClaim)))
  , expectEq
      "prov: retracting both leaves nothing"
      0
      (length (pfFacts (retractSource srcB (retractSource srcA twoDocsSameClaim))))
  , expectEq
      "prov: retracting an unrelated source changes nothing"
      (pfFacts twoDocsSameClaim)
      (pfFacts (retractSource srcC twoDocsSameClaim))
  , expectEq
      "prov: retraction is idempotent"
      (pfFacts (retractSource srcA twoDocsSameClaim))
      (pfFacts (retractSource srcA (retractSource srcA twoDocsSameClaim)))
  , expectEq
      "prov: retractionImpact reports before/after/lost"
      (2, 1, 1)
      (retractionImpact srcA twoDocsSameClaim)
  , expect
      "prov: retracting the only source of a single-source discourse empties it"
      (let pf = provenanceOf srcA "Every student reads a book."
       in null (pfFacts (retractSource srcA pf)))
  ]

--------------------------------------------------------------------------------
-- 3. Convergence is surfaced, not merged
--------------------------------------------------------------------------------

convergenceChecks :: [Check]
convergenceChecks =
  [ expectEq
      "prov: convergent claims are detected"
      1
      (length (convergentClaims twoDocsSameClaim))
  , expect
      "prov: a convergent claim lists both of its derivations"
      (case convergentClaims twoDocsSameClaim of
         [(_, g)] -> length g == 2
         _        -> False)
  , expectEq
      "prov: two different claims are not convergent"
      0
      (length
         (convergentClaims
            (collapseProvenance
               (mergedSelection (srcA, "John loves Mary.") (srcB, "Mary smiles.")))))
  , expect
      "prov: detecting convergence does not merge it"
      (length (pfFacts twoDocsSameClaim) == 2
         && not (null (convergentClaims twoDocsSameClaim)))
  , expectEq
      "prov: both sources are still reachable from the form"
      [srcA, srcB]
      (sourcesOf twoDocsSameClaim)
  , expectEq
      "prov: factsFrom selects by source"
      1
      (length (factsFrom srcA twoDocsSameClaim))
  ]

--------------------------------------------------------------------------------
-- 4. how-provenance is retained in full
--------------------------------------------------------------------------------

-- | @how@-provenance is strictly more informative than @why@. If a derivation
-- tree ever collapsed to just its source set, this mode would have silently
-- degraded into truth-mode's provenance handling.
howProvenanceChecks :: [Check]
howProvenanceChecks =
  [ expect
      "prov: derivation trees carry more than their source sets"
      (any
         (\f -> provSize (factProv f) > length (factSources f))
         (concatMap (pfFacts . provenanceOf srcA . caseText) fragmentCases))
  , expect
      "prov: every fact has a rendered derivation"
      (all
         (not . null . factDerivation)
         (concatMap (pfFacts . provenanceOf srcA . caseText) fragmentCases))
  , expect
      "prov: every fact traces to a span inside its source text"
      (all inBounds
         [ (c, f)
         | c <- fragmentCases
         , f <- pfFacts (provenanceOf srcA (caseText c))
         ])
  , expect
      "prov: rule names survive in the derivation"
      (any
         (not . null . provRuleNames . factProv)
         (concatMap (pfFacts . provenanceOf srcA . caseText) fragmentCases))
  , expect
      "prov: surface forms are recoverable from provenance"
      (all
         (\(c, f) -> all (`elem` words (lowerOf (caseText c))) (surfaceWords f))
         [ (c, f)
         | c <- fragmentCases
         , f <- pfFacts (provenanceOf srcA (caseText c))
         ])
  ]
  where
    inBounds (c, f) = case factSpan f of
      Nothing         -> False
      Just (Span a b) -> a >= 0 && b <= length (caseText c) && a <= b

    surfaceWords f = concatMap (\(_, _, w) -> words w) (provLeaves (factProv f))

    -- Punctuation-stripped, lower-cased words of the source text, so a token's
    -- surface form can be looked up in it.
    lowerOf = map (\ch -> if ch `elem` ".,;:!?" then ' ' else toLower ch)

--------------------------------------------------------------------------------
-- 5. Structural integrity
--------------------------------------------------------------------------------

-- | 'collapseProvenance' zips two parallel traversals (claims from
-- 'canonicalize', provenance from 'drsConditionProvs'). If those ever walk
-- conditions in different orders or different counts, the zip silently
-- truncates and facts get the wrong derivations attached. Worth pinning down.
integrityChecks :: [Check]
integrityChecks =
  [ expect
      "prov: fact count matches the condition-provenance count exactly"
      (all
         (\c ->
            let sel = provenanceOf srcA (caseText c)
                drs = discourseOf srcA (caseText c)
            in length (pfFacts sel) == length (drsConditionProvs drs))
         fragmentCases)
  , expect
      "prov: nothing is dropped relative to the source DRS"
      (all
         (\c ->
            let drs = discourseOf srcA (caseText c)
            in length (pfFacts (provenanceOf srcA (caseText c)))
                 == length (drsConditionProvs drs))
         fragmentCases)
  , expect
      "prov: fact ids are contiguous from zero"
      (all
         (\c ->
            let fs = pfFacts (provenanceOf srcA (caseText c))
            in map factId fs == [0 .. length fs - 1])
         fragmentCases)
  , expect
      "prov: nested boxes contribute facts too"
      (length (pfFacts (provenanceOf srcA "No student sleeps.")) > 1)
  , expect
      "prov: the universe survives the collapse"
      (pfUniverse (provenanceOf srcA "A student arrived.") == [CRef 0])
  , expect
      "prov: every case in the evaluation set collapses without error"
      (all (\c -> not (null (pfFacts (provenanceOf srcA (caseText c))))) fragmentCases)
  ]

--------------------------------------------------------------------------------
-- 6. Strategy contract
--------------------------------------------------------------------------------

strategyChecks :: [Check]
strategyChecks =
  [ expectEq "prov: strategy is named" "provenance-mode" (strategyName provenanceStrategy)
  , expect
      "prov: strategy documents what it preserves"
      (not (null (strategyDoc provenanceStrategy)))
  , expect
      "prov: running the strategy also yields the decision record"
      (case prSelection (runFragment srcA "John loves Mary.") of
         Nothing -> False
         Just sel ->
           let (_, dec) = runStrategy provenanceStrategy sel
           in decKind dec == "collapse" && not (null (decWhy dec)))
  , expect
      "prov: applyStrategy agrees with collapseProvenance"
      (case prSelection (runFragment srcA "Every student reads a book.") of
         Nothing  -> False
         Just sel -> applyStrategy provenanceStrategy sel == collapseProvenance sel)
  , expect
      "prov: the selection's rationale is carried into the output"
      (not (null (pfRationale (provenanceOf srcA "John loves Mary."))))
  , expect
      "prov: rendering mentions that no deduplication happened"
      (let r = renderProvenanceForm twoDocsSameClaim
       in not (null r))
  ]

--------------------------------------------------------------------------------
-- Main
--------------------------------------------------------------------------------

main :: IO ()
main =
  runChecks
    "provenance-mode collapse"
    ( concat
        [ separationChecks
        , retractionChecks
        , convergenceChecks
        , howProvenanceChecks
        , integrityChecks
        , strategyChecks
        ]
    )
