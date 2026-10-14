-- Executable transport proposal only. Does not modify/invoke the parser.
module Main (main) where
import qualified Data.Map as M
import Data.List (union)
import Harness
import NL2Proof.Semantics.Lambda
import NL2Proof.DRT.Types
import NL2Proof.Provenance
import NL2Proof.Bench.Export (drsJSON)
import NL2Proof.Bench.JSON

type Path = [Int]
data Cert = Cert { edge :: Int, paired :: Maybe Int } deriving (Eq,Ord,Show)
data Marked = Marked Term (M.Map Path Cert) deriving (Eq,Show)
term :: Marked -> Term
term (Marked t _) = t
marks :: Marked -> M.Map Path Cert
marks (Marked _ m) = m
plain :: Term -> Marked
plain t=Marked t M.empty
kids :: Term -> [Term]
kids t=case t of
 Lam _ _ a->[a]; TForall _ _ a->[a]; TExists _ _ a->[a]; TNot a->[a]
 App a b->[a,b]; TAnd a b->[a,b]; TOr a b->[a,b]; TImp a b->[a,b]; TEq a b->[a,b]
 _->[]
rebuild :: Term -> [Term] -> Term
rebuild t xs=case (t,xs) of
 (Lam v ty _,[a])->Lam v ty a
 (TForall v ty _,[a])->TForall v ty a
 (TExists v ty _,[a])->TExists v ty a
 (TNot _,[a])->TNot a
 (App _ _,[a,b])->App a b
 (TAnd _ _,[a,b])->TAnd a b
 (TOr _ _,[a,b])->TOr a b
 (TImp _ _,[a,b])->TImp a b
 (TEq _ _,[a,b])->TEq a b
 (_,[])->t
 _->error "invalid prototype reconstruction"
child :: Int -> Marked -> Marked
child i (Marked t m)=Marked (kids t!!i)
  (M.fromList [(ps,c)|(j:ps,c)<-M.toList m,j==i])
join :: Term -> Maybe Cert -> [Marked] -> Marked
join t own xs=Marked (rebuild t (map term xs)) (M.unions
 (maybe [] (\c->[M.singleton [] c]) own ++
 [M.mapKeys (i:) (marks x)|(i,x)<-zip [0..] xs]))
node :: Term -> [Marked] -> Marked
node t=join t Nothing
orAt :: Int -> Maybe Int -> Marked -> Marked -> Marked
orAt o e a b=join (TOr (term a) (term b)) (Just(Cert o e)) [a,b]
valid :: Marked -> Bool
valid x=all atOr(M.keys(marks x))
 where
  atOr p=case walk p(term x) of Just TOr{}->True; _->False
  walk [] t=Just t
  walk (i:is) t | i>=0 && i<length(kids t)=walk is(kids t!!i)
  walk _ _=Nothing
-- Renaming is capture avoiding and changes no constructor paths.
rename :: String -> String -> Marked -> Marked
rename a b (Marked t m)=Marked (subst a (Var b) t) m
replace :: String -> Marked -> Marked -> Marked
replace x s current@(Marked t m)=case t of
 Var v | v==x->s
 Lam v ty _->bind v (\w->Lam w ty (Var "unused"))
 TExists v ty _->bind v (\w->TExists w ty (Var "unused"))
 TForall v ty _->bind v (\w->TForall w ty (Var "unused"))
 _->join t (M.lookup [] m) [replace x s(child i current)|i<-[0..length(kids t)-1]]
 where
  bind v ctor | v==x=current
              | v `elem` freeVars(term s)=
                 let b=child 0 current
                     w=fresh (freeVars(term s) `union` freeVars(term b) `union` [x]) v
                 in node(ctor w)[replace x s(rename v w b)]
              | otherwise=node(ctor v)[replace x s(child 0 current)]
occurs :: String -> Term -> Int
occurs x t=case t of
 Var v->if x==v then 1 else 0
 Lam v _ _ | x==v->0
 TForall v _ _ | x==v->0
 TExists v _ _ | x==v->0
 _->sum(map(occurs x)(kids t))
norm :: Marked -> Either String Marked
norm current@(Marked t m)=case t of
 App _ _->do
  f<-norm(child 0 current)
  a<-norm(child 1 current)
  case term f of
   Lam v _ _->do
    let body=child 0 f
    if not(M.null(marks a)) && occurs v(term body)/=1
       then Left "marked argument duplicated or discarded"
       else norm(replace v a body)
   _->Right(node t[f,a])
 _->do
  cs<-mapM (norm . (`child` current)) [0..length(kids t)-1]
  Right(join t(M.lookup [] m)cs)
finish :: Marked -> Either String Marked
finish=finishIn []
finishIn :: Ctx -> Marked -> Either String Marked
finishIn ctx x | not(valid x)=Left "certificate not attached to OR"
finishIn ctx x=do
 ty<-case typeOf ctx(term x) of Left _->Left "ill-typed input"; Right t->Right t
 y<-norm x
 tyAfter<-case typeOf ctx(term y) of Left _->Left "ill-typed result"; Right t->Right t
 if ty/=tyAfter then Left "changed type" else Right ()
 if M.null(marks y) then Right(plain(simplifyConj(term y)))
 else if simplifyConj(term y)/=term y then Left "annotation-bearing conjunction rewrite deferred"
 else if valid y then Right y else Left "lost OR certificate"
-- Readout follows positions, not predicate/formula equality. This is the
-- proposed lowering callback input, not a replacement for existing DRT.Build.
readout :: Marked -> [(Path,Int,Bool)]
readout x=[(p,edge c,maybe False(const True)(paired c))|(p,c)<-M.toAscList(marks x)]
p,q :: Marked
p=plain(Con "P" TyT)
q=plain(Con "Q" TyT)
a,b :: Marked
a=orAt 10 (Just 1) p q
b=orAt 20 Nothing p q
imp,disj,app :: Marked -> Marked -> Marked
imp x y=node(TImp(term x)(term y))[x,y]
disj x y=orAt 30 Nothing x y
app x y=node(App(term x)(term y))[x,y]
lam :: String -> Ty -> Marked -> Marked
lam v ty x=node(Lam v ty(term x))[x]
passed :: Marked -> (Marked -> Bool) -> Bool
passed x predicate=case finish x of Right y->predicate y; _->False
rejected :: Marked -> Bool
rejected x=case finish x of Left _->True; _->False
-- Minimal Boolean lowering callback demonstration; quantifiers/attitudes
-- intentionally need separate production lowering tests.
lower :: Marked -> Either String DRS
lower root=go [] (term root)
 where
  src=SourceId "authored-occurrence-test"
  leaf n w=ProvLex src (Span n (n+1)) w
  fallback=leaf 100 "fixture"
  go path t=case t of
   TOr l r->case M.lookup path(marks root) of
    Nothing->Left "missing OR origin"
    Just c->do
     a'<-go(path++[0])l
     b'<-go(path++[1])r
     let pv=ProvRule(RuleName "CertifiedOrOccurrence")
          (leaf(edge c) "or":maybe [] (\n->[leaf n "either"])(paired c))
     Right(DRS [] [COr a' b' pv])
   TImp l r->do
    a'<-go(path++[0])l
    b'<-go(path++[1])r
    Right(DRS [] [CImp a' b' fallback])
   TNot t'->do
    a'<-go(path++[0])t'
    Right(DRS [] [CNot a' fallback])
   Con name TyT->Right(DRS [] [CPred name [] fallback])
   _->Left "outside Boolean lowering prototype"
flags :: JValue -> [(Bool,Bool)]
flags j@(JObj xs)=own++concatMap(flags.snd)xs
 where own=case(field "tag" j,field "either" j,field "either_scope_ambiguous" j)of
        (Just(JStr "or"),Just(JBool e),Just(JBool ambiguous))->[(e,ambiguous)]
        _->[]
flags(JArr xs)=concatMap flags xs
flags _=[]
exported :: Marked -> [(Bool,Bool)] -> Bool
exported input expected=case finish input >>= lower of
 Right d->flags(drsJSON d)==expected
 Left _->False
main :: IO ()
main=runChecks "either-occurrence-proposal"
 [expect "existing exporter obtains exact TF from local provenance" (exported(imp a b)[(True,False),(False,False)])
 ,expect "existing exporter obtains exact TT without fallback ambiguity" (exported(imp a(orAt 20(Just 2)p q))[(True,False),(True,False)])
 ,expect "existing exporter does not promote nested either to outer OR" (exported(disj a b)[(False,False),(True,False),(False,False)])
 ,expect "lowering rejects uncertified OR rather than sentence fallback" (case lower(plain(TOr(term p)(term q))) of Left _->True; _->False)
 ,expect "TF identical formulas retain distinct clause occurrences" (passed(imp a b)(\x->readout x==[([0],10,True),([1],20,False)]))
 ,expect "FT identical formulas retain distinct clause occurrences" (passed(imp b a)(\x->readout x==[([0],20,False),([1],10,True)]))
 ,expect "TT has two independently paired edges" (passed(imp a(orAt 20(Just 2)p q))(\x->readout x==[([0],10,True),([1],20,True)]))
 ,expect "nested plain outer OR does not inherit inner either" (passed(disj a b)(\x->readout x==[([],30,False),([0],10,True),([1],20,False)]))
 ,expect "beta identity moves certificate with argument" (passed(app(lam "x" TyT(plain(Var "x")))a)(\x->readout x==[([],10,True)]))
 ,expect "beta into consequent preserves local path" (passed(app(lam "x" TyT(imp b(plain(Var "x"))))a)(\x->readout x==[([0],20,False),([1],10,True)]))
 ,expect "marked beta duplication is explicitly rejected" (rejected(app(lam "x" TyT(imp(plain(Var "x"))(plain(Var "x"))))a))
 ,expect "marked beta deletion is explicitly rejected" (rejected(app(lam "x" TyT p)a))
 ,expect "same formula different evidence cannot be deduplicated" (rejected(node(TAnd(term a)(term b))[a,b]))
 ,expect "negation is a boundary not a marker source" (passed(node(TNot(term a))[a])(\x->readout x==[([0],10,True)]))
 ,expect "existential binder preserves internal occurrence" (passed(node(TExists "z" TyE(term a))[a])(\x->readout x==[([0],10,True)]))
 ,expect "capture avoidance retains free y and marker" (let { arg=orAt 11(Just 3)(plain(Var "y"))q
     ; input=app(lam "x" TyT(lam "y" TyT(plain(Var "x"))))arg
     } in case finishIn [("y",TyT)] input of Right x->freeVars(term x)==["y"] && readout x==[([0],11,True)] && alphaEq(term x)(normalize(term input)); _->False)
 ,expect "shadowed substitution is unchanged" (let input=app(lam "x" TyT(lam "x" TyT a))p
     in passed input(\x->readout x==[([0],10,True)]))
 ,expect "forged label on predicate rejected" (rejected(Marked(term p)(M.singleton[](Cert 10(Just 1)))))
 ,expect "transport erasure agrees with ordinary beta normalization" (all (\x->passed x(\y->alphaEq(term y)(normalize(term x))))
      [imp a b,disj a b,app(lam "x" TyT(plain(Var "x")))a])
 ,expect "ordinary unannotated simplification remains available" (passed(plain(TAnd(term p)(term p)))(\x->term x==term p))
 ]
