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
  , toDRSWithOrOrigins
  , OrLoweringFailure(..)
  , predicatesOn
  , describeIota
    -- * Anaphora resolution
  , resolveLocalAnaphora
  , Antecedents(..)
  , flatAntecedents
  , resolveAnaphora
  , resolveAnaphoraWith
    -- * Presupposition
  , projectPresuppositions
  , reportDefiniteDecisions
    -- * Discourse
  , Discourse(..)
  , emptyDiscourse
  , extendDiscourse
  , runDiscourse
  ) where

import Data.Functor.Identity (Identity(..))
import Data.Char (toLower)
import Data.List (isPrefixOf, nub, sortBy)
import qualified Data.Map as M
import Data.Maybe (fromMaybe, mapMaybe)

import NL2Proof.DRT.Types
import NL2Proof.Provenance
import NL2Proof.Semantics.Intensional (deindexWith, isFactiveVerb)
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
-- | Active occurrence failures are distinct from semantic type-check failures.
data OrLoweringFailure
  = MissingOrOrigin [Int]
  | UnconsumedOrOrigin [Int]
  | UnsupportedOrTerm [Int]
  | UnsupportedOrAttitude [Int]
  deriving (Eq, Show)

-- Internal state consumes each supplied occurrence once. It is not an origin
-- certificate constructor: the caller must supply independently licensed sources.
newtype OriginWalk a = OriginWalk
  { runOriginWalk :: M.Map [Int] Prov -> Either OrLoweringFailure (a, M.Map [Int] Prov) }
instance Functor OriginWalk where
  fmap f (OriginWalk g) = OriginWalk $ \m -> do
    (a,m') <- g m
    pure (f a,m')
instance Applicative OriginWalk where
  pure a = OriginWalk $ \m -> Right (a,m)
  OriginWalk f <*> OriginWalk g = OriginWalk $ \m -> do
    (h,m') <- f m
    (a,m'') <- g m'
    pure (h a,m'')
instance Monad OriginWalk where
  OriginWalk g >>= f = OriginWalk $ \m -> do
    (a,m') <- g m
    runOriginWalk (f a) m'

-- | Legacy lowering keeps its exact fallback and unsupported-term behavior.
toDRS :: ProvIndex -> Prov -> Term -> DRS
toDRS idx fallback t = runIdentity
  (buildDRS (\_ _ -> pure ()) (\_ -> pure fallback) idx fallback t)

-- | Lower an already normalized term with occurrence-local OR provenance.
-- Uses the SAME conversion as toDRS; only explicit active validation and OR
-- provenance differ. Every map entry must be consumed, and every OR needs one.
-- This structural API does not license source markers or select English senses.
toDRSWithOrOrigins :: ProvIndex -> Prov -> Term -> M.Map [Int] Prov
                  -> Either OrLoweringFailure DRS
toDRSWithOrOrigins idx fallback t origins = do
  (d, remaining) <- runOriginWalk (buildDRS supported takeOrigin idx fallback t) origins
  case M.lookupMin remaining of
    Nothing -> Right d
    Just (p,_) -> Left (UnconsumedOrOrigin p)
  where
    takeOrigin p = OriginWalk $ \m -> case M.lookup p m of
      Nothing -> Left (MissingOrOrigin p)
      Just origin -> Right (origin,M.delete p m)
    supported p term = OriginWalk $ \m ->
      let failWith f = Left (f p)
      in case term of
        TExists{} -> Right ((),m)
        TForall{} -> Right ((),m)
        TAnd{} -> Right ((),m)
        TImp{} -> Right ((),m)
        TOr{} -> Right ((),m)
        TNot{} -> Right ((),m)
        TEq a b | not (containsOr a || containsOr b) -> Right ((),m)
        Con{} -> Right ((),m)
        App{} -> case spine term of
          (Con _ _, args)
            | not (null args), Lam _ TyS _ <- last args -> failWith UnsupportedOrAttitude
            | not (any containsOr args) -> Right ((),m)
          _ -> failWith UnsupportedOrTerm
        _ -> failWith UnsupportedOrTerm
    containsOr term = case term of
      TOr{} -> True
      Lam _ _ x -> containsOr x
      TExists _ _ x -> containsOr x
      TForall _ _ x -> containsOr x
      TNot x -> containsOr x
      App x y -> containsOr x || containsOr y
      TAnd x y -> containsOr x || containsOr y
      TImp x y -> containsOr x || containsOr y
      TEq x y -> containsOr x || containsOr y
      _ -> False

-- One semantic conversion for legacy and occurrence-aware modes. Paths refer
-- to the original normalized Term tree, never the flattened DRS condition list.
buildDRS :: Monad m => ([Int] -> Term -> m ()) -> ([Int] -> m Prov)
         -> ProvIndex -> Prov -> Term -> m DRS
buildDRS check orOrigin idx fallback = go []
  where
    go path term = do
      check path term
      case term of
        TExists v _ body -> addRef (Ref v) (refProv v body) <$> go (path ++ [0]) body
        TAnd a b -> mergeDRS <$> go (path ++ [0]) a <*> go (path ++ [1]) b
        TForall v _ (TImp a b) -> do
          left <- go (path ++ [0,0]) a
          right <- go (path ++ [0,1]) b
          pure (DRS [] [CImp (addRef (Ref v) (refProv v a) left) right fallback])
        TForall v _ body -> do
          right <- go (path ++ [0]) body
          pure (DRS [] [CImp (DRS [(Ref v,refProv v body)] []) right fallback])
        TImp a b -> do
          left <- go (path ++ [0]) a
          right <- go (path ++ [1]) b
          pure (DRS [] [CImp left right fallback])
        TOr a b -> do
          origin <- orOrigin path
          left <- go (path ++ [0]) a
          right <- go (path ++ [1]) b
          pure (DRS [] [COr left right origin])
        TNot a -> do
          child <- go (path ++ [0]) a
          pure (DRS [] [CNot child fallback])
        TEq a b -> pure (DRS [] [CEq (dterm a) (dterm b) (condProvFor [a,b] [])])
        App{} -> case spine term of
          (Con c _, args)
            | not (null args), Lam w TyS body <- last args -> do
                child <- go (path ++ [1,0]) (deindexWith (Var w) body)
                pure (DRS [] [CAtt c (map dterm (init args)) child (condProvFor (init args) [c])])
          (Con c _, args) -> pure (DRS [] [CPred c (map dterm args) (condProvFor args [c])])
          _ -> pure (unsupported term)
        Con c _ -> pure (DRS [] [CPred c [] (condProvFor [] [c])])
        _ -> pure (unsupported term)
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
-- introducing words sit latest in the text. Main-box constants are candidates
-- too. Neuter it excludes attitude participants conservatively; there is no
-- general gender/number agreement, salience weighting or world knowledge.
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
  { antCandidates :: [DTerm]
    -- ^ Best first.
  , antPersonal :: [DTerm]
    -- ^ Attitude participants, conservatively excluded for neuter @it@. This is a
    -- selection heuristic, not an animacy ontology.
  , antWhy        :: String
    -- ^ The rule that ordered them.
  , antNoneNote   :: String
    -- ^ Why there may be none, for the diagnostic.
  }

-- | Stage 1's source: top-level referents and directly mentioned named
-- entities, most recent first. Names and definite descriptions remain constants
-- in the logic; making them bindable does not invent an existential or equality.
-- Only direct arguments in the main box (including attitude holders) enter here.
-- Constants in subordinate boxes never become discourse candidates.
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
    { antCandidates = nub [ t | (_, _, t) <- sortBy laterFirst keyed ]
    , antPersonal = nub [a | CAtt _ as _ _ <- drsConds context, a <- as]
    , antWhy = "most recently introduced accessible referent or directly mentioned named entity, by lexical surface position; it conservatively excludes personal attitude participants"
    , antNoneNote =
        "referents inside negated, implicational or attitude boxes are correctly"
          ++ " inaccessible; it also excludes personal attitude participants"
    }
  where
    mentions = [(DRef r, p) | (r, p) <- drsUniverse context]
      ++ concatMap named (drsConds context)
    keyed = [(provSpan p, i, t) | (i, (t, p)) <- zip [0 :: Int ..] mentions]
    laterFirst (p, i, _) (q, j, _) = compare q p <> compare j i
    named c =
      [ (DConst n, nameProv n (condProv c))
      | DConst n <- directArgs c, not (isAnaphorName n) ]
    directArgs (CPred _ as _) = as
    directArgs (CEq a b _) = [a, b]
    directArgs (CAtt _ as _ _) = as
    directArgs _ = []
    -- A condition can mention both subject and object. Its covering span would
    -- tie their recency, so recover the entity's own words when available.
    nameProv n p = case
      [ ProvLex src sp w | (src, sp, w) <- provLeaves p
                        , map toLower w `elem` words (map toLower n) ] of
      [] -> p
      ps -> provRule "named-antecedent" ps

resolveAnaphoraWith :: Antecedents -> DRS -> Prov -> (DRS, Trace)
resolveAnaphoraWith ants new sentProv =
  foldl step (new, mempty) (anaphorConstants new)
  where
    eligible name t = not (isIt name && t `elem` antPersonal ants)
    isIt n = n == "?it" || "?it_" `isPrefixOf` n
    step (drs, tr) name = case filter (eligible name) (antCandidates ants) of
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
        ( substConstDRS name chosen drs
        , tr
            <> note
              Decision
                { decKind = "anaphora"
                , decChoice = show chosen
                       , decAlternatives = map show (rejected ++ filter (not . eligible name) (antCandidates ants))
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
    mentions name (CAtt _ as _ _) = DConst name `elem` as
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
      -- The attitude holder is resolved where the condition sits; the reported
      -- box is subordinate, like a negated one.
      CAtt {} ->
        let (c', t) = foldl (resolveIn env) (c, mempty) (anaphorsIn c)
        in case c' of
             CAtt v as k p ->
               let (k', tk) = goBox env k in (CAtt v as k' p : acc, tr <> t <> tk)
             _ -> (c' : acc, tr <> t)
      CPresup k p ->
        let (k', t) = goBox env k in (CPresup k' p : acc, tr <> t)
      _ ->
        let (c', t) = foldl (resolveIn env) (c, mempty) (anaphorsIn c)
        in (c' : acc, tr <> t)

    anaphorsIn (CPred _ as _) = nub [n | DConst n <- as, isAnaphorName n]
    anaphorsIn (CEq a b _)    = nub [n | DConst n <- [a, b], isAnaphorName n]
    anaphorsIn (CAtt _ as _ _) = nub [n | DConst n <- as, isAnaphorName n]
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
-- Presupposition projection
--------------------------------------------------------------------------------

-- | Hoist the complement of every factive attitude condition (@know(x, K)@,
-- @know@ in 'NL2Proof.Semantics.Intensional.factiveVerbs') as a presupposed
-- box, @CPresup K@, logging a @presupposition@ 'Decision' for each.
-- @know(x, K)@ itself stays where it is.
--
-- __The rule, stated:__ the presupposition goes to the top of its target box,
-- wherever the factive sits below it, so it projects through negation,
-- conditionals and disjunction: @"Bob does not know that P"@ still
-- presupposes @P@. The target is the main DRS, except:
--
-- * __Never out of an attitude report.__ Under an enclosing attitude the target
--   is that attitude's box. In @"Alice said that Bob knows that P"@ the
--   commitment to @P@ is Alice's, so @P@ stays inside her report: projecting it
--   to the main DRS would turn hearsay into an assertion.
-- * __Binding is out of scope.__ If @K@ uses a referent not accessible at the
--   target (bound by a box in between), nothing is hoisted and the decision
--   says so. Local accommodation is not implemented.
--
-- Hoisted boxes are alpha-renamed against every referent in the structure, so
-- the merge stays disjoint.
projectPresuppositions :: DRS -> (DRS, Trace)
projectPresuppositions root =
  let rootAcc = map fst (drsUniverse root)
      (d, hs, tr) = box rootAcc [] Nothing root
  in (absorb d hs, tr)
  where
    taken = drsRefs root

    -- Append hoisted conditions to their target, freshening each.
    absorb = foldl (\acc h -> mergeDRS acc (fst (freshenAgainst (taken ++ drsRefs acc) h)))

    -- @tgtAcc@: referents accessible at the current target box; @env@:
    -- referents accessible here (this box's universe is added); @att@: the
    -- verb of the enclosing attitude, if any.
    box tgtAcc env att (DRS us cs) =
      let env' = env ++ map fst us
          (cs', hs, tr) = foldl (step tgtAcc env' att) ([], [], mempty) cs
      in (DRS us (reverse cs'), hs, tr)

    step tgtAcc env att (acc, hs, tr) c = case c of
      CNot d p ->
        let (d', h, t) = box tgtAcc env att d in (CNot d' p : acc, hs ++ h, tr <> t)
      COr a b p ->
        let (a', ha, ta) = box tgtAcc env att a
            (b', hb, tb) = box tgtAcc env att b
        in (COr a' b' p : acc, hs ++ ha ++ hb, tr <> ta <> tb)
      CImp a b p ->
        let (a', ha, ta) = box tgtAcc env att a
            (b', hb, tb) = box tgtAcc (env ++ map fst (drsUniverse a')) att b
        in (CImp a' b' p : acc, hs ++ ha ++ hb, tr <> ta <> tb)
      CAtt v as k p ->
        -- The attitude box is the target for whatever projects inside it.
        let kAcc = env ++ map fst (drsUniverse k)
            (k', hk, tk) = box kAcc env (Just v) k
            here = CAtt v as (absorb k' hk) p : acc
            free = [ r | r <- usedRefs k, r `notElem` drsRefs k ]
        in if not (isFactiveVerb v)
             then (here, hs, tr <> tk)
             else if all (`elem` tgtAcc) free
               then (here, hs ++ [DRS [] [CPresup k p]], tr <> tk <> decide v p att True)
               else (here, hs, tr <> tk <> decide v p att False)
      _ -> (c : acc, hs, tr)

    usedRefs (DRS _ cs) = nub (concatMap condRefs cs)
    condRefs c = case c of
      CPred _ as _  -> [r | DRef r <- as]
      CEq a b _     -> [r | DRef r <- [a, b]]
      CNot d _      -> usedRefs d
      CImp a b _    -> usedRefs a ++ usedRefs b
      COr a b _     -> usedRefs a ++ usedRefs b
      CAtt _ as k _ -> [r | DRef r <- as] ++ usedRefs k
      CPresup k _   -> usedRefs k

    decide v p att projected =
      note Decision
        { decKind = "presupposition"
        , decChoice = case (projected, att) of
            (True, Nothing) -> "complement of " ++ v ++ " presupposed in the main DRS"
            (True, Just a)  -> "complement of " ++ v ++ " presupposed inside the report of "
                                 ++ a ++ " (stays attributed)"
            (False, _)      -> "not projected: the complement of " ++ v
                                 ++ " uses a referent bound below the target"
        , decAlternatives =
            [ "no presupposition (non-factive reading)" ]
              ++ [ "projection to the main DRS (refused: would assert reported content)"
                 | Just _ <- [att] ]
        , decWhy = "factive verb: its complement is presupposed at the actual world and"
            ++ " projects through negation and conditionals, never out of an attitude"
            ++ " report; local accommodation and binding are out of scope"
        , decProv = p
        }

-- | Decisions about definite descriptions inside attitude complements: each is
-- read /de dicto/, local to the report.
--
-- The repo's definite encoding (a description-named constant, see
-- 'describeIota') is kept inside the report box, so @"Bob said that the cat is
-- red"@ reports @red(cat)@. Because it sits only in the report, the main DRS
-- does not assert that there is a cat; the de re reading (the speaker
-- vouching for the cat) is not generated. Logged, since nothing in the syntax
-- forces it.
reportDefiniteDecisions :: Prov -> Term -> Trace
reportDefiniteDecisions p = go False
  where
    go inReport t = case t of
      App (Con c _) d | c == iotaName, inReport ->
        note Decision
          { decKind = "definite-in-report"
          , decChoice = "de dicto: the description is local to the report"
          , decAlternatives = ["de re (description scoped out of the attitude, asserted)"]
          , decWhy = "complements are read de dicto; de re readings are not generated"
          , decProv = p
          } <> go inReport d
      Lam _ TyS b    -> go True b
      Lam _ _ b      -> go inReport b
      App f a        -> go inReport f <> go inReport a
      TAnd a b       -> go inReport a <> go inReport b
      TOr a b        -> go inReport a <> go inReport b
      TImp a b       -> go inReport a <> go inReport b
      TNot a         -> go inReport a
      TEq a b        -> go inReport a <> go inReport b
      TForall _ _ b  -> go inReport b
      TExists _ _ b  -> go inReport b
      _              -> mempty

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
