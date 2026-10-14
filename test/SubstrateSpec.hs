-- | Substrate test suite: verification, genealogy, fusion, reward.
--
-- Kept separate from the language suites because these checks assert __design
-- constraints__ rather than linguistic behaviour. The constraint that motivated
-- the whole refactor is:
--
-- > A system cannot use its own internal consistency checks as the reward signal
-- > for the step that produces the claims in the first place.
--
-- That is a sentence in a document until something executes it. Sections 4 and 5
-- here execute it: a set of mutually-supporting, perfectly well-formed claims
-- with no oracle beneath them scores exactly zero, and adding more of them never
-- moves the number.
--
-- The load-bearing checks are 'cycleChecks' (a claim cannot ground itself, which
-- is what makes 'grounded' a least fixed point rather than a greatest one) and
-- 'selfAgreementChecks' (the reward is unmoved by internal coherence).
module Main (main) where

import Data.List (sort)

import Harness
import NL2Proof.Collapse.Class
import NL2Proof.DRT.Canonical
import NL2Proof.DRT.Types
import NL2Proof.Fragment
import NL2Proof.Fusion
import NL2Proof.Genealogy
import NL2Proof.Pipeline
import NL2Proof.Provenance
import NL2Proof.Reward
import NL2Proof.Verify.Claims
import NL2Proof.Verify.ClaimKind (assertedClaims)
import NL2Proof.Verify.Oracle

--------------------------------------------------------------------------------
-- Fixtures
--------------------------------------------------------------------------------

pv :: Prov
pv = ProvLex (SourceId "substrate") (Span 0 1) "w"

-- These test-only fixtures explicitly author a whole DRS. They do not recover
-- assertion witnesses from a pipeline's bare/embedded contents. The production
-- API always retains the witnesses produced at structural extraction.
fixtureDRS :: [CanonCond] -> DRS
fixtureDRS = fromBox . Canonical []
  where
    fromRef (CRef i) = Ref ("fixture" ++ show i)
    fromTerm (CRefT r) = DRef (fromRef r)
    fromTerm (CConstT n) = DConst n
    fromBox (Canonical us cs) = DRS [(fromRef r, pv) | r <- us] (map fromCond cs)
    fromCond c = case c of
      CanPred p ts -> CPred p (map fromTerm ts) pv
      CanEq a b -> CEq (fromTerm a) (fromTerm b) pv
      CanNot d -> CNot (fromBox d) pv
      CanImp a b -> CImp (fromBox a) (fromBox b) pv
      CanOr a b -> COr (fromBox a) (fromBox b) pv
      CanAtt v ts d -> CAtt v (map fromTerm ts) (fromBox d) pv
      CanPresup d -> CPresup (fromBox d) pv

confirmFixtures :: Oracle -> [CanonCond] -> [Confirmed]
confirmFixtures o = confirmAll o . map fst . assertedClaims . fixtureDRS

confirmFixture :: Oracle -> CanonCond -> Maybe Confirmed
confirmFixture o c = case assertedClaims (fixtureDRS [c]) of
  [(a, _)] -> confirm o a
  _ -> Nothing

-- | A unary claim about a named individual.
cl :: String -> CanonCond
cl n = CanPred n [CConstT "a"]

box :: [CanonCond] -> Canonical
box = Canonical []

-- | A material implication: antecedent box binds nothing.
impl :: CanonCond -> CanonCond -> CanonCond
impl a b = CanImp (box [a]) (box [b])

-- | A universal: the antecedent box binds a referent. Shaped like an
-- implication and emphatically not one.
univ :: CanonCond -> CanonCond
univ b = CanImp (Canonical [CRef 0] [CanPred "student" [CRefT (CRef 0)]]) (box [b])

yesOracle, noOracle, blindOracle :: Oracle
yesOracle = Oracle "yes" "everything" (const True) (const True)
noOracle = Oracle "no" "everything" (const True) (const False)
blindOracle = Oracle "blind" "nothing at all" (const False) (const True)

-- | Covers unary predicates only, and confirms a fixed whitelist. Stands in for
-- a real external procedure; it is plumbing, not physics.
unaryOracle :: Oracle
unaryOracle =
  Oracle
    { oracleName = "unary"
    , oracleDomain = "unary predicates drawn from a fixed whitelist"
    , oracleCovers = \c -> case c of
        CanPred _ [_] -> True
        _             -> False
    , oracleHolds = \c -> case c of
        CanPred n _ -> n `elem` ["student", "book", "arrive", "smile"]
        _           -> False
    }

node :: Int -> CanonCond -> Node
node i c = Node (NodeId i) c pv

-- | Lexical provenance over a chosen span, so that two nodes can carry
-- genuinely different derivations rather than the shared 'pv'.
pvAt :: Int -> Int -> Prov
pvAt a b = ProvLex (SourceId "substrate") (Span a b) (replicate (b - a) 'w')

nodeP :: Int -> CanonCond -> Prov -> Node
nodeP i c = Node (NodeId i) c

-- | @n0@ and @n1@ are confirmed premises. @n2@ has two independent derivations,
-- one from each. @n3@ rests on @n0@ alone.
--
-- This is the shape the whole retraction story turns on, so it is built once.
twoSupport :: Genealogy
twoSupport =
  addJustification (derivation (NodeId 3) "d3" [NodeId 0])
    . addJustification (derivation (NodeId 2) "d2b" [NodeId 1])
    . addJustification (derivation (NodeId 2) "d2a" [NodeId 0])
    . addJustification (premise (NodeId 1) "oracle")
    . addJustification (premise (NodeId 0) "oracle")
    . addNode (node 3 (cl "y")) Unknown
    . addNode (node 2 (cl "x")) Unknown
    . addNode (node 1 (cl "q")) Confirmed
    . addNode (node 0 (cl "p")) Confirmed
    $ emptyGenealogy

--------------------------------------------------------------------------------
-- 1. Oracles and the scope boundary
--------------------------------------------------------------------------------

oracleChecks :: [Check]
oracleChecks =
  [ expectEq "oracle: covered and holding is Confirmed"
      Confirmed (check unaryOracle (cl "student"))
  , expectEq "oracle: covered and failing is Refuted"
      Refuted (check unaryOracle (cl "dragon"))
  , expectEq "oracle: uncovered is Unknown, not Refuted"
      Unknown (check unaryOracle (impl (cl "student") (cl "book")))
  , expect "oracle: Unknown and Refuted are distinct verdicts"
      (Unknown /= Refuted)
  , -- The distinction is the scope boundary: collapsing them would manufacture
    -- truth-grounding for domains that have none.
    expect "oracle: an oracle covering nothing returns Unknown for everything"
      (all ((== Unknown) . check blindOracle) [cl "student", cl "dragon"])

  , -- The gate. 'Confirmed' has no exported constructor, so this is really a
    -- compile-time property; what is checkable at runtime is that no token ever
    -- escapes for a non-confirming verdict.
    expect "oracle: confirm yields a token exactly when the verdict confirms"
      (all (\c -> (confirmFixture unaryOracle c /= Nothing) == (check unaryOracle c == Confirmed))
           [cl "student", cl "dragon", impl (cl "student") (cl "book")])
  , expectEq "oracle: refuted claims yield no token" Nothing
      (confirmFixture noOracle (cl "student"))
  , expectEq "oracle: uncovered claims yield no token either" Nothing
      (confirmFixture blindOracle (cl "student"))
  , expect "oracle: every token names the oracle that issued it"
      (all ((== "unary") . confOracle) (confirmFixtures unaryOracle [cl "student", cl "book"]))
  , expectEq "oracle: confirmAll keeps only the confirmed" [cl "book", cl "student"]
      (sort (map confClaim (confirmFixtures unaryOracle [cl "student", cl "dragon", cl "book"])))

  , -- Coverage reporting: the uncovered count is the ungroundable remainder.
    expectEq "oracle: coverage partitions the claim set" (2, 1, 1)
      (let c = coverage unaryOracle
                 [cl "student", cl "dragon", cl "book", impl (cl "a") (cl "b")]
       in ( length (covConfirmed c)
          , length (covRefuted c)
          , length (covUncovered c) ))
  , expect "oracle: coverage dedupes its input"
      (let c = coverage unaryOracle [cl "student", cl "student"]
       in length (covConfirmed c) == 1)
  ]

--------------------------------------------------------------------------------
-- 2. Genealogy: grounded support
--------------------------------------------------------------------------------

supportChecks :: [Check]
supportChecks =
  [ expect "genealogy: a confirmed premise is grounded"
      (isGrounded twoSupport (NodeId 0))
  , expect "genealogy: a derived node with a grounded antecedent is grounded"
      (isGrounded twoSupport (NodeId 3))
  , expectEq "genealogy: all four nodes are grounded here" 4
      (length (nodeIds twoSupport))

  , -- A refuted premise grounds nothing.
    expect "genealogy: a refuted premise is not grounded"
      (not (isGrounded (setVerdict (NodeId 0) Refuted onePremise) (NodeId 0)))
  , -- And neither does an UNCOVERED one. This is the scope boundary reaching
    -- the graph: no coverage is not the same as true.
    expect "genealogy: an uncovered premise is not grounded"
      (not (isGrounded (setVerdict (NodeId 0) Unknown onePremise) (NodeId 0)))
  , expect "genealogy: a node with no justification at all is not grounded"
      (not (isGrounded (addNode (node 9 (cl "z")) Confirmed onePremise) (NodeId 9)))

  , expect "genealogy: supportingJustifications is a subset of justificationsFor"
      (length (supportingJustifications twoSupport (NodeId 2))
         <= length (justificationsFor twoSupport (NodeId 2)))
  , expectEq "genealogy: both derivations of n2 are carrying it" 2
      (length (supportingJustifications twoSupport (NodeId 2)))
  , expectEq "genealogy: only one carries n2 once n0 is refuted" 1
      (length (supportingJustifications
                 (setVerdict (NodeId 0) Refuted twoSupport) (NodeId 2)))

  , expectEq "genealogy: premisesUnder finds the oracle floor" [NodeId 0]
      (premisesUnder twoSupport (NodeId 3))
  , expectEq "genealogy: antecedentsOf includes the node itself"
      True (NodeId 3 `elem` antecedentsOf twoSupport (NodeId 3))
  ]
  where
    onePremise =
      addJustification (premise (NodeId 0) "oracle")
        (addNode (node 0 (cl "p")) Confirmed emptyGenealogy)

--------------------------------------------------------------------------------
-- 3. Genealogy: a claim cannot ground itself
--------------------------------------------------------------------------------

-- | The formal content of the design's central constraint.
--
-- 'grounded' is the __least__ fixed point of "has a justification whose
-- antecedents are all grounded". Circular support satisfies the /greatest/ fixed
-- point and not the least, so a ring of mutually-justifying claims is
-- unsupported no matter how internally coherent it is. Mutual consistency is
-- exactly the self-agreement that must not be mistaken for truth.
cycleChecks :: [Check]
cycleChecks =
  [ expect "cycle: two mutually justifying claims are both unsupported"
      (not (isGrounded ring (NodeId 0)) && not (isGrounded ring (NodeId 1)))
  , expectEq "cycle: nothing in a bare ring is grounded" 0
      (length (nodeIds ring) - length [i | i <- nodeIds ring, not (isGrounded ring i)])
  , expect "cycle: a three-node ring is unsupported too"
      (all (not . isGrounded ring3) (nodeIds ring3))
  , expect "cycle: adding more ring nodes never grounds any of them"
      (all (not . isGrounded ring3) (nodeIds ring3)
         && all (not . isGrounded ring) (nodeIds ring))

  , -- But a cycle does not poison legitimate support: with a confirmed premise
    -- underneath, the ring becomes grounded through it.
    expect "cycle: a ring with a confirmed premise beneath it is grounded"
      (all (isGrounded grounded3) (nodeIds grounded3))
  , expect "cycle: and retracting that premise ungrounds the whole ring"
      (let (_, lost) = retract (NodeId 2) grounded3
       in length lost == 3)
  ]
  where
    -- n0 <- n1, n1 <- n0. No premise.
    ring =
      addJustification (derivation (NodeId 1) "b" [NodeId 0])
        . addJustification (derivation (NodeId 0) "a" [NodeId 1])
        . addNode (node 1 (cl "q")) Unknown
        . addNode (node 0 (cl "p")) Unknown
        $ emptyGenealogy

    ring3 =
      addJustification (derivation (NodeId 0) "c" [NodeId 2])
        . addJustification (derivation (NodeId 2) "b" [NodeId 1])
        . addJustification (derivation (NodeId 1) "a" [NodeId 0])
        . addNode (node 2 (cl "r")) Unknown
        . addNode (node 1 (cl "q")) Unknown
        . addNode (node 0 (cl "p")) Unknown
        $ emptyGenealogy

    -- The same ring, plus a confirmed premise n2 that also justifies n0.
    grounded3 =
      addJustification (derivation (NodeId 0) "from-premise" [NodeId 2])
        . addJustification (premise (NodeId 2) "oracle")
        . addJustification (derivation (NodeId 1) "b" [NodeId 0])
        . addJustification (derivation (NodeId 0) "a" [NodeId 1])
        . addNode (node 2 (cl "r")) Confirmed
        . addNode (node 1 (cl "q")) Unknown
        . addNode (node 0 (cl "p")) Unknown
        $ emptyGenealogy

--------------------------------------------------------------------------------
-- 4. Genealogy: precise retraction
--------------------------------------------------------------------------------

-- | The reason this module exists. When an oracle reverses an answer, the system
-- must withdraw /precisely/ the claims that lose support — not everything
-- downstream, which is what a reachability query returns.
retractionChecks :: [Check]
retractionChecks =
  [ expectEq "retract: n0 and n3 lose support" [NodeId 0, NodeId 3]
      (sort (snd (retract (NodeId 0) twoSupport)))
  , expect "retract: n2 survives, because n1 still supports it"
      (survivesRetractionOf (NodeId 0) (NodeId 2) twoSupport)
  , expectEq "retract: the coarse answer names both dependents"
      [NodeId 2, NodeId 3] (sort (dependents twoSupport (NodeId 0)))
  , expect "retract: so the coarse answer over-retracts by exactly n2"
      (rrSurvived (retractionReport (NodeId 0) twoSupport) == [NodeId 2])
  , expectEq "retract: grounded count drops by the number lost" (4, 2)
      (let r = retractionReport (NodeId 0) twoSupport
       in (rrGroundedBefore r, rrGroundedAfter r))

  , -- Symmetry: retracting the other premise takes only itself, since n3 never
    -- depended on it and n2 keeps its first derivation.
    expectEq "retract: retracting n1 costs only n1" [NodeId 1]
      (sort (snd (retract (NodeId 1) twoSupport)))
  , -- Both premises gone and n2 falls too: nothing is left standing.
    expectEq "retract: retracting both premises ungrounds everything" 0
      (let (g2, _) = retract (NodeId 1) (setVerdict (NodeId 0) Refuted twoSupport)
       in length [i | i <- nodeIds g2, isGrounded g2 i])
  , expectEq "retract: n2 goes only when its second support goes too" [NodeId 1, NodeId 2]
      (sort (snd (retract (NodeId 1) (setVerdict (NodeId 0) Refuted twoSupport))))

  , expect "retract: retracting an already-refuted premise loses nothing new"
      (null (snd (retract (NodeId 0) (setVerdict (NodeId 0) Refuted twoSupport))))
  , -- Purity makes "does not mutate the input" true by construction, so that
    -- is not what this pins. What it pins is that the /new/ graph is the one
    -- that carries the retraction: a caller holding the pre-retraction value
    -- still gets the pre-retraction answer, which is why 'retract' has to
    -- return it rather than only the list of losses.
    expect "retract: the two graphs disagree about n0, and only the new one is right"
      (let (g', lost) = retract (NodeId 0) twoSupport
       in isGrounded twoSupport (NodeId 0)
            && not (isGrounded g' (NodeId 0))
            && NodeId 0 `elem` lost)

  , -- Convergence, which is what makes the survival above possible.
    expect "retract: n2 has independent support"
      (hasIndependentSupport twoSupport (NodeId 2))
  , expect "retract: n3 does not"
      (not (hasIndependentSupport twoSupport (NodeId 3)))
  , expectEq "retract: n2's two derivations rest on disjoint premises"
      [[NodeId 0], [NodeId 1]]
      (sort (independentSupports twoSupport (NodeId 2)))
  , expectEq "retract: convergent claims are found by claim, across nodes" 1
      (length (convergentNodes converged))
  ]
  where
    -- Two nodes asserting the same claim: what fusion would merge, and what must
    -- stay separate until it does.
    converged =
      addJustification (premise (NodeId 1) "oracle")
        . addJustification (premise (NodeId 0) "oracle")
        . addNode (node 1 (cl "p")) Confirmed
        . addNode (node 0 (cl "p")) Confirmed
        $ emptyGenealogy

--------------------------------------------------------------------------------
-- 5. Fusion: safe only because verification already happened
--------------------------------------------------------------------------------

fusionChecks :: [Check]
fusionChecks =
  [ expectEq "fusion: redundant confirmations are deduped" 1
      (length (fusedClaims (fuse (confirmFixtures yesOracle [cl "p", cl "p", cl "p"]))))
  , expectEq "fusion: and the loss is measured" 2
      (fusedDropped (fuse (confirmFixtures yesOracle [cl "p", cl "p", cl "p"])))
  , expectEq "fusion: distinct claims are kept" 2
      (length (fusedClaims (fuse (confirmFixtures yesOracle [cl "p", cl "q"]))))
  , expect "fusion: the contributing oracles are named"
      (fusedOracles (fuse (confirmFixtures yesOracle [cl "p"])) == ["yes"])
  , expect "fusion: nothing refuted can reach this stage"
      (null (fusedClaims (fuse (confirmFixtures noOracle [cl "p", cl "q"]))))
  , expect "fusion: nor anything uncovered"
      (null (fusedClaims (fuse (confirmFixtures blindOracle [cl "p"]))))

  , -- Box-level compression, with its honest limitation asserted so it stays
    -- visible.
    expectEq "fusion: compress dedupes at depth" 1
      (let inner = box [cl "p", cl "p"]
           (kept, _) = compress (Canonical [] [CanNot inner])
       in case canonConds kept of
            [CanNot c] -> length (canonConds c)
            _          -> 0)
  , expect "fusion: compress reports what it removed"
      (snd (compress (Canonical [] [cl "p", cl "p"])) > 0)
  , expect "fusion: compressionRatio is 1.0 when nothing is dropped"
      (compressionRatio (Canonical [] [cl "p", cl "q"]) == 1.0)
  , -- The documented gap: syntactic equality is strictly finer than logical
    -- equivalence, and no amount of work on 'compress' closes it.
    expect "fusion: ~(p|q) and ~p & ~q are logically equivalent and do NOT merge"
      (let negOr = CanNot (box [CanOr (box [cl "p"]) (box [cl "q"])])
           deMorgan = [CanNot (box [cl "p"]), CanNot (box [cl "q"])]
           a = fusedClaims (fuse (confirmFixtures yesOracle [negOr]))
           b = fusedClaims (fuse (confirmFixtures yesOracle deMorgan))
       in a /= b)

  , -- Mechanical entailment, with its soundness side condition.
    expectEq "fusion: modus ponens detaches from a material implication"
      [cl "q"] (detachable [cl "p", impl (cl "p") (cl "q")] (impl (cl "p") (cl "q")))
  , expect "fusion: and does NOT detach from a universal"
      (null (detachable [CanPred "student" [CRefT (CRef 0)], univ (cl "q")]
                        (univ (cl "q"))))
  , expect "fusion: because a bound antecedent box is a quantifier, not an arrow"
      (case univ (cl "q") of
         CanImp a _ -> not (null (canonUniverse a))
         _          -> False)
  , expect "fusion: entailedFrom closes over chained implications"
      (let f = fuse (confirmFixtures yesOracle
                       [cl "p", impl (cl "p") (cl "q"), impl (cl "q") (cl "r")])
       in cl "r" `elem` entailedFrom f)
  , expect "fusion: entailedFrom adds nothing without a detachable premise"
      (let f = fuse (confirmFixtures yesOracle [impl (cl "p") (cl "q")])
       in entailedFrom f == fusedClaims f)
  ]

--------------------------------------------------------------------------------
-- 6. Reward: internal coherence is worth exactly nothing
--------------------------------------------------------------------------------

-- | The constraint, executed.
--
-- Every genealogy here is internally impeccable — well-formed claims, coherent
-- justifications, no contradictions. None of them has an oracle beneath it, and
-- all of them score zero. Growing them does not help.
selfAgreementChecks :: [Check]
selfAgreementChecks =
  [ expectEq "reward: an unverified chain scores zero" 0.0
      (rwScore (score (fuse []) (chain 5)))
  , expectEq "reward: a longer unverified chain scores the same zero" 0.0
      (rwScore (score (fuse []) (chain 50)))
  , expect "reward: so internal coherence cannot be farmed for reward"
      (rwScore (score (fuse []) (chain 5))
         == rwScore (score (fuse []) (chain 50)))
  , expectEq "reward: an uncovered premise scores zero" 0.0
      (rwScore (score (fuse []) uncoveredPremise))
  , expect "reward: and is reported as uncovered rather than hidden"
      (rwUncovered (score (fuse []) uncoveredPremise) == 1)
  , expect "reward: unsupported nodes are reported too"
      (rwUngrounded (score (fuse []) (chain 5)) == length (nodeIds (chain 5)))
  , expect "reward: which is every node in the chain, since none is grounded"
      (length (nodeIds (chain 5)) == 6)

  , -- What does score.
    expect "reward: confirmed claims score positively"
      (rwScore (score (fuse (confirmFixtures yesOracle [cl "p", cl "q"])) twoSupport) > 0)
  , expect "reward: refuted premises are penalised"
      (rwScore (score (fuse []) refutedPremise) < 0)
  , expect "reward: refutation costs more than silence"
      (rwScore (score (fuse []) refutedPremise)
         < rwScore (score (fuse []) uncoveredPremise))
  , expect "reward: entailed consequences contribute"
      (let f = fuse (confirmFixtures yesOracle [cl "p", impl (cl "p") (cl "q")])
       in rwEntailed (score f emptyGenealogy) == 1)
  , expect "reward: but less than direct confirmation"
      (wEntailed defaultWeights < wConfirmed defaultWeights)
  , expect "reward: score is monotone in confirmations"
      (rwScore (score (fuse (confirmFixtures yesOracle [cl "p"])) emptyGenealogy)
         < rwScore (score (fuse (confirmFixtures yesOracle [cl "p", cl "q"])) emptyGenealogy))

  , -- The admissibility self-check has teeth.
    expect "reward: the default weights are admissible"
      (adAllOk (admissibility defaultWeights))
  , expect "reward: paying for uncovered claims is inadmissible"
      (not (adAllOk (admissibility defaultWeights { wUncovered = 0.1 })))
  , expect "reward: not penalising refutation is inadmissible"
      (not (adAllOk (admissibility defaultWeights { wRefuted = 0 })))
  , expect "reward: valuing entailment above confirmation is inadmissible"
      (not (adAllOk (admissibility defaultWeights { wEntailed = 2 })))
  ]
  where
    -- n0 <- n1 <- n2 <- ... , with no premise anywhere. Perfectly coherent,
    -- entirely unsupported.
    chain k =
      foldr
        (\i g ->
           addJustification (derivation (NodeId i) "step" [NodeId (i + 1)])
             (addNode (node i (cl ("c" ++ show i))) Unknown g))
        (addNode (node k (cl ("c" ++ show k))) Unknown emptyGenealogy)
        [0 .. k - 1]

    uncoveredPremise =
      addJustification (premise (NodeId 0) "oracle")
        (addNode (node 0 (cl "p")) Unknown emptyGenealogy)

    refutedPremise =
      addJustification (premise (NodeId 0) "oracle")
        (addNode (node 0 (cl "p")) Refuted emptyGenealogy)

--------------------------------------------------------------------------------
-- 6b. What the scalar cannot see
--------------------------------------------------------------------------------

-- | Three properties of 'rwScore', executed rather than asserted.
--
-- Each is a fact about collapsing the coordinates to one number, and each is the
-- reason the coordinates are reported separately. The point of these checks is
-- not that the scalar is wrong — it satisfies every constraint 'admissibility'
-- states — but that satisfying those constraints is compatible with all three
-- blind spots, so a future weight table cannot be trusted to close them.
--
-- If any of these ever /fails/, someone has changed the collapse. That is
-- allowed, and it should be deliberate, which is what a failing check here is
-- for.
scalarBlindSpotChecks :: [Check]
scalarBlindSpotChecks =
  [ -- 1. Extensivity: over-generation is free.
    expect "blind: appending uncovered claims does not move the score"
      (rwScore (score confirmedTwo (overGenerate 0))
         == rwScore (score confirmedTwo (overGenerate 20)))
  , expect "blind: and it is not that they went unnoticed"
      (rwUncovered (score confirmedTwo (overGenerate 20)) == 20)
  , expect "blind: the yield coordinate is what sees it"
      (rwYield (score confirmedTwo (overGenerate 20))
         < rwYield (score confirmedTwo (overGenerate 0)))
  , expect "blind: no weight table separates the two, because it is one condition"
      (adOverGenerationFree (admissibility defaultWeights)
         == adUncoveredIsZero (admissibility defaultWeights))

  , -- 2. Input-independence: the scalar never reads provenance.
    expect "blind: grounding six characters scores what grounding the text scores"
      (rwScore (score confirmedTwo (groundedOver 0 6))
         == rwScore (score confirmedTwo (groundedOver 0 200)))
  , expectEq "blind: the span coordinate distinguishes them" 6
      (rwGroundedSpan (score confirmedTwo (groundedOver 0 6)))
  , expectEq "blind: and reads coverage against the source when told its extent"
      (Just 0.5)
      (rwSourceCoverage
         (scoreOver defaultWeights (Just (Span 0 20)) confirmedTwo
            (groundedOver 0 10)))
  , expectEq "blind: coverage is unknown, not total, when the extent is withheld"
      Nothing
      (rwSourceCoverage (score confirmedTwo (groundedOver 0 10)))

  , -- 3. The idempotent quotient: corroboration is invisible to the scalar.
    expect "blind: two derivations of one claim score as one derivation does"
      (rwScore (score confirmedTwo twiceSameWay)
         == rwScore (score confirmedTwo twiceDifferently))
  , expectEq "blind: repetition is not corroboration" 0
      (rwCorroborated (score confirmedTwo twiceSameWay))
  , expectEq "blind: two distinct derivations are" 1
      (rwCorroborated (score confirmedTwo twiceDifferently))
  , expectEq "blind: convergence, which fusion wants, counts both" 1
      (length (convergentNodes twiceSameWay))
  , expect "blind: so convergence and corroboration are different questions"
      (length (convergentNodes twiceSameWay)
         /= length (corroboratedNodes twiceSameWay))

  , -- The stronger notion, and why it is not the one used here.
    expect "blind: premise-disjoint support is vacuous on a premise-only graph"
      (not (any (hasIndependentSupport twiceDifferently) (nodeIds twiceDifferently)))
  , expect "blind: while it does hold where derivations exist"
      (hasIndependentSupport twoSupport (NodeId 2))

  , -- Novelty: content the oracle had to supply.
    expectEq "blind: a claim implied by the others is not novel" 2
      (rwNovel (score (fuse (confirmFixtures yesOracle [cl "p", impl (cl "p") (cl "q"), cl "q"]))
                  emptyGenealogy))
  , expectEq "blind: with nothing implied, every claim is novel" 2
      (rwNovel (score confirmedTwo emptyGenealogy))
  , expect "blind: novelty and corroboration are opposite pressures"
      (rwNovel (score confirmedTwo emptyGenealogy) > 0
         && rwCorroborated (score confirmedTwo twiceDifferently) > 0)

    -- Span coverage counts overlap once, which is what makes it a measure.
  , expectEq "spanCoverage: overlapping spans count once" 8
      (spanCoverage [Span 0 5, Span 3 8])
  , expectEq "spanCoverage: naive summing double counts" 10
      (sum (map spanWidth [Span 0 5, Span 3 8]))
  , expectEq "spanCoverage: containment counts once" 10
      (spanCoverage [Span 0 10, Span 2 4])
  , expectEq "spanCoverage: disjoint spans add" 10
      (spanCoverage [Span 10 15, Span 0 5])
  , expectEq "spanCoverage: nothing covers nothing" 0 (spanCoverage [])
  , expectEq "spanCoverage: empty spans contribute nothing" 0
      (spanCoverage [Span 4 4, Span 9 9])
  ]
  where
    confirmedTwo = fuse (confirmFixtures yesOracle [cl "p", cl "q"])

    -- Two confirmed premises, plus k premises no oracle covers.
    overGenerate k =
      foldl
        (\g i ->
           addJustification (premise (NodeId i) "oracle")
             (addNode (node i (cl ("j" ++ show i))) Unknown g))
        (addJustification (premise (NodeId 1) "oracle")
           (addJustification (premise (NodeId 0) "oracle")
              (addNode (node 1 (cl "q")) Confirmed
                 (addNode (node 0 (cl "p")) Confirmed emptyGenealogy))))
        [2 .. k + 1]

    -- One confirmed premise whose derivation covers [a,b) of the source.
    groundedOver a b =
      addJustification (premise (NodeId 0) "oracle")
        (addNode (nodeP 0 (cl "p") (pvAt a b)) Confirmed emptyGenealogy)

    -- The same claim twice. Same derivation in one graph, different in the
    -- other; both grounded, so the difference is corroboration and nothing else.
    twiceSameWay = twice (pvAt 0 4) (pvAt 0 4)
    twiceDifferently = twice (pvAt 0 4) (pvAt 10 14)

    twice p1 p2 =
      addJustification (premise (NodeId 1) "oracle")
        (addJustification (premise (NodeId 0) "oracle")
           (addNode (nodeP 1 (cl "p") p2) Confirmed
              (addNode (nodeP 0 (cl "p") p1) Confirmed emptyGenealogy)))

--------------------------------------------------------------------------------
-- 7. End to end, on the real front end
--------------------------------------------------------------------------------

-- | Stage 1 output through verification, fusion and scoring.
--
-- The oracle is a whitelist and settles nothing about the world; the point is
-- that the seams line up and that the numbers move in the right direction when a
-- verdict changes.
endToEndChecks :: [Check]
endToEndChecks =
  [ expect "e2e: a fragment case yields a selection"
      (tableOf "quantified" /= Nothing)
  , expect "e2e: the claim table retains every condition"
      (case tableOf "quantified" of
         Just ct -> not (null (ctFacts ct))
         Nothing -> False)
  , expect "e2e: every fact traces to the declared source"
      (case tableOf "quantified" of
         Just ct -> all ((== [SourceId "e2e"]) . factSources) (ctFacts ct)
         Nothing -> False)
  , expect "e2e: the genealogy has one premise per fact"
      (case tableOf "quantified" of
         Just ct ->
           let g = genealogyOf unaryOracle ct
           in length (nodeIds g) == length (ctFacts ct)
         Nothing -> False)
  , expect "e2e: grounded nodes are exactly the oracle-confirmed premises"
      (case tableOf "anaphora" of
         Just ct ->
           let g = genealogyOf unaryOracle ct
           in [i | i <- nodeIds g, isGrounded g i]
                == [i | i <- nodeIds g, verdictOf g i == Confirmed]
         Nothing -> False)
  , expect "e2e: swapping in an oracle that covers nothing drops the score to zero"
      (case tableOf "anaphora" of
         Just ct ->
           let g = genealogyOf blindOracle ct
               f = fuse (confirmAll blindOracle (map factAssertion (ctFacts ct)))
           in rwScore (score f g) == 0.0
         Nothing -> False)
  , expect "e2e: and the whitelist oracle scores above zero on the same text"
      (case tableOf "anaphora" of
         Just ct ->
           let g = genealogyOf unaryOracle ct
               f = fuse (confirmAll unaryOracle (map factAssertion (ctFacts ct)))
           in rwScore (score f g) > 0.0
         Nothing -> False)
  , expect "e2e: fusion never sees more claims than verification retained"
      (case tableOf "anaphora" of
         Just ct ->
           let f = fuse (confirmAll unaryOracle (map factAssertion (ctFacts ct)))
           in length (fusedClaims f) <= length (ctFacts ct)
         Nothing -> False)
  , expect "e2e: the retaining strategy names itself"
      (strategyName retainingStrategy == "verification")
  , expect "e2e: source-level retraction removes every fact using that source"
      (case tableOf "anaphora" of
         Just ct ->
           let (before, after, _) = retractionImpact (SourceId "e2e") ct
           in before > 0 && after == 0
         Nothing -> False)
  ]
  where
    tableOf i = claimsOf <$> prSelection (runFragment (SourceId "e2e") (textOf i))

    textOf i = case [caseText c | c <- fragmentCases, caseId c == i] of
      (t : _) -> t
      []      -> error ("no such case: " ++ i)

--------------------------------------------------------------------------------
-- Assembly
--------------------------------------------------------------------------------

allChecks :: [Check]
allChecks =
  concat
    [ oracleChecks
    , supportChecks
    , cycleChecks
    , retractionChecks
    , fusionChecks
    , selfAgreementChecks
    , scalarBlindSpotChecks
    , paretoChecks
    , endToEndChecks
    ]

-- | The vector-valued reward: corroboration and novelty are anti-correlated, so
-- the Pareto frontier (not a scalar) is the honest object. These checks pin that
-- the two axes are treated as a trade-off, not summed away.
paretoChecks :: [Check]
paretoChecks =
  [ expect "corroboration-heavy and novelty-heavy rewards are Pareto-incomparable"
      (not (dominates corrHeavy novHeavy) && not (dominates novHeavy corrHeavy))
  , expect "a strictly-better reward dominates a worse one"
      (dominates balanced dominated)
  , expect "the frontier keeps the anti-correlated pair and drops the dominated point"
      (let fr = paretoFrontier [dominated, balanced, corrHeavy, novHeavy]
       in notElem dominated fr && all (`elem` fr) [balanced, corrHeavy, novHeavy])
  , expect "rwScore is blind to corroboration/novelty (the omission the vector fixes)"
      (rwScore corrHeavy == rwScore novHeavy)
  , expect "corroboration-heavy is not dominated by the balanced reward either"
      (not (dominates balanced corrHeavy))
  ]
  where
    -- confirmed entailed refuted uncov ungr off corrob novel  spans... rwScore
    mkR c e rf co nv =
      Reward c e rf 0 0 0 co nv 0 0 0
             (fromIntegral c * 1.0 + fromIntegral e * 0.5 - fromIntegral rf)
    corrHeavy = mkR 3 0 0 9 0
    novHeavy  = mkR 3 0 0 0 9
    balanced  = mkR 3 0 0 4 4
    dominated = mkR 2 0 0 3 3

main :: IO ()
main = runChecks "substrate" allChecks
