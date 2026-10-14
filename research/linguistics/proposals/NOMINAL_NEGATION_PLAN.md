# Bounded negated nominal predication

Design and independent controls only, based on accepted nominal-v2 fedfbfd.
Known-name origins landed separately as accepted 1b9fc27; this plan now
uses that accepted dependency for named subjects. No production source edits or corpus
loads are included; implementation requires review and fresh fidelity gates.

## Priority and limits of the inventory

CONSTRUCTIONS records 47,529 Pronto predicate-negation occurrences, alongside
503,067 article+noun predicates. These are overlapping feature totals: their
intersection is not known from that table. Do not call 47,529 the recoverable
negated-nominal count. Predicate conjunction is more frequent at 149,937, so
negation is a useful bounded follow-up to positive nominal predication, not
proof that it outranks every remaining construction. Prover's 562 negated-copula
cues and 1,180 copula+a/an cues likewise do not supply their intersection.
ProofWriter's 829,487 controlled negative copular occurrences are **adjectival**;
they motivate preservation checks, not predicted gains from nominal negation.
No new inventory or coverage experiment was run for this design.

## Unit 2: one existing combinator, an occurrence-certified frame

Let `VP=S[dcl]\NP`. Retain the original source categories:

```
is       VP/NP
not      (S\NP)\(S\NP)
a/an     NP[nb]/N
animal   N

is not   VP/NP                  BwdXComp: Y/Z  X\Y => X/Z
an animal NP[nb]               FwdApp
is not an animal VP            FwdApp
NP subject + VP => S[dcl]      BwdApp
```

This is a category derivation using the existing feature-specializing rule,
not an assertion that every actual token receives those tags. The initial
increment requires the actually offered, actually interpreted backward VP-not
entry. A token offering only forward or adjectival-not categories is unsupported
by this increment. Do not substitute a global property-negator category merely
to avoid this source requirement.

Internally, preserve the existing captured-property nominal route:
`is:VP/N`, `a/an:N/N` **only within its certified construction**. The same
backward crossed composition gives `(is not):VP/N`; applying the independently
certified article+noun property gives the negative VP. No global lexical article
change, no arbitrary NP inversion, no equative fallback and no invented noun
category are required. The ordinary argument article remains existential.

The current implementation cannot certify this frame: nominal pairs require
adjacent `is` and `a/an`, and the active nominal role rejects arbitrary
composition. This is the first construction divergence. Permitting composition
for every Pending sign would remove precisely the protection that prevented
previous nested nominal failures.

## Unit 3: reuse the declared subject-over-not meaning

With `P=e→t`, `Q=P→t`, the existing captured-property copula is
`C = λP λQ.Q(P)`. The existing backward VP-not entry is
`N = λV λQ.Q(λx.¬V(λk.k(x)))`. Their ordinary composition is:

```
N ∘ C = λP λQ.Q(λx.¬P(x))
```

Thus the subject receives widest scope:

- `Ari is not an animal` → `¬animal(Ari)`;
- `Every cat is not an animal` → `∀x(cat(x) → ¬animal(x))`;
- not `¬∀x(cat(x) → animal(x))` and not an asserted existential animal witness.

This is the project's explicit subject-over-not contract, not a denial of
possible English scope ambiguity. In particular, do not generalize this clause
to `Not every cat ...`, negative determiners, indefinites as subjects, double
negation, coordination, relatives or reporting. Their truth conditions and
source certificates need separate controls. The construction uses closed
lexical meanings and the existing capture-safe-for-closed-terms composeTerm;
it does not extend that helper's preconditions to arbitrary open terms.

The six operator tests independently check original/internal category
composition, type, both scoped meanings and the non-equivalence to negating the
whole universal. Passing these tests does not establish parser admission.

## Minimal certificate extension to propose for implementation

Add optional typed negation evidence **to the nominal certificate**, not to every
general sign. A concrete shape is `ncNegation :: Maybe NominalNegationOrigin`,
where the origin holds source, token index/span, written `not`, original
backward VP-modifier category and the closed lexical constructor choice. The
positive frame keeps Nothing. A negative certificate requires exactly adjacent
`is`, `not`, `a/an` indices and ordered nonoverlapping source spans. It is not
valid under the positive adjacency invariant by accident.

Mint the negation evidence in the actual closed lexical branch for the selected
not entry. Do not infer it from a rendered term or the existing `scope` note.
A single duplicate tagged lexical alternative can carry the mandatory
`NominalNegator certificate` role; retain ordinary independent not alternatives
for ordinary adjective and argument negation. Retain all noun and name evidence
from v2/name candidate without weakening their admission policies.

| Transition | Exact permitted evidence | Result |
| --- | --- | --- |
| Copula + not | Same negative certificate; direct lexical is and backward not; BwdXComp only | Mandatory NominalNegatedCopula |
| Article + lexical noun | Same captured-P and noun-origin checks as v2; article occurs after certified not | Certified property with matching negative frame |
| Negated copula + property | Exact composed provenance, same frame/source, FwdApp only | Pending negative VP, retaining noun and negation origins |
| Universal/name subject + Pending | Existing typed subject checks, direct BwdApp | Complete carrying frame, subject and complement evidence |
| Final period/root | Existing mandatory-active and full declarative-root checks | Retain the complete frame and all origins |

Source-pair checks must cover the original `VP/NP + VP\VP` composition and the
original composed `VP/NP + NP` application. The category prepass can map these
exact occurrences to their internal `VP/N` counterparts, not whitelist an
unseen pair globally. For negative copula application the chart split is at
the article index (copula index+2), not the old positive index+1. The semantic
transition must independently validate the exact `BwdXComp` provenance and
selected child categories even if the category prepass overapproximates it.

Every active negative role rejects generic unary, raising, other composition,
coordination, nonfinal punctuation and embedding. Packing keys include the
entire negative frame; equal normalized meanings do not erase not's occurrence
or its source category. An ordinary not note copied onto an uncertified sign
must not discharge anything. Named Complete and universal Complete can retain
the shared extended certificate without collapsing their distinct typed
subject origins. The exact API migration must be reviewed against the source
that actually lands, rather than assuming the frozen candidate already landed.

## Unit 4: scope and claim status

Named negative predication is `[ | ¬[ | animal(Ari)]]`. The NOT condition is
Asserted; `animal(Ari)` is Embedded. Universal negative predication is
`[ | [x | cat(x)] ⇒ [ | ¬[ | animal(x)]]]`. Only the implication is Asserted;
its restriction, the consequent NOT, and the negative body's atom are Embedded.
Neither case asserts a positive class membership or allocates an animal witness
outside negation. Source provenance must retain `not` itself as well as noun,
article, copula and subject.

Ordinary `Ari does not see an animal` retains a distinct negative existential
box `[ | ¬[x | animal(x), see(Ari,x)]]`. Its object witness stays inside NOT.
Do not globally contract existential/equality structure or rewrite every
indefinite as a property to obtain the nominal result. Ordinary positive
`Ari sees an animal` still has its ordinary main-box witness.

For ContextUnknownNouns, the complement's inferred lexical property and its
policy marker remain under the same negative frame and in the output metadata.
KnownNounsOnly still rejects unknown nouns. Neither policy creates a name
certificate for an unknown initial capital, and this proposal never changes
the evidence contract for a known name. Restricted unknown-noun semantics remain
an explicit controlled-language assumption, not an English fidelity claim.

## Boxer/ccg2lambda comparison and controls

The pinned comparison in `negation-conditionals-disjunction.md` supports
operator boxes and the separation of lexical meaning from semantic type:
Boxer construction/resolution cannot make a misplaced NOT faithful merely
because it yields a DRS. The pinned 2015 ccg2lambda English templates use a
subject-under-which-not-scopes convention; the separately documented event
never template has a different scope option. Reuse the explicitly declared
local VP-not contract rather than treating publication as a gold oracle.
Neither external system was run here.

The independent miniature suite covers two universal nouns, a stipulated
known name, and v2's explicit unknown-noun policy. Expected DRS and all four
claim-status groups were written before experiments. Baseline tests distinguish
intended red nominal admission from green ordinary adjectival negation and
positive/negative indefinite-object meanings. Future source tests must also
attack swapped/missing negator occurrence, foreign source, wrong span/index,
forward-only not, missing source seen-pair, same-term different-origin packing,
unsupported embedding/relative/coordinator escape and final punctuation.

Do not register expected reds as a passing release suite. Implementation needs
review of this precise rule, actual origin/transition tests, all source tests,
and fresh construction-fidelity/Explain checks. Exact recovery, absence of new
wrong-but-typed readings, and retained source/claim status must be measured on
the merged result before any coverage or fidelity-gate claim.


Baseline validation on accepted source:12/12 intended nominal admission checks
remain red even after named-subject integration1b9fc27;19/19 boundary/preservation
checks pass. Existing source-category/operator checks6/6pass. Default standalone
execution therefore has25/37pass and12known failures, not a production regression
suite. Modes and the earlier isolated-base comparison are recorded in the note.
