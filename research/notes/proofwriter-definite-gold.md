# Independent ProofWriter definite-description controls

Authored before any parser observation in isolated astra/proofwriter-definite-gold
from accepted7812f16. Full-access shell works. Own new fixture and this note only;
frozen190 and production files remain unchanged. No parser/model/benchmark load.

## Source and independent construction boundary

Three unchanged, distinct presented sentences are taken from the already
committed sample, not a new bulk corpus extraction. Source
bench/proofwriter/sample.jsonl SHA-256
bd8afbf08dcf92060afe330bc4d41ee2d5ea63af5d6261d7c9b87b351d7afd0a,
physical line5, record RelNoneg-OWA-D5-453-Q12. Projected id/theory/question for
verification; answers, proofs and hidden representations do not determine gold.

- The bald eagle sees the cat. — theory sentence3 (zero-based), chars[74,102).
- The cat sees the bald eagle. — theory sentence7, chars[181,209).
- The tiger does not see the tiger. — complete question, chars[0,33).

Each theory sentence occurs once at its recorded span. No word, modifier,
article, punctuation, subject/object or query polarity was changed. Isolating the
question as a sentence diagnostic provides its meaning, not an asserted fact
that the theory makes true. The three source sentences share one input record;
they are independently occurring clauses, not independent population records.
Two test positive argument order; one tests negative repeated-description identity.
This is not2–3negative source cases or representative corpus coverage.

The first and third source sentences previously appeared only after replacing
definite descriptions with Arthur/Bill in pw-atom-transitive-1 and
pw-atom-transitive-neg-1. Those transformed English strings are not these new
fixtures. The second role-reversed source sentence is not created by swapping
tokens in the first: its exact occurrence is independently verified. The full
original descriptions and compound now remain visible.

## Explicit semantics contract, not new compound ontology

Contract ID: proofwriter-description-constant-v1. This instantiates the existing
reviewed C1b policy in design-names-nominals f19b0fa and the stated describeIota
convention, not output fitting: supported definite descriptions denote fixed
content-named constants. The cat denotes `cat`, the tiger denotes `tiger`, and
the bald eagle denotes the complete `bald eagle` constant. Repetition of the same
description within this controlled input denotes the same individual. Surface
description order is retained. No new referent, existence/uniqueness assertion,
accommodation, or bald/eagle taxonomy is exported. These fixtures do not claim
literal intersective anatomy for the species name, general compound resolution,
or rigid cross-world/report reference. Without this declared controlled contract,
a general-English compound/definite interpretation would remain unresolved.

Thus the compound is not dropped or replaced by a generic eagle: its full label
is preserved. The existing policy explicitly names this phrase, so no new
unreviewed compound relation is invented to admit it. Other compound descriptions
outside supported content remain blocked rather than inferred from their noun
head alone. This contract is separate from historical unversioned gold and must
stay separately reported.

## Hand derivations: Units2/3/4

Unit2 candidate categories: the NP[nb]/N; cat/tiger/eagle N; bald N/N;
sees (S[dcl]\NP)/NP; see (S[b]\NP)/NP;
does (S[dcl]\NP)/(S[b]\NP); not a feature-compatible VP modifier.
These describe a proposed faithful compositional route, not observed lexical
CCGbank offers or an Explain producer witness. No new parser observation exists.

Unit3: write Q=(e→t)→t and lift(a)=λP.P(a). The definite determiner
λP R.R(ιP) applied to cat/tiger or the full bald-eagle description supplies
lift(cat), lift(tiger), lift(bald eagle) under the declared description-name
contract. The lexical transitive meaning is
λO S.S(λx.O(λy.see(x,y))). Forward application supplies the right-hand definite
object; backward application supplies the left-hand subject. The two positive
clauses therefore yield see(bald eagle,cat) and see(cat,bald eagle), respectively.
No commutation or role collapse is licensed. In the negative clause, do-support
preserves the base VP; NOT encloses see(tiger,tiger). The two syntactic descriptions
use the same constant, not two witnesses and not a reflexive-pronoun mechanism.

Unit4 independent gold, with empty universes throughout:

| ID suffix | DRS | Asserted | Embedded | Reported / Presupposed |
|---|---|---|---|---|
| subject-compound | [ | see(bald eagle,cat)] | that relation | empty | empty / empty |
| object-compound | [ | see(cat,bald eagle)] | that relation | empty | empty / empty |
| negative-identity | [ | NOT [ | see(tiger,tiger)]] | NOT condition | see(tiger,tiger) | empty / empty |

No description-membership predicates, equality atom, existential object, or
positive asserted self-relation should be added. The last row is not a positive
reflexive assertion. Condition/claim order is fixed; disjunction annotation list
is empty because none of these sentences contains OR.

## Comparison and validation boundary

Retained REFERENCES distinguishes Boxer event/compound-role treatment from our
explicit description-name convention; its broader semantics is not silently
imported. ccg2lambda's 2015 two-slot NP and existential-the choices are not the
same interface or definite contract. The existing C1b comparison explains why
we retain this narrow controlled reading rather than claim a general definite
resolution system. Neither upstream system nor any local parser was run.

Validate schema, canonical numbering/scope/claims, exact projected source spans,
nonduplication against committed/frozen190 texts and provenance hashes before
review. Do not append these rows to current membership or frozen190; reviewer
approval and a separate root freeze precede any parser observation. Gold presence
is not implementation support or an improvement in exact fidelity.

Validation complete:3/3 rows pass reviewed strict gold-only validation from
5c187c9; all source SHA/record/field/character spans match unchanged input and
occur exactly once. New IDs/texts are unique against all committed fixtures and
frozen190;190 hash reverified unchanged. Fixture SHA-256 recorded in commit
content; no parser baseline inspected or generated. Reviewer approval pending.
