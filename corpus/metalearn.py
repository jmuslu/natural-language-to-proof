"""Learn cost-aware escalation from externally scored paired outcomes.

Method disagreement is a diagnostic, not an error label. A paid heavy method may
be worse than the cheap method, or share its bias. The learner estimates signed
loss reduction from checked outcomes. Its optimism bonus is a heuristic; no
bandit regret theorem is claimed for changing, selectively observed contexts.
"""
from __future__ import annotations

import math


def _n_bucket(n):
    return "tiny" if n < 15 else "small" if n < 50 else "med" if n < 200 else "large"


def _z_bucket(z):
    return "z0" if z < 1 else "z1" if z < 2 else "z2" if z < 4 else "z4" if z < 6 else "z6"


def finite(value, label):
    if type(value) not in (int, float) or not math.isfinite(value):
        raise ValueError(f"{label} must be finite")
    return value


class ResidualLearner:
    """Estimate E[cheap_loss-heavy_loss | context] from checked paired examples.

    Each loss is in [0,1]. Only the chosen training probes may be observed;
    evaluation freezes the learned policy and withholds test outcomes until scoring.
    """
    def __init__(self, cost=1., stakes=10., beta=.3):
        if finite(cost, "cost") < 0 or finite(stakes, "stakes") <= 0 or finite(beta, "beta") < 0:
            raise ValueError("nonnegative cost/beta and positive stakes required")
        self.cost, self.stakes, self.beta = cost, stakes, beta
        self.mean, self.count, self.t = {}, {}, 0

    def _bucket(self, n, z):
        if type(n) is not int or n < 1 or finite(z, "context discrepancy") < 0:
            raise ValueError("positive n and nonnegative finite discrepancy required")
        return _n_bucket(n), _z_bucket(z)

    def ucb_gain(self, n, z):
        bucket = self._bucket(n, z)
        bonus = self.beta * math.sqrt(math.log(self.t+2)/(self.count.get(bucket, 0)+1))
        return self.mean.get(bucket, 0.) + bonus

    def decide(self, n, z):
        self._bucket(n, z)
        self.t += 1
        return self.ucb_gain(n, z)*self.stakes > self.cost

    def observe(self, n, z, *, cheap_loss, heavy_loss):
        for label, loss in (("cheap_loss", cheap_loss), ("heavy_loss", heavy_loss)):
            if not 0 <= finite(loss, label) <= 1:
                raise ValueError("checked losses must be in [0,1]")
        bucket = self._bucket(n, z)
        count = self.count.get(bucket, 0)
        gain = cheap_loss-heavy_loss
        self.mean[bucket] = (self.mean.get(bucket, 0.)*count+gain)/(count+1)
        self.count[bucket] = count+1

    def escalates(self, n, z):
        """Frozen decision: no exploration or test-label updates."""
        return self.mean.get(self._bucket(n, z), 0.)*self.stakes > self.cost


def fixed_policy(n, z):
    return n < 30 or z > 4.


def incurred(escalate, cheap_loss, heavy_loss, cost, stakes):
    return cost + stakes*heavy_loss if escalate else stakes*cheap_loss


def _selftest():
    import json
    from adaptive_evaluation import selector_experiment
    print(json.dumps(selector_experiment(), indent=2))


if __name__ == "__main__":
    _selftest()
