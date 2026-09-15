"""alternates.py — go WIDE: alternate machineries per brain mechanic, compared fairly.

estimand.py/multihop.py each committed to ONE machinery. That is the pruning trap: a
corner that looks dead in the default can be the right one in a regime the default hides.
So for each mechanic we build several machineries behind a common interface and compare
them on the fixtures. The comparison is discovery, not elimination — we KEEP promising
corners and record *where each wins*, we do not crown one.

Mechanics and their alternates:
  UPDATE (measurement -> posterior):  Gaussian-conjugate | Student-t | particle | interval/credal
  GROUND (legs -> apex):              strict-colimit | noisy-AND | quorum(hybrid)
  PROPAGATE (uncertainty thru hops):  delta | Monte-Carlo | interval
  PROPOSE (discovery):                abstraction | composition | bifurcation-search

Dependency-free (math, random, statistics). Run: python3 alternates.py
"""
from __future__ import annotations

import math
import random
import statistics as stats

RNG = random.Random(0)


def line(t): print(f"\n{'='*74}\n{t}\n{'='*74}")


# =========================================================================== #
# MECHANIC 1 — UPDATE.  How a measurement moves a prior. Tested on a consistent
# measurement (all should agree) AND a small-n OUTLIER (where they diverge).
# =========================================================================== #
def _t_logpdf(x, mu, scale, nu):
    z = (x - mu) / scale
    return (math.lgamma((nu + 1) / 2) - math.lgamma(nu / 2)
            - 0.5 * math.log(nu * math.pi) - math.log(scale)
            - (nu + 1) / 2 * math.log1p(z * z / nu))


def up_gaussian(pm, ps, est, se, n):
    p0, pm_ = 1 / ps**2, 1 / se**2
    var = 1 / (p0 + pm_)
    return (pm * p0 + est * pm_) * var, math.sqrt(var), "closed-form"


def up_student_t(pm, ps, est, se, n):
    """Numeric posterior with a heavy-tailed (t, nu=n-1) likelihood: a far outlier under
    few observations is DISCOUNTED, not trusted."""
    nu = max(2.1, n - 1)
    lo, hi = pm - 8 * ps, pm + 8 * ps
    xs = [lo + (hi - lo) * i / 800 for i in range(801)]
    w = [math.exp(-0.5 * ((x - pm) / ps)**2) * math.exp(_t_logpdf(x, est, se, nu)) for x in xs]
    s = sum(w) or 1.0
    w = [wi / s for wi in w]
    m = sum(x * wi for x, wi in zip(xs, w))
    v = sum((x - m)**2 * wi for x, wi in zip(xs, w))
    return m, math.sqrt(v), f"numeric t(nu={nu:g})"


def up_particle(pm, ps, est, se, n, N=20000):
    nu = max(2.1, n - 1)
    xs = [RNG.gauss(pm, ps) for _ in range(N)]
    w = [math.exp(_t_logpdf(x, est, se, nu)) for x in xs]
    s = sum(w) or 1.0
    w = [wi / s for wi in w]
    m = sum(x * wi for x, wi in zip(xs, w))
    v = sum((x - m)**2 * wi for x, wi in zip(xs, w))
    return m, math.sqrt(v), f"{N} particles"


def up_interval(pm, ps, est, se, n, z=1.64):
    """Credal: prior interval ∩ measurement interval. Consistent -> tightens; CONFLICT
    (disjoint) -> report the hull and flag it, never a falsely-confident point."""
    a0, a1 = pm - z * ps, pm + z * ps
    b0, b1 = est - z * se, est + z * se
    if a1 < b0 or b1 < a0:      # disjoint -> conflict
        lo, hi = min(a0, b0), max(a1, b1)
        return (lo + hi) / 2, (hi - lo) / (2 * z), "CONFLICT: hull (honest widening)"
    lo, hi = max(a0, b0), min(a1, b1)
    return (lo + hi) / 2, (hi - lo) / (2 * z), "intersection"


def compare_update():
    line("MECHANIC 1 — UPDATE: consistent measurement vs a small-n outlier")
    fns = [("gaussian", up_gaussian), ("student-t", up_student_t),
           ("particle", up_particle), ("interval", up_interval)]
    print("consistent (prior N(0,1); meas est=3, se=1, n=200):")
    for name, f in fns:
        m, s, note = f(0.0, 1.0, 3.0, 1.0, 200)
        print(f"  {name:10} mean {m:+.2f}  sd {s:.2f}   ({note})")
    print("\noutlier / small-n (prior N(0,0.3) confident; meas est=5, se=0.5, n=4, fat-tailed):")
    res = {}
    for name, f in fns:
        m, s, note = f(0.0, 0.3, 5.0, 0.5, 4)
        res[name] = (m, s, note)
        print(f"  {name:10} mean {m:+.2f}  sd {s:.2f}   ({note})")
    # FINDING (checked): Gaussian is yanked far toward the outlier; the heavy-tailed and
    # credal machineries resist or flag conflict. Default-Gaussian is fragile in the
    # fat-tailed, small-n regime finance actually lives in.
    assert res["gaussian"][0] > res["student-t"][0] + 0.3, res
    assert "CONFLICT" in res["interval"][2], res
    print("  -> FINDING: Gaussian over-trusts a small-n outlier; Student-t/particle resist,"
          "\n     interval flags conflict. Robust updater should be the DEFAULT, not Gaussian.")


# =========================================================================== #
# MECHANIC 2 — GROUND.  legs -> apex. Tested on a coherent pattern AND a pattern
# with one MARGINAL prediction leg (does strict-colimit wrongly prune it?).
# =========================================================================== #
def _pass_prob(t, z=1.64, k=1.5):          # logistic pass-probability from a t-stat
    return 1 / (1 + math.exp(-k * (t - z)))


def gr_strict(legs):
    ok = all((abs(l["t"]) < 1.0) if l["kind"] == "necessity" else (l["dir"] * l["t"] >= 1.64)
             for l in legs)
    return (1.0 if ok else 0.0), "strict conjunction (colimit)"


def gr_noisy_and(legs):
    p = 1.0
    for l in legs:
        p *= (1 - _pass_prob(abs(l["t"]))) if l["kind"] == "necessity" else _pass_prob(l["dir"] * l["t"])
    return p, "noisy-AND (soft product)"


def gr_quorum(legs, m=None):
    """HYBRID: necessity legs STRICT (an ablation that must collapse is not negotiable),
    prediction/specificity legs by QUORUM (>= m of them bind) so one flaky check does not
    kill a real signal."""
    nec = [l for l in legs if l["kind"] == "necessity"]
    if any(abs(l["t"]) >= 1.0 for l in nec):
        return 0.0, "quorum: a necessity leg failed (strict veto)"
    preds = [l for l in legs if l["kind"] != "necessity"]
    binds = sum(1 for l in preds if l["dir"] * l["t"] >= 1.64)
    need = m if m is not None else max(1, len(preds) - 1)   # allow one to miss
    conf = binds / len(preds) if preds else 0.0
    return (conf if binds >= need else 0.0), f"quorum {binds}/{len(preds)} (need {need}); necessity strict"


def compare_ground():
    line("MECHANIC 2 — GROUND: coherent pattern vs ONE marginal prediction leg")
    coherent = [dict(name="edge", kind="prediction", t=2.84, dir=1),
                dict(name="ablation", kind="necessity", t=-0.17, dir=1),
                dict(name="cross", kind="specificity", t=2.8, dir=1)]
    flaky = [dict(name="edge", kind="prediction", t=2.84, dir=1),
             dict(name="edge2", kind="prediction", t=1.4, dir=1),   # marginal, just under
             dict(name="ablation", kind="necessity", t=-0.17, dir=1),
             dict(name="cross", kind="specificity", t=2.8, dir=1)]
    for tag, legs in [("coherent", coherent), ("one-marginal-leg", flaky)]:
        print(f"{tag}:")
        for name, f in [("strict", gr_strict), ("noisy-AND", gr_noisy_and), ("quorum", gr_quorum)]:
            c, note = f(legs)
            print(f"  {name:10} conf {c:.2f}   ({note})")
    # FINDING (checked): on the one-marginal-leg pattern, STRICT prunes it to 0 (a real
    # signal killed by one noisy check), while quorum keeps it alive at lower confidence
    # AND still vetoes on a failed necessity leg. The right machinery is the HYBRID.
    assert gr_strict(flaky)[0] == 0.0 and gr_quorum(flaky)[0] > 0.0
    # but a broken necessity leg is vetoed by BOTH (ablation must be strict)
    broken = [dict(name="edge", kind="prediction", t=2.84, dir=1),
              dict(name="ablation", kind="necessity", t=3.0, dir=1)]
    assert gr_strict(broken)[0] == 0.0 and gr_quorum(broken)[0] == 0.0
    print("  -> FINDING: strict-colimit prunes a real signal over one marginal leg; quorum"
          "\n     keeps the corner (necessity still strict). Adopt HYBRID: strict necessity +"
          "\n     quorum predictions.")


# =========================================================================== #
# MECHANIC 3 — PROPAGATE.  uncertainty through hops. Tested on a NONLINEAR hop
# where the delta-method (Jacobian) diverges from Monte-Carlo truth.
# =========================================================================== #
def prop_delta(mu, sd, f, dfdx):
    return f(mu), abs(dfdx(mu)) * sd, "delta (Jacobian)"


def prop_mc(mu, sd, f, dfdx, N=50000):
    ys = [f(RNG.gauss(mu, sd)) for _ in range(N)]
    return stats.fmean(ys), stats.pstdev(ys), f"Monte-Carlo ({N})"


def prop_interval(mu, sd, f, dfdx, z=1.64):
    lo, hi = f(mu - z * sd), f(mu + z * sd)
    lo, hi = min(lo, hi), max(lo, hi)
    return (lo + hi) / 2, (hi - lo) / (2 * z), "interval bounds"


def compare_propagate():
    line("MECHANIC 3 — PROPAGATE: a NONLINEAR hop (f(x)=x^2), delta vs Monte-Carlo")
    f, dfdx = (lambda x: x * x), (lambda x: 2 * x)
    mu, sd = 0.7, 0.15
    out = {}
    for name, fn in [("delta", prop_delta), ("monte-carlo", prop_mc), ("interval", prop_interval)]:
        m, s, note = fn(mu, sd, f, dfdx)
        out[name] = (m, s)
        print(f"  {name:12} mean {m:+.4f}  sd {s:.4f}   ({note})")
    # FINDING (checked): delta MISSES the Jensen gap (E[x^2] = mu^2 + var) so its mean is
    # biased low; MC captures it. Delta is a fast local-linear approximation only — for a
    # nonlinear hop (Kelly sizing, ratios, squares) use MC/unscented.
    assert out["monte-carlo"][0] > out["delta"][0] + 0.01, out
    print("  -> FINDING: delta underestimates the mean of a convex hop (misses the +var"
          "\n     term). Use delta only near-linear; MC/unscented for nonlinear hops.")


# =========================================================================== #
# MECHANIC 4 — PROPOSE.  discovery. abstraction reaches only known templates;
# composition and bifurcation-search reach signals it CANNOT.
# =========================================================================== #
def propose_abstraction(method_classes):
    return {f"{mc}::instance" for mc in method_classes}


def propose_composition(grounded):
    """Recombine grounded mechanisms into conjunction signals — novel from known parts."""
    out = set()
    for i, a in enumerate(grounded):
        for b in grounded[i + 1:]:
            out.add(f"{a} x {b}")
    return out


def propose_bifurcation(param_scan):
    """From dynamical systems: scan a parameter, find where the signed effect FLIPS
    (a qualitative/topological transition), and propose a signal anchored at the flip."""
    out = set()
    for (p0, e0), (p1, e1) in zip(param_scan, param_scan[1:]):
        if e0 * e1 < 0:
            out.add(f"signal@bifurcation(param≈{(p0+p1)/2:.2f})")
    return out


def compare_propose():
    line("MECHANIC 4 — PROPOSE: abstraction vs composition vs bifurcation-search")
    grounded = ["regime_attractor_residual", "cross_asset_flow"]
    scan = [(0.1, -1.2), (0.2, -0.4), (0.3, +0.5), (0.4, +1.1)]   # effect flips ~0.25
    A = propose_abstraction(grounded)
    C = propose_composition(grounded)
    B = propose_bifurcation(scan)
    print(f"  abstraction   -> {sorted(A)}")
    print(f"  composition   -> {sorted(C)}")
    print(f"  bifurcation   -> {sorted(B)}")
    # FINDING (checked): composition and bifurcation reach candidates abstraction cannot.
    assert C - A == C and B - A == B and C and B
    print("  -> FINDING: abstraction is bounded by known templates (proposer ceiling);"
          "\n     composition + bifurcation-search widen discovery. KEEP ALL proposers.")


def main():
    compare_update()
    compare_ground()
    compare_propagate()
    compare_propose()
    line("SUMMARY — design revisions discovered by going wide (corners kept, none pruned)")
    print("""  UPDATE   : default to a ROBUST updater (Student-t/particle); keep Gaussian only
             where tails are thin. Interval/credal for honest conflict-flagging.
  GROUND   : adopt the HYBRID combiner — necessity legs strict (veto), prediction/
             specificity legs by quorum — so one marginal check can't prune a real signal.
  PROPAGATE: delta only near-linear; MC/unscented for nonlinear hops (Kelly, ratios).
  PROPOSE  : keep abstraction AND add composition + bifurcation-search — wider reach.
  None of these replaces estimand.py's colimit; they are the machineries it should be
  able to SWAP IN per regime. Robustness = having the alternates, not one default.""")
    print("\nalternates: PASS — alternate machineries built and compared; findings are checked.")


if __name__ == "__main__":
    main()
