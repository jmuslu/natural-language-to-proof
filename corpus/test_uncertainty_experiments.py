"""Exact targets, independent fitting, numerical agreement and adverse scenarios."""
from dataclasses import replace
import json
import math
import unittest

from estimand import EstimandIdentity, Measurement, Quantity
from uncertainty_experiments import (Estimate, Scores, posterior_estimate, transformed_estimate,
    fit_pooling_model, posterior_matrix, pooling_matrix, regime_matrix, run_matrix)


def target(population="test group", summary="latent location"):
    return EstimandIdentity("response", population, "one period", (), "dimensionless", "raw", summary)


class NumericalMethodTests(unittest.TestCase):
    def test_same_gaussian_target_has_exact_posterior(self):
        identity = target()
        prior = Quantity(0, 1, identity.units, identity=identity)
        measurement = Measurement(2, 1, 1, identity.units, provenance={"measurement"}, robust=False, identity=identity)
        estimate,_ = posterior_estimate(prior, measurement, "gaussian")
        self.assertEqual(estimate.point, 1)
        self.assertAlmostEqual(estimate.upper-estimate.lower, 2*1.959963984540054/math.sqrt(2))
        self.assertEqual(estimate.identity, identity)
        with self.assertRaises(TypeError):
            posterior_estimate(prior, replace(measurement, identity=target("other")), "gaussian")

    def test_student_particle_and_grid_approximate_same_posterior_model(self):
        identity = target()
        prior = Quantity(0, 1, identity.units, identity=identity)
        measurement = Measurement(1, .7, 1, identity.units, provenance={"measurement"}, robust=False, identity=identity)
        fine, grid_diag = posterior_estimate(prior, measurement, "student_grid", grid_points=1601)
        coarse,_ = posterior_estimate(prior, measurement, "student_grid", grid_points=801)
        particles, particle_diag = posterior_estimate(prior, measurement, "student_particles", seed=43, particles=30000)
        self.assertLess(abs(fine.point-coarse.point), .001)
        self.assertLess(abs(fine.point-particles.point), .025)
        self.assertLess(abs(fine.lower-particles.lower), .06)
        self.assertLess(grid_diag["grid_boundary_mass"], 1e-8)
        self.assertGreater(particle_diag["effective_sample_size"], 1000)

    def test_nonlinear_methods_target_transformed_latent_not_transformed_mean(self):
        identity = target(summary="transformed latent value")
        exact = transformed_estimate(0, 1, "square", "exact", identity)
        delta = transformed_estimate(0, 1, "square", "delta", identity)
        mc = transformed_estimate(0, 1, "square", "monte_carlo", identity, seed=51, particles=20000)
        self.assertEqual(exact.point, 1)
        self.assertEqual((delta.point, delta.lower, delta.upper), (0, 0, 0))
        self.assertGreater(exact.lower, 0)
        self.assertLess(abs(mc.point-exact.point), .04)
        self.assertLess(abs(mc.upper-exact.upper), .2)
        exp = transformed_estimate(0, 1, "exp", "exact", identity)
        self.assertAlmostEqual(exp.point, math.exp(.5))
        self.assertEqual(transformed_estimate(1, .5, "linear", "delta", identity),
                         transformed_estimate(1, .5, "linear", "exact", identity))

    def test_scores_count_independent_replicates_not_correlated_points(self):
        scores = Scores()
        good = Estimate(0, -1, 1, target())
        bad = Estimate(2, 1, 3, target())
        scores.add([0]*10, [good]*10)
        scores.add([0]*10, [bad]*10)
        report = scores.report()
        self.assertEqual(report["independent_replicates"], 2)
        self.assertEqual(report["scored_points"], 20)
        self.assertEqual(report["coverage"], .5)
        self.assertAlmostEqual(report["coverage_simulation_se"], .5)
        self.assertLess(report["coverage_hoeffding_95"][0], report["coverage"])
        self.assertGreater(report["coverage_hoeffding_95"][1], report["coverage"])


class PoolingContractTests(unittest.TestCase):
    def measurements(self):
        return [Measurement(value,.2,25,"dimensionless",provenance={f"train-{index}"},robust=False,
                            identity=target(f"group-{index}","group mean")) for index,value in enumerate((1.,2.,3.))]

    def test_pooling_requires_explicit_model_and_independent_training_groups(self):
        training = self.measurements()
        model = fit_pooling_model(training)
        measurement = Measurement(0,1,1,"dimensionless",provenance={"heldout"},robust=False,
                                   identity=target("new group","group mean"))
        estimate = model.predict(measurement)
        self.assertEqual(estimate.identity, measurement.identity)
        self.assertGreater(estimate.value, 0)
        self.assertLess(estimate.value, model.center)
        self.assertIn("hyperparameters frozen", estimate.assumptions[0])
        with self.assertRaises(TypeError):
            model.predict(replace(measurement, identity=replace(measurement.identity, horizon="another period")))
        with self.assertRaises(ValueError):
            model.predict(replace(measurement, provenance={"train-0"}))
        with self.assertRaises(ValueError):
            fit_pooling_model([training[0],training[0],training[2]])
        with self.assertRaises(ValueError):
            fit_pooling_model([training[0],replace(training[1],identity=training[0].identity),training[2]])

    def test_frozen_partial_pooling_has_shift_failure_control(self):
        report = pooling_matrix(80, 30009501)
        exchangeable = report["cases"]["exchangeable"]["methods"]
        shifted = report["cases"]["sign_flipped_subgroup"]["methods"]
        self.assertLess(exchangeable["partial_pooling"]["mse"], exchangeable["no_pooling"]["mse"])
        self.assertGreater(shifted["partial_pooling"]["first_subgroup"]["mse"],
                           shifted["no_pooling"]["first_subgroup"]["mse"])
        self.assertLess(shifted["partial_pooling"]["first_subgroup"]["coverage"], .5)
        self.assertNotEqual(report["training_seed"], report["test_seed_base"])


class ExperimentMatrixTests(unittest.TestCase):
    def test_covariance_model_and_prior_shift_produce_expected_adverse_controls(self):
        report = posterior_matrix(80, 9501, 256, 201)
        naive = report["dependent_naive"]["methods"]["gaussian"]
        aware = report["dependent_covariance_model"]["methods"]["gaussian"]
        self.assertGreater(aware["coverage"], naive["coverage"]+.2)
        shifted = report["shifted_target_prior"]["methods"]
        self.assertGreater(shifted["student_grid"]["mse"], shifted["gaussian"]["mse"])
        self.assertEqual(report["gaussian"]["methods"]["student_particles"]["deterministic_work_units"], 80*256)

    def test_no_change_jump_and_outlier_use_paired_noise_without_universal_winner(self):
        report = regime_matrix(60, 20009501)
        jump = report["persistent_jump"]["methods"]
        outlier = report["single_outlier"]["methods"]
        self.assertLess(jump["adaptive"]["event_window"]["mse"], jump["fixed"]["event_window"]["mse"])
        self.assertLess(outlier["robust"]["event_window"]["mse"], outlier["adaptive"]["event_window"]["mse"])
        self.assertAlmostEqual(report["no_change"]["R_observation_variance"], .2**2)

    def test_report_is_finite_seeded_and_not_oracle_evidence(self):
        report = run_matrix(trials=20,seed=22,particles=128,grid_points=101)
        self.assertEqual(report["status"], "synthetic_known_targets_not_oracle_evidence")
        self.assertFalse(report["writes_beliefs"])
        self.assertEqual(len(report["posterior"]), 6)
        self.assertEqual(len(report["nonlinear"]), 3)
        self.assertEqual(len(report["regime"]), 4)
        self.assertEqual(len(report["pooling"]["cases"]), 2)
        json.dumps(report,allow_nan=False)
        for kwargs in ({"trials":1}, {"particles":2}, {"grid_points":2}, {"seed":True}):
            with self.assertRaises(ValueError):
                run_matrix(**kwargs)


if __name__ == "__main__":
    unittest.main()
