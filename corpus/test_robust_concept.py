import itertools
import unittest

from abstain import fit_threshold, risk_coverage
from robust_concept import Conjunction, train_candidates, select_candidate, prediction_confidence


class RobustConceptTests(unittest.TestCase):
    def world(self):
        return [(frozenset(f for f, flag in zip(("a", "b", "c"), flags) if flag), flags[0] and not flags[1])
                for flags in itertools.product((False, True), repeat=3)]

    def test_recovers_signed_conjunction_despite_symmetric_training_errors(self):
        clean = self.world()
        noisy = [(features, label if repetition else not label) for repetition in range(5) for features, label in clean]
        candidates, resources = train_candidates(noisy, ("a", "b", "c"), max_required=1)
        model, _ = select_candidate(candidates, clean)
        self.assertEqual((model.required, model.forbidden), (("a",), ("b",)))
        self.assertTrue(all(model.predict(features) == label for features, label in clean))
        self.assertEqual(resources["hypotheses_evaluated"], 14)

    def test_training_order_and_feature_order_do_not_change_fit(self):
        rows = self.world()
        first, _ = train_candidates(rows, ("a", "b", "c"), max_required=1)
        second, _ = train_candidates(list(reversed(rows)), ("c", "a", "b"), max_required=1)
        self.assertEqual(first, second)

    def test_all_negative_training_keeps_constant_false(self):
        rows = [(features, False) for features, _ in self.world()]
        candidates, _ = train_candidates(rows, ("a", "b", "c"), max_required=1)
        model, _ = select_candidate(candidates, rows)
        self.assertTrue(model.constant_false)

    def test_calibration_not_training_error_selects_complexity(self):
        candidates = [{"model": Conjunction(("a",)), "training_errors": 0},
                      {"model": Conjunction(constant_false=True), "training_errors": 10}]
        model, scores = select_candidate(candidates, [(frozenset({"a"}), False)]*5)
        self.assertTrue(model.constant_false)
        self.assertEqual(scores[1]["calibration_errors"], 0)

    def test_hypothesis_resource_cap_rejects_before_search(self):
        with self.assertRaisesRegex(ValueError, "hypothesis cap"):
            train_candidates([(frozenset({"a"}), True)], ("a", "b", "c"), max_hypotheses=1)

    def test_unknown_training_features_and_nonboolean_labels_rejected(self):
        with self.assertRaises(ValueError):
            train_candidates([(frozenset({"z"}), True)], ("a",))
        with self.assertRaises(ValueError):
            train_candidates([(frozenset({"a"}), "true")], ("a",))

    def test_xor_remains_outside_one_signed_conjunction(self):
        rows = [(features, ("a" in features) != ("b" in features)) for features, _ in self.world()]
        candidates, _ = train_candidates(rows, ("a", "b", "c"), max_required=2)
        self.assertGreater(min(candidate["training_errors"] for candidate in candidates), 0)

    def test_irreducible_outcome_errors_do_not_gain_risk_certificate(self):
        model = Conjunction(("a",))
        calibration = [(frozenset({"a"}), i % 4 != 0) for i in range(2000)]
        confidence = prediction_confidence(model, calibration)
        self.assertEqual(confidence[True], .75)
        rows = [(confidence[True], True, i % 4 != 0) for i in range(2000)]
        threshold = fit_threshold(rows)
        self.assertIsNone(threshold.value)
        self.assertEqual(risk_coverage(rows, threshold)["coverage"], 0.)


if __name__ == "__main__":
    unittest.main()
