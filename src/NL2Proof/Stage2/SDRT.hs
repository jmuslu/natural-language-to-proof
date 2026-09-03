-- | Segmented Discourse Representation Theory: labelled discourse units and
-- rhetorical relations between them.
--
-- == Why this is a new object, not a richer DRS
--
-- "NL2Proof.DRT.Types"'s `mergeDRS` is a monoid: it concatenates universes and
-- conditions. That can express /order and multiplicity/ and nothing else. It
-- cannot express __which units are still open for attachment__, because that is a
-- property of a graph, not of a flat list. So SDRT sits one level up:
--
-- > DRS   : a monoid of conditions
-- > SDRS  : a labelled graph whose nodes are DRSs and whose edges are relations
--
-- == The part that is mechanically load-bearing
--
-- Relations are not decoration. Via the __right frontier constraint__ they
-- determine which referents a later sentence can reach:
--
-- * a __subordinating__ relation (Elaboration, Explanation) leaves its left
--   argument open, so that unit's referents stay accessible
-- * a __coordinating__ relation (Narration, Contrast) closes its left argument,
--   so those referents become unreachable
--
-- Two identical DRSs joined by different relations therefore give __different__
-- accessibility for a third sentence, while their plain `mergeDRS` is identical
-- in both cases. That is the concrete sense in which this is a separate layer,
-- and 'sdrsAccessible' is where it shows up.
--
-- == A worked example that actually discriminates, and one that does not
--
-- A natural-looking demonstration is @"Every student reads a book."@ followed by a
-- specific instance. __It does not work.__ That sentence's top-level universe is
-- empty — both referents are trapped inside the duplex condition — so it
-- contributes no accessible referents whether or not it is on the frontier, and
-- the two relations give identical results. The example looks like SDRT does not
-- matter.
--
-- A first unit with a __top-level existential__ is required:
--
-- > A student arrived.   -- accessible {x}
-- > Mary smiles.         -- accessible {} ("mary" is a constant, not a referent)
-- > She reads a book.    -- needs an antecedent
--
-- Under @Elaboration@ the frontier is both units and @she@ can reach @x@. Under
-- @Narration@ the frontier is the second unit alone and @she@ has no antecedent.
-- Same two DRSs, same merge, different outcome.
--
-- == On the relation inventory and stratification
--
-- Relations stratify by what settles them, exactly as modifier classes do — but
-- they deliberately do __not__ share the type. ARCHITECTURE.md is explicit: the
-- stratification /principle/ is common, the classes are not, and collapsing them
-- into one enumeration would repeat the flattening error at a larger scale.
module NL2Proof.Stage2.SDRT
  ( -- * Relations
    Relation(..)
  , RelationKind(..)
  , relationKind
  , relationLayer
  , relationGloss
  , allRelations
    -- * Discourse units and structures
  , Label(..)
  , DiscourseUnit(..)
  , SDRS(..)
  , emptySDRS
  , addRoot
  , attach
  , labelsInOrder
  , unitsInOrder
    -- * The right frontier
  , rightFrontier
  , frontierFrom
  , sdrsAccessible
  , accessibleOn
  , isOpen
  , unitAt
    -- * Glue logic
  , Cue(..)
  , detectCues
  , cueWeight
  , noCuePrior
  , glue
    -- * Rendering
  , renderSDRS
  , renderCue
  ) where

import Data.List (intercalate, nub)
import qualified Data.Map.Strict as M

import NL2Proof.DRT.Types
import NL2Proof.Stage2.Distribution

--------------------------------------------------------------------------------
-- Relations
--------------------------------------------------------------------------------

-- | The relation inventory.
--
-- Kept small and deliberately not extensible-by-accident: adding a relation means
-- deciding its kind (which changes accessibility) and its layer (which says what
-- evidence could settle it). Both are required, so 'relationKind' and
-- 'relationLayer' are total functions over this type rather than lookups that
-- could silently miss.
data Relation
  = Narration      -- ^ next event in a sequence
  | Result         -- ^ the second unit is a consequence of the first
  | Contrast       -- ^ the units are opposed
  | Continuation   -- ^ same topic, no stronger relation identified
  | Elaboration    -- ^ the second unit says more about the first
  | Explanation    -- ^ the second unit says why the first holds
  | Background     -- ^ the second unit sets the scene for the first
  | Instance       -- ^ the second unit is a specific case of a general first
  deriving (Eq, Ord, Show, Enum, Bounded)

allRelations :: [Relation]
allRelations = [minBound .. maxBound]

-- | Coordinating relations close their left argument; subordinating ones leave it
-- open. This distinction is the entire mechanism by which relation choice affects
-- anaphora, so it is a property of the type rather than a convention.
data RelationKind = Coordinating | Subordinating
  deriving (Eq, Ord, Show)

relationKind :: Relation -> RelationKind
relationKind Narration    = Coordinating
relationKind Result       = Coordinating
relationKind Contrast     = Coordinating
relationKind Continuation = Coordinating
relationKind Elaboration  = Subordinating
relationKind Explanation  = Subordinating
relationKind Background   = Subordinating
relationKind Instance     = Subordinating

-- | What kind of evidence could settle this relation. Lower is cheaper.
--
-- * __1__ — decidable from surface cues alone: an explicit connective, a tense
--   shift. No inference needed.
-- * __2__ — needs the units' predicate content compared.
-- * __3__ — needs world knowledge. A structural layer should flag and stop.
relationLayer :: Relation -> Int
relationLayer Narration    = 1
relationLayer Contrast     = 1
relationLayer Continuation = 1
relationLayer Instance     = 2
relationLayer Elaboration  = 2
relationLayer Background   = 2
relationLayer Result       = 3
relationLayer Explanation  = 3

relationGloss :: Relation -> String
relationGloss r = show r ++ " (" ++ kindWord ++ ", layer " ++ show (relationLayer r) ++ ")"
  where
    kindWord = case relationKind r of
      Coordinating  -> "closes its left argument"
      Subordinating -> "leaves its left argument open"

--------------------------------------------------------------------------------
-- Discourse units and structures
--------------------------------------------------------------------------------

newtype Label = Label Int
  deriving (Eq, Ord)

instance Show Label where
  show (Label i) = "K" ++ show i

-- | One segment: its DRS, plus the surface tokens it came from.
--
-- Tokens are retained because layer-1 cues are surface facts (an explicit
-- connective) that the DRS has already discarded. Keeping them here means cue
-- detection needs no access to the parser.
data DiscourseUnit = DiscourseUnit
  { duLabel  :: Label
  , duDRS    :: DRS
  , duTokens :: [String]
  }

-- | Units plus labelled edges plus the most recently attached label.
--
-- @sdrsEdges@ holds @(relation, left, right)@ meaning @relation(left, right)@.
data SDRS = SDRS
  { sdrsUnits :: M.Map Label DiscourseUnit
  , sdrsEdges :: [(Relation, Label, Label)]
  , sdrsLast  :: Maybe Label
  }

emptySDRS :: SDRS
emptySDRS = SDRS M.empty [] Nothing

-- | Seed the structure with its first unit, which has nothing to attach to.
addRoot :: DiscourseUnit -> SDRS -> SDRS
addRoot u s =
  s { sdrsUnits = M.insert (duLabel u) u (sdrsUnits s)
    , sdrsLast = Just (duLabel u)
    }

-- | Attach a new unit to an existing one by a chosen relation.
--
-- Takes the relation as an argument rather than choosing it: selection is
-- 'glue''s job and is a logged decision, not something buried in a graph update.
attach :: Relation -> Label -> DiscourseUnit -> SDRS -> SDRS
attach rel parent u s =
  s { sdrsUnits = M.insert (duLabel u) u (sdrsUnits s)
    , sdrsEdges = sdrsEdges s ++ [(rel, parent, duLabel u)]
    , sdrsLast = Just (duLabel u)
    }

-- | Labels in source order. 'Label''s 'Ord' is on the sentence index, so the
-- map's own key order is source order and no separate sequence is needed.
labelsInOrder :: SDRS -> [Label]
labelsInOrder = M.keys . sdrsUnits

unitsInOrder :: SDRS -> [DiscourseUnit]
unitsInOrder = M.elems . sdrsUnits

--------------------------------------------------------------------------------
-- The right frontier
--------------------------------------------------------------------------------

-- | Labels still open for attachment.
--
-- The last unit, plus every ancestor reachable from it through
-- __subordinating__ edges. A coordinating edge closes its left argument, so that
-- parent is excluded — but the climb continues through it, since a coordinating
-- pair may itself sit under a subordinating parent that remains open.
--
-- That last detail is easy to get wrong by stopping at the first coordinating
-- edge, which would make deeply nested structures lose accessibility they should
-- keep.
rightFrontier :: SDRS -> [Label]
rightFrontier s = maybe [] (frontierFrom s) (sdrsLast s)

-- | The frontier as seen from an arbitrary label rather than from 'sdrsLast'.
--
-- 'rightFrontier' is this at the last node. Threading needs the general version
-- because it asks the question at a node that is not yet the last one: given that
-- a new unit would attach /here/, what stays open?
frontierFrom :: SDRS -> Label -> [Label]
frontierFrom s l = nub (l : climb [l] l)
  where
    parentsOf n = [(rel, p) | (rel, p, c) <- sdrsEdges s, c == n]

    climb seen n =
      concat
        [ case relationKind rel of
            Subordinating -> p : climb (p : seen) p
            Coordinating  ->     climb (p : seen) p
        | (rel, p) <- parentsOf n
        , p `notElem` seen
        ]

isOpen :: SDRS -> Label -> Bool
isOpen s l = l `elem` rightFrontier s

unitAt :: SDRS -> Label -> Maybe DiscourseUnit
unitAt s l = M.lookup l (sdrsUnits s)

-- | Referents a following sentence may resolve against.
--
-- Union of the top-level universes of the units on the right frontier. This is
-- the SDRT-aware replacement for calling
-- "NL2Proof.DRT.Types".'accessibleRefs' on a flat merge: same per-unit rule,
-- but restricted to open units.
sdrsAccessible :: SDRS -> [Ref]
sdrsAccessible s = accessibleOn s (rightFrontier s)

-- | Referents contributed by a given set of labels, __most recent first__.
--
-- Order matters here in a way it does not for 'sdrsAccessible' as a set: the
-- anaphora heuristic takes the head of this list, so the ordering /is/ the
-- heuristic. Frontier order is last-unit-first, and within a unit
-- 'accessibleRefs' is left-to-right, so each unit's universe is reversed.
accessibleOn :: SDRS -> [Label] -> [Ref]
accessibleOn s ls =
  nub
    [ r
    | l <- ls
    , Just u <- [unitAt s l]
    , r <- reverse (accessibleRefs (duDRS u))
    ]

--------------------------------------------------------------------------------
-- Glue logic
--------------------------------------------------------------------------------

-- | Evidence bearing on which relation holds.
data Cue
  = -- | An explicit discourse connective opening the second unit. Layer 1.
    --
    -- __Cannot fire on the current fragment.__ Connectives are not in the
    -- lexicon, so a sentence containing one fails to parse and produces no DRS.
    -- Implemented so the path exists, and so that lexicalizing connectives later
    -- is a lexicon change rather than an SDRT change.
    Connective String
  | -- | The first unit makes a general claim (a duplex condition) and the second
    -- predicates of a named individual. Layer 2.
    GenericThenSpecific
  | -- | Both units predicate the same symbol. Layer 2.
    SharedPredicate String
  | -- | The second unit introduces a fresh top-level referent. Layer 1.
    NewReferent
  deriving (Eq, Ord, Show)

renderCue :: Cue -> String
renderCue (Connective w)      = "connective " ++ show w
renderCue GenericThenSpecific = "generic-then-specific"
renderCue (SharedPredicate p) = "shared predicate " ++ show p
renderCue NewReferent         = "new referent introduced"

-- | Read cues off a pair of units.
detectCues :: DiscourseUnit -> DiscourseUnit -> [Cue]
detectCues a b =
  concat
    [ [Connective w | w <- take 1 (duTokens b), w `elem` knownConnectives]
    , [GenericThenSpecific | hasDuplex (duDRS a), hasNamedIndividual (duDRS b)]
    , [SharedPredicate p | p <- nub (drsPredicates (duDRS a))
                         , p `elem` drsPredicates (duDRS b)]
    , [NewReferent | not (null (accessibleRefs (duDRS b)))]
    ]
  where
    knownConnectives = ["then", "so", "but", "because", "meanwhile"]

    hasDuplex d = or [True | CImp _ _ _ <- drsConds d]
    hasNamedIndividual d = not (null (drsConstants d))

-- | How much a cue favours a relation. __Stipulated__, in the same sense as the
-- fingerprint weights: these numbers encode a guess and are the thing a corpus
-- would replace. The /structure/ they feed — kind, frontier, accessibility — is
-- not stipulated and is what the tests pin down.
cueWeight :: Cue -> Relation -> Double
cueWeight (Connective "then") Narration      = 8
cueWeight (Connective "so") Result           = 8
cueWeight (Connective "but") Contrast        = 8
cueWeight (Connective "because") Explanation  = 8
cueWeight (Connective "meanwhile") Background = 6
cueWeight (Connective _) _                    = 1
cueWeight GenericThenSpecific Instance        = 5
cueWeight GenericThenSpecific Elaboration     = 3
cueWeight GenericThenSpecific _               = 1
cueWeight (SharedPredicate _) Continuation    = 3
cueWeight (SharedPredicate _) Elaboration     = 2
cueWeight (SharedPredicate _) _               = 1
cueWeight NewReferent Narration               = 2
cueWeight NewReferent _                       = 1

-- | A distribution over __all__ relations, given the cues.
--
-- Every relation keeps positive mass. Nothing is pruned at this stage, per the
-- standing principle: a relation that is never proposed cannot be recorded as
-- rejected, and cannot be recovered when the cue weights turn out to be wrong.
--
-- Defeasibility lives here. Cues raise a relation's weight; they never establish
-- it, and a later segment can contradict the choice — which is what Stage 3's
-- rollback is for.
-- | The prior when no cue fires at all. 'Continuation' is the least committal
-- relation, so it takes the default.
--
-- __This is the most load-bearing number in the layer, and it is the one least
-- like a cue weight.__ Measured rather than assumed: see
-- @docs\/cue-weight-sensitivity.hs@.
--
-- Because 'glue' is multiplicative in the weights, the ratio between the best
-- relation of each kind /is/ the perturbation threshold for flipping the kind,
-- exactly. On an edge where some cue fires that ratio is @2.0@ to @4.16@ on the
-- fragment: comfortably robust to a twenty-percent wobble, which is what
-- \"stipulated\" is supposed to mean. On an edge where __no__ cue fires the
-- only asymmetry left is this prior, so the ratio is @1.2@ — and a
-- twenty-percent wobble flips 'relationKind', hence 'rightFrontier', hence which
-- referents a later pronoun can reach.
--
-- Most edges in the fragment are no-cue edges. So the honest reading is not
-- \"this number is a guess\" but: __on a no-cue edge there is no evidence, and
-- @1.2@ is not evidence either — it is a tie-break wearing a prior's clothes.__
-- That is an argument for 'NL2Proof.Stage2.Threading.Marginal' over
-- 'NL2Proof.Stage2.Threading.Committed' on such edges, not an argument for a
-- different number: marginalising reports the absence of evidence, while
-- committing manufactures a structural decision out of it.
noCuePrior :: Relation -> Double
noCuePrior Continuation = 1.2
noCuePrior _            = 1.0

glue :: DiscourseUnit -> DiscourseUnit -> Maybe (Dist Relation)
glue a b = fromWeights [(r, score r) | r <- allRelations]
  where
    cues = detectCues a b
    score r = product [cueWeight c r | c <- cues] * noCuePrior r

--------------------------------------------------------------------------------
-- Rendering
--------------------------------------------------------------------------------

renderSDRS :: SDRS -> String
renderSDRS s =
  unlines $
    [ "units:" ]
      ++ [ "  " ++ show l ++ openMark l ++ "  refs=" ++ show (accessibleRefs (duDRS u))
             ++ "  " ++ unwords (duTokens u)
         | (l, u) <- M.toList (sdrsUnits s)
         ]
      ++ [ "edges:" ]
      ++ [ "  " ++ show rel ++ "(" ++ show p ++ ", " ++ show c ++ ")  "
             ++ show (relationKind rel)
         | (rel, p, c) <- sdrsEdges s
         ]
      ++ [ "right frontier: " ++ intercalate ", " (map show (rightFrontier s))
         , "accessible:     " ++ show (sdrsAccessible s)
         ]
  where
    openMark l = if isOpen s l then " [open]" else " [closed]"
