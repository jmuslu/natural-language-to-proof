"""selector.py — the machinery that uses the alternates IN TANDEM, switching by situation.

The alternates (alternates.py) are a repertoire, not a menu to pick once. This is the
meta-layer that IS the intelligence: for each call it runs the cheap machinery first and
ESCALATES to the heavy one only when the situation is near a decision boundary (small-n,
outlier, nonlinearity, marginal leg), then records where cheap and heavy diverged — the
learning signal that, over time, tunes the escalation thresholds.

  build lightweight -> test -> where it disagrees, go heavy -> compare -> learn -> steer.

Cost-aware (don't pay for particles/MC when Gaussian/delta agree) and robust (pay when it
matters). Dependency-free. Run: python3 selector.py
"""
from __future__ import annotations

import math

from alternates import (up_gaussian, up_particle, up_interval, gr_strict, gr_quorum,
                        prop_delta, prop_mc, propose_abstraction, propose_composition,
                        propose_bifurcation)

# the learning signal: (mechanic, divergence) each time escalation found the cheap
# machinery wrong. A rising divergence rate in a regime is the cue to lower its threshold.
DIVERGENCE_LOG: list = []


def select_update(pm, ps, est, se, n, z_conflict=4.0, n_min=30):
    """Gaussian is cheap and correct when tails are thin, sampling is ample, and the
    measurement is consistent with the prior. Escalate to a robust (particle) posterior —
    and an interval conflict check — only when n is small OR the standardized discrepancy
    is large (a potential outlier)."""
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
    """Strict colimit when every prediction leg is comfortably clear of the threshold
    (it and quorum agree, and strict is the cleaner statement). Switch to the HYBRID
    quorum (strict necessity + quorum predictions) when any prediction leg sits NEAR the
    boundary, so one marginal check cannot prune a real signal."""
    preds = [l for l in legs if l["kind"] != "necessity"]
    near = [l for l in preds if abs(l["dir"] * l["t"] - z) < margin]
    if not near:
        c, note = gr_strict(legs)
        return {"conf": c, "machinery": "strict", "escalated": False,
                "why": "all prediction legs clear of the boundary -> strict"}
    c, note = gr_quorum(legs)
    return {"conf": c, "machinery": "quorum(hybrid)", "escalated": True,
            "why": f"{len(near)} marginal prediction leg(s) near boundary -> quorum ({note})"}


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
    """Discovery never prunes: run every proposer and union the candidates. Breadth of
    exploration is free (belief is gated elsewhere)."""
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
    assert g_ok["machinery"] == "strict" and g_marg["machinery"].startswith("quorum") and g_marg["conf"] > 0

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

    print(f"\nLEARNING SIGNAL (where escalation caught the cheap machinery wrong):")
    for mech, div in DIVERGENCE_LOG:
        print(f"  {mech:10} divergence {div:.3f}  (a rising rate here => lower this regime's threshold)")
    assert len(DIVERGENCE_LOG) >= 2

    print("\nselector selftest: PASS — machineries used in tandem, switching by situation; "
          "escalates only when it pays; divergences logged as the learning signal.")


if __name__ == "__main__":
    _selftest()
