# ProntoQA inventory audit notes

2026-10-14 — Prediction before aggregate check: the 80 extracted JSON files will reproduce 819,128 sentence occurrences and 177,560 unique strings, including demonstrations (not just test questions). A stricter anchored template recognizer should leave few or no unmatched strings, but will split the old subject-copula family into single clauses and sentence coordination. Joint profiles must distinguish restriction coordination from consequent coordination. The previous passive-candidate feature may be a suffix false positive for predicative adjectives; no passive meaning may be inferred from it. No parser, model or answer benchmark will run.

Plan: inspect both JSON schemas without reading labels/proofs; inspect pinned upstream syntax-generation code; classify only presented theory/query fields; verify record/role/family/profile conservation; audit residuals and report ambiguity instead of treating a surface match as meaning fidelity.

Source inspected: asaparov/prontoqa commit `0a6412b6fddf46324a1cb96e066dd7b3d89b87d6`, `syntax.py` and `run_experiment.py`, fetched read-only to `/tmp/prontoqa-generator-review`. Generator source was not executed. Local archives will be checked for duplication against extracted files without counting them twice.

First result: predicted totals reproduced exactly (80 files; 65,600 records; 819,128 occurrences; 177,560 unique). All anchored surface templates matched, with 5,516 sentence-coordination cases separated from 266,759 single named clauses. All 79 archive JSON members are byte-identical to extracted copies, so the archive adds no new inputs. There are 47 full joint profiles and 18 operator-only joint profiles. Prediction before second check: correcting comma-location bookkeeping and caching repeated surfaces will leave all family totals unchanged; the old 22,143 passive-candidate sentences will involve adjectival words from the inspected property vocabulary, rather than passive templates. Authored template controls will check nested connective location and reject out-of-grammar strings.

Restart completion: full-access shell verified on `astra/inventory-prontoqa`.
The documented second check ran as
`python3 research/linguistics/inventory-prontoqa.py --data /home/gram/data/prontoqa --output research/linguistics/prontoqa-inventory.json`.
It passed authored controls and conservation checks, reproduced all five family
counts and zero unmatched, and retained47 full joint profiles. Passive suffix
counts were exactly wooden7392/red7394/muffled7357, totaling22143, matching the
inspected generator property list; prediction held. Delivered section and compact
aggregate with file hashes; no raw samples, models, benchmark answers, or corpus
loads. Before commit, prediction: JSON profile and role conservation independently
recompute the reported totals, and only four owned paths enter the commit.
Validation outcome: independent recomputation passed total, unique, role,
file-hash-count and suffix conservation; authored controls passed. Staged diff
check passed and staged names are exactly the four owned artifacts. Haskell and
fidelity gates remain coordinator integration responsibilities; no semantic code
changed on this branch. Unrelated transferred dirty work remains unstaged.
