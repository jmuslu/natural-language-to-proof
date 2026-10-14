{-# LANGUAGE DataKinds #-}
-- | Checked external snapshots through the existing Haskell substrate.
module Main (main) where

import Data.Either (isLeft)
import Data.List (isInfixOf)
import qualified Data.Set as S

import Harness
import NL2Proof.DRT.Canonical
import NL2Proof.DRT.Types
import NL2Proof.Fusion
import NL2Proof.Genealogy
import NL2Proof.Provenance
import NL2Proof.Reward
import NL2Proof.Verify.External
import NL2Proof.Verify.ClaimKind (Claim, ClaimKind(Asserted), assertedClaims)
import NL2Proof.Verify.Oracle

-- Explicitly authored receipt statements, admitted as whole DRS conditions.
receiptAssertions :: [String] -> [Claim 'Asserted]
receiptAssertions runIds = map fst (assertedClaims (DRS []
  [ CPred "passes_validation" [DConst n] (provRule "receipt-fixture" []) | n <- runIds ]))

snapshot :: String
snapshot = unlines
  [ receiptHeader
  , "run-pass\tconfirmed\tsha256:aaa"
  , "run-fail\trefuted\tsha256:bbb"
  , "run-pending\tunknown\t-"
  ]

withBook :: (ReceiptBook -> [Check]) -> [Check]
withBook f = case parseReceipts snapshot of
  Left why -> [bad "fixture parses" why]
  Right book -> f book

parserChecks :: [Check]
parserChecks =
  [ expect "header-only snapshot covers nothing" (case parseReceipts (receiptHeader ++ "\n") of
      Right book -> check (receiptOracle book) (validationClaim "run") == Unknown
      Left _ -> False)
  , expect "CRLF accepted" (case parseReceipts (concatMap (\c -> if c == '\n' then "\r\n" else [c]) snapshot) of
      Right _ -> True
      Left _ -> False)
  ] ++
  [ expect ("reject malformed snapshot: " ++ label) (isLeft (parseReceipts input))
  | (label, input) <-
      [ ("missing header", "")
      , ("wrong header", "run_id,verdict,evidence_id\n")
      , ("extra column", receiptHeader ++ "\nr\tconfirmed\tx\textra\n")
      , ("empty row", receiptHeader ++ "\n\n")
      , ("missing column", receiptHeader ++ "\nr\tconfirmed\n")
      , ("nonboolean verdict", receiptHeader ++ "\nr\ttrue\tx\n")
      , ("case change", receiptHeader ++ "\nr\tConfirmed\tx\n")
      , ("empty run", receiptHeader ++ "\n\tconfirmed\tx\n")
      , ("unicode run", receiptHeader ++ "\nr\955\tconfirmed\tx\n")
      , ("path run", receiptHeader ++ "\n../r\tconfirmed\tx\n")
      , ("long run", receiptHeader ++ "\n" ++ replicate 257 'a' ++ "\tconfirmed\tx\n")
      , ("blank evidence", receiptHeader ++ "\nr\tconfirmed\t\n")
      , ("unknown placeholder cannot confirm", receiptHeader ++ "\nr\tconfirmed\t-\n")
      , ("unknown placeholder cannot refute", receiptHeader ++ "\nr\trefuted\t-\n")
      , ("duplicate replay", snapshot ++ "run-pass\tconfirmed\tsha256:aaa\n")
      , ("conflicting verdict", snapshot ++ "run-pass\trefuted\tsha256:ccc\n")
      , ("invalid after valid row", snapshot ++ "broken\n")
      ]
  ]

oracleChecks :: [Check]
oracleChecks = withBook $ \book ->
  let oracle = receiptOracle book
  in
  [ expectEq "external passing receipt confirms run" Confirmed
      (check oracle (validationClaim "run-pass"))
  , expectEq "external failing receipt refutes run" Refuted
      (check oracle (validationClaim "run-fail"))
  , expectEq "explicit unknown stays unknown" Unknown
      (check oracle (validationClaim "run-pending"))
  , expectEq "unseen run stays unknown" Unknown
      (check oracle (validationClaim "missing"))
  , expectEq "receipt does not certify arbitrary source proposition" Unknown
      (check oracle (CanPred "market_is_predictable" [CConstT "run-pass"]))
  , expectEq "receipt does not certify all runs" Unknown
      (check oracle (CanPred "passes_validation" [CRefT (CRef 0)]))
  , expectEq "receipt does not certify wrong arity" Unknown
      (check oracle (CanPred "passes_validation" []))
  , expectEq "only confirmed token enters fusion" 1
      (length (fusedClaims (fuse (confirmAll oracle
        (receiptAssertions ["run-pass", "run-fail", "run-pending", "missing"])))))
  , expectEq "weakening removes confirmed claim" []
      (fusedClaims (withoutClaim (validationClaim "run-pass")
        (fuse (confirmAll oracle (receiptAssertions ["run-pass"])))))
  , expectEq "weakening cannot introduce unconfirmed claim" [validationClaim "run-pass"]
      (fusedClaims (withoutClaim (validationClaim "run-fail")
        (fuse (confirmAll oracle (receiptAssertions ["run-pass"])))))
  , expect "empty request returns no evidence and zero reward"
      (case evaluateReceipts book [] of
        Right ev -> null (evaluationRuns ev)
          && null (fusedClaims (evaluationFused ev))
          && rwOffered (evaluationReward ev) == 0
          && rwScore (evaluationReward ev) == 0
        Left _ -> False)
  , expect "duplicate query is rejected" (isLeft (evaluateReceipts book ["run-pass", "run-pass"]))
  , expect "invalid query is rejected" (isLeft (evaluateReceipts book ["bad/run"]))
  ]

pipelineChecks :: [Check]
pipelineChecks = withBook $ \book ->
  case evaluateReceipts book ["run-pass", "run-fail", "run-pending", "missing"] of
    Left why -> [bad "external pipeline evaluates" why]
    Right ev ->
      let r = evaluationReward ev
          g = evaluationGenealogy ev
      in
      [ expectEq "one confirmed proposition rewarded" 1 (rwConfirmed r)
      , expectEq "one refuted proposition penalized" 1 (rwRefuted r)
      , expectEq "explicit and absent unknowns score neither way" 2 (rwUncovered r)
      , expectEq "confirmed and refuted net to zero" 0.0 (rwScore r)
      , expectEq "all four requested runs count as offered" 4 (rwOffered r)
      , expectEq "no invented entailments" 0 (rwEntailed r)
      , expectEq "only confirmed run is grounded" (S.singleton (NodeId 0)) (grounded g)
      , expectEq "external evidence id retained" (Just "sha256:aaa")
          (case evaluationRuns ev of (_, _, evidence, _) : _ -> evidence; [] -> Nothing)
      , expect "genealogy keeps evidence provenance"
          (case nodeAt g (NodeId 0) of
             Just node -> RuleName "external-receipt:sha256:aaa" `elem` provRuleNames (nodeProv node)
             Nothing -> False)
      , expectEq "receipt does not invent source-text coverage" 0 (rwGroundedSpan r)
      , expect "machine JSON contains unknown verdict" ("\"verdict\":\"unknown\"" `isInfixOf` renderEvaluation ev)
      , expectEq "oracle reversal withdraws confirmed premise" [NodeId 0] (snd (retract (NodeId 0) g))
      ]

main :: IO ()
main = runChecks "external receipt bridge" (parserChecks ++ oracleChecks ++ pipelineChecks)
