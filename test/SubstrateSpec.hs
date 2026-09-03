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
import NL2Proof.Fragment
import NL2Proof.Fusion
import NL2Proof.Genealogy
import NL2Proof.Pipeline
import NL2Proof.Provenance
import NL2Proof.Reward
import NL2Proof.Verify.Claims
import NL2Proof.Verify.Oracle

--------------------------------------------------------------------------------
-- Fixtures
--------------------------------------------------------------------------------

pv :: Prov
pv = ProvLex (SourceId "substrate") (Span 0 1) "w"

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
      (all (\c -> (confirm unaryOracle c /= Nothing) == (check unaryOracle c == Confirmed))
           [cl "student", cl "dragon", impl (cl "student") (cl "book")])
  , expectEq "oracle: refuted claims yield no token" Nothing
      (confirm noOracle (cl "student"))
  , expectEq "oracle: uncovered claims yield no token either" Nothing
      (confirm blindOracle (cl "student"))
  , expect "oracle: every token names the oracle that issued it"
      (all ((== "unary") . confOracle) (confirmAll unaryOracle [cl "student", cl "book"]))
  , expectEq "oracle: confirmAll keeps only the confirmed" [cl "book", cl "student"]
      (sort (map confClaim (confirmAll unaryOracle [cl "student", cl "dragon", cl "book"])))

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
      (length (fusedClaims (fuse (confirmAll yesOracle [cl "p", cl "p", cl "p"]))))
  , expectEq "fusion: and the loss is measured" 2
      (fusedDropped (fuse (confirmAll yesOracle [cl "p", cl "p", cl "p"])))
  , expectEq "fusion: distinct claims are kept" 2
      (length (fusedClaims (fuse (confirmAll yesOracle [cl "p", cl "q"]))))
  , expect "fusion: the contributing oracles are named"
      (fusedOracles (fuse (confirmAll yesOracle [cl "p"])) == ["yes"])
  , expect "fusion: nothing refuted can reach this stage"
      (null (fusedClaims (fuse (confirmAll noOracle [cl "p", cl "q"]))))
  , expect "fusion: nor anything uncovered"
      (null (fusedClaims (fuse (confirmAll blindOracle [cl "p"]))))

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
           a = fusedClaims (fuse (confirmAll yesOracle [negOr]))
           b = fusedClaims (fuse (confirmAll yesOracle deMorgan))
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
      (let f = fuse (confirmAll yesOracle
                       [cl "p", impl (cl "p") (cl "q"), impl (cl "q") (cl "r")])
       in cl "r" `elem` entailedFrom f)
  , expect "fusion: entailedFrom adds nothing without a detachable premise"
      (let f = fuse (confirmAll yesOracle [impl (cl "p") (cl "q")])
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
      (rwScore (score (fuse (confirmAll yesOracle [cl "p", cl "q"])) twoSupport) > 0)
  , expect "reward: refuted premises are penalised"
      (rwScore (score (fuse []) refutedPremise) < 0)
  , expect "reward: refutation costs more than silence"
      (rwScore (score (fuse []) refutedPremise)
         < rwScore (score (fuse []) uncoveredPremise))
  , expect "reward: entailed consequences contribute"
      (let f = fuse (confirmAll yesOracle [cl "p", impl (cl "p") (cl "q")])
       in rwEntailed (score f emptyGenealogy) == 1)
  , expect "reward: but less than direct confirmation"
      (wEntailed defaultWeights < wConfirmed defaultWeights)
  , expect "reward: score is monotone in confirmations"
      (rwScore (score (fuse (confirmAll yesOracle [cl "p"])) emptyGenealogy)
         < rwScore (score (fuse (confirmAll yesOracle [cl "p", cl "q"])) emptyGenealogy))

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
               f = fuse (confirmAll blindOracle (map factClaim (ctFacts ct)))
           in rwScore (score f g) == 0.0
         Nothing -> False)
  , expect "e2e: and the whitelist oracle scores above zero on the same text"
      (case tableOf "anaphora" of
         Just ct ->
           let g = genealogyOf unaryOracle ct
               f = fuse (confirmAll unaryOracle (map factClaim (ctFacts ct)))
           in rwScore (score f g) > 0.0
         Nothing -> False)
  , expect "e2e: fusion never sees more claims than verification retained"
      (case tableOf "anaphora" of
         Just ct ->
           let f = fuse (confirmAll unaryOracle (map factClaim (ctFacts ct)))
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
    , endToEndChecks
    ]

main :: IO ()
main = runChecks "substrate" allChecks
