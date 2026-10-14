-- | Unwired sparse OR-origin transport. This module checks location/typing,
-- not lexical licensing: the caller must supply independently certified origins.
-- Ordinary mode always returns the existing normalization and packing key.
module NL2Proof.Semantics.OrOccurrence
  ( Path, Mode(..), Failure(..), Evidence, PackingKey(..), Result(..)
  , passiveEvidence, evidenceSnapshot, evidenceFailure, evidenceInputs, assembleEvidence, dispatch
  ) where

import qualified Data.Map.Strict as M
import Data.List (isPrefixOf)
import NL2Proof.Semantics.Lambda

type Path = [Int]
data Mode = Ordinary | PairedPending | PairedActive deriving (Eq,Ord,Show)
data Failure = InvalidOrigins | IllTyped | StaleEvidence | UnsupportedBetaUse
             | UnsupportedConjunctionRewrite | UnavailableOrigin
             | TransportMismatch | InvalidModeTransition | InvalidEmbedding | OriginCollision deriving (Eq,Ord,Show)
-- Snapshot is always the term to which its map actually belongs. On failure it
-- is retained unchanged, rather than being relabelled as the rewritten term.
data Evidence a = Available Mode Term (M.Map Path a)
                | Untransported Mode Term (M.Map Path a) Failure
                | AssemblyUnavailable Mode Term (M.Map Path a)
                    [(Path,Term,Evidence a)] Failure deriving (Eq,Show)
data PackingKey a = OrdinaryKey Term | PairedKey Mode Term (M.Map Path a)
  deriving (Eq,Ord,Show)
data Result a = Result
  { resultTerm :: Term, resultEvidence :: Evidence a, resultKey :: PackingKey a }
  deriving (Eq,Show)

evidenceSnapshot :: Evidence a -> (Term,M.Map Path a)
evidenceSnapshot (Available _ t m)=(t,m)
evidenceSnapshot (Untransported _ t m _)=(t,m)
evidenceSnapshot (AssemblyUnavailable _ t m _ _)=(t,m)
evidenceFailure :: Evidence a -> Maybe Failure
evidenceFailure Available{}=Nothing
evidenceFailure (Untransported _ _ _ f)=Just f
evidenceFailure (AssemblyUnavailable _ _ _ _ f)=Just f
-- Original child snapshots retained when an ordinary assembly is unavailable.
evidenceInputs :: Evidence a -> [(Path,Term,Evidence a)]
evidenceInputs (AssemblyUnavailable _ _ _ inputs _)=inputs
evidenceInputs _=[]

children :: Term -> [Term]
children t=case t of
 Lam _ _ a->[a]; TForall _ _ a->[a]; TExists _ _ a->[a]; TNot a->[a]
 App a b->[a,b]; TAnd a b->[a,b]; TOr a b->[a,b]; TImp a b->[a,b]; TEq a b->[a,b]
 _->[]
orPaths :: Term -> [Path]
orPaths t=(case t of TOr{}->[[]]; _->[]) ++
 [i:p|(i,c)<-zip [0..](children t),p<-orPaths c]
valid :: Ctx -> Term -> M.Map Path a -> Either Failure ()
valid ctx t m=case typeOf ctx t of
 Left _->Left IllTyped
 Right _ | M.keys m == orPaths t->Right ()
         | otherwise->Left InvalidOrigins
passiveEvidence :: Ctx -> Term -> M.Map Path a -> Evidence a
passiveEvidence ctx t m=case valid ctx t m of
 Right ()->Available Ordinary t m
 Left f->Untransported Ordinary t m f
submap :: Int -> M.Map Path a -> M.Map Path a
submap i m=M.fromList[(ps,a)|(j:ps,a)<-M.toList m,j==i]
prefix :: Int -> M.Map Path a -> M.Map Path a
prefix i=M.mapKeys(i:)
-- Only positions of genuinely free occurrences; production subst performs all
-- renaming and term construction. Alpha-renaming leaves these paths unchanged.
freeSites :: String -> Term -> [Path]
freeSites name t=case t of
 Var v | v==name->[[]]
 Lam v _ _ | v==name->[]
 TForall v _ _ | v==name->[]
 TExists v _ _ | v==name->[]
 _->[i:p|(i,c)<-zip[0..](children t),p<-freeSites name c]

-- No copied lambda evaluator: all resulting terms come from production
-- normalize/subst. This walk computes only the parallel map at their rewrites.
transport :: Term -> M.Map Path a -> Either Failure (M.Map Path a)
transport t m=case t of
 App f arg->do
  fm<-transport f(submap 0 m)
  am<-transport arg(submap 1 m)
  let fn=normalize f; an=normalize arg
  case fn of
   Lam v _ body->do
    let sites=freeSites v body
    if not(M.null am) && length sites/=1 then Left UnsupportedBetaUse else Right ()
    let substituted=subst v an body
        bm=submap 0 fm
        inserted=[M.mapKeys(p++)am|p<-sites]
    -- A free variable is a leaf, so inserted keys cannot collide with bm.
    transport substituted(M.unions(bm:inserted))
   _->Right(M.union(prefix 0 fm)(prefix 1 am))
 _->do
  ms<-sequence[transport c(submap i m)|(i,c)<-zip[0..](children t)]
  Right(M.unions(M.filterWithKey(\p _->null p)m : zipWith prefix[0..]ms))

checked :: Ctx -> Term -> Evidence a -> Either Failure (Term,M.Map Path a)
checked _ _ Untransported{}=Left UnavailableOrigin
checked _ _ AssemblyUnavailable{}=Left UnavailableOrigin
checked ctx t (Available _ snapshot m)
 | t/=snapshot=Left StaleEvidence
 | otherwise=do
   valid ctx t m
   nm<-transport t m
   let n=normalize t
   valid ctx n nm
   if typeOf ctx t/=typeOf ctx n then Left TransportMismatch else Right ()
   if not(M.null nm) && simplifyConj n/=n
      then Left UnsupportedConjunctionRewrite
      else let out=simplifyConj n in valid ctx out nm >> Right(out,nm)

dispatch :: Ctx -> Mode -> Term -> Evidence a -> Either Failure (Result a)
dispatch ctx mode t ev
 | evidenceMode ev==PairedActive && mode/=PairedActive=Left InvalidModeTransition
 | evidenceMode ev==PairedPending && mode==Ordinary=Left InvalidModeTransition
dispatch ctx Ordinary t ev=
 let out=simplifyConj(normalize t)
     evidence=case checked ctx t ev of
       Right (same,m) | same==out->Available Ordinary out m
       Left f->case evidenceFailure ev of
         Just _->ev
         Nothing->let(old,m)=evidenceSnapshot ev in Untransported Ordinary old m f
       _->let(old,m)=evidenceSnapshot ev in Untransported Ordinary old m TransportMismatch
 in Right(Result out evidence(OrdinaryKey(canonicalAC out)))
dispatch ctx mode t ev=do
 (out,m)<-checked ctx t ev
 Right(Result out(Available mode out m)(PairedKey mode(canonical out)m))

-- Once pairing begins, a caller cannot erase the obligation by dispatching the
-- same evidence through Ordinary. Lexical justification of promotion is external.
evidenceMode :: Evidence a -> Mode
evidenceMode (Available mode _ _)=mode
evidenceMode (Untransported mode _ _ _)=mode

evidenceMode (AssemblyUnavailable mode _ _ _ _)=mode

-- | Assemble evidence only at a trusted semantic constructor. Origin payloads
-- themselves remain producer-certified; this function authenticates neither
-- lexical categories nor token spans. Inputs identify ORIGINAL child subterms,
-- e.g. located coordination's clLeftPath/clRightPath, before normalization.
-- Ordinary failure keeps legacy semantics possible and retains all child audit
-- snapshots; an active/pending import fails closed. No Eq constraint on origins
-- is needed: collisions are rejected by path, never merged by payload equality.
assembleEvidence :: Ctx -> Mode -> Term -> [(Path,Term,Evidence a)]
                 -> M.Map Path a -> Either Failure (Evidence a)
assembleEvidence ctx mode out inputs introduced
 | any (\(_,_,ev)->evidenceMode ev>mode) inputs=Left InvalidModeTransition
 | otherwise=case assemble of
    Right m->Right(Available mode out m)
    Left failure | mode==Ordinary->Right(AssemblyUnavailable mode out introduced inputs failure)
                 | otherwise->Left failure
 where
  paths=[p|(p,_,_)<-inputs]
  overlap=or [p `isPrefixOf` q || q `isPrefixOf` p
             |(i,p)<-zip[0::Int ..]paths,(j,q)<-zip[0::Int ..]paths,i<j]
  assemble=do
   if overlap then Left InvalidEmbedding else Right ()
   ms<-mapM importChild inputs
   let allMaps=introduced:ms
       count=sum(map M.size allMaps)
       merged=M.unions allMaps
   if M.size merged/=count then Left OriginCollision else Right ()
   valid ctx out merged
   Right merged
  importChild (path,inserted,ev)=do
   if subterm path out/=Just inserted then Left InvalidEmbedding else Right ()
   case ev of
    Available _ snapshot m->do
     if snapshot/=inserted then Left StaleEvidence else Right ()
     valid ctx snapshot m
     Right(M.mapKeys(path++)m)
    _->Left UnavailableOrigin
  subterm [] t=Just t
  subterm (i:is) t
   | i>=0 && i<length(children t)=subterm is(children t!!i)
   | otherwise=Nothing
