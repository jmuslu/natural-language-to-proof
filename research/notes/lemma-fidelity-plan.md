# Lemma proposal validation record

Full-access shell verified, isolated astra/lemma-fidelity-plan from421b6c7.
Own NounLemmaProposalSpec.hs, proposals/noun-lemma-fidelity.md and this note only.
Read actual CCGSem openTemplate/verbLemma and CCGSemParse lexicalSigns/model
attestation construction. No source/gold mutation, parser/corpus/model load.

Prediction before standalone tests: two base-attested regular plural noun
expectations fail because current N template uses lowercase surface. Ten
preservation/attestation checks pass, including verbLemma excels already excel.
Tests use authored lantern/crane vocabulary, not benchmark word memorization.
Run with runghc -isrc -itest test/NounLemmaProposalSpec.hs; no cabal registration.

First result:2expected noun failures plus1irrelevant binder-name comparison failure
in an adjective-preservation assertion. Corrected test comparison to canonicalAC
(alpha-normalized) on both sides, preserving predicate expectation. Rerun result:
10/12pass; only2 intended plural-noun red controls remain. No source change.
Actual source verbLemma excels already excel; do not misdiagnose that row as a
missing suffix rule. Nominal proposed normalization must live at category+POS-
evidenced lexical interface, leaving reportingLemma/attestation untouched.

Reviewer refinement before implementation: replace the ambiguous appended-s
spelling prose with exact lower-ASCII envelope excluding every -es ending,
including legitimate cranes. Add axes/bases with competing singulars, news,
species, compounds, capitalized surface and conflicting POS controls. Prediction:
the same2 positive reds remain (lanterns/gardens), with23 preservation checks
passing; no actual CCGbank POS availability or fidelity gain is predicted.

Final refined controls include minority-name evidence too:26checks,24pass and2
intendedred. Exact spelling envelope now lowerASCII len>=4 final s excluding
es/ss/us/is/ews; original/base POS support exactlyNNS/NN. This deliberately defers
valid cranes and -ews nouns to avoid broad inference. Source predicates remain
unchanged; target benchmark lexical evidence is still unobserved. Reviewer must
approve refined contract before any source implementation.

Before source implementation added six requested controls: conflicting base
adjective/name POS, nonplain N/NP/modifier/adjective/verbal category exclusion,
reserved things, retained category/score and explicit surface/POS provenance.
Prediction: previous2normalization reds plus missing-provenance red; all29other
checks pass. Then implement only open actual-offered plainN candidate hook.

Implementation result: red32controls29pass3fail before source; after bounded
lexicalSigns hook all32pass. Added POS-backoff-only N preservation regression:
final33/33pass. Source change is only CCGSemParse open lexical candidate handling
and isSuffixOf import. Actual offered plainN condition, lowercase spelling gates,
exact dictionaryPOS support sets and original score/category retention enforced;
changed meaning gets noun-lemma stipulation with original/base and both sets.
Closed classes/names/verbal templates/reportingLemma/model attestation untouched.

Focused existing suites via runghc (no corpus): NameSemSpec30/30,
HasLemmaProposalSpec12/12, CCGSemSpec89/89 pass. No cabal registration or shared
root files changed. These unit checks do not predict actual CCGbank lexical
qualification or population improvements. Candidate requires independent source
review, coordinator fresh fixed gold and all release gates before landing.
