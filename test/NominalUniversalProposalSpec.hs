-- Independent red acceptance controls; no corpus/model load.
-- runghc -isrc -itest test/NominalUniversalProposalSpec.hs
module Main (main) where
import qualified Data.Set as Set
import qualified Data.Map.Strict as M
import Harness
import NL2Proof.DRT.Canonical
import NL2Proof.Pipeline
import NL2Proof.Provenance
import NL2Proof.Semantics.Lambda
import NL2Proof.Syntax.CCGBank (CCat, parseCCGCat, eraseFeatures)
import NL2Proof.Syntax.CCGRules (Combinator(..), allCombinators)
import NL2Proof.Syntax.Tokenize (casedTokens)
import NL2Proof.Syntax.CCGParse (Rules(..))
import NL2Proof.Syntax.CCGSemParse
import NL2Proof.Syntax.CCGSupertag (TagModel(..), POSModel(..), buildPOSModel, buildTagModel)
import NL2Proof.Verify.ClaimKind (claimCond)
import NL2Proof.Verify.Reported (splitClaims)

mini :: SemModel
mini = (defaultSemModel tags poses (Rules [] []) Set.empty)
 { smAlpha=0, smSeenRules=False }
 where
  cc = either error id . parseCCGCat
  entries = [("every","NP[nb]/N","DT"),("each","NP[nb]/N","DT")
   ,("a","NP[nb]/N","DT"),("an","NP[nb]/N","DT")
   ,("is","(S[dcl]\\NP)/NP","VBZ"),(".",".",".")]
   ++ [(n,"N","NN") | n <- ["cat","animal","dog","mammal","artist","teacher"]]
  tags=buildTagModel [(w,cc c) | (w,c,_) <- entries]
  poses=buildPOSModel [(w,p) | (w,_,p) <- entries]

checks :: String -> String -> String -> [Check]
checks text subj predicate =
 let p name = CanPred name [CRefT (CRef 0)]
     whole = CanImp (Canonical [CRef 0] [p subj]) (Canonical [] [p predicate])
     wanted = Canonical [] [whole]
     s = case prSentences (runPipelineWith (CCGBankParser mini)
                  (SourceId "nominal-universal-independent") text) of
           [one] -> one
           _ -> error "expected one sentence"
     status = case srDRS s of
       Just d -> let (as,rs,ps,es)=splitClaims d
                 in map (claimCond . fst) as == [whole]
                   && map claimCond es == [p subj,p predicate]
                   && null rs && null ps
       _ -> False
 in [expectEq ("exact universal classification: "++text)
       (Just wanted) (canonicalize <$> srDRS s)
    ,expect ("independent Asserted/Embedded allocation: "++text) status
    ,expect ("all returned readings classify under one quantifier: "++text)
       (not (null (srReadings s)) && all
          ((==Just wanted) . fmap canonicalize . rrDRS) (srReadings s))]

main :: IO ()
main = runChecks "universal nominal independent proposal"
 (checks "Every cat is an animal." "cat" "animal"
 ++ checks "Each dog is a mammal." "dog" "mammal"
 ++ checks "Every artist is a teacher." "artist" "teacher"
 ++ transitionChecks ++ boundaryChecks ++ ordinaryChecks)


-- Mechanical evidence wrapper: all original assertions retain the v1 policy.
known p c = NominalNounOrigin p c DictionaryCommonNoun

cc :: String -> CCat
cc = either error id . parseCCGCat
cert :: NominalCertificate
cert = NominalCertificate (SourceId "nominal-transition") 2 3
 (Span 10 12) (Span 13 14) "is" "a"
 (cc "(S[dcl]\\NP)/NP") (cc "NP[nb]/N")
leaf :: Span -> String -> Prov
leaf = ProvLex (ncSource cert)
sign :: String -> Term -> Prov -> NominalRole -> SSign
sign category term origin role = SSign
 {ssCat=cc category,ssSem=term,ssProv=origin,ssScore=0
 ,ssCoord=Nothing,ssStructural=Nothing,ssOpenConditional=False
 ,ssConditionalRaised=False,ssList=Nothing,ssFused=FusedPlain
 ,ssNominal=role,ssNotes=[]}
article, noun, copula, predicateSign, pending, subjectNoun, determiner, subject, complete :: SSign
article=sign "N/N" (Lam "P" tyPred1 (Var "P")) (leaf (Span 13 14) "a") (NominalArticle cert)
noun=sign "N" (pred1 "animal") origin (NominalNoun (known origin (cc "N")))
 where origin=leaf (Span 15 21) "animal"
copula=sign "(S[dcl]\\NP)/N"
 (Lam "P" tyPred1 (Lam "Q" tyGQ (App (Var "Q") (Var "P"))))
 (leaf (Span 10 12) "is") (NominalCopula cert)
predicateSign=sign "N" (pred1 "animal")
 (provRule "FwdApp" [ssProv article,ssProv noun])
 (NominalPredicate cert (known (ssProv noun) (cc "N")))
pending=sign "S[dcl]\\NP" (normalize (App (ssSem copula) (ssSem predicateSign)))
 (provRule "FwdApp" [ssProv copula,ssProv predicateSign])
 (NominalPending cert (known (ssProv noun) (cc "N")))
subjectNoun=sign "N" (pred1 "cat") origin (NominalNoun (known origin (cc "N")))
 where origin=leaf (Span 6 9) "cat"
determiner=sign "NP[nb]/N"
 (Lam "P" tyPred1 (Lam "Q" tyPred1 (TForall "x" TyE
    (TImp (App (Var "P") (Var "x")) (App (Var "Q") (Var "x"))))))
 origin (NominalUniversalDeterminer origin (cc "NP[nb]/N"))
 where origin=leaf (Span 0 5) "Every"
subject=sign "NP[nb]" (normalize (App (ssSem determiner) (ssSem subjectNoun)))
 (provRule "FwdApp" [ssProv determiner,ssProv subjectNoun])
 (NominalUniversalSubject (ssProv determiner) (cc "NP[nb]/N") (known (ssProv subjectNoun) (cc "N")))
complete=sign "S[dcl]" (normalize (App (ssSem pending) (ssSem subject)))
 (provRule "BwdApp" [ssProv subject,ssProv pending])
 (NominalComplete cert (ssProv subject) (known (ssProv subjectNoun) (cc "N")) (known (ssProv noun) (cc "N")))

period :: SSign
period=(sign "." (Con "." TyT) (leaf (Span 21 22) ".") NominalPlain)
 {ssStructural=Just "."}
transitionChecks :: [Check]
transitionChecks =
 [expect "direct article captures lexical property" $
    nominalTransition FwdApp (cc "N") article noun == Just (ssNominal predicateSign)
 ,expect "matching copula consumes property" $
    nominalTransition FwdApp (cc "S[dcl]\\NP") copula predicateSign == Just (ssNominal pending)
 ,expect "direct overt determiner certifies subject" $
    nominalTransition FwdApp (cc "NP[nb]") determiner subjectNoun == Just (ssNominal subject)
 ,expect "direct quantified subject completes envelope" $
    nominalTransition BwdApp (cc "S[dcl]") subject pending == Just (ssNominal complete)
 ,expect "same Q without subject license cannot enter envelope" $
    nominalTransition BwdApp (cc "S[dcl]") (subject {ssNominal=NominalPlain}) pending == Nothing
 ,expect "raised subject cannot reuse direct certificate" $
    nominalTransition BwdApp (cc "S[dcl]")
      (subject {ssProv=provRule "unary" [ssProv subject]}) pending == Nothing
 ,expect "unary noun cannot reuse lexical evidence" $
    nominalTransition FwdApp (cc "N") article
      (noun {ssProv=provRule "unary" [ssProv noun]}) == Nothing
 ,expect "different occurrence cannot discharge copula" $
    nominalTransition FwdApp (cc "S[dcl]\\NP") copula
      (predicateSign {ssNominal=NominalPredicate (cert {ncCopulaIndex=7,ncArticleIndex=8})
                      (known (ssProv noun) (cc "N"))}) == Nothing
 ,expect "foreign source cannot capture property" $
    nominalTransition FwdApp (cc "N") article
      (noun {ssProv=ProvLex (SourceId "foreign") (Span 15 21) "animal"}) == Nothing
 ,expect "plain property cannot counterfeit paired predicate" $
    nominalTransition FwdApp (cc "S[dcl]\\NP") copula
      (predicateSign {ssNominal=NominalPlain}) == Nothing
 ,expect "typed category with wrong lambda type cannot capture property" $
    nominalTransition FwdApp (cc "N") article (noun {ssSem=entity "wrong"})==Nothing
 ,expect "pending conditional noun cannot capture property" $
    nominalTransition FwdApp (cc "N") article (noun {ssOpenConditional=True})==Nothing
 ,expect "pending coordinator noun cannot capture property" $
    nominalTransition FwdApp (cc "N") article (noun {ssCoord=Just "and"})==Nothing
 ,expect "structural noun cannot capture property" $
    nominalTransition FwdApp (cc "N") article (noun {ssStructural=Just ","})==Nothing
 ,expect "literal final period preserves complete obligation" $
    nominalTransition PunctRight (cc "S[dcl]") complete period==Just (ssNominal complete)
 ,expect "comma cannot release complete obligation" $
    nominalTransition PunctRight (cc "S[dcl]") complete
      (period {ssCat=cc ",",ssStructural=Just ","})==Nothing
 ,expect "completed clause accepts root only" (nominalRootAllowed complete)
 ,expect "active roles cannot enter unary" (all (not . nominalUnaryAllowed) [article,copula,predicateSign,pending,complete])
 ,expect "incomplete roles cannot enter root" (all (not . nominalRootAllowed) [article,copula,predicateSign,pending])
 ,expectEq "packing retains same meaning with different subject capability" 2
    (length (packCell 20 [subject,subject {ssNominal=NominalPlain}]))
 ,expectEq "packing retains same property with different origin" 2
    (length (packCell 20 [predicateSign,predicateSign {ssNominal=NominalPredicate
       (cert {ncSource=SourceId "other"}) (known (ssProv noun) (cc "N"))}]))
 ] ++ [expect ("pending path rejects "++show combinator)
       (nominalTransition combinator (cc "S[dcl]") subject pending==Nothing)
       | combinator <- allCombinators, combinator/=BwdApp]
   ++ [expect ("complete embedding rejects "++show combinator)
       (nominalTransition combinator (cc "S[dcl]") complete subject==Nothing)
       | combinator <- allCombinators]

roots :: SemModel -> String -> [SSign]
roots model text=spRoots (semParse model (SourceId "nominal-boundary") (casedTokens 0 text))
withPOS :: String -> [String] -> SemModel
withPOS word ps = mini {smPOS=POSModel (M.insert word (M.fromList [(p,1)|p<-ps]) original)}
 where POSModel original=smPOS mini
boundaryChecks :: [Check]
boundaryChecks =
 [expect "name conflict in subject noun supplies no new route" (null (roots (withPOS "cat" ["NN","NNP"]) "Every cat is an animal."))
 ,expect "adjective conflict in predicate supplies no new route" (null (roots (withPOS "animal" ["NN","JJ"]) "Every cat is an animal."))
 ,expect "unknown POS noun supplies no new route" (null (roots (withPOS "animal" []) "Every cat is an animal."))
 ,expect "bare generic subject does not enter route" (null (roots mini "Cat is an animal."))
 ,expect "indefinite subject does not enter route" (null (roots mini "A cat is an animal."))
 ,expect "orphan paired article cannot assert" (null (roots mini "Is an animal."))
 ,expect "source seen-pair mapping licenses the two new applications"
    (not (null (roots seen "Every cat is an animal.")))
 ,expect "missing nominal source pair prevents new route"
    (null (roots (seen {smSeen=Set.delete (eraseFeatures (cc "(S[dcl]\\NP)/NP"),cc "NP") (smSeen seen)}) "Every cat is an animal."))
 ]
 where
  seen=mini {smSeenRules=True,smSeen=Set.fromList
    [(eraseFeatures (cc l),eraseFeatures (cc r)) | (l,r)<-
       [("NP[nb]/N","N"),("(S[dcl]\\NP)/NP","NP[nb]")
       ,("NP[nb]","S[dcl]\\NP"),("S[dcl]",".")]]}


-- Independent ordinary routes must keep their semantics even when this new
-- paired route is available. This larger miniature lexicon remains corpus-free.
ordinaryModel :: SemModel
ordinaryModel=mini {smTags=tags,smPOS=poses}
 where
  more=[("is","(S[dcl]\\NP)/(S[adj]\\NP)","VBZ")
       ,("red","S[adj]\\NP","JJ"),("Bob","NP","NNP")
       ,("sees","(S[dcl]\\NP)/NP","VBZ")]
  tags=buildTagModel ([(w,c) | (w,cs)<-M.toList (tmWord (smTags mini)),(c,_)<-cs]
                       ++[(w,cc c)|(w,c,_)<-more])
  poses=POSModel (M.unionWith (M.unionWith (+)) original additions)
  POSModel original=smPOS mini
  POSModel additions=buildPOSModel [(w,p)|(w,_,p)<-more]
ordinaryDRS :: String -> Maybe Canonical
ordinaryDRS text=case prSentences (runPipelineWith (CCGBankParser ordinaryModel)
                                    (SourceId "nominal-ordinary") text) of
 [one] -> canonicalize <$> srDRS one
 _ -> Nothing
ordinaryChecks :: [Check]
ordinaryChecks=
 [expectEq "adjective route retains direct predicate under universal"
   (Just (Canonical [] [CanImp
     (Canonical [CRef 0] [CanPred "cat" [CRefT (CRef 0)]])
     (Canonical [] [CanPred "red" [CRefT (CRef 0)]])]))
   (ordinaryDRS "Every cat is red.")
 ,expectEq "ordinary object article retains existential witness"
   (Just (Canonical [CRef 0]
     [CanPred "animal" [CRefT (CRef 0)],CanPred "see" [CConstT "Bob",CRefT (CRef 0)]]))
   (ordinaryDRS "Bob sees an animal.")
 ]
