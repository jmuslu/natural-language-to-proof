-- Independent red design controls; deliberately outside cabal release suites.
-- Run: runghc -isrc test/ModifierOrderProposalSpec.hs
-- No corpus load. Failing order checks must not be fixed by renaming definites.
module Main (main) where
import Control.Monad (unless)
import System.Exit (exitFailure)
import NL2Proof.Semantics.CCGSem
import NL2Proof.Semantics.Lambda
import NL2Proof.Syntax.CCGBank (parseCCGCat)
import NL2Proof.DRT.Build (describeIota)

main :: IO ()
main = do
  let cc = either error id . parseCCGCat
      lexical w c = case closedEntries 0 w (cc c) of
        LexTerm t _ _ : _ -> t
        _ -> error ("Missing closed entry: " ++ w)
      modifier w = case openTemplate w (cc "N/N") of
        Just (LexTerm t _ _) -> t
        _ -> error ("Missing modifier: " ++ w)
      noun = pred1 "cat"
      modified ws = foldr (App . modifier) noun ws
      subject d ws = normalize (apply (lexical d "NP[nb]/N") [modified ws,pred1 "sleep"])
      leaves (TAnd a b) = leaves a ++ leaves b
      leaves t = [t]
      predicateNames ts = sequence [case t of
                         App (Con n _) (Var _) -> Just n
                         _ -> Nothing | t <- ts]
      existential d ws = case subject d ws of
        TExists _ _ b -> predicateNames (leaves b)
        _ -> Nothing
      universal ws = case subject "every" ws of
        TForall _ _ (TImp a _) -> predicateNames (leaves a)
        _ -> Nothing
      definiteName nominal = case normalize (apply (lexical "the" "NP[nb]/N") [nominal,pred1 "sleep"]) of
        App _ (App (Con name _) property) | name == iotaName -> describeIota property
        _ -> error "Definite failed to retain iota description"
      description ws = definiteName (modified ws)
      eagle = normalize (App (modifier "bald") (pred1 "eagle"))
      relVP = case openTemplate "quiet" (cc "S[dcl]\\NP") of
        Just (LexTerm t _ _) -> t
        _ -> error "Missing relative VP"
      relative nounTerm = normalize (apply (lexical "that" "(N\\N)/(S[dcl]\\NP)") [relVP,nounTerm, Var "x"])
      relativeOrder ws = predicateNames (leaves (relative (modified ws)))
      -- A category-only fallback cannot license a relational noun compound.
      -- Until a lexical/contextual analysis exists, the reviewed goal is abstention.
      compoundFailsClosed = case openTemplate "stone" (cc "N/N") of
        Nothing -> True
        _ -> False
      checks =
        [ ("a single modifier: head then modifier then scope", existential "a" ["red"] == Just ["cat","red","sleep"])
        , ("a multiple modifiers: head then surface order", existential "a" ["blue","young"] == Just ["cat","blue","young","sleep"])
        , ("every single modifier: head then modifier", universal ["red"] == Just ["cat","red"])
        , ("every multiple modifiers: head then surface order", universal ["blue","young"] == Just ["cat","blue","young"])
        , ("the bald eagle retains exact rigid identifier", definiteName eagle == "bald eagle")
        , ("the blue young cat retains surface description", description ["blue","young"] == "blue young cat")
        , ("relative property follows nominal head", relativeOrder [] == Just ["cat","quiet"])
        , ("relative with modifier retains head/modifier/relative order", relativeOrder ["red"] == Just ["cat","red","quiet"])
        , ("unknown noun compound does not become two intersective predicates", compoundFailsClosed)
        ]
  mapM_ (\(n,ok) -> putStrLn ((if ok then "PASS " else "FAIL ") ++ n)) checks
  unless (all snd checks) exitFailure
