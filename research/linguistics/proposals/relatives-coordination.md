# Restrictive relatives and coordination: review proposal

Status: design/review only, 2026-10-14. Existing source repairs are preserved;
no new parser rule is approved by this document. Evidence comes from source,
existing regression tests and sealed Explain logs, not a new benchmark run.

## Learner map and type conventions

Read STUDY_PLAN Units 2, 3 and 4 in that order. Unit 2 asks which constituent
contains the gap and where its modifier attaches; Unit 3 asks which variable is
shared; Unit 4 asks which box binds that variable and whether its predicates are
asserted. Type correctness answers none of these questions by itself.

Write `p=e→t`, `q=(e→t)→t`, `lift(x)=λP.P(x)`. This implementation maps `N` to
`p`, `NP` to `q`, `S` to `t`, and `S\NP` to `q→t`. Features constrain syntax
without changing these semantic types. Ordinary adjectives are
`λQ.Q(λx.red(x)) : q→t`; transitive verbs are
`λO Q.Q(λx.O(λy.like(x,y))) : q→q→t`. These are extensional fragments of the
project's Montague interface; no event or world variable is silently introduced.

In the DRS notation `[x | C]`, referents before `|` bind conditions. Main-box
conditions enter Asserted; descendants of implication, negation or disjunction
enter Embedded, not independent Asserted facts. Reported and Presupposed remain
empty for the simple examples here. Embedding the entire sentence under an
attitude changes that status: this proposal does not bypass the claim traversal.

## R1. Restrictive subject relative: an existing repair

Example: `Every cat that is red is big.`

| Word | Category | Meaning |
|---|---|---|
| every | `NP[nb]/N` | `λN Q.∀x(N(x)→Q(x)) : p→q` |
| cat | `N` | `λx.cat(x) : p` |
| that / who / which | `(N\N)/(S[dcl]\NP)` | `λV N x.N(x) ∧ V(lift(x)) : (q→t)→p→p` |
| is | `(S[dcl]\NP)/(S[adj]\NP)` | identity on `q→t` |
| red / big | `S[adj]\NP` | property lifted to `q→t` |

Derive `is red : S[dcl]\NP` by `>`, `that is red : N\N` by `>`,
`cat that is red : N` by `<`, then `Every ... : NP[nb]` by `>` and the
complete sentence by `<`. The result is
`∀x((cat(x)∧red(x))→big(x))`, not `∀x(cat(x)→(red(x)∧big(x)))`.

DRS: `[ | [x | cat(x),red(x)] ⇒ [ | big(x)]]`. The implication is Asserted;
`cat`, `red`, `big` are Embedded. For `A cat that is red is big`,
`[x | cat(x),red(x),big(x)]` makes all three conditions Asserted. The relative
itself does not choose epistemic status; the determiner and containing box do.

Current evidence: `subjectRelative` and `closedTable` in CCGSem.hs;
SemanticRepairSpec checks universal, existential, `who`, and negated restrictors.
Sealed `research/runs/linguistics-design/explain.log` around line 1899 and
`research/runs/phase-b/explain-final.log` around line 671 show the N attachment.
These controls are repaired, not proof that every relative construction works.

The CCGbank-style NP-attaching category `(NP\NP)/(S[dcl]\NP)` cannot simply
receive pointwise GQ conjunction: `λV Q P.Q(λx.V(lift(x))∧P(x))` places the
relative in every's nuclear scope. A general NP-level solution needs an explicit
restrictor interface or a licensed derivation rewrite to N attachment. Do not
claim the two categories are semantically interchangeable under this one-slot GQ.

## R2. Quantified-pronoun relatives and mixed predicate coordination

`Everything that is red is big` needs `[ | [x | red(x)] ⇒ [ | big(x)]]`
under the controlled benchmark's unrestricted-domain convention. The sealed
Explain log around line 580 instead has
`∀x((everything(x)∧red(x))→big(x))`. First divergence: the leaf `Everything:N`
receives an ordinary noun predicate; generic N→NP subsequently preserves the
invented restriction. The relative template itself works on that wrong input.

Pronto gold rows `pronto-restrict-and-1/2` and `pronto-restrict-or-1/2` strengthen
this check: `Everything that is earthy and an impus is a brimpus` requires
`[ | [x | earthy(x),impus(x)] ⇒ [ | brimpus(x)]]`. The `or` counterpart puts
`[ | slow(x)] ∨ [ | impus(x)]` inside the antecedent. Every descendant remains
Embedded. One x binds both conjuncts/disjuncts and the consequent.

Coordination requires equal categories, not merely equal semantic types. An
adjectival predicate `S[adj]\NP` and predicative nominal `NP` are not directly
conjoinable. Review candidate copular nominal templates and a licensed common
predicate category with the quantifier worker; do not solve this by globally
making arbitrary NP interchangeable with adjective predicates. A closed-class
`everything` restriction interface is likewise shared design work. Existing
Prover gold's `quantified_pronoun_or_relative` rows contain `Everyone is ... or
...`, not actual relative clauses: those rows alone cannot certify this family.

## R3. Object relatives and nonrestrictive relatives remain separate

`Every cat that Bob likes is big`: proposed object-gap category
`(N\N)/(S[dcl]/NP)` and the same typed meaning `λV N x.N(x)∧V(lift(x))`.
Raise `Bob:NP` to `S/(S\NP)` (`λf.f(Bob_GQ)`), compose with
`likes:(S[dcl]\NP)/NP` to form `Bob likes:S[dcl]/NP`, then attach the
relative at N. Desired DRS is `[ | [x | cat(x),like(Bob,x)] ⇒ [ | big(x)]]`.
This is a proposal: syntax must retain features and distinguish the extracted
object from the subject. Existing subject-relative success does not implement it.

`Bob, who is red, is big` is nonrestrictive and must not become an N restrictor.
The current comma-relative rejection is intentional fail-closed behavior.
Projecting supplements, their presupposition/at-issue status, and reference
resolution need a separately reviewed convention. Preserve no-parse rather than
silently treating punctuation as semantically inert here.

## C1. Constituent conjunction and disjunction

The token `and:conj` is structural. A conjunction introduction creates `X[conj]`;
combining matching `X` with it supplies the connective at the category's type.

| Category X | Conjoined meaning | Key fidelity test |
|---|---|---|
| `S` | `A∧B : t` | Two main-box asserted conditions |
| `N` | `λx.A(x)∧B(x) : p` | Same noun referent |
| `NP` | `λP.A(P)∧B(P) : q` | Both independently quantified NPs |
| `S\NP` | `λQ.Q(λx.A(lift(x))∧B(lift(x))) : q→t` | One shared subject |

Replace `∧` by inclusive `∨` for plain `or`, while retaining its DRS box.
The operator worker owns `either...or` exclusivity policy. A comma is a list
conjunction only in a licensed list derivation, not an all-purpose connective.

`Something is cold and not round` must mean
`∃x(cold(x)∧¬round(x))`; two independent existential subjects are wrong.
DRS `[x | cold(x), ¬[ | round(x)]]` asserts cold and the negated box, while
round is Embedded. `Something is cold or round` has a shared existential
outside the disjunction. Bare universal subjects scope over coordinated VPs;
coordination must not decide a noun phrase's quantifier from the connective.

`Bob likes the cat and the dog` requires a distributive object reading:
`like(Bob,ιcat)∧like(Bob,ιdog)` (the project's current definite convention).
Its two likes conditions are Asserted; definites' resolution/presupposition
convention belongs to the determiner design, not this connective. Collectives
such as `Bob and Anne met` are not licensed by this distributive rule.

## C2. Non-constituent argument-cluster coordination: existing partial repair

For `Bob likes and Anne hates a cat`, raise Bob and Anne to `S/(S\NP)` and
use `>B` with their transitive verbs to produce two `S/NP` constituents. Conjoin
them before supplying `a cat:NP`. The meaning is
`∃y(cat(y)∧like(Bob,y)∧hate(Anne,y))`, with one shared existential object.
DRS `[y | cat(y),like(Bob,y),hate(Anne,y)]` asserts its three conditions.
`coordTerm` scopes q-typed arguments once over the connective; ordinary pointwise
application `λQ.A(Q)∧B(Q)` would incorrectly permit different cats.

Current SemanticRepairSpec checks this shared indefinite and the licensed-model
selected reading. Sealed phase-b Explain around line 303 returns correct
`S/NP` coordination, but its second reading around line 331 uses sentence
coordination after reading `likes` as intransitive: `likes(Bob)∧hate(Anne,ιcat)`.
First divergence is lexical valency/category, followed by a different derivation,
not an ill-typed coordination term. Keep this wrong-but-typed reading visible.
The current selective argument-cluster raising does not license all extraction.

## C3. NP conjunction still has a spurious noun-modifier derivation

Sealed phase-b Explain lines 1429–1480 contains both the correct reading and
`like(Bob,ιx(cat(x)∧dog(x)))∧like(Bob,ιx.dog(x))`. The bad derivation starts
with `cat:N/N`, composes `the` and `cat` into `NP[nb]/N`, conjoins that
incomplete constituent with the second `the`, and applies `dog:N` to both.
Thus “cat dog” is not merely a display typo or a broken connective. The first
semantic divergence is a noun used as an intersective modifier, licensed by a
competing lexical category; coordination of determiners completes the spurious
reading. Banning all `N/N` nouns or all functor coordination would sacrifice real
noun compounds or examples such as `every and some ...`. Review lexical evidence
and construction licensing before adding a contextual constraint. A top-ranked
correct reading is not an all-readings fidelity pass.

## External comparisons: adopt, adapt, reject

[Bos 2008](https://aclanthology.org/W08-2222/) composes CCG-derived meanings into
DRSs and uses neo-Davidsonian event/role representations. Adopt the discipline
of tracking argument binding and DRS scope through combinators; adapt to this
project's direct unary/binary predicates. Its coverage claims are not an exact
meaning score, and the paper is not evidence that our object-relative or
coordination proposals have passed. Event/role output cannot be compared byte
for byte to our gold without an independently specified projection.

The locally cached [ccg2lambda EMNLP2015 templates](https://github.com/mynlp/ccg2lambda/blob/master/en/semantic_templates_en_emnlp2015.yaml)
are concrete comparison evidence: conjunction rules at lines 70–134 include
shared-subject VP lowering, NP continuation conjunction and N intersection;
relative entries around lines 567–578 handle NP modifiers and object gaps.
Adopt their explicit binder sharing. Adapt their two-continuation NP interface
rather than copying its terms into our one-continuation q type. In particular,
NP-relative correctness depends on that restriction interface. Reject blind
copying: this cached file's sentence-level `or` rule literally uses conjunction,
and one forward modifier-`or` entry composes modifiers rather than disjoining
predicates. Those entries cannot define our intended gold. Event-template
variants use different interfaces again; a category match alone proves little.

## Reviewer checklist and order

Prioritize using merged inventory counts, without treating overlapping labels as
a frequency partition. First close the false noun analyses and quantified-pronoun
restrictor issue that produce wrong-but-typed results; preserve repaired subject
relatives and shared-argument coordination. Add object relatives only after
independent gold and extraction licensing review. Nonrestrictives and collectives
remain explicit unsupported families until their semantics is specified.

Require 2–3 independently authored examples for each actual family, including
universal versus existential restrictors, negated relatives, shared existential
VPs/objects, subject/object gap reversal, and both NP conjunction readings.
Existing SemanticRepairSpec examples are engineering regression controls, not
independent benchmark fidelity gold. Review each proposed rule against new gold,
Boxer and ccg2lambda before implementation. Report exact / wrong-but-typed /
no-parse for every construction, plus contamination by any non-gold returned
reading. Do not relabel a ranked success as an unambiguous fidelity success.
