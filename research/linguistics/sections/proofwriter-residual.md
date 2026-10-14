## ProofWriter's final 156 residual occurrences: complete text-only review

All12 distinct strings previously labelled `UNCLASSIFIED` have now been inspected
against their saved text-only inventory and their first authoritative input
location. They instantiate **three surface families**, detailed below. This
accounts for the residual without declaring its meanings recovered. The inventory
script and original `UNCLASSIFIED` counts are unchanged; no parser/model/benchmark
was launched, and no label, proof or hidden formal representation was consulted.

### Reconciliation

| Residual family | Occurrences | Distinct strings | Individual-string multiplicities | Assessment |
|---|---:|---:|---|---|
| Name + missing copula + size/age nominal predicate | 36 | 6 | 8,4,8,4,8,4 | Source fragment/ill-formed sentence, not a licensed declarative clause. |
| Association with reflexive object, color complement and concessive passive | 48 | 5 | 12,4,20,8,4 | Missing lexical, reflexive, PP and concessive constructions. |
| Possessive pronoun + red plural body-part NP + past intransitive | 72 | 1 | 72 | Grammatical contextual predication, omitted by the surface lexical recognizer. |
| **Total** | **156** | **12** | | All are `premise_fact`, `paraphrase`. |

The first two families occur only in `meta-train.jsonl`; the last occurs only in
`meta-test.jsonl`. Each has identical counts across four physical locations:
`CWA/NatLang`, `CWA/depth-3ext-NatLang`, `OWA/NatLang` and
`OWA/depth-3ext-NatLang`. Per-location totals are9,12 and18 respectively. Thus
there are39 residual sentence occurrences per corresponding world/bucket set;
the156 physical-file occurrences must not be interpreted as156 independent
linguistic examples. All are standard files, with zero staged/abductive residual
occurrences. The read-only inventory DB contains all110 file paths.

### Boundary audit: representation artifact versus missing construction

The dataset's `sentences` mapping uses a semicolon between portions of these
source units, while the presented `theory` uses a period. The existing inventory
alignment intentionally preserves the presented text before splitting. For **all12
first-source locators**, the residual string is present verbatim in `theory`, its
period-stripped content is present in the mapped input sentence, and the stored
record identifier agrees. This is an input-field check only; mappings' synthetic
logical interpretations were never inspected.

Therefore these are not12 accidental fragments introduced by a new tokenizer.
The missing copula already occurs before the source-unit boundary. The reflexive
association clause is a complete preceding clause. The possessive clause is the
second sentence of a presented unit whose preceding sentence supplies a named
human referent. Preserving that discourse context matters: a unique-string count
collapses contexts in which the possessive may denote different people. Do not
assign all72 possessives the antecedent from the single stored representative.

There is a real **punctuation representation discrepancy**, already handled by
alignment, and a real **context limitation** in sentence-isolated semantic tests.
Neither licenses translating the presented wording into its hidden controlled
fact. A controlled source role called `premise_fact` is provenance, not proof that
all predicates in its paraphrase are top-level asserted properties of its name.

### F1. Missing copula with a comparison standard (36/6)

Authored analogue: `Mira a big person for her young age.` This lacks a finite
copula. Proposed Unit2 pieces are `Mira:NP`, `a:NP[nb]/N`, `person:N`,
`big:N/N`, and a comparison-standard PP. Even if the nominal phrase composes,
`NP NP` is not an application yielding `S[dcl]`. Supplying an unspoken `is`
would be an explicit ellipsis/error-correction policy, not ordinary CCG parsing.
Do not install silent insertion solely to recover this bucket.

Unit3: `big` under the age-standard phrase is not simple intersective
`λN x.N(x)∧big(x)`. A meaning such as
`λN x.N(x)∧bigRelativeTo(x,N,ageStandard(x)) : (e→t)→e→t`
is schematic: its comparison semantics, possessive resolution and degree scale
need a separately declared representation. This audit does **not** propose or
approve an implementation of that operator. If repair is ever enabled, retain
both the inserted-copula decision and the comparison standard as provenance.

Unit4: no complete unrepaired sentence proposition means no Asserted claim.
A repaired variant could contain a predicate about relative size, but it must not
silently assert an unqualified `big(Mira)` or `young(Mira)`; the latter wording
modifies the age expression. Fail closed until an explicit sentence-repair and
comparison policy is reviewed. Authored controls should contrast the malformed
analogue with `Mira is a person` and `Mira is big for her age`, labelling the last
as unresolved comparison semantics rather than forcing a flat gold atom.

### F2. Reflexive association plus concessive passive (48/5)

Authored analogue: `Mira associated herself with red despite being covered in
blue.` The original residual additionally contains a coverage-extent modifier;
that modifier cannot be silently discarded in an exact-meaning claim.

Unit2 candidate categories:

| Item | Category | Semantic responsibility |
|---|---|---|
| associated | `((S[dcl]\NP)/PP)/NP` | Subject, reflexive object and with-complement roles. |
| herself | `NP` | Locally subject-bound reflexive, not latest arbitrary discourse antecedent. |
| with | `PP/NP` | Prepositional argument licensed by association's lexical frame. |
| red (color nominal) | `NP` via licensed color-nominal interpretation | Color/concept argument, not a red-property assertion about Mira. |
| despite | `((S\NP)\(S\NP))/(S[ng]\NP)` | Concessive adjunct sharing the matrix subject. |
| being | `(S[ng]\NP)/(S[pss]\NP)` | Passive auxiliary, preserving passive role structure. |
| covered | `(S[pss]\NP)/PP` | Passive predicate plus complement; covered entity is patient. |
| in | `PP/NP` | Complement relation of covering, not unconditional semantic identity. |

These are proposed licensing choices, not observed CCGbank tags for this sentence.
With project `q=(e→t)→t`, where PP presently maps like NP, association can have
`λO C Q.Q(λx.O(λy.C(λz.associateWith(x,y,z)))) : q→q→q→t`.
Reflexive resolution must enforce `y=x` at the local subject dependency; supplying
an unconstrained existential object is wrong. Whether the color NP denotes a
color individual or reified property must be specified consistently before gold.
A three-place predicate is a proposed representation extension, not an existing
open template or an excuse to turn this whole sentence into a unary label.

A conservative concessive projection is
`λW V Q.Q(λx.V(lift(x)) ∧ W(lift(x))) : (q→t)→(q→t)→q→t`,
which retains both asserted contents with a shared subject. It is **not exact**:
it omits the contrary-expectation component of despite. Exact treatment requires
an explicit concession operator/provenance relation and a declared status for
that component. Do not mark this projection exact in fidelity gold.

Unit4 intended content skeleton, pending representation decisions, has local
identity `associateWith(m,m,redColor)` and a covering condition whose patient is m
and color is blue. It must not assert `red(m)` merely from association. The
covering is inside the concessive subordinate expression syntactically, but
`despite P` normally presents P as actual; an ordinary conditional interpretation
would lose that commitment. A semantic design must distinguish its asserted
content from the additional non-at-issue concession relation. The current claim
classes do not by themselves decide how to encode that relation.

Independent authored contrasts: `Mira associates herself with a group` versus
`Mira associates Nora with a group` test local reflexivity and argument order;
`Mira is calm despite being tired` tests content commitment without inferring a
causal implication. These are proposed gold-design controls, not measured cases.

### F3. Possessive plural body-part predication (72/1)

Authored discourse analogue: `Mira entered. Her red cheeks glowed.` Unit2 needs
`her:NP[nb]/N`, `red:N/N`, `cheeks:N`, and `glowed:S[dcl]\NP`.
The adjective is intersective in this concrete color use. Its noun referent,
not the antecedent Mira, receives the red and glow predicates. Number and past
time are additional representation obligations; no s-stripping or tense deletion
is justified by this bucket alone.

A one-slot GQ skeleton is
`possDet(a)=λN Q.Q(ιx.(N(x)∧possessor(x,a))) : (e→t)→q`,
with `red=λN x.N(x)∧red(x)` and `glowed=λQ.Q(λx.glow(x))` only under an
explicitly declared tense abstraction. The iota/group treatment is schematic:
a plural referent or sum individual C is needed to avoid pretending that cheeks
means a single cheek. An existential approximation changes definiteness.

Unit4 proposed discourse structure: a resolved antecedent a and body-part/group
referent C, with `cheeks(C)`, `red(C)`, `possessor(C,a)` in the possessive
description, and main predication `glow(C)`. Determine with the determiner design
whether descriptive existence/possession is Presupposed and how it is
accommodated; do not casually place every description atom in Asserted. At minimum
`red(a)` and `glow(a)` are forbidden projections. If no antecedent can be resolved,
retain an explicit unresolved-anaphor result/abstention; never emit an apparently
complete claim with a free possessive constant.

Authored contrasts: `Mira entered. Her cheeks glowed` versus
`Nora entered. Her cheeks glowed` test discourse dependence; the isolated
`Her cheeks glowed` tests refusal to invent an antecedent. These expectations
are independent of the dataset's mapped controlled fact.

### What this review establishes

Every residual string is now assigned a **reviewed surface diagnosis**, but all
three families still require design decisions or intentional rejection before
exact semantic coverage can be claimed. Their main obstacles differ: malformed
syntax and comparison standard; reflexive/PP/concessive semantic structure; and
possessive anaphora with plural definiteness. Adding `glowed` or `associated` to
a lexical cue list would reduce `UNCLASSIFIED` while solving none of those issues.

[Bos2008](https://aclanthology.org/W08-2222.pdf) motivates keeping construction
and anaphora/presupposition resolution separate and retaining event roles. The
pinned [ccg2lambda templates](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_event.yaml)
provide comparison points for passive/argument roles and richer event interfaces;
they are not drop-in meanings for this project's direct predicates. Existing
REFERENCES.md/TEMPLATE_COMPARISON.md document those source comparisons. No Boxer
or ccg2lambda run, or claim of their correctness on these12 strings, is made.

### Reproduction evidence

Read-only files: `research/runs/linguistics/proofwriter/unclassified.jsonl` and
`sentences.sqlite3` opened with SQLite `mode=ro`; the latter's `occurrences`
table provides file/role/layer/multiplicity. Residual-cache SHA256:
`c43838e2804f6c1d52eb56e704e46d3c0309c2ec19f4054a6ab485b379e7da55`.
First-source checks accessed only `id`, `sentences[sid]` and `theory` at the12
saved locators in the local full release. No raw or bulk sentence list is copied
into this report. Quantities are aggregate counts; examples are authored analogues.
