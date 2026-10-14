# Bounded lexical evidence for seven negative nominals

This is a completed diagnostic, not a semantic rule proposal or new parser run.
It explains necessary lexical admission gates in reviewed candidate17a17f9 using
an authorized streaming read of the exact observed training inputs. It does not
reconstruct chart search or infer lexical eligibility from a best supertag.

## Result: the Dave miss is a known-noun evidence barrier

For the stated initial-subject/truecase=True scenario, all seven effective forms
remain their written forms; every lowercase subject key has empty POS and tag
maps. These are complete selected-key aggregates over the observed loader
inputs, conditional on the missing-file boundary below.

| Frozen case | Subject unpruned POS; all observed categories | Noun unpruned POS; all observed categories | Proven necessary-gate result |
|---|---|---|---|
| pw-atom-nominal-neg-1 | Dave: NNP11; N5, N/N6 | ostrich: empty; empty | Name dictionary predicate passes; KnownNounsOnly complement predicate fails |
| pw-atom-nominal-neg-2 | Colin: NNP2; N1, N/N1 | bird: NN3; N/N3 | Both dictionary predicates pass; offered lexical N is a separate scored-category requirement |
| prover-transitive-nominal-3 | Nora: NNP6; N5, N/N1 | dancer: NN2; N2 | Both dictionary predicates pass |
| pronto-negative-1 | Sam: NNP26; N5, N/N21 | rompus: empty; empty | Name predicate passes; known-noun complement predicate fails |
| pronto-negative-2 | Polly: NNP12; N/N12 | dumpus: empty; empty | Name predicate passes; known-noun complement predicate fails; scored name category still independently required |
| prover-transitive-nominal-1 | Adalynn: empty; empty | libertarian: empty; empty | Name dictionary predicate fails under both noun policies; known-noun complement predicate also fails |
| prover-transitive-nominal-2 | Bodhi: empty; empty | environmentalist: NN1; N1 | Name dictionary predicate fails under both noun policies; noun dictionary predicate passes |

“Pass” means the unpruned necessary dictionary predicate on these inputs, not a
full nominal certificate. The first supported missing **admission** gate for
Dave is the common-noun evidence check, not a name, type or proven beam failure.
The same necessary noun gate fails for Sam/Polly. Adalynn/Bodhi fail the positive
name-evidence requirement; changing the noun policy cannot supply that evidence.
This identifies a code-level necessary blocker, not an observed original-tree
first divergence. It does not establish that a blocked case has no other
independent blockers.

Root's separately executed sealed trial is consistent: default yields only
Colin/Nora exact gains; optional ContextUnknownNouns also yields Dave/Sam/Polly;
Adalynn/Bodhi remain no_parse. The optional route admits an actually offered
lowercase lexical N with absent POS only in the certified complement context.
The current audit confirms its absent-POS precondition for ostrich/rompus/dumpus,
not every source/occurrence/beam condition. The root run, not this reader,
supplies evidence that complete exact readings were actually admitted.

In particular **bird has only N/N in the raw dictionary**, and **Polly only N/N**.
Do not conclude either fails actual offered-category admission: default smoothing
uses a global category prior. This reader deliberately builds no full prior,
SemModel or chart. The root's exact results do not tell this reader whether a
selected name used original NP or the lexical-N repair. Reconstructing a best
category alone would still not prove original selected provenance.

## Closed words and source-pair facts

Complete selected-word POS maps are: is `{NNS:2,VBZ:6891}`;
not `{RB:1287,RBR:1}`; a `{DT:19151,FW:7,LS:1,NNP:2,SYM:10}`;
an `{',':1,DT:3125}`. These are dictionary counts, not open-word admission rules
for closed lexical meanings. Local ignored output retains complete category
maps for all25 requested written/lowercase/noun/closed-word keys. To keep this
committed artifact compact, the following table reports only the four required
closed categories; it does not pretend they are the entire dictionaries.

| Written word | Required exact source category | Count |
|---|---|---:|
| is | `(S[dcl]\NP)/NP` |1676|
| not | `(S\NP)\(S\NP)` |743|
| a | `NP[nb]/N` |17469|
| an | `NP[nb]/N` |3031|

All four required feature-erased binary source pairs occur in accepted trees:

| Left | Right | Count |
|---|---|---:|
| `(S\NP)/NP` | `(S\NP)\(S\NP)` |2757|
| `NP/N` | `N` |91539|
| `(S\NP)/NP` | `NP` |38074|
| `NP` | `S\NP` |58664|

These counts exactly use the loader's recursive binary-node child categories,
with parseCCGCat and eraseFeatures; its smSeen uses membership, not counts.
Thus absence of those **global source pairs** is not a blocker on the observed
inputs. This is not proof that those categories survive offeredTags scoring for
a particular token, that the selected not is the actual closed entry, or that
its frame survives category/semantic chart beams. No bypass is licensed.

## Reproducibility and data boundary

Tool: [NominalNegationEvidence.hs](../../tools/NominalNegationEvidence.hs), adapted
from the previously reviewed bounded name reader. Twenty-one synthetic checks
passed before the one authorized read, including invalid-tree rejection,
original-line POS versus parsed-tree tags, case handling, rare contrary POS,
feature-erased source-pair collection and nested traversal. Only accepted
parseAuto lines contribute. The original-line leafHeaders behavior intentionally
matches the loader, including its accepted trailing-header quirk.

Run from the isolated worktree:

```
python3 /home/gram/nl2proof-astra/scripts/with-ccgbank-slot.py /usr/bin/time -v runghc -isrc research/tools/NominalNegationEvidence.hs /home/gram/ccgbank/ccgbank_1_1/data research/runs/nominal-negation-evidence/manifest.jsonl
```

stdout is the local evidence.json; stderr is timing.log. The shared wrapper used
the existing globalcap3. Elapsed6:22.34; peakRSS298240KiB, including runghc;
exit0. This does not authorize raising the global concurrency limit.

Read1875 files;125 candidate paths missing;0 unreadable/changed files;
39604 accepted trees;0 rejected lines;39604 skipped ID/blank lines. Ordered
2000 manifest paths/statuses/readable byte digests match BOTH before and after
manifests for each of root expanded190-baseline, expanded190-context-unknown and
nominal-negation-context-unknown. Readable files were hashed before and after
this scan as well. Status normalization is only readable→read; compare tuples
(path,status,sha256) in order and require length2000. All six comparisons pass.
Consequently these are exact dictionary aggregates for the observed loader
inputs, not a definitive absence/unopposed claim over missing files or English.

SHA256:

- Tool: `2e929098fcf520e73755c15be77b6407f6c5f53645ce9fb46e257abaf76a2956`
- Ordered manifest: `384ecf3d19fc6d43f0c738e752ef39eafc525343c21faeb4a42ce65af59607b8`
- Complete bounded local output: `807fd45454eebf09970bdcea283b61bf2f5bbd6215366b529f273c6278c8e36b`

Local manifests/output/timing/comparison remain ignored under
research/runs/nominal-negation-evidence and must be preserved before worktree
cleanup. No raw lines, trees, full lexicon or bulk closed-category maps are
committed. No parser/model/answer-benchmark run was launched by this worker.
The audit changes neither independent gold nor default noun/name policy. It
explains the preregistered default Dave prediction miss; it does not rewrite
that prediction as a success or count optional gains toward default coverage.
