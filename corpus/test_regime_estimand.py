"""State initialization, causal updates, and matched jump/outlier tradeoffs."""
import math
import unittest

from regime_estimand import kalman


class RegimeEstimandTests(unittest.TestCase):
    def test_first_observation_is_used_once_with_flat_prior(self):
        self.assertEqual(kalman([10], R=4, q_base=0), ([10.], [4.], [None]))
        estimates, variances, surprises = kalman([10, 10], R=4, q_base=0)
        self.assertEqual(estimates, [10, 10])
        self.assertEqual(variances, [4, 2])
        self.assertEqual(surprises, [None, 0])

    def test_independent_prior_updates_once_by_exact_gaussian_product(self):
        estimates, variances, surprises = kalman([10], R=4, q_base=0,
                                                 initial_mean=0, initial_variance=4)
        self.assertEqual(estimates, [5])
        self.assertEqual(variances, [2])
        self.assertEqual(surprises, [12.5])

    def test_fixed_state_filter_matches_batch_gaussian_sample_mean(self):
        obs = [3., -2., 4., 1.]
        estimates, variances, _ = kalman(obs, R=9, q_base=0)
        for t in range(len(obs)):
            self.assertAlmostEqual(estimates[t], sum(obs[:t+1])/(t+1))
            self.assertAlmostEqual(variances[t], 9/(t+1))

    def test_all_modes_are_prefix_invariant(self):
        prefix = [0., .1, 5.]
        for options in ({}, {"adaptive": True}, {"robust": True}, {"adaptive": True, "robust": True}):
            expected = kalman(prefix, R=.04, q_base=.001, **options)
            extended = kalman(prefix + [2., -10., 0.], R=.04, q_base=.001, **options)
            self.assertEqual(expected, tuple(values[:len(prefix)] for values in extended))

    def test_jump_and_outlier_demand_opposite_responses(self):
        jump_truth = [0.] * 40 + [1.] * 40
        outlier_truth = [0.] * 80
        outlier_obs = list(outlier_truth)
        outlier_obs[40] = 10.
        errors = {}
        for scenario, obs, truth in (("jump", jump_truth, jump_truth), ("outlier", outlier_obs, outlier_truth)):
            errors[scenario] = {}
            for mode, options in (("fixed", {}), ("adaptive", {"adaptive": True}), ("robust", {"robust": True})):
                estimates, variances, _ = kalman(obs, R=.04, q_base=.001, **options)
                errors[scenario][mode] = sum((estimates[t]-truth[t])**2 for t in range(40,50))/10
                self.assertTrue(all(math.isfinite(p) and p >= 0 for p in variances))
        self.assertLess(errors["jump"]["adaptive"], errors["jump"]["fixed"])
        self.assertGreater(errors["jump"]["robust"], errors["jump"]["fixed"])
        self.assertLess(errors["outlier"]["robust"], errors["outlier"]["fixed"])
        self.assertGreater(errors["outlier"]["adaptive"], errors["outlier"]["fixed"])

    def test_robust_mode_matches_baseline_for_small_innovations(self):
        obs = [0., .01, .02, -.01]
        self.assertEqual(kalman(obs, R=.04, q_base=.001), kalman(obs, R=.04, q_base=.001, robust=True))

    def test_empty_and_deterministic_independent_prior(self):
        self.assertEqual(kalman([], R=1, q_base=0), ([], [], []))
        self.assertEqual(kalman([100], R=1, q_base=0, initial_mean=2, initial_variance=0),
                         ([2], [0], [9604]))

    def test_invalid_variances_parameters_and_observations_rejected(self):
        cases = ({"R": 0}, {"R": -1}, {"R": True}, {"R": float("nan")},
                 {"q_base": -1}, {"q_base": float("inf")}, {"adaptive": 1}, {"robust": "yes"},
                 {"beta": -1}, {"thresh": 0}, {"outlier_z": 0},
                 {"initial_mean": 0}, {"initial_variance": 1},
                 {"initial_mean": 0, "initial_variance": -1},
                 {"initial_mean": float("nan"), "initial_variance": 1})
        for changes in cases:
            options = {"R": 1, "q_base": 0, **changes}
            with self.subTest(options=options), self.assertRaises(ValueError):
                kalman([1, 2], **options)
        for obs in ([float("inf")], [True], [10**1000], [0, 1e308]):
            with self.subTest(obs=str(obs)[:30]), self.assertRaises(ValueError):
                kalman(obs, R=1, q_base=0)


if __name__ == "__main__":
    unittest.main()
