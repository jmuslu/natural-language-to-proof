-- | The Stage 1 pipeline: text in, provenance-tagged DRS out.
--
-- The order of operations mirrors the architecture's split. Everything up to and
-- including 'srParses' is __search__: it produces a candidate set and commits to
-- nothing. Everything after is either mechanical translation or an explicitly
-- logged __decision__.
--
-- Two places where this module refuses to take a shortcut, both deliberate:
--
-- * A sentence with more than one derivation is /not/ silently resolved to the
--   first. It raises 'ParseAmbiguity' and records a 'Decision' naming the
--   tie-breaking rule.
--
-- * A sentence whose meaning fails 'typeOf' is /not/ dropped. It raises
--   'TypeCheckFailure' and contributes nothing to the discourse, so the failure
--   is visible in the output rather than showing up as a mysteriously absent
--   condition.
--
-- There are two front ends ('ParserChoice'): the hand-written fragment lexicon
-- with its application-only parser, and the CCGbank-trained parser with the
-- semantic layer of "NL2Proof.Semantics.CCGSem". They differ up to the
-- candidate set of root signs; selection, type checking and DRS construction
-- are one shared back end, so both are held to the same discipline.
module NL2Proof.Pipeline
  ( -- * Results
    SentenceResult(..)
  , PipelineResult(..)
    -- * Running
  , ParserChoice(..)
  , runPipeline
  , runPipelineWith
  , runFragment
  , sentenceProv
    -- * Ambiguity detection
  , detectCoupling
    -- * Reporting
  , renderPipelineResult
  , renderSentenceResult
  ) where

import Data.List (intercalate, nub, sort)
import qualified Data.Map as M

import NL2Proof.Collapse.Class
import NL2Proof.DRT.Build
import NL2Proof.DRT.Types
import NL2Proof.Provenance
import NL2Proof.Semantics.CCGSem (LexItem(..), Stipulation(..))
import NL2Proof.Semantics.Lambda
import NL2Proof.Syntax.CCG
import NL2Proof.Syntax.CCGBank (ccatToCat)
import NL2Proof.Syntax.CCGSemParse
import NL2Proof.Syntax.Category
import NL2Proof.Syntax.Lexicon
import NL2Proof.Syntax.Tokenize
import NL2Proof.Trace

--------------------------------------------------------------------------------
-- Results
--------------------------------------------------------------------------------

data SentenceResult = SentenceResult
  { srSentence :: Sentence
  , srLattice  :: Lattice
    -- ^ Every candidate lexical unit, before the parser chose among them.
  , srTokens   :: [Token]
    -- ^ Raw whitespace tokens. Not what was parsed — see 'srLattice'.
  , srUnknown  :: [Token]
    -- ^ Raw tokens no candidate unit covers.
  , srParses   :: [Sign]
    -- ^ __All__ derivations, not the selected one.
  , srChosen   :: Maybe Sign
  , srForm     :: Maybe Term
    -- ^ Beta-normal form of the chosen derivation's meaning.
  , srDRS      :: Maybe DRS
    -- ^ Sentence-local DRS, before discourse-level anaphora resolution.
  , srTrace    :: Trace
  }

data PipelineResult = PipelineResult
  { prSource    :: SourceId
  , prText      :: String
  , prSentences :: [SentenceResult]
  , prDiscourse :: Discourse
    -- ^ The merged, anaphora-resolved discourse DRS.
  , prSelection :: Maybe Selection
    -- ^ Handoff point to a 'CollapseStrategy'. 'Nothing' when nothing parsed.
  , prTrace     :: Trace
    -- ^ Every decision and diagnostic, sentence-level and discourse-level.
  }

--------------------------------------------------------------------------------
-- Running
--------------------------------------------------------------------------------

-- | Which front end produces the candidate signs.
data ParserChoice
  = -- | The hand-written lexicon ("NL2Proof.Syntax.Lexicon") and the
    -- application-only CKY parser of "NL2Proof.Syntax.CCG".
    HandLexicon Lexicon
  | -- | The CCGbank-trained supertagger and grammar, with meanings from
    -- "NL2Proof.Semantics.CCGSem" ("NL2Proof.Syntax.CCGSemParse").
    CCGBankParser SemModel

-- | Run the fragment lexicon over a text.
runFragment :: SourceId -> String -> PipelineResult
runFragment = runPipeline fragmentLexicon

runPipeline :: Lexicon -> SourceId -> String -> PipelineResult
runPipeline = runPipelineWith . HandLexicon

runPipelineWith :: ParserChoice -> SourceId -> String -> PipelineResult
runPipelineWith choice src text =
  PipelineResult
    { prSource = src
    , prText = text
    , prSentences = results
    , prDiscourse = discourse
    , prSelection = selection
    , prTrace = foldMap srTrace results <> dscTrace discourse
    }
  where
    results = map (processSentence choice src) (splitSentences text)

    -- Discourse threading happens over the sentences that produced a DRS.
    -- A sentence that failed to parse or failed to type-check contributes
    -- nothing but has already recorded a diagnostic saying so.
    discourse =
      runDiscourse
        [ (d, sentenceProv src r) | r <- results, Just d <- [srDRS r] ]

    selection =
      let d = dscDRS discourse
      in if null (drsConds d) && null (drsUniverse d)
           then Nothing
           else Just (selectOnly d (discourseProv src results))

-- | Provenance for a whole sentence: its chosen derivation if there is one,
-- otherwise a bare span over its tokens.
sentenceProv :: SourceId -> SentenceResult -> Prov
sentenceProv src r = case srChosen r of
  Just s  -> sProv s
  Nothing ->
    provRule "sentence" [ProvLex src (tokSpan t) (tokText t) | t <- srTokens r]

discourseProv :: SourceId -> [SentenceResult] -> Prov
discourseProv src = provRule "discourse" . map (sentenceProv src)

processSentence :: ParserChoice -> SourceId -> Sentence -> SentenceResult
processSentence (HandLexicon lexicon) = processHand lexicon
processSentence (CCGBankParser model) = processCCG model

processHand :: Lexicon -> SourceId -> Sentence -> SentenceResult
processHand lexicon src sent =
  SentenceResult
    { srSentence = sent
    , srLattice = lat
    , srTokens = toks
    , srUnknown = unknown
    , srParses = parses
    , srChosen = chosen
    , srForm = form
    , srDRS = drs
    , srTrace =
        unknownTrace <> segTrace <> couplingTrace <> backTrace
    }
  where
    lat = sentenceLattice (inLexicon lexicon) (maxPhraseLength lexicon) sent
    toks = latRaw lat
    unknown = uncoveredTokens lat

    unknownTrace = foldMap (unknownWord src "unknown word: ") unknown

    -- A fork is not a decision here, so it is a diagnostic and not a
    -- 'Decision': nothing is collapsed at this point. It is still worth logging,
    -- because a fork whose alternative dies inside the parse table leaves no
    -- other trace that it existed.
    segTrace =
      foldMap
        (\(u, v) ->
           flag
             Diagnostic
               { diagKind = SegmentationAmbiguity
               , diagMsg =
                   "competing lexical units " ++ show (tokText u) ++ " and "
                     ++ show (tokText v) ++ "; both kept, the parser decides"
               , diagProv =
                   provRule "segmentation"
                     [ ProvLex src (tokSpan u) (tokText u)
                     , ProvLex src (tokSpan v) (tokText v)
                     ]
               })
        (latticeForks lat)

    couplingTrace = foldMap flag (detectCoupling lexicon src toks)

    parses = parse lexicon src lat S

    (chosen, form, drs, backTrace) =
      backEnd
        BackEnd
          { beTieBreak =
              "first derivation in CKY enumeration order; a positional"
                ++ " tie-break, not a linguistic one"
          , beProvIndex = buildProvIndex lexicon . sProv
          , bePostDRS = \sg d ->
              let (d1, t1) = projectPresuppositions d
              in (d1, t1 <> reportDefiniteDecisions (sProv sg) (normalize (sSem sg)))
          , beNotes = const mempty
          }
        src sent (null unknown) parses

-- | The CCGbank path: case-preserving tokens with punctuation, the semantic
-- chart, then the shared back end. Root candidates are distinct meanings, best
-- supertagger score first.
processCCG :: SemModel -> SourceId -> Sentence -> SentenceResult
processCCG model src sent =
  SentenceResult
    { srSentence = sent
    , srLattice = lat
    , srTokens = toks
    , srUnknown = unknown
    , srParses = parses
    , srChosen = chosen
    , srForm = form
    , srDRS = drs
    , srTrace = unknownTrace <> backTrace
    }
  where
    toks = casedTokens (spanStart (sentSpan sent)) (sentText sent)
    lat = Lattice toks (M.fromList [ ((i, i + 1), t) | (i, t) <- zip [0 ..] toks ])
    sp = semParse model src toks
    lexs = spLexical sp

    -- The analogue of an unknown word: the tagger offered categories, but the
    -- semantic lexicon interprets none of them.
    unknown = [ t | (t, ls) <- zip toks lexs, null ls ]
    unknownTrace =
      foldMap (unknownWord src "no interpretable CCGbank category for word: ") unknown

    roots = spRoots sp
    parses = map toSign roots
    toSign s = Sign (maybe S id (ccatToCat (ssCat s))) (ssSem s) (ssProv s)
    -- The back end always selects the first candidate, so the stipulations to
    -- log are those of the first root.
    chosenNotes = case roots of { (r : _) -> ssNotes r; [] -> [] }

    -- Word-level provenance from the chosen derivation's own leaves: each leaf
    -- token maps the constants of its interpretable readings to its span.
    provIndexFor sg =
      let spans = [ sp' | (_, sp', _) <- provLeaves (sProv sg) ]
      in M.fromList
           [ (c, ProvLex src (tokSpan t) (tokText t))
           | (t, ls) <- zip toks lexs
           , tokSpan t `elem` spans
           , LexSign _ (LexTerm tm _ _) _ <- ls
           , c <- constNames tm
           ]

    (chosen, form, drs, backTrace) =
      backEnd
        BackEnd
          { beTieBreak =
              "highest supertagger log-probability (sum over the derivation);"
                ++ " a statistical tie-break from CCGbank frequencies, not a"
                ++ " linguistic one"
          , beProvIndex = provIndexFor
          , bePostDRS = \sg d ->
              let (d1, t1) = resolveLocalAnaphora (provIndexFor sg) d
                  (d2, t2) = projectPresuppositions d1
              in (d2, t1 <> t2 <> reportDefiniteDecisions (sProv sg) (sSem sg))
          , beNotes = \_ ->
              foldMap
                (\(st, p) ->
                   note
                     Decision
                       { decKind = stKind st
                       , decChoice = stChoice st
                       , decAlternatives = stAlternatives st
                       , decWhy = stWhy st
                       , decProv = p
                       })
                chosenNotes
          }
        src sent (null unknown) parses

unknownWord :: SourceId -> String -> Token -> Trace
unknownWord src msg t =
  flag
    Diagnostic
      { diagKind = NoParse
      , diagMsg = msg ++ show (tokText t)
      , diagProv = ProvLex src (tokSpan t) (tokText t)
      }

-- | What differs between front ends inside the shared back end.
data BackEnd = BackEnd
  { beTieBreak  :: String
    -- ^ How the first candidate came to be first, for the selection 'Decision'.
  , beProvIndex :: Sign -> ProvIndex
  , bePostDRS   :: Sign -> DRS -> (DRS, Trace)
    -- ^ Sentence-internal DRS steps after translation (the CCGbank path
    -- resolves donkey anaphora here; both project factive presuppositions).
  , beNotes     :: Sign -> Trace
    -- ^ Decisions the chosen derivation's entries stipulated.
  }

-- | Selection, verification and translation: shared by both front ends.
backEnd :: BackEnd -> SourceId -> Sentence -> Bool -> [Sign] -> (Maybe Sign, Maybe Term, Maybe DRS, Trace)
backEnd be src sent wordsCovered parses = (chosen, form, drs, parseTrace <> typeTrace)
  where
    sentProvFallback =
      provRule "sentence" [ProvLex src (sentSpan sent) (sentText sent)]

    -- Search produced a candidate set; here is where it collapses, out loud.
    (chosen, parseTrace) = case parses of
      [] ->
        ( Nothing
        , if wordsCovered
            then
              flag
                Diagnostic
                  { diagKind = NoParse
                  , diagMsg = "no derivation to S for " ++ show (sentText sent)
                  , diagProv = sentProvFallback
                  }
            else mempty -- already reported per word
        )
      [only] -> (Just only, mempty)
      (first : rest) ->
        ( Just first
        , flag
            Diagnostic
              { diagKind = ParseAmbiguity
              , diagMsg =
                  show (length parses) ++ " derivations to S: "
                    ++ intercalate " | " (map (pretty . normalize . sSem) parses)
              , diagProv = sentProvFallback
              }
            <> note
              Decision
                { decKind = "parse-selection"
                , decChoice = pretty (normalize (sSem first))
                , decAlternatives = map (pretty . normalize . sSem) rest
                , decWhy = beTieBreak be
                , decProv = sentProvFallback
                }
        )

    -- Verification: the chosen meaning must inhabit the type its category
    -- demands. This is mechanical, and a failure is fatal for this sentence.
    (form, drs, typeTrace) = case chosen of
      Nothing -> (Nothing, Nothing, mempty)
      Just s -> case typeOf [] (sSem s) of
        Right t
          | t == catTy (sCat s) ->
              let nf = normalize (sSem s)
                  (d, postTrace) = bePostDRS be s (toDRS (beProvIndex be s) (sProv s) nf)
              in (Just nf, Just d, beNotes be s <> postTrace)
        Right t ->
          ( Nothing
          , Nothing
          , flag
              Diagnostic
                { diagKind = TypeCheckFailure
                , diagMsg =
                    "meaning has type " ++ show t ++ " but category "
                      ++ show (sCat s) ++ " demands " ++ show (catTy (sCat s))
                , diagProv = sProv s
                }
          )
        Left err ->
          ( Nothing
          , Nothing
          , flag
              Diagnostic
                { diagKind = TypeCheckFailure
                , diagMsg = renderTypeError err
                , diagProv = sProv s
                }
          )

--------------------------------------------------------------------------------
-- Ambiguity detection
--------------------------------------------------------------------------------

-- | Flag runs of two or more stacked @N\/N@ modifiers before a noun.
--
-- __The heuristic, stated explicitly:__ two or more adjacent modifier-capable
-- words immediately preceding a noun-capable word. That is all. It over-triggers
-- on genuinely iterated intersection (@"old red book"@ really is intersective)
-- and it says nothing about /which/ modifier fuses with the noun.
--
-- Both limitations are intended. The job here is to localize where the ambiguity
-- lives, not to resolve it — resolution needs graded similarity judgements, which
-- is Stage 2's DisCoCat\/kernel work. A flag that is sometimes a false positive is
-- useful; a silent wrong answer is not.
detectCoupling :: Lexicon -> SourceId -> [Token] -> [Diagnostic]
detectCoupling lexicon src = go
  where
    isMod = isModifierWord lexicon . tokText
    isNoun t = not (null (entriesWithCat lexicon N (tokText t)))

    go [] = []
    go ts = case span isMod ts of
      ([], _ : rest) -> go rest
      ([], [])       -> []
      (mods, rest)
        | length mods >= 2, (hd : tl) <- rest, isNoun hd ->
            diag mods hd : go tl
        | otherwise -> go rest

    diag mods headNoun =
      Diagnostic
        { diagKind = ModifierCoupling
        , diagMsg =
            show (length mods) ++ " stacked modifiers ["
              ++ intercalate ", " (map tokText mods) ++ "] on "
              ++ show (tokText headNoun)
              ++ ": read as iterated intersection; may be a fused subkind"
        , diagProv =
            provRule "modifier-stack"
              [ProvLex src (tokSpan t) (tokText t) | t <- mods ++ [headNoun]]
        }

--------------------------------------------------------------------------------
-- Reporting
--------------------------------------------------------------------------------

renderSentenceResult :: SentenceResult -> String
renderSentenceResult r =
  unlines $
    [ "sentence " ++ show (sentSpan (srSentence r)) ++ " " ++ show (sentText (srSentence r))
    , "  words:   " ++ unwords (map tokText (srTokens r))
    , "  units:   "
        ++ unwords (map (show . tokText) (M.elems (latUnits (srLattice r))))
    , "  parses:  " ++ show (length (srParses r))
    ]
      ++ [ "  form:    " ++ pretty f | Just f <- [srForm r] ]
      ++ maybe [] (map ("  " ++) . drsBoxLines) (srDRS r)

renderPipelineResult :: PipelineResult -> String
renderPipelineResult p =
  unlines $
    [ "source: " ++ show (prSource p)
    , "text:   " ++ show (prText p)
    , ""
    ]
      ++ map renderSentenceResult (prSentences p)
      ++ [ "-- discourse DRS" ]
      ++ drsBoxLines (dscDRS (prDiscourse p))
      ++ [ ""
         , "-- sources: " ++ intercalate ", " (map show (drsSources (dscDRS (prDiscourse p))))
         , "-- diagnostic kinds: "
             ++ show (sort (nub (map diagKind (traceDiagnostics (prTrace p)))))
         , ""
         , renderTrace (prTrace p)
         ]
