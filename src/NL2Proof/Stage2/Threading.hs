-- | SDRT-aware discourse threading: the tie-in between
-- "NL2Proof.Stage2.SDRT" and the anaphora resolution in "NL2Proof.DRT.Build".
--
-- == What was missing before this module
--
-- SDRT computed 'sdrsAccessible' correctly and nothing consulted it.
-- 'NL2Proof.DRT.Build.extendDiscourse' resolved pronouns against
-- 'NL2Proof.DRT.Types.accessibleRefs' of a flat merge, so the right frontier had
-- no effect on any output. The layer existed, was tested, and was inert.
--
-- == The first thing to notice, because it constrains the whole design
--
-- __SDRT threading can only ever remove antecedents.__ The frontier's referents
-- are a subset of the flat merge's: every unit's universe is in the merge, and
-- only some units are open. So switching the default from flat to
-- frontier-restricted is a strict loss of coverage — and on this fragment it is a
-- loss driven by a __stipulated cue weight__, which is exactly the kind of thing
-- that must not be allowed to silently delete an antecedent.
--
-- The direction of that loss is set by an awkward accident of the inventory:
-- 'glue''s no-cue default is 'Continuation', because it is the least committal
-- /relation/. But 'Continuation' is __coordinating__, so it is the most
-- restrictive choice for /accessibility/. The least committal relation is not the
-- least committal for anaphora. With no cues firing, committed threading closes
-- every parent and accessibility collapses to the previous sentence alone.
--
-- == So there are two policies, not one
--
-- * 'Committed' takes 'NL2Proof.Stage2.Distribution.argmax' of the relation
--   distribution and uses that relation's frontier. This is textbook SDRT. It is
--   also the version that can delete a correct resolution on the strength of a
--   guessed weight.
--
-- * 'Marginal' keeps every referent that /some/ positive-mass relation would
--   keep, annotated with how much mass that is. Nothing is deleted; the frontier
--   becomes a __ranking__ over antecedents instead of a filter.
--
-- 'Marginal' is the one that fits the standing principle — build the space, rank
-- it, keep collapse a separate logged step. It is also the one that lets SDRT
-- contribute to anaphora without regressing coverage, because 'Elaboration'
-- always retains positive mass, so a parent is never fully closed.
--
-- == The marginal is over one edge, not over the structure
--
-- Stated plainly because it would otherwise be over-read. Marginalising over
-- /every/ relation choice in a discourse means carrying a distribution over
-- structures, whose support is exponential in the number of segments. This module
-- marginalises over the __most recent edge only__, holding earlier attachments at
-- their committed values. That is enough to grade the referent whose reachability
-- the last relation choice actually governs, and it is cheap. It is a deliberate
-- truncation, not an approximation with a bound.
--
-- == Where the referents come from, and the off-by-one worth naming
--
-- For @relation(a, b)@ the referents of @a@ are accessible to @b@ /whatever the
-- relation is/: DRS accessibility flows from the left argument to the right one.
-- The relation's kind governs what the __next__ unit sees, not what @b@ sees. So
-- the frontier consulted when resolving unit @n@ is the frontier of the structure
-- through unit @n-1@, and the relation chosen at step @n@ affects unit @n+1@.
-- Getting this off by one would make a coordinating relation block its own right
-- argument, which is wrong.
--
-- == A known over-restriction, recorded rather than patched
--
-- A resolved pronoun adds no referent to its unit's universe — substitution
-- replaces a constant with an existing 'Ref'. So under 'Committed', a chain of
-- coordinating relations starves: @"A man walked in. He sat down. He ordered."@
-- has an empty frontier universe at the third unit even though the intended
-- referent is obvious. Real SDRT percolates referents up the graph. This does
-- not, and 'Marginal' sidesteps the symptom without fixing the cause.
module NL2Proof.Stage2.Threading
  ( -- * Segments
    Segment(..)
  , segmentsOf
    -- * Policies
  , Policy(..)
    -- * Antecedent ranking
  , Ranked(..)
  , rankedAntecedents
  , antecedentsFor
    -- * Threading
  , Step(..)
  , Threaded(..)
  , threadDiscourse
  , threadFragment
  , threadedDRS
    -- * Comparison with flat threading
  , Divergence(..)
  , compareThreading
    -- * Rendering
  , renderThreaded
  , renderDivergence
  ) where

import Data.List (intercalate, sortBy)
import Data.Maybe (fromMaybe, listToMaybe)
import Data.Ord (comparing)

import NL2Proof.DRT.Build
import NL2Proof.DRT.Types
import NL2Proof.Pipeline
import NL2Proof.Provenance
import NL2Proof.Stage2.Distribution
import NL2Proof.Stage2.SDRT
import NL2Proof.Syntax.Tokenize (tokText)
import NL2Proof.Trace

--------------------------------------------------------------------------------
-- Segments
--------------------------------------------------------------------------------

-- | One sentence's contribution: its DRS, its provenance, and its surface
-- tokens.
--
-- Tokens are carried because layer-1 cue detection is a surface fact that the DRS
-- has already thrown away.
data Segment = Segment
  { segDRS    :: DRS
  , segProv   :: Prov
  , segTokens :: [String]
  }

-- | The segments of a Stage 1 run: the sentences that produced a DRS.
--
-- A sentence that failed to parse or to type-check contributes nothing and has
-- already recorded a diagnostic saying so, exactly as in
-- 'NL2Proof.DRT.Build.runDiscourse'.
segmentsOf :: SourceId -> PipelineResult -> [Segment]
segmentsOf src p =
  [ Segment d (sentenceProv src r) (map tokText (srTokens r))
  | r <- prSentences p
  , Just d <- [srDRS r]
  ]

--------------------------------------------------------------------------------
-- Policies
--------------------------------------------------------------------------------

-- | How to turn the relation distribution into an antecedent list.
data Policy
  = -- | Commit to the most probable relation, then use its frontier. Textbook
    -- SDRT, and strictly lossy relative to the flat merge.
    Committed
  | -- | Keep every referent some positive-mass relation would keep, graded by
    -- that mass. Ranks rather than filters.
    Marginal
  deriving (Eq, Show)

--------------------------------------------------------------------------------
-- Antecedent ranking
--------------------------------------------------------------------------------

-- | A candidate antecedent, with the mass of the last edge's relation
-- distribution under which it stays reachable, and which relations those are.
--
-- @rkMass == 1@ means every relation keeps it — typically because it lives in the
-- immediately preceding unit, which is always on the frontier. A mass strictly
-- between 0 and 1 is the interesting case: the referent survives only if the last
-- attachment was subordinating, and the number says how much of the glue logic's
-- mass that is.
data Ranked = Ranked
  { rkRef       :: Ref
  , rkMass      :: Double
  , rkLicensors :: [Relation]
  }
  deriving (Eq, Show)

-- | Candidate antecedents for the unit about to be attached, best first.
--
-- @lastEdge@ is the most recently added edge together with the distribution its
-- relation was drawn from. 'Nothing' for a single-unit structure, where there is
-- no edge to marginalise over.
rankedAntecedents
  :: Policy
  -> SDRS
  -> Maybe (Label, Label, Dist Relation)
  -> [Ranked]
rankedAntecedents policy s lastEdge =
  sortBy (comparing (\k -> (negate (rkMass k), rankOf (rkRef k))))
    [ Ranked r m rels
    | r <- dedup (concatMap (visibleUnder . fst) weighted)
    , let hits = [(v, w) | (v, w) <- weighted, r `elem` visibleUnder v]
    , let m = sum (map snd hits)
    , let rels = [rel | (Just rel, _) <- hits]
    , m > 0
    ]
  where
    -- The hypothetical values for the last edge's relation, with their weights.
    weighted = case (policy, lastEdge) of
      (_, Nothing)                -> [(Nothing, 1)]
      (Committed, Just (_, _, d)) -> [(argmax d, 1)]
      (Marginal, Just (_, _, d))  -> [(Just r, m) | (r, m) <- ranked d]

    -- Referents visible under one hypothetical value for the last relation.
    visibleUnder Nothing = accessibleOn s (rightFrontier s)
    visibleUnder (Just rel) =
      let s' = case lastEdge of
                 Nothing        -> s
                 Just (p, c, _) -> setEdge p c rel s
      in accessibleOn s' (rightFrontier s')

    -- Recency over the whole discourse, used only as a tie-break so that grading
    -- never silently reorders equal-mass candidates. Most recent unit first, and
    -- within a unit rightmost first.
    recency =
      concat (reverse [reverse (accessibleRefs (duDRS u)) | u <- unitsInOrder s])

    rankOf r = fromMaybe (length recency) (lookupIndex r recency)

-- | Replace the relation on a specific edge, leaving everything else alone.
setEdge :: Label -> Label -> Relation -> SDRS -> SDRS
setEdge p c rel s =
  s { sdrsEdges =
        [ if (p', c') == (p, c) then (rel, p', c') else e
        | e@(_, p', c') <- sdrsEdges s
        ]
    }

-- | Wrap a ranking as an 'Antecedents' for
-- 'NL2Proof.DRT.Build.resolveAnaphoraWith'.
antecedentsFor :: Policy -> [Ranked] -> Antecedents
antecedentsFor policy rs =
  Antecedents
    { antCandidates = map rkRef rs
    , antWhy = case policy of
        Committed ->
          "most recent referent on the SDRT right frontier under the most"
            ++ " probable relation"
        Marginal ->
          "highest-mass referent on the SDRT right frontier, marginalising over"
            ++ " the last relation"
            ++ case rs of
                 (r : _) -> " (mass " ++ show3 (rkMass r) ++ ")"
                 []      -> ""
    , antNoneNote = case policy of
        Committed ->
          "the right frontier is closed: a coordinating relation shut the"
            ++ " earlier units off"
        Marginal ->
          "no relation with positive mass leaves an earlier unit open"
    }

--------------------------------------------------------------------------------
-- Threading
--------------------------------------------------------------------------------

-- | One threading step, kept in full because comparing against flat threading is
-- the point and needs the intermediate state.
data Step = Step
  { stLabel    :: Label
  , stFrontier :: [Label]
    -- ^ The frontier /before/ this unit attached: its available attachment sites.
  , stRanked   :: [Ranked]
    -- ^ The antecedents offered to this unit.
  , stParent   :: Maybe Label
  , stRelation :: Maybe Relation
  , stRelDist  :: Maybe (Dist Relation)
  , stCues     :: [Cue]
  }

data Threaded = Threaded
  { thSDRS   :: SDRS
  , thSteps  :: [Step]
  , thPolicy :: Policy
  , thTrace  :: Trace
  }

-- | Thread segments into an SDRS, resolving each unit's anaphors against the
-- frontier rather than against a flat merge.
threadDiscourse :: Policy -> [Segment] -> Threaded
threadDiscourse policy segs = case segs of
  [] -> Threaded emptySDRS [] policy mempty
  (s0 : rest) ->
    let l0 = Label 1
        -- The first unit has nothing to attach to and nothing to resolve
        -- against, so its own anaphors fail through the same code path as any
        -- other failure rather than a special case.
        (d0, tr0) =
          resolveAnaphoraWith (antecedentsFor policy []) (segDRS s0) (segProv s0)
        u0 = DiscourseUnit l0 d0 (segTokens s0)
        st0 = Step l0 [] [] Nothing Nothing Nothing []
    in go (addRoot u0 emptySDRS) Nothing [st0] tr0 (zip [2 ..] rest)
  where
    go sdrs _ steps tr [] = Threaded sdrs (reverse steps) policy tr
    go sdrs lastEdge steps tr ((i, seg) : more) =
      let front = rightFrontier sdrs
          rs = rankedAntecedents policy sdrs lastEdge
          (resolved, trAna) =
            resolveAnaphoraWith (antecedentsFor policy rs) (segDRS seg) (segProv seg)

          lbl = Label i
          unit = DiscourseUnit lbl resolved (segTokens seg)

          -- Attachment site: a recency default. The alternatives are logged
          -- because the frontier genuinely offers more than one, and choosing
          -- among them is a collapse like any other.
          parent = fromMaybe (Label 1) (listToMaybe front)
          trSite = case front of
            (_ : others@(_ : _)) ->
              note
                Decision
                  { decKind = "sdrt-attachment"
                  , decChoice = show parent
                  , decAlternatives = map show others
                  , decWhy =
                      "most recent open unit on the right frontier; a recency"
                        ++ " default, not a cue-driven choice"
                  , decProv = segProv seg
                  }
            _ -> mempty

          parentUnit = unitAt sdrs parent
          dist = parentUnit >>= \pu -> glue pu unit
          cues = maybe [] (\pu -> detectCues pu unit) parentUnit
          rel = fromMaybe Continuation (dist >>= argmax)

          trRel = case dist of
            Nothing -> mempty
            Just d ->
              note
                Decision
                  { decKind = "sdrt-relation"
                  , decChoice = relationGloss rel
                  , decAlternatives =
                      [show r ++ " " ++ show3 m | (r, m) <- ranked d, r /= rel]
                  , decWhy =
                      "glue logic argmax over cues ["
                        ++ intercalate ", " (map renderCue cues)
                        ++ "]; the weights are stipulated, the kind/frontier"
                        ++ " consequence is not"
                  , decProv = segProv seg
                  }

          step = Step lbl front rs (Just parent) (Just rel) dist cues
      in go
           (attach rel parent unit sdrs)
           (Just (parent, lbl, fromMaybe (certain rel) dist))
           (step : steps)
           (tr <> trSite <> trRel <> trAna)
           more

-- | Thread a Stage 1 result.
threadFragment :: Policy -> SourceId -> PipelineResult -> Threaded
threadFragment policy src p = threadDiscourse policy (segmentsOf src p)

-- | The flat merge of the threaded units, for comparison with
-- 'NL2Proof.DRT.Build.dscDRS'.
--
-- Note what this does __not__ do: it does not push the graph into the DRS. The
-- graph is the extra information, and flattening it here would discard exactly
-- that. This exists only to ask whether the two threadings resolved the same
-- pronouns.
threadedDRS :: Threaded -> DRS
threadedDRS t =
  foldr mergeDRS emptyDRS (map duDRS (unitsInOrder (thSDRS t)))

--------------------------------------------------------------------------------
-- Comparison with flat threading
--------------------------------------------------------------------------------

-- | A pronoun the two threadings resolved differently.
data Divergence = Divergence
  { dvAnaphor :: String
  , dvFlat    :: Maybe Ref
  , dvSDRT    :: Maybe Ref
  , dvWhy     :: String
  }
  deriving (Eq, Show)

-- | Every anaphor on which flat and SDRT-aware threading disagree.
--
-- Both resolvers take the head of their candidate list, so the comparison is
-- exactly head-of-flat against head-of-frontier, per anaphor, per segment. No
-- trace parsing: the traces keep decisions and diagnostics in separate lists, so
-- an unresolved anaphor and a resolved one cannot be interleaved back into source
-- order, and aligning on the pronoun's surface word would collide on a repeated
-- @"she"@.
--
-- The expected answer on the nine-case fragment is __none__, because both
-- multi-sentence cases are two sentences long, and in a two-unit structure the
-- only parent is on the pre-attachment frontier whatever relation is chosen.
-- Divergence needs three segments. Worth having as a check rather than an
-- assumption: it says the tie-in is safe to run on the existing corpus, and it
-- says the corpus is too short to exercise it.
compareThreading :: Policy -> [Segment] -> [Divergence]
compareThreading policy segs =
  concat (zipWith cmp (flatSteps emptyDRS segs) (thSteps (threadDiscourse policy segs)))
  where
    -- Flat threading, re-run here so both sides are read off candidate lists
    -- rather than off traces.
    flatSteps _ [] = []
    flatSteps ctx (s : ss) =
      let ants = flatAntecedents ctx
          (resolved, _) = resolveAnaphoraWith ants (segDRS s) (segProv s)
      in (segDRS s, listToMaybe (antCandidates ants))
           : flatSteps (mergeDRS ctx resolved) ss

    cmp (d, flatPick) st =
      [ Divergence n flatPick sdrtPick why
      | flatPick /= sdrtPick
      , n <- anaphorConstants d
      ]
      where
        sdrtPick = listToMaybe (map rkRef (stRanked st))
        why
          | sdrtPick == Nothing = "closed by the right frontier"
          | otherwise           = "the frontier ranks a different referent first"

--------------------------------------------------------------------------------
-- Rendering
--------------------------------------------------------------------------------

renderThreaded :: Threaded -> String
renderThreaded t =
  unlines $
    ("policy: " ++ show (thPolicy t))
      : concatMap renderStep (thSteps t)
      ++ ["", renderSDRS (thSDRS t)]
  where
    renderStep st =
      [ show (stLabel st) ++ ":"
      , "  attachment sites: " ++ showLabels (stFrontier st)
      , "  antecedents:      " ++ renderRanked (stRanked st)
      ]
        ++ [ "  attached:         " ++ show r ++ " to " ++ show p
           | Just r <- [stRelation st]
           , Just p <- [stParent st]
           ]
        ++ [ "  cues:             " ++ intercalate ", " (map renderCue (stCues st))
           | not (null (stCues st))
           ]

    showLabels [] = "(none)"
    showLabels ls = intercalate ", " (map show ls)

    renderRanked [] = "(none)"
    renderRanked rs =
      intercalate ", " [show (rkRef r) ++ "@" ++ show3 (rkMass r) | r <- rs]

renderDivergence :: Divergence -> String
renderDivergence d =
  dvAnaphor d ++ ": flat " ++ shown (dvFlat d) ++ " vs sdrt " ++ shown (dvSDRT d)
    ++ " (" ++ dvWhy d ++ ")"
  where
    shown = maybe "unresolved" show

--------------------------------------------------------------------------------
-- Small helpers
--------------------------------------------------------------------------------

show3 :: Double -> String
show3 v = show (fromIntegral (round (v * 1000) :: Int) / 1000 :: Double)

dedup :: Eq a => [a] -> [a]
dedup []       = []
dedup (x : xs) = x : dedup (filter (/= x) xs)

lookupIndex :: Eq a => a -> [a] -> Maybe Int
lookupIndex a as = listToMaybe [i | (i, b) <- zip [0 ..] as, b == a]
