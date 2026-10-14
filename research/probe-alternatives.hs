module Main where

import NL2Proof.Bench.JSON
import NL2Proof.Pipeline
import NL2Proof.Provenance
import NL2Proof.Readings.Alternatives
import NL2Proof.Readings.Modifier
import NL2Proof.Semantics.Lambda
import NL2Proof.Syntax.Lexicon

lexicon :: Lexicon
lexicon=mkLexicon ([ (w,lookupWord fragmentLexicon w)|w<-lexiconKeys fragmentLexicon]
  ++[("fake",[adjEntry "fake"]),("gun",[nounEntry "gun"])])

texts :: [String]
texts=["Every student reads a book.","Every student who reads a book smiles.","No student sleeps.",
       "An ancient Chinese red dragon sleeps.","A fake gun sleeps.",
       "John sees an ancient Chinese red dragon.","John sees a fake gun."]

main :: IO ()
main=mapM_ probe texts

probe :: String -> IO ()
probe text=case [f|r<-prSentences(runPipeline lexicon (SourceId "alternatives") text),Just f<-[srForm r]] of
  [form] -> do
    let scoped=scopeAlternatives form
        coupled=couplingCandidates (isModifierWord lexicon) form
        choices=alternatives (isModifierWord lexicon) form
    putStrLn(renderJSON(JObj
      [("text",JStr text),("original",JStr(pretty form))
      ,("scope_count",JNum(fromIntegral(length scoped)))
      ,("scope_signatures",JArr(map(JStr . scopeSignature)scoped))
      ,("alternative_count",JNum(fromIntegral(length choices)))
      ,("all_closed_typed",JBool(all(\t->null(freeVars t)&&typeOf [] t==Right TyT)choices))
      ,("coupling",JArr[JObj[("form",JStr(pretty(ccTerm c))),("modifier",maybe JNull JStr(ccModifier c)),
          ("licensed",JBool(ccLicensed c)),("class",maybe JNull(JStr . show)(ccClass c))]|c<-coupled])
      ,("fake_class",JStr(show(classifyModifier "fake")))]))
  _ -> putStrLn(renderJSON(JObj[("text",JStr text),("error",JStr "no unique selected form")]))
