#!/usr/bin/env python3
"""Ingest oracle-checked backtest outcomes into the epistemic graph — the live
half of the Layer 7 loop.

Reads backtest result JSONs (as `strategy-core` now emits them: an `attribution`
block with `claim_refs`, and a `validation` certificate with a pass/fail verdict),
and for each one propagates the checked outcome *backward* to the specific corpus
claims the strategy leaned on. This is the general mechanism the
`reverse_propagation_demo` illustrated by hand: the demo invented the attribution;
this consumes the *real* attribution a result carries.

Verdict mapping: `validation.passed == True` -> +1 (the strategy the claims fed
survived out-of-sample + the nulls), `False` -> -1. A single outcome is a noisy,
modest signal (implicate edge weight 0.3, per epistemic_graph); confidence over a
claim accrues only as independent outcomes accumulate.

Usage:
  python3 corpus/ingest_outcomes.py RESULT.json [RESULT.json ...]   # ingest real results
  python3 corpus/ingest_outcomes.py --selftest
"""
import json
import os
import sys

from build_graph import build
from epistemic_graph import EpistemicGraph

try:
    from estimand import Leg, colimit   # graded reverse-prop (typed grounding)
except Exception:                        # optional: legacy ±1 path works without it
    Leg = colimit = None

HERE = os.path.dirname(os.path.abspath(__file__))


def outcome_verdict(result: dict):
    """Map a backtest result's validation certificate to a signed verdict, or None
    if the result carries no usable verdict."""
    val = result.get("validation")
    if isinstance(val, dict) and "passed" in val:
        return 1.0 if val["passed"] else -1.0
    # a run that errored or never validated carries no verdict
    return None


def resolve_verdict(result: dict):
    """(verdict, edge_weight, mode). If the result carries a structured `grounding`
    block (mechanism-entailed legs), grade it via the estimand colimit — an ungrounded
    apex yields (0.0, 0.0, 'refused'): the brain declines to update belief from a signal
    whose facts do not bind, and multiplicity sets the edge weight (a multiply-realized
    apex moves upstream trust more than a lone pattern). Otherwise fall back to the legacy
    pass/fail -> ±1 at the flat 0.3 weight, so existing results keep working unchanged."""
    grounding = result.get("grounding")
    if grounding and colimit is not None:
        legs = []
        for d in grounding:
            d = dict(d)
            d["provenance"] = frozenset(d.get("provenance", []))
            legs.append(Leg(**d))
        apex = (result.get("attribution", {}) or {}).get("hypothesis_id", "apex")
        r = colimit(apex, legs)
        return (r.verdict, r.edge_weight, "grounded" if r.grounded else "refused")
    v = outcome_verdict(result)
    if v is None:
        return (None, 0.0, "no_verdict")
    return (v, 0.3, "legacy")


def ingest_outcome(g: EpistemicGraph, result: dict, oid: str) -> dict:
    """Attach one backtest outcome to the graph and reverse-propagate it to the
    claims named in result['attribution']['claim_refs']. Returns a report."""
    attrib = result.get("attribution", {}) or {}
    claim_refs = attrib.get("claim_refs", []) or []
    verdict, edge_weight, mode = resolve_verdict(result)
    report = {"outcome_id": oid, "verdict": verdict, "edge_weight": edge_weight,
              "mode": mode, "claim_refs": claim_refs,
              "resolved": [], "unresolved_refs": [], "skipped_reason": None}
    if verdict is None:
        report["skipped_reason"] = "no validation verdict on result"
        return report
    if not claim_refs:
        report["skipped_reason"] = "no attribution.claim_refs on result (attribution not yet populated upstream)"
        return report

    sid = f"strategy:{attrib.get('hypothesis_id', oid)}"
    if sid not in g.nodes:
        g.add_node(sid, "claim", {"synthetic": False, "role": "strategy",
                                  "hypothesis_id": attrib.get("hypothesis_id")})
    onode = f"outcome:{oid}"
    g.add_node(onode, "outcome", {"verdict": verdict,
                                  "validation": result.get("validation", {})})
    for cref in claim_refs:
        cid = cref if cref.startswith("claim:") else f"claim:{cref}"
        if cid in g.nodes:
            g.add_edge(cid, sid, "feeds")
            report["resolved"].append(cid)
        else:
            report["unresolved_refs"].append(cref)
    g.add_edge(sid, onode, "feeds")
    g.implicate_from_outcome(onode, verdict=verdict, edge_weight=edge_weight)
    return report


def ingest_files(paths):
    g = build()  # base corpus graph
    reports = []
    for p in paths:
        result = json.load(open(p))
        oid = os.path.splitext(os.path.basename(p))[0]
        reports.append((p, ingest_outcome(g, result, oid)))
    g.propagate()
    return g, reports


def _selftest():
    g = build()
    # pick a real, currently-unresolved claim (trust 0) and a synthetic result
    target = "claim:003-a"
    assert abs(g.trust_of(target)) < 1e-9, g.trust_of(target)
    result = {
        "attribution": {"hypothesis_id": "hyp_selftest", "claim_refs": ["003-a", "003-b"]},
        "validation": {"passed": False},
    }
    rep = ingest_outcome(g, result, "selftest_run")
    g.propagate()
    assert rep["resolved"] == ["claim:003-a", "claim:003-b"], rep
    assert g.trust_of(target) < 0.0, g.trust_of(target)          # failed backtest -> negative
    # a result with no claim_refs is skipped, not crashed on
    rep2 = ingest_outcome(g, {"validation": {"passed": True}}, "no_attrib")
    assert rep2["skipped_reason"], rep2

    # graded path: a result carrying a structured `grounding` block is scored by the
    # estimand colimit. A grounded, multiply-realized apex updates trust with an edge
    # weight > the flat 0.3; a refused apex (a leg fails) does NOT move trust at all.
    if colimit is not None:
        grounded_legs = [
            {"name": "edge_all_holds", "kind": "prediction", "effect": 5.4,
             "stderr": 1.9, "provenance": ["NQ_ts"], "direction": 1},
            {"name": "ablation_collapses", "kind": "necessity", "effect": -0.2,
             "stderr": 1.2, "provenance": ["NQ_abl"]},
            {"name": "cross_present", "kind": "specificity", "effect": 5.4, "stderr": 1.9,
             "provenance": ["cross"], "direction": 1, "present": True},
        ]
        g2 = build()
        rg = ingest_outcome(g2, {
            "attribution": {"hypothesis_id": "hyp_grounded", "claim_refs": ["003-a"]},
            "grounding": grounded_legs}, "grounded_run")
        g2.propagate()
        assert rg["mode"] == "grounded" and rg["edge_weight"] > 0.3, rg
        assert g2.trust_of("claim:003-a") > 0.0, g2.trust_of("claim:003-a")

        refused_legs = list(grounded_legs)
        refused_legs[1] = {"name": "ablation_collapses", "kind": "necessity",
                           "effect": 4.0, "stderr": 1.2, "provenance": ["NQ_abl"]}
        g3 = build()
        rr = ingest_outcome(g3, {
            "attribution": {"hypothesis_id": "hyp_refused", "claim_refs": ["003-a"]},
            "grounding": refused_legs}, "refused_run")
        g3.propagate()
        assert rr["mode"] == "refused" and rr["edge_weight"] == 0.0, rr
        assert abs(g3.trust_of("claim:003-a")) < 1e-9, g3.trust_of("claim:003-a")

    print("ingest_outcomes selftest: PASS "
          "(legacy claim_refs resolved + reverse-propagated; missing attribution skipped; "
          "graded grounding updates trust, refused grounding does not)")


def main():
    if "--selftest" in sys.argv:
        _selftest()
        return
    paths = [a for a in sys.argv[1:] if not a.startswith("-")]
    if not paths:
        print("usage: ingest_outcomes.py RESULT.json [...]  |  --selftest")
        return
    g, reports = ingest_files(paths)
    print("== ingested backtest outcomes ==")
    for p, rep in reports:
        print(f"\n{os.path.basename(p)}: verdict={rep['verdict']} "
              f"resolved={[c.split(':')[1] for c in rep['resolved']]} "
              f"{'SKIPPED: '+rep['skipped_reason'] if rep['skipped_reason'] else ''}")
        for cid in rep["resolved"]:
            print(f"    {cid:16} -> trust {g.trust_of(cid):+.3f}")
        if rep["unresolved_refs"]:
            print(f"    (claim_refs not in corpus: {rep['unresolved_refs']})")


if __name__ == "__main__":
    main()
