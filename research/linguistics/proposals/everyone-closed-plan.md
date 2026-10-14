# Everyone: strict-person lexical entry and bounded source-category repair

Design only, based ond6e9182; no shared source changes. Units2/3/4 respectively:
source category licensing, generalized-quantifier meaning, and scoped DRS claims.

## Observed/static gap and semantic target

Accepted expanded167 Explain displays Everyone:N in both new strict-person cases.
One stops later at but, the other at semantic composition; it does not establish
all offered categories or a successful Everyone meaning. Static source is decisive:
CCGSem.closedClassWords and closedTable omit everyone. An offered N may therefore
use the open predicate everyone(x), then generic N→NP lifting; it is not a correct
strict-English lexical pronoun. Existing someone/everything are reserved, and
restrictedPronounEntries handles only those two. This plan fixes no but/both,
exclusive ellipsis, predicative-nominal or arbitrary relative attachment problem.

Proposed standalone `everyone:NP` has Q=(e→t)→t and meaning
`λP.∀x.(person(x) → P(x))`, with no existential import and no everyone predicate.
`Everyone is tall`: backward application of NP to finite copular VP gives
`∀x.(person(x) → tall(x))`. DRS: one asserted implication, antecedent introduces x
with person(x), consequent tall(x); both atoms Embedded, no Reported/Presupposed.
`Everyone is not quiet` has NOT inside the consequent, never ¬∀person.quiet.
The negative fixture explicitly selects surface forall-not scope; ordinary
English can pragmatically convey not-all. This is not a claim that all ambiguity
is absent. A domain with no persons satisfies these universals; do not add a witness at root.

Restricted `Everyone who is tall is quiet` requires
`∀x.((person(x) ∧ tall(x)) → quiet(x))`, not
`∀x.person(x)→(tall(x)∧quiet(x))`. In the existing paired construction, internal
head NP/N = `λR.λP.∀x.((person(x)∧R(x))→P(x))`; relative N/VP abstracts the same
subject as the accepted fused design. Original who category is
`(NP\NP)/(S[dcl]\NP)`. Relative VP first applies to that internal operator to
produce a certified property; its matching head consumes only that property.
DRS antecedent order person then relative property, including negative restriction
boxes; consequent remains outside the relative restriction. No arbitrary NP
meaning is inverted into a restriction. Empty person+restriction domain is vacuous.

Input-only weighted cache audit: everyone281 occurrences, contiguous everyone who202.
These overlap and are not guaranteed construction counts. This is a bounded281-cue
lexical prerequisite, not a claim to solve the4146 not-both family.

## Minimal first source step, separate from offered-N repair

1. Reserve case-folded everyone; add exactly ordinary NP closed entry with the
strict-person term. No generic N lexical predicate or NP[conj]/expletive entries.
2. Extend restrictedPronounEntries everyone with the restricted person-universal
term. Extend existing validCertificate word allowlist only for everyone with
ordinary offered NP and original subject-relative category. Existing span/source,
occurrence-equality, lexical-leaf, source-rule, type and discharge gates unchanged.
3. Keep all previous something/everything/people/things entries byte-for-byte
semantically unchanged. In particular literal people:N stays person property;
things:N stays thing property; something keeps its current thing restriction;
everything keeps its current unrestricted policy. Do not run global sortal erasure
or rename every word ending in -one. The strict English person predicate is real
meaning even if a downstream benchmark conversion intentionally drops sortals.

This first step can turn wrongly typed offered-N derivations into no-parse because
the reserved word can no longer use openTemplate. That is a fidelity improvement,
not coverage progress. Do not weaken reservation to retain everyone(x). It need not
make the observed N-tag cases exact; report the distinction before an experiment.

## Offered N→NP: occurrence-specific lexical reanalysis, separate review

Do not add everyone:N with property person or everyone and rely on generic N→NP:
that can introduce an existential or wrong universal restriction and makes the
actual source-category repair invisible. Do not globally change N/NP lifting.

Proposed `PersonPronounOrigin` stores source, token index/span, original surface,
original offered category, target category and declared closed-entry identity.
Mint only for casefold everyone, actual offered **bare N with no features**,
nonempty original token span, and selected strict-person entry target ordinary NP.
There is no POS guess, unknown-word fallback or string-in-term trigger. Lexical
N inventory evidence is sufficient only for this explicitly reserved word, not
for someone/everything/people/things/names/other nouns. No ordinary N reading is
retained. Original category and log-score remain recorded in a decision; the
source token is still Everyone, never silently rewritten to people.

Standalone reanalysis yields the same closed NP meaning and follows ordinary NP
combination/seen-rule constraints. No blanket unseen-pair exception. If target NP
combinations are rejected by the existing seen rules, retain no-parse and inspect
before proposing a narrowly proved source-rule mapping. No hidden fallback to
source N generic quantification. A small stable lexical-origin field or explicit
lexical construction wrapper can carry the occurrence certificate; avoid a global
NP-type migration or new independent chart flags unless needed for pair identity.

For fused Everyone[N] who/that/which, extend the existing FusedCertificate rather
than minting a separate free property. Accept source head N ONLY when the validated
PersonPronounOrigin matches the same token; store original N, not invented NP, in
fcHeadCategory. validCertificate must distinguish existing NP heads from the new
Everyone-only N path; `N + anything` is not generally permitted. Paired source
relative remains exact `(NP\NP)/(S[dcl]\NP)` at immediately next token. Keep
head and relative indices/spans, all actual-source constraints, original selected
entries and paired identity. Update category overapproximation and sourcePair
checks coherently so they do not silently replace original N with NP evidence.
Initially require the actual original source pairs to satisfy existing rules;
any broader mapping is a separately reviewed change, not implicit in this plan.

**Mandatory negative controls:** forged NP/N lexical head without offered N/NP;
Everyone N[feature] or NP[conj]/expletive; other word with the same source N;
nonadjacent/foreign-source/copied occurrence certificate; orphan who property;
head applied to ordinary noun; wrong original relative category; unary/composition
laundering; arbitrary people:N becoming closed universal; people/things losing
sortals. Existing fused adversarial checks remain required after extension.

## Independent gold and compatibility boundary

New everyone-closed-controls.jsonl contains6 authored strict-English controls,
3 standalone (including VP negation) and3 subject-relative (including negative
restriction), with hand DRS and independent claim arrays. No input-population
frequency or benchmark origin is claimed. They are gold before any parser
observation; no candidate parser was launched. Existing source-derived who gold
and strict-person connective gold remain independent integration controls.

Historical `prover-quantified_pronoun_or_relative-1/2` specify empty restrictions;
those rows and their contracts must remain unchanged. A strict-person output can
therefore remain wrong under that legacy diagnostic while satisfying new gold.
Report separate old-unrestricted versus strict-person panels and selected-object
diffs; do not pool the panels or weaken gold to make a total improve. The legacy
rows already have wrong everyone predicates in the sealed cache, but no regression
claim is inferred without fresh comparison. Current representative90% gate stays
closed; six authored controls are not population acceptance evidence.

## Comparison and implementation gate

Bos2008 locally audited REFERENCES §§2–3 separates category-conditioned lexical
semantics from construction and anaphora resolution. Adopt this separation; do
not use generic noun semantics to invent a quantifier. No Boxer-specific everyone
implementation was inspected or claimed. [Source](https://aclanthology.org/W08-2222/).

Pinned2015 ccg2lambda YAML lines192–194 explicitly makes everyone universal with
_people(x) restriction and two NP predicate slots; locally reinspected at
research/runs/linguistics-sources/ccg2lambda/en/semantic_templates_en_emnlp2015.yaml,
commit a68cb264413791150011c347c64a7b35e2f7270d. Adopt strict-person restriction;
adapt its two-slot relative architecture only via our existing certified pair,
not by copying a different NP type into this parser. Our atom is person, and
Reported/Presupposed distinctions remain ours.
[Template](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_emnlp2015.yaml#L192-L194).

Review standalone NP and NP-head fused step first, then N-origin contract before
implementation. Pure lexical red controls and gold schema checks are prerequisites,
not successful parser runs. After authorized source: all retained miniature
readings for offered NP/N variants, fused forged-certificate tests, all suites,
root fresh gold with panel-separated predictions, and independent reviewer verdict.

## Bounded candidate status

The approved first source step is implemented in this branch only: strict-person
NP entry/reservation, person-universal restricted head, and existing NP-only fused
allowlist extension. No offered-N reanalysis/source-pair bypass. Eighteen focused
lexical/public-miniature checks pass, including every retained and selected DRS
plus claims for6authored golds;89existing fused controls pass. A missing DRS or
alternative ¬∀ reading fails these scoped controls. Root full gates/fresh panels
and final review still govern integration; later N repair remains design only.
