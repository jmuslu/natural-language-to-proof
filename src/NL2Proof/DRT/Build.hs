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
  , describeIota
    -- * Anaphora resolution
  , resolveLocalAnaphora
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
      App (Con c _) p | c == iotaName -> DConst (describeIota p)
      _       -> DConst (pretty t)

    -- Provenance for a condition: the words behind its predicate symbol and
    -- behind each of its constant arguments (including the words of a definite
    -- description, which reach the condition as an iota argument).
    condProvFor args extra =
      let names = extra ++ filter (/= iotaName) (concatMap constNames args)
      in case mapMaybe (lookupProv idx) (nub names) of
           [] -> fallback
           ps -> provRule "cond" ps

    -- Provenance for a referent: the words behind the predicates that apply to
    -- it, which for @exists x. student(x) & ...@ is the noun @student@.
    refProv v body =
      case mapMaybe (lookupProv idx) (predicatesOn v body) of
        [] -> fallback
        ps -> provRule "ref" ps

-- | The constant a definite description @iota(P)@ denotes, named by its
-- descriptive content: the one-place predicates @P@ conjoins on its variable, in
-- order, space-separated (@the bald eagle@ names @"bald eagle"@).
--
-- __This is the unique-name reading of definites, stated:__ a description is a
-- rigid name for one individual, and the same description in two places names
-- the same individual, so identity across sentences needs no resolution step.
-- That is the reading the ProofWriter theories are generated under, and it is a
-- /translation/ here, not a decision: nothing is chosen among candidates. A
-- description that is not a conjunction of one-place predicates on its variable
-- is rendered verbatim rather than guessed at.
describeIota :: Term -> String
describeIota p = case p of
  Con c _ -> c
  Lam v _ body | Just cs <- mapM (onVar v) (conjs body) -> unwords cs
  _ -> pretty p
  where
    conjs (TAnd a b) = conjs a ++ conjs b
    conjs t          = [t]
    onVar v (App (Con c _) (Var v')) | v' == v = Just c
    onVar _ _                                 = Nothing

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
-- __The heuristic, stated explicitly:__ pick the accessible referent whose
-- introducing words sit latest in the text. Nothing else — no gender agreement,
-- no number agreement, no salience weighting, no world knowledge.
--
-- "Latest in the text" rather than "last added to the universe": see
-- 'recencyOrdered'. The two agree today and stop agreeing the moment a
-- scope-permuted reading is lowered into a box.
--
-- It is stated here rather than left implicit because an un-stated heuristic
-- isn't reusable on the next batch of examples. It is deliberately weak, and
-- every application of it is logged with the alternatives it passed over, so the
-- disagreements it produces are visible instead of silent. That log is the input
-- Stage 2 needs in order to do better.
--
-- The candidate set now comes from 'Antecedents' rather than being computed
-- inline, so "do better" can mean "supply a different candidate set" without
-- touching the substitution or the logging.
resolveAnaphora :: DRS -> DRS -> Prov -> (DRS, Trace)
resolveAnaphora context = resolveAnaphoraWith (flatAntecedents context)

-- | A ranked candidate list together with the name of the rule that produced it.
--
-- Introduced so that the /source/ of antecedents is a parameter rather than a
-- hard-coded call to 'accessibleRefs'. Stage 1 supplies 'flatAntecedents'; an
-- SDRT layer would supply a frontier-restricted list. Both then go through the
-- same 'resolveAnaphoraWith', so the substitution and the logging are shared and only
-- the candidate set differs — which is what makes the two comparable at all.
--
-- 'antWhy' and 'antNoneNote' travel with the candidates because a 'Decision'
-- that does not name its own heuristic is not reusable, and the two sources have
-- genuinely different explanations for the same outcome: flat threading says a
-- missing antecedent is inside a negated box, SDRT threading would say it was
-- closed off by a coordinating relation.
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
-- Ordering comes from 'recencyOrdered', which reads the surface position of the
-- words that introduced each referent. It deliberately does /not/ reverse
-- 'accessibleRefs': that list is in construction order, and construction order
-- coincides with surface order only while the grammar gives every subject wide
-- scope over its object. Recency has to mean "later in the text" for a reason
-- that survives scope permutation.
flatAntecedents :: DRS -> Antecedents
flatAntecedents context =
  Antecedents
    { antCandidates = recencyOrdered context
    , antWhy = "most recently introduced accessible referent, by surface position"
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
-- Intra-sentential anaphora (donkey binding)
--------------------------------------------------------------------------------

-- | Resolve a sentence's anaphors against the referents DRT makes accessible to
-- them /inside the sentence/: the referents of the anaphor's own box, of every
-- box that contains it, and — for a box in the consequent of a conditional —
-- of that conditional's antecedent box.
--
-- This is the donkey case. In @"If something is big then it is red"@ the
-- referent introduced by @something@ lives in the antecedent box, so
-- 'resolveAnaphora' (which only sees top-level referents of /earlier/ sentences)
-- cannot reach it, and it must not: the binding is internal to the conditional.
--
-- __The heuristic, stated:__ among accessible referents whose introducing words
-- /precede/ the pronoun, take the latest by surface position (the same recency
-- notion as 'recencyOrdered'). No agreement features are consulted. Every
-- binding is logged as an @anaphora@ 'Decision' naming the alternatives passed
-- over. An anaphor with no preceding accessible referent is left untouched, so
-- discourse-level resolution (or its 'UnresolvedAnaphor' diagnostic) still sees
-- it.
resolveLocalAnaphora :: ProvIndex -> DRS -> (DRS, Trace)
resolveLocalAnaphora idx = goBox []
  where
    goBox env (DRS us cs) =
      let env' = env ++ us
          (cs', tr) = foldl (step env') ([], mempty) cs
      in (DRS us (reverse cs'), tr)

    step env (acc, tr) c = case c of
      CNot d p ->
        let (d', t) = goBox env d in (CNot d' p : acc, tr <> t)
      COr a b p ->
        let (a', ta) = goBox env a
            (b', tb) = goBox env b
        in (COr a' b' p : acc, tr <> ta <> tb)
      CImp a b p ->
        let (a', ta) = goBox env a
            (b', tb) = goBox (env ++ drsUniverse a') b
        in (CImp a' b' p : acc, tr <> ta <> tb)
      _ ->
        let (c', t) = foldl (resolveIn env) (c, mempty) (anaphorsIn c)
        in (c' : acc, tr <> t)

    anaphorsIn (CPred _ as _) = nub [n | DConst n <- as, isAnaphorName n]
    anaphorsIn (CEq a b _)    = nub [n | DConst n <- [a, b], isAnaphorName n]
    anaphorsIn _              = []

    resolveIn env (c, tr) name =
      let here = lookupProv idx name >>= provSpan
          before (_, p) = case (here, provSpan p) of
            (Just h, Just s) -> spanStart s < spanStart h
            _                -> False
          ranked = recencyOrdered (DRS (filter before env) [])
      in case ranked of
           [] -> (c, tr)
           (chosen : rejected) ->
             ( substCond name (DRef chosen) c
             , tr <> note Decision
                 { decKind = "anaphora"
                 , decChoice = show chosen
                 , decAlternatives = map show rejected
                 , decWhy = "intra-sentential (DRT accessibility: own box, enclosing"
                     ++ " boxes, antecedent of an enclosing conditional); latest"
                     ++ " accessible referent preceding the pronoun"
                 , decProv = fromMaybe (condProv c) (lookupProv idx name)
                 } )

    substCond name new c = case drsConds (substConstDRS name new (DRS [] [c])) of
      [c'] -> c'
      _    -> c

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
