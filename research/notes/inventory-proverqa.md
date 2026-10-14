# ProverQA inventory notes

2026-10-14. Prediction before measurement: previously recovered outer-family totals
will reproduce (17,345 occurrences; 17,285 unique). Initial conditionals will
contain many disjunction/exclusion cues. Most residual sentences will look like
single names followed by inflected lexical verbs, but token shapes cannot establish
semantic coverage. This is a surface audit, not a parser/solver benchmark.

Command (stream the existing unique-text cache, retaining no raw sentences):

```
python3 research/linguistics/inventory-proverqa.py --cache /home/gram/nl2proof-astra/research/runs/linguistics/other-refresh/proverqa-unique.jsonl
```

The cache is read-only; counts preserve occurrence multiplicities. Role totals
cannot be reconstructed from its representative first-role field, so those totals
must be taken from the original aggregate inventory, not inferred from this run.

Result: the command exited 0 and reproduced 17,345/17,285 and all outer-family
counts. Initial-if sentences contain 2,836 explicit `not both` cues, 302 `or both`
cues, and 5,160 subject-pronoun cues. Residual shape buckets were 3,602 / 22 / 167;
prediction held at the surface level, but these remain semantically unclassified.
A read-only inspection of the first 15 residual `other` examples identified
possessive subjects, titled names, abbreviations, coordination and lexical verbs.
No extra construction-coverage claim follows from that nonrandom inspection.

The section distinguishes generic indefinites, nonexclusive language, candidate
particles and unresolved lexical frames. This is documentation/inventory only;
root owns full release gates before any push. No parser corpus load occurred.
