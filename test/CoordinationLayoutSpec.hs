module Main (main) where
import Harness
import NL2Proof.Semantics.CCGSem
import NL2Proof.Semantics.Lambda

-- Independent read-only address observer, not a coordination builder.
at :: [Int] -> Term -> Maybe Term
at [] t = Just t
at (i:is) t = case (i,t) of
  (0,Lam _ _ x) -> at is x
  (0,App x _) -> at is x
  (1,App _ y) -> at is y
  (0,TAnd x _) -> at is x
  (1,TAnd _ y) -> at is y
  (0,TOr x _) -> at is x
  (1,TOr _ y) -> at is y
  _ -> Nothing

vp :: String -> Term
vp p = Lam "S" tyGQ (App (Var "S") (pred1 p))
tv :: String -> Term
tv p = Lam "O" tyGQ (Lam "S" tyGQ (App (Var "S")
  (Lam "s" TyE (App (Var "O") (Lam "o" TyE
    (App (App (pred2 p) (Var "s")) (Var "o")))))))
a,b :: Term
a = vp "red"
b = vp "blue"
person :: Term
person = App (pred1 "person") (Var "x")
quant :: (Term -> Term) -> Term
quant body = Lam "P" tyPred1 (body (App (Var "P") (Var "x")))
some,none,every :: Term
some = quant (TExists "x" TyE . TAnd person)
none = quant (TNot . TExists "x" TyE . TAnd person)
every = quant (TForall "x" TyE . TImp person)
joined :: Term
joined = TOr (App (pred1 "red") (Var "x")) (App (pred1 "blue") (Var "x"))
scoped :: Term -> Term -> Bool
scoped q expected = case coordTermLocated CoordOr (tyGQ ~> TyT) a b of
  Just layout -> alphaEq (normalize (App (clTerm layout) q)) expected
  Nothing -> False

layoutOK :: CoordOp -> Ty -> Term -> Term -> Bool
layoutOK op ty left right = case coordTermLocated op ty left right of
  Just l -> clTerm l == maybe (Var "missing") id (coordTerm con ty left right)
    && at (clLeftPath l) (clTerm l) == Just left
    && at (clRightPath l) (clTerm l) == Just right
    && clLeftPath l /= clRightPath l
    && case at (clOperatorPath l) (clTerm l) of
         Just TAnd{} -> op == CoordAnd
         Just TOr{} -> op == CoordOr
         _ -> False
  Nothing -> False
  where con = case op of CoordAnd -> TAnd; CoordOr -> TOr

main :: IO ()
main = runChecks "coordination-layout" $
  [expect "universal subject above OR" (scoped every (TForall "x" TyE (TImp person joined)))
  ,expect "indefinite subject shares one witness" (scoped some (TExists "x" TyE (TAnd person joined)))
  ,expect "negative subject above OR" (scoped none (TNot (TExists "x" TyE (TAnd person joined))))
  ,expect "VP layout exact introduced site" (fmap clOperatorPath (coordTermLocated CoordOr (tyGQ~>TyT) a b)==Just [0,1,0])
  ,expect "VP original operand embedding addresses"
      (fmap (\l -> (clLeftPath l,clRightPath l))
        (coordTermLocated CoordOr (tyGQ~>TyT) a b)
        ==Just ([0,1,0,0,0],[0,1,0,1,0]))
  ,expect "multiple NP slots exact introduced site"
      (fmap clOperatorPath (coordTermLocated CoordOr (tyGQ~>tyGQ~>TyT) (tv "like") (tv "see"))==Just [0,0,1,0,1,0])
  ,expect "all multiple NP slots scoped once in original order" multiScope
  ,expect "repeated identical OR children have different original roots"
      (layoutOK CoordOr TyT repeated repeated)
  ,expect "repeated OR under VP remains distinct from introduced OR"
      (layoutOK CoordOr (tyGQ~>TyT) nested nested)
  ,expect "identical nested OR sites preserved by child embeddings"
      (case coordTermLocated CoordOr (tyGQ~>TyT) nested nested of
         Just l -> clLeftPath l /= clRightPath l
           && at (clLeftPath l ++ [0,1,0]) (clTerm l) == Just joined
           && at (clRightPath l ++ [0,1,0]) (clTerm l) == Just joined
           && clOperatorPath l /= clLeftPath l ++ [0,1,0]
           && clOperatorPath l /= clRightPath l ++ [0,1,0]
         Nothing -> False)
  ,expect "original callback receives actual applied children in original order"
      (coordTerm (\x y -> TImp y x) TyT (Var "p") (Var "q")==Just(TImp (Var "q") (Var "p")))
  ,expect "arbitrary callback may discard a child unchanged"
      (coordTerm (\x _ -> x) (TyE~>TyT) (pred1 "red") (pred1 "blue")
        ==Just(Lam "c0" TyE (App (pred1 "red") (Var "c0"))))
  ,expect "entity codomain rejected" (coordTermLocated CoordOr TyE (entity "A") (entity "B")==Nothing)
  ,expect "world codomain rejected" (coordTermLocated CoordAnd TyS (Var "w") (Var "v")==Nothing)
  ] ++ [expect ("actual constructor paths " ++ show op ++ " " ++ show ty) (layoutOK op ty l r)
       | op<-[CoordAnd,CoordOr],(ty,l,r)<-
         [(TyT,App (pred1 "red") (entity "A"),App (pred1 "blue") (entity "B"))
         ,(tyPred1,pred1 "red",pred1 "blue")
         ,(tyGQ,some,every),(tyGQ~>TyT,a,b)
         ,(tyGQ~>tyGQ~>TyT,tv "see",tv "like")]]
  where
    repeated=TOr (App (pred1 "red") (entity "A")) (App (pred1 "blue") (entity "A"))
    nested=Lam "S" tyGQ (App (Var "S") (Lam "x" TyE joined))

multiScope :: Bool
multiScope = case coordTermLocated CoordOr (tyGQ~>tyGQ~>TyT) (tv "like") (tv "see") of
  Nothing -> False
  Just l -> alphaEq (normalize (App (App (clTerm l) object) subject)) expected
  where
    object=Lam "P" tyPred1 (TExists "o" TyE (TAnd (App (pred1 "cat") (Var "o")) (App (Var "P") (Var "o"))))
    subject=Lam "P" tyPred1 (TForall "s" TyE (TImp (App (pred1 "person") (Var "s")) (App (Var "P") (Var "s"))))
    rel p=App (App (pred2 p) (Var "s")) (Var "o")
    expected=TExists "o" TyE (TAnd (App (pred1 "cat") (Var "o"))
      (TForall "s" TyE (TImp (App (pred1 "person") (Var "s")) (TOr (rel "like") (rel "see")))))
