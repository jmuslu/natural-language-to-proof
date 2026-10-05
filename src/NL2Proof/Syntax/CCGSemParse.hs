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
-- * Two items with the same category, the same pending coordinator and
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
  , SemParse(..)
  , semParse
  , syntacticParse
  ) where

import Control.Exception (IOException, try)
import Control.Monad (foldM)
import Data.Char (isUpper, toLower)
import Data.List (foldl', sortBy)
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
import NL2Proof.Syntax.CCGBank (CCat(..), Feat(..), eraseFeatures, parseCCGCat)
import NL2Proof.Syntax.CCGDeriv (AutoNode(..), leafHeaders, nodeCat, parseAuto)
import NL2Proof.Syntax.CCGParse (Rules(..), chartParseScored)
import NL2Proof.Syntax.CCGTypeChange (TypeChange(..), inducements, normalizeTC)
import NL2Proof.Syntax.CCGRules
  (Combinator(..), combineNamed, allCombinators, isCoordinator, isPunct, unifiable)
import NL2Proof.Syntax.CCGSupertag
import NL2Proof.Syntax.Tokenize (Token(..))

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
    -- ^ Use the learned type-raising rules (@X -> T\/(T\\X)@ etc.). Off by
    -- default: see 'defaultSemModel'.
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
    -- committed. On sections 02-21 it includes @noted@, @added@,
    -- @announced@ and @see@ (@see that ...@).
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
-- Type-raising is off. Its meaning is fixed (@\\f. f(a)@) and it is
-- implemented, but in a chart that also has composition it mostly re-derives
-- what application already derives, while multiplying the categories per cell
-- (measured on ProofWriter train sentences: at most ~15 categories per cell
-- without it, ~100 with it, and 2-4x the parse time). It is needed for
-- extraction and argument-cluster coordination, neither of which occurs in
-- ProofWriter's training sentences. A stated, train-set-informed restriction.
defaultSemModel :: TagModel -> POSModel -> Rules -> Set.Set (CCat, CCat) -> SemModel
defaultSemModel tm pm rs seen =
  SemModel tm pm rs 0.01 20 40 1.0 20 True False seen True
    (M.fromList (tmPrior tm)) (fromIntegral (sum (map snd (tmPrior tm))))
    (Set.fromList [ reportingLemma w | (w, cs) <- M.toList (tmWord tm), any (thatClauseCat . fst) cs ])

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

-- | Is a binary combination of these two categories allowed ('smSeenRules')?
seenPair :: SemModel -> CCat -> CCat -> Bool
seenPair m l r = not (smSeenRules m) || (eraseFeatures l, eraseFeatures r) `Set.member` smSeen m

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
-- entries; names turn each offered @N@ into a name @NP@; everything else uses
-- the open-class templates.
lexicalSigns :: SemModel -> Int -> String -> [LexSign]
lexicalSigns m i w
  | isClosedClass w || all (not . isWordChar) w =
      [ LexSign c it s | (c, s) <- tags, it <- closedEntries i w c ]
  | otherwise = case nameStatus m (i == 0) w of
      NotName     -> open
      NameOnly    -> names
      NameOrOther -> names ++ open
  where
    tags = offeredTags m (i == 0) w
    open = [ LexSign c it s | (c, s) <- tags
                            , Just it <- [openTemplateWith (`Set.member` smThatAttested m) w c] ]
    names = [ LexSign (CAtom "NP" []) (nameItem w) s | (CAtom "N" _, s) <- tags ]
    isWordChar c = c `notElem` ".,;:!?\"'()"

--------------------------------------------------------------------------------
-- Chart
--------------------------------------------------------------------------------

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
  }

key :: SSign -> (CCat, Term, Maybe String, Maybe String)
key s = (ssCat s, canonicalAC (ssSem s), ssCoord s, ssStructural s)

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
semParse m src toks = SemParse roots lexs maxCats
  where
    n = length toks
    lexs = [ lexicalSigns m i (tokText t) | (i, t) <- zip [0 ..] toks ]

    leafSigns = M.fromList
      [ (i, filter (usefulAt (i, i + 1) . ssCat) (map (mkLeaf t) ls))
      | (i, (t, ls)) <- zip [0 :: Int ..] (zip toks lexs) ]

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
          , seenPair m l r
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
                  pairs = [ (l, r) | l <- Set.toList ls, r <- Set.toList rs, seenPair m l r
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

    mkLeaf t (LexSign c it s) =
      let pv = ProvLex src (tokSpan t) (tokText t)
      in case it of
           LexTerm tm _ st ->
             SSign c (finish tm) pv s Nothing Nothing [ (x, pv) | Just x <- [st] ]
           LexStructural _ ->
             SSign c (Con (tokText t) TyT) pv s Nothing (Just (tokText t)) []

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
          , seenPair m lc rc
          , let outs = [ co | co@(_, out) <- combineNamed allCombinators lc rc, usefulAt (i, j) out ]
          , not (null outs)
          , l <- ls
          , r <- rs
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
                            , smTypeRaise m || not (isTypeRaise to) ]
    isTypeRaise (CSlash _ _ (CSlash _ _ _ _) _) = True
    isTypeRaise _                                = False

    unaries x
      | ssCoord x /= Nothing || ssStructural x /= Nothing = []
      | otherwise =
          [ SSign to (finish (f (ssSem x))) pv (ssScore x - smUnaryPenalty m) Nothing Nothing
                  (ssNotes x ++ [ (st, pv) | Just st <- [mst] ])
          | (fr, to) <- meaningful
          , unifiable (ssCat x) fr
          , Just (f, mst) <- [unarySem (ssCat x) to]
          , let pv = provRule ("unary " ++ show to) [ssProv x]
          ]

    roots =
      let rs = [ s | s <- ML.findWithDefault [] (0, n) table
                   , unifiable (ssCat s) (CAtom "S" [])
                   -- A root asserts: an embedded clause (S[em], a proposition)
                   -- standing alone is not a sentence meaning.
                   , semTy (ssCat s) == Just TyT
                   , ssCoord s == Nothing, ssStructural s == Nothing ]
          byMeaning = M.fromListWith (\new old -> if ssScore new > ssScore old then new else old)
                        [ (canonicalAC (ssSem s), s) | s <- rs ]
      in sortBy (comparing (Down . ssScore)) (M.elems byMeaning)

-- | The sign a combinator application yields from two adjacent items, if the
-- semantics admits it: each combinator of 'combineNamed' has one fixed semantic
-- operation.
semCombine :: Combinator -> CCat -> SSign -> SSign -> Maybe SSign
semCombine comb0 out0 l r = sem comb0 out0 >>= emGuard
  where
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
    mk comb out tm coord = SSign out (finish tm) (pv comb) (ssScore l + ssScore r) coord Nothing notes

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
            Just (mk comb out (ssSem r) (Just w))
      CoordApply
        | plain l, Just w <- ssCoord r, Just op <- coordinatorOp w
        , Just ty <- semTy out, Just tm <- coordTerm op ty (ssSem l) (ssSem r) ->
            Just (mk comb out tm Nothing)
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
