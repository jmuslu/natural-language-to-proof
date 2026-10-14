-- Adversarial checks against origins recovered from actual lexical/chart minting.
-- Before the new API exists this file intentionally does not compile; it is not
-- counted as a passing baseline. No corpus loads.
module Main (main) where
import qualified Data.Set as Set
import qualified Data.Map.Strict as M
import Harness
import NL2Proof.Provenance
import NL2Proof.Semantics.Lambda
import NL2Proof.Syntax.CCGBank
import NL2Proof.Syntax.CCGParse (Rules(..))
import NL2Proof.Syntax.CCGRules (Combinator(..),allCombinators)
import NL2Proof.Syntax.CCGSemParse
import NL2Proof.Syntax.CCGSupertag
import NL2Proof.Syntax.Tokenize

cc :: String -> CCat
cc=either error id . parseCCGCat
mini :: [String] -> [(String,Int)] -> SemModel
mini nameCats ps=(defaultSemModel tags poses (Rules [] []) Set.empty)
 {smAlpha=0,smSeenRules=False}
 where
  ordinary=[("is","(S[dcl]\\NP)/NP","VBZ"),("an","NP[nb]/N","DT")
           ,("animal","N","NN"),(".",".",".")]
  tags=buildTagModel ([("Ari",cc c)|c<-nameCats]++[(w,cc c)|(w,c,_)<-ordinary])
  POSModel base=buildPOSModel [(w,p)|(w,_,p)<-ordinary]
  poses=POSModel(M.insert "Ari" (M.fromList ps) base)

roots :: SemModel -> [SSign]
roots m=spRoots (semParse m (SourceId "name-origin") (casedTokens 0 "Ari is an animal."))

main :: IO ()
main=case roots (mini ["NP"] [("NNP",4)]) of
 []->runChecks "nominal name origin" [bad "actual lexical branch mints named root" "no root"]
 (root:_)->case ssNominal root of
  NominalNamedComplete certificate origin complement ->
   let p=pred1 "animal"
       subject=root {ssCat=cc "NP",ssSem=Lam "k" tyPred1(App(Var "k")(entity "Ari"))
         ,ssProv=nmoProv origin,ssNominal=NominalNameSubject origin,ssNotes=[]}
       article=ProvLex (ncSource certificate) (ncArticleSpan certificate) (ncArticleWord certificate)
       copula=ProvLex (ncSource certificate) (ncCopulaSpan certificate) (ncCopulaWord certificate)
       pending=root {ssCat=cc "S[dcl]\\NP",ssSem=Lam "Q" tyGQ(App(Var "Q")p)
         ,ssProv=provRule "FwdApp" [copula,provRule "FwdApp" [article,nnoProv complement]]
         ,ssNominal=NominalPending certificate complement,ssNotes=[]}
       accept s=nominalTransition BwdApp (cc "S[dcl]") s pending
       mutate f=subject {ssNominal=NominalNameSubject(f origin)}
       lexical=nmoLexical origin
       plain=subject {ssNominal=NominalPlain}
       sameTermRoots=roots(mini ["NP"] [("NNP",4)]) ++ roots(mini ["N"] [("NNP",4)])
       hasSource category sign=case ssNominal sign of
         NominalNamedComplete _ o _->nloSourceCategory(nmoLexical o)==cc category
         _->False
       npnb=roots(mini ["NP[nb]"] [("NNP",4)])
   in runChecks "nominal name origin"
    ([expect "actual lexical branch stores source NP" (nloSourceCategory lexical==cc "NP")
     ,expect "actual lexical branch stores unpruned support" (nloWrittenPOS lexical==[("NNP",4)])
     ,expect "direct subject transition preserves typed origin"
       (accept subject==Just(NominalNamedComplete certificate origin complement))
     ,expect "same exact category term and notes without origin rejected" (accept plain==Nothing)
     ,expect "foreign lexical provenance rejected"
       (accept(subject {ssProv=ProvLex(SourceId "foreign")(Span 0 3)"Ari"})==Nothing)
     ,expect "foreign origin source rejected"
       (accept(mutate(\o->o {nmoProv=ProvLex(SourceId "foreign")(Span 0 3)"Ari"}))==Nothing)
     ,expect "shifted origin span rejected"
       (accept(mutate(\o->o {nmoProv=ProvLex(SourceId "name-origin")(Span 1 4)"Ari"}))==Nothing)
     ,expect "shifted token index rejected"
       (accept(mutate(\o->o {nmoLexical=lexical {nloIndex=1}}))==Nothing)
     ,expect "different written token rejected"
       (accept(mutate(\o->o {nmoLexical=lexical {nloWord="Other"}}))==Nothing)
     ,expect "rare contrary POS cannot be inserted into certificate"
       (accept(mutate(\o->o {nmoLexical=lexical {nloWrittenPOS=[("NNP",100),("NN",1)]}}))==Nothing)
     ,expect "source-category repair cannot be relabeled"
       (accept(mutate(\o->o {nmoLexical=lexical {nloCategoryStep=LexicalNameNRepair}}))==Nothing)
     ,expect "inconsistent effective lookup cannot be relabeled"
       (accept(mutate(\o->o {nmoLexical=lexical {nloEffective="other"}}))==Nothing)
     ,expect "lowercase contrary evidence blocks certificate"
       (accept(mutate(\o->o {nmoLexical=lexical {nloLowercasePOS=[("JJ",1)]}}))==Nothing)
     ,expect "wrong subject semantic type rejected" (accept(subject {ssSem=entity "Ari"})==Nothing)
     ,expect "pending coordinator cannot enter nominal subject" (accept(subject {ssCoord=Just "and"})==Nothing)
     ,expect "structural punctuation cannot enter nominal subject" (accept(subject {ssStructural=Just ","})==Nothing)
     ,expect "generic unary provenance cannot reuse lexical origin"
       (accept(subject {ssProv=provRule "unary" [ssProv subject]})==Nothing)
     ,expect "pending conditional origin cannot enter nominal subject"
       (accept(subject {ssOpenConditional=True})==Nothing)
     ,expectEq "packing distinguishes optional certified and plain same-term subjects" 2
       (length(packCell 20 [subject,plain]))
     ,expect "actual N and NP lexical sources both survive to Complete"
       (any(hasSource "N") sameTermRoots && any(hasSource "NP") sameTermRoots)
     ,expectEq "packing preserves actual N-vs-NP origins before final meaning dedup" 2
       (length(packCell 20 [s {ssNotes=[]}|s<-sameTermRoots]))
     ,expect "same-meaning final root dedup remains unchanged"
       (length(roots(mini ["NP","N"] [("NNP",4)]))==1)
     ,expect "NP[nb] source feature remains explicit" (any(hasSource "NP[nb]") npnb)
     ,expect "root requires complete declarative category" (nominalRootAllowed root &&
       not(nominalRootAllowed(root {ssCat=cc "NP"})))
     ,expect "unary cannot release NamedComplete" (not(nominalUnaryAllowed root))
     ,expect "all-NNP versus rare NN changes actual minting"
       (null(roots(mini ["NP"] [("NNP",100),("NN",1)])))
     ,expect "unknown name cannot mint despite source NP"
       (null(roots(mini ["NP"] [])))
     ] ++ [expect ("non-direct subject transition blocked: "++show comb)
         (nominalTransition comb (cc "S[dcl]") subject pending==Nothing)
        |comb<-allCombinators,comb/=BwdApp]
       ++ [expect ("complete embedding blocked: "++show comb)
         (nominalTransition comb (cc "S[dcl]") root subject==Nothing)
        |comb<-allCombinators])
  _->runChecks "nominal name origin" [bad "actual root retains typed named origin" "wrong nominal role"]
