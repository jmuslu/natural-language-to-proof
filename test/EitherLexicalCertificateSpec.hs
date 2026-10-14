-- Corpus-free evidence/semantic controls for a future lexical certificate.
-- No enabled policy or private certificate is implemented by this test.
module Main(main) where
import qualified Data.Set as Set
import Harness
import NL2Proof.Provenance
import NL2Proof.Semantics.CCGSem
import NL2Proof.Semantics.Lambda
import NL2Proof.Syntax.CCGBank(CCat,parseCCGCat)
import NL2Proof.Syntax.CCGParse(Rules(..))
import NL2Proof.Syntax.CCGRules(Combinator(..),combineNamed)
import NL2Proof.Syntax.CCGSemParse
import NL2Proof.Syntax.CCGSupertag(buildPOSModel,buildTagModel)
import NL2Proof.Syntax.Tokenize
cc :: String -> CCat
cc=either error id . parseCCGCat
model :: String -> String -> SemModel
model w c=(defaultSemModel(buildTagModel[(w,cc c)])
 (buildPOSModel[(w,"RB")])(Rules [] []) Set.empty){smAlpha=0,smSeenRules=False}
lexemes :: String -> String -> [LexSign]
lexemes w c=lexicalSigns(model w c) 0 w
vp :: String
vp="S[adj]\\NP"
modifier :: String
modifier="(S[adj]\\NP)/(S[adj]\\NP)"
meaning :: [LexSign] -> [Term]
meaning ls=[t|LexSign _ (LexTerm t _ _) _<-ls]
main :: IO ()
main=runChecks "either lexical certificate evidence" $
 [expect "legacy either is not globally reserved" (not(isClosedClass "either"))
 ,expect "legacy offered adjective VP modifier has no interpreted leaf" (null(lexemes "either" modifier))
 ,expect "legacy offered finite VP modifier has no interpreted leaf"
    (null(lexemes "either" "(S[dcl]\\NP)/(S[dcl]\\NP)"))
 ,expect "legacy N/N fallback is an actual property, not identity"
    (case meaning(lexemes "either" "N/N") of
      [t]->alphaEq t (Lam "P" tyPred1(Lam "x" TyE(TAnd(App(pred1 "either")(Var "x"))(App(Var "P")(Var "x")))))
      _->False)
 ,expectEq "VP semantic type is generalized-quantifier-to-truth"
    (Just(tyGQ ~> TyT))(semTy(cc vp))
 ,expectEq "modifier semantic type is V-to-V"
    (Just((tyGQ ~> TyT) ~> (tyGQ ~> TyT)))(semTy(cc modifier))
 ,expect "surface finite and adjective VPs share type but not category"
    (semTy(cc vp)==semTy(cc "S[dcl]\\NP") && cc vp/=cc "S[dcl]\\NP")
 ,expectEq "direct pending application category step"
    [(FwdApp,cc vp)](combineNamed [FwdApp](cc modifier)(cc vp))
 ,expect "generic grammar permits dangerous modifier composition"
    (not(null(combineNamed [FwdComp](cc modifier)(cc modifier))))
 ,expectEq "punctuation survives cased tokenization; cannot be ignored in a pairing interval"
    ["either",",","red","or","big"](map tokText(casedTokens 0 "either, red or big"))
 ,expectEq "token spans preserve actual document offsets"
    [Span 10 16,Span 18 21,Span 22 24,Span 25 28]
    (map tokSpan(casedTokens 10 "either  red or big"))
 ,expectEq "hyphenated either-or remains one lexical token"
    ["either-or"](map tokText(casedTokens 0 "either-or"))
 ,expectEq "apostrophe is not normalized away to the marker"
    ["either's"](map tokText(casedTokens 0 "either's"))
 ,expectEq "quote boundaries are explicit token positions"
    ["\"","either","\""] (map tokText(casedTokens 0 "\"either\""))
 ,expectEq "repeated markers remain separate occurrences"
    [Span 0 6,Span 7 13](map tokSpan(casedTokens 0 "either either"))
 ] ++
 [expect ("legacy unsupported source category stays unsupported: "++c)(null(lexemes "either" c))
 |c<-["NP","NP/N","S/S","(S[em]\\NP)/(S[em]\\NP)"]]
 ++ scopeControls

-- Independent hand-scoped meanings, not toDRS/parser output used as gold.
scopeControls :: [Check]
scopeControls=case coordTerm TOr (tyGQ ~> TyT) (property "red") (property "big") of
 Nothing->[bad "actual VP coordination exists" "coordTerm rejected V"]
 Just joined->
  let qSome=Lam "k" tyPred1(TExists "x" TyE(App(Var "k")(Var "x")))
      qAll=Lam "k" tyPred1(TForall "x" TyE(TImp(App(pred1 "person")(Var "x"))(App(Var "k")(Var "x"))))
      qName=Lam "k" tyPred1(App(Var "k")(entity "Ari"))
      red x=App(pred1 "red")x; big x=App(pred1 "big")x
      scopeSome=TExists "x" TyE(TOr(red(Var "x"))(big(Var "x")))
      scopeAll=TForall "x" TyE(TImp(App(pred1 "person")(Var "x"))(TOr(red(Var "x"))(big(Var "x"))))
      splitAll=TOr(TForall "x" TyE(TImp(App(pred1 "person")(Var "x"))(red(Var "x"))))
                    (TForall "x" TyE(TImp(App(pred1 "person")(Var "x"))(big(Var "x"))))
  in [expectEq "coordinated VP retains V type" (Right(tyGQ ~> TyT))(typeOf [] joined)
     ,expect "named scope is inclusive OR"(alphaEq(normalize(App joined qName))(TOr(red(entity "Ari"))(big(entity "Ari"))))
     ,expect "one existential binder scopes above OR"(alphaEq(normalize(App joined qSome))scopeSome)
     ,expect "universal subject scopes above OR"(alphaEq(normalize(App joined qAll))scopeAll)
     ,expect "pointwise OR of whole universal propositions is not the intended term"
       (not(alphaEq(normalize(App joined qAll))splitAll))]
 where property w=Lam "Q" tyGQ(App(Var "Q")(pred1 w))
