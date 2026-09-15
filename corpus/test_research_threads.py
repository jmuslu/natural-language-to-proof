"""The research battery must expose its counterexamples reproducibly.

Passing these tests validates the experiments and witnesses. It does not mean the
prototype claims they challenge are true or that a financial signal is validated.
"""
import json
import math
import unittest

from research_threads import (adaptation_probe, bernoulli_kl, causal_prefix_probe,
    conditional_signal_probe, coproduct_factorization, evidence_probe,
    expected_information_gain, idle_mixture_sharpe, learning_failure_probe,
    nonlinear_delta_probe, run_battery, stability_counterexamples, topology_counterexample)


class ExactCounterexampleTests(unittest.TestCase):
    def test_asymptotic_stability_is_not_finite_step_contraction_or_truth(self):
        result = stability_counterexamples()
        self.assertLess(result["spectral_radius"], 1)
        self.assertGreater(result["one_step_e2_norm_gain"], 10)
        self.assertGreater(result["covariance_trace_after"], result["covariance_trace_before"])
        self.assertGreater(result["stable_noisy_scalar"]["variance_after"], 100)
        self.assertLess(result["biased_contraction"]["jacobian"], 1)
        self.assertNotEqual(result["biased_contraction"]["output_mean"], result["biased_contraction"]["target"])
        self.assertEqual(result["exact_unit_scaling"]["input_snr"], result["exact_unit_scaling"]["output_snr"])

    def test_conjugate_flows_have_different_observable_relaxation_times(self):
        result = topology_counterexample()
        self.assertLess(result["identity_max_roundoff"], 1e-12)
        self.assertNotEqual(*result["relaxation_times"])

    def test_colimit_requires_both_existence_and_uniqueness_of_factorization(self):
        self.assertEqual(coproduct_factorization(1,0,0)["mediator_counts"], [1,0,0,1])
        self.assertTrue(coproduct_factorization(2,0,1)["passes_finite_test"])
        self.assertEqual(coproduct_factorization(3,0,1)["mediator_counts"], [2,2,2,2])

    def test_sharpe_idle_mixture_moments_disprove_exact_square_root_coercion(self):
        result = idle_mixture_sharpe(1,1,.1)
        self.assertAlmostEqual(result["calendar_mean"], .1)
        self.assertAlmostEqual(result["calendar_variance"], .19)
        self.assertEqual(result["active_sharpe"], 1)
        self.assertAlmostEqual(result["sqrt_deployment_approximation"], 1/math.sqrt(1.9))
        self.assertGreater(result["active_sharpe"]-result["sqrt_deployment_approximation"], .27)
        # The approximation improves in the stated small-mean regime.
        small = idle_mixture_sharpe(.001,1,.1)
        self.assertLess(abs(small["active_sharpe"]-small["sqrt_deployment_approximation"]), 1e-8)

    def test_kl_direction_and_noise_surprise_differ_from_information_gain(self):
        self.assertNotAlmostEqual(bernoulli_kl(.9,.5), bernoulli_kl(.5,.9))
        noisy = expected_information_gain([.5,.5], [[.25]*4,[.25]*4])
        informative = expected_information_gain([.5,.5], [[1,0],[0,1]])
        self.assertAlmostEqual(noisy["expected_information_gain"], 0)
        self.assertGreater(noisy["predictive_entropy"], informative["predictive_entropy"])
        self.assertAlmostEqual(informative["expected_information_gain"], math.log(2))

    def test_invalid_experiment_probabilities_are_rejected(self):
        for prior,likelihood in [([],[]), ([.5,.5],[[1],[.5,.5]]),
                                 ([.6,.6],[[1,0],[0,1]]), ([.5,.5],[[float("nan"),0],[0,1]])]:
            with self.assertRaises(ValueError):
                expected_information_gain(prior,likelihood)


class PrototypeProbeTests(unittest.TestCase):
    def test_future_suffix_changes_smoothing_but_not_filtering(self):
        result = causal_prefix_probe()
        self.assertEqual(result["filter_prefix"], result["filter_extended_same_time"])
        self.assertAlmostEqual(result["kl_prefix"], 0)
        self.assertGreater(result["kl_extended_same_time"], .4)
        self.assertTrue(result["causal_prefix_invariant"])
        self.assertEqual(result["causal_last_prefix"], result["causal_extended_same_time"])

    def test_provenance_regression_and_remaining_calibration_limits(self):
        result = evidence_probe()
        self.assertTrue(result["duplicate_unchanged"])
        self.assertEqual(result["multiplicity_once"], 1)
        self.assertEqual(result["multiplicity_after_relabeling_same_data"], 2)
        conflict = result["conflicting_normal_update"]
        self.assertLess(conflict["posterior_sigma"], conflict["prior_sigma"])
        self.assertGreater(conflict["signed_snr_score"], .999)
        self.assertTrue(result["underpowered_null"]["historical_nonsignificance_binds"])
        self.assertFalse(result["underpowered_null"]["current_equivalence_binds"])
        self.assertFalse(result["underpowered_null"]["establishes_equivalence"])

    def test_adaptive_filter_wins_on_jump_but_loses_on_outlier(self):
        result = adaptation_probe()
        jump, outlier = result["persistent_jump"], result["single_outlier"]
        self.assertLess(jump["adaptive"]["mse_after_change"], jump["fixed"]["mse_after_change"])
        self.assertGreater(outlier["adaptive"]["mse_after_change"], outlier["fixed"]["mse_after_change"])
        self.assertLess(outlier["robust"]["mse_after_change"], outlier["fixed"]["mse_after_change"])
        self.assertGreater(jump["robust"]["mse_after_change"], jump["fixed"]["mse_after_change"])
        mismatch = result["historical_demo_noise_parameter_mismatch"]
        self.assertNotEqual(mismatch["actual_variance"], mismatch["filter_R_argument"])
        self.assertEqual(result["current_variance_contract"]["filter_R_argument"], .15**2)
        self.assertTrue(result["current_variance_contract"]["first_observation_used_once"])

    def test_order_dependence_and_adverse_abstention_are_exposed(self):
        result = learning_failure_probe()
        first,second = result["same_training_set_different_orders"]
        self.assertFalse(first["predicts_negative_as_true"])
        self.assertFalse(second["predicts_negative_as_true"])
        self.assertTrue(result["current_order_invariant"])
        self.assertEqual(result["historical_order_dependent_predictions"], [True, False])
        abstention = result["adversely_calibrated_abstention"]
        self.assertGreater(abstention["accepted_error"], abstention["overall_error"])
        self.assertEqual(result["disagreement_is_not_truth"][1]["divergence"], 0)


class MeasuredExperimentTests(unittest.TestCase):
    def test_nonlinear_gaussian_moments_and_monte_carlo_agree(self):
        result = nonlinear_delta_probe()
        square, exp = result["square"], result["exp"]
        self.assertEqual(square["exact_mean"], 1)
        self.assertEqual(square["exact_variance"], 2)
        self.assertEqual(square["delta_variance"], 0)
        self.assertLess(abs(square["sample_mean"]-square["exact_mean"]), .1)
        self.assertLess(abs(square["sample_variance"]-square["exact_variance"]), .3)
        self.assertLess(abs(exp["sample_mean"]-exp["exact_mean"]), .15)
        self.assertLess(abs(exp["sample_variance"]-exp["exact_variance"]), 2)

    def test_frozen_interaction_rule_survives_independent_holdout(self):
        result = conditional_signal_probe()
        self.assertNotEqual(result["seed"], result["heldout_seed"])
        self.assertEqual(result["selected_before_holdout"], "x*z")
        self.assertEqual(result["exact_marginal_effects"], [0,0])
        self.assertLess(max(map(abs,result["heldout_marginal_effects"])), .1)
        self.assertGreater(result["heldout_interaction_mean"], .95)
        self.assertLess(abs(result["heldout_permuted_control_mean"]), .1)

    def test_report_is_reproducible_and_never_an_oracle_receipt(self):
        first,second = run_battery(samples=1000),run_battery(samples=1000)
        self.assertEqual(first,second)
        self.assertEqual(first["status"], "synthetic_research_not_oracle_evidence")
        self.assertFalse(first["writes_beliefs"])
        self.assertEqual(len(first["cases"]), 12)
        self.assertNotIn("oracle_receipt", first)
        json.dumps(first,allow_nan=False)


if __name__ == "__main__":
    unittest.main()
