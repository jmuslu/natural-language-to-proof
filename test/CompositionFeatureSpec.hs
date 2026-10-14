-- Corpus-free independent feature dependency and local scope controls.
module Main (main) where
import Control.Monad (unless)
import System.Exit (exitFailure)
import NL2Proof.Syntax.CCGBank (parseCCGCat)
import NL2Proof.Syntax.CCGRules
import NL2Proof.Semantics.CCGSem
import NL2Proof.Semantics.Lambda (typeOf)

main :: IO ()
main = do
 let cat = either error id . parseCCGCat
     run c l r = map snd (combineNamed [c] (cat l) (cat r))
     gives c l r want = run c l r == [cat want]
     vp = "S[dcl]\\NP"
     adj = "S[adj]\\NP"
     is = "(S[dcl]\\NP)/(S[adj]\\NP)"
     notB = "(S\\NP)\\(S\\NP)"
     notF = "(S\\NP)/(S\\NP)"
     crossed = run FwdXComp is notB
     accepts input = not (null [o | c <- crossed, (_,o) <- combineNamed [BwdApp] (cat input) c])
     lexical w c = case closedEntries 0 w (cat c) of
       LexTerm t _ _ : _ -> t
       _ -> error ("Missing lexical meaning: " ++ w)
     compositionTyped = case semTy (cat adj) of
       Just ty -> let term = composeTerm ty (lexical "is" is) (lexical "not" notB)
                  in case crossed of
                       [output] -> Just (typeOf [] term) == fmap Right (semTy output)
                       _ -> False
       _ -> False
     checks =
      [("specialized crossed is-not term has result semantic type", compositionTyped)
      ,("good backward crossed matrix is-not keeps adjective input", gives BwdXComp is "(S[dcl]\\NP)\\(S[dcl]\\NP)" is)
      ,("forward composition specializes endomorphic argument", gives FwdComp is notF "(S[dcl]\\NP)/(S[adj]\\NP)")
      ,("forward crossed specializes endomorphic argument", gives FwdXComp is notB "(S[dcl]\\NP)\\(S[adj]\\NP)")
      ,("backward composition specializes endomorphic argument", gives BwdComp notB "(S[dcl]\\NP)\\(S[adj]\\NP)" "(S[dcl]\\NP)\\(S[adj]\\NP)")
      ,("backward crossed specializes endomorphic argument", gives BwdXComp notF "(S[dcl]\\NP)\\(S[adj]\\NP)" "(S[dcl]\\NP)/(S[adj]\\NP)")
      ,("bad relative is-red plus crossed is-not is blocked", not (accepts vp))
      ,("adjective red plus crossed is-not remains licensed", accepts adj)
      ,("unrelated bare S argument remains bare", gives FwdComp "NP/S[dcl]" "S/NP" "NP/NP")
      ,("unrelated bare S inside distinct argument remains bare", gives FwdComp "NP/S[dcl]" "S/(S\\NP)" "NP/(S\\NP)")
      ,("unrelated output clause remains bare", gives FwdComp "S/S[dcl]" "S[dcl]/NP" "S/NP")
      ,("conflicting specified intermediate features rejected", null (run FwdComp "NP/S[dcl]" "S[adj]/NP"))
      ,("existing forward endomorphic result propagation retained", gives FwdComp "S/S" "S[dcl]/NP" "S[dcl]/NP")
      ,("both whole-category dependencies specialize", gives FwdComp "S/S" "S[dcl]/S[dcl]" "S[dcl]/S[dcl]")
      ,("backward existing result propagation retained", gives BwdComp "S[dcl]\\NP" "S\\S" "S[dcl]\\NP")
      ,("ordinary is-red finite predicate remains licensed", gives FwdApp is adj vp)]
 mapM_ (\(n,ok)->putStrLn ((if ok then "PASS " else "FAIL ")++n)) checks
 unless (all snd checks) exitFailure
