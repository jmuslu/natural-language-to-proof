#!/usr/bin/env python3
"""Worked example of reverse propagation (main handoff Layer 7) on the REAL corpus
graph: a claim that no external reference could settle gets a delayed, indirect
verdict once a strategy that leaned on it is backtested.

This is a DEMONSTRATION of the mechanism, not real data. The attribution link
("strategy S leaned on claims X, Y") and the backtest outcome are synthetic and
labelled as such. Real attribution logging -- recording which claims a strategy
used, at generation time -- is the un-built prerequisite the handoff flags (Layer
7, "it isn't free the way exact derivation dependency is in Genealogy.hs"); this
script shows what the graph does *once that link exists*, so the value of building
attribution logging is concrete rather than abstract.

The point it makes: records 003-a/003-b ("~29%/year unleveraged", ">200%
leveraged") are `unresolved` under direct reference-checking -- no external
source in hand settles them, so they sit at trust 0. But if a strategy built on
those return claims is run through the Layer 3 validation suite and the
certificate comes back failing (no out-of-sample edge, doesn't beat the nulls),
that oracle-checked outcome propagates backward to implicate exactly those claims.
An unverifiable claim becomes verifiable, indirectly, through a downstream check.
"""
from build_graph import build


def demo(outcome_verdict: float, n_outcomes: int, label: str):
    g = build()  # the real corpus graph, propagated
    claim_ids = ["claim:003-a", "claim:003-b"]
    before = {c: g.trust_of(c) for c in claim_ids}

    # --- SYNTHETIC attribution + outcome(s) (not real corpus data) ---
    g.add_node("strategy:demo_stablecoin_mm", "claim",
               {"synthetic": True, "note": "stand-in strategy node built on the return claims"})
    for c in claim_ids:
        g.add_edge(c, "strategy:demo_stablecoin_mm", "feeds")
    for i in range(n_outcomes):
        oid = f"outcome:demo_backtest_{i}"
        g.add_node(oid, "outcome", {"synthetic": True, "verdict": outcome_verdict, "note": label})
        g.add_edge("strategy:demo_stablecoin_mm", oid, "feeds")
        g.implicate_from_outcome(oid, verdict=outcome_verdict)
    g.propagate()
    after = {c: g.trust_of(c) for c in claim_ids}
    return before, after


def main():
    print("== Reverse-propagation demonstration (SYNTHETIC attribution + outcome) ==")
    print("Real corpus claims 003-a/003-b are `unresolved` by direct checking (trust 0).")
    print("A single backtest is a noisy signal, so one outcome moves a claim only")
    print("modestly; confidence accrues as independent outcomes accumulate (Layer 7).")
    print()

    for verdict, n, label in [(-1.0, 1, "1 backtest FAILED (noisy single signal)"),
                              (-1.0, 5, "5 independent backtests FAILED (accumulating)"),
                              (+1.0, 5, "5 independent backtests PASSED (accumulating)")]:
        before, after = demo(verdict, n, label)
        print(f"-- {label} --")
        for c in before:
            print(f"   {c:14} trust {before[c]:+.3f} -> {after[c]:+.3f}")
        print()
    print("Takeaway: with an attribution link, oracle-checked outcomes propagate "
          "backward to the claims that fed a strategy -- the same reverse shape as "
          "Genealogy's retraction propagation, stretched across news->strategy->"
          "backtest. One outcome is weak; calibration across many is the real "
          "signal. Building real attribution logging turns this from a demo into "
          "a live signal.")


if __name__ == "__main__":
    main()
