# Construction decisions from Boxer and ccg2lambda

This note supplies the source comparison for [DESIGN.md](DESIGN.md). It is a
design proposal against checkpoint `fe5bf33`, before the owner-directed fidelity
repairs. It changes no production behavior. Sources and version are in
[REFERENCES.md](REFERENCES.md).

Start with three questions from the study plan: **Unit2:** what category and
derivation does this token actually receive? **Unit3:** which lexical term and
combinator produce its meaning? **Unit4:** which variable is bound in which box,
and which whole condition can be asserted? A type-correct answer to Unit3 does
not establish that Unit2 selected an appropriate lexical analysis.

Notation below: `P=e→t`, `Q=P→t`, `lift(x)=λP.P(x)`. Our current `NP` has type
`Q`; `N` has type `P`; an intransitive VP has type `Q→t`. A DRS `[x | ...]`
existentially binds `x`; `[]` indicates no new referents. A displayed formula is
the intended meaning of a stated fragment, not an instruction to inject a whole
sentence formula before parsing.

## 1. N, NP, names and quantification — Units2/3/4

**Current seam.** [openTemplate](../../src/NL2Proof/Semantics/CCGSem.hs) maps every
offered `N/N` to intersection; `unarySem` gives every common-noun `N→NP` a logged
generic universal. [lexicalSigns](../../src/NL2Proof/Syntax/CCGSemParse.hs) instead
lifts a POS-recognized name offered as `N` directly to `NP`. Thus a useful names
mechanism already exists, but an offered direct `NP` is not handled by that
names comprehension. Category availability and lexical meaning are separate
failure sites.

**Source comparison.** ccg2lambda's [2015 unary rules](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_emnlp2015.yaml#L20-L46)
choose existential common nouns and a POS-conditioned proper-name case. Its
[determiner entries](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_emnlp2015.yaml#L213-L265)
distinguish some/every/no. Neither its universal `any`, existential `the`, nor our
universal bare-NP default is a context-free truth about English.

**Adapt:** preserve the distinction `cat:P` versus `Bob:Q`. Give *some* the
closed term `λP.λR.∃x(P(x)∧R(x))`; *every* gets
`λP.λR.∀x(P(x)→R(x))`; *no* gets `λP.λR.¬∃x(P(x)∧R(x))`.
These terms have type `P→Q`. Add appropriate determiner categories explicitly;
never permit a reserved quantifier to fall through as `some(x)`. A repair must
address both the offered category and its meaning. Distinguish an episodic bare
plural from a generic in gold; until licensed, retain alternatives or abstain.
Do not resolve the ambiguity by silently switching all `N→NP` to existential.

**Acceptance contrasts:** `Some cats sleep` has a top witness; `Every cat sleeps`
has an implication with an antecedent-bound witness; `Bob sleeps` uses a rigid
name. `Cats are barking` versus `Cats are mammals` tests the bare-plural choice.
Only the whole implication is Asserted; its antecedent and consequent atoms are
Embedded. Existential atoms remain contextual claims, not closed oracle facts.

The existing FOLIO121 counterexample is decisive: *Some affection is love*
currently becomes `∀x(some(x)∧affection(x)→love(x))`, and composes into a false
positive proof. See [SEAMS](../SEAMS.md). This is a lexical/template error before
DRT or solving.

## 2. Restrictive relatives — Units2/3/4

**Source mechanism.** Mineshima etal. §2/ Figure3 uses
`NP*:P→P→t`: one slot extends the restriction, another supplies the scope.
`every N = λF.λG.∀x((N(x)∧F(x))→G(x))`. The
[subject/object relative entries](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_emnlp2015.yaml#L564-L573)
modify the first slot of an `NP\NP`, preserving CCGbank attachment.

**Adapt as a coherent architecture option:** migrating to `NP*` requires changing
determiners, names, transitive scope, negation and coordination together. Adding
that relative term to our current `Q` cannot work. Our existing subject-relative
repair instead reanalyses `(NP\NP)/(S[dcl]\NP)` as
`(N\N)/(S[dcl]\NP)`, giving `λV.λN.λx.(N(x)∧V(lift(x)))`.
That is a bounded alternative with a logged reanalysis, not full CCGbank fidelity.

**Gold:** `Every cat that sleeps runs` must be
`[x | cat(x),sleep(x)] ⇒ [ | run(x)]`, not
`[x | cat(x)] ⇒ [ | sleep(x),run(x)]`. Add an object-gap contrast before claiming
object-relative coverage. **Reject** treating comma nonrestrictives as the same
restriction; the current guard must remain until their meaning/status is
specified independently.

## 3. Negation, modals and feature-sensitive predicates — Units2/3/4

**Adopt closed negation; adapt scope explicitly.** For our time-abstracted test
fragment, VP negation is `λV.λQ.Q(λx.¬V(lift(x)))`; `some N never V` therefore
means `∃x(N(x)∧¬V(x))`, with one witness. Full temporal *never* needs more than
this abstraction. The [2015 never entry](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_emnlp2015.yaml#L468-L480)
has subject-wide scope. The [event version](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_event.yaml#L1518-L1521)
places negation outside the subject quantifier and comments the other choice.
They differ for quantified subjects. Preserve the choice in gold and trace.

**Feature obligations:** current `openTemplate` handles `S[f]\NP` uniformly
except verb versus adjective naming; that is insufficient for voice. The event
templates separate [adjectives](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_event.yaml#L1062-L1074)
from [passives](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_event.yaml#L1086-L1098),
placing the passive subject in the object's event role.

| Construction | Our proposed obligation and decision |
| --- | --- |
| `S[adj]\NP`, *Bob is red* | Adopt entity property `red(Bob)`; copula supplies no extra red event in the present fragment. Do not infer that any token tagged `adj` is semantically an adjective. |
| `S[pss]\NP`, *Bob is chased by Anne* | Adapt role-sensitive composition: `chase(Anne,Bob)` in a direct relational fragment, or a declared event representation with the same participants. Agentless passive needs existential agent or event semantics; never unary `chase(Bob)` as if active. |
| `S[ng]\NP`, *running* | Distinguish progressive VP, reduced relative and nominal gerund conversions. A nominal event/activity reading is not an ordinary person property. Only license the particular unary conversions whose binding and aspect abstraction have gold. |
| modal auxiliary, *Bob might run* | Reject the flat template's [modal event conjunction](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_event_flat.yaml#L1285-L1296) for truth-preserving admission. Keep `run(Bob)` behind an operator/world barrier. This criticism concerns those modal entries, not every attitude entry in that file. |

FOLIO163 currently produces positive `never(x)` and `lands(x)`, not negation.
Adding negative meaning while retaining an incompatible `S[adj]` fallback would
leave a wrong alternative in the beam. Test the full returned reading set.

## 4. Particles, PP attachment and phrasal verbs — Units2/3/4

The later event templates introduce [PR and particle-taking verbs](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_event.yaml#L1155-L1190):
verb and particle constrain one event. This is a useful compositional attachment
mechanism. It is not an idiom dictionary: `give(e)∧up(e)` alone does not establish
the meaning of *give up*.

**Adapt** either (a) lexicalized multiword predicate families for the inventoried
fragment, with a typed, logged verb–particle construction, or (b) event predicates
and shared event roles through a coherent semantic-type change. Choose using the
generator's actual particle inventory, not answer labels. Our present `PP:Q`
stipulation is not the event template's `PP:Ev→t`; copying its lambda terms would
change types and ontology.

**Gold contrasts:** *Bob wakes up* versus *Bob walks up the hill*; transitive
*Bob picks up the box* versus separated *Bob picks the box up*; an unsupported
idiom must remain explicitly unsupported. Preserve the particle in the predicate
or event condition, argument order, and object witness. Do not add `up(Bob)` or
drop *up*. **Reject** the source's higher-order PR entry at lines1189–1190 for a
general fallback: it ignores both verb and particle arguments.

## 5. Reflexives — Units2/3/4

Boxer's §3.3 lists reflexives among resolution triggers, but does not supply a
local binding implementation in this paper. A literal search of the three
English YAML files for reflexive names (`himself`, `herself`, `itself`,
`themselves`, `ourselves`, `myself`, `yourself`) and `reflex` found no dedicated
entry. This does not establish absence elsewhere in ccg2lambda.

**Design locally; do not copy a nonexistent guarantee.** *Every cat sees itself*
requires `∀x(cat(x)→see(x,x))`. The reflexive is a coargument bound by the local
subject, not a fresh existential or the latest discourse referent. An explicit
lexical reanalysis can give object reflexive category
`(S\NP)\((S\NP)/NP)` and term
`λR.λQ.Q(λx.R(lift(x))(lift(x)))`; application to the transitive verb yields a VP.
This is a proposed construction rule, not a claim that CCGbank assigns that tag.
Alternatively carry a binding obligation to a local composition step. Either
route needs a logged derivation and must not escape an attitude/negation box.

**Gold:** named and universal subjects, a distracting earlier name, and an
embedded clause with a different local subject. Exempt/logophoric reflexives and
possessive configurations remain outside this initial rule. Test gender/number
licensing separately from identity of the two predicate arguments.

## 6. Conjunction and coordination — Units2/3/4

**Adopt shared-witness VP coordination.** The
[2015 VP conjunction](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_emnlp2015.yaml#L71-L90)
scopes one subject over both predicates. Our `coordTerm` already follows this
principle: `something is red and big` has one witness, not independent witnesses.
Retain separate noun, NP, VP and sentence acceptance cases even with a polymorphic
implementation. Nonconstituent coordination still needs licensed raising and
composition, preserving both lexical verbs and their arguments.

**Reject universal distributivity:** *Bob and Anne lifted a piano* may be
collective. A distributive fragment must say so or expose alternatives. For
inclusive *or*, retain `COr` rather than two Asserted atoms; exclusive *either/or*
is an explicit benchmark convention only where locally attributed.

**Source counterexample:** the [2015 sentence-or rule](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_emnlp2015.yaml#L102-L106)
uses conjunction. Substituting one true and one false sentence distinguishes that
formula from disjunction. This is a static rule audit, not a claim about every
upstream parse. Do not use the existence of a published YAML entry as gold.

Current corpus evidence retains a bad second reading of *Bob likes and Anne
hates the cat*: `likes(Bob) ∧ hate(Anne,cat)`. Top-reading correctness cannot hide
this construction failure; the fidelity runner should expose all-reading exact
availability and wrong retained alternatives separately.

## 7. Punctuation — Units2/3/4

The [2015 rules](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_emnlp2015.yaml#L138-L173)
distinguish final punctuation, comma absorption and comma coordination. Our
`PunctLeft`/`PunctRight` rules are broad, with later construction guards.

**Adapt rule-sensitive treatment:** final full stop may preserve its sentence;
list comma needs a licensed coordination; comma apposition, nonrestrictive
relatives and attribution need their own semantics/status. **Reject** punctuation
deletion as a universal identity. Preserve existing nonrestrictive/quote guards
until replacement derivations pass fidelity tests. A quote-like sentence that
cannot preserve attribution should abstain, not assert its quoted proposition.

## 8. Numerals, compounds and template selection — Units2/3

**Adopt the source distinction, not a single broad rule.** Bos §3.2 is directly
relevant to our `N/N` collision. A numeral constrains cardinality; a compound can
introduce another referent/relation; an intersective adjective conjoins a
property. A non-intersective adjective requires a different operator.

FOLIO15's *four sides* is currently a universal object restriction, and it is not
linked to *four-sided*. Gold must preserve cardinality or mark the construction
unsupported. Do not invent an unbounded bridge between hyphenated adjectives and
arbitrary noun phrases merely to make this item answerable.

**Adapt declarative matching:** ccg2lambda's category, base/surface, POS, rule
and child-feature schema is useful for recording exactly why a template applies.
Prefer explicit priorities or checked disjoint cases to undocumented last-match
wins. Record the selected rule and competing matches in Explain. **Reject** its
[arity-only fallback](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/scripts/semantic_index.py#L156-L169),
which can erase an uninterpreted expression. An unsupported construction should
remain measurable as no parse/residual.

## Fidelity contract before implementation

For each construction, keep at least a positive example, a quantifier/scope
contrast and a blocking near-neighbor. Author its category derivation, normalized
lambda term, scoped DRS and claim-status table before changing the template.
Use generator-derived examples without deriving gold from the current parser or
solver labels. Compare selected-reading exact/wrong-but-typed/no-parse first;
report any-reading exact separately and retain all wrong alternatives for audit.
Neither a high parse score nor a closed oracle condition establishes English
faithfulness. The proposed templates must earn that claim one construction at a
time.
