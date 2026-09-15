"""metalearn.py — the brain learns its own escalation thresholds from divergence residuals.

The selector's cheap↔heavy DIVERGENCE is itself a residual signal — the KL-residual
principle turned reflexively on the brain: *where the cheap machinery was wrong is exactly
where to escalate*. A fixed, hand-set threshold (selector.py) prunes regions it never
checks; a residual-driven learner with optimism-under-uncertainty (UCB) DISCOVERS
divergence corners the hand rule misses — the "dead marginal, beautiful corner"
phenomenon, found automatically instead of hand-specified.

Formulation: a contextual bandit over the {escalate, skip} action. Escalating costs `c`
but yields the right answer; skipping is free but incurs an error ~ divergence·stakes.
Escalate iff the UCB estimate of divergence·stakes exceeds `c`. UCB's bonus keeps every
region occasionally revisited, so no corner is permanently pruned (active inference: the
epistemic drive is built into the decision, not bolted on).

Dependency-free. Run: python3 metalearn.py
"""
from __future__ import annotations

import math
import random

RNG = random.Random(7)


def _n_bucket(n):
    return "tiny" if n < 15 else "small" if n < 50 else "med" if n < 200 else "large"


def _z_bucket(z):
    return "z0" if z < 1 else "z1" if z < 2 else "z2" if z < 4 else "z4" if z < 6 else "z6"


class ResidualLearner:
    """Learns E[divergence | context] from the residuals it observes when it escalates,
    and escalates by an optimistic (UCB) estimate so under-sampled contexts get probed."""

    def __init__(self, cost=1.0, stakes=10.0, beta=0.3):
        self.cost, self.stakes, self.beta = cost, stakes, beta
        self.mean: dict = {}      # bucket -> running mean divergence
        self.count: dict = {}     # bucket -> times observed
        self.t = 0

    def _bucket(self, n, z):
        return (_n_bucket(n), _z_bucket(z))

    def ucb_div(self, n, z):
        b = self._bucket(n, z)
        m = self.mean.get(b, 0.0)
        c = self.count.get(b, 0)
        bonus = self.beta * math.sqrt(math.log(self.t + 2) / (c + 1))
        return m + bonus

    def decide(self, n, z) -> bool:
        self.t += 1
        # escalate iff the optimistic expected error beats the escalation cost
        return self.ucb_div(n, z) * self.stakes > self.cost

    def observe(self, n, z, divergence):
        b = self._bucket(n, z)
        c = self.count.get(b, 0)
        self.mean[b] = (self.mean.get(b, 0.0) * c + divergence) / (c + 1)
        self.count[b] = c + 1

    def escalates(self, n, z) -> bool:
        """Post-hoc read: would it escalate here now (no exploration bonus)?"""
        return self.mean.get(self._bucket(n, z), 0.0) * self.stakes > self.cost


# ---- the true (hidden) divergence surface the learner must discover -------- #
def true_divergence(n, z):
    """Cheap↔heavy divergence. Two divergent regions: a KNOWN corner the fixed rule
    covers (small n & large z), and a HIDDEN corner it never checks (mid-z, large n) —
    the beautiful corner a low-dimensional hand rule prunes."""
    d = 0.02
    if n < 30 and z > 4:
        d = 1.2                       # known corner (fixed rule escalates here)
    elif 1.0 <= z < 2.0 and n >= 200:
        d = 0.9                       # HIDDEN corner (fixed rule misses it entirely)
    return max(0.0, d + RNG.gauss(0, 0.02))


def fixed_policy(n, z) -> bool:       # the hand-set selector.py rule
    return n < 30 or z > 4.0


def _incurred(escalate, div, cost, stakes):
    return cost if escalate else div * stakes


def _selftest():
    cost, stakes, T = 1.0, 10.0, 12000
    learner = ResidualLearner(cost, stakes)
    reg = {"always": 0.0, "never": 0.0, "fixed": 0.0, "learner": 0.0}
    for _ in range(T):
        n = RNG.choice([5, 10, 20, 60, 200, 500])
        z = RNG.uniform(0, 8)
        d = true_divergence(n, z)
        oracle = min(cost, d * stakes)                       # best possible this step
        # policies
        reg["always"] += _incurred(True, d, cost, stakes) - oracle
        reg["never"] += _incurred(False, d, cost, stakes) - oracle
        reg["fixed"] += _incurred(fixed_policy(n, z), d, cost, stakes) - oracle
        esc = learner.decide(n, z)
        reg["learner"] += _incurred(esc, d, cost, stakes) - oracle
        if esc:
            learner.observe(n, z, d)                         # observe the residual only when we pay

    print("cumulative regret over", T, "situations (lower is better):")
    for k in ("always", "never", "fixed", "learner"):
        print(f"  {k:8} {reg[k]:9.1f}")

    # the payoff checks: the learner beats the fixed hand-rule AND both trivial policies,
    # by (a) not over-escalating in the safe small-n region and (b) DISCOVERING the hidden
    # mid-z/large-n corner the fixed rule never checks.
    assert reg["learner"] < reg["fixed"], reg
    assert reg["learner"] < reg["always"] and reg["learner"] < reg["never"], reg
    hidden_found = learner.escalates(500, 1.5)     # the corner the fixed rule prunes
    fixed_hidden = fixed_policy(500, 1.5)
    print(f"\nhidden corner (n=500, z=1.5, true div {true_divergence(500,1.5):.2f}):")
    print(f"  learner escalates? {hidden_found}   fixed-rule escalates? {fixed_hidden}")
    assert hidden_found and not fixed_hidden, (hidden_found, fixed_hidden)
    # and it does NOT waste escalation in the genuinely safe region
    assert not learner.escalates(500, 0.3), "should have learned the safe region skips"

    print("\nmetalearn selftest: PASS — the learner used divergence residuals to beat the "
          "fixed hand-rule, discovered the hidden divergence corner the rule prunes, and "
          "stopped wasting escalation in the safe region. Residual -> better machinery.")


if __name__ == "__main__":
    _selftest()
