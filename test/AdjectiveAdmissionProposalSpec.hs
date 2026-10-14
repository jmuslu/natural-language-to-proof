-- Independent miniature proposal controls. Two deliberate reds on current source.
-- No corpus/model loading and no implementation of the proposed filter here.
module Main (main) where
import qualified Data.Set as Set
import Harness
import NL2Proof.Syntax.CCGBank (parseCCGCat)
import NL2Proof.Syntax.CCGParse (Rules(..))
import NL2Proof.Syntax.CCGSemParse
import NL2Proof.Syntax.CCGSupertag (buildPOSModel,buildTagModel)
cc = either error id . parseCCGCat
adj = "S[adj]\\NP"
model tags poses = (defaultSemModel
  (buildTagModel [(w,cc c) | (w,c) <- tags])
  (buildPOSModel poses) (Rules [] []) Set.empty)
  {smAlpha=100,smBeta=0,smKmax=100,smSeenRules=False}
seed = [("gentle",adj),("gentle","N/N")]
has m w c = cc c `elem` map lxCat (lexicalSigns m 1 w)
offered m w c = cc c `elem` map fst (offeredTags m False w)
plural = model (("lanterns","N"):seed) [("lanterns","NNS")]
verb = model (("glides","S[dcl]\\NP"):seed) [("glides","VBZ")]
main = runChecks "adjective-admission-proposal"
  [ expect "fixture offers smoothed adjective to plural noun" (offered plural "lanterns" adj)
  , expect "RED suppress unattested adjective for exclusively NNS known form"
      (not (has plural "lanterns" adj))
  , expect "fixture offers smoothed adjective to finite verb" (offered verb "glides" adj)
  , expect "RED suppress unattested adjective for exclusively VBZ known form"
      (not (has verb "glides" adj))
  , expect "noun candidate survives" (has plural "lanterns" "N")
  , expect "finite verb category survives" (has verb "glides" "S[dcl]\\NP")
  , expect "N/N untouched: noun compounds need separate interpretation"
      (has plural "lanterns" "N/N")
  , expect "word-attested adjective category overrides sparse contrary POS"
      (has (model (("lanterns",adj):("lanterns","N"):seed)
        [("lanterns","NNS")]) "lanterns" adj)
  , expect "minority JJ evidence protects adjective"
      (has (model (("round","N"):seed)
        [("round","NN"),("round","NN"),("round","JJ")]) "round" adj)
  , expect "known kind with noun-only POS not in NNS/VBZ envelope survives"
      (has (model (("kind","N"):seed) [("kind","NN")]) "kind" adj)
  , expect "unknown round keeps existing prior backoff"
      (has (model seed []) "round" adj)
  , expect "unknown nonce adjective keeps prior backoff"
      (has (model seed []) "velvety" adj)
  , expect "known form with no POS evidence keeps adjective"
      (has (model (("lanterns","N"):seed) []) "lanterns" adj)
  , expect "mixed plural/verb evidence is outside narrow envelope"
      (has (model (("darts","N"):seed) [("darts","NNS"),("darts","VBZ")]) "darts" adj)
  , expect "participial ambiguity is not rejected"
      (has (model (("painted","S[pss]\\NP"):seed) [("painted","VBN")]) "painted" adj)
  , expect "comparative POS remains outside exclusion envelope"
      (has (model (("brighter","N"):seed) [("brighter","JJR")]) "brighter" adj)
  , expect "JJ backoff still supplies missing adjective without smoothing"
      (has ((model [("round","N")] [("round","JJ")])
        {smAlpha=0,smPOSBackoff=True}) "round" adj)
  , expect "unseen capitalization retains name behavior"
      (has (model (("lamp","N"):seed) []) "Aster" "NP")
  ]
