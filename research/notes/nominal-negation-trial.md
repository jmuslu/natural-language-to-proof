# Nominal-negation trial preregistration

Written before observing candidate17a17f9 on frozen190. Full-access pwd verified
in nominal-negation-plan; source and prior candidate unchanged. This note uses
only frozen fixtures, sealed observations/reports and source inspection: no
parser, model, benchmark or CCGbank load. Candidate source is
`17a17f9f162285c23931e7846482e05c705edce0`; CCGSemParse SHA256
`0a42c458278817b3d0bb2d4a7f8dbfd961a6b5415eecd4984f10c82c5ea77a3b`.

## Fixed evidence and comparisons

Use the exact190 cases,188 distinct texts, SHA256
`ee8f3aef38b6925cc626da95d2bf65e6b3a7eb9baa342a5d021ca9cc8c23e564`,
from root `research/runs/expanded190-preparation/cases.jsonl`. Do not expand or
rewrite gold after observations. The preparation manifest's observed:false is
its historical freeze-time state, not a claim that baseline190 remains unseen.

Existing same-binary paired-policy reports are:

| Root run directory | Policy | Exact / wrong / no-parse / incomplete | fresh.json SHA256 |
|---|---|---|---|
| expanded190-baseline | known-only |63 /32 /94 /1|a217247ae706fc4da84f6576b3bde1558fb521f36176e82060b0da4506a58fc9|
| expanded190-context-unknown | context-unknown |68 /32 /89 /1|c87c38ac60a875df59e49f24450183a56897296f7eb15a91126f824aa7312fbf|

Compare candidate known-only to known-only, optional candidate context-unknown
to context-unknown. The existing five policy gains are not gains from nominal
negation. If another source rule lands before this serial trial, first preserve
a same-gold pre-candidate baseline for that source and both measured policies;
report any intervening changes separately. The optional run needs explicit
execution-policy binding in request, response, report and replay, never an
inferred flag. Mixed-contract190 totals are diagnostic, not acceptance-panel
certification or the representative ProverQA gate.

## Exact target IDs and predictions

All seven simple target cases below are no_parse under both sealed policies.
The implementation admits only an actual certified name, the exact is/not/a-an
frame, the appropriate source pairs, and an admissible lexical noun. The table
is a falsifiable **prediction**, not a completed dictionary or chart audit.
No complete unpruned written/effective/lowercase POS evidence for these seven
subjects is present in the inspected caches. A best NP/name tag (including
Nora in an older unrelated Explain example) does not establish that evidence.

| Frozen ID | Text | Default known-only prediction | Optional context-unknown prediction |
|---|---|---|---|
| pw-atom-nominal-neg-1 | Dave is not an ostrich. | provisional no→exact target | same target |
| pw-atom-nominal-neg-2 | Colin is not a bird. | provisional no→exact target | same target |
| prover-transitive-nominal-3 | Nora is not a dancer. | provisional no→exact target | same target |
| pronto-negative-1 | Sam is not a rompus. | remain no_parse: invented noun has no demonstrated dictionary license | additional provisional no→exact target, only if actual name/source checks pass |
| pronto-negative-2 | Polly is not a dumpus. | remain no_parse: invented noun has no demonstrated dictionary license | additional provisional no→exact target, only if actual name/source checks pass |
| prover-transitive-nominal-1 | Adalynn is not a libertarian. | conservatively predict no_parse; attested-name eligibility unknown | same; optional nouns cannot license an unknown name |
| prover-transitive-nominal-2 | Bodhi is not an environmentalist. | conservatively predict no_parse; attested-name eligibility unknown | same; optional nouns cannot license an unknown name |

Thus the working change-ID hypothesis is default
`{pw-atom-nominal-neg-1,pw-atom-nominal-neg-2,prover-transitive-nominal-3}`;
optional additionally `{pronto-negative-1,pronto-negative-2}`. This is not a
promised3/5 gain or verified eligibility set. Zero gains is compatible with
unmet lexical/category/seen-pair/beam gates; explain the first remaining gate
rather than relaxing it. Conversely an exact gain for Adalynn/Bodhi is a
prediction miss to audit against actual attested evidence, not by itself a
semantic failure. Complete unopposed POS/source evidence must support it.

The frozen set contains **no direct Every/Each N is not a/an N** example.
Universal nominal-negation scope therefore gets no190 coverage credit. Keep the
independent48 semantic/boundary/operator and71 actual-origin controls, including
all-retained readings under both policies; do not silently append their authored
sentences to the frozen denominator. Existing synthetic universal expectations
are `∀x(cat(x)→¬animal(x))`, never `¬∀x(cat(x)→animal(x))`.

## Negative controls and hard stops

- Nested/coordinate negative frames must not gain through this rule:
  `pronto-nested-negative-1/2/3`, `pronto-coordination-1`, and
  `pronto-coordination-5/6/7` (each suffix denotes the full existing ID).
  Their subjects/root structures are outside the certificate; all are currently
  no_parse under both policies. Any new admission requires diagnosis before
  landing, even if one selected formula happens to match.
- Positive nominal controls retain their policy-specific results:
  `pw-atom-nominal-1/2`, `prover-positive-nominal-1/2/3`,
  `pronto-nominal-1/2`, `pronto-every-1`, `pronto-each-2`.
  Do not loosen Bill/unknown-name handling to improve counts.
- Ordinary negation controls retain meanings/statuses: `prover-subject_do-1/2`,
  `pronto-negative-adjective-1/2/3`, `pronto-every-2`,
  `authored-everyone-closed-3/6`, `particle-authored-negation`,
  `particle-next-authored-3`, `authored-something-domain-3/4`,
  `operator-not-both-1/2`. Existing wrong/no-parse controls are not authorized
  fixes; unrelated changes must be isolated and explained.
- For each admitted named target require exactly the frozen `NOT(P(name))` DRS:
  empty root universe; NOT Asserted, inner positive atom Embedded; no extra
  equality, witness, generic universal, Reported or Presupposed claim. Predicate
  and full name identity must match independent gold. For universal synthetic
  controls only the implication is Asserted; restrictor, NOT and inner atom
  remain Embedded. Ordinary negative argument-indefinites keep their witness
  inside NOT; predicative article identity must not escape.
- Stop landing on **any exact→wrong/no-parse**, new wrong-but-typed admission,
  scope/status/identity change outside the bounded contract, type/error failure,
  lost document completeness, missing not provenance, or retained wrong reading
  hidden by an exact selected one. For a new admission require a nonempty set of
  retained readings and every reading to have the independent exact DRS/claims;
  absent DRS is failure, not a filtered alternative. Preserve existing retained
  alternatives on all unchanged controls, comparing semantic objects rather
  than only aggregate status. Any other unexpected ID/result change pauses
  integration for diagnosis; do not redefine the target set retrospectively.
- Explain must preserve source/category/occurrence evidence for actual closed
  not, the exact BwdXComp and complete frame. Compatible reconstruction alone
  cannot prove the original selected derivation; raw fallback must be reported
  as such. No unexplained new replay failure is acceptable. Run all normal
  release gates and independent review before push. An exact improvement never
  authorizes new benchmark/model launches while the fidelity gate is closed.
