# Frozen-v1 acceptance controls for proposed unknown nominal v2

This is a test/design artifact only. It preserves `8e2a6ad` v1 source and its
approved rejection of unknown POS; it does not authorize a v2 production change
before the coordinator's v1 gates. The prior design is `38b260d`.

The new standalone `test/NominalOpenNounV2Spec.hs` uses a miniature tag dictionary
with source categories supplied explicitly, not inferred by observing parser
outputs. Every/each and a/an offer NP[nb]/N, is offers (S[dcl]\NP)/NP; the new
nominal terms have direct N and no POS counts. Known cat/animal have NN. No
licensed corpus or statistical model is loaded. The independently expected
classification is forall x(subject(x) implies complement(x)), with only the
implication Asserted and its two predicates Embedded, no equality/witness, and
all retained readings subject to the same exact expectation.

Four independent unknown/mixed cases: Every dax is a blicket; Each wumpus is an
impus; Every cat is a blicket; Every dax is an animal. These exercise two nonce
vocabularies and both mixed known/inferred positions. Known Every cat is an
animal is the positive v1 compatibility control. These are authored controls,
not new population gold or counted benchmark examples.

## Negative boundaries preserved independently

Five complement POS configurations—JJ, NN+JJ, NNP, NN+NNP and VB-only—must not
enter the unknown-only route. Known conflicting subject noun evidence is tested
separately with a known complement. Unknown uppercase Zorp is excluded. A
complement offering NP alone cannot be transformed into N by inspecting or
unwrapping its generalized-quantifier term. An absent proper noun interpretation
is not inferred merely from lowercase spelling when positive NNP evidence exists.

Bare/indefinite subjects and orphan predications remain outside the root-universal
route. The assertion tested here is **no new NominalComplete route**, not that
all independent ordinary English readings must disappear. Original ordinary
adjective/object-existential controls in v1 remain unchanged and must continue
running when v2 is implemented; this separate file does not replace them.

The typed local transition controls preserve lexical occurrence requirements:
same property with NominalPlain cannot substitute for a noun capability; unary
provenance cannot counterfeit a leaf; foreign source cannot discharge an article;
NP/Q cannot be unwrapped into the direct N input. Pending internal article may
neither form root nor enter unary. Packing retains equal properties carrying
lexical capability versus plain role rather than dropping the capability.

## What the existing API cannot yet test

V1 has no explicit KnownDictionaryNoun versus UnknownContextNoun origin sum.
The current packing test checks capability versus no capability, **not** the
new evidence-class distinction. A future v2 implementation must add that origin
class to noun/subject evidence and packing keys and add the direct test: two
identical terms/categories with distinct known versus inferred origins remain
separate until an authorized transition consumes them. Do not fake that test by
using different spans or predicates and claim it tests the missing origin class.

Likewise the no-POS capability must be context-bound: a direct lexical unknown N
outside direct Every/each subject or certified is+a/an complement must not acquire
a generally reusable semantic license. Root-only, matching occurrence certificate,
seen-source-pair, no negation/coordination/composition/embedding escape and existing
fused-relative isolation obligations remain the v1 contract. The existing v1
transition suite already tests these; v2 must preserve it, not edit its negative
expectations wholesale. Its unknown-POS rejection case must be retained as an
explicit v1-policy control while v2 tests exercise a separately selected policy;
otherwise claiming all old tests pass would conceal a changed contract.

## Unit 2/3/4 and scope of the proposal

Unit2 licenses a selected lexical N by actual offered category and the bounded
determiner context; global-prior offerings still do not prove lexical sense.
Unit3 retains the existing property P, paired identity article, copula lambda
P Q.Q(P), and the universal subject Q. No equality or Q-term dissection supplies
the predicate. Unit4 requires the same witness in antecedent and consequent,
with unchanged epistemic status. The unknown lexical interpretation assumption
is explicitly weaker than dictionary attestation, separate from those structural
properties; contrary POS evidence must continue to defeat it.

[Boxer2008](https://aclanthology.org/W08-2222.pdf) motivates category plus
lexical-information selection, not unlimited N/N coercion. The pinned
[ccg2lambda templates](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_emnlp2015.yaml)
provide category-driven nominal properties but do not certify a corpus-prior tag
as correct English sense. Adopt compositional properties, retain local evidence,
and reject treating published templates or these authored controls as population
fidelity evidence.

Pronto's185426 every/each outer occurrences and503067 predicate-article+noun cues
motivate the family but do not measure this exact direct singular root frame or
its unknown-POS subset. No coverage improvement or90% gate claim follows from
these red controls. New source requires separate review and fresh gate evidence.

## Concrete minimal evidence/policy delta for further review

Retain one **model-level** policy enumeration, `KnownNounsOnly | ContextUnknownNouns`,
defaulting to KnownNounsOnly. Do not add independent flags to every SSign. The
existing `ssNominal :: NominalRole` already participates in packing and contains
the bounded construction state. Extend that typed state rather than creating a
second parallel chart protocol.

Replace repeated noun `(Prov,CCat)` payloads in NominalRole with a single
`NominalNounOrigin` value containing lexical occurrence provenance, exact source
N category and typed `NounAdmission`. Its alternatives are:

- `DictionaryCommonNoun`: current nonempty NN/NNS, no contradictory JJ/name POS
  predicate, unchanged under either policy.
- `ContextLicensedUnknown UnknownNominalContext`: no POS evidence, actual offered
  lexical N, non-name, nonempty alphabetic entirely lowercase token, and no
  reserved closed-class status. The context alternative is either
  `DirectUniversalSubject determinerOccurrence determinerCategory` or
  `PairedNominalComplement NominalCertificate`. These are mutually exclusive
  source origins, not flags inferred from the completed lambda term.

The policy is consulted when generating the optional lexical capability, not by
weakening all NominalNoun validity tests. Under v1 default no unknown evidence is
minted. Under v2, a candidate unknown leaf receives this capability only when
its *actual source occurrence* has the stated adjacent direct determiner or
matching paired copula/article certificate. The selected source determiner must
be Every/each NP[nb]/N, not merely a string nearby; the complement source pair
remains exact is+(a/an) with original offered categories and seen-pair proof.
This is still an optional interpretation of an unknown word, not an asserted
lexical fact or a new category. Raw offered N without this context remains plain.

Carry the origin value through the existing stages:

- NominalNoun(origin) → direct universal application →
  NominalUniversalSubject(determinerOrigin, nounOrigin).
- Matching paired article + NominalNoun(origin) →
  NominalPredicate(certificate, nounOrigin) →
  NominalPending(certificate, nounOrigin).
- Root completion → NominalComplete(certificate, subjectEvidence,
  predicateNounOrigin). Preserve both noun evidence classes to completion.

Every consuming transition validates the origin context against its actual
operands and lexical spans/source IDs. An unknown subject license cannot be
reused as a predicate license, or vice versa; a complement license cannot move
to another copula/article pair. Known-vs-inferred and distinct-context payloads
remain in Eq/Ord packing identity automatically through NominalRole. No role is
erased to Plain to escape validation. Existing all-sign fields and unrelated
combinators need no new boolean; existing full-root and active-role guards remain.

Add one logged decision for the inferred lexical reading with its source N,
unknown-POS observation, bounded context and selected policy. No substring or
normalized-term matching recovers evidence. No Q unwrapping or synthetic NN
count is introduced. Noun morphology, adjective sense coercion and generic
subjects are outside this evidence extension.

Future direct typed-origin tests, after API introduction, must prove:

1. Equal category/meaning with DictionaryCommonNoun versus ContextLicensedUnknown
   stays as two packed signs; known/inferred differences survive Subject,
   Predicate/Pending and Complete, not just leaf packing.
2. A context-unknown complement origin cannot complete a direct subject, and
   a subject origin cannot be captured by the paired article.
3. Same-spelling noun from another index/source and a complement bound to another
   certificate fail; unrelated lexical P/Q equality cannot confer a capability.
4. KnownNounsOnly preserves the existing unknown-POS negative control. Only
   ContextUnknownNouns activates the independently specified positive unknown
   meanings, while all existing JJ/NNP/name/unary/embedding negatives remain.

These tests are not presently fabricated using a constructor absent from v1.
They are explicit implementation obligations before any v2 source is accepted.

## Extended red fixtures and lexical assumption

The executable controls now additionally reject `dax2`, `dax-blicket`, `dAx`
and `123` as inferred common nouns, despite an offered direct N in the miniature
tag fixture. A separate positive fixture removes dax and blicket entirely from
the per-word tag dictionary while retaining an N-containing global prior. It
checks absence of POS/per-word records and actual N offering, then requires the
same independently authored universal classification under proposed v2.

That last case deliberately tests the controversial assumption: determiner
context can license a novel nominal interpretation even when N arose only from
prior fallback. It is not disguised as corpus lexical attestation. Any practical
implementation must report these inferred-origin cases separately and pass
selected/all-retained reading fidelity, not count the existence of a typed
candidate as success. This remains a proposal pending v1 gates and reviewer
approval of the concrete v2 changes.
