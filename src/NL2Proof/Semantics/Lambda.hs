{-# LANGUAGE LambdaCase #-}

-- | Montague-style simply-typed lambda calculus over the semantic types @e@ and
-- @t@, with generalized quantifiers as higher-order functions.
--
-- This module is the Stage 1 verification story in miniature. Composition is not
-- merely /performed/, it is /type-checked/ ('typeOf'): a CCG derivation that
-- produces a semantically ill-typed term is rejected mechanically, not by
-- inspection. That is the Curry–Howard framing of ARCHITECTURE.md applied at the
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
    -- * Equality and rendering
  , canonical
  , alphaEq
  , pretty
  ) where

import Data.List (delete, intercalate, nub, union)

--------------------------------------------------------------------------------
-- Types
--------------------------------------------------------------------------------

-- | Semantic types: entities, truth values, and functions between them.
data Ty
  = TyE
  | TyT
  | TyFun Ty Ty
  deriving (Eq, Ord)

infixr 9 ~>

-- | Right-associative function type constructor: @TyE ~> TyT ~> TyT@.
(~>) :: Ty -> Ty -> Ty
(~>) = TyFun

instance Show Ty where
  show TyE           = "e"
  show TyT           = "t"
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
