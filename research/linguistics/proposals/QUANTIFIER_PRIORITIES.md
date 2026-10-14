# Quantifier repair priorities from constructions and sealed evidence

Design audit at `c409f22`; source inspected directly and current behavior read
from the sealed `research/runs/fused-integration/fresh.json` and companion
observations. No new parse, model, answer benchmark, or corpus loading occurred.
These are construction diagnostics, not a population acceptance estimate.
The acceptance-manifest specialist owns denominators and partition enforcement.

## Frequency order: families first, not unmeasured word totals

| Frequency rank among relevant measured families | Inventory evidence | Quantifier work actually needed |
| --- | --- | --- |
| 1 | ProofWriter explicit all family590,281 occurrences /6,319 distinct surfaces | `all` already has universal meaning. Modified restriction ordering and lexical nominal classification are the remaining high-mass seams; changing all's force does not fix them. |
| 2 | Pronto every/each family185,426 /30,878 | Preserve implemented `every/each`; distinguish tag/category failure, unknown nominal complement and lexical noun handling from determiner semantics. Inventory combines the two words, so no each-versus-every rank is justified. |
| 3 | Pronto restrictive-relative universal176,850 /80,550 | `everything that` now has bounded certificate-backed restriction composition. Remaining unknown nominal/coordination inputs still no-parse; no basis to widen categories indiscriminately. |
| 4 | Prover quantified pronoun/relative outer983 /982; quantified-pronoun+who overlapping cue959 | `everyone/anyone` absent from closed table and paired-relative vocabulary. Strict-English person restriction and contextual any-force must be designed before extension. These two counts overlap and cannot be summed. |
| 5 | Prover initial universal nominal418 /418 | `all/every/each` force already supplied; modifier interpretation, head order, noun lemmas, relations and modal scopes can still fail inside this surface family. |
| 6 | FOLIO universal nominal117 /69 and negative-quantifier23 /14 | `all/no` have meanings but noun lemmas, predicate-nominal categories and restrictive attachment still diverge. No is not missing a lexical quantifier term. |

ProofWriter's generic-conditional families1,001,985 and915,052 are larger related
work, but are not frequencies of lexical *all/any/everyone*. Prover's
if-someone/anyone/somebody/anybody cue504 (455 in initial-if) likewise does not
supply an *any* token count or prove uniform universal force. No isolated *any*
frequency is established in these committed inventories. Preserve that unknown;
a word-count invention would give a false implementation order. Counts measure
different benchmark populations and should not become one pooled priority weight.
Within the owner's ProverQA focus, person-relative wrong-but-typed output merits
attention before chasing the much larger other-benchmark occurrence totals.

## Units 2 and 3: existing and proposed meanings

Let `P=e→t`, `Q=P→t`. Determiner category `NP[nb]/N` has type `P→Q`;
N is a property and NP a generalized quantifier. Subject NP combines with a
VP `S[dcl]\NP` of type `Q→t` by backward application.

| Word/construction | Exact scope contract | Current source and next action |
| --- | --- | --- |
| every, each, all + N | `λP R.∀x(P(x)→R(x))` | Implemented exact `NP[nb]/N`, reserved closed class. Preserve. Distributive each here makes no collective claim; all+plural agreement/collectivity requires separate analysis. |
| no + N | `λP R.¬∃x(P(x)∧R(x))` | Implemented, reserved. Preserve fixed negated-existential structural gold; do not switch to universal-negation merely because truth equivalent. |
| some + N | `λP R.∃x(P(x)∧R(x))` | Implemented; relevant contrast to no and scope negation. Noun witness shared with nuclear scope. |
| everyone, strict-English ordinary NP | `λR.∀x(person(x)→R(x))` | Missing closed entry/reservation. General candidate, requiring versioned strict contract and protected lexical admission. |
| everyone who VP, strict-English | `λP R.∀x((person(x)∧P(x))→R(x))` | Missing paired head/certificate vocabulary. Extend the existing certified NP+subject-relative reanalysis with person before relative restriction, not a free NP/N entry or sentence rewrite. |
| everything that VP | `λP R.∀x(P(x)→R(x))` | Implemented paired restriction and unrestricted ordinary NP. Its domain policy differs from lexical everyone/person; do not alias the words. |
| anyone who VP | In a positive free-choice generic, proposed `∀x((person(x)∧P(x))→R(x))` | Context-sensitive. Unlike everyone, unrestricted ordinary anyone is not safely assigned universal force in all clauses. Needs scope/polarity licensing first. |
| any + N | Universal free-choice versus existential under licensing environments | Deferred general entry. No silent alias to every. “Did any cat leave?” and “No person saw any cat” do not contain the same assertion-level universal as “Any cat with this tag qualifies.” |

The certified relative construction starts with actually offered NP and
`(NP\NP)/(S[dcl]\NP)` categories, then jointly reanalyses them into NP/N and
N/(S[dcl]\NP) carrying a restriction obligation. Proposed everyone extension
must update the admitted head meaning and certificate whitelist together,
preserve head/relative adjacency and source identity, and carry the obligation
through packing/combinators until discharged. Broad extra lexical categories
would bypass the attachment evidence. Do not reuse `someone`'s existential head
or let the relative appear after the universal closes.

For each/all/every, category mismatches remain a real concern: closedEntries
requires exact `NP[nb]/N`, not arbitrary NP/N. A category expansion needs observed
lexical evidence and independent compatible/near-neighbor controls. The existing
source's unary-determiner guard lists the/a/an/every/all/someone/something and
omits each/some/no; this static asymmetry warrants a targeted review but is not
itself proof of a measured first failure. Do not add names to that guard before
checking precisely which unary rule and nominal use it protects.

## Unit 4: scope and claim status

For every/each/all, DRS is `[ | [x | N(x)] ⇒ [ | R(x)]]`: Asserted is only the
whole implication; N and R are Embedded. For no, DRS is
`[ | ¬[x | N(x),R(x)]]`: Asserted is the whole negation, with both atoms Embedded.
For strict everyone who is red, antecedent is `[x | person(x),red(x)]`; matrix
scope is in the consequent. `person` is neither a separate top-level assertion
nor an additional witness. Reported/Presupposed remain empty in these isolated
assertions; a containing attitude must retain its own boundary.

Never turn *some cats are not red* into *no cats are red*. The former has a
main-box cat witness and a nested negation; the latter quantifies within the
negative box. Likewise never turn universal-relative restriction into a
universal's consequent just because both versions are type t.

## Concrete first divergences: source plus sealed observations

| Case | Sealed selected behavior | Earliest supported explanation |
| --- | --- | --- |
| `pronto-each-1`, Each yumpus is aggressive | Exact | Existing each lexical repair works here; not evidence for whole family coverage. |
| `pronto-each-2` | No parse | Observation establishes absence of selected derivation. It does **not** identify the failing token without additional lexical/derivation evidence. |
| `pw-universal-explicit-1/2` | Typed implication with restrictions blue,young,person and kind,red,thing | Existing modifier-first template disagrees with independent head-first convention; all's quantification is not the first supported fault. Preserve definite identity while solving this separate interface seam. |
| `folio-no-1/2` | Negated existential with animals/pets and alligators plural predicate names | Quantifier and scope are present; lexical noun normalization first differs from singular gold. Not a no-template gap. |
| `folio-extended-universal-1` | humans(x) implies mortal(x) | Noun lemma mismatch; universal force present. |
| `folio-extended-universal-2` | No parse | Do not infer a lemma repair alone would produce a derivation. |
| `prover-who-restriction-1` | everyone(x),driven(x) implies persistent(x) | Lexical treatment of everyone as an open predicate; closed reservation/meaning and certified restriction admission absent. Strict gold expects person(x), not everyone(x). |
| `prover-who-restriction-2` | No parse | Additional derivational/lexical dependency unresolved; adding person semantics is not yet an observed cure. |
| starter diagnostic `prover-quantified_pronoun_or_relative` | Current meanings are evaluated against explicitly unrestricted everyone gold | Contract incompatibility with strict person everyone is separate from implementation correctness; do not silently count this panel as strict English. |

These observations predate later integration changes and belong to the named
sealed binary/source/gold hashes in fresh.json. They are not current-head Explain
measurements. Selected exact, wrong-but-typed and no-parse retain all cases;
source hypotheses for no-parse rows remain hypotheses. No fresh runs were used
to choose easier targets or redefine acceptance.

## Versioned domains are mandatory before everyone implementation

Historical controlled fixtures intentionally stipulated unrestricted everyone.
New `proverqa-strict-english-v1` relative fixtures explicitly require person;
new controlled-compatible named or-both fixtures exercise neither policy.
An ordinary everyone repair cannot satisfy both incompatible meanings under one
unlabelled parser contract. Keep historical results intact. Build a consistent
versioned strict-English acceptance panel, or declare a controlled-domain parser
mode whose mapping and domain axioms are explicit. Do not accept two incompatible
meanings in one gold array merely to make both outputs pass. The acceptance
manifest must prevent incompatible pooling; this note does not own that logic.

## Boxer/ccg2lambda decisions and next review boundary

[Boxer2008](https://aclanthology.org/W08-2222.pdf) §§3.2–3.3 separates category,
lexical/POS selection and resolution. Adopt this distinction: a correct closed
quantifier does not establish that its noun/relative has a faithful meaning.
Do not infer exactness or oracle authority from wide coverage.

The pinned [ccg2lambda2015 determiner entries](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_emnlp2015.yaml#L213-L265)
explicitly distinguish every/all/each, some and no. Adopt the quantifier force;
adapt their extra NP restriction continuation to our certified restriction
interface. Its no uses a universal-negative form; retain our independently fixed
negated-existential DRS. Reject its context-free universal *any* as a general
English rule, and its existential *the* as a replacement for our current definite
identity contract. Relative entries support keeping restriction separate from
scope, not copying an incompatible semantic type. These are source comparisons,
not upstream runtime measurements.

Immediate candidate after contract review: reserve and give strict everyone a
person-restricted ordinary NP plus certified who-relative head. Require2–3
independent strict examples including negated matrix scope, cross-clause binding
and a blocking unsupported relative. Keep any deferred until explicit
polarity/free-choice licensing and corresponding gold are available. Preserve
implemented each/all/no rather than broadening them to mask noun, modifier or
nominal-predicate failures. Whole-family gate certification remains outside this
bounded design recommendation.
