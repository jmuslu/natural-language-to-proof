# Narrow lexical name subjects for nominal predication

Design only. The bounded nominal-v1 candidate still needs its own integration
and fidelity gates. This document neither changes that branch nor activates
rejected nominal-candidate. It specifies an optional, independently reviewable
subject admission policy; it predicts no recovered corpus cases.

## Answer and epistemic boundary

An unopposed dictionary-NNP lexical certificate can suffice **under a declared
lexical assumption**: an attested, unopposed singular proper-name entry denotes
a rigid individual in this bounded subject position. It does not prove that
English ambiguity is resolved. An incomplete dictionary can miss a common-noun
or adjective use, a metalinguistic mention, or an unfamiliar referent. If the
required guarantee is resolution of every such possibility, this evidence is
insufficient and the name extension must remain deferred.

The proposed policy is deliberately stronger than current NameOnly and weaker
than a claim of universal linguistic certainty. It admits only a positive
lexical-evidence subset, without per-name lists, frequency thresholds fitted to
gold, or changing independent gold to match a parser's preferred reading.

## What the current interface actually says

`src/NL2Proof/Syntax/CCGSemParse.hs` defines exactly `NotName`, `NameOnly`, and
`NameOrOther`. There is no `NameFromCaps` constructor. That label below describes
an evidence origin, not a value that implementation can pattern-match today.

| Existing result | Possible evidence source | Sufficient for this proposal? |
| --- | --- | --- |
| NameOnly | Highest-count POS is NNP or NNPS; lower-ranked competitors may exist | No |
| NameOnly | Unseen noninitial capital, no POS evidence | No |
| NameOrOther | Unseen initial capital, name plus open-class alternatives | No |
| NotName | Highest-count POS is not NNP/NNPS, possibly after truecasing | No |

`lookupForm` can select an attested lowercase form for an initial capital;
`nameStatus` checks only the first ranked POS. `offeredTags` applies scoring,
beam and cap. Neither the selected NP, the surviving offered list nor absence
of `stAlternatives` certifies absence of contrary dictionary evidence.
`NameOnly` generates no alternate lexical meanings even when its underlying
counts contain contrary POS. The admission check must inspect original
positive counts, before ranking/pruning, not a human-readable note string.

## Concrete proposed minting contract

Use a distinct subject evidence constructor; do not redefine global NameStatus.
For one direct lexical occurrence, all conditions must hold:

1. The written form and the effective `lookupForm` each have nonempty positive
   dictionary POS support, and every positive POS there is exactly `NNP`.
   Reject NNPS in this first singular-name extension, pending a group/plural
   reference contract. Reject zero/negative-count data as malformed rather than
   treating it as positive name evidence.
2. As a conservative spelling-ambiguity guard, inspect the lowercase form's
   available POS evidence too. Any positive non-NNP evidence there blocks this
   extension. Absence of lowercase evidence is not positive name evidence;
   only step 1 supplies that. Never replace the constant with the lowercase
   spelling or infer an alias. This guard is a declared restriction and may
   reject real names; it does not decide which case variant is the right sense.
3. The particular lexical candidate is produced by the existing rigid-name
   constructor, with an actually offered ordinary NP source category, or an
   actually offered N source category using the existing licensed name N→NP
   repair. Preserve that original category and repair identity. NP expletive,
   there, conjunct features, arbitrary unary N→NP, type raising, inferred bare
   generics, and NP category alone do not mint this certificate.
4. Preserve source, token index/span, written form, effective lookup form,
   inspected POS evidence/model identity, original category, and the exact
   existing rigid-name term. The property certificate is separate. A token-wide
   boolean must not certify every alternative sharing its span.

Requiring NNP-only rather than merely rejecting NN/JJ also defers other
contrary analyses. The unpruned evidence audit concerns lexical assumptions;
it is not a fabricated list of complete grammatical alternatives. Do not log
rejected POS entries as complete readings. Conversely, smoothing and category
priors cannot manufacture missing positive dictionary evidence.

An implementation should compute this from the same immutable loaded model
that supplied the lexical candidate. If the model lacks reliable evidence or
its provenance cannot be checked, do not mint the optional capability. No new
load or corpus audit was performed here.

## Preserve the predication envelope

**Unit 2:** only this certified lexical NP can fill the subject slot of the
existing bounded Pending nominal VP through direct backward application.
Ordinary N→NP name repair remains available on its old routes; this optional
construction capability does not rewrite its behavior. Complement `a/an + N`
still needs its own independently licensed lexical N. Capturing a subject does
not make a bare adjective into a nominal complement.

**Unit 3:** the name subject is `Q = λk.k(a)` using the original full constant.
The complement's P is captured at direct article+N construction, never recovered
by inverting arbitrary normalized Q. Completion is `Q(P) = P(a)`. Do not restore
equative fallback, collapse global existential equalities, or attach a name
certificate to the complement just because it is NP. Argument indefinites keep
their existing witness semantics.

**Unit 4:** for the independent schematic reading `Ari is a geologist`, the
expected result under stipulated NNP evidence is `[ | geologist(Ari)]`, one
Asserted atom; no identity witness or occupation presupposition is added.
Keep the full-root Complete certificate, source identity, all packing keys and
embedding/negation/coordination restrictions of nominal-v1. This subject change
does not authorize those further constructions. A reported clause must not
escape the envelope and assert its embedded nominal atom.

Boxer 2008's lexical construction versus resolution distinction and the pinned
ccg2lambda copular templates discussed in `nominal-licensing.md` explain the
boundary: typed composition specifies what a supplied NP means, not why this
occurrence deserves a rigid NP. The lexical assumption belongs in Explain's
construction evidence; it is not a semantic proof or an external-system result.

## Sealed evidence and negative cases

The coordinator's `research/runs/expanded-gold167/explain.log` shows Abraham,
Alyssa, and Amiyah with best NP `[name]`, explicitly **no selected derivation**;
all three positive nominal gold sentences are no-parse. These summaries do not
show complete POS counts or satisfy the certificate. Their eligibility is
UNKNOWN from this artifact. No gain for these three is predicted. Amiyah's
complement also has best `volunteer:N/N`, an independent noun-leaf issue.

Prior sealed findings in `research/notes/name-ambiguity.md` locate Dean/Legend
failures at lexical/truecasing and generic-subject selection, before negation or
copular composition. They do not establish full current POS counts. If either
has contrary effective/written/lowercase noun evidence, this extension abstains;
if only a majority summary is available, eligibility stays unknown. It does not
repair their intended named reading by spelling-specific exception.

American in the rejected nominal candidate was used as a rigid equative
complement. This extension never licenses that complement route, regardless of
POS counts. A hypothetical subject with NNP+JJ evidence is also rejected.
Unknown plural Gorpuses and casing-only unknown initial names are deferred;
attested NNPS-only family names are likewise outside this first extension.
These abstentions are not errors to erase by changing their independent gold.
