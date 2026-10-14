# Either execution protocol design

Full-access shell verified; isolated astra/either-protocol-plan from579db46.
Own proposal/notes and independent synthetic test only. Source inspected read-only
for existing v1 execution validation and replay; no parser/corpus/model loads.

Prediction before checks:11 tests total;8 backward-compatibility/rejection checks
pass.3 feature-positive tests remain red (v2 validator, v2 replay, mocked enabled
CLI). Some negative passes are currently only unknown-v2 rejection, not evidence
of implemented v2 semantics; this limitation must remain explicit after review.
No source/gold/default190 change. No gold contract may select the runtime option.

Standalone run:11 tests,8 pass and3 expected red feature tests (5 error reports
because two tests cover both v2 modes). Positive v2 validation/replay fail unknown
schema; enabled mocked driver fails unrecognized option. No output comparison
or source change was made. v1 backward-compatible paths remain green. Protocol
proposal explicitly distinguishes unknown-schema negative passes from genuine
implemented paired-mode integrity, and requires normal/python-O plus actual
exporter tests after implementation. Diff check clean.
