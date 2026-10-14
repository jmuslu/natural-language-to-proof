# Primary sources for the construction redesign

Read on 2026-10-14. This is a source map, not a claim that either historical
system implements our guarantees. The comparison and proposed acceptance cases
are in [TEMPLATE_COMPARISON.md](TEMPLATE_COMPARISON.md). The current integrated
design belongs in [DESIGN.md](DESIGN.md).

## Boxer

Johan Bos (2008), **Wide-Coverage Semantic Analysis with Boxer**, STEP,
pp. 277–286. [Publisher record](https://aclanthology.org/W08-2222/),
[full paper](https://aclanthology.org/W08-2222.pdf).

Read §§2–3 for the interface: CCG categories constrain semantic types; POS,
word form and morphology select lexical meanings. In particular, `N/N` covers
adjectives, numerals and noun compounds (§3.2, pp.281–282). Figure1's compound
introduces another referent and a relation, not adjective intersection. Event
participants have thematic roles (§2.2). Construction and anaphora/presupposition
resolution are separate (§3.3).

The examples are also counterevidence to a coverage-only criterion: unresolved
pronouns, collective/distributive coordination, measures and shallow lexical
analyses remain (§§3.4–4). Quotes were removed for one text (§4, p.284), which
cannot establish quotation fidelity for this project. The conclusion explicitly
lacks gold representations to quantify meaning quality (§5, p.285).

**Our use:** adopt the separation of category, lexical meaning, composition and
resolution. Adapt event roles only with a declared representation change. Reject
global accommodation as a route to oracle confirmation and reject quote deletion
as an attribution repair. See [Unit2](../../STUDY_PLAN.md#unit-2-ccg-and-ccgbank-weeks-23-the-biggest-gap),
[Unit3](../../STUDY_PLAN.md#unit-3-the-syntaxsemantics-interface-week-4), and
[Unit4](../../STUDY_PLAN.md#unit-4-discourse-representation-theory-week-5).

## ccg2lambda paper

Koji Mineshima, Pascual Martínez-Gómez, Yusuke Miyao and Daisuke Bekki (2015),
**Higher-order logical inference with compositional semantics**, EMNLP,
pp.2055–2061. [Publisher record](https://aclanthology.org/D15-1244/),
[full paper](https://aclanthology.org/D15-1244.pdf).

Read §2 and Figure3 for the key interface change: CCGbank attaches relatives at
`NP\NP`, so NP receives an extra predicate slot for restriction. This avoids
putting a restrictive relative in the scope of a universal. §3 distinguishes
ordinary first-order quantifiers from higher-order operators. Modal and attitude
contexts block actual-world inference. Footnote4 explicitly leaves factive
presupposition projection outside the paper's scope. Evaluation uses selected
FraCaS sections (§4), not a guarantee of unrestricted English fidelity.

**Our use:** adapt the extra restriction slot if we undertake a coherent NP-type
migration; it is not a drop-in relative-word patch. Keep our separate world,
Reported and Presupposed boundaries. Do not import a `know(P) → P` inference as
Asserted admission. Use the paper to derive local gold, not to justify the parser's
current category choice.

## Official implementation, pinned separately from the paper

The official [mynlp/ccg2lambda repository](https://github.com/mynlp/ccg2lambda)
was inspected at commit `a68cb264413791150011c347c64a7b35e2f7270d`.
The English directory contains three relevant files; later event templates are
not identical to the 2015 paper's representation.

| Source at the pin | Role in this audit |
| --- | --- |
| [2015 English templates](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_emnlp2015.yaml) | Two-predicate NP continuation, quantifiers, relatives, coordination and lexical exceptions. |
| [Event templates](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_event.yaml) | Event continuation, passive roles, `PR` particle patterns, feature-sensitive templates. |
| [Flat event templates](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_event_flat.yaml) | A different modal treatment; useful counterexample to copying a whole template collection. |
| [Template documentation](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/README.md#interpreting-and-writing-your-own-semantic-templates) | Category, surface/base, POS, rule and child-attribute matching; last matching rule wins. |
| [Semantic selection implementation](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/scripts/semantic_index.py#L38-L98) | Confirms selection order, lexical base-form application, and unary/binary child application. |
| [Category matching implementation](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/scripts/category.py#L30-L42) | `\|` in a pattern matches either slash direction; feature matching uses subsumption. This is pattern notation, not a third CCG combinator. |

The source files carry Apache2.0 notices. Downloaded reference copies remain in
ignored `research/runs/linguistics-sources/`; no full YAML is vendored here.
Line links refer to the pinned source, not to a mutable branch or PDF extraction
line numbers. This audit reads source and derives counterexamples; it does **not**
report having installed or run either upstream system.
