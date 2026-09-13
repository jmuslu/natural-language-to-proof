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
  , templateSkeletonFor
  , corpusEntry
  , peToEntry
  , skeletonWellTyped
  , IngestResult(..)
  , ingest
  ) where

import Data.List (nub)

import NL2Proof.Semantics.Lambda
  ( Term(..), Ty(TyE, TyT), (~>), tyPred1, tyGQ, entity, pred1, typeOf )
import NL2Proof.Syntax.Category
  ( Cat(S, NP, N, Feature, (:/), (:\)), catTy )
import NL2Proof.Syntax.Lexicon (Entry(..))
import NL2Proof.Syntax.CCGBank (parseCCGCat, ccatToCat, atomsOf)
import NL2Proof.Syntax.CCGRules (isCoordinator)

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

-- | A /richer/ canonical meaning for the common content-word category shapes: a
-- first-order Montague template with actual predicate-argument structure, rather
-- than the opaque constant 'skeletonFor' produces.
--
-- This is a __stipulated default, not a faithful meaning__ (the same honesty caveat
-- as 'skeletonFor', TRACE S2): it assumes the standard intersective / neo-Montague
-- reading, which is right for a plain transitive verb or intersective adjective and
-- wrong for many real words. It exists so the DRT/SDRT stages can be exercised on
-- reconstructed sentences: 'toDRS' consumes a 'Term', and an opaque constant yields a
-- degenerate DRS with no variables or predicates for anaphora/accessibility to act
-- on, whereas these templates yield real discourse referents and conditions. It does
-- NOT replace 'skeletonFor' -- ingestion still uses the opaque skeleton by default;
-- this is opt-in for the meaning/DRT experiment. Only the common shapes are templated
-- (noun, proper NP, intransitive/transitive verb, intersective adjective); every
-- other category falls back to the opaque constant, honestly untemplated.
--
-- Recall @catTy NP == tyGQ@, so arguments are generalized quantifiers and the verb
-- templates quantify in; each template inhabits exactly @catTy cat@ (checked in the
-- suite), so it composes under the parser like any other entry.
templateSkeletonFor :: String -> Cat -> Term
templateSkeletonFor w cat = case eraseFeat cat of
  N                 -> Lam "x" TyE (App (pred1 w) (Var "x"))                 -- λx. w(x)
  NP                -> Lam "p" tyPred1 (App (Var "p") (entity w))            -- λP. P(w)
  (S :\ NP)         -> Lam "q" tyGQ (App (Var "q") (pred1 w))               -- λQ. Q(λx. w(x))
  ((S :\ NP) :/ NP) -> transitive                                            -- λQo Qs. Qs(λx. Qo(λy. w(x,y)))
  (N :/ N)          -> adjective                                             -- λP x. w(x) ∧ P(x)
  (N :\ N)          -> adjective
  (NP :/ N)         -> determiner                                            -- λP Q. ∃x. P(x) ∧ Q(x)  (indefinite default)
  _                 -> skeletonFor w cat                                     -- honest fallback
  where
    transitive =
      Lam "qo" tyGQ (Lam "qs" tyGQ
        (App (Var "qs")
          (Lam "x" TyE
            (App (Var "qo")
              (Lam "y" TyE
                (App (App (Con w (TyE ~> TyE ~> TyT)) (Var "x")) (Var "y")))))))
    adjective =
      Lam "p" tyPred1 (Lam "x" TyE
        (TAnd (App (pred1 w) (Var "x")) (App (Var "p") (Var "x"))))
    -- indefinite default for a determiner NP/N: introduces a discourse referent, so
    -- composed sentences yield DRSs with real universes (what DRT needs). Definites /
    -- universals differ; templating every NP/N as indefinite is the stipulation.
    determiner =
      Lam "p" tyPred1 (Lam "q" tyPred1
        (TExists "x" TyE
          (TAnd (App (Var "p") (Var "x")) (App (Var "q") (Var "x")))))

-- | Erase all feature wrappers so template selection matches on the bare shape
-- (@catTy@ already erases features, so the template's type is unaffected).
eraseFeat :: Cat -> Cat
eraseFeat (Feature _ c) = eraseFeat c
eraseFeat (a :/ b)      = eraseFeat a :/ eraseFeat b
eraseFeat (a :\ b)      = eraseFeat a :\ eraseFeat b
eraseFeat c             = c

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
  | RuleHandled String       -- ^ not a lexical /type/ but handled by a combinatory
                             --   rule (the mechanism, e.g. @"coordination"@). A bare
                             --   @conj@\/comma\/semicolon coordinator has no
                             --   monomorphic skeleton, yet 'CCGRules.combine' parses
                             --   it via the two-step coordination rule
                             --   (@conj X => X[conj]@, then @X X[conj] => X@). Kept
                             --   distinct from 'Unrepresentable' so "handled
                             --   structurally, not lexically" is not miscounted as
                             --   "cannot represent".
  | Unrepresentable [String] -- ^ mentions atoms with neither a core 'Cat' type nor a
                             --   rule (conj-/function/ categories, @.@ @:@ LRB RRB)
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
      Nothing
        | isCoordinator ccat -> RuleHandled "coordination"
        | otherwise -> Unrepresentable (nub (filter (`notElem` ["S", "NP", "N", "PP"]) (atomsOf ccat)))
