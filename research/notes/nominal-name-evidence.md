# Nominal name evidence audit

Full-access pwd and git worktree creation succeeded. Created
/home/gram/astra-wt/nominal-name-evidence, astra/nominal-name-evidence from
astra/research 990760f. Frozen token-boundaries and nominal-name-licensing
worktrees untouched. Own compact proposal and this note only.

Read-only checks: inspected existing expanded-gold167 explain.log and
lexical-alternatives.log, positive-nominals-baseline/report.observations.jsonl,
source POS/load/name interfaces, and filename search for cached POS/lexical
models. No raw corpus read, parser/model load or benchmark execution.

Sealed root artifact SHA256:
- expanded-gold167/explain.log:
  d3e7214f71d8ab76dec900fc76f3e5062caf9ca1d63b886c6aa9e28ae83fe4c6
- expanded-gold167/lexical-alternatives.log:
  8697b32ee6a7ec1c293b0f6f41b0a0ba9edbadbcf3010b0b285bbda4c456a7ab
- positive-nominals-baseline/report.observations.jsonl:
  f16f5e7d74dc6fa6fb4e0b5aae6b76515faead2f502789405a3fd6ae42aba2f9

Reproduce selected evidence with rg on these existing files for Abraham,
Alyssa, Amiyah; ordinary Explain first entries at lines 5,20,35; all-readings
entries Abraham line5 and Amiyah line67. No all-readings Alyssa input. These
are category summaries, not POS counts. Eligibility UNKNOWN for all3.

Proposed next step: bounded six-key evidence export on an independently
approved existing model load, or separately reviewed exact streaming extractor.
Need actual full counts, tag membership/effective lookup, model identity.
Typed origin must be minted beside nameItem construction, not inferred from
note strings, term shape, or a bare ProvLex. No production change authorized by
this note. Corpus-free structural controls specified in proposal, not run.

## Authorized bounded streaming follow-up (prediction before dataset read)

Owner/root now authorizes training-file reads for a six-key evidence audit.
Extractor imports actual ccgbankTrainFiles, parseAuto, leafHeaders and leafPairs;
no SemModel is built. The loader uses sections02–21, candidate2000 filenames,
skipping unreadable files and rejected trees. Export.hs and Explain use default
truecase=True; POS backoff does not change these dictionary counts.

Prediction: unknown/unseen support is plausible for these supplied names, and
an NP display alone cannot predict NNP evidence. Therefore no guaranteed passes
are predicted. Synthetic equivalence controls must pass before corpus scanning.
Expected accepted-tree total from sealed logs:39604; mismatch triggers a
manifest/partition investigation, not a silently declared equivalence.

Reviewer requested ordered paths and byte digests, unreadable/rejected counts,
and no definitive complete-corpus absence/unopposed claim when inputs are
missing. The extractor records all candidate paths with status, hashes readable
files before/after scanning, and emits only six-key aggregates. Actual runtime
lexical origin and full clause eligibility remain outside the evidence audit.

16 synthetic checks passed before reading training files. Started the first
bounded scan, then stopped its exact process on receipt of root's new shared
slot requirement; discarded partial evidence and restarted using:
```
python3 scripts/with-ccgbank-slot.py /usr/bin/time -v runghc -isrc research/tools/NominalNameEvidence.hs /home/gram/ccgbank/ccgbank_1_1/data research/runs/nominal-name-evidence/manifest.jsonl
```
The run's stdout/stderr are locally retained as evidence.json/timing.log.
This parses annotated AUTO tree syntax to reproduce loader acceptance, not
English chart parsing or model construction. Manifest and timing remain local;
only compact selected evidence and tool source will be committed.

## Completed result

Completed wrapper run exited0 in4:36.43; peakRSS263680KiB (includes runghc).
1875 files read;125 missing candidatepaths;0unreadable/changed;39604accepted
AUTO trees,0rejected lines,39604skippedID/blank lines. Exact tree total matches
prior sealed model. Missing paths are recorded rather than silently called a
complete licensed-corpus inventory; all conclusions conditional on observed
loader inputs, not all possible corpus files or all English usage.

Unpruned compact evidence:
- Abraham: NNP4; categories N2 and N/N2; lowercase key has no POS/tags.
- Alyssa: no POS/tags; lowercase key has no POS/tags.
- Amiyah: no POS/tags; lowercase key has no POS/tags.

For stipulated initial=True/truecase=True (source defaults), effective keys are
unchanged. c77ad00 dictionary predicate is True/False/False respectively on
observed inputs. Source nameStatus therefore dictionaryNameOnly for Abraham,
initialNameOrOther for Alyssa/Amiyah. This is not actual runtime origin or full
clause admission; no production source implemented and no new fidelity score.

Reproducibility SHA256:
- research/tools/NominalNameEvidence.hs:
  027eb15d045282433454f4a6e048a1ee34c5e31b2adb2221909da5af6b8cda53
- ordered local manifest.jsonl (2000 candidate path/status records, readable
  file digests checked before and after scan):
  384ecf3d19fc6d43f0c738e752ef39eafc525343c21faeb4a42ce65af59607b8
- local evidence.json:
  f8a04e7d2d089fa94abb3353d8dcb41d1e968ce39f397f78109ef3666c65db7c

Reviewer approved live extractor logic before completion; final results sent
for acknowledgement. Full model is never built. For tests run:
`runghc -isrc research/tools/NominalNameEvidence.hs --self-test`.
Only explicit tool/proposal/notes paths are staged; manifest/rawdata stay out
of git. Shared slot released; Pronto worker notified for their queued audit.
