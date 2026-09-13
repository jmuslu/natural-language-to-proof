-- | Turning CCGbank @(word, category)@ pairs into provenance-tagged lexical
-- entries the core parser can use.
--
-- This is the Layer 2 "lexicon growth from CCGbank" deliverable. A corpus line
-- gives a /category/ but no /meaning/, so this synthesises a canonical,
-- type-correct meaning __skeleton__ for the category and records the entry with
-- explicit provenance. Three honesty points, all from the handoff:
--
--   * __The category is corpus-attested; the meaning is synthesised.__ The
--     category is trustworthy because CCGbank is linguist-annotated; the meaning
--     skeleton is not attested by anything, and is flagged as such
--     ('CorpusAttested' tags the /category/'s source, and the skeleton is
--     deliberately opaque — see 'skeletonFor').
--   * __'typeOf' on the skeleton is a weak gate, and that is stated, not hidden.__
--     Every semantic type in the @{e,t}@ calculus is trivially inhabited, so
--     @skeletonWellTyped@ can never fail; it verifies the /synthesiser/ produces
--     well-typed terms (a real property of this code), not that the meaning is
--     faithful. Faithful predicate-argument semantics needs the per-construction
--     decisions the handoff says are not derivable, and is not claimed here.
--   * __Representability is kept a visible, separate axis from provenance.__ With
--     the feature-migrated 'Cat', S\/NP\/N\/PP + features project directly
--     ('ccatToCat'); only @conj@ and punctuation atoms still can't, and those are
--     reported as 'NeedsNewAtom' rather than silently built.
module NL2Proof.Syntax.CCGLexicon
  ( Provenance(..)
  , ProvEntry(..)
  , skeletonFor
  , corpusEntry
  , peToEntry
  , skeletonWellTyped
  , IngestResult(..)
  , ingest
  ) where

import Data.List (nub)

import NL2Proof.Semantics.Lambda (Term(Con), typeOf)
import NL2Proof.Syntax.Category (Cat, catTy)
import NL2Proof.Syntax.Lexicon (Entry(..))
import NL2Proof.Syntax.CCGBank (parseCCGCat, ccatToCat, atomsOf)

-- | Where a lexical entry's category came from. The three-way split the handoff
-- requires, kept from collapsing into one undifferentiated count.
data Provenance
  = HandWritten            -- ^ the closed fragment's own entries
  | CorpusAttested String  -- ^ lifted from CCGbank (the source tag, e.g. "CCGbank")
  | LLMProposed            -- ^ guessed by an LLM, no corpus attestation (future)
  deriving (Eq, Ord, Show)

-- | A lexical entry plus its provenance. Kept separate from the core 'Entry' so
-- the hand-written fragment is untouched; provenance lives with the grown lexicon.
data ProvEntry = ProvEntry
  { peWord :: String
  , peCat  :: Cat
  , peSem  :: Term
  , peProv :: Provenance
  }
  deriving (Eq, Show)

-- | The canonical, type-correct meaning skeleton for a category: a single
-- constant, named by the word, of exactly the type the category demands.
--
-- It is deliberately /opaque/ — it does not decompose into predicate-argument
-- structure (that would be the un-derivable per-construction semantics). It is a
-- valid inhabitant of @catTy cat@ (so it type-checks and composes under the
-- parser's application rules), and it names the word (so distinct words give
-- distinct constants). That is the honest content of "synthesise a meaning for a
-- corpus category": a usable placeholder of the right type, not a claim about
-- what the word means.
skeletonFor :: String -> Cat -> Term
skeletonFor word cat = Con word (catTy cat)

-- | Build a corpus-attested provenance entry for a @(word, category)@ pair.
corpusEntry :: String -> Cat -> String -> ProvEntry
corpusEntry word cat src = ProvEntry word cat (skeletonFor word cat) (CorpusAttested src)

-- | Drop provenance to get a core 'Entry' for the parser's lexicon. The gloss
-- records the provenance so it is not lost when it enters the core type.
peToEntry :: ProvEntry -> Entry
peToEntry pe = Entry (peCat pe) (peSem pe) (gloss (peProv pe))
  where
    gloss HandWritten        = "hand-written"
    gloss (CorpusAttested s) = "corpus-attested (" ++ s ++ ")"
    gloss LLMProposed        = "llm-proposed"

-- | Does the entry's meaning inhabit the type its category demands? This is the
-- same check the fragment suite runs on hand-written entries. For a synthesised
-- skeleton it can never fail (see the module header); it confirms the synthesiser
-- is correct, and would catch a future non-skeleton meaning that was mistyped.
skeletonWellTyped :: ProvEntry -> Bool
skeletonWellTyped pe = typeOf [] (peSem pe) == Right (catTy (peCat pe))

-- | The outcome of ingesting one @(word, category-string)@ pair. (Constructor
-- names are distinct from 'NL2Proof.Syntax.CCGBank.Representability' so both can
-- be imported together.)
data IngestResult
  = Built ProvEntry          -- ^ representable in the core 'Cat'; entry built
  | Unrepresentable [String] -- ^ mentions atoms the core 'Cat' lacks (conj, punctuation)
  | Unparseable String       -- ^ the category string does not parse
  deriving (Eq, Show)

-- | Ingest one @(word, category-string)@ pair, tagging with a source. Parses the
-- category, projects it into the feature-bearing core 'Cat', and — if
-- representable — builds a corpus-attested skeleton entry. Malformed vs.
-- unrepresentable stays distinguishable (the Layer 1 requirement).
ingest :: String -> String -> String -> IngestResult
ingest src word catStr =
  case parseCCGCat catStr of
    Left e     -> Unparseable e
    Right ccat -> case ccatToCat ccat of
      Just cat -> Built (corpusEntry word cat src)
      Nothing  -> Unrepresentable (nub (filter (`notElem` ["S", "NP", "N", "PP"]) (atomsOf ccat)))
