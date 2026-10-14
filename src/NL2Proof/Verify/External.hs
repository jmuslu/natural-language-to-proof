-- | External validation receipts enter the existing oracle/fusion/reward seam.
--
-- This adapter settles only @passes_validation(run_id)@. A backtest certificate
-- does not establish every source claim a strategy cites. The producing process
-- is responsible for checking the measurements before exporting a receipt.
--
-- Receipts are a local trust boundary, not cryptographic authentication. The
-- evidence id links back to the checked artifact; this module does not fetch it,
-- execute content, reinterpret natural language, or turn missing coverage false.
module NL2Proof.Verify.External
  ( ReceiptBook
  , parseReceipts
  , receiptHeader
  , validIdentifier
  , validationClaim
  , receiptOracle
  , Evaluation(..)
  , evaluateReceipts
  , renderEvaluation
  ) where

import Control.Monad (foldM)
import Data.Char (isAscii, isAlphaNum)
import Data.List (intercalate, nub)
import qualified Data.Map.Strict as M

import NL2Proof.DRT.Canonical
import NL2Proof.DRT.Types
import NL2Proof.Fusion
import NL2Proof.Genealogy
import NL2Proof.Provenance
import NL2Proof.Reward
import NL2Proof.Verify.Claims
import NL2Proof.Verify.Oracle

-- Constructors stay private; parsing validates the complete snapshot first.
data Receipt = Receipt Verdict String
newtype ReceiptBook = ReceiptBook (M.Map String Receipt)

receiptHeader :: String
receiptHeader = "run_id\tverdict\tevidence_id"

validIdentifier :: String -> Bool
validIdentifier [] = False
validIdentifier s@(x : _) =
  length s <= 256 && alnum x && all allowed s
  where
    alnum c = isAscii c && isAlphaNum c
    allowed c = alnum c || c `elem` "._:-"

-- | Exact three-column TSV. CRLF is accepted, whitespace is not trimmed.
-- Duplicate run ids, including identical replays, invalidate the snapshot.
-- Header-only snapshots are valid and cover nothing.
parseReceipts :: String -> Either String ReceiptBook
parseReceipts input = case map stripCR (lines input) of
  [] -> Left "missing receipt header"
  h : rows
    | h /= receiptHeader -> Left "invalid receipt header"
    | otherwise -> ReceiptBook <$> foldM add M.empty (zip [2 :: Int ..] rows)
  where
    stripCR s = case reverse s of
      '\r' : rest -> reverse rest
      _ -> s
    add acc (lineNo, row) = case splitTabs row of
      [runId, verdictText, evidenceId]
        | not (validIdentifier runId) -> err "invalid run_id"
        | M.member runId acc -> err "duplicate run_id"
        | otherwise -> do
            verdict <- case verdictText of
              "confirmed" -> Right Confirmed
              "refuted" -> Right Refuted
              "unknown" -> Right Unknown
              _ -> err "invalid verdict"
            if validIdentifier evidenceId || (verdict == Unknown && evidenceId == "-")
              then Right (M.insert runId (Receipt verdict evidenceId) acc)
              else err "invalid or missing evidence_id"
      _ -> err "expected exactly three TSV columns"
      where
        err why = Left ("receipt line " ++ show lineNo ++ ": " ++ why)

splitTabs :: String -> [String]
splitTabs s = case break (== '\t') s of
  (a, []) -> [a]
  (a, _ : rest) -> a : splitTabs rest

validationClaim :: String -> CanonCond
validationClaim runId = CanPred "passes_validation" [CConstT runId]

lookupClaim :: ReceiptBook -> CanonCond -> Maybe Receipt
lookupClaim (ReceiptBook receipts) (CanPred "passes_validation" [CConstT runId]) =
  M.lookup runId receipts
lookupClaim _ _ = Nothing

-- | Explicit unknown receipts and absent runs both remain outside coverage.
-- A positive oracle function alone cannot bypass the separate coverage gate.
receiptOracle :: ReceiptBook -> Oracle
receiptOracle book = Oracle
  { oracleName = "external-validation-receipts-v1"
  , oracleDomain = "checked passes_validation(run_id) receipts"
  , oracleCovers = \claim -> case lookupClaim book claim of
      Just (Receipt v _) -> v /= Unknown
      Nothing -> False
  , oracleHolds = \claim -> case lookupClaim book claim of
      Just (Receipt Confirmed _) -> True
      _ -> False
  }

data Evaluation = Evaluation
  { evaluationRuns :: [(String, Verdict, Maybe String, Bool)]
  , evaluationFused :: Fused
  , evaluationGenealogy :: Genealogy
  , evaluationReward :: Reward
  }

-- | Offers the requested runs to the real Oracle API. Confirmation tokens flow
-- through 'confirmAll' to 'fuse'; all verdicts flow through 'genealogyOf' to
-- 'score'. No reward is assigned directly from a TSV cell.
evaluateReceipts :: ReceiptBook -> [String] -> Either String Evaluation
evaluateReceipts book@(ReceiptBook receipts) runIds
  | any (not . validIdentifier) runIds = Left "invalid requested run_id"
  | length (nub runIds) /= length runIds = Left "duplicate requested run_id"
  | otherwise = Right Evaluation
      { evaluationRuns =
          [ (runId, check oracle claim, evidenceFor runId, isGrounded genealogy (NodeId i))
          | (i, runId) <- zip [0 ..] runIds
          , let claim = validationClaim runId
          ]
      , evaluationFused = fused
      , evaluationGenealogy = genealogy
      , evaluationReward = score fused genealogy
      }
  where
    oracle = receiptOracle book
    claims = map factAssertion (ctFacts table)
    fused = fuse (confirmAll oracle claims)
    genealogy = genealogyOf oracle table
    table = claimsOfDRS "external run validation receipts" (DRS [] conditions)
    conditions =
      [ CPred "passes_validation" [DConst runId]
          (provRule ("external-receipt:" ++ maybe "uncovered" id (evidenceFor runId)) [])
      | runId <- runIds
      ]
    evidenceFor runId = case M.lookup runId receipts of
      Just (Receipt _ "-") -> Nothing
      Just (Receipt _ evidenceId) -> Just evidenceId
      Nothing -> Nothing

-- | Machine-readable JSON; all strings are either fixed literals or identifiers
-- already restricted by the parser. Input spans are deliberately absent:
-- receipt provenance does not measure natural-language extraction faithfulness.
renderEvaluation :: Evaluation -> String
renderEvaluation ev = object
  [ ("schema", quote "external-validation-receipts-v1")
  , ("runs", "[" ++ intercalate "," (map renderRun (evaluationRuns ev)) ++ "]")
  , ("fused_claims", show (length (fusedClaims (evaluationFused ev))))
  , ("reward", object
      [ ("confirmed", show (rwConfirmed r))
      , ("refuted", show (rwRefuted r))
      , ("unknown", show (rwUncovered r))
      , ("entailed", show (rwEntailed r))
      , ("ungrounded", show (rwUngrounded r))
      , ("offered", show (rwOffered r))
      , ("score", show (rwScore r))
      ])
  ]
  where
    r = evaluationReward ev
    renderRun (runId, verdict, evidenceId, groundedRun) = object
      [ ("run_id", quote runId)
      , ("verdict", quote (case verdict of
          Confirmed -> "confirmed"
          Refuted -> "refuted"
          Unknown -> "unknown"))
      , ("evidence_id", maybe "null" quote evidenceId)
      , ("grounded", if groundedRun then "true" else "false")
      ]
    object xs = "{" ++ intercalate "," [quote k ++ ":" ++ v | (k, v) <- xs] ++ "}"
    quote s = "\"" ++ s ++ "\""
