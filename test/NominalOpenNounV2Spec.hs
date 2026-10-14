-- Independent v2 red controls; compile against frozen nominal v1 src, not production.
-- No corpus load. See research/notes/nominal-v2-controls.md for the exact command.
module Main (main) where
import qualified Data.Map.Strict as M
import qualified Data.Set as Set
import Harness
import NL2Proof.DRT.Canonical
import NL2Proof.Pipeline
import NL2Proof.Provenance
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
base = (defaultSemModel tags poses (Rules [] []) Set.empty) {smAlpha=0,smSeenRules=False}
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
classification text sub obj =
 let atom n=CanPred n [CRefT (CRef 0)]
     implication=CanImp (Canonical [CRef 0] [atom sub]) (Canonical [] [atom obj])
     expected=Canonical [] [implication]
     sentence=case prSentences (runPipelineWith (CCGBankParser base) (SourceId "v2-independent") text) of
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
 ,ssFused=FusedPlain,ssNominal=role,ssNotes=[]}
article=sign "N/N" (Lam "P" tyPred1 (Var "P"))
 (ProvLex (SourceId "v2-origin") (Span 13 14) "a") (NominalArticle certificate)
noun=sign "N" (pred1 "blicket") origin (NominalNoun origin (cc "N"))
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
 ++safety)
