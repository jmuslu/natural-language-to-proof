-- | Modifier classes, and the layer each one is resolvable at.
--
-- == Why this module exists
--
-- Stage 1 gives every adjective one lexical entry — intersective conjunction,
-- @\\P. \\x. a(x) & P(x)@ — and the obvious candidate rule for
-- "NL2Proof.Readings.Alternatives" would treat every @N\/N@ word as an equally
-- good fusion candidate. Both are the same flattening error: __modifiers are not one kind of thing, and the classes differ
-- in how hard they are to resolve.__ Treating them uniformly means either
-- over-generating implausible candidates or silently getting truth conditions
-- wrong.
--
-- The same stratification shows up on the SDRT side: some discourse relations are
-- cued structurally (Narration follows from tense sequence) while others need
-- abstract inference (Explanation). Those belong at different layers too, for the
-- same reason. This module handles the modifier half; the discourse half is
-- "NL2Proof.Discourse.SDRT", which deliberately does not reuse this type — the
-- classes are different even though the stratification principle is shared.
--
-- Restored from tag @pre-cut@; not yet wired into "NL2Proof.Pipeline".
--
-- == The classes, ordered by resolution difficulty
--
-- 'modifierLayer' is the load-bearing function. Layer 1 is decidable from
-- structure alone, layer 3 needs world knowledge, and a candidate generator
-- should not pretend it can operate above the layer it has evidence for.
module NL2Proof.Readings.Modifier
  ( -- * Classes
    ModifierClass(..)
  , modifierLayer
  , classDescription
    -- * Behaviour implied by a class
  , isIntersective
  , mayFuseWithHead
  , preservesHeadTruth
  , reorderable
    -- * The fragment's classification
  , classifyModifier
  , fragmentModifierClasses
  , ambiguousModifiers
  ) where

import qualified Data.Map.Strict as M

--------------------------------------------------------------------------------
-- Classes
--------------------------------------------------------------------------------

-- | How a modifier combines with its head.
data ModifierClass
  = -- | @red@, @ancient@. @red(x) & dragon(x)@ is faithful: a red dragon is red
    -- and is a dragon. Reordering is meaning-preserving, and there is nothing to
    -- fuse.
    Intersective
  | -- | @chinese@, @nuclear@, @electric@. Names a /subkind/ rather than an
    -- independent property. @chinese(x) & dragon(x)@ is not obviously wrong, but
    -- @chinese_dragon(x)@ is often what is meant — a lexicalized kind with its
    -- own properties. This is the only class where fusion is a real candidate.
    Classificatory
  | -- | @skilled@, @large@, @good@. A skilled surgeon is skilled /as a surgeon/,
    -- so the property cannot be separated from the head. @skilled(x) &
    -- surgeon(x)@ is wrong, because @skilled(x)@ alone means nothing.
    Subsective
  | -- | @fake@, @former@, @alleged@. A fake gun is __not__ a gun. Emitting
    -- @fake(x) & gun(x)@ asserts something false, so this class is a
    -- representation error in Stage 1's lexicon rather than an ambiguity to
    -- rank.
    Privative
  deriving (Eq, Ord, Show, Enum, Bounded)

-- | Resolution layer. Lower is easier.
--
-- * __1__ — decidable from structure alone. No lexical knowledge needed beyond
--   the class itself.
-- * __2__ — needs the head noun, and a graded judgement about whether this
--   modifier-noun pair is conventionalized. This is where a similarity signal
--   earns its keep.
-- * __3__ — needs world knowledge or a real lexical resource. A structural
--   generator should flag and stop, not guess.
modifierLayer :: ModifierClass -> Int
modifierLayer Intersective   = 1
modifierLayer Classificatory = 2
modifierLayer Subsective     = 3
modifierLayer Privative      = 3

classDescription :: ModifierClass -> String
classDescription Intersective   = "intersective: conjunction is faithful"
classDescription Classificatory = "classificatory: may name a lexicalized subkind"
classDescription Subsective     = "subsective: property is relative to the head"
classDescription Privative      = "privative: head predicate does NOT hold"

--------------------------------------------------------------------------------
-- Behaviour implied by a class
--------------------------------------------------------------------------------

isIntersective :: ModifierClass -> Bool
isIntersective = (== Intersective)

-- | May this modifier fuse with the head into a single subkind predicate?
--
-- Only 'Classificatory'. This is the fix for the original over-generation: with
-- every @N\/N@ word treated as fusable, @"ancient Chinese red dragon"@ produced
-- @ancient_chinese@ and @chinese_red@ among its candidates, neither of which is a
-- plausible English subkind.
mayFuseWithHead :: ModifierClass -> Bool
mayFuseWithHead = (== Classificatory)

-- | Does @modifier(x) & head(x)@ keep the head predicate true?
--
-- False only for 'Privative', where the conjunction is not merely imprecise but
-- asserts something false.
preservesHeadTruth :: ModifierClass -> Bool
preservesHeadTruth Privative = False
preservesHeadTruth _         = True

-- | Can this modifier be freely reordered against its siblings without changing
-- meaning?
--
-- Only intersective conjunction commutes. Subsective and privative modifiers take
-- scope over what follows them, so moving them changes what they apply to.
reorderable :: ModifierClass -> Bool
reorderable Intersective = True
reorderable _            = False

--------------------------------------------------------------------------------
-- The fragment's classification
--------------------------------------------------------------------------------

-- | Classify one of the fragment's modifiers. Unknown words default to
-- 'Intersective', which is the assumption Stage 1 already makes — so this is
-- strictly an improvement on the status quo rather than a new source of error.
classifyModifier :: String -> ModifierClass
classifyModifier w = M.findWithDefault Intersective w fragmentModifierClasses

-- | Hand-classified, because the fragment is small enough to do honestly and
-- there is no lexical resource wired in yet.
--
-- When a real resource is available (WordNet-style class data, or corpus
-- statistics for the conventionalization judgement at layer 2) this table is the
-- thing it replaces. The table, not the callers — nothing downstream should need
-- to change.
fragmentModifierClasses :: M.Map String ModifierClass
fragmentModifierClasses =
  M.fromList
    [ ("red",      Intersective)
    , ("ancient",  Intersective)
    , ("young",    Intersective)
    , ("chinese",  Classificatory)
      -- 'old' is genuinely ambiguous: "an old man" is intersective (aged), "an
      -- old friend" is subsective (of long standing). Classified as the reading
      -- Stage 1 assumes, and listed in 'ambiguousModifiers' so the ambiguity is
      -- recorded rather than decided by this table.
    , ("old",      Intersective)
    ]

-- | Modifiers whose class is itself ambiguous, with a note on why.
--
-- Kept explicit because a hand table's real risk is quietly asserting a
-- classification it should not. These are the entries where the table is making
-- a choice rather than reporting a fact.
ambiguousModifiers :: [(String, String)]
ambiguousModifiers =
  [ ( "old"
    , "intersective in 'an old man' (aged), subsective in 'an old friend' "
      ++ "(of long standing); classified intersective to match Stage 1"
    )
  ]
