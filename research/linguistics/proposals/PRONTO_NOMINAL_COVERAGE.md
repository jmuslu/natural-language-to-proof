# ProntoQA: the nominal v1 surface opportunity

The bounded nominal candidate `8e2a6ad` has **86,788 input occurrences and
1,402 unique strings** with its necessary surface shape:
`Every/Each WORD is a/an WORD.` This is10.60% of819,128 presented occurrences
but0.79% of177,560 unique strings. These are **structural opportunity counts,
not licensed parses, coverage gains, or fidelity estimates**. Repeated
in-context demonstrations account for much of the occurrence weighting.

Reproduce without raw input or a corpus load:

```
python3 research/linguistics/pronto-nominal-coverage.py \
  --output research/linguistics/pronto-nominal-coverage.json
```

The [script](../pronto-nominal-coverage.py) reads only the committed
[joint inventory](../prontoqa-inventory.json), whose source hashes and
80-file/65,600-record scope are documented in the
[Pronto section](../sections/prontoqa.md). Its anchored classifier requires a
full-stop-terminated single sentence, one-word subject, singular `is`, and
one-word positive article complement for this profile. Matching requires the
family `universal_every_each` **and exactly** the single feature
`consequent_article_predication`. Marginal article and quantifier frequencies
cannot be multiplied to obtain this intersection. Neither the pooled Every/Each
nor a/an split is retained separately in the aggregate; do not invent splits.

## Exhaustive structural partition

| Surface family / first structural exclusion | Occurrences | Unique strings |
|---|---:|---:|
| Direct Every/Each + positive single a/an complement: opportunity | 86,788 | 1,402 |
| Every/Each + single bare consequent | 33,813 | 2,316 |
| Every/Each + nominal coordinated consequent | 32,458 | 9,295 |
| Every/Each + mixed bare/article coordinated consequent | 17,816 | 15,828 |
| Every/Each + negative consequent | 14,551 | 2,037 |
| Named single clause | 266,759 | 37,289 |
| Bare-plural subject (`WORD are ...`) | 184,577 | 24,756 |
| Restrictive relative (`Everything that is ... is ...`) | 176,850 | 80,550 |
| Named clause coordination | 5,516 | 4,087 |
| Total | 819,128 | 177,560 |

These rows partition the47 existing joint profiles; counts are not overlapping
marginals. The script verifies total, unique, and per-family conservation and
fails on an unreviewed universal profile. Negation receives priority before
coordination in the exclusion classifier; in this inventory the universal
negative profiles are single-consequent forms. Of the14,551 negative occurrences,
only150 (133unique) have an article complement;14,401 (1,904unique) have a bare
complement. “Bare” is a surface description: it does not decide whether the
lexical meaning is adjectival, nominal, generic, or a morphology error.

A useful cross-family comparison holds the consequent fixed. Positive single
article consequents occur109,245times in named clauses (153unique),86,788times
in Every/Each clauses (1,402unique), and174,874times in restrictive-relative
clauses (78,626unique). The named and relative counts remain structurally
excluded by v1 even though their consequent shape matches. No bare-plural
family profile has this positive single article consequent shape; its overall
184,577 occurrences are not all equivalent to “add a plural subject license.”

## Lexical eligibility requires a separate join

WORD does not prove lexical N. Candidate v1 additionally requires:

1. A direct lexical N decision with NN/NNS dictionary evidence and no
   JJ/JJR/JJS/NNP/NNPS evidence, plus the existing NotName decision, for both
   subject and predicate nouns. Unknown/no-POS words are not certified.
2. Offered exact source article `NP[nb]/N` and nominal copula
   `(S[dcl]\NP)/NP`, and supported overt Every/Each determiner source category.
3. The source seen-pair licenses for direct determiner and copula applications,
   correct noun lemmas, matching occurrence certificates, and no unsupported
   unary/composition/coordination or embedding path.
4. Retained candidate through bounded chart search and correct final selected
   meaning. Surface inventory says nothing about these outcomes.

The structural aggregate alone contains no token/profile join or dictionary
counts. Its lexical fields remain null by design. A subsequent authorized,
bounded join now supplies **POS-policy evidence**, not full route eligibility,
in [pronto-nominal-pos-eligibility.json](../pronto-nominal-pos-eligibility.json).

### Observed local POS gate: zero supported opportunities

The existing cached input frequencies reproduced all819,128 occurrences and
177,560 unique strings, including exactly86,788/1,402 direct-positive
opportunities. They contain38 distinct interior noun keys and772 distinct
subject–predicate key pairs. The cache hash was recorded at recovery; agreement
with the committed totals is a conservation check, not authentication of the
original cache producer.

A single slot-wrapped streaming pass used the same `ccgbankTrainFiles` sections
02–21 and `parseAuto`-accepted-line contract as the loader. POS counts come from
`leafHeaders` of accepted lines, category counts from `leafPairs` of parsed
annotation trees. No SemModel was built or English sentence parsed. Of2,000
candidate paths,1,875 were readable and125 missing; none unreadable or changed.
There were39,604 accepted annotation trees and zero rejected lines. These are
observations of the local readable snapshot, not corpus-wide absence proofs.

| POS policy class | Distinct noun keys | Weighted noun-token occurrences |
|---|---:|---:|
| No POS observations | 38 | 173,576 |
| Contrary JJ/JJR/JJS/NNP/NNPS observations | 0 | 0 |
| NN/NNS observed without contrary observations | 0 | 0 |
| Other POS only | 0 | 0 |

Both nouns are unknown in every one of the86,788 opportunities (1,402 unique
strings). Consequently **0 of the measured opportunities satisfies v1's
necessary positive NN/NNS condition in this snapshot**. This is a stronger
lexical diagnosis than the previous aggregate-only uncertainty, but it is not
a measured parser or fidelity rate. The keys also have no category attestations;
that does **not** show that N would be absent from offered tags, because the
supertagger can supply OOV-prior categories. Source-category offers/pruning,
seen pairs, lemma correctness, and chart survival remain unmeasured.
`actual_nominal_route_eligible` remains null in the result; the observed failure
of a necessary POS condition is reported separately and explicitly.

Lookup is exact literal case because both noun tokens follow other tokens.
There is no sentence-initial truecasing or invented lowercase lexicon. The
classifier uses all observed POS counts, so even one contrary adjective/name
observation would block noun support. The JSON count adapter narrowly normalizes
finite integral `JNum` values such as4.0; booleans, fractional weights, NaN and
infinity fail validation. Tests cover the actual emitted numeric format.

The [join tool](../pronto-nominal-pos-join.py) recovers frequency-linked keys
locally, seals source snapshots, validates evidence membership/conservation,
and emits only compact counts. The [bounded extractor](../../tools/ProntoNominalPOSEvidence.hs)
adapts the names worker's7d85eb1 accepted-line contract with an explicit target
keyfile. Per-key counts and the2,000-entry file manifest stay ignored. The
compact output records source commit, extractor/source/context digests, cache
and join digests, and training-file manifest digest. Scanner source was frozen
through the pass. Runtime4:41.37; peak RSS263,936KiB.

Reproduction, with local evidence under ignored runs (the corpus scan is a
separately authorized diagnostic and must use the shared lock):

```
python3 research/linguistics/pronto-nominal-pos-join.py recover \
  --cache /home/gram/nl2proof-astra/research/runs/linguistics/other-refresh/prontoqa-unique.jsonl \
  --output research/runs/pronto-pos-join/input-pairs.json
python3 research/linguistics/pronto-nominal-pos-join.py snapshot \
  --keys research/runs/pronto-pos-join/input-pairs.keys.txt \
  --extractor research/tools/ProntoNominalPOSEvidence.hs \
  --output research/runs/pronto-pos-join/scan-source-manifest.json
python3 /home/gram/nl2proof-astra/scripts/with-ccgbank-slot.py \
  runghc -isrc research/tools/ProntoNominalPOSEvidence.hs \
  /home/gram/ccgbank/ccgbank_1_1/data \
  research/runs/pronto-pos-join/input-pairs.keys.txt \
  research/runs/pronto-pos-join/training-manifest.jsonl \
  > research/runs/pronto-pos-join/lexical-evidence.json
python3 research/linguistics/pronto-nominal-pos-join.py join \
  --pairs research/runs/pronto-pos-join/input-pairs.json \
  --evidence research/runs/pronto-pos-join/lexical-evidence.json \
  --manifest research/runs/pronto-pos-join/training-manifest.jsonl \
  --extractor research/tools/ProntoNominalPOSEvidence.hs \
  --scan-sources research/runs/pronto-pos-join/scan-source-manifest.json \
  --scan-context research/runs/pronto-pos-join/scan-source-manifest.context.json \
  --output research/linguistics/pronto-nominal-pos-eligibility.json
```

Recorded initial-run context is named `scan-context.json`; the reproduction
command emits `scan-source-manifest.context.json`. Source commit/context digests
will change on a later checkout; counts are comparable only with the same input
and local training snapshot. No second corpus scan was run to test this recipe:
recovery and snapshot values were independently reproduced, and normal/python-O
joins over the saved evidence produced byte-identical compact results.

## What this implies for the next design decision

The initial generic capability is deliberately narrow, and the observed
unknown-POS condition blocks its Pronto surface opportunity in this snapshot. Its86,788
occurrences comprise only1,402 unique strings; a broad fidelity claim from that
number would be misleading. Named single positive nominal clauses have a larger
occurrence opportunity but depend on independently justified name admission.
Relative clauses have the largest unique-string opportunity, but require a
reviewed nominal VP/relative interface preserving restrictor scope. They cannot
be enabled by releasing Pending/Complete certificates as ordinary VPs.
Coordinated nominal consequents are a separate32,458-occurrence structural
extension with subject-wide property conjunction; mixed coordination and comma
lists need their own contract. The15,000-scale negative marginal mostly concerns
bare predicates, so nominal negation alone is not its general solution.

The single authorized frozen167-row preflight of candidate8e2a6ad found no
status or selected-meaning changes against its accepted baseline:49exact,
26wrong-but-typed,91no-parse,1incomplete. That fixture diagnostic is separate
from these population input counts and proves no lexical cause for the lack of
gain. The root still requires full integration gates and fresh fidelity. The
ProverQA construction gate remains closed; no model/benchmark launch is enabled.

For the compositional interpretation and primary-source comparison, see
[NOMINAL_ENVELOPE](NOMINAL_ENVELOPE.md): CCGbank source categories constrain
possible composition; Boxer2008 separates lexical/POS selection from category;
the pinned ccg2lambda equality copula cannot license arbitrary parser-produced
NPs. This count does not relax any of those semantic obligations.
