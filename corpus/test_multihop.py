"""Qualitative support cannot manufacture dimensional effects or sample precision."""
from dataclasses import replace
import unittest

from estimand import EstimandIdentity, Quantity, Hop
from multihop import MethodClass, LegSlot, propose, belief_chain, explore_chain


class MultihopTests(unittest.TestCase):
    def setUp(self):
        self.target = EstimandIdentity("response", "synthetic generator", "one step", (), "units", "raw", "mean")
        self.method = MethodClass("method", "synthetic context", (
            LegSlot("edge", "prediction"), LegSlot("control", "necessity", equivalence_margin=.5)))
        self.candidate = propose(self.method, "candidate", "context", estimand_identity=self.target)
        self.base = Quantity(8, 2, "units", identity=self.target,
                             support={"n": 100, "provenance": {"numerical-observations"}})
        self.hops = [Hop(.5)]

    def check_legs(self):
        return self.candidate.measure({"edge": (3, 1, {"qualitative-check"}),
                                       "control": (0, .1, {"control-check"})})

    def test_coherent_qualitative_score_does_not_supply_numerical_value_or_sigma(self):
        self.assertTrue(self.check_legs().grounded)
        self.assertIsNone(belief_chain(self.candidate, None, self.hops)[0])
        with self.assertRaisesRegex(TypeError, "Quantity"):
            belief_chain(self.candidate, "sharpe", self.hops)
        out, note = belief_chain(self.candidate, self.base, self.hops)
        self.assertEqual((out.value, out.sigma), (4, 1))
        self.assertIn("external validation remains required", note)
        self.assertEqual(self.candidate.status, "coherent-unverified")

    def test_exploration_survives_without_grounding_or_numeric_output(self):
        self.assertIsNone(belief_chain(self.candidate, self.base, self.hops)[0])
        self.assertEqual(explore_chain(self.candidate, self.base, self.hops)[0].value, 4)
        self.assertIsNone(explore_chain(self.candidate, None, self.hops)[0])
        self.assertEqual(self.candidate.status, "proposed-not-grounded")

    def test_wrong_target_or_unmeasured_base_cannot_enter_conditional_chain(self):
        self.check_legs()
        with self.assertRaises(TypeError):
            belief_chain(self.candidate, replace(self.base, identity=replace(self.target, population="other")), self.hops)
        self.assertIsNone(belief_chain(self.candidate, replace(self.base, support={}), self.hops)[0])

    def test_realization_names_do_not_increase_trust_or_precision(self):
        self.check_legs()
        before = belief_chain(self.candidate, self.base, self.hops)[0]
        renamed = self.method
        for i in range(100):
            renamed = renamed.realized_by(f"renamed-{i}")
        self.assertIsNone(self.method.trust())
        self.assertIsNone(renamed.trust())
        self.assertEqual(before, belief_chain(self.candidate, self.base, self.hops)[0])
        self.assertEqual(renamed, renamed.realized_by("renamed-0"))

    def test_missing_measurements_and_missing_null_margin_remain_nonbinding(self):
        self.assertFalse(self.candidate.measure({"edge": (3, 1, {"data"})}).grounded)
        no_margin = MethodClass("legacy", "context", (LegSlot("edge", "prediction"), LegSlot("control", "necessity")))
        candidate = propose(no_margin, "legacy", "context")
        self.assertFalse(candidate.measure({"edge": (3, 1, {"data"}), "control": (0, .01, {"data"})}).grounded)


if __name__ == "__main__":
    unittest.main()
