-- | Candidate generation: the readings Stage 1 deliberately did not produce.
--
-- Stage 1's fragment yields exactly one derivation per sentence, because scope is
-- fixed in the transitive verb's lexical entry and modifier stacks are read as
-- iterated intersection. ARCHITECTURE.md records both as Stage 2's job rather
-- than as omissions to patch in a hand-written lexicon:
--
-- > Only the subject-wide-scope reading is generated [...] The inverse reading is
-- > a Stage 2 candidate-generation concern, not a Stage 1 omission.
--
-- This module is that layer, and it is still __discrete__: it enumerates readings
-- and takes no view on which is right. Ranking them is
-- "NL2Proof.Stage2.RSA"'s job. The separation is the point — generation is
-- search, ranking is scoring, and neither one is a collapse.
--
-- == Method
--
-- Quantifiers are lifted out of a normalized term into a scope-neutral form
-- ('Scoped'), the prefix is permuted, and each valid permutation is
-- relinearized: underspecification-then-enumeration, in miniature.
--
-- \"Valid\" is a real constraint rather than a formality. A quantifier's
-- restrictor may mention variables bound by another quantifier, and reordering
-- across that dependency would let a variable escape its binder. 'validOrder'
-- rejects those permutations, so every reading returned is closed and
-- well-scoped.
module NL2Proof.Stage2.Alternatives
  ( -- * Scope-neutral form
    QKind(..)
  , Quant(..)
  , Scoped(..)
  , unscope
  , relinearize
  , validOrder
    -- * Generation
  , scopeAlternatives
  , couplingAlternatives
  , couplingCandidates
  , CouplingCandidate(..)
  , alternatives
    -- * Inspection
  , scopeSignature
  , modifierChains
    -- * Conjunction helpers
  , flattenAnd
  , rebuildAnd
  ) where

import Data.List (nub, permutations)

import NL2Proof.Semantics.Lambda
import NL2Proof.Stage2.Modifier

--------------------------------------------------------------------------------
-- Scope-neutral form
--------------------------------------------------------------------------------

data QKind
  = QForall  -- ^ @forall x. restrictor -> body@
  | QExists  -- ^ @exists x. restrictor & body@
  deriving (Eq, Ord, Show)

-- | One quantifier lifted out of a term, with the restrictor it came with.
data Quant = Quant
  { qKind       :: QKind
  , qVar        :: Var
  , qRestrictor :: Term
  }
  deriving (Eq, Show)

-- | A term split into a quantifier prefix and the core it scopes over.
data Scoped = Scoped
  { scopeQuants :: [Quant]
  , scopeCore   :: Term
  }
  deriving (Eq, Show)

-- | Lift the outermost quantifier prefix out of a normalized term.
--
-- Peels only quantifiers in the canonical restrictor shapes — @forall@ over an
-- implication, @exists@ over a conjunction. Anything else is left in the core
-- untouched, notably a negated existential as in @"No student sleeps"@.
--
-- That restraint is deliberate. Re-scoping across a negation changes truth
-- conditions in ways this module has no basis for proposing, so it does not
-- propose them. A quantifier inside a relative clause's restrictor likewise stays
-- put, which is why @"Every student who reads a book smiles"@ yields one reading
-- rather than a spurious second.
unscope :: Term -> Scoped
unscope = go []
  where
    go acc (TForall v _ (TImp restr body)) = go (Quant QForall v restr : acc) body
    go acc (TExists v _ (TAnd restr body)) = go (Quant QExists v restr : acc) body
    go acc t = Scoped (reverse acc) t

-- | Rebuild a term from a quantifier prefix and a core. Inverse of 'unscope' on
-- the same prefix order.
relinearize :: [Quant] -> Term -> Term
relinearize [] core = core
relinearize (q : qs) core = case qKind q of
  QForall -> TForall (qVar q) TyE (TImp (qRestrictor q) rest)
  QExists -> TExists (qVar q) TyE (TAnd (qRestrictor q) rest)
  where
    rest = relinearize qs core

-- | Is this quantifier order well-scoped?
--
-- Each restrictor may mention its own variable and any variable bound to its
-- left, and nothing else. A restrictor referring to a variable bound to its
-- /right/ would be captured by nothing, leaving the reading open.
validOrder :: [Quant] -> Bool
validOrder = go []
  where
    go _ [] = True
    go bound (q : qs) =
      let needed = filter (/= qVar q) (freeVars (qRestrictor q))
      in all (`elem` bound) needed && go (qVar q : bound) qs

--------------------------------------------------------------------------------
-- Conjunction helpers
--------------------------------------------------------------------------------

-- | Flatten a right-nested conjunction into its conjuncts.
flattenAnd :: Term -> [Term]
flattenAnd (TAnd a b) = flattenAnd a ++ flattenAnd b
flattenAnd t          = [t]

-- | Rebuild a right-nested conjunction, matching the shape Stage 1 produces.
rebuildAnd :: [Term] -> Term
rebuildAnd []       = Con "true" TyT
rebuildAnd [x]      = x
rebuildAnd (x : xs) = TAnd x (rebuildAnd xs)

--------------------------------------------------------------------------------
-- Generation
--------------------------------------------------------------------------------

-- | Deduplicate up to alpha-equivalence, preserving first-seen order.
nubAlpha :: [Term] -> [Term]
nubAlpha = foldl step []
  where
    step seen x
      | any (alphaEq x) seen = seen
      | otherwise            = seen ++ [x]

-- | All well-scoped readings of a term, surface order first.
--
-- The input reading is always element zero, so a caller wanting Stage 1's
-- behaviour takes the head and a caller wanting the candidate set takes the list.
-- Deduplicated up to alpha-equivalence, so a term with one quantifier returns one
-- reading rather than @n!@ copies of it.
scopeAlternatives :: Term -> [Term]
scopeAlternatives t =
  nubAlpha (surface : [ relinearize p core | p <- permutations qs, validOrder p ])
  where
    Scoped qs core = unscope t
    surface = relinearize qs core

-- | Maximal runs of unary predicates on one variable where every predicate but
-- the last is a modifier.
--
-- The caller supplies the modifier test, so this module never consults the
-- lexicon and stays independent of the fragment.
modifierChains :: (String -> Bool) -> Term -> [(Var, [String])]
modifierChains isModifier t =
  [ (v, ps)
  | v <- nub (boundVars t)
  , let ps = unaryPredsOn v t
  , length ps >= 2
  , all isModifier (take (length ps - 1) ps)
  ]

-- | Readings in which a modifier fuses with the head noun into a single
-- lexicalized subkind, rather than intersecting with it.
--
-- The @"ancient Chinese red dragon"@ case. Stage 1 produces
-- @ancient(x) & chinese(x) & red(x) & dragon(x)@ and flags the stack; this
-- generates @ancient(x) & red(x) & chinese_dragon(x)@, where @chinese_dragon@ is
-- one predicate.
--
-- __Only 'Classificatory' modifiers fuse__, per
-- "NL2Proof.Stage2.Modifier".'mayFuseWithHead'. An earlier version treated every
-- @N\/N@ word as fusable and generated @ancient_chinese@ and @chinese_red@ among
-- its candidates — neither a plausible English subkind. Modifier classes are not
-- interchangeable, and a generator that ignores the distinction produces garbage
-- candidates that the ranking layer then has to spend evidence rejecting.
--
-- Fusion targets the __head__ rather than the adjacent word, because a subkind is
-- formed with the noun. In @"ancient Chinese red dragon"@ the classificatory
-- modifier is not adjacent to the head, and fusing it with @red@ would be wrong
-- on both counts.
--
-- Note what this does __not__ do: decide. It widens the candidate set and leaves
-- the choice to the ranking layer, per the architecture's insistence that
-- localizing an ambiguity and resolving it are different jobs.
couplingAlternatives :: (String -> Bool) -> Term -> [Term]
couplingAlternatives isModifier =
  nubAlpha . map ccTerm . couplingCandidates isModifier

-- | One fusion candidate, with the evidence about how plausible it is.
data CouplingCandidate = CouplingCandidate
  { ccTerm     :: Term
  , ccModifier :: Maybe String
    -- ^ Which modifier was fused, or 'Nothing' for the unfused surface reading.
  , ccHead     :: Maybe String
  , ccClass    :: Maybe ModifierClass
    -- ^ The fused modifier's class.
  , ccLicensed :: Bool
    -- ^ Does that class license fusion at all? 'False' candidates are still
    -- generated and returned.
  , ccLayer    :: Int
    -- ^ Resolution layer needed to settle this candidate. @0@ for the surface
    -- reading, which needs nothing settled.
  }

-- | __Every__ fusion the chain admits, annotated rather than filtered.
--
-- An earlier version suppressed fusions whose modifier was not
-- 'Classificatory', which meant @ancient_chinese@ and @chinese_red@ were never
-- generated for @"ancient Chinese red dragon"@. That was preemptive pruning, and
-- it is the wrong shape for this architecture: __build the space first, narrow it
-- with an explicit mechanism afterwards.__ A candidate that never exists cannot
-- be collapsed, cannot be logged as rejected, and cannot be recovered when the
-- classification turns out to be wrong.
--
-- So the stratification is preserved as __evidence on the candidate__
-- ('ccClass', 'ccLicensed', 'ccLayer') rather than as a filter. The ranking layer
-- can down-weight unlicensed fusions to near zero, and the record of having done
-- so survives — which is exactly the difference between a decision and a
-- silent omission.
--
-- 'couplingAlternatives' keeps the plain-term interface for callers that only
-- want readings.
couplingCandidates :: (String -> Bool) -> Term -> [CouplingCandidate]
couplingCandidates isModifier t = surface : concatMap fuseChain (modifierChains isModifier t)
  where
    surface = CouplingCandidate t Nothing Nothing Nothing True 0

    -- The head is the last predicate in the chain; the rest are modifiers.
    fuseChain (v, preds) = case reverse preds of
      [] -> []
      (headNoun : revMods) ->
        let mods = reverse revMods
        in [ CouplingCandidate
               { ccTerm = rewriteChain v (dropAt i mods ++ [m ++ "_" ++ headNoun]) t
               , ccModifier = Just m
               , ccHead = Just headNoun
               , ccClass = Just cls
               , ccLicensed = mayFuseWithHead cls
               , ccLayer = modifierLayer cls
               }
           | i <- [0 .. length mods - 1]
           , let m = mods !! i
           , let cls = classifyModifier m
           ]

    dropAt i xs = take i xs ++ drop (i + 1) xs

-- | Replace the unary predicates on @v@ with a new list, in place.
--
-- Splices the replacement at the position of the first chain link and drops the
-- rest, so conjuncts about other variables keep their positions. That matters:
-- preserving position is what lets 'nubAlpha' recognize a regenerated surface
-- reading as the one it already has.
rewriteChain :: Var -> [String] -> Term -> Term
rewriteChain v newPreds = go
  where
    replacement = rebuildAnd [App (pred1 p) (Var v) | p <- newPreds]

    isLink term = case spine term of
      (Con _ _, [Var v']) -> v' == v
      _                   -> False

    go term = case term of
      TAnd _ _ ->
        let cs = flattenAnd term
        in if any isLink cs then rebuildAnd (splice True cs) else rebuildAnd (map go cs)
      TForall x ty b -> TForall x ty (go b)
      TExists x ty b -> TExists x ty (go b)
      TImp a b       -> TImp (go a) (go b)
      TOr a b        -> TOr (go a) (go b)
      TNot a         -> TNot (go a)
      _              -> term

    splice _ [] = []
    splice pending (c : rest)
      | isLink c  = if pending then replacement : splice False rest else splice pending rest
      | otherwise = go c : splice pending rest

-- | Scope readings and coupling readings together, surface reading first.
alternatives :: (String -> Bool) -> Term -> [Term]
alternatives isModifier t =
  nubAlpha (concatMap (couplingAlternatives isModifier) (scopeAlternatives t))

--------------------------------------------------------------------------------
-- Inspection
--------------------------------------------------------------------------------

-- | The quantifier prefix as a readable signature, e.g. @"forall x exists y"@.
--
-- Two readings of one sentence differ exactly here while agreeing on predicate
-- content, which makes this both the right thing to show a user and the right key
-- to group readings by.
scopeSignature :: Term -> String
scopeSignature t =
  case scopeQuants (unscope t) of
    [] -> "(no quantifier prefix)"
    qs -> unwords [ sym (qKind q) ++ " " ++ qVar q | q <- qs ]
  where
    sym QForall = "forall"
    sym QExists = "exists"

--------------------------------------------------------------------------------
-- Traversal helpers
--------------------------------------------------------------------------------

boundVars :: Term -> [Var]
boundVars = go
  where
    go (TForall v _ b) = v : go b
    go (TExists v _ b) = v : go b
    go (Lam v _ b)     = v : go b
    go (TAnd a b)      = go a ++ go b
    go (TOr a b)       = go a ++ go b
    go (TImp a b)      = go a ++ go b
    go (TEq a b)       = go a ++ go b
    go (TNot a)        = go a
    go (App f a)       = go f ++ go a
    go Var{}           = []
    go Con{}           = []

-- | Unary predicates applied to exactly this variable, left to right.
unaryPredsOn :: Var -> Term -> [String]
unaryPredsOn v = go
  where
    go term = case term of
      App{} -> case spine term of
        (Con c _, [Var v']) | v' == v -> [c]
        (_, args)                     -> concatMap go args
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
