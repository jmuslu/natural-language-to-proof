"""Causal filtering updates and explicitly retrospective HMM diagnostics.

``causal_surprise_series`` uses observations through the scored time only, for
fixed model parameters. ``retrospective_surprise_series`` compares filtering to
full-sequence smoothing and therefore needs future data. The old ``surprise_series``
name remains a retrospective compatibility wrapper.

Neither diagnostic establishes a profitable signal or expected experiment value.
Realized posterior-to-predictive KL, expected information gain, and variational
free energy are different quantities. Dependency-free Gaussian HMM, any state count.
"""
from __future__ import annotations

import math


def _finite(value, name):
    try:
        valid = type(value) in (int, float) and math.isfinite(value)
    except OverflowError:
        valid = False
    if not valid:
        raise ValueError(f"{name} must be a finite number")
    return float(value)


def _distribution(values, name):
    values = [_finite(value, name) for value in values]
    if (not values or any(value < 0 or value > 1 for value in values)
            or not math.isclose(math.fsum(values), 1, rel_tol=0, abs_tol=1e-12)):
        raise ValueError(f"{name} must be normalized nonnegative probabilities")
    return values


def _log(value):
    return math.log(value) if value else -math.inf


def _logsumexp(values):
    largest = max(values)
    if largest == -math.inf:
        return largest
    return largest + math.log(math.fsum(math.exp(value - largest) for value in values))


def _normalise_logs(values):
    normalizer = _logsumexp(values)
    if not math.isfinite(normalizer):
        raise ValueError("model has no numerically representable likelihood for observations")
    return [value - normalizer for value in values], normalizer


def _forward(obs, mus, sd, trans, pi):
    obs = [_finite(value, "observation") for value in obs]
    mus = [_finite(value, "state mean") for value in mus]
    sd = _finite(sd, "observation standard deviation")
    if not mus or sd <= 0:
        raise ValueError("nonempty states and positive observation standard deviation required")
    pi = _distribution(pi, "initial state distribution")
    trans = [_distribution(row, "transition row") for row in trans]
    states = len(mus)
    if len(pi) != states or len(trans) != states or any(len(row) != states for row in trans):
        raise ValueError("state means, initial distribution, and square transition matrix must agree")
    logtrans = [[_log(value) for value in row] for row in trans]
    constant = math.log(sd) + .5 * math.log(2 * math.pi)
    try:
        emissions = [[-.5 * ((value - mu) / sd) ** 2 - constant for mu in mus] for value in obs]
    except OverflowError as exc:
        raise ValueError("observation scale exceeds numerical range") from exc
    if any(not math.isfinite(value) for row in emissions for value in row):
        raise ValueError("observation scale exceeds numerical range")

    trace, logfilters = [], []
    for t, emission in enumerate(emissions):
        predicted = ([_log(value) for value in pi] if t == 0 else
                     [_logsumexp([logfilters[-1][j] + logtrans[j][s] for j in range(states)])
                      for s in range(states)])
        posterior, log_evidence = _normalise_logs([p + e for p, e in zip(predicted, emission)])
        information_gain = math.fsum(math.exp(post) * (post - pred)
                                     for post, pred in zip(posterior, predicted)
                                     if post != -math.inf)
        logfilters.append(posterior)
        trace.append({"t": t, "predictive": [math.exp(p) for p in predicted],
                      "posterior": [math.exp(p) for p in posterior],
                      "information_gain_kl": max(0., information_gain),
                      "predictive_surprisal": -log_evidence})
    return trace, logfilters, emissions, logtrans


def causal_surprise_series(obs, mus, sd, trans, pi):
    """Per-time causal diagnostics, in nats, with parameters fixed before scoring.

    ``predictive`` is P(state_t | observations_before_t), ``posterior`` includes
    observation_t. ``information_gain_kl`` is KL(posterior || predictive), the
    realized belief update. ``predictive_surprisal`` is -log predictive observation
    density; it depends on measurement units and can be negative. Large observation
    surprise need not reveal the state. This is not expected information gain over
    proposed experiments. Estimating parameters using later data would leak future
    information even though this forward pass itself is causal. ``sd`` is a standard
    deviation, not a variance.
    """
    return _forward(obs, mus, sd, trans, pi)[0]


def filter_smooth(obs, mus, sd, trans, pi):
    """Return (causal filter, full-sequence smoother) state posteriors.

    Forward/backward calculations stay in log space so extreme observations do not
    turn every state probability into zero. Empty observations produce empty lists.
    """
    trace, logfilters, emissions, logtrans = _forward(obs, mus, sd, trans, pi)
    if not trace:
        return [], []
    states = len(logfilters[0])
    logbackward = [[0.] * states for _ in trace]
    for t in range(len(trace) - 2, -1, -1):
        values = [_logsumexp([logtrans[s][j] + emissions[t+1][j] + logbackward[t+1][j]
                              for j in range(states)]) for s in range(states)]
        logbackward[t], _ = _normalise_logs(values)
    smoothed = []
    for filtered, backward in zip(logfilters, logbackward):
        row, _ = _normalise_logs([a + b for a, b in zip(filtered, backward)])
        smoothed.append([math.exp(value) for value in row])
    return [row["posterior"] for row in trace], smoothed


def kl(p, q):
    """KL(p || q), with exact zero-support semantics (positive / zero -> infinity)."""
    p, q = _distribution(p, "p"), _distribution(q, "q")
    if len(p) != len(q):
        raise ValueError("distributions must have equal length")
    if any(left > 0 and right == 0 for left, right in zip(p, q)):
        return math.inf
    return max(0., math.fsum(left * (math.log(left) - math.log(right))
                            for left, right in zip(p, q) if left > 0))


def retrospective_surprise_series(obs, mus, sd, trans, pi):
    """KL(filter_t || full-sequence smoother_t): a future-sensitive diagnostic.

    Historical values change when future observations arrive. Do not score a
    historical action with this full-sequence value as though it was available then.
    """
    filt, smooth = filter_smooth(obs, mus, sd, trans, pi)
    return [kl(f, g) for f, g in zip(filt, smooth)]


def surprise_series(obs, mus, sd, trans, pi):
    """Compatibility wrapper: RETROSPECTIVE; see causal_surprise_series for live use."""
    return retrospective_surprise_series(obs, mus, sd, trans, pi)


def where_to_explore(scores):
    """Index of the largest supplied diagnostic score; not an acquisition model.

    Scoring a proposed experiment requires outcomes, likelihoods, and a utility.
    Ranking realized surprise alone does not supply those missing quantities.
    """
    if not scores:
        raise ValueError("at least one diagnostic score required")
    return max(range(len(scores)), key=lambda i: scores[i])


def _selftest():
    args = ((0., 2.), .6, [[.95, .05], [.05, .95]], [.5, .5])
    prefix, future = [0., 0., 1.], [2., 2., 2.]
    causal = causal_surprise_series(prefix, *args)
    assert causal == causal_surprise_series(prefix + future, *args)[:len(prefix)]
    before = surprise_series(prefix, *args)[-1]
    hindsight = surprise_series(prefix + future, *args)[len(prefix)-1]
    assert before < 1e-12 and hindsight > .4
    print(f"surprise selftest: PASS; causal prefix unchanged; hindsight KL {before:.6f} -> {hindsight:.6f}")


if __name__ == "__main__":
    _selftest()
