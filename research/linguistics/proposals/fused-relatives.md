# Restrictive relatives on everything, something and someone

Here “fused” refers to the quantifying indefinite-pronoun head. These are overt
headed restrictive relatives, not the free-relative construction of *what*.

**Proposal, not implemented.** The current noun-level relative repair correctly
handles `Every cat that is red is big`, but it cannot attach a restriction to
an already quantified pronoun without moving the relative into the wrong scope.
Adjective-only independent controls now isolate this missing interface from the
separate nominal-copula problem. Never fix it by conjoining a relative proposition
with the matrix proposition or by making *everything* an open-class noun.

## Inventory and actual evidence

ProntoQA's complete local inventory has176,850 `Everything that is ... is ...`
occurrences. Its restrictive conjunction and disjunction gold requires unrestricted
quantification: no `everything(x)` or synthetic `thing(x)` conjunct. The source
also has mixed OR restrictions/AND consequences and negative consequences. The
three nestedPronto relative groups each scored0exact/0wrong/3no-parse against the
frozen original binary; those nine nominal-heavy cases alone do not locate the
first failure. ProverQA's983 outer quantified-pronoun/relative-headed strings are
a broader surface bucket, not983 proven cases of this precise construction.

Current source makes *something* and *someone* closed NP indefinites, the latter
with a `person` sortal. *Everything* has no closed lexical entry and is not
reserved. CCGbank's subject-gap relative category is
`(NP\NP)/(S[dcl]\NP)`. Our existing lexical reanalysis changes that to
`(N\N)/(S[dcl]\NP)` with a property-modifying meaning. The ordinary noun
under a determiner can supply its N argument, but an atomic NP pronoun cannot.
The head-relative interface is therefore missing before nominal predicates arise.

The hand-tagged test dictionary uses the source-supported NP head and NP-relative
category shape, then lets production lexical/category rules operate. It is an
independent controlled dictionary, **not a claim that the live corpus offers
those categories for every one of these words**. No licensed corpus was loaded.
The tests' words, input categories and expected meanings are authored controls;
observed lexical frequencies/beam membership still require a later Explain audit.

## Unit2: bounded paired category reanalysis

Let `P=e->t`, `Q=P->t`, and `V=Q->t` (the semantic type of a VP). CCGbank's NP
interface is not a license to inspect or invert an arbitrary Q term and recover
a restrictor. A quantified head requires a lexical restriction-bearing variant.

A bounded alternative to migrating all NPs is a **paired reanalysis**:

| Part | Source construction shape | Internal proposal | Meaning type |
|---|---|---|---|
| Quantified pronoun head | `NP` | `NP/N`, pending property-relative restriction | `P -> Q` |
| Subject relativizer | `(NP\NP)/(S[dcl]\NP)` | `N/(S[dcl]\NP)`, producing a certified relative property | `V -> P` |
| Relative body | `S[dcl]\NP` | same | `V` |
| Matrix body | `S[dcl]\NP` | same | `V` |

The proposal categories are transparent **internal reanalyses**, not newly claimed
CCGbank attestations. They reuse the existing N property type to avoid a global
NP semantic-type migration, but the result of `that is red` is a relative property,
not evidence that *that* is an ordinary noun or determiner. No category may be
invented for an unknown open-class predicate to make the derivation succeed.

The necessary application derivation is:

```
that : N/VP     is red : VP
              >
         N  [certified relative property]
everything : NP/N
              >
         NP [restriction discharged]
                                   is big : VP
                         <
                            S[dcl]
```

Here `VP` abbreviates `S[dcl]\NP`; the semantic term for its gap is lifted at
composition, not replaced by a fresh referent. The relative body's predicate
coordination/negation stays inside this VP. The matrix VP combines only after
the head consumes its restriction.

**Licensing is part of the proposal, not optional implementation detail.** The
internal head is a closed quantified-pronoun candidate originating in an offered
ordinary NP (or separately justified nominal-head category). A paired relative
candidate must originate in the offered subject-relative category, and the
completed property must carry its derivational origin. The head can consume only
that property; the property cannot undergo ordinary N-to-NP lifting, satisfy a
normal determiner, or become a sentence subject by itself. An internal pending
head cannot consume an ordinary lexical noun (`Everything cat is red`). A root
with an unresolved obligation must not be admitted. A convenient private
`N[fused]` feature alone does not enforce this: current empty feature lists
unify as wildcards. Use an explicit derivation-local obligation/provenance check,
with preservation through allowed applications/compositions, like other bounded
construction obligations; never a global surface phrase rejection.

The initial domain is a single overt restrictive **subject-gap** relative on these
heads. It excludes object gaps, comma supplementaries, free relatives such as
`what ...`, and arbitrary `NP\NP` modifiers. Attachments outside that domain
retain existing behavior or documented failure. Repeated relative attachments
need a separately reviewed restriction-accumulation rule; do not accidentally
admit them by conflating completed NP with a pending quantifying head.

## Unit3: closed meanings and scope

The property-relative term is:

`rel = lambda V. lambda x. V(lambda R. R(x)) : V -> P`.

It does not introduce a quantifier or a separate witness. The three restricted
head variants are:

- `everythingRel = lambda P Q. forall x.(P(x) -> Q(x))`.
- `somethingRel = lambda P Q. exists x.(P(x) & Q(x))` in the declared
  unrestricted controlled domain.
- `someoneRel = lambda P Q. exists x.(person(x) & P(x) & Q(x))`.

All inhabit `P->Q`, the type of internal `NP/N`. The main subject scopes once
across all coordinated predicates. `Something that is red or blue is cold`
has one witness satisfying `(red(x) OR blue(x)) AND cold(x)`, not an existential
independent of the relative or one fresh witness in each disjunct. A universal
OR restriction means `(red(x) OR blue(x)) -> big(x)`, never the stronger
`red(x) -> blue(x) AND big(x)` or `forall red AND forall big`.

**Sortal policy must remain explicit.** Existing production `something` has
`thing`, whereas DESIGN's controlled-fragment convention omits that sortal.
The new *something* red controls intentionally use that already declared
unrestricted domain; they expose an additional semantic-policy mismatch. Do not
silently make the fused version unrestricted while the standalone version still
uses `thing` in the same configuration. A coherent declared domain policy must
choose both forms together; general English may retain a thing restriction.
The literal-English *someone* tests retain `person`. This is not a request to
erase ordinary noun predicates `thing`/`person` or benchmark restrictions globally.
Reviewer must resolve the policy before an implementation can claim these tests.
*Everything* in ProntoQA is independently established as unrestricted.

The adjective VPs `is red`, `is big`, `is cold` use the existing identity copula
and open-class adjective meanings; no change to nominal predication is needed
for these controls. Input `is a dumpus` additionally needs the rejected/quarantined
nominal-copula repair and correct noun evidence. A passing fused-head adjective
suite must not be reported as a repair of all176,850 Pronto relative occurrences.

## Unit4: DRS and claim status, independently specified

The canonical quantifier cases differ fundamentally:

| Input | Intended DRS | Asserted / Embedded |
|---|---|---|
| Everything that is red is big. | `[ | [x | red(x)] => [ | big(x)]]` | A: whole implication; E: red, big |
| Everything that is red or blue is big and cold. | `[ | [x | [ | red(x)] OR [ | blue(x)]] => [ | big(x),cold(x)]]` | A: implication; E: OR wrapper, red, blue, big, cold |
| Something that is red is not big. | `[x | red(x), NOT[ | big(x)]]` | A: red, NOT wrapper; E: big |
| Someone who is red is big. | `[x | person(x),red(x),big(x)]` | A: person, red, big; E: none |

For the universal OR restriction, the antecedent declares x **outside** the
branches. For an existential relative, the top universe declares x before OR or
NOT. This accessibility is part of the independent expected representation, not
something to repair by merging free variables later. `Everything that is not red
is big` places NOT inside the antecedent, and does not assert `not red` globally.
No example supplies a Reported, Presupposed or Confirmed claim. Existential
Asserted atoms retain their context; they do not become closed oracle facts.

The standalone test specifies all nine DRS structures and independently lists
Asserted/Embedded conditions. It additionally requires every returned reading
of these unambiguous controls to retain the intended DRS, preventing a good
alternative from hiding a bad selected or second reading. The adjective OR
control is ordinary inclusive disjunction; full exporter gold must also retain
its `either=false, scope_ambiguous=false` annotations before integration.

## Comparison: adopt the restriction interface, not the wrong template type

The pinned [ccg2lambda2015 relative templates](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_emnlp2015.yaml#L564-L573)
use the CCGbank NP-relative category and an extended
`NP* = P -> P -> t`: the relative fills a restriction argument, leaving the main
scope available. Its [everyone lexical entry](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_emnlp2015.yaml#L189-L198)
retains a people restriction and separate restriction/scope slots. Adopt that
scope discipline. A complete NP* migration would handle the source categories
more directly, but must also migrate names, ordinary determiners, verbs, negation,
coordination and their tests. Its relative meaning is not a well-typed drop-in
at this project's current Q interface.

The paired property route adapts the same separation locally and records its
category deviation explicitly. Reject `lambda V Q R. Q(lambda x.(V(lift x) & R(x)))`
as a universal relative: it adds the restriction to the universal scope. It can
coincidentally produce an existential conjunction, but that accidental success
is not a general relative template. Do not select such a rule by benchmark label
or inspect a normalized arbitrary NP term to guess whether it is universal.

Bos2008 §§2–3 supplies the complementary lesson: lexical/category meanings compose
before discourse resolution, and lexical evidence is more specific than a bare
category. Adapt that separation and transparent lexical reanalysis, not an
unsupported claim that Boxer uses these exact internal categories. Neither the
paper nor the locally inspected ccg2lambda files establishes live nl2proof
supertagger coverage for this construction. The pinned source map is
`research/linguistics/REFERENCES.md`; no upstream system was executed.

## Test-first result and integration obligations

`test/FusedRelativeProposalSpec.hs` has3independent adjective examples per head,
covering universal/relative OR/negative restriction, existential/OR/negative
consequence, and person existential/conjunction/negative consequence. Inputs are
authored construction controls, not copied source benchmark rows. Source-based
nominal controls remain unchanged in the committed fidelity JSONL.

The expected-red run uses only the miniature dictionary and local source:

```
runghc -isrc -itest test/FusedRelativeProposalSpec.hs
```

Initial18 DRS/claim checks all failed with no selected parse; `everything`
reservation also failed. Ordinary determiner+noun relative and two domain
rejection checks passed. All-returned-reading checks were then added before
rerunning, with the additional prediction recorded in the notes. These controls
are not registered as a green release suite and no failing test was removed.

Before implementation, reviewer must approve the closed-head domain policy,
paired origin obligations, and actual-category reanalysis. Then require the
adjective controls, malformed-category controls, corpus-backed Explain first-stage
audit and complete fidelity comparisons. Shared nominal copula, ordinary relatives,
reported complements and punctuation must retain their previous behavior. No
model or answer benchmark can resume merely because this local construction passes.
