-- | ProofWriter (Tafjord et al., AllenAI, CC BY 4.0): its gold structured
-- representation, and the conversion of a sentence DRS into that form.
--
-- Each theory sentence in the @meta-*.jsonl@ files comes with a Lisp-style
-- representation — a fact @("cow" "is" "big" "+")@, or a rule
-- @((("something" "is" "big" "+")) -> ("something" "is" "red" "+"))@. That is the
-- gold standard for /semantic/ correctness: a sentence counts as correct only if
-- the DRS the pipeline built converts to exactly this.
--
-- The conversion is mechanical and its conventions are stated here, once:
--
-- * A one-place condition @p(a)@ is the attribute triple @(a "is" p)@; a
--   two-place condition @r(a, b)@ is @(a r b)@. Relations are compared after
--   'lemma3sg' on both sides (gold writes @likes@ even after @does not@).
-- * A constant is its own name: a proper name keeps its case (@"Anne"@), a
--   definite description is named by its content (@"bald eagle"@, see
--   'NL2Proof.DRT.Build.describeIota').
-- * A discourse referent bound in a conditional's antecedent is a rule
--   variable, named @"something"@ or @"someone"@ by the sortal predicate
--   ('sortalThing', 'sortalPerson') that restricts it; the sortal condition
--   itself is dropped, as ProofWriter's rules carry no sort.
-- * A negated box @NOT [p(a)]@ is the atom with negative polarity. Gold writes
--   @"-"@ for a negated fact and @"~"@ (negation as failure, under CWA) for a
--   negated rule condition; both are compared as negative polarity.
-- * A whole sentence is a fact when its box holds exactly one atom and no
--   referents, and a rule when it holds exactly one conditional whose
--   consequent is exactly one atom. Anything else does not convert, and the
--   reason is returned rather than a best guess.
module NL2Proof.Bench.ProofWriter
  ( -- * Statements
    Pol(..)
  , Atom(..)
  , Statement(..)
  , normalizeStatement
  , renderStatement
  , statementNegated
  , statementPremises
    -- * Gold
  , parseRepr
  , Theory(..)
  , parseTheory
    -- * Conversion
  , drsToStatement
  ) where

import Data.Char (isSpace)
import Data.List (nub, sort)

import NL2Proof.Bench.JSON
import NL2Proof.DRT.Types
import NL2Proof.Semantics.CCGSem (isSortal, lemma3sg, sortalPerson, sortalThing)
import NL2Proof.Semantics.Lambda (isAnaphorName)

--------------------------------------------------------------------------------
-- Statements
--------------------------------------------------------------------------------

data Pol = Pos | Neg
  deriving (Eq, Ord, Show)

data Atom = Atom
  { atSubj :: String
  , atRel  :: String
  , atObj  :: String
  , atPol  :: Pol
  }
  deriving (Eq, Ord, Show)

data Statement
  = Fact Atom
  | Rule [Atom] Atom
  deriving (Eq, Ord, Show)

-- | Lemmatise relations and treat a rule body as a set (conjunction is
-- commutative and idempotent). Applied to both gold and prediction before
-- comparison.
normalizeStatement :: Statement -> Statement
normalizeStatement (Fact a)    = Fact (normAtom a)
normalizeStatement (Rule bs h) = Rule (sort (nub (map normAtom bs))) (normAtom h)

normAtom :: Atom -> Atom
normAtom a = a { atRel = if atRel a == "is" then "is" else lemma3sg (atRel a) }

renderAtom :: Atom -> String
renderAtom (Atom s r o p) =
  "(" ++ unwords (map show [s, r, o]) ++ " " ++ (if p == Pos then "+" else "-") ++ ")"

renderStatement :: Statement -> String
renderStatement (Fact a)    = renderAtom a
renderStatement (Rule bs h) = "(" ++ unwords (map renderAtom bs) ++ ") -> " ++ renderAtom h

statementNegated :: Statement -> Bool
statementNegated (Fact a)    = atPol a == Neg
statementNegated (Rule bs h) = any ((== Neg) . atPol) (h : bs)

-- | Number of rule premises (0 for a fact).
statementPremises :: Statement -> Int
statementPremises (Fact _)   = 0
statementPremises (Rule bs _) = length bs

--------------------------------------------------------------------------------
-- Gold representation
--------------------------------------------------------------------------------

data SExp = SList [SExp] | SStr String | SArrow
  deriving (Eq, Show)

sexp :: String -> Either String SExp
sexp s0 = case go (dropWhile isSpace s0) of
  Right (e, rest) | all isSpace rest -> Right e
  Right (_, rest) -> Left ("trailing: " ++ take 20 rest)
  Left e -> Left e
  where
    go ('(' : r) = list [] (dropWhile isSpace r)
    go ('"' : r) = let (w, r') = break (== '"') r
                   in case r' of
                        '"' : r'' -> Right (SStr w, dropWhile isSpace r'')
                        _         -> Left "unterminated string"
    go ('-' : '>' : r) = Right (SArrow, dropWhile isSpace r)
    go r = Left ("unexpected: " ++ take 20 r)
    list acc (')' : r) = Right (SList (reverse acc), dropWhile isSpace r)
    list acc r = do
      (e, r') <- go r
      list (e : acc) r'

-- | Parse a ProofWriter representation string.
parseRepr :: String -> Either String Statement
parseRepr s = sexp s >>= toStmt
  where
    toStmt e@(SList (SStr _ : _)) = Fact <$> atom e
    toStmt (SList [SList bs, SArrow, h]) = Rule <$> mapM atom bs <*> atom h
    toStmt e = Left ("not a fact or rule: " ++ show e)
    atom (SList [SStr a, SStr r, SStr b, SStr p]) = Atom a r b <$> pol p
    atom e = Left ("not an atom: " ++ show e)
    pol "+" = Right Pos
    pol "-" = Right Neg
    pol "~" = Right Neg
    pol p   = Left ("polarity: " ++ p)

-- | One theory: its facts, rules and questions, each as @(text, gold)@.
data Theory = Theory
  { thId        :: String
  , thFacts     :: [(String, Statement)]
  , thRules     :: [(String, Statement)]
  , thQuestions :: [(String, Statement)]
  }

-- | Parse one line of a @meta-*.jsonl@ file.
parseTheory :: String -> Either String Theory
parseTheory line = do
  j <- parseJSON line
  tid <- maybe (Left "no id") Right (field "id" j >>= str)
  facts <- section "triples" "text" j
  rules <- section "rules" "text" j
  qs <- section "questions" "question" j
  Right (Theory tid facts rules qs)
  where
    section name textKey j = case field name j >>= obj of
      Nothing -> Right []
      Just kvs ->
        mapM (\(k, v) -> do
                t <- maybe (Left (k ++ ": no " ++ textKey)) Right (field textKey v >>= str)
                r <- maybe (Left (k ++ ": no representation")) Right
                       (field "representation" v >>= str)
                st <- either (\e -> Left (k ++ ": " ++ e)) Right (parseRepr r)
                Right (t, st))
             kvs

--------------------------------------------------------------------------------
-- Conversion
--------------------------------------------------------------------------------

-- | Convert a sentence DRS to a ProofWriter statement, or say why it cannot be.
drsToStatement :: DRS -> Either String Statement
drsToStatement (DRS us cs)
  | not (null us) =
      Left "referent in the top-level box (an indefinite outside any conditional) has no ProofWriter name"
  | [CImp a b _] <- cs = do
      env <- names a
      body <- atoms env a
      hd <- atoms env b
      case hd of
        [h] | not (null body) -> Right (Rule body h)
        [_] -> Left "conditional with an empty antecedent"
        _   -> Left ("conditional consequent has " ++ show (length hd) ++ " atoms, not 1")
  | any isImp cs = Left "conditional together with other top-level conditions"
  | otherwise = do
      as <- atoms [] (DRS [] cs)
      case as of
        [a] -> Right (Fact a)
        _   -> Left ("fact box has " ++ show (length as) ++ " atoms, not 1")
  where
    isImp CImp{} = True
    isImp _      = False

    -- Rule variables are the antecedent box's referents, named by their sort.
    names (DRS rs conds) = mapM nameOf (map fst rs)
      where
        nameOf r = case [ p | CPred p [DRef r'] _ <- conds, r' == r, isSortal p ] of
          (p : _) | p == sortalThing  -> Right (r, "something")
                  | p == sortalPerson -> Right (r, "someone")
          _ -> Left ("rule variable " ++ show r ++ " has no sortal (thing/person)")

    atoms env (DRS rs conds)
      | not (null rs) && null env = Left "referent introduced outside a conditional antecedent"
      | otherwise = concat <$> mapM (atomsOf env) conds

    atomsOf env c = case c of
      CPred p [DRef _] _ | isSortal p -> Right []
      CPred p [a] _ -> do { a' <- term env a; Right [Atom a' "is" p Pos] }
      CPred p [a, b] _ -> do
        a' <- term env a
        b' <- term env b
        Right [Atom a' p b' Pos]
      CNot (DRS [] [inner]) _ -> do
        xs <- atomsOf env inner
        case xs of
          [x] -> Right [x { atPol = Neg }]
          _   -> Left "negation over other than one atom"
      CNot _ _ -> Left "negation over a box with referents or several conditions"
      CPred p as _ -> Left ("predicate " ++ p ++ " with " ++ show (length as) ++ " arguments")
      CEq{} -> Left "equality condition"
      CImp{} -> Left "nested conditional"
      COr{} -> Left "disjunction"
      CAtt{} -> Left "attitude report"
      CPresup{} -> Left "unprojected presupposition"

    term env t = case t of
      DRef r -> maybe (Left ("unbound referent " ++ show r)) Right (lookup r env)
      DConst c
        | isAnaphorName c -> Left ("unresolved anaphor " ++ c)
        | otherwise -> Right c
