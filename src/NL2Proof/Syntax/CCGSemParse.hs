-- | The CCGbank-trained parser, carrying meanings.
--
-- "NL2Proof.Syntax.CCGParse" decides /whether/ a category sequence derives a
-- root; its cells are sets of categories and it keeps no derivations. This
-- module runs the same grammar — the same 'NL2Proof.Syntax.CCGRules' combinators
-- with the same feature unification, the same learned unary type-change
-- inventory, the same frequency supertagger and log-probability scores — but
-- each chart item is a /sign/: category, lambda term, provenance tree, score.
-- Meanings come only from "NL2Proof.Semantics.CCGSem".
--
-- What is packed and what is not, stated because it is the ambiguity
-- discipline:
--
-- * Two items with the same category, pending conditional obligations,
--   occurrence-bound relative certificates, pending coordinator and
--   equivalent meaning — equal up to alpha-renaming and associativity,
--   commutativity and idempotence of @&@ ('simplifyConj', 'canonicalAC'), all
--   sound — are one item — spurious ambiguity, which changes nothing above it. The
--   higher-scoring provenance is kept.
-- * Items with different meanings are never merged. At the root, every distinct
--   meaning is returned, best score first, so the caller can raise
--   'NL2Proof.Trace.ParseAmbiguity' and log the selection.
-- * Each cell keeps the @smBeam@ best items by score. That is a search bound,
--   and it can drop a reading; it is a parameter, not hidden.
module NL2Proof.Syntax.CCGSemParse
  ( -- * Model
    SemModel(..)
  , defaultSemModel
  , loadSemModel
  , ccgbankDataDir
  , ccgbankTrainFiles
    -- * Lexical assignment
  , NameStatus(..)
  , nameStatus
  , offeredTags
  , LexSign(..)
  , lexicalSigns
    -- * Chart
  , SSign(..)
  , FusedCertificate(..)
  , FusedRole(..)
  , fusedTransition
  , fusedUnaryAllowed
  , fusedRootAllowed
  , packCell
  , SemParse(..)
  , semParse
  , syntacticParse
  ) where

import Control.Exception (IOException, try)
import Control.Monad (foldM)
import Data.Char (isUpper, toLower)
import Data.List (foldl', isPrefixOf, isSuffixOf, sortBy)
-- Strict maps for counting; the chart table must be the lazy map (it is
-- defined by self-reference, as in "NL2Proof.Syntax.CCGParse").
import qualified Data.Map as ML
import qualified Data.Map.Strict as M
import qualified Data.Set as Set
import Data.Ord (comparing, Down(..))
import System.Environment (lookupEnv)
import Text.Printf (printf)

import NL2Proof.Provenance
import NL2Proof.Semantics.CCGSem
import NL2Proof.Semantics.Intensional (applyIntensional, isIntensionalTerm, liftsTo)
import NL2Proof.Semantics.Lambda
import NL2Proof.Syntax.CCGBank (CCat(..), Dir(..), Feat(..), eraseFeatures, parseCCGCat)
import NL2Proof.Syntax.CCGDeriv (AutoNode(..), leafHeaders, nodeCat, parseAuto)
import NL2Proof.Syntax.CCGParse (Rules(..), chartParseScored)
import NL2Proof.Syntax.CCGTypeChange (TypeChange(..), inducements, normalizeTC)
import NL2Proof.Syntax.CCGRules
  (Combinator(..), combineNamed, allCombinators, isCoordinator, isPunct, unifiable)
import NL2Proof.Syntax.CCGSupertag
import NL2Proof.Syntax.Tokenize (Token(..))
import NL2Proof.Trace

--------------------------------------------------------------------------------
-- Model
--------------------------------------------------------------------------------

-- | Everything the parser learned from CCGbank, plus its search parameters.
data SemModel = SemModel
  { smTags         :: TagModel
  , smPOS          :: POSModel
  , smRules        :: Rules
  , smBeta         :: Double  -- ^ supertagger β-beam (relative to the top tag)
  , smKmax         :: Int     -- ^ max tags per word
  , smBeam         :: Int     -- ^ max items per chart cell
  , smUnaryPenalty :: Double  -- ^ score cost of one unary type-change
  , smAlpha        :: Double
    -- ^ Dirichlet smoothing of a word's tag counts toward the category prior:
    -- @P(c|w) = (n(w,c) + alpha * P(c)) / (n(w) + alpha)@. 0 is the raw tag
    -- dictionary of @ccg-supertag-parse@.
  , smTruecase     :: Bool
    -- ^ Read a sentence-initial word through its lower-cased form when that
    -- form is attested (see 'lookupForm').
  , smTypeRaise    :: Bool
    -- ^ Enable learned type raising globally. Off by default; the bounded
    -- argument-cluster coordination trigger still enables it locally.
  , smSeen         :: Set.Set (CCat, CCat)
    -- ^ Feature-erased @(left, right)@ category pairs of every binary node in
    -- the training trees.
  , smSeenRules    :: Bool
    -- ^ Allow a binary combination only if its feature-erased category pair is
    -- in 'smSeen' — the "seen rules" constraint of the C&C parser (Clark &
    -- Curran 2007), learned from the same sections as everything else. Without
    -- it, generalised (crossed) composition derives readings CCGbank never
    -- uses, e.g. backward-crossing a determiner-modifier @NP\/N@ into a VP to
    -- pick up a head noun at the end of the sentence.
  , smPriorMap     :: M.Map CCat Int
    -- ^ Derived from 'smTags' once: the category prior as a map.
  , smPriorTotal   :: Double
    -- ^ Derived from 'smTags' once: total category count.
  , smThatAttested :: Set.Set String
    -- ^ Derived from 'smTags' once: every 'reportingLemma' of a word form the
    -- tag dictionary has seen with an explicit that-clause category
    -- ('thatClauseCat': @(S\\NP)\/S[em]@ or @((S\\NP)\/S[em])\/NP@). An
    -- unlisted verb is read as reporting under a bare-complement category
    -- only if its lemma is here (see 'attitudeEntryWith'). Computed
    -- from the licensed corpus at load time, so no derived word list is
    -- committed. On sections 02-21 it includes @note@, @add@,
    -- @announce@ and @see@ (@see that ...@).
  , smPOSBackoff :: Bool
    -- ^ Optional dictionary-POS backoff for missing noun/adjective tags.
    -- This is not a contextual POS tagger: truly unseen words have no POS
    -- evidence, and verb POS alone supplies no argument structure.
  }

-- | The search parameters of @ccg-supertag-parse@'s defaults (β = 0.01, k = 20,
-- beam 40, unary penalty 1.0), plus smoothing α = 20, truecasing and the
-- seen-rules constraint, around a tagger, POS dictionary, type-change
-- inventory and seen category pairs.
--
-- α = 20 is the soft form of the C&C convention of trusting the tag dictionary
-- only for words seen at least 20 times (Clark & Curran 2007): a word seen once
-- (@rabbit@, once in sections 02–21, as @N\/N@) is mostly prior, a word seen
-- thousands of times (@is@) is all its own counts.
--
-- Global type-raising is off. Its meaning is fixed (@\\f. f(a)@) and it is
-- implemented, but in a chart that also has composition it mostly re-derives
-- what application already derives, while multiplying the categories per cell
-- (measured on ProofWriter train sentences: at most ~15 categories per cell
-- without it, ~100 with it, and 2-4x the parse time). It is needed for
-- extraction and argument-cluster coordination. The latter is now enabled
-- locally after a transitive-verb + coordinator + new-NP trigger; ordinary VP
-- and adjective lists keep the cheaper search.
defaultSemModel :: TagModel -> POSModel -> Rules -> Set.Set (CCat, CCat) -> SemModel
defaultSemModel tm pm rs seen =
  SemModel tm pm rs 0.01 20 40 1.0 20 True False seen True
    (M.fromList (tmPrior tm)) (fromIntegral (sum (map snd (tmPrior tm))))
    (Set.fromList [ reportingLemma w | (w, cs) <- M.toList (tmWord tm), any (thatClauseCat . fst) cs ])
    False

-- | @$CCGBANK_DIR@ if set, else @~/ccgbank/ccgbank_1_1/data@ (the licensed
-- corpus lives outside the repository and is never committed).
ccgbankDataDir :: IO FilePath
ccgbankDataDir = do
  d <- lookupEnv "CCGBANK_DIR"
  h <- lookupEnv "HOME"
  pure (maybe (maybe "." id h ++ "/ccgbank/ccgbank_1_1/data") id d)

-- | The standard training sections 02–21, as candidate file paths (not every
-- number exists; 'loadSemModel' skips missing files).
ccgbankTrainFiles :: FilePath -> [FilePath]
ccgbankTrainFiles dir =
  [ printf "%s/AUTO/%02d/wsj_%02d%02d.auto" dir sec sec n
  | sec <- [2 .. 21 :: Int], n <- [0 .. 99 :: Int] ]

-- | Train tagger, POS dictionary and type-change inventory on sections 02–21.
-- Returns the model and the number of trees read.
--
-- Builds exactly what 'buildTagModel', 'buildPOSModel' and 'rulesFrom' build
-- from the same trees, but as a strict fold over files, so the corpus text is
-- never held in memory all at once.
loadSemModel :: FilePath -> IO (SemModel, Int)
loadSemModel dir = do
  acc <- foldM addFile (LoadAcc M.empty M.empty Set.empty Set.empty 0) (ccgbankTrainFiles dir)
  let byCount = sortBy (comparing (Down . snd)) . M.toList
      tm = TagModel
        { tmWord = M.map byCount (laTags acc)
        , tmPrior = byCount (M.unionsWith (+) (M.elems (laTags acc)))
        }
      tcs = Set.toList (laTC acc)
      rs = Rules { rUnary = [ (a, b) | TCUnary a b <- tcs ]
                 , rBinTC = [ (a, b, c) | TCBinary a b c <- tcs ] }
  pure (defaultSemModel tm (POSModel (laPOS acc)) rs (laSeen acc), laTrees acc)
  where
    addFile acc f = do
      r <- try (readFile f) :: IO (Either IOException String)
      case r of
        Left _  -> pure acc
        Right s -> let acc' = foldl' addLine acc (lines s) in laTrees acc' `seq` pure acc'

    addLine acc l
      | null l || take 3 l == "ID=" = acc
      | otherwise = case parseAuto l of
          Left _ -> acc
          Right t ->
            LoadAcc
              { laTags = foldl' (\m (w, c) -> M.insertWith (M.unionWith (+)) w (M.singleton c 1) m)
                                (laTags acc) (leafPairs t)
              , laPOS = foldl' (\m (_, p, w) -> M.insertWith (M.unionWith (+)) w (M.singleton p 1) m)
                               (laPOS acc) (leafHeaders l)
              , laTC = foldl' (flip Set.insert) (laTC acc) (map (normalizeTC id) (inducements t))
              , laSeen = foldl' (flip Set.insert) (laSeen acc) (binaryPairs t)
              , laTrees = laTrees acc + 1
              }

data LoadAcc = LoadAcc
  { laTags  :: !(M.Map String (M.Map CCat Int))
  , laPOS   :: !(M.Map String (M.Map String Int))
  , laTC    :: !(Set.Set TypeChange)
  , laSeen  :: !(Set.Set (CCat, CCat))
  , laTrees :: !Int
  }

-- | Feature-erased child category pairs of every binary node.
binaryPairs :: AutoNode -> [(CCat, CCat)]
binaryPairs (AutoLeaf _ _) = []
binaryPairs (AutoTree _ kids) =
  here ++ concatMap binaryPairs kids
  where
    here = case kids of
      [a, b] | Right ca <- parseCCGCat (nodeCat a), Right cb <- parseCCGCat (nodeCat b) ->
        [(eraseFeatures ca, eraseFeatures cb)]
      _ -> []

-- | The stated reflexive construction licenses a new category pair even
-- when absent from the corpus. Semantic application additionally requires
-- lexical leaves and the closed reflexive marker; this shape alone is not
-- evidence of local binding.
localReflexiveVP :: CCat -> CCat -> Maybe CCat
localReflexiveVP left right = case left of
  CSlash Fwd vp@(CSlash Bwd (CAtom "S" [Feat feature]) (CAtom "NP" []) [])
              (CAtom "NP" []) []
    | feature `elem` ["dcl", "b"], right == CSlash Bwd vp left [] -> Just vp
  _ -> Nothing

-- | Is a binary combination of these two categories allowed ('smSeenRules')?
seenPair :: SemModel -> CCat -> CCat -> Bool
seenPair m l r = not (smSeenRules m)
  || (eraseFeatures l, eraseFeatures r) `Set.member` smSeen m
  || relativePair l r
  || localReflexiveVP l r /= Nothing
  where
    -- The restrictive relative is interpreted below the determiner even
    -- when CCGbank attaches it at NP. Its two local combinations are licensed
    -- by this stated construction instead of the corpus's NP attachment.
    relativePair (CAtom "N" _) (CSlash Bwd (CAtom "N" _) (CAtom "N" _) _) = True
    relativePair (CSlash Fwd (CSlash Bwd (CAtom "N" _) (CAtom "N" _) _) vp _) arg =
      unifiable vp arg
    relativePair _ _ = False

--------------------------------------------------------------------------------
-- Lexical assignment
--------------------------------------------------------------------------------

-- | Whether a token is read as a proper name.
data NameStatus
  = NotName
  | NameOnly
  | NameOrOther
    -- ^ An unseen capitalised sentence-initial word: capitals there are
    -- uninformative, so both readings are offered and the chart decides.
  deriving (Eq, Show)

-- | The form whose statistics a token is read through. A sentence-initial
-- capital is typography, not identity, so with 'smTruecase' a sentence-initial
-- word whose lower-cased form CCGbank attests is read as that form (@White@ at
-- the start of a sentence is @white@, not the surname that dominates WSJ's
-- @White@). Elsewhere, and when the lower-cased form is unattested (@Bob@),
-- the word is read as written.
lookupForm :: SemModel -> Bool -> String -> String
lookupForm m initial w
  | smTruecase m, initial, lw /= w, M.member lw (tmWord (smTags m)) = lw
  | otherwise = w
  where lw = map toLower w

-- | Proper-name status from CCGbank's POS dictionary: a seen word is a name iff
-- its majority POS is NNP\/NNPS. An unseen word is a name iff capitalised —
-- unless it is sentence-initial, where it may be either.
nameStatus :: SemModel -> Bool -> String -> NameStatus
nameStatus m initial w =
  case posCounts (smPOS m) (lookupForm m initial w) of
    ((p, _) : _) -> if p `elem` ["NNP", "NNPS"] then NameOnly else NotName
    [] | startsUpper, initial -> NameOrOther
       | startsUpper          -> NameOnly
       | otherwise            -> NotName
  where
    startsUpper = case w of { (c : _) -> isUpper c; [] -> False }

-- | The supertagger's scored categories for a token: its (smoothed) counts,
-- else the global prior for an unseen word, through the β-beam of
-- 'scoreCounts'.
offeredTags :: SemModel -> Bool -> String -> [(CCat, Double)]
offeredTags m initial w =
  case M.findWithDefault [] (lookupForm m initial w) (tmWord (smTags m)) of
    [] -> oov
    cs | smAlpha m <= 0 -> scoreCounts (smBeta m) (smKmax m) cs
       | otherwise -> scoreSmoothed cs
  where
    prior = tmPrior (smTags m)
    -- Exactly @scoreCounts beta kmax prior@ (the prior is sorted by count),
    -- without re-sorting and re-summing it per token.
    oov = case prior of
      [] -> []
      ((_, mx) : _) ->
        take (smKmax m) [ (c, log (fromIntegral n / smPriorTotal m))
                        | (c, n) <- prior, fromIntegral n >= smBeta m * fromIntegral mx ]
    -- Same β-beam and k cap as 'scoreCounts', over smoothed mass, with the
    -- exact smoothed log-probability. Candidates: the word's own categories
    -- plus the prior's most frequent (the only ones smoothing can lift over
    -- the beam).
    scoreSmoothed cs =
      let a = smAlpha m
          nW = fromIntegral (sum (map snd cs)) :: Double
          own = M.fromList [ (c, fromIntegral n) | (c, n) <- cs ] :: M.Map CCat Double
          mass c = M.findWithDefault 0 c own
                   + a * fromIntegral (M.findWithDefault 0 c (smPriorMap m)) / smPriorTotal m
          cats = M.keys (M.union (M.map (const ()) own)
                                 (M.fromList [ (c, ()) | (c, _) <- take (4 * smKmax m) prior ]))
          ranked = sortBy (comparing (Down . snd)) [ (c, mass c) | c <- cats ]
          mx = case ranked of { ((_, x) : _) -> x; [] -> 0 }
      in take (smKmax m) [ (c, log (x / (nW + a))) | (c, x) <- ranked, x >= smBeta m * mx ]

-- | One interpretable lexical candidate.
data LexSign = LexSign
  { lxCat   :: CCat
  , lxItem  :: LexItem
  , lxScore :: Double
  }

-- | Every interpretable reading of token @i@: offered categories filtered
-- through the semantic lexicon. Closed-class words use only their table
-- entries; licensed names lift offered @N@ or use an already offered ordinary
-- @NP@. The category alone never licenses a name. Everything else uses the
-- open-class templates.
lexicalSigns :: SemModel -> Int -> String -> [LexSign]
lexicalSigns m i w
  | lw `elem` ["himself", "herself", "itself"] =
      [ LexSign target (withNote (reflexiveNote original target) item) score
      | (original, score) <- tags, ordinaryReflexiveTag original
      , feature <- ["dcl", "b"]
      , let target = cat ("(S[" ++ feature ++ "]\\NP)\\((S[" ++ feature ++ "]\\NP)/NP)")
      , item <- closedEntries i w target ]
  | isClosedClass w || all (not . isWordChar) w =
      [ LexSign c' (relativeNote c c' it) s
      | (c, s) <- tags, let c' = restrictiveTag c, it <- closedEntries i w c' ]
  | otherwise = case nameStatus m (i == 0) w of
      NotName     -> open
      NameOnly    -> names
      NameOrOther -> names ++ open
  where
    ordinaryReflexiveTag (CAtom "N" fs) = null fs
    ordinaryReflexiveTag (CAtom "NP" fs) = all (== Feat "nb") fs
    ordinaryReflexiveTag _ = False
    reflexiveNote original target = Stipulation "reflexive-local-binding"
      ("direct-object reflexive: " ++ show original ++ " -> " ++ show target) []
      ("recognized reflexive reanalysis " ++ show original ++ " -> " ++ show target
        ++ "; local lexical transitive subject binds its object, not a discourse antecedent")
    tags = offeredTags m (i == 0) w
    open = [ LexSign c (tagNote c (nounLemmaNote c it)) s
           | (c, s) <- tags ++ thatTags ++ posTags
           , Just it <- [openTemplateWith (`Set.member` smThatAttested m) (nounWord c) c] ]
    -- A deliberately narrow regular-plural policy, not a general lemmatizer.
    -- Only an actually offered plain N with unambiguous dictionary support may
    -- change predicate spelling. Names, closed classes, backoff-only tags,
    -- verbal/attitude keys, adjectives and compounds keep their existing paths.
    nounBase
      | length w >= 4, all (\ch -> 'a' <= ch && ch <= 'z') w
      , last w == 's'
      , not (any (`isSuffixOf` w) ["es", "ss", "us", "is", "ews"])
      , Set.fromList (map fst (posCounts (smPOS m) w)) == Set.singleton "NNS"
      , let base = init w
      , Set.fromList (map fst (posCounts (smPOS m) base)) == Set.singleton "NN"
      = Just base
      | otherwise = Nothing
    nounWord c
      | c == CAtom "N" [], c `elem` map fst tags, Just base <- nounBase = base
      | otherwise = w
    nounLemmaNote c it
      | nounWord c /= w = withNote
          (Stipulation "noun-lemma" (w ++ " -> " ++ nounWord c ++ " at offered N")
            ["unchanged surface predicate " ++ w]
            "regular-s-noun-v1: lowercase single-word shape; surface POS support {NNS}, base POS support {NN}; es/ss/us/is/ews excluded; token, category and score retained") it
      | otherwise = it
    names = [ LexSign c' (withNote (nameNote c) (nameItem w)) s
            | (c, s) <- tags, Just c' <- [nameCategory c] ]
    -- NP[nb] is non-bare, not an expletive or a pending conjunct. Keep that
    -- ordinary NP feature; do not erase expl/thr/conj to create an individual.
    nameCategory (CAtom "N" _) = Just (CAtom "NP" [])
    nameCategory c@(CAtom "NP" fs)
      | all (== Feat "nb") fs = Just c
    nameCategory _ = Nothing
    nameNote c = Stipulation
      { stKind = "name-lexicon"
      , stChoice = "rigid name from " ++ show c
      -- These are available lexical alternatives, not necessarily complete
      -- sentence readings. NameOnly generates none; do not invent a candidate
      -- that would make the decision trace report a false ambiguity count.
      , stAlternatives = case nameStatus m (i == 0) w of
          NameOrOther -> [show c' ++ ": " ++ gloss
                         | LexSign c' (LexTerm _ gloss _) _ <- open]
          _ -> []
      , stWhy = case posCounts (smPOS m) (lookupForm m (i == 0) w) of
          ((p, _) : _) -> "dictionary majority POS " ++ p
            ++ " licenses the proper-name meaning; N lifts to NP and ordinary NP keeps its category"
          [] | i == 0 -> "unseen sentence-initial capital: the existing casing policy offers a name alternative alongside open-class meanings; capitalization here does not prove identity"
             | otherwise -> "unseen noninitial capital: the existing casing policy licenses a name; the category alone is not name evidence"
      }
    isWordChar c = c `notElem` ".,;:!?\"'()"
    lw = map toLower w
    restrictiveTag c
      | lw `elem` ["that", "which", "who"]
      , c == cat "(NP\\NP)/(S[dcl]\\NP)" = cat "(N\\N)/(S[dcl]\\NP)"
      | otherwise = c
    relativeNote old new it
      | old /= new = withNote (Stipulation "relative-attachment"
          "restrictive relative modifies N before the determiner"
          ["NP-level attachment (requires quantifier restriction semantics)", "nonrestrictive relative"]
          "CCGbank's NP attachment is reanalysed below the determiner to preserve universal/existential restrictions") it
      | otherwise = it
    -- Inflected forms can lose S[em] in the frequency beam even when the
    -- normalized lexeme is attested with that. Bare and that complements have
    -- the same intensional meaning; restore only this attested alternation.
    thatTags =
      [ (c', s) | reportingLemma w `Set.member` smThatAttested m
                , (CSlash Fwd vp (CAtom "S" [Feat "dcl"]) fs, s) <- tags
                , let c' = CSlash Fwd vp (CAtom "S" [Feat "em"]) fs
                , thatClauseCat c', c' `notElem` map fst tags ]
    -- POS is dictionary evidence only. No valency, adjective gradability or
    -- unknown-word morphology is guessed. Backoff tags are deliberately below
    -- every offered tag; this score ranks search and never admits facts.
    posTags =
      [ (c, minimum (0 : map snd tags) - 1)
      | smPOSBackoff m
      , c <- Set.toList (Set.fromList
          ([cat "N" | any (`elem` ["NN", "NNS"]) poses]
            ++ [cat c' | "JJ" `elem` poses, c' <- ["N/N", "S[adj]\\NP"]]))
      , c `notElem` map fst tags ]
    poses = map fst (posCounts (smPOS m) (lookupForm m (i == 0) w))
    tagNote c it
      | c `elem` map fst posTags = withNote
          (Stipulation "pos-backoff" ("dictionary POS licenses " ++ show c)
            ["corpus word-category dictionary only"]
            "optional noun/adjective backoff: an attested NN/NNS/JJ POS supplies a missing open-class category; no contextual POS or verb valency is inferred") it
      | c `elem` map fst thatTags = withNote
          (Stipulation "attested-that-complement" "explicit that-clause tag from lexeme attestation"
            ["only the inflected word's offered tags"]
            "the lemma has an explicit-that attestation; its offered bare-clause tag has the same intensional meaning") it
      | otherwise = it
    -- Preserve an existing semantic decision (notably see-sense) while
    -- documenting a simultaneous lexical category repair.
    withNote st (LexTerm tm gloss Nothing) = LexTerm tm gloss (Just st)
    withNote st (LexTerm tm gloss (Just old)) = LexTerm tm gloss
      (Just old { stWhy = stWhy old ++ "; " ++ stWhy st
                , stAlternatives = stAlternatives old ++ stAlternatives st })
    withNote _ it = it
    cat = either error id . parseCCGCat

--------------------------------------------------------------------------------
-- Chart
--------------------------------------------------------------------------------

-- | A same-category coordinate chain, certified by chart rules rather than by
-- inspecting logical terms. Nothing means comma edges have no overt operator.
-- Explicit incompatible subtrees remain atomic members with their provenance.
data CoordList = CoordList CCat (Maybe String) [(Term, Prov)] [(String, Prov)]
  deriving (Eq, Ord)
-- | A closed lexical reanalysis is tied to two adjacent input occurrences.
-- Original categories and spans are retained, not inferred from rendered terms.
data FusedCertificate = FusedCertificate
  { fcSource :: SourceId
  , fcHeadIndex :: Int
  , fcRelativeIndex :: Int
  , fcHeadSpan :: Span
  , fcRelativeSpan :: Span
  , fcHeadWord :: String
  , fcRelativeWord :: String
  , fcHeadCategory :: CCat
  , fcRelativeCategory :: CCat
  } deriving (Eq, Ord, Show)

data FusedRole
  = FusedPlain
  | FusedHead FusedCertificate
  | FusedRelOp FusedCertificate
  | FusedProperty FusedCertificate
  deriving (Eq, Ord, Show)

fusedHeadCat, fusedRelCat, fusedVPCat, fusedN, fusedNP, sourceRelCat :: CCat
fusedHeadCat = CSlash Fwd fusedNP fusedN []
fusedRelCat = CSlash Fwd fusedN fusedVPCat []
fusedVPCat = CSlash Bwd (CAtom "S" [Feat "dcl"]) fusedNP []
fusedN = CAtom "N" []
fusedNP = CAtom "NP" []
sourceRelCat = CSlash Fwd (CSlash Bwd fusedNP fusedNP []) fusedVPCat []

-- | A chart item.
data SSign = SSign
  { ssCat   :: CCat
  , ssSem   :: Term
    -- ^ Beta-normal and 'simplifyConj'-normal. For a structural item
    -- (coordinator, punctuation) a placeholder constant that is never used.
  , ssProv  :: Prov
  , ssScore :: Double
  , ssCoord :: Maybe String
    -- ^ A pending coordinator: this item is @X[conj]@ waiting for its left
    -- conjunct, and the string is the coordinator word.
  , ssStructural :: Maybe String
    -- ^ The word, if this item is a bare coordinator or punctuation mark.
  , ssOpenConditional :: Bool
    -- ^ A closed conditional introducer still waiting to form a complete
    -- sentence. Cleared at S, retained through functor composition/raising.
    -- Only clause-modifier comma coordination consults this obligation.
  , ssConditionalRaised :: Bool
    -- ^ The pending role has passed through an actual unary type-raising step.
    -- An isomorphic lexical category alone does not license a raised guard.
  , ssList :: Maybe CoordList
    -- ^ Only coordination/punctuation carry a list across their own boundary.
  , ssFused :: FusedRole
    -- ^ Pending local restriction certificate; part of the packing identity.
  , ssNotes :: [(Stipulation, Prov)]
    -- ^ Stipulations used anywhere in the derivation, with where.
  }

data SemParse = SemParse
  { spRoots   :: [SSign]
    -- ^ One item per distinct root meaning (category unifying with @S@), best
    -- score first.
  , spLexical :: [[LexSign]]
    -- ^ Interpretable readings per token.
  , spMaxCats :: Int
    -- ^ Largest category set in the category-only pre-pass (a size statistic).
  , spTrace :: Trace
    -- ^ Sentence-wide safety decisions, including a quote rejected entirely.
  }

key :: SSign -> (CCat, Term, Maybe String, Maybe String, Bool, Bool, Maybe CoordList, FusedRole)
key s = (ssCat s, canonicalAC (ssSem s), ssCoord s, ssStructural s, ssOpenConditional s, ssConditionalRaised s, ssList s, ssFused s)

-- | Pack by 'key' (keep the best score; earlier wins ties) and keep the beam.
packCell :: Int -> [SSign] -> [SSign]
packCell beam xs =
  take beam (sortBy (comparing (Down . ssScore)) (M.elems (M.fromListWith better [ (key s, s) | s <- xs ])))
  where better new old = if ssScore new > ssScore old then new else old

finish :: Term -> Term
finish = simplifyConj . normalize

-- | Parse one sentence's tokens. Token positions (for anaphor names) are the
-- indices into the list.
--
-- Two passes. First a category-only chart over the same interpretable lexical
-- categories, combinators and meaningful unary rules, followed by a backward
-- pass marking each @(span, category)@ that lies on some derivation of a root
-- @S@. Then the semantic chart, which builds items only for marked pairs. The
-- pruning is exact — an unmarked item cannot be part of any root derivation —
-- so it changes speed, not results, except that the per-cell beam is now spent
-- only on items that can still matter.
semParse :: SemModel -> SourceId -> [Token] -> SemParse
semParse m src toks = SemParse roots lexs maxCats (quoteTrace <> relativeTrace)
  where
    n = length toks
    ordinary = [ lexicalSigns m i (tokText t) | (i, t) <- zip [0 ..] toks ]
    -- Source tags, not invented internal tags, license the paired candidates.
    fusedPairs =
      [ (certificate, hs, rs, headEntry, relEntry)
      | (i, (headToken, relToken)) <- zip [0..] (zip toks (drop 1 toks))
      , Just (headEntry, relEntry) <- [restrictedPronounEntries (tokText headToken)]
      , map toLower (tokText relToken) `elem` ["that", "who", "which"]
      , (hc, hs) <- offeredTags m (i == 0) (tokText headToken), hc == fusedNP
      , (rc, rs) <- offeredTags m False (tokText relToken), rc == sourceRelCat
      , let certificate = FusedCertificate src i (i+1) (tokSpan headToken)
              (tokSpan relToken) (tokText headToken) (tokText relToken) hc rc ]
    annotated =
      [ [(l,FusedPlain) | l <- original] ++ concat
          [ [(LexSign fusedHeadCat headEntry hs, FusedHead certificate) | i == fcHeadIndex certificate]
            ++ [(LexSign fusedRelCat relEntry rs, FusedRelOp certificate) | i == fcRelativeIndex certificate]
          | (certificate,hs,rs,headEntry,relEntry) <- fusedPairs ]
      | (i, original) <- zip [0..] ordinary ]
    lexs = map (map fst) annotated

    -- Sound category overapproximation of the two licensed semantic steps.
    -- Ordinary pairs are untouched; pending semantic roles are checked later.
    categoryPairAt i k left right = seenPair m left right || any mapsSource fusedPairs
      where
        mapsSource (certificate,_,_,_,_) =
          (i == fcRelativeIndex certificate && k == i+1
           && left == fusedRelCat && right == fusedVPCat
           && sourcePair m (fcRelativeCategory certificate) right)
          || (i == fcHeadIndex certificate && k == i+1
              && left == fusedHeadCat && right == fusedN
              && sourcePair m (fcHeadCategory certificate) (CSlash Bwd fusedNP fusedNP []))

    leafSigns = M.fromList
      [ (i, filter (usefulAt (i, i + 1) . ssCat) (map (mkLeaf t) ls))
      | (i, (t, ls)) <- zip [0 :: Int ..] (zip toks annotated) ]

    -- Category-only forward pass.
    catTable :: ML.Map (Int, Int) (Set.Set CCat)
    catTable = ML.fromList
      [ ((i, j), catCell i j) | len <- [1 .. n], i <- [0 .. n - len], let j = i + len ]
    catCell i j
      | j == i + 1 = closeCats (Set.fromList [ lxCat l | l <- lexs !! i ])
      | otherwise = closeCats $ Set.fromList
          [ out
          | k <- [i + 1 .. j - 1]
          , l <- Set.toList (ML.findWithDefault Set.empty (i, k) catTable)
          , r <- Set.toList (ML.findWithDefault Set.empty (k, j) catTable)
          , categoryPairAt i k l r
          , (_, out) <- combineNamed allCombinators l r
          ]
    closeCats s0 = go (2 :: Int) s0
      where
        go 0 s = s
        go k s =
          let s' = Set.union s (Set.fromList [ to | (fr, to) <- meaningful, c <- Set.toList s, unifiable c fr ])
          in if Set.size s' == Set.size s then s else go (k - 1) s'
    maxCats = maximum (0 : map Set.size (ML.elems catTable))

    -- Backward pass: which (span, category) pairs reach a root.
    useful :: M.Map (Int, Int) (Set.Set CCat)
    useful = foldl' visit start [ (i, i + len) | len <- [n, n - 1 .. 1], i <- [0 .. n - len] ]
      where
        start = M.singleton (0, n)
          (Set.filter (\c -> unifiable c (CAtom "S" [])) (ML.findWithDefault Set.empty (0, n) catTable))
        visit acc (i, j) =
          let here = ML.findWithDefault Set.empty (i, j) catTable
              u0 = M.findWithDefault Set.empty (i, j) acc
              u = unaryBack here u0
              acc1 = M.insert (i, j) u acc
          in if Set.null u then acc1 else foldl' (split here u) acc1 [i + 1 .. j - 1]
          where
            split _ u a k =
              let ls = ML.findWithDefault Set.empty (i, k) catTable
                  rs = ML.findWithDefault Set.empty (k, j) catTable
                  pairs = [ (l, r) | l <- Set.toList ls, r <- Set.toList rs, categoryPairAt i k l r
                                   , any ((`Set.member` u) . snd) (combineNamed allCombinators l r) ]
              in M.insertWith Set.union (k, j) (Set.fromList (map snd pairs))
                   (M.insertWith Set.union (i, k) (Set.fromList (map fst pairs)) a)
        unaryBack here u0 = go (2 :: Int) u0
          where
            go 0 u = u
            go k u =
              let u' = Set.union u (Set.fromList
                         [ c | c <- Set.toList here, (fr, to) <- meaningful
                             , to `Set.member` u, unifiable c fr ])
              in if Set.size u' == Set.size u then u else go (k - 1) u'

    usefulAt ij c = c `Set.member` M.findWithDefault Set.empty ij useful

    mkLeaf t (LexSign c it s, fused) =
      let pv = ProvLex src (tokSpan t) (tokText t)
      in case it of
           LexTerm tm _ st ->
             -- The role belongs to the closed lexical entry, not a search for
             -- an if token anywhere in a completed constituent.
             SSign c (finish tm) pv s Nothing Nothing (isConditionalIntroducer (tokText t) c) False Nothing fused
               ([ (x, pv) | Just x <- [st] ] ++ fusedNotes fused pv)
           LexStructural _ ->
             SSign c (Con (tokText t) TyT) pv s Nothing (Just (tokText t)) False False Nothing FusedPlain []

    table :: ML.Map (Int, Int) [SSign]
    table = ML.fromList
      [ ((i, j), cell i j) | len <- [1 .. n], i <- [0 .. n - len], let j = i + len ]

    cell i j
      | j == i + 1 = closeUnary (i, j) (packCell (smBeam m) (M.findWithDefault [] i leafSigns))
      | otherwise = closeUnary (i, j) $ packCell (smBeam m)
          [ p
          | k <- [i + 1 .. j - 1]
            -- Combinability depends only on the two categories, so it is
            -- decided once per category pair and only then per item pair.
          , (lc, ls) <- groups (i, k)
          , (rc, rs) <- groups (k, j)
          , categoryPairAt i k lc rc
          , let outs = [ co | co@(_, out) <- combineNamed allCombinators lc rc, usefulAt (i, j) out ]
          , not (null outs)
          , l <- ls
          , r <- rs
          , fusedSeenPair m l r
          , (comb, out) <- outs
          , Just p <- [semCombine comb out l r]
          ]

    groups ij = M.toList (M.fromListWith (flip (++)) [ (ssCat x, [x]) | x <- ML.findWithDefault [] ij table ])

    -- Unary closure, two rounds (type-raising over a bare NP is the deepest
    -- chain the semantics licenses).
    closeUnary ij s0 = go (2 :: Int) s0
      where
        go 0 s = s
        go k s =
          let new = [ s' | x <- s, s' <- unaries x, usefulAt ij (ssCat s') ]
          in if null new then s else go (k - 1) (packCell (smBeam m) (s ++ new))

    -- Only type-changes with a meaning can contribute; the rest of the learned
    -- inventory is filtered out once, up front (a pure optimisation: a rule
    -- 'unarySem' rejects produces no item either way).
    meaningful = [ (fr, to) | (fr, to) <- rUnary (smRules m), Just _ <- [unarySem fr to]
                            , smTypeRaise m || clusterCoord || not (isTypeRaise to) ]
    -- The expensive raising search is enabled automatically only for a
    -- transitive verb immediately followed by a coordinator and a new NP.
    -- Plain adjective/VP lists do not trigger it.
    clusterCoord = or
      [ any (isTransitive . lxCat) (lexs !! (i - 1)) && startsNP (i + 1)
      | (i,t) <- zip [0..] toks, i > 0, i + 1 < n
      , map toLower (tokText t) `elem` ["and", "or"] ]
    isTransitive (CSlash Fwd (CSlash Bwd (CAtom "S" _) (CAtom "NP" _) _) (CAtom "NP" _) _) = True
    isTransitive _ = False
    startsNP i = nameStatus m (i == 0) (tokText (toks !! i)) /= NotName
      || map toLower (tokText (toks !! i)) `elem` ["the", "a", "an", "every", "all", "someone", "something"]
    isTypeRaise (CSlash _ _ (CSlash _ _ _ _) _) = True
    isTypeRaise _                                = False

    unaries x
      | ssCoord x /= Nothing || ssStructural x /= Nothing || pendingReflexive x || not (fusedUnaryAllowed x) = []
      | otherwise =
          [ SSign to (finish (f (ssSem x))) pv (ssScore x - smUnaryPenalty m) Nothing Nothing
                  (pendingConditional to [x])
                  (pendingConditional to [x] && (ssConditionalRaised x || isTypeRaise to)) Nothing FusedPlain
                  (ssNotes x ++ [ (st, pv) | Just st <- [mst] ]
                    ++ [(raisingNote, pv) | isTypeRaise to])
          | (fr, to) <- meaningful
          , unifiable (ssCat x) fr
          , Just (f, mst) <- [unarySem (ssCat x) to]
          , let pv = provRule ("unary " ++ show to) [ssProv x]
          ]

    raisingNote = Stipulation "type-raising" "type raising for argument-cluster coordination"
      ["application/composition without type raising"]
      "a transitive verb followed by a coordinator and a new NP requires the subject-verb cluster as a constituent; explicit smTypeRaise also enables this rule"

    unguardedRoots =
      let rs = [ s | s <- ML.findWithDefault [] (0, n) table
                   , unifiable (ssCat s) (CAtom "S" [])
                   -- A root asserts: an embedded clause (S[em], a proposition)
                   -- standing alone is not a sentence meaning.
                   , semTy (ssCat s) == Just TyT
                   , ssCoord s == Nothing, ssStructural s == Nothing, fusedRootAllowed s ]
          byMeaning = M.fromListWith (\new old -> if ssScore new > ssScore old then new else old)
                        [ (canonicalAC (ssSem s), s) | s <- rs ]
      in sortBy (comparing (Down . ssScore)) (M.elems byMeaning)

    -- Inverted quote tags can be absent altogether: a comma-coordinated
    -- transitive reading then silently asserts P and boast(cat,Bob). For the
    -- bounded suffix constructions P, VERB NP and P, NP VERB, retain only a
    -- whole-root attribution by that verb. Missing safe tags means no parse.
    -- The suffix NP must be present in the category chart and start with a
    -- name/determiner/pronoun. This deliberately also abstains on ambiguous
    -- independent comma clauses of this shape; plain adjective lists survive.
    -- It does not claim to recognize every English quotation.
    quoteCues = concat
      [ [cue (i+1) (i+2) contentEnd | verbAt (i+1), npSpan (i+2) contentEnd]
        ++ [cue (contentEnd-1) (i+1) (contentEnd-1)
           | verbAt (contentEnd-1), npSpan (i+1) (contentEnd-1)]
      | (i,t) <- zip [0..] toks, tokText t == ",", i+2 < contentEnd ]
    contentEnd = n - length (takeWhile (\t -> tokText t `elem` [".", "!", "?", "\"", "'"]) (reverse toks))
    verbAt i = any (isPrefixOf "VB" . fst)
      (posCounts (smPOS m) (map toLower (tokText (toks !! i))))
    npSpan a b = a < b && startsNP a
      && any (unifiable (CAtom "NP" []))
         (Set.toList (ML.findWithDefault Set.empty (a,b) catTable))
    cue v a b =
      ( reportingLemma (tokText (toks !! v))
      , if b == a+1 && nameStatus m False (tokText (toks !! a)) == NameOnly
          then Just (tokText (toks !! a)) else Nothing )
    safeQuote (verb,holder) tm = case tm of
      App (App (Con v _) h) (Lam _ TyS _) -> v == verb && typeOf [] h == Right TyE
        && maybe True (\name -> h == entity name) holder
      _ -> False
    roots = [r | null nonrestrictives, r <- unguardedRoots
               , all (\quoteCue -> safeQuote quoteCue (ssSem r)) quoteCues]
    nonrestrictives =
      [t | (previous,t) <- zip toks (drop 1 toks), tokText previous == ","
         , map toLower (tokText t) `elem` ["that", "which", "who"]]
    relativeTrace
      | null nonrestrictives = mempty
      | otherwise = note Decision
          { decKind = "relative-safety"
          , decChoice = "abstain: comma-marked nonrestrictive relative is unsupported"
          , decAlternatives = ["erase commas and incorrectly restrict the quantifier domain"]
          , decWhy = "restrictive relative semantics cannot express supplementary content; punctuation absorption must not turn one into the other"
          , decProv = provRule "relative-safety" [ProvLex src (tokSpan t) (tokText t) | t <- nonrestrictives]
          }
    quoteTrace
      | null quoteCues = mempty
      | otherwise = note Decision
          { decKind = "quote-safety"
          , decChoice = if null roots then "abstain: no whole-quote attribution reading"
                        else "retain only whole-quote attribution readings"
          , decAlternatives = [pretty (ssSem r) | r <- unguardedRoots
                             , not (all (\quoteCue -> safeQuote quoteCue (ssSem r)) quoteCues)]
          , decWhy = "comma + verb/NP suffix is quote-shaped; extensional coordination must not assert the quoted clause"
          , decProv = provRule "quote-safety" [ProvLex src (tokSpan t) (tokText t) | t <- toks]
          }

-- | The special diagonal category remains pending only until direct-object
-- binding. Its note then survives on an ordinary VP as provenance, not a ban
-- on subsequent composition. Checking the category also blocks unmarked
-- lookalikes from using ordinary combinators to bypass the local-domain gate.
pendingReflexive :: SSign -> Bool
pendingReflexive sign = case ssCat sign of
  CSlash Bwd vp (CSlash Fwd vp' (CAtom "NP" _) _) _ ->
    vp == vp' && case vp of
      CSlash Bwd (CAtom "S" _) (CAtom "NP" _) _ -> True
      _ -> False
  _ -> False

-- | The sign a combinator application yields from two adjacent items, if the
-- semantics admits it: each combinator of 'combineNamed' has one fixed semantic
-- operation.
semCombine :: Combinator -> CCat -> SSign -> SSign -> Maybe SSign
semCombine comb0 out0 l r
  | any pendingReflexive [l, r], not localBinding = Nothing
  | otherwise = do
      role <- fusedTransition comb0 out0 l r
      result <- sem comb0 out0 >>= emGuard
      let discharged = case (ssFused l, ssFused r, role) of
            (FusedHead _, FusedProperty _, FusedPlain) ->
              [(Stipulation "fused-relative-discharge"
                 "quantified head consumes its own relative restriction"
                 [] "paired input occurrences and source categories agree", ssProv result)]
            _ -> []
      pure result { ssFused = role, ssNotes = ssNotes result ++ discharged }
  where
    localBinding = comb0 == BwdApp && not (pendingReflexive l)
      && pendingReflexive r && plain l && plain r
      && lexical (ssProv l) && lexical (ssProv r)
      && any (\(note, prov) -> stKind note == "reflexive-local-binding"
                              && prov == ssProv r) (ssNotes r)
      && case localReflexiveVP (ssCat l) (ssCat r) of
        Just vp -> out0 == vp
          && case (semTy (ssCat l), semTy (ssCat r)) of
               (Just lt, Just rt) -> typeOf [] (ssSem l) == Right lt
                                 && typeOf [] (ssSem r) == Right rt
               _ -> False
        Nothing -> False
    lexical (ProvLex _ _ _) = True
    lexical _ = False
    -- Feature unification treats @S@ as a wildcard for @S[em]@, but the two
    -- differ in semantic type (@t@ versus @s -> t@, see
    -- 'NL2Proof.Syntax.Category.catTy'), and an entry with a declared
    -- intensional parameter has a lifted type ('liftsTo'). Where either is
    -- involved, a combination whose meaning does not inhabit its output type
    -- (up to declared lifting) is dropped rather than built: composition into
    -- an intensional parameter, for one, cannot re-index an argument it does
    -- not have yet. Elsewhere no check is made, so nothing changes for
    -- extensional sentences.
    emGuard x
      | ssStructural x == Nothing
      , any mentionsEm [ssCat l, ssCat r, ssCat x]
          || any (isIntensionalTerm . ssSem) [l, r]
      , Just ty <- semTy (ssCat x) =
          case typeOf [] (ssSem x) of
            Right t | t `liftsTo` ty -> Just x
            _                        -> Nothing
      | otherwise = Just x

    plain x = ssCoord x == Nothing && ssStructural x == Nothing
    pv comb = provRule (show comb) [ssProv l, ssProv r]
    notes = ssNotes l ++ ssNotes r
    mk comb out tm coord = SSign out (finish tm) (pv comb) (ssScore l + ssScore r) coord Nothing
      (pendingConditional out [l, r])
      (pendingConditional out [l, r] && any ssConditionalRaised [l, r]) Nothing FusedPlain notes

    sem comb out = case comb of
      -- 'applyIntensional' is 'App' unless the functor declares an
      -- intensional parameter (then the argument is abstracted over a world).
      FwdApp  | plain l, plain r -> Just (mk comb out (applyIntensional (ssSem l) (ssSem r)) Nothing)
      BwdApp  | plain l, plain r -> Just (mk comb out (applyIntensional (ssSem r) (ssSem l)) Nothing)
      FwdComp | plain l, plain r -> compose comb out (ssSem l) (ssSem r) (argOfR r)
      FwdXComp | plain l, plain r -> compose comb out (ssSem l) (ssSem r) (argOfR r)
      BwdComp | plain l, plain r -> compose comb out (ssSem r) (ssSem l) (argOfR l)
      BwdXComp | plain l, plain r -> compose comb out (ssSem r) (ssSem l) (argOfR l)
      CoordMark
        | Just w <- ssStructural l, isCoordinator (ssCat l), plain r ->
            Just ((mk comb out (ssSem r) (Just w)) { ssList = ssList r })
      CoordApply
        | plain l, Just w <- ssCoord r
        , not (w == "," && any pendingModifier [l, r])
        , Just marker <- pendingCoordinator (ssProv r)
        , Just (tm, certificate, repair) <- coordinateList out (map toLower w) marker l r ->
            Just ((mk comb out tm Nothing)
              { ssList = Just certificate, ssNotes = notes ++ repair })
      PunctRight
        | isPunct (ssCat r), Just _ <- ssStructural r, ssStructural l == Nothing ->
            Just (keep l)
      PunctLeft
        | isPunct (ssCat l), Just _ <- ssStructural l, ssStructural r == Nothing
        , ssCoord r == Nothing ->
            Just (keep r)
      _ -> Nothing
      where
        keep x = x { ssProv = pv comb, ssScore = ssScore l + ssScore r, ssNotes = notes }

    -- The composed-over argument: the inner functor's own argument.
    argOfR x = case ssCat x of
      CSlash _ _ z _ -> semTy z
      _              -> Nothing

    compose comb out f g (Just zTy) = Just (mk comb out (composeTerm zTy f g) Nothing)
    compose _ _ _ _ Nothing = Nothing

-- | Source-category evidence for the two internal reanalysis applications.
-- Do not turn a licensed local reanalysis into a global unseen-pair exception.
sourcePair :: SemModel -> CCat -> CCat -> Bool
sourcePair model left right = not (smSeenRules model)
  || (eraseFeatures left, eraseFeatures right) `Set.member` smSeen model

fusedSeenPair :: SemModel -> SSign -> SSign -> Bool
fusedSeenPair model left right = case (ssFused left, ssFused right) of
  (FusedPlain,FusedPlain) -> seenPair model (ssCat left) (ssCat right)
  (FusedRelOp certificate,FusedPlain) ->
    sourcePair model (fcRelativeCategory certificate) (ssCat right)
  (FusedHead certificate,FusedProperty other) -> certificate == other
    && sourcePair model (fcHeadCategory certificate) (CSlash Bwd fusedNP fusedNP [])
  _ -> False

fusedNotes :: FusedRole -> Prov -> [(Stipulation,Prov)]
fusedNotes FusedPlain _ = []
fusedNotes role pv = [(Stipulation "fused-relative-reanalysis"
  (show role) []
  "offered NP head and subject-relative category form a local restriction pair; no arbitrary NP inversion", pv)]

-- | Exact local transition contract. No pending sign passes through raising,
-- composition, coordination or punctuation, and category equality alone never
-- discharges a head. Ordinary signs retain the existing combinator behavior.
-- Token adjacency is guaranteed by pair minting and adjacent chart spans; the
-- exported helper checks identity/source ordering, not arbitrary forged signs.
fusedTransition :: Combinator -> CCat -> SSign -> SSign -> Maybe FusedRole
fusedTransition comb out left right = case (ssFused left, ssFused right) of
  (FusedPlain,FusedPlain) -> Just FusedPlain
  (FusedRelOp certificate,FusedPlain)
    | comb == FwdApp, out == fusedN, ssCat left == fusedRelCat
    , ssCat right == fusedVPCat, clean left, clean right
    , validCertificate certificate, relativeLeaf certificate (ssProv left)
    , sameSourceAfter certificate (fcRelativeSpan certificate) (ssProv right)
    , coherent left, coherent right -> Just (FusedProperty certificate)
  (FusedHead certificate,FusedProperty other)
    | comb == FwdApp, out == fusedNP, certificate == other
    , ssCat left == fusedHeadCat, ssCat right == fusedN
    , clean left, clean right, validCertificate certificate
    , headLeaf certificate (ssProv left), propertyOrigin certificate (ssProv right)
    , coherent left, coherent right -> Just FusedPlain
  _ -> Nothing
  where
    clean sign = ssCoord sign == Nothing && ssStructural sign == Nothing
    coherent sign = case semTy (ssCat sign) of
      Just ty -> typeOf [] (ssSem sign) == Right ty
      Nothing -> False
    relativeLeaf certificate = (== ProvLex (fcSource certificate)
      (fcRelativeSpan certificate) (fcRelativeWord certificate))
    headLeaf certificate = (== ProvLex (fcSource certificate)
      (fcHeadSpan certificate) (fcHeadWord certificate))
    propertyOrigin certificate (ProvRule (RuleName "FwdApp") [relative,body]) =
      relativeLeaf certificate relative
      && sameSourceAfter certificate (fcRelativeSpan certificate) body
    propertyOrigin _ _ = False

validCertificate :: FusedCertificate -> Bool
validCertificate certificate = fcRelativeIndex certificate == fcHeadIndex certificate + 1
  && fcHeadIndex certificate >= 0
  && fcHeadCategory certificate == fusedNP
  && fcRelativeCategory certificate == sourceRelCat
  && map toLower (fcHeadWord certificate) `elem` ["everything","someone"]
  && map toLower (fcRelativeWord certificate) `elem` ["that","who","which"]
  && spanEnd (fcHeadSpan certificate) <= spanStart (fcRelativeSpan certificate)

sameSourceAfter :: FusedCertificate -> Span -> Prov -> Bool
sameSourceAfter certificate before pv = provSources pv == [fcSource certificate]
  && case provSpan pv of
       Just span' -> spanEnd before <= spanStart span'
       Nothing -> False

fusedUnaryAllowed :: SSign -> Bool
fusedUnaryAllowed = (==FusedPlain) . ssFused

fusedRootAllowed :: SSign -> Bool
fusedRootAllowed = (==FusedPlain) . ssFused

-- | The exact closed lexical key supplies the syntactic role. Human-readable
-- glosses may change without changing grammar; alternate conditional categories
-- must be licensed deliberately alongside their closed lexical entries.
isConditionalIntroducer :: String -> CCat -> Bool
isConditionalIntroducer word c = map toLower word == "if"
  && Right c == parseCCGCat "(S/S)/S[dcl]"

-- | The pending marker is introduced by CoordMark and may absorb right-hand
-- punctuation. Do not mistake a coordinator inside its operand for this edge.
pendingCoordinator :: Prov -> Maybe Prov
pendingCoordinator (ProvRule (RuleName "CoordMark") [marker, _]) = Just marker
pendingCoordinator (ProvRule (RuleName "PunctRight") [marked, _]) = pendingCoordinator marked
pendingCoordinator _ = Nothing

-- | Resolve only comma-created edges, never explicit mixed conjunctions. Two
-- incompatible explicit child chains stay atomic; their separating comma keeps
-- the established asyndetic AND reading until an outer overt list licenses it.
coordinateList :: CCat -> String -> Prov -> SSign -> SSign
               -> Maybe (Term, CoordList, [(Stipulation, Prov)])
coordinateList category word marker left right = do
  original <- coordinatorOp word
  ty <- semTy category
  let child sign = case ssList sign of
        Just list@(CoordList c _ _ _)
          | unifiable c category, semTy c == Just ty -> Just list
        _ -> Nothing
      operator sign = case child sign of
        Just (CoordList _ op _ _) -> op
        Nothing -> Nothing
      -- The overt coordinator must close this list on the right. An earlier
      -- OR alone does not turn a later asyndetic comma into another OR.
      overt = if word /= "," then Just word else case (operator left, operator right) of
        (Just a, Just b) | a /= b -> Nothing
        (_, Just op) -> Just op
        _ -> Nothing
      members onRight sign = case child sign of
        Just (CoordList _ op childMembers childEdges)
          | op == Nothing || op == overt
          -- An overt edge closes preceding commas; it cannot reach into a
          -- following comma-only subtree and retroactively make those ORs.
          , not (onRight && word /= "," && op == Nothing) -> (childMembers, childEdges)
        _ -> ([(ssSem sign, ssProv sign)], [])
      (ls, le) = members False left
      (rs, re) = members True right
      xs = ls ++ rs
      edges = le ++ [(word, marker)] ++ re
      resolve = any ((== ",") . fst) edges && overt /= Nothing
      certificate = CoordList category overt xs edges
      build _ [(tm, _)] = Just tm
      build op ((tm, _) : rest) = build op rest >>= coordTerm op ty tm
      build _ [] = Nothing
  tm <- if resolve
    then case overt >>= coordinatorOp of
      Just op -> build op xs
      Nothing -> Nothing
    else coordTerm original ty (ssSem left) (ssSem right)
  let repair = [(Stipulation "comma-list" "comma list inherits or"
                  ["comma defaults to and"]
                  "same-category coordination provenance supplies an overt OR; explicit mixed edges remain atomic",
                 marker) | resolve, overt == Just "or"]
  pure (tm, certificate, repair)

-- | A complete sentence discharges all conditional obligations contained in it.
-- In particular, embedding/raising that sentence must not poison surrounding
-- comma coordination. On functors retain the obligation through application,
-- composition and unary type raising; counting applications would wrongly
-- consume it when a raised sign merely receives its continuation.
pendingConditional :: CCat -> [SSign] -> Bool
pendingConditional (CAtom "S" _) _ = False
pendingConditional _ signs = any ssOpenConditional signs

-- | The bounded guard covers coordination of sentence modifiers that mistakes a conditional boundary
-- for pointwise conjunction of antecedent/consequent operators. Other functor
-- categories and explicit and/or coordination keep their existing behavior.
-- Recognize licensed type-raising wrappers too: raising the two modifiers must
-- not provide a route around their boundary obligation.
pendingModifier :: SSign -> Bool
pendingModifier sign = ssOpenConditional sign
  && (plainClauseModifier (ssCat sign)
      || ssConditionalRaised sign && clauseModifier (ssCat sign))

plainClauseModifier :: CCat -> Bool
plainClauseModifier (CSlash _ (CAtom "S" _) (CAtom "S" _) _) = True
plainClauseModifier _ = False

clauseModifier :: CCat -> Bool
clauseModifier (CSlash _ (CAtom "S" _) (CAtom "S" _) _) = True
clauseModifier (CSlash d t (CSlash d' t' inner _) _)
  | d /= d', unifiable t t' = clauseModifier inner
clauseModifier _ = False

-- | Does a category mention an embedded clause @S[em]@?
mentionsEm :: CCat -> Bool
mentionsEm (CAtom "S" fs)      = Feat "em" `elem` fs
mentionsEm (CAtom _ _)         = False
mentionsEm (CSlash _ a b _)    = mentionsEm a || mentionsEm b

-- | The existing category-only parser ('chartParseScored') on the same tagger
-- output: does /any/ category derivation reach @S@, meanings aside? Reported
-- next to 'semParse' so a semantic failure is never mistaken for a syntactic one.
syntacticParse :: SemModel -> [Token] -> Bool
syntacticParse m toks =
  let tags = [ offeredTags m (i == 0) (tokText t) | (i, t) <- zip [0 :: Int ..] toks ]
  in any (\(c, _) -> unifiable c (CAtom "S" []))
         (chartParseScored (smBeam m) (smRules m) tags)
