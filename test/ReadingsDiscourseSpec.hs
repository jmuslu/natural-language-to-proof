-- | Discrete readings and discourse structure: scope and coupling
-- alternatives ("NL2Proof.Readings.Alternatives"), modifier classes
-- ("NL2Proof.Readings.Modifier"), SDRT ("NL2Proof.Discourse.SDRT") and
-- frontier-aware threading ("NL2Proof.Discourse.Threading").
--
-- Restored from @test/Stage2Spec.hs@ in tag @pre-cut@, keeping only the sections
-- for these four modules. The distribution, RSA, model and fingerprint checks
-- stay in @pre-cut@. Checks that used to read probability mass now read the
-- licensing relations instead; every such change is marked "deterministic".
module Main (main) where

import Data.List (isInfixOf, nub, sort)
import qualified Data.Map.Strict as M

import Harness
import NL2Proof.Discourse.SDRT
import NL2Proof.Discourse.Threading
import NL2Proof.DRT.Build
import NL2Proof.DRT.Types
import NL2Proof.Fragment
import NL2Proof.Pipeline
import NL2Proof.Provenance
import NL2Proof.Readings.Alternatives
import NL2Proof.Readings.Modifier
import NL2Proof.Semantics.Lambda
import NL2Proof.Syntax.Lexicon
import NL2Proof.Syntax.Tokenize
import NL2Proof.Trace

--------------------------------------------------------------------------------
-- Fixtures
--------------------------------------------------------------------------------

caseTerm :: String -> Term
caseTerm i = case caseById i >>= headOf . caseForms of
  Just t  -> t
  Nothing -> error ("no such case: " ++ i)
  where
    headOf (x : _) = Just x
    headOf []      = Nothing

--------------------------------------------------------------------------------
-- 1. Scope alternatives
--------------------------------------------------------------------------------

scopeChecks :: [Check]
scopeChecks =
  [ expectEq "alt: quantified sentence yields both scopings" 2
      (length (scopeAlternatives (caseTerm "quantified")))
  , expect "alt: the surface reading comes first"
      (case scopeAlternatives (caseTerm "quantified") of
         (t : _) -> alphaEq t (caseTerm "quantified")
         []      -> False)
  , expectEq "alt: the two scopings differ in prefix, not content"
      ["forall x exists y", "exists y forall x"]
      (map scopeSignature (scopeAlternatives (caseTerm "quantified")))
  , -- A quantifier trapped in a relative clause restrictor must not be lifted:
    -- doing so would change what the universal quantifies over.
    expectEq "alt: relative-clause quantifier is not lifted" 1
      (length (scopeAlternatives (caseTerm "relative-clause")))
  , expectEq "alt: nothing is re-scoped across negation" 1
      (length (scopeAlternatives (caseTerm "negative-quantifier")))
  , expectEq "alt: a single quantifier yields one reading, not n!" 1
      (length (scopeAlternatives (caseTerm "anaphora")))
  , expectEq "alt: a quantifier-free term yields itself" 1
      (length (scopeAlternatives (caseTerm "transitive")))
  , expect "alt: every generated reading is closed"
      (all (null . freeVars) (scopeAlternatives (caseTerm "quantified")))
  , expect "alt: every generated reading is well-typed"
      (all wellTyped (scopeAlternatives (caseTerm "quantified")))
  , expect "alt: unscope and relinearize round-trip"
      (let t = caseTerm "quantified"
           s = unscope t
       in alphaEq (relinearize (scopeQuants s) (scopeCore s)) t)
  , -- The dependency constraint is the reason permutation is safe at all.
    expect "alt: validOrder rejects a restrictor depending on a later binder"
      (not (validOrder
              [ Quant QExists "y" (App (pred2 "owns") (Var "x") `App` Var "y")
              , Quant QForall "x" (App (pred1 "person") (Var "x"))
              ]))
  , expect "alt: validOrder accepts the same pair in dependency order"
      (validOrder
         [ Quant QForall "x" (App (pred1 "person") (Var "x"))
         , Quant QExists "y" (App (pred2 "owns") (Var "x") `App` Var "y")
         ])
  ]

--------------------------------------------------------------------------------
-- 2. Modifier classes
--------------------------------------------------------------------------------

-- | The stratification exists because treating all modifiers alike
-- over-generates. These checks pin the behavioural consequences of each class,
-- not just the class labels.
modifierChecks :: [Check]
modifierChecks =
  [ expectEq "mod: chinese is classificatory" Classificatory (classifyModifier "chinese")
  , expectEq "mod: red is intersective" Intersective (classifyModifier "red")
  , expectEq "mod: unknown words default to intersective, as Stage 1 assumes"
      Intersective (classifyModifier "wibbly")
  , expect "mod: only classificatory modifiers may fuse with a head"
      (all (\c -> mayFuseWithHead c == (c == Classificatory)) [minBound .. maxBound])
  , expect "mod: privative modifiers do not preserve head truth"
      (not (preservesHeadTruth Privative))
  , expect "mod: every other class preserves head truth"
      (all preservesHeadTruth [Intersective, Classificatory, Subsective])
  , expect "mod: only intersective modifiers reorder freely"
      (all (\c -> reorderable c == (c == Intersective)) [minBound .. maxBound])
  , -- Layers must be ordered, or "resolvable at a lower layer" means nothing.
    expect "mod: intersective is the easiest layer"
      (all (\c -> modifierLayer Intersective <= modifierLayer c) [minBound .. maxBound])
  , expect "mod: privative and subsective need the hardest layer"
      (modifierLayer Privative == 3 && modifierLayer Subsective == 3)
  , expect "mod: classificatory sits strictly between the two"
      (modifierLayer Intersective < modifierLayer Classificatory
         && modifierLayer Classificatory < modifierLayer Privative)
  , expect "mod: every class has a description"
      (all (not . null . classDescription) [minBound .. maxBound])
  , expect "mod: genuinely ambiguous modifiers are recorded, not silently decided"
      (not (null ambiguousModifiers)
         && all (\(w, why) -> M.member w fragmentModifierClasses && not (null why))
                ambiguousModifiers)
  ]

--------------------------------------------------------------------------------
-- 3. Coupling alternatives
--------------------------------------------------------------------------------

-- | The space is built, then narrowed. These assert both halves: every fusion is
-- generated, and the licensing evidence needed to narrow them is attached rather
-- than applied.
couplingChecks :: [Check]
couplingChecks =
  [ expectEq "coupling: surface plus one candidate per modifier, none suppressed"
      4 (length cands)
  , expect "coupling: the surface reading comes first and is unfused"
      (case cands of
         (c : _) -> alphaEq (ccTerm c) (caseTerm "coupling")
                      && ccModifier c == Nothing && ccLayer c == 0
         []      -> False)
  , expect "coupling: chinese_dragon is generated"
      (any (\t -> "chinese_dragon" `elem` constNames t) couplings)
  , -- No preemptive pruning: implausible fusions are generated too, so they can
    -- be down-weighted explicitly rather than silently never existing.
    expect "coupling: implausible fusions ARE generated, not suppressed"
      (all (\q -> any (\t -> q `elem` constNames t) couplings)
           ["ancient_dragon", "red_dragon"])
  , expect "coupling: exactly one candidate is licensed by its modifier class"
      (length [c | c <- cands, ccModifier c /= Nothing, ccLicensed c] == 1)
  , expect "coupling: and it is the classificatory one"
      (case [c | c <- cands, ccModifier c /= Nothing, ccLicensed c] of
         [c] -> ccModifier c == Just "chinese" && ccClass c == Just Classificatory
         _   -> False)
  , expect "coupling: unlicensed candidates still carry their class as evidence"
      (all (\c -> ccClass c == Just Intersective && not (ccLicensed c))
           [c | c <- cands, ccModifier c `elem` [Just "ancient", Just "red"]])
  , expect "coupling: every fused candidate records its head"
      (all (\c -> ccHead c == Just "dragon") [c | c <- cands, ccModifier c /= Nothing])
  , expect "coupling: the licensed candidate sits at layer 2"
      (all (\c -> ccLayer c == 2)
           [c | c <- cands, ccLicensed c, ccModifier c /= Nothing])
  , expect "coupling: the fused reading drops the separate conjunct"
      (case filter (\t -> "chinese_dragon" `elem` constNames t) couplings of
         (t : _) -> "chinese" `notElem` constNames t
         []      -> False)
  , expect "coupling: all candidates stay closed and well-typed"
      (all (\t -> null (freeVars t) && wellTyped t) couplings)
  , expectEq "coupling: a sentence with no modifier stack yields itself" 1
      (length (couplingAlternatives (const True) (caseTerm "transitive")))
  ]
  where
    cands = couplingCandidates (const True) (caseTerm "coupling")
    couplings = couplingAlternatives (const True) (caseTerm "coupling")

--------------------------------------------------------------------------------
-- 4. SDRT: relations, the right frontier, and accessibility
--------------------------------------------------------------------------------

-- | The point of SDRT is that relation choice changes what a later sentence can
-- refer to. These checks pin that down, and pin down the example that *cannot*
-- show it -- which is the trap worth having a regression for.
sdrtChecks :: [Check]
sdrtChecks =
  [ -- Inventory: the kind split is what drives everything else.
    expectEq "sdrt: four coordinating relations" 4
      (length [r | r <- allRelations, relationKind r == Coordinating])
  , expectEq "sdrt: four subordinating relations" 4
      (length [r | r <- allRelations, relationKind r == Subordinating])
  , expect "sdrt: every relation has a layer in 1..3"
      (all (\r -> relationLayer r >= 1 && relationLayer r <= 3) allRelations)
  , expect "sdrt: Narration is layer 1, cued from the surface"
      (relationLayer Narration == 1)
  , expect "sdrt: Explanation is layer 3, needs inference"
      (relationLayer Explanation == 3)
  , expect "sdrt: every relation glosses its own kind"
      (all (not . null . relationGloss) allRelations)

  , -- The right frontier.
    expectEq "sdrt: a subordinating relation leaves the parent open"
      [Label 2, Label 1] (rightFrontier (joined Elaboration))
  , expectEq "sdrt: a coordinating relation closes the parent"
      [Label 2] (rightFrontier (joined Narration))
  , expect "sdrt: isOpen agrees with the frontier"
      (isOpen (joined Elaboration) (Label 1)
         && not (isOpen (joined Narration) (Label 1)))

  , -- THE payoff: same two DRSs, different relation, different accessibility.
    expectEq "sdrt: under Elaboration the earlier referent stays accessible"
      [Ref "x"] (sdrsAccessible (joined Elaboration))
  , expectEq "sdrt: under Narration it does not"
      [] (sdrsAccessible (joined Narration))
  , expect "sdrt: so relation choice changes downstream anaphora"
      (sdrsAccessible (joined Elaboration) /= sdrsAccessible (joined Narration))

  , -- And the flat monoid cannot express the difference at all.
    expect "sdrt: mergeDRS is identical under both relations"
      (accessibleRefs (mergeDRS (duDRS k1) (duDRS k2))
         == accessibleRefs (mergeDRS (duDRS k1) (duDRS k2)))
  , expect "sdrt: and it keeps the referent regardless, so it cannot discriminate"
      (accessibleRefs (mergeDRS (duDRS k1) (duDRS k2)) == [Ref "x"])

  , -- The trap. A universally quantified first unit has an EMPTY top-level
    -- universe, so it contributes nothing whether open or closed, and the two
    -- relations give identical results. Using it to demonstrate SDRT would make
    -- the layer look inert.
    expect "sdrt: a duplex-only first unit cannot discriminate the relations"
      (sdrsAccessible (joinedWith badK1 Elaboration)
         == sdrsAccessible (joinedWith badK1 Narration))
  , expectEq "sdrt: because its accessible set is empty either way"
      [] (sdrsAccessible (joinedWith badK1 Elaboration))
  , expect "sdrt: even though the frontier genuinely differs"
      (rightFrontier (joinedWith badK1 Elaboration)
         /= rightFrontier (joinedWith badK1 Narration))

  , -- Climbing: a coordinating edge is skipped but climbed THROUGH, so a
    -- subordinating ancestor above it stays open. Easy to get wrong by stopping
    -- at the first coordinating edge.
    expectEq "sdrt: climbs through a coordinating edge to a subordinating ancestor"
      [Label 3, Label 1] (rightFrontier threeChain)

  , -- Glue: builds the space, prunes nothing. (deterministic: scores and a
    -- total ranking replace the pre-cut distribution)
    expect "sdrt: glue scores every relation positively"
      (length (glueScores k1 k2) == length allRelations
         && all ((> 0) . snd) (glueScores k1 k2))
  , expectEq "sdrt: glueRanked is a permutation of the inventory"
      (sort allRelations) (sort (glueRanked k1 k2))
  , expectEq "sdrt: with no cues, Continuation is the least committal default"
      (Just Continuation) (headMay (glueRanked k1 k2))
  , expectEq "sdrt: and no cues fire on that pair" [] (detectCues k1 k2)

  , -- Cues that do fire.
    expect "sdrt: generic-then-specific is detected"
      (GenericThenSpecific `elem` detectCues badK1 k2)
  , expectEq "sdrt: and it favours Instance"
      (Just Instance) (headMay (glueRanked badK1 k2))
  , expect "sdrt: a shared predicate is detected"
      (any isShared (detectCues k1 sameVerb))
  , expect "sdrt: cue weights never reach zero, so nothing is pruned by a cue"
      (all (\c -> all (\r -> cueWeight c r > 0) allRelations)
           [GenericThenSpecific, NewReferent, SharedPredicate "p", Connective "then"])

  , -- The connective path exists but cannot fire yet, and that is a lexicon gap
    -- rather than an SDRT gap. Asserted so the gap is visible.
    expect "sdrt: a connective-led sentence still fails to parse (lexicon gap)"
      (null [d | Just d <- [drsOf "Then Mary smiles."]])
  , expect "sdrt: but the connective cue is defined and weighted"
      (cueWeight (Connective "then") Narration > cueWeight (Connective "then") Elaboration)
  ]
  where
    k1 = mkUnit 1 "A student arrived."
    k2 = mkUnit 2 "Mary smiles."
    badK1 = mkUnit 1 "Every student reads a book."
    -- Must actually share a predicate with k1, whose predicates are
    -- {student, arrive}. "Mary reads a book" shares none; "Susan arrived"
    -- shares `arrive`.
    sameVerb = mkUnit 3 "Susan arrived."

    joined rel = joinedWith k1 rel
    joinedWith a rel = attach rel (Label 1) k2 (addRoot a emptySDRS)

    -- K1 --Elaboration--> K2 --Narration--> K3
    threeChain =
      attach Narration (Label 2) (mkUnit 3 "Mary smiles.")
        (attach Elaboration (Label 1) k2 (addRoot k1 emptySDRS))

    isShared (SharedPredicate _) = True
    isShared _                   = False

mkUnit :: Int -> String -> DiscourseUnit
mkUnit i txt =
  DiscourseUnit (Label i) (dscDRS (prDiscourse (runFragment sdrtSrc txt))) (toks txt)
  where
    toks =
      concatMap
        ( map tokText
            . latRaw
            . sentenceLattice
                (inLexicon fragmentLexicon)
                (maxPhraseLength fragmentLexicon)
        )
        . splitSentences

-- | 'Nothing' when the text produced no conditions at all, i.e. nothing parsed.
drsOf :: String -> Maybe DRS
drsOf txt =
  let d = dscDRS (prDiscourse (runFragment sdrtSrc txt))
  in if null (drsConds d) then Nothing else Just d

sdrtSrc :: SourceId
sdrtSrc = SourceId "sdrt"

--------------------------------------------------------------------------------
-- 5. The SDRT tie-in: threading that actually consults the frontier
--------------------------------------------------------------------------------

-- | Section 11 checks that the frontier is computed correctly. These checks ask
-- whether anything /uses/ it, which is a different question: a correctly computed
-- frontier that nothing consults has no observable effect.
--
-- Two facts do most of the work:
--
-- * the fragment corpus __cannot__ show a divergence, because both of its
--   multi-sentence cases are two sentences long
-- * a three-sentence discourse __does__, and under 'Committed' the divergence is
--   a lost resolution rather than a different one
threadingChecks :: [Check]
threadingChecks =
  [ -- Structure. The threader builds the graph it claims to build.
    expectEq "threading: three segments become three units" 3
      (length (labelsInOrder (thSDRS threeCommitted)))
  , expectEq "threading: and two edges" 2
      (length (sdrsEdges (thSDRS threeCommitted)))
  , expect "threading: the first unit has no attachment site"
      (null (stFrontier (head (thSteps threeCommitted))))
  , expect "threading: and no relation"
      (stRelation (head (thSteps threeCommitted)) == Nothing)

  , -- The off-by-one. K2 attaches to K1, so K1's referent is offered to K2
    -- whatever relation is chosen at that step: accessibility flows from the
    -- left argument of a relation to its right one.
    expectEq "threading: unit 2 is offered the referent from unit 1"
      [Ref "x"] (map rkRef (stRanked (thSteps threeCommitted !! 1)))
  , expect "threading: licensed under every hypothesis, since no earlier edge exists"
      (all rkAlways (stRanked (thSteps threeCommitted !! 1)))

  , -- With no cues firing, glue defaults to Continuation, which is
    -- coordinating. So committed threading closes K1 and unit 3 gets nothing.
    expectEq "threading: with no cues the chosen relation is Continuation"
      (Just Continuation) (stRelation (thSteps threeCommitted !! 1))
  , expect "threading: which is coordinating"
      (relationKind Continuation == Coordinating)
  , expect "threading: so under Committed unit 3 is offered no antecedent"
      (null (stRanked (thSteps threeCommitted !! 2)))

  , -- Permissive keeps it, graded. Elaboration is always a candidate, so the
    -- referent is never deleted -- only ranked below the always-licensed ones.
    -- (deterministic: "mass" checks now read the licensing relations)
    expectEq "threading: under Permissive unit 3 is still offered the referent"
      [Ref "x"] (map rkRef (stRanked (thSteps threePermissive !! 2)))
  , expect "threading: but not under every relation"
      (case stRanked (thSteps threePermissive !! 2) of
         (r : _) -> not (rkAlways r) && not (null (rkLicensors r))
         []      -> False)
  , expect "threading: and its licensors are exactly the subordinating relations"
      (case ( stRanked (thSteps threePermissive !! 2)
            , stRelOrder (thSteps threePermissive !! 1) ) of
         ((r : _), Just rs) ->
           sort (rkLicensors r)
             == sort [rel | rel <- rs, relationKind rel == Subordinating]
         _ -> False)
  , expect "threading: licensed only by subordinating relations"
      (case stRanked (thSteps threePermissive !! 2) of
         (r : _) -> not (null (rkLicensors r))
                      && all ((== Subordinating) . relationKind) (rkLicensors r)
         []      -> False)

  , -- The consequence for the pronoun, which is the whole point.
    expect "threading: flat threading resolves the third-sentence pronoun"
      (flatResolved threeSent)
  , expect "threading: Committed threading does not -- a strict loss"
      (not (sdrtResolved Committed threeSent))
  , expect "threading: Permissive threading does"
      (sdrtResolved Permissive threeSent)
  , expectEq "threading: so Committed diverges from flat on exactly one anaphor"
      1 (length (compareThreading Committed (segsOf threeSent)))
  , expectEq "threading: and the divergence is a loss, not a different choice"
      [Nothing] (map dvSDRT (compareThreading Committed (segsOf threeSent)))
  , expectEq "threading: while Permissive diverges nowhere"
      [] (compareThreading Permissive (segsOf threeSent))
  , expect "threading: original named middle sentence exposes Ref-only ranking gap"
      (not (null (compareThreading Permissive
         (segsOf "A student arrived. Mary smiles. She reads a book."))))

  , -- Forcing a subordinating relation restores it even under Committed. This
    -- is the check that the loss above is about the stipulated cue weights and
    -- not about the frontier code being broken.
    expect "threading: a generic-then-specific cue picks a subordinating relation"
      (fmap relationKind (stRelation (thSteps genericLed !! 1))
         == Just Subordinating)
  , expect "threading: so Committed leaves the earlier unit open there"
      (stFrontier (thSteps genericLed !! 2) == [Label 2, Label 1])
  , expect "threading: and logs the attachment site it picked from the two"
      (any (\d -> decKind d == "sdrt-attachment")
           (traceDecisions (thTrace genericLed)))

  , -- The corpus. Both multi-sentence cases have two segments, so the only
    -- parent is always on the pre-attachment frontier and no relation choice can
    -- change anything. Neither policy may regress the existing suite.
    expectEq "threading: no divergence on any fragment case under Committed"
      [] (concat [ compareThreading Committed (segsOf (caseText c))
                 | c <- fragmentCases ])
  , expectEq "threading: nor under Permissive"
      [] (concat [ compareThreading Permissive (segsOf (caseText c))
                 | c <- fragmentCases ])
  , expect "threading: and that is because no case has three segments"
      (all (\c -> length (segsOf (caseText c)) <= 2) fragmentCases)
  , expect "threading: the anaphora case still resolves under both policies"
      (sdrtResolved Committed anaphoraCase && sdrtResolved Permissive anaphoraCase)
  , expect "threading: the blocked case still fails under both, as it should"
      (not (sdrtResolved Committed blockedCase)
         && not (sdrtResolved Permissive blockedCase))

  , -- Decisions are logged, with alternatives, per the tracing contract.
    expect "threading: relation choice is logged as a decision with alternatives"
      (case [ d | d <- traceDecisions (thTrace threeCommitted)
                , decKind d == "sdrt-relation" ] of
         (d : _) -> length (decAlternatives d) == length allRelations - 1
         []      -> False)
  , expect "threading: the anaphora decision names the frontier heuristic"
      (any (\d -> decKind d == "anaphora"
                    && "right frontier" `isInfixOf` decWhy d)
           (traceDecisions (thTrace threePermissive)))
  , expect "threading: and the Permissive heuristic reports what licensed it"
      (any (\d -> decKind d == "anaphora" && "licensed" `isInfixOf` decWhy d)
           (traceDecisions (thTrace threePermissive)))
  , expect "threading: a closed frontier is diagnosed, not silently dropped"
      (any (\g -> diagKind g == UnresolvedAnaphor
                    && "coordinating" `isInfixOf` diagMsg g)
           (traceDiagnostics (thTrace threeCommitted)))

  , -- The flat merge of the threaded units is the flat discourse DRS, which is
    -- what makes the two comparable at all: the graph is additional structure,
    -- not a different DRS.
    expect "threading: Permissive threading reproduces the flat discourse conditions"
      (drsConds (threadedDRS threePermissive)
         == drsConds (dscDRS (prDiscourse (runFragment thrSrc threeSent))))
  ]
  where
    threeSent = "A student arrived. Every professor smiles. She reads a book."
    genericSent = "Every student reads a book. Mary smiles. She sleeps."
    anaphoraCase = "A student arrived. She smiles."
    blockedCase = "No student sleeps. She smiles."

    threeCommitted = threadDiscourse Committed (segsOf threeSent)
    threePermissive = threadDiscourse Permissive (segsOf threeSent)
    genericLed = threadDiscourse Committed (segsOf genericSent)

-- | The segments of a text, as Stage 1 produces them.
segsOf :: String -> [Segment]
segsOf txt = segmentsOf thrSrc (runFragment thrSrc txt)

-- | Did flat threading give some anaphor an antecedent, with none left over?
flatResolved :: String -> Bool
flatResolved txt = resolvedIn (dscTrace (prDiscourse (runFragment thrSrc txt)))

-- | Same question under SDRT threading.
sdrtResolved :: Policy -> String -> Bool
sdrtResolved policy txt =
  resolvedIn (thTrace (threadDiscourse policy (segsOf txt)))

resolvedIn :: Trace -> Bool
resolvedIn tr =
  any (\d -> decKind d == "anaphora") (traceDecisions tr)
    && not (any (\g -> diagKind g == UnresolvedAnaphor) (traceDiagnostics tr))

thrSrc :: SourceId
thrSrc = SourceId "thread"

--------------------------------------------------------------------------------
-- 6. Referent identity and the shape of the licensing family
--------------------------------------------------------------------------------

-- | Section 5's graded frontier is indexed by 'Ref', so 'Ref' has to be
-- discourse-unique, otherwise the index conflates distinct individuals.
-- 'NL2Proof.DRT.Types.freshenAgainst' provides that. With a correct index the
-- family of licensed sets (one per relation labelling) is __not__ nested once
-- two edges are free: a fact about the structure, not about any weights.
--
-- (deterministic: the pre-cut mass values and the RSA cross-checks are dropped;
-- the support and licensing checks are kept.)
muChecks :: [Check]
muChecks =
  [ -- 1. Where the collision was. Segment-local DRSs still share names, which is
    -- correct -- each sentence is alpha-equivalent to itself -- and the merge is
    -- where disjointness has to be established.
    expectEq "mu: two same-shaped existentials are still locally both x"
      [Ref "x", Ref "x"]
      (map (head . accessibleRefs . segDRS) (take 2 (segsOf collide)))
  , expectEq "mu: but the merged universe now has two distinct referents"
      (2, 2)
      (let u = accessibleRefs (dscDRS (prDiscourse (runFragment thrSrc collide)))
       in (length (nub u), length u))
  , expect "mu: so the student is not the professor"
      (let d = dscDRS (prDiscourse (runFragment thrSrc collide))
           refOf p = [r | CPred q [DRef r] _ <- drsConds d, q == p]
       in refOf "student" /= refOf "professor")
  , expect "mu: and the anaphora decision does not offer a choice against itself"
      (all (\d -> decChoice d `notElem` decAlternatives d)
           [ d | d <- traceDecisions (prTrace (runFragment thrSrc collideAna))
               , decKind d == "anaphora" ])
  , expect "mu: SDRT threading freshens too, so units never share a referent"
      (let rs = concatMap (drsRefs . duDRS) (unitsInOrder (thSDRS collideThreaded))
       in length rs == length (nub rs))

  , -- 2. The payoff. With a correct index the focal family is NOT nested, so mu
    -- is not a possibility distribution and the t-norm route closes on the
    -- merits rather than being left open. Both indexings now agree, which is the
    -- concrete sense in which the fix made Ref honest.
    expect "mu: Ref-indexed focal sets are NOT nested"
      (not (nestedUnder refIndexed))
  , expect "mu: (Label, Ref)-indexed focal sets are NOT either"
      (not (nestedUnder pairIndexed))
  , expectEq "mu: and the two indexings now see the same focal family"
      (4, 4) (length (focalFamily refIndexed), length (focalFamily pairIndexed))
  , expect "mu: the crossing pair is two referents at different depths"
      (let sets = focalFamily pairIndexed
       in any (\(a, b) -> not (all (`elem` b) a) && not (all (`elem` a) b))
              [(a, b) | a <- sets, b <- sets])

  , -- 2b. And the sharpest consequence: consonance holds at ONE free edge as a
    -- theorem, because frontier(sub) = frontier(coord) + {parent} gives exactly
    -- two nested focal sets. It fails at TWO. The implementation runs at one free
    -- edge, so it sits in the only regime where the possibility reading is
    -- available -- and that regime is the truncation. The truncation and the
    -- possibility reading stand or fall together, and the truncation has to go.
    expect "mu: at one free edge the focal family is nested, always"
      (let s1 = focalAt collideFour 4 1 in length s1 == 2 && nestedSets s1)
  , expect "mu: at two free edges it is not"
      (let s2 = focalAt collideFour 4 2 in length s2 == 4 && not (nestedSets s2))
  , expect "mu: so mu is a possibility distribution only under the truncation"
      (nestedSets (focalAt collideFour 4 1)
         && not (nestedSets (focalAt collideFour 4 2)))

  , -- 2c. The truncation deletes the deeper of two candidates.
    expect "mu: and the truncation deletes the deeper of the two candidates"
      (case (stRanked (thSteps collideFourM !! 3), fullLicensingAt (thSDRS collideFourM) 4) of
         (t, Just f) -> length t == 1 && length f == 2
         _           -> False)

  , -- 3. At one free edge the grading is two-valued: every offered referent is
    -- either licensed under every relation or exactly under the subordinating
    -- ones. One global degree of freedom.
    expect "mu: at one free edge every referent is always-licensed or subordinate-only"
      (and [ rkAlways r || sort (rkLicensors r) == subordinating
           | st <- thSteps threeM, r <- stRanked st ])
  , expect "mu: and the third unit's referent is the subordinate-only kind"
      (case stRanked (thSteps threeM !! 2) of
         (r : _) -> not (rkAlways r) && sort (rkLicensors r) == subordinating
         []      -> False)

  , -- 4. The one-edge truncation is not a small perturbation: at four segments
    -- it DELETES a referent some full labelling keeps. So "Permissive deletes
    -- nothing" holds at one open edge and fails past it.
    expect "mu: at 4 segments the truncation offers nothing for K4"
      (null (stRanked (thSteps fourM !! 3)))
  , expect "mu: while the full licensing keeps the referent"
      (case fullLicensingAt (thSDRS fourM) 4 of
         Just (r : _) -> rkRef r == Ref "x"
         _            -> False)
  , expect "mu: so the truncation can delete, which is what Permissive was for"
      (null (stRanked (thSteps fourM !! 3))
         && maybe False (not . null) (fullLicensingAt (thSDRS fourM) 4))
  , expect "mu: at 3 segments truncated and full agree exactly"
      (case (stRanked (thSteps threeM !! 2), fullLicensingAt (thSDRS threeM) 3) of
         ((a : _), Just (b : _)) ->
           (rkRef a, rkAlways a, sort (rkLicensors a))
             == (rkRef b, rkAlways b, sort (rkLicensors b))
         _ -> False)
  , expect "mu: multiset multiplicity is unobservable at one free edge"
      (all ((<= 1) . length) [rkLicensors r | r <- stRanked (thSteps threeM !! 2)]
         || all (\r -> length (rkLicensors r) == length (nub (rkLicensors r)))
                (stRanked (thSteps threeM !! 2)))
  , expect "mu: fullLicensingAt refuses rather than blowing up on long discourses"
      (fullLicensingAt (thSDRS threeM) 9 == Nothing)
  ]
  where
    collide = "A student arrived. A professor walks."
    collideAna = "A student arrived. A professor walks. She smiles."
    threeSent = "A student arrived. Every professor smiles. She reads a book."
    fourSent = "A student arrived. Mary smiles. John sleeps. She reads a book."

    threeM = threadDiscourse Permissive (segsOf threeSent)
    fourM = threadDiscourse Permissive (segsOf fourSent)
    collideThreaded = threadDiscourse Permissive (segsOf collideThree)
    collideFour = "A student arrived. A professor walks. Mary smiles. She reads a book."
    collideFourM = threadDiscourse Permissive (segsOf collideFour)

    subordinating = [r | r <- allRelations, relationKind r == Subordinating]

    -- The focal family for unit @k@ with @m@ trailing edges free, on the
    -- committed topology. Same construction 'fullLicensingAt' marginalises over.
    focalAt txt k m =
      let s0 = thSDRS (threadDiscourse Committed (segsOf txt))
          units = unitsInOrder s0
          parents = [p | (_, p, _) <- sdrsEdges s0]
          committed = [r | (r, _, _) <- sdrsEdges s0]
          nEdges = k - 2
          freeIx = [nEdges - m .. nEdges - 1]
          labelsFor rho =
            [ maybe (committed !! i) id (lookup i (zip freeIx rho))
            | i <- [0 .. length committed - 1]
            ]
          built rho =
            foldl (\acc (rel, p, u) -> attach rel p u acc)
              (addRoot (head units) emptySDRS)
              (zip3 (labelsFor rho) (take nEdges parents) (take nEdges (drop 1 units)))
      in nub [ sort (accessibleOn (built rho) (rightFrontier (built rho)))
             | rho <- sequence (replicate m allRelations)
             ]

    nestedSets sets =
      and [all (`elem` b) a || all (`elem` a) b | a <- sets, b <- sets]

    -- The focal family {acc(S[rho])} over both edges of the colliding text,
    -- under the two candidate index sets.
    refIndexed = False
    pairIndexed = True

    focalFamily byPair =
      nub [ accOf byPair [a, b] | a <- allRelations, b <- allRelations ]

    nestedUnder byPair =
      let sets = focalFamily byPair
      in and [all (`elem` y) x || all (`elem` x) y | x <- sets, y <- sets]

    accOf byPair labels =
      let th = threadDiscourse Committed (segsOf collideThree)
          s0 = thSDRS th
          units = unitsInOrder s0
          parents = [p | (_, p, _) <- sdrsEdges s0]
          built =
            foldl (\acc (rel, p, u) -> attach rel p u acc)
              (addRoot (head units) emptySDRS)
              (zip3 labels (take 2 parents) (take 2 (drop 1 units)))
          fr = rightFrontier built
      in sort
           (nub   -- accessibleOn nubs, so Ref-indexing must too
              [ if byPair then show l ++ ":" ++ show r else show r
              | l <- fr
              , Just u <- [unitAt built l]
              , r <- accessibleRefs (duDRS u)
              ])

    collideThree = "A student arrived. A professor walks. Mary smiles."

--------------------------------------------------------------------------------
-- 7. How much can a stipulated cue weight move?
--------------------------------------------------------------------------------

-- | The kind-flip margin: the ratio between the best relation of each kind.
--
-- 'glueScores' is multiplicative in the cue weights, so this ratio is /exactly/ the
-- factor by which a single weight must be scaled to change which kind wins. No
-- sampling required, and no perturbation loop — the margin is the answer.
--
-- Kind is the right thing to measure rather than the relation itself, because
-- 'relationKind' is what 'rightFrontier' consults. A flip inside one kind
-- relabels an edge; a flip across kinds changes which referents are accessible.
kindMargin :: DiscourseUnit -> DiscourseUnit -> Maybe Double
kindMargin a b =
  let ps = glueScores a b
      best k = maximum (0 : [m | (r, m) <- ps, relationKind r == k])
      co = best Coordinating
      sub = best Subordinating
  in if co <= 0 || sub <= 0
       then Nothing
       else Just (max co sub / min co sub)

-- | \"Stipulated\" has to mean robust to the stipulation, and it is true of the
-- cue weights and false of the no-cue prior. These checks pin both halves.
--
-- The bar is stated rather than discovered: a kind decision driven by a cue must
-- survive a twenty-percent perturbation __with room to spare__, and @2x@ is the
-- stated threshold. If a future weight edit erodes a cue-driven margin below it,
-- this fails, which is the point.
cueSensitivityChecks :: [Check]
cueSensitivityChecks =
  [ expectEq "cue: a no-cue edge rests on the prior alone"
      (Just (noCuePrior Continuation / noCuePrior Narration))
      (kindMargin (mkUnit 0 "John loves Mary.") (mkUnit 1 "Mary smiles."))
  , expect "cue: which is a 20% margin, so the kind is not evidence-driven there"
      (case kindMargin (mkUnit 0 "John loves Mary.") (mkUnit 1 "Mary smiles.") of
         Just m  -> m < 1.5
         Nothing -> False)
  , expect "cue: no cue fires on that edge, which is why"
      (null (detectCues (mkUnit 0 "John loves Mary.") (mkUnit 1 "Mary smiles.")))

  , expect "cue: a generic-then-specific edge is robust to 20%"
      (atLeast 2
         (kindMargin (mkUnit 0 "Every student reads a book.")
            (mkUnit 1 "Mary smiles.")))
  , expect "cue: and so is a shared-predicate edge"
      (atLeast 2
         (kindMargin (mkUnit 0 "A student arrived.")
            (mkUnit 1 "A student arrived.")))
  , expect "cue: and a new-referent edge"
      (atLeast 2
         (kindMargin (mkUnit 0 "A student arrived.")
            (mkUnit 1 "A professor walks.")))
  , expect "cue: so the two populations differ by at least 1.6x in robustness"
      (case ( kindMargin (mkUnit 0 "John loves Mary.") (mkUnit 1 "Mary smiles.")
            , kindMargin (mkUnit 0 "Every student reads a book.") (mkUnit 1 "Mary smiles.")
            ) of
         (Just weak, Just strong) -> strong / weak >= 1.6
         _                        -> False)
  ]
  where
    atLeast t = maybe False (>= t)

--------------------------------------------------------------------------------
-- 8. Scope permutation must not move the anaphora answer
--------------------------------------------------------------------------------

-- | The integration that had never been made, made as a test.
--
-- 'scopeAlternatives' produces object-wide readings, and nothing anywhere lowered
-- one into a DRS, so the anaphora layer had never been handed a term in which the
-- object nests outside the subject. That mattered, because the old ordering rule
-- was @reverse . accessibleRefs@: 'NL2Proof.DRT.Types.addRef' conses, so nesting
-- decides where a referent lands in the universe, and under an object-wide
-- reading a following pronoun would have resolved to the __subject__.
--
-- Scope is a fact about quantifier nesting. It moves no word in the sentence, so
-- the two readings have to agree about recency, and
-- 'NL2Proof.DRT.Types.recencyOrdered' makes them agree by reading spans.
--
-- Note what these checks do /not/ claim: that either reading is the right one.
-- Choosing between them is ranking's job. The claim is only that the anaphora
-- answer is stable across a choice that has nothing to do with anaphora.
scopeRecencyChecks :: [Check]
scopeRecencyChecks =
  case (prSentences (runFragment recSrc twoIndefinites), pronounDRS) of
    ([r], Just pron)
      | Just form <- srForm r ->
          let prov = sentenceProv recSrc r
              idx = buildProvIndex fragmentLexicon prov
              boxes = [toDRS idx prov t | t <- scopeAlternatives form]
              wordFor d ref = maybe "?" provSurface (lookup ref (drsUniverse d))
              universeOrder d = map show (accessibleRefs d)
              byRecency d = map (wordFor d) (recencyOrdered d)
              oldRule d = map (wordFor d) (reverse (accessibleRefs d))
              resolvedTo d =
                [ wordFor d (Ref (decChoice dec))
                | dec <- traceDecisions (snd (resolveAnaphora d pron prov))
                , decKind dec == "anaphora"
                ]
          in [ expectEq "scope-recency: the sentence has two scope readings" 2
                 (length boxes)
             , expect "scope-recency: whose universes really are ordered differently"
                 (length (nub (map universeOrder boxes)) == 2)
             , expectEq "scope-recency: recency is the same under both" 1
                 (length (nub (map byRecency boxes)))
             , expectEq "scope-recency: and it is the object, in both"
                 [["book", "student"]]
                 (nub (map byRecency boxes))
             , expectEq "scope-recency: reversing the universe would not have been"
                 2
                 (length (nub (map oldRule boxes)))
             , expectEq "scope-recency: so a following pronoun resolves the same way"
                 [["book"]]
                 (nub (map resolvedTo boxes))
             ]
    _ -> [bad "scope-recency: fixture parsed" "unexpected pipeline result"]
  where
    twoIndefinites = "A student reads a book."

    -- Sentence-local DRS for the pronoun sentence. Its universe is empty, so it
    -- needs no freshening against the context.
    pronounDRS =
      case prSentences (runFragment recSrc "It arrived.") of
        [r] -> srDRS r
        _   -> Nothing

recSrc :: SourceId
recSrc = SourceId "recency"

headMay :: [a] -> Maybe a
headMay (x : _) = Just x
headMay []      = Nothing

--------------------------------------------------------------------------------
-- Main
--------------------------------------------------------------------------------

main :: IO ()
main =
  runChecks
    "readings and discourse"
    (concat
       [ scopeChecks
       , modifierChecks
       , couplingChecks
       , sdrtChecks
       , threadingChecks
       , muChecks
       , cueSensitivityChecks
       , scopeRecencyChecks
       ])
