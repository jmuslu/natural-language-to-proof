# Independent names/N/NP review

2026-10-14. Scope: documentation only; shared source remains untouched.
Read lexicalSigns/nameStatus/lookupForm, nameItem/unarySem, the existing
NameSemSpec controls, existing NAMES observations and fidelity gold, and the
pinned local ccg2lambda 2015 NNP rule. Boxer comparison uses the recorded primary
source reading in REFERENCES; no claim to have run either external system.

Prediction before focused validation: the existing bounded repair and trace
correction preserve all 30 hand-dictionary checks. Command:

```
runghc -isrc -itest test/NameSemSpec.hs
```

This does not load CCGbank or launch a benchmark/model. No new mirrored tests
are warranted: the existing controls already cover category features, casing,
rigid identity, embedded negation and actual trace alternatives. Legend remains
a documented unresolved interpretation even if this regression suite passes.

Result: 30/30 checks passed on the transferred repair, exit 0. Shell execution
works under the resumed permissions; no sandbox failure occurred. The branch
base is fe5bf33, with the needed source/test repair copied as uncommitted inputs;
those inputs are deliberately excluded from this specialist's commit. Root's
d88b1e5 is the separately gated source handoff.

Added explicit gold links for Cruz/Ali copular facts and the rigid Legend
requirement inside disjunction, and distinguished the unit checks from corpus
exact/wrong-but-typed/no-parse scoring. Re-read the pinned local ccg2lambda YAML
NNP rule and lexicalSigns/nameStatus directly. No CCGbank load or model/benchmark
run occurred. Coordinator/reviewer must validate the integrated result and run
release gates; this documentation branch claims no release or fidelity threshold.
