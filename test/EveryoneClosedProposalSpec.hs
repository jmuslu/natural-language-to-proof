-- Pure lexical API red controls, no parser/model/corpus load.
module Main (main) where
import Harness
import NL2Proof.Semantics.CCGSem
import NL2Proof.Semantics.Lambda
import NL2Proof.Syntax.CCGBank (parseCCGCat)

entry word category = [canonicalAC (normalize tm) | LexTerm tm _ _ <- closedEntries 0 word (cc category)]
cc = either error id . parseCCGCat
x = Var "x"
p = Var "P"
q = Var "Q"
person = App (pred1 "person") x
standalone = Lam "P" tyPred1 (TForall "x" TyE (TImp person (App p x)))
restricted = Lam "P" tyPred1 (Lam "Q" tyPred1 (TForall "x" TyE (TImp (TAnd person (App p x)) (App q x))))
main = runChecks "everyone-closed-proposal-expected-red"
 [expect "RED Everyone is reserved case-insensitively" (isClosedClass "Everyone")
 ,expectEq "RED standalone everyone NP is person-universal" [canonicalAC standalone] (entry "everyone" "NP")
 ,expect "RED paired everyone has person-restricted head" (case restrictedPronounEntries "Everyone" of
    Just (LexTerm tm _ _,_) -> canonicalAC tm == canonicalAC restricted
    _ -> False)
 ,expect "source N is not a free closed noun predicate" (null (entry "everyone" "N"))
 ,expect "conj NP is not an ordinary everyone entry" (null (entry "everyone" "NP[conj]"))
 ,expectEq "literal people retains person property" [canonicalAC (Lam "x" TyE person)] (entry "people" "N")
 ,expectEq "literal things retains thing property" [canonicalAC (Lam "x" TyE (App (pred1 "thing") x))] (entry "things" "N")
 ,expectEq "someone retains existential person" [canonicalAC (Lam "P" tyPred1 (TExists "x" TyE (TAnd person (App p x))))] (entry "someone" "NP")
 ,expectEq "everything retains existing unrestricted universal" [canonicalAC (Lam "P" tyPred1 (TForall "x" TyE (App p x)))] (entry "everything" "NP")
 ]
