{-# LANGUAGE LambdaCase #-}

-- | Montague-style simply-typed lambda calculus over the semantic types @e@ and
-- @t@, with generalized quantifiers as higher-order functions, plus the world
-- type @s@ of Gallin's Ty2 for attitude contexts (see
-- "NL2Proof.Semantics.Intensional"; every other meaning stays extensional).
--
-- This module is the Stage 1 verification story in miniature. Composition is not
-- merely /performed/, it is /type-checked/ ('typeOf'): a CCG derivation that
-- produces a semantically ill-typed term is rejected mechanically, not by
-- inspection. That is the project's Curry–Howard framing applied at the
-- smallest available scale — type-checking as proof-checking.
--
-- The calculus is simply typed and therefore strongly normalizing, so
-- 'normalize' is total and needs no fuel parameter.
module NL2Proof.Semantics.Lambda
  ( -- * Types
    Ty(..)
  , (~>)
  , tyPred1
  , tyPred2
  , tyGQ
  , tyDet
  , tyProp
    -- * Terms
  , Var
  , Term(..)
  , spine
  , apply
    -- * Constructors
  , entity
  , pred1
  , pred2
  , gq
  , det
    -- * Definite descriptions
  , iotaName
  , tyIota
  , iota
  , isIota
    -- * Anaphora placeholders
    -- $anaphora
  , anaphorPrefix
  , mkAnaphor
  , isAnaphorName
  , anaphorNames
    -- * Type checking
  , Ctx
  , TypeError(..)
  , typeOf
  , wellTyped
  , renderTypeError
    -- * Reduction
  , freeVars
  , constNames
  , fresh
  , subst
  , normalize
  , simplifyConj
    -- * Equality and rendering
  , canonical
  , canonicalAC
  , alphaEq
  , pretty
  ) where

import Data.List (delete, intercalate, nub, sort, union)

--------------------------------------------------------------------------------
-- Types
--------------------------------------------------------------------------------

-- | Semantic types: entities, truth values, worlds, and functions between them.
--
-- 'TyS' (worlds, Gallin's Ty2 index type) occurs only in attitude contexts: the
-- proposition type @s -> t@ of a @that@-clause and the verbs that take one.
-- Every other meaning is extensional and read at the actual world.
data Ty
  = TyE
  | TyT
  | TyS
  | TyFun Ty Ty
  deriving (Eq, Ord)

infixr 9 ~>

-- | Right-associative function type constructor: @TyE ~> TyT ~> TyT@.
(~>) :: Ty -> Ty -> Ty
(~>) = TyFun

instance Show Ty where
  show TyE           = "e"
  show TyT           = "t"
  show TyS           = "s"
  show (TyFun a b)   = "(" ++ show a ++ "->" ++ show b ++ ")"

-- | One-place predicate, @e -> t@.
tyPred1 :: Ty
tyPred1 = TyE ~> TyT

-- | Two-place predicate, @e -> e -> t@.
tyPred2 :: Ty
tyPred2 = TyE ~> TyE ~> TyT

-- | Generalized quantifier, @(e -> t) -> t@.
--
-- /All/ noun phrases in this fragment have this type, including proper names.
-- Uniformity here is what lets @"John"@ and @"every student"@ combine with the
-- same verb entry, which is the whole point of the Montagovian treatment.
tyGQ :: Ty
tyGQ = tyPred1 ~> TyT

-- | Determiner, @(e -> t) -> (e -> t) -> t@.
tyDet :: Ty
tyDet = tyPred1 ~> tyGQ

-- | Proposition, @s -> t@: the set of worlds where a clause holds. The type of
-- an embedded @that@-clause (CCGbank @S[em]@).
tyProp :: Ty
tyProp = TyS ~> TyT

--------------------------------------------------------------------------------
-- Terms
--------------------------------------------------------------------------------

type Var = String

-- | Lambda terms with explicitly typed binders, so type checking is a simple
-- decidable synthesis pass rather than inference with unification.
data Term
  = Var Var
  | Lam Var Ty Term
  | App Term Term
  | -- | A constant, carrying its type. Predicates, entity names, and anaphora
    -- placeholders are all constants.
    Con String Ty
  | TAnd Term Term
  | TOr Term Term
  | TImp Term Term
  | TNot Term
  | TForall Var Ty Term
  | TExists Var Ty Term
  | TEq Term Term
  deriving (Eq, Ord)

instance Show Term where
  show = pretty

-- | Peel an application spine: @f a b c@ becomes @(f, [a, b, c])@.
spine :: Term -> (Term, [Term])
spine = go []
  where
    go acc (App f a) = go (a : acc) f
    go acc t         = (t, acc)

-- | Left-associated application.
apply :: Term -> [Term] -> Term
apply = foldl App

--------------------------------------------------------------------------------
-- Constructors
--------------------------------------------------------------------------------

entity :: String -> Term
entity n = Con n TyE

pred1 :: String -> Term
pred1 n = Con n tyPred1

pred2 :: String -> Term
pred2 n = Con n tyPred2

gq :: String -> Term
gq n = Con n tyGQ

det :: String -> Term
det n = Con n tyDet

--------------------------------------------------------------------------------
-- Definite descriptions
--------------------------------------------------------------------------------

-- | The description operator: @iota(P)@ denotes /the/ @P@, an entity.
--
-- A constant of type @(e -> t) -> e@ rather than a binder, for the same reason
-- anaphors are constants: the lambda calculus composes it without knowing what
-- it means. "NL2Proof.DRT.Build" interprets it when it builds a DRS, under the
-- unique-name reading (a definite description names one individual, and the
-- same description names the same one).
iotaName :: String
iotaName = "iota"

tyIota :: Ty
tyIota = tyPred1 ~> TyE

-- | @iota p@ is the entity term /the p/.
iota :: Term -> Term
iota = App (Con iotaName tyIota)

isIota :: Term -> Bool
isIota (App (Con c _) _) = c == iotaName
isIota _                 = False

--------------------------------------------------------------------------------
-- Anaphora placeholders
--------------------------------------------------------------------------------

-- $anaphora
-- A pronoun contributes an entity-typed constant whose name is marked with
-- 'anaphorPrefix'. It stays unresolved through composition and is discharged at
-- the DRT stage, where the discourse context is available.
--
-- Keeping the marker as a naming convention on 'Con' rather than a dedicated
-- constructor is deliberate: the lambda calculus should not need to know that
-- anaphora exists. Resolution is a discourse-level decision, and pushing it into
-- the term language would let it leak into composition.

-- | Marks a constant as an unresolved anaphor.
anaphorPrefix :: String
anaphorPrefix = "?"

-- | @mkAnaphor "she"@ builds the entity-typed placeholder @?she@.
mkAnaphor :: String -> Term
mkAnaphor n = Con (anaphorPrefix ++ n) TyE

isAnaphorName :: String -> Bool
isAnaphorName n = take (length anaphorPrefix) n == anaphorPrefix

-- | Every unresolved anaphor constant in a term.
anaphorNames :: Term -> [String]
anaphorNames = filter isAnaphorName . constNames

--------------------------------------------------------------------------------
-- Type checking
--------------------------------------------------------------------------------

type Ctx = [(Var, Ty)]

data TypeError
  = Unbound Var
  | NotAFunction Term Ty
  | Mismatch Term Ty Ty
    -- ^ @Mismatch subterm expected actual@
  | NotProp Term Ty
    -- ^ A connective or quantifier body that is not of type @t@.
  deriving (Eq, Show)

renderTypeError :: TypeError -> String
renderTypeError = \case
  Unbound v          -> "unbound variable: " ++ v
  NotAFunction t ty  -> "not a function: " ++ pretty t ++ " : " ++ show ty
  Mismatch t e a     ->
    "type mismatch at " ++ pretty t ++ ": expected " ++ show e ++ ", got " ++ show a
  NotProp t ty       ->
    "expected a proposition (t) at " ++ pretty t ++ ", got " ++ show ty

-- | Synthesize the type of a term, or explain why it has none.
typeOf :: Ctx -> Term -> Either TypeError Ty
typeOf ctx term = case term of
  Var v   -> maybe (Left (Unbound v)) Right (lookup v ctx)
  Con _ t -> Right t
  Lam v t b -> TyFun t <$> typeOf ((v, t) : ctx) b
  App f a -> do
    tf <- typeOf ctx f
    ta <- typeOf ctx a
    case tf of
      TyFun d r
        | d == ta   -> Right r
        | otherwise -> Left (Mismatch a d ta)
      _ -> Left (NotAFunction f tf)
  TAnd a b -> prop2 a b
  TOr  a b -> prop2 a b
  TImp a b -> prop2 a b
  TNot a   -> prop1 a
  TForall v t b -> bound v t b
  TExists v t b -> bound v t b
  TEq a b -> do
    ta <- typeOf ctx a
    tb <- typeOf ctx b
    if ta == tb then Right TyT else Left (Mismatch b ta tb)
  where
    requireT e t = if t == TyT then Right TyT else Left (NotProp e t)
    prop1 a = typeOf ctx a >>= requireT a
    prop2 a b = do
      _ <- typeOf ctx a >>= requireT a
      typeOf ctx b >>= requireT b
    bound v t b = typeOf ((v, t) : ctx) b >>= requireT b

-- | Does the term type-check to exactly @t@ in the empty context? This is the
-- gate a sentence meaning must pass.
wellTyped :: Term -> Bool
wellTyped t = typeOf [] t == Right TyT

--------------------------------------------------------------------------------
-- Reduction
--------------------------------------------------------------------------------

freeVars :: Term -> [Var]
freeVars = \case
  Var v         -> [v]
  Con{}         -> []
  Lam v _ b     -> delete v (freeVars b)
  TForall v _ b -> delete v (freeVars b)
  TExists v _ b -> delete v (freeVars b)
  App f a       -> freeVars f `union` freeVars a
  TAnd a b      -> freeVars a `union` freeVars b
  TOr  a b      -> freeVars a `union` freeVars b
  TImp a b      -> freeVars a `union` freeVars b
  TEq  a b      -> freeVars a `union` freeVars b
  TNot a        -> freeVars a

-- | Every constant name occurring in a term.
constNames :: Term -> [String]
constNames = nub . go
  where
    go = \case
      Con c _       -> [c]
      Var{}         -> []
      Lam _ _ b     -> go b
      TForall _ _ b -> go b
      TExists _ _ b -> go b
      TNot a        -> go a
      App f a       -> go f ++ go a
      TAnd a b      -> go a ++ go b
      TOr  a b      -> go a ++ go b
      TImp a b      -> go a ++ go b
      TEq  a b      -> go a ++ go b

fresh :: [Var] -> Var -> Var
fresh used v = go (v : [v ++ show n | n <- [1 :: Int ..]])
  where
    -- The candidate list is infinite and 'used' is finite, so this terminates.
    go (c : cs) | c `notElem` used = c
                | otherwise        = go cs
    go []                          = v

-- | Capture-avoiding substitution: @subst x s t@ replaces free @x@ in @t@ by @s@.
subst :: Var -> Term -> Term -> Term
subst x s = go
  where
    fvS = freeVars s

    go = \case
      Var v
        | v == x    -> s
        | otherwise -> Var v
      c@Con{}       -> c
      App f a       -> App (go f) (go a)
      TAnd a b      -> TAnd (go a) (go b)
      TOr  a b      -> TOr  (go a) (go b)
      TImp a b      -> TImp (go a) (go b)
      TEq  a b      -> TEq  (go a) (go b)
      TNot a        -> TNot (go a)
      Lam v t b     -> bind Lam v t b
      TForall v t b -> bind TForall v t b
      TExists v t b -> bind TExists v t b

    bind con v t b
      -- The binder shadows x, so there is no free x left to replace.
      | v == x        = con v t b
      -- The binder would capture a free variable of s, so rename it first.
      | v `elem` fvS  =
          let v' = fresh (fvS `union` freeVars b `union` [x]) v
          in con v' t (go (subst v (Var v') b))
      | otherwise     = con v t (go b)

-- | Full beta normalization. Total: the calculus is simply typed.
normalize :: Term -> Term
normalize = \case
  App f a -> case normalize f of
    Lam v _ b -> normalize (subst v (normalize a) b)
    f'        -> App f' (normalize a)
  Lam v t b     -> Lam v t (normalize b)
  TForall v t b -> TForall v t (normalize b)
  TExists v t b -> TExists v t (normalize b)
  TAnd a b      -> TAnd (normalize a) (normalize b)
  TOr  a b      -> TOr  (normalize a) (normalize b)
  TImp a b      -> TImp (normalize a) (normalize b)
  TEq  a b      -> TEq  (normalize a) (normalize b)
  TNot a        -> TNot (normalize a)
  t@Var{}       -> t
  t@Con{}       -> t

-- | Flatten nested conjunctions and drop repeated conjuncts (keeping the first
-- occurrence, so order is otherwise preserved), everywhere in a term.
--
-- Sound: it uses only associativity and idempotence of @&@, so the result is
-- logically equivalent to the input. It matters for the CCGbank path, where two
-- derivations of one meaning can differ by exactly this much (pointwise
-- coordination of intersective modifiers repeats the noun's conjunct), and
-- treating those as distinct meanings would report ambiguity that is not there.
-- Not commutativity: conjunct order is left as the derivation produced it.
simplifyConj :: Term -> Term
simplifyConj = \case
  t@TAnd{}      -> rebuild (dedupe (concatMap conjuncts [t]))
  Lam v ty b    -> Lam v ty (simplifyConj b)
  App f a       -> App (simplifyConj f) (simplifyConj a)
  TOr a b       -> TOr (simplifyConj a) (simplifyConj b)
  TImp a b      -> TImp (simplifyConj a) (simplifyConj b)
  TNot a        -> TNot (simplifyConj a)
  TEq a b       -> TEq (simplifyConj a) (simplifyConj b)
  TForall v ty b -> TForall v ty (simplifyConj b)
  TExists v ty b -> TExists v ty (simplifyConj b)
  t@Var{}       -> t
  t@Con{}       -> t
  where
    conjuncts (TAnd a b) = conjuncts a ++ conjuncts b
    conjuncts t          = [simplifyConj t]
    -- Simplifying a non-conjunction never produces a conjunction at its root,
    -- so one flattening pass suffices.
    dedupe = reverse . foldl (\acc c -> if any (alphaEq c) acc then acc else c : acc) []
    -- 'conjuncts' of a TAnd is never empty, so foldr1 is safe here.
    rebuild = foldr1 TAnd

--------------------------------------------------------------------------------
-- Equality and rendering
--------------------------------------------------------------------------------

-- | Rename every bound variable to its de Bruijn /level/, giving a canonical
-- representative of the alpha-equivalence class.
canonical :: Term -> Term
canonical = go [] (0 :: Int)
  where
    -- All three binder constructors share this shape, so the renaming is
    -- written once and passed the constructor.
    rebind env n con v t b =
      let v' = "#" ++ show n
      in con v' t (go ((v, v') : env) (n + 1) b)

    go env n = \case
      Var v         -> Var (maybe v id (lookup v env))
      c@Con{}       -> c
      App f a       -> App (go env n f) (go env n a)
      TAnd a b      -> TAnd (go env n a) (go env n b)
      TOr  a b      -> TOr  (go env n a) (go env n b)
      TImp a b      -> TImp (go env n a) (go env n b)
      TEq  a b      -> TEq  (go env n a) (go env n b)
      TNot a        -> TNot (go env n a)
      Lam v t b     -> rebind env n Lam v t b
      TForall v t b -> rebind env n TForall v t b
      TExists v t b -> rebind env n TExists v t b

-- | 'canonical', then conjunctions flattened and their conjuncts sorted: a key
-- for equality up to alpha-renaming /and/ associativity-commutativity of @&@.
--
-- For deciding whether two derivations mean the same thing, not for display:
-- it forgets conjunct order, which the derivation's own term keeps (and which
-- matters downstream, e.g. for naming a description @"bald eagle"@).
canonicalAC :: Term -> Term
canonicalAC = go . canonical
  where
    go = \case
      t@TAnd{}      -> foldr1 TAnd (sort (map go (conjuncts t)))
      Lam v ty b    -> Lam v ty (go b)
      App f a       -> App (go f) (go a)
      TOr a b       -> TOr (go a) (go b)
      TImp a b      -> TImp (go a) (go b)
      TNot a        -> TNot (go a)
      TEq a b       -> TEq (go a) (go b)
      TForall v ty b -> TForall v ty (go b)
      TExists v ty b -> TExists v ty (go b)
      t             -> t
    conjuncts (TAnd a b) = conjuncts a ++ conjuncts b
    conjuncts t          = [t]

-- | Equality up to renaming of bound variables. This is what the tests assert,
-- since the particular variable names a derivation happens to produce are not
-- part of the logical content.
alphaEq :: Term -> Term -> Bool
alphaEq a b = canonical a == canonical b

-- | Readable ASCII rendering. Predicates print in applicative form
-- (@love(john, mary)@) rather than curried, because that is how the expected
-- forms in the test suite are written by hand.
pretty :: Term -> String
pretty = p (0 :: Int)
  where
    p d = \case
      Var v   -> v
      Con c _ -> c
      TForall v _ b -> paren (d > 0) ("forall " ++ v ++ ". " ++ p 0 b)
      TExists v _ b -> paren (d > 0) ("exists " ++ v ++ ". " ++ p 0 b)
      Lam v t b     -> paren (d > 0) ("\\" ++ v ++ ":" ++ show t ++ ". " ++ p 0 b)
      TImp a b      -> paren (d > 1) (p 2 a ++ " -> " ++ p 1 b)
      TOr  a b      -> paren (d > 2) (p 3 a ++ " | " ++ p 2 b)
      TAnd a b      -> paren (d > 3) (p 4 a ++ " & " ++ p 3 b)
      TNot a        -> paren (d > 4) ("~" ++ p 5 a)
      TEq  a b      -> paren (d > 4) (p 5 a ++ " = " ++ p 5 b)
      t@App{} ->
        let (h, as) = spine t
        in p 5 h ++ "(" ++ intercalate ", " (map (p 0) as) ++ ")"

    paren True  s = "(" ++ s ++ ")"
    paren False s = s
