-- | Meanings for CCGbank categories: the semantic layer that turns the
-- CCGbank-trained parser's derivations into typed lambda terms.
--
-- The parser ("NL2Proof.Syntax.CCGParse", "NL2Proof.Syntax.CCGSupertag") assigns
-- categories and combines them; it knows nothing about meaning. This module
-- supplies meaning in exactly three places, and nowhere else:
--
-- 1. __Lexical entries.__ Closed-class words get explicit, hand-written entries
--    keyed by @(word, category)@ ('closedEntries'). Open-class words get a
--    template chosen by the /shape/ of the category alone ('openTemplate'). A
--    @(word, category)@ pair with neither has /no meaning/, and the parser drops
--    that candidate instead of inventing an opaque constant — so an
--    uninterpretable category shows up as a failed parse, not as a well-typed
--    term that means nothing.
--
-- 2. __Combinators.__ Application, composition, coordination and punctuation
--    each have one fixed semantic operation ('composeTerm', 'coordTerm').
--
-- 3. __Unary type-changes.__ Only those whose meaning is fixed by their shape
--    get one ('unarySem'): type-raising, and @N -> NP@ (bare noun phrases).
--    Every other learned type-change is syntactic only and is not used.
--
-- Every entry inhabits @catTy@ of its category; the test suite checks that for
-- each one, which is the same coherence check the hand lexicon is held to.
--
-- Where an entry fixes something the syntax leaves open (negation scope, the
-- quantificational force of a bare plural), it carries a 'Stipulation'. The
-- pipeline logs that stipulation as a 'NL2Proof.Trace.Decision' whenever the
-- entry is used in a chosen derivation, so the choice is never silent.
module NL2Proof.Semantics.CCGSem
  ( -- * Types
    semTy
  , LexItem(..)
  , Stipulation(..)
    -- * Lexical entries
  , closedTable
  , closedClassWords
  , isClosedClass
  , closedEntries
  , intensionalTable
  , attitudeEntry
  , attitudeEntryWith
  , thatClauseCat
  , reportingLemma
  , openTemplate
  , openTemplateWith
  , nameItem
  , restrictedPronounEntries
  , lemma3sg
  , verbLemma
    -- * Sortal predicates
  , sortalThing
  , sortalPerson
  , isSortal
    -- * Combinator semantics
  , composeTerm
  , coordinatorOp
  , coordTerm
  , unarySem
  ) where

import Data.Char (isPunctuation, toLower)
import Data.List (isSuffixOf)

import NL2Proof.Semantics.Intensional
import NL2Proof.Semantics.Lambda
import NL2Proof.Syntax.CCGBank (CCat(..), Dir(..), Feat(..), ccatToCat, parseCCGCat)
import NL2Proof.Syntax.CCGRules (isPunct, unifiable)
import NL2Proof.Syntax.Category (catTy)

--------------------------------------------------------------------------------
-- Types
--------------------------------------------------------------------------------

-- | The semantic type a CCGbank category demands: project into the core 'Cat'
-- and apply 'catTy' (features erased, @PP@ as an argument-like @NP@). 'Nothing'
-- for categories with no semantic type (@conj@, punctuation atoms).
semTy :: CCat -> Maybe Ty
semTy = fmap catTy . ccatToCat

-- | A choice an entry makes that the syntax does not force. Logged as a
-- 'NL2Proof.Trace.Decision' each time a chosen derivation uses the entry.
data Stipulation = Stipulation
  { stKind         :: String
  , stChoice       :: String
  , stAlternatives :: [String]
  , stWhy          :: String
  }
  deriving (Eq, Show)

-- | What the semantic lexicon says about one @(word, category)@ pair.
data LexItem
  = -- | A meaning of type @semTy cat@.
    LexTerm Term String (Maybe Stipulation)
  | -- | A coordinator or punctuation mark. It has no meaning of its own; its
    -- contribution is fixed by the combinator that consumes it
    -- ('coordinatorOp', punctuation absorption).
    LexStructural String
  deriving (Eq, Show)

--------------------------------------------------------------------------------
-- Closed class
--------------------------------------------------------------------------------

cat :: String -> CCat
cat s = either (error . ("CCGSem: bad category literal: " ++)) id (parseCCGCat s)

-- | The sortal predicates contributed by @thing(s)@\/@something@ and
-- @people@\/@someone@. They restrict a variable to things or persons; the
-- ProofWriter conversion reads them as the variable's name and drops them.
sortalThing, sortalPerson :: String
sortalThing = "thing"
sortalPerson = "person"

isSortal :: String -> Bool
isSortal p = p == sortalThing || p == sortalPerson

x_, p_, q_ :: Term
x_ = Var "x"
p_ = Var "P"
q_ = Var "Q"

-- | The pronoun/gap lift @\\P. P(x)@ of an entity variable.
liftE :: Term -> Term
liftE e = Lam "P" tyPred1 (App p_ e)

detThe, detAll, detSome, detNo :: Term
-- | @the@: @\\P \\Q. Q(iota P)@ — a definite description (see 'iota').
detThe = Lam "P" tyPred1 (Lam "Q" tyPred1 (App q_ (iota p_)))
-- | @all@\/@every@: @\\P \\Q. forall x. P(x) -> Q(x)@.
detAll = Lam "P" tyPred1 (Lam "Q" tyPred1
  (TForall "x" TyE (TImp (App p_ x_) (App q_ x_))))
-- | @a@\/@an@: @\\P \\Q. exists x. P(x) & Q(x)@.
detSome = Lam "P" tyPred1 (Lam "Q" tyPred1
  (TExists "x" TyE (TAnd (App p_ x_) (App q_ x_))))

-- | Negative determiner: negate the entire restricted existential.
-- Its witness cannot escape into the main DRS or become an asserted atom.
detNo = Lam "P" tyPred1 (Lam "Q" tyPred1
  (TNot (TExists "x" TyE (TAnd (App p_ x_) (App q_ x_)))))

-- | Copula and auxiliary: semantically empty, @\\V. V@ over a VP meaning.
vpIdentity :: Term
vpIdentity = Lam "V" (tyGQ ~> TyT) (Var "V")

-- | @not@ as a VP operator, __subject scoping over negation__:
-- @\\V \\S. S(\\x. ~V(\\P. P(x)))@.
--
-- The alternative (@~V(S)@, negation over the subject) differs exactly when the
-- subject is quantified: @"something is not round"@ is /some thing is non-round/
-- under this entry and /nothing is round/ under the other. The entry picks the
-- first, and says so ('negScope').
vpNot :: Term
vpNot = Lam "V" (tyGQ ~> TyT) (Lam "S" tyGQ
  (App (Var "S") (Lam "x" TyE (TNot (App (Var "V") (liftE x_))))))

negScope :: Stipulation
negScope = Stipulation
  { stKind = "scope"
  , stChoice = "subject > not"
  , stAlternatives = ["not > subject"]
  , stWhy = "lexical entry for VP negation gives the subject wide scope; the two"
      ++ " readings differ only for a quantified subject"
  }

-- | @if@: @\\p \\q. p -> q@ (category @(S\/S)\/S[dcl]@).
ifTerm :: Term
ifTerm = Lam "p" TyT (Lam "q" TyT (TImp (Var "p") (Var "q")))

-- | @then@ as @S\/S@: @\\p. p@.
sIdentity :: Term
sIdentity = Lam "p" TyT (Var "p")

indefinite :: String -> Term
indefinite sortal = Lam "P" tyPred1
  (TExists "x" TyE (TAnd (App (pred1 sortal) x_) (App p_ x_)))

sortalNoun :: String -> Term
sortalNoun sortal = Lam "x" TyE (App (pred1 sortal) x_)

-- | A pronoun at token position @i@: @\\P. P(?w_i)@. The position makes two
-- occurrences of the same pronoun distinct anaphors, so each is resolved (and
-- logged) on its own.
pronoun :: String -> Int -> Term
pronoun w i = Lam "P" tyPred1 (App p_ (mkAnaphor (w ++ "_" ++ show i)))

-- | Restrictive subject relatives attach to the noun, before its determiner.
-- An NP-level pointwise conjunction would incorrectly require /all/ cats to
-- be red in "every cat that is red". Object-gap and nonrestrictive relatives
-- need distinct constructions and are deliberately not supplied here.
subjectRelative :: Term
subjectRelative = Lam "V" (tyGQ ~> TyT) (Lam "N" tyPred1 (Lam "x" TyE
  (TAnd (App (Var "N") x_) (App (Var "V") (liftE x_)))))

-- | Local direct-object binding: apply the subject quantifier once, with
-- the same individual in the verb's object and subject slots. The parser
-- licenses this only against a lexical finite/base transitive governor.
localReflexive :: Term
localReflexive = Lam "R" (tyGQ ~> tyGQ ~> TyT) (Lam "S" tyGQ
  (App (Var "S") (Lam "x" TyE
    (App (App (Var "R") (liftE x_)) (liftE x_)))))

-- | Meanings for a paired, subject-relative quantified-pronoun construction.
-- These are not ordinary closed-table categories: the parser must certify the
-- offered NP head and subject-relative origins before assigning NP/N and N/VP.
-- Something is deliberately absent until its domain/sortal policy is resolved.
restrictedPronounEntries :: String -> Maybe (LexItem, LexItem)
restrictedPronounEntries word = do
  headTerm <- case map toLower word of
    "everything" -> Just detAll
    "someone" -> Just (Lam "P" tyPred1 (Lam "Q" tyPred1
      (TExists "x" TyE (TAnd (App (pred1 sortalPerson) x_)
        (TAnd (App p_ x_) (App q_ x_))))))
    _ -> Nothing
  let relative = Lam "V" (tyGQ ~> TyT) (Lam "x" TyE
        (App (Var "V") (liftE x_)))
  pure (LexTerm headTerm "restricted quantified-pronoun head" Nothing,
        LexTerm relative "subject relative as restriction property" Nothing)

-- | The closed-class table: @(word, category, entry)@. Lower-case keys. The
-- pronoun entries take the token position, hence the function.
closedTable :: Int -> [(String, CCat, LexItem)]
closedTable i =
  [ (w, cat "NP[nb]/N", LexTerm detThe "definite determiner" Nothing) | w <- ["the"] ]
  ++ [ (w, cat "NP[nb]/N", LexTerm detAll "universal determiner" Nothing) | w <- ["all", "every", "each"] ]
  ++ [ (w, cat "NP[nb]/N", LexTerm detSome "indefinite determiner" Nothing) | w <- ["a", "an", "some"] ]
  ++ [ ("no", cat "NP[nb]/N", LexTerm detNo "negative determiner" Nothing) ]
  ++ [ (w, cat "(S[dcl]\\NP)/(S[adj]\\NP)", LexTerm vpIdentity "copula (predicative adjective)" Nothing)
     | w <- ["is", "are"] ]
  ++ [ (w, cat "(S[dcl]\\NP)/(S[b]\\NP)", LexTerm vpIdentity "do-support auxiliary" Nothing)
     | w <- ["does", "do"] ]
  ++ [ ("not", c, LexTerm vpNot "VP negation" (Just negScope))
     | c <- map cat ["(S\\NP)\\(S\\NP)", "(S\\NP)/(S\\NP)", "(S[adj]\\NP)/(S[adj]\\NP)"] ]
  ++ [ ("if", cat "(S/S)/S[dcl]", LexTerm ifTerm "conditional" Nothing)
     , ("then", cat "S/S", LexTerm sIdentity "conditional consequent marker" Nothing)
     , ("everything", cat "NP", LexTerm
          (Lam "Q" tyPred1 (TForall "x" TyE (App q_ x_)))
          "unrestricted universal pronoun" Nothing)
     , ("something", cat "NP", LexTerm (indefinite sortalThing) "indefinite pronoun (thing)" Nothing)
     , ("someone", cat "NP", LexTerm (indefinite sortalPerson) "indefinite pronoun (person)" Nothing)
     , ("things", cat "N", LexTerm (sortalNoun sortalThing) "sortal noun (thing)" Nothing)
     , ("people", cat "N", LexTerm (sortalNoun sortalPerson) "sortal noun (person)" Nothing)
     , ("and", cat "conj", LexStructural "coordinator (and)")
     , ("or", cat "conj", LexStructural "coordinator (or)")
     ]
  ++ [ (w, cat ("(S[" ++ f ++ "]\\NP)\\((S[" ++ f ++ "]\\NP)/NP)"),
          LexTerm localReflexive "local object reflexive" (Just
            (Stipulation "reflexive-local-binding" "local subject fills both verb arguments" []
              "only lexical finite/base transitive direct-object binding is licensed")))
     | w <- ["himself", "herself", "itself"], f <- ["dcl", "b"] ]
  ++ [ (w, cat "NP", LexTerm (pronoun w i) "pronoun" Nothing) | w <- ["it", "they"] ]
  ++ [ ("did", cat "(S[dcl]\\NP)/(S[b]\\NP)", LexTerm vpIdentity "do-support auxiliary (past)" Nothing) ]
  ++ [ (w, cat "(N\\N)/(S[dcl]\\NP)", LexTerm subjectRelative "restrictive subject relative" Nothing)
     | w <- ["that", "which", "who"] ]

--------------------------------------------------------------------------------
-- Intensional entries
--------------------------------------------------------------------------------

-- | Closed-class entries that /declare an intensional parameter/ (see
-- "NL2Proof.Semantics.Intensional"): their type lifts @τ@ to @s -> τ@ at that
-- argument, so it is 'liftsTo' of the category's type rather than equal to it.
-- Kept out of 'closedTable', whose entries inhabit their category type exactly.
--
-- * @that@, @S[em]\/S[dcl]@: @\\p:s->t. p@, declared @(s -> t) -> s -> t@.
intensionalTable :: [(String, CCat, LexItem)]
intensionalTable =
  [ ("that", cat "S[em]/S[dcl]", LexTerm complementizer "complementiser (declared s->t parameter)" Nothing) ]

-- | Reporting and attitude verbs, by category shape and lemma.
--
-- Two explicitly separate lists, "NL2Proof.Semantics.Intensional".'nonFactiveVerbs'
-- and 'factiveVerbs', decide the class of a listed word. A word in neither
-- is read as reporting (non-factive) anyway, __the fail-safe__, when the
-- evidence for a clausal complement is good enough:
--
-- * an explicit @that@-clause (@S[em]@ argument): always. @that@ is a strong
--   signal, and @"noted that P"@ fails toward not-asserting.
-- * a fronted or inverted quote (@"P," Bob laments@, @"P," laments Bob@):
--   always. Without the reported reading the quoted clause is still a
--   sentence, and a comma coordination asserting it can win instead (measured:
--   @"The cat is red, laments Bob."@ then asserts @red(cat)@).
-- * a bare complement (@S[dcl]@ argument, with or without an addressee): only
--   for a lemma /attested with a that-clause/ ('attitudeEntryWith''s
--   predicate; the parser derives it from CCGbank, see
--   "NL2Proof.Syntax.CCGSemParse".'NL2Proof.Syntax.CCGSemParse.smThatAttested').
--   The WSJ tagger offers @(S[dcl]\\NP)\/S[dcl]@ to verbs that never report
--   anything; without a that-clause in the corpus the category is not
--   evidence of a reporting verb, and the entry gives no reading. That loses
--   the reading and nothing else: no template gives the category an
--   extensional meaning, so the complement is not asserted either way.
--
-- The fail-safe choice is a logged 'NL2Proof.Trace.Decision'. Shapes (any
-- @S@ feature on the result):
--
-- * @(S\\NP)\/S[em]@: @\\p:s->t. \\S. S(\\x. v(x, p))@
-- * @(S\\NP)\/S[dcl]@ (bare complement): the same term; the @S[dcl]@ argument
--   is a declared intensional parameter. Logged.
-- * @((S\\NP)\/S[em])\/NP@ and @((S\\NP)\/S[dcl])\/NP@ (@told Alice that P@):
--   three-place, @tell(x, y, p)@.
-- * @(S[dcl]\\S[dcl])\\NP@ and @(S[dcl]\\S[dcl])\/NP@: the fronted or quoted
--   clause (CCGbank strips quotation marks: @"The cat is red," Bob said@ and
--   @..., said Bob@), and @((S[dcl]\\S[dcl])\\NP)\/NP@ with an addressee.
--   Logged.
--
-- Factivity is a property of the lemma: a factive entry logs it, and the DRT
-- stage projects the complement as a presupposition.
--
-- 'attitudeEntry' is the version without corpus evidence: every unlisted
-- lemma counts as attested, so it reads at least as much as reported as the
-- parser does.
attitudeEntry :: String -> CCat -> Maybe LexItem
attitudeEntry = attitudeEntryWith (const True)

-- | 'attitudeEntry' given which unlisted lemmas ('reportingLemma') are
-- attested with a that-clause.
attitudeEntryWith :: (String -> Bool) -> String -> CCat -> Maybe LexItem
attitudeEntryWith attested w c = do
  (shape, term) <- attitudeShape c
  let (lemma, cls, listed) = case attitudeOf w of
        Just (l, a) -> (l, a, True)
        Nothing     -> (reportingLemma w, NonFactive, False)
      st
        | lemma == "see"      = Just seeSense
        | not listed          = Just (failSafe shape)
        | shape == "bare"     = Just bareComplement
        | shape == "fronted"  = Just frontedReport
        | cls == Factive      = Just factivity
        | otherwise           = Nothing
      gloss = (if cls == Factive then "factive" else "non-factive") ++ " attitude verb ("
        ++ shape ++ (if listed then ")" else ", unlisted: fail-safe)")
  if listed || shape /= "bare" || attested lemma
    then Just (LexTerm (term lemma) gloss st)
    else Nothing

-- | Shared normalization for attestation construction and lexical lookup.
reportingLemma :: String -> String
reportingLemma = verbLemma . map toLower

-- | Perception see-that is factive, but supervisory see-that means ensure.
-- The category alone does not distinguish these senses. Keep attribution
-- until a construction supplies the missing distinction (see research log).
seeSense :: Stipulation
seeSense = Stipulation
  { stKind = "see-sense"
  , stChoice = "non-factive attribution while the sense of see is unresolved"
  , stAlternatives = ["perception: complement presupposed", "supervision/ensure: non-factive complement"]
  , stWhy = "perceptual see-that is factive, but the same clausal category admits"
      ++ " supervisory ensure readings; lexical categories alone cannot choose the sense"
  }

-- | An explicit that-clause category: @(S\\NP)\/S[em]@ or
-- @((S\\NP)\/S[em])\/NP@, any @S@ feature on the result. What a lemma must
-- have been seen with in CCGbank to count as attested.
thatClauseCat :: CCat -> Bool
thatClauseCat c = fmap fst (attitudeShape c) `elem` [Just "that-clause", Just "addressee"]

-- | The clausal-complement shapes, with the attitude term each takes.
attitudeShape :: CCat -> Maybe (String, String -> Term)
attitudeShape cat' = case cat' of
  CSlash Fwd (CSlash Bwd r n _) (CAtom "S" fs) _
    | isS r, isNP n, fs == em  -> Just ("that-clause", attitudeVerb)
    | isS r, isNP n, fs == dcl -> Just ("bare", attitudeVerb)
  CSlash Fwd (CSlash Fwd (CSlash Bwd r n _) (CAtom "S" fs) _) o _
    | isS r, isNP n, isNP o, fs == em  -> Just ("addressee", addresseeVerb)
    | isS r, isNP n, isNP o, fs == dcl -> Just ("bare", addresseeVerb)
  CSlash _ (CSlash Bwd r a _) n _
    | r == s dcl, a == s dcl, isNP n -> Just ("fronted", frontedVerb)
  CSlash Fwd (CSlash Bwd (CSlash Bwd r a _) n _) o _
    | r == s dcl, a == s dcl, isNP n, isNP o -> Just ("fronted", frontedAddresseeVerb)
  _ -> Nothing
  where
    s fs = CAtom "S" fs
    isNP (CAtom "NP" _) = True
    isNP _              = False
    isS (CAtom "S" _) = True
    isS _             = False
    em = [Feat "em"]
    dcl = [Feat "dcl"]

-- | Factivity, as a stated lexical property.
factivity :: Stipulation
factivity = Stipulation
  { stKind = "factive"
  , stChoice = "complement presupposed at the actual world"
  , stAlternatives = ["complement only attributed (non-factive)"]
  , stWhy = "know/realize/regret are lexically factive: the complement is presupposed"
      ++ " true, not asserted by the verb; the DRT stage projects it and logs where"
  }

-- | Reading a bare complement as an attitude complement.
bareComplement :: Stipulation
bareComplement = Stipulation
  { stKind = "bare-complement"
  , stChoice = "bare complement read as attitude (a proposition, not asserted)"
  , stAlternatives = ["asserted complement (read extensionally)"]
  , stWhy = "CCGbank's S[dcl] argument does not mark the clause as embedded, but under an"
      ++ " attitude verb a clause without 'that' is reported exactly like one with it"
  }

-- | Reading a fronted (quoted) clause as reported.
frontedReport :: Stipulation
frontedReport = Stipulation
  { stKind = "fronted-report"
  , stChoice = "fronted or quoted clause read as reported (a proposition, not asserted)"
  , stAlternatives = ["asserted clause"]
  , stWhy = "CCGbank strips quotation marks, so a quote surfaces as an S[dcl] the reporting"
      ++ " verb takes on its left; it is the reported content, not an assertion"
  }

-- | The fail-safe for a clausal-complement verb in neither list.
failSafe :: String -> Stipulation
failSafe shape = Stipulation
  { stKind = "unlisted-reporting-verb"
  , stChoice = "reported (non-factive): complement attributed, not asserted (" ++ shape ++ ")"
  , stAlternatives = ["asserted complement", "factive (complement presupposed)"]
  , stWhy = "the verb is in neither the factive nor the non-factive list; an unknown"
      ++ " reporting verb fails toward not-asserting"
  }

-- | Words whose meanings come only from the closed-class table. Such a word
-- never falls through to an open-class template, so @"is"@ cannot be read as a
-- transitive verb predicate @is(x, y)@ just because CCGbank offers that category.
closedClassWords :: [String]
closedClassWords =
  [ "the", "all", "every", "each", "a", "an", "some", "no", "is", "are", "does", "do", "not", "if"
  , "himself", "herself", "itself", "themselves", "myself", "yourself"
  , "yourselves", "ourselves", "oneself", "then", "everything", "something", "someone", "things", "people", "and", "or", "it"
  , "they", "did", "that", "which", "who" ]

isClosedClass :: String -> Bool
isClosedClass w = map toLower w `elem` closedClassWords

-- | Meanings for a closed-class word (or punctuation) under a category the
-- tagger offered. A punctuation category is structural only for a nonempty
-- punctuation-only surface. Tagger alternatives must never erase words,
-- numbers, whitespace or symbols by labeling them punctuation.
-- Matching is by exact category: an entry stated for @NP[nb]/N@ is not used for
-- @NP/N@, because the tag dictionary is what decides which categories a word
-- may take and this table should not quietly widen it.
closedEntries :: Int -> String -> CCat -> [LexItem]
closedEntries i w c
  | isPunct c, not (null w), all isPunctuation w =
      [LexStructural ("punctuation " ++ show w)]
  | otherwise = [ e | (w', c', e) <- closedTable i ++ intensionalTable, w' == map toLower w, c' == c ]

--------------------------------------------------------------------------------
-- Open class
--------------------------------------------------------------------------------

-- | Category-shape templates for open-class words. Predicate names are the
-- lower-cased word, except that verbs (an @S@ result other than @S[adj]@) use
-- conservative 'verbLemma', so known inflections share one predicate.
--
-- * @N@: @\\x. w(x)@
-- * @N\/N@: @\\P \\x. w(x) & P(x)@ (intersective; preserves descriptive-name order)
-- * @S[f]\\NP@: @\\S. S(\\x. w(x))@ (predicative adjective or intransitive verb)
-- * @(S[f]\\NP)\/NP@: @\\O \\S. S(\\x. O(\\y. w(x, y)))@ (transitive, subject wide scope)
--
-- Clausal-complement shapes go to 'attitudeEntryWith' first (reporting verbs,
-- with the fail-safe for unlisted ones). 'openTemplate' assumes every
-- unlisted lemma attested; the parser passes the CCGbank-derived set.
--
-- Any other shape: 'Nothing'. That is deliberate (see the module header).
openTemplate :: String -> CCat -> Maybe LexItem
openTemplate = openTemplateWith (const True)

-- | 'openTemplate' given which unlisted lemmas are attested with a
-- that-clause (passed to 'attitudeEntryWith').
openTemplateWith :: (String -> Bool) -> String -> CCat -> Maybe LexItem
openTemplateWith attested w c | Just it <- attitudeEntryWith attested w c = Just it
openTemplateWith _ w c = case c of
  CAtom "N" _ ->
    Just (LexTerm (Lam "x" TyE (App (pred1 lw) x_)) "noun (template)" Nothing)
  CSlash Fwd (CAtom "N" _) (CAtom "N" _) _ ->
    Just (LexTerm (Lam "P" tyPred1 (Lam "x" TyE (TAnd (App (pred1 lw) x_) (App p_ x_))))
                  "intersective modifier (template)" Nothing)
  CSlash Bwd s@(CAtom "S" _) (CAtom "NP" _) _ ->
    Just (LexTerm (Lam "S" tyGQ (App (Var "S") (Lam "x" TyE (App (pred1 (predName s)) x_))))
                  "one-place predicate (template)" Nothing)
  CSlash Fwd (CSlash Bwd s@(CAtom "S" _) (CAtom "NP" _) _) (CAtom "NP" _) _ ->
    Just (LexTerm (Lam "O" tyGQ (Lam "S" tyGQ
                    (App (Var "S") (Lam "x" TyE
                      (App (Var "O") (Lam "y" TyE (apply (pred2 (predName s)) [x_, Var "y"])))))))
                  "transitive verb (template)" Nothing)
  _ -> Nothing
  where
    lw = map toLower w
    -- Adjectives keep their form; every verbal category is lemmatised, so a
    -- verb the tagger also offers as S[b] or S[ng] does not yield a second
    -- predicate (likes vs like) that differs only by inflection.
    predName (CAtom _ fs)
      | Feat "adj" `elem` fs = lw
    predName _ = verbLemma lw

-- | A proper name: @NP@, @\\P. P(n)@, the name keeping its written case.
--
-- CCGbank tags a lone name @N@ and type-changes it to @NP@; the same @N -> NP@
-- step for a common noun is a bare plural with quantificational force
-- ('unarySem'). Which one applies is a fact about the word (its POS), not the
-- category, so the parser folds the name reading in at the lexicon.
nameItem :: String -> LexItem
nameItem n = LexTerm (Lam "P" tyPred1 (App p_ (entity n))) "proper name" Nothing

-- | Third-person-singular present to base form: @likes -> like@,
-- @chases -> chase@, @watches -> watch@, @kisses -> kiss@. Words not ending in
-- a plain @-s@ are returned unchanged. A deterministic suffix rule, so it is
-- wrong on irregulars (@goes -> goe@); it is applied identically to the gold
-- relations when comparing, so it can merge but never invent a predicate.
lemma3sg :: String -> String
lemma3sg w
  | length w <= 2 = w
  | any (`isSuffixOf` w) ["sses", "ches", "shes", "xes", "zes"] = take (length w - 2) w
  | "ss" `isSuffixOf` w = w
  | "s" `isSuffixOf` w = init w
  | otherwise = w

-- | Conservative verb normalization. Known inflections share one lexical
-- key, including when building the that-clause attestation set. Unknown past
-- and participial forms are preserved: spelling alone cannot distinguish
-- hoped/hopped or lexical dd in added from inflectional doubling. This small
-- hand-authored inventory is not a corpus-derived lexical dump.
verbLemma :: String -> String
verbLemma w
  | Just (lemma, _) <- attitudeOf w = lemma
  | Just lemma <- lookup w inflections = lemma
  | otherwise = lemma3sg w
  where
    inflections =
      [(form, base) | (base, forms) <-
        [ ("add", ["added", "adding"]), ("note", ["noted", "noting"])
        , ("announce", ["announced", "announcing"]), ("boast", ["boasted", "boasting"])
        , ("lament", ["lamented", "lamenting"]), ("like", ["liked", "liking"])
        , ("hate", ["hated", "hating"]), ("chase", ["chased", "chasing"])
        , ("watch", ["watched", "watching"]), ("walk", ["walked", "walking"])
        , ("smile", ["smiled", "smiling"]), ("see", ["saw", "seen", "seeing"])
        , ("go", ["goes", "went", "gone"]), ("do", ["does", "did", "done"])
        , ("have", ["has"])
        ] , form <- forms]

--------------------------------------------------------------------------------
-- Combinators
--------------------------------------------------------------------------------

-- | Composition, for every composition combinator: @\\z. f(g(z))@ where @z@ has
-- the semantic type of the composed-over argument. @f@ and @g@ are closed (all
-- lexical meanings are), so the bound name cannot capture.
composeTerm :: Ty -> Term -> Term -> Term
composeTerm zTy f g = Lam "z" zTy (App f (App g (Var "z")))

-- | The connective a coordinator contributes. A comma acting as a coordinator
-- (CCGbank's analysis of @"cold, green things"@) lists conjuncts and is read as
-- @and@ — a stated reading of list commas, not a lexical fact about commas.
coordinatorOp :: String -> Maybe (Term -> Term -> Term)
coordinatorOp w = case map toLower w of
  "and" -> Just TAnd
  ","   -> Just TAnd
  "or"  -> Just TOr
  _     -> Nothing

-- | Generalised coordination of two meanings of type @ty@ (which ends in @t@).
--
-- Arguments of non-quantifier type are passed pointwise (@\\P. A(P) & B(P)@).
-- An argument of quantifier type (an @NP@ slot) is instead /scoped over/ the
-- coordination: @\\S. S(\\x. A(\\P. P(x)) & B(\\P. P(x)))@. This is the
-- Partee–Rooth point: conjoining two VPs at the quantifier level would make
-- @"something is cold and not round"@ mean /something is cold and something is
-- not round/, two existentials where the sentence has one. Lowering the
-- subject to an entity variable keeps one.
coordTerm :: (Term -> Term -> Term) -> Ty -> Term -> Term -> Maybe Term
coordTerm op ty0 a b = go ty0 (0 :: Int) []
  where
    go TyT _ args = Just (wrap args (op (applyAll a args) (applyAll b args)))
    go (TyFun d r) n args = go r (n + 1) (args ++ [(n, d)])
    go TyE _ _ = Nothing
    go TyS _ _ = Nothing

    argVar n = "c" ++ show n
    entVar n = "e" ++ show n

    applyAll f args =
      apply f [ if d == tyGQ then liftE (Var (entVar n)) else Var (argVar n)
              | (n, d) <- args ]

    wrap args body =
      let scoped = foldr (\(n, d) acc ->
                            if d == tyGQ
                              then App (Var (argVar n)) (Lam (entVar n) TyE acc)
                              else acc)
                         body args
      in foldr (\(n, d) acc -> Lam (argVar n) d acc) scoped args

-- | Meaning of a unary type-change @from -> to@, when its shape fixes one.
--
-- * Type-raising @X -> T\/(T\\X)@ or @X -> T\\(T\/X)@: @\\f. f(a)@.
-- * @N -> NP@ (a bare noun phrase): __generic, universal__ —
--   @\\Q. forall x. P(x) -> Q(x)@ — with a 'Stipulation', because a bare plural
--   can also be existential (/dogs are barking/) and nothing in the category
--   says which.
--
-- Everything else: 'Nothing', and the type-change is not used.
unarySem :: CCat -> CCat -> Maybe (Term -> Term, Maybe Stipulation)
unarySem from to = case (from, to) of
  (CAtom "N" _, CAtom "NP" _) -> Just (generic, Just bareGeneric)
  (_, CSlash d1 t (CSlash d2 t' a _) _)
    | d1 /= d2, unifiable t t', unifiable a from, Just fty <- semTy (CSlash d2 t' a []) ->
        Just (\v -> Lam "f" fty (App (Var "f") v), Nothing)
  _ -> Nothing
  where
    generic p = Lam "Q" tyPred1 (TForall "x" TyE (TImp (App p x_) (App q_ x_)))
    bareGeneric = Stipulation
      { stKind = "bare-np"
      , stChoice = "generic (forall)"
      , stAlternatives = ["existential (exists)"]
      , stWhy = "the N -> NP type-change carries no determiner; bare noun phrases are"
          ++ " read generically"
      }
