# Open nominal predicates: distinguish syntactic license from dictionary coverage

Independent design review at `c4b9380`, inspecting candidate `8e2a6ad` directly.
No source or gold changes, no test/parse/model/benchmark launch. This proposal
is **not** authorization to loosen nominal-universal v1 before its fresh gate.

## Finding

Positive NN/NNS dictionary evidence is a conservative admission policy, not a
semantic requirement of universal nominal classification. The explicit frame
*Every wumpus is an impus* supplies two determiner-selected nominal positions.
Given independently licensed direct lexical N entries whose meanings are
properties `wumpus,impus:e→t`, composition should yield
`∀x(wumpus(x)→impus(x))`, not an existential impus linked by equality.
No dictionary entry is needed to perform that typed structural composition.

However, “offered N” is not the same as independently attested lexical noun:
`offeredTags` uses the global prior for unseen words and smoothing can add prior
categories to seen words. The existing open N template creates an uninterpreted
unary predicate for any admitted token; type correctness cannot prove its sense.
A novel lower-case word in this bounded frame can coherently receive a nominal
reading under that already declared open-lexicon assumption. This is a defeasible
linguistic design choice, not proof that every unknown English word denotes a
count noun. Keep the assumption visible and test its failures separately from
structural quantifier/scope fidelity.

**Recommendation:** retain v1 unchanged for its current trial. Approve a separate
v2 investigation of an explicit “unattested lowercase nominal in determiner
context” capability, rather than imposing the NN/NNS dictionary forever or
silently removing all lexical guards. Preserve contrary POS/name evidence,
source-category licensing, exact occurrence roles, and whole-root obligations.
A global unknown-word noun rule, broad category injection, Q unwrapping, or
corpus-specific nonce-word whitelist is not justified by this argument.

## Frequency relevance and its limits

The complete local Pronto acquisition contains819,128 sentence occurrences.
Every/each universal outer family contributes185,426 (30,878 distinct surfaces);
predicate article+noun cue503,067 spans several outer families. These counts
justify examining nominal predication but do not count the exact intersection
of Every/each+is+a/an+direct N, much less its no-POS subset. Do not add them or
claim all185,426 would benefit. The acquisition also includes266,759 named
clauses,184,577 bare plurals and176,850 restrictive relatives; v1 and the proposed
v2 bounded universal route do not repair those merely by handling unknown nouns.

Current independent `pronto-every-1`, *Every wumpus is an impus*, and
`pronto-each-2`, *Each yumpus is a dumpus*, are relevant direct nominal controls
(fixture IDs and text checked directly). A no-parse
result alone cannot prove missing POS is the only blocker: source category
availability, seen pairs, finite copula and lexical shape can also prevent the
route. No fresh measurement or projected exact percentage is claimed here.

## What candidate v1 actually certifies

`8e2a6ad` requires direct lexical category N, NotName, at least one NN/NNS count,
and no JJ/JJR/JJS/NNP/NNPS dictionary entry. Subject evidence is direct FwdApp of
lexical Every/each `NP[nb]/N` with such a noun. The source copula must offer
`(S[dcl]\NP)/NP` and adjacent article a/an must offer `NP[nb]/N`. Paired internal
`is:(S[dcl]\NP)/N` and `a/an:N/N` compose classification without changing the
ordinary existential article. Mandatory roles carry source identity, spans,
categories and matching copula/article occurrences through both chart passes.
Only full positive root declaratives discharge the route; unrelated composition,
unary, negation, embedding and mixed certificates cannot erase the obligation.

Dictionary NN/NNS is not contextual disambiguation: one attested noun use does
not prove the current use, and one JJ use does not prove a nominal use impossible.
The existing conflict veto deliberately sacrifices potentially valid readings
instead of resolving sense. Its asymmetry—allowing ordinary open N elsewhere
but requiring dictionary support for this particular reanalysis—is a defensible
v1 risk boundary, not a theorem that missing POS makes classification unsound.

## A bounded v2 capability to review, not an implementation

Keep v1 KnownCommonNoun and add UnknownNominalInDeterminerContext with explicit
origin class. This is evidence for a selected nominal interpretation, not a new
semantic type. The latter requires all of:

1. Existing offered **direct lexical N** and its existing P:e→t meaning; not N
   derived by unary, composition, a relative, coordination or modifier output.
   Do not invent N when absent, and do not extract P from a normalized NP/Q.
2. No dictionary POS evidence for this lookup form, lower-case alphabetic token,
   and NotName; no reserved closed-class token. “No POS” is absence of evidence,
   not evidence overriding a positive JJ/NNP entry. A POS-known verb-only word
   is a different policy question and does not enter this no-POS extension.
3. Direct subject Every/each selection or paired copular a/an selection from the
   same source occurrence. A standalone unknown N receives no new global
   capability; the context license is checked at consumption, not guessed from
   nearby words. Both nominal slots must satisfy their own licensing condition.
4. Existing exact copula/article source categories, seen-pair constraints,
   certificate matching, whole-root-only completion and all active-role guards.
   A new evidence-origin field must participate in packing, so equal terms from
   known and hypothesized origins cannot lose their distinctions.
5. An Explain decision recording inferred nominal use, unknown dictionary state,
   selected source N and the scoped construction. If richer lexical alternatives
   remain, inspect all readings and selected fidelity; do not call the branch
   correct because one added reading happens to match gold.

The intended P is the existing uninterpreted nominal property. No new lemma,
sense bridge, equality, presupposition or oracle confirmation follows. Unknown
plural morphology, mass/count coercion and subsective/adjectival nominalization
are outside this first v2 boundary. Unknown tokens that happen to be adjectives
in a different lexicon remain an unavoidable model assumption; contrary lexical
evidence becoming available must defeat this unknown-only license. Do not claim
the pattern is an oracle for grammatical English.

## Independent acceptance controls before any proposed source change

These are authored test specifications, not newly changed gold or measured results.
Freeze lexical/source/POS fixtures independently, including offered alternatives.

| Input and lexical fixture | Required result or boundary |
| --- | --- |
| Every wumpus is an impus; both lower-case, no POS, offered direct N | Candidate classification `∀x(wumpus(x)→impus(x))`, one implication Asserted, both atoms Embedded; trace both inferred nominal origins. |
| Each dax is a blicket; same evidence | Same universal classification, no equality/second witness. Distinct nonce vocabulary prevents a benchmark-word patch. |
| Every cat is a blicket; cat knownNN, blicket unknownN | Mixed known/inferred origin works without changing cat meaning or requiring all slots share one evidence class. |
| Every dax is an animal; dax unknownN, animal knownNN | Converse mixed-origin control; subject quantifier remains once. |
| Every cat is red; knownJJ, adjective source category | Preserve ordinary adjective meaning. No paired article exists, so new route is inapplicable. |
| Every cat is a red; red knownJJ or NN+JJ, also offered N | New unknown-only route rejects; v1 conflict veto remains. Do not conflate adjective property with a color/token noun by type alone. |
| Every cat is a jordan; jordan has NNP or NN+NNP evidence | New route rejects despite lowercase typography/offered N; lexical name conflict not erased. |
| Every dax is a Zorp; unseen capitalized complement | Reject unknown-only nominal capability; preserve independent ordinary name policies. |
| Every dax is an impus; complement offered only NP, not lexical N | No Q unwrapping, no synthesized N. Remains unsupported by this route. |
| Every dax is a red impus; modifier-produced N | Not supported by this direct-N route. Modifier sense/order needs its own reviewed design. |
| Every dax that sleeps is an impus | Relative/unary subject cannot counterfeit direct determiner+noun capability. |
| Bob is a dax; A dax is a blicket; Daxes are blickets | Outside supported subject family; preserve existing behavior rather than silently broadening scope. |
| Bob sees a dax | Ordinary a retains existential object witness. New predicative article meaning cannot leak. |
| A is B / Every dax is the impus / embedded “says that Every…” | No new equative or definite-Q reinterpretation; incomplete/embedded roles remain blocked. |
| Certificates with same strings but swapped token indices/source IDs | Reject mismatches. Equal normalized properties do not identify occurrences. |

Negative controls must distinguish “new route absent” from “whole sentence has
no ordinary reading.” Do not suppress a legitimate existing adjective/name
analysis merely because the new paired construction is unavailable.

## Units 2/3/4 and historical comparison

Unit2: direct category N and explicit determiner context constrain the syntactic
hypothesis; POS dictionary evidence selects/vetoes lexical uses but is not itself
the category derivation. Unit3: N already has P, the paired article is identity
on P, copula `λP Q.Q(P)` takes that property, and Every/each contributes
`λN R.∀x(N(x)→R(x))`. Unit4: `[ | [x | dax(x)] ⇒ [ | blicket(x)]]`; no main-box
existential, equality, or embedded atom promotion. The lexical interpretation
assumption must remain distinct from these structural guarantees.

[Boxer2008](https://aclanthology.org/W08-2222.pdf) §3.2 uses category together
with lexical/POS/morphological information, particularly because shared categories
can have different meanings. Adopt that separation; do not misread it as requiring
a finite corpus dictionary before any novel common noun receives a property.
[ccg2lambda's pinned English templates](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_emnlp2015.yaml)
use category-based nominal property templates plus more specific lexical/POS
entries. Adapt that open-vocabulary property idea with explicit local evidence;
reject its adoption as a guarantee that an arbitrary offered category determines
English sense. Neither system's coverage claim supplies our independent fidelity
or provenance gate. Neither justifies discarding incompatible lexical evidence.

Conclusion for review: nonempty NN/NNS evidence need not be a permanent
requirement for this construction. Removing it without a declared unknown-only,
context-bound capability would weaken the reviewed v1 contract. Finish v1 gates,
then separately review/implement/test v2 with unchanged gold, full retained
negative controls and fresh selected-reading fidelity before any landing.
