# C1–C2: reference and nominal predication

These cards teach the bounded implementation accepted through `1b9fc27`, with
policy reporting at `d83adaa`. They are not a claim that arbitrary names,
definites or copular sentences are solved. The negative nominal card describes
the independently reviewed **proposal** `c90f2d5`, not accepted source behavior.

**Reading key.** Let `P=e→t`, `Q=P→t`, and `V=Q→t`. An NP denotes a generalized
quantifier of type Q; `lift(a)=λR.R(a)`. Write `VP=S[dcl]\NP` below.
`[u | conditions]` is a DRS. `Asserted` applies to the whole asserted condition;
conditions inside negation or implication remain `Embedded`, not independent
facts. All examples are learner-authored semantic illustrations, not new gold
or reports of corpus parses. Their category sequences specify the intended
reading; actual lexical admission and source-category evidence are additional
requirements.

Study these in order: [Unit 2: CCG and CCGbank](../../../STUDY_PLAN.md#unit-2-ccg-and-ccgbank-weeks-23-the-biggest-gap)
explains the category/application column; [Unit 3: syntax–semantics](../../../STUDY_PLAN.md#unit-3-the-syntaxsemantics-interface-week-4)
explains beta reduction and the type column; [Unit 4: DRT](../../../STUDY_PLAN.md#unit-4-discourse-representation-theory-week-5)
explains scope, accessibility and claim status.

## C1a. A name denotes an individual, even when its source category is N

For **Arthur is red**, suppose the lexical evidence licenses the rigid-name
reading of Arthur. Token meanings are:

| Token | Interpreted category | Meaning and type |
|---|---|---|
| Arthur | NP | `lift(Arthur) : Q` |
| is | `(S[dcl]\NP)/(S[adj]\NP)` | `λV.V : V→V` |
| red | `S[adj]\NP` | `λQ.Q(red) : V`, with `red:P` |

1. Forward application of **is** to **red** yields `VP`, with meaning
   `λQ.Q(red)`.
2. Backward application to **Arthur** yields `S[dcl]`, with meaning
   `(λQ.Q(red))(λR.R(Arthur)) = red(Arthur) : t`.
3. DRS: `[ | red(Arthur)]`. The atom is `Asserted`. No existential common-noun
   condition `arthur(x)` is introduced.

An actual CCGbank lexical entry can offer `N` for a name. The existing name
repair creates an interpreted NP with `lift(Arthur)` from the **name lexical
branch**, retaining the offered category and occurrence provenance. This is not
the ordinary common-noun unary `N→NP` rule. Compare a common noun `cat:P`:
turning it into a generic or existential Q changes its meaning; merely calling
both results “NP” does not establish fidelity.

The general name policy and the narrower C2 name-subject certificate are
separate. Initial capitals alone cannot settle whether **Dean** is a person or
a role, or **Legend** a person or a common noun. A plural-looking name likewise
cannot be identified by stripping its suffix. No per-name list or universal
casing rule is justified. Multiword/title labels also require intact token and
sentence boundaries: the independent title gold intends a full written rigid
label, without asserting a profession or alias relation.

**First-divergence evidence.** Historical sealed diagnoses of **Dean does not
work** and **Legend is red** found generic common-noun meanings instead of the
intended rigid reference. That is a lexical/category admission issue, not a
failure of the final type checker. The title gold baseline split at **Dr.**;
segmentation is an observed earlier failure there. Neither diagnosis establishes
that every later name derivation is correct. Compatible Explain replay can
reconstruct a provenance-compatible derivation; it is not necessarily the
original selected tree. Raw provenance fallback is not a full leaf derivation.

## C1b. A definite description is currently a description-named constant

For **The cat is red**:

| Token | Category | Meaning and type |
|---|---|---|
| the | `NP[nb]/N` | `λP.λR.R(ιP) : P→Q` |
| cat | `N` | `cat:P` |
| is | `(S[dcl]\NP)/(S[adj]\NP)` | `λV.V : V→V` |
| red | `S[adj]\NP` | `λQ.Q(red) : V` |

1. Forward application **the cat** gives `NP[nb]`, `λR.R(ιcat)`.
2. Forward application **is red** gives VP, `λQ.Q(red)`.
3. Backward application gives `red(ιcat):t`.
4. The current DRT builder translates `ιcat` to `DConst "cat"`. Thus the DRS is
   `[ | red("cat")]`, with the red atom `Asserted`. Quotes distinguish the
   constant label from the noun predicate. For **the bald eagle**, the label is
   `"bald eagle"`, preserving conjunction order in the description.

This is an explicit description-as-name convention, useful for the relevant
controlled theories. It does **not** assert `cat("cat")`, prove that exactly one
cat exists, resolve a discourse antecedent, or accommodate a presupposition.
Repeating the same supported descriptive content names the same constant;
this is a translation convention, not a general theory of definites. Do not
export existence or uniqueness as additional Asserted claims. Reporting and
world-dependent descriptions need their separate intensional contract; this
simple root card does not license rigid reference across every report/world.

The source makes this boundary explicit in `detThe` and `describeIota`
([CCGSem.hs](../../../src/NL2Proof/Semantics/CCGSem.hs),
[Build.hs](../../../src/NL2Proof/DRT/Build.hs)). A source inspection establishes
the encoding; it does not establish a measured first divergence for every
benchmark definite.

## C2a. Positive nominal predication classifies the subject

For **Every cat is an animal**, the ordinary offered categories are:

| Token | Offered category | Ordinary meaning/type |
|---|---|---|
| every | `NP[nb]/N` | `λP.λR.∀x(P(x)→R(x)) : P→Q` |
| cat | `N` | `cat:P` |
| is | `(S[dcl]\NP)/NP` | no unrestricted equative fallback is licensed here |
| an | `NP[nb]/N` | `λP.λR.∃y(P(y)∧R(y)) : P→Q` |
| animal | `N` | `animal:P` |

The accepted construction supplies a **local, typed source certificate** for
the direct nominal frame. Its internal application uses `is:VP/N` with
`C=λP.λQ.Q(P) : P→V` and `an:N/N` with identity `λP.P:P→P`. These internal
categories are a bounded predication analysis, not a claim that the ordinary
article lexicon is `N/N` or that CCGbank supplied that category.

1. **Every cat** uses ordinary forward application: `NP[nb]`,
   `Qcat=λR.∀x(cat(x)→R(x))`.
2. Certified **an animal** captures the actual lexical noun property `animal`
   and preserves it as N. It does not reconstruct that property by inspecting
   an arbitrary NP lambda term.
3. Certified **is an animal** uses forward application, yielding VP,
   `λQ.Q(animal)`.
4. Backward application gives `Qcat(animal)`, hence
   `∀x(cat(x)→animal(x)) : t`.
5. DRS: `[ | [x | cat(x)] ⇒ [ | animal(x)]]`. The implication is `Asserted`;
   both restriction and consequent atoms are `Embedded`. There is no root
   existential witness and no separately asserted animal.

For **Arthur is an animal**, an eligible named subject instead contributes
`lift(Arthur):Q`; the last application yields `animal(Arthur)`. DRS:
`[ | animal(Arthur)]`, one `Asserted` atom. Names are not turned into a
universal restriction, nor is a fresh object equated with Arthur.

**What is licensed.** The accepted rule retains the lexical noun origins,
source categories, occurrence spans and direct copula/article certificate
through the complete root. It requires its bounded subject/root/application
shape and permits the checked final-period path. It is not an embedding,
relative-clause, coordinated-NP or general equative rule. The named extension
mints an origin inside the actual rigid-name lexical branch: positive,
unpruned written/effective POS evidence must be nonempty and exclusively NNP,
with no contrary lowercase support. It retains the original NP/NP[nb] category
or the existing lexical-N name-repair origin. A normalized name-shaped term,
majority NNP vote, note string, unknown capital or generic unary N→NP is
insufficient. This is a declared lexical assumption, not proof that English
names are unambiguous.

`KnownNounsOnly` remains the default noun policy. The separate optional
`ContextUnknownNouns` admits narrowly context-licensed unknown common nouns;
it never extends unknown-name eligibility. The observed installation's lexical
audit found positive NNP support for Abraham, not Alyssa or Amiyah. Missing
training inputs make the audit conditional on observed loader inputs; its
counts alone establish neither a full parse nor a complete subject certificate.
The accepted names trial improved Arthur's nominal case from no parse to exact;
the other 172 selected meanings/statuses were unchanged (173-case diagnostic,
not the representative fidelity gate).

**Why this boundary matters.** The rejected general nominal candidate gained
15 exact readings but produced six formerly-exact regressions and 28 new wrong
readings. Adjectives entering generic NP paths and uncertain name readings can
be well typed yet wrong. The accepted remedy therefore checks source-origin
licensing before semantic application. Ordinary **Arthur sees an animal**
retains existential `a/an`: `[y | animal(y), see(Arthur,y)]`. Predicative article
identity cannot escape into this object NP. No global existential/equality
contraction is used; such contraction can alter discourse accessibility and
recency even when its static formula is equivalent.

## C2b. Negative nominal predication: reviewed proposal, not current coverage

Intended **Every cat is not an animal** has subject-wide scope:
`∀x(cat(x)→¬animal(x))`, not `¬∀x(cat(x)→animal(x))`.

Use the same offered categories as C2a plus
`not:(S\NP)\(S\NP)`. The existing VP-negator meaning is
`N=λV.λQ.Q(λx.¬V(lift(x))) : V→V`. The proposed certificate additionally binds
the actual not lexical origin, category, token index and span in the exact
contiguous **is not a/an** frame.

1. Backward crossed composition (`Y/Z`, `X\Y` → `X/Z`) combines certified
   `is:VP/N` with `not:VP\VP`, producing `VP/N` with `N∘C`.
2. Its meaning reduces to `λP.λQ.Q(λx.¬P(x)) : P→V`.
3. Applying certified **an animal** gives `λQ.Q(λx.¬animal(x)) : V`.
4. Applying **Every cat** gives the subject-wide formula above.
5. DRS: `[ | [x | cat(x)] ⇒ [ | ¬[ | animal(x)]]]`.
   The implication is `Asserted`; restriction, negation and inner atom are
   `Embedded`. For a certified named subject, **Arthur is not an animal** gives
   `[ | ¬[ | animal(Arthur)]]`: the negation is `Asserted`, its atom `Embedded`.

This is an explicit proposed crossing step, not permission for arbitrary
composition to bypass mandatory construction roles. It must retain the
separate universal/name origins, actual seen-category evidence, complete-root
checks and the default noun policy. Missing, swapped or foreign not origins,
wrong features, embedding and unsupported coordination must abstain. The
proposal's independent tests distinguish desired red cases from existing
operator and boundary controls. No accepted corpus gain follows from them.
Ordinary **Arthur does not see an animal** still places its existential object
inside negation: `[ | ¬[y | animal(y), see(Arthur,y)]]`.

## Compare the semantic choices, not just category labels

| Primary comparison | Adopt / adapt / reject here |
|---|---|
| Bos 2008 §§2–3, lexical semantics and compositional DRS construction | **Adopt** category-guided composition and scoped DRS checks. **Adapt** with explicit typed occurrence certificates for this bounded controlled fragment. Do not attribute this local certificate machinery to Boxer. |
| Bos 2008 §3.3, anaphora/presupposition resolution after construction | **Reject as an implemented claim** that our description-named constant performs Boxer's resolution/accommodation work. C1b states the narrower convention. |
| ccg2lambda EMNLP2015 YAML lines20–46, common-noun existential unary and NNP-sensitive equality witness | **Adopt** distinguishing name and common-noun lexical evidence. **Adapt** names to `lift(a)` in our one-continuation Q representation, without its explicit existential equality witness. Neither casing alone nor every N→NP derivation is a name. |
| Same YAML lines213–265, determiners | **Adopt** ordinary existential a/an and universal every/each after adapting its continuation slots. **Reject as our definite contract** its existential `the`: we use the explicitly limited iota-to-constant convention. Predicative article identity remains local. |
| Same YAML lines439–458, copulas | **Adopt** adjectival identity. **Do not activate** its general NP equality copula as a substitute for verified nominal classification; our admitted nominal property is captured at the licensed noun source. |
| Same YAML lines468–480, not/never | **Adapt** the subject-wide VP negation template to Q with one continuation; C2b proposes an occurrence-certified compositional route to use it for nominal predicates. No new global category for not is proposed. |

Sources: [Bos, *Wide-Coverage Semantic Analysis with Boxer* (2008)](https://aclanthology.org/W08-2222/),
[paper PDF](https://aclanthology.org/W08-2222.pdf);
[Mineshima et al. (2015)](https://aclanthology.org/D15-1244/).
Exact implementation comparisons use pinned ccg2lambda commit
`a68cb264413791150011c347c64a7b35e2f7270d`:
[noun/name unary](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_emnlp2015.yaml#L20-L46),
[determiners](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_emnlp2015.yaml#L213-L265),
[copulas](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_emnlp2015.yaml#L439-L458),
[negation](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_emnlp2015.yaml#L468-L480).
These templates have extra lexical/event and continuation arguments; their
category labels do not make their meanings identical to this project's Q.
Boxer's broad coverage discussion (§5) is not a semantic-fidelity guarantee.
