"""Regression checks for support, provenance, and oracle-revision boundaries.

These synthetic inputs test the calculation; they are not external observations.
Run: python3 -m unittest discover -s corpus -p test_grounding.py -v
"""
import itertools
import math
import unittest
from dataclasses import replace

from estimand import (EstimandIdentity, Hop, Leg, Measurement, Quantity, colimit, colimit_hybrid,
                      edge_weight_from_multiplicity, update)
from retract import Genealogy


def prediction(name="edge", effect=2.0, provenance=("source-a",), **kwargs):
    return Leg(name, "prediction", effect, 1.0, frozenset(provenance), **kwargs)


class GenealogyTests(unittest.TestCase):
    def test_empty_justification_needs_oracle_confirmation(self):
        g = Genealogy()
        g.justify("premise", [])
        g.justify("claim", ["premise"])
        self.assertEqual(g.grounded(), set())
        self.assertIsNone(g.premises["premise"])
        report = g.set_verdict("premise", True)
        self.assertEqual(report["added"], {"premise", "claim"})
        self.assertEqual(g.grounded(), {"premise", "claim"})

    def test_unknown_default_and_strict_three_valued_verdicts(self):
        g = Genealogy()
        g.add_premise("unknown")
        g.add_premise("false", False)
        g.add_premise("true", True)
        self.assertEqual(g.grounded(), {"true"})
        for malformed in (0, 1, "False", "confirmed", [], {}):
            with self.subTest(malformed=malformed):
                with self.assertRaises(TypeError):
                    g.add_premise("bad", malformed)
                with self.assertRaises(TypeError):
                    g.set_verdict("true", malformed)
                self.assertEqual(g.grounded(), {"true"})
        with self.assertRaises(TypeError):
            Genealogy(premises={"bad": "False"})
        g.premises["bad"] = 1
        with self.assertRaises(TypeError):
            g.grounded()

    def test_cycle_needs_external_root_and_collapses_when_root_withdrawn(self):
        g = Genealogy()
        g.justify("a", ["b"])
        g.justify("b", ["a"])
        g.justify("self", ["self"])
        self.assertEqual(g.grounded(), set())
        g.add_premise("root", True)
        g.justify("a", ["root"])
        self.assertEqual(g.grounded(), {"root", "a", "b"})
        report = g.apply_retraction("root")
        self.assertEqual(report["precise"], {"root", "a", "b"})
        self.assertEqual(g.grounded(), set())
        self.assertNotIn("a", g.dependents("a"))

    def test_alternate_support_preview_and_persistent_retraction(self):
        g = Genealogy()
        for name in ("p1", "p2", "p3"):
            g.add_premise(name, True)
        g.justify("c", ["p1"])
        g.justify("c", ["p2"])
        g.justify("d", ["c", "p3"])
        g.justify("e", ["p1"])
        before = g.grounded()
        preview = g.retract("p1")
        self.assertEqual(g.grounded(), before)
        self.assertIs(g.premises["p1"], True)
        self.assertEqual(preview["precise"], {"p1", "e"})
        self.assertEqual(preview["survivors"], {"c", "d"})
        actual = g.apply_retraction("p1")
        self.assertEqual(actual, preview)
        self.assertEqual(actual["after"], g.grounded())
        self.assertEqual(actual["before"] - actual["after"], actual["precise"])
        self.assertIs(g.premises["p1"], False)
        self.assertEqual(g.apply_retraction("p1")["precise"], set())
        self.assertEqual(g.set_verdict("p1", True)["added"], {"p1", "e"})
        self.assertEqual(g.set_verdict("p1", None)["precise"], {"p1", "e"})
        self.assertIsNone(g.premises["p1"])

    def test_duplicate_support_is_idempotent_and_derived_verdict_cannot_seed(self):
        g = Genealogy()
        g.justify("a", ["b"])
        g.justify("a", ["b"])
        self.assertEqual(len(g.justifications), 1)
        with self.assertRaises(KeyError):
            g.set_verdict("a", True)
        self.assertEqual(g.grounded(), set())

    def test_retraction_can_preserve_premise_with_alternative_derivation(self):
        g = Genealogy(premises={"p": True, "q": True})
        g.justify("p", ["q"])
        self.assertEqual(g.apply_retraction("p")["precise"], set())
        self.assertEqual(g.grounded(), {"p", "q"})


class GroundingTests(unittest.TestCase):
    def test_empty_and_null_only_patterns_cannot_ground(self):
        cases = [[],
                 [Leg("null", "necessity", 0, 1, frozenset({"a"}))],
                 [prediction(effect=0, direction=0)],
                 [Leg("absent", "specificity", 0, 1, frozenset({"a"}), present=False)]]
        for legs in cases:
            for ground in (colimit, colimit_hybrid):
                with self.subTest(ground=ground.__name__, legs=legs):
                    result = ground("apex", legs)
                    self.assertFalse(result.grounded)
                    self.assertEqual((result.verdict, result.edge_weight), (0, 0))

    def test_negative_predicted_effect_supports_hypothesis(self):
        neg = colimit("falls", [prediction(effect=-2.5, direction=-1)])
        pos = colimit("rises", [prediction(effect=2.5, direction=1)])
        self.assertTrue(neg.grounded)
        self.assertEqual(neg.verdict, pos.verdict)
        self.assertGreater(neg.verdict, 0.9)
        self.assertFalse(colimit("rises", [prediction(effect=-2.5)]).grounded)

    def test_copies_and_renamed_copies_cannot_amplify_evidence(self):
        leg = prediction()
        once = colimit("apex", [leg])
        for copies in ([leg] * 100, [leg, replace(leg, name="renamed")],
                       [leg, replace(leg, name="stronger-same-source", effect=20)]):
            self.assertEqual(once, colimit("apex", copies))

    def test_transitive_overlap_is_order_invariant(self):
        legs = [prediction("a", 2, ("a",)), prediction("b", 4, ("b",)),
                prediction("bridge", 3, ("a", "b")), prediction("c", 5, ("c",))]
        expected = colimit("apex", legs)
        self.assertEqual(expected.multiplicity, 2)
        self.assertEqual(expected.verdict, math.tanh(2))
        for permutation in itertools.permutations(legs):
            self.assertEqual(colimit("apex", list(permutation)), expected)

    def test_nonbinding_control_can_declare_shared_provenance(self):
        legs = [prediction("a", provenance=("a",)), prediction("b", provenance=("b",)),
                Leg("joint-null", "necessity", 0, .1, frozenset({"a", "b"}), equivalence_margin=.5)]
        self.assertEqual(colimit("apex", legs).multiplicity, 1)

    def test_disjoint_tags_do_not_pool_precision(self):
        one = colimit("apex", [prediction()])
        more = colimit("apex", [prediction(), prediction("other", provenance=("b",))])
        self.assertEqual(more.verdict, one.verdict)
        self.assertEqual(more.multiplicity, 2)
        self.assertGreater(more.edge_weight, one.edge_weight)

    def test_unmeasured_null_or_absent_slot_cannot_pass(self):
        for missing in (Leg("null", "necessity", 0, 1, frozenset()),
                        Leg("absent", "specificity", 0, 1, frozenset(), present=False),
                        prediction("missing", provenance=())):
            for ground in (colimit, colimit_hybrid):
                result = ground("apex", [prediction(), missing])
                self.assertFalse(result.grounded)
                self.assertIn(missing.name, result.failed_legs)

    def test_hybrid_cannot_skip_null_prediction_veto(self):
        legs = [prediction(), prediction("expected-null", 4, direction=0)]
        self.assertFalse(colimit_hybrid("apex", legs, allow_miss=100).grounded)
        self.assertTrue(colimit_hybrid("apex", [prediction(), prediction("marginal", 1)]).grounded)

    def test_hybrid_quorum_is_not_changed_by_duplicate_checks(self):
        good, marginal = prediction(), prediction("marginal", 1)
        expected = colimit_hybrid("apex", [good, marginal])
        self.assertTrue(expected.grounded)
        self.assertEqual(expected, colimit_hybrid("apex", [good, marginal, marginal]))
        self.assertEqual(expected, colimit_hybrid("apex", [good, marginal,
                                                          replace(marginal, name="renamed")]))

    def test_invalid_legs_rejected_before_calculation(self):
        good = prediction()
        invalid = [("effect", float("nan")), ("effect", float("inf")), ("effect", 10**1000),
                   ("stderr", 0), ("stderr", -1), ("stderr", float("inf")),
                   ("stderr", float("nan")), ("stderr", True), ("kind", "typo"),
                   ("direction", 2), ("direction", True), ("present", "false"),
                   ("n", 0), ("n", 2.5), ("n", True), ("name", ""),
                   ("provenance", "source"), ("provenance", [""]),
                   ("provenance", [None]), ("provenance", {"source": True})]
        for field, value in invalid:
            with self.subTest(field=field, value=value), self.assertRaises(ValueError):
                replace(good, **{field: value})
        with self.assertRaises(ValueError):
            Leg("bad", "specificity", 0, 1, frozenset({"a"}), direction=0)
        for value in (-1, 0.5, True):
            with self.assertRaises(ValueError):
                colimit_hybrid("apex", [good], allow_miss=value)
            with self.assertRaises(ValueError):
                edge_weight_from_multiplicity(value)


class MeasurementTests(unittest.TestCase):
    def setUp(self):
        self.identity = EstimandIdentity("response", "synthetic population", "one period", (), "x", "raw", "mean")
        self.prior = Quantity(0, 1, "x", identity=self.identity)
        self.measurement = Measurement(3, 1, 100, "x", provenance=frozenset({"a"}), identity=self.identity)

    def test_replay_uses_stored_prior_provenance(self):
        once = update(self.prior, self.measurement)
        replayed = update(once, self.measurement)
        self.assertEqual(once, replayed)
        # Supplying an empty explicit set must not override stored provenance.
        self.assertEqual(once, update(once, self.measurement, prior_provenance=frozenset()))

    def test_partial_overlap_cannot_add_fractional_precision(self):
        once = update(self.prior, self.measurement)
        overlapping = replace(self.measurement, estimate=20, provenance=frozenset({"a", "b"}))
        self.assertEqual(once, update(once, overlapping))

    def test_disjoint_conditional_update_and_sample_count(self):
        once = update(self.prior, self.measurement)
        twice = update(once, replace(self.measurement, provenance=frozenset({"b"})))
        self.assertLess(twice.sigma, once.sigma)
        self.assertEqual(twice.support["n"], 200)
        self.assertEqual(twice.support["provenance"], frozenset({"a", "b"}))

    def test_units_basis_and_missing_provenance_refused(self):
        for field, value in (("units", "y"), ("basis", "calendar")):
            with self.assertRaises(TypeError):
                update(self.prior, replace(self.measurement, **{field: value},
                                          identity=replace(self.identity, **{field: value})))
        with self.assertRaises(ValueError):
            update(self.prior, replace(self.measurement, provenance=frozenset()))
        with self.assertRaises(ValueError):
            update(replace(self.prior, support={"n": 10}), self.measurement)

    def test_invalid_quantities_measurements_and_hops_refused(self):
        for value in (0, -1, float("nan"), float("inf"), True):
            with self.subTest(value=value):
                with self.assertRaises(ValueError):
                    replace(self.prior, sigma=value)
                with self.assertRaises(ValueError):
                    replace(self.measurement, stderr=value)
        for changes in ({"estimate": float("inf")}, {"provenance": "a"},
                        {"provenance": [""]}, {"robust": "true"}, {"n": 0},
                        {"deployment": float("nan")}, {"deployment": 1.5}):
            with self.assertRaises(ValueError):
                replace(self.measurement, **changes)
        for changes in ({"jacobian": float("nan")}, {"add_var": -1}, {"add_var": float("inf")}):
            with self.assertRaises(ValueError):
                replace(Hop(1), **changes)


if __name__ == "__main__":
    unittest.main()
