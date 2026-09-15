"""Target identity, return-basis arithmetic and equivalence-test boundaries."""
from dataclasses import replace
import math
import unittest

from estimand import (EstimandIdentity, Quantity, Measurement, Leg, Hop, Z_SIGNIF,
                      commensurable, update, paired_sharpe, to_deployed,
                      to_deployed_approx, compose_chain, colimit)
from fixture_futures_reversal import (NQ_LEGS, SYNTHETIC_ACTIVE,
    SYNTHETIC_ZERO_IDLE_RETURNS, SYNTHETIC_NONZERO_IDLE_RETURNS)


def identity(**changes):
    return EstimandIdentity(**{"observable": "net return", "population": "generator A",
        "horizon": "one day", "conditioning": (), "units": "points", "basis": "raw",
        "summary": "mean", **changes})


class IdentityTests(unittest.TestCase):
    def test_every_declared_target_attribute_constrains_pooling(self):
        target = identity()
        prior = Quantity(0, 1, "points", identity=target)
        measurement = Measurement(2, 1, 100, "points", provenance={"samples"}, identity=target)
        self.assertGreater(update(prior, measurement).value, 0)
        for name, value in (("observable", "price"), ("population", "generator B"),
                            ("horizon", "two days"), ("conditioning", ("high volatility",)),
                            ("summary", "median"), ("intervention", "new policy"),
                            ("comparator", "baseline"), ("units", "dollars"), ("basis", "calendar")):
            changed = replace(target, **{name: value})
            other = replace(measurement, identity=changed, units=changed.units, basis=changed.basis)
            with self.subTest(attribute=name):
                self.assertFalse(commensurable(prior, other))
                with self.assertRaises(TypeError):
                    update(prior, other)

    def test_two_unknown_legacy_targets_are_not_commensurable(self):
        prior = Quantity(0, 1, "points")
        measurement = Measurement(2, 1, 100, "points", provenance={"samples"})
        self.assertIsNone(prior.identity)
        self.assertFalse(commensurable(prior, prior))
        with self.assertRaises(TypeError):
            update(prior, measurement)
        with self.assertRaises(TypeError):
            update(replace(prior, identity=identity()), measurement)

    def test_identity_schema_is_explicit_and_canonical(self):
        self.assertEqual(identity(conditioning=("b", "a", "a")), identity(conditioning=("a", "b")))
        for changes in ({"observable": ""}, {"conditioning": None}, {"conditioning": "all"},
                        {"conditioning": ("",)}, {"horizon": ""}, {"intervention": ""}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                identity(**changes)
        with self.assertRaises(ValueError):
            Quantity(0, 1, "dollars", identity=identity())

    def test_numerical_hop_changes_type_only_via_explicit_target(self):
        base = Quantity(3, 1, "points", identity=identity())
        dollars = identity(units="dollars")
        out, _ = compose_chain(base, [Hop(2, 0, "two dollars per point", output_identity=dollars)])
        self.assertEqual((out.value, out.sigma, out.units, out.identity), (6, 2, "dollars", dollars))
        self.assertFalse(commensurable(base, out))


class ReturnBasisTests(unittest.TestCase):
    def test_retained_idle_mixture_matches_exact_empirical_moments(self):
        report = paired_sharpe(SYNTHETIC_ZERO_IDLE_RETURNS, SYNTHETIC_ACTIVE)
        self.assertEqual(report["deployment"], .1)
        self.assertAlmostEqual(report["calendar"]["mean"], .1)
        self.assertAlmostEqual(report["calendar"]["variance"], .19)
        self.assertEqual(report["deployed"]["mean"], 1)
        self.assertEqual(report["deployed"]["variance"], 1)
        self.assertEqual(report["deployed"]["sharpe"], 1)
        self.assertAlmostEqual(report["calendar"]["sharpe"] / math.sqrt(.1), 1/math.sqrt(1.9))
        self.assertIsNone(report["uncertainty"])

    def test_nonzero_idle_returns_break_zero_idle_conversion_but_not_paired_estimates(self):
        zero = paired_sharpe(SYNTHETIC_ZERO_IDLE_RETURNS, SYNTHETIC_ACTIVE)
        report = paired_sharpe(SYNTHETIC_NONZERO_IDLE_RETURNS, SYNTHETIC_ACTIVE)
        self.assertEqual(report["deployed"], zero["deployed"])
        self.assertFalse(report["zero_idle_returns"])
        self.assertAlmostEqual(report["calendar"]["mean"], .19)
        self.assertAlmostEqual(report["calendar"]["variance"], .1729)
        self.assertNotEqual(report["calendar"]["sharpe"], zero["calendar"]["sharpe"])

    def test_approximation_requires_assumptions_and_rejects_incompatible_point_estimate(self):
        target = identity(units="sharpe", basis="calendar", summary="equal_period_sharpe")
        small = Quantity(.001, .0001, "sharpe", basis="calendar", identity=target)
        with self.assertRaisesRegex(TypeError, "not an exact"):
            to_deployed(small, .1)
        for flags in ((False, True), (True, False), (1, True)):
            with self.assertRaises(ValueError):
                to_deployed_approx(small, .1, equal_period_zero_idle=flags[0], low_active_snr=flags[1])
        approx = to_deployed_approx(small, .1, equal_period_zero_idle=True, low_active_snr=True)
        self.assertAlmostEqual(approx.value, small.value/math.sqrt(.1))
        self.assertEqual(approx.identity.basis, "deployed")
        self.assertIn("active", approx.identity.conditioning)
        self.assertIn("APPROXIMATION", approx.assumptions[0])
        high = replace(small, value=.1/math.sqrt(.19))
        with self.assertRaisesRegex(ValueError, "contradicts"):
            to_deployed_approx(high, .1, equal_period_zero_idle=True, low_active_snr=True)

    def test_degenerate_streams_do_not_invent_precision(self):
        report = paired_sharpe([1, 1], [True, True])
        self.assertIsNone(report["calendar"]["sharpe"])
        self.assertEqual(report["idle"]["n"], 0)
        for returns, active in (([1], [True]), ([1, 2], [True]), ([1, 2], [False, False]),
                                ([1, 2], [1, 0]), ([0, float("nan")], [True, False]),
                                ([0, 1e308], [True, True])):
            with self.subTest(returns=returns, active=active), self.assertRaises(ValueError):
                paired_sharpe(returns, active)


class EquivalenceTests(unittest.TestCase):
    def test_large_stderr_or_missing_margin_cannot_establish_equivalence(self):
        legacy = Leg("control", "necessity", 0, .1, {"data"})
        self.assertFalse(legacy.binds())
        precise = replace(legacy, equivalence_margin=.5)
        self.assertTrue(precise.binds())
        self.assertFalse(replace(precise, stderr=100).binds())
        self.assertFalse(replace(precise, effect=.5).binds())
        self.assertFalse(replace(precise, effect=-.5).binds())

    def test_confidence_interval_boundary_and_directional_absence(self):
        boundary = Leg("control", "necessity", 0, 1, {"data"}, equivalence_margin=Z_SIGNIF)
        self.assertFalse(boundary.binds())
        self.assertTrue(replace(boundary, equivalence_margin=Z_SIGNIF + .001).binds())
        null_prediction = replace(boundary, kind="prediction", direction=0)
        self.assertFalse(null_prediction.binds())
        absent = Leg("absent", "specificity", 0, 100, {"data"}, present=False, equivalence_margin=.5)
        self.assertFalse(absent.binds())
        self.assertTrue(replace(absent, effect=-3, stderr=.1).binds())
        self.assertFalse(replace(absent, effect=3, stderr=.1).binds())
        self.assertFalse(replace(absent, effect=-3, stderr=.1, direction=-1).binds())

    def test_legacy_reconstruction_remains_unverified_without_invented_margins(self):
        result = colimit("reconstruction", NQ_LEGS)
        self.assertFalse(result.grounded)
        self.assertIn("kl_ablation_collapses", result.failed_legs)
        self.assertIn("cross_ES_absent", result.failed_legs)

    def test_invalid_margin_and_confidence_scale(self):
        leg = Leg("control", "necessity", 0, 1, {"data"})
        for name in ("equivalence_margin", "equivalence_z"):
            for value in (0, -1, True, float("nan"), float("inf")):
                with self.subTest(name=name, value=value), self.assertRaises(ValueError):
                    replace(leg, **{name: value})


if __name__ == "__main__":
    unittest.main()
