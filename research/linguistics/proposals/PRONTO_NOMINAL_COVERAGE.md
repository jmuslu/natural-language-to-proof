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

## Lexical eligibility is a separate, presently unidentified intersection

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

The aggregate contains no token/profile join or dictionary counts. Consequently
all86,788 structurally matching occurrences remain **lexically unassessed** in
this audit. Dictionary-unknown, conflicting-POS, and fully licensed counts are
`null` in the [machine-readable result](../pronto-nominal-coverage.json), not
zero and not86,788. A lexical table without frequency-linked sentence membership
would still not identify the joint eligibility count. No rate is extrapolated
from a handful of sealed gold traces or from the generator vocabulary.

To resolve that next, an independently authorized input-only join must retain
subject/predicate token identities locally and intersect both with a sealed
lexical evidence snapshot from the same parser source/model configuration.
Emit aggregate exclusion counts only; separate unknown POS, conflicting POS,
missing source tags, morphology uncertainty, and missing source pairs. Predict
those diagnostics before running them. Do not turn dictionary availability into
a semantic-fidelity result or infer absence of a source category from a pruned
selected derivation alone. No such join/load was run for this proposal.

## What this implies for the next design decision

The initial generic capability is useful but deliberately narrow. Its86,788
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
