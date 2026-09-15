#!/usr/bin/env python3
"""Assemble exploratory graph scores from corpus records and reference proposals.

Scores retain their source provenance; pending reference interpretations and
source-level owner judgments are not checked factual labels. Direct observed
run receipts enter through ingest_outcomes and remain scoped to their runs.
"""
import glob
import json
import os
from pathlib import Path

from epistemic_graph import EpistemicGraph

HERE = os.path.dirname(os.path.abspath(__file__))
CONF_W = {"high": 0.9, "medium": 0.6, "low": 0.3, "n/a": 0.0}
OWNER_CONF_W = {"firm": 0.9, "tentative": 0.5, "uncertain": 0.0, "none": 0.0}
OWNER_SIGN = {"consistent": +1, "inconsistent": -1, "ambiguous": 0, "unlabeled": 0}


def load():
    records = [json.loads(Path(f).read_text()) for f in sorted(glob.glob(os.path.join(HERE, "records", "*.json")))]
    vpath = os.path.join(HERE, "verdicts_agent_proposed.json")
    verdicts = json.loads(Path(vpath).read_text())["verdicts"] if os.path.exists(vpath) else []
    return records, verdicts


def claim_of_verdict(cid):
    """Verdict ids may be sub-claims (e.g. 001-4-b-target); map to the record claim."""
    tail = cid.rsplit("-", 1)[-1]
    return cid.rsplit("-", 1)[0] if tail in ("target", "cci") else cid


def build():
    records, verdicts = load()
    g = EpistemicGraph()
    domains = set()

    for rec in records:
        sid = f"source:{rec['record_id']}"
        g.add_node(sid, "source", {"title": rec["title"], "format": rec["format"],
                                   "length_words": rec["length"]["raw_word_count"]})
        # owner label as an external-check node about the source
        ol = rec["owner_label"]
        sign = OWNER_SIGN.get(ol["class"], 0)
        w = OWNER_CONF_W.get(ol["confidence"], 0.0)
        if sign != 0 and w > 0:
            olid = f"ownerlabel:{rec['record_id']}"
            # seed is the checker's RELIABILITY (always positive); the edge sign
            # carries the verdict direction, so a contradict edge (coeff -1) times
            # a positive seed yields negative trust -- not the double-negative of a
            # signed seed on a signed edge.
            g.add_node(olid, "owner_label", {"class": ol["class"], "confidence": ol["confidence"]},
                       seed=w)
            g.add_edge(olid, sid, "supports" if sign > 0 else "contradicts", weight=1.0)
        for c in rec["claims"]:
            cid = f"claim:{c['claim_id']}"
            g.add_node(cid, "claim", {"text": c["claim_text"], "claim_type": c["claim_type"],
                                        "verification_status": c.get("verification_status", "not_performed"),
                                        "consistency_verdict": c.get("consistency_verdict")})
            g.add_edge(sid, cid, "asserts")
            dom = c["domain"]
            domains.add(dom)
            did = f"domain:{dom}"
            if did not in g.nodes:
                g.add_node(did, "domain", {"name": dom})
            g.add_edge(cid, did, "in_domain")

    # Reference proposals seed exploratory scores only; they do not establish checks.
    for vd in verdicts:
        parent = claim_of_verdict(vd["claim_id"])
        cid = f"claim:{parent}"
        if cid not in g.nodes:
            continue
        if vd["verdict"] == "unresolved":
            continue  # no trust originated for unresolved claims
        w = CONF_W.get(vd["confidence"], 0.0)
        if w <= 0:
            continue
        rid = f"ref:{vd['claim_id']}"
        # positive seed = the reference's reliability; edge sign = the verdict.
        g.add_node(rid, "reference",
                   {"reference": vd["checkable_reference"], "verdict": vd["verdict"],
                    "verdict_source": vd["verdict_source"],
                    "verification_status": vd.get("verification_status", "unverified"),
                    "claim_id": vd["claim_id"], "score_role": "exploratory_proposal"},
                   seed=w)
        g.add_edge(rid, cid, "supports" if vd["verdict"] == "consistent" else "contradicts", weight=1.0)

    g.propagate()
    return g


def main():
    g = build()
    # emit graph.json
    nodes = [{"id": n.id, "kind": n.kind, "trust": round(n.trust, 4),
              "seed": n.seed, "attrs": n.attrs} for n in g.nodes.values()]
    edges = [{"src": e.src, "dst": e.dst, "kind": e.kind, "weight": e.weight} for e in g.edges]
    out = {"summary": g.summary(), "nodes": nodes, "edges": edges}
    with open(os.path.join(HERE, "graph.json"), "w") as fh:
        json.dump(out, fh, indent=2)

    print("== epistemic graph ==")
    print("summary:", g.summary())
    print()
    print("source trust (claim aggregate + owner-label evidence; descriptive, domain-blind read-off):")
    for n in sorted((n for n in g.nodes.values() if n.kind == "source"), key=lambda n: n.id):
        print(f"  {n.id:12} trust={n.trust:+.3f}  {n.attrs.get('format'):16} {n.attrs['title'][:44]}")
    print()
    print("claims with a proposed verdict, by resulting trust:")
    scored = [n for n in g.nodes.values() if n.kind == "claim" and abs(n.trust) > 1e-9]
    for n in sorted(scored, key=lambda n: -n.trust):
        print(f"  {n.id:16} trust={n.trust:+.3f}  {n.attrs['text'][:60]}")
    print()
    unresolved = [n for n in g.nodes.values() if n.kind == "claim" and abs(n.trust) < 1e-9]
    print(f"claims with no nonzero exploratory score: {len(unresolved)}")
    print("wrote graph.json")


if __name__ == "__main__":
    main()
