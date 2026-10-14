# Name ambiguity and title segmentation: bounded proposal

2026-10-14. Worktree astra/name-ambiguity; full access verified with pwd. Own files
are this note and test/NameAmbiguityProposalSpec.hs only. No source/gold changes,
parser calls, corpus loads or model/answer-benchmark runs. The test calls lexical
assignment, type checking and sentence splitting on tiny hand-authored inputs;
it does not call semParse/runPipeline.

Prediction before executing: all12 evidence controls pass, while ten proposed
alternative-preservation/title-split controls expose existing unsupported behavior.
These are intentional red proposal controls, not a registered release gate.
Commands: `runghc -isrc -itest test/NameAmbiguityProposalSpec.hs --evidence` and
`runghc -isrc -itest test/NameAmbiguityProposalSpec.hs --proposed`.

Result: evidence12/12 pass; proposed0/10, all expected failures. No corpus/parser
was invoked. These tests are explicitly separate from existing NameSemSpec and
must not be represented as a passing implementation or an approved policy change.

## Sealed first divergences

Sources: root research/runs/reflexive-integration/fresh.observations.jsonl,
nominal-integration/fresh.observations.jsonl (rejected candidate), and
gold-extension-baseline/fresh.observations.jsonl. Historical Legend evidence is
in research/linguistics/NAMES.md. No case expectation was reconstructed from these
outputs; the outputs are only evidence of where the existing meanings diverge.

| Input | Observation | First supported divergence |
|---|---|---|
| Dean does not work. | Accepted baseline selects `∀x(dean(x)→¬work(x))` | Initial lexical/truecasing policy and bare-N generic lifting; intended named person is lost before negation |
| Legend is red. | Earlier cached diagnostic selected `∀x(legend(x)→red(x))`; a noninitial Legend occurrence had rigid meaning | Initial lexical policy, not the accepted direct-NP name meaning repair |
| Legend is either a champion or fast. | Current sealed baseline has no parse | Do not label this observed row wrong-but-typed just because the simpler earlier name control was wrong |
| Gorpuses are lorpuses and wumpuses. | Rigid Gorpuses wins; generic alternative also returned | Unseen initial capital receives a name alternative; statistical selection chooses it without identity evidence |
| Some players are not American. | Rejected nominal candidate selects `∃x(players(x)∧¬(x=American))` | Majority NNP supplies rigid American, followed by newly licensed equative complement |
| Yuri is tall or American. | Rejected candidate selects adjective-as-generic equation OR Yuri=American | Independent bare-N equative leak plus demonym/reference ambiguity; accepted baseline is no-parse |

Switching Gorpuses to its existing generic alternative would not establish exact
fidelity: plural-to-singular predicate lemmas are a separate contract. Likewise,
adding a rigid Dean or Legend alternative does not prove it is selected correctly.
The sealed traces do not expose the complete corpus dictionary's competing POS
counts/categories. Synthetic tests demonstrate what a policy would do **if**
that evidence exists, not that exact-case NNP or adjective tags were observed for
every production example.

## Separate three questions

1. **Meaning availability:** independently licensed name plus offered N, NP or
   NP[nb] must receive the accepted rigid Q meaning. Preserve this repair, scores,
   ordinary features and forbidden expletive/dummy/conjunction NP handling.
2. **Evidence collection:** gather lexical evidence without discarding the
   competing ordinary use merely because a different POS is more frequent.
   At sentence start, inspect both the exact written form and independently
   attested lower-case form; typography is not identity evidence. Retain their
   distinct provenance. A lower-case common noun must not erase an independently
   attested proper-name candidate, and NNP majority must not erase an independently
   attested adjective category. Do not invent noun/adjective alternatives from
   smoothing priors and then call them dictionary evidence.
3. **Admission/selection:** a complete grammatical reading needs a supported
   interpretation of the NP, not just a type-correct name term. Scores rank
   readings but cannot certify which entity or property the writer intended.
   Retaining alternatives alone is not a fidelity repair if a wrong selected
   reading still enters the claim graph.

The proposed red tests concern question2 and title segmentation; they do not
claim to implement question3. The source's compact NameStatus enum currently
mixes evidence with a pruning decision. A future change needs an explicit contract
for actual alternatives and reasons; do not silently weaken trace truthfulness.

## General grammatical evidence, and its limits

An overt ordinary determiner with a common-role noun licenses a descriptive NP;
`the dean` is not automatically the person named Dean. A rigid name is licensed
by a name use, not by any token ending in a capital letter. Bare singular count
nouns normally cannot use the current generic N→NP rule indiscriminately, but
POS NN alone does not distinguish count nouns from mass nouns or contextually
referential titles. A safe rule requires independently justified countability
and construction evidence; a hard-coded Dean exception is not a rule.

Plural inflection and agreement provide useful constraints, not an automatic
universal quantifier. Unknown Gorpuses before `are` is compatible with a plural
common noun, but plural names/families/groups also exist. Roberts must not lose
its independently licensed NNPS name meaning because it ends in s. CCG NP[nb]
means non-bare, not plural. The current copula categories do not encode enough
number/animacy/countability to use agreement as a proof. Generic versus episodic
bare-plural quantification is another independent semantic choice.

Demonyms can function as adjectives, nominal properties, or names. A corpus NNP
majority for American does not decide a particular predicative use. Permit an
independently supported adjective category to compete in adjectival context;
do not enable arbitrary equative NP fallback merely to gain parses. The rejected
nominal candidate remains rejected. If actual adjective evidence is absent,
this proposal does not fabricate a demonym lexicon from benchmark expectations.

Noninitial capitalization is stronger contextual evidence than initial typography,
but not proof of unique rigid identity. The proposed move from forced NameOnly
to explicit uncertainty for unseen noninitial capitals would intentionally change
an existing heuristic. It needs its own source review and broad unchanged-gold
measurement; these red tests do not authorize it. General lexicalized title
phrases and independently introduced named referents may supply stronger evidence,
but cannot borrow the desired gold or an answer label.

## Principled failure when evidence remains insufficient

If independently supported **complete** readings disagree on rigid individual
versus generic quantifier, and the grammatical/contextual evidence does not
resolve that conflict, withhold automatic factual admission for the unresolved
meaning. Do not convert the alternatives into a conjunction, silently choose the
highest score, or erase the ambiguity from the trace. Conversely, an unused
lexical candidate that cannot participate in any grammatical complete reading
is not itself a competing proposition.

A bounded beam may fail to return a competing reading; absence from the beam is
not evidence that lexical uncertainty disappeared. The chosen reading's actual
unresolved name evidence must remain visible. Cross-sentence evidence can help
only if it comes from an independently analyzed occurrence, retains its source
and uncertainty, and does not promote referents/properties out of negation,
conditionals or reports. No circular self-reinforcing name inference is permitted.

This fail-closed proposal needs an explicit admission/result contract. A parsed,
well-typed but rejected ambiguous meaning is not a syntactic no-parse. The current
fidelity schema has no dedicated semantic-abstention outcome; do not improve
numbers by relabeling it. Preserve all cases in the denominator and either
report rejection separately with unchanged protocol semantics or review a schema
extension as its own change. No scorer or admission change is made here.

This can lose genuine named-person coverage, especially on unseen names. It is
not a way to claim the ProverQA90% gate or a complete name recognizer. Some
isolated expressions are underdetermined by English alone; document that limit
and seek independently available context rather than invent certainty.

## Units2/3/4 and upstream comparison

**Unit2:** keep category evidence distinct from identity evidence. Complete NP
syntax allows a name generalized quantifier, but cannot decide whether that NP
is a name, descriptive definite, or bare generic. Preserve licensed N→NP *name*
lifting separately from common-N generic type change. Multiword/title analysis
also requires a segmentation decision before categories can compose.

**Unit3:** rigid `λP.P(Dean)` and generic `λP.∀x(dean(x)→P(x))` share type Q.
Applying either to the negative work VP produces type t, with different truth
conditions. Type safety is necessary and insufficient. Similarly, adjective
`λN.N(λx.american(x))` and name `λP.P(American)` are distinct lexical meanings
whose differing categories must remain available when independently supported.

**Unit4:** named negative work has `[ | ¬[ | work(Dean)]]`: A the negation,
E the work atom. Generic negative work has a universally restricted implication;
its whole implication is A, with inner negative/property conditions embedded.
Neither interpretation is oracle-confirmed simply because lexical selection
chose it. The proposed ambiguity failure is upstream of factual admission, not
an excuse to weaken the Asserted/Embedded boundary.

Bos2008 §3.2 supports lexical/POS-sensitive semantic selection distinct from
category/type; §3.3 distinguishes construction from reference resolution. Adopt
that separation, not a claim that its POS analysis uniquely resolves homographs.
The pinned ccg2lambda2015 NNP rules likewise motivate evidence-sensitive names,
but do not certify the policy “majority NNP means NameOnly” or unseen capital
certainty. Its two-continuation/equality-witness representation remains distinct
from our rigid constant. See [REFERENCES](../linguistics/REFERENCES.md) and
[the pinned NNP rule](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_emnlp2015.yaml#L37-L46).
Neither upstream system was executed.

## Independent earlier boundary: abbreviation segmentation

The newly approved two titled-name controls have a confirmed **earlier** failure:
`splitSentences` breaks on every '.', '!' or '?' without an abbreviation rule.

- `Dr. Yareli Hernandez is empathetic.` becomes two sentences, `Dr.` at0:3 and
  the suffix at4:35. Neither parses in the sealed observation: sentence_count2,
  parsed_sentences0, hence no-parse.
- `Dr. Marlon is not analytical.` becomes `Dr.` at0:3 and the suffix at4:29.
  One suffix parses as `¬analytical(Marlon)` with a generic alternative. The
  document is incomplete, not an exact titled-name success.

A small independently reviewed honorific-abbreviation boundary rule is useful
without solving Dean/Legend. It must handle the lexical class (Dr., Mr., Mrs.,
Ms., Prof., where licensed), preserve document-global offsets and ordinary later
sentence boundaries, and avoid a benchmark-person whitelist. It must also state
what happens when an abbreviation is itself terminal or followed by ambiguous
capitalized material; unconditional suppression after every short capital token
would be another unsound guess. Uncertain abbreviation boundaries may require
alternative segmentation, not a forced merge.

The existing casedTokens still emits Dr and '.' separately even if sentence
splitting is corrected. Preserving a sentence boundary does not itself identify
the full multiword NP or retain `Dr. Marlon` as the gold's rigid key. A title-span
lexer/name construction needs its own evidence and tests. Do not claim the two
gold rows fixed merely because sentence_count becomes1 or the suffix parses.

The five proposed segmentation checks isolate this first boundary without
running a parser: two exact gold texts, an invented Prof. name, a following
ordinary sentence, and exact spans. Existing ordinary-boundary and isolated-Dr
controls stay green. Before implementation add terminal/quotation/initialism/
decimal neighbors as appropriate to the specific abbreviation rule; do not
advertise general sentence segmentation from this small title fragment.

## Recommendation

Pursue the general abbreviation boundary repair as a separate bounded change
with downstream title fidelity still explicitly open. Preserve the accepted
name-meaning repair. For semantic name ambiguity, first review evidence-preserving
lexical alternatives and an explicit admission contract; do not ship a POS/case
score tweak as a solved recognizer. The ten red controls are proposals, while
the12 green controls document the invariants to preserve. No production behavior
or gold has been changed by this branch.
