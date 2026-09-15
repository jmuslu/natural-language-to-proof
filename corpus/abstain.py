"""Calibrate a selective decision using independently checked outcomes.

Scores are fallible predictions of correctness. Calibration uses separate labeled
examples; no score reveals whether that example's label was actually corrupted.
The finite-threshold bound assumes independent examples from the deployment
distribution. It does not certify risk after a quality or context shift.
"""
from __future__ import annotations

from dataclasses import dataclass
import math

from grok import sample_signal


def probability(value):
    if type(value) not in (int, float) or not math.isfinite(value) or not 0 <= value <= 1:
        raise ValueError("finite probability in [0,1] required")
    return float(value)


def labeled_stream(rng, n, p_noise=.25, *, shifted=False):
    """Simulated fallible label source; quality is drawn before label corruption.

    Same-quality rows contain both correct and incorrect labels. Under shifted=True
    the confidence ranking reverses; a threshold frozen on the old channel can fail.
    The synthetic target remains hidden from the consumer of this stream.
    """
    probability(p_noise)
    if type(n) is not int or n < 0:
        raise ValueError("nonnegative integer sample count required")
    qualities = (max(.01, 1-1.8*p_noise), 1-p_noise, min(.99, 1-.2*p_noise))
    out = []
    for _ in range(n):
        feats, truth, _ = sample_signal(rng, "market")
        quality = rng.choice(qualities)
        actual = max(0., min(1., 1.25-quality)) if shifted else quality
        label = truth if rng.random() < actual else not truth
        out.append((feats, label, quality))
    return out


@dataclass(frozen=True)
class Threshold:
    value: float | None
    max_risk: float
    alpha: float
    calibration: tuple

    def accepts(self, score):
        score = probability(score)
        return self.value is not None and score >= self.value

    def to_dict(self):
        return {"threshold": self.value, "max_risk": self.max_risk, "alpha": self.alpha,
                "calibration": list(self.calibration),
                "bound": "finite-threshold Hoeffding union bound; independent same-distribution examples required"}


def checked_rows(rows):
    result = []
    for score, prediction, truth in rows:
        if type(prediction) is not bool or type(truth) is not bool:
            raise ValueError("Boolean predictions and independently checked Boolean outcomes required")
        result.append((probability(score), prediction, truth))
    return result


def fit_threshold(rows, *, max_risk=.1, alpha=.05, thresholds=(.5, .7, .8, .9, .95)):
    """Choose greatest calibration coverage among thresholds passing a risk bound.

    Candidate thresholds must be fixed before inspecting these outcomes. The
    union bound covers selection among that finite family, including threshold ties.
    No passing threshold yields a valid all-abstain policy.
    """
    rows = checked_rows(rows)
    probability(max_risk)
    if not 0 < probability(alpha) < 1:
        raise ValueError("alpha must be strictly between zero and one")
    candidates = sorted(set(probability(t) for t in thresholds))
    if not candidates:
        raise ValueError("a prespecified finite threshold family is required")
    reports = []
    for threshold in candidates:
        accepted = [(p, y) for score, p, y in rows if score >= threshold]
        n = len(accepted)
        errors = sum(p != y for p, y in accepted)
        risk = errors/n if n else None
        upper = min(1., risk + math.sqrt(math.log(len(candidates)/alpha)/(2*n))) if n else 1.
        reports.append({"threshold": threshold, "accepted": n, "errors": errors,
                        "risk": risk, "risk_upper": upper})
    eligible = [r for r in reports if r["accepted"] and r["risk_upper"] <= max_risk]
    chosen = max(eligible, key=lambda r: (r["accepted"], -r["threshold"]))["threshold"] if eligible else None
    return Threshold(chosen, max_risk, alpha, tuple(reports))


def risk_coverage(rows, threshold=None):
    rows = checked_rows(rows)
    kept = [(p, y) for score, p, y in rows if threshold is None or threshold.accepts(score)]
    errors = sum(p != y for p, y in kept)
    return {"examples": len(rows), "accepted": len(kept), "errors": errors,
            "coverage": len(kept)/len(rows) if rows else 0.,
            "risk": errors/len(kept) if kept else None,
            "score_brier": sum((score-(p == y))**2 for score, p, y in rows)/len(rows) if rows else None}


def _selftest():
    import json
    from adaptive_evaluation import abstention_experiment
    print(json.dumps(abstention_experiment(), indent=2))


if __name__ == "__main__":
    _selftest()
