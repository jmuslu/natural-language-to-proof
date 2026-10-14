-- Independent scoped nominal-negation controls; known red plan, no source fix.
-- Tiny synthetic dictionaries only; no model/corpus loader.
module Main (main) where
import qualified Data.Map.Strict as M
import qualified Data.Set as Set
import System.Environment (getArgs)
import Harness
import NL2Proof.DRT.Canonical
import NL2Proof.Pipeline
import NL2Proof.Semantics.CCGSem (LexItem(..),closedEntries,composeTerm)
import NL2Proof.Semantics.Lambda
import NL2Proof.Syntax.CCGRules (Combinator(..),combineNamed)
import NL2Proof.Provenance
import NL2Proof.Syntax.CCGBank (CCat,parseCCGCat)
import NL2Proof.Syntax.CCGParse (Rules(..))
import NL2Proof.Syntax.CCGSemParse
import NL2Proof.Syntax.CCGSupertag
import NL2Proof.Verify.ClaimKind (claimCond)
import NL2Proof.Verify.Reported (splitClaims)

cc :: String -> CCat
cc=either error id . parseCCGCat
mini :: SemModel
mini=(defaultSemModel tags poses (Rules [] []) Set.empty) {smAlpha=0,smSeenRules=False}
 where
  entries=[("Ari","NP","NNP"),("every","NP[nb]/N","DT"),("each","NP[nb]/N","DT")
   ,("a","NP[nb]/N","DT"),("an","NP[nb]/N","DT")
   ,("is","(S[dcl]\\NP)/NP","VBZ"),("is","(S[dcl]\\NP)/(S[adj]\\NP)","VBZ")
   ,("not","(S\\NP)\\(S\\NP)","RB"),("not","(S\\NP)/(S\\NP)","RB")
   ,("not","(S[adj]\\NP)/(S[adj]\\NP)","RB")
   ,("does","(S[dcl]\\NP)/(S[b]\\NP)","VBZ")
   ,("see","(S[b]\\NP)/NP","VB"),("sees","(S[dcl]\\NP)/NP","VBZ")
   ,("red","S[adj]\\NP","JJ"),(".",".",".")]
   ++[(w,"N","NN")|w<-["cat","dog","animal","mammal"]]
  tags=buildTagModel ([(w,cc c)|(w,c,_)<-entries]++[(w,cc "N")|w<-["dax","wug"]])
  poses=buildPOSModel [(w,p)|(w,_,p)<-entries]

result :: SemModel -> String -> SentenceResult
result m text=case prSentences(runPipelineWith(CCGBankParser m)(SourceId "nominal-negation-independent")text) of
 [one]->one
 _->error "expected single sentence"

exact :: SemModel -> String -> Canonical -> [CanonCond] -> [CanonCond] -> [Check]
exact m text wanted asserted embedded=
 let r=result m text
 in [expectEq ("exact scoped DRS: "++text) (Just wanted)(canonicalize <$> srDRS r)
    ,expect ("all returned readings preserve scoped meaning: "++text)
      (not(null(srReadings r)) && all((==Just wanted).fmap canonicalize.rrDRS)(srReadings r))
    ,expect ("independent claim statuses: "++text) (case srDRS r of
       Nothing->False
       Just d->let(as,rs,ps,es)=splitClaims d in map(claimCond.fst)as==asserted
               && map claimCond es==embedded && null rs && null ps)]

universal :: SemModel -> String -> String -> String -> [Check]
universal m text noun predicate=
 let n=CanPred noun [CRefT(CRef 0)]
     p=CanPred predicate [CRefT(CRef 0)]
     neg=CanNot(Canonical [] [p])
     whole=CanImp(Canonical [CRef 0][n])(Canonical [] [neg])
 in exact m text (Canonical [] [whole]) [whole] [n,neg,p]

positive :: [Check]
positive=
 universal mini "Every cat is not an animal." "cat" "animal"
 ++ universal mini "Each dog is not a mammal." "dog" "mammal"
 ++ let atom=CanPred "animal" [CConstT "Ari"]; neg=CanNot(Canonical [] [atom])
    in exact mini "Ari is not an animal." (Canonical [] [neg]) [neg] [atom]
 ++ universal (mini {smNominalPolicy=ContextUnknownNouns})
      "Every dax is not a wug." "dax" "wug"

blocked :: String -> SemModel -> String -> Check
blocked label m text=expect label (null(srReadings(result m text)))

boundaries :: [Check]
boundaries=
 [blocked "no indefinite subject extension" mini "A cat is not an animal."
 ,blocked "unknown initial name never licensed by noun policy"
    (mini {smNominalPolicy=ContextUnknownNouns}) "Zorlan is not an animal."
 ,blocked "KnownNounsOnly still blocks unknown noun predicate" mini "Every cat is not a wug."
 ,blocked "equative complement stays unsupported" mini "Every cat is not Ari."
 ,blocked "bare nominal complement stays unsupported" mini "Every cat is not animal."
 ,blocked "double not is not a single certified occurrence" mini "Every cat is not not an animal."
 ,blocked "wide-scope not-every is separate construction" mini "Not every cat is an animal."
 ,blocked "orphan negative copula has no root" mini "Is not an animal."
 ,blocked "forward-only not cannot mint the backward source frame" forwardOnly "Every cat is not an animal."
 ,blocked "rare adjective opposition still blocks nominal complement" conflict "Every cat is not an animal."]
 ++ let atom=CanPred "red" [CConstT "Ari"]; neg=CanNot(Canonical [] [atom])
    in exact mini "Ari is not red." (Canonical [] [neg]) [neg] [atom]
 ++ let animal=CanPred "animal" [CRefT(CRef 0)]
        see=CanPred "see" [CConstT "Ari",CRefT(CRef 0)]
    in exact mini "Ari sees an animal." (Canonical [CRef 0][animal,see]) [animal,see] []
 ++ let animal=CanPred "animal" [CRefT(CRef 0)]
        see=CanPred "see" [CConstT "Ari",CRefT(CRef 0)]
        neg=CanNot(Canonical [CRef 0][animal,see])
    in exact mini "Ari does not see an animal." (Canonical [] [neg]) [neg] [animal,see]
 where
  POSModel ps=smPOS mini
  conflict=mini {smPOS=POSModel(M.insert "animal"(M.fromList[("NN",100),("JJ",1)])ps)}
  forwardOnly=mini {smTags=(smTags mini) {tmWord=M.insert "not"
     [(cc "(S\\NP)/(S\\NP)",1)] (tmWord(smTags mini))}}


-- Checks of the existing source combinator and operator meaning, not evidence
-- that the parser licenses the proposed occurrence-certified construction.
operatorChecks :: [Check]
operatorChecks=case closedEntries 2 "not" (cc "(S\\NP)\\(S\\NP)") of
 [LexTerm neg _ _]->
  let cop=Lam "P" tyPred1(Lam "Q" tyGQ(App(Var "Q")(Var "P")))
      composed=composeTerm tyPred1 neg cop
      p=pred1 "animal"
      name=Lam "k" tyPred1(App(Var "k")(entity "Ari"))
      universalQ=Lam "k" tyPred1(TForall "x" TyE(TImp(App(pred1 "cat")(Var "x"))(App(Var "k")(Var "x"))))
      namedResult=normalize(App(App composed p)name)
      quantifiedResult=normalize(App(App composed p)universalQ)
      wanted=TForall "x" TyE(TImp(App(pred1 "cat")(Var "x"))(TNot(App p(Var "x"))))
  in [expectEq "source backward crossed copula-not derivation"
       [(BwdXComp,cc "(S[dcl]\\NP)/NP")]
       (combineNamed [BwdXComp](cc "(S[dcl]\\NP)/NP")(cc "(S\\NP)\\(S\\NP)"))
     ,expectEq "internal captured-property argument retains crossed derivation"
       [(BwdXComp,cc "(S[dcl]\\NP)/N")]
       (combineNamed [BwdXComp](cc "(S[dcl]\\NP)/N")(cc "(S\\NP)\\(S\\NP)"))
     ,expectEq "composed operator has property-to-VP type"
       (Right(tyPred1 ~> tyGQ ~> TyT))(typeOf [] composed)
     ,expect "named composed meaning is direct negative classification"
       (alphaEq namedResult(TNot(App p(entity "Ari"))))
     ,expect "universal composed meaning places NOT inside implication"
       (alphaEq quantifiedResult wanted)
     ,expect "negated universal proposition is a different meaning"
       (not(alphaEq quantifiedResult(TNot(TForall "x" TyE(TImp(App(pred1 "cat")(Var "x"))(App p(Var "x")))))))]
 _->[bad "existing backward VP not lexical entry available" "missing or ambiguous lexical entry"]

main :: IO ()
main=do
 args<-getArgs
 runChecks "bounded nominal negation plan"
   (case args of ["--positive"]->positive;["--boundaries"]->boundaries;["--operator"]->operatorChecks;_->positive++boundaries++operatorChecks)
