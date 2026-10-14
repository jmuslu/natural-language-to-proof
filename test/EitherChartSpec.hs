-- Actual public chart controls; authored before the optional parser API.
module Main(main) where
import qualified Data.Map.Strict as M
import qualified Data.Set as Set
import Harness
import NL2Proof.Provenance
import NL2Proof.Semantics.CCGSem(LexItem(..))
import NL2Proof.Semantics.Lambda
import NL2Proof.Syntax.CCGBank(CCat,parseCCGCat)
import NL2Proof.Syntax.CCGParse(Rules(..))
import NL2Proof.Syntax.CCGSemParse
import NL2Proof.Syntax.CCGSupertag
import NL2Proof.Syntax.Tokenize
cc :: String -> CCat
cc=either error id . parseCCGCat
mini :: SemModel
mini=(defaultSemModel(buildTagModel[(w,cc c)|(w,c,p)<-entries])
 (buildPOSModel[(w,p)|(w,c,p)<-entries])(Rules [] []) Set.empty)
 {smAlpha=0,smSeenRules=False,smEitherPolicy=EitherSurfaceInclusiveV1}
 where
  entries=[("Bob","NP","NNP"),("Mira","NP","NNP")
          ,("is","(S[dcl]\\NP)/(S[adj]\\NP)","VBZ")
          ,("either","(S[adj]\\NP)/(S[adj]\\NP)","RB")
          ,("red","S[adj]\\NP","JJ"),("big","S[adj]\\NP","JJ")
          ,("or","conj","CC"),("and","conj","CC"),(".",".",".")
          ,(",",",",",")]
parseWith :: SemModel -> String -> String -> [SSign]
parseWith m source=spRoots . semParse m (SourceId source) . casedTokens 0
roots :: String -> [SSign]
roots=parseWith mini "either-chart"
no :: String -> Check
no text=expect ("bounded chart rejects: "++text)(null(roots text))
main :: IO ()
main=let text="Bob is either red or big."
         target=TOr(App(pred1 "red")(entity "Bob"))(App(pred1 "big")(entity "Bob"))
         got=roots text
         exact s=alphaEq(ssSem s)target && case pairedOrOrigins s of
           Right(Just(t,origins))->t==ssSem s && M.size origins==1 && all
              (\o->ooOrProv o==ProvLex(SourceId "either-chart")(Span 18 20)"or"
                && ooEitherProv o==Just(ProvLex(SourceId "either-chart")(Span 7 13)"either")) (M.elems origins)
           _->False
         replaceTag tag=mini {smTags=(smTags mini){tmWord=M.insert "either" [(cc tag,1)](tmWord(smTags mini))}}
         ordinary=mini {smEitherPolicy=EitherLegacyDisabled}
         lexSnapshot m=[(show(lxCat l),show(lxItem l),lxScore l)|l<-lexicalSigns m 2 "either"]
     in runChecks "either actual chart" $
       [expect "actual paired root exists and every retained root exact/local"(not(null got)&&all exact got)
          ,expect "ordinary OR remains unpaired"(not(null(roots "Bob is red or big.")) && all
          (\s->pairedOrOrigins s==Right Nothing)(roots "Bob is red or big."))
          ,expect "legacy explicit disable leaves no new identity candidate"(null(lexSnapshot ordinary))
          ,expect "enabled reserves offered N/N"(null(lexSnapshot(replaceTag "N/N")))
          ,expect "legacy preserves N/N property fallback"(not(null(lexSnapshot((replaceTag "N/N"){smEitherPolicy=EitherLegacyDisabled}))))
       ] ++ map no ["Bob is either red.","Bob is either red and big.","Bob is either either red or big."
             ,"Bob is either, red or big.","Bob is either red, or big.","Bob is either red or, big."
             ,"Bob is either red or big and red.","Either Bob is red or big."
             ,"Bob is either red or big, red.","Bob is either red or big but not both."]
       ++ [expect ("unsupported either category: "++tag)(null(parseWith(replaceTag tag)"either-chart"text))
           |tag<-["N/N","NP","NP/N","S/S","(S[em]\\NP)/(S[em]\\NP)","(S[dcl]\\NP)/(S[adj]\\NP)","(S[adj]\\NP)\\(S[adj]\\NP)"]]
       ++ case got of
        []->[bad "actual-origin adversarial controls have witness" "no root"]
        root:_->let foreignRoots=parseWith mini "foreign" text
                    altered=root {ssSem=App(pred1 "red")(entity "Bob")}
                in [expect "foreign provenance cannot retain actual origin"(case pairedOrOrigins(root{ssProv=ProvLex(SourceId "foreign")(Span 0 24)text})of Left _->True;_->False)
                      ,expect "changed semantic snapshot rejected"(case pairedOrOrigins altered of Left _->True;_->False)
                      ,expect "wrong root category rejected"(case pairedOrOrigins(root{ssCat=cc "NP"})of Left _->True;_->False)
                      ,expectEq "same terms from actual distinct source origins stay packed separately"2(length(packCell 20(root:take 1 foreignRoots)))
                      ,expect "copying actual state to a different root provenance rejected"(case foreignRoots of
                      f:_->case pairedOrOrigins(f{ssOrState=ssOrState root})of Left _->True;_->False
                      _->False)]
