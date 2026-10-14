-- Regression for loss of a root existential's witness environment across documents.
-- Run: runghc -isrc research/probe-claim-scope.hs
-- Hand-authored fixtures only; no parser, labels, datasets or accepting oracle.
module Main (main) where

import qualified Data.Map.Strict as M
import Data.Maybe (isJust)
import System.Exit (exitFailure)

import NL2Proof.DRT.Canonical
import NL2Proof.DRT.Types
import NL2Proof.Fusion
import NL2Proof.Provenance
import NL2Proof.Verify.ClaimKind
import NL2Proof.Verify.Oracle

type Env = M.Map CRef String

-- This finite model has two objects. P(a), not P(b), and not q.
-- A local oracle computes truth under an explicitly displayed assignment;
-- there is no unconditional acceptance fixture.
domain :: [String]
domain = ["a", "b"]

assignments :: Env -> [CRef] -> [Env]
assignments env [] = [env]
assignments env (r:rs) = concat
  [assignments (M.insert r object env) rs | object <- domain]

term :: Env -> CTerm -> Maybe String
term env (CRefT r) = M.lookup r env
term _ (CConstT name) = Just name

body :: Env -> Canonical -> Maybe Bool
body env = fmap and . mapM (holds env) . canonConds

box :: Env -> Canonical -> Maybe Bool
box env k = or <$> mapM (`body` k) (assignments env (canonUniverse k))

holds :: Env -> CanonCond -> Maybe Bool
holds env (CanPred "P" [x]) = (== "a") <$> term env x
holds _ (CanPred "q" []) = Just False
holds env (CanEq x y) = (==) <$> term env x <*> term env y
holds env (CanNot k) = not <$> box env k
holds env (CanImp a b) = and <$> mapM implication
  (assignments env (canonUniverse a))
  where implication e = (\p q -> not p || q) <$> body e a <*> box e b
holds env (CanOr a b) = (||) <$> box env a <*> box env b
holds _ _ = Nothing

modelOracle :: String -> Env -> Oracle
modelOracle name env = Oracle name "finite model P(a), not P(b), not q; scoped witness assignment"
  (isJust . holds env) ((== Just True) . holds env)

pv :: String -> Prov
pv name = ProvLex (SourceId name) (Span 0 1) name

p :: String -> Condition
p name = CPred "P" [DRef (Ref name)] (pv name)

q :: Condition
q = CPred "q" [] (pv "q")

rule :: String -> Condition
rule name = CImp (DRS [] [p name]) (DRS [] [q]) (pv name)

docA, docB, combined :: DRS
docA = DRS [(Ref "alice-witness", pv "docA")] [p "alice-witness"]
docB = DRS [(Ref "bob-witness", pv "docB")] [rule "bob-witness"]
combined = DRS (drsUniverse docA ++ drsUniverse docB)
  (drsConds docA ++ drsConds docB)

tokens :: Oracle -> DRS -> [Confirmed]
tokens oracle = confirmAll oracle . map fst . assertedClaims

query :: CanonCond
query = CanPred "q" []

main :: IO ()
main = do
  let envA = M.singleton (CRef 0) "a"
      envB = M.singleton (CRef 0) "b"
      a = tokens (modelOracle "docA:r0=a" envA) docA
      b = tokens (modelOracle "docB:r0=b" envB) docB
      merged = fuse (a ++ b)
      joinedEnv = M.fromList [(CRef 0, "a"), (CRef 1, "b")]
      joined = fuse (tokens (modelOracle "joint:r0=a,r1=b" joinedEnv) combined)
      rigidA = DRS [] [CPred "P" [DConst "a"] (pv "rigidA")]
      rigidB = DRS [] [CImp (DRS [] [CPred "P" [DConst "b"] (pv "rigidB")])
        (DRS [] [q]) (pv "rigidB")]
      rigidOracle = modelOracle "rigid" M.empty
      rigid = fuse (tokens rigidOracle rigidA ++ tokens rigidOracle rigidB)
      closedOnly = fuse (tokens (modelOracle "closed-only" M.empty) docA
        ++ tokens (modelOracle "closed-only" M.empty) docB)
      checks =
        [ ("both complete documents true in the same two-object countermodel",
            box M.empty (canonicalize docA) == Just True
            && box M.empty (canonicalize docB) == Just True)
        , ("their properly scoped conjunction is true", box M.empty (canonicalize combined) == Just True)
        , ("closed conclusion q is false in that model", holds M.empty query == Just False)
        , ("both local oracle predicates truthfully accept their scoped conditions",
            all (oracleHolds (modelOracle "docA" envA) . claimCond . fst) (assertedClaims docA)
            && all (oracleHolds (modelOracle "docB" envB) . claimCond . fst) (assertedClaims docB))
        , ("central boundary refuses tokens missing a local witness environment", null a && null b)
        , ("neither isolated document detaches q", query `notElem` entailedFrom (fuse a)
            && query `notElem` entailedFrom (fuse b))
        , ("FIX: separately canonicalized conditions cannot detach false q", query `notElem` entailedFrom merged)
        , ("joint canonicalization preserves witness distinction", query `notElem` entailedFrom joined)
        , ("rigid a/b constants do not alias", query `notElem` entailedFrom rigid)
        , ("oracle rejecting open claims blocks this path", null (fusedClaims closedOnly))
        ]
  putStrLn ("docA: " ++ show (canonicalize docA))
  putStrLn ("docB: " ++ show (canonicalize docB))
  putStrLn ("joint: " ++ show (canonicalize combined))
  putStrLn ("separate confirmations: " ++ show (map confClaim (a ++ b)))
  putStrLn ("separate closure: " ++ show (entailedFrom merged))
  putStrLn ("joint closure: " ++ show (entailedFrom joined))
  mapM_ (\(name, ok) -> putStrLn ((if ok then "PASS " else "FAIL ") ++ name)) checks
  if all snd checks then pure () else exitFailure
