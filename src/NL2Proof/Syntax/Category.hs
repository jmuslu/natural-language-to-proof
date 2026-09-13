-- | CCG categories, and the map from a syntactic category to the semantic type
-- its meaning must have.
--
-- 'catTy' is the load-bearing function here. It states, mechanically, the
-- syntax–semantics correspondence that Montague grammar asserts informally: a
-- category determines a semantic type, and a lexical entry is coherent only if
-- its meaning inhabits the type its category demands. The test suite checks
-- @typeOf [] sem == Right (catTy cat)@ for every entry in the lexicon, which
-- turns \"the lexicon is well formed\" from a claim into a checked property.
--
-- Hand-written CCG was chosen over a library parser because the derivation tree
-- lines up 1:1 with the Montague composition — which is exactly what Stage 2's
-- DisCoCat bridge needs, since tensor contraction follows the same syntax tree.
--
-- __Feature annotations and @PP@__ were added so the one core parser can combine
-- CCGbank-style feature-annotated categories, not only the closed fragment.
-- Features are carried by the 'Feature' wrapper and are /erased/ by 'catTy'
-- (they are selectional/syntactic, not semantic-type, distinctions — the finding
-- from the CCGbank feature survey), and combination unifies them via 'catUnify'
-- rather than requiring exact equality. Crucially this is backward compatible:
-- the fragment's categories carry no features, and on feature-free categories
-- 'catUnify' is exactly structural equality, so the fragment parses unchanged.
module NL2Proof.Syntax.Category
  ( Cat(..)
  , catTy
  , isAtomic
  , argOf
  , resultOf
  , catUnify
  ) where

import NL2Proof.Semantics.Lambda

-- | Categories over the atoms @S@, @NP@, @N@, @PP@, with an optional feature
-- annotation on any category and the two slashes.
--
-- The result category is on the left of the slash, the argument on the right:
--
-- * @res ':/' arg@ — takes @arg@ on the __right__, yields @res@
-- * @res ':\\' arg@ — takes @arg@ on the __left__, yields @res@
--
-- @Feature \"dcl\" S@ is CCGbank's @S[dcl]@. The wrapper may sit on a complex
-- category too (@Feature \"conj\" (S :\\ NP)@ is the coordinated-VP marker
-- @(S\\NP)[conj]@).
data Cat
  = S
  | NP
  | N
  | PP
  | Feature String Cat
  | Cat :/ Cat
  | Cat :\ Cat
  deriving (Eq, Ord)

infixl 8 :/
infixl 8 :\

instance Show Cat where
  show S              = "S"
  show NP             = "NP"
  show N              = "N"
  show PP             = "PP"
  show (Feature f c)  = show c ++ "[" ++ f ++ "]"
  show (r :/ a)       = wrap r ++ "/" ++ wrap a
  show (r :\ a)       = wrap r ++ "\\" ++ wrap a

wrap :: Cat -> String
wrap c
  | isAtomic c = show c
  | otherwise  = "(" ++ show c ++ ")"

-- | Atoms are the base categories and any feature-annotation of an atom; slashes
-- are not atomic.
isAtomic :: Cat -> Bool
isAtomic S             = True
isAtomic NP            = True
isAtomic N             = True
isAtomic PP            = True
isAtomic (Feature _ c) = isAtomic c
isAtomic _             = False

-- | The semantic type a meaning of this category must have.
--
-- Note that a slash's direction is purely syntactic: @X/Y@ and @X\\Y@ map to the
-- same semantic type. Direction constrains /where the argument sits in the
-- string/, not /what the function does/.
--
-- Features are erased (@catTy (Feature _ c) == catTy c@): the CCGbank survey
-- established that S\/NP\/N features are selectional, not semantic-type,
-- distinctions, so no new 'Ty' primitive is needed for them.
--
-- @catTy PP == tyGQ@ is a __[stipulated]__ choice, made so the core parser's
-- type map is total: it treats @PP@ like an argument-position @NP@, which makes a
-- case-marking @PP\/NP@ preposition (\"of\", \"as\") come out
-- @tyGQ -> tyGQ@ (a semantically transparent, identity-typed function). This is
-- deliberately more committal than the ingestion classifier
-- ('NL2Proof.Syntax.CCGBank.ccatToTy'), which still returns @AmbiguousAtomType
-- \"PP\"@ so a human reviews PP-bearing corpus entries before they are trusted.
-- The two coexist on purpose: the classifier flags PP for scrutiny; the running
-- parser needs a concrete, provisional type to compose at all.
catTy :: Cat -> Ty
catTy S             = TyT
catTy NP            = tyGQ
catTy N             = tyPred1
catTy PP            = tyGQ
catTy (Feature _ c) = catTy c
catTy (r :/ a)      = catTy a ~> catTy r
catTy (r :\ a)      = catTy a ~> catTy r

-- | The argument category of a functor, if it is one. Feature annotations on a
-- functor are transparent to this.
argOf :: Cat -> Maybe Cat
argOf (_ :/ a)      = Just a
argOf (_ :\ a)      = Just a
argOf (Feature _ c) = argOf c
argOf _             = Nothing

-- | The result category of a functor, if it is one.
resultOf :: Cat -> Maybe Cat
resultOf (r :/ _)      = Just r
resultOf (r :\ _)      = Just r
resultOf (Feature _ c) = resultOf c
resultOf _             = Nothing

-- | Feature-aware unification of two categories, used by the combinatory rules
-- instead of exact equality.
--
-- The policy is __underspecification-as-wildcard__: a feature-free category
-- unifies with any annotation of it (@S@ unifies with @S[dcl]@); two annotated
-- categories unify only if their features match. On feature-free categories this
-- is exactly structural equality, so the closed fragment — whose categories
-- carry no features — combines exactly as it did under @==@. The policy is the
-- same one validated at 99.8% of binary rule firings against CCGbank's GRAMMAR
-- (see 'NL2Proof.Syntax.CCGRules'); it lives here too so the /core/ parser, not
-- only the corpus-ingestion path, can use it.
catUnify :: Cat -> Cat -> Bool
catUnify (Feature f a) (Feature g b) = f == g && catUnify a b
catUnify (Feature _ a) b             = catUnify a b
catUnify a (Feature _ b)             = catUnify a b
catUnify S  S   = True
catUnify NP NP  = True
catUnify N  N   = True
catUnify PP PP  = True
catUnify (ra :/ aa) (rb :/ ab) = catUnify ra rb && catUnify aa ab
catUnify (ra :\ aa) (rb :\ ab) = catUnify ra rb && catUnify aa ab
catUnify _ _ = False
