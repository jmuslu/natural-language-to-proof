"""Direct observed evidence for the retrieval store, separate from graph scores.

Only the local checked-receipt journal currently supplies factual labels. This
checks the materialized snapshot's identity and consistency, not cryptographic
producer authenticity. References, owner quality labels, and graph propagation
cannot enter this channel. A future fact-attestation importer needs its own
explicit validation contract.
"""
from __future__ import annotations

import json

from oracle_bridge import IDENTIFIER, SCHEMA, cutoff


def validation_text(run_id):
    return f"Backtest run {run_id} passed its declared validation gates."


def observation(receipt):
    """Normalize one observed receipt; missing/malformed provenance fails closed."""
    if not isinstance(receipt, dict) or receipt.get("schema") != SCHEMA:
        return None
    rid, eid = receipt.get("run_id"), receipt.get("evidence_id")
    if not all(isinstance(v, str) and IDENTIFIER.fullmatch(v) for v in (rid, eid)):
        return None
    proposition = {"kind": "passes_validation", "run_id": rid}
    if receipt.get("proposition") != proposition:
        return None
    verdict = receipt.get("verdict")
    if verdict not in ("confirmed", "refuted", "unknown"):
        return None
    observed = receipt.get("observed_at")
    # Journal observations are zoned instants, never inferred publication dates.
    if not isinstance(observed, str) or len(observed) <= 10:
        return None
    try:
        observed = cutoff(observed)
    except (TypeError, ValueError, OverflowError):
        return None
    return {"source": "oracle_receipt", "proposition": proposition,
            "verdict": verdict, "evidence_id": eid, "observed_at": observed}


def read_observation(value, as_of=None):
    """Validate persisted metadata and mask evidence not yet observed at as_of."""
    try:
        value = json.loads(value) if isinstance(value, str) else value
        if not isinstance(value, dict) or value.get("source") != "oracle_receipt":
            return None
        prop = value.get("proposition", {})
        if not isinstance(prop, dict):
            return None
        result = observation({"schema": SCHEMA, "run_id": prop.get("run_id"),
                              "proposition": prop, "verdict": value.get("verdict"),
                              "evidence_id": value.get("evidence_id"),
                              "observed_at": value.get("observed_at")})
        end = cutoff(as_of)
        if result is None or (end is not None and result["observed_at"] > end):
            return None
        return result
    except (TypeError, ValueError, OverflowError):
        return None


def direct_evidence(claim_id, claim, graph):
    """Join an exact scoped proposition to its own direct journal outcome.

    Copying metadata to a source claim or adding corroboration edges cannot
    confer a check. Duplicate graph identities, stale mismatches, and malformed
    snapshots fail closed. The graph's propagated trust is never inspected.
    """
    check = read_observation(claim.get("check_provenance"))
    if check is None:
        return None
    rid = check["proposition"]["run_id"]
    if (claim_id != "validation:" + rid or claim.get("source_id") != "oracle:" + rid
            or claim.get("claim_type") != "run_validation"
            or claim.get("evidence_basis") != "oracle_receipt"
            or claim.get("text") != validation_text(rid)):
        return None
    cid, oid = "claim:" + claim_id, "outcome:" + rid
    claims = [n for n in graph.get("nodes", []) if n.get("id") == cid]
    outcomes = [n for n in graph.get("nodes", []) if n.get("id") == oid]
    if len(claims) != 1 or len(outcomes) != 1:
        return None
    node, outcome = claims[0], outcomes[0]
    if (node.get("kind") != "claim" or outcome.get("kind") != "outcome"
            or read_observation(node.get("attrs", {}).get("check_provenance")) != check
            or observation(outcome.get("attrs")) != check):
        return None
    edges = [e for e in graph.get("edges", []) if e.get("src") == oid and e.get("dst") == cid]
    if len(edges) != 1 or edges[0].get("kind") != "supports" or edges[0].get("weight", 1) != 1:
        return None
    return check


def fields(value, as_of=None):
    check = read_observation(value, as_of)
    verdict = check["verdict"] if check else "unknown"
    return {"checked": verdict in ("confirmed", "refuted"),
            "check_verdict": verdict,
            "check_value": {"confirmed": 1.0, "refuted": -1.0}.get(verdict),
            "check_evidence_id": check["evidence_id"] if check else None,
            "check_observed_at": check["observed_at"] if check else None,
            "check_source": check["source"] if check else None}
