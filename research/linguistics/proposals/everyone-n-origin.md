# Everyone offered-N origin: second-step design, not source authorization

Base2d1cae6. First-step NP-only candidate ecd75dd is frozen on its own branch and
must pass coordinator trial before this proposal can authorize source. No shared
source edited here. Six independent authored strict-person golds remain exactly
those from0475ad8/ecd75dd; no new meanings are derived from parser observations.

## Exact lexical operation

The old173 baseline gives all6 new Everyone cases wrong everyone(x). First-step
reservation may turn those into no-parse if only N is offered. This second step
would reinterpret an actual offered **bare N** for exact case-folded everyone as
an entire strict-person generalized quantifier NP. It is a closed lexical
category repair, not N→NP semantic type raising:

`Everyone:N (original offer) => Everyone:NP (closed entry)`
`λP.∀x.(person(x) → P(x)) : (e→t)→t`.

No ordinary N term is emitted: neither everyone(x) nor a substitute person noun.
Thus a/an/every cannot consume it as N and turn a person-universal pronoun into an
existential or separately quantified noun. Literal people/things remain their
existing N properties; something/everything, names, arbitrary nouns and prefixes
such as everyoneElse receive no new conversion. Do not infer the repair from
capitalization, POS guessing, term shape, or presence of person in a final DRS.

Proposed pure lexical helper:

```haskell
closedPronounReanalysis :: String -> CCat -> Maybe (CCat, LexItem)
-- accepts casefold(surface)=="everyone" && original==N[] only
-- returns (NP[], exact approved closedEntries everyone NP term)
-- no return if the NP closed entry is missing; no fallback meaning
```

lexicalSigns consumes the actual `(originalCategory, originalScore)` from
**offeredTags**, calling this helper for Everyone only before ordinary closed
entry filtering. Retain direct offered NP normally; produce no offered-N noun
entry. For each repaired candidate add stable `closed-pronoun-source-category`
stipulation recording original N, target NP, and score unchanged. At mkLeaf the
original token source/span remains ProvLex; wrap it in a dedicated lexical-reanalysis
ProvRule, keeping the exact same surface and span. Do not pretend the tagger offered
NP. The rule+stipulation are audit evidence, not permission for any later arbitrary
category conversion. No new dormant chart flag is needed for this standalone
closed NP: it has the complete final semantics and uses ordinary NP combinators.

Use a structured lexical origin, not a test of a human gloss or stipulation text:
`LexSign.lxClosedOrigin :: Maybe ClosedPronounOrigin`, where the record stores
original category, target category and closed-entry enum `EveryonePerson`.
The helper returns this origin alongside the target/entry; lexicalSigns retains
it, and mkLeaf consumes it to construct the dedicated provenance rule and audit
note. All other LexSign constructors supply Nothing. Full occurrence identity
is minted only at mkLeaf with its actual SourceId/index/token span. This is one
small lexical annotation, not a new live SSign obligation. Fused minting uses
the same pure helper and stores the actual source category in FusedCertificate.
No origin is inferred from a term, gloss, note text or target category alone.
Standalone packing may retain the best equivalent NP meaning with its matching
provenance/notes, exactly as now; this is not a claim to retain all lexical tag
histories. No source-pair exception accompanies the closed-NP result.

## Fused restriction: preserve ORIGINAL N in the existing pair certificate

Reuse FusedHead/FusedRelOp/FusedProperty. The pair minting condition becomes:
original head is ordinary NP as before, OR original head is bare N **and** the
closedPronounReanalysis helper succeeds for that exact Everyone occurrence.
Store N in fcHeadCategory; do not replace it with target NP in source evidence.
The internal categories remain NP/N and N/(S[dcl]\NP), with the approved
person-universal restriction meaning and matching original relative occurrence.
validCertificate must accept the new N alternative only for Everyone, retain
all old NP-word cases and all source/index/span/type restrictions, and reject
N-based Someone/Everything/people or forged internal categories. No duplicated
pair-state machinery or detached property terms.

Initial scope retains exact original relative category
`(NP\NP)/(S[dcl]\NP)` and immediately adjacent who/that/which. Crucially, the
final source pair check must be `(original N, original NP\NP)` when original N
was recorded. Do NOT silently test `(NP,NP\NP)` to obtain a more permissive seen
rule. Relative+VP source check uses the original relative category unchanged.
Both categoryPairAt/mapsSource and semantic fusedSeenPair must use the identical
source categories from the same certificate. The original pair may be absent in
real CCGbank; then this route correctly remains no-parse even though a permissive
miniature test passes. This is an explicit potential blocker, not a reason to
bypass the learned rule constraint.

An independently offered `(N\N)/(S[dcl]\NP)` relative would require a separate
reviewed source-shape extension with final `(N,N\N)` check; it is NOT silently
mapped to the existing NP-relative category in this step. First inspect accepted
actual offers/cached derivation evidence before selecting that extension. The
high-level claim 'N tags repaired' must never imply every fused N source is licensed.

## Guard and packing invariants

- Actual original offered N only; N[nb]/N[conj] etc are not bare N. Score comes from
  that offer, no score fabricated for target NP. No `closedEntries everyone N`
  property entry exists.
- Standalone repaired NP receives no sourcePair bypass. Ordinary seenPair must
  license NP+VP; a model containing only N+VP evidence cannot thereby license it.
- Fused original N and NP certificates remain distinct in existing ssFused packing
  keys. Pair identity includes original head category and occurrence; a property
  certified for a different occurrence/source/category cannot discharge the head.
- Category-only prepass is an overapproximation driven by the same immutable pair
  certificates. Semantic sourcePair guards still decide admission; do not widen
  only one stage. Preserve ssNominal, ssList, conditional and reflexive checks.
- Completed repaired NP is a full universal, not a property capability for the
  nominal root-only repair. nominalCapability must not mark it NominalNoun, so
  article/universal-determiner application cannot consume it as N.

## Public mini controls and expected results before implementation

EveryoneNOriginProposalSpec uses public lexicalSigns and runPipelineWith over
hand-listed categories, never CCGbank loading. Expected strict-person boxes and
claim partitions are copied from the6independent authored controls, not from
observed meanings. Each checks selected DRS plus every retained reading, requiring
nonempty readings and no missing DRS. Add:

1. Bare-N lexical input yields only complete NP strict-person meaning, preserves
   actual score, and emits a source-category decision.
2. All6 positive/negative/relative golds with N-only Everyone category are exact
   under the explicitly permissive miniature source-rule setting. These are
   compositional tests, not proof of learned source-rule admission.
3. `A everyone is tall` and `Every everyone is tall` have no derivation, including
   with ordinary noun-raising enabled; no person-noun escape. Feature-bearing
   N[conj] cannot repair. Other nouns and people/things receive no new lexical NP.
4. The included seen-rule-on miniature with absent original
   `(N,NP\NP)` pair but present target `(NP,NP\NP)` pair: fused route MUST fail.
   Conversely a model explicitly containing the original pair may admit the
   certified local construction. The test explicitly includes the finite/relative/copular intermediate category
   catalog and paired models differ ONLY that one pair. It remains red on old
   source; positive repaired exact output is required alongside negative rejection
   before claiming a guard, so unrelated missing-rule no-parse cannot suffice.

The current branch lacks the NP-only source dependency, so initial results are
expected red; retain them as proposal evidence. The source-rule-on pair test is
an explicit implementation gate, not silently replaced by permissive mini tests.
Independent production trial predictions follow only after the NP step result.
Do not change old unrestricted gold: person means person under the strict panel,
and all source/meaning changes must be reported separately by contract. No new
benchmark/model launches or representative fidelity claim.

## Comparison

Unit2 distinguishes original offered category from internal category; Unit3 assigns
the complete generalized quantifier at reanalysis, rather than smuggling a noun
property into a generic type change; Unit4 keeps person plus relative restriction
in one implication antecedent and preserves the negative surface-scope contract.
Boxer2008 locally audited category/lexical/construction separation supports this
architecture distinction, not an Everyone-specific implementation claim.
Pinned ccg2lambda2015 lines192–194 explicitly uses person-restricted everyone
with two NP predicate slots. Adopt restriction semantics, retain our local fused
certificate rather than transplanting its incompatible NP interface. References
and verified local source pin remain in REFERENCES.md and the NP-only proposal.
