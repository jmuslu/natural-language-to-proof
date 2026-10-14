# Either lexical certificate: exact origin and pairing boundary

Plan and independent controls only, base579db46. No production source, policy,
protocol, gold or corpus changes. Depends on the still-isolated OR transport
kernel9f1a90d and integration plan94bbff4; this document supplies their missing
lexical authority, not an alternative normalization implementation. Current
corpus availability is not measured. The supplied miniature offered categories
are assumptions of the tests, not evidence of trained lexical coverage.

## Policy dispatch must precede lexical interpretation

`legacy-disabled` is the default and must call the existing lexical path
unchanged: same categories, terms, scores, notes, ordering, packing and roots.
Do not add either unconditionally to shared closedClassWords. The existing
N/N fallthrough can create an either predicate; preserving that default is a
compatibility requirement, not a claim that it is linguistically correct.

Only explicit `surface-inclusive-v1` intercepts the exact ASCII word either,
case-insensitively, **before** ordinary/name/open-template fallback. It consumes
only actually offered X/X entries meeting the shape below; every unsupported
offer for that reserved token produces no enabled candidate. Thus offered N/N,
NP, NP/N, S/S or missing offers cannot become a free identity or ordinary
predicate in the enabled route. No category is synthesized. Unknown token
shapes such as neither, either2, either's and either-or cannot mint an either
origin; unrelated ordinary-word handling is not redefined by a prefix match.
Quotes/punctuation are separate tokens and cannot be stripped to make a pair.

The policy schema, exporter/error echo, reports/replay and solver combination
restrictions remain coordinator-owned requirements of94bbff4. No enabled mode
may be advertised while its lexical, transport and lowering pieces are unwired.
Inclusive OR plus a precise marker is not XOR, and cannot silently be consumed
under the solver's controlled-exclusive ProverQA convention.

## A concrete private API proposal

Use one private pairing payload in the proposed SSign OR field, alongside the
kernel's opaque Evidence. Do not authenticate an origin from its normalized
term, human note, public SSign fields or a source-text word search.

```
EitherLexChoice(index, written, offeredCategory, X)
ExplicitOrChoice(index, written, offeredConjCategory)

EitherOrigin(source, tokenIndex, tokenSpan, written, offeredCategory, X)
OrEdgeOrigin(source, tokenIndex, tokenSpan, written, offeredConjCategory)
TokenCover(first, endExclusive)       -- actual chart coordinates
DirectOrRight(orOrigin, rightOperandCover, rightOperandProv, X)
OrPayload(kernelEvidence, pairState, optionalDirectOrRight)

PairState = Ordinary
          | EitherPending EitherOrigin
          | EitherLeft EitherOrigin operandCover operandProv X
          | Paired (set of completed PairCertificate)

PairCertificate(source, eitherOrigin, orOrigin,
                leftOperandCover, rightOperandCover, X)
```

Names are proposed, not exports available today. LexChoice constructors are
private and minted only at the **actual selected lexical branch**. Bind source
and spans when that branch becomes a chart leaf, checking index/text/category
against its actual token. The ordinary structural-or branch must mint its own
private ExplicitOrChoice from an actually interpreted `LexStructural` offered
`conj` entry; `ssStructural="or"` or `ssCoord="or"` alone is not authority.
Keep the original structural placeholder out of logical OR-origin maps.
DirectOrRight is a passive field built only at actual CoordMark, not a completed
pair or logical OR. It remains associated with the selected ordinary marked-right
item; ordinary keys still ignore passive evidence quality, preserving ties.
If the retained item lacks valid direct evidence it cannot close a paired route;
do not rescue a losing ordinary candidate to obtain a certificate. A residual
DirectOrRight cannot be a root (the existing ssCoord guard also rejects it).

For the initial predicate tranche, X is exactly `S[adj]\NP` or `S[dcl]\NP`,
with plain NP and the stated single S feature; source X/X has a forward slash,
identical left/right X and no extra slash/outer features. Reject generic bare S,
S[b]/S[ng]/S[em], differing X features, NP[expl]/NP[thr]/NP[conj], backward X\X,
N/N, lifted/doubly modified categories and any type mismatch. This is a bounded
admission choice, not a claim those other English constructions are invalid.

The selected enabled lexical meaning is typed identity `λv:V.v`, where
**V=Q→t, Q=(e→t)→t**. It exists only with mandatory EitherPending; there is no
unmarked sibling identity. This corrects the older interface document's
schematic e→t VP description. A public lexical projection may display this
candidate, but cannot establish that the private origin or pending obligation
was transported through a complete parse. The authorized pipeline must use the
annotated branch, not reconstruct an origin from that projection.

## Exact transition contract

Let i be the marker index and k the index of explicit or. A chart constituent
uses half-open token intervals. “Direct” below means the specified actual
combinator event and child origins, not equality to a reconstructed term.

| Transition | Required selected inputs | Output and obligations |
|---|---|---|
| Leaf | Enabled exact either, actual admitted offered X/X | Identity with EitherPending; kernel PairedPending with validated empty OR map |
| FwdApp | Pending leaf `[i,i+1)` + ordinary X `[i+1,k)`; exact X/features/type; clean flags | EitherLeft with operand interval/provenance and same origin; still PairedPending |
| CoordMark | Actual lexical conj/or `[k,k+1)` + ordinary X `[k+1,j)` | Direct marked-right wrapper retaining exact OrEdgeOrigin and right operand cover/provenance; no logical OR yet |
| CoordApply | EitherLeft `[i,k)` + that direct marked-right `[k,j)`; matching X and same source | coordTerm TOr of original operands; one completed certificate; PairedActive with complete transported map |
| Direct application after pairing | Supported FwdApp/BwdApp; independently available child evidence, all old construction guards | Preserve all completed certificates and kernel paths; never downgrade to Ordinary |
| Final period | Completed active declarative root + actual final period only | Preserve pair evidence and exact operator-local provenance; pending states cannot take this path |
| Root/lowering | No pending marker/right edge obligation; complete active S; all existing root gates | Checked normalized OR map consumed by occurrence-aware DRS lowering for selected and every retained reading |

Both ordinary operands in the initial pair must have no pending/active pair,
no existing CoordList, no structural/coordinator/list/conditional/fused/nominal
obligation and a valid OR-free semantic snapshot. Requiring OR-free operands is
a conservative first-tranche restriction: it refuses to attach a marker to an
already coordinated predicate or hide a nested OR under a modifier. It does
not erase existing ordinary OR behavior. More complex pair operands need a
separately reviewed extension; no source-shape whitelist substitutes for one.

Token intervals must partition the actual chart span: marker, left operand,
or, right operand, in that order, with no skipped token. Every selected leaf
has the same SourceId; spans are nonempty, ordered and nonoverlapping and agree
with actual tokens. A span hull cannot prove token contiguity. semParse receives
tokens rather than raw source text; in the Pipeline's casedTokens route all
punctuation survives as tokens and only whitespace is skipped. Therefore
whitespace-gap claims depend on that trusted tokenizer contract, not merely
numeric offsets. A public caller supplying fabricated tokens is not certified
by these helpers. Do not expand the API to claim raw-text verification it lacks.

The direct marked-right wrapper must retain its actual CoordMark event and
children, not merely a recursively found descendant OR. Closing requires
literal or, never and/comma/but, exact conj source category, and exact operand
features. Use existing seen-pair/category/type guards as well; no new global
unseen-pair exception. Repeated either, marker-after-left, disjoint/foreign
source, swapped/overlapping covers and punctuation inside the frame reject.
An unsupported pending path must return no candidate, not silently clear state.

## Kernel and semantic constructor handoff

The kernel validates and transports a complete map of every TOr occurrence.
It does not know whether an origin is lexically licensed. Supply only this
certificate's actual edge plus its paired marker at the newly constructed OR;
ordinary OR origins are separate and remain unpaired. The coordinating helper
must report operator/left/right positions **before normalization**, preserving
child maps, as coordinated with the transport specialist. Do not search the
normalized term for an equal OR or attach the map after finish.

For actual VP operands A,B, coordTerm gives the meaning equivalent to:

```
λQ.Q(λx. A(λP.P(x)) ∨ B(λP.P(x)))
```

Its subject scopes once over OR. In `Every person is either red or big`, the
intended result is `∀x(person(x)→(red(x)∨big(x)))`, not an OR between two
universals. The marker licenses neither XOR nor a separate existential witness.
For a named subject the DRS is an Asserted OR of two boxes, whose atoms are
Embedded. In a conditional the OR can be Embedded; marker locality and truth
scope are independent requirements.

Pending may become Active only on the closing transition. Neither mode can
be downgraded by dispatch. For active application, input evidence must match
its exact pre-normalization term, then kernel transport validates post-term/map.
Unavailable passive child origins, unsupported beta duplication/deletion of an
OR-bearing child and conjunction rewriting remain failures, not provenance
fallback success. Composition, raising, unary, intensity/deindexing, list
rebuilding and nested pairing are unsupported active routes in this tranche.
Ordinary optional signs may retain Untransported passive evidence without
changing their ordinary meanings/keys; they cannot enter a paired route with it.

## Constructor, update, packing and root checklist

Re-search these sites after rebasing; listed names reflect current source.

| Site | Required invariant |
|---|---|
| lexicalChoices / mkLeaf | Branch-minted either/or origins; default unchanged; structural placeholder has no fake TOr; bind actual token coordinates |
| particle two-token constructor | No either origin; ordinary passive evidence only; correct two-token cover |
| unary constructor | Reject Pending/Active, preserve ordinary behavior; do not initialize an active child as Ordinary |
| semCombine.mk and compose | Policy-aware path carries payload before finish; all four composition rules reject active/pending even via compose helper |
| CoordMark record update (`ssList=ssList r`) | Preserve right evidence and exact lexical coordinator origin; do not invent PairCertificate |
| CoordApply / coordinateList update | Direct binary close only; create one origin at actual constructor; keep new list certificate but forbid active list rebuilding |
| keep punctuation record update | Pending and EitherLeft reject; active final-period-only rule; changing whole-sign provenance does not change local OR origin |
| final fused/nominal/notes update | Preserve new payload while retaining every current guard; no new exemption for either |
| chart key / packCell | Legacy and Ordinary keys/tie behavior unchanged; Pending/Active keys include exact state, origins, covers, features and kernel PairedKey |
| root byMeaning | Same paired distinction; canonicalAC/meaning equality must not collapse different pair attachments or marker maps |
| Pipeline toSign/rootFor/lowerReading | Bind each root to its own payload; no first equal-term/provenance lookup; selected and all alternatives use exact occurrence-aware lowering |

Complete paired payload can lose the old ssList after a supported application,
but cannot lose its independent certificate/map. `ssCoord=Nothing` does not
mean all obligations are discharged. Both bare Pending and EitherLeft must be
explicitly rejected at roots, in addition to conditional/fused/nominal guards.
Unsupported active punctuation, sentence prefixes/suffixes, explicit not-both,
corrective/modal tails and multi-item pairing cannot be dropped for a root.
A complete candidate must consume the entire sentence token range.

## Independent controls and source-authorization boundary

`test/EitherLexicalCertificateSpec.hs` has24 passing corpus-free checks of
existing behavior: legacy lexical projection (including unwanted N/N property),
actual VP types, a grammar composition escape that a future role must block,
punctuation/word-shape/token-offset boundaries, and independently hand-written
named/existential/universal coordTerm scope targets. These are not enabled-mode
or private-certificate tests, and are not claimed as source authorization.
No copied proposed admission predicate is being tested against itself.

Before implementation approval, add actual-origin controls as the API appears:

- Enabled X/X from actual offered adjective/finite VP entries; exact-case/case
  variants; no offer means no capability. Unsupported N/N/NP/S/S offers reserve
  either with zero enabled candidates; legacy projection remains byte-identical.
- An identical category/identity/provenance with missing origin cannot apply;
  alter source/span/index/word/category/feature and reject. Same-term valid
  origins at two actual occurrences remain distinct in both packing stages.
- Pending accepts only the direct FwdApp above; EitherLeft accepts only the
  direct CoordApply close. Test every alternate combinator and both punctuation
  directions, unary/type raising, ordinary AND/comma, repeated markers and
  changing the actual OR edge to a descendant/unrelated edge.
- Close only after an actual OrEdge origin from the structural lexical branch;
  copying ssCoord or a note must fail. Missing seen source pairs fail. List,
  conditional, fused/nominal/reflexive obligations cannot be bypassed.
- Public Pipeline selected and all retained readings must be nonempty and have
  exact DRS, claims and local marker for paired examples. Missing rrDRS is a
  failure. Preserve plain OR and legacy entire-output behavior, plus TT/TF/FT
  equal-formula clause controls from the integration plan. Unsupported scopes
  abstain; never infer their support from path-only kernel tests.

Old exclusive-contract fixtures remain wrong if an inclusive-only interpretation
is newly returned; report that hard stop rather than changing gold, hiding the
case or calling the marker XOR. No corpus availability, gain or default
activation is predicted here. A coherent optional lexical→chart→kernel→lowering
vertical implementation, protocol binding, independent review and root gates
are required before landing any portion of this plan.
