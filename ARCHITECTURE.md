# Architecture

The system proposes formal claims, checks selected proofs, records external
evidence, and preserves enough support information to revise its conclusions.
The working objective is reliable reasoning with a modest proposer. The current
implementation establishes bounded interfaces and controlled experiments; it
does not establish general language understanding or frontier-level capability.

## Executable paths

Three paths share representations and evidence discipline, with different scopes:

```text
Language research
  text -> lexical lattice -> CCG derivations -> typed lambda terms -> DRS
       -> scope/coupling/discourse candidates -> ranked, recorded selection

External validation
  agentic-qr result + declared experiment family -> independent certificate audit
       -> immutable receipt revisions -> passes_validation(run_id)
       -> Haskell Oracle -> Confirmed -> genealogy + fusion -> reward coordinates

Controlled reasoning experiment
  public typed-world task -> bounded model proposal -> exact proof-step checker
       -> externally supplied fact receipts + explicit task-rule assumptions
       -> supported answer / abstention -> feedback and optional repair
       -> independent held-out scoring + offline replay
```

The language front end does not yet automatically produce the controlled
reasoning tasks. The external bridge certifies a named run's recorded validation,
not the truth of its source prose. These are integration boundaries to measure,
not interchangeable notions of correctness.

Operational commands and detailed protocols live in
[ORACLE_BRIDGE.md](ORACLE_BRIDGE.md) and [REASONING.md](REASONING.md).
[TRACE.md](TRACE.md) retains the language and formal-substrate findings.
[RESEARCH_THREADS.md](RESEARCH_THREADS.md) is the hypothesis and falsification
ledger for the statistical and adaptive-reasoning research.

## Evidence boundaries

1. **Candidates are proposals.** Parsing, typing, semantic similarity, RSA
   ranking and model-generated confidence do not attest external truth.
2. **Proof checks establish a conditional consequence.** A valid Horn proof
   establishes its signed query from the admitted facts and declared rules.
   Task rules are explicit benchmark assumptions; real-world rule attestations
   remain a separate integration requirement.
3. **Receipts have scope.** The bridge admits only `passes_validation(run_id)`.
   A failed strategy cannot refute every claim cited by its author. `claim_refs`
   are attribution edges and do not themselves license truth propagation.
4. **Unknown is distinct from refuted.** Missing, malformed or uncovered evidence
   cannot establish falsity. Refuting a query requires its explicit negative
   proof; an accepted `unknown` proposal is an abstention, not a proof that no
   answer exists.
5. **Local certificates are not authentication.** Recomputing recorded checks
   detects inconsistencies. It does not authenticate the producer, prove that a
   declared experiment family is complete, or establish independence of the
   underlying data.

Haskell `Confirmed` and `Fused` use hidden positional constructors and ordinary
read-only accessors. `confirm` admits evidence through an `Oracle`; `fuse` accepts
confirmed tokens; `withoutClaim` can only remove support. Compile-failure tests
cover constructor forgery and record-update bypasses. An authorized caller can
still define an untrustworthy `Oracle`: the type boundary is admission control,
not proof that the oracle is honest.

## Content, provenance and support

These answer different questions:

| Representation | Question | Preservation rule |
|---|---|---|
| `Term`, `DRS`, `CanonCond` | What does this candidate assert? | Preserve exact predicates, arguments, binding and sign |
| `Prov` | Which source spans and derivation steps produced it? | Retain lexical leaves and rule trees |
| `Selection`, `Decision` | Why was this candidate chosen? | Keep the alternatives and the stated choice |
| `Genealogy` | Which evidence and derivations currently support it? | Keep addressable nodes and alternative justifications |
| Receipt journal | What was observed or withdrawn, and when? | Append revisions; replay current support without duplication |

Genealogy computes the **least fixed point** of supported nodes, starting from
confirmed premises. A cycle without an external leaf stays unsupported. A
conclusion survives a withdrawal if another retained derivation still supports
it. Precise retraction is the difference between support before and after the
revision; transitive reachability alone would remove too much.

The typed proof checker merges alternative supplied derivations at the signed
atom node. Repeating a fact ID or alias of the same evidence does not add an
independent root. It checks chronological references and explicit premises; it
does not search for omitted proofs. Direct opposing receipts are visible to the
checker, while an opposing derivation omitted by the proposer may be unseen.
The benchmark's separate closure evaluator ensures its queried worlds are
consistent. Arbitrary inconsistent worlds require a stronger conflict contract.

Fusion deduplicates exact canonical content after admission, while genealogy
retains the derivations. Canonical equality is not full logical equivalence and
similarity thresholds are not an equivalence relation. Keep ranked similarity
separate from exact identity.

## Time, retrieval and measurements

`knowable_time` records when information was available, which may differ from
the event's date. As-of retrieval includes only facts available by the requested
time. A newly read historical receipt receives its local observation time;
filenames cannot backdate evidence. Replaying old input cannot undo a withdrawal;
reinstatement requires an explicit reason. See [TEMPORAL.md](TEMPORAL.md).

`brain*.py` embeds claims for retrieval and exploration. Graph `trust` remains an
exploratory score; `brain_evidence.py` separately admits exact observed run
receipts as checked labels. Missing provenance, pending reference interpretations,
source judgments and propagated scores cannot supply those labels. Historical
queries also mask checks by observation time; undated graph scores are not
backdated. Legacy databases need rebuilding to recover checked provenance.
`answer` reports confirmed/refuted related propositions and checked retrieval
coverage, with `answer_status=not_inferred`. Similarity does not establish a
proposition's logical relation to the question. Leave-one-out label diagnostics
do not establish calibrated future confidence.

`estimand.py` and `regime_estimand.py` track quantities, units, basis and declared
provenance. `Leg` is a measurement pattern, not an external check. Empty or
null-only patterns cannot ground. Duplicate or overlapping declared provenance
cannot increase pooled precision; different labels do not prove independence.
The function named `colimit` is a research heuristic, not an implemented
categorical universal property. `reason.py` confidence is bounded metadata,
not a calibrated probability.

## Reward and evaluation

`Reward` reports confirmed/refuted/uncovered counts, grounded consequences,
offer yield, source coverage, corroboration and novelty. It also provides Pareto
comparisons and a stipulated scalar. The scalar assigns zero to uncovered
claims but consequently ignores the cost of offering more of them. It cannot
measure source fidelity or distinguish repeated evidence from independently
supported derivations. Report denominators and provenance coordinates alongside
it; choose utility weights against an external objective.

Model experiments record raw answer accuracy separately from proof-supported
accuracy and coverage. A valid abstention has no grounded answer. Repair receives
checker errors, never gold answers. Arms share resource ceilings, while actual
calls, tokens and elapsed time are reported. Offline replay reconstructs prompt
and response hashes, checks, selected answers, scores and accounting. Interrupted
paid calls without durable result records block resume until reconciled.

## Code map

| Area | Implementation | Primary checks |
|---|---|---|
| Token spans, lattice, fragment CCG | [Syntax](src/NL2Proof/Syntax), [Pipeline](src/NL2Proof/Pipeline.hs) | [Spec](test/Spec.hs): `spanChecks`, `latticeChecks`, `lexiconChecks` |
| CCGbank reconstruction and parsing | `CCGDeriv`, `CCGTypeChange`, `CCGParse`, `CCGSupertag`, `CCGLexicon` | [CCGBankSpec](test/CCGBankSpec.hs), [tools](tools) |
| Lambda forms and DRS | [Lambda](src/NL2Proof/Semantics/Lambda.hs), [DRT](src/NL2Proof/DRT) | `lambdaChecks`, `freshnessChecks`, `recencyChecks` |
| Alternatives, finite models, RSA, SDRT | [Stage2](src/NL2Proof/Stage2) | [Stage2Spec](test/Stage2Spec.hs) |
| Oracle, fusion, support and reward | [Verify](src/NL2Proof/Verify), [Genealogy](src/NL2Proof/Genealogy.hs), [Fusion](src/NL2Proof/Fusion.hs), [Reward](src/NL2Proof/Reward.hs) | [SubstrateSpec](test/SubstrateSpec.hs), [ExternalSpec](test/ExternalSpec.hs), [boundary checks](scripts/check-oracle-boundary.sh) |
| Receipt ingestion and retrieval | [oracle_bridge](corpus/oracle_bridge.py), [ingest_outcomes](corpus/ingest_outcomes.py), [pipeline](corpus/pipeline.py), [brain](corpus/brain.py) | [bridge tests](corpus/test_oracle_bridge.py), [temporal tests](corpus/test_brain_temporal.py) |
| Typed proof and measured proposing | [reasoning](corpus/reasoning), [reason](corpus/reason.py), [retract](corpus/retract.py) | `test_engine.py`, `test_benchmark.py`, `test_run.py` |
| Measurement and adaptive research | `estimand`, `multihop`, `abstain`, `selector`, `alternates`, `metalearn`, `grok`, `discover`, `surprise` | [grounding tests](corpus/test_grounding.py), [research battery](corpus/research_threads.py) |

CCGbank is licensed external data, read by the research drivers at runtime; it
is not committed. Category reconstruction, root coverage, faithful semantics,
valid proof and external confirmation are separate evaluation targets. The
remaining integrations must be tested against those targets individually.
