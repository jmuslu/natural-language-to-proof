"""Bind typed proof leaves to an observed external run-receipt journal.

Task rules are caller-supplied assumptions. This adapter establishes only their
consequences from passes_validation(run_id), never the truth of source prose or
the fitness of a strategy for deployment. It never consumes model-written
receipt fields. Rechecking uses the current (or explicit historical) journal.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from oracle_bridge import ReceiptLedger
from reasoning.engine import evaluate

SCHEMA = "nl2proof.ledger-proof.v1"


def digest(value):
    raw = json.dumps(value, sort_keys=True, separators=(",", ":"), allow_nan=False)
    return hashlib.sha256(raw.encode()).hexdigest()


def bind_receipts(task, ledger, *, as_of=None):
    """Resolve declared run bindings from the trusted journal, at one snapshot.

    An explicit Refuted verdict confirms the negative *run-validation* atom.
    Unknown confirms neither polarity. Model-proposed fact text is descriptive;
    the authoritative atom comes only from the fixed adapter and run identity.
    """
    if task.get("predicates", {}).get("passes_validation") != ["validation_run"]:
        raise ValueError("task must declare passes_validation(validation_run)")
    observed = {r["run_id"]: r for r in ledger.snapshots(as_of)}
    receipts, dependencies = {}, {}
    facts = task.get("facts")
    if not isinstance(facts, list):
        raise ValueError("task facts must be a list")
    for fact in facts:
        binding = fact.get("oracle") if isinstance(fact, dict) else None
        if not isinstance(binding, dict) or set(binding) != {"kind", "run_id"}:
            raise ValueError("each fact needs an explicit kind/run_id oracle binding")
        rid = binding["run_id"]
        if binding["kind"] != "passes_validation" or not isinstance(rid, str):
            raise ValueError("only passes_validation run bindings are supported")
        if task.get("entities", {}).get(rid) != "validation_run":
            raise ValueError("bound run must be a declared validation_run entity")
        fid = fact.get("id")
        if not isinstance(fid, str) or fid in receipts:
            raise ValueError("fact IDs must be distinct strings")
        row = observed.get(rid)
        if row is None:
            receipts[fid] = {"atom": {"predicate": "passes_validation", "args": [rid], "negated": False},
                             "verdict": "unknown", "evidence_id": None, "provenance": []}
            dependencies[rid] = {"run_id": rid, "revision": None, "verdict": "unknown"}
            continue
        if row.get("proposition") != {"kind": "passes_validation", "run_id": rid}:
            raise ValueError("journal proposition differs from fixed binding")
        verdict = row.get("verdict")
        if verdict not in ("confirmed", "refuted", "unknown"):
            raise ValueError("invalid journal verdict")
        receipts[fid] = {"atom": {"predicate": "passes_validation", "args": [rid],
                                   "negated": verdict == "refuted"},
                         "verdict": "confirmed" if verdict in ("confirmed", "refuted") else "unknown",
                         "evidence_id": row["evidence_id"], "provenance": ["run:" + digest(rid)]}
        dependencies[rid] = {key: row[key] for key in
                             ("run_id", "revision", "observed_at", "verdict", "evidence_id")}
    return receipts, sorted(dependencies.values(), key=lambda d: d["run_id"])


def check_against_ledger(task, proposal, ledger, *, as_of=None):
    receipts, dependencies = bind_receipts(task, ledger, as_of=as_of)
    checked = evaluate(task, proposal, receipts).to_dict()
    body = {"schema": SCHEMA, "task_sha256": digest(task), "proposal_sha256": digest(proposal),
            "receipts_sha256": digest(receipts), "as_of": as_of,
            "dependencies": dependencies, "check": checked,
            "scope": "Consequence of caller-supplied task rules and observed run-validation receipts."}
    return {**body, "artifact_id": "sha256:" + digest(body)}


def read_input(path):
    with Path(path).open("rb") as stream:
        raw = stream.read(1_000_001)
    if len(raw) > 1_000_000:
        raise ValueError("input exceeds 1 MB")
    return json.loads(raw, parse_constant=lambda _: (_ for _ in ()).throw(ValueError("non-finite JSON")))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--journal", type=Path, required=True)
    parser.add_argument("--task", type=Path, required=True)
    parser.add_argument("--proposal", type=Path, required=True)
    parser.add_argument("--as-of")
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()
    if not args.journal.is_file():
        parser.error("journal does not exist; ingest source results through oracle_bridge first")
    ledger = ReceiptLedger(args.journal)
    try:
        report = check_against_ledger(read_input(args.task), read_input(args.proposal), ledger, as_of=args.as_of)
    finally:
        ledger.close()
    if args.report:
        from reasoning.run import atomic_json
        args.report.parent.mkdir(parents=True, exist_ok=True)
        atomic_json(args.report, report)
    print(json.dumps(report, indent=2))
    if not report["check"]["accepted"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
