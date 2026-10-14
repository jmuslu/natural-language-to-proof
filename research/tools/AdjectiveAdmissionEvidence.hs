-- Targeted dictionary projection of loadSemModel; never runs a chart/parser.
-- Default is inert. --self-test uses synthetic strings only; --extract DIR needs
-- separate coordinator authorization and the shared CCGbank slot wrapper.
module Main (main) where
import Control.Exception (IOException, try)
import Control.Monad (foldM, unless)
import Data.List (foldl')
import qualified Data.Map.Strict as M
import qualified Data.Set as Set
import System.Environment (getArgs)
import System.Exit (die)
import NL2Proof.Bench.JSON
import NL2Proof.Syntax.CCGBank (CCat,parseCCGCat)
import NL2Proof.Syntax.CCGDeriv (parseAuto,leafHeaders)
import NL2Proof.Syntax.CCGSupertag (leafPairs)
import NL2Proof.Syntax.CCGSemParse (ccgbankTrainFiles)

targets :: [String]
targets = ["hawks","hawk","mammals","mammal","excels","excel",
           "pets","pet","animals","animal","humans","human","frogs","frog"]
wanted = Set.fromList targets
-- No non-target word identities or full lexicon are retained.
data Acc = Acc { cats :: !(M.Map String (M.Map CCat Int)),
                 poses :: !(M.Map String (M.Map String Int)),
                 trees :: !Int, invalid :: !Int, absent :: !Int }
empty = Acc M.empty M.empty 0 0 0
bump w k = M.insertWith (M.unionWith (+)) w (M.singleton k 1)
addLine a l
  | null l || take 3 l == "ID=" = a
  | otherwise = case parseAuto l of
      Left _ -> a {invalid=invalid a+1}
      Right t -> a
        { cats=foldl' (\m (w,c) -> if Set.member w wanted then bump w c m else m)
                      (cats a) (leafPairs t)
        , poses=foldl' (\m (_,p,w) -> if Set.member w wanted then bump w p m else m)
                       (poses a) (leafHeaders l)
        , trees=trees a+1 }
-- Match production file order, readFile exception handling, skip rules and strict
-- file-by-file fold. Category counts use parsed leafPairs; POS counts use raw
-- leafHeaders only AFTER successful parseAuto, exactly as loadSemModel does.
addFile a f = do
  r <- try (readFile f) :: IO (Either IOException String)
  case r of
    Left _ -> pure a {absent=absent a+1}
    Right s -> let a' = foldl' addLine a (lines s) in trees a' `seq` pure a'
num = JNum . fromIntegral
counts f m = JArr [JObj [("value",JStr (f k)),("count",num n)] | (k,n)<-M.toAscList m]
emit a = renderJSON $ JObj
  [ ("schema",num (1::Int)),("contract",JStr "loadSemModel-target-dictionary-projection-v1")
  , ("training_sections",JStr "02-21; ccgbankTrainFiles enumeration")
  , ("accepted_trees",num (trees a)),("invalid_nonheader_lines",num (invalid a))
  , ("unreadable_files",num (absent a)),("targets",JArr [entry w | w<-targets]) ]
  where
    entry w = JObj [("lookup_form",JStr w),
      ("own_categories",counts show (M.findWithDefault M.empty w (cats a))),
      ("pos_support_counts",counts id (M.findWithDefault M.empty w (poses a)))]

-- Independent expected counts: casing, POS-field choice, malformed lines and
-- duplicate occurrences matter. This is not a licensed corpus fixture.
selfTest = do
  let leaf c p q w = "(<L "++c++" "++p++" "++q++" "++w++" "++c++">)"
      n = either error id (parseCCGCat "N")
      ad = either error id (parseCCGCat "S[adj]\\NP")
      fixture = ["", "ID=synthetic",leaf "N" "NNS" "JJ" "hawks",
        leaf "N" "NNS" "JJ" "hawks",leaf "N" "NN" "NN" "hawk",
        leaf "S[adj]\\NP" "JJ" "NN" "hawks",leaf "N" "NNS" "NNS" "Hawks",
        leaf "N" "NN" "NN" "unrelated", "(<L N NNS NNS hawks N>",
        leaf "/" "VBZ" "JJ" "excels"]
      a = foldl' addLine empty fixture
      checks =
        [ ("duplicate target category counts", M.lookup "hawks" (cats a)==Just (M.fromList [(n,2),(ad,1)]))
        , ("modified POS field; preserve mixed support", M.lookup "hawks" (poses a)==Just (M.fromList [("NNS",2),("JJ",1)]))
        , ("base counted separately", M.lookup "hawk" (poses a)==Just (M.singleton "NN" 1))
        , ("case sensitive target restriction", M.notMember "Hawks" (cats a))
        , ("non-target not retained", M.notMember "unrelated" (cats a))
        , ("malformed tree does not contribute", invalid a==1)
        , ("invalid category retains POS on valid AUTO tree", M.notMember "excels" (cats a) && M.lookup "excels" (poses a)==Just (M.singleton "VBZ" 1))
        , ("successful AUTO trees counted including non-target", trees a==7)
        , ("production enumeration boundaries", let fs=ccgbankTrainFiles "synthetic" in length fs==2000 && head fs=="synthetic/AUTO/02/wsj_0200.auto" && last fs=="synthetic/AUTO/21/wsj_2199.auto")
        , ("absent target explicit in JSON", case parseJSON (emit a) >>= maybe (Left "targets absent") Right . field "targets" of
            Right (JArr entries) -> length entries==14 && any (\e -> field "lookup_form" e==Just (JStr "mammals") && field "own_categories" e==Just (JArr []) && field "pos_support_counts" e==Just (JArr [])) entries
            _ -> False) ]
  mapM_ (\(label,ok) -> putStrLn ((if ok then "ok " else "FAIL ")++label)) checks
  unless (all snd checks) (die "synthetic evidence contract failed")
  putStrLn "10 synthetic checks passed; no corpus loaded"
main = do
  args <- getArgs
  case args of
    ["--self-test"] -> selfTest
    ["--paths",dir] -> putStrLn (renderJSON (JArr (map JStr (ccgbankTrainFiles dir))))
    ["--extract",dir] -> foldM addFile empty (ccgbankTrainFiles dir) >>= putStrLn . emit
    _ -> die "Usage: AdjectiveAdmissionEvidence --self-test | --paths DIR | --extract CCGbank_DATA_DIR (separate authorization required)"
