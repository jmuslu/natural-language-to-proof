-- | __truth-mode__ collapse tests.
--
-- Picked up automatically by @scripts\/build.{sh,ps1}@, which run
-- @test\/ModeSpec.hs@ when it exists.
--
-- The suite is organized around the property that /defines/ this mode: two
-- independent assertions of the same proposition must become __one__. The
-- companion assertion on the @provenance-mode@ branch is the exact opposite, and
-- both are run against the same shared core. If either branch ever satisfied
-- both properties, the two modes would have stopped being distinct.
module Main (main) where

import Data.List (sort)

import Harness
import NL2Proof.Collapse.Class
import NL2Proof.Collapse.Truth
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

srcA, srcB :: SourceId
srcA = SourceId "A"
srcB = SourceId "B"

-- | Run the pipeline and collapse, truth-mode.
truthOf :: SourceId -> String -> TruthForm
truthOf s t = case prSelection (runFragment s t) of
  Nothing  -> error ("no selection for " ++ show t)
  Just sel -> collapseTruth sel

-- | Merge two independently-sourced discourses into one DRS, the way a system
-- ingesting two documents would.
--
-- Deliberately uses a sentence with no discourse referents, so merging cannot
-- collide variable names — that would be a different bug wearing this test's
-- clothes.
mergedSelection :: String -> String -> Selection
mergedSelection ta tb =
  selectOnly
    (mergeDRS (discourseOf srcA ta) (discourseOf srcB tb))
    (provRule "two-documents" [ProvLex srcA (Span 0 1) "a", ProvLex srcB (Span 0 1) "b"])
  where
    discourseOf s t = dscDRS (prDiscourse (runFragment s t))

--------------------------------------------------------------------------------
-- 1. The defining property: equal propositions merge
--------------------------------------------------------------------------------

mergeChecks :: [Check]
mergeChecks =
  [ -- The same claim asserted twice in one document collapses to one condition.
    expectEq
      "truth: a claim repeated in one document collapses to one condition"
      1
      (canonConditionCount (tfForm (truthOf srcA "John loves Mary. John loves Mary.")))
  , expect
      "truth: and the collapse is reported as loss, not hidden"
      (tfDropped (truthOf srcA "John loves Mary. John loves Mary.") > 0)
  , -- The headline case from ARCHITECTURE.md: two *different sources* asserting
    -- the same proposition. truth-mode merges them and can no longer tell them
    -- apart. That is correct here and catastrophic in provenance-mode, which is
    -- why the modes are separate branches rather than a runtime flag.
    expectEq
      "truth: two documents asserting one proposition collapse to one condition"
      1
      (canonConditionCount
         (tfForm (collapseTruth (mergedSelection "John loves Mary." "John loves Mary."))))
  , expectEq
      "truth: but both sources are still named (why-provenance survives)"
      [srcA, srcB]
      (tfSources (collapseTruth (mergedSelection "John loves Mary." "John loves Mary.")))
  , expect
      "truth: merging two documents with different claims drops nothing"
      (tfDropped (collapseTruth (mergedSelection "John loves Mary." "Mary smiles.")) == 0)
  , expectEq
      "truth: two different claims stay two conditions"
      2
      (canonConditionCount
         (tfForm (collapseTruth (mergedSelection "John loves Mary." "Mary smiles."))))
  ]

--------------------------------------------------------------------------------
-- 2. Canonicality
--------------------------------------------------------------------------------

canonicalityChecks :: [Check]
canonicalityChecks =
  [ -- Surface order must not be observable in the output.
    expect
      "truth: canonical form is insensitive to sentence order"
      (sameProposition
         (truthOf srcA "John loves Mary. Mary smiles.")
         (truthOf srcA "Mary smiles. John loves Mary."))
  , expect
      "truth: canonical form is insensitive to which source it came from"
      (sameProposition (truthOf srcA "John loves Mary.") (truthOf srcB "John loves Mary."))
  , expect
      "truth: but the source set is not erased"
      (tfSources (truthOf srcA "John loves Mary.") /= tfSources (truthOf srcB "John loves Mary."))
  , expect
      "truth: genuinely different propositions do not collapse together"
      (not (sameProposition (truthOf srcA "John loves Mary.") (truthOf srcA "Mary smiles.")))
  , expect
      "truth: negation is not lost in compression"
      (not (sameProposition (truthOf srcA "John loves Mary.") (truthOf srcA "John does not love Mary.")))
  , -- Compression must be a fixed point, or "canonical" means nothing.
    expect
      "truth: compress is idempotent across the whole evaluation set"
      (all idempotent (map caseText fragmentCases))
  , expect
      "truth: sources are sorted, so the field itself is canonical"
      (all (\c -> let ss = tfSources (truthOf srcA (caseText c)) in ss == sort ss) fragmentCases)
  ]
  where
    idempotent t =
      let once = tfForm (truthOf srcA t)
          twice = fst (compress once)
      in once == twice

--------------------------------------------------------------------------------
-- 3. Measured loss
--------------------------------------------------------------------------------

-- | truth-mode is lossy by design. The requirement is not that it loses nothing,
-- but that it /reports/ what it lost — per the methodology note that drift you
-- have measured differs in kind from drift you have assumed away.
lossChecks :: [Check]
lossChecks =
  [ expect
      "truth: no spurious loss on the evaluation set"
      (all (\c -> tfDropped (truthOf srcA (caseText c)) == 0) fragmentCases)
  , expect
      "truth: compressionRatio is 1.0 when nothing was dropped"
      (compressionRatio (truthOf srcA "John loves Mary.") == 1.0)
  , expect
      "truth: compressionRatio drops below 1.0 when conditions merged"
      (compressionRatio (truthOf srcA "John loves Mary. John loves Mary.") < 1.0)
  , expect
      "truth: dropped count reconciles with the size difference"
      (let tf = truthOf srcA "John loves Mary. John loves Mary."
           original = canonSize (canonicalize (dscDRS (prDiscourse (runFragment srcA "John loves Mary. John loves Mary."))))
       in canonSize (tfForm tf) + tfDropped tf == original)
  ]

--------------------------------------------------------------------------------
-- 4. Strategy contract
--------------------------------------------------------------------------------

strategyChecks :: [Check]
strategyChecks =
  [ expectEq "truth: strategy is named" "truth-mode" (strategyName truthStrategy)
  , expect
      "truth: strategy documents what it discards"
      (not (null (strategyDoc truthStrategy)))
  , expect
      "truth: running the strategy also yields the decision record"
      (case prSelection (runFragment srcA "John loves Mary.") of
         Nothing -> False
         Just sel ->
           let (_, dec) = runStrategy truthStrategy sel
           in decKind dec == "collapse" && not (null (decWhy dec)))
  , expect
      "truth: applyStrategy agrees with collapseTruth"
      (case prSelection (runFragment srcA "Every student reads a book.") of
         Nothing  -> False
         Just sel -> applyStrategy truthStrategy sel == collapseTruth sel)
  , expect
      "truth: nested boxes are compressed too"
      (let tf = truthOf srcA "No student sleeps."
       in case canonConds (tfForm tf) of
            [CanNot inner] -> canonConditionCount inner == 2
            _              -> False)
  , expect
      "truth: every case in the evaluation set collapses without error"
      (all (\c -> canonSize (tfForm (truthOf srcA (caseText c))) > 0) fragmentCases)
  ]

--------------------------------------------------------------------------------
-- Main
--------------------------------------------------------------------------------

main :: IO ()
main =
  runChecks
    "truth-mode collapse"
    (concat [mergeChecks, canonicalityChecks, lossChecks, strategyChecks])
