"""Scalar state tracking with separate jump and observation-outlier heuristics.

R is observation VARIANCE; q_base is process VARIANCE per transition. The fixed
Kalman model is a baseline. Adaptive process inflation follows large innovations
quickly, which can help jumps but amplify isolated bad observations. Optional robust
observation inflation damps outliers but can delay real jumps. Their covariance
outputs are model diagnostics, not automatically calibrated uncertainty guarantees.
Run: python3 regime_estimand.py
"""
from __future__ import annotations

import math
import random


def _number(value, name):
    try:
        valid = type(value) in (int, float) and math.isfinite(value)
    except OverflowError:
        valid = False
    if not valid:
        raise ValueError(f"{name} must be a finite number")
    return float(value)


def kalman(obs, R, q_base, adaptive=False, beta=4.0, thresh=1.0, *,
           robust=False, outlier_z=3.0, initial_mean=None, initial_variance=None):
    """Return (estimates, state variances, standardized squared innovations).

    Observation model: y_t = state_t + N(0, R); R and q_base are variances.
    With no independent prior, the first observation initializes mean=y_0, P=R
    exactly once (the flat-prior limit); its innovation is unavailable, represented
    by None. Alternatively supply both initial_mean and initial_variance, describing
    an independent state prior just before the first transition/update.

    adaptive=True inflates predicted state variance when innovation^2/S > thresh.
    robust=True inflates observation variance by max(1, innovation^2/(S*outlier_z^2)),
    damping isolated extreme measurements. Both flags are explicit heuristics;
    neither dominates, and combining them is not a fitted regime/outlier classifier.
    All outputs are causal for fixed parameters. Empty observations return three
    empty lists. Invalid or numerically overflowing inputs raise ValueError.
    """
    R, q_base = _number(R, "R (observation variance)"), _number(q_base, "q_base (process variance)")
    beta, thresh = _number(beta, "beta"), _number(thresh, "thresh")
    outlier_z = _number(outlier_z, "outlier_z")
    if R <= 0 or q_base < 0 or beta < 0 or thresh <= 0 or outlier_z <= 0:
        raise ValueError("positive R, thresh, outlier_z and nonnegative q_base, beta required")
    if type(adaptive) is not bool or type(robust) is not bool:
        raise ValueError("adaptive and robust must be bool")
    if (initial_mean is None) != (initial_variance is None):
        raise ValueError("supply both independent initial_mean and initial_variance, or neither")
    if initial_mean is not None:
        initial_mean = _number(initial_mean, "initial_mean")
        initial_variance = _number(initial_variance, "initial_variance")
        if initial_variance < 0:
            raise ValueError("initial_variance must be nonnegative")
    obs = [_number(y, "observation") for y in obs]
    if not obs:
        return [], [], []
    if initial_mean is None:
        x, P, start = obs[0], R, 1
        estimates, variances, surprises = [x], [P], [None]
    else:
        x, P, start = initial_mean, initial_variance, 0
        estimates, variances, surprises = [], [], []
    for y in obs[start:]:
        predicted = P + q_base
        innovation = y - x
        S = predicted + R
        try:
            surprise = innovation ** 2 / S
            effective_R = R * max(1., surprise / outlier_z ** 2) if robust else R
            if adaptive and surprise > thresh:
                predicted *= 1. + beta * (surprise - thresh)
        except (OverflowError, ZeroDivisionError) as exc:
            raise ValueError("filter scale exceeds numerical range") from exc
        if (not all(math.isfinite(value) for value in (predicted, effective_R, S, surprise))
                or not math.isfinite(predicted + effective_R)):
            raise ValueError("filter scale exceeds numerical range")
        gain = predicted / (predicted + effective_R)
        x += gain * innovation
        # Joseph form avoids cancellation from (1-K)*P when the gain is near one.
        P = (1. - gain) ** 2 * predicted + gain ** 2 * effective_R
        if not math.isfinite(x) or not math.isfinite(P):
            raise ValueError("filter scale exceeds numerical range")
        estimates.append(x)
        variances.append(P)
        surprises.append(surprise)
    return estimates, variances, surprises


def _mae(est, truth, lo, hi):
    return sum(abs(est[i] - truth[i]) for i in range(lo, hi)) / (hi - lo)


def _selftest():
    rng = random.Random(5)
    T, jump_t, noise_sd = 120, 60, .15
    truth, x = [], .5
    for t in range(T):
        x += rng.gauss(0, .02)
        if t == jump_t:
            x += 1.
        truth.append(x)
    obs = [value + rng.gauss(0, noise_sd) for value in truth]
    modes = {"fixed": {}, "adaptive": {"adaptive": True}, "robust": {"robust": True}}
    jump_mae = {name: _mae(kalman(obs, R=noise_sd**2, q_base=.001, **kwargs)[0],
                           truth, jump_t, jump_t+12) for name, kwargs in modes.items()}
    outlier = [0.] * 40 + [10.] + [0.] * 39
    outlier_response = {name: kalman(outlier, R=.04, q_base=.001, **kwargs)[0][40]
                        for name, kwargs in modes.items()}
    assert jump_mae["adaptive"] < jump_mae["fixed"]
    assert abs(outlier_response["robust"]) < abs(outlier_response["fixed"])
    assert kalman([10], R=4, q_base=0) == ([10.], [4.], [None])
    print(f"regime_estimand selftest: PASS; generated sd={noise_sd}, filter R={noise_sd**2}")
    print(f"  seeded jump MAE: {jump_mae}")
    print(f"  isolated outlier response: {outlier_response}")
    print("  Tradeoffs are scenario-specific; these checks do not establish calibrated coverage.")


if __name__ == "__main__":
    _selftest()
