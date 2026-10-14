# Bounded nominal predication envelope

Design proposal, not implemented or measured. This refines
[nominal licensing](nominal-licensing.md) into a testable local contract. It does
not activate rejected `astra/nominal-candidate` (`c2bff11`), change gold, or predict
recovered exact counts. Units [2/3/4](../../../STUDY_PLAN.md) respectively supply the
category derivation, continuation meaning, and DRS/claim obligations below.

## Why the rejected candidate failed

The typed internal copula operator recognized positive existential complements
and otherwise admitted an equality interpretation for stable generalized
quantifiers. Its local lambda tests established elaboration, not the legitimacy
of every parser-produced NP. Adjectival `red` could enter a bare-generic N→NP
route, yielding `λk.∀x(red(x)→k(x))`. The nominal copula then produced
`∀x(red(x)→cat=x)` instead of `red(cat)`. This is a type-correct interpretation
of the wrong licensed construction, before DRS or claim extraction.

The saved `research/runs/nominal-integration/explain.log` has six failed
assertions across four displayed inputs. `The cat is not red` asserts a negated
red-to-equality implication; the conditional embeds that implication in its
antecedent; `Bob says ...` reports it; `Bob knows ...` presupposes it. The latter
two retain their attribution status but have incorrect content. Separately, the
unchanged fidelity run records six exact→wrong regressions, fifteen
no-parse→exact gains, and twenty-eight newly wrong cases; these are not the six
Explain assertions. The per-ID audit is in the earlier licensing proposal.

A generic Q and an overt universal Q can have identical normal forms. Changing
only the operator recognizer cannot recover erased lexical origin. Rejecting
all sentences with a `bare-np` note incorrectly rejects legitimate subjects;
checking only the final complement span misses uncertified coordination
branches. A correct complement with a freely released VP still permits nested
relative and scope leaks. Therefore evidence must survive completion.

## Smallest candidate: direct positive clauses first

Keep ordinary CCGbank-style syntax: `a/an : NP[nb]/N`, a licensed lexical
`N`, `be : (S[dcl]\NP)/NP`, and subject `NP`. These are source category
shapes, not a claim that every target token is assigned them. The proposed
internal evidence below is new; it is not a CCGbank annotation.

Use existing ordinary Montague meanings `P=e→t`, `Q=P→t`:

- argument `a/an N`: `λk.∃x(N(x)∧k(x))`, unchanged;
- certified predicative complement also carries **P=N**, recovered at the
  direct article application, never by inspecting a normalized arbitrary Q;
- named subject `Q=λk.k(a)`; overt every/each subject
  `Q=λk.∀x(N(x)→k(x))`; overt a/an subject has its ordinary existential Q;
- new licensed copula consumes certified P and builds a pending `λQ.Q(P)`.
  No equative fallback exists on this new route.

The smallest source investigation supports these direct positive clauses only.
Negation and coordination are separate increments below, with independent
controls before activation. This deliberately narrows the previous staged
proposal; it does not erase those higher-frequency requirements or their gold.
No second grammar, global equality contraction, or change to ordinary article
semantics is needed. Do not import the old lambda operator solely to perform
`Q(P)` if the certified property is already available.

## Evidence representation and permitted transitions

An immutable evidence value accompanies each participating chart sign. A
possible algebra (names illustrative) is:

```
Plain
NounLeaf(token, sourceCategory, lexicalDecision, predicate)
Article(token, sourceCategory, aOrAn)
Subject(originTree, Q, subjectKind)
Complement(originTree, P)
Copula(token, sourceCategory)
Pending(copulaOrigin, complementOrigin, P)
Complete(subjectOrigin, copulaOrigin, complementOrigin, meaning)
```

`subjectKind` distinguishes rigid-name evidence, overt universal, and overt
indefinite even where Q normalizes identically. A lexical name uses the existing
licensed reference decision; initial capitalization, arbitrary NP type, or
majority POS without a resolved competing adjective/common-noun analysis is not
sufficient new evidence. Unresolved names remain unresolved. A noun leaf needs
an actual lexical N decision and its existing lemma; this contract supplies no
new singularization, fictional-noun dictionary, or adjective→N coercion.

Use a capability set for an article+N sign: it can be an ordinary indefinite,
a licensed subject, or a certified complement. Do not replace its ordinary
meaning with a property globally. A consumed nominal route acquires Pending or
Complete evidence and cannot recover Plain via an untracked fallback. Existing
independent ordinary analyses remain separate chart items.

| Operation | Required evidence | Result / prohibition |
|---|---|---|
| Lexical mint | Exact token occurrence, offered source category and licensed lexical decision | Evidence only on that lexical alternative; no token-wide promotion |
| Direct forward article application | Article + lexical NounLeaf, adjacent spans, exact category match | Ordinary Q plus Complement(P) and Subject(Q, indefinite) capabilities |
| Direct every/each application | Independently supported overt determiner + lexical NounLeaf | Subject(Q, universal); never Complement |
| Direct copula application | Copula + Complement, matching source frame and adjacent spans | Pending(P); no unrestricted plain VP copy of this route |
| Direct subject application | Subject + Pending, normal backward application and adjacent spans | Complete(Q(P)); subject applied exactly once |
| Final punctuation | Complete + independently recognized final punctuation using reviewed punctuation rule | Complete preserved; punctuation cannot mint or erase evidence |
| Root selection | Complete at full declarative sentence span, no pending roles | Materialize existing normalized formula/DRS and ordinary claim extraction |
| Embedding, relatives, sentence coordination | Any Complete | Reject this route initially; no implicit Plain conversion |
| Raising, unary conversion, arbitrary composition, nonfinal punctuation | Any active Pending/Complete or construction-required child | Reject this construction transition; independent ordinary routes unaffected |

NounLeaf/Article/Subject/Complement are evidence attached to otherwise ordinary
signs, not restrictions on their unrelated existing uses. In contrast, Pending
and Complete are obligations: every application, composition, unary operation,
packing, and root check must handle them explicitly. A default combinator must
not silently drop them. Category prepass must represent the extra licensed route
and its potential continuation without manufacturing semantic evidence; source
category identities must survive its seen-pair mapping.

Packing and seen-pair identity include the entire role/capability value,
origin token occurrences, lexical decisions, source category, tree shape, and
property/subject semantic identity using the parser's stable term identity.
Equal surface spans or alpha-equivalent Q alone cannot merge licensed and
unlicensed alternatives. Preserve distinct origins even when denotations match.
A branch containing one uncertified child cannot inherit its sibling's license.
Tests should exercise chart transitions, not merely public constructors that
can fabricate evidence. Actual adjacency is enforced by chart span composition.

This is a local proof object attached to existing signs, not a second parser.
It must compose explicitly with existing fused-relative certificates; never
reuse Plain as an escape from either obligation. Initially no fused-relative
subject or nominal VP inside a fused relative is licensed. If integrating this
small algebra requires duplicating general parsing machinery, stop and review
the representation before implementing broader coverage.

## Later increments, with scope fixed before implementation

For direct VP negation, proposed `NegPending(P)` means `λQ.Q(λx.¬P(x))`.
For a universal subject this is `∀x(N(x)→¬P(x))`, not `¬∀x(N(x)→P(x))`.
Only a reviewed category- and origin-preserving negation path may produce it;
no general crossed composition exemption. The actual supported derivation must
be supplied before this increment is implemented.

For explicit complement AND/OR, both branches must independently have
Complement evidence. Build a property tree `λx.P(x)∧R(x)` or
`λx.P(x)∨R(x)` with preserved order/association and apply the subject once.
`every N` must yield `∀x(N(x)→(P(x)∨R(x)))`, not a disjunction of universals.
Comma lists, mixed adjective/nominal branches, and relative-modified nouns
require separate contracts. Root-only Complete deliberately prevents these
increments from quietly introducing conditional, reported, or relative uses.

## Independent controls and DRS obligations

These are proposed corpus-free controls, not measured results or replacement
gold. Supply explicit lexical decisions in transition tests; a sentence-level
name test separately checks the real lexical route. Use at least these pairs
before a positive-clause candidate can be considered for integration:

| Construction | Controls | Intended meaning and claim status |
|---|---|---|
| Rigid subject | Alice is a doctor; Bob is an artist | doctor(Alice), artist(Bob), each Asserted; no complement witness/equality |
| Universal subject | Every cat is an animal; Each dog is a mammal | `[x\|cat(x)]⇒[\|animal(x)]` and dog→mammal, implication Asserted; component atoms Embedded |
| Indefinite subject | A cat is an animal; An artist is a teacher | `[x\|cat(x),animal(x)]`, `[x\|artist(x),teacher(x)]`; ordinary positive existential admission, one shared subject witness |
| Ordinary argument unchanged | Alice sees a doctor; Bob sees an artist | Existing existential object witness retained, no property coercion outside copula |
| Adjective regression | The cat is red; The cat is not red | Existing adjective reading preserved; nominal route absent for adjective→bare NP |
| Distinct origins | Same normalized universal Q from bare N→NP versus every+N; same NP type from adjective coercion versus a+N | Only overt licensed constructions receive their stated capabilities; packing retains difference |
| Unlicensed new route | Alice is every doctor; Alice is Bob | No new predication route; independent old readings are not globally rejected |
| Boundary protection | If Alice is a doctor then Bob is happy; Bob says Alice is a doctor; Everything that is a doctor is red | New root-only envelope cannot escape into embedding/relative; existing readings remain independently eligible |

Negative transition tests additionally cover type-raised Subject, unary-derived
N, a mixed-origin coordinated Complement, Pending across arbitrary composition,
Complete stripped by punctuation, wrong occurrence pairing, and incomplete
Pending at root. Include ordinary existential argument controls so the article
capability does not replace its normal semantics.

Later negation controls: Alice is not a doctor; Every cat is not a dog; A cat is
not a dog. Expected respectively `¬doctor(Alice)`, universal negative predicate,
and `∃x(cat(x)∧¬dog(x))`. Negated predicates are Embedded, never promoted as
positive Asserted atoms. Later OR controls: Alice is a doctor or an artist;
Every cat is an animal or a pet. DRS retains the OR node; branches are Embedded
with explicit OR paths, and no branch atom is asserted independently.

## Primary-source comparison and limits

[Boxer 2008 §§2–3](https://aclanthology.org/W08-2222/) separates category/type
from lexical interpretation selected using POS, word form and morphology, and
construction from resolution (§3.3). That supports retaining lexical evidence;
it does not attest our certificate algebra, root-only fragment, or guarantee
correct name resolution. Our direct property convention deliberately avoids an
extra identity witness and follows the committed independent gold.

The pinned [ccg2lambda 2015 copula templates, lines439–458](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_emnlp2015.yaml#L439-L458)
map nominal `(S\NP)/NP` to subject/complement continuations joined by equality;
the adjectival frame is an identity on the supplied VP. Their NP takes two
predicate slots, unlike this project's Q. Copying the equality template is
neither a drop-in type change nor evidence that adjective-derived generic NPs
are licensed nominal complements. The [2015 paper §2/Figure3](https://aclanthology.org/D15-1244/)
uses the extra restriction slot for relatives; our initial envelope does not
claim to solve that larger representation problem. See the pinned source map in
[REFERENCES](../REFERENCES.md). No upstream system was executed for this proposal.

## Acceptance boundary

Reviewer approval here licenses a design investigation only. Before source
landing: direct transition/packing tests, preserved independent gold, full
Explain regressions, required project gates, and fresh fidelity with all original
inputs in the denominator. Report exact/wrong-but-typed/no-parse separately;
there is no projected score from fifteen historical gains. A no-parse is honest
for an unsupported route, but any newly wrong selected reading blocks landing.
The ProverQA90%exact/near-zero-wrong gate and model/benchmark pause remain intact.
