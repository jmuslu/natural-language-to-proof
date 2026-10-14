## C3. Quantifiers, bare plurals and existential there — Units 2/3/4

**Status at accepted d83adaa.** Every/each/all, some/a/an and no have closed
`NP[nb]/N` meanings. This does not guarantee that a sentence supplies the right
noun category, lemma or complete derivation. KnownNounsOnly remains the nominal
construction default; ContextUnknownNouns is explicit opt-in, with typed origins
and policy-bound observations. No enabled-policy measurement is claimed here.
The bare-plural reading below is a declared controlled-domain convention.
Existential-there below is a complete **proposal**, with unresolved licensing
and truth-normalization interfaces; it is not implemented or measured fidelity.

### Unit 2: distinguish category, lexical evidence and construction

Use `P=e→t` for a property and `Q=P→t` for a generalized quantifier. `N:P`,
`NP:Q`, `S:t`; a VP `S[dcl]\NP` has type `Q→t`. Adjectival
`S[adj]\NP` also has continuation type `Q→t`. Treating NP as an entity would
make the following lexical meanings incompatible with the current interface.

| Token/sense | Category | Typed meaning |
|---|---|---|
| cat / bird, ordinary noun | `N` | `cat`, `bird`:P |
| every / each / all | `NP[nb]/N` | `U = λP R.∀x(P(x)→R(x))`:P→Q |
| some / a / an | `NP[nb]/N` | `E = λP R.∃x(P(x)∧R(x))`:P→Q |
| no | `NP[nb]/N` | `Z = λP R.¬∃x(P(x)∧R(x))`:P→Q |
| red / quiet, predicative adjective | `S[adj]\NP` | `λQ.Q(red)` / `λQ.Q(quiet)`:Q→t |
| is / are, adjectival copula | `(S[dcl]\NP)/(S[adj]\NP)` | `λV.V`:(Q→t)→(Q→t) |
| not, VP scope | `(S\NP)\(S\NP)` | `λV Q.Q(λx.¬V(lift(x)))` |

`lift(x)=λR.R(x)`. Feature matching must preserve adjectival versus finite VP
requirements; the generic notation on not is not permission to unify arbitrary
finite/adjacent clause pieces. Plural forms require independently licensed noun
lemmatization. An offered adjective category for *hawks* is not repaired by
merely supplying the correct existential determiner.

### Unit 3: four complete determiner derivations

Here `>` is forward application and `<` backward application. Category subsumption
allowing a subject NP[nb] to fill NP does not change its quantifier meaning.
For `Every cat is red`:

```text
Every:NP[nb]/N  cat:N          is:(S[dcl]\NP)/(S[adj]\NP)  red:S[adj]\NP
        > NP[nb]                           > S[dcl]\NP
                         < S[dcl]
```

The left term is `U(cat)=λR.∀x(cat(x)→R(x))`. The right term is
`λQ.Q(red)`. Applying right to left gives `∀x(cat(x)→red(x))`.
Replacing Every by Each retains this derivation and distributive reading:
`Each cat is red` gives the same implication. It makes no claim about collective
or cumulative plural readings. Replacing Every by Some gives
`E(cat)=λR.∃x(cat(x)∧R(x))`, then `∃x(cat(x)∧red(x))` for
`Some cats are red`. Replacing it by No gives
`Z(cat)=λR.¬∃x(cat(x)∧R(x))`, then `¬∃x(cat(x)∧red(x))`
for `No cats are red`. The latter is not normalized into universal-negative
gold merely because classical logic can prove their equivalence.

For `Each bird is not quiet`, one feature-compatible derivation first combines
`is:VP/AP` with `not:VP\VP` by backward crossed composition, yielding
`VP/AP`; application to `quiet:AP` yields the negative VP. The resulting term is
`λQ.Q(λx.¬quiet(x))`. Apply it to `U(bird)` to obtain
`∀x(bird(x)→¬quiet(x))`. Substituting Some obtains
`∃x(bird(x)∧¬quiet(x))`, **not** `¬∃x(bird(x)∧quiet(x))`.
These are worked derivations using licensed lexical choices, not claims that
Explain always reconstructs the original selected derivation.

### Unit 4: eight worked meanings with full claim boundaries

Notation: `[x | ...]` introduces x locally; `[ | ...]` introduces no referent.
`A=...` lists Asserted conditions; `E=...` lists Embedded conditions in traversal
order. Reported and Presupposed are empty in all isolated examples below; no
disjunction annotations occur. The claim-universe equals the outer DRS universe,
not the union of all nested binders. This notation displays the entire scoped
meaning, not just a truth-functional gloss.

| Sentence | DRS | Asserted; Embedded |
|---|---|---|
| Every cat is red. | `[ | [x|cat(x)] ⇒ [|red(x)]]` | A: whole implication. E: cat(x), red(x). |
| Every bird is quiet. | `[ | [x|bird(x)] ⇒ [|quiet(x)]]` | A: whole implication. E: bird(x), quiet(x). |
| Each cat is red. | `[ | [x|cat(x)] ⇒ [|red(x)]]` | A: whole implication. E: cat(x), red(x). |
| Each bird is not quiet. | `[ | [x|bird(x)] ⇒ [|¬[|quiet(x)]]]` | A: whole implication. E: bird(x), whole inner negation, quiet(x). |
| Some cats are red. | `[x | cat(x),red(x)]` | A: cat(x), red(x). E: empty. |
| Some birds are not quiet. | `[x | bird(x),¬[|quiet(x)]]` | A: bird(x), whole negation. E: quiet(x). |
| No cats are red. | `[ | ¬[x|cat(x),red(x)]]` | A: whole negation. E: cat(x), red(x). |
| No birds are quiet. | `[ | ¬[x|bird(x),quiet(x)]]` | A: whole negation. E: bird(x), quiet(x). |

Only the two Some rows have a main-box witness. A contextual predicate with a
bound discourse referent is not a closed ground fact about an arbitrary named
individual. Nothing in Every/Each proves that a cat or bird exists. A negative
box's x cannot escape as an asserted witness.

These eight are learner examples, not new benchmark gold. Existing independent
files contain Pronto every/each pairs and FOLIO some/some-not/no pairs. The audit
quantifier-gold-audit distinguishes broad two-row labels from missing force/
polarity subtypes; these demonstrations cannot silently fill that empirical gap.

### Bare plurals: same N input, a separate interpretation decision

Current `N→NP` unary semantics logs a generic universal assumption. It is not
inherent in CCG's type change. For controlled `Cats are red`, choose
`G(cat)=λR.∀x(cat(x)→R(x))`, then the same VP application as above. For an
explicit episodic reading, an existential alternative would be
`E(cat)=λR.∃x(cat(x)∧R(x))`; this is a proposed reading policy, not a blanket
source change. One NP cannot silently switch policy to fit observed outputs.

| Declared reading | Derivation and complete DRS | Claims |
|---|---|---|
| Cats are red — controlled universal | cat:N → G(cat):NP; are+red:VP; `< S`. `[|[x|cat(x)]⇒[|red(x)]]` | A: implication. E: cat(x),red(x). Outer universe empty. |
| Birds are not quiet — controlled universal | bird:N → G(bird):NP; negative VP; `< S`. `[|[x|bird(x)]⇒[|¬[|quiet(x)]]]` | A: implication. E: bird(x),inner negation,quiet(x). Outer universe empty. |
| Cats are red — stipulated episodic “some cats here” reading | cat:N → E(cat):NP; are+red:VP; `< S`. `[x|cat(x),red(x)]` | A: cat(x),red(x). E empty. Outer universe x. |

Reported/Presupposed and disjunction metadata remain empty. The last sentence is
intentionally repeated with a different declared context to show an ambiguity,
not proposed as interchangeable gold alternatives for one unlabelled fixture.
Bare generic universals in Pronto/ProofWriter remain their controlled convention;
natural-language genericity need not mean exceptionless universal quantification.
No episodic source reading or contextual location is silently inferred.

### Domain restrictions: do not confuse force with ontology

Strict everyone is `λR.∀x(person(x)→R(x))`; someone is
`λR.∃x(person(x)∧R(x))`. Current lexical something contributes thing, whereas
some independent controlled fixtures deliberately use an unrestricted entity.
That conflict is not cured by changing nominal noun admission. Three complete
contrasts make the distinction visible:

- Everyone is quiet: `[|[x|person(x)]⇒[|quiet(x)]]`; A is implication,
  E is person(x),quiet(x); no main witness.
- Someone is quiet: `[x|person(x),quiet(x)]`; A is both atoms, E empty.
- Something is not quiet: current lexical domain gives
  `[x|thing(x),¬[|quiet(x)]]`; A is thing(x) and whole negation, E quiet(x).
  The separate controlled-entity-existential-v1 gold instead omits thing(x),
  yielding `[x|¬[|quiet(x)]]`, A whole negation, E quiet(x).

Reported/Presupposed/disjunctions are empty. Historical unrestricted everyone,
new strict-person everyone, and controlled unrestricted something are separate
versioned contracts. Do not combine them into a supposedly uniform fidelity
score or authorize two incompatible answers merely to cover both parser outputs.

### Existential there: a proposed full derivation, not a recovered template

Separate existential *there* from locative *there*. The following exact categories
are a candidate to check against actually offered CCGbank entries; this section
does not claim their presence in a selected local derivation:

```text
there:NP[expl]  is:(S[dcl]\NP[expl])/NP   a:NP[nb]/N cat:N
                                                   > NP[nb]
                             > S[dcl]\NP[expl]
                    < S[dcl]
```

Keep the current Q type for NP[expl] **only in this proposed guarded sense**.
Give existential there the dummy continuation `D=λP.True:Q`, and existential
is/are the term `B=λQ λD.Q(λx.True):Q→Q→t`. The expletive argument is ignored
because its lexical occurrence is certified as expletive, not because arbitrary
NP content may be erased. With `a cat=λR.∃x(cat(x)∧R(x))`, reduction yields
`B(a(cat))(D)=∃x(cat(x)∧True)`. After an explicitly licensed logical-True
normalization, intended DRS is `[x|cat(x)]`. No entity named there is introduced.

| Proposed family member | Reduction after True normalization | DRS and full claims |
|---|---|---|
| There is a cat. | ∃x.cat(x) | `[x|cat(x)]`; A cat(x), E empty. |
| There is a bird. | ∃x.bird(x) | `[x|bird(x)]`; A bird(x), E empty. |
| There are no cats. | ¬∃x.cat(x) | `[|¬[x|cat(x)]]`; A whole negation, E cat(x); no main witness. |

Reported/Presupposed/disjunction metadata is empty; claims universe is x only in
the positive examples. No existential import is attached to a negative row.
This is narrow singular/plural existence, not a semantics for *there are three*,
*there is only*, definites, locative there, presentational there or nested relative
restrictions. Those need independent descriptions and gold.

**Unresolved interfaces:** the production category-to-type map does not by itself
certify expletives; source occurrence/category and paired-be evidence must prevent
ordinary name, demonstrative or locative NP from receiving D or losing content.
Feature-sensitive category selection and a dedicated True normalization/DRS path
must be reviewed. No generic NP/Q unwrapping is permitted. The existing nominal
universal/name certificates are not automatically licenses for this different
construction. The displayed derivation is fully typed but no source rule, gold
JSONL, parse measurement or claim of implementation is supplied by this section.

### Explain: locate a divergence only with evidence

For a determiner sentence, inspect actual offered category and closed-entry
selection first, then noun/category/POS and lemma, then scoped application, then
DRS/claims. For a bare plural, identify the logged generic assumption before
judging force. For there, a missing certified expletive/paired-be route is a
proposal boundary; a no-parse result alone would not prove which token failed.
Earlier sealed FOLIO no rows already had negated-existential scope but plural
predicate identity mismatches; do not rewrite no to repair a noun problem.
Explain's compatible replay is constrained reconstruction, not always the
original lexical derivation; raw provenance fallback is not a complete term
trace. No fresh first-divergence measurement was performed for this section.

The v2 unknown-noun route requires lower alphabetic non-name text, no POS evidence,
actual offered N and direct determiner or certified nominal-complement context.
It carries known versus inferred origins through completion/packing and explains
the assumption. It does not supply a missing N category, override JJ/NNP evidence,
solve bare plurals, existential there, general negated nominals or domain policy.
The default-preserving source has passed its release gates; enabled-policy
fidelity remains a separately preregistered experiment, not implied by typing.

### Boxer and ccg2lambda: specific adoption, adaptation and rejection

The retained [Bos2008 account](../REFERENCES.md#boxer) §§3.2–3.3 distinguishes
category/POS/word-dependent construction from resolution; adopt this separation.
Its §5 lack of semantic gold cautions against equating coverage with meaning
fidelity. That account does not establish our exact existential-there entry or
person/thing ontology; this section makes no new claim to have reverified its
PDF. The5b4fa3c audit explicitly records that evidence boundary.

Pinned [ccg2lambda2015 determiner entries](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_emnlp2015.yaml#L213-L265)
provide every/all/each universals and some/a/an existentials, but use an extra NP
restriction slot. Adopt force and restriction/scope separation; adapt the type
interface, never paste a two-slot term into Q. Their no is universal-negative;
retain our independent negated-existential serialization. Their context-free
universal any and existential the are not general replacements for our licensing
and definite identity. The NP everyone entry at192–194 uses _people; mapping it
to person is a declared ontology adaptation. Its default existential NP does not
settle our controlled bare-plural universal choice.

The inspected pinned file's expletive-category entry460–461 is the more complex
`((S[dcl]\NP[expl])/S[em])/(S[adj]\NP)` pattern. It is **not** the simple
existential-be template proposed above; do not cite an expletive feature alone as
proof that upstream supplies or validates this derivation. No upstream system
was run. These comparisons justify separating the interfaces, not borrowing a
coverage number as a fidelity guarantee.
