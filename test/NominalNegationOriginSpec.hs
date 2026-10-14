-- Independent adversarial controls; roots supply real lexical-minted evidence.
-- Authored red before the bounded API/implementation existed.
module Main(main) where
import qualified Data.Set as Set
import Harness
import NL2Proof.Provenance
import NL2Proof.Semantics.Lambda
import NL2Proof.Semantics.CCGSem(LexItem(..),closedEntries,composeTerm)
import NL2Proof.Syntax.CCGBank
import NL2Proof.Syntax.CCGParse(Rules(..))
import NL2Proof.Syntax.CCGRules(Combinator(..),allCombinators)
import NL2Proof.Syntax.CCGSemParse
import NL2Proof.Syntax.CCGSupertag
import NL2Proof.Syntax.Tokenize
cc :: String -> CCat
cc=either error id . parseCCGCat
mini :: SemModel
mini=(defaultSemModel (buildTagModel[(w,cc c)|(w,c,_)<-entries])
 (buildPOSModel[(w,p)|(w,_,p)<-entries]) (Rules [] []) Set.empty)
 {smAlpha=0,smSeenRules=False}
 where entries=[("Ari","NP","NNP"),("is","(S[dcl]\\NP)/NP","VBZ")
        ,("not","(S\\NP)\\(S\\NP)","RB"),("an","NP[nb]/N","DT")
        ,("animal","N","NN"),("every","NP[nb]/N","DT"),("cat","N","NN")]
roots :: SemModel -> String -> [SSign]
roots m=spRoots . semParse m (SourceId "negative-origin") . casedTokens 0
main :: IO ()
main=case roots mini "Ari is not an animal" of
 []->runChecks "nominal negation origin" [bad "actual negative root" "no root"]
 root:_->case ssNominal root of
  NominalNamedComplete c name noun | Just origin<-nominalNegation c ->
   let vp=cc "S[dcl]\\NP"; ci=cc "(S[dcl]\\NP)/N"; nc=cc "(S\\NP)\\(S\\NP)"
       cop=Lam "P" tyPred1(Lam "Q" tyGQ(App(Var "Q")(Var "P")))
       neg=case closedEntries 2 "not" nc of [LexTerm t _ _]->t;_->error "closed not"
       cp=ProvLex(ncSource c)(ncCopulaSpan c)(ncCopulaWord c)
       ap=ProvLex(ncSource c)(ncArticleSpan c)(ncArticleWord c)
       np=nnoProv noun; no=nnProv origin
       leaf category term prov role=root {ssCat=category,ssSem=term,ssProv=prov,ssNominal=role,ssNotes=[]}
       copula=leaf ci cop cp (NominalCopula c)
       notSign=leaf nc neg no (NominalNegator c)
       crossed=leaf ci (composeTerm tyPred1 neg cop)
         (provRule "BwdXComp" [cp,no]) (NominalNegatedCopula c)
       property=leaf (cc "N") (pred1 "animal") (provRule "FwdApp" [ap,np]) (NominalPredicate c noun)
       combine l r=nominalTransition BwdXComp ci l r
       changeOrigin f=c {ncNegationOrigin=f origin}
       changedNot d=notSign {ssNominal=NominalNegator d}
       foreignOrigin=origin {nnProv=ProvLex(SourceId "foreign")(Span 7 10)"not"}
       badIndex=origin {nnIndex=nnIndex origin+1}
       badCat=origin {nnCategory=cc "(S[dcl]\\NP)\\(S[dcl]\\NP)"}
       positive=NominalCertificate(ncSource c)(ncCopulaIndex c)(ncArticleIndex c)
         (ncCopulaSpan c)(ncArticleSpan c)(ncCopulaWord c)(ncArticleWord c)
         (ncCopulaCategory c)(ncArticleCategory c)
       otherNot=case roots mini "Every cat is not an animal" of
         other:_ -> case ssNominal other of
           NominalComplete d _ _ _ | Just o<-nominalNegation d ->
             leaf nc neg (nnProv o) (NominalNegator d)
           _ -> error "expected actual universal negative origin"
         _ -> error "expected actual universal negative root"
       strict=mini {smSeenRules=True,smSeen=Set.fromList
         [(eraseFeatures(cc a),eraseFeatures(cc b))|(a,b)<-
          [("(S[dcl]\\NP)/NP","(S\\NP)\\(S\\NP)"),("NP[nb]/N","N")
          ,("(S[dcl]\\NP)/NP","NP[nb]"),("NP","S[dcl]\\NP")
          ,("NP[nb]","S[dcl]\\NP")]]}
       remove a b=strict {smSeen=Set.delete(eraseFeatures(cc a),eraseFeatures(cc b))(smSeen strict)}
   in runChecks "nominal negation origin"
    ([expect "actual closed branch bound to not occurrence" (nnIndex origin==2 && no==ProvLex(SourceId "negative-origin")(Span 7 10)"not" && nnCategory origin==nc)
     ,expect "exact crossed transition accepted" (combine copula notSign==Just(NominalNegatedCopula c))
     ,expect "exact composed predicate application accepted"
       (nominalTransition FwdApp vp crossed property==Just(NominalPending c noun))
     ,expect "ordinary identical term not cannot discharge" (combine copula(notSign {ssNominal=NominalPlain})==Nothing)
     ,expect "foreign origin cannot discharge" (combine copula(changedNot(changeOrigin(const foreignOrigin)))==Nothing)
     ,expect "wrong index cannot discharge" (combine copula(changedNot(changeOrigin(const badIndex)))==Nothing)
     ,expect "wrong category feature cannot discharge" (combine copula(changedNot(changeOrigin(const badCat)))==Nothing)
     ,expect "wrong actual not category cannot discharge"
       (combine copula(notSign {ssCat=cc "(S[dcl]\\NP)\\(S[dcl]\\NP)"})==Nothing)
     ,expect "shifted not source span cannot discharge"
       (combine copula(notSign {ssProv=ProvLex(SourceId "negative-origin")(Span 8 11)"not"})==Nothing)
     ,expect "unary not provenance cannot discharge"
       (combine copula(notSign {ssProv=provRule "unary" [no]})==Nothing)
     ,expect "swapped child order cannot discharge" (combine notSign copula==Nothing)
     ,expect "mismatching not provenance cannot discharge" (combine copula(notSign {ssProv=cp})==Nothing)
     ,expect "same altered foreign certificate still cannot hide wrong provenance"
       (combine(copula {ssNominal=NominalCopula(changeOrigin(const foreignOrigin))})
          (changedNot(changeOrigin(const foreignOrigin)))==Nothing)
     ,expect "wrong not semantic type cannot discharge" (combine copula(notSign {ssSem=entity "not"})==Nothing)
     ,expect "swapped not/article index certificate cannot discharge"
       (let d=changeOrigin(\o->o {nnIndex=ncArticleIndex c}) in
          combine(copula {ssNominal=NominalCopula d})(changedNot d)==Nothing)
     ,expect "overlapping not/copula spans cannot discharge"
       (let d=changeOrigin(\o->o {nnProv=ProvLex(ncSource c)(ncCopulaSpan c)"not"}) in
          combine(copula {ssNominal=NominalCopula d})
             ((changedNot d) {ssProv=ProvLex(ncSource c)(ncCopulaSpan c)"not"})==Nothing)
     ,expect "coordinator flag cannot discharge" (combine copula(notSign {ssCoord=Just "and"})==Nothing)
     ,expect "conditional flag cannot discharge" (combine copula(notSign {ssOpenConditional=True})==Nothing)
     ,expect "positive certificate cannot discharge negative copula"
       (combine(copula {ssNominal=NominalCopula positive})(changedNot positive)==Nothing)
     ,expect "uncomposed is cannot skip certified not"
       (nominalTransition FwdApp vp copula property==Nothing)
     ,expect "generic copied composition provenance cannot discharge"
       (nominalTransition FwdApp vp (crossed {ssProv=provRule "FwdComp" [cp,no]}) property==Nothing)
     ,expectEq "packing retains identical-term different certificates" 2
       (length(packCell 20 [notSign,changedNot(changeOrigin(const badIndex))]))
     ,expectEq "packing retains distinct actual minted not occurrences with identical terms" 2
       (length(packCell 20 [notSign,otherNot]))
     ,expect "mandatory not has no bare root" (not(nominalRootAllowed notSign))
     ,expect "mandatory composed copula has no bare root" (not(nominalRootAllowed crossed))
     ,expect "mandatory composed copula cannot unary-escape" (not(nominalUnaryAllowed crossed))
     ,expect "mandatory not cannot unary-escape" (not(nominalUnaryAllowed notSign))
     ,expect "complete named certificate retains negation" (nominalNegation c==Just origin && nmoProv name/=no)
     ,expect "all required seen source pairs permit frame" (not(null(roots strict "Ari is not an animal")))
     ,expect "missing original is/not pair blocks frame" (null(roots(remove "(S[dcl]\\NP)/NP" "(S\\NP)\\(S\\NP)") "Ari is not an animal"))
     ,expect "missing composed is-not/NP pair blocks frame" (null(roots(remove "(S[dcl]\\NP)/NP" "NP[nb]") "Ari is not an animal"))
     ,expect "positive source pairs remain sufficient without negative pair" (not(null(roots(remove "(S[dcl]\\NP)/NP" "(S\\NP)\\(S\\NP)") "Ari is an animal")))
     ] ++ [expect ("not-frame rejects alternate combinator "++show comb)
       (nominalTransition comb ci copula notSign==Nothing)|comb<-allCombinators,comb/=BwdXComp]
       ++ [expect ("active negative cannot generic-combine "++show comb)
       (nominalTransition comb ci crossed notSign==Nothing)|comb<-allCombinators]
       ++ [expect ("active not cannot combine with ordinary sign "++show comb)
       (nominalTransition comb ci notSign (copula {ssNominal=NominalPlain})==Nothing)|comb<-allCombinators]
       ++ [expect ("complete negative rejects embedding "++show comb)
       (nominalTransition comb (cc "S[dcl]") root (notSign {ssNominal=NominalPlain})==Nothing)|comb<-allCombinators])
  _->runChecks "nominal negation origin" [bad "actual negative typed certificate" "wrong role"]
