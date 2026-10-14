# Versioned meaning contracts and acceptance panels

This proposal prevents a linguistic correction from being mistaken for a parser
improvement. It changes no gold, scorer, parser or report. Independent reviewer
advice through `d997927` requires preserving the frozen 121-case historical panel
and separating new strict-person meanings. [FIDELITY_COVERAGE](FIDELITY_COVERAGE.md)
continues to govern coverage and representativeness; versioning does not make a
small acceptance panel representative or open the model/benchmark gate.

## Observed contract conflict

The sealed `research/runs/reflexive-integration/cases.jsonl` contains 121 rows,
SHA256 `7e339cb987abf3ed93f044a78d31d5895106d3141692d0cd46b23a50fc08bdc9`.
Its historical regression contract is the exact row-specific meanings, not a
single uniform interpretation of English quantifiers.

| Cases | Frozen or proposed interpretation | Consequence |
|---|---|---|
| `prover-quantified_pronoun_or_relative-1`, `-2` | Everyone has an empty domain restriction | Diagnostic stipulation, not strict-person English |
| `prover-nested-or-2`, `prover-nested-binding-2` | Someone adds person in conditional antecedent | Already person-restricted inside frozen121 |
| `pw-cond-generic-1`, `-2`, `pw-cond-generic-coord-1`, `-2` | Something binds an unrestricted individual | No added thing or person predicate |
| Pronto `Everything that ...` cases | Unrestricted domain plus written relative restriction | No lexical thing predicate in this controlled fragment |
| New `prover-who-restriction-1`, `-2` | Everyone contributes person before relative property | Cannot silently inherit starter empty-restriction policy |
| New six `pw-binding-*` cases | Someone contributes person; singular they shares generic-rule binder | Explicit rule-reading convention, including distractor caveat |

Thus it would be inaccurate to label all 121 cases “unrestricted”: they mix
explicit diagnostic conventions. Preserve that historical fact. The new who cases
use different English from the starter sentences but expose the inconsistent
policy that would arise from treating standalone everyone as unrestricted and
relative everyone as person-restricted within one supposedly uniform contract.

New metadata is presently heterogeneous: ProofWriter uses the string
`semantics_contract: strict-English`; Prover relatives use an object with
`id: proverqa-strict-english-v1`, domain policy and acceptance-panel prose.
The scorer does not enforce or partition either representation; prose/metadata
alone does not prevent accidental pooling. No such reporting support is claimed
by this document.

## Minimal proposed panel scheme

Use a small coordinator-owned sidecar manifest keyed by exact case ID and gold
hash. Keep old JSONL bytes unchanged. Do not infer a contract from benchmark name
or English tokens. New cases are assigned explicitly by independent review.

| Proposed panel ID | Members initially | Purpose |
|---|---|---|
| `historical-121-v1` | Exact frozen121 ordered file above | Backward diagnostic comparison, never a uniform strict-English score |
| `strict-person-v1` | Two new Prover who cases and six PW binding cases | Person restriction and scoped generic binding acceptance |
| `overt-inclusive-v1` | Two new Prover overt-or-both cases | Inclusive meaning with truthful surface either metadata |

These panel names are proposed, not implemented. An initial strict-person panel
must report ProverQA and ProofWriter separately as well as its eight-case total;
it cannot replace a ProverQA population denominator. Overt-inclusive contains two
ProverQA cases. Other new gold requires explicit compatible panel membership or
its own named extension. Appending a case or changing its expectation creates a
new panel version; historical panel identity never expands silently.

A minimal sidecar contract should contain:

```json
{
  "schema": 1,
  "panel_id": "strict-person-v1",
  "purpose": "construction-acceptance",
  "contract_id": "person-generic-rule-v1",
  "cases_sha256": "<ordered panel input hash>",
  "members": [
    {
      "case_id": "pw-binding-someone-1",
      "gold_sha256": "<canonical full allowed-meanings hash>",
      "benchmark": "ProofWriter",
      "source_kind": "benchmark-adapted",
      "source_row_sha256": "<exact full fixture row hash>"
    }
  ]
}
```

Hashes and complete member lists must be materialized and reviewed before any
new panel run; these placeholders are not an executable manifest. The source
row hash captures text, provenance, notes and metadata; the separately specified
gold hash identifies exactly the accepted DRS/claims/annotations. Specify hashing
serialization once (UTF-8, sorted JSON keys, compact separators, no ASCII escaping)
and record it in schema, rather than depending on unspecified Python formatting.

Reporting must carry panel_id, contract_id, manifest hash, binary hash, scorer
hash and actual source snapshot hashes, and partition by panel, benchmark and
construction. Exact/wrong-but-typed/no-parse/type-failure/incomplete/error remain
in each fixed denominator. Report repeated texts and cross-panel membership;
never sum overlapping panels into an “overall acceptance” score. Case ID alone
is not enough to pair outcomes across revised gold; require the expectation hash.
The meaning contract stays on the evaluation side: only id/text cross the parser
boundary, preserving independent inference from gold.

Until reporting validates membership and emits these partitions, run separate
case files/reports with explicit filenames/manifests or hold new incompatible
cases out of acceptance scoring. Do not concatenate strict-person gold to the
historical file and rely on a reader noticing its notes.

## Semantic choices the versions must state

**Quantifier domain.** Under strict-person semantics everyone is
λP.∀x(person(x)→P(x)); someone is λP.∃x(person(x)∧P(x)). A generic conditional
antecedent makes its introduced person witness available to the consequent;
it does not turn standalone someone into a universal. In a who relative,
restriction is person(x)∧relative(x); neither condition is independently Asserted.
Thing-domain decisions remain separately explicit: something/everything must not
switch between unrestricted and thing-restricted merely because a relative is
present. An actual noun people/things retains its lexical sortal unless the
contract independently says otherwise. Generic-rule singular they has declared
binding here; general contextual pronoun ambiguity is not disproved.

**Either and truth conditions.** `either=true` in current disjunction annotations
records a surface marker; it is not a proof of XOR. Ordinary or and overt or both
license inclusive OR; explicit but not both adds a negated conjunction in the
appropriate scope. Bare either has a declared reading/convention, not an automatic
universal linguistic XOR law. Not necessarily both is not not both: it remains
modal/unresolved until its representation is reviewed. The new or-both cases must
retain either=true and inclusive DRS. If downstream benchmark policy still turns
every marker into XOR, that is a separate known interface failure; changing gold
metadata to false would conceal it. An eventual operator-policy annotation needs
its own versioned exporter contract, not reinterpretation of this boolean.

**Structure and order.** Current exactness preserves order, multiplicity, scope,
case-sensitive constants, binder accessibility and all four claim classes.
Nominal-head-before-intersective-modifier is a declared structural convention,
not evidence that an adjective is intersective. Coordinated predicates retain
surface order. A known equivalent reordering can remain a structural failure;
report it honestly. Do not silently sort all conditions, deduplicate claims,
contract existential equality globally or accept every parser association.
Predeclared legitimate binary OR associations in Pronto gold are structural
alternatives under one meaning policy, unlike person/empty-domain conflicts.

## Independent correction procedure

1. Preserve the old panel, artifacts and hashes. Open a proposed contract revision
   with the linguistic reason, affected IDs and semantic contrast. State whether
   the issue is a gold error, changed controlled-domain convention or new scope
   commitment; do not label these changes parser repairs.
2. Have an independent author write full replacement DRS and claim tables from
   English and the adopted contract. The reviewer checks category/meaning/DRS
   seams and the Boxer/ccg2lambda comparison without receiving current parser
   outputs as candidate answers. Existing observations cannot be un-seen, so
   disclose prior exposure rather than falsely claim all sentences are unseen.
3. For a uniform future strict-English panel, revise both historical everyone
   rows to add person in antecedent and Embedded table, alongside scoped OR
   entries, after independent review. Give revised cases new IDs with explicit
   supersedes links; retain old expectations in historical121. Audit all related
   standalone/restricted pronouns for consistency, not just failing examples.
4. Record text identity across panels. Same English may appear for a historical
   comparison under incompatible expectations, but it cannot simultaneously be
   certified exact under a single contract. Do not put person-restricted and
   unrestricted structures in one allowed-readings list to conceal this policy
   difference. Multiple readings require independently justified ambiguity under
   the same explicit context and contract.
5. Freeze revision and membership before fresh observations; rerun schema,
   provenance/duplicate and reviewer checks, then coordinator records predictions
   and evaluates with a sealed binary. Report old and new panel results side by
   side, isolating denominator/gold changes from source changes. A favorable score
   delta after correcting gold is not evidence of parser improvement.
6. Require fresh construction and release gates before source acceptance. No
   historical exact case may be erased to hide a regression; a versioned policy
   correction must have an independent justification even if it worsens results.
   Population fidelity, missing constructions and model-launch authorization stay
   governed by the owner target and FIDELITY_COVERAGE, not panel bookkeeping.
