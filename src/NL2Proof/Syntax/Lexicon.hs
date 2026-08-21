-- | The lexicon for the closed English fragment.
--
-- Deliberately small. Per ARCHITECTURE.md the Stage 1 target is a handful of
-- sentence types covering simple transitives, quantified NPs, a relative clause,
-- a cross-sentence pronoun, and a compound-noun\/coupling case — implemented
-- fully and tested, rather than broad coverage implemented shallowly.
--
-- Every noun phrase is a generalized quantifier of type @(e -> t) -> t@,
-- including proper names. That uniformity is what lets @"John"@ and
-- @"every student"@ combine with one and the same verb entry.
module NL2Proof.Syntax.Lexicon
  ( -- * Entries
    Entry(..)
  , Lexicon
  , mkLexicon
  , lookupWord
  , lexiconKeys
  , inLexicon
  , entriesWithCat
  , isModifierWord
  , maxPhraseLength
    -- * The fragment
  , fragmentLexicon
    -- * Entry builders
  , nameEntry
  , nounEntry
  , adjEntry
  , ivEntry
  , tvEntry
  , pronounEntry
  ) where

import Data.Char (toLower)
import qualified Data.Map as M

import NL2Proof.Semantics.Lambda
import NL2Proof.Syntax.Category

--------------------------------------------------------------------------------
-- Entries
--------------------------------------------------------------------------------

-- | A lexical entry: a category, a meaning of the type that category demands,
-- and a short gloss naming the entry's linguistic role.
data Entry = Entry
  { entryCat   :: Cat
  , entrySem   :: Term
  , entryGloss :: String
  }
  deriving (Eq, Show)

-- | Words map to a /list/ of entries: lexical ambiguity is represented, not
-- resolved. Resolving it is a downstream decision.
newtype Lexicon = Lexicon (M.Map String [Entry])

-- | Keys are lower-cased. Multi-word keys use single spaces (@"does not"@).
mkLexicon :: [(String, [Entry])] -> Lexicon
mkLexicon = Lexicon . M.fromListWith (++) . map (\(k, v) -> (map toLower k, v))

lookupWord :: Lexicon -> String -> [Entry]
lookupWord (Lexicon m) w = M.findWithDefault [] (map toLower w) m

lexiconKeys :: Lexicon -> [String]
lexiconKeys (Lexicon m) = M.keys m

inLexicon :: Lexicon -> String -> Bool
inLexicon l = not . null . lookupWord l

entriesWithCat :: Lexicon -> Cat -> String -> [Entry]
entriesWithCat l c w = filter ((== c) . entryCat) (lookupWord l w)

-- | Does this word have an @N\/N@ reading? Used to detect stacked modifiers,
-- the @"ancient Chinese red dragon"@ coupling case.
isModifierWord :: Lexicon -> String -> Bool
isModifierWord l w = not (null (entriesWithCat l (N :/ N) w))

-- | Longest multi-word key in the fragment, in tokens. The tokenizer uses this
-- as its greedy-match window.
maxPhraseLength :: Int
maxPhraseLength = 3

--------------------------------------------------------------------------------
-- Entry builders
--------------------------------------------------------------------------------

-- | Proper name: @NP@, @\\P. P(n)@.
nameEntry :: String -> Entry
nameEntry n = Entry NP (Lam "P" tyPred1 (App (Var "P") (entity n))) "proper name"

-- | Common noun: @N@, the bare predicate.
nounEntry :: String -> Entry
nounEntry n = Entry N (pred1 n) "common noun"

-- | Intersective adjective: @N\/N@, @\\P. \\x. a(x) & P(x)@.
--
-- This is the /naive/ treatment, and it is knowingly wrong for fused compounds.
-- See "NL2Proof.Trace".'NL2Proof.Trace.ModifierCoupling': Stage 1 produces the
-- iterated-intersection reading and flags the stack rather than pretending the
-- ambiguity is not there.
adjEntry :: String -> Entry
adjEntry a =
  Entry
    (N :/ N)
    (Lam "P" tyPred1 (Lam "x" TyE (TAnd (App (pred1 a) (Var "x")) (App (Var "P") (Var "x")))))
    "intersective adjective"

-- | Intransitive verb: @S\\NP@, @\\S. S(v)@.
ivEntry :: String -> Entry
ivEntry v = Entry (S :\ NP) (Lam "S" tyGQ (App (Var "S") (pred1 v))) "intransitive verb"

-- | Transitive verb: @(S\\NP)\/NP@, subject taking wide scope.
--
-- The subject-wide-scope choice is baked into the lexical entry, which means the
-- inverse reading of @"Every student reads a book"@ is not generated at all.
-- That is a Stage 1 limitation recorded as such: scope alternation belongs to
-- the Stage 2 candidate-generation layer, not to a hand-written lexicon.
tvEntry :: String -> Entry
tvEntry v =
  Entry
    ((S :\ NP) :/ NP)
    ( Lam "O" tyGQ
        (Lam "S" tyGQ
           (App (Var "S")
              (Lam "x" TyE
                 (App (Var "O") (Lam "y" TyE (apply (pred2 v) [Var "x", Var "y"]))))))
    )
    "transitive verb"

-- | Pronoun: @NP@ over an unresolved anaphor constant, discharged at the DRT
-- stage where discourse context exists.
pronounEntry :: String -> Entry
pronounEntry p = Entry NP (Lam "P" tyPred1 (App (Var "P") (mkAnaphor p))) "pronoun"

--------------------------------------------------------------------------------
-- Determiners, relativizer, negation
--------------------------------------------------------------------------------

-- | @every@: @\\P. \\Q. forall x. P(x) -> Q(x)@
detEvery :: Entry
detEvery =
  Entry
    (NP :/ N)
    ( Lam "P" tyPred1
        (Lam "Q" tyPred1
           (TForall "x" TyE (TImp (App (Var "P") (Var "x")) (App (Var "Q") (Var "x")))))
    )
    "universal determiner"

-- | @a@ \/ @an@ \/ @some@: @\\P. \\Q. exists x. P(x) & Q(x)@
detExists :: Entry
detExists =
  Entry
    (NP :/ N)
    ( Lam "P" tyPred1
        (Lam "Q" tyPred1
           (TExists "x" TyE (TAnd (App (Var "P") (Var "x")) (App (Var "Q") (Var "x")))))
    )
    "existential determiner"

-- | @no@: @\\P. \\Q. ~ exists x. P(x) & Q(x)@
detNo :: Entry
detNo =
  Entry
    (NP :/ N)
    ( Lam "P" tyPred1
        (Lam "Q" tyPred1
           (TNot (TExists "x" TyE (TAnd (App (Var "P") (Var "x")) (App (Var "Q") (Var "x"))))))
    )
    "negative determiner"

-- | Subject relativizer: @(N\\N)\/(S\\NP)@,
-- @\\V. \\P. \\x. P(x) & V(\\Q. Q(x))@.
--
-- The inner @\\Q. Q(x)@ is the generalized quantifier standing in for the gap,
-- which is how the verb phrase gets an @NP@-typed argument without an @NP@
-- being present in the string.
relEntry :: Entry
relEntry =
  Entry
    ((N :\ N) :/ (S :\ NP))
    ( Lam "V" (tyGQ ~> TyT)
        (Lam "P" tyPred1
           (Lam "x" TyE
              (TAnd (App (Var "P") (Var "x"))
                    (App (Var "V") (Lam "Q" tyPred1 (App (Var "Q") (Var "x")))))))
    )
    "subject relativizer"

-- | @does not@: @(S\\NP)\/(S\\NP)@, @\\V. \\S. ~ V(S)@.
--
-- Negation scopes outside the subject here. For the proper-name subjects in this
-- fragment the two scopings are equivalent; for a quantified subject they are
-- not, and that divergence is a scope-ambiguity case for Stage 2.
negEntry :: Entry
negEntry =
  Entry
    ((S :\ NP) :/ (S :\ NP))
    (Lam "V" (tyGQ ~> TyT) (Lam "S" tyGQ (TNot (App (Var "V") (Var "S")))))
    "verbal negation"

--------------------------------------------------------------------------------
-- The fragment
--------------------------------------------------------------------------------

-- | The closed fragment's vocabulary.
fragmentLexicon :: Lexicon
fragmentLexicon =
  mkLexicon $
    concat
      [ -- proper names
        [ (w, [nameEntry w]) | w <- ["john", "mary", "susan"] ]
        -- common nouns
      , [ (w, [nounEntry w]) | w <- ["student", "book", "dragon", "professor", "poem"] ]
        -- intersective adjectives
      , [ (w, [adjEntry w]) | w <- ["ancient", "chinese", "red", "old", "young"] ]
        -- pronouns
      , [ (w, [pronounEntry w]) | w <- ["she", "he", "it", "they"] ]
        -- determiners
      , [ ("every", [detEvery])
        , ("a",     [detExists])
        , ("an",    [detExists])
        , ("some",  [detExists])
        , ("no",    [detNo])
        ]
        -- relativizers
      , [ ("who",  [relEntry])
        , ("that", [relEntry])
        ]
        -- negation (multi-word entry, merged by the tokenizer)
      , [ ("does not", [negEntry]) ]
        -- intransitive verbs: inflected and bare stems (the latter appear after
        -- "does not")
      , [ ("smiles",  [ivEntry "smile"])
        , ("smile",   [ivEntry "smile"])
        , ("sleeps",  [ivEntry "sleep"])
        , ("sleep",   [ivEntry "sleep"])
        , ("walks",   [ivEntry "walk"])
        , ("walk",    [ivEntry "walk"])
        , ("arrived", [ivEntry "arrive"])
        , ("arrive",  [ivEntry "arrive"])
        ]
        -- transitive verbs: inflected and bare stems
      , [ ("loves", [tvEntry "love"])
        , ("love",  [tvEntry "love"])
        , ("reads", [tvEntry "read"])
        , ("read",  [tvEntry "read"])
        , ("sees",  [tvEntry "see"])
        , ("see",   [tvEntry "see"])
        , ("wrote", [tvEntry "write"])
        , ("write", [tvEntry "write"])
        ]
      ]
