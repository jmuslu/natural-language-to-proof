# ProverQA occurrence strata

Full-access shell verified in isolated astra/prover-occurrence-strata. Own only
counting script, compact aggregate and this note. No sampling draw or parser,
benchmark or model launch. Read STATE first, then GOAL and acceptance proposal
29c6524. Only context/question fields select frame members; labels/proofs are
never consulted. Whole-file SHA256 is an opaque source identity, not label use.

Prediction before counting: easy theory2029/question500; medium theory4867/question500;
hard theory8949/question500. Sum17345, theory15845/question1500;17285 global surfaces.
Derived from prior published per-file totals minus500 questions, not measured
stratified results. Preserve the exact inventory-other.py splitter and strip_query
convention; question is one occurrence even if it contains internal punctuation.
Question maps to the earlier query role. Repeated text remains repeated population
membership; unique counts are supplementary only. No improved segmentation claim.

Script compares reconstructed record/file/role/total/unique/outer-family counts
against other-counts.json and reports mismatches with nonzero exit; never forces
agreement. Six strata exist even when empty; zero-based physical record indices
preserve repeats independently of any dataset ID. Canonical input projection and
ordered frame hashes permit reproduction without committing text/locators in bulk.

Observed six-stratum counts match the prediction exactly. Aggregate is5227bytes;
17345 occurrences,17285 global surfaces,60 duplicate excess. All seven baseline
comparisons match. Independently reran inventory-proverqa.py --root on the same
original inputs: file totals, role totals, total/unique and complete exclusive
outer-family distribution match the new aggregation. The same splitter is reused
intentionally, so this is accounting reconciliation, not independent validation
of segmentation semantics.

Validation: synthetic duplicate rows produce6 occurrences/3 surfaces, theory4 and
question2, with the four absent strata zero. Dr. abbreviation remains intact under
existing splitter. Changed answer metadata changes opaque file hash but leaves
projected-input/frame hashes invariant. A multi-sentence question remains one
question occurrence. Reference mismatch is reported, not forced to match. A second
real input run yields byte-identical aggregate. `git diff --check` passes.

Reproduce from repository root:

```sh
python3 research/linguistics/inventory-proverqa-strata.py --root /home/gram/data/proverqa --output research/linguistics/proverqa-strata-counts.json
```

No draw, inclusion probabilities, sample outcomes or acceptance conclusion are
claimed. N_h is original physical occurrence membership, not unique-surface count.
The6 strata alone do not establish complete semantic-family recovery. Source file
identifiers are only the three aggregate paths; no bulk sentence/record locators
or raw text appear in the committed aggregate.
