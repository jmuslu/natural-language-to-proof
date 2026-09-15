"""Legacy reconstruction diagnostics and retained synthetic return examples.

NQ_LEGS preserves earlier reconstructed figure values for traceability. They lack
original sample artifacts, preregistered null margins and external validation
receipts. They cannot establish a real strategy or necessity claim. Separate
synthetic inputs demonstrate the corrected contracts without relabeling legacy
values as new evidence. This script does not write graph trust.
"""
from __future__ import annotations

from estimand import Leg, colimit, paired_sharpe


NQ_LEGS = [
    Leg("gated_edge_all_holds", "prediction", 5.4, 1.9, frozenset({"NQ_ts"})),
    Leg("ungated_no_edge", "necessity", .3, 1.5, frozenset({"NQ_ts"})),
    Leg("kl_ablation_collapses", "necessity", -.2, 1.2, frozenset({"NQ_ablation"})),
    Leg("losers_move_right_first", "prediction", 10., 3., frozenset({"NQ_ts"})),
    Leg("cross_NQ_present", "specificity", 5.4, 1.9, frozenset({"cross_sectional"})),
    Leg("cross_ES_absent", "specificity", -.2, 1.5, frozenset({"cross_sectional"}), present=False),
    Leg("cross_RTY_absent", "specificity", -.3, 1.5, frozenset({"cross_sectional"}), present=False),
    Leg("cross_YM_absent", "specificity", -7.7, 1.6, frozenset({"cross_sectional"}), present=False),
]

# Retained equal-period synthetic streams: active outcomes 0 and 2, p=.1.
SYNTHETIC_ACTIVE = (False,)*18 + (True, True)
SYNTHETIC_ZERO_IDLE_RETURNS = (0.,)*18 + (0., 2.)
SYNTHETIC_NONZERO_IDLE_RETURNS = (.1,)*18 + (0., 2.)


def main():
    legacy = colimit("legacy-nq-reconstruction", NQ_LEGS)
    assert not legacy.grounded and legacy.edge_weight == 0
    print(f"legacy reconstruction remains unverified; missing null margins: {legacy.failed_legs}")
    # Margin and model are specified for this independent synthetic demonstration.
    positive = Leg("synthetic-edge", "prediction", 3., 1., frozenset({"synthetic"}))
    precise = Leg("synthetic-control", "necessity", 0., .1, frozenset({"synthetic"}), equivalence_margin=.5)
    underpowered = Leg("synthetic-control", "necessity", 0., 100., frozenset({"synthetic"}), equivalence_margin=.5)
    assert colimit("synthetic-hypothesis", [positive, precise]).grounded
    assert not colimit("synthetic-hypothesis", [positive, underpowered]).grounded
    zero = paired_sharpe(SYNTHETIC_ZERO_IDLE_RETURNS, SYNTHETIC_ACTIVE)
    nonzero = paired_sharpe(SYNTHETIC_NONZERO_IDLE_RETURNS, SYNTHETIC_ACTIVE)
    assert abs(zero["calendar"]["mean"]-.1) < 1e-12
    assert abs(zero["calendar"]["variance"]-.19) < 1e-12
    assert zero["deployed"]["sharpe"] == nonzero["deployed"]["sharpe"] == 1
    assert zero["calendar"]["sharpe"] != nonzero["calendar"]["sharpe"]
    assert not nonzero["zero_idle_returns"]
    print(f"retained synthetic stream: calendar Sharpe={zero['calendar']['sharpe']:.6f}, "
          f"active Sharpe={zero['deployed']['sharpe']:.6f}; uncertainty not estimated")
    print(f"nonzero idle returns change calendar Sharpe to {nonzero['calendar']['sharpe']:.6f}")
    print("fixture_futures_reversal: PASS; legacy insufficiency and separate synthetic contract checks")


if __name__ == "__main__":
    main()
