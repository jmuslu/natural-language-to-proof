-- | Parsing and classifying CCGbank's feature-annotated categories.
--
-- CCGbank (LDC2005T13) annotates every leaf with a category that carries
-- feature brackets the repo's own 'NL2Proof.Syntax.Category.Cat' cannot
-- represent: @S[dcl]@, @NP[nb]@, @N[num]@, a bare @PP@, and a category-level
-- @[conj]@ marker. This module parses those categories faithfully into 'CCat',
-- then answers the two mechanical questions Layer 1 of the handoff says must be
-- kept distinct:
--
--   * __Is the string well formed?__  A parse failure is a genuinely malformed
--     entry ('Malformed'). This is the "malformed vs. merely-unrepresentable"
--     split the handoff wants made visible: right now an ingestion pass cannot
--     tell the two apart, and that ambiguity is the same silent-failure problem
--     the codebase exists to prevent, living inside the type system.
--   * __Does it fit the existing 'Cat'?__  A parsed category is classified as
--     'RepresentableAsIs', 'NeedsFeature', or 'NeedsNewAtom'. These are kept
--     visibly separate, per the handoff: blending them into one "N categories
--     ingested" count recreates the well-typed-but-not-faithful trap at the
--     reporting layer.
--
-- __What this module deliberately does not do__ is synthesise a meaning and
-- claim 'NL2Proof.Semantics.Lambda.typeOf' has validated it. CCGbank supplies a
-- category but /no meaning/, and every semantic type in the @{e,t}@ calculus is
-- trivially inhabited by a bare constant, so a @typeOf@ check on a synthesised
-- inhabitant can never fail and therefore verifies nothing. For a hand-authored
-- entry @typeOf@ gates a human-supplied meaning and can catch a wrong one; for a
-- category with no meaning attached there is nothing for it to catch. The
-- faithful-meaning question therefore stays exactly where the handoff puts
-- LLM-proposed meanings: unverifiable by internal machinery, tagged by
-- provenance, never promoted to \"checked\" by type-checking alone. The real,
-- non-vacuous mechanical checks available here are /parseability/ and
-- /representability/, and those are what this module provides.
module NL2Proof.Syntax.CCGBank
  ( -- * Feature-annotated categories
    Dir(..)
  , Feat(..)
  , CCat(..)
  , prettyCCat
    -- * Parsing
  , parseCCGCat
    -- * Semantic type (feature-erasing), with the atoms that need scrutiny
  , TyIssue(..)
  , ccatToTy
    -- * Projection into the core 'Cat'
  , ccatToCat
  , toBareCat
    -- * Representability classification
  , CatProfile(..)
  , profile
  , Representability(..)
  , classify
    -- * Structure queries
  , atomsOf
  , featsOf
  , eraseFeatures
  ) where

import Data.Char (isAlpha, isSpace)
import Data.List (isSuffixOf, nub, sort)

import NL2Proof.Semantics.Lambda (Ty(TyT), tyGQ, tyPred1, tyProp, (~>))
import NL2Proof.Syntax.Category (Cat(..))

--------------------------------------------------------------------------------
-- Types
--------------------------------------------------------------------------------

-- | Slash direction. @Fwd@ is @/@ (argument on the right), @Bwd@ is @\\@
-- (argument on the left), matching 'NL2Proof.Syntax.Category.:/' and ':\\'.
data Dir = Fwd | Bwd
  deriving (Eq, Ord, Show)

-- | A feature bracket's contents, e.g. @Feat \"dcl\"@ for @S[dcl]@.
newtype Feat = Feat String
  deriving (Eq, Ord)

instance Show Feat where
  show (Feat f) = "[" ++ f ++ "]"

-- | A CCGbank category. Features may sit on an atom (@S[dcl]@) or, via the
-- trailing bracket after a parenthesised group, on a complex node
-- (@(S[dcl]\\NP)[conj]@ — see the note on @[conj]@ in 'parseCCGCat').
data CCat
  = CAtom String [Feat]
  | CSlash Dir CCat CCat [Feat]
  deriving (Eq, Ord)

instance Show CCat where
  show = prettyCCat

-- | Render a category back to CCGbank surface syntax. Round-trips with
-- 'parseCCGCat' up to redundant parentheses (the parser is left-associative, so
-- the printer only parenthesises where precedence requires it).
prettyCCat :: CCat -> String
prettyCCat = go
  where
    go (CAtom n fs) = n ++ concatMap show fs
    go (CSlash d r a fs) =
      wrap r ++ slash d ++ wrap a ++ concatMap show fs
    slash Fwd = "/"
    slash Bwd = "\\"
    -- An atom never needs parens; a slash does when it is an operand.
    wrap c@CAtom{}  = go c
    wrap c@CSlash{} = "(" ++ go c ++ ")"

--------------------------------------------------------------------------------
-- Parser (recursive descent, dependency-free)
--------------------------------------------------------------------------------

-- | Parse a CCGbank category string.
--
-- Grammar (left-associative slashes, matching @infixl 8@ on the repo's slashes):
--
-- > category := slash EOF
-- > slash    := primary (('/' | '\') primary)*
-- > primary  := '(' slash ')' feats | atom feats
-- > atom     := [A-Za-z]+ | one of  . , : ;
-- > feats    := ('[' [^]]+ ']')*
--
-- __On the @[conj]@ marker:__ CCGbank writes a coordinated VP conjunct as
-- @S[dcl]\\NP[conj]@, meaning @(S[dcl]\\NP)[conj]@ — the @[conj]@ marks the whole
-- category, not the @NP@. A naive left-to-right parse would attach @[conj]@ to
-- the @NP@ atom. This parser normalises it to the root instead, justified by the
-- measured invariant that @[conj]@ never occurs in non-final position anywhere in
-- the corpus (see @tools/CCGGrammarCoverage.hs@ and the LEX check in
-- @tools/CCGBankReport.hs@, both reporting zero non-trailing @[conj]@): a
-- trailing @[conj]@ therefore always marks the whole category, so it is stripped
-- and re-attached to the outermost node.
parseCCGCat :: String -> Either String CCat
parseCCGCat input =
  let s = dropWhile isSpace input
  in case stripTrailingConj s of
       Just core -> addFeats [Feat "conj"] <$> parseCore core
       Nothing   -> parseCore s

parseCore :: String -> Either String CCat
parseCore s =
  case pSlash s of
    Left e -> Left e
    Right (c, rest)
      | all isSpace rest -> Right c
      | otherwise        -> Left ("trailing input after category: " ++ show rest)

-- | If the string (ignoring trailing whitespace) ends in the category-level
-- @[conj]@ marker, return the prefix before it. See the invariant noted on
-- 'parseCCGCat'.
stripTrailingConj :: String -> Maybe String
stripTrailingConj s =
  let t      = reverse (dropWhile isSpace (reverse s))
      marker = "[conj]"
  in if marker `isSuffixOf` t
       then Just (take (length t - length marker) t)
       else Nothing

type P a = String -> Either String (a, String)

pSlash :: P CCat
pSlash s0 = do
  (left, s1) <- pPrimary s0
  go left s1
  where
    go left s = case s of
      ('/'  : rest) -> do (r, s') <- pPrimary rest; go (CSlash Fwd left r []) s'
      ('\\' : rest) -> do (r, s') <- pPrimary rest; go (CSlash Bwd left r []) s'
      _             -> Right (left, s)

pPrimary :: P CCat
pPrimary s = case s of
  ('(' : rest) -> do
    (inner, s1) <- pSlash rest
    case s1 of
      (')' : s2) -> do
        (fs, s3) <- pFeats s2
        Right (addFeats fs inner, s3)
      _ -> Left "expected ')'"
  _ -> do
    (name, s1) <- pAtomTok s
    (fs, s2)   <- pFeats s1
    Right (CAtom name fs, s2)

-- | Attach features read after a @)@ to the (possibly complex) node inside.
addFeats :: [Feat] -> CCat -> CCat
addFeats []  c                  = c
addFeats fs (CAtom n fs0)       = CAtom n (fs0 ++ fs)
addFeats fs (CSlash d r a fs0)  = CSlash d r a (fs0 ++ fs)

pAtomTok :: P String
pAtomTok s =
  let (letters, rest) = span isAlpha s
  in if not (null letters)
       then Right (letters, rest)
       else case s of
              (c : cs) | c `elem` puncAtoms -> Right ([c], cs)
              _ -> Left ("expected an atom at: " ++ show (take 12 s))

-- | Punctuation that appears as a category atom in CCGbank leaves.
puncAtoms :: String
puncAtoms = ".,:;"

pFeats :: P [Feat]
pFeats s = case s of
  ('[' : rest) -> case break (== ']') rest of
    (inside, ']' : s')
      | not (null inside) -> do
          (more, s'') <- pFeats s'
          Right (Feat inside : more, s'')
    _ -> Left "unterminated feature bracket"
  _ -> Right ([], s)

--------------------------------------------------------------------------------
-- Semantic type (feature-erasing)
--------------------------------------------------------------------------------

-- | An atom whose semantic type is not mechanically settled. These are the
-- constructions the handoff flags for per-construction scrutiny rather than a
-- mechanical default.
data TyIssue
  = AmbiguousAtomType String
    -- ^ @PP@: could be a case-marking pass-through (@tyGQ ~> tyGQ@ on
    -- @PP/NP@) or a predicative modifier (@e -> t@). Not settled here.
  | PolymorphicAtom String
    -- ^ @conj@: coordination is polymorphic (@X\\X\/X@ for any @X@); there is
    -- no single monomorphic type in this calculus.
  | UnmappableAtom String
    -- ^ Punctuation and bracket atoms (@.@, @,@, @LRB@ …): structural, no
    -- semantic content to type.
  deriving (Eq, Show)

-- | The semantic type a meaning of this category must have, /erasing features/.
--
-- This validates Layer 1's central survey conclusion: the S\/NP\/N feature set
-- is syntactic (selectional), not a semantic-type distinction, so @S[dcl]@,
-- @S[b]@, @S[to]@ all map to @t@ and __no new 'Ty' primitive is required__. The
-- only atoms that do not map cleanly are exactly the ones the survey isolated
-- for manual scrutiny, returned here as a 'TyIssue' rather than given a silent
-- default.
ccatToTy :: CCat -> Either TyIssue Ty
ccatToTy (CAtom name fs) = case name of
  -- An embedded clause (S[em]) denotes a proposition; see 'NL2Proof.Syntax.Category.catTy'.
  "S" | Feat "em" `elem` fs -> Right tyProp
  "S"  -> Right TyT
  "NP" -> Right tyGQ
  "N"  -> Right tyPred1
  "PP"   -> Left (AmbiguousAtomType "PP")
  "conj" -> Left (PolymorphicAtom "conj")
  _      -> Left (UnmappableAtom name)
ccatToTy (CSlash _ res arg _) = do
  ta <- ccatToTy arg
  tr <- ccatToTy res
  Right (ta ~> tr)

--------------------------------------------------------------------------------
-- Projection into the existing bare Cat
--------------------------------------------------------------------------------

-- | Project a CCGbank category into the /feature-bearing/ core 'Cat': feature
-- brackets become 'Feature' wrappers and @PP@ maps to the 'PP' atom. Returns
-- 'Nothing' only for atoms the core 'Cat' still lacks (@conj@, punctuation) —
-- so, unlike 'toBareCat', this covers the S\/NP\/N\/PP + features majority of the
-- corpus that the feature-migrated 'Cat' can now represent.
ccatToCat :: CCat -> Maybe Cat
ccatToCat (CAtom name fs) = do
  base <- case name of
    "S"  -> Just S
    "NP" -> Just NP
    "N"  -> Just N
    "PP" -> Just PP
    _    -> Nothing
  Just (foldr (\(Feat f) c -> Feature f c) base fs)
ccatToCat (CSlash d r a fs) = do
  r' <- ccatToCat r
  a' <- ccatToCat a
  let slashed = case d of { Fwd -> r' :/ a'; Bwd -> r' :\ a' }
  Just (foldr (\(Feat f) c -> Feature f c) slashed fs)

-- | Project a CCGbank category into the repo's current 'Cat', if it uses only
-- the atoms the current system has ({S, NP, N}). Features are erased. Returns
-- 'Nothing' for any category mentioning an atom 'Cat' cannot express (@PP@,
-- @conj@, punctuation …) — i.e. exactly the categories that would need a schema
-- extension before the existing parser could handle them.
toBareCat :: CCat -> Maybe Cat
toBareCat (CAtom name _) = case name of
  "S"  -> Just S
  "NP" -> Just NP
  "N"  -> Just N
  _    -> Nothing
toBareCat (CSlash d res arg _) = do
  r <- toBareCat res
  a <- toBareCat arg
  Just $ case d of
    Fwd -> r :/ a
    Bwd -> r :\ a

--------------------------------------------------------------------------------
-- Structure queries
--------------------------------------------------------------------------------

-- | Distinct atom names used anywhere in a category (sorted, deduped).
atomsOf :: CCat -> [String]
atomsOf = sort . nub . go
  where
    go (CAtom n _)        = [n]
    go (CSlash _ r a _)   = go r ++ go a

-- | Distinct features used anywhere in a category (sorted, deduped).
featsOf :: CCat -> [Feat]
featsOf = sort . nub . go
  where
    go (CAtom _ fs)       = fs
    go (CSlash _ r a fs)  = fs ++ go r ++ go a

-- | Drop every feature bracket, keeping the slash structure and atoms.
eraseFeatures :: CCat -> CCat
eraseFeatures (CAtom n _)        = CAtom n []
eraseFeatures (CSlash d r a _)   = CSlash d (eraseFeatures r) (eraseFeatures a) []

--------------------------------------------------------------------------------
-- Representability classification
--------------------------------------------------------------------------------

-- | A summary of what a category needs to be represented, used to keep the
-- ingestion counts honestly separated.
data CatProfile = CatProfile
  { cpAtoms    :: [String]  -- ^ all distinct atoms used
  , cpNewAtoms :: [String]  -- ^ atoms outside {S, NP, N}
  , cpFeatures :: [Feat]    -- ^ all distinct features used
  }
  deriving (Eq, Show)

profile :: CCat -> CatProfile
profile c =
  CatProfile
    { cpAtoms    = as
    , cpNewAtoms = filter (`notElem` ["S", "NP", "N"]) as
    , cpFeatures = featsOf c
    }
  where as = atomsOf c

-- | The representability verdict for a category string. Ordered from
-- "already handled" to "cannot even be parsed".
data Representability
  = RepresentableAsIs
    -- ^ Only {S, NP, N} atoms and no features: the current 'Cat' holds it
    -- exactly.
  | NeedsFeature [Feat]
    -- ^ Only {S, NP, N} atoms, but carries features the current 'Cat' drops.
  | NeedsNewAtom [String]
    -- ^ Mentions atoms the current 'Cat' has no constructor for (@PP@, @conj@,
    -- punctuation …); may also carry features.
  | Malformed String
    -- ^ The string does not parse as a category at all.
  deriving (Eq, Show)

-- | Classify a raw category string. This is the function the handoff's Layer 1
-- asks for: it makes "malformed" and "merely unrepresentable" distinguishable,
-- and keeps the three representability buckets separate.
classify :: String -> Representability
classify raw = case parseCCGCat raw of
  Left err -> Malformed err
  Right c ->
    let p = profile c
    in if not (null (cpNewAtoms p))
         then NeedsNewAtom (cpNewAtoms p)
         else if not (null (cpFeatures p))
                then NeedsFeature (cpFeatures p)
                else RepresentableAsIs
