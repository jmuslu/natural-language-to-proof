# Local direct-object reflexive repair: review before implementation

The frozen seven-case gold gives 0 exact / 7 wrong-but-typed / 0 no-parse.
Reflexives introduce a new universally restricted object instead of reusing
the local subject. Repair composition before DRS; gold remains immutable.

## Typed rule and lexical license

For `Q=(e→t)→t`, `V=Q→t`, `T=Q→Q→t`, use the reviewed construction category
`(S[f]\NP)\((S[f]\NP)/NP)` and closed term
`λR:T.λS:Q.S(λx:e.R(λP.P(x))(λP.P(x)))` of type `T→V`.
R takes its object first. Named subject yields `defend(Amara,Amara)`;
`every cat` yields `∀x(cat(x)→groom(x,x))`: the subject quantifier applies once.
Negation encloses that diagonal atom. An earlier Anne is irrelevant, and an
embedded clause's subject, not its reporting holder, binds its local reflexive.

Initial supported forms: singular direct-object himself/herself/itself. Reserve
all standard reflexive spellings against open-class/name fallback; unsupported
plural/person/exempt uses must not silently become predicates. Singular-they,
plural distributivity, possessives and logophoric cases need independent policy.
Do not infer gender from names; enforce incompatible agreement only with
independent evidence.

Reanalyse ordinary offered NP/NP[nb] or N for recognized reflexive forms into
the construction category; N must never pass through generic N-to-NP. Reject
expletive/there/conjunct features, N/N, PP and clause categories. Preserve tag
scores and add a `reflexive-local-binding` decision recording original category,
target and domain; do not invent nonexistent alternatives. Preserve the consuming
verb's feature: finite dcl and negation-support base b are required. Do not use
an all-feature identity template or license adjectives/passives accidentally.

**Locality is an integration obligation.** A transitive-shaped function can be
created by composition or relative extraction; its type alone does not prove
local coargument status. Initial application must certify a lexical transitive
predicate and its direct-object slot (or a separately reviewed extension).
A constructor/sign annotation checked at binary application can enforce this;
a global string substitution cannot. Do not apply diagonal binding indiscriminately
to PP governors or arbitrary composed functions merely because erased types
match T. Reviewer must settle this gate before production implementation.

## Proposed integration

1. `CCGSem`: one closed diagonal term, reserved forms, category-coherent entries
   and trace stipulation. No benchmark verb/name whitelist.
2. `CCGSemParse.lexicalSigns`: narrowly licensed reflexive category reanalysis
   before open/name paths, keeping category and score evidence.
3. At reflexive application, enforce the local direct-object gate above; ordinary
   application, normalization, DRS construction and claim splitting then suffice.
4. Coordinator registers the standalone proposed test only after review, then
   runs miniature tests and immutable fidelity through the shared slot wrapper.

The standalone `test/ReflexiveProposalSpec.hs` calls production closedEntries,
lexicalSigns and Pipeline using authored miniature tags. It contains no duplicate
reflexive implementation. Expected terms are independently reduced. It tests
coherent diagonal entry, named and quantified subjects, offered N, base-form
negation, previous-name distraction, absence of retained bad alternatives and
fail-closed unsupported categories. It intentionally fails on current production.
It does not prove exclusion of every composed-function counterexample; that
requires reviewer-approved local-domain instrumentation and follow-up tests.

Unit 2: preserve category direction/features and explicit reanalysis. Unit 3:
verify `typeOf term == semTy category`, plus one subject quantifier and diagonal
arguments. Unit 4: keep universal/negation internals Embedded and only whole
conditions Asserted. Frozen claim splitting correctly classified wrong formulas;
promoting an Embedded atom would conceal the actual defect.

[Boxer 2008](https://aclanthology.org/W08-2222/) separates construction from
resolution and lists reflexive triggers, but does not establish this algorithm.
Adopt the separation, adapt binding to Q-valued NP. The pinned ccg2lambda audit
in [REFERENCES](../REFERENCES.md) found no dedicated reflexive entry in its three
inspected English YAML files. Do not claim upstream validation or paste its
incompatible event/NP continuation terms. This proposal supplies a general local
construction with explicit unresolved extensions, not a ProverQA gate release.

## Exact bounded gate after reviewer follow-up

Reuse existing `SSign.ssProv` and `ssNotes`; no new payload on all signs.
Identify a pending reflexive by the construction category above and its closed
`reflexive-local-binding` stipulation at the same lexical provenance. A category
with that special shape but no licensed closed marker is not an ordinary open
functor fallback. In `semCombine`, guard pending items before ordinary dispatch:

- The only consuming rule is `BwdApp`, with reflexive on the right and lexical
  transitive on the left. Both signs must be plain (no pending coordinator or
  structural placeholder). A pending reflexive on the left is rejected.
- Left `ssProv` must be exactly `ProvLex`, not a ProvRule with one leaf. Left
  category is exactly `(S[dcl]\NP)/NP` or `(S[b]\NP)/NP`, with ordinary
  argument NPs; explicitly reject passive, adjectival, embedded and generic S.
  Left cannot be a clause-gap `S/NP`, PP governor, unary-extracted sign or
  composition. Word identity does not decide eligibility.
- Right must also remain its marked lexical sign, with expected reflexive
  category whose VP feature agrees with the left; resulting category must be
  that same finite/base VP. Require ordinary type agreement as well as category
  matching. Do not erase features to make the gate pass.
- Pending reflexives may not undergo unary change, composition, coordination,
  or punctuation attachment before consumption. Sentence-final punctuation can
  attach after the lexical verb/reflexive VP has been built. This retains a
  licensed derivation without manufacturing a nonlexical pending binder.
- Once the reflexive is consumed, its category is ordinary VP; the inherited
  note remains provenance, not a permanent ban on subsequent composition.
  Apply `not` and `does` to that completed VP. In particular `does defend` as
  a composed T cannot consume the reflexive, but `does (defend herself)` can.

This lexical-leaf restriction deliberately excludes composed/extracted governors
until independently reviewed. It avoids carrying a new universal sign flag and
makes the domain inspectable in the existing derivation tree. All standard
reflexive words remain protected from ordinary noun/name meanings, including
unsupported contexts; otherwise the guard can be bypassed through lexical fallback.

Additional public-API tests inspect returned provenance for auxiliary and negated
inputs and reject PP, subject intensifier, clause-extracted and incompatible
passive/adjective governors in miniature tag models. These are not a substitute
for reviewing the early gate: root packing can hide a discarded spurious route,
and some negative miniature grammars already lack a semantic parse. No private
function is exported solely for testing. Coordinator integration must inspect
all branches of the gate and confirm unary closure cannot alter a pending sign.
