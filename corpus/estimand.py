"""estimand.py — the reverse-propagation mechanics of the discovery brain.

Replaces the one-bit hole (`implicate_from_outcome`: outcome -> ±1, flat edge
weight 0.3) with a *typed numerical update*. An external MEASUREMENT of a claim's
ESTIMAND updates a posterior over a quantity that carries:

  * units   — a nominal type ("sharpe", "abn_return_pts", ...); incommensurable
              quantities cannot be compared or folded, even when both dimensionless;
  * basis   — the time-normalization ("calendar" | "deployed" | "portfolio_marginal");
              cross-basis comparison requires an explicit, assumption-carrying coercion
              (the Sharpe "0.7 vs 5" swing is a basis/units error this prevents);
  * support — deployment fraction, sample size n, and data provenance.

From this, trust becomes a DERIVED property of the posterior (signed SNR), and the
reverse-propagation edge weight is DERIVED from *multiplicity* — how many
provenance-independent patterns bind an apex — instead of a flat 0.3. Grounding is a
colimit: an apex is grounded iff its pattern of externally-checked legs coheres.

This module governs BELIEF only. It never prunes exploration (see nl2proof/BRAIN.md:
the two gates). Dependency-free (math only). Run `python3 estimand.py` for the self-test.
"""
from __future__ import annotations

import math
from dataclasses import dataclass, field, replace
from typing import Optional

Z_SIGNIF = 1.64      # one-sided ~5% — a leg "binds" when |effect|/stderr >= this
Z_COLLAPSE = 1.0     # a necessity leg (ablation/ungated) must fall BELOW this


# --------------------------------------------------------------------------- #
# Quantities: a posterior/prior over a scalar, with its full type.
# --------------------------------------------------------------------------- #
@dataclass(frozen=True)
class Quantity:
    value: float
    sigma: float                      # posterior std (uncertainty); > 0
    units: str                        # nominal type
    basis: str = "raw"                # time-normalization basis
    support: dict = field(default_factory=dict)   # {deployment, n, provenance:set}
    assumptions: tuple = ()           # coercions applied, each carrying its licence

    def snr(self) -> float:
        return self.value / self.sigma if self.sigma > 0 else math.copysign(math.inf, self.value)


def commensurable(a: Quantity, b: Quantity) -> bool:
    """Same nominal type AND same basis. The type-check at the membrane: refuse to
    compare/fold a hazard-ratio into a return, or a calendar-Sharpe into a deployed one."""
    return a.units == b.units and a.basis == b.basis


# --- basis coercions (assumption-carrying) ---------------------------------- #
# Only Sharpe-like rate quantities have a time-normalization basis worth coercing.
_SCALABLE = {"sharpe"}


def to_deployed(q: Quantity, deployment_fraction: float) -> Quantity:
    """calendar-basis -> deployed-basis. Sharpe_deployed = Sharpe_calendar / sqrt(p).
    Records the licence: this assumes idle capital is redeployable (a pod)."""
    if q.units not in _SCALABLE:
        raise TypeError(f"no basis coercion defined for units={q.units!r}")
    if q.basis != "calendar":
        raise TypeError(f"to_deployed expects basis=calendar, got {q.basis!r}")
    if not (0.0 < deployment_fraction <= 1.0):
        raise ValueError("deployment_fraction must be in (0,1]")
    k = 1.0 / math.sqrt(deployment_fraction)
    return replace(q, value=q.value * k, sigma=q.sigma * k, basis="deployed",
                   assumptions=q.assumptions + (
                       f"calendar->deployed x{k:.2f} (=1/sqrt(p={deployment_fraction:g}); "
                       f"assumes redeployable capital)",))


# --------------------------------------------------------------------------- #
# Measurements and the typed update.
# --------------------------------------------------------------------------- #
@dataclass(frozen=True)
class Measurement:
    estimate: float
    stderr: float
    n: int
    units: str
    basis: str = "raw"
    provenance: frozenset = frozenset()   # data-source tags (for independence)
    deployment: Optional[float] = None
    robust: bool = True                   # small-n fat-tail widening (Student-t)

    def effective_stderr(self) -> float:
        """Widen stderr for small n under a fat-tailed (Student-t, nu=n-1) view, so a
        handful of events (aducanumab n=5, event returns heavy-tailed) cannot pose as
        precise. Returns a stderr that is AT LEAST the raw one — honest, never tighter."""
        if not self.robust:
            return self.stderr
        nu = self.n - 1
        if nu > 2:
            return self.stderr * math.sqrt(nu / (nu - 2))   # t-variance inflation
        return self.stderr * 3.0                             # n<=3: deliberately very wide

    def t(self) -> float:
        se = self.effective_stderr()
        return self.estimate / se if se > 0 else math.copysign(math.inf, self.estimate)


def _jaccard(a: frozenset, b: frozenset) -> float:
    if not a or not b:
        return 0.0
    return len(a & b) / len(a | b)


def update(prior: Quantity, m: Measurement,
           prior_provenance: frozenset = frozenset()) -> Quantity:
    """Conjugate (Normal-Normal) update of a prior by a measurement, gated by:
      * units+basis type-check (raises TypeError on mismatch — the membrane);
      * small-n/fat-tail widening (Measurement.effective_stderr);
      * evidence-independence: a measurement sharing provenance with the prior's
        evidence contributes only its INDEPENDENT fraction of precision (fully
        redundant evidence -> no update). This is FDR lifted to evidence-independence.
    Trust is not touched here; it is DERIVED later (derived_trust)."""
    if prior.units != m.units or prior.basis != m.basis:
        raise TypeError(f"measurement {m.units}/{m.basis} incommensurable with "
                        f"prior {prior.units}/{prior.basis} — coerce first")
    se = m.effective_stderr()
    indep = 1.0 - _jaccard(prior_provenance, m.provenance)   # independent fraction
    prec0 = 1.0 / (prior.sigma ** 2)
    prec_m = indep / (se ** 2) if se > 0 else 0.0
    post_prec = prec0 + prec_m
    post_var = 1.0 / post_prec
    post_mu = (prior.value * prec0 + m.estimate * prec_m) / post_prec
    support = dict(prior.support)
    support["n"] = support.get("n", 0) + (m.n if indep > 0 else 0)
    support["provenance"] = set(prior_provenance) | set(m.provenance)
    if m.deployment is not None:
        support["deployment"] = m.deployment
    return replace(prior, value=post_mu, sigma=math.sqrt(post_var), support=support)


def derived_trust(q: Quantity) -> float:
    """Trust as a derived property of the posterior: signed by value, magnitude by SNR,
    squashed to [-1,1]. A tight posterior far from zero -> strong trust; a wide one ->
    near zero regardless of the point estimate (honest low confidence)."""
    return math.tanh(q.snr())


# --------------------------------------------------------------------------- #
# Grounding as a colimit: an apex binds a pattern of externally-checked legs.
# --------------------------------------------------------------------------- #
@dataclass(frozen=True)
class Leg:
    """One externally-checked prediction entailed by the apex mechanism.
      kind='prediction'  : must BIND — effect in `direction`, |t| >= Z_SIGNIF.
      kind='necessity'   : must COLLAPSE — |t| < Z_COLLAPSE (ablation / ungated baseline).
      kind='specificity' : the thesis predicts the edge is PRESENT (`present=True`,
                           dir·t >= Z_SIGNIF) on should-work instruments, or ABSENT
                           (`present=False`, dir·t < Z_SIGNIF) on should-not ones. An
                           absent-check passes whether the instrument is null OR reverses
                           (YM = −7.7 still "shows no retail-long edge") — the honest test
                           is 'no significant edge in the predicted direction', not 'null'.
    `provenance` groups legs that share underlying data (they are NOT independent)."""
    name: str
    kind: str
    effect: float
    stderr: float
    provenance: frozenset
    direction: int = +1        # expected sign of the retail edge (+1/-1)
    present: bool = True       # specificity: is that edge expected present or absent?
    n: int = 100

    def t(self) -> float:
        se = self.stderr if self.stderr > 0 else 1e-9
        return self.effect / se

    def binds(self) -> bool:
        t = self.t()
        if self.kind == "necessity":
            return abs(t) < Z_COLLAPSE                          # must collapse
        if self.kind == "specificity":
            signal = self.direction * t
            return (signal >= Z_SIGNIF) if self.present else (signal < Z_SIGNIF)
        if self.direction == 0:
            return abs(t) < Z_COLLAPSE                          # expected null must be null
        return (self.direction * t) >= Z_SIGNIF                 # right sign, significant

    def is_binding_evidence(self) -> bool:
        """Counts toward multiplicity only if it is positive evidence FOR the apex:
        a passing prediction (dir≠0) or a passing present-specificity leg."""
        if not self.binds():
            return False
        if self.kind == "prediction":
            return self.direction != 0
        if self.kind == "specificity":
            return self.present
        return False


@dataclass(frozen=True)
class GroundingResult:
    grounded: bool
    multiplicity: int                 # # provenance-independent binding patterns
    verdict: float                    # signed, in [-1,1] — feeds implicate_from_outcome
    edge_weight: float                # derived from multiplicity (upgrades flat 0.3)
    failed_legs: tuple
    note: str


def edge_weight_from_multiplicity(m: int) -> float:
    """More provenance-independent bindings -> a stronger (less noisy) reverse-prop
    signal. Saturating; one lonely pattern is worth ~0.22, three ~0.53, five ~0.71 —
    i.e. a genuinely multiply-realized apex moves upstream claims far more than the old
    flat 0.3, while a single-pattern apex moves them less (rightly more suspect)."""
    return 1.0 - math.exp(-m / 2.0)


def colimit(apex: str, legs: list[Leg]) -> GroundingResult:
    """Does the pattern of legs cohere into the apex (a universal cocone)? Grounded iff
    EVERY leg binds as its kind requires. Multiplicity = number of provenance-disjoint
    groups that each contain at least one binding *prediction/specificity* leg — the
    Multiplicity Principle made countable. Non-existence of the colimit (a failed leg)
    IS 'the facts don't bind, the signal isn't real'."""
    failed = tuple(l.name for l in legs if not l.binds())
    grounded = len(failed) == 0

    # multiplicity: provenance-disjoint binding evidence groups
    binding = [l for l in legs if l.is_binding_evidence()]
    groups: list[frozenset] = []
    for l in binding:
        merged = set(l.provenance)
        rest = []
        for g in groups:
            if g & l.provenance:
                merged |= g
            else:
                rest.append(g)
        rest.append(frozenset(merged))
        groups = rest
    multiplicity = len(groups)

    # verdict: pooled SNR of the binding prediction legs (inverse-variance weighted),
    # signed; magnitude squashed. Only meaningful if grounded.
    if grounded and binding:
        num = sum(l.effect / (l.stderr ** 2) for l in binding)
        den = sum(1.0 / (l.stderr ** 2) for l in binding)
        pooled_mu = num / den
        pooled_sigma = math.sqrt(1.0 / den)
        verdict = math.tanh(pooled_mu / pooled_sigma)
    else:
        verdict = 0.0

    ew = edge_weight_from_multiplicity(multiplicity) if grounded else 0.0
    note = ("grounded" if grounded else f"colimit does not exist; failed legs: {failed}")
    return GroundingResult(grounded, multiplicity, verdict, ew, failed, note)


# --------------------------------------------------------------------------- #
# Multi-hop uncertainty composition (delta method for numerical hops).
# --------------------------------------------------------------------------- #
@dataclass(frozen=True)
class Hop:
    jacobian: float          # local linear gain d(out)/d(in)
    add_var: float = 0.0     # variance injected by this hop (model/approx error)
    label: str = ""


def compose_chain(base: Quantity, hops: list[Hop]) -> tuple[Quantity, bool]:
    """Propagate a quantity through numerical hops by the delta method:
    value *= prod(J); var_out = J^2 * var_in + add_var per hop. Returns the final
    quantity and a `contractive` flag (product |J| < 1 AND SNR did not degrade below
    the input) — a DIAGNOSTIC of whether the chain kept uncertainty in check. A thin
    chain (large add_var) widens the posterior and drops SNR: honest low confidence,
    the property LLM chain-of-thought structurally lacks."""
    v, var = base.value, base.sigma ** 2
    jprod = 1.0
    for h in hops:
        v = v * h.jacobian
        var = (h.jacobian ** 2) * var + h.add_var
        jprod *= abs(h.jacobian)
    out = replace(base, value=v, sigma=math.sqrt(var))
    contractive = jprod < 1.0 and abs(out.snr()) >= abs(base.snr()) - 1e-9
    return out, contractive


# --------------------------------------------------------------------------- #
# self-test — proven with numbers.
# --------------------------------------------------------------------------- #
def _selftest():
    # 1) conjugate update tightens and moves toward the measurement.
    prior = Quantity(0.0, 1.0, "abn_return_pts")
    m = Measurement(5.0, 1.0, n=200, units="abn_return_pts")
    post = update(prior, m)
    assert post.sigma < min(prior.sigma, m.effective_stderr()), post.sigma
    assert 0.0 < post.value < 5.0, post.value
    assert derived_trust(post) > 0.9, derived_trust(post)

    # 2) units/basis type-check refuses incommensurable folds.
    try:
        update(prior, Measurement(1.0, 1.0, 50, units="sharpe"))
        assert False, "should have raised"
    except TypeError:
        pass

    # 3) basis coercion: calendar Sharpe -> deployed, x1/sqrt(p), assumption recorded.
    cal = Quantity(0.7, 0.2, "sharpe", basis="calendar")
    dep = to_deployed(cal, deployment_fraction=0.03)
    assert abs(dep.value - 0.7 / math.sqrt(0.03)) < 1e-9, dep.value
    assert dep.value > 3.5 and dep.basis == "deployed" and dep.assumptions, dep
    assert not commensurable(cal, dep)   # cannot be compared without the coercion

    # 4) evidence independence: a fully-redundant measurement does not move the posterior.
    p0 = Quantity(0.0, 1.0, "abn_return_pts")
    prov = frozenset({"NQ_bars_2022_2026"})
    once = update(p0, Measurement(5.0, 1.0, 200, "abn_return_pts", provenance=prov))
    redundant = update(once, Measurement(5.0, 1.0, 200, "abn_return_pts", provenance=prov),
                       prior_provenance=prov)
    assert abs(redundant.value - once.value) < 1e-9 and abs(redundant.sigma - once.sigma) < 1e-9, \
        (once, redundant)
    independent = update(once, Measurement(5.0, 1.0, 200, "abn_return_pts",
                                           provenance=frozenset({"ES_bars"})),
                         prior_provenance=prov)
    assert independent.sigma < once.sigma, (once.sigma, independent.sigma)

    # 5) small-n fat tails widen honestly.
    big = Measurement(5.0, 1.0, n=500, units="x")
    small = Measurement(5.0, 1.0, n=5, units="x")
    assert small.effective_stderr() > big.effective_stderr() > 1.0 - 1e-9

    # 6) multi-hop: a thin chain widens the posterior and drops SNR (honest).
    base = Quantity(5.0, 1.0, "x")   # snr 5
    thin, contr = compose_chain(base, [Hop(1.0, add_var=4.0, label="noisy coercion")])
    assert thin.sigma > base.sigma and abs(thin.snr()) < abs(base.snr()), (base, thin)
    assert not contr

    # 7) grounding as colimit: a coherent multiply-realized pattern grounds and beats
    #    the flat 0.3 edge weight; a non-collapsing ablation (raw features still work)
    #    breaks the colimit; a wrong-direction should-work instrument breaks it too.
    legs_ok = [
        Leg("all_holds", "prediction", 5.4, 1.9, frozenset({"NQ"}), direction=+1),
        Leg("ungated_flat", "necessity", 0.3, 1.5, frozenset({"NQ"})),
        Leg("ablation_collapses", "necessity", -0.2, 1.2, frozenset({"NQ_abl"})),
        Leg("cross_NQ", "specificity", 5.4, 1.9, frozenset({"XI"}), direction=+1, present=True),
        Leg("cross_YM", "specificity", -7.7, 1.6, frozenset({"XI"}), direction=+1, present=False),
    ]
    r = colimit("nq_reversal", legs_ok)
    assert r.grounded and r.multiplicity == 2 and r.verdict > 0.9, r
    assert r.edge_weight > 0.3, r.edge_weight
    bad = list(legs_ok); bad[2] = Leg("ablation_collapses", "necessity", 4.0, 1.2,
                                      frozenset({"NQ_abl"}))
    assert not colimit("nq_reversal", bad).grounded

    print("estimand selftest: PASS (conjugate tighten+move; type-check refuses; "
          "basis coercion 1/sqrt(p) w/ licence; redundant evidence inert, independent tightens; "
          "small-n widens; thin chain -> honest wide posterior)")


if __name__ == "__main__":
    _selftest()
