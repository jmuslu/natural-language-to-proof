-- | Stage 1 demo: run the fragment's evaluation set and print everything the
-- pipeline produced, including the parts it is unsure about.
module Main (main) where

import NL2Proof.Collapse.Class
import NL2Proof.DRT.Build
import NL2Proof.DRT.Types
import NL2Proof.Fragment
import NL2Proof.Pipeline
import NL2Proof.Provenance
import NL2Proof.Semantics.Lambda
import NL2Proof.Syntax.Tokenize
import NL2Proof.Trace

main :: IO ()
main = do
  putStrLn "natural-language-to-proof :: Stage 1 (discrete semantic core)"
  putStrLn "branch `main` -- shared core, no collapse backend"
  mapM_ demo fragmentCases
  putStrLn (replicate 78 '=')
  putStrLn "Collapse backends live on the mode branches:"
  putStrLn "  truth-mode      -> NL2Proof.Collapse.Truth"
  putStrLn "  provenance-mode -> NL2Proof.Collapse.Provenance"

demo :: FragmentCase -> IO ()
demo c = do
  putStrLn ""
  putStrLn (replicate 78 '=')
  putStrLn (caseId c ++ "  [" ++ caseKind c ++ "]")
  putStrLn (replicate 78 '-')
  putStrLn ("text: " ++ show (caseText c))
  putStrLn ""

  let res = runFragment (SourceId "demo") (caseText c)

  mapM_ showSentence (prSentences res)

  putStrLn "discourse DRS (after anaphora resolution):"
  putStr (unlines (map ("  " ++) (drsBoxLines (dscDRS (prDiscourse res)))))

  case prSelection res of
    Nothing -> putStrLn "selection: none (nothing parsed)"
    Just sel -> do
      putStrLn
        ( "selection: " ++ show (selectionCandidateCount sel)
            ++ " candidate(s), " ++ selRationale sel
        )
      putStrLn ("  sources: " ++ show (selectionSources sel))
      putStrLn ("  spans:   " ++ show (selectionSpans sel))

  putStrLn ""
  putStr (renderTrace (prTrace res))
  putStrLn ("note: " ++ caseNotes c)

showSentence :: SentenceResult -> IO ()
showSentence r = do
  putStrLn
    ( "  [" ++ show (sentSpan (srSentence r)) ++ "] tokens: "
        ++ unwords (map tokText (srTokens r))
    )
  putStrLn ("      derivations: " ++ show (length (srParses r)))
  case srForm r of
    Nothing -> putStrLn "      form: <none>"
    Just f  -> putStrLn ("      form: " ++ pretty f)
  case srDRS r of
    Nothing -> pure ()
    Just d ->
      putStrLn
        ( "      conditions: " ++ show (length (drsConds d))
            ++ ", referents: " ++ show (length (drsUniverse d))
        )
  -- One condition's full how-provenance, to show what is being carried.
  case srDRS r >>= firstCondProv of
    Nothing -> pure ()
    Just p  -> putStrLn ("      provenance of first condition: " ++ renderProvInline p)
  where
    firstCondProv d = case drsConditionProvs d of
      (p : _) -> Just p
      []      -> Nothing
