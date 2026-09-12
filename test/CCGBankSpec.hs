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
import NL2Proof.Syntax.CCGRules
import NL2Proof.Syntax.CCGDeriv

main :: IO ()
main = runChecks "ccgbank"
  (parseChecks ++ classifyChecks ++ tyChecks ++ agreementChecks
   ++ unifyChecks ++ ruleChecks ++ derivChecks)

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
    -- the unparenthesised VP-conjunct form normalises the trailing [conj] to
    -- the root, matching the parenthesised form rather than attaching it to NP
  , expectEq "trailing [conj] normalises to the whole category"
      (parseCCGCat "(S[dcl]\\NP)[conj]")
      (parseCCGCat "S[dcl]\\NP[conj]")
  , expectEq "trailing [conj] on a complex node, explicit"
      (Right (CSlash Fwd (CAtom "NP" [Feat "nb"]) (CAtom "N" []) [Feat "conj"]))
      (parseCCGCat "NP[nb]/N[conj]")
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
-- Feature unification
--------------------------------------------------------------------------------

unifyChecks :: [Check]
unifyChecks =
  [ expect "underspecified S unifies with S[dcl]"
      (unifiable (pc "S") (pc "S[dcl]"))
  , expect "underspecified S\\NP unifies with S[dcl]\\NP"
      (unifiable (pc "S\\NP") (pc "S[dcl]\\NP"))
  , expect "NP[nb] unifies with bare NP"
      (unifiable (pc "NP[nb]") (pc "NP"))
  , expect "S[dcl] does not unify with S[b]"
      (not (unifiable (pc "S[dcl]") (pc "S[b]")))
  , expect "different atoms do not unify"
      (not (unifiable (pc "NP") (pc "N")))
  , expect "slash direction matters"
      (not (unifiable (pc "S/NP") (pc "S\\NP")))
  ]

--------------------------------------------------------------------------------
-- Combinatory rules, checked against CCGbank's top-frequency GRAMMAR rules
--------------------------------------------------------------------------------

-- | Does the rule set license @parent@ (up to feature unification) from the pair?
-- @parent@, @l@, @r@ are given as CCGbank category strings.
reproduces :: String -> String -> String -> Bool
reproduces parent l r =
  any (unifiable (pc parent)) (combine (pc l) (pc r))

ruleChecks :: [Check]
ruleChecks =
  [ expect "N/N N -> N (fwd app)"                (reproduces "N" "N/N" "N")
  , expect "NP[nb]/N N -> NP (fwd app, feature)" (reproduces "NP" "NP[nb]/N" "N")
  , expect "NP NP\\NP -> NP (bwd app)"           (reproduces "NP" "NP" "NP\\NP")
  , expect "NP S[dcl]\\NP -> S[dcl] (bwd app)"   (reproduces "S[dcl]" "NP" "S[dcl]\\NP")
  , expect "PP/NP NP -> PP (fwd app)"            (reproduces "PP" "PP/NP" "NP")
  , expect "adverbial modifies underspecified VP"
      (reproduces "S[dcl]\\NP" "S[dcl]\\NP" "(S\\NP)\\(S\\NP)")
  , expect "S/S S[dcl] -> S[dcl] (fwd app, underspec result)"
      (reproduces "S[dcl]" "S/S" "S[dcl]")
  , expect "conj NP -> NP[conj] (coordination mark)"
      (reproduces "NP[conj]" "conj" "NP")
  , expect "comma NP -> NP[conj] (comma as coordinator)"
      (reproduces "NP[conj]" "," "NP")
  , expect "NP NP[conj] -> NP (coordination apply)"
      (reproduces "NP" "NP" "NP[conj]")
  , expect "S[dcl] . -> S[dcl] (punct right)"
      (reproduces "S[dcl]" "S[dcl]" ".")
  , expect "comma S[dcl] -> S[dcl] (punct left)"
      (reproduces "S[dcl]" "," "S[dcl]")
  , expect "fwd composition: S/S S/S -> S/S"
      (reproduces "S/S" "S/S" "S/S")
    -- a pair that should NOT combine to an unrelated category
  , expect "N and NP do not combine to S"
      (not (reproduces "S" "N" "NP"))
  ]

--------------------------------------------------------------------------------
-- .auto derivation parsing & reconstruction
--------------------------------------------------------------------------------

-- A synthetic derivation tree (made-up words foo/bar/baz, NOT corpus text), so
-- no CCGbank-licensed material lives in the repo. Structure mirrors a real
-- transitive-clause derivation:
--   S[dcl]  ->  NP   (S[dcl]\NP)
--   S[dcl]\NP -> (S[dcl]\NP)/NP  NP
syntheticAuto :: String
syntheticAuto =
  "(<T S[dcl] 0 2> (<L NP DT DT foo NP>) "
  ++ "(<T S[dcl]\\NP 0 2> "
  ++ "(<L (S[dcl]\\NP)/NP VBZ VBZ bar (S[dcl]\\NP)/NP>) "
  ++ "(<L NP NN NN baz NP>) ) )"

derivChecks :: [Check]
derivChecks =
  [ expectEq "parses a synthetic derivation tree"
      (Right expectedTree) (parseAuto syntheticAuto)
  , expect "leaf category is read (predarg parens do not break tokenising)"
      (case parseAuto "(<L (S[dcl]\\NP)/NP VBZ VBZ bar (S[dcl]\\NP)/NP>)" of
         Right (AutoLeaf c w) -> c == "(S[dcl]\\NP)/NP" && w == "bar"
         _ -> False)
  , expect "every binary node of the synthetic tree reconstructs"
      (either (const False) fullyReconstructed (parseAuto syntheticAuto))
  , expect "a broken binary node is flagged uncovered"
      (case parseAuto "(<T S[dcl] 0 2> (<L NP DT DT foo NP>) (<L NP NN NN baz NP>) )" of
         Right t  -> not (fullyReconstructed t)  -- NP NP does not combine to S[dcl]
         Left _   -> False)
  , expect "malformed auto line is a Left"
      (case parseAuto "(<T S[dcl] 0 2> (<L NP" of Left _ -> True; Right _ -> False)
  ]
  where
    expectedTree =
      AutoTree "S[dcl]"
        [ AutoLeaf "NP" "foo"
        , AutoTree "S[dcl]\\NP"
            [ AutoLeaf "(S[dcl]\\NP)/NP" "bar"
            , AutoLeaf "NP" "baz"
            ]
        ]

--------------------------------------------------------------------------------
-- helpers
--------------------------------------------------------------------------------

-- | Parse a category literal, erroring loudly on a parse bug (all literals here
-- are valid CCGbank categories).
pc :: String -> CCat
pc s = either (\e -> error ("bad test category " ++ show s ++ ": " ++ e)) id
             (parseCCGCat s)

isLeft :: Either a b -> Bool
isLeft (Left _)  = True
isLeft (Right _) = False
