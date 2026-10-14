-- | Independent acceptance contract for restricted quantified-pronoun relatives.
-- Run: runghc -isrc -itest test/FusedRelativeProposalSpec.hs
-- No corpus/model load. These authored adjective controls isolate quantifier
-- restriction from nominal copulas. Something remains separately deferred.
-- Before the general composition-feature repair, three matrix-negation checks
-- deliberately remain red; do not omit them to admit the dependent candidate.
module Main (main) where

import qualified Data.Set as Set
import Data.List (isPrefixOf)
import System.Environment (getArgs)
import Harness
import NL2Proof.DRT.Canonical
import NL2Proof.Pipeline
import NL2Proof.Provenance
import NL2Proof.Semantics.CCGSem
import NL2Proof.Semantics.Lambda
import NL2Proof.Syntax.CCGBank (CCat, parseCCGCat, eraseFeatures)
import NL2Proof.Syntax.CCGRules (Combinator(..), allCombinators)
import NL2Proof.Syntax.CCGParse (Rules(..))
import NL2Proof.Syntax.CCGSemParse
import NL2Proof.Syntax.CCGSupertag (buildPOSModel, buildTagModel)
import NL2Proof.Syntax.Tokenize (casedTokens)
import NL2Proof.Verify.ClaimKind (claimCond)
import NL2Proof.Verify.Reported (splitClaims)

cc :: String -> CCat
cc = either error id . parseCCGCat
mini :: SemModel
mini = miniWith "NP" "(NP\\NP)/(S[dcl]\\NP)"

miniWith :: String -> String -> SemModel
miniWith headTag relativeTag = (defaultSemModel tags poses rules Set.empty)
  { smAlpha = 0, smSeenRules = False }
  where
    entries = [("everything",headTag,"NN"),("something","NP","NN")
      ,("someone",headTag,"NN"),("Every","NP[nb]/N","DT"),("cat","N","NN")
      ,("that",relativeTag,"WDT")
      ,("who",relativeTag,"WP")
      ,("is","(S[dcl]\\NP)/(S[adj]\\NP)","VBZ")
      ,("red","S[adj]\\NP","JJ"),("blue","S[adj]\\NP","JJ")
      ,("big","S[adj]\\NP","JJ"),("cold","S[adj]\\NP","JJ")
      ,("not","(S\\NP)\\(S\\NP)","RB")
      ,("and","conj","CC"),("or","conj","CC"),(".",".",".")]
    tags = buildTagModel [(w,cc c) | (w,c,_) <- entries]
    poses = buildPOSModel [(w,p) | (w,_,p) <- entries]
    rules = Rules [(cc "N",cc "NP")] []

sentence :: String -> SentenceResult
sentence text = case prSentences (runPipelineWith (CCGBankParser mini)
                         (SourceId "fused-relative-proposal") text) of
  [s] -> s
  _ -> error "expected one sentence"

atom :: String -> CanonCond
atom name = CanPred name [CRefT (CRef 0)]
red, blue, big, cold, person, catAtom :: CanonCond
red=atom "red"; blue=atom "blue"; big=atom "big"; cold=atom "cold"
person=atom "person"; catAtom=atom "cat"
neg :: CanonCond -> CanonCond
neg p = CanNot (Canonical [] [p])
alt :: CanonCond -> CanonCond -> CanonCond
alt p q = CanOr (Canonical [] [p]) (Canonical [] [q])
rule :: [CanonCond] -> [CanonCond] -> CanonCond
rule lhs rhs = CanImp (Canonical [CRef 0] lhs) (Canonical [] rhs)

-- Each row supplies its own Asserted/Embedded table; no claim splitter computes
-- expected allocation. Universal restriction OR binds r0 outside both branches.
data Case = Case String Canonical [CanonCond] [CanonCond]
cases :: [Case]
cases =
 [ universal "Everything that is red is big." [red] [big] [red,big]
 , universal "Everything that is red or blue is big and cold."
     [alt red blue] [big,cold] [alt red blue,red,blue,big,cold]
 , universal "Everything that is not red is big."
     [neg red] [big] [neg red,red,big]
 , existential "Something that is red is big." [red,big] [red,big] []
 , existential "Something that is red or blue is cold."
     [alt red blue,cold] [alt red blue,cold] [red,blue]
 , existential "Something that is red is not big."
     [red,neg big] [red,neg big] [big]
 , existential "Someone who is red is big."
     [person,red,big] [person,red,big] []
 , existential "Someone who is red and blue is cold."
     [person,red,blue,cold] [person,red,blue,cold] []
 , existential "Someone who is red is not big."
     [person,red,neg big] [person,red,neg big] [big]
 , universal "Everything is red." [] [red] [red]
 , universal "Everything is red and blue." [] [red,blue] [red,blue]
 , universal "Everything is not red." [] [neg red] [neg red,red]
 ]
  where
    universal text lhs rhs embedded =
      let whole=rule lhs rhs in Case text (Canonical [] [whole]) [whole] embedded
    existential text conditions asserted embedded =
      Case text (Canonical [CRef 0] conditions) asserted embedded

checkCase :: Case -> [Check]
checkCase (Case text intended asserted embedded) =
 let s=sentence text
     claimsOK = case srDRS s of
       Just drs -> let (as,rs,ps,es)=splitClaims drs
                  in map (claimCond . fst) as == asserted
                     && map claimCond es == embedded && null rs && null ps
       _ -> False
 in [expectEq ("selected scoped DRS: "++text) (Just intended)
       (canonicalize <$> srDRS s)
    ,expect ("independent claim status: "++text) claimsOK
    ,expect ("all returned readings retain the scoped DRS: "++text)
       (not (null (srReadings s))
        && all ((==Just intended) . fmap canonicalize . rrDRS) (srReadings s))]

main :: IO ()
main = do
  args <- getArgs
  if args == ["--deferred-something"]
    then runChecks "DEFERRED Something domain policy (not implementation gate)"
      (concatMap checkCase [c | c@(Case text _ _ _) <- cases, "Something " `isPrefixOf` text])
    else runChecks "fused-relative Everything/Someone"
      (concatMap checkCase [c | c@(Case text _ _ _) <- cases, not ("Something " `isPrefixOf` text)]
       ++ boundaryChecks ++ certificateChecks)

boundaryChecks :: [Check]
boundaryChecks =
  [expect "everything must be reserved, not an open-class predicate"
      (isClosedClass "everything")
  ,expectEq "existing determiner+noun relative retains restriction scope"
      (Just (Canonical [] [rule [catAtom,red] [big]]))
      (canonicalize <$> srDRS (sentence "Every cat that is red is big."))
  ,expect "fused head cannot consume an arbitrary noun as relative restriction"
      (null (srReadings (sentence "Everything cat is red.")))
  ,expect "relative property cannot stand as an unlicensed bare subject"
      (null (srReadings (sentence "That is red is big.")))]
  ++ [expect ("pending obligations reject: " ++ label) (rejects model text)
     | (label,model,text) <- negativeCases]
  ++ [expect ("completed relative retains scope with aggressive unary search: " ++ text)
       (case prSentences (runPipelineWith (CCGBankParser raised)
                           (SourceId "fused-raised-positive") text) of
          [s] -> not (null (srReadings s))
                 && all ((==Just intended) . fmap canonicalize . rrDRS) (srReadings s)
          _ -> False)
     | Case text intended _ _ <- take 1 cases]
  ++ [expect "retained fused roots do not compose pending lexical head/relativizer"
       (let roots = spRoots (semParse raised (SourceId "fused-composition-positive")
                              (casedTokens 0 "Everything that is red is big."))
        in not (null roots) && all (noEarlyComposition . ssProv) roots)]

-- A limited public provenance check, not a substitute for certificate-state
-- transition tests. It examines only the unambiguous fused positive above;
-- ordinary noun relatives elsewhere may compose before application.
noEarlyComposition :: Prov -> Bool
noEarlyComposition (ProvRule (RuleName comb) children)
  | comb `elem` ["FwdComp","FwdXComp","BwdComp","BwdXComp"]
  , any pendingLexical children = False
  | otherwise = all noEarlyComposition children
noEarlyComposition _ = True

pendingLexical :: Prov -> Bool
pendingLexical (ProvLex _ _ word) = word `elem` ["Everything","everything","that"]
pendingLexical _ = False

-- These external chart controls are deliberately adversarial: invented offered
-- categories are INPUT TO THE TEST dictionary, never additions to production.
-- They cannot replace direct transition/packing-key unit tests once source roles
-- exist. Rejections alone do not show that valid roots remain complete.
raised :: SemModel
raised = mini { smTypeRaise = True, smUnaryPenalty = -1
  , smRules = Rules
      [(cc "N",cc "NP")
      ,(cc "N",cc "S/(S\\N)")
      ,(cc "NP/N",cc "S/(S\\(NP/N))")
      ,(cc "N/(S[dcl]\\NP)",cc "S/(S\\(N/(S[dcl]\\NP)))")
      ,(cc "NP",cc "S/(S\\NP)")] [] }

rejects :: SemModel -> String -> Bool
rejects model text = null (spRoots (semParse model
                           (SourceId "fused-pending-boundary") (casedTokens 0 text)))

negativeCases :: [(String,SemModel,String)]
negativeCases =
 [("ordinary noun cannot discharge head",mini,"Everything cat is red.")
 ,("unary/raising cannot discharge ordinary noun as certified property",raised,
     "Everything cat is red.")
 ,("unary cannot promote orphan relative property",raised,"That is red is big.")
 ,("coordinator cannot merge pending relative operators",mini,
     "Everything that and who is red is big.")
 ,("mixed noun/property coordination is not a relative certificate",mini,
     "Everything cat and that is red is big.")
 ,("forged internal head tag is not an offered ordinary NP origin",
     miniWith "NP/N" "(NP\\NP)/(S[dcl]\\NP)",
     "Everything that is red is big.")
 ,("forged property-relative tag is not source-relative evidence",
     miniWith "NP" "N/(S[dcl]\\NP)",
     "Everything that is red is big.")
 ,("composition cannot hide an orphan relative property",raised,
     "That is red and blue is big.")]

-- Exercise the ACTUAL production transition, unary/root and packing functions.
-- Independent well-typed signs make illicit paths possible without relying on
-- the category chart to prune them accidentally.
certificate :: FusedCertificate
certificate = FusedCertificate (SourceId "certificate-control") 0 1
  (Span 0 10) (Span 11 15) "Everything" "that"
  (cc "NP") (cc "(NP\\NP)/(S[dcl]\\NP)")

termOf :: LexItem -> Term
termOf (LexTerm term _ _) = term
termOf _ = error "expected lexical meaning"

headSign, relativeSign, vpSign, propertySign :: SSign
headSign = plainSign (cc "NP/N") (termOf headEntry)
  (ProvLex (fcSource certificate) (fcHeadSpan certificate) "Everything")
  (FusedHead certificate)
  where Just (headEntry,_) = restrictedPronounEntries "everything"
relativeSign = plainSign (cc "N/(S[dcl]\\NP)") (termOf relativeEntry)
  (ProvLex (fcSource certificate) (fcRelativeSpan certificate) "that")
  (FusedRelOp certificate)
  where Just (_,relativeEntry) = restrictedPronounEntries "everything"
vpSign = plainSign (cc "S[dcl]\\NP")
  (Lam "Q" tyGQ (App (Var "Q") (pred1 "red")))
  (provRule "FwdApp" [ProvLex (fcSource certificate) (Span 16 18) "is",
                       ProvLex (fcSource certificate) (Span 19 22) "red"]) FusedPlain
propertySign = plainSign (cc "N")
  (normalize (App (ssSem relativeSign) (ssSem vpSign)))
  (provRule "FwdApp" [ssProv relativeSign,ssProv vpSign]) (FusedProperty certificate)

plainSign :: CCat -> Term -> Prov -> FusedRole -> SSign
plainSign category meaning provenance role = SSign
  { ssCat=category,ssSem=meaning,ssProv=provenance,ssScore=0
  , ssCoord=Nothing,ssStructural=Nothing,ssOpenConditional=False
  , ssConditionalRaised=False,ssFused=role,ssNotes=[] }

certificateChecks :: [Check]
certificateChecks =
 [expectEq "standalone Someone retains person sortal"
    (Just (Canonical [CRef 0] [person,red]))
    (canonicalize <$> srDRS (sentence "Someone is red."))
 ,expectEq "deferred Something retains existing standalone thing sortal"
    (Just (Canonical [CRef 0] [atom "thing",red]))
    (canonicalize <$> srDRS (sentence "Something is red."))
 ,expect "deferred Something has no paired restricted entry"
    (restrictedPronounEntries "something" == Nothing)
 ,expectEq "actual RelOp application certifies the property"
    (Just (FusedProperty certificate))
    (fusedTransition FwdApp (cc "N") relativeSign vpSign)
 ,expectEq "actual equal-occurrence head/property application discharges"
    (Just FusedPlain) (fusedTransition FwdApp (cc "NP") headSign propertySign)
 ,expect "ordinary N cannot counterfeit a certified property"
    (fusedTransition FwdApp (cc "NP") headSign
      (propertySign {ssFused=FusedPlain}) == Nothing)
 ,expect "different occurrence cannot discharge a head"
    (fusedTransition FwdApp (cc "NP") headSign
      (propertySign {ssFused=FusedProperty other}) == Nothing)
 ,expect "foreign-source VP cannot acquire this relative certificate"
    (fusedTransition FwdApp (cc "N") relativeSign
      (vpSign {ssProv=ProvLex (SourceId "foreign") (Span 16 22) "is red"}) == Nothing)
 ,expect "a raised lexical relativizer is not an original relative leaf"
    (fusedTransition FwdApp (cc "N")
      (relativeSign {ssProv=provRule "unary raised" [ssProv relativeSign]}) vpSign == Nothing)
 ,expect "a copied property without original relative application is rejected"
    (fusedTransition FwdApp (cc "NP") headSign
      (propertySign {ssProv=ssProv vpSign}) == Nothing)
 ,expect "pending marker cannot be coordinated even with correct category"
    (fusedTransition FwdApp (cc "N") relativeSign
      (vpSign {ssCoord=Just "and"}) == Nothing)
 ,expect "source category mismatch cannot mint a valid certificate"
    (fusedTransition FwdApp (cc "N")
      (relativeSign {ssFused=FusedRelOp (certificate {fcRelativeCategory=cc "N/(S[dcl]\\NP)"})})
      vpSign == Nothing)
 ,expect "actual packing retains Plain and distinct occurrence certificates"
    (let xs=packCell 10 [propertySign,propertySign {ssScore=2},
             propertySign {ssFused=FusedPlain,ssScore=100},
             propertySign {ssFused=FusedProperty other,ssScore=200}]
     in length xs==3 && any (\x -> ssFused x==FusedProperty certificate && ssScore x==2) xs)
 ,expect "actual packing distinguishes every pending role at same term/category"
    (length (packCell 10 [propertySign {ssFused=role} | role <- roles]) == length roles)
 ,expect "source-seen-pair mapping reaches valid fused root without internal pair evidence"
    (scopedResult seenModel == Just (Canonical [] [rule [red] [big]]))
 ,expect "missing source relative/body pair does not inherit a global bypass"
    (scopedResult (seenModel {smSeen=Set.delete relPair (smSeen seenModel)}) == Nothing)
 ,expect "missing source head/modifier pair does not inherit a global bypass"
    (scopedResult (seenModel {smSeen=Set.delete headPair (smSeen seenModel)}) == Nothing)
 ] ++
 [expect ("pending unary/root rejection for "++show role)
    (let sign=propertySign {ssFused=role}
     in not (fusedUnaryAllowed sign) && not (fusedRootAllowed sign))
 | role <- tail roles] ++
 [expect ("pending transition rejects "++show comb++" / "++show (ssFused l,ssFused r))
    (fusedTransition comb out l r == Nothing)
 | comb <- allCombinators
 , (l,r,out) <- [(relativeSign,vpSign,cc "N"),(headSign,propertySign,cc "NP"),
                 (propertySign,vpSign,cc "S[dcl]")]
 , comb /= FwdApp || ssFused l == FusedProperty certificate]
 where
   other=certificate {fcHeadIndex=3,fcRelativeIndex=4}
   roles=[FusedPlain,FusedHead certificate,FusedRelOp certificate,FusedProperty certificate]
   pair a b=(eraseFeatures (cc a),eraseFeatures (cc b))
   relPair=pair "(NP\\NP)/(S[dcl]\\NP)" "S[dcl]\\NP"
   headPair=pair "NP" "NP\\NP"
   seenModel=mini {smSeenRules=True,smSeen=Set.fromList
     [relPair,headPair,pair "(S[dcl]\\NP)/(S[adj]\\NP)" "S[adj]\\NP",
      pair "NP" "S[dcl]\\NP",pair "S[dcl]\\NP" ".",pair "S[dcl]" "."]}
   scopedResult model=case prSentences (runPipelineWith (CCGBankParser model)
                 (SourceId "fused-source-pairs") "Everything that is red is big.") of
     [s] -> canonicalize <$> srDRS s
     _ -> Nothing
