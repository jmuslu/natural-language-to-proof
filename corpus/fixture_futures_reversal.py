"""fixture_futures_reversal.py — the discovery brain's first end-to-end chain.

Encodes the *authoritative* Futures-Reversal write-up (NQ intraday retail-squeeze
reversal; the private aiqs-org repo) as an apex bound by a pattern of externally-checked
legs — its five figures — and drives the reverse-propagation mechanics (estimand.py)
end-to-end:

  * grounds the real NQ signal (the colimit exists: every leg coheres);
  * REFUSES two negative controls (the KL ablation that must collapse but doesn't; the
    NQ thesis mis-applied to YM) — no belief update at all, where the old flat-0.3
    reverse-prop would have moved the claim regardless;
  * computes the basis-typed Sharpe (calendar 0.7 -> deployed ~3.3 = /sqrt(p), with the
    redeployable-capital licence attached — the "0.7 vs 5" units error made impossible);
  * composes multi-hop uncertainty (calendar Sharpe -> deployed -> portfolio-marginal),
    the posterior widening honestly with each hop;
  * feeds the GRADED verdict + multiplicity-derived edge weight into the real
    EpistemicGraph, so a grounded, multiply-realized apex moves upstream trust and an
    ungrounded one does not.

Numbers are read from the write-up's Figures 1-5 (Sept 2026). Run: python3 fixture_futures_reversal.py
"""
from __future__ import annotations

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from estimand import (Quantity, to_deployed, commensurable, Leg, colimit, Hop,
                      compose_chain, edge_weight_from_multiplicity)
from epistemic_graph import EpistemicGraph


# --- the NQ apex: five figures as checked legs ------------------------------ #
# provenance groups: {NQ_ts} = NQ time-series (Fig 2 equity, Fig 4 all-holds, Fig 3 MFE);
# {NQ_ablation} = the KL-residual mechanism swap (Fig 5); {cross_sectional} = the
# cross-instrument study (Fig 1, uses ES/YM/RTY data NQ_ts does not touch).
NQ_LEGS = [
    # Fig 4: gated net pts/trade positive across ALL holds 15-60min (peak t~2.85).
    Leg("gated_edge_all_holds", "prediction", 5.4, 1.9, frozenset({"NQ_ts"}), direction=+1),
    # Fig 4: ungated crossovers flat -> necessity of the gates.
    Leg("ungated_no_edge", "necessity", 0.3, 1.5, frozenset({"NQ_ts"})),
    # Fig 5: with KP_surprise +3.3 (p=0.0000); WITHOUT (raw |kl_accel|) -0.2 (p=0.4964)
    #        -> the ablation must COLLAPSE. This is the mechanism-dependence necessity.
    Leg("kl_ablation_collapses", "necessity", -0.2, 1.2, frozenset({"NQ_ablation"})),
    # Fig 3B: even losing trades show positive MFE (entry genuinely selects buying pressure).
    Leg("losers_move_right_first", "prediction", 10.0, 3.0, frozenset({"NQ_ts"}), direction=+1),
    # Fig 1: cross-instrument specificity. Edge PRESENT on NQ (should-work); ABSENT on
    #        ES/RTY (null) and YM (reverses -7.7 -> still no retail-long edge).
    Leg("cross_NQ_present", "specificity", 5.4, 1.9, frozenset({"cross_sectional"}),
        direction=+1, present=True),
    Leg("cross_ES_absent", "specificity", -0.2, 1.5, frozenset({"cross_sectional"}),
        direction=+1, present=False),
    Leg("cross_RTY_absent", "specificity", -0.3, 1.5, frozenset({"cross_sectional"}),
        direction=+1, present=False),
    Leg("cross_YM_absent", "specificity", -7.7, 1.6, frozenset({"cross_sectional"}),
        direction=+1, present=False),
]


def line(title):
    print(f"\n{'='*72}\n{title}\n{'='*72}")


def ground_into_graph(apex_claim: str, result) -> float:
    """Feed a grounding result into the real EpistemicGraph via implicate_from_outcome,
    using the GRADED verdict + multiplicity-derived edge weight, and return the apex
    claim's resulting trust. An ungrounded result (edge_weight 0) leaves trust at 0."""
    g = EpistemicGraph()
    g.add_node(apex_claim, "claim")
    g.add_node("outcome:grounding", "outcome")
    g.add_edge(apex_claim, "outcome:grounding", "feeds")
    g.implicate_from_outcome("outcome:grounding", verdict=result.verdict,
                             edge_weight=result.edge_weight)
    g.propagate()
    return g.trust_of(apex_claim)


def main():
    line("1. GROUND THE NQ SIGNAL (colimit of the five figures)")
    r = colimit("claim:nq_retail_squeeze", NQ_LEGS)
    print(f"grounded      : {r.grounded}")
    print(f"multiplicity  : {r.multiplicity}  (provenance-independent binding patterns)")
    print(f"verdict       : {r.verdict:+.4f}  (signed, pooled SNR of binding legs)")
    print(f"edge_weight   : {r.edge_weight:.3f}  (vs the old flat 0.3)")
    print(f"note          : {r.note}")
    assert r.grounded and r.multiplicity == 2 and r.verdict > 0.9 and r.edge_weight > 0.3

    line("2. NEGATIVE CONTROLS — the brain must REFUSE to ground")
    # A: the KL ablation does NOT collapse (raw features still work) -> mechanism not specific
    ctrlA = list(NQ_LEGS)
    ctrlA[2] = Leg("kl_ablation_collapses", "necessity", 4.0, 1.2, frozenset({"NQ_ablation"}))
    rA = colimit("claim:nq_retail_squeeze", ctrlA)
    print(f"A) ablation does NOT collapse : grounded={rA.grounded}  edge_weight={rA.edge_weight:.3f}"
          f"  failed={rA.failed_legs}")
    # B: apply the NQ (retail-long) thesis to YM as the tradeable signal -> wrong direction
    ctrlB = [Leg("ym_edge_all_holds", "prediction", -7.7, 1.6, frozenset({"YM_ts"}), direction=+1)] \
        + NQ_LEGS[1:]
    rB = colimit("claim:ym_retail_squeeze", ctrlB)
    print(f"B) NQ thesis applied to YM     : grounded={rB.grounded}  edge_weight={rB.edge_weight:.3f}"
          f"  failed={rB.failed_legs}")
    assert not rA.grounded and rA.edge_weight == 0.0
    assert not rB.grounded and rB.edge_weight == 0.0

    line("3. BASIS-TYPED SHARPE (the units error made impossible)")
    p = 0.046   # ~128 trades/yr x 35min active / ~98k RTH min/yr
    cal = Quantity(0.70, 0.15, "sharpe", basis="calendar", support={"deployment": p})
    dep = to_deployed(cal, deployment_fraction=p)
    print(f"calendar Sharpe : {cal.value:.2f} ± {cal.sigma:.2f}")
    print(f"deployed Sharpe : {dep.value:.2f} ± {dep.sigma:.2f}   (= calendar / sqrt(p={p}))")
    print(f"licence         : {dep.assumptions[0]}")
    print(f"comparable without coercion? {commensurable(cal, dep)}  "
          f"(refusing to quote 0.70 and 3.26 as the same metric)")
    assert dep.value > 3.0 and dep.value > cal.value and not commensurable(cal, dep)

    line("4. MULTI-HOP UNCERTAINTY (calendar -> deployed -> portfolio-marginal)")
    base = Quantity(0.70, 0.15, "sharpe", basis="calendar")   # snr ~4.7
    hops = [
        Hop(jacobian=1.0 / (p ** 0.5), add_var=0.04, label="coerce to deployed (÷√p; redeployable?)"),
        Hop(jacobian=0.5, add_var=0.30, label="portfolio-marginal (corr dilution + capacity unc.)"),
    ]
    out, contractive = compose_chain(base, hops)
    print(f"base (calendar)         : {base.value:.2f} ± {base.sigma:.2f}   SNR {base.snr():.2f}")
    print(f"after portfolio-marginal: {out.value:.2f} ± {out.sigma:.2f}   SNR {out.snr():.2f}")
    print(f"contractive (kept unc. in check)? {contractive}  "
          f"-> a thin chain widens the posterior honestly")
    assert out.sigma > base.sigma and abs(out.snr()) < abs(base.snr())

    line("5. REVERSE-PROP INTO THE REAL EPISTEMIC GRAPH (graded, not flat 0.3)")
    t_grounded = ground_into_graph("claim:nq_retail_squeeze", r)
    t_refusedA = ground_into_graph("claim:nq_retail_squeeze", rA)
    t_refusedB = ground_into_graph("claim:ym_retail_squeeze", rB)
    print(f"grounded NQ apex  -> claim trust {t_grounded:+.3f}  "
          f"(graded by verdict {r.verdict:+.2f} x edge_weight {r.edge_weight:.2f})")
    print(f"refused control A -> claim trust {t_refusedA:+.3f}  (brain declines to update)")
    print(f"refused control B -> claim trust {t_refusedB:+.3f}  (brain declines to update)")
    print("contrast: the OLD implicate_from_outcome would have moved the claim by the flat "
          "0.3 for ALL THREE, believing the ablated and YM controls just as much as the real one.")
    assert t_grounded > 0.5 and t_refusedA == 0.0 and t_refusedB == 0.0

    print("\nfixture_futures_reversal: PASS — grounded the real signal, refused both "
          "controls, basis-typed the Sharpe, composed honest multi-hop uncertainty, and "
          "reverse-propagated a graded verdict into the epistemic graph.")


if __name__ == "__main__":
    main()
