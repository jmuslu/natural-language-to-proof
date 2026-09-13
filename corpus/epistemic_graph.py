"""A bidirectional epistemic graph: claims, sources, references and outcomes as
nodes, with information propagating both ways along typed edges.

This is the graph-shaped store the corpus and the (future) backtest outcomes feed
into. It is the epistemic analog of `Genealogy.hs`'s provenance DAG in the main
pipeline: forward, corroboration and support flow from evidence to claims to
sources; backward, an oracle-checked outcome implicates the claims that fed it and
onward to their sources (the reverse-propagation of the main handoff's Layer 7,
the same shape as Genealogy's retraction propagation). Nothing here decides a
mechanism Layer 5 is meant to keep open — see the note on `propagate` — it
provides the structure and one transparent, inert-by-default aggregation.

The load-bearing discipline, straight from the main handoff's Layer 8 (entropy
Version A vs B): **trust originates only from external checks.** Reference
verdicts, owner labels and oracle outcomes are the only trust *sources*.
Claim-to-claim corroboration can *amplify* trust that already has an external
root, but a cluster of mutually-corroborating claims with no external check stays
at zero — the echo chamber gets nothing, no matter how internally coherent. That
property is what keeps this a Version-A store (anchored to things that get
checked) rather than a Version-B one (coherence with itself). It is tested
directly in the self-test.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Optional


# Node kinds. `reference`, `owner_label` and `outcome` are *external-check*
# kinds -- the only ones allowed to originate trust.
EXTERNAL_KINDS = {"reference", "owner_label", "outcome"}
NODE_KINDS = {"source", "claim", "domain"} | EXTERNAL_KINDS

# Edge kinds and their sign (+1 support, -1 contradiction, 0 structural/no trust).
EDGE_SIGN = {
    "asserts": 0,          # source --asserts--> claim   (structural provenance)
    "in_domain": 0,        # claim --in_domain--> domain (structural)
    "checked_against": 0,  # claim --checked_against--> reference (structural link)
    "supports": +1,        # reference/outcome --supports--> claim (external evidence)
    "contradicts": -1,     # reference/outcome --contradicts--> claim (external evidence)
    "corroborates": +1,    # claim --corroborates--> claim (amplifier, not originator)
    "feeds": 0,            # claim --feeds--> strategy/outcome (forward provenance)
    "implicates": +1,      # outcome --implicates--> claim (reverse propagation; signed by outcome)
}


@dataclass
class Node:
    id: str
    kind: str
    attrs: dict = field(default_factory=dict)
    # trust in [-1, 1]; None until computed. Seed trust set on external-check nodes.
    seed: Optional[float] = None
    trust: float = 0.0


@dataclass
class Edge:
    src: str
    dst: str
    kind: str
    weight: float = 1.0
    attrs: dict = field(default_factory=dict)


class EpistemicGraph:
    def __init__(self):
        self.nodes: dict[str, Node] = {}
        self.edges: list[Edge] = []

    # -- construction -------------------------------------------------------
    def add_node(self, id, kind, attrs=None, seed=None):
        assert kind in NODE_KINDS, f"unknown node kind {kind}"
        if seed is not None:
            assert kind in EXTERNAL_KINDS, (
                f"only external-check nodes may seed trust, not {kind} "
                f"(Layer-8 Version-A discipline)")
        self.nodes[id] = Node(id, kind, attrs or {}, seed, seed or 0.0)
        return id

    def add_edge(self, src, dst, kind, weight=1.0, attrs=None):
        assert kind in EDGE_SIGN, f"unknown edge kind {kind}"
        assert src in self.nodes and dst in self.nodes, f"edge over missing node: {src}->{dst}"
        self.edges.append(Edge(src, dst, kind, weight, attrs or {}))

    # -- traversal (both directions) ---------------------------------------
    def out_edges(self, nid):
        return [e for e in self.edges if e.src == nid]

    def in_edges(self, nid):
        return [e for e in self.edges if e.dst == nid]

    # -- propagation --------------------------------------------------------
    def propagate(self, iterations: int = 50, corroboration_gain: float = 0.25,
                  damping: float = 1.0) -> None:
        """Compute node trust to a fixed point.

        [stipulated] This is one transparent aggregation, deliberately inert by
        default; the *dynamics* of how trust updates over time (edge-weight vs
        edge-existence vs node-level propagation) are the main handoff's Layer 5
        open question and are NOT decided here. What is fixed, and load-bearing,
        is the Version-A anchor: a node's trust is seeded only by external-check
        nodes; every other node's trust is a function of trust reaching it along
        signed edges. Corroboration between claims (`corroborates`) is capped and
        multiplicative on already-present trust, so it can amplify an
        externally-rooted claim but cannot manufacture trust from nothing.
        """
        for n in self.nodes.values():
            n.trust = n.seed if n.seed is not None else 0.0

        # per-edge-kind trust coefficient. `corroborates` is a *weaker* signed
        # relay (gain < 1), so it carries externally-rooted trust to independently
        # corroborating claims but, with no external seed anywhere, the whole
        # system stays at its all-zeros fixed point -- the echo chamber gets
        # nothing. (Whether a `corroborates` edge reflects *genuinely independent*
        # corroboration vs. a restatement is an edge-construction question, guarded
        # upstream where the edge is added, not here.)
        coeff = {"supports": 1.0, "contradicts": -1.0, "implicates": 1.0,
                 "corroborates": corroboration_gain}

        for _ in range(iterations):
            new = {}
            for nid, n in self.nodes.items():
                if n.seed is not None:
                    new[nid] = n.seed          # external seeds are pinned
                    continue
                if n.kind in ("source", "domain"):
                    # descriptive, domain-scoped aggregate of this node's claims'
                    # trust, PLUS any direct external judgment about the node itself
                    # (e.g. an owner_label supporting/contradicting a source). Never
                    # fed forward to lighten scrutiny of the source's next claim
                    # (halo guard) -- this is a read-off, not an input to per-claim
                    # verification.
                    claim_trusts = [self.nodes[e.dst].trust
                                    for e in self.out_edges(nid)
                                    if e.kind in ("asserts", "in_domain")]
                    agg = (sum(claim_trusts) / len(claim_trusts)) if claim_trusts else 0.0
                    ext = 0.0
                    for e in self.in_edges(nid):
                        c = coeff.get(e.kind, 0.0)
                        if c:
                            ext += c * e.weight * self.nodes[e.src].trust
                    new[nid] = _clamp(agg + ext)
                    continue
                acc = 0.0
                for e in self.in_edges(nid):
                    c = coeff.get(e.kind, 0.0)
                    if c:
                        acc += c * e.weight * self.nodes[e.src].trust
                new[nid] = _clamp(acc) * damping
            for nid, t in new.items():
                self.nodes[nid].trust = t

    # -- reverse propagation (Layer 7 shape) --------------------------------
    def implicate_from_outcome(self, outcome_id: str, verdict: float,
                               edge_weight: float = 0.3) -> list[str]:
        """An oracle-checked outcome implicates the claims that fed it.

        Records `implicates` edges (outcome -> claim) for every claim that reaches
        `outcome_id` backward through `feeds` edges, seeds the outcome node with
        the signed verdict, and returns the implicated claim ids. This is the
        reverse half of "information propagates both ways": a forward `feeds`
        chain (claim -> ... -> outcome) becomes a backward implication once the
        outcome is checked. The trust effect then falls out of `propagate`.

        `edge_weight` is deliberately small (default 0.3): a single backtest is a
        *noisy* signal about any upstream claim (a strategy can fail for reasons
        unrelated to whether the claim was true), so one outcome must move a claim
        only modestly. Confidence accrues from *many* independent outcomes — each
        adds another `implicates` edge and the contributions sum in `propagate`
        (saturating via the clamp) — which is the calibration-over-many-instances
        signal the handoff's Layer 7 calls for, not a single P&L verdict.
        """
        assert self.nodes[outcome_id].kind == "outcome"
        self.nodes[outcome_id].seed = _clamp(verdict)
        self.nodes[outcome_id].trust = _clamp(verdict)
        implicated = []
        # walk backward over feeds edges to find contributing claims
        frontier = [outcome_id]
        seen = set()
        while frontier:
            cur = frontier.pop()
            for e in self.in_edges(cur):
                if e.kind == "feeds" and e.src not in seen:
                    seen.add(e.src)
                    if self.nodes[e.src].kind == "claim":
                        implicated.append(e.src)
                        self.add_edge(outcome_id, e.src, "implicates", weight=edge_weight)
                    frontier.append(e.src)
        return implicated

    def trust_of(self, nid):
        return self.nodes[nid].trust

    def summary(self):
        by_kind = {}
        for n in self.nodes.values():
            by_kind.setdefault(n.kind, 0)
            by_kind[n.kind] += 1
        return {"nodes": len(self.nodes), "edges": len(self.edges), "by_kind": by_kind}


def _clamp(x, lo=-1.0, hi=1.0):
    return max(lo, min(hi, x))


# ---------------------------------------------------------------------------
# self-test: the checker is validated on synthetic ground truth
# ---------------------------------------------------------------------------

def _selftest():
    # 1) echo chamber gets nothing: three claims mutually corroborating, NO
    #    external check -> all trust stays 0.
    g = EpistemicGraph()
    for c in ("c1", "c2", "c3"):
        g.add_node(c, "claim")
    for a, b in (("c1", "c2"), ("c2", "c3"), ("c3", "c1"), ("c2", "c1"), ("c3", "c2"), ("c1", "c3")):
        g.add_edge(a, b, "corroborates")
    g.propagate()
    assert all(abs(g.trust_of(c)) < 1e-9 for c in ("c1", "c2", "c3")), \
        {c: g.trust_of(c) for c in ("c1", "c2", "c3")}

    # 2) one external reference roots the cluster -> trust propagates and
    #    corroboration amplifies (rooted claim >= its raw external evidence).
    g.add_node("ref1", "reference", seed=1.0)
    g.add_edge("ref1", "c1", "supports", weight=0.6)
    g.propagate()
    assert g.trust_of("c1") >= 0.6 - 1e-9, g.trust_of("c1")
    assert g.trust_of("c2") > 0.0, g.trust_of("c2")   # amplified via corroboration from c1

    # 3) a contradicting reference pushes a claim negative
    g2 = EpistemicGraph()
    g2.add_node("c", "claim")
    g2.add_node("r", "reference", seed=1.0)
    g2.add_edge("r", "c", "contradicts", weight=0.8)
    g2.propagate()
    assert g2.trust_of("c") <= -0.8 + 1e-9, g2.trust_of("c")

    # 4) reverse propagation: a failed outcome implicates the claims that fed it,
    #    but ONE outcome is only a modest (noisy) signal...
    g3 = EpistemicGraph()
    g3.add_node("claimA", "claim")
    g3.add_node("out1", "outcome")
    g3.add_edge("claimA", "out1", "feeds")
    implicated = g3.implicate_from_outcome("out1", verdict=-1.0)
    assert implicated == ["claimA"], implicated
    g3.propagate()
    one = g3.trust_of("claimA")
    assert -0.5 < one < 0.0, one          # negative but modest, not saturated

    # ...and confidence accrues as independent outcomes accumulate (calibration).
    for i in range(6):
        g3.add_node(f"outN{i}", "outcome")
        g3.add_edge("claimA", f"outN{i}", "feeds")
        g3.implicate_from_outcome(f"outN{i}", verdict=-1.0)
    g3.propagate()
    many = g3.trust_of("claimA")
    assert many < one, (one, many)        # more failed outcomes -> stronger negative
    assert many <= -0.9, many             # accumulates toward saturation

    print("epistemic_graph selftest: PASS "
          "(echo chamber -> 0; external check roots + amplifies; contradiction -> negative; "
          "one outcome = modest reverse signal, many accumulate toward saturation)")


if __name__ == "__main__":
    _selftest()
