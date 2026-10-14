# Unknown names: evidence, hypotheses and an optional input contract

Design only; no source change or implementation authorization. Based on accepted
research7812f16, the attested-name certificate, c77ad00 licensing design and
7d85eb1 lexical evidence audit. Keep the current name repair and known-name
nominal admission unchanged. Recommend **deferring automatic unknown-name
promotion**. The smallest defensible optional route would require a caller's
independently declared input-language convention; absence from a dictionary is
not a new positive lexical fact.

## What is known, and what remains a hypothesis

| Evidence | What it supports | What it cannot establish |
|---|---|---|
| Nonempty unpruned written/effective POS exclusively NNP, no contrary lowercase evidence | Current narrow dictionary-name assumption, with an actual nameItem origin | Unique reference or absence of every possible English homograph |
| Initial capital and absent POS | Candidate name hypothesis alongside other analyses | Proper-name status: sentence-initial common nouns also capitalize |
| Noninitial capital and absent POS | A stronger orthographic cue, still a hypothesis | Name rather than acronym, title, quoted mention or capitalization error |
| Offered NP/NP[nb] | A syntactically available category | A dictionary-attested NP when the offer came from smoothing/prior; name rather than descriptive/generic reference |
| Offered N and existing name N→NP repair | A typed rigid-name route once its lexical assumption is licensed | A generic unary N→NP is a name, or an unknown N is a singular individual |
| Independently supplied identifier-language contract | Permission to interpret conforming tokens under that declared convention | Evidence that an ordinary-English benchmark was generated under that convention |

The observed loader audit found Abraham NNP4 with offered dictionary categories
N2/N/N2; Alyssa and Amiyah had no observed POS/tags, including lowercase keys.
The scan read1875 files with125 missing candidate paths; conclusions concern
that installation, not universal lexical absence. Abraham's current dictionary
predicate can pass; Alyssa/Amiyah cannot. The displayed best NP/name in old
Explain summaries was insufficient for this distinction. Neither audit nor
selected NP alone establishes a full clause. Amiyah also has a separate
complement-category issue; a subject policy cannot manufacture a lexical N for
volunteer.

Historical sealed failures further separate the issues: Dean/Legend can receive
a common-noun generic reading; unknown Gorpuses received a rigid alternative;
American entered a rejected equative nominal route. Their exact unpruned POS
counts were not established by those traces. Do not repair them with per-name
exceptions, suffix stripping, aliases or a benchmark-specific whitelist.

## Reject the apparent shortcut

A rule “unknown initial capital + NP + is a N means a rigid name” confuses
well-typed composition with evidence of reference. Consider an unseen written
role-word and an unseen person's name with identical offered categories and
empty case-variant dictionaries. The parser's available evidence is identical
apart from spelling; the complete type-t name reading need not be the intended
English interpretation. A beam that drops the common-noun route does not resolve
that uncertainty. New no-parse→wrong-but-typed readings would recreate the
rejected broad nominal failure.

Plural-looking strings, acronyms and demonyms do not rescue the shortcut.
NP[nb] does not encode singularity, human reference or a proper-name ontology.
Ending in s does not distinguish Gorpuses from James, and all-capitals can
identify organizations, plural abbreviations or ordinary emphasis. Mixed-case
forms may be identifiers or words. A multiword title may require segmentation
before syntax; the Dr. title failures cannot be solved by a single-token subject
certificate. A pronoun is an anaphoric/deictic expression, not a fresh rigid name.

## Smallest optional policy worth a later decision

A possible policy is `DeclaredIdentifierSubjects`, enabled only by an explicit
**run-level controlled-language contract**, independently supplied by the caller
before gold/parser observations. The convention would say that conforming
single-token identifiers in the bounded subject position denote rigid singular
individuals, with exactly their written label, within a stated document/domain.
It must be a uniform syntactic/ontological convention, not a roster extracted
from fixture names, an answer-dependent declaration or a new benchmark filter.
For example, a caller can generate its own controlled language under that
convention; the analyst cannot retroactively claim ordinary English follows it.

For a minimal first design, restrict the declared identifier spelling to ASCII
initial-upper followed by at least one lowercase letter, and the occurrence to
one direct subject of the already licensed nominal frame. These are declared
input-language restrictions, not linguistic tests for English namehood. They
exclude single-letter I, all-cap acronyms, internal capitals, digits, apostrophes,
hyphens, titles and multiword identifiers from this initial scope. They do not
magically exclude an unknown role-word or plural-looking token: under the
contract these would be identifiers, so applying the contract to ordinary text
would be a semantic error. Do not add a final-s heuristic to conceal this fact.

Additional proposed requirements:

1. Preserve the default dictionary certificate as its own alternative. The
   new route requires truly empty written/effective/lowercase POS and absent
   dictionary tag membership for those forms in the actual immutable model.
   Any contrary or malformed evidence blocks the hypothesis route; majority
   NNP, NNPS or existing conflicting common-word evidence cannot be bypassed.
   Missing training data is recorded as model provenance, not evidence that no
   such word exists in English.
2. Require an actually offered **ordinary NP or NP[nb]** from the existing
   lexical nameItem branch. Record that its support is backoff/prior where
   applicable; never label it dictionary evidence. Do not add categories or
   change lexicalSigns order/scores. Initially defer the unknown lexical-N
   repair route; the accepted dictionary-supported N repair stays unchanged.
   This may leave Alyssa/Amiyah unsupported if their actual offered categories
   do not qualify. It is a bounded restriction, not a predicted gain.
3. Require not closed-class and not pronoun, expletive, there-NP, conjunct,
   article-bearing description, coordination, type-raised subject, generic
   unary or a term merely shaped like lift(name). Mint a distinct
   `HypothesizedName` evidence constructor alongside the actual lexical branch,
   bound to contract identity, model context, written/effective forms, checked
   evidence, source, span, index and original NP category.
4. Retain that constructor through the actual nominal subject transition,
   Complete, packing, final-period and root checks. It is neither NNP support
   nor an alias certificate. Equal normalized terms with dictionary and
   hypothetical origins remain distinguishable before final meaning dedup;
   the retained result must expose every assumption used for its admission.
5. Restrict its use to the already reviewed direct nominal envelope. If the
   separately reviewed negated frame is available, preserve its exact not
   certificate and subject-wide scope; otherwise do not introduce negation
   indirectly. No descriptive/equative complement, relative, coordination,
   report, generic N→NP or discourse-propagation extension follows.

This is more than a parser boolean: invocation, response, report, replay and
selected claim provenance need the contract identity and policy. Do not silently
mark the resulting claim as ordinary dictionary-backed English, Reported or
Presupposed; none of those statuses means “lexical hypothesis.” Under the
explicit controlled-language interpretation the input sentence is asserted,
but its interpretation is conditional on the external convention and must
remain labeled. The present unknown-noun execution field cannot carry this
separate assumption. If assumption visibility/admission cannot be enforced
without disproportionate machinery, reject the option rather than hide it in
a note. Implementation remains deferred pending that cost/usefulness review.

## Independent acceptance controls before any implementation

These are prospective semantic/admission contracts, not tests reported as
passing. Construct miniature models and independent gold before observations;
exercise actual minted origins once an API exists. No corpus/gold edits here.

| Control | Required behavior |
|---|---|
| Unknown Zorlan, direct offered NP, no contract | Current default unchanged; no new nominal-subject capability |
| Same evidence plus explicit identifier contract | Conditional candidate only; `Zorlan is a geologist` means geologist(Zorlan), if noun source independently qualifies |
| Same unknown token with offered N only | No new optional capability; ordinary repair elsewhere unchanged |
| Unknown Curator under ordinary English | No automatic name promotion; capital and type t are insufficient |
| Unknown Curator under the explicit identifier convention | Treat only as stipulated identifier, labeled separately; cannot count as English disambiguation |
| Known lowercase curator/legend or NN/JJ competitor, rare count1 | Block hypothesis even if scoring/beam hides competitor |
| Written NNP100 plus NN1; NNPS-only name | No hypothesis bypass of failed dictionary certificate |
| Unseen Gorpuses before are | Outside exact singular-copula nominal frame; no optional extension |
| Gorpuses before is under identifier convention | Spelling alone cannot reject it; interpretation conditional on convention, not a universal common-noun analysis |
| USA, iPhone, Dr. Marlon, Mary-Jane, O'Neil, He, I | Outside initial scope; no split/strip/repair to fit it |
| Same term/span but missing, foreign or changed contract | No discharge; packing must preserve evidence distinction |
| `Zorlan is not a geologist` in independently licensed negative frame | NOT Asserted, inner atom Embedded; no positive class membership |
| `Every geologist is an animal` | Existing universal semantics/policy unaffected; unknown-name option irrelevant |
| `Zorlan sees an animal` | No new use of optional nominal certificate; ordinary object article remains existential |
| Reported/conditional/relative occurrence later reused as a name declaration | Forbidden: no self-bootstrapping or promotion from embedded evidence |
| Two spelling variants, abbreviated title, or repeated label in another source | No inferred alias or cross-document identity; explicit reference scope governs |

Unit2 separates category availability from reference evidence. Unit3 keeps
`Q=λP.P(a)` distinct from a generic Q even though both typecheck; the hypothesis
changes admission, not lambda reduction. Unit4 preserves Asserted/Embedded
scope and source-local identity without adding existence, occupation or alias
claims. Boxer2008's construction/resolution distinction and ccg2lambda's
POS-sensitive name unary (pinned a68cb264, EMNLP2015 YAML lines35–46) motivate
keeping reference assumptions visible, not claiming either system proves this
identifier convention. See [name licensing](NOMINAL_NAME_LICENSING.md) and
[ambiguity evidence](../../notes/name-ambiguity.md) for the existing comparison.

## Predictions and hard stops

No ordinary-English frozen190 gain is preregistered from this design. Alyssa and
Amiyah illustrate the known dictionary barrier, not a promised optional recovery;
actual source NP offers, complement nouns and the absence of a preexisting input
convention remain independent blockers. Unknown-name gold and common-word
negatives must be evaluated under separate fixed contracts, not pooled with the
known-only panel or used to claim ProverQA>=90% exact.

Unknown **noun** policy hypothesizes a common property P in a constrained
Every/each or a/an slot; unknown **name** policy hypothesizes reference Q and
rigid identity. Neither flag implies the other. If both are eventually exposed,
use a four-cell policy comparison (both off, noun-only, name-only, both on), same
frozen membership and same source; bind both flags and contract in execution.
Do not credit an existing noun-policy gain to a new name assumption.

Stop on default lexical behavior changes, any exact regression, new wrong typed
reading, missing assumption provenance, alternate readings with different
reference/scope, absent DRS silently filtered from all-reading checks, or
cross-document alias/discourse leakage. A nonempty retained set must all match
independent scoped gold under the declared contract; selected-exact alone is
insufficient. Absence of a competing reading under a beam does not discharge an
unresolved lexical hypothesis. If the input contract itself is absent or
inapplicable, abstain from the new route and preserve existing results rather
than relabel ambiguity as successful parsing. No policy interface or parser
implementation is recommended until these requirements and measured usefulness
justify the additional surface area.
