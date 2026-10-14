-- Actual public chart controls; authored before the optional parser API.
module Main(main) where
import qualified Data.Map.Strict as M
import qualified Data.Set as Set
import Harness
import System.Process(readProcessWithExitCode)
import System.Exit(ExitCode(..))
import NL2Proof.Provenance
import NL2Proof.Semantics.CCGSem(LexItem(..))
import NL2Proof.Semantics.Lambda
import NL2Proof.Syntax.CCGBank(CCat,parseCCGCat,eraseFeatures)
import NL2Proof.Syntax.CCGRules (addConjFeat)
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
          ,("red-hot","S[adj]\\NP","JJ"),("or","conj","CC"),("and","conj","CC"),(".",".",".")
          ,(",",",",","),("(",",",","),(")",",",","),("-",",",","),("[",",",","),("]",",",",")]
parseWith :: SemModel -> String -> String -> [SSign]
parseWith m source=spRoots . semParse m (SourceId source) . casedTokens 0
roots :: String -> [SSign]
roots=parseWith mini "either-chart"
no :: String -> Check
no text=expect ("bounded chart rejects: "++text)(null(roots text))
main :: IO ()
main=do
     private <- privateControls
     let text="Bob is either red or big."
         target=TOr(App(pred1 "red")(entity "Bob"))(App(pred1 "big")(entity "Bob"))
         got=roots text
         exact s=alphaEq(ssSem s)target && case pairedOrOrigins s of
           Right(Just(t,origins))->t==ssSem s && M.size origins==1 && all
              (\o->ooOrProv o==ProvLex(SourceId "either-chart")(Span 18 20)"or"
                && ooEitherProv o==Just(ProvLex(SourceId "either-chart")(Span 7 13)"either")) (M.elems origins)
           _->False
         replaceTag tag=mini {smTags=(smTags mini){tmWord=M.insert "either" [(cc tag,1)](tmWord(smTags mini))}}
         vp=cc "S[adj]\\NP"
         cats=map cc ["NP","S[dcl]","S[dcl]\\NP","(S[dcl]\\NP)/(S[adj]\\NP)","(S[adj]\\NP)/(S[adj]\\NP)","S[adj]\\NP","conj","."]++[addConjFeat vp]
         allSeen=Set.fromList[(eraseFeatures a,eraseFeatures b)|a<-cats,b<-cats]
         seen=mini{smSeenRules=True,smSeen=allSeen}
         ordinary=mini {smEitherPolicy=EitherLegacyDisabled}
         lexSnapshot m=[(show(lxCat l),show(lxItem l),lxScore l)|l<-lexicalSigns m 2 "either"]
     runChecks "either actual chart" $ private ++
       [expect "actual paired root exists and every retained root exact/local"(not(null got)&&all exact got)
          ,expect "ordinary OR remains unpaired"(not(null(roots "Bob is red or big.")) && all
          (\s->pairedOrOrigins s==Right Nothing)(roots "Bob is red or big."))
          ,expect "legacy explicit disable leaves no new identity candidate"(null(lexSnapshot ordinary))
          ,expect "enabled reserves offered N/N"(null(lexSnapshot(replaceTag "N/N")))
          ,expect "legacy preserves N/N property fallback"(not(null(lexSnapshot((replaceTag "N/N"){smEitherPolicy=EitherLegacyDisabled}))))
          ,expect "case variants retain actual lexical origins"(not(null(roots "Bob is EITHER red OR big.")))
          ,expect "mixed hyphen adjective remains eligible"(not(null(roots "Bob is either red-hot or big.")))
          ,expect "complete seen-pair set admits actual pair"(not(null(parseWith seen "seen" text)))
          ,expect "missing actual either application source pair rejects"(null(parseWith(seen{smSeen=Set.delete(eraseFeatures(cc "(S[adj]\\NP)/(S[adj]\\NP)"),eraseFeatures vp)allSeen}) "seen" text))
          ,expect "missing explicit OR source pair rejects"(null(parseWith(seen{smSeen=Set.delete(eraseFeatures(cc "conj"),eraseFeatures vp)allSeen}) "seen" text))
       ] ++ concat [[expect ("offered punctuation witness "++p)(all (not.null.lexicalSigns mini 4.tokText)(casedTokens 0 p)),no("Bob is either red "++p++" or big.")] |p<-["(",")","..."]]
       ++ map no ["Bob, is either red or big.","Bob ( is either red or big.","Bob is either red -- or big.","Bob is either red [ or big.","Bob is either red ] or big.","Bob is either red.","Bob is either red and big.","Bob is either either red or big."
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

-- Private GHCi harness exercises real lexical producers without exporting
-- constructors or copying the admission implementation into the test.
privateControls :: IO [Check]
privateControls = do
 (code,out,err)<-readProcessWithExitCode "ghci" ["-ignore-dot-ghci","-v0","-isrc","-itest","test/EitherChartSpec.hs"] (unlines privateScript)
 pure [expect label (code==ExitSuccess && wanted `elem` lines out && null err) | (label,wanted)<-privateExpected]

privateExpected :: [(String,String)]
privateExpected = [("actual private producer completes only direct pair", "PRIVATE-0:True"), ("every alternate pending combinator fails", "PRIVATE-1:True"), ("every alternate left-pair combinator fails", "PRIVATE-2:True"), ("missing payload cannot enter pending application", "PRIVATE-3:True"), ("foreign lexical provenance cannot enter pending application", "PRIVATE-4:True"), ("wrong offered feature cannot enter pending application", "PRIVATE-5:True"), ("missing selected OR origin cannot close pair", "PRIVATE-6:True"), ("same term and category without pending origin cannot gain marker", "PRIVATE-7:True"), ("altered pending token index fails actual marker", "PRIVATE-8:True"), ("pending and ordinary identical term signs pack separately", "PRIVATE-9:True"), ("actual type-raising semantics cannot downgrade pending origin", "PRIVATE-10:True")]

privateScript :: [String]
privateScript =
 [":module + *NL2Proof.Syntax.CCGSemParse",
  "let el i w c = head [ SSign c tm pv 0 Nothing structural False False Nothing FusedPlain NominalPlain (lexicalOrState Main.mini (i,i+1) pv c tm origin) [] | (l,origin)<-lexicalChoices Main.mini i w,lxCat l==c,let pv=ProvLex (SourceId \"private\") (Span (10*i) (10*i+length w)) w,let (tm,structural)=case lxItem l of {LexTerm t _ _->(finish t,Nothing);LexStructural _->(Con w TyT,Just w)}]",
  "let v=Main.cc \"S[adj]\\\\NP\"",
  "let e=el 0 \"either\" (Main.cc \"(S[adj]\\\\NP)/(S[adj]\\\\NP)\")",
  "let a=el 1 \"red\" v",
  "let o=el 2 \"or\" (Main.cc \"conj\")",
  "let b=el 3 \"big\" v",
  "let Just left=semCombineEither Main.mini FwdApp v e a",
  "let Just right=semCombineEither Main.mini CoordMark (addConjFeat v) o b",
  "putStrLn (\"PRIVATE-0:\" ++ show (maybe False eitherMandatory (semCombineEither Main.mini CoordApply v left right)))",
  "putStrLn (\"PRIVATE-1:\" ++ show (null [() | c<-allCombinators,c/=FwdApp,Just _<-[semCombineEither Main.mini c v e a]]))",
  "putStrLn (\"PRIVATE-2:\" ++ show (null [() | c<-allCombinators,c/=CoordApply,Just _<-[semCombineEither Main.mini c v left right]]))",
  "putStrLn (\"PRIVATE-3:\" ++ show (case semCombineEither Main.mini FwdApp v (e{ssOrState=Nothing}) a of {Nothing->True;_->False}))",
  "putStrLn (\"PRIVATE-4:\" ++ show (case semCombineEither Main.mini FwdApp v (e{ssProv=ProvLex (SourceId \"other\") (Span 0 6) \"either\"}) a of {Nothing->True;_->False}))",
  "putStrLn (\"PRIVATE-5:\" ++ show (case semCombineEither Main.mini FwdApp v (e{ssCat=Main.cc \"(S[dcl]\\\\NP)/(S[dcl]\\\\NP)\"}) a of {Nothing->True;_->False}))",
  "putStrLn (\"PRIVATE-6:\" ++ show (let o2=o{ssOrState=fmap (\\st->st{osMarker=Nothing}) (ssOrState o)} in case semCombineEither Main.mini CoordMark (addConjFeat v) o2 b >>= semCombineEither Main.mini CoordApply v left of {Nothing->True;_->False}))",
  "putStrLn (\"PRIVATE-7:\" ++ show (let e2=e{ssOrState=ordinaryOrState Main.mini (0,1) (ssProv e) (ssSem e)} in case semCombineEither Main.mini FwdApp v e2 a >>= \\l->semCombineEither Main.mini CoordApply v l right of {Just r->not(eitherMandatory r);Nothing->False}))",
  "putStrLn (\"PRIVATE-8:\" ++ show (let e2=e{ssOrState=fmap (\\st->st{osCover=(1,2)}) (ssOrState e)} in case semCombineEither Main.mini FwdApp v e2 a of {Nothing->True;_->False}))",
  "putStrLn (\"PRIVATE-9:\" ++ show (let e2=e{ssOrState=ordinaryOrState Main.mini (0,1) (ssProv e) (ssSem e)} in length(packCell 20 [e,e2])==2))",
  "putStrLn (\"PRIVATE-10:\" ++ show (let target=CSlash Fwd (CAtom \"S\" []) (CSlash Bwd (CAtom \"S\" []) (ssCat e) []) [] in case unarySem (ssCat e) target of {Just(f,_)->case ordinaryUnaryState e (f(ssSem e)) of {Nothing->True;_->False};Nothing->False}))",
  ":quit"]
