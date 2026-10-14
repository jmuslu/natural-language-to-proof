# Universal nominal trial: plan before execution

2026-10-14. Full-access shell verified in isolated astra/nominal-universal-trial
at 1eb363e. Read coordinator STATE first and GOAL. No corpus/model/benchmark
loads. Initial ownership: this note and test/NominalUniversalProposalSpec.hs.

Prediction before any test execution: authored direct Every/each lexical-N
subjects with positive is+a/an+lexical-N complements currently lack the exact
classification DRS. The proposed bounded route should derive one universal
implication, with no equality witness or promoted embedded atoms. Baseline red
controls are expected; no score/coverage promise follows from this miniature
lexicon. Root must acknowledge this prediction before a test is launched.

## Concrete template proposed for reviewer approval

Use paired source-to-internal reanalysis, not normalized-Q inspection, an
unlicensed placeholder term, or global article or copular equality changes.

Source offered categories:
`is : (S[dcl]\\NP)/NP`, `a/an : NP[nb]/N`, noun `N`.
Proposed internal categories (not CCGbank attestations):
`is : (S[dcl]\\NP)/N`, meaning `λP.λQ.Q(P)`;
`a/an : N/N`, meaning `λP.P`. Only this paired construction-specific article
has identity meaning. Ordinary article NP[nb]/N keeps existential continuation.

Mint a certificate from adjacent is+article occurrences with exact source
categories, source id, token indices/spans, lexical spellings and source scores.
No benchmark nouns, sentence-text filter, name assumption, or synthetic POS.
The supported present singular copula is a declared finite lexical frame;
other finite forms require a reviewed feature/morphology extension.

Internal roles: Plain; Article(cert); Predicate(cert,nounOrigin);
Copula(cert); Pending(cert,nounOrigin); Complete(cert,subjectOrigin).
Lexical noun and overt subject evidence must be retained separately as ordinary
capabilities, not inferred from equal normalized terms. All mandatory roles and
capabilities participate in packing/seen-pair identity. Subject origin records
exact direct FwdApp of lexical Every/each NP[nb]/N to lexical N, both source
categories and occurrences. Require noun lexical entry N and matching NN/NNS
POS evidence; unresolved adjective/name category alternatives are not certified
by this template. Existing morphology remains unchanged and may independently
block fidelity. Direct subject Q remains the existing quantifier meaning.

Transitions (all other role combinations reject the new route):

1. FwdApp Article(cert) + lexical N produces Predicate(cert,N), category N,
   carrying exactly the noun's existing P. N must be a direct lexical leaf, not
   modifier/unary/coordinate/relative output. Source seen-pair obligation is
   article NP[nb]/N + N, not internal N/N + N.
2. FwdApp matching Copula(cert) + Predicate(cert,N) produces Pending(cert,N),
   category S[dcl]\\NP, meaning λQ.Q(P). Source seen-pair is nominal copula +
   completed source NP[nb]. Matching certificate includes both occurrences;
   chart adjacency enforces actual contiguity, not a loose span inequality.
3. BwdApp direct licensed universal Subject + Pending produces Complete,
   category S[dcl], meaning Q(P). Preserve quantifier once and subject noun
   as antecedent predicate. Names, bare generics, indefinite subjects,
   modified/relative subjects, raised/unary subjects are unsupported here.
4. Final punctuation may preserve Complete under the existing reviewed rule.
   Root alone discharges Complete at whole declarative span. No embedding,
   coordination, negation, unary, composition or relative use of active roles.

The category prepass must include internal lexical alternatives and source-pair
mapping for steps1/2; this is an overapproximation only. The semantic chart must
independently enforce all evidence/role transitions. Do not introduce a source
seen-pair bypass for unrelated internal categories. Preserve ordinary analyses
as independent alternatives; never copy Pending/Complete into Plain, and never
reject a sentence globally because an unsupported new route was attempted.
Fused-relative certificates must remain intact and cannot combine with pending
nominal roles. Completed clauses cannot escape through punctuation/unary.

Implementation proposed in CCGSemParse only: local paired LexTerm generation,
explicit role/evidence state, guarded transitions, prepass source mapping,
packing, unary and root checks. Semantic λ terms use existing constructors;
CCGSem is unchanged. If SSign gains a field, existing positional constructors in
test/FusedRelativeProposalSpec.hs need coordinated ownership before editing.
No source implementation until reviewer approves this concrete plan.

## Controls and acceptance

Positive independent fixtures: Every cat is an animal; Each dog is a mammal;
Every artist is a teacher. Each exact DRS is `[ | [x | SUBJECT(x)] =>
[ | PREDICATE(x)]]`; only the implication Asserted, both atoms Embedded, no
Reported/Presupposed claims. Check every returned reading, not selected only.
Controls run with miniature explicit tag/POS tables, no CCGbank load.

Later direct role tests must reject mismatched certificates, unary/raised nouns
or subjects, active composition, half-pair roots, mixed source occurrences,
role-erasing punctuation, and embedding. Packing test retains two equal terms
with distinct origins/licenses. Ordinary adjective and indefinite-argument
controls preserve existing semantics. No names admitted by this candidate.

Baseline sentence controls deliberately remain red until implementation; their
expected meanings are independent of parser outputs. Any fresh-fidelity newly
wrong selected reading blocks source landing. Unsupported inputs retain original
gold and denominator. Full project gates/fresh fidelity are coordinator-owned.

Baseline after coordinator logged prediction: runghc independent controls
completed 0/9 pass (three sentence rows, each three assertions). All selected
DRSs absent, as predicted. These are intentional red acceptance controls,
not nine distinct semantic regressions. No corpus was loaded.

Reviewer approved bounded investigation before source edits, requiring exact
POS policy. Initial noun capability requires a nonempty dictionary POS set with
NN or NNS and no JJ/JJR/JJS/NNP/NNPS entry of any positive count; it does not
pretend to resolve contextual ambiguity. Direct lexical category must be N and
nameStatus NotName. Competing verb POS alone does not erase noun evidence; the
source N decision selects the noun use. Unknown/no-POS nouns get no capability.
Ordinary analyses remain available. This intentionally loses possible coverage
rather than admitting unresolved adjective/name-derived nominal predication.

## Implemented bounded candidate and checks

CCGSemParse now generates the two typed internal lexical alternatives from
paired offered source categories and keeps NominalRole through packing,
application, unary rejection and root admission. No Q-term unwrapping or
reserved semantic operator was needed. Ordinary lexical noun/universal-subject
capabilities can be dropped on unrelated ordinary paths; mandatory article,
property, copula, pending and complete roles cannot be dropped. CCGSem unchanged.

Completion supports either an unpunctuated root or a literal final period only;
other punctuation is deliberately not part of this new route. Full source
seen-pair mapping is checked independently in prepass and semantic chart.
The only change to the existing fused test is initializing ssNominal to
NominalPlain, as authorized; all original assertions remain.

Post-change corpus-free validation (no corpus loads):
- NominalUniversalProposalSpec: 59/59 (three independent exact DRS/claim/all-
  reading rows plus actual transitions, coherence/cleanliness, packing,
  occurrence/source mismatch, unary/composition/root/punctuation rejection,
  source seen pairs, noun POS conflicts, and ordinary adjective/object routes).
- FusedRelativeProposalSpec: 89/89.
- CCGSemSpec: 89/89.
- CoordinationDiagnosisSpec: 24/24.
- ReflexiveProposalSpec: 21/21.
- git diff --check: passed.

No fidelity gain is claimed from these miniature-lexicon controls. Dictionary
conflicts, missing noun evidence, source category offering, seen-pair evidence,
lemma fidelity and bounded search can independently prevent real-input gains.
Full gates and fresh unchanged-gold fidelity remain coordinator requirements;
any newly wrong selected reading blocks landing. Reviewer inspected live source
without a blocker; final committed-source review requested after these checks.
