# Quantifiers and determiners: a reviewed interface, not a word substitution

Proposal against `fe5bf33`, with independently authored gold conventions from
`astra/gold-folio` (`169165e`) and `astra/gold-proverqa` (`43ac355`). The bounded implementation is recorded below; whole-sentence coverage remains
unmeasured on this branch. Historical caches are not current-head measurements.

## Unit 2: categories and derivations

Use `N` for properties and `NP` for generalized quantifiers. Features such as
`NP[nb]` constrain syntactic matching; they do not change the semantic type.
A determiner has CCGbank category `NP[nb]/N`, a common noun `N`, an intersective
attributive adjective `N/N`, an adjective predicate `S[adj]\NP`, and present
copular *is/are* `(S[dcl]\NP)/(S[adj]\NP)` in the adjective construction.

For **Some red cats are quiet**, the intended derivation is:

1. `red:N/N + cats:N → N` by forward application.
2. `some:NP[nb]/N + red cats:N → NP[nb]` by forward application.
3. `are:(S[dcl]\NP)/(S[adj]\NP) + quiet:S[adj]\NP → S[dcl]\NP` by forward application.
4. `some red cats:NP + are quiet:S[dcl]\NP → S[dcl]` by backward application.

Replacing *some* with *every*, *each*, or *no* changes the closed lexical meaning,
not the derivation. The determiner entries must also be reserved closed-class
words: an incompatible offered tag must not produce `some(x)` or `no(x)` via an
open-class fallback. Derivation acceptance requires both an offered/licensed
category and its meaning; adding a meaning does not establish tagger coverage.

**Some birds are hawks** needs predicative nominal classification as well. A
proposed bounded construction gives plural `N` predicate *hawks* the property
`hawk`, and copular classification category `(S[dcl]\NP)/N` with meaning
`λP.λQ.Q(P)`. This is a declared reanalysis, not an assertion that CCGbank always
assigns that category. A full standard `(S[dcl]\NP)/NP` copula must distinguish
predicative from referential NP meanings. Do not apply existential NP identity
indiscriminately, or turn object **has a degree** into classification. The nouns
specialist/reviewer must approve this seam before corpus fidelity is claimed.

## Unit 3: Montague types and closed meanings

Write `P=e→t`, `Q=P→t`. Then `N:P`, `NP:Q`, `VP:Q→t`, determiner `P→Q`.
This display is the extensional fragment of the project's intensional system;
none of these terms erases attitude/world barriers.

| Expression | Meaning | Scope obligation |
| --- | --- | --- |
| every, all, distributive each | `λP.λR.∀x(P(x)→R(x))` | No existential import; each here excludes collective readings. |
| a, an, some | `λP.λR.∃x(P(x)∧R(x))` | One witness shared by restriction and scope. |
| no | `λP.λR.¬∃x(P(x)∧R(x))` | Binder stays inside negation. |
| red, as intersective N/N | `λP.λx.(P(x)∧red(x))` | Noun-head condition precedes modifier in structural gold. |
| quiet, as adjective VP | `λQ.Q(λx.quiet(x))` | Apply subject exactly once. |
| not, as VP modifier | `λV.λQ.Q(λx.¬V(λP.P(x)))` | Subject-wide reading: some cats are not quiet has an outer witness. |
| the | Existing iota description, pending definite-resolution design | Do not replace by existential merely to pass examples. |

For *Some red cats are quiet*, beta reduction yields
`∃x((cat(x)∧red(x))∧quiet(x))`. For *No red cats are quiet*, the entire
existential is negated. For *Some cats are not quiet*, only `quiet(x)` is
negated. These contrasts test semantics even when all outputs are well typed.

Head-before-modifier is a serialization convention for an intersective fragment,
not a claim that conjunction is noncommutative in FOL. Canonical DRS preserves
condition order, so establish one independently selected convention across gold
and templates. Do not modify gold to accept current wrong syntax. Numerals,
compounds, *former*, *alleged*, and *fake* do not become intersective adjectives
merely because a tag is `N/N`; lexical licensing is a separate pending obligation.

Quantificational pronouns require a separate restriction decision. *Someone* and
*every person* restrict to `person(x)`; *some cat* restricts to `cat(x)`. A literal
*some thing* may restrict to `thing(x)`, while unrestricted logical *something*
and *everything* quantify over the domain without an extra lexical sortal.
The existing snapshot uses `thing` for *something*; do not silently copy that
choice into independent gold. Explicitly attribute a benchmark's sortal/domain
convention and contrast `∃x.R(x)` with `∃x(thing(x)∧R(x))`. They are equivalent
only under an explicit domain axiom. Determiner repair does not settle this seam.

Bare plurals need a declared generic/episodic policy. Existing `N→NP` is a logged
generic universal, not the semantic definition of every English bare NP. Keep
this decision separate from adding *some/no/each*. Likewise *any*, *most*, *few*,
*exactly two*, and partitive *some of* need independent scope/cardinality designs;
never add these as aliases to repair coverage. *At least one* may use an
existential only as a licensed quantified-NP construction, not a global rewrite
of *at least* (contrast *at least once a day*).

## Unit 4: DRS and claim boundaries

For restriction `cat(x)` and scope `quiet(x)`, the expected forms are:

| Construction | DRS | Asserted | Embedded |
| --- | --- | --- | --- |
| Some cats are quiet | `[x | cat(x), quiet(x)]` | `cat(x)`, `quiet(x)` in their binder context | none |
| Every cat is quiet | `[ | [x | cat(x)] ⇒ [ | quiet(x)]]` | whole implication | both atoms |
| No cats are quiet | `[ | ¬[x | cat(x), quiet(x)]]` | whole negation | both atoms |
| Some cats are not quiet | `[x | cat(x), ¬[ | quiet(x)]]` | `cat(x)` and whole negation | `quiet(x)` |

Reported and Presupposed are empty for these isolated declaratives. The absence
of those statuses is not permission to promote a sentence inside a report or
factive complement: nesting must preserve the enclosing claim boundary.
Contextual existential atoms are Asserted but are not closed oracle facts;
`freeCanonRefs` still prevents confirmation without their binder context.
Although `no P R` is FOL-equivalent to `∀x(P(x)→¬R(x))`, fidelity exactness uses
the negated-existential convention fixed before implementation. Preserve this
agreement with FOLIO gold, including both predicates as Embedded.

## Explain evidence and first divergence

On this branch snapshot, `closedTable` has every/all and a/an, but not some/no/each;
`closedClassWords` omits those three. Thus their first demonstrated divergence
is lexical semantics at Unit 3: no determiner term exists and spurious open
analyses remain possible. The earlier FOLIO121 audit in `research/SEAMS.md`
records *Some affection is love* becoming a universal restricted by
`some(x)∧affection(x)`. This is a historical observation, not a fresh Explain run.
`openTemplate N/N` additionally emits modifier before noun; this is structurally
different from the independently selected gold convention, even where truth
conditions agree. New Explain runs must distinguish the lexical failure from
later nominal-copula, lemmatization, supertag-ranking, or scope failures.

The standalone `test/QuantifierProposalSpec.hs` directly checks seven obligations:
reservation of three words, their normal forms, and noun-first intersection.
Prediction recorded before execution: all seven fail at this snapshot.
Observed on 2026-10-14: seven FAILs, expected red result, no corpus load. This is
an acceptance proposal, deliberately not wired into the current release suite.

Gold anchors are FOLIO `folio-some-2/3`, `folio-some-not-1/2`, `folio-no-1/2`, and
`folio-atleast-one-1/2`; ProverQA `subject_have` controls protect object witnesses.
Existing Pronto gold exercises universal/generic restrictions. Passing the
lexical seven is necessary but insufficient: rerun the entire independent set
and inspect retained wrong readings before acceptance. Score selected-reading
exact / wrong-but-typed / no-parse, and report any-reading exact separately.
Do not count an unimplemented cardinality construction out of the denominator.

## Boxer and ccg2lambda: adopt, adapt, reject

[Boxer 2008](https://aclanthology.org/W08-2222.pdf), §§3.2–3.3, separates lexical
selection using category/POS/morphology from composition and resolution. **Adopt**
that separation: category alone does not identify an intersective modifier, and
a definite's resolution should not be confused with ordinary quantification.
**Adapt** its DRT box discipline to our explicit claim-status partition; Boxer
2008 is not evidence for our oracle-admission guarantees. **Reject** inferring
meaning fidelity from wide parsing coverage. The paper's conclusion explicitly
lacks gold meaning representations for quantitative semantic evaluation.

The pinned [2015 ccg2lambda determiner entries](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_emnlp2015.yaml#L213-L265)
have explicit existential some/a/an and universal every/all/each; **adopt** those
truth-conditional distinctions. Their NPs have an extra restriction continuation,
so **adapt**, do not paste, the lambda terms into our `Q=(e→t)→t` interface.
Their *no* is universal negative; our negated-existential convention is logically
equivalent for this fragment but deliberately differs structurally. **Reject**
the unqualified existential *the*, universal *any*, and *few* treated like *no*
as general English defaults. Those entries cannot serve as independent gold.
The restricted comparison reads published source; it does not claim an upstream
runtime evaluation. Full source map is [REFERENCES.md](../REFERENCES.md).

## Integration order and reviewer checklist

Use the four inventory sections to rank implementation work; no frequency number
is invented here. Reserve/add some/no/each and normalize intersection only after
review of the independent gold representation. Quantifier terms are small, but
nominal classification and lemma licensing must be checked before declaring the
sentence construction repaired. Protect every/all/a/an/the, object existentials,
negated existentials, relative restriction, and claim nesting. Any change to
`N/N` licensing needs its own contrastive tests. If another branch owns
`CCGSem.hs`, the coordinator integrates this proposal rather than parallel edits.

## Final bounded implementation after independent review

Implemented exact `NP[nb]/N` some/no/each meanings with closed-word reservation.
No category injection, nominal copula change, or broader modifier licensing was
added. `test/QuantifierProposalSpec.hs` has 24 passing semantic checks, including
scope contrasts, established determiners and incompatible-tag rejections.
Full independent fidelity and release gates remain required on integration.

### Deferred modifier ordering: preserve definite identity

An interim head-first modifier change exposed a genuine identity regression:
*the bald eagle* denoted `eagle bald`. `describeIota` intentionally derives a
rigid unique name from ordered predicate content; it has no retained syntactic
head or POS information from which to reconstruct the old descriptive name.
The coordinator and reviewer therefore withdrew **all modifier-order production
changes**. Some/no/each remain implemented. The final direct quantifier suite
has 24 green checks; the single-modifier order check was moved, not discarded,
into `test/QuantifierModifierOrderKnownFailure.hs` alongside a multi-modifier
case. Current output is `red,cat` and `blue,young,cat`, against independently
expected `cat,red` and `cat,blue,young`. This diagnostic remains outside cabal
and exits1 with both known failures. All original bald-eagle identity tests
remain unchanged. A future modifier repair must preserve identity/provenance
and meet gold ordering together; this branch does not claim modifier fidelity.
The seven-failure report above is historical pre-repair evidence.
