-- Proposal algebra and current admission boundaries only. No parser/corpus load.
module Main (main) where
import Harness
import NL2Proof.Semantics.CCGSem
import NL2Proof.Semantics.Lambda
import NL2Proof.Syntax.CCGBank (parseCCGCat)

main :: IO ()
main = runChecks "operator-gap-proposal" $
  [expect "no global context-free but operator admitted" (case coordinatorOp "but" of Nothing -> True; _ -> False)
  ,expect "exceptive NP but remains unlicensed" (null (closedEntries 0 "but" (cc "(NP\\NP)/NP")))
  ,expect "nominal but remains unlicensed" (null (closedEntries 0 "but" (cc "(N\\N)/N")))
  ,expect "both ellipsis is not a lexical adjective fix" (null (closedEntries 0 "both" (cc "N/N")))
  ,expectEq "proposed complete clausal contrast truth conditions" (Just (TAnd p q)) (coordTerm TAnd TyT p q)
  ,expect "XOR differs from conjunction" (xor True False && not (True && False))
  ,expect "not-both alone wrongly admits neither" (not (False && False) && not (xor False False))
  ,expect "inclusive OR must retain both-true" ((True || True) && not (xor True True))
  ,expect "corrective narrow negation differs from wide negation" (not (True && False) /= (not True && False))
  ,expect "per-person XOR is not global exclusion" (not (all (uncurry xor) [(True,True),(True,False)]) && all (uncurry (||)) [(True,True),(True,False)] && not (and [True,True] && and [True,False]))
  ,expect "exceptive restriction is not conjunction with Bob" (not (all id [True,False]) && all id [True])
  ,expect "mixed OR/AND grouping cannot flatten to OR" (((False || False) && True) /= (False || False || True))
  ] ++ [expectEq ("XOR truth row " ++ show (a,b)) (a /= b) (xor a b) | a <- [False,True], b <- [False,True]]
 where
  p = App (pred1 "tall") (entity "Bob")
  q = App (pred1 "quiet") (entity "Bob")
  cc = either error id . parseCCGCat
  xor a b = (a || b) && not (a && b)
