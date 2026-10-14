# Linguistic redirect: decision document

Snapshot: accepted reflexive integration `61f52d8` and its sealed 121-case run,
plus 28 independently authored extension cases evaluated with the same binary.
The linguistic-design-first redirect remains active. **Keep new model and answer
benchmark launches paused.** Construction inventories and learner design now
exist, but current evidence is far below the ProverQA fidelity gate and is not a
representative population estimate. This is an interim contribution to
[research/FINDINGS.md](../FINDINGS.md), not completion of the original goal.

The old FINDINGS opening “D/E comparisons active” is stale under the owner
redirect. Saved earlier experiments remain evidence of their historical scopes;
they do not authorize new runs. Current priorities are faithful English meanings,
independent scoped gold, and narrowly licensed compositional repairs.

## What is established

[CONSTRUCTIONS](CONSTRUCTIONS.md) and [DESIGN](DESIGN.md), consolidated in
`7c6e90f`, connect inventory frequencies to Units 2/3/4: CCG categories and
derivations, Montague composition, DRS binding and claim status. The inventory
scope is explicit:

| Acquisition | Files | Input records | Sentence occurrences | Distinct surfaces |
|---|---:|---:|---:|---:|
| ProverQA local dev easy/medium/hard | 3 | 1,500 | 17,345 | 17,285 |
| ProofWriter all stored variants/worlds | 110 | 702,271 | 13,247,543 | 172,834 |
| ProntoQA extracted local acquisition | 80 | 65,600 | 819,128 | 177,560 |
| FOLIO committed sample | 1 | 120 | 744 | 439 |

These totals are input accounting, not semantic coverage. Repeated ProofWriter
stages and Pronto demonstrations are occurrences, not independent observations.
Pronto's anchored local surface grammar is recovered; ProverQA is LLM-verbalized,
with 3,791 residual frame occurrences in the consolidated inventory. ProofWriter
surface residuals are 156 occurrences/12 strings, and its broad NatLang groups
still need semantic refinement. FOLIO retains 238 residual occurrences/137
strings. Subsequent frame/residual audits refine priorities without proving all
those English meanings understood. See the section scripts/manifests linked in
CONSTRUCTIONS for reproduction; licensed/raw inputs stay outside version control.

## Accepted repairs have bounded evidence

| Accepted work | Evidence and limit |
|---|---|
| Licensed name N/NP handling and fidelity exporter/scorer foundation | Makes meanings reviewable with independent DRS/claim gold; it does not establish multiword/title or all name fidelity |
| some/no/each determiner repair (`d64d3e6`) | Fresh85 changed 21 exact/24 wrong/40 no-parse to 22/23/40; Prover starter stayed7/24 exact |
| has→have irregular lemma (`04a85b8`) | General lexical repair preserves object-witness meanings; residual frame audit remains separate from word recognition |
| Conditional role/packing repair | Fresh114 changed24/33/57 to27/30/57, exactly three wrong→exact; no status regressions; pending clause modifiers cannot be consumed as comma coordination |
| Local singular object reflexives (`5f2d513`, integrated `61f52d8`) | Fresh121 changed27/32/62 to34/25/62: seven wrong→exact and no other status changes; local transitive subject supplies both argument positions |

The reflexive repair is guarded by lexical/category origin and locality. It is
not a general discourse/logophoric/possessive-reflexive solution. Its evidence
includes quantified subject sharing, distracting prior names and negation scope.
Counts above refer to differently sized/versioned diagnostic sets and cannot be
subtracted into a common population trend. Predictions, commands and exact scope
are in [LOG](../LOG.md); independent review through `d997927` approved the sealed
reflexive result.

Accepted `61f52d8` gates were 17 Haskell suites/1,270 checks, build, oracle boundary,
Explain, 29 scorer contracts and live hand4/4. Later scorer audit `9f0e49b` /
`f3567ff` adds independent tests: 42 checks means 40 passes plus two documented
expected gold-admission-policy failures, not 42 green. These later tests do not
change the semantic result or resolve the open gold-authoring trust boundary.

## Current selected fidelity, with contracts separated

The sealed historical panel has121 rows/119 distinct texts and **34 exact,
25 wrong-but-typed, 62 no-parse**. All other outcome counts are zero. Its ProverQA
starter remains10/24 exact. The historical panel mixes disclosed diagnostic
domain conventions; it is neither a uniform strict-English panel nor a random
population sample.

The 28 new cases were parsed with exactly the same accepted executable, after
independent authoring/review. Their sealed partition report is:

| Reported contract partition | n | Exact | Wrong-but-typed | No-parse | Incomplete |
|---|---:|---:|---:|---:|---:|
| compatible-extension-diagnostic | 18 | 6 | 0 | 11 | 1 |
| proverqa-strict-english-v1 | 2 | 0 | 1 | 1 | 0 |
| proverqa-controlled-v1 (overt or both) | 2 | 0 | 0 | 2 | 0 |
| strict-English (ProofWriter binding) | 6 | 6 | 0 | 0 | 0 |

Type-failure/error are zero in each partition. The compatible six successes are
three lexical-have/object-witness and three negative-transitive/indefinite-object
cases. Its failures include negative nominal predicates, relative/coordination
forms and titled names; one title input is incomplete. All six person-restricted
ProofWriter generic binding cases succeed on this bounded fragment, including
relational arguments and negative consequence. This does not certify ordinary
English contextual pronoun resolution or all ProofWriter.

The raw tool report also contains a pooled28 summary, but it is not an acceptance
score: strict-person and historical unrestricted everyone contracts must remain
separate. The overt-or-both partition name is its actual stored identifier, not a
claim that either universally means XOR. These cases require inclusive OR while
retaining truthful surface either metadata. Follow the reviewed versioning
proposal `743ef4f` ([SEMANTIC_CONTRACTS](SEMANTIC_CONTRACTS.md)) rather than putting
incompatible interpretations into one allowed-reading list.

Local sealed evidence, intentionally ignored rather than committed as bulk data:
[historical121 report](../runs/reflexive-integration/fresh.json),
[extension partition report](../runs/gold-extension-baseline/contract-panels.json)
and [extension manifest](../runs/gold-extension-baseline/manifest.json).
Both reports identify binary SHA256
`7389678a14a7aca701bfd601ae3af1b8e4e8f89dcf622c0ff54da8801018f432`.
Historical cases hash is
`7e339cb987abf3ed93f044a78d31d5895106d3141692d0cd46b23a50fc08bdc9`;
extension cases hash is
`31021d6bb608f748bd2d18865742414b61d8e3e20327a6552cb8cd030d8519fb`.
These paths require the research workspace; commits and this compact summary
remain the portable record. No claim is made that independent gold covers every
construction or proves the owner's >=90% population target.

## Reject the broad nominal candidate

Keep the predicative-nominal candidate isolated as local `astra/nominal-candidate`
(`c2bff11`, source snapshot `91645ae`); it was not accepted or pushed. Although55
focused controls and16 Haskell suites passed, Explain failed six checks. Fresh114
changed **24/33/57 to33/67/14** (exact/wrong/no-parse): 15 no-parse→exact, six
exact→wrong and28 no-parse→wrong. Newly typed output was often less faithful.

This is evidence against using coverage gains or focused green tests as the
admission criterion. The six regressions were bare-generic adjective NPs selected
as universal equatives; further newly typed failures exposed relative/name
licensing dependencies. Preserve evidence in the
[nominal quarantine manifest](../runs/nominal-quarantine/manifest.json) and LOG.
The independently reviewed licensing proposal `8ecc681` is **design only**.
Do not restore the candidate wholesale, add surface exceptions or weaken gold.
Require origin-sensitive licensing and coherent relative/NP semantics first.

## Decisions and the next three linguistic steps

1. **Finish quantifier/relative scope before broad nominal enabling.** ProverQA
   quantified-pronoun+who has959 cue occurrences; initial-if has5,279 outer
   occurrences, including2,836 not-both and654 copula+a/an cues. Review concrete
   origin propagation/packing obligations for fused relatives; require person
   contracts coherent for standalone/restricted pronouns and preserve restriction
   versus scope. Fresh evidence must include existing exact controls and newly
   typed failures. Isolated worker candidates are not accepted repairs.
2. **Repair sentence/nominal coordination with lexical-origin safeguards.**
   Pronto predicate-AND occurs149,937 times, relative restriction-AND128,988 and
   clause-AND5,516; these overlapping cues are not additive weights. New sentence
   conjunction/list gold currently fails, while the rejected nominal experiment
   exposes unsafe generalized-quantifier coercion. Separate predicative N from
   referential/equative NP and comma conjunction from attribution. Validate shared
   versus distinct subjects and final-conjunct negation before broadening coverage.
3. **Expand semantic families and freeze honest acceptance contracts.** Use
   FIDELITY_COVERAGE's frequency queue, including conditional inclusive/exclusive
   scope, relational argument frames, retained definite descriptions, names and
   PP/particle distinctions. Preserve historical121, version new panels and author
   2–3 scoped cases per actual semantic family. Modals/hedges, subsective modifiers,
   passive/control/temporal meanings and scalar/cardinality contracts remain
   explicit unresolved work. Do not erase these to certify an easy denominator.

Keep POS backoff opt-in, restored Threading/SDRT diagnostic-only, and see-that's
logged conservative sense policy pending stronger evidence, as recommended in
the earlier FINDINGS. The redirect supplies no new evidence overturning those
choices. Solver fallback/reading policies remain options to evaluate after
upstream fidelity; proof correctness cannot fix mistranslated premises.

## Original goal status

Phase B remains open for construction semantics beyond bounded repairs. Phase C
has prior algebra/retraction evidence in [STRENGTH](../STRENGTH.md), retained but
not re-proved here. Phase D has prior solver/options work with incomplete
comparisons; new answer-benchmark measurements are paused. Phase E graph/model
comparisons remain behind the fidelity gate. Phase F's earlier authored structured
support/withdrawal evaluation is not an English parsing benchmark. Phase G's
restored-module audit supports keeping modules diagnostic-only; remaining ranking
comparisons are pending. Phase H synthesis, owner decisions, final risk/coverage
figures and merge guide are incomplete. No phase is silently waived by this note.

The original research goal stays active. Typed claims, provenance guarantees,
independent gold and all-green release gates are valuable, but none alone proves
that English has been translated faithfully. Near-zero wrong-but-typed and the
ProverQA exactness target remain unmet; no restart authority follows from this
interim document.
