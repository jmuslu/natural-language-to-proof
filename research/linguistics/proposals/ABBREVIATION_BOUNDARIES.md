# Sentence and token boundaries before name interpretation

Status: design and independent red controls only. No production change or
coverage gain is claimed. The name ambiguity proposal remains separate: fixing
a boundary does not determine whether an expression denotes a person.

## Observed first divergence

The sealed `research/runs/gold-extension-baseline/fresh.observations.jsonl`
on the coordinator worktree records these approved gold sentences:

| Gold | First boundary result | Consequence |
| --- | --- | --- |
| `Dr. Yareli Hernandez is empathetic.` | `Dr.` at 0:3; remainder at 4:35 | Both units fail; no full-name reading |
| `Dr. Marlon is not analytical.` | `Dr.` at 0:3; remainder at 4:29 | First unit fails; suffix can produce `~analytical(Marlon)`; document is incomplete |

The suffix result is not a correct interpretation of the complete referring
expression. These observations locate the failure; they did not generate the
gold meanings. The independent title gold (`69688d8`) specifies the full written
rigid labels, no additional doctor predicate and no short-name alias claim.

`splitSentences` in `src/NL2Proof/Syntax/Tokenize.hs` currently splits at every
`.`, `!`, or `?`. This precedes CCG search. `casedTokens` separately emits each
period as punctuation. Changing only either function leaves the other boundary
decision unresolved. A third, independent defect is that trimming trailing
space changes sentence text without reducing its span end.

## Proposed contract

Maintain four distinct decisions: sentence extent, lexical token extent, CCG
category selection, and semantic admission. Preserve source spelling and
document-global half-open spans at every stage. A token must correspond to its
source slice; punctuation must neither disappear nor be duplicated to simulate
two roles. A final initialism period can belong to its token and also mark the
sentence end; this is a boundary annotation, not a second source character.

The smallest independently reviewable repairs are exact whitespace-trim spans,
recognition of internal digit-dot-digit punctuation, and contiguous `?!`
terminator grouping. The numeric rule identifies a written unit, not a number's
semantic type: decimals and version strings can share that surface pattern.
It must leave the terminal period in `3.14.` available as punctuation. Ellipses
and punctuation inside quotations are outside the terminator-grouping claim.

A finite language-level honorific inventory (`Dr.`, `Mr.`, `Mrs.`, `Ms.`,
`Prof.`) would be a general lexical policy, not a list of benchmark people.
It can support the examples below without enumerating their names. However,
an abbreviation followed by a capitalized token is not universal evidence of
continuation. Sentence-final abbreviations, metalinguistic mentions, headings,
and fragments make that rule unsafe as an unrestricted policy. A reviewed
honorific-plus-referring-expression derivation may retain the internal period;
a raw next-capital heuristic alone cannot establish that derivation. A future
implementation must either state a restricted input convention or retain the
uncertainty for admission. Do not silently certify the convention from these
finite fixtures.

Initialisms require an additional distinction. Internal stops in `U.S.` are
not separate sentences, but its final stop may be terminal. `The U.S. Navy
works.` and `Ada lives in the U.S. Bob works.` refute respectively “split before
every following capital” and “suppress every initialism period.” The present
single-list `splitSentences` interface cannot express competing segmentations.
An ambiguity-aware extension is an open design choice, not part of this patch.

Closing punctuation should stay with the preceding unit in the unambiguous
fixtures `"Ada is kind." Bob is red.` and `(Ada is kind.) Bob is red.`.
This is not permission to split every quotation at its internal stop:
`"Stop!" Ada said.` has an attribution suffix, and `Ada said "Stop!".` has
an outer terminator. Quote scope and attribution need their own contract.
Removing the quote marks to obtain a parsable assertion would be unsound.

## Units 2, 3, and 4

**Unit 2:** the intended full titled name is one referring constituent `NP`,
potentially constructed from multiple lexical tokens. A tokenizer need not
collapse the entire name to one token. Preserving `Dr.` as a lexical unit is
one proposed interface; the title-plus-name combination still needs a licensed
CCG derivation. No new category for every person's spelling is proposed.
Existing proper-name `N`/`NP` repair must retain its separate evidence and tests.

**Unit 3:** with `Q=(e→t)→t`, the title gold's convention is
`λP.P("Dr. Marlon")`; the negative sentence means
`¬analytical("Dr. Marlon")`. The positive example means
`empathetic("Dr. Yareli Hernandez")`. These are intended meanings, not
claims that a new CCG derivation has been measured. A title is part of the
referring label under this gold convention, not an asserted professional
credential and not a license to equate differently written labels.

**Unit 4:** the negative example is `[ | ¬[ | analytical("Dr. Marlon")]]`:
the NOT condition is Asserted and its atom is Embedded. The positive example
has one Asserted atom. Neither yields an additional `doctor` or alias claim.
Quoted speech must preserve the relevant attribution/embedding status; merely
recovering a type-`t` suffix cannot justify promoting it to an assertion.

Relative to the Boxer 2008 and ccg2lambda comparisons in `DESIGN.md`, this is
an upstream contract: neither category-driven semantic composition nor a
well-typed template can restore a title already isolated into another input
sentence. Boxer-style DRS scope motivates retaining negative and reported
contexts; ccg2lambda-style category/semantic templates motivate testing the
actual full NP derivation after segmentation. This is an architectural
comparison, not a claim about either external system's tokenizer behavior;
neither external system was run for this proposal.

## Independent controls and current results

`test/AbbreviationBoundaryProposalSpec.hs` calls only existing sentence/token
functions. No CCGbank load or parser output is used as an oracle. The 31
fixtures cover independent strings and explicitly chosen intended readings.

| Mode | Current result | Interpretation |
| --- | --- | --- |
| `--invariants` | 10/10 pass | Existing sentence punctuation, apostrophes, hyphens, ordinary spans, fragments |
| `--bounded` | 0/15 pass | Desired title/decimal/closing punctuation/terminator/span controls; all known red |
| `--deferred` | 0/6 pass | Initialism final stops and reporting-quote context; all known red |

“Bounded” names the finite fixture group, not approval of a universal heuristic.
Its title/quote cases need the contextual qualifications above. Default test
execution intentionally includes reds and is not registered as a green release
suite. The intended readings do not prove unique segmentation for all possible
texts. Isolated `Dr.` remains a fragment; the test does not authorize a name
reading for it.

## Recommendation and integration conditions

Review local span/numeric/terminator repairs separately from honorific and
quotation interpretation. Do not combine name disambiguation or nominal copula
activation with a boundary change. For honorifics, settle the restricted-input
or ambiguity contract before implementing automatic suppression. Initialisms
and quoted attribution remain deferred rather than covered by a broad regex.

After any approved implementation, rerun these preservation controls, add
counterexamples to its exact chosen policy, and rerun the independent full
fidelity set and Explain gates. Inspect whole-document completeness, full
constant identity, provenance spans, and claim statuses for both title gold
rows. Boundary success alone must not count as exact fidelity or as a reopened
model/benchmark gate. No such post-change results exist in this proposal.
