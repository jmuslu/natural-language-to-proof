-- | Finite model enumeration and evaluation.
--
-- == Why this exists
--
-- The first RSA setup in this project gave the recursion no way to measure
-- __informativity__, which is RSA's actual engine. Its only asymmetry was a
-- stipulated prior favouring surface scope, so the conclusion "RSA amplifies the
-- prior" was a tautology of the construction rather than a finding. The
-- reference-game test disproved the general version of that claim on its own: the
-- implicature there appears under a /uniform/ prior, driven entirely by an
-- asymmetric lexicon.
--
-- Informativity needs semantics. This module supplies it by brute force: enumerate
-- every finite model over a small domain, evaluate a reading in each, and read
-- informativity off the size of its truth set.
--
-- == Why brute force is the right call here
--
-- The asymmetry it recovers is __derived, not stipulated__. For
-- @"Every student reads a book"@:
--
-- > exists y. book(y) & forall x. student(x) -> read(x, y)     -- inverse
-- > forall x. student(x) -> exists y. book(y) & read(x, y)     -- surface
--
-- the inverse reading (one book everyone reads) __entails__ the surface reading
-- (each reads some book), so it is true in strictly fewer models. That is a fact
-- about the readings, checkable rather than assumed, and it is exactly the kind of
-- asymmetry RSA is built to exploit.
--
-- It also gives the project a real, if tiny, __model checker__: 'entails' decides
-- entailment between readings over all models of a given size — a semantic
-- counterpart to the syntactic type check, and honest about its limits, see
-- 'entails'.
--
-- It is __not__ an oracle. Entailment between two readings of one sentence is
-- an internal fact; grounding comes from "NL2Proof.Verify.Oracle". What this
-- module supplies downstream is informativity, which RSA ranks with.
module NL2Proof.Stage2.Model
  ( -- * Models
    Model(..)
  , Signature(..)
  , signatureOf
  , enumerateModels
  , modelCount
    -- * Evaluation
  , Env
  , evalTerm
  , truthSet
    -- * Derived measures
  , informativity
  , truthFraction
  , entails
  , equivalent
  , strictlyStronger
    -- * Rendering
  , renderModel
  ) where

import Data.List (intercalate, nub, subsequences)
import qualified Data.Map.Strict as M

import NL2Proof.Semantics.Lambda

--------------------------------------------------------------------------------
-- Models
--------------------------------------------------------------------------------

-- | A finite first-order model. The domain is @[0 .. n-1]@.
data Model = Model
  { modelDomain :: [Int]
  , modelUnary  :: M.Map String [Int]
  , modelBinary :: M.Map String [(Int, Int)]
  , modelConsts :: M.Map String Int
  }
  -- Ord so a model can be a meaning in an RSA model, where distributions need
  -- an ordered key. Structural, with no semantic reading.
  deriving (Eq, Ord, Show)

-- | The symbols a term needs a model to interpret.
data Signature = Signature
  { sigUnary  :: [String]
  , sigBinary :: [String]
  , sigConsts :: [String]
  }
  deriving (Eq, Show)

-- | Read the signature off a term.
--
-- Anaphor placeholders are included as constants, so a reading with an
-- unresolved pronoun is evaluable rather than silently unmodellable.
signatureOf :: Term -> Signature
signatureOf t =
  Signature
    { sigUnary = nub [c | (c, 1) <- apps]
    , sigBinary = nub [c | (c, 2) <- apps]
    , sigConsts = nub (constArgs t)
    }
  where
    apps = predApps t

predApps :: Term -> [(String, Int)]
predApps = go
  where
    go term = case term of
      App{} -> case spine term of
        (Con c _, args) -> (c, length args) : concatMap go args
        (h, args)       -> go h ++ concatMap go args
      TAnd a b      -> go a ++ go b
      TOr a b       -> go a ++ go b
      TImp a b      -> go a ++ go b
      TEq a b       -> go a ++ go b
      TNot a        -> go a
      Lam _ _ b     -> go b
      TForall _ _ b -> go b
      TExists _ _ b -> go b
      Var{}         -> []
      Con{}         -> []

-- | Constants appearing in argument position — entity names, not predicates.
constArgs :: Term -> [String]
constArgs = go
  where
    go term = case term of
      App{} -> case spine term of
        (Con _ _, args) -> [c | Con c _ <- args] ++ concatMap go args
        (h, args)       -> go h ++ concatMap go args
      TEq a b       -> [c | Con c _ <- [a, b]] ++ go a ++ go b
      TAnd a b      -> go a ++ go b
      TOr a b       -> go a ++ go b
      TImp a b      -> go a ++ go b
      TNot a        -> go a
      Lam _ _ b     -> go b
      TForall _ _ b -> go b
      TExists _ _ b -> go b
      Var{}         -> []
      Con{}         -> []

-- | How many models a signature has at a given domain size.
--
-- @2^(n*|unary|) * 2^(n^2*|binary|) * n^|consts|@. Exposed so callers can check
-- the cost before paying it — this grows fast, and @n = 3@ with one binary
-- predicate is already 512 times @n = 2@.
modelCount :: Int -> Signature -> Integer
modelCount n sig =
  2 ^ (toInteger n * u) * 2 ^ (toInteger (n * n) * b) * toInteger n ^ c
  where
    u = toInteger (length (sigUnary sig))
    b = toInteger (length (sigBinary sig))
    c = toInteger (length (sigConsts sig))

-- | Every model of the signature over domain @[0 .. n-1]@.
enumerateModels :: Int -> Signature -> [Model]
enumerateModels n sig =
  [ Model dom (M.fromList us) (M.fromList bs) (M.fromList cs)
  | us <- assignEach (sigUnary sig) unaryExts
  , bs <- assignEach (sigBinary sig) binaryExts
  , cs <- assignEach (sigConsts sig) dom
  ]
  where
    dom = [0 .. n - 1]
    unaryExts = subsequences dom
    binaryExts = subsequences [(a, b) | a <- dom, b <- dom]

    -- Every way of assigning one value from `vals` to each name.
    assignEach [] _ = [[]]
    assignEach (name : names) vals =
      [ (name, v) : rest | v <- vals, rest <- assignEach names vals ]

--------------------------------------------------------------------------------
-- Evaluation
--------------------------------------------------------------------------------

type Env = M.Map Var Int

-- | Evaluate a closed formula in a model.
--
-- 'Nothing' when the model does not interpret something the term mentions, which
-- 'enumerateModels' over 'signatureOf' cannot produce — so a 'Nothing' here means
-- the caller mismatched a term with a signature, and it is surfaced rather than
-- defaulted to 'False'.
evalTerm :: Model -> Env -> Term -> Maybe Bool
evalTerm m env term = case term of
  TAnd a b -> (&&) <$> evalTerm m env a <*> evalTerm m env b
  TOr a b  -> (||) <$> evalTerm m env a <*> evalTerm m env b
  TImp a b -> (\x y -> not x || y) <$> evalTerm m env a <*> evalTerm m env b
  TNot a   -> not <$> evalTerm m env a

  TForall v _ body ->
    and <$> traverse (\d -> evalTerm m (M.insert v d env) body) (modelDomain m)
  TExists v _ body ->
    or <$> traverse (\d -> evalTerm m (M.insert v d env) body) (modelDomain m)

  TEq a b -> (==) <$> denote m env a <*> denote m env b

  App{} -> case spine term of
    (Con c _, args) -> do
      es <- traverse (denote m env) args
      case es of
        [x]    -> elem x <$> M.lookup c (modelUnary m)
        [x, y] -> elem (x, y) <$> M.lookup c (modelBinary m)
        _      -> Nothing
    _ -> Nothing

  -- A bare propositional constant is not part of this fragment's output.
  Con{} -> Nothing
  Var{} -> Nothing
  Lam{} -> Nothing

-- | Interpret an argument as a domain element.
denote :: Model -> Env -> Term -> Maybe Int
denote m env t = case t of
  Var v   -> M.lookup v env
  Con c _ -> M.lookup c (modelConsts m)
  _       -> Nothing

-- | The models in which a term is true.
truthSet :: [Model] -> Term -> [Model]
truthSet ms t = [m | m <- ms, evalTerm m M.empty t == Just True]

--------------------------------------------------------------------------------
-- Derived measures
--------------------------------------------------------------------------------

-- | Fraction of models in which the term holds. Lower means logically stronger.
truthFraction :: [Model] -> Term -> Double
truthFraction ms t
  | null ms   = 0
  | otherwise = fromIntegral (length (truthSet ms t)) / fromIntegral (length ms)

-- | Surprisal in bits: @-log2(truthFraction)@.
--
-- The measure RSA actually wants. A reading true everywhere carries no
-- information (@0@ bits); a reading true nowhere is infinitely informative and
-- returns 'Nothing' rather than an infinity.
informativity :: [Model] -> Term -> Maybe Double
informativity ms t
  | f <= 0    = Nothing
  | otherwise = Just (negate (logBase 2 f))
  where
    f = truthFraction ms t

-- | Does the first term entail the second, over all models of this set?
--
-- __Limits, stated.__ This is entailment over a /finite/ model set, not a proof.
-- A counterexample it finds is real; a failure to find one is not a proof of
-- entailment, only evidence at that domain size. For the readings this fragment
-- generates, domain size 2 already separates the scope readings — but the
-- asymmetry between "found a counterexample" and "found none" is exactly the
-- search-versus-verification distinction the architecture is built around, and
-- this function sits on the search side.
entails :: [Model] -> Term -> Term -> Bool
entails ms a b =
  all (\m -> evalTerm m M.empty a /= Just True || evalTerm m M.empty b == Just True) ms

equivalent :: [Model] -> Term -> Term -> Bool
equivalent ms a b = entails ms a b && entails ms b a

-- | @a@ entails @b@ but not conversely: @a@ is strictly the stronger reading.
strictlyStronger :: [Model] -> Term -> Term -> Bool
strictlyStronger ms a b = entails ms a b && not (entails ms b a)

--------------------------------------------------------------------------------
-- Rendering
--------------------------------------------------------------------------------

renderModel :: Model -> String
renderModel m =
  "dom=" ++ show (modelDomain m)
    ++ part "un" [k ++ show v | (k, v) <- M.toList (modelUnary m)]
    ++ part "bin" [k ++ show v | (k, v) <- M.toList (modelBinary m)]
    ++ part "const" [k ++ "=" ++ show v | (k, v) <- M.toList (modelConsts m)]
  where
    part _ []  = ""
    part l xs = "  " ++ l ++ "{" ++ intercalate "," xs ++ "}"
