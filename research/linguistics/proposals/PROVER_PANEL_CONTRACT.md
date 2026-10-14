# ProverQA acceptance panel: executable protocol specification

This follows reviewed design `fd5ebb6` (`PROVER_ACCEPTANCE_PANEL.md`), making its
sampler and semantic-adjudication prerequisites concrete. **No draw, seed,
parser run, gold admission or acceptance claim is made.** The proposal is ready
for implementation review; an implemented, tested sampler and verified occurrence
frame remain required. The coordinator must explicitly record agreement with
the proposed near-zero criterion before use. Existing benchmark/model pauses stay
in force; this document does not authorize launches.

## 1. Fixed population and validity checks

Use exactly the three local dev files named by
[proverqa-strata-counts.json](../proverqa-strata-counts.json), each with 500 records.
Do not glob in new files or silently substitute another release. The audit here
compared committed aggregates and script digests only, without reading raw text.

| Check | Required value |
|---|---|
| Total occurrence units / distinct surfaces | 17,345 / 17,285 |
| Theory units / stripped questions | 15,845 / 1,500 |
| Easy theory / question | 2,029 / 500 |
| Medium theory / question | 4,867 / 500 |
| Hard theory / question | 8,949 / 500 |
| Duplicate excess / exclusive outer families | 60 / 13 |
| Strata artifact SHA256 | `00020259933cc0286d8bfe6c3589f464a9d620ba2256e16f9ce9d912ee9ae94b` |
| Reference `other-counts.json` SHA256 | `8fd5f996b7ac795549a7c2d488b433b6443841c090cd7b67eff9cbb07dd8c94b` |
| Splitter/normalizer source SHA256 | `439c25ec9fa9af618643eeba6cf9c720e0aecd50bb87bd4383eb46d9aef51938` |
| Strata-script SHA256 | `2f4fec1d7f8a9dbfcbae625838ba8d1988fa35e72f93ee0ff8a8f33579f46c66` |
| Ordered occurrence-frame SHA256 | `3a86ffca1c854570475a28541e07252c9f520c202d6944982bc81a995c4274db` |
| Projected input SHA256 | `feca7c56c75383b26454096ae5d81c9ef35e839faa8bde755fc4eee81e17d7f0` |

The first four artifact/script digests were checked in this task. Frame and input
digests above are **existing inventory seals**, not newly regenerated evidence.
Each source file's complete digest is in the strata artifact. A future frame
verifier must check those bytes before and after loading, recompute the projected
input/frame seals and all table totals, and stop on any mismatch. No partial
frame or changed splitter can use the old 17,345 denominator or thresholds.
A changed population requires a separately versioned design and new calculation.

Frame bytes are the concatenation, in sorted relative-file order, then zero-based
record order, theory before question, then sentence order, of canonical lines:
`[relative_file, record_index, role, sentence_index, text]`.
Serialize each array with `json.dumps(ensure_ascii=False, sort_keys=True,
separators=(',', ':'))`, encode UTF-8, append exactly one LF. The pinned splitter
and query stripper determine text: do not add Unicode normalization, whitespace
cleanup, title repair or additional sentence splitting. Questions are stripped
once, never split. Record ID is an auxiliary locator; index is authoritative for
the sealed frame. Verify coordinate uniqueness and nonempty textual units.
Store source spans/transform provenance separately where available; never
pretend normalized unit bytes are a verbatim substring without checking.

The unique-surface cache is insufficient: its representative locator and count
cannot recreate all occurrence coordinates or contexts. Reuse a verified
occurrence cache if available; otherwise reconstruction needs a separately
coordinator-authorized input-only traversal selecting context/question fields.
Do not consult answer, proof, formula, conclusion or hidden controlled facts.
This protocol preparation neither reconstructs that frame nor certifies an
uninspected cache as valid.

### What one unit means

An occurrence is one pinned inventory unit, not an entire question record, a
unique type, a construction cue, or a parse alternative. Its outer-family label
is diagnostic only. Nested cues can overlap; do not duplicate the unit when
it contains both a relative and a conditional. A repeated surface at different
coordinates remains multiple population units even if the interpretation agrees.
Gold may share a reviewed payload only when text, semantic contract and required
context agree; each selected coordinate still receives its own observation and
sampling weight. Contextually different possessives cannot share gold solely
because their isolated strings match.

The proposed tested interface is the **single inventory unit as parser input**.
Input context is available to authors to diagnose dependency, but must not be
silently supplied only to gold. If the unit's interpretation requires external
antecedents absent from the tested interface, mark `context_required` unresolved.
If that limitation is to be tested with a contextual parser instead, preregister
that distinct interface and estimand before drawing. Malformed segmentation,
annotations, typos and fragments stay selected and block admission when no
faithful full interpretation exists; there is no post-draw replacement pool.

## 2. Deterministic draw algorithm, to implement before drawing

Algorithm ID: `prover-occurrence-srs-sha256-fy-v1`.
Constants: N=17,345; n=800; frame indices 0 through N-1.
After review and candidate/contract freeze, obtain **one** 32-byte OS-entropy
seed and immediately seal its lowercase 64-hex representation. No seed is chosen
or generated in this task. A failed implementation must replay that seed after
correction, with the failure/version logged; it must not choose a nicer sample.
Only a reviewed correction restoring conformance to this frozen algorithm may
replay the seed. A change to the algorithm/design itself invalidates the attempted
confirmatory draw and requires a new preregistration/error-budget decision.

Define block counter c starting at 0. Each 32-byte block is

```
SHA256(ASCII("prover-occurrence-srs-v1") || 0x00 || seed32 || uint64_be(c))
```

Concatenate blocks in counter order. Consume each consecutive eight-byte chunk
as an unsigned big-endian integer u. For `randbelow(m)`, require 1<=m<=N,
set L=2^64-(2^64 mod m); discard u>=L and read the next chunk; otherwise return
u mod m. Rejected chunks are consumed permanently. Counter overflow is a hard
error, not wraparound. Initialize A to `[0,1,...,N-1]`. For i=0..799, set
j=i+randbelow(N-i), swap A[i] and A[j]. The ordered sample is A[0:800].
The order is retained for replay, not sorted to change the draw. A separately
sorted coordinate view may be generated without changing membership.

This partial Fisher–Yates scheme removes replacement and modulo bias under
uniform stream words. SHA256 seeded expansion is a practical pseudorandomness
assumption: a 256-bit seed does not enumerate every possible 800-subset, and this
is not a proof of information-theoretic randomness. The inferential SRS model
uses that declared approximation. Freeze algorithm/version and implementation
hash before seed generation; do not derive the seed from convenient item text,
parser output, case IDs or a candidate's success.

Before launch, two independent implementations must agree on fixed **synthetic**
small-N vectors, exact word consumption and rejection cases using injected byte
streams; no population indices need be drawn for those tests. Include all-zero
seed decoding, endian/counter tests, m=1, forced rejection at L, malformed seed,
N<n, range/uniqueness, deterministic replay and fail-closed changed-manifest tests.
Tests must exercise rejection deliberately rather than wait for a rare random
case. A protocol description alone is not evidence those tests pass.

The selection manifest records algorithm, seed, N/n, exact ordered indices and
coordinates, text SHA256, input/frame/plan/contract/candidate digests, timestamp,
and inventory difficulty/role/outer-family tags. Seal the manifest before gold
work. Exposure matching is an additional annotation, never a membership filter.
Keep text/frame/manifests containing bulk inputs under ignored runs; compact
hashes/counts and the sampler may be committed after review.

## 3. One strict acceptance contract; separate diagnostic domain policies

Proposed contract ID: `proverqa-surface-strict-panel-v1`. It is a **gold-authoring
and admission policy**, not permission to claim missing ontology/export rules
already exist. Before the seed, attach a reviewed representation specification
covering every admitted operator and an explicit unresolved disposition for all
others. The table defines those dispositions without guessing a dataset's
intended hidden logic.

| Surface obligation | Admission rule / unresolved outcome |
|---|---|
| Names, lexical predicates and arguments | Preserve case-sensitive referent identity under a documented name normalization; map lexical senses/arity independently of parser outputs. A sentence-sized invented unary label is inadmissible. Unknown sense or unresolved name/common-noun ambiguity stays unresolved. |
| Everyone/someone/who | Preserve person restriction where linguistically licensed; never erase it because the synthetic domain appears all-person. Author every restrictor, binder and scope explicitly. |
| Everything/something | No automatic person restriction, nor automatic nonperson exclusion. Quantification is over the contract's declared entity domain; any additional thing/sortal restriction must have a coherent reviewed ontology applying to standalone and restricted forms. If not fixed before draw, affected rows stay unresolved. |
| Every/each, a/an and bare plurals | Explicit universals retain noun restrictions. Classify existential versus generic indefinite and bare-plural readings independently. Do not turn a generic into a universal or an existential merely because one is supported by the exporter. Missing generic operator/domain convention means unresolved. |
| Negation, AND, OR, conditionals | Preserve all scopes and dependent bindings. Overt exclusion is not inclusive OR; bare either is not automatically XOR. Enumerate defensible ambiguity before observation; if representation cannot express it faithfully, unresolved. |
| Nominal/classificatory present clauses | An unmarked present-context extensional classification may use a predicate at evaluation context when independently justified. This is not a license to erase habitual, temporal, aspectual or comparative content elsewhere. |
| Tense/aspect, quantity, degree, modality and causal content | Require a reviewed full operator/argument/scale/time representation. Surface modifiers may not vanish through an extensional abstraction. Unsupported representation stays unresolved, not guessed exact or automatic no-parse. |
| Relatives, reflexives, pronouns and possession | Capture restriction versus scope, local identity and accessibility. Context unavailable to the tested interface cannot be filled from a hidden fact or an invented constant. Definite existence/projection is not ordinary existential assertion by default. |
| Reports, knowledge and presupposition | Preserve explicit source and reported boundaries; factive complements follow the reviewed Presupposed convention, not Asserted promotion. Implicit passive holder, additive/degree or unresolved projection contracts block admission rather than licensing empty-holder invention. |

An explicit **unresolved** outcome preserves honesty but does not satisfy the
acceptance gate; all 800 need settled gold before a confirmatory producer run.
If a needed operator has no adequate representation, report the blocked panel
and pursue a separate development task. Do not expand or weaken the contract
for selected sentences while presenting it as the same preregistered test.

Historical controlled-domain and bare-generic fixtures remain unchanged and
separately scored. They cannot be pooled into this strict denominator, converted
by deleting restrictions, or treated as independent strict gold simply because
a text matches. A future coherent domain-specific panel needs its own contract,
estimand and acceptance claim; it cannot certify the strict gate by substitution.
Legacy missing-contract rows require fresh adjudication, not automatic adoption.
The reviewed canonical-gold proposal `d1ef6a9` is a validation dependency where
available; schema/canonical success alone does not establish linguistic truth.

## 4. Independent annotation, disagreements and freeze ledger

Use these row states, with append-only transition evidence:

1. `selected`: immutable coordinate/text hash; record exposure to prior gold,
   parser observations and source-level development independently of status.
2. `independent_A` and `independent_B`: two authors each receive only selected
   input, permitted source context, the frozen contract and blank annotation
   forms. Neither sees the other's draft, parser output, benchmark labels,
   proofs, formulas or model-generated candidate meanings. A worker exposed to
   this item's prior parse cannot count as an independent author for that item.
3. `agreement` or `disputed`: compare complete DRS, complete independently
   authored claim table, disjunction markers, lexical identity, binders,
   presupposition/source boundaries and scope. Record both original drafts;
   disagreement rate is reported, not hidden by overwriting a draft.
4. `adjudicated` or `unresolved`: a third reviewer explains each decision from
   language and the frozen contract. Majority vote, parser convenience, answer
   agreement and extra “acceptable” gold added to match a parse are insufficient.
   Unresolved reasons are typed: lexical/scope/domain/representation/context/
   source-unit. The full selected set remains intact.
5. `frozen`: validators pass; independent reviewer signs row membership,
   semantics and provenance. Seal all alternatives and negative projection
   obligations before candidate observations. Only after **all 800** are frozen
   may the coordinator consider authorizing the one confirmatory measurement.

The authored form includes occurrence ID, text hash, source locator/context
hash, contract ID/hash, lexical ontology entries used, Unit 2 candidate category
analysis (clearly hypothetical), Unit 3 full scoped meaning, Unit 4 DRS and every
claim status, approved reading alternatives, rationale, author/reviewer identities
and exposure declaration. Categories are explanation, not a license to infer
semantics from a production parse. Exporter-derived claims cannot serve as an
independent reference table. Gold-only schema/canonical checks must not invoke
the producer or infer missing fields.

Duplicate texts may share an adjudicated payload only after the context/interface
check in §1, while keeping independent occurrence IDs and multiplicities. Distinct
approved readings are alternative complete analyses, not a union of incompatible
claims. Record their interpretation conditions. If the scorer permits “any gold
matches,” all alternatives must already be approved before observation; never
choose which ambiguity counts after inspecting the selected output.

Freeze a top-level manifest binding ordered selection, every gold row, both
original drafts, adjudication ledger, representation/contract, ontology and
validator versions, candidate source/binary, all parser policies, scorer and
producer execution protocol. SHA256 all exact bytes, not only filenames. Root
logs prediction before launch. Any candidate change after draw or representation
change driven by sampled difficulties turns this panel into development evidence.
A discovered gold error after observation invalidates the confirmatory verdict;
record correction and rerun only as explicitly labeled development, not a stealth
rewrite of the original gold or successful one-shot test.

## 5. Operational gate, reporting and failure handling

The original reviewed proposal uses N=17,345, n=800 and exact hypergeometric tail
inversion. Allocate alpha=.025 to each one-sided bound, giving at least 95%
simultaneous coverage by Bonferroni under the declared sampling model.

- Exactness: require lower population bound >=.90. At K=floor(.9*N)=15,610,
  P(X>=737)=.020570196 while P(X>=736)=.027832719. Require E>=737.
- Near-zero: require W=0 **and** upper population wrong fraction <=.005.
  With zero observed wrong, K=78 is first rejected because
  C(N-78,800)/C(N,800)=.024932488; largest retained K=77, upper77/N=.00443932.
- Require unresolved U=0, all execution/provenance/gold validations, full root
  gates and no newly wrong development controls. A failed execution, timeout or
  malformed export is U, never silently no-parse or discarded denominator.

E/W/no-parse/U sum to 800 even when repeated texts share a meaning. Exact refers
to the selected production reading matching a complete approved reference;
a correct unselected alternative does not rescue a wrong selected reading.
No-parse requires completed execution with no admissible reading. A typed output
with no complete gold cannot be called W or E. Report individual and joint-bound
assumptions, counts, rates and source policy even on failure.

The value .005 is the proposal's explicit operational definition of near-zero,
not a claim that the owner already selected that number. Coordinator/reviewer
agreement must be recorded before drawing; changing it after results is forbidden.
The design does not claim any sentence family is 90% exact merely from three
controls or the aggregate passing. Report six difficulty/role strata, 13 outer
families and overlapping nested cues separately, with conditional finite-population
95% diagnostic intervals where population counts are known. No simultaneous
per-family guarantee is claimed. Unmeasured cells stay visible; supplements have
zero weight in the primary score and cannot repair a failed gate.

One frozen candidate gets one confirmatory analysis under this allocation.
A failed or exposed panel becomes development evidence. Further confirmation
needs a fresh preregistered draw, independence review and explicit repeated-test
error budget; do not reuse this .05 budget indefinitely or retry seeds. The
sample's prior-exposure overlaps are retained and disclosed; this is not a claim
that all selected language was previously unseen. Gold independence and sampling
representativeness are separate properties, both needing evidence.

## Completion checklist without new launches

This task supplies the specification and reconciled compact provenance only.
Before any draw, root needs: explicit criterion approval; frozen candidate and
representation/contract; independently reviewed sampler with synthetic tests;
verified complete occurrence frame and source seals; author assignment/exposure
protocol; manifest writers and gold-only validation. Before parsing, root also
needs all 800 adjudicated references and independent freeze review. If any item
is missing, the honest state is not ready, with no source, gold or denominator
mutation to simulate completion.
