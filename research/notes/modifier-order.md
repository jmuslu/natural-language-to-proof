# Modifier order versus definite identity: design audit

Full-access shell verified in astra/modifier-order at61f52d8. Own this note and
test/ModifierOrderProposalSpec.hs only. No source/gold changes or fresh corpus
loads. Read DESIGN's fixed head-first/surface-modifier convention, LOG's rejected
reorder, existing quantifier known-failure controls and DRT Build describeIota.

Prediction before corpus-free controls: four a/every head-first checks fail;
both definite-name preservation checks pass; simple relative ordering passes;
modified relative ordering fails; category-only stone-as-N/N compound falls
through to intersection and fails the proposed fail-closed control. Expected
3 passing,6 failing. These are design acceptance controls, outside cabal, not a
claim that a currently exposed API can distinguish every compound from adjective.
Command: runghc -isrc test/ModifierOrderProposalSpec.hs.

## Evidence and the actual obstruction

The sealed reflexive-integration121 cache records `All blue, young people are
not rough` restriction order blue,young,person, and `All kind, red things are
green` order kind,red,thing. The intended independent gold order is person,
blue,young and thing,kind,red respectively. This confirms a pre-existing
structural fidelity failure; it is not evidence of a fresh parser run.

`openTemplate N/N` is lambda P x.modifier(x) and P(x). Nested application
therefore emits modifiers in surface order then the head. Reversing each local
conjunction emits head then modifiers in reverse surface order, still wrong.
`describeIota` consumes that same normalized property and constructs a rigid
identifier from its ordered unary predicates: bald,eagle becomes `bald eagle`.
A global reversal/sort or unconditional head-first modifier therefore changes
identity; this is a genuine compatibility regression, not harmless display.

More seriously, normalization erases lexical head, attachment and modifier
class. `N/N` can denote an adjective, numeral or noun compound. The current
ProvIndex is Map predicate-name provenance: repeated words overwrite entries,
and Pipeline indexes every interpretable lexical candidate at a selected span,
not an occurrence-unique typed noun-construction plan. It cannot establish
selected head vs modifier merely by looking up predicate name or token position.
Relative restrictors already use head then relative property; moving the final
predicate first confuses the relative with the noun head. The matrix predicate
can also share the variable (documented in the restored Alternatives audit).

There is also a literal test-contract conflict. Existing CCGSemSpec requires
red(x) and thing(x), and AssertionSpec requires red,thing for All red things.
Independent gold requires thing,red. No single identical exposed normalized
form/DRS can satisfy both ordered assertions unchanged. Preserving every old
test **and** the new serialized order is impossible without explicit interface
versioning or review-approved representation-expectation updates. Preserve all
semantic/identity guards; do not fake success by altering gold or redefining
exact as unordered during this repair.

## Smallest coherent direction, not a claimed small patch

Separate nominal semantic structure from definite surface identity before
normalization discards either. A per-selected-derivation nominal plan needs:
(a) occurrence-unique head contribution; (b) ordered modifier contributions with
licensed semantic class; (c) attachment scopes, including restrictive relatives;
(d) the legacy surface description used only for definite rigid naming. It must
travel with a semantic sign through application/composition/type change until
the NP is consumed, including coordination and repeated predicate occurrences.

For a/every/no, construct property head first then licensed intersective
modifiers in original order, then relative restrictions; put the quantified
scope after the full restriction and keep its binding/claim status. For the,
use the identical semantic property but preserve its separately stored original
surface descriptor for the established rigid-name fragment. A normalizer cannot
reconstruct that descriptor from arbitrary formula order. Unsupported compounds
and nonintersective adjectives must retain a separately justified meaning or
remain unsupported; head-ordering is not permission to conjoin them.

A smaller possible implementation family adds occurrence-aware head/modifier
annotations to semantic terms instead of a separate plan. That still needs
capture-safe substitution, type checking, beta normalization, deindexing,
canonicalization and all consumers to preserve/erase annotations correctly.
It is not a one-line lexical-template fix. Avoid adding an opaque sentinel
predicate that becomes a fake asserted condition or an iota-name substring.

Keep existing describeIota's public bare-term behavior for backwards-compatible
callers. Any new definite construction carries explicit identity information;
legacy unannotated terms cannot be safely guessed into the new representation.
No automatic canonical sort of names or lexical whitelist qualifies as the
required general solution. A narrow explicit fragment mode is possible only
with a declared, versioned contract, not hidden lexical repair per gold sentence.

## Units 2/3/4 and source comparison

Unit2 retains CCG category, derivation attachment, token occurrence and head.
Unit3 distinguishes intersection from relational compounds and nonintersective
operators, with the determiner Q receiving the same complete restriction.
Unit4 orders conditions without moving them across boxes or promoting an
Embedded property; definite identity remains separate from condition ordering.
[Boxer2008](https://aclanthology.org/W08-2222.pdf) §3.2 expressly distinguishes
adjectives/numerals/compounds sharing N/N; adopt that lexical/category separation.
[ccg2lambda2015](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_emnlp2015.yaml)
uses an additional NP restriction argument for relatives; adapt restriction
attachment coherently, not as a post-normalization reorder. Neither supplies
our project's special ordered-description rigid-identity compatibility contract.

Recommendation: do not implement a guessed downstream head reorder. The general
solution needs a reviewed richer nominal interface plus explicit migration of
order-sensitive expectations while retaining identity and scope guarantees.
The nine controls below make those competing obligations reviewable without
claiming the architecture already meets them.

Result:9 controls ran,3 PASS/6 FAIL exactly predicted. Both definite checks
consume the actual closed the determiner and inspect its resulting iota argument;
they do not replace that composition with an expected string. Revised that
instrumentation and reran, same3/6 result. No production or gold edits made.
