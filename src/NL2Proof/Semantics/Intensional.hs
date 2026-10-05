{-# LANGUAGE LambdaCase #-}

-- | Intensional types for attitude reports: what lets @"Bob said that the cat
-- is red"@ be a fact about Bob rather than an assertion that the cat is red.
--
-- == Ty2 with explicit worlds, not IL
--
-- Montague's IL leaves the index implicit and adds @^@ and @ˇ@, with a
-- restricted beta rule (an argument must be modally closed) and the @ˇ^@
-- cancellation law. Gallin's Ty2 adds a world type @s@ ('TyS') and makes
-- indices ordinary variables. We use Ty2: intensional abstraction is plain
-- 'Lam' over @w : s@, so 'typeOf', 'normalize', 'subst' and 'alphaEq' handle
-- attitude terms unchanged, beta stays unrestricted, and propositions are
-- written as @\\w. P_w@ with the world visible in the body.
--
-- == World-indexed twins and the context of interpretation
--
-- Every /non-logical/ constant @c : τ@ (@red@, @cat@, @say@, @Bob@, ...) has a
-- twin @c_s : s -> τ@ ('twinName'). The plain @c@ the rest of the system uses
-- is shorthand for @c_s w0@, the constant read at the actual world, which is
-- never written. Logical constants have no twin: the connectives and
-- quantifiers are term constructors, and @iota@, anaphor placeholders and
-- world-typed constants are left alone ('isLogicalConst').
--
-- A meaning is interpreted in a context ('Ctx'): 'Actual', or 'At' @n@ for the
-- bound world variable @wn@. In 'Actual' a term is returned unchanged, which is
-- exactly today's code path, so no existing meaning changes. In 'At' @n@ every
-- non-logical constant @c@ becomes @c_s wn@ ('meaningAt').
--
-- The chart is a bottom-up fold over terms. Rather than carry a function
-- @Ctx -> Term@ per chart item (which would defeat packing by meaning), the
-- fold computes the 'Actual' meaning and 'meaningAt' derives any other context
-- from it. That is sound: lexical meanings are closed, and replacing a
-- constant by a closed term commutes with beta-reduction, so interpreting a
-- node at @At n@ equals re-indexing its actual-world normal form. Constants
-- that are already twins are not re-indexed, so an inner clause keeps its own
-- world.
--
-- == The intensional-parameter rule
--
-- A lexical entry may /declare/ an intensional parameter: a domain of type
-- @s -> τ@ where its category alone would give @τ@ (@that@ is @S[em]\/S[dcl]@,
-- category type @t -> s -> t@, declared @(s -> t) -> s -> t@). When such a
-- functor is applied to an argument of type @τ@, the argument is interpreted at
-- a fresh world and abstracted: @λw(n+1). meaningAt (At (n+1)) arg@
-- ('applyIntensional'). So @catTy@ stays keyed on category (@S[dcl]@ is still
-- @t@; only @S[em]@ is @s -> t@), the body of a proposition really contains its
-- world variable, and a bare-complement verb gets its @s -> t@ argument from its
-- own entry, leaving every other @S[dcl]@-taking word untouched.
--
-- == Opacity
--
-- Inside @\\w1. spy_s w1 (ames_s w1)@ there is no occurrence of @ames@, only of
-- @ames_s w1@. So Leibniz's law from a /contingent/ identity (@ι mayor = ames@
-- at the actual world) cannot fire there, while a /necessary/ identity
-- (@∀w. ames_s w = ι (mayor_s w)@) can ('leibniz'). Opacity is a consequence of
-- the representation, not a rule that is switched off.
--
-- == Not handled
--
-- De re readings (the description scoped out of the attitude): complements are
-- always de dicto. Coordinated complements (@"said that P and that Q"@) and
-- right-node raising with attitudes need generalised conjunction and
-- composition at @s -> t@; composition into an intensional parameter is not
-- licensed (the argument is not yet known, so it cannot be re-indexed). Modal
-- subordination and tense are out of scope.
module NL2Proof.Semantics.Intensional
  ( -- * Contexts and twins
    Ctx(..)
  , twinName
  , isTwinName
  , untwinName
  , isLogicalConst
  , worldVar
  , actualWorld
  , meaningAt
  , indexWith
  , deindexWith
  , isIntensionalTerm
    -- * The intensional-parameter rule
  , applyIntensional
  , liftsTo
    -- * Attitude verbs
  , Attitude(..)
  , nonFactiveVerbs
  , factiveVerbs
  , attitudeOf
  , isFactiveVerb
  , tyAttRel
  , tyAttRel3
    -- * Lexical meanings
  , complementizer
  , attitudeVerb
  , addresseeVerb
  , frontedVerb
  , frontedAddresseeVerb
    -- * Opacity
  , Identity(..)
  , identityPremise
  , leibniz
  ) where

import Data.Char (isDigit, toLower)
import Data.List (isPrefixOf, isSuffixOf)

import NL2Proof.Semantics.Lambda hiding (Ctx)

--------------------------------------------------------------------------------
-- Contexts and twins
--------------------------------------------------------------------------------

-- | The context a meaning is interpreted in: the actual world, or the bound
-- world variable @wn@.
data Ctx = Actual | At Int
  deriving (Eq, Show)

-- | @red@ -> @red_s@.
twinName :: String -> String
twinName c = c ++ "_s"

isTwinName :: String -> Bool
isTwinName c = "_s" `isSuffixOf` c

untwinName :: String -> String
untwinName c = if isTwinName c then take (length c - 2) c else c

-- | Constants with no twin: @iota@, anaphor placeholders (discourse referents
-- still to be resolved, rigid by construction), anything of world type, and
-- constants that already are twins.
isLogicalConst :: String -> Ty -> Bool
isLogicalConst c ty =
  c == iotaName || isAnaphorName c || ty == TyS || isWorldIndexed ty
  where
    isWorldIndexed (TyFun TyS _) = isTwinName c
    isWorldIndexed _             = False

worldVar :: Int -> Var
worldVar n = "w" ++ show n

-- | @w0@, the actual world, for the adequacy check ('meaningAt' never writes it).
actualWorld :: Term
actualWorld = Con "w0" TyS

-- | The meaning of a term in a context. 'Actual' is the identity.
meaningAt :: Ctx -> Term -> Term
meaningAt Actual t = t
meaningAt (At n) t = indexWith (Var (worldVar n)) t

-- | Replace every non-logical constant @c : τ@ by @c_s w : τ@.
indexWith :: Term -> Term -> Term
indexWith w = go
  where
    go = \case
      Con c ty
        | isLogicalConst c ty -> Con c ty
        | otherwise           -> App (Con (twinName c) (TyS ~> ty)) w
      t@Var{}        -> t
      Lam v ty b     -> Lam v ty (go b)
      App f a        -> App (go f) (go a)
      TAnd a b       -> TAnd (go a) (go b)
      TOr a b        -> TOr (go a) (go b)
      TImp a b       -> TImp (go a) (go b)
      TNot a         -> TNot (go a)
      TEq a b        -> TEq (go a) (go b)
      TForall v ty b -> TForall v ty (go b)
      TExists v ty b -> TExists v ty (go b)

-- | The inverse at one world: @c_s w@ back to @c@. Other worlds' twins are
-- left alone, so an inner clause keeps its own index.
deindexWith :: Term -> Term -> Term
deindexWith w = go
  where
    go = \case
      App (Con c (TyFun TyS ty)) w'
        | isTwinName c, w' == w -> Con (untwinName c) ty
      t@Con{}        -> t
      t@Var{}        -> t
      Lam v ty b     -> Lam v ty (go b)
      App f a        -> App (go f) (go a)
      TAnd a b       -> TAnd (go a) (go b)
      TOr a b        -> TOr (go a) (go b)
      TImp a b       -> TImp (go a) (go b)
      TNot a         -> TNot (go a)
      TEq a b        -> TEq (go a) (go b)
      TForall v ty b -> TForall v ty (go b)
      TExists v ty b -> TExists v ty (go b)

-- | Does any type annotation in the term mention worlds? False for every
-- extensional meaning, which is what keeps the intensional checks off the
-- extensional path.
isIntensionalTerm :: Term -> Bool
isIntensionalTerm = \case
  Con _ ty       -> mentionsS ty
  Var{}          -> False
  Lam _ ty b     -> mentionsS ty || isIntensionalTerm b
  App f a        -> isIntensionalTerm f || isIntensionalTerm a
  TAnd a b       -> isIntensionalTerm a || isIntensionalTerm b
  TOr a b        -> isIntensionalTerm a || isIntensionalTerm b
  TImp a b       -> isIntensionalTerm a || isIntensionalTerm b
  TNot a         -> isIntensionalTerm a
  TEq a b        -> isIntensionalTerm a || isIntensionalTerm b
  TForall _ ty b -> mentionsS ty || isIntensionalTerm b
  TExists _ ty b -> mentionsS ty || isIntensionalTerm b
  where
    mentionsS TyS         = True
    mentionsS (TyFun a b) = mentionsS a || mentionsS b
    mentionsS _           = False

-- | The largest @n@ such that @wn@ is bound in the term (0 if none).
maxWorld :: Term -> Int
maxWorld = \case
  Lam v TyS b    -> max (worldIndex v) (maxWorld b)
  Lam _ _ b      -> maxWorld b
  App f a        -> max (maxWorld f) (maxWorld a)
  TAnd a b       -> max (maxWorld a) (maxWorld b)
  TOr a b        -> max (maxWorld a) (maxWorld b)
  TImp a b       -> max (maxWorld a) (maxWorld b)
  TNot a         -> maxWorld a
  TEq a b        -> max (maxWorld a) (maxWorld b)
  TForall _ _ b  -> maxWorld b
  TExists _ _ b  -> maxWorld b
  _              -> 0
  where
    worldIndex v
      | "w" `isPrefixOf` v, let ds = drop 1 v, not (null ds), all isDigit ds = read ds
      | otherwise = 0

--------------------------------------------------------------------------------
-- The intensional-parameter rule
--------------------------------------------------------------------------------

-- | Application with the intensional-parameter rule: if the functor's domain is
-- @s -> τ@ and the argument has type @τ@, the argument is interpreted at a
-- fresh world and abstracted over it. Otherwise plain 'App'. On extensional
-- terms this is exactly 'App' (no type is computed).
applyIntensional :: Term -> Term -> Term
applyIntensional f a
  | isIntensionalTerm f
  , Right (TyFun (TyFun TyS dom) _) <- typeOf [] f
  , Right ta <- typeOf [] a
  , ta == dom =
      let n = maxWorld a + 1
      in App f (Lam (worldVar n) TyS (meaningAt (At n) a))
  | otherwise = App f a

-- | @liftsTo declared expected@: is a declared entry type the category type
-- with some argument domains lifted from @τ@ to @s -> τ@? This is the
-- coherence check for entries with intensional parameters (equality otherwise).
liftsTo :: Ty -> Ty -> Bool
liftsTo d e | d == e = True
liftsTo (TyFun d r) (TyFun d' r') = (d == d' || d == TyS ~> d') && liftsTo r r'
liftsTo _ _ = False

--------------------------------------------------------------------------------
-- Attitude verbs
--------------------------------------------------------------------------------

-- | The two lexical classes. Kept in separate lists ('nonFactiveVerbs',
-- 'factiveVerbs'); a reporting verb in neither is treated as 'NonFactive' (the
-- fail-safe: unknown means reported, never asserted), and that is logged by the
-- lexicon.
data Attitude = NonFactive | Factive
  deriving (Eq, Show)

-- | @(lemma, surface forms)@: the complement is attributed to the subject.
nonFactiveVerbs :: [(String, [String])]
nonFactiveVerbs =
  [ ("say",     ["say", "says", "said", "saying"])
  , ("claim",   ["claim", "claims", "claimed"])
  , ("believe", ["believe", "believes", "believed"])
  , ("think",   ["think", "thinks", "thought"])
  , ("report",  ["report", "reports", "reported"])
  , ("hear",    ["hear", "hears", "heard"])
  , ("tell",    ["tell", "tells", "told"])
  ]

-- | @(lemma, surface forms)@: the complement is also presupposed at the actual
-- world.
factiveVerbs :: [(String, [String])]
factiveVerbs =
  [ ("know",    ["know", "knows", "knew", "known"])
  , ("realize", ["realize", "realizes", "realized", "realise", "realises", "realised"])
  , ("regret",  ["regret", "regrets", "regretted"])
  ]

-- | Lemma and class of a listed surface form, case-insensitively.
attitudeOf :: String -> Maybe (String, Attitude)
attitudeOf w = case [ (l, NonFactive) | (l, fs) <- nonFactiveVerbs, lw `elem` fs ]
                 ++ [ (l, Factive) | (l, fs) <- factiveVerbs, lw `elem` fs ] of
  (x : _) -> Just x
  []      -> Nothing
  where lw = map toLower w

-- | Is this predicate name (a lemma) factive?
isFactiveVerb :: String -> Bool
isFactiveVerb l = l `elem` map fst factiveVerbs

-- | An attitude relation, @e -> (s -> t) -> t@.
tyAttRel :: Ty
tyAttRel = TyE ~> tyProp ~> TyT

-- | With an addressee (@tell@), @e -> e -> (s -> t) -> t@.
tyAttRel3 :: Ty
tyAttRel3 = TyE ~> TyE ~> tyProp ~> TyT

--------------------------------------------------------------------------------
-- Lexical meanings
--------------------------------------------------------------------------------

-- | @that@, @S[em]\/S[dcl]@: @\\p:s->t. p@, declared @(s -> t) -> s -> t@. The
-- work is done by the declared parameter: applied to a clause it receives
-- @\\w. P_w@.
complementizer :: Term
complementizer = Lam "p" tyProp (Var "p")

-- | @(S\\NP)\/S[em]@ or, with the parameter declared, @(S\\NP)\/S[dcl]@:
-- @\\p:s->t. \\S. S(\\x. v(x, p))@. NPs are generalised quantifiers here, so
-- the subject is @S@, not an entity. Factivity is not in the term: it is a
-- property of the lemma ('isFactiveVerb') that the DRT stage acts on.
attitudeVerb :: String -> Term
attitudeVerb v =
  Lam "p" tyProp (Lam "S" tyGQ (App (Var "S") (Lam "x" TyE
    (apply (Con v tyAttRel) [Var "x", Var "p"]))))

-- | @((S\\NP)\/S[em])\/NP@ (@told Alice that P@): the addressee first, as the
-- category orders it: @\\O. \\p. \\S. S(\\x. O(\\y. v(x, y, p)))@.
addresseeVerb :: String -> Term
addresseeVerb v =
  Lam "O" tyGQ (Lam "p" tyProp (Lam "S" tyGQ (App (Var "S") (Lam "x" TyE
    (App (Var "O") (Lam "y" TyE (apply (Con v tyAttRel3) [Var "x", Var "y", Var "p"])))))))

-- | The fronted-report verb, @(S[dcl]\\S[dcl])\\NP@ (@"The cat is red," Bob
-- said@) or inverted @(S[dcl]\\S[dcl])\/NP@ (@..., said Bob@): subject first,
-- then the fronted clause as a declared intensional parameter:
-- @\\S. \\p. S(\\x. v(x, p))@.
frontedVerb :: String -> Term
frontedVerb v =
  Lam "S" tyGQ (Lam "p" tyProp (App (Var "S") (Lam "x" TyE
    (apply (Con v tyAttRel) [Var "x", Var "p"]))))

-- | @((S[dcl]\\S[dcl])\\NP)\/NP@ (@"...," Bob told Alice@):
-- @\\O. \\S. \\p. S(\\x. O(\\y. v(x, y, p)))@.
frontedAddresseeVerb :: String -> Term
frontedAddresseeVerb v =
  Lam "O" tyGQ (Lam "S" tyGQ (Lam "p" tyProp (App (Var "S") (Lam "x" TyE
    (App (Var "O") (Lam "y" TyE (apply (Con v tyAttRel3) [Var "x", Var "y", Var "p"])))))))

--------------------------------------------------------------------------------
-- Opacity
--------------------------------------------------------------------------------

-- | An identity premise between two extensional terms of type @e@.
data Identity
  = -- | @a = b@ at the actual world only (Ortcutt: the mayor is Ames).
    Contingent Term Term
  | -- | @∀w. a_w = b_w@: the two co-refer at every world.
    Necessary Term Term
  deriving (Eq, Show)

-- | The premise as a formula.
identityPremise :: Identity -> Term
identityPremise (Contingent a b) = TEq a b
identityPremise (Necessary a b) =
  TForall "w" TyS (TEq (indexWith (Var "w") a) (indexWith (Var "w") b))

-- | Leibniz's law: rewrite @a@ to @b@ wherever the premise licenses it.
--
-- A contingent identity licenses the rewrite at the actual world: it matches
-- the extensional @a@ only, which never occurs under a world binder (there the
-- term is @a_w@). A necessary identity licenses it at every world, so under
-- @\\wn@ it also rewrites @a_wn@ to @b_wn@.
leibniz :: Identity -> Term -> Term
leibniz ident = go
  where
    (a, b, necessary) = case ident of
      Contingent x y -> (x, y, False)
      Necessary x y  -> (x, y, True)

    go t
      | alphaEq t a = b
      | otherwise = case t of
          Lam w TyS body | necessary ->
            Lam w TyS (rewriteAt (Var w) (go body))
          Lam v ty body  -> Lam v ty (go body)
          App f x        -> App (go f) (go x)
          TAnd x y       -> TAnd (go x) (go y)
          TOr x y        -> TOr (go x) (go y)
          TImp x y       -> TImp (go x) (go y)
          TNot x         -> TNot (go x)
          TEq x y        -> TEq (go x) (go y)
          TForall v ty x -> TForall v ty (go x)
          TExists v ty x -> TExists v ty (go x)
          _              -> t

    -- At world @w@, the instances @a_w@ and @b_w@.
    rewriteAt w = replace (indexWith w a) (indexWith w b)

    replace from to t
      | alphaEq t from = to
      | otherwise = case t of
          Lam v ty x     -> Lam v ty (replace from to x)
          App f x        -> App (replace from to f) (replace from to x)
          TAnd x y       -> TAnd (replace from to x) (replace from to y)
          TOr x y        -> TOr (replace from to x) (replace from to y)
          TImp x y       -> TImp (replace from to x) (replace from to y)
          TNot x         -> TNot (replace from to x)
          TEq x y        -> TEq (replace from to x) (replace from to y)
          TForall v ty x -> TForall v ty (replace from to x)
          TExists v ty x -> TExists v ty (replace from to x)
          _              -> t
