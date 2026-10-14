# Independent nominal name controls

Full-access shell and isolated worktree creation verified; base d6e9182. Frozen
nominal-v1 source8e2a6ad is read-only. Owned test, proposal and this note only.

Prediction before execution: six positive checks (NP/N repair, exact DRS,
all-reading identity and claim status) fail on v1 because its subject capability
admits overt universal subjects only. Sixteen boundary/preservation checks
should pass. Miniature dictionaries are independent fixtures, not CCGbank loads.
Ari with explicit NNP-only support is a schematic intended name, not a change to
actual unknown-name eligibility. Observed Abraham evidence informs the allowed
class but does not supply these expected meanings.

Reviewer approved lexicalChoices projection design for controls only; no source
implementation authorization. Must add typed-origin/packing/foreign occurrence
controls once the proposed API exists; do not simulate a production capability
with a separate Boolean implementation and call it integration coverage.

Executed against frozen8e2a6ad using:
```
runghc -i/home/gram/astra-wt/nominal-universal-trial/src -itest test/NominalNameControlsSpec.hs --boundaries
runghc -i/home/gram/astra-wt/nominal-universal-trial/src -itest test/NominalNameControlsSpec.hs --positive
```
Initial boundaries16/16passed; positives0/6passed (expected six reds).
Added explicit ordinary named-object and NP[expl] preservation controls;
final boundaries18/18passed. No production source changed; frozen worktree
status remains clean. Tests use only tiny hand-built dictionaries. They remain
unregistered and default includes reds. Source-specific foreign-origin/packing
controls are explicitly pending the typed API, not reported as tested.

Concrete private lexicalChoices projection and NominalRole NamedSubject /
Complete typed-subject-origin API is documented for review. Public lexicalSigns
can remain a projection; do not add optional provenance to every general sign.
CapturedNproperty, noQinversion and fullroot obligations retained.

## Dependent implementation start

Parent authorized isolated source implementation after frozen v2 a4846ca review,
conditional on v2 passing root trial. Synced current accepted research and merged
that explicit dependency (d66f3d7); sole conflict was imports, resolved by union
of existing isSuffixOf and v2 isAlpha/isLower. No dependency source semantics
changed. Existing public positive controls rerun before source:0/6 pass as
predicted. New NominalNameOriginSpec drafted first: it intentionally fails to
compile until the typed API exists; this is not counted as an executed red
semantic test. Source/packing/occurrence attacks must then run using an origin
recovered from actual lexical/chart construction.

Implemented isolated candidate in CCGSemParse only. Reviewer accepted separate
NominalNamedComplete variant to avoid another v2 universal type migration;
new named subject/completion carry actual lexical origin and same mandatory
root/period guards. Public lexicalSigns is unchanged projection of branch-
preserving lexicalChoices. Optional capability minted only immediately before
an actual licensed nominal pair. Complete dictionary evidence, sourcecategory,
NP[nb] feature, Nrepair step and occurrence are retained; no full-model hash.
No unknown-name exception, Q inversion, equative fallback or default noun-policy
change. Explicit assumption note is added only on nominal subject discharge.

Focused results:27/27 public controls (formerly six reds) and46/46 actual-origin
checks pass. First origin suite had37/38 pass: test mistakenly required both
same-meaning source alternatives to survive final roots. Existing public root
contract deduplicates by meaning only after all mandatory guards. Corrected
that test to recover actual origins from separate NP-only/N-only parses,
assert two distinct packCell entries despite equal terms/notes, and separately
assert unchanged one-root final dedup. No source change made to hide failure.

192 public lexicalSigns snapshots before/after are byte-identical across4 source
categories×4 POS scenarios×2 positions×6 tokens (category/item/notes/score/order).
The owned public test now supports --lexical-snapshot to reproduce this audit.
Initial snapshots retained at /tmp/name-lexical-before.txt and -after.txt; source
baseline d66f3d7. No raw data. Source/packing checks use actual minted origins,
then adversarially altered copies, not pretend certificates minted by tests.

Final local validation:
- `cabal test all --offline --test-show-details=failures`:25 registered suites
  pass, exit0. No cabal edits by this worker.
- `runghc -isrc -itest test/NominalOpenNounV2Spec.hs`:58/58pass; included
  separately because the frozen dependency's suite is not yet registered here.
- Named public controls27/27; actual-origin attacks46/46.
- Final --lexical-snapshot still byte-identical to baseline; before/after SHA256:
  028bb8cf98560e879e4edc8ade996df083176263070f44e91f2d8c8f60d8b4c2
- git diff --check clean. No corpus/model/benchmark loads; all fixtures synthetic.

Reviewer approved live concrete source contingent on this final validation and
root merged trial. Local ignored evidence copied to research/runs/nominal-name-
controls/ (actual directory name has no line break). Coordinator must preserve
that directory before worktree removal, land v2 first, register new standalone
suites, and run fresh fidelity/Explain/source-hash and remaining gates. No
corpus gain is claimed and no push from this worker.
