# Corpus, graph, and retrieval

This small adversarial corpus stores source metadata and checkable claim
decompositions. It is useful for ingestion and provenance tests. Its size and
format/label confounds do not support general discrimination claims; current
evidence is summarized in [PROGRESS.md](../PROGRESS.md).

## Data contract

| Artifact | Meaning |
|---|---|
| `records/`, `record_schema.json` | Structured source/claim metadata. Owner labels and agent decomposition retain separate provenance. |
| `verdicts_agent_proposed.json` | Reference-backed proposed verdicts, marked pending confirmation; citations do not authenticate an agent's interpretation. |
| `claims_index.json` | Stable claim IDs, readable text, evidence basis, source and time fields for retrieval. |
| `graph.json` | Rebuildable graph scores, retaining their original evidence/proposal provenance. Scores are not calibrated probabilities. |
| `events/` | Separate dated-event records, with event and disclosure/knowability times. |
| `brain_manifest.json` | A dated calibration artifact; consult its dataset/embedder configuration before comparing runs. |
| `runtime/` | Ignored run journal, receipt snapshots, current graph/index/brain and experiment reports. |

Raw transcripts and articles remain outside the repository. Structured records
contain derived metadata and short claim statements. `brain.db` and `.venv/` are
ignored local artifacts.

Schema fields distinguish media format/length, owner confidence, strategy
risk-quality, claim type, and **evidence basis**. A risk judgment is not a factual
verdict. `public_reference`, `self_reported`, `unquantifiable`, and
`not_applicable` route different checks; they do not themselves establish truth.

## Build and query

| Entry point | Function |
|---|---|
| `build_records.py`, `export_claims_index.py` | Build structured records and stable claim index. |
| `verify_claims.py` | Produce reference-backed proposed verdicts. |
| `confound_check.py` | Test format/length confounds and sample readiness. |
| `build_graph.py`, `epistemic_graph.py` | Construct nodes, structural edges and evidence-score propagation. |
| `oracle_bridge.py`, `ingest_outcomes.py` | Recompute run certificates, journal revisions, materialize run-validation claims. |
| `brain_build.py`, `brain_query.py`, `brain_evidence.py` | Build the libSQL store; retrieve explicit direct evidence separately from exploratory scores and propose checks. |
| `pipeline.py` | Run the receipt/Haskell/graph/brain handoff with explicit stage reports. |
| `reasoning/` | Bounded model proposals, typed proofs, receipt bindings, experiment/replay protocol. |

```sh
python3 corpus/confound_check.py --selftest
python3 corpus/pipeline.py --oracle-only --oracle-repo ~/projects
corpus/.venv/bin/python corpus/pipeline.py --quick --oracle-repo ~/projects
corpus/.venv/bin/python corpus/brain_query.py --help
```

Embedding/libSQL dependencies are in `requirements-brain.txt`. A deterministic
hashing embedder supports offline contract tests; it is not a semantic model.

## Graph and brain boundaries

The graph distinguishes sources, claims, domains, references, owner labels and
run outcomes. Structural attribution and logical/evidential support are separate.
The current base graph includes agent-proposed reference scores and owner
judgments. Neither is upgraded to an independently checked fact by retrieval.

New result ingestion updates only `passes_validation(run_id)`. An unsuccessful
strategy does not refute its cited source claims. Older generic reverse-propagation
demonstrations are graph experiments, not the live receipt policy. See
[ORACLE_BRIDGE.md](../ORACLE_BRIDGE.md) for identity, withdrawal and replay.

Embeddings locate text; they do not create evidence. `answer` returns
`confirmed_related`, `refuted_related`, and `unchecked_relevant` citations,
`checked_retrieval_coverage`, and `answer_status=not_inferred`. Verdicts concern
the cited propositions; similarity alone does not establish an answer. Confidence
remains null and local licensing false. Calibration uses direct observed receipt
labels, never graph scores. Old databases without provenance are readable as
unchecked; rebuild from the journal to restore their direct evidence.

Historical queries filter every stage by the eligible evidence set before
ranking or calibration. Date-only cutoffs mean the end of that UTC day. Source
event time, disclosure time and local observation time have different roles;
see [TEMPORAL.md](../TEMPORAL.md).

## Development evidence

`brain_test.py`, `test_brain_evidence.py`, `test_brain_temporal.py` and
`test_temporal.py` cover retrieval, direct provenance, historical selection,
ranking, calibration and agenda behavior. These validate
code contracts; `confound_check.py` and held-out downstream tasks must establish
whether the corpus supports a useful research claim.

Research hypotheses and numerical-method limits are maintained once in
[RESEARCH_THREADS.md](../RESEARCH_THREADS.md). Proof-loop experiments and
receipt-backed reasoning are in [REASONING.md](../REASONING.md).
