"""Heuristic selection among numerical methods under one decision standard.

Disagreement can trigger investigation; it does not identify which method is
right. Paired external losses, latency and cost determine whether escalation
helped. See adaptive_evaluation.py for independent-outcome policy experiments.
"""
from __future__ import annotations

import math

from alternates import (up_gaussian, up_particle, up_interval,
                        prop_delta, prop_mc, propose_abstraction, propose_composition,
                        propose_bifurcation)

# Diagnostic disagreement only; neither method supplies its own error label.
DIVERGENCE_LOG: list = []


def select_update(pm, ps, est, se, n, z_conflict=4.0, n_min=30):
    """A fixed heuristic chooses Gaussian or heavy-tailed particle assumptions.
    Small n or prior discrepancy triggers a second calculation, not proof that
    the particle answer is more accurate. These assumptions need external scoring.
    """
    g = up_gaussian(pm, ps, est, se, n)
    z_disc = abs(est - pm) / math.sqrt(ps**2 + se**2)
    if n >= n_min and z_disc <= z_conflict:
        return {"mean": g[0], "sd": g[1], "machinery": "gaussian", "escalated": False,
                "why": f"thin-tail/ample (n={n}, z_disc={z_disc:.1f}) -> cheap Gaussian"}
    r = up_particle(pm, ps, est, se, n)
    iv = up_interval(pm, ps, est, se, n)
    div = abs(g[0] - r[0])
    DIVERGENCE_LOG.append(("update", div))
    return {"mean": r[0], "sd": r[1], "machinery": "particle(robust)", "escalated": True,
            "cheap_mean": g[0], "divergence": div, "conflict": "CONFLICT" in iv[2],
            "why": f"risky (n={n}, z_disc={z_disc:.1f}) -> escalate; robust vs Gaussian "
                   f"diverged {div:.2f}" + ("; interval flags CONFLICT" if "CONFLICT" in iv[2] else "")}


def select_ground(legs, z=1.64, margin=0.6):
    """Apply one strict screening criterion regardless of computational margin.

    Marginal legs request review; they never switch the claim to a quorum.
    This legacy t-statistic screen is not an external certificate. In particular,
    its abs(t)<1 necessity screen is not an equivalence or causal necessity test.
    Conf is a binary screen result, not a calibrated probability or truth token.
    """
    if any(type(x) not in (int, float) or not math.isfinite(x) or x < 0 for x in (z, margin)):
        raise ValueError("finite nonnegative screen threshold and review margin required")
    legs = list(legs)
    for leg in legs:
        if (leg.get("kind") not in ("prediction", "specificity", "necessity")
                or type(leg.get("t")) not in (int, float) or not math.isfinite(leg["t"])
                or type(leg.get("dir")) not in (int, float) or leg["dir"] not in (-1, 1)):
            raise ValueError("each screen leg needs a recognized kind, finite t, and signed direction")
    preds = [l for l in legs if l["kind"] != "necessity"]
    near = [l for l in preds if abs(l["dir"] * l["t"] - z) < margin]
    passed = bool(preds) and all(abs(l["t"]) < 1 if l["kind"] == "necessity"
                                 else l["dir"]*l["t"] >= z for l in legs)
    return {"conf": float(passed), "accepted": passed, "grounded": False,
            "machinery": "strict", "escalated": False, "requires_review": bool(near),
            "decision_standard": "all prediction/specificity thresholds and legacy null screen",
            "why": f"strict criterion retained; {len(near)} marginal prediction leg(s) require review"}


def select_propagate(mu, sd, f, dfdx, tol=0.02, probe_N=2000):
    """Delta is exact for a linear hop and cheap. Probe with a small MC; if it agrees with
    delta, keep delta. If they diverge (nonlinearity — Jensen gap, ratios, Kelly), escalate
    to a full MC."""
    d = prop_delta(mu, sd, f, dfdx)
    probe = prop_mc(mu, sd, f, dfdx, N=probe_N)
    div = abs(d[0] - probe[0]) + abs(d[1] - probe[1])
    if div < tol:
        return {"mean": d[0], "sd": d[1], "machinery": "delta", "escalated": False,
                "why": f"delta≈MC probe (div {div:.3f}) -> near-linear, keep delta"}
    full = prop_mc(mu, sd, f, dfdx, N=50000)
    DIVERGENCE_LOG.append(("propagate", div))
    return {"mean": full[0], "sd": full[1], "machinery": "monte-carlo", "escalated": True,
            "divergence": div, "why": f"delta≠MC (div {div:.3f}) -> nonlinear, escalate to MC"}


def select_proposers(method_classes, grounded, scan):
    """Union this finite repertoire's candidates; downstream evidence gates belief.
    Larger repertoires need explicit computation and candidate budgets.
    """
    cands = (propose_abstraction(method_classes) | propose_composition(grounded)
             | propose_bifurcation(scan))
    return {"candidates": cands, "machinery": "abstraction+composition+bifurcation",
            "why": "keep all proposers — a promising corner is never pruned from search"}


def _selftest():
    def show(tag, d): print(f"  {tag:22} -> {d['machinery']:18} {'[escalated]' if d.get('escalated') else '[cheap]  '}  {d['why']}")

    print("TANDEM SELECTION — cheap first, escalate only near a decision boundary\n")
    print("UPDATE:")
    u_ok = select_update(0.0, 1.0, 3.0, 1.0, 200)      # consistent, well-sampled
    u_bad = select_update(0.0, 0.3, 5.0, 0.5, 4)        # small-n outlier
    show("consistent/ample", u_ok)
    show("small-n outlier", u_bad)
    assert u_ok["machinery"] == "gaussian" and not u_ok["escalated"]
    assert u_bad["escalated"] and "particle" in u_bad["machinery"] and u_bad["conflict"]

    print("GROUND:")
    coherent = [dict(name="edge", kind="prediction", t=2.84, dir=1),
                dict(name="abl", kind="necessity", t=-0.17, dir=1),
                dict(name="cross", kind="specificity", t=2.8, dir=1)]
    marginal = coherent + [dict(name="edge2", kind="prediction", t=1.4, dir=1)]
    g_ok = select_ground(coherent)
    g_marg = select_ground(marginal)
    show("coherent legs", g_ok)
    show("one marginal leg", g_marg)
    assert g_ok["conf"] == 1 and g_marg["conf"] == 0 and g_marg["requires_review"]
    assert not g_ok["grounded"] and not select_ground([])["accepted"]

    print("PROPAGATE:")
    p_lin = select_propagate(0.7, 0.15, lambda x: 2 * x, lambda x: 2.0)
    p_non = select_propagate(0.7, 0.15, lambda x: x * x, lambda x: 2 * x)
    show("linear hop", p_lin)
    show("nonlinear hop x^2", p_non)
    assert p_lin["machinery"] == "delta" and p_non["machinery"] == "monte-carlo"

    print("PROPOSE:")
    pr = select_proposers(["regime_attractor_residual"], ["regime_attractor_residual", "cross_asset_flow"],
                          [(0.1, -1.2), (0.2, -0.4), (0.3, 0.5), (0.4, 1.1)])
    print(f"  candidates             -> {sorted(pr['candidates'])}")
    assert any("x" in c for c in pr["candidates"]) and any("bifurcation" in c for c in pr["candidates"])

    print(f"\nDISAGREEMENT DIAGNOSTICS (accuracy requires independent outcomes):")
    for mech, div in DIVERGENCE_LOG:
        print(f"  {mech:10} divergence {div:.3f}")
    assert len(DIVERGENCE_LOG) >= 2

    print("\nselector checks: PASS — strict standard preserved; numerical method disagreement recorded. "
          "These checks do not establish that escalation improves accuracy.")


if __name__ == "__main__":
    _selftest()
