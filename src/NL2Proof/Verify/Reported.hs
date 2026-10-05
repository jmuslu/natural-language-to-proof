{-# LANGUAGE DataKinds #-}

-- | Reported and presupposed claims: content a text /attributes/ (@"Bob said
-- that the cat is red"@) or /presupposes/ (@"Bob knows that the cat is red"@),
-- as opposed to content it asserts.
--
-- This is the logical floor of the grounded-vs-hearsay distinction. The DRT
-- stage keeps attitude content in a box attached to the attitude condition
-- ('NL2Proof.DRT.Types.CAtt'); here that box's conditions become
-- @'Claim' 'Reported@ values with their attribution chain. The attitude
-- condition itself (@say(Bob, K)@), at the top level, is an ordinary asserted
-- claim: the text does assert that Bob said something.
--
-- == The polarity rule
--
-- Only an attitude condition at the /top level/ of the main DRS yields reported
-- claims, and inside a report only attitudes at the top of that report recurse.
-- @"Bob did not say that P"@ yields no reported claim: the text denies the
-- report. The same holds under a conditional or a disjunction. Reported claims
-- are the top-level conditions of the report box, so @"Bob said that the cat is
-- not red"@ reports @~red(cat)@ and nothing else.
--
-- The same rule governs assertion ('splitClaims'): only the top-level
-- conditions of the main box are asserted. Under a negation the attitude
-- condition itself is not asserted either: @"Bob did not say that P"@ asserts
-- @~[say(Bob, K)]@ and nothing else.
--
-- == The guard
--
-- A 'Reported' carries a @'Claim' 'Reported@, which
-- 'NL2Proof.Verify.Oracle.confirm' rejects at compile time. The constructor is
-- not exported and the fields are positional, so a report cannot be forged or
-- have its attribution edited away. To check reported content against the
-- world, promote it with 'NL2Proof.Verify.ClaimKind.asCandidate' and ask an
-- oracle: the token is for the candidate, and says nothing about the report.
-- @test/compile-fail/Reported*.hs@ check this with the compiler.
module NL2Proof.Verify.Reported
  ( -- * Attribution
    Attribution(..)
    -- * Reported claims
  , Reported
  , reportedClaim'
  , reportedContent
  , reportedChain
  , reportedProv
  , reportedSource
  , reportedVerb
    -- * Presupposed claims
  , Presupposed
  , presupposedClaim'
  , presupposedProv
    -- * Construction
  , splitClaims
    -- * Rendering
  , renderAttribution
  , renderReported
  , renderPresupposed
  ) where

import Data.List (intercalate)

import NL2Proof.DRT.Canonical
import NL2Proof.DRT.Types
import NL2Proof.Provenance
import NL2Proof.Semantics.Intensional (isFactiveVerb)
import NL2Proof.Verify.ClaimKind

-- | One attitude level a claim is embedded under: the verb (a lemma), its
-- holder (and addressee, for @tell@), and whether the verb is factive.
data Attribution = Attribution
  { attVerb    :: String
  , attHolders :: [CTerm]
  , attFactive :: Bool
  }
  deriving (Eq, Ord, Show)

-- | A claim the text attributes rather than asserts.
--
-- Positional on purpose: exported record selectors would permit
-- @r { chain = [] }@ outside this module even with the constructor hidden.
data Reported = MkReported (Claim 'Reported) [Attribution] Prov
  deriving (Eq, Show)

reportedClaim' :: Reported -> Claim 'Reported
reportedClaim' (MkReported c _ _) = c

-- | The content, for inspection. Canonically renamed consistently with the
-- asserted facts of the same claim table.
reportedContent :: Reported -> CanonCond
reportedContent = claimCond . reportedClaim'

-- | The attitudes it is embedded under, outermost first. In @"Alice said that
-- Bob believes that P"@, @P@ has the chain @[say(Alice), believe(Bob)]@ and
-- @believe(Bob, P)@ has @[say(Alice)]@.
reportedChain :: Reported -> [Attribution]
reportedChain (MkReported _ ch _) = ch

reportedProv :: Reported -> Prov
reportedProv (MkReported _ _ p) = p

-- | The attributed source: the holder of the outermost attitude, i.e. who the
-- text says the content came from.
reportedSource :: Reported -> Maybe CTerm
reportedSource r = case reportedChain r of
  (Attribution _ (h : _) _ : _) -> Just h
  _                             -> Nothing

-- | The verb of the innermost attitude (the one whose complement this is).
reportedVerb :: Reported -> Maybe String
reportedVerb r = case reverse (reportedChain r) of
  (a : _) -> Just (attVerb a)
  []      -> Nothing

-- | A claim the text presupposes: a condition of a top-level 'CPresup' box.
data Presupposed = MkPresupposed (Claim 'Presupposed) Prov
  deriving (Eq, Show)

presupposedClaim' :: Presupposed -> Claim 'Presupposed
presupposedClaim' (MkPresupposed c _) = c

presupposedProv :: Presupposed -> Prov
presupposedProv (MkPresupposed _ p) = p

-- | Split a DRS into asserted claims (with provenance), reported claims,
-- presupposed claims and embedded claims.
--
-- __Only a top-level condition of the main box is asserted__ ('topCond' is
-- the one place that decides it). A negation, conditional or disjunction at
-- the top level is asserted /whole/, as the single condition it is: @~[red(cat)]@
-- for @"The cat is not red"@, the rule @[red(x)] => [big(x)]@ for @"All red
-- things are big"@. Nothing inside such a box is asserted: the text denies,
-- conditions on or offers it, and a fact of the table becomes a genealogy
-- premise that an oracle may confirm. Those inner conditions (at every depth,
-- including attitudes and their content under a negation) are returned as
-- @'Claim' 'Embedded@, which 'NL2Proof.Verify.Oracle.confirm' rejects at
-- compile time.
--
-- Reported claims follow the polarity rule in the module header. Presupposed
-- claims are the conditions of top-level 'CPresup' boxes. All four share one
-- canonical renaming, so a reported @red(r0)@ and an asserted @red(r0)@ are
-- about the same referent.
splitClaims :: DRS -> ([(CanonCond, Prov)], [Reported], [Presupposed], [Claim 'Embedded])
splitClaims top = mconcat (zipWith topCond (drsConds top) (canonConds canon))
  where
    canon = canonicalize top

    topCond c k = case (c, k) of
      (CAtt v _ x _, CanAtt _ hs kx) ->
        ([(k, condProv c)], reported [attribution v hs] x kx, [], [])
      (CPresup x _, CanPresup kx) ->
        ([], [], zipWith (\c' k' -> MkPresupposed (presupposedClaim k') (condProv c'))
                         (drsConds x) (canonConds kx), [])
      _ -> ([(k, condProv c)], [], [], map embeddedClaim (below k))

    -- Every condition strictly inside a top-level negation, conditional or
    -- disjunction, at every depth. None of it is asserted.
    below k = case k of
      CanNot x   -> inside x
      CanImp a b -> inside a ++ inside b
      CanOr a b  -> inside a ++ inside b
      _          -> []
    inside (Canonical _ ks) = concatMap (\k' -> k' : nested k') ks
    nested k = case k of
      CanAtt _ _ x -> inside x
      CanPresup x  -> inside x
      _            -> below k

    -- The top-level conditions of a report box, each a reported claim; an
    -- attitude at the top of the box recurses one level deeper; a presupposed
    -- box inside the report contributes its conditions under the same chain.
    reported chain (DRS _ cs) (Canonical _ ks) = concat (zipWith (reportCond chain) cs ks)
    reportCond chain c k = case (c, k) of
      (CPresup x _, CanPresup kx) -> reported chain x kx
      (CAtt v _ x _, CanAtt _ hs kx) ->
        MkReported (reportedClaim k) chain (condProv c)
          : reported (chain ++ [attribution v hs]) x kx
      _ -> [MkReported (reportedClaim k) chain (condProv c)]

    attribution v hs = Attribution v hs (isFactiveVerb v)

renderAttribution :: Attribution -> String
renderAttribution a =
  attVerb a ++ "(" ++ intercalate ", " (map renderCTerm (attHolders a)) ++ ")"
    ++ (if attFactive a then " [factive]" else "")

renderReported :: Reported -> String
renderReported r =
  renderCanonCond (reportedContent r)
    ++ "  <- reported via " ++ intercalate " > " (map renderAttribution (reportedChain r))

renderPresupposed :: Presupposed -> String
renderPresupposed p = renderCanonCond (claimCond (presupposedClaim' p)) ++ "  <- presupposed"
