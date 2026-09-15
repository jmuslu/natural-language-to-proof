#!/usr/bin/env python3
"""Ingest checked run verdicts with replay and revision support.

The proposition is passes_validation(run_id). Source claim_refs are attribution,
never promoted to proofs or refuted by a strategy's failure. Descriptive grounding
legs cannot override the independent certificate. Use --help for the replay CLI.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

from build_graph import build
from oracle_bridge import ReceiptLedger, checked_receipt, load_evaluator
from retract import Genealogy

HERE = Path(__file__).resolve().parent


def outcome_verdict(result, evaluator):
    return {"confirmed": 1.0, "refuted": -1.0, "unknown": None}[checked_receipt(result, evaluator)["verdict"]]


def resolve_verdict(result, evaluator):
    verdict = outcome_verdict(result, evaluator)
    return verdict, 1.0 if verdict is not None else 0.0, "checked_run" if verdict is not None else "unknown"


def ingest_receipt(graph, receipt):
    rid = receipt["run_id"]
    outcome, claim = f"outcome:{rid}", f"claim:validation:{rid}"
    # Replace exactly this run's edges; distinct runs cannot pool attribution
    # through a shared strategy node. Replaying an outcome cannot count it twice.
    graph.edges[:] = [e for e in graph.edges if not ({e.src, e.dst} & {outcome, claim})]
    verdict = {"confirmed": 1.0, "refuted": -1.0, "unknown": None}[receipt["verdict"]]
    graph.add_node(outcome, "outcome", dict(receipt), seed=verdict)
    graph.add_node(claim, "claim", {"role": "validation_proposition", "run_id": rid,
                                    "text": f"Backtest run {rid} passed its declared validation gates.",
                                    "oracle_verdict": receipt["verdict"],
                                    "knowable_time": receipt.get("observed_at")})
    graph.add_edge(outcome, claim, "supports")
    resolved, unresolved = [], []
    for ref in sorted(set(receipt.get("claim_refs", []))):
        cid = ref if ref.startswith("claim:") else f"claim:{ref}"
        if cid in graph.nodes and cid != claim:
            graph.add_edge(cid, outcome, "feeds")  # attribution, coefficient zero
            resolved.append(cid)
        else:
            unresolved.append(ref)
    return {"run_id": rid, "verdict": receipt["verdict"], "reason": receipt["reason"],
            "claim": claim, "resolved_attribution": resolved, "unresolved_refs": unresolved}


def ingest_outcome(graph, result, oid=None, *, evaluator):
    receipt = checked_receipt(result, evaluator)
    if oid is not None and oid != receipt["run_id"]:
        raise ValueError("caller outcome id disagrees with checked run identity")
    return ingest_receipt(graph, receipt)


def materialize(receipts):
    graph = build()
    reports = [ingest_receipt(graph, r) for r in receipts]
    graph.propagate()
    return graph, reports


def support_graph(receipts):
    """Logical support is separate from signed descriptive trust."""
    genealogy = Genealogy()
    for r in receipts:
        premise = "oracle:" + r["run_id"]
        genealogy.add_premise(premise, {"confirmed": True, "refuted": False, "unknown": None}[r["verdict"]])
        genealogy.justify("passes_validation:" + r["run_id"], {premise})
    return genealogy


def revision_report(before, after):
    old, new = support_graph(before).grounded(), support_graph(after).grounded()
    return {"withdrawn": sorted(old - new), "newly_grounded": sorted(new - old), "retained": sorted(old & new)}


def graph_document(graph):
    return {"summary": graph.summary(),
            "nodes": [{"id": n.id, "kind": n.kind, "trust": n.trust,
                       "seed": n.seed, "attrs": n.attrs} for n in graph.nodes.values()],
            "edges": [{"src": e.src, "dst": e.dst, "kind": e.kind,
                       "weight": e.weight, "attrs": e.attrs} for e in graph.edges]}


def augmented_index(receipts):
    index = json.loads((HERE / "claims_index.json").read_text())
    for r in receipts:
        rid = r["run_id"]
        index["claims"]["validation:" + rid] = {
            "text": f"Backtest run {rid} passed its declared validation gates.",
            "domain": "statistical_validation", "claim_type": "run_validation",
            "evidence_basis": "oracle_receipt", "source_id": "oracle:" + rid,
            "knowable_time": r.get("observed_at"), "event_time": None,
            "oracle_verdict": r["verdict"], "evidence_id": r["evidence_id"]}
    index["count"] = len(index["claims"])
    return index


def ingest_files(paths, *, oracle_repo, ledger_path=HERE / "runtime/oracle.sqlite"):
    ledger = ReceiptLedger(ledger_path)
    try:
        ledger.ingest_files(paths, load_evaluator(oracle_repo))
        return materialize(ledger.snapshots())
    finally:
        ledger.close()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("results", nargs="*")
    parser.add_argument("--oracle-repo", type=Path, default=Path.home() / "projects")
    parser.add_argument("--ledger", type=Path, default=HERE / "runtime/oracle.sqlite")
    parser.add_argument("--as-of")
    parser.add_argument("--withdraw", action="append", default=[])
    parser.add_argument("--reinstate", action="append", type=int, default=[], help="explicitly restore a historical revision")
    parser.add_argument("--reason")
    parser.add_argument("--selftest", action="store_true")
    args = parser.parse_args()
    if args.selftest:
        import unittest
        suite = unittest.defaultTestLoader.discover(str(HERE), pattern="test_oracle_bridge.py")
        if not unittest.TextTestRunner(verbosity=1).run(suite).wasSuccessful():
            raise SystemExit(1)
        return
    if (args.withdraw or args.reinstate) and not args.reason:
        parser.error("--withdraw/--reinstate requires --reason")
    ledger = ReceiptLedger(args.ledger)
    try:
        before = ledger.snapshots()
        actions = ledger.ingest_files(args.results, load_evaluator(args.oracle_repo)) if args.results else []
        actions += [ledger.withdraw(rid, args.reason) for rid in args.withdraw]
        actions += [ledger.reinstate(revision, args.reason) for revision in args.reinstate]
        after = ledger.snapshots(args.as_of)
        _, reports = materialize(after)
        print(json.dumps({"actions": actions, "support_changes": revision_report(before, ledger.snapshots()),
                          "receipts": reports, "as_of": args.as_of}, indent=2))
    finally:
        ledger.close()


if __name__ == "__main__":
    main()
