# Technical reference: representations and discriminating examples

This reference retains the useful findings from the original stage-by-stage
trace. It records the current code's scope, fixtures that distinguish competing
designs, and concrete extension points. Historical proposition IDs appear only
where useful for older code comments. The operating contract is in
[ARCHITECTURE.md](ARCHITECTURE.md); live experiments and falsification priorities
are in [RESEARCH_THREADS.md](RESEARCH_THREADS.md).

## 1. Source, syntax and typed meaning

For `Every student reads a book.`, the fragment lexicon gives:

| Unit | Category | Meaning shape |
|---|---|---|
| `every` | `NP/N` | universal generalized quantifier |
| `student`, `book` | `N` | unary predicate |
| `reads` | `(S\NP)/NP` | transitive relation lifted over two generalized quantifiers |
| `a` | `NP/N` | existential generalized quantifier |

The application-only fragment derives the surface reading
`forall x. student(x) -> exists y. book(y) and read(x,y)`.
The broader CCGbank parser also uses composition, coordination, punctuation and
learned type changes. Its chart caps and supertag inventory bound search;
successful root-category reconstruction does not establish semantic fidelity.
Corpus-attested categories and synthesized meaning skeletons remain distinct.

**Spans and segmentation.** Word spans are half-open source intervals. Lexical
units form a lattice over word boundaries, allowing `red dragon` and `red` plus
`dragon` to coexist. A complete path is a segmentation; CKY can retain parses
from multiple paths. Span envelopes include intervening spaces and may include
noncontributing text. More lexical edges increase ambiguity and actual runtime
even though word-boundary chart indexing is unchanged.

**Typing and normalization.** `catTy` maps both slash directions to function
types, so semantic typing alone cannot recover syntactic direction. The fragment
uses generalized-quantifier NP types for names as well as quantified phrases.
Beta normalization and alpha-equivalence are different operations: the former
reduces application; the latter disregards bound-variable names. Strong
normalization applies to well-typed simply typed terms, not every malformed
value constructible using the public `Term` representation. First-order
lowering still has a supported fragment to check.

Code: [Tokenize](src/NL2Proof/Syntax/Tokenize.hs),
[CCG](src/NL2Proof/Syntax/CCG.hs),
[Lambda](src/NL2Proof/Semantics/Lambda.hs),
[CCGParse](src/NL2Proof/Syntax/CCGParse.hs).
Checks: [Spec](test/Spec.hs) `spanChecks`, `latticeChecks`, `lambdaChecks`;
[CCGBankSpec](test/CCGBankSpec.hs) `sentenceParseChecks`, `supertagChecks`,
`templateChecks`, `lexChecks`.

## 2. Provenance and DRS identity

`Prov` is a derivation tree with source-span leaves and rule nodes. Source-set
union loses multiplicity; span envelopes lose gaps; size and depth lose tree
shape. Retain the tree when those distinctions matter. Genealogy separately
adds addressable evidence and claim nodes with shared alternative support.
The useful distinction is missing identity/sharing in this representation,
not a general impossibility theorem about folds or graph encodings.

DRS universes and conditions are lists. `mergeDRS` concatenates them; distinct
sentence-local referents must be freshened before combining boxes.
`freshenAgainst` enforces that at the discourse merge, preserving provenance.
Without it, `A student arrived. A professor walks.` could incorrectly identify
both individuals as one `x`.

Accessibility reads the top-level universe. Quantifier-local referents in
`Every student reads a book.` do not become available to a subsequent pronoun.
Among accessible candidates, **recency is source position**, not list order or
quantifier nesting. The discriminating fixture lowers both scope readings of
`A student reads a book.` and resolves `It arrived.`; both must select `book`.

Code: [Provenance](src/NL2Proof/Provenance.hs),
[DRT.Types](src/NL2Proof/DRT/Types.hs), [DRT.Build](src/NL2Proof/DRT/Build.hs).
Checks: [Spec](test/Spec.hs) `provenanceChecks`, `anaphoraChecks`,
`freshnessChecks`, `recencyChecks`; [Stage2Spec](test/Stage2Spec.hs)
`scopeRecencyChecks`.

### Canonical equality and fusion (P5.2, P5.4, P12)

| Operation | What it removes | What it does not establish |
|---|---|---|
| `canonicalize` | provenance and referent naming distinctions | commutative or multiset normal form |
| `Fusion.compress` | duplicate canonical conditions and their order, recursively | arbitrary logical equivalence |
| Fingerprint similarity | supplies a graded comparison | transitive identity suitable for exact deduplication |

The equivalent formulas `not (p or q)` and `not p and not q` have different
canonical shapes and remain distinct. Finite-model counterexamples can disprove
equivalence, but agreement on the enumerated domains cannot certify unrestricted
first-order equivalence. Proven equivalences for a restricted logic could be a
future compression rule; general decidability is not assumed.

`Fusion.detachable` performs restricted modus ponens only when the antecedent
box binds no referents. Removing this guard would treat universal DRS duplexes
as closed material implications without constructing required witnesses.

Code: [Canonical](src/NL2Proof/DRT/Canonical.hs),
[Fusion](src/NL2Proof/Fusion.hs).
Checks: [Spec](test/Spec.hs) `canonicalChecks`;
[SubstrateSpec](test/SubstrateSpec.hs) `fusionChecks`.

## 3. Scope, coupling and finite-model meaning

`scopeAlternatives` separates a quantifier prefix from its core and generates
orders that respect variable dependencies. The original order round-trips;
generated readings remain closed and typed. A quantifier inside a restrictor is
not lifted by this fragment. The implementation filters all permutations;
direct generation of valid topological orders could avoid rejected candidates,
but the number of valid orders itself can still be factorial.

For the example above, the inverse reading is
`exists y. book(y) and forall x. student(x) -> read(x,y)`.
It implies the surface reading; the converse fails when there are no students
and no books. Exhaustive fixture counts are:

| Domain size | Models | Surface true | Inverse true |
|---|---:|---:|---:|
| 1 | 8 | 5 | 3 |
| 2 | 256 | 137 | 119 |
| 3 | 32,768 | 17,303 | 15,465 |

These are finite-model results for the declared uninterpreted predicates, not
language-wide frequencies. In this example, the two truth sets form a chain.
The four coupling readings of `ancient Chinese red dragon` are pairwise
incomparable in the fixture when fused predicates have no added lexical axioms;
their truth sets nevertheless overlap. The standalone probe enumerates 524,288
domain-size-two models; the regression suite uses a smaller domain.

A distribution over the **speaker's intended reading** can be normalized even
when the readings' truth sets overlap. Probabilities that their propositions are
**true in a world** are different events and need not sum to one. This distinction
avoids treating overlapping propositions as mutually exclusive world states.

Code: [Alternatives](src/NL2Proof/Stage2/Alternatives.hs),
[Model](src/NL2Proof/Stage2/Model.hs).
Checks: [Stage2Spec](test/Stage2Spec.hs) `scopeChecks`, `modelChecks`,
`orderChecks`; [chain/antichain probe](docs/chain-antichain-probe.hs).

## 4. Ranking and its assumptions

`Dist` supports finite weights, normalization, pushforward, conditioning and
reweighting. These operations can fail on empty support. `softmax` sharpens
scores; `entropy` measures the resulting distribution. The API has no generic
bind/join, but probabilistic steps can already be composed explicitly.
Normalization, support changes and floating-point input handling need their
own invariants before stronger analytic claims.

RSA alternates listener and speaker calculations:

```text
L0(m | u) proportional to prior(m) * compatibility(u,m)
Sk(u | m) proportional to exp(alpha * (log L(k-1)(m | u) - cost(u)))
Lk(m | u) proportional to prior(m) * Sk(u | m)
```

`listenerTable` shares lower-level computations and map lookups. Depth is an
explicit parameter; convergence or contraction has not been established for the
implemented operator. A fixed-point theorem needs a domain on which the actual
operator is defined and continuous, including boundary/support behavior.

The reference-game test produces pragmatic effects with a uniform prior and an
asymmetric lexicon. A scope-signature prior cannot distinguish coupling readings
sharing that signature; finite-model informativity can. A common additive score
shift cancels in a softmax. Changing one utterance's cost may still change RSA's
posterior through the speaker's meaning-dependent normalization; it is not
generally inert.

Fingerprints retain content and structural components: scope permutations have
identical predicate content but different quantifier order, while coupling can
change predicate content with little structural change. The weights combining
these components are stipulated. Compare separate coordinates with a fitted
combination on independent tasks before treating similarity as calibrated.

Code: [Distribution](src/NL2Proof/Stage2/Distribution.hs),
[RSA](src/NL2Proof/Stage2/RSA.hs),
[Fingerprint](src/NL2Proof/Stage2/Fingerprint.hs).
Checks: [Stage2Spec](test/Stage2Spec.hs) `distChecks`, `referenceGameChecks`,
`scopeRankingChecks`, `fingerprintChecks`, `pipelineChecks`.

## 5. SDRT and the incomplete antecedent space

The discourse threader uses a right-frontier graph. A relation between segments
`a` and `b` affects accessibility for the *next* segment; `b` sees the frontier
before its own attachment. `Committed` chooses an edge relation and filters
antecedents. `Marginal` sums over possible relations for the most recent edge
while holding the earlier graph committed.

The discriminating three-segment fixture is
`A student arrived. Mary smiles. She reads a book.` Flat threading resolves the
pronoun; committed coordinating edges lose its antecedent; marginal threading
retains it with mass about `0.488`, the subordinating mass of the uncertain edge.
The original two-segment fragment cases cannot distinguish these policies.

Important limits:

- **One-edge truncation has no approximation bound.** Four-segment examples lose
  an antecedent that full structure marginalization retains. Full support grows
  exponentially in edge choices, so compare exact small cases with explicitly
  budgeted approximations.
- **Accessibility mass is not a distribution over referents.** Multiple
  referents may be accessible together. With one free edge, nested frontiers
  yield only two mass levels; with two free edges the tested focal sets cross.
  Those examples do not prove every longer discourse is non-nested.
- **Some algebra choices coincide on this restricted case.** With a Boolean
  accessibility indicator, `max/product` and `max/min` give the same one-edge
  number. Multi-edge witnesses can distinguish them. Maximizing over licensors
  differs from choosing the maximum-probability relation first.
- **No-cue commitment is sensitive to a prior.** `Continuation` has weight
  `1.2`; a factor `1.2` change can change relation kind and accessibility.
  Cue-driven fixture decisions have larger margins, checked separately.
- **Pronoun percolation is incomplete.** A resolved pronoun does not introduce
  a new top-level referent, so successive coordinating clauses can lose it.
- **Antecedent assignments are not reading alternatives.** Frontier mass is
  indexed by `Ref`; RSA readings are indexed by `Int`. Materializing the joint
  `(scope, coupling, antecedent assignment)` space is the missing connection.
  Any prior combination must account for dependencies between these choices.

Code: [SDRT](src/NL2Proof/Stage2/SDRT.hs),
[Threading](src/NL2Proof/Stage2/Threading.hs).
Checks: [Stage2Spec](test/Stage2Spec.hs) `sdrtChecks`, `threadingChecks`,
`muChecks`, `cueSensitivityChecks`;
[cue sensitivity probe](docs/cue-weight-sensitivity.hs).

## 6. Verification, retraction and reward

Verification retains claim provenance and alternative supports; fusion keeps
exact confirmed content. `Selection` records a decision and rejected candidates.
Those candidates need not be equivalent to the chosen one, so selection itself
is not generally a mathematical quotient.

The retraction fixture has `n0 -> n3` and two independent alternatives
`n0 -> n2`, `n1 -> n2`. With both premises confirmed, all four nodes are
supported. Withdraw `n0`: `n0` and `n3` lose support; `n2` survives through `n1`.
An unsupported cycle grounds nothing. Scope-specific receipt history is now
implemented; richer conflict resolution remains distinct from mere withdrawal.

Reward tests expose three scalar blind spots: adding uncovered claims leaves
the scalar unchanged; different source coverage can score equally; and two
derivations of one claim can score like repetition. `rwYield`, source-span
coordinates, corroboration and novelty retain information needed for an
external objective. Distinct provenance trees are not proof of independent
data or independent oracle judgments. `hasIndependentSupport` is false on a
premise-only graph; use derivation-bearing fixtures to test that mechanism.

Code: [Genealogy](src/NL2Proof/Genealogy.hs), [Reward](src/NL2Proof/Reward.hs),
[Oracle](src/NL2Proof/Verify/Oracle.hs).
Checks: [SubstrateSpec](test/SubstrateSpec.hs) `cycleChecks`,
`retractionChecks`, `selfAgreementChecks`, `scalarBlindSpotChecks`,
`paretoChecks`; [admission boundary](scripts/check-oracle-boundary.sh).
The current external protocol and typed multi-hop experiments are documented
in [ORACLE_BRIDGE.md](ORACLE_BRIDGE.md) and [REASONING.md](REASONING.md).

## 7. Representation extensions worth testing

These are design options, not dependencies that block current experiments:

| Extension | Existing hook | Discriminating test |
|---|---|---|
| Modifier stratification | [Modifier](src/NL2Proof/Stage2/Modifier.hs): intersective, classificatory, subsective, privative; `ambiguousModifiers` | Separate context-sensitive `old friend` from `old man`; a privative reading must not entail its head |
| Nested coupling | `couplingCandidates` currently fuses modifiers with the final head | Distinguish `Chinese red-dragon` from a red `Chinese-dragon`; current head-only candidates miss nested structure |
| Adjective-order evidence | Scope ordering machinery and uncertain modifier classes | A total hierarchy needs sortedness; a partial hierarchy admits several orders. Test whether markedness helps class inference on held-out text |
| Plurals and full-NP anaphora | DRS, model domain and candidate generator | Distinguish fresh/coreferent groups and collective/distributive readings; add numeral, group-domain and NP-matching support before claiming coverage |
| Text overlap and multiset identity | `Prov` leaves and canonical DRS | Preserve exact contributing spans and duplicate multiplicity when the downstream query needs them |
| Richer belief revision | Existing persistent receipt revisions and least-fixed-point support | Compare minimal conflict repair with precise withdrawal on independently specified changed worlds |

Plural representations could enrich the entity domain with group structure;
that proposal does not by itself supply numeral semantics, distributivity,
lexical constraints or discourse matching. Likewise, generating more candidates
requires explicit search budgets and retrieval tests. Unbounded computation and
unmeasured coverage are not substitutes for a falsifiable experiment.
