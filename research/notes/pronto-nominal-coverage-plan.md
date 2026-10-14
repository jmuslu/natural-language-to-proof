# Pronto nominal v1 structural opportunity audit

2026-10-14. Full-access shell verified; isolated astra/pronto-nominal-coverage-plan
created from research990760f. Frozen nominal8e2a6ad and its preflight evidence
untouched. Read STATE then GOAL. No source edits, raw-input reread, corpus/model
loads, or benchmark launch.

Prediction before the new aggregate script/check: the committed anchored
inventory's exact joint profile universal_every_each + sole feature
consequent_article_predication is the entire surface opportunity for nominal v1.
Initial input inspection already showed86788 occurrences/1402unique in that
profile; this is a reproduction prediction, not an unseen estimate. New
aggregation should conserve819128occurrences/177560unique, exclude all other
outer families, and separate nonpositive/coordinated/bare consequents inside
the universal family. Lexical unknown/conflict eligibility cannot be counted
from these joint profiles because they do not retain token-to-profile/POS joins.
Do not label unassessed tokens as dictionary-unknown or claim parser coverage.

Own outputs: research/linguistics/pronto-nominal-coverage.py, compact
pronto-nominal-coverage.json, proposals/PRONTO_NOMINAL_COVERAGE.md, this note.
Only committed aggregate inventory plus its anchored classifier definition are
used for population counts. Sealed preflight is a separate fixture diagnostic.

Result: conserved819128occurrences/177560unique across47profiles. Exact surface
opportunity86788/1402 as predicted. Other Every/Each partitions: bare33813/2316,
nominal coordination32458/9295, mixed coordination17816/15828, negative14551/2037.
Other outer families all remain structurally excluded by v1. Positive single
article consequents in named109245/153 and relative174874/78626 families do not
imply subject/embedding eligibility. No token/profile/POS join exists in the
aggregate; lexical unknown/conflict/fully licensed counts explicitly null.

Validation planned before commit: reproduce output byte-for-byte, run the same
conservation and fail-closed controls under python -O, check document links and
explicit owned staging; request independent reviewer. Sourcefrozen nominal v1
and its167 preflight remain untouched. No parser was run for this task.

Validation outcome: normal and python -O aggregate runs produced byte-identical
JSON; conservation and authored fail-closed controls passed in both modes.
All local proposal links resolve and git diff --check passed. Explicit staging
included only the four owned artifacts. Independent review requested on3a1e472;
no approval is inferred while that review is pending.

## Authorized POS eligibility join: prediction before extraction

Owner/coordinator next task authorizes a bounded lexical-evidence join, no
parser/model launch. Shell verified again; nominal8e2a6ad and preflight frozen.
Existing ignored other-refresh/prontoqa-unique.jsonl has input text plus counts;
expect it to reproduce819128/177560 and the86788/1402 direct-positive joint
profile. Fail closed on any mismatch rather than mix inventory generations.
Recover both exact interior noun keys and frequency-linked pairs locally;
interior tokens use their literal case, with no sentence-initial truecasing.

Prediction before examining dictionary counts: synthetic Pronto nouns may have
no training POS evidence, so structural opportunity is expected to overstate
POS eligibility. Unknown and contrary JJ*/NNP* evidence must be separate; do
not guess which dominates or infer absent lexical N from missing POS alone.
Coordinate one streaming exact-parseAuto training-leaf extractor with names
worker under shared two-slot lock. Store per-word/source join evidence ignored;
commit only reproducible aggregate tool, compact counts, and notes/proposal.
This measures necessary POS-policy eligibility, not offered/pruned source tags,
seen-pairs, morphology correctness, chart survival, or fidelity.

Cache recovery passed before corpus scan:177560unique/819128occurrences and
1402unique/86788opportunity occurrences;38exact interior noun keys,772 noun
pairs. Cache SHA2560aa9be97707dd54e5647c780d6d4bf0db32002b62d178faf84b59931b747b62d.
Names worker finished its pass before ours began. The bounded adapter preserves
its exact parseAuto accepted-line/leafHeaders/leafPairs behavior and imports the
same ccgbankTrainFiles partition. Six synthetic extraction controls passed.
Names helper source7d85eb1, SHA256027eb15d045282433454f4a6e048a1ee34c5e31b2adb2221909da5af6b8cda53.

Reviewer approved local observed-snapshot interpretation before results, with
125 missing candidate paths kept explicit and actual route eligibility null.
Reviewer also caught JNum serialization as integral floats. Before interpreting
snapshot output, added narrow finite-integral normalization (booleans,
fractional values, NaN and infinity rejected), plus actual4.0/1.0 rendered JSON
fixture checks; normal and python -O self-checks pass. Scanner source untouched.

Final observed snapshot:1875read/125missing/0unreadable-or-changed training
candidates;39604accepted annotation trees/0rejected, matching names pass counts.
All38 requested interior keys have empty POS and category tables. All86788
opportunity occurrences/1402unique are unknown/unknown;173576 weighted noun
slots unknown; zero contrary-POS keys, zero known-noun-supported keys. Reviewer
approved wording before final prose:0 measured opportunities satisfies v1's
necessary POS condition in this snapshot. No actual parse/fidelity rate or v2
gain inferred; OOVprior may still offer N even without N attestations.

Streaming runtime4:41.37, peak RSS263936KiB; sharedslot released. No SemModel
built and no English sentence parser/model/answerbenchmark invoked. Normal and
python-O joins over saved evidence are byte-identical. Independent snapshot
command reproduced pre-scan source/context values; all recorded source hashes
still agree. Private evidence research/runs/pronto-pos-join/ includes input-pairs,
keys, lexical-evidence, training-manifest, scan-source-manifest, scan-context,
scan.log and join logs. Only compact output and reproducibility code are staged.
