# Derived N properties inside bounded nominal constructions

Design only, accepted base05fdf2a. No production edit, population gold or corpus
load. The smallest defensible next step is a typed **property-origin tree**, first
for a known noun with an independently licensed intersective adjective. Purely
propagating today's lexical noun flag through every N-result combinator is unsafe.
Coordination and relatives are separate constructors/increments, not automatic
consequences of broadening that flag.

## Why this cannot resurrect c2bff11

The rejected broad nominal candidate admitted arbitrary generalized-quantifier
complements and an equality fallback. Its recorded114-case trial gained15 exact
from no-parse but lost6 prior exact cases and created28 newly wrong cases. In
`Anne is cold`, an adjective-as-N generic Q could produce
forall x(cold(x) implies Anne=x), outranking cold(Anne). The six regressed cases
were Wren/earthy, Cruz/wise, Ali/gentle, Anne/cold, Anne/furry and Gary's
conditional. Six Explain assertions also failed across negative, conditional,
reported and presupposed content; they are not the same six fidelity cases.

Those published candidate-audit findings are inherited evidence, not a fresh
observation here. The cause was missing construction/lexical origin before DRS,
not a broken equality operator or an assertion-status converter. Scanning a
normalized Q for an existential, rejecting all bare-np notes, or replacing every
article with identity cannot repair erased origins. Correct typed meanings and
new coverage did not compensate for those regressions.

Current source instead carries actual lexical noun evidence, exact determiner
occurrence, nominal copula/article certificate, optional known/inferred admission,
and actual name-branch origin. Pending/Complete roles are mandatory until full
root; optional noun/determiner capabilities retain ordinary routes. Preserve all
of that, including existing name-vs-common-noun competition. The new proposal
consumes a derived property only where a noun property is already expected,
never arbitrary NP, Q, stable lambda normal form or potential equality term.

## Units2/3: proposed evidence algebra and smallest scope

Illustrative typed constructors, not implemented API:

```text
NominalPropertyOrigin
  = NounLeaf(existing NominalNounOrigin)
  | IntersectiveModifier(actual modifier lexical origin,
                         guarded FwdApp derivation, NominalPropertyOrigin)
  | PropertyCoordination(actual connective occurrence,
                          guarded N-coordination derivation,
                          leftOrigin, rightOrigin)
  | CertifiedSubjectRelative(new ordinary-N relative origin evidence,
                             nominalHeadOrigin, relativeVPEvidence)
```

Each carries actual source category, source/interval/tree provenance and stable
property-term identity, not just a Boolean `hasNoun`. Leaves must be selected
lexical N:e→t with the current known or explicitly inferred admission. Reject an
adjective promoted to N via unrelated fallback, NP[expl], name NP and generically
raised N→NP. A final N category alone is insufficient evidence.

**First increment: known-noun + intersective modifier only.** Source N/N combines
with certified N by actual FwdApp to N. Both occurrences share source, are adjacent
chart operands and have the recorded derivation. The modifier must carry an
independently justified intersective lexical choice. POS JJ and N/N alone do not
prove this: former/alleged/fake and nominal compounds cannot all mean intersection.
Existing generic openTemplate N/N assumption is not that certificate. This missing
modifier-sense admission interface is a blocker to automatic broad activation,
not a request for a list of target words. Authored red/quiet fixtures stipulate
intersective senses to isolate the construction; they do not attest arbitrary
corpus adjectives.

Represent P compositionally, e.g. cat(x) and red(x), then:
Every/Each:NP[nb]/N applies directly to derived N, retaining the *whole* property
origin and actual determiner. Paired predicate article captures derived N directly
as P, never unwraps an ordinary existential Q. Copula maps P to lambda Q.Q(P).
Universal or certified rigid-name subject applies exactly once to that pending
VP; final completion contains complete subject/complement origins. Ordinary
argument a/an remains existential; the internal identity article remains bound
to its original source category and copula/article certificate.

Today's metadata requires lexical noun ssProv and lexical span checks. Replace
these checks with typed property validation, not their deletion. Subject proof
must reconstruct actual determiner+property provenance; predicate proof actual
article+property provenance; pending proof copula+predicate; complete proof full
subject/pending spine. Validate origin source IDs, exact child category/term and
interval boundaries at consumption. Existing source-pair/seen-rule policy maps
internal steps back to their exact source category frames. Category prepass may
overapproximate the licensed syntax but cannot mint semantic evidence.

**Ordering is an independent blocker.** Current ordinary N/N semantics preserves
modifier-first descriptive order, including definite bald-eagle identity. New
independent property gold expects head-first then surface modifier order. A
property-origin tree can identify heads and modifier sequence without reversing
arbitrary conjunctions. If a new nominal internal interpretation constructs that
ordered property, it must do so from lexical constructor semantics and record the
reanalysis; it must not rewrite existing definite identifier terms or guess heads
from predicate names. No global conjunction sort/reversal. Demonstrate both
single/multiple modifier fidelity and unchanged definite identity before source
approval. This is why mere role propagation is not yet a complete small fix.

## Deferred increments: coordination and relative restriction

**N coordination:** two certified property trees and a selected AND/OR connective
combine only under the actual N-coordination derivation. AND gives lambda x.
(P(x) and R(x)); OR gives lambda x.(P(x) or R(x)), with one shared subject witness
later. Never interpret coordinated Qs, ordinary existential article NPs or mixed
N/NP branches as this tree. Preserve left/right order and exact operator; article
scope outside N coordination is distinct from coordinating two article NPs. First
controls use a shared article. No distributive/collective semantics or arbitrary
mixed nesting follows from this increment.

**Subject relative on N:** the ordinary cat+that route currently uses
restrictiveTag/local seenPair N-relative reanalysis; it does not carry the
FusedCertificate for restricted pronoun NP heads. A new actual-occurrence/
derivation property-evidence transition must be specified for this ordinary
N-relative route, together with a certified VP using the same gap witness; head property and relative property
combine in the restriction, not as a new matrix conjunct. A nominal complement
can then denote animal(x) and quiet(x) without changing the universal's subject
restriction. That ordinary-N origin interface remains unresolved. Separately, when a
restricted-pronoun fused route actually participates, it needs an explicit
compatibility rule with its FusedCertificate/roles: mandatory obligations must
be discharged into typed property evidence, never erased to NominalPlain.
The inapplicable NP-head certificate cannot certify ordinary cat+that. No object gaps, comma relatives,
nested nominal copula, independent reference or finite sentence closure can
silently enter this constructor. If the two evidence protocols cannot compose
locally, defer it rather than setting one role to plain.

KnownNounsOnly is the initial policy. ContextUnknownNouns currently licenses
only direct adjacent determiner/head or paired article/head context. A modifier
between them invalidates that direct assumption. Do not silently widen the
unknown policy while adding known derived properties. A later proposal would
need an unknown head's license tied to the enclosing certified property tree and
actual consuming determiner/pair, with contrary POS/name exclusions unchanged.
No inferred name extension is implied. The enabled-policy190 trial, if run,
is a separate experiment; it is not evidence for derived unknown N properties.

## Unit4: independent controls and expected claim boundaries

`test/NominalPropertyProposalSpec.hs` supplies a miniature dictionary, independent
expected canonical objects and claim tables, and selected/all-retained checks.
No corpus or trained model is loaded; the actual parser runs on the hand-fixtured dictionary. The direct lexical baseline remains:
Every cat is an animal → `[|[x|cat(x)]⇒[|animal(x)]]`.

| Future control | Full intended DRS | Asserted / Embedded |
|---|---|---|
| Every red cat is an animal. | `[|[x|cat(x),red(x)]⇒[|animal(x)]]` | Whole implication / cat,red,animal in order. |
| Every cat is a red animal. | `[|[x|cat(x)]⇒[|animal(x),red(x)]]` | Whole implication / cat,animal,red. |
| Every cat is an animal and mammal. | `[|[x|cat(x)]⇒[|animal(x),mammal(x)]]` | Whole implication / cat,animal,mammal. |
| Every cat is an animal or mammal. | `[|[x|cat(x)]⇒[|[|animal(x)] OR [|mammal(x)]]]` | Whole implication / cat,whole OR,animal,mammal. |
| Every cat that is red is an animal. | `[|[x|cat(x),red(x)]⇒[|animal(x)]]` | Whole implication / cat,red,animal. |
| Every cat is an animal that is quiet. | `[|[x|cat(x)]⇒[|animal(x),quiet(x)]]` | Whole implication / cat,animal,quiet. |

All outer universes empty; no existential import, equality, Reported or
Presupposed. OR is inclusive, no either marker or XOR inference. Current test
compares canonical DRS/claims, not disjunction metadata: an eventual implementation
suite must also assert exact OR path/either=false/scope_ambiguous=false. Missing
annotation coverage is explicit, not treated as complete semantic acceptance.

Unsupported-frame controls deny this construction on bare adjective, name
identity, existential subject, name-as-noun, universal complement and reporting
embedding. Ordinary independent readings may remain; the test asserts absence
of NominalComplete/NominalNamedComplete, not global no-parse. Before any source
change add direct adversaries for same term/different origin, mismatched source,
wrong span/tree, one uncertified coordination branch, reversed relative binding,
known/inferred policy packing, and every unary/composition/embedding escape.
These future constructor tests cannot be claimed tested while the API is absent.
Add rigid-name+derived-complement positives after name-origin interface review;
current negative Mira=Nora is not a positive name-licensing proof.

## Frequency and implementation order

ProofWriter explicit all590,281 and bare universals597,392 justify understanding
modified nominal restrictions, but these are whole families, not counts of this
new nominal-copula frame. Pronto predicate article+noun503,067 overlaps predicate
AND149,937 and OR17,932; relative universals176,850 overlap relative AND128,988
and OR47,862. Do not multiply or add these cues to claim exact coordinated-N
opportunities. The already measured86,788 direct lexical nominal opportunities
exclude the proposed modifications and are not a derived-property denominator.
Prover nominal-predicate cue1,180 and quantified-who959 likewise do not measure
this envelope. Priority: solve evidence/order for known modified N first, then
shared-article N coordination, then compatible certified relative properties;
validate each separately instead of selecting the largest cue as an immediate
coverage promise. Further input-only joint counting is required for exact ranks.

## Prior-source comparison and review boundary

Boxer2008 §§3.2–3.3, as recorded in REFERENCES, distinguishes category/lexical
selection from resolution; its N/N compound example is not adjective intersection.
Adopt that distinction, not unrestricted N/N promotion. Pinned ccg2lambda2015
relative entries566–573 use a second NP restriction slot. Their coherent interface
is a useful alternative, not a term to paste into current one-slot Q or a reason
to erase evidence. Existing bounded property reconstruction avoids a whole NP
interface migration only while constructors and role composition stay local.

No implementation is authorized by this proposal. The first increment still
requires reviewed intersective-sense admission and ordered-property/definite
compatibility. If those cannot be expressed as a small typed extension, report
that architectural cost and defer source; do not recover coverage by reviving
Q inspection, global article identity, equative fallback or relaxed gold.
