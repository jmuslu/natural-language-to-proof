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
