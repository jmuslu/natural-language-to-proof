-- | Building DRSs from lambda terms, and threading them through a discourse.
--
-- Two things happen here that are worth separating in your head:
--
-- 1. 'toDRS' is a /translation/. A normalized first-order term maps onto box
--    notation mechanically; there is no choice being made and nothing is logged.
--
-- 2. 'resolveAnaphora' is a /decision/. It picks one antecedent out of several
--    accessible candidates, and it emits a 'Decision' recording what it chose,
--    what it rejected, and which heuristic broke the tie.
--
-- Keeping those two apart, even at Stage 1 where the decision procedure is a
-- one-line heuristic, is the whole point. When Stage 2 replaces the heuristic
-- with RSA-weighted candidate ranking, only 'resolveAnaphora' changes.
--
-- Discourse state is threaded explicitly through 'extendDiscourse' rather than
-- via a @State@ monad. The structure is the same; the explicit version makes the
-- provenance and trace plumbing visible at each step, which is what this stage
-- is for.
module NL2Proof.DRT.Build
  ( -- * Word-level provenance
    ProvIndex
  , buildProvIndex
  , lookupProv
    -- * Translation
  , toDRS
  , predicatesOn
    -- * Anaphora resolution
  , Antecedents(..)
  , flatAntecedents
  , resolveAnaphora
  , resolveAnaphoraWith
    -- * Discourse
  , Discourse(..)
  , emptyDiscourse
  , extendDiscourse
  , runDiscourse
  ) where

import Data.List (nub)
import qualified Data.Map as M
import Data.Maybe (fromMaybe, mapMaybe)

import NL2Proof.DRT.Types
import NL2Proof.Provenance
import NL2Proof.Semantics.Lambda
import NL2Proof.Syntax.Lexicon
import NL2Proof.Trace

--------------------------------------------------------------------------------
-- Word-level provenance
--------------------------------------------------------------------------------

-- | Maps a constant name (a predicate symbol, an entity name, an anaphor
-- placeholder) to the lexical provenance of the word that introduced it.
--
-- This is how conditions get __word-level__ provenance rather than merely
-- sentence-level, without threading provenance through the lambda calculus
-- itself. The lexicon is the only place a constant can enter a derivation, so
-- indexing that derivation's own lexical leaves is enough — and it keeps
-- "NL2Proof.Semantics.Lambda" ignorant of provenance, which is the right
-- separation.
--
-- Note the index is built from the /chosen derivation/, not from the words of
-- the sentence. Those differ: competing segmentations put competing lexical
-- units over the same words, and a unit that lost has no business supplying
-- provenance for a constant it did not contribute.
type ProvIndex = M.Map String Prov

buildProvIndex :: Lexicon -> Prov -> ProvIndex
buildProvIndex lexicon p =
  M.fromList
    [ (c, ProvLex s sp w)
    | (s, sp, w) <- provLeaves p
    , e <- lookupWord lexicon w
    , c <- constNames (entrySem e)
    ]

lookupProv :: ProvIndex -> String -> Maybe Prov
lookupProv = flip M.lookup

--------------------------------------------------------------------------------
-- Translation
--------------------------------------------------------------------------------

-- | Translate a normalized, closed, type-@t@ term into a DRS.
--
-- @fallback@ is the sentence's full CCG derivation, used for any node whose
-- provenance cannot be pinned to specific words.
toDRS :: ProvIndex -> Prov -> Term -> DRS
toDRS idx fallback = go
  where
    go term = case term of
      -- An existential introduces a referent into the universe.
      TExists v _ body ->
        addRef (Ref v) (refProv v body) (go body)

      TAnd a b -> mergeDRS (go a) (go b)

      -- A universal over an implication is the classic duplex condition, with
      -- the bound referent living in the antecedent box.
      TForall v _ (TImp a b) ->
        DRS [] [CImp (addRef (Ref v) (refProv v a) (go a)) (go b) fallback]

      TForall v _ body ->
        DRS [] [CImp (DRS [(Ref v, refProv v body)] []) (go body) fallback]

      TImp a b -> DRS [] [CImp (go a) (go b) fallback]
      TOr a b  -> DRS [] [COr (go a) (go b) fallback]
      TNot a   -> DRS [] [CNot (go a) fallback]

      TEq a b  -> DRS [] [CEq (dterm a) (dterm b) (condProvFor [a, b] [])]

      App{} -> case spine term of
        (Con c _, args) -> DRS [] [CPred c (map dterm args) (condProvFor args [c])]
        _               -> unsupported term

      Con c _ -> DRS [] [CPred c [] (condProvFor [] [c])]

      _ -> unsupported term

    -- Anything the fragment cannot express is recorded as an opaque condition
    -- rather than dropped, so it stays visible in the output.
    unsupported t = DRS [] [CPred ("UNSUPPORTED[" ++ pretty t ++ "]") [] fallback]

    dterm t = case t of
      Var v   -> DRef (Ref v)
      Con c _ -> DConst c
      _       -> DConst (pretty t)

    -- Provenance for a condition: the words behind its predicate symbol and
    -- behind each of its constant arguments.
    condProvFor args extra =
      let names = extra ++ [c | Con c _ <- args]
      in case mapMaybe (lookupProv idx) (nub names) of
           [] -> fallback
           ps -> provRule "cond" ps

    -- Provenance for a referent: the words behind the predicates that apply to
    -- it, which for @exists x. student(x) & ...@ is the noun @student@.
    refProv v body =
      case mapMaybe (lookupProv idx) (predicatesOn v body) of
        [] -> fallback
        ps -> provRule "ref" ps

-- | Names of predicates applied to exactly the variable @v@ and nothing else.
--
-- Used to attribute a referent to the noun that introduced it.
predicatesOn :: Var -> Term -> [String]
predicatesOn v = nub . go
  where
    go term = case term of
      App{} -> case spine term of
        (Con c _, [Var v']) | v' == v -> [c]
        (_, args)                     -> concatMap go args
      Lam _ _ b     -> go b
      TForall _ _ b -> go b
      TExists _ _ b -> go b
      TNot a        -> go a
      TAnd a b      -> go a ++ go b
      TOr a b       -> go a ++ go b
      TImp a b      -> go a ++ go b
      TEq a b       -> go a ++ go b
      Var{}         -> []
      Con{}         -> []

--------------------------------------------------------------------------------
-- Anaphora resolution
--------------------------------------------------------------------------------

-- | Resolve unresolved anaphors in @new@ against the referents accessible in
-- @context@.
--
-- __The heuristic, stated explicitly:__ pick the most recently introduced
-- accessible referent. Nothing else — no gender agreement, no number agreement,
-- no salience weighting, no world knowledge.
--
-- It is stated here rather than left implicit because an un-stated heuristic
-- isn't reusable on the next batch of examples. It is deliberately weak, and
-- every application of it is logged with the alternatives it passed over, so the
-- disagreements it produces are visible instead of silent. That log is the input
-- Stage 2 needs in order to do better.
--
-- The candidate set now comes from 'Antecedents' rather than being computed
-- inline, so "do better" can mean "supply a different candidate set" without
-- touching the substitution or the logging. 'NL2Proof.Stage2.Threading' is the
-- first consumer of that.
resolveAnaphora :: DRS -> DRS -> Prov -> (DRS, Trace)
resolveAnaphora context = resolveAnaphoraWith (flatAntecedents context)

-- | A ranked candidate list together with the name of the rule that produced it.
--
-- Introduced so that the /source/ of antecedents is a parameter rather than a
-- hard-coded call to 'accessibleRefs'. Stage 1 supplies 'flatAntecedents'; the
-- SDRT layer supplies a frontier-restricted list. Both then go through the same
-- 'resolveAnaphoraWith', so the substitution and the logging are shared and only
-- the candidate set differs — which is what makes the two comparable at all.
--
-- 'antWhy' and 'antNoneNote' travel with the candidates because a 'Decision'
-- that does not name its own heuristic is not reusable, and the two sources have
-- genuinely different explanations for the same outcome: flat threading says a
-- missing antecedent is inside a negated box, SDRT threading says it was closed
-- off by a coordinating relation.
data Antecedents = Antecedents
  { antCandidates :: [Ref]
    -- ^ Best first.
  , antWhy        :: String
    -- ^ The rule that ordered them.
  , antNoneNote   :: String
    -- ^ Why there may be none, for the diagnostic.
  }

-- | Stage 1's source: every top-level referent of the accumulated context,
-- most recent first.
--
-- 'accessibleRefs' yields source order (within a sentence 'toDRS' conses
-- outermost-first, and across sentences 'mergeDRS' appends), so the most
-- recently introduced referent is the /last/ one. Reverse to put it first.
flatAntecedents :: DRS -> Antecedents
flatAntecedents context =
  Antecedents
    { antCandidates = reverse (accessibleRefs context)
    , antWhy = "most recently introduced accessible referent"
    , antNoneNote =
        "referents inside negated or implicational boxes are correctly"
          ++ " inaccessible"
    }

resolveAnaphoraWith :: Antecedents -> DRS -> Prov -> (DRS, Trace)
resolveAnaphoraWith ants new sentProv =
  foldl step (new, mempty) (anaphorConstants new)
  where
    step (drs, tr) name = case antCandidates ants of
      [] ->
        ( drs
        , tr
            <> flag
              Diagnostic
                { diagKind = UnresolvedAnaphor
                , diagMsg =
                    "no accessible antecedent for " ++ name
                      ++ " (note: " ++ antNoneNote ants ++ ")"
                , diagProv = provFor name
                }
        )
      (chosen : rejected) ->
        ( substConstDRS name (DRef chosen) drs
        , tr
            <> note
              Decision
                { decKind = "anaphora"
                , decChoice = show chosen
                , decAlternatives = map show rejected
                , decWhy = antWhy ants
                , decProv = provFor name
                }
        )

    provFor name = fromMaybe sentProv (findAnaphorProv name)

    -- The anaphor's own lexical provenance, recovered from the new DRS.
    findAnaphorProv name =
      case [ condProv c | c <- drsConds new, mentions name c ] of
        (p : _) -> Just p
        []      -> Nothing

    mentions name (CPred _ as _) = DConst name `elem` as
    mentions name (CEq a b _)    = DConst name `elem` [a, b]
    mentions _ _                 = False

--------------------------------------------------------------------------------
-- Discourse
--------------------------------------------------------------------------------

-- | Accumulated discourse state: one DRS for everything so far, plus the trace
-- of every decision and diagnostic that produced it.
data Discourse = Discourse
  { dscDRS   :: DRS
  , dscTrace :: Trace
  }
  deriving (Eq, Show)

emptyDiscourse :: Discourse
emptyDiscourse = Discourse emptyDRS mempty

-- | Add one sentence's DRS to the discourse, resolving its anaphors against what
-- came before.
--
-- __Freshens first.__ 'mergeDRS' is only sound when the two universes are
-- disjoint, and referent names come from the lambda terms, so two sentences of
-- the same shape arrive with the same names. Without the alpha-conversion,
-- @\"A student arrived. A professor walks.\"@ merged to a single @x@ that was
-- both — see 'mergeDRS' for the box.
--
-- The renaming is mechanical and therefore not logged. Each referent keeps its
-- own provenance through 'mapRefs', so a renamed referent is still traceable to
-- the words that introduced it, which is what makes silence the right choice
-- here rather than a lost decision.
extendDiscourse :: Discourse -> DRS -> Prov -> Discourse
extendDiscourse (Discourse ctx tr) new sentProv =
  let (freshened, _) = freshenAgainst (drsRefs ctx) new
      (resolved, tr') = resolveAnaphora ctx freshened sentProv
  in Discourse (mergeDRS ctx resolved) (tr <> tr')

-- | Fold a sequence of sentence DRSs into one discourse, left to right.
runDiscourse :: [(DRS, Prov)] -> Discourse
runDiscourse = foldl (\d (drs, p) -> extendDiscourse d drs p) emptyDiscourse
