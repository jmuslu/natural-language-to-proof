-- | Hand-authored regressions for real-text CCG seams. No corpus data is used.
module Main (main) where

import Data.List (isInfixOf)
import qualified Data.Map as M
import qualified Data.Set as Set
import System.Environment (getArgs)

import Harness
import NL2Proof.Pipeline
import NL2Proof.Provenance
import NL2Proof.Semantics.CCGSem
import NL2Proof.Semantics.Lambda
import NL2Proof.Syntax.CCGBank (CCat, parseCCGCat)
import NL2Proof.Syntax.CCGParse (Rules(..))
import NL2Proof.Syntax.CCGSemParse
import NL2Proof.Syntax.CCGRules
import NL2Proof.Syntax.CCGSupertag (TagModel(..), buildPOSModel, buildTagModel)
import NL2Proof.Syntax.Tokenize (casedTokens)
import NL2Proof.Trace

main :: IO ()
main = do
  args <- getArgs
  if args == ["--corpus"]
    then do
      dir <- ccgbankDataDir
      (m, _) <- loadSemModel dir
      runChecks "semantic-repair-corpus" (corpusChecks m)
    else runChecks "semantic-repair" checks

cc :: String -> CCat
cc = either error id . parseCCGCat

mini :: SemModel
mini = (defaultSemModel tm pm rs Set.empty) { smAlpha = 0, smSeenRules = False }
  where
    obs =
      [ ("the", "NP[nb]/N"), ("every", "NP[nb]/N"), ("a", "NP[nb]/N")
      , ("cat", "N"), ("dog", "N"), ("Bob", "N"), ("Anne", "N")
      , ("is", "(S[dcl]\\NP)/(S[adj]\\NP)")
      , ("red", "S[adj]\\NP"), ("big", "S[adj]\\NP")
      , ("not", "(S\\NP)\\(S\\NP)")
      , ("likes", "(S[dcl]\\NP)/NP"), ("hates", "(S[dcl]\\NP)/NP")
      , ("that", "(N\\N)/(S[dcl]\\NP)")
      , ("which", "(NP\\NP)/(S[dcl]\\NP)")
      , ("who", "(N\\N)/(S[dcl]\\NP)")
      , ("that", "S[em]/S[dcl]")
      , ("added", "(S[dcl]\\NP)/S[em]")
      , ("adds", "(S[dcl]\\NP)/S[dcl]")
      , ("sees", "(S[dcl]\\NP)/S[em]")
      , ("boasted", "(S[adj]\\NP)/NP")
      , ("round", "N/N"), ("kind", "N/N")
      , ("and", "conj"), (",", ","), (".", ".") ]
    tm = buildTagModel [(w, cc c) | (w,c) <- obs]
    pm = buildPOSModel [(w, pos w) | (w,_) <- obs]
    pos w | w `elem` ["Bob", "Anne"] = "NNP"
          | w `elem` ["boasted", "added"] = "VBD"
          | w `elem` ["round", "kind"] = "JJ"
          | otherwise = "XX"
    rs = Rules [(cc "N",cc "NP"), (cc "NP",cc "S/(S\\NP)")] []

run :: SemModel -> String -> SentenceResult
run m txt = case prSentences (runPipelineWith (CCGBankParser m) (SourceId "repair") txt) of
  [r] -> r
  _ -> error "expected one sentence"

expectForm :: String -> String -> Term -> Check
expectForm label txt expected = case srForm (run mini txt) of
  Just actual | canonicalAC actual == canonicalAC expected -> ok label
              | otherwise -> bad label (pretty actual)
  Nothing -> bad label "no meaning"

predX :: String -> Term
predX p = App (pred1 p) (Var "x")

theCat :: Term
theCat = iota (Lam "x" TyE (predX "cat"))

checks :: [Check]
checks =
  [ expectForm "subject relative restricts universal domain" "Every cat that is red is big."
      (TForall "x" TyE (TImp (TAnd (predX "cat") (predX "red")) (predX "big")))
  , expectForm "NP-tagged which is safely reanalysed below determiner" "Every cat which is red is big."
      (TForall "x" TyE (TImp (TAnd (predX "cat") (predX "red")) (predX "big")))
  , expectForm "who has restrictive subject-relative meaning" "Every cat who is red is big."
      (TForall "x" TyE (TImp (TAnd (predX "cat") (predX "red")) (predX "big")))
  , expectForm "relative also restricts existential" "A cat that is red is big."
      (TExists "x" TyE (TAnd (TAnd (predX "cat") (predX "red")) (predX "big")))
  , expectForm "argument-cluster coordination" "Bob likes and Anne hates the cat."
      (TAnd (apply (pred2 "like") [entity "Bob",theCat])
            (apply (pred2 "hate") [entity "Anne",theCat]))
  , expectForm "coordinated object is one shared existential" "Bob likes and Anne hates a cat."
      (TExists "x" TyE (TAnd (predX "cat")
        (TAnd (apply (pred2 "like") [entity "Bob",Var "x"])
              (apply (pred2 "hate") [entity "Anne",Var "x"]))))
  , expect "crossed composition retains declarative feature"
      ((BwdXComp,cc "(S[dcl]\\NP)/(S[adj]\\NP)") `elem`
         combineNamed allCombinators (cc "(S[dcl]\\NP)/(S[adj]\\NP)") (cc "(S\\NP)\\(S\\NP)"))
  , expectEq "modifier application retains declarative feature"
      [(FwdApp,cc "S[dcl]")]
      (combineNamed [FwdApp] (cc "S/S") (cc "S[dcl]"))
  , expect "feature preservation never conflates em and dcl"
      (null (combineNamed [FwdApp] (cc "S[dcl]/S[dcl]") (cc "S[em]")))
  , expectEq "added normalizes to add" "add" (reportingLemma "Added")
  , expectEq "noted normalizes to note" "note" (reportingLemma "noted")
  , expect "normalized attestation is shared by past and present"
      ("add" `Set.member` smThatAttested mini && srForm (run mini "Bob adds the cat is red.") /= Nothing)
  , expect "see sense ambiguity remains nonassertive and logged"
      ("see-sense" `elem` map decKind (traceDecisions (srTrace (run mini "Bob sees that the cat is red."))))
  , expect "inverted quotation cannot assert its content through a spurious adjective tag"
      (null (spRoots (semParse mini (SourceId "quote") (casedTokens 0 "The cat is red, boasted Bob."))))
  , expect "ordinary and-coordination remains supported"
      (srForm (run mini "The cat is red and big.") /= Nothing)
  , expect "backoff is absent by default"
      (srForm (run mini "The cat is round.") == Nothing)
  , expect "all closed entries remain category-typed"
      (and [Just (typeOf [] t) == fmap Right (semTy c) | (_,c,LexTerm t _ _) <- closedTable 0])
  , expect "coordination trace records type raising"
      (any (isInfixOf "raising" . decKind) (traceDecisions (srTrace (run mini "Bob likes and Anne hates the cat."))))
  , expect "POS backoff repairs dictionary-attested JJ adjectives when enabled"
      (and [srForm (run (mini {smPOSBackoff = True}) ("The cat is " ++ w ++ ".")) /= Nothing
           | w <- ["round", "kind"]])
  , expect "selected POS backoff is a logged decision"
      ("pos-backoff" `elem` map decKind (traceDecisions (srTrace
        (run (mini {smPOSBackoff = True}) "The cat is round."))))
  , expect "backoff does not invent adjective POS for a known nonadjective"
      (not (any ((== cc "S[adj]\\NP") . lxCat) (lexicalSigns (mini {smPOSBackoff = True}) 3 "cat")))
  , expect "unsupported inflections stay unchanged rather than guessed"
      (verbLemma "bed" == "bed" && verbLemma "hoped" == "hoped" && verbLemma "hopped" == "hopped")
  , expect "quote rejection records the discarded asserted meaning"
      (case traceDecisions (spTrace (semParse mini (SourceId "quote") (casedTokens 0 "The cat is red, boasted Bob."))) of
         [d] -> decKind d == "quote-safety" && not (null (decAlternatives d))
         _ -> False)
  , expect "quote guard preserves an available safe attribution"
      (let tm = smTags mini
           safe = mini {smTags = tm {tmWord = M.insertWith (++) "boasted"
                          [(cc "(S[dcl]\\S[dcl])/NP",1)] (tmWord tm)}}
           roots = spRoots (semParse safe (SourceId "quote") (casedTokens 0 "The cat is red, boasted Bob."))
       in not (null roots) && all (isInfixOf "boast(Bob" . pretty . ssSem) roots)
  , expect "nonrestrictive punctuation cannot be silently read restrictively"
      (srForm (run mini "Every cat, which is red, is big.") == Nothing)
  , expectForm "negated subject relative stays inside universal restriction"
      "Every cat that is not red is big."
      (TForall "x" TyE (TImp (TAnd (predX "cat") (TNot (predX "red"))) (predX "big")))
  , expect "inverted quotation with definite speaker fails closed"
      (srForm (run mini "The cat is red, boasted the dog.") == Nothing)
  , expect "forward quotation suffix cannot become independent assertions"
      (let tm = smTags mini
           m = mini {smTags = tm {tmWord = M.insertWith (++) "boasted"
                        [(cc "S[dcl]\\NP",1)] (tmWord tm)}}
       in all ((== Nothing) . srForm . run m)
            ["The cat is red, Bob boasted.", "The cat is red, the dog boasted."])
  , expectForm "ordinary comma adjective coordination survives quote guard"
      "The cat is red, big."
      (TAnd (App (pred1 "red") theCat) (App (pred1 "big") theCat))
  ]

-- Optional integration checks against the local licensed model. Only these
-- handwritten sentences and aggregate checks are printed or committed.
corpusChecks :: SemModel -> [Check]
corpusChecks m =
  [ correct "corpus restrictive relative" "Every cat that is red is big."
      (TForall "x" TyE (TImp (TAnd (predX "cat") (predX "red")) (predX "big")))
  , correct "corpus argument-cluster coordination" "Bob likes and Anne hates the cat."
      (TAnd (apply (pred2 "like") [entity "Bob",theCat])
            (apply (pred2 "hate") [entity "Anne",theCat]))
  , expect "corpus inverted quotation fails closed"
      (let rs = spRoots (semParse m (SourceId "corpus") (casedTokens 0 "The cat is red, boasted Bob."))
       in all (isInfixOf "boast(Bob" . pretty . ssSem) rs)
  , expect "corpus sees-that now has an attributed reading"
      (maybe False (isInfixOf "see(Bob" . pretty) (srForm (run m "Bob sees that the cat is red.")))
  , expect "corpus sees-that logs sense ambiguity"
      ("see-sense" `elem` map decKind (traceDecisions (srTrace (run m "Bob sees that the cat is red."))))
  , expect "corpus added uses normalized lemma"
      (maybe False (isInfixOf "add(Bob" . pretty) (srForm (run m "Bob added that the cat is red.")))
  , expect "corpus adjective backoff repairs round with attested JJ evidence"
      (srForm (run (m {smPOSBackoff = True}) "The cat is round.") /= Nothing)
  , expect "corpus kind has no JJ evidence and conservatively remains unsupported"
      (srForm (run (m {smPOSBackoff = True}) "The cat is kind.") == Nothing)
  ]
  where
    correct label txt expected = case srForm (run m txt) of
      Just actual | canonicalAC actual == canonicalAC expected -> ok label
                  | otherwise -> bad label (pretty actual)
      Nothing -> bad label "no meaning"
