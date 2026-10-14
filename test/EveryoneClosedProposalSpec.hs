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
import NL2Proof.Syntax.CCGBank (CCat, parseCCGCat)

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
main = runChecks "everyone-closed" (lexicalChecks ++ scopedChecks)
lexicalChecks :: [Check]
lexicalChecks =
 [expect "Everyone is reserved case-insensitively" (isClosedClass "Everyone")
 ,expectEq "standalone everyone NP is person-universal" [canonicalAC standalone] (entry "everyone" "NP")
 ,expect "paired everyone has person-restricted head" (case restrictedPronounEntries "Everyone" of
    Just (LexTerm tm _ _,_) -> canonicalAC tm == canonicalAC restricted
    _ -> False)
 ,expect "source N is not a free closed noun predicate" (null (entry "everyone" "N"))
 ,expect "conj NP is not an ordinary everyone entry" (null (entry "everyone" "NP[conj]"))
 ,expect "expletive NP is not an ordinary everyone entry" (null (entry "everyone" "NP[expl]"))
 ,expectEq "literal people retains person property" [canonicalAC (Lam "x" TyE person)] (entry "people" "N")
 ,expectEq "literal things retains thing property" [canonicalAC (Lam "x" TyE (App (pred1 "thing") x))] (entry "things" "N")
 ,expectEq "someone retains existential person" [canonicalAC (Lam "P" tyPred1 (TExists "x" TyE (TAnd person (App p x))))] (entry "someone" "NP")
 ,expectEq "everything retains existing unrestricted universal" [canonicalAC (Lam "P" tyPred1 (TForall "x" TyE (App p x)))] (entry "everything" "NP")
 ]


-- Six meanings authored independently in everyone-closed-controls.jsonl before
-- source work; all retained readings must satisfy the DRS AND claim partition.
model :: String -> SemModel
model headCat = (defaultSemModel tags pos (Rules [] []) Set.empty)
 {smAlpha=0,smSeenRules=False}
 where
  obs=[("Everyone",headCat,"NN"),("who","(NP\\NP)/(S[dcl]\\NP)","WP")
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
 ,let sentences=prSentences(runPipelineWith (CCGBankParser (model "NP")) (SourceId "everyone-authored") txt)]
 ++ [expect "bare offered N cannot fall through to everyone predicate"
       (null (lexicalSigns (model "N") 0 "Everyone"))
    ,expect "bare offered N cannot mint a fused NP-head certificate"
       (all (null . srReadings) (prSentences (runPipelineWith (CCGBankParser (model "N"))
         (SourceId "everyone-N-rejected") "Everyone who is tall is quiet.")))]
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
