"""Explicit estimand identities, conditional numerical updates, and leg diagnostics.

Quantities carry target attributes, units, basis, uncertainty and declared evidence
support. Unknown targets cannot be pooled. Return-basis summaries use retained
streams; null claims need positive equivalence evidence within declared margins.
Provenance tags, signed SNR and local coherence do not authenticate observations,
establish statistical independence, or calibrate factual confidence. The external
receipt evaluator governs belief changes. Exploration remains unrestricted.
See ARCHITECTURE.md and RESEARCH_THREADS.md. Dependency-free selftest below.
"""
from __future__ import annotations

import math
from dataclasses import dataclass, field, replace
from typing import Optional

Z_SIGNIF = 1.6448536269514722  # standard Normal one-sided 5% threshold


def _finite(value, name, *, positive=False):
    try:
        valid = type(value) in (int, float) and math.isfinite(value)
    except OverflowError:
        valid = False
    if not valid:
        raise ValueError(f"{name} must be a finite number")
    if positive and value <= 0:
        raise ValueError(f"{name} must be positive")


def _label(value, name):
    if not isinstance(value, str) or not value.strip():
        raise ValueError(f"{name} must be a nonempty string")


def _provenance(value):
    if not isinstance(value, (set, frozenset, list, tuple)):
        raise ValueError("provenance must be a collection of nonempty string tags")
    for tag in value:
        _label(tag, "provenance tag")
    return frozenset(value)


def _sample_size(value):
    if type(value) is not int or value <= 0:
        raise ValueError("n must be a positive integer")


# --------------------------------------------------------------------------- #
# Quantities: a posterior/prior over a scalar, with its full type.
# --------------------------------------------------------------------------- #
@dataclass(frozen=True)
class EstimandIdentity:
    """Declared statistical target; matching labels assert identity, not authenticity.

    conditioning=() explicitly means unconditional. Include sampling interval in
    horizon and the summary functional (mean, equal-period Sharpe, etc.). Optional
    intervention/comparator distinguish causal targets when applicable. Legacy
    quantities without an identity may be inspected but cannot be pooled.
    """
    observable: str
    population: str
    horizon: str
    conditioning: tuple
    units: str
    basis: str
    summary: str
    intervention: Optional[str] = None
    comparator: Optional[str] = None

    def __post_init__(self):
        for name in ("observable", "population", "horizon", "units", "basis", "summary"):
            _label(getattr(self, name), name)
        if not isinstance(self.conditioning, tuple):
            raise ValueError("conditioning must be an explicit tuple; () means unconditional")
        for condition in self.conditioning:
            _label(condition, "conditioning term")
        object.__setattr__(self, "conditioning", tuple(sorted(set(self.conditioning))))
        for name in ("intervention", "comparator"):
            if getattr(self, name) is not None:
                _label(getattr(self, name), name)


def _identity(identity, units, basis):
    if identity is not None:
        if not isinstance(identity, EstimandIdentity):
            raise TypeError("identity must be EstimandIdentity or None (legacy unknown)")
        if identity.units != units or identity.basis != basis:
            raise ValueError("quantity units/basis must agree with its estimand identity")


@dataclass(frozen=True)
class Quantity:
    value: float
    sigma: float                      # posterior std (uncertainty); > 0
    units: str                        # nominal type
    basis: str = "raw"                # time-normalization basis
    support: dict = field(default_factory=dict)   # {deployment, n, provenance:set}
    assumptions: tuple = ()           # coercions applied, each carrying its licence
    identity: Optional[EstimandIdentity] = None

    def __post_init__(self):
        _finite(self.value, "value")
        _finite(self.sigma, "sigma", positive=True)
        _label(self.units, "units")
        _label(self.basis, "basis")
        _identity(self.identity, self.units, self.basis)
        if not isinstance(self.assumptions, tuple):
            raise ValueError("assumptions must be a tuple")
        for assumption in self.assumptions:
            _label(assumption, "assumption")
        if not isinstance(self.support, dict):
            raise ValueError("support must be a dictionary")
        support = dict(self.support)
        if "provenance" in support:
            support["provenance"] = _provenance(support["provenance"])
        if "n" in support:
            _sample_size(support["n"])
        if "deployment" in support:
            _finite(support["deployment"], "deployment", positive=True)
            if support["deployment"] > 1:
                raise ValueError("deployment must be at most 1")
        object.__setattr__(self, "support", support)

    def snr(self) -> float:
        return self.value / self.sigma


def commensurable(a: Quantity, b: Quantity) -> bool:
    """Both targets are explicitly identified and match in every declared attribute.

    Two missing legacy identities are unknown, not a match. Shared units alone
    never license pooling different populations, observables or horizons.
    """
    return (a.identity is not None and b.identity is not None and a.identity == b.identity
            and a.units == b.units and a.basis == b.basis)


# --- basis coercions (assumption-carrying) ---------------------------------- #
# Only Sharpe-like rate quantities have a time-normalization basis worth coercing.
_SCALABLE = {"sharpe"}


def to_deployed(q: Quantity, deployment_fraction: float) -> Quantity:
    """Removed unsafe exact-conversion API; retained to give callers a clear error."""
    raise TypeError("calendar/sqrt(p) is not an exact Sharpe conversion; use paired_sharpe "
                    "on equal-period returns or to_deployed_approx with explicit assumptions")


def to_deployed_approx(q: Quantity, deployment_fraction: float, *,
                       equal_period_zero_idle: bool, low_active_snr: bool,
                       max_relative_error: float = .01) -> Quantity:
    """Small-active-SNR approximation, requiring equal-period zero-idle returns.

    R=I*X gives S_calendar=sqrt(p)*S_active/sqrt(1+(1-p)*S_active^2).
    The point-estimate approximation error implied by this identity must fit the
    supplied tolerance. Neither redeployability nor annualized Sharpe supplies
    these assumptions. The scaled sigma is also a local approximation, conditional
    on p being known exactly; its approximation/coverage is not certified here.
    Prefer paired_sharpe when the return stream is retained.
    """
    if equal_period_zero_idle is not True or low_active_snr is not True:
        raise ValueError("explicit equal-period zero-idle and low-active-SNR assumptions required")
    _finite(max_relative_error, "max_relative_error", positive=True)
    if max_relative_error >= 1:
        raise ValueError("max_relative_error must be below one")
    if q.units not in _SCALABLE:
        raise TypeError(f"no basis coercion defined for units={q.units!r}")
    if q.basis != "calendar":
        raise TypeError(f"approximation expects basis=calendar, got {q.basis!r}")
    if q.identity is None or q.identity.summary != "equal_period_sharpe":
        raise TypeError("explicit equal_period_sharpe estimand identity required")
    _finite(deployment_fraction, "deployment_fraction", positive=True)
    if deployment_fraction > 1.0:
        raise ValueError("deployment_fraction must be in (0,1]")
    if "deployment" in q.support and q.support["deployment"] != deployment_fraction:
        raise ValueError("deployment fraction disagrees with the quantity's declared support")
    k = 1.0 / math.sqrt(deployment_fraction)
    approximate = q.value * k
    try:
        remaining = 1 - (1 - deployment_fraction) * approximate**2
    except OverflowError as exc:
        raise ValueError("Sharpe approximation exceeds numerical range") from exc
    if remaining <= 0 or 1 - math.sqrt(remaining) > max_relative_error:
        raise ValueError("point estimate contradicts the declared small-active-SNR error tolerance")
    target = replace(q.identity, basis="deployed", conditioning=q.identity.conditioning + ("active",))
    return replace(q, value=q.value * k, sigma=q.sigma * k, basis="deployed",
                   identity=target,
                   support={**q.support, "deployment": deployment_fraction},
                   assumptions=q.assumptions + (
                       f"APPROXIMATION calendar/sqrt(p={deployment_fraction:g}); equal-period zero-idle "
                       f"returns, low active SNR, fixed known p; point relative error <= {max_relative_error:g}; "
                       "sigma scaling is a local approximation",))


def paired_sharpe(returns, active):
    """Direct descriptive ratios from one retained equal-period excess-return stream.

    Returns calendar/all-period and deployed/active-period empirical moments using
    variance divisor n. No standard error, annualization, portfolio inference or
    independence is invented. Idle observations may be nonzero. Zero dispersion
    gives ratio=None, rather than infinite confidence. Caller retains the stream
    and defines financing/excess-return convention and period length.
    """
    returns, active = tuple(returns), tuple(active)
    if len(returns) < 2 or len(active) != len(returns):
        raise ValueError("at least two equal-period returns and one active flag per return required")
    for value in returns:
        _finite(value, "return")
    if any(type(flag) is not bool for flag in active) or not any(active):
        raise ValueError("active flags must be bool and include an active period")

    def moments(values):
        if not values:
            return {"n": 0, "mean": None, "variance": None, "sharpe": None}
        try:
            mean = math.fsum(value / len(values) for value in values)
            variance = math.fsum((value - mean)**2 / len(values) for value in values)
        except OverflowError as exc:
            raise ValueError("return moments exceed numerical range") from exc
        _finite(variance, "return variance")
        return {"n": len(values), "mean": mean, "variance": variance,
                "sharpe": mean/math.sqrt(variance) if variance > 0 else None}

    return {"calendar": moments(returns),
            "deployed": moments([r for r, flag in zip(returns, active) if flag]),
            "idle": moments([r for r, flag in zip(returns, active) if not flag]),
            "deployment": sum(active)/len(active),
            "zero_idle_returns": all(r == 0 for r, flag in zip(returns, active) if not flag),
            "convention": "equal-period excess returns; empirical population moments; no annualization",
            "uncertainty": None}


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
    provenance: frozenset = frozenset()   # declared source tags, not independence proof
    deployment: Optional[float] = None
    robust: bool = True                   # small-n fat-tail widening (Student-t)
    identity: Optional[EstimandIdentity] = None

    def __post_init__(self):
        _finite(self.estimate, "estimate")
        _finite(self.stderr, "stderr", positive=True)
        _sample_size(self.n)
        _label(self.units, "units")
        _label(self.basis, "basis")
        _identity(self.identity, self.units, self.basis)
        object.__setattr__(self, "provenance", _provenance(self.provenance))
        if type(self.robust) is not bool:
            raise ValueError("robust must be a boolean")
        if self.deployment is not None:
            _finite(self.deployment, "deployment", positive=True)
            if self.deployment > 1:
                raise ValueError("deployment must be at most 1")

    def effective_stderr(self) -> float:
        """Optional small-n scale inflation using a Student-t variance analogy.

        This is a heuristic: widening alone does not certify interval coverage or
        specify the measurement likelihood. n<=3 uses an explicitly ad hoc factor.
        """
        if not self.robust:
            return self.stderr
        nu = self.n - 1
        if nu > 2:
            return self.stderr * math.sqrt(nu / (nu - 2))   # t-variance inflation
        return self.stderr * 3.0                             # n<=3: deliberately very wide

    def t(self) -> float:
        se = self.effective_stderr()
        return self.estimate / se


def update(prior: Quantity, m: Measurement,
           prior_provenance: frozenset = frozenset()) -> Quantity:
    """Conjugate (Normal-Normal) update of a prior by a measurement, gated by:
      * explicit complete estimand identity (unknown/mismatch raises TypeError);
      * small-n/fat-tail widening (Measurement.effective_stderr);
      * any shared provenance blocks precision gain, including partial overlap.

    Stored prior provenance is always used; callers cannot accidentally forget it
    on replay. Missing measurement provenance is rejected. Disjoint tags are only
    a de-duplication check: the caller must establish conditional independence to
    license this Normal-Normal calculation. This is not an FDR procedure.
    Trust is not touched here; it is DERIVED later (derived_trust)."""
    if not commensurable(prior, m):
        raise TypeError("measurement and prior require matching explicit estimand identities; "
                        "units/basis alone or two unknown legacy targets cannot license pooling")
    support = dict(prior.support)
    seen = _provenance(support.get("provenance", frozenset())) | _provenance(prior_provenance)
    if not m.provenance:
        raise ValueError("measurement provenance is required for a posterior update")
    if support.get("n", 0) and not seen:
        raise ValueError("prior evidence has no provenance; cannot check overlap")
    if seen & m.provenance:
        # Still retain explicitly supplied prior provenance for subsequent calls.
        support["provenance"] = seen
        return replace(prior, support=support)
    se = m.effective_stderr()
    _finite(se, "effective stderr", positive=True)
    # Ratios avoid overflow/underflow from explicitly squaring raw uncertainties.
    if prior.sigma <= se:
        ratio = prior.sigma / se
        weight = ratio * ratio / (1.0 + ratio * ratio)
    else:
        ratio = se / prior.sigma
        weight = 1.0 / (1.0 + ratio * ratio)
    post_sigma = min(prior.sigma, se) / math.sqrt(1.0 + ratio * ratio)
    post_mu = (1.0 - weight) * prior.value + weight * m.estimate
    support["n"] = support.get("n", 0) + m.n
    support["provenance"] = seen | m.provenance
    if m.deployment is not None:
        support["deployment"] = m.deployment
    return replace(prior, value=post_mu, sigma=post_sigma, support=support)


def derived_trust(q: Quantity) -> float:
    """Legacy-named signed SNR score in [-1,1], not calibrated factual confidence."""
    return math.tanh(q.snr())


# --------------------------------------------------------------------------- #
# Grounding as a colimit: an apex binds a pattern of externally-checked legs.
# --------------------------------------------------------------------------- #
@dataclass(frozen=True)
class Leg:
    """One descriptive measurement for a prediction entailed by an apex mechanism.

    Constructing a Leg does not certify a measurement. External check receipts
    must be verified at ingestion before this calculation may update belief.
      kind='prediction'  : must BIND — effect in `direction`, |t| >= Z_SIGNIF.
      kind='necessity'   : normal-approximation equivalence interval must lie within
                           a declared +/-equivalence_margin, not merely include zero.
      kind='specificity' : the thesis predicts the edge is PRESENT (`present=True`,
                           dir·t >= Z_SIGNIF) on should-work instruments, or ABSENT
                           (`present=False`, dir·t < Z_SIGNIF) on should-not ones. An
                           absent-check requires a one-sided upper bound below a
                           declared positive tolerated edge (equivalence_margin).
    `provenance` groups declared shared data; disjoint tags do not prove independence.
    Empty provenance marks an unmeasured/unknown slot, which cannot bind.
    Margins and confidence level must be chosen before seeing data. These tests
    assume the supplied effect/SE normal approximation; matching, causal necessity,
    multiplicity control and external verification are separate requirements."""
    name: str
    kind: str
    effect: float
    stderr: float
    provenance: frozenset
    direction: int = +1        # expected sign of the retail edge (+1/-1)
    present: bool = True       # specificity: is that edge expected present or absent?
    n: int = 100
    equivalence_margin: Optional[float] = None
    equivalence_z: float = Z_SIGNIF

    def __post_init__(self):
        _label(self.name, "leg name")
        if self.kind not in ("prediction", "necessity", "specificity"):
            raise ValueError(f"unknown leg kind: {self.kind!r}")
        _finite(self.effect, "effect")
        _finite(self.stderr, "stderr", positive=True)
        object.__setattr__(self, "provenance", _provenance(self.provenance))
        if type(self.direction) is not int or self.direction not in (-1, 0, 1):
            raise ValueError("direction must be -1, 0, or 1")
        if self.kind == "specificity" and self.direction == 0:
            raise ValueError("specificity requires a nonzero predicted direction")
        if type(self.present) is not bool:
            raise ValueError("present must be a boolean")
        _sample_size(self.n)
        if self.equivalence_margin is not None:
            _finite(self.equivalence_margin, "equivalence_margin", positive=True)
        _finite(self.equivalence_z, "equivalence_z", positive=True)

    def t(self) -> float:
        return self.effect / self.stderr

    def binds(self) -> bool:
        if not self.provenance:
            return False
        t = self.t()
        if self.kind == "necessity":
            return self.equivalence_margin is not None and (
                abs(self.effect) + self.equivalence_z*self.stderr < self.equivalence_margin)
        if self.kind == "specificity":
            signal = self.direction * t
            return (signal >= Z_SIGNIF) if self.present else (
                self.equivalence_margin is not None and
                self.direction*self.effect + self.equivalence_z*self.stderr < self.equivalence_margin)
        if self.direction == 0:
            return self.equivalence_margin is not None and (
                abs(self.effect) + self.equivalence_z*self.stderr < self.equivalence_margin)
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
    multiplicity: int                 # # disjoint declared groups with binding evidence
    verdict: float                    # support for apex, in [0,1]; not raw effect sign
    edge_weight: float                # derived from multiplicity (upgrades flat 0.3)
    failed_legs: tuple
    note: str


def edge_weight_from_multiplicity(m: int) -> float:
    """Saturating heuristic weight for distinct declared evidence groups.

    One group weighs ~0.39, three ~0.78. This is not a probability or a claim that
    different provenance labels establish statistical independence.
    """
    if type(m) is not int or m < 0:
        raise ValueError("multiplicity must be a nonnegative integer")
    return 1.0 - math.exp(-m / 2.0)


def _distinct_legs(legs):
    """Exact repeated checks, even when renamed, are one quorum vote.

    The lexically first name is retained for deterministic diagnostics. Shared
    provenance with different measurements is handled separately by _summary.
    """
    unique = {}
    for leg in legs:
        if not isinstance(leg, Leg):
            raise TypeError("grounding requires Leg measurements")
        key = (leg.kind, leg.effect, leg.stderr, leg.provenance,
               leg.direction, leg.present, leg.n, leg.equivalence_margin, leg.equivalence_z)
        if key not in unique or leg.name < unique[key].name:
            unique[key] = leg
    return sorted(unique.values(), key=lambda leg: leg.name)


def colimit(apex: str, legs: list[Leg]) -> GroundingResult:
    """Require every declared check plus positive binding evidence for the apex.

    Empty and null-only patterns cannot ground an apex. ``grounded`` describes
    coherence of these supplied measurements; external authenticity is checked by
    ingestion, not inferred from the numbers or tags here.
    """
    legs = _distinct_legs(legs)
    failed = tuple(sorted({l.name for l in legs if not l.binds()}))
    multiplicity, verdict_raw = _summary(legs)
    grounded = not failed and multiplicity > 0
    verdict = verdict_raw if grounded else 0.0
    ew = edge_weight_from_multiplicity(multiplicity) if grounded else 0.0
    note = ("coherent measurements; external receipt required for belief"
            if grounded else (f"failed or unmeasured legs: {failed}" if failed
                              else "no positive binding evidence (empty or null-only pattern)"))
    return GroundingResult(grounded, multiplicity, verdict, ew, failed, note)


def _summary(legs: list) -> tuple:
    """Group transitive provenance overlaps and score the weakest binding check.

    No precision is pooled, even across disjoint tags: those labels alone cannot
    justify independence. The support score uses the predicted direction, so an
    observed negative effect supports a hypothesis that predicted a negative effect.
    Repeated or renamed copies cannot raise its score or provenance multiplicity.
    Null/necessity legs may link source groups but never count as positive evidence.
    """
    groups = []                         # (union of tags, binding support scores)
    for leg in legs:
        if not leg.provenance:
            continue
        tags = set(leg.provenance)
        scores = [leg.direction * leg.t()] if leg.is_binding_evidence() else []
        remaining = []
        # Existing groups are already disjoint, so one pass closes every overlap.
        for group_tags, group_scores in groups:
            if tags & group_tags:
                tags.update(group_tags)
                scores.extend(group_scores)
            else:
                remaining.append((group_tags, group_scores))
        groups = remaining + [(tags, scores)]
    group_scores = [min(scores) for _, scores in groups if scores]
    return len(group_scores), math.tanh(min(group_scores)) if group_scores else 0.0


def colimit_hybrid(apex: str, legs: list, allow_miss: int = 1) -> GroundingResult:
    """The alternates.py finding, operationalized: grounding where NECESSITY legs (and
    absent-specificity legs) are a strict veto, but bind-required prediction / present-
    specificity legs are graded by QUORUM — up to `allow_miss` may fall short of the
    threshold without pruning the apex. So one marginal check no longer kills a real
    signal, while an ablation that must collapse remains non-negotiable."""
    if type(allow_miss) is not int or allow_miss < 0:
        raise ValueError("allow_miss must be a nonnegative integer")
    legs = _distinct_legs(legs)
    strict_kinds = [l for l in legs
                    if l.kind == "necessity" or (l.kind == "specificity" and not l.present)
                    or (l.kind == "prediction" and l.direction == 0)
                    or not l.provenance]
    veto = tuple(sorted({l.name for l in strict_kinds if not l.binds()}))
    if veto:
        return GroundingResult(False, 0, 0.0, 0.0, veto, f"strict veto (necessity/absent): {veto}")
    req = [l for l in legs if (l.kind == "prediction" and l.direction != 0)
           or (l.kind == "specificity" and l.present)]   # bind-wanting legs
    missed = tuple(sorted(l.name for l in req if not l.binds()))
    grounded = len(missed) <= allow_miss and (len(req) - len(missed)) >= 1
    multiplicity, verdict_raw = _summary(legs)
    grounded = grounded and multiplicity > 0
    verdict = verdict_raw if grounded else 0.0
    ew = edge_weight_from_multiplicity(multiplicity) if grounded else 0.0
    note = (f"grounded (quorum {len(req) - len(missed)}/{len(req)}, necessity strict)"
            if grounded else f"quorum not met; missed {missed}")
    return GroundingResult(grounded, multiplicity, verdict, ew, missed, note)


# --------------------------------------------------------------------------- #
# Multi-hop uncertainty composition (delta method for numerical hops).
# --------------------------------------------------------------------------- #
@dataclass(frozen=True)
class Hop:
    jacobian: float          # local linear gain d(out)/d(in)
    add_var: float = 0.0     # variance injected by this hop (model/approx error)
    label: str = ""
    output_identity: Optional[EstimandIdentity] = None

    def __post_init__(self):
        _finite(self.jacobian, "jacobian")
        _finite(self.add_var, "add_var")
        if self.add_var < 0:
            raise ValueError("add_var must be nonnegative")
        if self.output_identity is not None:
            if not isinstance(self.output_identity, EstimandIdentity):
                raise TypeError("output_identity must be EstimandIdentity or None")
            _label(self.label, "named transformation required for an identity change")


def compose_chain(base: Quantity, hops: list[Hop]) -> tuple[Quantity, bool]:
    """Propagate a quantity through numerical hops by the delta method:
    value *= prod(J); var_out = J^2 * var_in + add_var per hop. Returns the final
    quantity and a local gain/SNR diagnostic (product |J| < 1 and SNR maintained).
    This is zero-offset scalar linear propagation; nonlinear delta approximations,
    hop bias and correlated errors need additional models. The boolean establishes
    neither factual truth, calibrated coverage nor a general stability theorem.
    Units/basis stay fixed unless an explicit output_identity names a transformation.
    """
    v, var = base.value, base.sigma ** 2
    jprod = 1.0
    identity = base.identity
    for h in hops:
        v = v * h.jacobian
        var = (h.jacobian ** 2) * var + h.add_var
        jprod *= abs(h.jacobian)
        if h.output_identity is not None:
            identity = h.output_identity
    out = replace(base, value=v, sigma=math.sqrt(var), identity=identity,
                  units=identity.units if identity is not None else base.units,
                  basis=identity.basis if identity is not None else base.basis,
                  assumptions=base.assumptions + tuple(f"declared linear hop: {h.label}" for h in hops if h.label))
    local_gain_snr_ok = jprod < 1.0 and abs(out.snr()) >= abs(base.snr()) - 1e-9
    return out, local_gain_snr_ok


# --------------------------------------------------------------------------- #
# self-test — proven with numbers.
# --------------------------------------------------------------------------- #
def _selftest():
    target = EstimandIdentity("net return", "synthetic generator", "one period", (),
                              "abn_return_pts", "raw", "mean")
    # 1) conjugate update tightens and moves toward the measurement.
    prior = Quantity(0.0, 1.0, "abn_return_pts", identity=target)
    m = Measurement(5.0, 1.0, n=200, units="abn_return_pts", provenance=frozenset({"fixture"}), identity=target)
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

    # 3) explicit small-effect approximation; paired stream avoids the approximation.
    sharpe_target = EstimandIdentity("excess return", "synthetic generator", "one period", (),
                                     "sharpe", "calendar", "equal_period_sharpe")
    cal = Quantity(.001, .0001, "sharpe", basis="calendar", identity=sharpe_target)
    dep = to_deployed_approx(cal, .1, equal_period_zero_idle=True, low_active_snr=True)
    assert abs(dep.value - .001/math.sqrt(.1)) < 1e-12 and dep.assumptions
    paired = paired_sharpe([0.]*18 + [0., 2.], [False]*18 + [True, True])
    assert paired["deployed"]["sharpe"] == 1
    assert abs(paired["calendar"]["variance"] - .19) < 1e-12
    assert not commensurable(cal, dep)   # cannot be compared without the coercion

    # 4) evidence independence: a fully-redundant measurement does not move the posterior.
    p0 = Quantity(0.0, 1.0, "abn_return_pts", identity=target)
    prov = frozenset({"NQ_bars_2022_2026"})
    once = update(p0, Measurement(5.0, 1.0, 200, "abn_return_pts", provenance=prov, identity=target))
    redundant = update(once, Measurement(5.0, 1.0, 200, "abn_return_pts", provenance=prov, identity=target),
                       prior_provenance=prov)
    assert abs(redundant.value - once.value) < 1e-9 and abs(redundant.sigma - once.sigma) < 1e-9, \
        (once, redundant)
    independent = update(once, Measurement(5.0, 1.0, 200, "abn_return_pts",
                                           provenance=frozenset({"independent-generator-draws"}), identity=target),
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
        Leg("ungated_flat", "necessity", 0.3, .1, frozenset({"NQ"}), equivalence_margin=.5),
        Leg("ablation_collapses", "necessity", -0.2, .1, frozenset({"NQ_abl"}), equivalence_margin=.5),
        Leg("cross_NQ", "specificity", 5.4, 1.9, frozenset({"XI"}), direction=+1, present=True),
        Leg("cross_YM", "specificity", -7.7, 1.6, frozenset({"XI"}), direction=+1, present=False,
            equivalence_margin=1.),
    ]
    r = colimit("nq_reversal", legs_ok)
    assert r.grounded and r.multiplicity == 2 and r.verdict > 0.9, r
    assert r.edge_weight > 0.3, r.edge_weight
    bad = list(legs_ok); bad[2] = Leg("ablation_collapses", "necessity", 4.0, 1.2,
                                      frozenset({"NQ_abl"}), equivalence_margin=.5)
    assert not colimit("nq_reversal", bad).grounded

    print("estimand selftest: PASS (conjugate tighten+move; type-check refuses; "
          "paired return moments and explicit small-effect approximation; replay inert; "
          "declared equivalence margin required; local linear uncertainty propagation)")


if __name__ == "__main__":
    _selftest()
