-- Bounded lexical and corpus-free pipeline controls; no CCGbank load.
module Main (main) where
import qualified Data.Set as Set
import Harness
import NL2Proof.DRT.Canonical
import NL2Proof.Pipeline
import NL2Proof.Provenance
import NL2Proof.Syntax.CCGParse (Rules(..))
import NL2Proof.Syntax.CCGSemParse
import NL2Proof.Syntax.CCGSupertag (buildTagModel, buildPOSModel)
import NL2Proof.Verify.ClaimKind (claimCond)
import NL2Proof.Verify.Reported (splitClaims)
import NL2Proof.Semantics.CCGSem
import NL2Proof.Semantics.Lambda
import NL2Proof.Syntax.CCGBank (CCat, parseCCGCat, eraseFeatures)

entry :: String -> String -> [Term]
entry word category = [canonicalAC (normalize tm) | LexTerm tm _ _ <- closedEntries 0 word (cc category)]
cc :: String -> CCat
cc = either error id . parseCCGCat
x, p, q, person, standalone, restricted :: Term
x = Var "x"
p = Var "P"
q = Var "Q"
person = App (pred1 "person") x
standalone = Lam "P" tyPred1 (TForall "x" TyE (TImp person (App p x)))
restricted = Lam "P" tyPred1 (Lam "Q" tyPred1 (TForall "x" TyE (TImp (TAnd person (App p x)) (App q x))))
main :: IO ()
main = runChecks "everyone-N-origin-proposal-expected-red" (originChecks ++ scopedChecks ++ sourcePairChecks)
originChecks :: [Check]
originChecks =
 [expect "RED offered N produces only complete strict-person NP"
    (not(null candidates) && all correct candidates)
 ,expect "candidate score is the actual offered N score"
    (not(null candidates) && all ((==sourceScore).lxScore) candidates)
 ,expect "RED repaired N carries source-category audit"
    (any hasAudit candidates)
 ,expect "N[conj] is not a bare-N repair license"
    (all ((/=cc "NP").lxCat) (lexicalSigns (model "N[conj]") 0 "Everyone"))
 ,expect "literal people remains property category"
    (entry "people" "N" == [canonicalAC (Lam "x" TyE person)])
 ,expect "literal things remains property category"
    (entry "things" "N" == [canonicalAC (Lam "x" TyE (App (pred1 "thing") x))])
 ,expect "RED a determiner cannot consume Everyone as a noun" (noReading "A everyone is tall.")
 ,expect "RED every determiner cannot consume Everyone as a noun" (noReading "Every everyone is tall.")
 ]
 where
  candidates=lexicalSigns (model "N") 0 "Everyone"
  sourceScore=case [s|(c,s)<-offeredTags (model "N") True "Everyone",c==cc "N"] of
    [s]->s
    _->error "fixture must offer exactly one bare N"
  correct l=lxCat l==cc "NP" && case lxItem l of
    LexTerm tm _ _ -> canonicalAC tm==canonicalAC standalone
    _ -> False
  hasAudit l=case lxItem l of
    LexTerm _ _ (Just st)->stKind st=="closed-pronoun-source-category"
    _->False
  noReading txt=all (null.srReadings) (prSentences(runPipelineWith (CCGBankParser (model "N")) (SourceId "everyone-determiner") txt))

-- Six meanings authored independently in everyone-N-origin-controls.jsonl before
-- source work; all retained readings must satisfy the DRS AND claim partition.
model :: String -> SemModel
model headCat = (defaultSemModel tags pos (Rules [(cc "N",cc "NP")] []) Set.empty)
 {smAlpha=0,smSeenRules=False}
 where
  obs=[("Everyone",headCat,"NN"),("everyone",headCat,"NN"),("A","NP[nb]/N","DT"),("Every","NP[nb]/N","DT"),("who","(NP\\NP)/(S[dcl]\\NP)","WP")
      ,("is","(S[dcl]\\NP)/(S[adj]\\NP)","VBZ")
      ,("tall","S[adj]\\NP","JJ"),("quiet","S[adj]\\NP","JJ")
      ,("not","(S[adj]\\NP)/(S[adj]\\NP)","RB"),(".",".",".")]
  tags=buildTagModel [(w,cc c)|(w,c,_)<-obs]
  pos=buildPOSModel [(w,t)|(w,_,t)<-obs]
atom :: String -> CanonCond
atom name=CanPred name [CRefT (CRef 0)]
box :: [CanonCond] -> Canonical
box=Canonical []
notAtom :: String -> CanonCond
notAtom name=CanNot (box [atom name])
cases :: [(String,[CanonCond],[CanonCond],[CanonCond])]
cases=
 [("Everyone is tall.",[],[atom "tall"],[atom "person",atom "tall"])
 ,("Everyone is quiet.",[],[atom "quiet"],[atom "person",atom "quiet"])
 ,("Everyone is not quiet.",[],[notAtom "quiet"],[atom "person",notAtom "quiet",atom "quiet"])
 ,("Everyone who is tall is quiet.",[atom "tall"],[atom "quiet"],[atom "person",atom "tall",atom "quiet"])
 ,("Everyone who is quiet is tall.",[atom "quiet"],[atom "tall"],[atom "person",atom "quiet",atom "tall"])
 ,("Everyone who is not tall is quiet.",[notAtom "tall"],[atom "quiet"],[atom "person",notAtom "tall",atom "tall",atom "quiet"])]
scopedChecks :: [Check]
scopedChecks =
 [expect ("all readings preserve person/scope/claims: " ++ txt)
    (length sentences == 1 && all (sentenceMatches implication embedded) sentences)
 |(txt,restriction,consequent,embedded)<-cases
 ,let implication=CanImp (Canonical [CRef 0] (atom "person":restriction)) (box consequent)
 ,let sentences=prSentences(runPipelineWith (CCGBankParser (model "N")) (SourceId "everyone-authored") txt)]

 where
  sentenceMatches implication embedded sentence =
    let readings=srReadings sentence
        matching=maybe False (matches implication embedded)
    in not (null readings) && matching (srDRS sentence)
       && all (matching . rrDRS) readings
  matches implication embedded d =
   let (as,rs,ps,es)=splitClaims d
   in canonicalize d == box [implication] && map (claimCond.fst) as == [implication]
      && null rs && null ps && map claimCond es == embedded


-- Two explicit seen-rule fixtures differ ONLY at the original N/NP-modifier
-- pair. The target NP/NP-modifier pair remains present in both. This is a
-- synthetic controlled inventory, not a claim that CCGbank contains this pair.
sourcePairModel :: Bool -> SemModel
sourcePairModel allowOriginal = (model "N") {smSeenRules=True, smSeen=pairs}
 where
  cats=map (eraseFeatures.cc)
    ["N","NP","NP/N","N/(S[dcl]\\NP)","NP\\NP","N\\N"
    ,"(NP\\NP)/(S[dcl]\\NP)","(N\\N)/(S[dcl]\\NP)"
    ,"S[dcl]","S[dcl]\\NP","S[adj]\\NP"
    ,"(S[dcl]\\NP)/(S[adj]\\NP)","."]
  pairs=Set.fromList [(a,b)|a<-cats,b<-cats,allowOriginal || (a,b)/=originalPair]
originalPair :: (CCat,CCat)
originalPair=(cc "N",cc "NP\\NP")
sourcePairChecks :: [Check]
sourcePairChecks=
 [expect "source pair fixtures differ only in original N/modifier evidence"
    (Set.difference (smSeen(sourcePairModel True)) (smSeen(sourcePairModel False))==Set.singleton originalPair)
 ,expect "target NP/modifier evidence cannot replace absent original N/modifier"
    (all (null.srReadings) (sentences False))
 ,expect "RED original source pair enables exact fused strict-person readings"
    (not(null(sentences True)) && all exact (sentences True))
 ]
 where
  sentences allow=prSentences(runPipelineWith (CCGBankParser(sourcePairModel allow))
      (SourceId "everyone-source-pair") "Everyone who is tall is quiet.")
  implication=CanImp (Canonical [CRef 0] [atom "person",atom "tall"]) (box [atom "quiet"])
  matching d=let (as,rs,ps,es)=splitClaims d
    in canonicalize d==box [implication] && map (claimCond.fst) as==[implication]
       && null rs && null ps && map claimCond es==[atom "person",atom "tall",atom "quiet"]
  exact sentence=not(null(srReadings sentence)) && maybe False matching (srDRS sentence)
     && all (maybe False matching.rrDRS) (srReadings sentence)
