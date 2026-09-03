-- | Are the glue-logic cue weights disposable, or quietly load-bearing?
--
-- ARCHITECTURE.md and 'NL2Proof.Stage2.SDRT.cueWeight' both label the numbers
-- __stipulated__: the structure is claimed to be real and the constants a guess
-- that a corpus would replace. That is a claim about /robustness to the
-- constants/, and it had not been measured.
--
-- What matters is not whether the argmax relation moves. It is whether the
-- argmax's __kind__ moves, because 'NL2Proof.Stage2.SDRT.relationKind' is what
-- decides the right frontier, and the frontier decides which referents a later
-- pronoun can reach. A flip inside one kind reorders a label; a flip across
-- kinds changes accessibility, which is a structural outcome.
--
-- Since @score r = product [cueWeight c r | c <- cues] * base r@ is
-- multiplicative in the weights, the margin is read directly: to overturn the
-- winner by scaling a single cue weight, that factor must exceed the ratio of
-- the winner's score to the challenger's. So the reported ratio /is/ the
-- perturbation threshold, exactly, with no sampling.
--
-- Run: @runghc -isrc docs/cue-weight-sensitivity.hs@
module Main (main) where

import Data.List (sortBy)
import Data.Maybe (fromMaybe)
import Data.Ord (comparing)

import NL2Proof.DRT.Types
import NL2Proof.Pipeline
import NL2Proof.Provenance
import NL2Proof.Stage2.Distribution
import NL2Proof.Stage2.SDRT
import NL2Proof.Syntax.Tokenize (tokText)

main :: IO ()
main = do
  putStrLn "cue-weight sensitivity: how far can a stipulated number move"
  putStrLn "before the argmax's KIND changes, and accessibility with it?"
  putStrLn ""
  mapM_ report texts
  putStrLn "Read the last column as the multiplicative perturbation of a single"
  putStrLn "cue weight needed to change the relation's kind. inf means no"
  putStrLn "challenger of the other kind has positive mass."

texts :: [String]
texts =
  [ "A student arrived. She smiles."
  , "A student arrived. A professor walks. Mary smiles."
  , "Every student reads a book. Mary smiles."
  , "John loves Mary. Mary smiles."
  , "A student arrived. A student arrived."
  ]

report :: String -> IO ()
report txt = do
  putStrLn ("text: " ++ show txt)
  case unitsOf txt of
    us@(_ : _ : _) ->
      mapM_ edge (zip us (drop 1 us))
    _ -> putStrLn "  (fewer than two units; nothing to glue)"
  putStrLn ""
  where
    edge (a, b) = case glue a b of
      Nothing -> putStrLn "  no distribution"
      Just d ->
        let rs = sortBy (comparing (negate . snd)) (toPairs d)
            (top, topMass) = head rs
            k = relationKind top
            others = [(r, m) | (r, m) <- rs, relationKind r /= k, m > 0]
            second = case drop 1 rs of
              ((_, m) : _) -> m
              []           -> 0
        in do
             putStrLn
               ( "  " ++ pad 22 (unwords (map short (detectCues a b)))
                   ++ pad 14 (show top)
                   ++ pad 16 (show k)
                   ++ "top/2nd " ++ pad 8 (ratio topMass second)
                   ++ "kind flip needs x" ++ ratio topMass (bestOf others)
               )

    bestOf [] = 0
    bestOf xs = maximum (map snd xs)

    ratio _ 0 = "inf"
    ratio p q = trim (show (p / q))

    trim r = case break (== '.') r of
      (whole, '.' : frac) -> whole ++ '.' : take 2 frac
      _                   -> r

    pad n str = str ++ replicate (max 1 (n - length str)) ' '

    short (Connective w)      = "conn:" ++ w
    short GenericThenSpecific = "generic>specific"
    short (SharedPredicate p) = "shared:" ++ p
    short NewReferent         = "newref"

-- | One discourse unit per sentence that produced a DRS.
--
-- Deliberately not routed through 'NL2Proof.Stage2.Threading.threadDiscourse':
-- the cues this probe perturbs are detected from the sentence-local DRSs and the
-- word lists, none of which threading changes. Referent freshening would matter
-- for accessibility and does not matter for cue detection.
unitsOf :: String -> [DiscourseUnit]
unitsOf txt =
  [ DiscourseUnit (Label i) (fromMaybe emptyDRS (srDRS r)) (map tokText (srTokens r))
  | (i, r) <- zip [0 ..] (prSentences (runFragment (SourceId "probe") txt))
  ]
