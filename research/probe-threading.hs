module Main where

import NL2Proof.Bench.JSON
import NL2Proof.Discourse.Threading
import NL2Proof.DRT.Build
import NL2Proof.DRT.Types
import NL2Proof.Pipeline
import NL2Proof.Provenance
import NL2Proof.Semantics.Lambda
import NL2Proof.Syntax.Category
import NL2Proof.Syntax.Lexicon
import NL2Proof.Trace

fixtures :: [(String,String)]
fixtures =
  [ ("two-sentence-existential", "A student arrived. She smiles.")
  , ("named-antecedent", "John smiles. He sleeps.")
  , ("definite-antecedent", "The cat sleeps. It walks.")
  , ("three-sentence-universal-interlude", "A student arrived. Every professor smiles. She sleeps.")
  , ("four-sentence-universal-interludes", "A student arrived. Every professor smiles. Every dragon sleeps. She walks.")
  , ("two-candidates-recency", "A student arrived. A professor walks. She smiles.")
  , ("negation-barrier", "No student sleeps. She smiles.")
  , ("report-barrier", "John says that a student sleeps. It walks.")
  , ("two-names", "John smiles. Mary sleeps. She walks.")
  , ("pronoun-chain", "A student arrived. He smiles. He sleeps. He walks.")
  ]

lexicon :: Lexicon
lexicon = mkLexicon ([ (w,lookupWord attitudeLexicon w) | w <- lexiconKeys attitudeLexicon]
  ++ [("cat",[nounEntry "cat"]),("the",[theEntry])])
  where
    theEntry=Entry (NP :/ N)
      (Lam "P" tyPred1 (Lam "Q" tyPred1 (App (Var "Q") (iota (Var "P"))))) "definite fixture"

main :: IO ()
main=mapM_ probe fixtures

probe :: (String,String) -> IO ()
probe (ident,text) = do
  let src=SourceId ident
      result=runPipeline lexicon src text
      segs=segmentsOf src result
      flat=prDiscourse result
      committed=threadDiscourse Committed segs
      permissive=threadDiscourse Permissive segs
      summary box trace=JObj
        [("unresolved",JNum(fromIntegral(length [d | d <- traceDiagnostics trace,diagKind d==UnresolvedAnaphor])))
        ,("choices",JArr [JStr(decChoice d)|d<-traceDecisions trace,decKind d=="anaphora"])
        ,("drs",JStr(renderDRS box))]
  putStrLn(renderJSON(JObj
    [("id",JStr ident),("text",JStr text),("sentences",JNum(fromIntegral(length(prSentences result))))
    ,("parsed",JNum(fromIntegral(length segs)))
    ,("flat",summary(dscDRS flat)(dscTrace flat))
    ,("committed",summary(threadedDRS committed)(thTrace committed))
    ,("permissive",summary(threadedDRS permissive)(thTrace permissive))
    ,("committed_equal",JBool(threadedDRS committed==dscDRS flat))
    ,("permissive_equal",JBool(threadedDRS permissive==dscDRS flat))]))
