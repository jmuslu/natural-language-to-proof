-- | Unit tests for the CCGbank category parser and classifier
-- ('NL2Proof.Syntax.CCGBank').
--
-- These pin the mechanical behaviour the aggregate report over the real corpus
-- relies on: that parsing distinguishes malformed from well-formed, that the
-- representability buckets are assigned correctly, and — the load-bearing
-- cross-check — that the new feature-erasing 'ccatToTy' agrees with the repo's
-- existing 'catTy' on every category the current 'Cat' can already express. If
-- those two ever diverge, the ingestion pass would be typing corpus entries by
-- a different rule than the hand-written lexicon, which is exactly the kind of
-- silent inconsistency the project is built to prevent.
module Main (main) where

import Harness
import NL2Proof.Semantics.Lambda (Ty(TyT), tyGQ, tyPred1, (~>))
import NL2Proof.Syntax.Category (Cat(..), catTy)
import NL2Proof.Syntax.CCGBank

main :: IO ()
main = runChecks "ccgbank" (parseChecks ++ classifyChecks ++ tyChecks ++ agreementChecks)

--------------------------------------------------------------------------------
-- Parsing
--------------------------------------------------------------------------------

parseChecks :: [Check]
parseChecks =
  [ expectEq "atom with feature" (Right (CAtom "S" [Feat "dcl"])) (parseCCGCat "S[dcl]")
  , expectEq "bare atom" (Right (CAtom "PP" [])) (parseCCGCat "PP")
  , expectEq "lowercase atom conj" (Right (CAtom "conj" [])) (parseCCGCat "conj")
  , expectEq "punctuation atom" (Right (CAtom "," [])) (parseCCGCat ",")
  , expectEq "two features stack"
      (Right (CAtom "S" [Feat "dcl", Feat "conj"]))
      (parseCCGCat "S[dcl][conj]")
  , expectEq "forward slash, determiner"
      (Right (CSlash Fwd (CAtom "NP" [Feat "nb"]) (CAtom "N" []) []))
      (parseCCGCat "NP[nb]/N")
  , expectEq "transitive verb, left-assoc + parens"
      (Right (CSlash Fwd
                (CSlash Bwd (CAtom "S" [Feat "dcl"]) (CAtom "NP" []) [])
                (CAtom "NP" []) []))
      (parseCCGCat "(S[dcl]\\NP)/NP")
  , expectEq "feature on a parenthesised complex node"
      (Right (CSlash Bwd (CAtom "S" [Feat "dcl"]) (CAtom "NP" []) [Feat "conj"]))
      (parseCCGCat "(S[dcl]\\NP)[conj]")
    -- malformed inputs are reported as Left, not silently accepted
  , expect "trailing slash is malformed"   (isLeft (parseCCGCat "S/"))
  , expect "unbalanced paren is malformed"  (isLeft (parseCCGCat "((S\\NP)"))
  , expect "empty string is malformed"      (isLeft (parseCCGCat ""))
  , expect "unterminated feature is malformed" (isLeft (parseCCGCat "S[dcl"))
  ]

-- | Round-trip: printing then reparsing is the identity on structure. The
-- printer emits canonical parentheses, so this holds exactly.
roundTrips :: String -> Check
roundTrips raw =
  case parseCCGCat raw of
    Left e  -> bad ("round-trip parse of " ++ show raw) e
    Right c ->
      expectEq ("round-trip " ++ show raw) (Right c) (parseCCGCat (prettyCCat c))

--------------------------------------------------------------------------------
-- Classification
--------------------------------------------------------------------------------

classifyChecks :: [Check]
classifyChecks =
  map roundTrips
    [ "S[dcl]", "(S[dcl]\\NP)/NP", "NP[nb]/N", "((S[b]\\NP)/PP)/NP"
    , "(NP\\NP)/NP", "conj", "PP/NP" ]
  ++
  [ expectEq "S\\NP is representable as is"
      RepresentableAsIs (classify "S\\NP")
  , expectEq "N/N is representable as is"
      RepresentableAsIs (classify "N/N")
  , expectEq "declarative transitive needs the [dcl] feature"
      (NeedsFeature [Feat "dcl"]) (classify "(S[dcl]\\NP)/NP")
  , expectEq "a PP category needs the PP atom"
      (NeedsNewAtom ["PP"]) (classify "PP/NP")
  , expectEq "conj needs the conj atom"
      (NeedsNewAtom ["conj"]) (classify "conj")
  , expect "a malformed category classifies as Malformed"
      (case classify "S/" of Malformed _ -> True; _ -> False)
  ]

--------------------------------------------------------------------------------
-- Semantic type
--------------------------------------------------------------------------------

-- | Parse (a known-good literal) then take its semantic type. The category
-- literals below all parse, so a parse failure here is a test bug, surfaced
-- loudly rather than silently absorbed into the 'TyIssue' channel.
tyOf :: String -> Either TyIssue Ty
tyOf raw =
  either (\e -> error ("test category failed to parse: " ++ raw ++ ": " ++ e))
         ccatToTy
         (parseCCGCat raw)

tyChecks :: [Check]
tyChecks =
  [ expectEq "feature is erased: S[dcl] : t"
      (Right TyT) (tyOf "S[dcl]")
  , expectEq "intransitive verb type"
      (Right (tyGQ ~> TyT)) (tyOf "S[dcl]\\NP")
  , expectEq "common noun type"
      (Right tyPred1) (tyOf "N")
  , expectEq "PP is flagged ambiguous, not given a silent default"
      (Left (AmbiguousAtomType "PP")) (tyOf "PP")
  , expectEq "coordination is flagged polymorphic"
      (Left (PolymorphicAtom "conj")) (tyOf "conj")
  , expect "a PP-bearing functor propagates the PP issue"
      (case tyOf "(S[b]\\NP)/PP" of
         Left (AmbiguousAtomType "PP") -> True
         _ -> False)
  ]

--------------------------------------------------------------------------------
-- Agreement with the existing catTy on the shared fragment
--------------------------------------------------------------------------------

-- | For every category the current 'Cat' can already express, the new
-- feature-erasing 'ccatToTy' must agree with the repo's 'catTy'. This is the
-- check that keeps the corpus ingestion typing entries by the same rule the
-- hand-written lexicon uses.
agreementChecks :: [Check]
agreementChecks = map agrees sharedFragment
  where
    sharedFragment =
      [ "N", "NP", "S", "N/N", "S\\NP", "(S\\NP)/NP", "NP/N"
      , "(N\\N)/(S\\NP)", "(S\\NP)/(S\\NP)", "((S\\NP)\\(S\\NP))/NP" ]
    agrees raw =
      case (parseCCGCat raw, parseCCGCat raw >>= toBareCatE) of
        (Right c, Right bare) ->
          expectEq ("ccatToTy agrees with catTy on " ++ show raw)
            (Right (catTy bare)) (ccatToTy c)
        _ -> bad ("agreement setup for " ++ show raw) "did not project to a bare Cat"
    toBareCatE :: CCat -> Either String Cat
    toBareCatE c = maybe (Left "no bare Cat") Right (toBareCat c)

--------------------------------------------------------------------------------
-- helpers
--------------------------------------------------------------------------------

isLeft :: Either a b -> Bool
isLeft (Left _)  = True
isLeft (Right _) = False
