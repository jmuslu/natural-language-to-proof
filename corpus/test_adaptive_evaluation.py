import itertools
import math
import random
import unittest

from abstain import fit_threshold, labeled_stream, risk_coverage
from adaptive_evaluation import simulated_outcomes, score_policy
from grok import CORE, KILLER, Grokker, is_real
from metalearn import ResidualLearner
from selector import select_ground


class ConceptTests(unittest.TestCase):
    def test_negative_before_positive_is_retained(self):
        learner = Grokker()
        learner.learn(CORE | {KILLER}, False)
        learner.learn(CORE, True)
        self.assertFalse(learner.predict(CORE | {KILLER}))
        self.assertEqual(learner.K, frozenset({KILLER}))
        self.assertTrue(learner.consistent)

    def test_all_training_orders_and_duplicate_observations_agree(self):
        examples = [(CORE | {"extra"}, True), (CORE, True), (CORE | {KILLER}, False)]
        states = []
        for order in itertools.permutations(examples):
            learner = Grokker()
            for f, y in order + order:
                learner.learn(f, y)
            states.append((learner.R, learner.K, learner.predict(CORE | {KILLER})))
        self.assertEqual(len(set(states)), 1)

    def test_no_positive_evidence_does_not_predict_true(self):
        learner = Grokker()
        self.assertFalse(learner.predict(frozenset()))
        learner.learn(CORE, False)
        self.assertFalse(learner.predict(CORE))

    def test_contradictory_labels_are_exposed(self):
        learner = Grokker()
        learner.learn(CORE, True); learner.learn(CORE, False)
        self.assertFalse(learner.consistent)

    def test_forbidden_feature_cannot_contradict_a_positive(self):
        learner = Grokker()
        for f, y in ((CORE | {"sometimes"}, True), (CORE, True), (CORE | {"sometimes", KILLER}, False)):
            learner.learn(f, y)
        self.assertEqual(learner.K, frozenset({KILLER}))
        self.assertTrue(learner.predict(CORE | {"sometimes"}))


class AbstentionTests(unittest.TestCase):
    def test_same_quality_contains_correct_and_corrupt_realizations(self):
        rows = labeled_stream(random.Random(52), 4000)
        grouped = {}
        for features, label, score in rows:
            grouped.setdefault(score, set()).add(label == is_real(features))
        self.assertTrue(all(values == {True, False} for values in grouped.values()))

    def test_calibration_selects_from_prespecified_thresholds(self):
        rows = [(.95, True, i % 50 != 0) for i in range(1000)]
        rows += [(.55, True, i % 2 == 0) for i in range(1000)]
        policy = fit_threshold(rows)
        report = risk_coverage(rows, policy)
        self.assertEqual((report["accepted"], report["errors"]), (1000, 20))
        self.assertLessEqual(next(r["risk_upper"] for r in policy.calibration if r["threshold"] == policy.value), .1)

    def test_empty_or_unsafe_calibration_abstains(self):
        for rows in ([], [(.99, True, False)]*1000):
            policy = fit_threshold(rows)
            self.assertIsNone(policy.value)
            report = risk_coverage([(.99, True, True)], policy)
            self.assertEqual(report["accepted"], 0)
            self.assertIsNone(report["risk"])

    def test_frozen_threshold_fails_under_reversed_quality(self):
        policy = fit_threshold([(.95, True, True)]*1000)
        old = policy.to_dict()
        report = risk_coverage([(.95, True, False)]*100 + [(.3, True, True)]*100, policy)
        self.assertEqual((report["coverage"], report["risk"]), (.5, 1.))
        self.assertEqual(policy.to_dict(), old)

    def test_invalid_probability_and_truth_are_rejected(self):
        for value in (float("nan"), float("inf"), -.1, 1.1, True):
            with self.assertRaises(ValueError):
                fit_threshold([(value, True, True)])
        with self.assertRaises(ValueError):
            fit_threshold([(.9, True, "true")])


class SelectionTests(unittest.TestCase):
    def test_review_margin_never_relaxes_acceptance(self):
        legs = [{"kind": "prediction", "t": 3., "dir": 1},
                {"kind": "prediction", "t": 1.4, "dir": 1}]
        for margin in (0., .1, .6, 100.):
            result = select_ground(legs, margin=margin)
            self.assertEqual(result["machinery"], "strict")
            self.assertFalse(result["accepted"])
            self.assertFalse(result["grounded"])
        self.assertTrue(select_ground(legs)["requires_review"])

    def test_empty_or_null_only_screen_does_not_accept(self):
        for legs in ([], [{"kind": "necessity", "t": 0., "dir": 1}]):
            self.assertFalse(select_ground(legs)["accepted"])

    def test_signed_threshold_is_preserved(self):
        leg = {"kind": "prediction", "t": -2., "dir": -1}
        self.assertTrue(select_ground([leg])["accepted"])
        self.assertFalse(select_ground([leg], z=2.1)["accepted"])

    def test_heavy_wrong_produces_negative_gain(self):
        learner = ResidualLearner()
        for _ in range(10):
            learner.observe(500, 1.5, cheap_loss=0, heavy_loss=1)
        self.assertFalse(learner.escalates(500, 1.5))
        self.assertEqual(next(iter(learner.mean.values())), -1.)

    def test_shared_bias_has_zero_gain_but_nonzero_error(self):
        learner = ResidualLearner()
        for _ in range(10):
            learner.observe(50, 3., cheap_loss=1, heavy_loss=1)
        self.assertFalse(learner.escalates(50, 3.))
        row = {"n": 50, "z": 3., "truth": False, "cheap": True, "heavy": True, "regime": "shared_bias"}
        report = score_policy([row], learner.escalates)
        self.assertEqual(report["error_rate"], 1.)
        self.assertEqual(report["mean_loss"], 10.)

    def test_disagreement_alone_cannot_be_observed_as_loss(self):
        with self.assertRaises(TypeError):
            ResidualLearner().observe(20, 3., .9)
        with self.assertRaises(ValueError):
            ResidualLearner().observe(20, 3., cheap_loss=float("nan"), heavy_loss=0)

    def test_testing_does_not_update_frozen_learner(self):
        learner = ResidualLearner()
        learner.observe(5, 7., cheap_loss=1, heavy_loss=0)
        before = (dict(learner.mean), dict(learner.count), learner.t)
        score_policy(simulated_outcomes(93, 300), learner.escalates)
        self.assertEqual(before, (learner.mean, learner.count, learner.t))

    def test_generated_channels_include_heavy_errors_and_shared_bias(self):
        rows = simulated_outcomes(94, 4000)
        self.assertTrue(any(r["heavy"] != r["truth"] and r["cheap"] == r["truth"] for r in rows))
        self.assertTrue(any(r["cheap"] == r["heavy"] != r["truth"] for r in rows))
        self.assertNotEqual(rows, simulated_outcomes(95, 4000))
        self.assertEqual(rows, simulated_outcomes(94, 4000))


if __name__ == "__main__":
    unittest.main()
