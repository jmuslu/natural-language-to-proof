-- | The derivation DAG: addressable claims, justifications, grounded support,
-- and precise retraction.
--
-- == Why this is a different object from 'Prov'
--
-- "NL2Proof.Provenance" is a __tree__, the initial algebra of a functor, and
-- every question you can ask of it is a fold. Two things are therefore not
-- expressible in it, and both are now load-bearing rather than theoretical:
--
-- 1. __Cross-derivation convergence.__ "Is there a path from A to B" is a
--    reachability question. A fold over a tree cannot answer it, and two
--    independent derivations of one claim are two separate trees with no
--    structure relating them.
-- 2. __Retraction.__ When an oracle reverses its own earlier answer, the system
--    has to find every claim that depended on that answer and withdraw
--    /precisely those/. A tree has no node identity to address and no edges to
--    follow backwards.
--
-- So this is a graph with named nodes, not a richer tree — and it is
-- load-bearing rather than a refinement, because retraction is not optional
-- once an external oracle can change its mind.
--
-- == Support is a least fixed point, and that is the anti-self-agreement property
--
-- A node is __grounded__ when it has at least one justification whose
-- antecedents are all grounded, bottoming out in premises the oracle confirmed.
-- 'grounded' computes the __least__ fixed point of that rule.
--
-- Taking the least rather than the greatest fixed point is the whole point, and
-- it is worth being explicit about why:
--
-- > A claim cannot ground itself, directly or around a cycle.
--
-- If @A@ justifies @B@ and @B@ justifies @A@ with no confirmed premise beneath
-- either, the greatest fixed point contains both — they are mutually consistent
-- — and the least fixed point contains neither. Mutual consistency is exactly
-- the self-agreement that must not be mistaken for truth, so the least fixed
-- point is the formal statement of the constraint the whole pipeline is built
-- around. It is asserted as a check, not left as a remark.
--
-- == Precise retraction is a difference of fixed points
--
-- 'retract' flips a premise's verdict, recomputes 'grounded', and returns the
-- set difference. That is what makes it precise. The naive answer — everything
-- transitively downstream, which 'dependents' computes — over-retracts, because
-- a claim with a second independent derivation keeps its support. The gap
-- between the two is measurable, and 'retractionReport' measures it.
module NL2Proof.Genealogy
  ( -- * Nodes
    NodeId(..)
  , Node(..)
    -- * Justifications
  , Justification(..)
  , premise
  , derivation
    -- * The graph
  , Genealogy(..)
  , emptyGenealogy
  , addNode
  , addJustification
  , nodeAt
  , nodeIds
  , verdictOf
  , setVerdict
    -- * Support
  , grounded
  , isGrounded
  , justificationsFor
  , supportingJustifications
    -- * Reachability
  , antecedentsOf
  , dependents
  , premisesUnder
    -- * Convergence
  , independentSupports
  , hasIndependentSupport
  , convergentNodes
  , corroboratedNodes
    -- * Retraction
  , retract
  , RetractionReport(..)
  , retractionReport
  , survivesRetractionOf
    -- * Rendering
  , renderGenealogy
  , renderRetractionReport
  ) where

import Data.List (nub, sort)
import qualified Data.Map.Strict as M
import qualified Data.Set as S

import NL2Proof.DRT.Canonical
import NL2Proof.Provenance
import NL2Proof.Verify.Oracle

--------------------------------------------------------------------------------
-- Nodes
--------------------------------------------------------------------------------

-- | Addressable identity, which is the property 'Prov' lacks.
--
-- Structural identity is not enough: two claims can be structurally identical
-- and still need to be separate nodes, because they were derived differently and
-- one of those derivations may later be withdrawn.
newtype NodeId = NodeId Int
  deriving (Eq, Ord)

instance Show NodeId where
  show (NodeId i) = "n" ++ show i

-- | One claim in the graph.
--
-- 'nodeProv' keeps the Stage 1 derivation tree. The tree is still the right
-- object for "which words produced this" — it is only the wrong object for
-- reachability and retraction, which is what the surrounding graph supplies. The
-- two coexist rather than one replacing the other.
data Node = Node
  { nodeId    :: NodeId
  , nodeClaim :: CanonCond
  , nodeProv  :: Prov
  }
  deriving (Eq, Show)

--------------------------------------------------------------------------------
-- Justifications
--------------------------------------------------------------------------------

-- | @jRule@ applied to @jAntecedents@ yields @jTarget@.
--
-- A node may have several justifications; that is the representation of
-- independent derivations, and it is why a list rather than a single parent
-- pointer. An empty antecedent list marks a __premise__ — a claim offered
-- directly to the oracle rather than derived from other claims.
data Justification = Justification
  { jTarget      :: NodeId
  , jRule        :: String
  , jAntecedents :: [NodeId]
  }
  deriving (Eq, Show)

premise :: NodeId -> String -> Justification
premise t rule = Justification t rule []

derivation :: NodeId -> String -> [NodeId] -> Justification
derivation = Justification

--------------------------------------------------------------------------------
-- The graph
--------------------------------------------------------------------------------

data Genealogy = Genealogy
  { gNodes    :: M.Map NodeId Node
  , gJusts    :: [Justification]
  , gVerdicts :: M.Map NodeId Verdict
    -- ^ Oracle verdicts. Only consulted for premises; a derived node's status
    -- comes from its antecedents, never from a verdict recorded against it.
  }

emptyGenealogy :: Genealogy
emptyGenealogy = Genealogy M.empty [] M.empty

addNode :: Node -> Verdict -> Genealogy -> Genealogy
addNode n v g =
  g { gNodes = M.insert (nodeId n) n (gNodes g)
    , gVerdicts = M.insert (nodeId n) v (gVerdicts g)
    }

addJustification :: Justification -> Genealogy -> Genealogy
addJustification j g = g { gJusts = gJusts g ++ [j] }

nodeAt :: Genealogy -> NodeId -> Maybe Node
nodeAt g i = M.lookup i (gNodes g)

nodeIds :: Genealogy -> [NodeId]
nodeIds = M.keys . gNodes

-- | Recorded verdict, defaulting to 'Unknown'. A node with no oracle answer is
-- uncovered, which is not the same as refuted — see
-- "NL2Proof.Verify.Oracle".
verdictOf :: Genealogy -> NodeId -> Verdict
verdictOf g i = M.findWithDefault Unknown i (gVerdicts g)

setVerdict :: NodeId -> Verdict -> Genealogy -> Genealogy
setVerdict i v g = g { gVerdicts = M.insert i v (gVerdicts g) }

--------------------------------------------------------------------------------
-- Support
--------------------------------------------------------------------------------

-- | The least set of nodes with grounded support.
--
-- Iterated to a fixed point from the empty set. The rule is monotone in the
-- accumulator, so the iteration converges and converges to the /least/ fixed
-- point — which is what excludes circular support. See the module header.
grounded :: Genealogy -> S.Set NodeId
grounded g = go S.empty
  where
    ids = nodeIds g

    go acc =
      let acc' = S.union acc (S.fromList [i | i <- ids, supported acc i])
      in if S.size acc' == S.size acc then acc else go acc'

    supported acc i = any (ok acc) (justificationsFor g i)

    ok acc j
      | null (jAntecedents j) = isConfirmed (verdictOf g (jTarget j))
      | otherwise             = all (`S.member` acc) (jAntecedents j)

isGrounded :: Genealogy -> NodeId -> Bool
isGrounded g i = i `S.member` grounded g

justificationsFor :: Genealogy -> NodeId -> [Justification]
justificationsFor g i = [j | j <- gJusts g, jTarget j == i]

-- | The justifications that are actually carrying a node, i.e. those whose
-- antecedents are all grounded (or which are confirmed premises).
--
-- Distinct from 'justificationsFor': a node can have five justifications and be
-- held up by one of them. Retraction cares about which.
supportingJustifications :: Genealogy -> NodeId -> [Justification]
supportingJustifications g i =
  [ j
  | j <- justificationsFor g i
  , if null (jAntecedents j)
      then isConfirmed (verdictOf g i)
      else all (`S.member` gr) (jAntecedents j)
  ]
  where
    gr = grounded g

--------------------------------------------------------------------------------
-- Reachability
--------------------------------------------------------------------------------

-- | Transitive antecedents: everything this node's derivations rest on.
antecedentsOf :: Genealogy -> NodeId -> [NodeId]
antecedentsOf g = S.toList . close S.empty . (: [])
  where
    close seen [] = seen
    close seen (i : rest)
      | i `S.member` seen = close seen rest
      | otherwise =
          let ups = concatMap jAntecedents (justificationsFor g i)
          in close (S.insert i seen) (ups ++ rest)

-- | Transitive consequents: everything that mentions this node as an antecedent,
-- at any depth.
--
-- __This is the over-retraction answer.__ Kept precisely so the difference
-- against 'retract' can be measured rather than argued about.
dependents :: Genealogy -> NodeId -> [NodeId]
dependents g i0 = S.toList (S.delete i0 (close S.empty [i0]))
  where
    close seen [] = seen
    close seen (i : rest)
      | i `S.member` seen = close seen rest
      | otherwise =
          let downs = [jTarget j | j <- gJusts g, i `elem` jAntecedents j]
          in close (S.insert i seen) (downs ++ rest)

-- | Premises in a node's ancestry: the nodes whose oracle verdicts it ultimately
-- rests on.
premisesUnder :: Genealogy -> NodeId -> [NodeId]
premisesUnder g i =
  [ a
  | a <- antecedentsOf g i
  , any (null . jAntecedents) (justificationsFor g a)
  ]

--------------------------------------------------------------------------------
-- Convergence
--------------------------------------------------------------------------------

-- | For each justification of a node, the set of premises it rests on.
--
-- Two justifications are __independent__ when these sets are disjoint: they draw
-- on no common oracle answer, so no single reversal can take both down.
independentSupports :: Genealogy -> NodeId -> [[NodeId]]
independentSupports g i =
  [ sort (nub (concatMap (premisesUnder g) (jAntecedents j)))
  | j <- justificationsFor g i
  , not (null (jAntecedents j))
  ]

-- | Does some pair of this node's justifications rest on disjoint premise sets?
--
-- __Vacuously 'False' on a premise-only graph__, because 'independentSupports'
-- skips justifications with no antecedents. Every graph
-- 'NL2Proof.Verify.Claims.genealogyOf' currently builds is premise-only, so this
-- measures /derivation-level/ independence and is not the corroboration signal
-- for the present pipeline. 'corroboratedNodes' is.
hasIndependentSupport :: Genealogy -> NodeId -> Bool
hasIndependentSupport g i =
  or
    [ S.null (S.intersection a b)
    | (a, k) <- zip sups [0 :: Int ..]
    , (b, l) <- zip sups [0 ..]
    , k < l
    , not (S.null a)
    , not (S.null b)
    ]
  where
    sups = map S.fromList (independentSupports g i)

-- | Nodes whose claim is asserted by more than one node.
--
-- This is the cross-derivation convergence signal, and it matters beyond
-- bookkeeping: the standing limitation "provable does not mean faithful" says a
-- single statement's provability is an unsafe reward, because the policy can
-- drift toward easily-provable statements. Independent extraction paths arriving
-- at the same claim is a signal that /is/ safe to use, and this is where it
-- becomes visible.
convergentNodes :: Genealogy -> [(CanonCond, [NodeId])]
convergentNodes g =
  [ (claim, map nodeId group) | (claim, group) <- claimGroups g, length group > 1 ]

-- | Claims asserted by more than one node __via derivations that differ__.
--
-- This is the corroboration signal, and the distinctness requirement is what
-- makes it one rather than a repetition counter. 'convergentNodes' groups by
-- claim identity alone, which is the right question for fusion — those are
-- precisely the nodes it will merge — and the wrong question for reward: the
-- same claim reached by the same derivation twice is a duplicate, and a signal
-- that paid for it would pay a policy for repeating itself. Two derivations that
-- differ are evidence the extraction does not rest on a single fragile path.
--
-- What this does __not__ establish is independence of the /oracle answers/. An
-- oracle is a function of the claim, so two nodes carrying the same claim receive
-- the same verdict and one reversal takes both down. The signal is about the
-- extraction, not a second opinion on the truth, and it is admissible for exactly
-- that reason: it is a fact about how the claim was reached from the input, not
-- something the system establishes about the claim itself.
corroboratedNodes :: Genealogy -> [(CanonCond, [NodeId])]
corroboratedNodes g =
  [ (claim, map nodeId group)
  | (claim, group) <- claimGroups g
  , length (nub (map nodeProv group)) > 1
  ]

claimGroups :: Genealogy -> [(CanonCond, [Node])]
claimGroups g =
  [ (claim, [n | n <- ns, nodeClaim n == claim])
  | claim <- nub (map nodeClaim ns)
  ]
  where
    ns = M.elems (gNodes g)

--------------------------------------------------------------------------------
-- Retraction
--------------------------------------------------------------------------------

-- | Reverse a premise's verdict and report exactly which nodes lost support.
--
-- The returned list is the difference of the grounded sets before and after. It
-- is /precisely/ the nodes that lost all grounded support — not everything
-- downstream. A claim with a second, independent derivation appears in
-- 'dependents' and not here, which is the entire reason this module exists.
retract :: NodeId -> Genealogy -> (Genealogy, [NodeId])
retract i g = (g', S.toList (before `S.difference` after))
  where
    before = grounded g
    g' = setVerdict i Refuted g
    after = grounded g'

data RetractionReport = RetractionReport
  { rrTarget    :: NodeId
  , rrGroundedBefore :: Int
  , rrGroundedAfter  :: Int
  , rrLost      :: [NodeId]
    -- ^ Precise: lost all grounded support.
  , rrDownstream :: [NodeId]
    -- ^ Coarse: transitively depends on the target, whether or not it survived.
  , rrSurvived  :: [NodeId]
    -- ^ Downstream but still grounded — the ones an over-eager retraction would
    -- have destroyed.
  }

retractionReport :: NodeId -> Genealogy -> RetractionReport
retractionReport i g =
  RetractionReport
    { rrTarget = i
    , rrGroundedBefore = S.size (grounded g)
    , rrGroundedAfter = S.size (grounded g')
    , rrLost = lost
    , rrDownstream = down
    , rrSurvived = [d | d <- down, d `notElem` lost]
    }
  where
    (g', lost) = retract i g
    down = dependents g i

survivesRetractionOf :: NodeId -> NodeId -> Genealogy -> Bool
survivesRetractionOf target subject g = subject `notElem` snd (retract target g)

--------------------------------------------------------------------------------
-- Rendering
--------------------------------------------------------------------------------

renderGenealogy :: Genealogy -> String
renderGenealogy g =
  unlines $
    ["nodes:"]
      ++ [ "  " ++ show (nodeId n) ++ mark (nodeId n)
             ++ "  " ++ renderCanonCond (nodeClaim n)
             ++ "  [" ++ renderVerdict (verdictOf g (nodeId n)) ++ "]"
         | n <- M.elems (gNodes g)
         ]
      ++ ["justifications:"]
      ++ [ "  " ++ show (jTarget j) ++ " <- " ++ jRule j
             ++ (if null (jAntecedents j)
                   then " (premise)"
                   else " " ++ show (jAntecedents j))
         | j <- gJusts g
         ]
      ++ [ "grounded: " ++ show (S.toList (grounded g)) ]
  where
    gr = grounded g
    mark i = if i `S.member` gr then " [grounded]" else " [unsupported]"

renderRetractionReport :: RetractionReport -> String
renderRetractionReport r =
  unlines
    [ "retracting " ++ show (rrTarget r)
    , "  grounded: " ++ show (rrGroundedBefore r) ++ " -> " ++ show (rrGroundedAfter r)
    , "  lost (precise):      " ++ show (rrLost r)
    , "  downstream (coarse): " ++ show (rrDownstream r)
    , "  survived downstream: " ++ show (rrSurvived r)
        ++ "  <- what the coarse answer would have destroyed"
    ]
