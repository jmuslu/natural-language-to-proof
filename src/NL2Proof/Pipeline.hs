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
module NL2Proof.Pipeline
  ( -- * Results
    SentenceResult(..)
  , PipelineResult(..)
    -- * Running
  , runPipeline
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
import NL2Proof.Semantics.Lambda
import NL2Proof.Syntax.CCG
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

-- | Run the fragment lexicon over a text.
runFragment :: SourceId -> String -> PipelineResult
runFragment = runPipeline fragmentLexicon

runPipeline :: Lexicon -> SourceId -> String -> PipelineResult
runPipeline lexicon src text =
  PipelineResult
    { prSource = src
    , prText = text
    , prSentences = results
    , prDiscourse = discourse
    , prSelection = selection
    , prTrace = foldMap srTrace results <> dscTrace discourse
    }
  where
    results = map (processSentence lexicon src) (splitSentences text)

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

processSentence :: Lexicon -> SourceId -> Sentence -> SentenceResult
processSentence lexicon src sent =
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
        unknownTrace <> segTrace <> couplingTrace <> parseTrace <> typeTrace
    }
  where
    lat = sentenceLattice (inLexicon lexicon) (maxPhraseLength lexicon) sent
    toks = latRaw lat
    unknown = uncoveredTokens lat

    unknownTrace =
      foldMap
        (\t ->
           flag
             Diagnostic
               { diagKind = NoParse
               , diagMsg = "unknown word: " ++ show (tokText t)
               , diagProv = ProvLex src (tokSpan t) (tokText t)
               })
        unknown

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

    sentProvFallback = provRule "sentence" [ProvLex src (sentSpan sent) (sentText sent)]

    -- Search produced a candidate set; here is where it collapses, out loud.
    (chosen, parseTrace) = case parses of
      [] ->
        ( Nothing
        , if null unknown
            then
              flag
                Diagnostic
                  { diagKind = NoParse
                  , diagMsg = "no derivation to S for " ++ show (sentText sent)
                  , diagProv = sentProvFallback
                  }
            else mempty -- already reported as unknown words
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
                , decWhy =
                    "first derivation in CKY enumeration order; a positional"
                      ++ " tie-break, not a linguistic one"
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
                  idx = buildProvIndex lexicon (sProv s)
              in (Just nf, Just (toDRS idx (sProv s) nf), mempty)
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
