{-# LANGUAGE DataKinds #-}

-- | Intensional types and attitude reports (Ty2, world-indexed twins):
-- propositions as @\\w. P_w@, attitude verbs as relations to them, reported
-- content kept out of the asserted claims (with source chains and the polarity
-- rule), factive presupposition, the fail-safe for unlisted reporting verbs,
-- fronted reports, opacity from contingent co-reference, adequacy of the
-- context-relative interpretation, and the claim-kind guard.
--
-- Both front ends: the CCGbank parser on a miniature tag dictionary (no
-- licensed data, as in the ccgsem suite) and the hand lexicon extended with
-- 'attitudeLexicon'. Terms are compared with 'alphaEq'.
module Main (main) where

import Data.Maybe (mapMaybe)
import qualified Data.Set as Set

import Harness
import NL2Proof.DRT.Build (Discourse(..))
import NL2Proof.DRT.Canonical
import NL2Proof.DRT.Types
import NL2Proof.Fragment (FragmentCase(..), fragmentCases)
import NL2Proof.Genealogy
import NL2Proof.Pipeline
import NL2Proof.Provenance
import NL2Proof.Semantics.CCGSem
import NL2Proof.Semantics.Intensional
import NL2Proof.Semantics.Lambda
import NL2Proof.Syntax.CCGBank (CCat, ccatToTy, parseCCGCat)
import NL2Proof.Syntax.CCGParse (Rules(..))
import NL2Proof.Syntax.CCGSemParse
import NL2Proof.Syntax.CCGSupertag (buildPOSModel, buildTagModel)
import NL2Proof.Syntax.Category
import NL2Proof.Syntax.Lexicon (attitudeLexicon, fragmentLexicon)
import NL2Proof.Trace
import NL2Proof.Verify.ClaimKind
import NL2Proof.Verify.Claims
import NL2Proof.Verify.Oracle
import NL2Proof.Verify.Reported

main :: IO ()
main = runChecks "intensional"
  (typingChecks ++ workedChecks ++ nestingChecks ++ negationChecks ++ factiveChecks
   ++ toldChecks ++ failSafeChecks ++ accessibilityChecks ++ opacityChecks
   ++ adequacyChecks ++ guardChecks ++ handChecks)

--------------------------------------------------------------------------------
-- Fixtures
--------------------------------------------------------------------------------

cc :: String -> CCat
cc s = either error id (parseCCGCat s)

mini :: SemModel
mini = (defaultSemModel tm pm rs Set.empty) { smAlpha = 0, smSeenRules = False }
  where
    obs =
      [ ("the", "NP[nb]/N"), ("a", "NP[nb]/N"), ("A", "NP[nb]/N")
      , ("cat", "N"), ("dog", "N")
      , ("is", "(S[dcl]\\NP)/(S[adj]\\NP)")
      , ("red", "S[adj]\\NP"), ("big", "S[adj]\\NP"), ("dangerous", "S[adj]\\NP")
      , ("not", "(S\\NP)\\(S\\NP)"), ("not", "(S[adj]\\NP)/(S[adj]\\NP)")
      , ("did", "(S[dcl]\\NP)/(S[b]\\NP)")
      , ("likes", "(S[dcl]\\NP)/NP")
      , ("If", "(S/S)/S[dcl]"), ("then", "S/S"), ("something", "NP"), ("it", "NP")
      , ("that", "S[em]/S[dcl]")
      , ("said", "(S[dcl]\\NP)/S[em]"), ("said", "(S[dcl]\\NP)/S[dcl]")
      , ("said", "(S[dcl]\\S[dcl])\\NP"), ("said", "(S[dcl]\\S[dcl])/NP")
      , ("say", "(S[b]\\NP)/S[em]")
      , ("believes", "(S[dcl]\\NP)/S[em]")
      , ("knows", "(S[dcl]\\NP)/S[em]"), ("know", "(S[b]\\NP)/S[em]")
      , ("told", "((S[dcl]\\NP)/S[em])/NP")
      , ("noted", "(S[dcl]\\NP)/S[em]"), ("announced", "(S[dcl]\\NP)/S[dcl]")
      , ("Bob", "N"), ("Alice", "N"), ("Ames", "N")
      , (",", ","), (".", ".")
      ]
    names = ["Bob", "Alice", "Ames"]
    tm = buildTagModel [ (w, cc c) | (w, c) <- obs ]
    pm = buildPOSModel [ (w, if w `elem` names then "NNP" else "XX") | (w, _) <- obs ]
    rs = Rules { rUnary = [(cc "N", cc "NP")], rBinTC = [] }

ccg :: ParserChoice
ccg = CCGBankParser mini

hand :: ParserChoice
hand = HandLexicon attitudeLexicon

runText :: ParserChoice -> String -> PipelineResult
runText p = runPipelineWith p (SourceId "t")

run1 :: ParserChoice -> String -> SentenceResult
run1 p t = case prSentences (runText p t) of
  [r] -> r
  rs  -> error ("expected one sentence, got " ++ show (length rs))

formOf :: ParserChoice -> String -> Maybe Term
formOf p = srForm . run1 p

drsOf :: ParserChoice -> String -> DRS
drsOf p t = maybe emptyDRS id (srDRS (run1 p t))

-- | The claim table of a whole text (its discourse DRS).
tableOf :: ParserChoice -> String -> ClaimTable
tableOf p t = claimsOfDRS "test" (dscDRS (prDiscourse (runText p t)))

factClaims :: ClaimTable -> [CanonCond]
factClaims = map factClaim . ctFacts

reportedClaims :: ClaimTable -> [CanonCond]
reportedClaims = map reportedContent . ctReported

presupposedClaims :: ClaimTable -> [CanonCond]
presupposedClaims = map (claimCond . presupposedClaim') . ctPresupposed

chains :: ClaimTable -> [(CanonCond, [Attribution])]
chains ct = [ (reportedContent r, reportedChain r) | r <- ctReported ct ]

decisionKinds :: SentenceResult -> [String]
decisionKinds = map decKind . traceDecisions . srTrace

expectForm :: String -> ParserChoice -> String -> Term -> Check
expectForm name p text want = case formOf p text of
  Just got | alphaEq got want -> ok name
           | otherwise -> bad name ("got " ++ pretty got ++ ", want " ++ pretty want)
  Nothing -> bad name ("no form: " ++ show (map diagMsg (traceDiagnostics (srTrace (run1 p text)))))

x_ :: Term
x_ = Var "x"

-- | The twin @c_s w@.
tw :: String -> Ty -> Term -> Term
tw c ty = App (Con (c ++ "_s") (TyS ~> ty))

w_ :: Int -> Term
w_ = Var . worldVar

-- | @\\wn. body@
lamW :: Int -> Term -> Term
lamW n = Lam (worldVar n) TyS

-- | @red(the cat)@ at world @w@: @red_s w (iota (\\x. cat_s w x))@.
redCatAt :: Term -> Term
redCatAt w = App (tw "red" tyPred1 w) (iota (Lam "x" TyE (App (tw "cat" tyPred1 w) x_)))

redCat :: Term
redCat = App (pred1 "red") (iota (Lam "x" TyE (App (pred1 "cat") x_)))

att :: String -> Term -> Term -> Term
att v holder k = apply (Con v tyAttRel) [holder, k]

bob, alice :: Term
bob = entity "Bob"
alice = entity "Alice"

pc :: String -> [String] -> CanonCond
pc p as = CanPred p (map CConstT as)

box :: [CanonCond] -> Canonical
box = Canonical []

topConds :: DRS -> [CanonCond]
topConds = canonConds . canonicalize

attr :: String -> [String] -> Bool -> Attribution
attr v hs = Attribution v (map CConstT hs)

--------------------------------------------------------------------------------
-- 1. Typing
--------------------------------------------------------------------------------

typingChecks :: [Check]
typingChecks =
  [ expectEq "catTy S[em] is s->t" tyProp (catTy (Feature "em" S))
  , expectEq "semTy S[em] is s->t" (Just tyProp) (semTy (cc "S[em]"))
  , expectEq "the ingestion classifier agrees: ccatToTy S[em] is s->t" (Right tyProp) (ccatToTy (cc "S[em]"))
  , expectEq "S[dcl] stays t (catTy is keyed on category; only S[em] changes)" (Just TyT) (semTy (cc "S[dcl]"))
  , expectEq "'that' declares (s->t) -> s->t" (Right (tyProp ~> tyProp)) (typeOf [] complementizer)
  , expect "...which lifts its category type t -> s->t (a declared intensional parameter)"
      (case semTy (cc "S[em]/S[dcl]") of
         Just ty -> (tyProp ~> tyProp) `liftsTo` ty && (tyProp ~> tyProp) /= ty
         Nothing -> False)
  , expectEq "attitude verb (S[dcl]\\NP)/S[em]: (s->t) -> GQ -> t, equal to its category type"
      (fmap Right (semTy (cc "(S[dcl]\\NP)/S[em]"))) (Just (typeOf [] (attitudeVerb "say")))
  , expect "bare-complement verb (S[dcl]\\NP)/S[dcl]: same term, a declared lift of t -> GQ -> t"
      (case (typeOf [] (attitudeVerb "say"), semTy (cc "(S[dcl]\\NP)/S[dcl]")) of
         (Right d, Just e) -> d `liftsTo` e && d /= e
         _ -> False)
  , expectEq "told ((S[dcl]\\NP)/S[em])/NP: GQ -> (s->t) -> GQ -> t"
      (fmap Right (semTy (cc "((S[dcl]\\NP)/S[em])/NP"))) (Just (typeOf [] (addresseeVerb "tell")))
  , expect "every intensional and attitude entry inhabits (a declared lift of) its category type"
      (and [ either (const False) (`liftsTo` ty) (typeOf [] t)
           | (c, LexTerm t _ _) <-
               [ (c, it) | (_, c, it) <- intensionalTable ]
                 ++ [ (cc c, it) | (w, c) <- attitudeCats, Just it <- [attitudeEntry w (cc c)] ]
           , Just ty <- [semTy c] ])
  , expect "extensional categories keep their types (no s anywhere)"
      (and [ semTy (cc c) == Just t
           | (c, t) <- [ ("S[dcl]", TyT), ("S", TyT), ("NP", tyGQ), ("N", tyPred1)
                       , ("S[adj]\\NP", tyGQ ~> TyT), ("(S[dcl]\\NP)/NP", tyGQ ~> tyGQ ~> TyT)
                       , ("(S/S)/S[dcl]", TyT ~> TyT ~> TyT), ("NP[nb]/N", tyPred1 ~> tyGQ)
                       , ("(S[dcl]\\NP)/(S[b]\\NP)", (tyGQ ~> TyT) ~> tyGQ ~> TyT) ] ])
  , expect "the hand fragment's categories are unchanged in type"
      (catTy ((S :\ NP) :/ NP) == tyGQ ~> tyGQ ~> TyT && catTy S == TyT)
  , expectForm "extensional sentence unchanged (CCGbank path)" ccg "the cat is red." redCat
  , expectEq "extensional sentence unchanged (hand path): attitude lexicon = fragment lexicon"
      (fmap canonical (formOf (HandLexicon fragmentLexicon) "John loves Mary"))
      (fmap canonical (formOf hand "John loves Mary"))
  , expect "an extensional meaning has no world in it"
      (maybe False (not . isIntensionalTerm) (formOf ccg "the cat is red."))
  , expect "a bare that-clause is not a sentence root (a proposition asserts nothing)"
      (null (srParses (run1 ccg "that the cat is red.")))
  ]
  where
    attitudeCats =
      [ ("said", "(S[dcl]\\NP)/S[em]"), ("said", "(S[dcl]\\NP)/S[dcl]"), ("say", "(S[b]\\NP)/S[em]")
      , ("told", "((S[dcl]\\NP)/S[em])/NP"), ("told", "((S[dcl]\\NP)/S[dcl])/NP")
      , ("said", "(S[dcl]\\S[dcl])\\NP"), ("said", "(S[dcl]\\S[dcl])/NP")
      , ("told", "((S[dcl]\\S[dcl])\\NP)/NP"), ("knows", "(S[dcl]\\NP)/S[em]")
      , ("noted", "(S[dcl]\\NP)/S[em]"), ("added", "(S[dcl]\\S[dcl])\\NP") ]

--------------------------------------------------------------------------------
-- 2. The worked example
--------------------------------------------------------------------------------

saidText :: String
saidText = "Bob said that the cat is red."

workedChecks :: [Check]
workedChecks =
  [ expectForm "form: say(Bob, \\w1. red_s(w1, iota(\\x. cat_s(w1, x))))" ccg saidText
      (att "say" bob (lamW 1 (redCatAt (w_ 1))))
  , expect "the proposition's body really contains its world variable"
      (case formOf ccg saidText of
         Just (App _ (Lam w TyS body)) -> w `elem` freeVars body
         _ -> False)
  , expectEq "DRS: say(Bob, K) with K = [red(cat)], the _s w1 indices stripped"
      [CanAtt "say" [CConstT "Bob"] (box [pc "red" ["cat"]])] (topConds (drsOf ccg saidText))
  , expect "red(cat) is not a top-level condition" (pc "red" ["cat"] `notElem` topConds (drsOf ccg saidText))
  , expectEq "the attitude itself is the one asserted claim"
      [CanAtt "say" [CConstT "Bob"] (box [pc "red" ["cat"]])] (factClaims (tableOf ccg saidText))
  , expectEq "red(cat) is a reported claim with source chain [Bob] and verb say"
      [(pc "red" ["cat"], [attr "say" ["Bob"] False])] (chains (tableOf ccg saidText))
  , expectEq "reportedSource / reportedVerb"
      [(Just (CConstT "Bob"), Just "say")]
      [ (reportedSource r, reportedVerb r) | r <- ctReported (tableOf ccg saidText) ]
  , expect "the reported claim keeps word-level provenance (the word 'red')"
      (any (\r -> any (\(_, _, w) -> w == "red") (provLeaves (reportedProv r))) (ctReported (tableOf ccg saidText)))
  , expect "the definite inside the report is logged as de dicto"
      ("definite-in-report" `elem` decisionKinds (run1 ccg saidText))
  , expectForm "bare complement: 'Bob said the cat is red' gets the same proposition"
      ccg "Bob said the cat is red." (att "say" bob (lamW 1 (redCatAt (w_ 1))))
  , expect "...logged as 'bare complement read as attitude'"
      ("bare-complement" `elem` decisionKinds (run1 ccg "Bob said the cat is red."))
  , expectForm "fronted (quote stripped): '\"The cat is red,\" Bob said'" ccg
      "the cat is red , Bob said." (att "say" bob (lamW 1 (redCatAt (w_ 1))))
  , expectForm "inverted: 'The cat is red, said Bob'" ccg
      "the cat is red , said Bob." (att "say" bob (lamW 1 (redCatAt (w_ 1))))
  , expect "...the fronted reading is logged and its content reported, not asserted"
      ("fronted-report" `elem` decisionKinds (run1 ccg "the cat is red , Bob said.")
        && reportedClaims (tableOf ccg "the cat is red , Bob said.") == [pc "red" ["cat"]]
        && pc "red" ["cat"] `notElem` factClaims (tableOf ccg "the cat is red , Bob said."))
  ]

--------------------------------------------------------------------------------
-- 3. Nesting
--------------------------------------------------------------------------------

nestedText :: String
nestedText = "Alice said that Bob believes that the cat is red."

nestingChecks :: [Check]
nestingChecks =
  [ expectForm "form: say(Alice, \\w1. believe_s(w1, Bob_s(w1), \\w2. red_s(w2, iota(\\x. cat_s(w2, x)))))"
      ccg nestedText
      (att "say" alice (lamW 1
        (apply (tw "believe" tyAttRel (w_ 1)) [tw "Bob" TyE (w_ 1), lamW 2 (redCatAt (w_ 2))])))
  , expectEq "DRS: say(Alice, [believe(Bob, [red(cat)])])"
      [CanAtt "say" [CConstT "Alice"] (box [CanAtt "believe" [CConstT "Bob"] (box [pc "red" ["cat"]])])]
      (topConds (drsOf ccg nestedText))
  , expectEq "only the outer attitude is asserted" 1 (length (factClaims (tableOf ccg nestedText)))
  , expectEq "one reported claim per level: chains [Alice] and [Alice, Bob]"
      [ (CanAtt "believe" [CConstT "Bob"] (box [pc "red" ["cat"]]), [attr "say" ["Alice"] False])
      , (pc "red" ["cat"], [attr "say" ["Alice"] False, attr "believe" ["Bob"] False]) ]
      (chains (tableOf ccg nestedText))
  , expectEq "the innermost claim's source is Alice and its verb believe"
      [(Just (CConstT "Alice"), Just "believe")]
      [ (reportedSource r, reportedVerb r) | r <- ctReported (tableOf ccg nestedText)
                                           , reportedContent r == pc "red" ["cat"] ]
  ]

--------------------------------------------------------------------------------
-- 4. Negation placement and the polarity rule
--------------------------------------------------------------------------------

negationChecks :: [Check]
negationChecks =
  [ expectForm "outside: ~say(Bob, \\w1. P_w1)" ccg "Bob did not say that the cat is red."
      (TNot (att "say" bob (lamW 1 (redCatAt (w_ 1)))))
  , expectForm "inside: say(Bob, \\w1. ~red_s(w1, ...))" ccg "Bob said that the cat is not red."
      (att "say" bob (lamW 1 (TNot (redCatAt (w_ 1)))))
  , expectEq "outside: the DRS negates the attitude condition"
      [CanNot (box [CanAtt "say" [CConstT "Bob"] (box [pc "red" ["cat"]])])]
      (topConds (drsOf ccg "Bob did not say that the cat is red."))
  , expectEq "polarity rule: no reported claim under negation"
      [] (reportedClaims (tableOf ccg "Bob did not say that the cat is red."))
  , expect "...and red(cat) is not asserted either"
      (pc "red" ["cat"] `notElem` factClaims (tableOf ccg "Bob did not say that the cat is red."))
  , expectEq "polarity rule: no reported claim under a conditional"
      [] (reportedClaims (tableOf ccg "If Bob said that the cat is red then the dog is big."))
  , expectEq "inside: the report is exactly ~red(cat) (the box's top-level condition)"
      [CanNot (box [pc "red" ["cat"]])] (reportedClaims (tableOf ccg "Bob said that the cat is not red."))
  ]

--------------------------------------------------------------------------------
-- 5. Factives
--------------------------------------------------------------------------------

knowsText :: String
knowsText = "Bob knows that the cat is red."

factiveChecks :: [Check]
factiveChecks =
  [ expectForm "form: know(Bob, \\w1. P_w1) (factivity is not in the term)" ccg knowsText
      (att "know" bob (lamW 1 (redCatAt (w_ 1))))
  , expectEq "DRS: know(Bob, K) stays, and K is hoisted as a presupposition"
      [CanAtt "know" [CConstT "Bob"] (box [pc "red" ["cat"]]), CanPresup (box [pc "red" ["cat"]])]
      (topConds (drsOf ccg knowsText))
  , expectEq "red(cat) is a presupposed claim" [pc "red" ["cat"]] (presupposedClaims (tableOf ccg knowsText))
  , expect "...not an asserted one"
      (pc "red" ["cat"] `notElem` factClaims (tableOf ccg knowsText))
  , expect "factivity and the hoisting are logged"
      (all (`elem` decisionKinds (run1 ccg knowsText)) ["factive", "presupposition"])
  , expect "the factive and non-factive lists are disjoint and complete for the brief's verbs"
      (all isFactiveVerb ["know", "realize", "regret"]
        && not (any isFactiveVerb ["say", "claim", "believe", "think", "report", "hear", "tell"]))
  , expectEq "factive under negation still presupposes: 'Bob did not know that P'"
      [pc "red" ["cat"]] (presupposedClaims (tableOf ccg "Bob did not know that the cat is red."))
  , expect "...while the knowing itself is negated"
      (case topConds (drsOf ccg "Bob did not know that the cat is red.") of
         [CanNot (Canonical [] [CanAtt "know" _ _]), CanPresup _] -> True
         _ -> False)
  , expectEq "a factive inside a report does not project out of it"
      [] (presupposedClaims (tableOf ccg "Alice said that Bob knows that the cat is red."))
  , expect "...the presupposition stays inside Alice's report (reported via [Alice])"
      ((pc "red" ["cat"], [attr "say" ["Alice"] False])
         `elem` chains (tableOf ccg "Alice said that Bob knows that the cat is red."))
  ]

--------------------------------------------------------------------------------
-- 6. told: three places
--------------------------------------------------------------------------------

toldChecks :: [Check]
toldChecks =
  [ expectForm "told: tell(Bob, Alice, \\w1. P_w1)" ccg "Bob told Alice that the cat is red."
      (apply (Con "tell" tyAttRel3) [bob, alice, lamW 1 (redCatAt (w_ 1))])
  , expectEq "told: reported with holders [Bob, Alice]"
      [(pc "red" ["cat"], [attr "tell" ["Bob", "Alice"] False])]
      (chains (tableOf ccg "Bob told Alice that the cat is red."))
  ]

--------------------------------------------------------------------------------
-- 7. The fail-safe for unlisted reporting verbs
--------------------------------------------------------------------------------

failSafeChecks :: [Check]
failSafeChecks =
  [ expectForm "unlisted 'noted' with a that-clause is a reporting verb" ccg
      "Bob noted that the cat is red." (att "noted" bob (lamW 1 (redCatAt (w_ 1))))
  , expect "...its content is reported, not asserted, and the fail-safe is logged"
      (reportedClaims (tableOf ccg "Bob noted that the cat is red.") == [pc "red" ["cat"]]
        && pc "red" ["cat"] `notElem` factClaims (tableOf ccg "Bob noted that the cat is red.")
        && "unlisted-reporting-verb" `elem` decisionKinds (run1 ccg "Bob noted that the cat is red."))
  , expect "unlisted 'announced' with a bare clause also fails toward not-asserting"
      (reportedClaims (tableOf ccg "Bob announced the cat is red.") == [pc "red" ["cat"]]
        && "unlisted-reporting-verb" `elem` decisionKinds (run1 ccg "Bob announced the cat is red."))
  , expect "unlisted fronted 'added' (CCGbank (S[dcl]\\S[dcl])\\NP) is reported too"
      (case attitudeEntry "added" (cc "(S[dcl]\\S[dcl])\\NP") of
         Just (LexTerm _ _ (Just st)) -> stKind st == "unlisted-reporting-verb"
         _ -> False)
  , expect "an unlisted verb is never read as factive"
      (presupposedClaims (tableOf ccg "Bob noted that the cat is red.") == [])
  ]

--------------------------------------------------------------------------------
-- 8. Accessibility
--------------------------------------------------------------------------------

accessibilityChecks :: [Check]
accessibilityChecks =
  [ expect "a referent introduced inside the report is not accessible outside it"
      (UnresolvedAnaphor `elem` map diagKind (traceDiagnostics (prTrace
         (runText ccg "Bob said that a cat is red. Alice likes it."))))
  , expect "...and is not in the main DRS's universe"
      (null (accessibleRefs (drsOf ccg "Bob said that a cat is red.")))
  , expect "an outer referent is accessible inside the report: 'A cat is big. Bob said that it is red.'"
      (let d = dscDRS (prDiscourse (runText ccg "A cat is big. Bob said that it is red."))
       in or [ r `elem` accessibleRefs d | CAtt "say" _ (DRS _ [CPred "red" [DRef r] _]) _ <- drsConds d ])
  ]

--------------------------------------------------------------------------------
-- 9. Opacity: contingent vs necessary co-reference (Quine's Ortcutt)
--------------------------------------------------------------------------------

opacityChecks :: [Check]
opacityChecks =
  case (formOf ccg "Ames is dangerous.", formOf ccg "Bob said that Ames is dangerous.") of
    (Just matrix, Just report) ->
      let ames = entity "Ames"
          theMayor = iota (Lam "x" TyE (App (pred1 "mayor") x_))
          contingent = Contingent ames theMayor
          necessary = Necessary ames theMayor
          dangerousAt w t = App (tw "dangerous" tyPred1 w) t
      in [ expect "the report is say(Bob, \\w1. dangerous_s(w1, Ames_s(w1)))"
             (alphaEq report (att "say" bob (lamW 1 (dangerousAt (w_ 1) (tw "Ames" TyE (w_ 1))))))
         , expect "(i) matrix: the contingent rewrite Ames -> the mayor FIRES"
             (alphaEq (leibniz contingent matrix) (App (pred1 "dangerous") theMayor))
         , expect "(ii) attitude: the same rewrite leaves the report UNCHANGED (Ames_s w1 is under a world binder)"
             (alphaEq (leibniz contingent report) report)
         , expect "(iii) control: a necessary identity, forall w. Ames_s w = iota(mayor_s w), DOES rewrite under \\w1"
             (alphaEq (leibniz necessary report)
                (att "say" bob (lamW 1 (dangerousAt (w_ 1)
                   (iota (Lam "x" TyE (App (tw "mayor" tyPred1 (w_ 1)) x_)))))))
         , expect "the necessary premise is a formula quantifying over worlds"
             (case identityPremise necessary of
                TForall _ TyS (TEq _ _) -> True
                _ -> False)
         , expect "on a conjunction, the contingent rewrite fires only in the matrix conjunct"
             (alphaEq (leibniz contingent (TAnd matrix report))
                      (TAnd (App (pred1 "dangerous") theMayor) report))
         ]
    _ -> [bad "opacity sentences parse" "no form"]

--------------------------------------------------------------------------------
-- 10. Adequacy of the context-relative interpretation
--------------------------------------------------------------------------------

-- | Interpret at @At 1@, evaluate at @w0@, read @c_s w0@ as @c@: the result
-- must be the 'Actual' meaning.
adequate :: Term -> Bool
adequate t = alphaEq (deindexWith actualWorld (subst (worldVar 1) actualWorld (meaningAt (At 1) t))) t

adequacyChecks :: [Check]
adequacyChecks =
  [ expectEq "Actual is the identity on every fragment form" []
      [ caseId c | c <- fragmentCases, f <- caseForms c, not (alphaEq (meaningAt Actual f) f) ]
  , expectEq "adequacy over the Fragment set (expected forms)" []
      [ caseId c | c <- fragmentCases, f <- caseForms c, not (adequate f) ]
  , expectEq "adequacy over the Fragment set (parsed forms)" []
      [ caseText c | c <- fragmentCases
                   , r <- prSentences (runText (HandLexicon fragmentLexicon) (caseText c))
                   , Just f <- [srForm r], not (adequate f) ]
  , expectEq "adequacy over ProofWriter-style sentences (CCGbank path)" []
      [ s | s <- pwSample, Just f <- [formOf ccg s], not (adequate f) ]
  , expectEq "...and each of those parsed" [] [ s | s <- pwSample, formOf ccg s == Nothing ]
  , expect "At 1 really re-indexes: the cat is red at w1 mentions w1"
      (maybe False (\f -> worldVar 1 `elem` freeVars (meaningAt (At 1) f)) (formOf ccg "the cat is red."))
  ]
  where
    pwSample =
      [ "the cat is red.", "the cat is not red.", "Bob likes the cat."
      , "If something is big then it is red.", "the dog is big." ]

--------------------------------------------------------------------------------
-- 11. The guard
--------------------------------------------------------------------------------

-- | An oracle that would confirm anything it is asked about.
credulous :: Oracle
credulous = Oracle "credulous" "everything" (const True) (const True)

guardChecks :: [Check]
guardChecks =
  let ct = tableOf ccg saidText
      g = genealogyOf credulous ct
      nodeClaims gen = [ nodeClaim n | Just n <- map (nodeAt gen) (nodeIds gen) ]
      both = tableOf ccg "Bob said that the cat is red. the cat is red."
  in [ expect "a report never becomes a genealogy premise, even under an oracle that confirms everything"
         (pc "red" ["cat"] `notElem` nodeClaims g)
     , expectEq "the genealogy has exactly the attitude node" 1 (length (nodeIds g))
     , expect "nor does a presupposition"
         (pc "red" ["cat"] `notElem` nodeClaims (genealogyOf credulous (tableOf ccg knowsText)))
     , expect "the legitimate path: asCandidate, then an oracle"
         (map confClaim (mapMaybe (confirm credulous . asCandidate . reportedClaim') (ctReported ct))
            == [pc "red" ["cat"]])
     , expect "asCandidate yields an unconfirmed candidate: a blind oracle confirms nothing"
         (null (mapMaybe (confirm (Oracle "blind" "nothing" (const False) (const False))
                            . asCandidate . reportedClaim') (ctReported ct)))
     , expect "when the content is also asserted, that assertion is a premise of its own"
         (pc "red" ["cat"] `elem` nodeClaims (genealogyOf credulous both))
     , expect "...and the report stays a report beside it" (reportedClaims both == [pc "red" ["cat"]])
     ]

--------------------------------------------------------------------------------
-- 12. The hand lexicon
--------------------------------------------------------------------------------

smileAt :: Term -> String -> Term
smileAt w n = App (tw "smile" tyPred1 w) (tw n TyE w)

handChecks :: [Check]
handChecks =
  [ expectForm "hand: John said that Mary smiles" hand "John said that Mary smiles"
      (att "say" (entity "john") (lamW 1 (smileAt (w_ 1) "mary")))
  , expectEq "hand: the DRS keeps the report in the attitude box"
      [CanAtt "say" [CConstT "john"] (box [pc "smile" ["mary"]])] (topConds (drsOf hand "John said that Mary smiles"))
  , expectEq "hand: reported with chain [john]"
      [(pc "smile" ["mary"], [attr "say" ["john"] False])] (chains (tableOf hand "John said that Mary smiles"))
  , expect "hand: factive 'knows' presupposes its complement and logs it"
      (presupposedClaims (tableOf hand "Mary knows that John smiles") == [pc "smile" ["john"]]
        && "presupposition" `elem` decisionKinds (run1 hand "Mary knows that John smiles"))
  , expectForm "hand: negation outside, John does not say that Mary smiles" hand
      "John does not say that Mary smiles" (TNot (att "say" (entity "john") (lamW 1 (smileAt (w_ 1) "mary"))))
  , expectEq "hand: no reported claim under negation"
      [] (reportedClaims (tableOf hand "John does not say that Mary smiles"))
  , expectEq "hand: nested, Susan said that John believes that Mary smiles"
      [ [attr "say" ["susan"] False], [attr "say" ["susan"] False, attr "believe" ["john"] False] ]
      (map snd (chains (tableOf hand "Susan said that John believes that Mary smiles")))
  , expect "hand and CCGbank paths agree on the shape of a report"
      (case (topConds (drsOf hand "John said that Mary smiles"), topConds (drsOf ccg saidText)) of
         ([CanAtt v1 [_] (Canonical [] [CanPred _ [_]])], [CanAtt v2 [_] (Canonical [] [CanPred _ [_]])]) -> v1 == v2
         _ -> False)
  ]
