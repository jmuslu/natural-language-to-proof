"""regime_estimand.py — the estimand as a non-stationary STATE, adaptive to regime breaks.

An estimand's true value is rarely a fixed scalar: an edge drifts with regime and JUMPS at
a transition (a bifurcation, in the dynamical-systems view). A fixed-uncertainty posterior
lags such a jump confidently — the overconfidence failure. Here the estimand is a state
tracked by a scalar Kalman filter whose process noise INFLATES on surprise: the innovation
(prediction residual, standardized) is the regime-break detector, and a large innovation
widens the state covariance before the update — so the belief adapts fast AND its
uncertainty spikes honestly at the break.

This is the same residual principle a third time: the Kalman innovation IS the residual;
acting on it (inflating process noise) is acting on surprise — the free-energy / active-
inference move, now for a non-stationary estimand. Dependency-free. Run: python3 regime_estimand.py
"""
from __future__ import annotations

import random


def kalman(obs, R, q_base, adaptive=False, beta=4.0, thresh=1.0):
    """Scalar Kalman over `obs` (obs = state + N(0,R)). If `adaptive`, a standardized
    innovation above `thresh` inflates the predicted covariance (regime-break reaction).
    Returns (estimates, covariances, surprises)."""
    x, P = obs[0], 1.0
    est, cov, surp = [], [], []
    for y in obs:
        # predict
        P_pred = P + q_base
        # innovation / surprise (available before the update)
        nu = y - x
        S = P_pred + R
        s = (nu * nu) / S            # standardized squared innovation ~ chi2(1) if in-regime
        surp.append(s)
        if adaptive and s > thresh:
            P_pred *= (1.0 + beta * (s - thresh))   # surprise inflates the state covariance
            S = P_pred + R
        # update
        K = P_pred / S
        x = x + K * nu
        P = (1.0 - K) * P_pred
        est.append(x); cov.append(P)
    return est, cov, surp


def _mae(est, truth, lo, hi):
    idx = range(lo, hi)
    return sum(abs(est[i] - truth[i]) for i in idx) / len(list(idx))


def _selftest():
    rng = random.Random(5)
    T, jump_t, R_true = 120, 60, 0.15
    # true state: slow drift, then a REGIME JUMP (+1.0) at jump_t, then drift again.
    truth, x = [], 0.5
    for t in range(T):
        x += rng.gauss(0, 0.02)
        if t == jump_t:
            x += 1.0
        truth.append(x)
    obs = [xt + rng.gauss(0, R_true) for xt in truth]

    fixed_e, fixed_P, _ = kalman(obs, R=R_true, q_base=0.001, adaptive=False)
    adapt_e, adapt_P, surp = kalman(obs, R=R_true, q_base=0.001, adaptive=True)

    # post-jump tracking error (does it catch the new regime quickly?)
    band = (jump_t, jump_t + 12)
    mae_fixed = _mae(fixed_e, truth, *band)
    mae_adapt = _mae(adapt_e, truth, *band)
    # uncertainty right after the jump (is it honestly wide, or falsely confident?)
    P_fixed_jump = max(fixed_P[jump_t:jump_t + 3])
    P_adapt_jump = max(adapt_P[jump_t:jump_t + 3])
    print(f"regime jump at t={jump_t} (+1.0)")
    print(f"  post-jump MAE   fixed {mae_fixed:.3f}   adaptive {mae_adapt:.3f}")
    print(f"  P at jump       fixed {P_fixed_jump:.3f}   adaptive {P_adapt_jump:.3f}")
    print(f"  surprise (std innovation^2) at jump: {max(surp[jump_t:jump_t+3]):.1f}  "
          f"(vs ~1 in-regime; the innovation IS the regime-break residual)")

    # CHECKS: the surprise-adaptive estimand (a) tracks the regime break markedly faster,
    # and (b) is HONESTLY uncertain at the break (covariance spikes) rather than confidently
    # wrong like the fixed-noise filter.
    assert mae_adapt < mae_fixed * 0.7, (mae_fixed, mae_adapt)
    assert P_adapt_jump > P_fixed_jump * 3, (P_fixed_jump, P_adapt_jump)
    # and in the stable pre-jump regime the adaptive filter is NOT needlessly loose
    assert _mae(adapt_e, truth, 20, 55) < 0.15

    print("\nregime_estimand selftest: PASS — the estimand tracks a regime jump fast AND "
          "widens its uncertainty honestly at the break (surprise-driven process noise), "
          "while staying tight in the stable regime. Non-stationary, residual-adaptive.")


if __name__ == "__main__":
    _selftest()
