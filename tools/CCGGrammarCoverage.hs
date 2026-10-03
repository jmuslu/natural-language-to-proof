-- | Measure the CCG combinatory rule set ('NL2Proof.Syntax.CCGRules') against
-- CCGbank's own @GRAMMAR@ file: 3,471 attested @parent --> children@ rule
-- instances. This is the external check on the rules and the unification policy
-- — the corpus, not the system's own metric, decides whether a rule is right.
--
-- For each __binary__ rule @parent --> l r@, we ask whether @combine l r@
-- licenses a category that unifies with the attested @parent@. Coverage is
-- reported two ways, kept separate:
--
--   * __unify-coverage__: a produced category unifies with @parent@ (absorbs
--     CCGbank's feature under-specification, e.g. a produced @NP[nb]@ counts for
--     an attested @NP@).
--   * __exact-coverage__: a produced category equals @parent@ structurally.
--
-- __Unary__ rules (type-changing / type-raising / the @TOP@ root rule) are a
-- different mechanism, not binary combination; they are counted and reported
-- separately, never folded into the binary coverage number.
--
-- Everything is weighted both by distinct rule types and by corpus frequency
-- (the count in column 1), so a high type-coverage that misses frequent rules
-- cannot hide behind the average.
--
-- Usage: @ccg-grammar-coverage [PATH]@ (defaults to the 00-24 grammar).
module Main (main) where

import Data.List (foldl', isInfixOf, sortBy)
import qualified Data.Map.Strict as M
import Data.Ord (comparing, Down(..))
import System.Environment (getArgs, lookupEnv)
import System.IO (hPutStrLn, stderr)

import NL2Proof.Syntax.CCGBank (parseCCGCat)
import NL2Proof.Syntax.CCGRules (combineNamed, unifiable, allCombinators, Combinator)

-- | Default input: @$CCGBANK_DIR@ if set, else @$HOME/ccgbank/ccgbank_1_1/data@.
defaultPath :: IO FilePath
defaultPath = do
  dir  <- lookupEnv "CCGBANK_DIR"
  home <- lookupEnv "HOME"
  let base = maybe (maybe "." id home ++ "/ccgbank/ccgbank_1_1/data") id dir
  pure (base ++ "/GRAMMAR/CCGbank.00-24.grammar")

-- | (frequency, parent, children).
data Rule = Rule Int String [String]

parseRule :: String -> Maybe Rule
parseRule line = case words line of
  (cntS : "#" : rest) -> case break (== "-->") rest of
    (parentToks, "-->" : childToks)
      | [p] <- parentToks
      , not (null childToks)
      , [(cnt, "")] <- reads cntS -> Just (Rule cnt p childToks)
    _ -> Nothing
  _ -> Nothing

data Acc = Acc
  { aBinTypes    :: !Int, aBinFreq    :: !Int
  , aUniqTypes   :: !Int, aUniqFreq   :: !Int   -- unify-covered
  , aExactTypes  :: !Int, aExactFreq  :: !Int   -- exact-covered
  , aUnaryTypes  :: !Int, aUnaryFreq  :: !Int
  , aParseFail   :: !Int
  , aNonTrailCj  :: !Int
  , aByComb      :: M.Map Combinator Int         -- covered rule types per combinator
  , aUncovered   :: [(Int, String, String, String)]  -- freq, parent, l, r
  }

emptyAcc :: Acc
emptyAcc = Acc 0 0 0 0 0 0 0 0 0 0 M.empty []

-- | @[conj]@ present but not as the final characters of the string.
nonTrailingConj :: String -> Bool
nonTrailingConj s = "[conj]" `isInfixOf` s && not (endsWith "[conj]" s)
  where endsWith suf x = take (length suf) (reverse x) == reverse suf

step :: Acc -> Rule -> Acc
step acc (Rule cnt parent children) =
  let cjHit = length (filter nonTrailingConj (parent : children))
      acc0  = acc { aNonTrailCj = aNonTrailCj acc + cjHit }
  in case children of
       [_] -> acc0 { aUnaryTypes = aUnaryTypes acc0 + 1
                   , aUnaryFreq  = aUnaryFreq acc0 + cnt }
       [ls, rs] ->
         let acc1 = acc0 { aBinTypes = aBinTypes acc0 + 1
                         , aBinFreq  = aBinFreq acc0 + cnt }
         in case (parseCCGCat parent, parseCCGCat ls, parseCCGCat rs) of
              (Right p, Right l, Right r) ->
                let produced = combineNamed allCombinators l r
                    hits     = [ c | (c, out) <- produced, unifiable p out ]
                    exact    = any (\(_, out) -> out == p) produced
                    acc2 = if not (null hits)
                             then acc1 { aUniqTypes = aUniqTypes acc1 + 1
                                       , aUniqFreq  = aUniqFreq acc1 + cnt
                                       , aByComb    = foldr (\c -> M.insertWith (+) c 1)
                                                            (aByComb acc1) (dedup hits) }
                             else acc1 { aUncovered =
                                           insertTop (cnt, parent, ls, rs) (aUncovered acc1) }
                    acc3 = if exact
                             then acc2 { aExactTypes = aExactTypes acc2 + 1
                                       , aExactFreq  = aExactFreq acc2 + cnt }
                             else acc2
                in acc3
              _ -> acc1 { aParseFail = aParseFail acc1 + 1
                        , aUncovered = insertTop (cnt, parent, ls, rs) (aUncovered acc1) }
       _ -> acc0  -- shouldn't happen: CCGbank rules are unary or binary
  where
    dedup = M.keys . M.fromList . map (\c -> (c, ()))

-- | Keep the highest-frequency uncovered rules (bounded list).
insertTop :: (Int, String, String, String) -> [(Int, String, String, String)]
          -> [(Int, String, String, String)]
insertTop x xs = take 20 (sortBy (comparing (Down . fst4)) (x : xs))
  where fst4 (a, _, _, _) = a

pct :: Int -> Int -> String
pct _ 0 = "n/a"
pct k tot =
  let tenths = round (1000 * fromIntegral k / fromIntegral tot :: Double) :: Int
  in show (fromIntegral tenths / 10 :: Double) ++ "%"

main :: IO ()
main = do
  args <- getArgs
  path <- case args of (p : _) -> pure p; [] -> defaultPath
  contents <- readFile path
  let rules = [ r | Just r <- map parseRule (lines contents) ]
      a     = foldl' step emptyAcc rules
  hPutStrLn stderr ("read " ++ show (length rules) ++ " grammar rules from " ++ path)
  putStrLn "== CCG rule-set coverage against CCGbank GRAMMAR (external check) =="
  putStrLn ("source : " ++ path)
  putStrLn ""
  putStrLn ("binary rules : " ++ show (aBinTypes a) ++ " types, "
            ++ show (aBinFreq a) ++ " corpus occurrences")
  putStrLn ("unary  rules : " ++ show (aUnaryTypes a) ++ " types, "
            ++ show (aUnaryFreq a)
            ++ " occurrences  (type-changing / type-raising / TOP; reported separately)")
  putStrLn ""
  putStrLn "coverage of BINARY rules by the combinator set:"
  putStrLn ("  unify-coverage : " ++ show (aUniqTypes a) ++ "/" ++ show (aBinTypes a)
            ++ " types (" ++ pct (aUniqTypes a) (aBinTypes a) ++ "), "
            ++ pct (aUniqFreq a) (aBinFreq a) ++ " of binary occurrences")
  putStrLn ("  exact-coverage : " ++ show (aExactTypes a) ++ "/" ++ show (aBinTypes a)
            ++ " types (" ++ pct (aExactTypes a) (aBinTypes a) ++ "), "
            ++ pct (aExactFreq a) (aBinFreq a) ++ " of binary occurrences")
  putStrLn ("  parse failures : " ++ show (aParseFail a))
  putStrLn ""
  putStrLn "covered binary rule types, by combinator that licensed them:"
  mapM_ (\(c, n) -> putStrLn ("  " ++ pad 12 (show c) ++ show n))
        (sortBy (comparing (Down . snd)) (M.toList (aByComb a)))
  putStrLn ""
  putStrLn ("non-trailing [conj] categories (parser-assumption check): "
            ++ show (aNonTrailCj a))
  putStrLn ""
  putStrLn "top uncovered binary rules by frequency:"
  mapM_ (\(f, p, l, r) -> putStrLn ("  " ++ pad 8 (show f) ++ p ++ " --> " ++ l ++ " " ++ r))
        (aUncovered a)
  where
    pad n s = s ++ replicate (max 1 (n - length s)) ' '
