-- Independent v2 red controls; compile against frozen nominal v1 src, not production.
-- No corpus load. See research/notes/nominal-v2-controls.md for the exact command.
module Main (main) where
import qualified Data.Map.Strict as M
import qualified Data.Set as Set
import Harness
import NL2Proof.DRT.Canonical
import NL2Proof.Pipeline
import NL2Proof.Provenance
import NL2Proof.Semantics.CCGSem (stKind)
import NL2Proof.Semantics.Lambda
import NL2Proof.Syntax.CCGBank (parseCCGCat)
import NL2Proof.Syntax.CCGRules (Combinator(..))
import NL2Proof.Syntax.CCGParse (Rules(..))
import NL2Proof.Syntax.CCGSemParse
import NL2Proof.Syntax.CCGSupertag
import NL2Proof.Syntax.Tokenize (casedTokens)
import NL2Proof.Verify.ClaimKind (claimCond)
import NL2Proof.Verify.Reported (splitClaims)

cc = either error id . parseCCGCat
base :: SemModel
base = (defaultSemModel tags poses (Rules [] []) Set.empty) {smAlpha=0,smSeenRules=False,smNominalPolicy=ContextUnknownNouns}
 where
  fixed=[("every","NP[nb]/N","DT"),("each","NP[nb]/N","DT"),
         ("is","(S[dcl]\\NP)/NP","VBZ"),("a","NP[nb]/N","DT"),
         ("an","NP[nb]/N","DT"),(".",".",".")]
  known=[("cat","N","NN"),("animal","N","NN")]
  tags=buildTagModel ([(w,cc c)|(w,c,_)<-fixed++known]
          ++[(w,cc "N")|w<-["dax","blicket","wumpus","impus","Zorp"]])
  poses=buildPOSModel [(w,p)|(w,_,p)<-fixed++known]
withPOS word ps = base {smPOS=POSModel (M.insert word (M.fromList [(p,1)|p<-ps]) original)}
 where POSModel original=smPOS base
roots model text=spRoots (semParse model (SourceId "open-nominal-v2") (casedTokens 0 text))
newRoute model text=any completed (roots model text)
 where completed s=case ssNominal s of NominalComplete{} -> True;_ -> False
classification = classificationWith base
classificationWith model text sub obj =
 let atom n=CanPred n [CRefT (CRef 0)]
     implication=CanImp (Canonical [CRef 0] [atom sub]) (Canonical [] [atom obj])
     expected=Canonical [] [implication]
     sentence=case prSentences (runPipelineWith (CCGBankParser model) (SourceId "v2-independent") text) of
       [s]->s;_->error "one sentence expected"
     statuses=case srDRS sentence of
       Just d -> let (as,rs,ps,es)=splitClaims d in
         map (claimCond . fst) as==[implication] && map claimCond es==[atom sub,atom obj]
         && null rs && null ps
       _ -> False
 in [expectEq ("selected classification: "++text) (Just expected) (canonicalize <$> srDRS sentence)
    ,expect ("scope/status: "++text) statuses
    ,expect ("every retained reading classifies: "++text)
      (not(null(srReadings sentence)) && all ((==Just expected) . fmap canonicalize . rrDRS) (srReadings sentence))]

-- Independently construct typed local evidence to exercise existing escape guards.
certificate=NominalCertificate (SourceId "v2-origin") 2 3 (Span 10 12) (Span 13 14)
 "is" "a" (cc "(S[dcl]\\NP)/NP") (cc "NP[nb]/N")
origin=ProvLex (SourceId "v2-origin") (Span 15 22) "blicket"
sign category meaning provenance role=SSign
 {ssCat=cc category,ssSem=meaning,ssProv=provenance,ssScore=0,ssCoord=Nothing
 ,ssStructural=Nothing,ssOpenConditional=False,ssConditionalRaised=False,ssList=Nothing
 ,ssFused=FusedPlain,ssNominal=role,ssOrState=Nothing,ssNotes=[]}
article=sign "N/N" (Lam "P" tyPred1 (Var "P"))
 (ProvLex (SourceId "v2-origin") (Span 13 14) "a") (NominalArticle certificate)
noun=sign "N" (pred1 "blicket") origin (NominalNoun (NominalNounOrigin origin (cc "N") DictionaryCommonNoun))
safety =
 [expect "same property without lexical origin capability is not unwrapped" $
    nominalTransition FwdApp (cc "N") article (noun {ssNominal=NominalPlain})==Nothing
 ,expect "unary-derived N cannot counterfeit lexical leaf" $
    nominalTransition FwdApp (cc "N") article (noun {ssProv=provRule "unary" [origin]})==Nothing
 ,expect "foreign occurrence cannot discharge article certificate" $
    nominalTransition FwdApp (cc "N") article
      (noun {ssProv=ProvLex (SourceId "foreign") (Span 15 22) "blicket"})==Nothing
 ,expect "NP generalized quantifier cannot substitute for direct N" $
    nominalTransition FwdApp (cc "N") article
      (noun {ssCat=cc "NP",ssSem=Lam "P" tyPred1 (App (Var "P") (entity "Bob"))})==Nothing
 ,expect "pending internal article cannot become root" (not(nominalRootAllowed article))
 ,expect "pending internal article cannot enter unary" (not(nominalUnaryAllowed article))
 ,expectEq "packing preserves lexical capability versus same plain property" 2
    (length(packCell 20 [noun,noun {ssNominal=NominalPlain}]))]

priorOnly :: SemModel
priorOnly=base {smTags=tags {tmWord=foldr M.delete (tmWord tags) ["dax","blicket"]}}
 where tags=smTags base
withOfferedUnknown word=base {smTags=tags {tmWord=M.insert word [(cc "N",1)] (tmWord tags)}}
 where tags=smTags base

main :: IO ()
main=runChecks "open-nominal-v2 independent red proposal"
 (concat [classification t s p | (t,s,p)<-
  [("Every dax is a blicket.","dax","blicket")
  ,("Each wumpus is an impus.","wumpus","impus")
  ,("Every cat is a blicket.","cat","blicket")
  ,("Every dax is an animal.","dax","animal")
  ,("Every cat is an animal.","cat","animal")]]
 ++[expect ("contrary POS does not license inferred noun: "++show ps)
      (not(newRoute (withPOS "blicket" ps) "Every cat is a blicket."))
      |ps<-[["JJ"],["NN","JJ"],["NNP"],["NN","NNP"],["VB"]]]
 ++[expect "unknown capitalized predicate is not inferred common noun"
       (not(newRoute base "Every cat is a Zorp."))
   ,expect "no direct determiner subject no new universal route"
       (not(newRoute base "Dax is a blicket."))
   ,expect "indefinite subject outside bounded universal route"
       (not(newRoute base "A dax is a blicket."))
   ,expect "orphan predication does not assert" (not(newRoute base "Is a blicket."))]
 ++[expect "subject JJ conflict remains excluded with known complement"
       (not(newRoute (withPOS "cat" ["NN","JJ"]) "Every cat is an animal."))
   ,expect "subject NNP conflict remains excluded with known complement"
       (not(newRoute (withPOS "cat" ["NN","NNP"]) "Every cat is an animal."))
   ,expect "offered NP alone cannot be invented into lexical N"
       (let tags=smTags base
            model=base {smTags=tags {tmWord=M.insert "animal" [(cc "NP",1)] (tmWord tags)}}
        in not(newRoute model "Every cat is an animal."))]
 ++[expect ("nonalphabetic or mixed-case noun excluded: "++word)
       (not(newRoute (withOfferedUnknown word) ("Every cat is a "++word++".")))
       |word<-["dax2","dax-blicket","dAx","123"]]
 ++[expect "prior-only noun fixture is OOV yet N offered without POS evidence"
       (all (\w -> M.notMember w (tmWord (smTags priorOnly))
             && null(posCounts (smPOS priorOnly) w)
             && any ((==cc "N") . fst) (offeredTags priorOnly False w)) ["dax","blicket"])]
 ++classificationWith priorOnly "Every dax is a blicket." "dax" "blicket"
 ++[expect "explicit v1 policy still rejects missing POS"
       (not(newRoute (base {smNominalPolicy=KnownNounsOnly}) "Every dax is a blicket."))]
 ++[expect "completed unknown route retains both noun admission origins"
       (any inferredComplete (roots base "Every dax is a blicket."))
   ,expect "unknown lexical choices are logged at both occurrences"
       (any ((==2) . length . filter ((=="context-unknown-noun") . stKind . fst) . ssNotes)
         (roots base "Every dax is a blicket."))
   ,expect "known nouns do not claim unknown lexical evidence"
       (all (null . filter ((=="context-unknown-noun") . stKind . fst) . ssNotes)
         (roots base "Every cat is an animal."))]
 ++typedOriginChecks ++safety)

inferredComplete s=case ssNominal s of
 NominalComplete _ _ a b -> inferred a && inferred b
 _ -> False
 where inferred origin=case nnoAdmission origin of ContextLicensedUnknown{}->True;_->False

-- Typed evidence is independent of the property lambda, never recovered from Q.
typedOriginChecks :: [Check]
typedOriginChecks =
 let known=NominalNounOrigin origin (cc "N") DictionaryCommonNoun
     inferred=known {nnoAdmission=ContextLicensedUnknown (PairedNominalComplement certificate)}
     wrongPair=inferred {nnoAdmission=ContextLicensedUnknown
         (PairedNominalComplement (certificate {ncCopulaIndex=7,ncArticleIndex=8}))}
     dp=ProvLex (SourceId "v2-origin") (Span 0 5) "Every"
     subjectEvidence=known {nnoAdmission=ContextLicensedUnknown (DirectUniversalSubject dp (cc "NP[nb]/N"))}
     det=sign "NP[nb]/N"
          (Lam "N" tyPred1 (Lam "P" tyPred1 (TForall "x" TyE
            (TImp (App (Var "N") (Var "x")) (App (Var "P") (Var "x"))))))
          dp (NominalUniversalDeterminer dp (cc "NP[nb]/N"))
     asN o=noun {ssNominal=NominalNoun o}
     pProv=provRule "FwdApp" [ssProv article,origin]
     predSign o=sign "N" (pred1 "blicket") pProv (NominalPredicate certificate o)
     copProv=ProvLex (SourceId "v2-origin") (Span 10 12) "is"
     copula=sign "(S[dcl]\\NP)/N"
          (Lam "P" tyPred1 (Lam "Q" tyGQ (App (Var "Q") (Var "P"))))
          copProv (NominalCopula certificate)
     pendingProv=provRule "FwdApp" [copProv,pProv]
     pending o=sign "S[dcl]\\NP" (Lam "Q" tyGQ (App (Var "Q") (pred1 "blicket")))
          pendingProv (NominalPending certificate o)
     subject o=sign "NP[nb]" (Lam "P" tyPred1 (App (Var "P") (entity "fixture")))
          dp (NominalUniversalSubject dp (cc "NP[nb]/N") o)
     completed o=sign "S[dcl]" (App (pred1 "quiet") (entity "fixture"))
          pProv (NominalComplete certificate dp known o)
 in [expect "matching inferred complement context captures lexical P"
        (nominalTransition FwdApp (cc "N") article (asN inferred)==Just (NominalPredicate certificate inferred))
    ,expect "wrong paired context rejects same lexical P"
        (nominalTransition FwdApp (cc "N") article (asN wrongPair)==Nothing)
    ,expect "subject license cannot be reused by paired article"
        (nominalTransition FwdApp (cc "N") article (asN subjectEvidence)==Nothing)
    ,expect "complement context cannot mint direct universal subject"
        (case nominalTransition FwdApp (cc "NP[nb]") det (asN inferred) of
           Just NominalUniversalSubject{} -> False;_ -> True)
    ,expect "subject with mismatched determiner occurrence cannot mint capability"
        (let mismatch=subjectEvidence {nnoAdmission=ContextLicensedUnknown
                (DirectUniversalSubject (ProvLex (SourceId "elsewhere") (Span 0 5) "Every") (cc "NP[nb]/N"))}
         in case nominalTransition FwdApp (cc "NP[nb]") det (asN mismatch) of
              Just NominalUniversalSubject{} -> False;_ -> True)
    ,expect "copula rechecks retained inferred complement certificate"
        (nominalTransition FwdApp (cc "S[dcl]\\NP") copula (predSign wrongPair)==Nothing)
    ,expect "copula preserves the actual inferred origin through pending"
        (nominalTransition FwdApp (cc "S[dcl]\\NP") copula (predSign inferred)==Just (NominalPending certificate inferred))]
    ++ [expectEq ("packing preserves known/inferred origin at "++name) 2
         (length(packCell 20 [make known,make inferred]))
       |(name,make)<-[("noun",asN),("subject",subject),("predicate",predSign),("pending",pending),("complete",completed)]]
