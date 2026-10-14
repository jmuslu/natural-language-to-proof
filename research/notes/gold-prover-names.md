# Independent ProverQA titled-name gold

2026-10-14. Worktree astra/gold-prover-names; full-access shell verified by `pwd`.
Owned files: test/fidelity/proverqa-names.jsonl and this note. Read the fidelity
schema and FIDELITY_COVERAGE multiword/titled-name gap. No parser observations,
labels, hidden formulas, proofs or model outputs supplied either meaning.

## Exact input evidence and selection

Read only context/id fields from local ProverQA dev files when locating title
occurrences. Chose two intact source sentences whose remaining predication is
simple enough for defensible complete gold:

| Gold ID | Input locator | Original sentence |
|---|---|---|
| prover-name-title-1 | dev/hard.json, item369, context sentence7 | Dr. Yareli Hernandez is empathetic. |
| prover-name-title-2 | dev/hard.json, item11, context sentence3 | Dr. Marlon is not analytical. |

Sentence indexes are zero-based and preserve the abbreviation `Dr.` inside its
sentence. Each row also gives a zero-based half-open context character span and
SHA256 of the exact extracted sentence. These locators do not depend on the
production sentence splitter. Wording is unchanged; isolation from the larger
context is the only adaptation. This closes a two-example diagnostic cell, not
population or name-resolution coverage. Source attribution is in
[bench/proverqa/README.md](../../bench/proverqa/README.md).

I did not choose title examples whose predicates include “often”, PP attachment,
modal “can”, “not necessarily both”, or unresolved plural-object readings merely
to reach three rows. Their complete meanings require additional contracts.

## Independently chosen reference convention

The complete written referring expression is the rigid constant key, including
the title, spacing and case: `Dr. Yareli Hernandez` and `Dr. Marlon`. The honorific
is treated as part of the referring label in these isolated benchmark inputs.
It does not by itself assert a doctor predicate or verify credentials. This is
an explicit bounded reference convention, not a general claim that English
titles never convey descriptive or presupposed content.

The larger contexts also use shortened names. The fixture does not infer their
identity with the title-bearing forms; no shortened form occurs inside either
isolated sentence. Aliasing, document-local identity and multiple same-name
entities remain separate gold requirements. Replacing the full label by a short
name or generic common-noun quantifier would change this representation contract.

## Units 2, 3 and 4

**Unit 2:** the complete licensed name span has category NP. `is` has
`(S[dcl]\NP)/(S[adj]\NP)`; the adjective is `S[adj]\NP`. Forward copula
application and backward subject application derive S[dcl]. Negation is the
existing VP operator with subject-wide scope. Its composition must preserve the
copula's adjectival argument and [dcl] feature. The period in `Dr.` is internal
to the name span, not sentence-final punctuation.

This describes the target derivation, not observed CCGbank component supertags.
No corpus was loaded and no tag assignments for Dr./Yareli/Hernandez were inferred
from a parser. Ordinary N/N noun/adjective templates on those fragments do not
by themselves establish one rigid multiword referent. A future implementation
needs licensed multiword-name analysis, preserving its evidence and ambiguity.

**Unit 3:** let P=e→t and Q=P→t. The name denotes `λK.K(c):Q`, with c the full
constant above. The adjective denotes `λN.N(λx.empathetic(x)):Q→t` (analytical
analogously); copula is identity on that VP meaning. Thus the first row is
`empathetic(Dr. Yareli Hernandez)`. VP negation yields
`¬analytical(Dr. Marlon)` in the second, not a generic universal over marlons.

**Unit 4:** the first DRS is `[ | empathetic(Dr. Yareli Hernandez)]`, no discourse
witness. Its one atom is Asserted. The second is
`[ | ¬[ | analytical(Dr. Marlon)]]`: whole negation Asserted, atom Embedded.
Both have empty Reported and Presupposed groups. Name recognition never makes an
assertion oracle-confirmed. The current conservative discourse policy may leave
a name occurring only under negation unavailable to later pronouns; neither row
claims to solve that separate accessibility question.

## Boxer and ccg2lambda comparison

Bos2008 §3.2 separates category/type from word/POS-sensitive lexical meaning;
§3.3 separates construction from reference resolution. Adopt those boundaries:
NP does not prove identity, and a multiword referring span does not resolve
aliases elsewhere in a document. The paper does not certify this fixture's
full-written-key convention. See [REFERENCES](../linguistics/REFERENCES.md).

The pinned [ccg2lambda2015 NNP rules](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_emnlp2015.yaml#L37-L46)
condition name interpretation on POS evidence and introduce an equality-bound
witness with two predicate continuations. Adapt evidence-sensitive name selection,
not that witness representation: this project's existing rigid-name contract has
one continuation and no existential name witness. Those rules alone do not solve
abbreviation segmentation or multiword-span recognition. Neither upstream system
was run, and neither source determines the expected claim table here.

## Validation plan and limitations

Prediction before static validation: both rows satisfy the existing schema,
unique IDs, canonical empty universes and independent claim scopes; source spans
match the exact input strings. Validate with fidelity.validate_case only, not the
production parser or claim splitter. Final review must approve the explicit
honorific/reference convention before integration. All new model/benchmark and
CCGbank loading remain paused; no parser-result score is claimed.


Static validation result:2/2 schema and exact-source locator checks passed;
both IDs unique, title-aware sentence indexes and character spans matched the
original context text. `git diff --check` passed. Reviewer accepted the proposed
reference convention provisionally; committed rows and locators are submitted
for final review. No parser, claim-splitter, model or CCGbank call occurred.
