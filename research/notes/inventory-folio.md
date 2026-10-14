# FOLIO input inventory work log

2026-10-14 prediction before aggregate checks: the committed 120-item sample will
reproduce the earlier 744 input-unit occurrences and 439 unique strings. Regex
outer buckets will leave substantial unclassified material and overlapping cues
will reveal constructions outside generated copular/conditional templates. Neither
bucket membership nor a lexical cue certifies a semantic reading. Only context
premises, statement text and item IDs are used; labels and supplied formulas are
excluded from analysis. No parser, solver, answer benchmark or model is launched.

Result: prediction held. `python3 research/linguistics/inventory-folio.py`
recovered 120 items, 624 premise occurrences + 120 queries = 744 units and 439
unique strings. Outer buckets sum to 744; 238 occurrences / 137 unique strings
remain unclassified. Independently audited 22 selected exact exemplars with
source locators, whose counts are explicitly not family-wide frequencies.
The section documents false-positive cues (Boeing/gerund, printed text/passive,
only children/only) and remaining semantic annotation gaps. No raw data copied;
only compact authored examples and aggregate counts enter owned files.

Validation plan before final checks: script should compile, repeat deterministically,
and all 22 manually selected strings should occur in source. Root coordinator is
responsible for repository release gates before integration/push; this worker
runs only inventory/schema checks and does not launch parser/model experiments.

Final checks passed: `python3 -m py_compile research/linguistics/inventory-folio.py`;
second inventory run matched the first byte-for-byte with `cmp`. Every selected
exemplar exists and every outer bucket total is conserved. Integration dependency:
`research/linguistics/inventory-other.py` is preserved coordinator work and is
imported read-only; this commit does not stage or modify it.
