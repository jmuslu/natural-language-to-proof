module Main (main) where

import Data.List (isInfixOf)

import Harness
import NL2Proof.Bench.Export
import NL2Proof.Bench.JSON
import NL2Proof.DRT.Types
import NL2Proof.Pipeline
import NL2Proof.Provenance
import NL2Proof.Syntax.Lexicon

main :: IO ()
main = runChecks "export" checks

p :: Prov
p = ProvLex (SourceId "fixture") (Span 0 6) "either"

atom :: String -> DTerm -> DRS
atom name arg = DRS [] [CPred name [arg] p]

request :: [String] -> String -> JValue
request context statement = JObj
  [("id",JStr "fixture"),("context",JArr (map JStr context)),("statement",JStr statement)]

arr :: Maybe JValue -> [JValue]
arr (Just (JArr xs)) = xs
arr _ = []

exported :: Int -> [String] -> String -> JValue
exported cap ctx query = either error id (exportRequest (HandLexicon fragmentLexicon) cap (request ctx query))

firstTheory :: JValue -> JValue
firstTheory v = case arr (field "theories" v) of
  x:_ -> x
  _ -> error "no exported theory"

firstQuery :: JValue -> JValue
firstQuery v = case arr (field "queries" (firstTheory v)) of
  x:_ -> x
  _ -> error "no exported query"

checks :: [Check]
checks =
  [ expectEq "JSON serialization round-trips escaped unicode and structure"
      (Right jsonFixture) (parseJSON (renderJSON jsonFixture))
  , expect "oracle/gold fields are rejected at parser boundary"
      (case exportRequest (HandLexicon fragmentLexicon) 64
        (JObj [("id",JStr "x"),("context",JArr []),("statement",JStr "John smiles."),("label",JStr "True")]) of
          Left _ -> True; _ -> False)
  , expect "duplicate request keys are rejected"
      (case exportRequest (HandLexicon fragmentLexicon) 64
        (JObj [("id",JStr "x"),("id",JStr "y"),("context",JArr []),("statement",JStr "John smiles.")]) of
          Left _ -> True; _ -> False)
  , expect "sentence-local scope is preserved in negation export"
      (let v=drsJSON (DRS [] [CNot (DRS [(Ref "x",p)] [CPred "red" [DRef (Ref "x")] p]) p])
       in case arr (field "conditions" v) of
            [c] -> field "tag" c == Just (JStr "not")
                && (field "body" c >>= field "universe") == Just (JArr [JStr "x"])
            _ -> False)
  , expect "implication antecedent variables remain accessible to consequent"
      (null (drsResiduals (DRS [] [CImp (DRS [(Ref "x",p)] [CPred "cat" [DRef (Ref "x")] p])
        (atom "red" (DRef (Ref "x"))) p])))
  , expect "free referent is residual not invented constant"
      (any (isInfixOf "unbound-ref") (drsResiduals (atom "red" (DRef (Ref "x")))))
  , expect "unresolved anaphor is residual"
      (not (null (drsResiduals (atom "red" (DConst "?it_0")))))
  , expect "stringified higher-order argument is residual"
      (not (null (drsResiduals (atom "red" (DConst "f(x)")))))
  , expect "UNSUPPORTED DRS marker remains residual"
      (not (null (drsResiduals (DRS [] [CPred "UNSUPPORTED[lambda]" [] p]))))
  , expect "attitude and presupposition boxes remain marked and residual"
      (let v=drsJSON (DRS [] [CAtt "say" [DConst "John"] (atom "red" (DConst "cat")) p,
                            CPresup (atom "big" (DConst "cat")) p])
       in map (field "tag") (arr (field "conditions" v)) == [Just (JStr "att"),Just (JStr "presup")]
          && length (drsResiduals (DRS [] [CAtt "say" [DConst "John"] emptyDRS p,CPresup emptyDRS p])) == 2)
  , expect "either marker is attached from condition provenance"
      (case arr (field "conditions" (drsJSON (DRS [] [COr emptyDRS emptyDRS p]))) of
         [c] -> field "either" c == Just (JBool True)
         _ -> False)
  , expect "sentence-wide either cannot mark two separate disjunctions exclusive"
      (let v=drsJSON (DRS [] [COr emptyDRS emptyDRS p,COr emptyDRS emptyDRS p])
       in all ((== Just (JBool False)) . field "either") (arr (field "conditions" v))
          && field "xor_residuals" v == Just (JArr [JStr "ambiguous-either-scope"]))
  , expect "separate sentences with one either each retain local evidence"
      (let other=ProvLex (SourceId "fixture") (Span 20 26) "either"
           v=drsJSON (DRS [] [COr emptyDRS emptyDRS p,COr emptyDRS emptyDRS other])
       in all ((== Just (JBool True)) . field "either") (arr (field "conditions" v)))
  , expect "plain multiword rigid names are supported"
      (null (drsResiduals (atom "red" (DConst "bald eagle"))))
  , expect "context existential referents are freshened across sentences"
      (case field "drs" (firstTheory (exported 64 ["A student smiles.","A student sleeps."] "John smiles.")) >>= field "universe" of
         Just (JArr [JStr x,JStr y]) -> x /= y
         _ -> False)
  , expect "query never enters premise box"
      (let v=exported 64 ["John smiles."] "Mary sleeps."
       in not ("sleep" `isInfixOf` maybe "" renderJSON (field "drs" (firstTheory v))))
  , expect "failed context sentence is retained as incomplete residual"
      (let t=firstTheory (exported 64 ["John smiles.","Flibberty flob."] "John smiles.")
       in field "complete" t == Just (JBool False) && not (null (arr (field "residuals" t))))
  , expect "multisentence statement is unsupported"
      (null (arr (field "queries" (firstTheory (exported 64 ["John smiles."] "John smiles. Mary sleeps.")))) )
  , expect "cross-context query referents force residual instead of free-variable proof"
      (let q=firstQuery (exported 64 ["A student smiles."] "She sleeps.")
       in field "complete" q == Just (JBool False))
  , expect "selected form and box are the first shared reading"
      (case prSentences (runFragment (SourceId "shared") "John smiles.") of
         [r] -> case srReadings r of
           first:_ -> rrForm first == srForm r && rrDRS first == srDRS r
           _ -> False
         _ -> False)
  , expect "alternative readings retain independently translated meanings"
      (let lexicon=mkLexicon [(w, [ivEntry "grin" | w == "smiles"] ++ lookupWord fragmentLexicon w) | w <- lexiconKeys fragmentLexicon]
           result=either error id (exportRequest (HandLexicon lexicon) 64 (request ["John smiles."] "John smiles."))
           theories=arr (field "theories" result)
       in length theories == 2
          && any (isInfixOf "grin" . renderJSON) theories
          && any (isInfixOf "smile" . renderJSON) theories
          && field "truncated" result == Just (JBool False))
  , expect "all returned meanings use shared translation and cap cannot claim completeness"
      (let lexicon=mkLexicon [(w, [ivEntry "grin" | w == "smiles"] ++ lookupWord fragmentLexicon w) | w <- lexiconKeys fragmentLexicon]
           result=either error id (exportRequest (HandLexicon lexicon) 1 (request ["John smiles."] "John smiles."))
       in field "truncated" result == Just (JBool True))
  ]
  where
    jsonFixture = JObj [("escape\"",JStr "line\n\t\\\"λ猫\000"),("items",JArr [JNum 1.5,JBool False,JNull])]
