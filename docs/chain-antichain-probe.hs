import NL2Proof.Fragment
import NL2Proof.Semantics.Lambda
import NL2Proof.Stage2.Alternatives
import NL2Proof.Stage2.Model

main :: IO ()
main = do
  let Just cq = caseById "quantified"; sq = head (caseForms cq)
      Just cc = caseById "coupling";   sc = head (caseForms cc)
  report "scope   " (scopeAlternatives sq)
  report "coupling" (couplingAlternatives (const True) sc)
 where
  report lbl rs = do
    let sig = signatureOf (foldr1 TAnd rs)
        ms  = enumerateModels 2 sig
        n   = length rs
    putStrLn (lbl ++ ": " ++ show n ++ " readings over " ++ show (length ms) ++ " models")
    sequence_ [ putStrLn ("   " ++ show i ++ " vs " ++ show j
                  ++ "  i|=j=" ++ show (entails ms (rs!!i) (rs!!j))
                  ++ "  j|=i=" ++ show (entails ms (rs!!j) (rs!!i))
                  ++ "  -> " ++ verdict (entails ms (rs!!i) (rs!!j)) (entails ms (rs!!j) (rs!!i)))
              | i <- [0..n-1], j <- [i+1..n-1] ]
  verdict True True   = "EQUIVALENT"
  verdict True False  = "chain (i stronger)"
  verdict False True  = "chain (j stronger)"
  verdict False False = "ANTICHAIN (incomparable)"
