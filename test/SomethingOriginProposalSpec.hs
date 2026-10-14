-- Independent domain-contract controls, miniature parser only.
-- Red controlled-domain expectations are not authorized default replacements.
module Main(main) where
import qualified Data.Set as Set
import Harness
import NL2Proof.DRT.Canonical
import NL2Proof.Pipeline
import NL2Proof.Provenance
import NL2Proof.Semantics.CCGSem
import NL2Proof.Semantics.Lambda
import NL2Proof.Syntax.CCGBank(parseCCGCat)
import NL2Proof.Syntax.CCGParse(Rules(..))
import NL2Proof.Syntax.CCGSemParse
import NL2Proof.Syntax.CCGSupertag(buildTagModel,buildPOSModel)
import NL2Proof.Verify.ClaimKind(claimCond)
import NL2Proof.Verify.Reported(splitClaims)
cc=either error id . parseCCGCat
entry word category=[canonicalAC(normalize t)|LexTerm t _ _<-closedEntries 0 word(cc category)]
x=Var "x"
thing=App(pred1 "thing")x
current=Lam "P" tyPred1(TExists "x" TyE(TAnd thing(App(Var "P")x)))
model headCat=(defaultSemModel(buildTagModel[(w,cc c)|(w,c,_)<-entries])
 (buildPOSModel[(w,p)|(w,_,p)<-entries])(Rules [] [])Set.empty){smAlpha=0,smSeenRules=False}
 where entries=[("Something",headCat,"NN"),("something",headCat,"NN"),
        ("is","(S[dcl]\\NP)/(S[adj]\\NP)","VBZ"),
        ("quiet","S[adj]\\NP","JJ"),("red","S[adj]\\NP","JJ"),
        ("not","(S[adj]\\NP)/(S[adj]\\NP)","RB"),
        ("and","conj","CC"),("that","(NP\\NP)/(S[dcl]\\NP)","WDT"),
        ("Mira","NP","NNP"),("sees","(S[dcl]\\NP)/NP","VBZ"),(".",".",".")]
p n=CanPred n [CRefT(CRef 0)]
box=Canonical []
neg n=CanNot(box[p n])
check label text conditions asserted embedded=
 let s=case prSentences(runPipelineWith(CCGBankParser(model "NP"))(SourceId "something-domain")text) of
         [one]->one;_->error "single fixture required"
     wanted=Canonical [CRef 0] conditions
     claims=case srDRS s of
       Just d->let(as,rs,ps,es)=splitClaims d in
          map(claimCond.fst)as==asserted && map claimCond es==embedded && null rs && null ps
       _->False
 in [expectEq(label++" selected: "++text)(Just wanted)(canonicalize <$> srDRS s),
     expect(label++" claims: "++text)claims,
     expect(label++" all retained: "++text)(not(null(srReadings s))&&all
        ((==Just wanted).fmap canonicalize.rrDRS)(srReadings s))]
main=runChecks "something origin/domain proposal"
 ([expect "case-insensitive reservation"(isClosedClass "Something"),
   expectEq "current exact NP entry retains thing domain"[canonicalAC current](entry "something" "NP"),
   expect "fused relative is deliberately unimplemented"(case restrictedPronounEntries "something" of Nothing->True;_->False)]
 ++[expect ("unsupported category not promoted: "++category)(null(entry "something" category))
     |category<-["N","NP[expl]","NP[conj]","NP/N","N/N"]]
 ++[expect "offered N cannot mint a lexical something predicate"(null(lexicalSigns(model "N")0 "Something"))]
 ++concat[check "current thing-domain" text (p "thing":scope)(p "thing":scope)embedded
       |(text,scope,embedded)<-[("Something is quiet.",[p "quiet"],[]),
                              ("Something is red.",[p "red"],[]),
                              ("Something is not quiet.",[neg "quiet"],[p "quiet"]),
                              ("Something is not red.",[neg "red"],[p "red"])]]
 ++concat[check "proposed separate controlled-domain" text scope scope embedded
       |(text,scope,embedded)<-[("Something is quiet.",[p "quiet"],[]),
                              ("Something is red.",[p "red"],[]),
                              ("Something is not quiet.",[neg "quiet"],[p "quiet"]),
                              ("Something is not red.",[neg "red"],[p "red"])]]
 ++check "one witness across VP conjunction" "Something is red and quiet."
      [p "thing",p "red",p "quiet"] [p "thing",p "red",p "quiet"] []
 ++let relation=CanPred "see" [CConstT "Mira",CRefT(CRef 0)]
   in check "ordinary object existential" "Mira sees something." [p "thing",relation] [p "thing",relation] []
 ++check "future guarded relative with current domain" "Something that is red is quiet."
      [p "thing",p "red",p "quiet"] [p "thing",p "red",p "quiet"] []
 ++check "future relative nested restriction negation" "Something that is not red is quiet."
      [p "thing",neg "red",p "quiet"] [p "thing",neg "red",p "quiet"] [p "red"]
 ++check "future relative with matrix negation" "Something that is red is not quiet."
      [p "thing",p "red",neg "quiet"] [p "thing",p "red",neg "quiet"] [p "quiet"])
