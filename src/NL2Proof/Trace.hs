-- | The tracing layer: decisions and diagnostics.
--
-- ARCHITECTURE.md, core principle: search\/generation and verification must stay
-- separated, and the pipeline must /explicitly collapse/ from a candidate set to
-- a single selected object before handing off downstream.
--
-- > That collapse is a decision, not a derivation, and should be logged as such.
--
-- 'Decision' is that log. A decision that does not record the alternatives it
-- discarded is indistinguishable from a derivation — which is precisely the
-- conflation the architecture forbids. So 'decAlternatives' is not optional
-- decoration; it is the field that makes a 'Decision' honest.
--
-- 'Diagnostic' implements the Stage 3 principle in miniature: produce
-- best-effort structures with attached ambiguity annotations rather than halting
-- on first ambiguity (parser error recovery, not parser failure).
module NL2Proof.Trace
  ( -- * Decisions
    Decision(..)
  , decisionCandidateCount
  , renderDecision
    -- * Diagnostics
  , DiagKind(..)
  , Diagnostic(..)
  , renderDiagnostic
    -- * Traces
  , Trace(..)
  , emptyTrace
  , note
  , flag
  , renderTrace
  ) where

import Data.List (intercalate)

import NL2Proof.Provenance

--------------------------------------------------------------------------------
-- Decisions
--------------------------------------------------------------------------------

-- | A point where the pipeline collapsed a candidate set to one choice.
data Decision = Decision
  { decKind         :: String
    -- ^ What kind of collapse (@"anaphora"@, @"parse-selection"@, @"scope"@).
  , decChoice       :: String
    -- ^ The option taken, rendered.
  , decAlternatives :: [String]
    -- ^ The options /not/ taken. Empty means the choice was forced, not free.
  , decWhy          :: String
    -- ^ The rule or heuristic that broke the tie. Name it explicitly: an
    -- un-stated heuristic isn't reusable on the next batch of examples.
  , decProv         :: Prov
    -- ^ Where in the source this decision was made.
  }
  deriving (Eq, Show)

-- | How many candidates were in play, including the one chosen.
decisionCandidateCount :: Decision -> Int
decisionCandidateCount d = 1 + length (decAlternatives d)

renderDecision :: Decision -> String
renderDecision d =
  "[" ++ decKind d ++ "] chose " ++ decChoice d ++ alts ++ "\n"
    ++ "    why: " ++ decWhy d ++ "\n"
    ++ "    at:  " ++ maybe "?" show (provSpan (decProv d))
    ++ " " ++ show (provSurface (decProv d))
  where
    alts = case decAlternatives d of
      [] -> " (forced, no alternatives)"
      as -> " over " ++ show (length as) ++ ": " ++ intercalate ", " as

--------------------------------------------------------------------------------
-- Diagnostics
--------------------------------------------------------------------------------

-- | Recurring shapes of failure. Kept as an explicit enumeration because,
-- per the methodology notes, disagreements are more valuable than agreements —
-- they are where failure modes become visible and harden into stated heuristics.
data DiagKind
  = -- | More than one CCG derivation survived.
    ParseAmbiguity
  | -- | Quantifier scope is underdetermined by the syntax.
    ScopeAmbiguity
  | -- | A stack of modifiers that may be a fused lexicalized subkind rather
    -- than iterated intersection — the @"ancient Chinese red dragon"@ case.
    -- Stage 1 deliberately does not resolve this; it flags it for Stage 2's
    -- tensor\/kernel coupling detection.
    ModifierCoupling
  | -- | A pronoun with no accessible antecedent.
    UnresolvedAnaphor
  | -- | No derivation at all.
    NoParse
  | -- | A term failed the semantic type check.
    TypeCheckFailure
  deriving (Eq, Ord, Show)

data Diagnostic = Diagnostic
  { diagKind :: DiagKind
  , diagMsg  :: String
  , diagProv :: Prov
  }
  deriving (Eq, Show)

renderDiagnostic :: Diagnostic -> String
renderDiagnostic d =
  "<" ++ show (diagKind d) ++ "> " ++ diagMsg d
    ++ "\n    at:  " ++ maybe "?" show (provSpan (diagProv d))
    ++ " " ++ show (provSurface (diagProv d))

--------------------------------------------------------------------------------
-- Traces
--------------------------------------------------------------------------------

-- | Accumulated decisions and diagnostics for a run.
--
-- Both lists are kept in source order.
data Trace = Trace
  { traceDecisions   :: [Decision]
  , traceDiagnostics :: [Diagnostic]
  }
  deriving (Eq, Show)

emptyTrace :: Trace
emptyTrace = Trace [] []

instance Semigroup Trace where
  Trace a b <> Trace c d = Trace (a ++ c) (b ++ d)

instance Monoid Trace where
  mempty = emptyTrace

note :: Decision -> Trace
note d = Trace [d] []

flag :: Diagnostic -> Trace
flag d = Trace [] [d]

renderTrace :: Trace -> String
renderTrace (Trace ds gs) = unlines (section "decisions" ds' ++ section "diagnostics" gs')
  where
    ds' = map renderDecision ds
    gs' = map renderDiagnostic gs
    section label [] = ["-- " ++ label ++ ": none"]
    section label xs = ("-- " ++ label ++ " (" ++ show (length xs) ++ ")") : xs
