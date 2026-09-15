"""Executable research counterexamples, not validation receipts or market evidence.

All inputs are constructed locally. Exact algebra, finite enumeration, current-code
probes, and seeded Monte Carlo measurements are labeled separately in the report.
The helpers are reusable in future benchmarks; running this file changes no corpus
beliefs. See RESEARCH_THREADS.md for hypotheses, limitations, and primary sources.
"""
from __future__ import annotations

import argparse
import itertools
import json
import math
from pathlib import Path
import random
import statistics


def bernoulli_kl(p, q):
    """KL(Bernoulli(p) || Bernoulli(q)), in nats, for interior probabilities."""
    if not 0 < p < 1 or not 0 < q < 1:
        raise ValueError("probabilities must be strictly between zero and one")
    return p * math.log(p / q) + (1 - p) * math.log((1 - p) / (1 - q))


def expected_information_gain(prior, likelihood):
    """Exact E_y KL(p(theta|y)||p(theta)) for a finite experiment.

    likelihood[theta][y] is a probability, not an observed hindsight score.
    """
    rows = [list(row) for row in likelihood]
    if not prior or len(prior) != len(rows) or not rows[0]:
        raise ValueError("nonempty prior and one likelihood row per state required")
    if any(len(row) != len(rows[0]) for row in rows):
        raise ValueError("likelihood rows must have equal length")
    for values in [prior] + rows:
        if (any(type(x) not in (int, float) or not math.isfinite(x) or x < 0 for x in values)
                or not math.isclose(math.fsum(values), 1, abs_tol=1e-12)):
            raise ValueError("normalized finite probabilities required")
    predictive = [math.fsum(prior[t] * rows[t][y] for t in range(len(prior)))
                  for y in range(len(rows[0]))]
    eig = math.fsum(prior[t] * rows[t][y] * math.log(rows[t][y] / predictive[y])
                    for t in range(len(prior)) for y in range(len(predictive))
                    if prior[t] * rows[t][y] > 0)
    entropy = -math.fsum(p * math.log(p) for p in predictive if p > 0)
    return {"expected_information_gain": eig, "predictive_entropy": entropy}


def stability_counterexamples():
    """Exact finite-dimensional witnesses; no fitted dynamical model."""
    # A = [[.5,10],[0,.5]]: eigenvalues .5, but A e2=(10,.5).
    return {
        "matrix": [[.5, 10], [0, .5]], "spectral_radius": .5,
        "one_step_e2_norm_gain": math.sqrt(100.25),
        "covariance_trace_before": 2, "covariance_trace_after": 100.5,
        "stable_noisy_scalar": {"a": .5, "Q": 100, "variance_before": 1,
                                "variance_after": 100.25, "stationary_variance": 100 / .75},
        "biased_contraction": {"map": "100 + 0.1*x", "jacobian": .1,
                               "input_mean": 0, "input_sigma": 1,
                               "output_mean": 100, "output_sigma": .1, "target": 0},
        "exact_unit_scaling": {"jacobian": 100, "input_snr": 2, "output_snr": 200 / 100},
    }


def topology_counterexample():
    """h(x)=sign(x)|x|^2 conjugates e^-t*x to e^-2t*y exactly.

    Relaxation time is not preserved by this nonlinear coordinate change. The
    small numerical residual checks the displayed identity; the formula proves it.
    """
    h = lambda x: math.copysign(x * x, x)
    residual = max(abs(h(math.exp(-t) * x) - math.exp(-2 * t) * h(x))
                   for x in (-3, -1, 0, 1, 3) for t in (0, .2, 1, 3))
    return {"flows": ["dx/dt=-x", "dy/dt=-2y"], "conjugacy": "sign(x)*abs(x)^2",
            "identity_max_roundoff": residual, "relaxation_times": [1, .5],
            "same_estimand": False,
            "bound": "Conjugacy preserves orbit structure, not a chosen observable, scale, or estimand."}


def coproduct_factorization(apex_size, left_point, right_point, target_size=2):
    """Enumerate the finite universal-property test for two singleton objects.

    Every choice of maps into the target must factor through exactly one mediator
    from the proposed apex. A commuting cocone alone need not satisfy this.
    """
    if (type(apex_size) is not int or apex_size < 1 or target_size < 1
            or left_point not in range(apex_size) or right_point not in range(apex_size)):
        raise ValueError("valid finite apex, target, and inclusion points required")
    counts = []
    for left, right in itertools.product(range(target_size), repeat=2):
        count = sum(mapping[left_point] == left and mapping[right_point] == right
                    for mapping in itertools.product(range(target_size), repeat=apex_size))
        counts.append(count)
    return {"mediator_counts": counts, "passes_finite_test": all(count == 1 for count in counts)}


def idle_mixture_sharpe(mu, sigma, deployment):
    """Exact equal-period population ratios for R=I*X, I~Bernoulli(p) independent X.

    X has mean mu and variance sigma^2; idle excess returns are exactly zero.
    No annualization, autocorrelation, financing, or portfolio inference is claimed.
    """
    if not (math.isfinite(mu) and math.isfinite(sigma) and sigma > 0 and 0 < deployment <= 1):
        raise ValueError("finite mean, positive sigma and deployment in (0,1] required")
    mean = deployment * mu
    variance = deployment * sigma**2 + deployment * (1 - deployment) * mu**2
    calendar = mean / math.sqrt(variance)
    return {"calendar_mean": mean, "calendar_variance": variance,
            "calendar_sharpe": calendar, "active_sharpe": mu / sigma,
            "sqrt_deployment_approximation": calendar / math.sqrt(deployment)}


def nonlinear_delta_probe(n=20000, seed=8101):
    """Known Gaussian moments alongside independent Monte Carlo estimates."""
    rng = random.Random(seed)
    xs = [rng.gauss(0, 1) for _ in range(n)]
    squared, exponentiated = [x*x for x in xs], [math.exp(x) for x in xs]
    return {"seed": seed, "n": n,
            "square": {"delta_mean": 0, "delta_variance": 0, "exact_mean": 1,
                       "exact_variance": 2, "sample_mean": statistics.mean(squared),
                       "sample_variance": statistics.variance(squared)},
            "exp": {"delta_mean": 1, "delta_variance": 1, "exact_mean": math.exp(.5),
                    "exact_variance": math.exp(2)-math.e,
                    "sample_mean": statistics.mean(exponentiated),
                    "sample_variance": statistics.variance(exponentiated)}}


def causal_prefix_probe():
    """Retain the hindsight counterexample alongside the causal API regression."""
    from surprise import causal_surprise_series, filter_smooth, surprise_series
    args = ((0., 2.), .6, [[.95, .05], [.05, .95]], [.5, .5])
    prefix = [0., 0., 1.]
    extended = prefix + [2., 2., 2.]
    filt, smooth = filter_smooth(prefix, *args)
    filt2, smooth2 = filter_smooth(extended, *args)
    causal = causal_surprise_series(prefix, *args)
    causal2 = causal_surprise_series(extended, *args)
    return {"filter_prefix": filt[-1], "filter_extended_same_time": filt2[len(prefix)-1],
            "smooth_prefix": smooth[-1], "smooth_extended_same_time": smooth2[len(prefix)-1],
            "kl_prefix": surprise_series(prefix, *args)[-1],
            "kl_extended_same_time": surprise_series(extended, *args)[len(prefix)-1],
            "causal_prefix_invariant": causal == causal2[:len(prefix)],
            "causal_last_prefix": causal[-1], "causal_extended_same_time": causal2[len(prefix)-1],
            "parameter_fit_contract": "All model parameters fixed before scoring; future-fitted parameters would leak."}


def evidence_probe():
    """Current-code regression plus limits of caller-declared provenance tags."""
    from estimand import EstimandIdentity, Leg, Quantity, Measurement, colimit, derived_trust, update
    leg = Leg("edge", "prediction", 2, 1, frozenset({"same-data"}))
    once = colimit("hypothesis", [leg])
    replay = colimit("hypothesis", [leg] * 20)
    relabeled = Leg("copy", "prediction", 2, 1, frozenset({"renamed-data"}))
    mislabeled = colimit("hypothesis", [leg, relabeled])
    target = EstimandIdentity("response", "synthetic generator", "one step", (), "fixture", "raw", "mean")
    prior = Quantity(0, 1, "fixture", identity=target)
    measurement = Measurement(10, 1, 100, "fixture", provenance=frozenset({"observation"}), robust=False,
                              identity=target)
    posterior = update(prior, measurement)
    null = Leg("underpowered-null", "necessity", 0, 100, frozenset({"null-data"}), equivalence_margin=.1)
    return {"duplicate_unchanged": once == replay, "multiplicity_once": once.multiplicity,
            "multiplicity_after_relabeling_same_data": mislabeled.multiplicity,
            "edge_weight_once": once.edge_weight, "edge_weight_after_relabeling": mislabeled.edge_weight,
            "conflicting_normal_update": {"prior_sigma": prior.sigma, "posterior_sigma": posterior.sigma,
                                          "posterior_mean": posterior.value,
                                          "signed_snr_score": derived_trust(posterior),
                                          "standardized_conflict": 10 / math.sqrt(2)},
            "underpowered_null": {"historical_nonsignificance_binds": True,
                                  "current_equivalence_binds": null.binds(), "estimate": 0, "stderr": 100,
                                  "ninety_percent_interval": [-164.485362695, 164.485362695],
                                  "equivalence_margin": .1, "establishes_equivalence": False},
            "snr_one": {"tanh_score": math.tanh(1), "probability_if_normal_posterior":
                        .5 * (1 + math.erf(1 / math.sqrt(2))),
                        "rescaled_tanh_probability": (1 + math.tanh(1)) / 2}}


def conditional_signal_probe(n=4000, seed=8201):
    """Train-only selection, frozen rule, separately seeded held-out XOR interaction.

    x,z are independent symmetric signs, y=x*z+noise. E[y|x]=E[y|z]=0
    exactly, while E[x*z*y]=1. This tests discoverability, not a market claim.
    """
    def sample(rng):
        x, z = rng.choice((-1, 1)), rng.choice((-1, 1))
        return x, z, x*z + rng.gauss(0, .5)
    train_rng, test_rng = random.Random(seed), random.Random(seed + 1)
    train = [sample(train_rng) for _ in range(n)]
    held = [sample(test_rng) for _ in range(n)]
    transforms = (lambda x,z:x, lambda x,z:z, lambda x,z:x*z)
    scores = [statistics.mean(fn(x,z)*y for x,z,y in train) for fn in transforms]
    selected = max(range(3), key=lambda j: abs(scores[j]))
    direction = 1 if scores[selected] >= 0 else -1
    vals = [direction*transforms[selected](x,z)*y for x,z,y in held]
    shuffled = [y for x,z,y in held]
    random.Random(seed + 2).shuffle(shuffled)
    null_vals = [direction*transforms[selected](x,z)*y for (x,z,_),y in zip(held,shuffled)]
    return {"seed": seed, "heldout_seed": seed+1, "n_train": n, "n_heldout": n,
            "candidate_features": ["x", "z", "x*z"], "training_scores": scores,
            "selected_before_holdout": ["x", "z", "x*z"][selected],
            "exact_marginal_effects": [0, 0], "exact_interaction_effect": 1,
            "heldout_marginal_effects": [statistics.mean(fn(x,z)*y for x,z,y in held)
                                          for fn in transforms[:2]],
            "heldout_interaction_mean": statistics.mean(vals),
            "heldout_standard_error": statistics.stdev(vals)/math.sqrt(n),
            "heldout_permuted_control_mean": statistics.mean(null_vals)}


def adaptation_probe():
    """Matched deterministic jump/outlier cases; no universal winning heuristic."""
    from regime_estimand import kalman
    reports = {}
    for scenario in ("persistent_jump", "single_outlier"):
        truth = [0.]*40 + [1.]*40 if scenario == "persistent_jump" else [0.]*80
        obs = list(truth)
        if scenario == "single_outlier":
            obs[40] = 10
        scores = {}
        for mode, options in (("fixed", {}), ("adaptive", {"adaptive": True}), ("robust", {"robust": True})):
            estimates, variances, _ = kalman(obs, R=.04, q_base=.001, **options)
            scores[mode] = {
                "first_response": estimates[40],
                "mse_after_change": statistics.mean((estimates[t]-truth[t])**2 for t in range(40,50)),
                "mae_after_change": statistics.mean(abs(estimates[t]-truth[t]) for t in range(40,50)),
                "reported_variance_at_change": variances[40]}
        reports[scenario] = scores
    reports["historical_demo_noise_parameter_mismatch"] = {"generated_sd": .15,
        "actual_variance": .15**2, "filter_R_argument": .15}
    reports["current_variance_contract"] = {"generated_sd": .15, "filter_R_argument": .15**2,
        "first_observation_used_once": kalman([10], R=4, q_base=0) == ([10.], [4.], [None]),
        "initial_innovation": None, "reported_covariance_is_calibrated_by_this_probe": False}
    return reports


def learning_failure_probe():
    """Retained-negative regression plus historical calibration counterexamples."""
    from grok import Grokker, CORE, KILLER
    positive, negative = CORE, CORE | {KILLER}
    outcomes = []
    for stream in ([(negative,False),(positive,True)], [(positive,True),(negative,False)]):
        learner = Grokker()
        for features,label in stream:
            learner.learn(features,label)
        outcomes.append({"required": sorted(learner.R), "forbidden": sorted(learner.K),
                         "predicts_negative_as_true": learner.predict(negative)})
    return {"same_training_set_different_orders": outcomes,
            "historical_order_dependent_predictions": [True, False],
            "current_order_invariant": outcomes[0] == outcomes[1],
            "adversely_calibrated_abstention": {"overall_error": .2,
                "accepted_coverage": .2, "accepted_error": 1,
                "construction": "20 wrong examples confidence .95; 80 correct confidence .30; accept >=.5"},
            "disagreement_is_not_truth": [
                {"truth": 0, "cheap": 0, "heavy": 10, "divergence": 10,
                 "cheap_error": 0, "heavy_error": 10},
                {"truth": 0, "cheap": 10, "heavy": 10, "divergence": 0,
                 "cheap_error": 10, "heavy_error": 10}]}


def run_battery(seed=8101, samples=20000):
    if type(samples) is not int or samples < 100:
        raise ValueError("at least 100 Monte Carlo samples required")
    noise = expected_information_gain([.5,.5], [[.001]*1000, [.001]*1000])
    informative = expected_information_gain([.5,.5], [[1,0],[0,1]])
    cases = [
        ("stability", "exact_algebra", stability_counterexamples()),
        ("estimand_topology", "exact_identity_with_roundoff_check", topology_counterexample()),
        ("categorical_universality", "finite_exhaustive_enumeration", {
            "collapsed_singleton": coproduct_factorization(1,0,0),
            "correct_two_point_apex": coproduct_factorization(2,0,1),
            "extra_unconstrained_point": coproduct_factorization(3,0,1)}),
        ("idle_mixture_sharpe", "exact_population_moments", idle_mixture_sharpe(1,1,.1)),
        ("nonlinear_delta", "exact_moments_plus_seeded_monte_carlo", nonlinear_delta_probe(samples,seed)),
        ("free_energy_and_acquisition", "exact_finite_probabilities", {
            "posterior_to_prior_kl": bernoulli_kl(.9,.5), "reverse_kl": bernoulli_kl(.5,.9),
            "uninformative_noisy_experiment": noise, "state_revealing_experiment": informative,
            "fixed_model_elbo": {"log_evidence": -2, "variational_kl_gap": .5, "elbo": -2.5}}),
        ("smoothing_causality", "deterministic_current_code_probe", causal_prefix_probe()),
        ("evidence_and_confidence", "deterministic_current_code_probe", evidence_probe()),
        ("dead_marginal_interaction", "exact_conditional_mean_plus_seeded_independent_holdout",
         conditional_signal_probe(max(1000,samples//5),seed+100)),
        ("nonstationarity", "deterministic_current_code_probe", adaptation_probe()),
        ("repertoire_and_abstention", "deterministic_current_code_probe", learning_failure_probe()),
        ("holdout_reuse", "exact_independent_null_probability", {
            "alpha": .05, "independent_null_queries": 100,
            "probability_at_least_one_false_positive": 1-.95**100,
            "bound": "This is a nonadaptive special case; arbitrary adaptive reuse needs its own controls."}),
    ]
    return {"schema": "nl2proof.research-counterexamples.v1", "seed": seed,
            "status": "synthetic_research_not_oracle_evidence",
            "writes_beliefs": False, "cases": [{"id":name,"evidence_kind":kind,"result":value}
                                                   for name,kind,value in cases]}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--seed", type=int, default=8101)
    parser.add_argument("--samples", type=int, default=20000)
    parser.add_argument("--out", type=Path, help="optional standalone JSON report")
    args = parser.parse_args()
    rendered = json.dumps(run_battery(args.seed,args.samples), indent=2, allow_nan=False) + "\n"
    if args.out:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(rendered, encoding="utf-8")
    else:
        print(rendered, end="")


if __name__ == "__main__":
    main()
