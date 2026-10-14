# Independent local reflexive gold — 2026-10-14

Prediction before checks: seven manually specified cases should pass the fixture
schema and reference checks; input-only source lookups should confirm every
benchmark adaptation anchor. No prediction of parser performance is made, and
no parser, Explain, model, corpus load or answer benchmark will run here.

Inputs inspected: coordinator's ignored ProverQA unique-input cache and read-only
ProofWriter sentence inventory SQLite database. No answer labels, symbolic
benchmark proofs, parser output or existing reflexive observations were consulted
to derive these expectations. Author had previously diagnosed the family from
Explain; this task's expected meanings are independently specified from English
local binding, not copied from those outputs.

Seven fixtures cover three named direct-object cases, two universal-local cases,
and two explicitly authored scope neighbors. Reflexive surface forms remain in
every sentence. Binary predicates put subject first and object second, both the
same constant or antecedent-bound reference. Universal atoms are Embedded, only
the implication Asserted. Negated atom is Embedded, only negation Asserted.
The distraction control keeps two asserted main-clause atoms; prior Anne must
not become the object of Amara's defense. It is not a benchmark sample row.

Only Amara's positive sentence is unaltered input. Muffin is a clause extraction;
Dave drops a result adjective and unrelated conjuncts (a deliberately simplified
binding diagnostic, not meaning preservation of the whole source). Quantified
cases substitute an explicit every-subject for the original conditional or
relative-clause frame to isolate local binding; they are benchmark-adapted,
not exact benchmark population measurements. Source coordinates and each edit
are in the rows. Three named and two quantified cases meet the two-to-three
contrasts request; the extra controls separately test discourse distraction and
negative scope. Representation: direct relational, tense-abstracted fragment;
no predicate `himself`, no fresh reflexive referent, no equality-only surrogate.

Limits: inventory cue counts are not seven-case coverage claims. The Prover
input cache has 116 rows matching the four searched reflexive spellings, not an
independent remeasurement of the inventory's 117 all-reflexive cue count. No
ProofWriter 1564 count was recomputed. Idiomatic express oneself, stand up for
oneself, intensifiers, reciprocal/mutual readings, PP reflexives, gender inference
from names, plural collective antecedents, logophoric exceptions, aspect and
resultatives are deliberately not assigned gold here. Their original inventory
failures remain required work; fixture omission must not shrink a benchmark gate
denominator. Reviewer must check this gold before any proposed binding rule.

Checks completed: `validate_case` accepted all seven explicit DRS/claim fixtures.
Read-only coordinate checks confirmed all five benchmark-adapted source anchors
against the unique-input JSONL/SQLite cache, including Dave's source resultative.
Two controls are expressly authored. `git diff --check` passed. Prediction held;
no parser observation or correctness rate was generated. Coordinator owns
integration gates and benchmark-wide fidelity reporting.

## Reviewed fixture baseline measurement

Coordinator subsequently authorized measuring reviewer-approved commit dde1bea
with the frozen production exporter. Full-access shell verification succeeded;
worktree was clean before recording this prediction. Prediction before execution:
zero exact cases are expected because the frozen parser has no reviewed local
reflexive binding rule. Some inputs may fail to parse; any typed reflexive noun
or separately quantified object reading should be wrong-but-typed. This is a
seven-case construction diagnostic, not an answer benchmark or population gate.
Gold is frozen and will not be edited in response to observed outputs.

Command (shared memory-token wrapper encloses the complete runner):

```
python3 /home/gram/nl2proof-astra/scripts/with-ccgbank-slot.py python3 test/fidelity/run.py --cases test/fidelity/reflexives.jsonl --binary /home/gram/nl2proof-astra/research/runs/integration-fidelity/fidelity-frozen --parser default --output research/runs/reflexive-baseline/report.json
```

Result: **0 exact / 7 wrong-but-typed / 0 no-parse**, with no type failures,
incomplete documents or observation errors. Named local: 0/3 exact; quantified
local: 0/2; scope controls: 0/2. None of the six single-sentence cases has an
exact returned alternative; the two-sentence distraction control has no
sentence-only alternative score. Frozen process completed normally in 83.88s
(excluding token wait). The zero-exact prediction held, and all failures were
typed rather than parse failures.

Selected first divergences from the saved observations:

| Cases | First structural difference | Observed meaning error |
| --- | --- | --- |
| named 1–3 | `drs.conditions[0].tag`: expected pred, observed imp | Reflexive becomes noun predicate restricting a new universally quantified object; e.g. forall y(herself(y) -> defend(Amara,y)) |
| quantified 1–2 | `drs.conditions[0].right.conditions[0].tag`: pred versus imp | Correct outer cat/hedgehog universal encloses a second itself-restricted universal, rather than reusing its subject witness |
| distraction | `drs.conditions[1].tag`: pred versus imp | Anne's preceding red atom is preserved, but the Amara clause still quantifies a new herself object |
| negated | `drs.conditions[0].body.conditions[0].tag`: pred versus imp | Negation encloses the erroneous herself implication, instead of the diagonal defend atom |

These are output-level first differences. The exporter does not provide lexical
Explain traces; the common shape is consistent with the independently diagnosed
noun-to-generic-NP route, but this run alone does not prove its derivation.
Claim tables faithfully classify the wrong structures: implication or negation
is Asserted and its internal atoms Embedded. Local binding must be repaired
before DRS/claim splitting, not patched by promoting an embedded atom.

Sealed artifacts remain ignored in this worktree at
`research/runs/reflexive-baseline/report.json`, `.observations.jsonl`, and
`.stderr.log`. Exporter SHA256:
`5b3f5e9fe4fbe58928bd6d43facc8657cf344c80a55fd06afc8b79f27dc7f035`.
Unmodified gold SHA256:
`2de153a9cf8d5a200f2e8c1ab186e11d0588143086ee4dbf28d17f20f44b582e`.
Source hashes recorded by the runner describe the worktree at observation time,
not necessarily the frozen executable's build; executable identity is the hash
above. No gold or production behavior changed after observing these failures.

## Test-first local-binding implementation proposal

Assigned proposal/test paths only; no production edits or gold changes. Before
running the standalone miniature parser contract, prediction: it compiles against
current APIs and reports failing production reflexive checks, since the reviewed
rule is absent. Tests use only authored miniature tags, never licensed CCGbank.
Command: `runghc -isrc -itest test/ReflexiveProposalSpec.hs`.

Result: standalone test compiled and ran without corpus loading; 3/13 checks
passed and 10 failed, as expected for absent local-binding support. Existing
NP[expl], NP[thr] and PP fallback checks already fail closed; N/N and verbal
category reflexive readings do not. Positive named/quantified/negated/distraction
checks and closed-entry/reservation checks fail. This is a deliberately red
proposal test, not a registered release suite or completed repair. Reviewed gold
unchanged. A first proposal write encountered an absent directory; created the
owned proposals directory and wrote the complete proposal successfully. No
shared production path or cabal file changed. Reviewer must resolve the lexical
transitive locality gate before root implements.
