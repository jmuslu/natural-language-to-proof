#!/usr/bin/env python3
"""Layer 5: fit the epistemic graph's trust-update *parameters* against an
external fitness function.

The main handoff draws a hard line for the graph-trust mechanism: searching
*parameter values within one fixed topology* (thresholds, magnitudes) is
legitimate brute-force-plus-verify; searching *which mechanism shape is correct*
by the system's own internal metric is the trap. This module does only the former,
and grades it only by the latter's opposite -- calibration against **held-out,
externally-checked** claim outcomes -- so no parameter is ever chosen because it
made the graph more internally coherent.

The fixed topology is `epistemic_graph.propagate` (trust originates only from
external checks; corroboration relays, threshold gates). The tunable parameters
are `corroboration_gain` (how much an externally-rooted claim lifts the claims
that independently corroborate it) and `threshold` (inert-below). The fitness is
`discrimination`: among claims with a known external outcome, do the ones the
graph trusts more actually resolve true more often? Fitting is train/test split so
the reported number is generalisation, not overfit -- the same discipline as the
type-change induction.

Load-bearing property, checked in the self-test: on a graph with **no** external
anchoring (a pure corroboration cluster), no parameter setting produces
discrimination -- the echo chamber cannot be fit into a signal. Parameters only
help when there is real external evidence to propagate.
"""
from __future__ import annotations

from epistemic_graph import EpistemicGraph


def _confidences(g: EpistemicGraph, gain: float, threshold: float,
                 ids: list[str]) -> dict:
    g.propagate(corroboration_gain=gain, threshold=threshold)
    # map trust in [-1,1] to a confidence in [0,1]
    return {i: (g.trust_of(i) + 1.0) / 2.0 for i in ids}


def discrimination(pairs: list[tuple[float, int]]) -> float:
    """Outcome rate among above-median-confidence claims minus the rate among the
    rest. > 0 means graph trust predicts real resolution; ~0 means it does not.
    (Same robust stand-in for AUC used in the calibration module.)"""
    if len(pairs) < 2:
        return 0.0
    confs = sorted(c for c, _ in pairs)
    med = confs[len(confs) // 2]
    hi = [o for c, o in pairs if c >= med]
    lo = [o for c, o in pairs if c < med]
    if not hi or not lo:
        return 0.0
    return (sum(hi) / len(hi)) - (sum(lo) / len(lo))


DEFAULT_GRID = [(g, t) for g in (0.0, 0.1, 0.25, 0.5, 0.75, 1.0)
                for t in (0.0, 0.05, 0.1, 0.2)]


def fit(g: EpistemicGraph, train_truth: dict, grid=DEFAULT_GRID):
    """Grid-search (corroboration_gain, threshold) maximising discrimination on
    the TRAIN set of externally-checked outcomes. Returns (best_params, score)."""
    ids = list(train_truth.keys())
    best, best_score = None, -2.0
    for gain, thr in grid:
        conf = _confidences(g, gain, thr, ids)
        score = discrimination([(conf[i], train_truth[i]) for i in ids])
        if score > best_score:
            best, best_score = {"corroboration_gain": gain, "threshold": thr}, score
    return best, best_score


def evaluate(g: EpistemicGraph, params: dict, test_truth: dict) -> float:
    """Discrimination on a HELD-OUT set of externally-checked outcomes."""
    ids = list(test_truth.keys())
    conf = _confidences(g, params["corroboration_gain"], params["threshold"], ids)
    return discrimination([(conf[i], test_truth[i]) for i in ids])


# ---------------------------------------------------------------------------
# self-test on synthetic ground truth
# ---------------------------------------------------------------------------

def _anchored_graph(n_each=12):
    """A graph where held-out claims inherit trust, via corroboration, from
    externally-checked anchor claims -- reliable ones corroborate a supported
    anchor, unreliable ones corroborate a contradicted anchor."""
    g = EpistemicGraph()
    g.add_node("ref_good", "reference", seed=1.0)
    g.add_node("ref_bad", "reference", seed=1.0)
    g.add_node("anchor_good", "claim"); g.add_edge("ref_good", "anchor_good", "supports")
    g.add_node("anchor_bad", "claim"); g.add_edge("ref_bad", "anchor_bad", "contradicts")
    truth = {}
    for i in range(n_each):
        r = f"rel_{i}"; g.add_node(r, "claim"); g.add_edge("anchor_good", r, "corroborates")
        truth[r] = 1
        u = f"unrel_{i}"; g.add_node(u, "claim"); g.add_edge("anchor_bad", u, "corroborates")
        truth[u] = 0
    return g, truth


def _echo_graph(n=20):
    """No external anchoring: claims only corroborate each other. Truth is a
    coin-flip label unrelated to the (zero) trust."""
    g = EpistemicGraph()
    ids = [f"c_{i}" for i in range(n)]
    for i in ids:
        g.add_node(i, "claim")
    for a, b in zip(ids, ids[1:] + ids[:1]):
        g.add_edge(a, b, "corroborates")
    truth = {i: (1 if k % 2 == 0 else 0) for k, i in enumerate(ids)}
    return g, truth


def _split(truth: dict):
    # stratified: both outcome classes appear in train AND test, or there is
    # nothing to discriminate within a split.
    pos = [k for k, v in truth.items() if v == 1]
    neg = [k for k, v in truth.items() if v == 0]
    train = {k: truth[k] for k in pos[::2] + neg[::2]}
    test = {k: truth[k] for k in pos[1::2] + neg[1::2]}
    return train, test


def _selftest():
    # 1) anchored graph: fit on train, generalise to held-out test
    g, truth = _anchored_graph()
    train, test = _split(truth)
    params, train_score = fit(g, train)
    test_score = evaluate(g, params, test)
    assert train_score > 0.5, (params, train_score)
    assert test_score > 0.5, (params, test_score)          # generalises to held-out
    assert params["corroboration_gain"] > 0.0, params      # gain helps here

    # 2) echo chamber: NO external anchoring -> no parameter yields discrimination
    ge, te = _echo_graph()
    tr2, ts2 = _split(te)
    _, echo_train = fit(ge, tr2)
    assert abs(echo_train) < 1e-9, echo_train              # cannot be fit into signal

    print("fit_graph selftest: PASS "
          "(parameters fit against held-out external outcomes generalise on an "
          "anchored graph; a pure echo chamber cannot be fit into discrimination)")


if __name__ == "__main__":
    _selftest()
