## C6. Coordination: choose the constituent, then preserve its binders

This section uses the current direct-predicate interface:
`P=e→t`, `Q=P→t`, `V=Q→t`, and `lift(a)=λR:P.R(a)`.
Unit2 identifies categories and licensed rules; Unit3 checks every binder;
Unit4 places the resulting conditions in scoped boxes. Examples are authored
teaching controls, not new corpus observations or additions to the acceptance set.

### N, NP, VP and sentence conjunction are different operations

The syntactic coordination schema first marks the right constituent:
`and:conj + Y → Y[conj]`, then combines a compatible left `X` with it to
produce the common category. This is a construction operation, not a claim
that original CCGbank supplies every occurrence of and with lexical category
`(X\X)/X`. Shared semantic arrow types do not license arbitrary category mixing.

| Coordinated category | Typed conjunction in this interface | Binding obligation |
| --- | --- | --- |
| N | `λP₁:P P₂:P x:e.P₁(x)∧P₂(x) : P→P→P` | One individual satisfies both noun predicates. |
| NP | `λQ₁:Q Q₂:Q R:P.Q₁(R)∧Q₂(R) : Q→Q→Q` | Each NP keeps its own quantification; this is a distributive reading. |
| S\NP | `λV₁:V V₂:V Q₀:Q.Q₀(λx.V₁(lift(x))∧V₂(lift(x))) : V→V→V` | Apply the subject quantifier once. |
| S | `λp:t q:t.p∧q : t→t→t` | Two already composed propositions retain their own binders. |

These are meanings to validate, not a claim that every NP/category path is
currently faithful. `Bob and Anne sleep` has the distributive NP
`λR.R(Bob)∧R(Anne)`. Combining with `sleep:V=λQ.Q(λx.sleep(x))`
gives `sleep(Bob)∧sleep(Anne)`:

```text
Bob:NP       and:conj Anne:NP               sleep:S[dcl]\NP
                     mark NP[conj]
          coord NP
                              < S[dcl]
```

DRS `[ | sleep(Bob),sleep(Anne)]`: both atoms Asserted; no Reported,
Presupposed or Embedded content. A collective example such as two people lifting
one piano is not licensed by this distributive interpretation. For `a cat and a
dog`, NP conjunction preserves two existential choices, not a single individual
forced to be both cat and dog. N conjunction instead precedes the determiner and
requires one witness satisfying both predicates.

### One shared subject versus two subjects

For `Some cat is red and big`, compose `is` with the coordinated adjective VPs:

```text
some:NP[nb]/N cat:N       is:(S[dcl]\NP)/(S[adj]\NP)
        > NP[nb]          red:S[adj]\NP and:conj big:S[adj]\NP
                                         mark (S[adj]\NP)[conj]
                                  coord S[adj]\NP
                               > S[dcl]\NP
                         < S[dcl]
```

`some cat=λR.∃x(cat(x)∧R(x))`. Shared-subject VP conjunction gives
`∃x(cat(x)∧red(x)∧big(x))`, DRS `[x | cat(x),red(x),big(x)]`.
All three conditions are Asserted **in the shared existential context**; they
are not closed oracle facts about a globally named object `r0`.
By contrast, `Some cat is red and some cat is big` coordinates two S meanings:
`[x,y | cat(x),red(x),cat(y),big(y)]`. It does not assert `x≠y`, but does not
require a shared witness either. The truth conditions must allow different cats.

With `Every cat is red and big`, the intended DRS is
`[ | [x | cat(x)] ⇒ [ | red(x),big(x)]]`. Only the implication is Asserted;
cat/red/big are Embedded. Reusing the subject quantifier twice would duplicate
an existential in the some case, even if the every case happens to be logically
equivalent. That is why universal-only tests cannot certify witness sharing.

### Argument-cluster coordination and a shared object

For `Bob likes and Anne hates a cat`, the subject+verb clusters must first
become object-taking constituents. Use source-licensed raising and composition:

```text
Bob:NP                    likes:(S[dcl]\NP)/NP
  >T S[dcl]/(S[dcl]\NP)
                  >B S[dcl]/NP

Anne:NP                   hates:(S[dcl]\NP)/NP
  >T S[dcl]/(S[dcl]\NP)
                  >B S[dcl]/NP

Bob likes:S[dcl]/NP    and:conj Anne hates:S[dcl]/NP
                                 mark (S[dcl]/NP)[conj]
                       coord S[dcl]/NP       a:NP[nb]/N cat:N
                                                       > NP[nb]
                                      > S[dcl]
```

The displayed feature-compatible raising is a hand derivation requirement,
not a newly authorized type change. Actual model licensing remains necessary.
The cluster meanings are `L=λO:Q.O(λy.like(Bob,y))` and
`H=λO:Q.O(λy.hate(Anne,y))`, both `Q→t`. Under the explicitly shared-object
reading, combine them as `λO.O(λy.L(lift(y))∧H(lift(y)))`.
Applying `a cat` yields `[y | cat(y),like(Bob,y),hate(Anne,y)]`.
All three are contextual Asserted conditions; Reported, Presupposed and Embedded
are empty. The object is shared across predicates, not copied into two independent
existential quantifiers. If a different scopal reading is intended, gold must
state it before scoring; this derivation does not settle all English coordination.

The saved corpus example with **the cat** retains a correct selected reading
and an alternative `likes(Bob)∧hate(Anne,ιcat)`. The latter arises from a wrong
intransitive lexical alternative for likes; it is not harmless spurious
ambiguity. Harmless derivational ambiguity holds lexical choices and licenses
fixed and produces the same normalized meaning. Every retained wrong lexical
alternative remains visible even if ranking selects the desired one. General
NP coordination still has the documented spurious cat-dog analysis; the formulas
above do not constitute a repair of that path.

### Accepted list guards and explanation limits

The accepted same-category comma-list construction retains a final overt OR,
recomposes its certified list, and preserves explicit mixed-operator subtrees.
Its certificate and pending-state identity participate in packing. This does not
make mixed nominal/adjective complements interchangeable or license arbitrary
functor coordination. A list's OR box is Asserted, with disjunct contents Embedded;
no individual disjunct becomes asserted by appearing in the same chart.

Explain can fail to reconstruct accepted list provenance. Its final formula,
DRS and claim split come from Pipeline, while its derivation is a separate
compatible reconstruction; successful replay is not proof of the exact original
lexical derivation. Raw-provenance fallback is an explanation limitation, not
by itself a semantic mismatch. Identify an observed first linguistic divergence
against independent gold separately from a replay failure boundary.

## C8. Relative clauses: put the restriction before the quantifier's scope

### Subject gap at noun level

For `Every cat that is red is big`, original CCGbank subject-relative evidence
may be `(NP\NP)/(S[dcl]\NP)`. The accepted bounded reanalysis attaches at N:
`that:(N\N)/(S[dcl]\NP)`. Its meaning is
`λW:V N:P x:e.N(x)∧W(lift(x)) : V→P→P`.

```text
every:NP[nb]/N cat:N    that:(N\N)/(S[dcl]\NP)
                        is:(S[dcl]\NP)/(S[adj]\NP) red:S[adj]\NP
                                            > S[dcl]\NP
                                  > N\N
                     < N
              > NP[nb]                  is big:S[dcl]\NP
                                < S[dcl]
```

The meaning is `∀x((cat(x)∧red(x))→big(x))`, DRS
`[ | [x | cat(x),red(x)] ⇒ [ | big(x)]]`. Only the implication is Asserted;
all atoms are Embedded. `∀x(cat(x)→(red(x)∧big(x)))` instead says every cat
is red and fails fidelity. The relative attaches to the restriction, not the
universal's consequent. For `A cat that is red is big`, DRS
`[x | cat(x),red(x),big(x)]` has three contextual Asserted atoms. The relative
word does not itself determine claim status: the enclosing quantifier does.

The accepted rewrite uses exact relative-category evidence for that/which/who,
records the attachment reanalysis, and licenses the local relative/VP and N/modifier
combinations. It is not a coherent replacement of the whole NP semantic interface.
Comma-marked nonrestrictive relatives remain rejected; supplement projection and
status require an independent construction design.

### Object gap: same semantic type, different syntactic direction

For `Every dog that Mira likes is quiet`, the missing argument is the object.
The proposed source category is `(NP\NP)/(S[dcl]/NP)`, reanalysed as
`(N\N)/(S[dcl]/NP)` only with reviewed source evidence. The slash in the
gapped clause is `/`, not `\`:

```text
Mira:NP                 likes:(S[dcl]\NP)/NP
  >T S[dcl]/(S[dcl]\NP)
                 >B S[dcl]/NP
that:(N\N)/(S[dcl]/NP)    Mira likes:S[dcl]/NP
                     > N\N
             dog:N < N\N  => N
       every:NP[nb]/N > N  => NP[nb]
                  NP[nb] < is quiet:S[dcl]\NP => S[dcl]
```

The gapped clause means `λO:Q.O(λy.like(Mira,y))`. Apply the restriction
term to it, preserving role order. Result:
`[ | [x | dog(x),like(Mira,x)] ⇒ [ | quiet(x)]]`.
The implication is Asserted and dog/like/quiet are Embedded. Reversing
`like(Mira,x)` to `like(x,Mira)` is a wrong-but-typed error because slash
direction disappears in the semantic arrow type. For an existential determiner,
`[x | dog(x),like(Mira,x),quiet(x)]` shares one object witness; for no,
`[ | ¬[x | dog(x),like(Mira,x),red(x)]]` asserts only the complete negation.
Inner relative negation instead nests just the relation under NOT inside the
restriction; it must not negate the whole universal.

This object-gap extension is **not implemented**. The next-priority
proposal has three expected-red positives and three passing controls; source
implementation still needs expanded guards and review. Its three existing gold
rows are AUTHORED, not source-attested FOLIO cases: the audited439 distinct sample
strings contained no identified finite active object relative. Infinitival and
reduced passive relatives are separate. High-frequency nominal-relative work
remains ahead of this lower-priority extension.

### Quantified pronouns: paired restriction without inventing a noun

The accepted source-licensed adjacent construction pairs an NP head with a
subject-relative marker and derives internal `NP/N` plus `N/(S[dcl]\NP)`:

```text
Everything:NP/N    that:N/(S[dcl]\NP)   is red:S[dcl]\NP
                                 > N
                     > NP                  is big:S[dcl]\NP
                                    < S[dcl]
```

These are disclosed internal categories, not claimed original lexical tags.
Relative property `R=λx.red(x)` comes from `λW:V x:e.W(lift(x))`.
The head meanings have type `P→Q`:

- Everything: `λR K.∀x(R(x)→K(x))`, under the stated unrestricted-domain contract.
- Someone: `λR K.∃x(person(x)∧R(x)∧K(x))`, for the existential fact reading.
- Everyone: `λR K.∀x((person(x)∧R(x))→K(x))`, strict-English person restriction.

Thus Everything gives `[ | [x | red(x)]⇒[ | big(x)]]`; Everyone adds person(x)
in that antecedent. Their whole implications are Asserted and all atoms Embedded.
Someone gives `[x | person(x),red(x),big(x)]`, with contextual Asserted atoms.
A generic conditional containing someone has a different outer DRS context;
this standalone existential does not authorize a universal rewrite everywhere.

The occurrence-specific certificate permits only relative+finite gapped VP and
then matching head+property direct applications. Pending states cannot raise,
compose, coordinate, absorb punctuation or enter a root; full origin identity
survives packing. Coordination can occur **inside the ordinary VP** before the
relative consumes it. For `Everything that is red or blue is big`, the binder
must remain in the antecedent universe outside the OR:
`[ | [x | [ | red(x)]∨[ | blue(x)]] ⇒ [ | big(x)]]`.
The outer implication is Asserted; the inner OR, red/blue and big are Embedded.
No branch creates its own fresh x. Mixed nominal/adjective restrictions need
separate nominal licensing; this pronoun construction does not supply it.

### Primary-source comparison and first-divergence worksheet

[Boxer2008 §§2–3](https://aclanthology.org/W08-2222.pdf) motivates explicit
compositional binding and subsequent DRS resolution. Its event/role predicates
are not byte-identical to this project's direct relations; no upstream exactness
claim follows. [Mineshima2015 §2/Fig3](https://aclanthology.org/D15-1244.pdf) and
[pinned 2015 templates566–573](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_emnlp2015.yaml#L566-L573)
use an NP restriction slot: `NP*:P→P→t`. Their relative modifies that slot.
Adopt the explicit binder discipline; adapt the interface coherently if migrating;
do not copy its NP modifier into our one-slot Q. The bounded N/paired-relative
routes above are declared alternatives, not an implementation of all NP* behavior.

The same pinned file's VP conjunction87–90 applies one subject quantifier around
both predicates; NP conjunction77–80 retains separate NP continuations. Its
sentence-or entry102–106 uses conjunction, so the template file is not a truth
oracle. Everyone192–194 uses `_people` and NP*: the project's person restriction
is an explicit lexical/ontology adaptation, not a literal copy.

For each exercise, write the expected scope first. Then record offered category,
admitted lexical term, guarded composition, normal form, DRS and claim split.
Mark the earliest **observed** mismatch only when evidence establishes it. A
missing object-relative lexical alternative in a miniature test is a measured
local boundary; a full corpus no-parse alone does not prove that is its first
failure. Keep historical wrong alternatives, current observations, proposed
repairs and Explain reconstruction failures in separate columns.
