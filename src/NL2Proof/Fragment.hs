-- | The fixed evaluation set.
--
-- ARCHITECTURE.md, methodology:
--
-- > Fix a stable evaluation set of test sentences\/short discourses before
-- > comparing any variant of the augmentation layer. Without this, comparisons
-- > are vibes, not evidence.
--
-- So the set lives here, in the library, as data — not inline in the test file.
-- Stage 2 will compare SDRT, RSA, and DisCoCat against /these/ cases, and it can
-- only do that if they are importable rather than embedded in a test runner.
--
-- Expected forms are hand-written 'Term's compared with 'alphaEq', not strings.
-- Bound-variable names are an artifact of derivation order and are not part of
-- the logical content, so asserting on them would make the suite fail for
-- reasons that do not matter.
module NL2Proof.Fragment
  ( FragmentCase(..)
  , fragmentCases
  , caseById
    -- * Expected-form helpers
  , ap1
  , ap2
  ) where

import NL2Proof.Semantics.Lambda
import NL2Proof.Trace (DiagKind (..))

-- | One case in the evaluation set.
data FragmentCase = FragmentCase
  { caseId    :: String
  , caseKind  :: String
    -- ^ The sentence type this case covers.
  , caseText  :: String
  , caseForms :: [Term]
    -- ^ Expected logical form per sentence, in order.
    --
    -- These are /pre-DRS/ forms, so a pronoun still appears as an unresolved
    -- anaphor constant here. Resolution is a discourse-level operation and is
    -- asserted separately.
  , caseDiags :: [DiagKind]
    -- ^ Diagnostics the pipeline is expected to raise.
  , caseNotes :: String
  }

-- | @ap1 "student" (Var "x")@ is @student(x)@.
ap1 :: String -> Term -> Term
ap1 n a = App (pred1 n) a

-- | @ap2 "love" j m@ is @love(j, m)@.
ap2 :: String -> Term -> Term -> Term
ap2 n a b = apply (pred2 n) [a, b]

x_, y_ :: Term
x_ = Var "x"
y_ = Var "y"

fragmentCases :: [FragmentCase]
fragmentCases =
  [ FragmentCase
      { caseId = "transitive"
      , caseKind = "simple transitive, two proper names"
      , caseText = "John loves Mary."
      , caseForms = [ap2 "love" (entity "john") (entity "mary")]
      , caseDiags = []
      , caseNotes =
          "Baseline. Both NPs are generalized quantifiers, so the two"
            ++ " applications of the verb entry reduce away entirely and the"
            ++ " normal form is atomic."
      }
  , FragmentCase
      { caseId = "intransitive"
      , caseKind = "intransitive, proper name subject"
      , caseText = "Mary smiles."
      , caseForms = [ap1 "smile" (entity "mary")]
      , caseDiags = []
      , caseNotes = "Backward application only."
      }
  , FragmentCase
      { caseId = "quantified"
      , caseKind = "quantified NP subject, indefinite object"
      , caseText = "Every student reads a book."
      , caseForms =
          [ TForall "x" TyE
              (TImp (ap1 "student" x_)
                    (TExists "y" TyE (TAnd (ap1 "book" y_) (ap2 "read" x_ y_))))
          ]
      , caseDiags = []
      , caseNotes =
          "Only the subject-wide-scope reading is generated, because scope is"
            ++ " fixed in the transitive verb's lexical entry. The inverse"
            ++ " reading is a Stage 2 candidate-generation concern, not a"
            ++ " Stage 1 omission to be patched in the lexicon."
      }
  , FragmentCase
      { caseId = "negative-quantifier"
      , caseKind = "negative determiner"
      , caseText = "No student sleeps."
      , caseForms =
          [TNot (TExists "x" TyE (TAnd (ap1 "student" x_) (ap1 "sleep" x_)))]
      , caseDiags = []
      , caseNotes =
          "The referent lands inside a negated box, which makes it"
            ++ " inaccessible to later anaphora. See the"
            ++ " 'blocked-anaphora' case."
      }
  , FragmentCase
      { caseId = "negation"
      , caseKind = "verbal negation"
      , caseText = "John does not love Mary."
      , caseForms = [TNot (ap2 "love" (entity "john") (entity "mary"))]
      , caseDiags = []
      , caseNotes =
          "\"does not\" is a single multi-word lexical entry. It is a unit"
            ++ " of the parse, not of a tokenization run in front of it: the"
            ++ " lattice offers it as an edge spanning two words and CKY uses"
            ++ " it. Here nothing competes, because neither part has an entry"
            ++ " of its own."
      }
  , FragmentCase
      { caseId = "relative-clause"
      , caseKind = "subject relative clause"
      , caseText = "Every student who reads a book smiles."
      , caseForms =
          [ TForall "x" TyE
              (TImp
                 (TAnd (ap1 "student" x_)
                       (TExists "y" TyE (TAnd (ap1 "book" y_) (ap2 "read" x_ y_))))
                 (ap1 "smile" x_))
          ]
      , caseDiags = []
      , caseNotes =
          "The relativizer supplies a generalized quantifier for the gap, so"
            ++ " the verb phrase gets an NP-typed argument with no NP in the"
            ++ " string."
      }
  , FragmentCase
      { caseId = "anaphora"
      , caseKind = "cross-sentence pronoun"
      , caseText = "A student arrived. She smiles."
      , caseForms =
          [ TExists "x" TyE (TAnd (ap1 "student" x_) (ap1 "arrive" x_))
          , ap1 "smile" (mkAnaphor "she")
          ]
      , caseDiags = []
      , caseNotes =
          "The anaphor survives composition unresolved and is discharged"
            ++ " against the discourse context, producing a logged Decision."
      }
  , FragmentCase
      { caseId = "blocked-anaphora"
      , caseKind = "pronoun with inaccessible antecedent"
      , caseText = "No student sleeps. She smiles."
      , caseForms =
          [ TNot (TExists "x" TyE (TAnd (ap1 "student" x_) (ap1 "sleep" x_)))
          , ap1 "smile" (mkAnaphor "she")
          ]
      , caseDiags = [UnresolvedAnaphor]
      , caseNotes =
          "Standard DRT accessibility: a referent introduced under negation is"
            ++ " not available to a later pronoun. Failing to resolve here is"
            ++ " the correct behaviour, and the diagnostic records it rather"
            ++ " than the pipeline guessing."
      }
  , FragmentCase
      { caseId = "coupling"
      , caseKind = "stacked modifiers / compound-noun coupling"
      , caseText = "John sees an ancient Chinese red dragon."
      , caseForms =
          [ TExists "x" TyE
              (TAnd
                 (TAnd (ap1 "ancient" x_)
                    (TAnd (ap1 "chinese" x_)
                       (TAnd (ap1 "red" x_) (ap1 "dragon" x_))))
                 (ap2 "see" (entity "john") x_))
          ]
      , caseDiags = [ModifierCoupling]
      , caseNotes =
          "The reading produced is iterated intersection, which is the wrong"
            ++ " analysis if the modifier-noun pair has fused into a"
            ++ " lexicalized subkind. Stage 1 does not attempt to decide;"
            ++ " it produces the compositional reading and flags the stack for"
            ++ " Stage 2's tensor/kernel coupling detection. Detecting the"
            ++ " ambiguity and resolving it are different jobs."
      }
  ]

caseById :: String -> Maybe FragmentCase
caseById i = case filter ((== i) . caseId) fragmentCases of
  (c : _) -> Just c
  []      -> Nothing
