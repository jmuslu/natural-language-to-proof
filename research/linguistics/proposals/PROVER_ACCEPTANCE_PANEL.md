# ProverQA representative construction-fidelity acceptance panel

This is a preregistration proposal, not a sampled panel or a fidelity result.
The owner gate remains closed. A reviewed probability panel of **800 sentence
occurrences**, supplemented by separate construction controls, can operationalize
“at least 90% exact with near-zero wrong-but-typed” on the available local inputs.
The proposed acceptance rule is **at least 737 exact and zero wrong-but-typed**,
with every selected occurrence resolved and scored. This is deliberately stronger
than a 90% point estimate. No parser/model launch is authorized by this document.

## Population, source seal and estimand

The target is the finite local ProverQA dev population, not unavailable training
inputs, unseen English, or answer accuracy. Use the exact occurrence frame in
[proverqa-strata-counts.json](../proverqa-strata-counts.json): 1,500 records,
17,345 occurrences, 17,285 unique surfaces, 60 duplicate excess occurrences.
The estimand is the fraction of **presented sentence occurrences** for which the
frozen production configuration selects an exact complete DRS and claim table.
Questions retain the existing one-time question stripping contract; theory uses
the pinned splitter. This is sentence fidelity, not whole-theory coreference or
reasoning success. Input-unit mistakes remain observable blockers, not silently
repaired text.

| Diagnostic stratum | Population occurrences | Expected sample size under SRS of 800 |
|---|---:|---:|
| easy / theory | 2,029 | 93.6 |
| easy / question | 500 | 23.1 |
| medium / theory | 4,867 | 224.5 |
| medium / question | 500 | 23.1 |
| hard / theory | 8,949 | 412.8 |
| hard / question | 500 | 23.1 |

These are expected counts, **not quotas**. Choose simple random sampling without
replacement (SRS) over the complete occurrence frame; conditioning on realized
stratum counts gives random samples within those strata. This avoids unreviewed
survey weighting and gives an exact finite-population acceptance calculation.
Every occurrence has inclusion probability 800/17,345. Repeated text can occupy
multiple selected positions and keeps that multiplicity in the primary score;
review its gold once where interpretation/context is identical, but never erase
its sampling weight. Publish a separate descriptive unique-text score with its
own denominator, not the primary confidence interval.

Seal source file hashes from the strata artifact plus:

- projected inputs: `feca7c56c75383b26454096ae5d81c9ef35e839faa8bde755fc4eee81e17d7f0`;
- ordered occurrence frame: `3a86ffca1c854570475a28541e07252c9f520c202d6944982bc81a995c4274db`;
- splitter source: `439c25ec9fa9af618643eeba6cf9c720e0aecd50bb87bd4383eb46d9aef51938`.

Frame order and canonical digest encoding are specified in the artifact and
[inventory-proverqa-strata.py](../inventory-proverqa-strata.py). Coordinates are
relative file, zero-based record index, role, and sentence index. Preserve exact
text and input context, with stable record ID as additional provenance when
available; never substitute a record ID for a row offset without verification.
The unique cache's first representative locator cannot recover this frame.
**Readiness blocker:** confirm an existing sealed occurrence-level cache, or obtain
a separately authorized input-only reconstruction matching the frame digest.
Do not infer 17,345 positions from the 17,285-row unique cache. This task has not
re-extracted inputs or drawn any text.

## Freeze and draw protocol

1. Reviewer approves this design, the complete semantic contract, and the chosen
   source/scorer/production configuration. Publish a hash of this plan before
   obtaining random seed material; no seed shopping.
2. Generate one 256-bit seed from OS entropy, archive it immediately, and pin
   sampling implementation/version. Use a reviewed deterministic Fisher–Yates
   partial shuffle with rejection sampling of uniformly distributed integers
   from a seeded cryptographic byte stream; select its first 800 distinct frame
   positions. Rejection sampling avoids modulo bias; the inferential design assumes
   this generator approximates independent uniform draws. Record that practical
   pseudorandomness assumption rather than claiming a 256-bit seed can enumerate
   every possible subset. Commit the small sampler
   and synthetic uniqueness/range/replay tests before the draw. No sampler or
   seed is supplied here: the draw remains a separately reviewed future action.
3. Write an ignored selection manifest containing ordered coordinates, frame
   hash, seed, algorithm/version, per-row text hashes, exposure flags and draw
   timestamp. Freeze the complete selection before gold work or any parsing.
   No replacing hard, ambiguous, duplicate, already-known, or unsupported items.
4. Two independent authors inspect only input text/context and the contract.
   They produce full DRS/claims independently, reconcile disagreements with a
   third reviewer, and freeze adjudication records before observations. Gold
   authors must not inspect parser output, dataset answers/proofs/formulas or
   model-generated interpretations. Authors who saw an item's previous parse
   must recuse from independent authorship of that item.
5. Root alone authorizes and executes a construction-fidelity measurement after
   prediction logging, sealed producer/scorer/gold/policy hashes and review.
   Each observation must bind its source and policy to the candidate binary.
   A benchmark answering run or LLM call is not part of this protocol.

## Semantic contract and unresolved cases

Use one explicitly versioned strict surface-English acceptance contract, reviewed
before drawing, covering person restrictions, existential versus generic force,
lexical argument structure, tense/aspect, degree, intensional/factive boundaries,
and predicate normalization. Do not silently import the historical controlled
empty-restriction convention. Either/or without overt exclusion is not automatically
XOR; ambiguous acceptable readings must be independently enumerated or the item
marked unresolved. Preserve all modifiers, bindings, presuppositions and claim
statuses. Exactness must check the selected reading, not merely whether a correct
reading appears somewhere among alternatives; enumerate approved ambiguity in
advance, not after seeing the selection.

Current seven `proverqa*.jsonl` files contain 56 IDs / 55 distinct texts: 24 in the
starter, plus names 2, nested 10, person-pronouns 4, positive-nominals 3, relatives
4 and transitives 9. Forty-five rows lack an explicit `semantics_contract`; the
remaining eleven use four contract IDs. They are development controls, not a
representative or automatically contract-compatible panel. Audit all sampled
text against every existing fixture and sealed observation before authorship;
retain selected overlaps, flag prior exposure and re-adjudicate under the frozen
contract. Never claim an entirely unseen holdout if overlap exists. Publish the
exposed/unexposed counts and scores separately without dropping either from SRS.

An unresolved meaning, defective segmentation, unavailable context, missing
observation or incomplete export stays in the 800 denominator as **unresolved**,
not exact and not automatically no-parse. Any such row blocks acceptance until
review resolves it without changing text or selecting a replacement. Explicit
no-parse requires a completed producer observation with no admissible reading.
Wrong-but-typed means a selected typed reading whose complete semantics disagrees
with every approved gold reading. If gold is unavailable, do not guess this label.
The final partition is exact / wrong-but-typed / no-parse / unresolved = 800.
The operational gate requires unresolved = 0.

## Exact acceptance calculation and uncertainty

Let N=17,345, n=800, E be exact observations and W wrong-but-typed observations.
For population success count K, sampled successes X follow Hypergeometric(N,K,n)
under this sampling design. Use exact one-sided confidence bounds obtained by
inverting its tails, not a binomial/Wilson interval presented as survey-exact.
Allocate alpha=0.025 to each gate bound (Bonferroni gives at least 95% simultaneous
coverage for the two bounds). Retain full precision and integer K boundaries.

- Require the lower confidence bound on population exact fraction to be at
  least 0.90. Test the boundary K=floor(0.90*N)=15,610: P(X >= 737)=0.020570196,
  whereas P(X >= 736)=0.027832719. Thus E >= 737 is sufficient at this n/N.
- Operationalize near-zero as **zero observed wrong** AND an upper population
  wrong-fraction bound <=0.005 (one-half percent). With W=0, invert
  P(X=0)=C(N-K,n)/C(N,n). K=78 is first rejected at 0.024932488; the largest
  retained integer K is 77, giving an upper bound 77/17,345 = 0.00443932.
- Require unresolved=0, every required invariant/regression gate to pass, and
  no newly wrong reading on the frozen development controls. No-parse consumes
  the nonexact allowance; it is never removed to inflate E/n.

This defines a proposed quantitative meaning of “near-zero,” not a unilateral
relaxation of the owner gate. Reviewer/coordinator acceptance of the operational
criterion is required before use. The proposal's thresholds were calculated from
integer combinations only, not parser results. Report point estimates, n/N,
all four counts and both bounds even when the gate fails.

This is a **single frozen-candidate confirmatory test**, not a target to tune
against repeatedly. After a failed or exposed candidate trial, the panel becomes
development evidence. Further confirmatory claims require a newly preregistered
probability draw and an explicit repeated-testing policy (e.g. alpha spending
across attempts), with fresh independence review; do not retry seeds or pretend
reused acceptance data are an untouched holdout. If the candidate changes after
the draw, this panel is development evidence for that changed candidate; a new
confirmatory protocol is needed. This design does not certify unobserved future
versions.

## Construction diagnosis without double counting

Report every one of the 13 mutually exclusive **outer recognizer families**, the
six difficulty/role strata, and predefined overlapping cues. Preserve the
3,791-occurrence unclassified bucket; its 249-instance narrow lexical refinement
is diagnostic and does not resolve the other 3,542. Conditional-initial alone has
5,279 occurrences; a conditional with pronouns, nominal predication and `not both`
is one primary observation and several diagnostic memberships.

For each family/cue show population occurrence count, realized sample n, unique
texts, exact/wrong/no-parse/unresolved, contract disagreements, and a conditional
finite-population interval (95% two-sided for diagnostics). Report n=0 as
unmeasured and small n as imprecise. These many intervals are descriptive,
not simultaneous per-family guarantees. A subfamily with no known population
count receives counts only, not a fabricated population CI. Do not sum overlapping
cue numerators/denominators or average family percentages into the primary score.
If family-level acceptance is later required, preregister its size/error budget
separately rather than pretending 2–3 examples establish 90% family fidelity.

Add a separate diagnostic panel of at least 2–3 independently authored controls
per **validated semantic construction**, including scope/binding contrasts:
conditionals and dependent pronouns; inclusive OR versus explicit exclusion and
`not necessarily both`; names/nominal predicates; relative restrictions; do/copula
negation; particles/reflexives; modal/attitude/PP/aspect residuals where a full
contract is possible. Draw source-based supplements by a predeclared input-only
rule from underrepresented families, or clearly label authored controls. Preserve
source frequency priorities without inventing a semantic family from a cue.
Supplement selection and all contracts must precede parser observations.

These supplements have no primary sampling weight and cannot rescue a failed
800-occurrence gate. A wrong supplement is a review blocker for its proposed rule,
not an excuse to change the SRS denominator. Existing development controls remain
mandatory regression evidence. Tie every new control to Unit 2 category/derivation,
Unit 3 Montague meaning and Unit 4 DRS/claim commitment; first-divergence Explain
analysis is performed only after independent gold is frozen.

## Deliverables before any acceptance claim

Required artifacts are the reviewed plan and sampler; source/frame/selection
manifest; complete versioned semantic contract; independently adjudicated frozen
gold with source locators and exposure records; candidate/policy/producer/scorer
manifest; all observations including failures; reproducible exact interval
calculation; primary and family diagnostic tables; reviewer verdict and full
root gates. Store raw frames, bulk text and parse output only in ignored runs.
Commit compact aggregate evidence and approved small gold controls according to
repository data policy. An 800-row source-text panel is not implicitly authorized
for git by this proposal. Root retains launch/merge authority.
