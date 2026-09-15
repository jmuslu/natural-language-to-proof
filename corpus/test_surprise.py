"""Causality, exact HMM enumeration, and numerical failure regressions."""
import itertools
import math
import unittest

from surprise import (causal_surprise_series, filter_smooth, kl,
                      retrospective_surprise_series, surprise_series)


ARGS = ((0., 2.), .6, [[.95, .05], [.05, .95]], [.5, .5])


class SurpriseTests(unittest.TestCase):
    def test_every_causal_prefix_unchanged_by_future_suffix(self):
        prefix = [0., 0., 1.]
        expected = causal_surprise_series(prefix, *ARGS)
        for suffix in ([2., 2., 2.], [-5., 10.], [100., -100.]):
            self.assertEqual(expected, causal_surprise_series(prefix + suffix, *ARGS)[:len(prefix)])
        filtered, _ = filter_smooth(prefix, *ARGS)
        self.assertEqual(filtered, [row["posterior"] for row in expected])

    def test_legacy_retrospective_api_remains_future_sensitive(self):
        prefix = [0., 0., 1.]
        before = surprise_series(prefix, *ARGS)
        extended = prefix + [2., 2., 2.]
        after = surprise_series(extended, *ARGS)
        self.assertEqual(after, retrospective_surprise_series(extended, *ARGS))
        self.assertAlmostEqual(before[-1], 0)
        self.assertGreater(after[len(prefix)-1], .4)

    def test_hmm_filter_and_smoother_match_exhaustive_state_path_probabilities(self):
        obs = [0., .4, 1.]
        mus, sd, trans, pi = ARGS

        def enumerated(data, at):
            totals = [0., 0.]
            for path in itertools.product(range(2), repeat=len(data)):
                weight = pi[path[0]]
                for t, value in enumerate(data):
                    if t:
                        weight *= trans[path[t-1]][path[t]]
                    weight *= math.exp(-.5*((value-mus[path[t]])/sd)**2) / (sd*math.sqrt(2*math.pi))
                totals[path[at]] += weight
            return [value / sum(totals) for value in totals]

        filtered, smoothed = filter_smooth(obs, *ARGS)
        for t in range(len(obs)):
            for actual, expected in zip(filtered[t], enumerated(obs[:t+1], t)):
                self.assertAlmostEqual(actual, expected, places=12)
            for actual, expected in zip(smoothed[t], enumerated(obs, t)):
                self.assertAlmostEqual(actual, expected, places=12)

    def test_causal_information_gain_matches_definition_and_density(self):
        trace = causal_surprise_series([0.], *ARGS)[0]
        self.assertAlmostEqual(trace["information_gain_kl"], kl(trace["posterior"], trace["predictive"]))
        mus, sd, _, pi = ARGS
        density = sum(p*math.exp(-.5*(mu/sd)**2)/(sd*math.sqrt(2*math.pi)) for p,mu in zip(pi,mus))
        self.assertAlmostEqual(trace["predictive_surprisal"], -math.log(density))

    def test_noise_surprise_does_not_imply_state_information(self):
        trace = causal_surprise_series([10.], [0., 0.], 1., [[1., 0.], [0., 1.]], [.5, .5])[0]
        self.assertGreater(trace["predictive_surprisal"], 50)
        self.assertAlmostEqual(trace["information_gain_kl"], 0)
        narrow = causal_surprise_series([0.], [0.], .01, [[1.]], [1.])[0]
        self.assertLess(narrow["predictive_surprisal"], 0)

    def test_extreme_observations_do_not_collapse_all_probabilities(self):
        filtered, smoothed = filter_smooth([100., -100., 100.], *ARGS)
        for row in filtered + smoothed:
            self.assertAlmostEqual(sum(row), 1, places=10)
            self.assertTrue(all(math.isfinite(value) and value >= 0 for value in row))
        self.assertGreater(filtered[0][1], .999)
        self.assertGreater(filtered[1][0], .999)

    def test_zero_transition_support_and_kl_semantics(self):
        trace = causal_surprise_series([0., 2.], [0., 2.], 1., [[1., 0.], [0., 1.]], [1., 0.])
        self.assertEqual([row["posterior"] for row in trace], [[1., 0.], [1., 0.]])
        self.assertEqual(kl([1., 0.], [0., 1.]), math.inf)
        self.assertEqual(kl([1., 0.], [1., 0.]), 0)

    def test_empty_input_has_defined_result(self):
        self.assertEqual(filter_smooth([], *ARGS), ([], []))
        self.assertEqual(causal_surprise_series([], *ARGS), [])
        self.assertEqual(surprise_series([], *ARGS), [])

    def test_malformed_or_nonfinite_model_rejected(self):
        for args in (([], .6, [], []), ([0, 2], 0, ARGS[2], ARGS[3]),
                     ([0, 2], -1, ARGS[2], ARGS[3]), ([0, 2], float("nan"), ARGS[2], ARGS[3]),
                     ([0, 2], .6, [[1, 0]], ARGS[3]),
                     ([0, 2], .6, [[.9, .2], [.1, .9]], ARGS[3]),
                     ([0, 2], .6, [[1, 0], [0, 1]], [1, -0.1]),
                     ([0, 2], .6, ARGS[2], [1]),
                     ([0, float("inf")], .6, ARGS[2], ARGS[3])):
            with self.subTest(args=args), self.assertRaises(ValueError):
                filter_smooth([0], *args)
        for obs in ([float("nan")], [True], [1e308], [10**1000]):
            with self.subTest(obs=str(obs)[:30]), self.assertRaises(ValueError):
                causal_surprise_series(obs, *ARGS)
        with self.assertRaises(ValueError):
            kl([1], [.5, .5])


if __name__ == "__main__":
    unittest.main()
