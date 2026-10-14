# Bounded adjective admission proposal

Status: proposal plus independent red controls, not source authorization. Baseline
is `169c761`; diagnostic evidence is `1659575` and the preserved ignored
`research/runs/wrong-first-divergence/` bundle. No further CCGbank load occurred.

## Observed problem and mechanism

`CCGSemParse.offeredTags` combines word-category counts with the global category
prior when smoothing is enabled; absent words use that prior directly.
`lexicalSigns` currently sends every offered open category to `openTemplateWith`.
Its POS-backed `posTags` is an optional additive repair: NN/NNS adds N and JJ adds
N/N plus S[adj]\\NP when absent. It does not veto an already offered adjective.
POS is a dictionary support set, not contextual tagging or proof of sense.

The sealed selected trace establishes hawks/mammals as S[adj]\\NP surface
predicates, despite successful bird/monkey normalization in subject N. Excels
selects S[adj]\\NP with excels; its alternative S[pss]\\NP gives excel. A passive
category matching the expected predicate does not establish correct finite
syntax. These are selected-category errors relative to the independently
specified constructions; the trace alone does **not** tell whether their
adjective tags were word-attested, smoothed, or OOV-prior, or supply their full
POS support sets. That distinction is necessary before predicting applicability.

## Minimal candidate envelope

Consider filtering only open-class candidates of the **exact** category
S[adj]\\NP, before constructing a lexical sign, and only if all hold:

1. The same `lookupForm m (i == 0) w` used by offeredTags has a nonempty
   word-category dictionary entry.
2. That word's own category counts contain no occurrence of exact S[adj]\\NP.
   Direct category evidence wins even against sparse contrary POS evidence.
3. The POS support set for the same lookup form is exactly `{NNS}` or exactly
   `{VBZ}`. No majority threshold, suffix heuristic or corpus-word exception.
4. This is the ordinary open-class path, not names, closed entries, reporting
   complement repairs or another reanalysis. No other category is removed.

This is a conservative lexical admission policy, **not** a theorem that these
POS inventories exclude all adjectival use. Lexical sense incompleteness remains
a risk. Mixed POS, NN-only kind, JJ/JJR/JJS, participles, missing POS, unseen
round and all other unknown words abstain from rejection. N/N stays unchanged:
its nominal-compound interpretation needs a separate proposal. Optional JJ
backoff remains intact. No global predicate spelling change, noun normalization,
verb valency inference, score change or category substitution is proposed.

If a later implementation is approved, retained signs keep their token, category,
score and existing origin. Rejection must be visible in diagnostics with lookup
form, own-category absence and the complete POS support set; do not silently
report merely 'no meaning'. The present proposal adds no diagnostic API or
production code. Existing Explain does not expose those rejected-evidence sets.

## Independent miniature controls

`test/AdjectiveAdmissionProposalSpec.hs` synthesizes tiny tag/POS dictionaries;
none uses target vocabulary hawks/mammals/excels. Lanterns and glides receive
smoothed adjective candidates although their own categories and exclusive POS
support are nominal/finite-verbal. Both proposed rejection assertions are red
on current production code. The other 16 assertions pass, including candidate
availability prerequisites, preservation of N and finite VP, N/N, word-attested
adjective with conflicting POS, minority JJ, NN-only kind, unknown round/nonce
adjective, absent/mixed POS, participles, comparative POS, JJ-only additive
backoff, and name behavior.

Run: `runghc -isrc -itest test/AdjectiveAdmissionProposalSpec.hs`.
Observed: **16/18 pass; two deliberate rejection failures**. These are independent
lexical-policy controls, not parser-derived gold, a reproduction of target
results, or a new acceptance denominator. No cabal entry or shared suite changed.

## Predictions before any source trial

| Evidence situation | Predicted effect; explicit uncertainty |
|---|---|
| Known NNS-only form, prior-only adjective | Candidate disappears; a complete faithful nominal derivation might become selected, or the sentence may become no-parse, or another wrong reading may win. No exact gain promised. |
| Known VBZ-only form, prior-only adjective | Candidate disappears; an existing finite reading may become selected, but passive or other wrong readings can survive. Excels is not certified by its passive alternative. |
| Unknown word / word-attested adjective / protected POS | No candidate change under this proposal, even if the selected reading remains wrong. |
| Existing exact reading relying on excluded prior-only adjective | May become wrong/no-parse: this is a regression risk, not a fidelity win. Fixed-panel newly-wrong and newly-no checks are mandatory. |

Before implementation acceptance, inspect already available lexical support if
present, otherwise request a separately authorized bounded evidence extraction:
record lookup form, own category counts, full POS support and offered scores for
the target occurrences and protected exact controls. No such extraction is
performed here. If targets are OOV or otherwise outside the envelope, report
zero applicability and pursue actual construction licensing; do not broaden
this gate to force gains. Reviewer approval and root gates precede source trial.
Wrong-to-no-parse reduces wrong readings but does not improve exact fidelity;
no gate score, gold, contract, denominator or model authority changes.
