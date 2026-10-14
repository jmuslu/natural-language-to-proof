# Construction design: predict the meaning before accepting the parse

This is the learner-facing design for the owner's linguistic-first redirect. Read
it with [CONSTRUCTIONS.md](CONSTRUCTIONS.md), which owns the inventory, denominators
and frequencies, and [STUDY_PLAN.md](../../STUDY_PLAN.md), especially Units 2, 3 and
4. The existing [source comparison](TEMPLATE_COMPARISON.md),
[pinned references](REFERENCES.md) and [bounded name repair](NAMES.md) are retained.
This document distinguishes implemented behavior, observed failures and proposed
rules. A construction card is a specification, not a declaration that it passes.

No answer benchmark or LLM run is licensed by this document. The ProverQA resume
gate remains at least 90% selected-reading exact construction fidelity and
near-zero wrong-but-typed, with independent gold and a disclosed denominator.
Neither a successful type check nor any-reading exact availability opens the gate.

## 1. Three questions, one worked derivation

**Unit 2 asks what combines.** A category has direction and features:
`(S[dcl]\NP)/NP` consumes an object on its right and a subject on its left.
`S[adj]`, `S[pss]` and `S[ng]` distinguish an adjective, a passive participle and an
-ing form. Sharing an arrow shape does not make these interchangeable.

**Unit 3 asks what each combination means.** Write `P=e→t`, `Q=P→t`,
`V=Q→t`, and `lift(a)=λP.P(a)`. Our interface maps `N` to `P`, `NP` to `Q`,
`S[dcl]` to `t`, and `S[em]` to `s→t`. Both slash directions map to function
application types; direction still constrains the syntactic derivation. An open
noun supplies `λx.noun(x)`; an intransitive predicate supplies
`λQ.Q(λx.verb(x))`; a transitive supplies
`λO.λQ.Q(λx.O(λy.verb(x,y)))`. The latter chooses subject-wide scope, which must
remain explicit when both arguments quantify. Closed words supply logical
operations, not ordinary predicates named `some`, `each`, `not` or `if`.

For **Every cat is red**, predict this derivation before running Explain:

```text
every: NP[nb]/N   cat: N      is: (S[dcl]\NP)/(S[adj]\NP)   red: S[adj]\NP
        > NP[nb]                              > S[dcl]\NP
                              < S[dcl]
```

The terms are `every=λP R.∀x(P(x)→R(x))`, `cat=λx.cat(x)`,
`is=λV.V`, `red=λQ.Q(λx.red(x))`. Applying `every` to `cat` yields
`λR.∀x(cat(x)→R(x))`; applying `is red` to that quantifier yields
`∀x(cat(x)→red(x))`. There is no existential import: it does not assert a cat
exists. The `nb` category feature does not change the quantifier's semantic type.

**Unit 4 asks where the truth commitment lives.** Write a box as `[referents |
conditions]`, with an empty slot for no new referents. The result is:

```text
[ | [x | cat(x)] ⇒ [ | red(x)]]
Asserted: the whole implication
Reported: none; Presupposed: none
Embedded: cat(x), red(x)
```

The antecedent binder scopes into its consequent. Neither atom becomes an asserted
world fact. Compare `A cat is red`: `[x | cat(x),red(x)]`. Its two top conditions
are Asserted *in that shared context*, but neither is a closed standalone oracle
claim about a global object called `r0`. Canonical names are bound references.

Throughout the cards, `A` means Asserted, `R` Reported, `Psp` Presupposed and `E`
Embedded. Unless stated otherwise, `R=Psp=∅`; `E` contains the conditions nested
under main-box negation, implication or disjunction, following
[splitClaims](../../src/NL2Proof/Verify/Reported.hs). For a positive ground atom,
`A={atom}` and `E=∅`. These abbreviations specify status without repeating empty
columns in every card. Proposed formulas must be authored as full DRS **and** claim
tables before entering the executable gold set.

## 2. Category evidence and first divergence

The categories below are CCGbank-shaped analyses, not claims that the trained
supertagger currently offers them for every token. A proposed reanalysis is
labelled. Licensed model observations appear in §5. For any unseen example, leave
its current behavior *unmeasured* until its actual Explain trace is inspected.
Do not turn a static prediction into an observed first divergence.

Use Explain's order to locate the first mismatch:

1. **Tokens/tags:** wrong sentence boundary, missing category, wrong name/POS
   evidence, or an incompatible higher-ranked category.
2. **Lexical λ-term:** the right category has no meaning, or receives a wrong
   closed/open template. An offered but dropped category is different from an
   absent category.
3. **Derivation:** wrong attachment, feature loss, unlicensed type change,
   coordination scope or missing complete root.
4. **Normalized λ-term:** check argument order, quantifier scope, polarity,
   particle identity and lemma. If already wrong, DRS lowering cannot repair it.
5. **DRS/claims:** check binders, accessibility, operator boxes, status and source
   chains. A correct formula with wrong status is still wrong-but-typed.

For a no-parse observation, distinguish the *observed* lack of a root from a
*diagnosed* lexical or grammar cause. A lower-ranked correct reading diagnoses
selection; it does not excuse the primary selected error. Some constructions have
both wrong selected meanings and additional unsupported candidates.

## 3. Construction cards

### C1. Names, definite entities and adjective predication

**Forms:** `Bob is red`; `the cat is red`; named/definite subjects and objects in
ProofWriter; ProverQA names; Pronto `named_adjective`. Unit 2 gives
`Bob:NP`, `the:NP[nb]/N`, `cat:N`, `is:(S[dcl]\NP)/(S[adj]\NP)`,
`red:S[adj]\NP`. `the cat` combines by `>`; the copula and adjective combine by
`>`; the subject combines by `<`. Final full stop is structural.

**Unit 3:** `Bob=lift(Bob)`, `red=λQ.Q(λx.red(x))`, `is=λV.V`.
The project's definite convention is `the=λP R.R(ιP)`; it differs from an
existential determiner. A POS-licensed name offered as `N` is given a rigid NP
meaning; this is not the generic common-noun `N→NP` operation.

**Unit 4:** `[ | red(Bob)]`, or the existing definite-constant representation for
`the cat`; A contains `red(Bob)` alone in the name example. Later name identity
may support pronoun resolution without transferring content out of a subordinate
box. Preserve the project's definite convention in gold and do not silently
claim uniqueness/accommodation has been fully implemented.

**Fix and controls:** the completed bounded N/NP name repair accepts a licensed
plain `NP`/`NP[nb]` as well as an `N`-offered name. It does not solve *Legend* at
sentence start or fictional plural recognition. Test a name, an initial common
noun and a proper/common homograph; do not repair by making every capital a name.
[NAMES.md](NAMES.md) contains the observed categories and test-first evidence.

### C2. Predicative nominals versus referential indefinite NPs

**Forms:** `Max is a yumpus`, `Sam is not a rompus`, `Every cat is an animal`.
These underlie Pronto's largest outer family and PW nominal atoms. Intended
classification is `yumpus(Max)`; *a yumpus* is not a second newly discovered
individual standing in an arbitrary relation to Max.

**Unit 2:** CCGbank permits a copular NP complement with `(S[dcl]\NP)/NP`;
`a:NP[nb]/N`, `yumpus:N` yields that complement. An adjective copula entry does not thereby supply this nominal meaning.
The implemented direct-universal checkpoint below is a bounded exception; general
nominal predication remains unsupported; the later attested-name checkpoint adds
a separate direct-name case. Two coherent designs
are possible: retain this syntax and add a marked predicative-NP interpretation,
or log a predicative reanalysis `a:N/N` (identity on P) and
`is:(S[dcl]\NP)/N`. The latter gives `a yumpus:N`, then a VP and sentence by
`>` and `<`. It is a proposed lexical construction, not a claim about the
corpus's original article tag.

**Unit 3:** for the predicative reanalysis, `a_pred=λP.P` and
`is_pred=λP Q.Q(P)` have types `P→P` and `P→V`; hence `yumpus(Max)`.
The ordinary argument determiner remains `a=λP R.∃x(P(x)∧R(x)):P→Q`.
Do not globally replace it with identity. Equality-based copular semantics can
express `∃y(yumpus(y)∧Max=y)`, but adopting that as gold requires an explicit
representation change; the existing Pronto gold specifies direct classification.

**Unit 4:** `[ | yumpus(Max)]`; negative `[ | ¬[ | rompus(Sam)]]` has A the
whole negation and E the atom. `Every cat is an animal` has an implication with
one antecedent-bound variable. No extra existential subject/object is introduced.

**Fix and controls:** implement one coherent predicative construction with trace,
including shared-copula `a P and a Q`; contrast `Max sees a yumpus`, where the
object really introduces an existential. Unknown fictional nouns need general
morphological/category licensing, not a memorized inventory of their names.

### C3. Explicit quantifiers, bare plurals and existential there

**Forms:** all/every/each, some/a/an, no; `Cats are red`; `Everything ...`;
`There is a cat`. Categories for determiners are `NP[nb]/N`; common nouns are
`N`; ordinary predicate composition follows §1. The generic bare-plural derivation
uses `N→NP` before combining with the VP. `everything` and `everyone` may be
lexical NP quantifiers, but their restrictive-relative composition also needs C8.

**Unit 3:** use `all=every=each=λP R.∀x(P(x)→R(x))`,
`some=a=an=λP R.∃x(P(x)∧R(x))`, and
`no=λP R.¬∃x(P(x)∧R(x))`, all `P→Q`. Universal *everything* is
`λR.∀x.R(x)` in Pronto's unrestricted domain; *everyone* can retain a person
restriction for literal English. Sortal removal is a declared dataset-domain
policy, not lexical English semantics. The chosen `no` DRS is negated existential;
a logically equivalent universal-negative representation must be declared before
scoring, not added after observing the output.

For controlled Pronto ontology statements, bare plurals have the generic
`λP R.∀x(P(x)→R(x))` interpretation and singular noun lemmas. In unrestricted
English, *Cats are running outside* need not be generic. Thus changing every
`N→NP` to universal or every `N→NP` to existential is not a general repair.
`There` in existential-there is an expletive `NP[thr]`, never a rigid name.
An existential construction such as `(S[dcl]\NP[thr])/NP` consumes the NP
quantifier and applies it to a vacuous/supplied predicate; the expletive contributes
no participant. This construction is proposed and must pass feature licensing.

**Unit 4:** `some P are Q → [x | P(x),Q(x)]`;
`all P are Q → [ | [x | P(x)]⇒[ | Q(x)]]`;
`no P are Q → [ | ¬[x | P(x),Q(x)]]`.
The first's atoms are contextual A; the others' operators are A and their atoms E.
`There is a cat → [x | cat(x)]`. A *no* sentence must never assert either atom.

**Fix and controls:** reserve logical words against open-template fallback; add
both their licensed categories and meanings; keep a determiner-free object
contrast and singular/plural pair. Existing `each(x)` and `some(x)` outputs are
wrong meanings, not harmless unrecognized-vocabulary features.

### C4. Lexical verbs, possession and do-support negation

**Forms:** `Bob sleeps`, `Bob likes Anne`, `Bob has a dog`, `Bob does not like
Anne`; ProverQA `subject_have`/`subject_do` and lexical unclassified cases; PW
intransitive/transitive atoms. Categories are `S[dcl]\NP` and
`(S[dcl]\NP)/NP`; object `NP` combines by `>`, subject by `<`.
`does:(S[dcl]\NP)/(S[b]\NP)` preserves an untensed VP's meaning while supplying
the finite category; `not` has a VP-modifier category.

**Unit 3:** use the open templates in §1, with a licensed lemma and valency.
Possession `has` can instantiate `have(x,y)` when it really denotes possession.
*has integrity*, *has to leave*, *has left* and *has lunch* require distinct
analyses; a broad has-as-binary-relation rule does not resolve light verbs or
perfect auxiliaries. A noun complement like *integrity* may denote a property,
an abstract object or an idiomatic construction; gold must state which.

**Unit 4:** `[ | like(Bob,Anne)]` has a single A atom;
`Bob has a dog → [x | dog(x),have(Bob,x)]` has two contextual A atoms sharing x.
Subject-wide VP negation is `λV Q.Q(λx.¬V(lift(x)))`; for a ground relation it
produces `[ | ¬[ | like(Bob,Anne)]]`. A is the negation, E the relation.
`Some cats do not sleep` binds a cat outside negation; it does not mean no cat
sleeps. Auxiliary identity must preserve this distinction.

**Fix and controls:** lexical POS/valency and conservative lemma rules; no invented
verb arguments from successful typing. Keep `Bob likes Anne` versus `Anne likes
Bob`, quantified subjects/objects, and *never* versus positive adverbs. Temporal
*never* can use closed negation only under a stated timeless fragment assumption;
full temporal universal force requires additional semantics.

### C5. Conditionals, variable binding and direction

**Forms:** `If Bob is red then Bob is big`; `Bob is big if Bob is red`;
`If someone is red and young then they are big`; PW ground/generic rules.
Fronted `if:(S/S)/S[dcl]` consumes antecedent then consequent.
`then:S/S` is identity. A postposed conditional needs `(S\S)/S[dcl]`, consuming
the following antecedent then the preceding consequent. The syntactic application direction differs; the lexical argument order remains antecedent then consequent:
fronted `λp q.p→q`, postposed `λp q.p→q` where p is still the following clause,
not whichever clause happened to be on the left in the sentence.

**Unit 3:** conjunction inside an antecedent is built before implication. Generic
*someone/something* contributes an indefinite antecedent, whose DRT binder can be
used in the consequent. This is a dynamic binding obligation; plain closed FOL
`(∃x.P(x))→Q(x)` would leave x free. The DRT construction must place x in the
antecedent box and resolve the consequent pronoun to that x. Do not replace every
*someone* in an asserted fact with a universal.

**Unit 4:** ground `[ | [ | red(Bob)]⇒[ | big(Bob)]]`;
generic `[ | [x | person(x),red(x),young(x)]⇒[ | big(x)]]`.
A contains the whole implication; E contains its component conditions. The illustrated someone retains its person restriction. In the declared
controlled fragment, something ranges over the domain without an extra thing
predicate; explicit people/things retain lexical sortal restrictions. A separately
declared domain adapter is a different operation and cannot silently change gold. A negated conjunct remains a nested negative condition, not a positive
premise or closed-world absence.

**Fix and controls:** test antecedent/consequent reversal, repeated versus distinct
variables, conjunction ellipsis and pronoun accessibility. *Only if* reverses the
usual sufficiency direction; *unless* needs its own negative antecedent;
*when*, *whenever* and *once* carry temporal/generic assumptions and cannot all be
silently rewritten to material implication. NatLang surface similarity is not a
license to substitute the synthetic ProofWriter rule.

### C6. Conjunction at noun, NP, VP and sentence levels

**Forms:** `red and young things`; `Bob and Anne sleep`; `Some cat is red and
big`; `Bob is red and Anne is big`; shared nominal predicates in Pronto.
`and:conj` first forms a conjunct category with the right constituent; `coord`
combines it with a compatible left constituent. List commas require their own
coordination derivation. `N`, `NP`, `S\NP` and `S` must remain distinct cases.

**Unit 3:** noun conjunction is `λP R x.P(x)∧R(x)`; sentence conjunction
`λp q.p∧q`. VP conjunction is
`λV W Q.Q(λx.V(lift(x))∧W(lift(x)))`, not `λV W Q.V(Q)∧W(Q)`.
The latter duplicates an existential subject. Distributive named-NP conjunction
is `λP.P(Bob)∧P(Anne)` in this fragment; collective predicates require a plural
individual/event analysis and are not licensed by that rule.

**Unit 4:** `Some cat is red and big → [x | cat(x),red(x),big(x)]`, with one
witness and all three contextual A conditions. `Every cat is red and big` places
both properties in the same consequent box; A is one implication and E includes
cat/red/big. `Bob is red and Anne is big` asserts both ground conditions.

For `Bob likes and Anne hates the cat`, Unit 2 requires the licensed `>T`, `>B`
argument-cluster derivation before coordination, then one shared object argument.
Unit 3 must preserve both verbs and subject roles. With a shared indefinite object,
the intended sharing convention must introduce one object witness if gold says
both predicates concern the same cat. The existing bounded implementation has a
correct selected corpus reading and a wrong alternative, documented in STUDY_PLAN.

**Fix and controls:** preserve the existing shared-quantifier `coordTerm`; repair
constituent availability/attachment, not by replacing coordination with a bag of
atoms. Test shared versus separate determiners and collective near-neighbors.

### C7. Inclusive disjunction, exclusive alternatives and neither/nor

**Forms:** Pronto `P or Q or R`; ProverQA sentence/VP either-or; FOLIO neither-nor.
Like conjunction, `or:conj` operates on matched categories. VP alternatives share
the subject: `λV W Q.Q(λx.V(lift(x))∨W(lift(x)))`. A correlative *either*
marks the coordinated constituent; it cannot introduce an ordinary either predicate.

**Unit 4:** ordinary `[ | [ | P(a)]∨[ | Q(a)]]` has A one OR condition and E
both atoms. Three-way gold may list both independently justified binary
associations because the current structural scorer preserves nesting. Neither/nor
means `¬P(a)∧¬Q(a)` (two A negations, two E atoms), not inclusive or exclusive OR.

Explicit *but not both* contributes `¬(P(a)∧Q(a))` in addition to inclusive OR.
A transparent XOR DRS is `[ | ([ | P(a)]∨[ | Q(a)]), ¬[ | P(a),Q(a)]]`.
Its claim table contains both top operators and nested atoms with their
multiplicity. This is distinct from the current exporter's `either` annotation,
which by itself does not encode the full English truth conditions.

**Dataset versus language:** ProverQA's intended exclusivity convention is
separate from what its varied surface paraphrases actually entail. *Not
necessarily both* does **not** assert *not both*; *mutually exclusive* asserts
at most one and does not by itself assert at least one. Keep two columns in any
such gold audit: literal surface meaning and dataset convention. Do not silently
make the literal-fidelity score pass by changing OR to XOR from labels or dataset
identity. The gate must disclose any convention-dependent cases rather than hide
them inside exact counts.

**Fix and controls:** closed correlative/conjunction rules with explicit scope;
truth-table countercontrols for P=true,Q=true and both false; quantifiers inside
one disjunct must not escape to the other. This is a high-priority nested feature
in the Prover inventory, even though outer *if* dominates its family count.

### C8. Restrictive relatives and quantified pronouns

**Forms:** `Every cat that is red is big`; `Everything that is red and an impus
is a brimpus`; `Anyone who accepts feedback ...`. CCGbank's subject relative
`(NP\NP)/(S[dcl]\NP)` yields an NP modifier after consuming a subject-gap VP.
With our NP type `Q`, naïve pointwise conjunction can put the relative in the
universal's scope rather than its restrictor.

**Implemented bounded alternative:** reanalyse the subject relative as
`(N\N)/(S[dcl]\NP)`, with
`λV N x.N(x)∧V(lift(x)) : V→P→P`. Apply relative to the gapped VP by `>`, attach
it to the noun by `<`, then apply the determiner and matrix VP. This produces
`[ | [x | cat(x),red(x)]⇒[ | big(x)]]`. A is the implication; E cat/red/big.
The wrong `cat(x)⇒red(x)∧big(x)` says every cat is red and is not acceptable.

**Architecture alternative:** ccg2lambda uses `NP*:P→P→t`, an extra restriction
slot. Names, determiners, verbs, negation and coordination then must all migrate
together; its NP-relative term is not well typed as a drop-in replacement in our
`Q` interface. The current noun-level repair can remain bounded while this is
weighed. The bounded quantified-pronoun construction below exposes a restrictor
explicitly; it does not pretend the pronoun already contains an ordinary noun.

**Gold obligation:** unrestricted Pronto `Everything that P or Q is R` requires
`∀x((P(x)∨Q(x))→R(x))`. The x binder is in the implication antecedent universe,
outside its internal OR, so it remains accessible in the consequent. Each
alternative contains P(x)/Q(x), not a separate newly introduced x.

**Fix and controls:** extend a coherent restrictor interface; add object-gap
`(NP\NP)/(S[dcl]/NP)` only with object-role gold. Comma supplementary relatives
need separate projection/status semantics; the existing fail-closed guard stays.

### C9. Particles, prepositions and lexical predicate identity

**Forms:** `Bob wakes up`, `Bob settles down`, `Bob walks up the hill`,
`Bob picks the box up`, `the cat runs through the garden`.
A selected `up:S[adj]\NP` is not a valid particle merely because it type checks.
The original [CCGbank manual §3.7.6, p.53](https://shannon.cs.illinois.edu/Papers/CCGbank/CCGbankManual.pdf)
does not subcategorize phrasal verbs for particles. Its offered categories must
be inspected; sealed evidence includes VP-modifier-shaped `up:(S\NP)\(S\NP)`.
The `PR` analyses in the pinned ccg2lambda templates belong to rebanked parses,
not evidence that this original CCGbank model offers that category. An explicit
reanalysis could combine `(S[dcl]\NP)/PR` and `PR` by `>`, but requires a reviewed
category and meaning interface. A PP modifier commonly has
`((S\NP)\(S\NP))/NP`, consuming its object before attaching to the VP.
Separated particles require their licensed valency/order.

**Unit 3 design choice:** either introduce a shared event continuation with verb,
particle and role conditions, or a declared lexical verb–particle construction
that produces a composite lexical predicate such as `wake_up(x)`.
The source's event term cannot be pasted into our current `PP:Q` type. A particle
must not become a generic object, disappear, or assert `up(Bob)`.
A transparent spatial PP needs a relation to the appropriate entity/event, not
unconditionally an intersective property of the subject. Idioms need a general
lexical construction policy with an explicit licensed lexeme, not a benchmark
sentence-to-formula substitution.

**Unit 4:** under the declared composite-predicate convention,
`[ | wake_up(Bob)]` has A the one atom; `Bob does not wake up` has A the negation
and E that atom. Under event semantics a positive event has an existential event
binder, verb and participant/particle conditions sharing it; negation binds that
event inside its negative box. These two representations are not silently
interchangeable in structural gold.

**Fix and controls:** highest-frequency actual lexical families first, with
unseen names/objects, particle/PP near-neighbors and separated-particle contrasts.
The saved Abdullah trace in §5 is a concrete wrong-but-typed example, not a lack
of theorem-prover power.

### C10. Pronouns, reflexives and local binding

**Forms:** `If a cat is red it is big`; `Bob sees himself`; `Every cat sees
itself`; later `It is red`. Ordinary pronouns are `NP` with an anaphoric referent
and a logged resolution choice. A reflexive can initially be `NP`, but requires
a local coargument-binding obligation; choosing the most recent discourse entity
is insufficient.

**Implemented bounded construction:** a logged object-reflexive reanalysis
`(S\NP)\((S\NP)/NP)` has term
`λR Q.Q(λx.R(lift(x))(lift(x))) : (Q→Q→t)→V`.
Backward application to a transitive verb produces the reflexive VP, then
application to the subject gives `see(Bob,Bob)` or
`∀x(cat(x)→see(x,x))`. This category is derived by the bounded reanalysis, not an assertion that
CCGbank assigns it lexically. The implementation requires a closed reflexive
lexical leaf and a direct finite/base lexical transitive governor; it rejects
unary raising, composition and punctuation before the binding step. Both the
new category pair and its semantic application must be licensed. After binding,
the resulting VP can undergo ordinary subject application or auxiliary negation.

**Unit 4:** named `[ | see(Bob,Bob)]` has A the ground atom. Universal
`[ | [x | cat(x)]⇒[ | see(x,x)]]` has A the implication and E the two atoms.
No fresh object witness and no outside antecedent may replace the bound subject.
Ordinary conditional pronouns use DRT antecedent accessibility; negated or
attitude-local referents do not leak into later main clauses.

**Fix and controls:** local finite-clause/coargument binding with a distracting
prior name and a distinct embedded subject. Gender/number constraints and
logophoric/exempt reflexives remain separate questions. Existing main-box recency
resolution is preserved and is not advertised as a reflexive-binding solution.

### C11. Passive, progressive and modal features

**Forms:** `Bob is chased by Anne`; `Bob is running`; `Bob can run`;
PW birds can/cannot; ProverQA modal and passive predicates.
The passive copula has `(S[dcl]\NP)/(S[pss]\NP)`; progressive auxiliary
`(S[dcl]\NP)/(S[ng]\NP)`; modal typically
`(S[dcl]\NP)/(S[b]\NP)`. They consume different feature-bearing VPs.
The passive `by` phrase is a PP/VP-modifier construction whose agent role is
selected by the passive, not a free extra subject property.

**Unit 3:** passive roles must yield `chase(Anne,Bob)` in a declared direct
relational fragment, or a chase event with Anne as agent and Bob as patient.
An agentless passive leaves an existential/unfilled agent obligation; it must not
become active unary `chase(Bob)`. Progressive identity over an activity predicate
is only a stated tense/aspect abstraction; it is unsuitable for unrestricted
English. A nominal gerund (*Running is tiring*) denotes an activity/event, while
reduced relatives modify a participant. These need distinct unary rules.

One proposed subject-wide/de-re modal schema is
`λV Q.Q(λx.MOD(λw.V_w(lift(x))))`; it is not a unique reading for quantified
subjects, and de-dicto/scope alternatives need independent gold; run remains inside a
modal/world barrier. Treating *can* as identity asserts ability's realization and
is wrong. Benchmark-specific `can_fly` predicates must be separately declared
ontology conventions; they do not establish ordinary can semantics.

**Unit 4:** relational passive `[ | chase(Anne,Bob)]` has A that atom. Modal
`MOD(K)` asserts the modal condition, never the unmodalized inner run atom; a new
modal representation/status policy is required if the current schema cannot
express it faithfully. Keep it unsupported rather than invent a Reported source
or flatten the operator. No existing gold format extension is implied here.

**Fix and controls:** preserve `[dcl]` through composition and distinguish all
three feature families before assigning a template. Use active/passive reversals,
agentless passive, progressive versus gerund, and can versus does controls.

### C12. Punctuation, topic phrases and scope-bearing paraphrases

**Forms:** final `.`, list commas, `For Bob, ...`, quotations, supplementary
relatives, parenthetical *but not both*. A final full stop can be absorbed by a
`punct` rule preserving the constituent meaning. This does not license deleting
all commas or treating arbitrary punctuation as semantic identity.

**Unit 2/3:** list commas participate in coordination (C6/C7); quote suffixes
need attribution; supplementary relative commas change attachment/projection.
A topic `For Bob, he ...` needs an explicit topic/binding construction, not a
free PP erasure. A proposed topical operator can bind a local subject slot,
`λa F.F(a)`, only after the following clause has supplied a genuine open topic
argument and pronouns are resolved; otherwise the type `t→t` identity masks an
unfulfilled dependency. Nominalized *For Bob, running and sleeping are mutually
exclusive* also needs gerund predication and scope, not ordinary entity-NP
coordination.

**Unit 4:** preserve the completed clause's boxes and bindings. A quotation
`Bob says that P` has A `say(Bob,K)` and R its top content with chain `say(Bob)`.
A matrix factive `Bob knows that P` has A its attitude and Psp the projected
content, without duplicate R or A for P. Nested factives retain an enclosing
report chain. Negated reports do not report their denied content.

**Fix and controls:** retain existing quote and nonrestrictive guards. Analyse
at-most-one versus exactly-one explicitly (C7). A fragment lacking a proposition
cannot be completed from an answer label. Titles such as `Dr.`/`Mr.` and quoted
work names need tokenizer/name tests before any semantic repair.

### C13. FOLIO and natural paraphrases beyond the controlled fragment

FOLIO's unclassified sample and ProofWriter NatLang are open obligations, not one
last universal template. Split each into cards as input auditing supplies evidence.
The following distinctions already need gold before production support:

| Construction | Categories/interface to inspect | Intended meaning/status obligation | General rule direction |
| --- | --- | --- | --- |
| Numerals, `four sides` | `N/N` or numeric category plus N; argument NP type change | Cardinality of distinct sides related to one owner; do not assert `four(y)` or generic all-sides quantification | Cardinal determiner/measurement construction, with exact/at-least scope declared |
| Compound nouns, `football player` | `N/N + N → N` | A lexical compound relation or licensed compound predicate; not necessarily football(x)∧player(x) | POS/lexeme-conditioned compound templates |
| Nonintersective adjective, `former president` | Same syntactic N/N shape | Former-president does not entail president now | Closed/lexically typed intensional modifier; no universal intersection fallback |
| Possessives and relational nouns | `NP/(N...)` and determiner/nominal attachment | Preserve possessor, possessed entity and relation, with accessibility/definiteness | Typed possessor construction; no generic noun conjunction |
| `if and only if`, `only if`, `unless` | Clause-taking connectives | Two implications; necessity direction; negated condition respectively, each A whole and E interiors | Dedicated closed connective semantics with scope controls |
| Causal/evidential, `because`, `apparently` | S/VP modifiers and clause attachment | Causation is more than material implication; evidence qualifier cannot disappear into assertion | Preserve relation/operator and evidence status, or abstain |
| Habitual/degree/comparative, `usually`, `more`, `very` | Modifier category does not determine semantic strength | Usually(P) does not entail universally P; comparative needs arguments/scale | Explicit operators or unsupported result |
| Multiword names and quoted titles | Token boundaries, N compounds, NP licensing | Rigid reference is distinct from a quote/report and from common-noun predication | Bounded name span recognition and punctuation rules |

A full cardinality example may bind four pairwise-distinct side variables, each
related to the same subject. *Exactly four* additionally excludes any fifth side;
*at least four* does not. None of these distinctions can be recovered from the
single unary predicate `four`. Do not build a special `four sides → four-sided`
bridge solely because one FOLIO item's answer would improve.

## 4. Inventory-to-design map and implementation order

Counts live in CONSTRUCTIONS and its aggregate JSON, not in a duplicated tally
here. Its outer families partition text; nested cues overlap and must not be summed
as independent sentences. Lexical regex cues are not verified constructions.

| Inventory family | Cards required before claiming fidelity |
| --- | --- |
| Prover `conditional_initial`, `conditional_final` | C5 plus every nested predicate/coordination/pronoun card |
| Prover `subject_copula`, `subject_do`, `subject_have` | C1–C4; C7/C9/C11 as applicable |
| Prover `vp_either_or`, `sentence_either_or` | C7 with C6, explicit surface-versus-dataset scope |
| Prover `quantified_pronoun_or_relative`, `universal_nominal`, `existential_nominal` | C3/C8, predication C2/C4 |
| Prover `subject_modal`, `for_topic` | C11/C12, with nominalizations and exclusivity distinguished |
| Prover `unclassified` | Audit into C4/C9/C10/C13 or new card; it remains in denominators |
| Pronto `named_single_clause`, `named_clause_coordination` | C1/C2, polarity C4, nested C6/C7 |
| Pronto `universal_every_each`, `universal_bare_plural` | C3 plus C2/C6/C7 |
| Pronto `universal_restrictive_relative` | C8 with conjunction/disjunction restrictors |
| PW `ATOM.COPULAR[.NEG]`, `ATOM.NOMINAL[.NEG]` | C1/C2/C4 |
| PW `ATOM.TRANSITIVE[.NEG]`, `ATOM.INTRANSITIVE[.NEG]` | C4; relational preposition C9 |
| PW `ATOM.MODAL[.NEG]` | C11; keep English ability separate from birds ontology conventions |
| PW `COND.GROUND[.COORD]`, `COND.GENERIC[.COORD]` | C5/C6/C10 with antecedent binders |
| PW `UNIVERSAL.EXPLICIT`, `UNIVERSAL.BARE` | C3/C6, sortal-domain convention explicit |
| PW `NL.CONDITIONAL.FRONT/POST`, `NL.CAUSAL` | C5/C13; temporal/causal force needs audit |
| PW `NL.ATTRIBUTION`, `NL.RELATIVE` | C12/C8; actual surface commitment, not synthetic paraphrase |
| PW `NL.QUANTIFIED`, `NL.GENERIC.PLURAL/INDEFINITE` | C3; generics not automatically material universals |
| PW `NL.COORDINATION`, `NL.MODAL.HABITUAL` | C6/C7/C11/C13 |
| PW `NL.COPULAR`, `NL.NONCOPULAR`, `UNCLASSIFIED` | C1–C13 selected by audited subconstruction; no blanket support claim |
| FOLIO matching outer families | Corresponding C1–C12 with literal meanings |
| FOLIO `negative_quantifier`, `existential_there`, `vp_neither_nor`, `biconditional`, residual | C3/C7/C13 |

The Prover outer count is led by initial conditionals, but their linguistic repair
is not a new generic *if* template: it depends on the lexical predicates, names,
coordination and binding inside them. Prioritize by **frequency of the failing
subconstruction**, subject to these dependencies. Reserve closed quantifiers
against predicate fallback and repair predicative nominals/general lexical
licensing before treating coverage as progress. Keep the bounded name repair,
existing Pronto gold and fidelity exporter/contract tests intact.

For each rule: predict its effects; author 2–3 independently reviewed examples
per refined construction (including a scope contrast/blocking near-neighbor);
run the local fidelity diagnostics; inspect all changed meanings; then measure
construction coverage. Reject an increase that creates wrong-but-typed cases.
Frequency determines order, not permission to weaken a rule's truth conditions.

## 5. Observed behavior and first divergences

This section is an evidence ledger. Historical logs remain evidence for their
recorded executables, not automatic measurements of the current source tree.
The full ignored traces are kept locally; only compact authored controls and
summaries belong in git.

| Evidence/input | Observed behavior | First divergence and card |
| --- | --- | --- |
| Saved name Explain: `Legend is red` | Generic `∀x(legend(x)→red(x))`, no rigid name reading | Initial casing/category/name policy before generic type change; C1. Bounded direct-NP name repair does not claim to solve it |
| Saved name Explain: `Abdullah explores cultures` | Selected `∀y(cultures(y)→explore(Abdullah,y))` | Bare object N→NP chooses generic force; C3/C4; proper subject alone is insufficient |
| Saved Prover Explain: `Abdullah settles down` | Selected `∀x(abdullah(x)∧settles(x)→down(x))`; other readings turn down into generic object | Selected N/N, N and adjective tags lack intended particle construction before λ/DRS; C1/C9 |
| Saved FOLIO `folio-val-121`: `Some affection is love` | `some(x)` in a universally quantified restriction | Closed some absent, open modifier plus generic NP; C3 |
| Saved FOLIO `folio-val-163`: `A hawk never lands` | Positive never(x) and lands(x), no negation | Never assigned ordinary property meaning; C4. Additional lemma issues remain |
| Saved FOLIO `folio-val-15`: `All squares have four sides` | Universal sides object restricted by four(y) | Numeric N/N intersection and generic object; C13 |
| STUDY_PLAN argument-cluster coordination | Selected correct; a retained alternative `likes(Bob)∧hate(Anne,cat)` | Wrong lexical valency/coordination reading before DRS; C6 |
| Historical Pronto DRS observation `Jompuses are yumpuses` | Named subject and unsingularized predicate instead of generic implication | Static diagnosis from the observed DRS plus source policy, not a recorded Explain derivation: fictional-plural/name and morphology candidates; C1/C3 |
| Historical Pronto DRS observation `Each yumpus is aggressive` | An extra each(x) in universal restrictor | Observed extra predicate; absent closed each is a static source diagnosis, not a per-case Explain trace; C3 |

Saved evidence paths: `research/runs/linguistics-names/explain-before.log`,
`research/runs/prover-meaning-audit/explain.log`, and the compact FOLIO audit in
[SEAMS.md](../SEAMS.md). See NAMES for which claims precede its bounded repair.

The **historical Pronto diagnostic baseline** has 25 authored cases across 11
construction groups, with 2–3 examples per group. Both default and POS reports
record 3 exact, 5 wrong-but-typed and 17 no-parse; any-reading exact is also 3.
These are local construction diagnostics, not a population accuracy estimate.
Both reports identify executable SHA256
`9558f839ede40fd08beab66e5bce51b4d6beccb24a3d2c7cab28747c5adad53d` and gold SHA256
`3b07deab7fa366a27eba2a7f73b5c71d97b350940e2960bf90effb04274e9d40`.
Their source hashes were observed at evaluation and explicitly do not certify the
compiled source snapshot. Do not relabel them post-repair measurements.

The evidence files are `research/runs/fidelity/pronto-default-report.json` and
`pronto-pos-report.json`. Exact groups: named adjectives 2/2 and every-universal
1/2. Wrong groups: bare-plural universal 3/3, each-universal 1/2 and predicate
conjunction universal 1/3. Other cases are no-parse. The scorer identifies a DRS
structural mismatch; an Explain inspection is still needed before claiming the
first lexical cause for each individual no-parse. Unsupported groups remain
visible rather than being dropped from the score.

## 6. What to adopt from the primary sources

The full per-construction audit and pinned YAML line links are in
[TEMPLATE_COMPARISON.md](TEMPLATE_COMPARISON.md). The following are design decisions
for this project, not assertions that upstream systems satisfy our claim contract.

[Bos 2008](https://aclanthology.org/W08-2222.pdf), §§2–3, motivates separating
category/type, POS-selected lexical meaning, compositional construction and
resolution. Its event roles inform C9/C11, and its compound example warns against
one intersective meaning for every N/N. **Adopt** that separation. **Adapt** event
roles only with a coherent representation migration. **Reject** quote deletion
and automatic accommodation as routes to trusted assertion. The paper's broad
coverage figures are not semantic-gold accuracy, and its discussion reports
unresolved reference and shallow analyses.

[Mineshima et al. 2015](https://aclanthology.org/D15-1244.pdf), §2/Fig.3, motivates
C8's restriction-slot alternative. **Adapt** it only with an interface-wide NP
migration. **Adopt** explicit open templates versus closed logical entries and
operator barriers. **Reject** importing factive veridicality as Asserted admission;
the paper leaves presupposition projection outside its scope. Our DRS/status
contract still governs Reports and Presuppositions.

The pinned [official 2015 templates](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_emnlp2015.yaml)
provide concrete POS-sensitive names, quantifiers, relatives and shared-subject VP
coordination. They also provide counterexamples: the sentence-or entry at lines
102–106 uses conjunction. **Adopt/adapt individual justified rules**, with truth
and scope controls; **reject** a whole-file import or gold copied from upstream
output. The event and flat-event files use different semantic interfaces and
modal treatments; their templates cannot be mixed solely because category strings
match. See REFERENCES for pinned sources inspected locally and rule-selection
implementation. Neither Boxer nor ccg2lambda was installed or run for this audit.

## 7. Fidelity is the admission gate, not the last chart

The [fidelity contract](../../test/fidelity/README.md) compares complete scoped DRS,
independently authored claim table and required disjunction annotations. The
primary partition is selected exact / wrong-but-typed / no-parse, with
incomplete/type-failure/error also retained in the full denominator. Do not force
technical failures into a linguistic success class. Structural ordering and
multiplicity currently matter; this is a conservative exactness metric, not an
independent logical-equivalence theorem.

Gold authoring starts from the construction and source sentence, without solver
answers, proof fields or parser output. Annotate changes, fragment assumptions,
ambiguities, source references, and whether a special benchmark convention differs
from literal English. Independent review checks binding, polarity, identity,
quantifier direction, particle/role content and every claim-status row. Freeze
gold before observing a changed parser. Do not normalize away the semantic error
under investigation.

Report per-construction selected fidelity, any-reading exact availability and
retained wrong alternatives separately. A 90% aggregate over common easy atoms
cannot hide an untested high-risk construction. Publish both the diagnostic-gold
composition and the inventory coverage; frequency-weighted projections must be
labelled projections, never exact full-corpus semantic evaluation. The operational
meaning of near-zero wrong-but-typed must be declared numerically before deciding
the gate, with unresolved scope/convention conflicts disclosed. Until independent
ProverQA construction gold and those checks exist, the gate is not established.

## 8. Reviewed family proposals and executable follow-through

The detailed reviewed proposals are [names/N versus NP](proposals/names-n-np.md),
[quantifiers/determiners](proposals/quantifiers-determiners.md),
[relatives/coordination](proposals/relatives-coordination.md),
[negation/conditionals/disjunction](proposals/negation-conditionals-disjunction.md),
and [particles/reflexives](proposals/particles-reflexives.md). Their notes identify
reviewed snapshots. A proposal approval is not implementation or construction
coverage approval. The independent [coverage audit](../notes/gold-coverage.md)
lists missing nested controls and representation gaps.

Gold fixes the nominal head before modifiers in surface order. The attempted
modifier reorder also renamed the definite identifier `bald eagle` to
`eagle bald`, because definite naming currently uses predicate order. Review
therefore separates this unresolved representation problem from the bounded
quantifier repair. Single and stacked modifier order remain fidelity gaps;
neither changing gold nor renaming a referent is a repair. Likewise no uses negated existential scope in the shared
representation contract; implication-to-negation is truth-equivalent but has a
different canonical claim traversal and is not silently substituted.

### Implemented determiner checkpoint

Commit `d64d3e6` supplies closed meanings for `some`, `no` and `each` at
exact `NP[nb]/N`, and reserves these words against open-class fallbacks.
`some` introduces a restricted existential, `each` a universal implication,
and `no` negates the entire restricted existential. Twenty-four direct
checks cover scope, established determiners and incompatible categories.
Fresh fixed-input fidelity is22 exact/23 wrong-but-typed/40 no-parse across
85 starter cases, versus21/24/40 before this repair; only `pronto-each-1`
changes status. ProverQA remains7/24 exact. Corpus category selection and
other construction errors still prevent the lexical repair from solving
most sentences. This is a bounded implementation result, not a license to
resume answer benchmarks.

The subsequent bounded `has→have` irregular entry preserves noun/adjective/name
meanings and does not license a perfect auxiliary. Twelve direct checks pass.
On114 independent regression rows (112 distinct texts), it changes precisely
the two ProverQA possessive cases from wrong-but-typed to exact:24 exact,
33 wrong-but-typed,57 no-parse. Starter ProverQA is9/24 exact; expanded
construction coverage remains incomplete. This is lexical identity recovery,
not a general morphology or noun-number repair.

### Rejected default nominal-copula candidate

A typed lexical nominal-copula elaborator passed55 focused scope, identity,
discourse and claim-status checks, but failed the independent corpus fidelity
check. On the same114 rows,24 exact/33 wrong/57 no-parse became33/67/14:
15 newly exact, six formerly exact now wrong, and28 newly wrong-but-typed.
Six Explain regressions independently confirmed the problem. Adjectives such
as `cold` acquired a bare-generic NP analysis, and the equative fallback
made `Anne is cold` a universal equation instead of `cold(Anne)`.

The default change was rejected and is preserved only on the local experimental
`astra/nominal-candidate` branch (`91645ae` source, `c2bff11` failure analysis).
Direct term correctness does not license a newly available syntactic route.
Bare N→NP generic meanings and explicit `every` meanings have the same lambda
shape; a term-only exception cannot distinguish them. Future activation needs
local NP-origin licensing, carried through composition/coordination and packing,
as well as independent name and relative-scope repairs. A whole-sentence cue
filter, altered gold, or increased parse coverage would not resolve this failure.

### Conditional delimiter repair

The reviewed chart rule now carries an open-conditional obligation from the
exact closed lexical entry through composition, punctuation and actual unary
raising. Comma coordination cannot conjoin pending clause modifiers; a complete
sentence discharges the obligation. Ordinary comma clauses and explicit `and/or`
remain available. The two role bits participate in chart packing.
Fourteen direct controls pass. Fresh114-row fidelity changes24/33/57 to
27 exact/30 wrong/57 no-parse: the starter binding conditional and both nested
binding cases become exact, with no status regressions. A separate synthetic
raising audit still exposes a pre-existing implication-direction error; it is
retained as a known failure, not counted as fixed by this boundary guard.

### Local direct-object reflexive repair

Closed `himself/herself/itself` entries reanalyse offered ordinary N/NP tags
with the diagonal meaning in C10. Unsupported reflexive forms are reserved
from open-class fallback. The new route requires exact finite/base local
transitive categories, two lexical leaves and the closed binding stipulation.
Twenty-one independent controls cover named/quantified subjects, negation,
locality, unsupported neighboring categories and the corpus-rule pair filter.

On the frozen121-row diagnostic (119 distinct texts), all seven reflexive rows
change wrong-but-typed→exact; the other114 statuses do not change. Totals become
34 exact/25 wrong/62 no-parse from27/32/62. Named identity, quantified diagonal
binding and negated scope now match the independently authored DRS/claims.
This does not cover plural, exempt/logophoric, PP or nonlocal reflexives. All
release gates pass; the ProverQA construction gate remains closed.

### Composition preserves the remaining argument's features

Both surviving ends of composition now preserve a matched whole-category
endomodifier's feature dependency. For forward crossed composition
`X/Y  Y'\Z → X\Z`, if `Y'` and `Z` are the same complete category, matching
`Y'` to `Y` also specializes `Z`. The other three composition rules apply the
same principle with their argument orientation. Unrelated bare `S` subterms
are not unified as one variable.

For example, copular `is` plus backward `not` cannot forget that the remaining
left argument is an adjective VP and consume an already finite `is red` VP.
Both VPs have Montague type `Q→t`; the type checker alone cannot detect this
category mismatch. Sixteen direct feature/type controls and all release gates
pass. In the frozen154-row diagnostic, three wrong FOLIO negative-relative
readings become no-parse, and every exact result is preserved. This removes
invalid derivations; it does not yet supply the missing correct readings.
The historical121 panel remains34/25/62, and semantic-contract partitions
stay separate. The ProverQA construction gate is still closed.

### Bounded Everything/Someone relative construction

An adjacent, source-licensed quantified head and subject relative can receive
paired internal categories `NP/N` and `N/(S[dcl]\NP)`. The relative denotes
`λV x.V(lift(x))`; the head supplies unrestricted universal quantification for
Everything or person-restricted existential quantification for Someone.
These are disclosed internal reanalyses, not claimed original CCGbank tags.

An occurrence-specific certificate allows exactly two direct applications:
relative operator plus finite gapped VP yields a property, then its matching
head consumes that property. Pending states cannot undergo raising, composition,
coordination, punctuation absorption or root admission. Their full identities
participate in chart packing, and the category prepass preserves the paired
source evidence. Ordinary relatives and standalone Someone remain available;
Something's unresolved domain convention is explicitly deferred.

Eighty-nine independent controls cover adjective meanings, Asserted/Embedded
scope, standalone Everything, role transitions, origin mismatch and packing.
They require the general composition-feature repair above. All release gates
pass, and every selected meaning and status in the frozen154-row panel remains
unchanged. This establishes a bounded capability with **no measured gain in
the current benchmark-derived gold**; nominal-heavy relatives still need the
missing predication construction. The historical121 stays34/25/62.


### Punctuation categories require punctuation surfaces

A sparse tagger can offer a punctuation category for a lexical word. Absorbing
that token would erase its contribution before Montague composition: for example,
losing an unseen OR can leave a comma chain interpreted as AND. The lexical
interface now supplies a structural punctuation meaning only for a nonempty
surface consisting entirely of punctuation characters. An apostrophe or hyphen
inside a word does not make that word punctuation; arbitrary symbolic tokens
are not accepted by this check. Actual punctuation still follows its existing
category and chart rules.

This Unit2/3 boundary has139 independent positive/negative controls and passes
all release gates. The frozen154-case panel keeps every selected meaning and
status, so this is an invalid lexical-analysis rejection with no measured gain
on that panel. It does not solve general tokenization, Unicode routing, sentence
segmentation, or all punctuation construction semantics.


### Same-category comma lists retain their overt operator

List composition now retains category, members, edges and their provenance.
A closing overt OR can give preceding comma edges disjunctive force, while
explicit mixed AND/OR subtrees retain their own scope. An earlier OR cannot
turn a later trailing comma into OR. Application, composition and unary rules
clear the list certificate; pending conditional guards still apply. Its full
identity participates in chart packing, so unlike derivations are not collapsed
merely because their normalized terms coincide.

Twenty-four independent controls cover these boundaries and scoped claim tables.
All release gates pass and all154 selected diagnostic meanings remain unchanged;
the gold comma-OR nominal example is still blocked earlier in its derivation.
Explain may report that it cannot replay a repaired list and display raw
provenance: its separate replay engine does not yet carry this certificate.
That limitation is explicit; the displayed Pipeline DRS/claims remain authoritative.
This is a bounded list rule, not general NP coordination or nominal predication.

### Expanded independent gold and observed next gaps

The frozen diagnostic now has167 rows after13 independently specified additions:
three ProverQA nominal classifications, four person-quantifier controls, three
finite active object relatives and three intransitive *give up* controls. Two
Someone controls are exact; the other eleven additions are no-parse. All original
154 statuses and selected meanings are unchanged: the resulting49 exact,
26 wrong-but-typed,91 no-parse and1 incomplete are bookkeeping totals across
separate semantic contracts, **not** a representative acceptance percentage.
The finite active object relatives are authored controls: the audit found none
in the439 distinct FOLIO sample inputs. Their inclusion does not establish FOLIO
population coverage.

The accepted Explain observations sharpen the next Unit2/3 decisions:

- The three positive nominal examples have a category-only sentence derivation
  but no semantic sentence. Their displayed name NP tags do not establish the
  unpruned POS evidence needed by a future name-licensing certificate.
- In the explicit exclusive-disjunction Everyone example, *but* has no
  interpretable category. An AND meaning for a conjunction would need separate
  controls against exceptive uses such as *everyone but Bob*; adding a word to
  an unrestricted conjunction table is not a sufficient design.
- For *Raul gives up* and its negative control, full alternative inspection
  confirms admitted intransitive `gives:S[dcl]\NP` and `give:S[b]\NP` heads.
  The offered `up:(S\NP)\(S\NP)` has no admitted meaning. The first observed
  gap is particle semantic admission, not an absent intransitive head category.
  The top-tag display alone obscures these lower-ranked alternatives.

The proposed particle repair must license the whole two-token lexeme, preserving
both tokens' categories, spans and provenance. Treating *up* as identity or
rewriting an already-built predicate would lose this evidence. The licensed
intransitive sense denotes `λQ.Q(λx.give_up(x))`; negation places the atom inside
an Embedded box, with only the enclosing negation Asserted. Independent gold is already frozen; the concrete implementation still requires
review before it is admitted.

### Direct universal nominal predication: bounded implementation

The paired reanalysis in C2 now has a deliberately narrow implemented route:
`Every/Each N is a/an N`, with a direct lexical noun at both positions and no
embedding. Unit2 uses source-offered nominal copula/article categories to license
internal `(S[dcl]\NP)/N` and `N/N` categories for those exact occurrences.
Unit3 gives the article property identity and the copula `λP Q.Q(P)`; the
ordinary existential article keeps its existing meaning on ordinary routes.
The direct universal subject supplies `λR.∀x(N(x)→R(x))`. Unit4 therefore
asserts the whole implication, with its two atoms Embedded and no existential
witness added to the main box.

The occurrence certificate permits only the paired article/noun application,
matching copula application and direct universal subject application. Its
completed clause may reach the root, optionally with a literal final period;
it cannot enter arbitrary composition, coordination or embedding. Origin and
capability participate in chart packing. Proper names, bare generics, indefinite
subjects, negation and relative/modified nouns remain outside this new route.
Both nouns require positive NN/NNS evidence and no adjective/proper-name conflict.
Unknown POS does not license this implementation. This bounded route avoided the
unbounded candidate's earlier equative and generic-reading regressions in the
frozen diagnostic.

The 59 independent controls test meanings, Asserted/Embedded allocation,
occurrence mismatch, packing and escape routes. The full frozen167 diagnostic
shows no status or selected-meaning gain; the earlier broad candidate remains
rejected. In particular, a separate lexical inventory audit finds no observed
POS evidence for any of the38 noun keys needed by ProntoQA's86,788 matching
surface occurrences. This establishes failure of a necessary v1 condition in
the measured training snapshot, not a full parser-coverage measurement. An
explicit context-licensed unknown-noun policy is a separate reviewed proposal;
it must preserve this route's obligations and be tested independently.

### Adjacent intransitive give-up lexeme

The bounded particle route now licenses adjacent finite `gives up` or base
`give up` from the original offered intransitive head and backward VP-modifier
categories. One complete two-token seed enters both the category and semantic
charts before usefulness filtering. Its meaning is the independently specified
unary `give_up` predicate; both original token spans, categories and scores are
retained in provenance. Ordinary alternatives survive. There is no general
identity meaning for *up*, no transitive-to-intransitive conversion, and no
unfulfilled obligation carried by the completed lexical VP.

Thirty-five independent controls cover scope, original evidence, competing
categories, malformed continuations and repeated source positions. Full release
gates pass. On frozen167, the one unchanged ProverQA source and two authored
particle controls change no-parse→exact; all164 other statuses and selected
meanings remain unchanged. Totals are52 exact,26 wrong-but-typed,88 no-parse and
1 incomplete across separate contracts. Positive `give_up(Raul)` is Asserted;
for the negative case, only its enclosing negation is Asserted and the atom is
Embedded. This measures that licensed sense and those three controls, not general
particle or ProverQA population coverage. Explain's separate derivation replay
still needs the shared span-seed API before it can justify this construction.

### Evidence-bound regular plural noun normalization

An actually offered plain `N` can now use a singular predicate for a narrowly
licensed lowercase regular plural. The surface must have only NNS evidence and
the candidate base only NN evidence in the loaded dictionary; ambiguous suffix
families, capitals, compounds and other category paths remain unchanged. The
original token, category and score survive, with the normalization recorded as a
stipulation. This is a lexical interpretation rule, not a rewrite of exported
DRSs, and it does not alter verbal lemmas or that-clause attestation.

Thirty-three independent controls and all release gates pass. Three selected
readings improve a restriction predicate (`birds→bird` twice and `monkeys→monkey`
once), preserving binders, negation and claim status. They remain wrong against
the full independent gold because the consequent predicates retain `hawks` or
`mammals`. All other selected meanings and all167 statuses remain unchanged:
52 exact,26 wrong-but-typed,88 no-parse,1 incomplete. This is partial lexical
progress, **not** three additional exact sentences; the remaining category and
lexical-evidence causes require their own Explain diagnosis.


### Person-restricted Everyone with offered NP evidence

For Study Plan Unit 2, an actually offered `NP` for *everyone* now receives a
closed-class generalized quantifier. Its Unit 3 meaning is
`λQ.∀x(person(x) → Q(x))`, rather than an open-class predicate named `everyone`.
The existing guarded subject-relative route admits this same NP source:
*everyone who P* contributes `λQ.∀x((person(x) ∧ P(x)) → Q(x))`.
Original source-category and relative-category evidence remain mandatory. An
N-only source is outside this repair and needs a separate licensing design.

In Unit 4, the outer universal implication is Asserted; its person restriction,
relative predicate and consequent stay Embedded. Negated VP controls use the
explicit surface-scope reading `∀x(person(x) → ¬P(x))`. This does not resolve
English scope ambiguity in general. The pinned ccg2lambda 2015 English template, lines192–194, uses `_people(x)`
and two NP predicate slots. Adapting that person restriction to project `person`
and the one-slot continuation type is an explicit lexical/interface choice;
see [the pinned implementation references](REFERENCES.md#official-implementation-pinned-separately-from-the-paper).
Bos2008 supplies methodological context, not evidence for this exact entry.
Semantic class does not follow merely from an available type.

Six independently authored controls were frozen and scored with the previous
binary before this implementation. On the unchanged 173-case diagnostic, these
six and one existing strict-English relative case change wrong-but-typed→exact.
Two legacy unrestricted-domain cases change from an `everyone` restriction to a
`person` restriction but remain wrong against their original contracts. Their
gold is unchanged. The other 164 selected readings and statuses are unchanged.
Totals are 59 exact, 25 wrong-but-typed, 88 no-parse and one incomplete; the mixed
contracts and authored controls do not certify representative ProverQA fidelity.
Eighteen focused controls cover all retained readings, source-category guards,
relative restriction and claim status. All release gates pass, and independent
review verified the source, fixture, binary, observation hashes and every change.


### Explicit policy for context-licensed unknown nouns

The bounded direct-universal nominal route now carries a typed noun origin:
positive dictionary evidence, or an explicitly enabled context hypothesis.
`KnownNounsOnly` remains the default. `ContextUnknownNouns` can admit an offered
`N` with no POS evidence only for a lowercase alphabetic non-name in the direct
Every/each subject position or an occurrence-bound copula/article complement.
It does not invent a noun category, change POS evidence or grant a generic
permission to ignore lexical evidence.

Unit 3 transitions check the original determiner or exact nominal pair when
consuming the hypothesis. Origin distinctions survive completion and chart
packing; the existing root and scope guards remain. Inferred origins add a
logged stipulation. Fifty-eight independent controls cover both policies,
source/context mismatch, packing and retained meanings; the old 59 nominal
assertions remain unchanged. All 27 suites and release gates pass, and the
fresh default-policy 173-case diagnostic preserves every status and selected
meaning. This certifies default compatibility only. An explicit invocation,
exporter response, report and replay policy contract must precede measuring the
optional mode; no enabled-mode corpus gain is claimed here.


### Attested proper names in direct nominal predication

The existing name interpretation now retains a typed record of its lexical
origin. This record is created only by the actual name branch, using the same
model's unpruned POS evidence, casing decision and offered category. It is not
inferred later from a lambda term or explanatory note. Public lexical output is
unchanged. Both ordinary offered name NPs and the existing name N repair retain
the original evidence.

A direct name can complete the bounded nominal copula/article pair only with
positive, consistent singular proper-name evidence. The occurrence-bound origin
survives completion and packing. This gives Unit 3 application of the nominal
property to the rigid individual, and Unit 4 Asserted classification, such as
`bird(Arthur)`. Unknown names, ambiguous lowercase/common-noun evidence,
coordination, negation and embedding do not acquire this license.

Twenty-seven public controls and 46 actual-origin adversarial checks cover the
new route. The full 173-case diagnostic changes only *Arthur is a bird* from
no-parse to exact; all 172 other statuses and selected meanings are unchanged.
The totals are 60 exact, 25 wrong-but-typed, 87 no-parse and one incomplete across
separate contracts. This is one measured source repair, not general named-nominal
coverage. All 29 Haskell suites and the remaining release gates pass. Independent review
verified all source/artifact hashes and the complete comparison before landing.


### Measured optional nominal policy

The [paired 190-case result](NOMINAL_POLICY_RESULT.md) uses one accepted binary
and fixed gold with explicit execution-policy seals. Enabling the bounded unknown
noun hypothesis changes five no-parse cases to exact: two universal Pronto
classifications, two named Pronto classifications and Abraham's archaeologist
classification. All 185 other selected meanings/statuses remain unchanged; no
retained target reading is wrong. Three additional trace-only changes are
reported separately. The default remains KnownNounsOnly, and this diagnostic
neither establishes population coverage nor opens the model-launch gate.

### Measured bounded nominal negation

The [negative nominal result](NOMINAL_NEGATION_RESULT.md) extends the certified
frame to **is not a/an N**, using actual closed-not origin and predicate
negation below the subject quantifier. Default frozen190 gains two sole-exact readings; optional context-unknown
gains five against its own prior baseline. Every other retained reading is
unchanged in each comparison. The default stays known-only; unknown names,
coordination and embedding acquire no extra license. Earlier construction cards
record their stated checkpoints; this result supplies the newer bounded evidence.

## Worked construction lessons (Units 2, 3 and 4)

These reviewed lessons expand the cards above with categories, derivations, typed meanings, DRS and claim scope, current divergences, and Boxer/ccg2lambda comparisons. Proposed rules remain distinct from accepted behavior. Each lesson records its stated evidence checkpoint; subsequent optional noun-policy measurements are reported in [the paired result](NOMINAL_POLICY_RESULT.md), without changing the default policy.

- [Names and nominal predication (C1–C2)](sections/design-names-nominals.md)

- [Quantifiers and determiners (C3)](sections/design-quantifiers.md)

- [Negation, conditionals and disjunction (C4–C5, C7)](sections/design-operators.md)
