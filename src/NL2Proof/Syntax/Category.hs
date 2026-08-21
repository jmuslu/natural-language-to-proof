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
module NL2Proof.Syntax.Category
  ( Cat(..)
  , catTy
  , isAtomic
  , argOf
  , resultOf
  ) where

import NL2Proof.Semantics.Lambda

-- | Categories over the atoms @S@, @NP@, @N@.
--
-- The result category is on the left of the slash, the argument on the right:
--
-- * @res ':/' arg@ — takes @arg@ on the __right__, yields @res@
-- * @res ':\\' arg@ — takes @arg@ on the __left__, yields @res@
data Cat
  = S
  | NP
  | N
  | Cat :/ Cat
  | Cat :\ Cat
  deriving (Eq, Ord)

infixl 8 :/
infixl 8 :\

instance Show Cat where
  show S         = "S"
  show NP        = "NP"
  show N         = "N"
  show (r :/ a)  = wrap r ++ "/" ++ wrap a
  show (r :\ a)  = wrap r ++ "\\" ++ wrap a

wrap :: Cat -> String
wrap c
  | isAtomic c = show c
  | otherwise  = "(" ++ show c ++ ")"

isAtomic :: Cat -> Bool
isAtomic S  = True
isAtomic NP = True
isAtomic N  = True
isAtomic _  = False

-- | The semantic type a meaning of this category must have.
--
-- Note that a slash's direction is purely syntactic: @X/Y@ and @X\\Y@ map to the
-- same semantic type. Direction constrains /where the argument sits in the
-- string/, not /what the function does/.
catTy :: Cat -> Ty
catTy S        = TyT
catTy NP       = tyGQ
catTy N        = tyPred1
catTy (r :/ a) = catTy a ~> catTy r
catTy (r :\ a) = catTy a ~> catTy r

-- | The argument category of a functor, if it is one.
argOf :: Cat -> Maybe Cat
argOf (_ :/ a) = Just a
argOf (_ :\ a) = Just a
argOf _        = Nothing

-- | The result category of a functor, if it is one.
resultOf :: Cat -> Maybe Cat
resultOf (r :/ _) = Just r
resultOf (r :\ _) = Just r
resultOf _        = Nothing
