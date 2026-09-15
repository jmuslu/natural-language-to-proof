"""Offline uncertainty and pooling matrix with independently generated known targets.

Every method sees the same observations and target within a case. Generator truth
is used only by scoring. Coverage means repeated-simulation coverage of that target,
not an assertion that every nominal 95% interval has 95% coverage. Timings vary;
seeds, data generators, deterministic work counts and statistical results reproduce.
No model calls, private data, belief writes or validation receipts are involved.
"""
from __future__ import annotations

import argparse
from dataclasses import asdict, dataclass, replace
import json
import math
from pathlib import Path
import random
import statistics
import time

from estimand import EstimandIdentity, Measurement, Quantity, commensurable, update
from regime_estimand import kalman

Z95 = 1.959963984540054
NORMAL = statistics.NormalDist()


@dataclass(frozen=True)
class Estimate:
    point: float
    lower: float
    upper: float
    identity: EstimandIdentity

    def __post_init__(self):
        if (not all(math.isfinite(x) for x in (self.point, self.lower, self.upper))
                or self.lower > self.upper or not isinstance(self.identity, EstimandIdentity)):
            raise ValueError("finite estimate, ordered interval and explicit target required")


def normal_estimate(quantity):
    if quantity.identity is None:
        raise TypeError("scoring requires an explicit target")
    return Estimate(quantity.value, quantity.value-Z95*quantity.sigma,
                    quantity.value+Z95*quantity.sigma, quantity.identity)


class Scores:
    """Aggregate within independent replicates; time points/groups are not iid trials."""
    def __init__(self):
        self.rows = []
        self.elapsed = 0.
        self.work = 0
        self.points = 0

    def add(self, truths, estimates, elapsed=0., work=1):
        if len(truths) != len(estimates) or not truths:
            raise ValueError("paired nonempty truth and estimate vectors required")
        self.rows.append({"mse": statistics.fmean((e.point-t)**2 for t,e in zip(truths,estimates)),
                          "coverage": statistics.fmean(e.lower <= t <= e.upper for t,e in zip(truths,estimates)),
                          "width": statistics.fmean(e.upper-e.lower for e in estimates)})
        self.elapsed += elapsed
        self.work += work
        self.points += len(truths)

    def report(self):
        result = {key: statistics.fmean(row[key] for row in self.rows) for key in ("mse", "coverage", "width")}
        for key in ("mse", "coverage"):
            result[key+"_simulation_se"] = (statistics.stdev(row[key] for row in self.rows)/math.sqrt(len(self.rows))
                                               if len(self.rows) > 1 else None)
        radius = math.sqrt(math.log(40)/(2*len(self.rows)))
        result["coverage_hoeffding_95"] = [max(0.,result["coverage"]-radius), min(1.,result["coverage"]+radius)]
        return {**result, "independent_replicates": len(self.rows), "scored_points": self.points,
                "elapsed_seconds": self.elapsed, "deterministic_work_units": self.work}


def _target(population, *, observable="latent response", summary="latent location", units="response_units"):
    return EstimandIdentity(observable, population, "one observation period", (), units, "raw", summary)


def _weighted_estimate(values, logweights, identity):
    largest = max(logweights)
    weights = [math.exp(w-largest) for w in logweights]
    total = math.fsum(weights)
    weights = [w/total for w in weights]
    point = math.fsum(x*w for x,w in zip(values,weights))
    ordered = sorted(zip(values,weights))

    def quantile(probability):
        cumulative = 0.
        for value, weight in ordered:
            cumulative += weight
            if cumulative >= probability:
                return value
        return ordered[-1][0]

    return Estimate(point, quantile(.025), quantile(.975), identity), 1/math.fsum(w*w for w in weights)


def posterior_estimate(prior, measurement, method, *, seed=0, particles=2048, grid_points=801):
    """Same latent-location target for Normal, t4-grid, t4-particle and interval models.

    Measurement.stderr is an observation-error STANDARD DEVIATION, never a t scale.
    The t4 model uses scale=stderr*sqrt((4-2)/4), so its variance equals stderr^2.
    Grid integrates prior mean +/-8 prior sd. Particles sample the same prior with
    a private seeded RNG. The interval method intersects two nominal 95% intervals,
    or takes their hull on conflict; this does not guarantee 95% target coverage.
    """
    if not commensurable(prior, measurement):
        raise TypeError("matching explicit targets required")
    if measurement.robust:
        raise ValueError("measurement must use robust=False; competing likelihood models are explicit here")
    if method == "gaussian":
        return normal_estimate(update(prior, measurement)), {"work": 1}
    if method == "interval":
        a,b = prior.value-Z95*prior.sigma, prior.value+Z95*prior.sigma
        c,d = measurement.estimate-Z95*measurement.stderr, measurement.estimate+Z95*measurement.stderr
        conflict = a > d or c > b
        lo,hi = (min(a,c),max(b,d)) if conflict else (max(a,c),min(b,d))
        return Estimate((lo+hi)/2, lo, hi, prior.identity), {"work": 1, "conflict": conflict}
    if method not in ("student_grid", "student_particles"):
        raise ValueError("unknown posterior method")
    nu, scale = 4., measurement.stderr/math.sqrt(2)

    def likelihood(value):
        return -(nu+1)/2*math.log1p(((value-measurement.estimate)/scale)**2/nu)

    if method == "student_grid":
        if type(grid_points) is not int or grid_points < 101:
            raise ValueError("grid_points must be at least 101")
        values = [prior.value + prior.sigma*(-8+16*i/(grid_points-1)) for i in range(grid_points)]
        logs = [-.5*((x-prior.value)/prior.sigma)**2+likelihood(x) for x in values]
        estimate, ess = _weighted_estimate(values, logs, prior.identity)
        largest = max(logs)
        normalized = [math.exp(w-largest) for w in logs]
        boundary_mass = sum(normalized[:3]+normalized[-3:])/sum(normalized)
        return estimate, {"work": grid_points, "grid_boundary_mass": boundary_mass}
    if type(particles) is not int or particles < 128:
        raise ValueError("particles must be at least 128")
    rng = random.Random(seed)
    values = [rng.gauss(prior.value, prior.sigma) for _ in range(particles)]
    estimate, ess = _weighted_estimate(values, [likelihood(x) for x in values], prior.identity)
    return estimate, {"work": particles, "effective_sample_size": ess}


def posterior_matrix(trials, seed, particles, grid_points):
    cases = ("gaussian", "heavy_t4", "dependent_naive", "dependent_covariance_model",
             "biased_observation", "shifted_target_prior")
    output = {}
    for index, case in enumerate(cases):
        # Dependence variants deliberately reuse exactly the same data seed.
        data_index = 2 if case == "dependent_covariance_model" else index
        methods = {method: Scores() for method in ("gaussian", "student_grid", "student_particles", "interval")}
        ess, differences, boundaries = [], [], []
        identity = _target(case)
        for trial in range(trials):
            rng = random.Random(seed + data_index*100000 + trial)
            truth = rng.gauss(4. if case == "shifted_target_prior" else 0., 1.)
            n, variance = 1, 1.
            if case.startswith("dependent"):
                n = 16
                common = rng.gauss(0, math.sqrt(.8))
                observation = truth + common + statistics.fmean(rng.gauss(0, math.sqrt(.2)) for _ in range(n))
                variance = .8 + .2/n if case == "dependent_covariance_model" else 1/n
            elif case == "heavy_t4":
                observation = truth + rng.gauss(0, 1)/math.sqrt(rng.gammavariate(2, 2)/4)/math.sqrt(2)
            else:
                observation = truth + rng.gauss(0, 1) + (2. if case == "biased_observation" else 0.)
            prior = Quantity(0, 1, identity.units, identity=identity)
            measurement = Measurement(observation, math.sqrt(variance), n, identity.units,
                                       provenance={f"synthetic:{seed}:{data_index}:{trial}"}, robust=False,
                                       identity=identity)
            estimates = {}
            for method, scores in methods.items():
                start = time.perf_counter()
                estimate, diagnostic = posterior_estimate(prior, measurement, method,
                    seed=seed+9000000+index*100000+trial, particles=particles, grid_points=grid_points)
                elapsed = time.perf_counter()-start
                scores.add([truth], [estimate], elapsed, diagnostic["work"])
                estimates[method] = estimate
                if "effective_sample_size" in diagnostic:
                    ess.append(diagnostic["effective_sample_size"])
                if "grid_boundary_mass" in diagnostic:
                    boundaries.append(diagnostic["grid_boundary_mass"])
            differences.append(abs(estimates["student_grid"].point-estimates["student_particles"].point))
        output[case] = {"identity": asdict(identity), "methods": {name:s.report() for name,s in methods.items()},
                        "student_particle_mean_abs_difference_from_grid": statistics.fmean(differences),
                        "student_particle_max_abs_difference_from_grid": max(differences),
                        "particle_fraction_ess_below_20": statistics.fmean(value < 20 for value in ess),
                        "particle_min_ess": min(ess), "particle_mean_ess": statistics.fmean(ess),
                        "max_grid_boundary_mass": max(boundaries),
                        "measurement_variance_used": variance,
                        "scope": "Matched prior except shifted_target_prior; bias/dependence cases deliberately violate nominal likelihood assumptions."}
    return output


def transformed_estimate(mean, variance, transformation, method, identity, *, seed=0, particles=2048):
    """Estimate g(latent state), with point target posterior E[g(state)].

    The input is dimensionless. This is not g(population mean) or the mean of future noisy observations. The
    model is a supplied Normal posterior. 'exact' is analytic/reference integration
    for that declared model, not externally known truth. Delta uses g(mean), losing
    Jensen terms. MC uses independent posterior draws and empirical quantiles.
    """
    functions = {"square": (lambda x:x*x, lambda x:2*x),
                 "exp": (math.exp, math.exp), "linear": (lambda x:2*x, lambda x:2.)}
    if transformation not in functions or variance <= 0 or not math.isfinite(variance):
        raise ValueError("known transformation and positive finite variance required")
    f, derivative = functions[transformation]
    sd = math.sqrt(variance)
    if method == "delta":
        center, width = f(mean), Z95*abs(derivative(mean))*sd
        return Estimate(center, center-width, center+width, identity)
    if method == "monte_carlo":
        if particles < 128:
            raise ValueError("at least 128 particles required")
        rng = random.Random(seed)
        values = sorted(f(rng.gauss(mean,sd)) for _ in range(particles))
        return Estimate(statistics.fmean(values), values[int(.025*particles)],
                        values[min(particles-1,int(.975*particles))], identity)
    if method != "exact":
        raise ValueError("unknown transformed estimate method")
    if transformation == "linear":
        return Estimate(2*mean, 2*(mean-Z95*sd), 2*(mean+Z95*sd), identity)
    if transformation == "exp":
        return Estimate(math.exp(mean+variance/2), math.exp(mean-Z95*sd), math.exp(mean+Z95*sd), identity)

    def square_quantile(probability):
        lo,hi = 0., (abs(mean)+12*sd)**2
        for _ in range(70):
            midpoint = (lo+hi)/2
            root = math.sqrt(midpoint)
            cdf = NORMAL.cdf((root-mean)/sd)-NORMAL.cdf((-root-mean)/sd)
            if cdf < probability:
                lo = midpoint
            else:
                hi = midpoint
        return (lo+hi)/2

    return Estimate(mean*mean+variance, square_quantile(.025), square_quantile(.975), identity)


def nonlinear_matrix(trials, seed, particles):
    output = {}
    for index, transformation in enumerate(("linear", "square", "exp")):
        identity = _target("matched Normal posterior", observable=f"{transformation}(latent response)",
                           summary="transformed latent value", units="dimensionless")
        methods = {method:Scores() for method in ("delta", "exact", "monte_carlo")}
        for trial in range(trials):
            rng = random.Random(seed+trial)
            truth = rng.gauss(0,1)
            observation = truth+rng.gauss(0,1)
            posterior_mean, posterior_variance = observation/2, .5
            target = {"linear":lambda x:2*x, "square":lambda x:x*x, "exp":math.exp}[transformation](truth)
            for method,scores in methods.items():
                start = time.perf_counter()
                estimate = transformed_estimate(posterior_mean, posterior_variance, transformation, method,
                    identity, seed=seed+1000000+trial, particles=particles)
                scores.add([target], [estimate], time.perf_counter()-start,
                           particles if method == "monte_carlo" else (140 if transformation == "square" and method == "exact" else 1))
        # Bayes risk = E[Var(g(theta)|y)], with theta~N(0,1), y|theta~N(theta,1).
        expected_risk = {"linear":2., "square":1.5, "exp":math.exp(2)-math.exp(1.5)}[transformation]
        output[transformation] = {"identity":asdict(identity), "methods":{name:s.report() for name,s in methods.items()},
                                  "analytic_expected_mse_exact_model":expected_risk,
                                  "risk_identity":"E[Var(g(theta)|y)] under the declared prior-predictive law; sample MSE can be tail-unstable"}
    return output


def regime_matrix(trials, seed):
    output = {}
    for case in ("no_change", "drift", "persistent_jump", "single_outlier"):
        scores = {name:Scores() for name in ("fixed", "adaptive", "robust")}
        event_scores = {name:Scores() for name in scores}
        alarms = {name:[] for name in scores}
        for trial in range(trials):
            rng = random.Random(seed+trial)
            truth = [(max(0,t-30)*.01 if case == "drift" else
                      (1. if case == "persistent_jump" and t >= 50 else 0.)) for t in range(100)]
            obs = [value+rng.gauss(0,.2) for value in truth]
            if case == "single_outlier":
                obs[50] += 4.
            for name,kwargs in (("fixed",{}), ("adaptive",{"adaptive":True}), ("robust",{"robust":True})):
                start = time.perf_counter()
                estimates,variances,surprises = kalman(obs, R=.04, q_base=.001, **kwargs)
                elapsed = time.perf_counter()-start
                intervals = [Estimate(x, x-Z95*math.sqrt(v), x+Z95*math.sqrt(v), _target(case))
                             for x,v in zip(estimates,variances)]
                scores[name].add(truth[20:], intervals[20:], elapsed, 100)
                event_scores[name].add(truth[50:60], intervals[50:60])
                alarms[name].append(statistics.fmean(s > 9 for s in surprises[20:]))
        output[case] = {"methods":{name:{**s.report(), "event_window":event_scores[name].report(),
                                          "innovation_above_9_rate":statistics.fmean(alarms[name])}
                                   for name,s in scores.items()},
                        "R_observation_variance":.04, "q_process_variance_model":.001,
                        "scope":"Same noise draws; process model is a tracking approximation. Scoring excludes first 20 steps; event window is 50:60."}
    return output


@dataclass(frozen=True)
class PoolingModel:
    """Empirical-Bayes Normal group model fitted on separate training groups.

    Borrowing is an explicit exchangeability model, not commensurable() pooling of
    different targets. Hyperparameter estimation uncertainty is approximated for
    the center and omitted for between-group variance; coverage is measured below.
    """
    center: float
    between_variance: float
    center_variance: float
    template: EstimandIdentity
    training_provenance: frozenset

    def __post_init__(self):
        if (not all(math.isfinite(value) for value in (self.center,self.between_variance,self.center_variance))
                or self.between_variance <= 0 or self.center_variance < 0
                or not isinstance(self.template, EstimandIdentity) or not self.training_provenance):
            raise ValueError("finite fitted model, positive group variance and training provenance required")

    def predict(self, measurement):
        if measurement.identity is None or replace(measurement.identity, population=self.template.population) != self.template:
            raise TypeError("group target differs beyond the population attribute licensed by this model")
        if not measurement.provenance or measurement.provenance & self.training_provenance:
            raise ValueError("test group requires declared provenance separate from training")
        within = measurement.stderr**2
        weight = self.between_variance/(self.between_variance+within)
        mean = weight*measurement.estimate+(1-weight)*self.center
        variance = weight*within+(1-weight)**2*self.center_variance
        return Quantity(mean, math.sqrt(variance), measurement.units, basis=measurement.basis,
                        identity=measurement.identity,
                        support={"n":measurement.n, "provenance":measurement.provenance | self.training_provenance},
                        assumptions=("Normal exchangeable-group model; hyperparameters frozen from separate training groups; "
                                     "between-variance estimation uncertainty omitted",))


def fit_pooling_model(group_measurements):
    if len(group_measurements) < 3:
        raise ValueError("at least three independent training groups required")
    template = group_measurements[0].identity
    if template is None:
        raise TypeError("explicit group identities required")
    seen, seen_targets = set(), set()
    for m in group_measurements:
        if (m.identity is None or replace(m.identity, population=template.population) != template
                or not m.provenance or seen & m.provenance or m.identity in seen_targets):
            raise ValueError("compatible declared group model and nonoverlapping training provenance required")
        seen.update(m.provenance)
        seen_targets.add(m.identity)
    means = [m.estimate for m in group_measurements]
    within = statistics.fmean(m.stderr**2 for m in group_measurements)
    observed_variance = statistics.variance(means)
    return PoolingModel(statistics.fmean(means), max(1e-9, observed_variance-within),
                        observed_variance/len(means), template, frozenset(seen))


def pooling_matrix(trials, seed):
    rng = random.Random(seed)
    training = []
    for group in range(200):
        truth = rng.gauss(2,.5)
        data = [rng.gauss(truth,1) for _ in range(6)]
        training.append(Measurement(statistics.fmean(data), 1/math.sqrt(6), 6, "response_units",
                        provenance={f"pool-train:{seed}:{group}"}, robust=False,
                        identity=_target(f"training group {group}", summary="group mean")))
    start = time.perf_counter()
    model = fit_pooling_model(training)
    training_elapsed = time.perf_counter()-start
    output = {}
    for case in ("exchangeable", "sign_flipped_subgroup"):
        scores = {name:Scores() for name in ("no_pooling", "complete_pooling", "partial_pooling")}
        subgroup_scores = {name:Scores() for name in scores}
        for trial in range(trials):
            rng = random.Random(seed+100000+trial)
            truths, measurements = [], []
            for group in range(12):
                truth = rng.gauss(2,.5)
                if case == "sign_flipped_subgroup" and group == 0:
                    truth = -truth
                data = [rng.gauss(truth,1) for _ in range(6)]
                truths.append(truth)
                measurements.append(Measurement(statistics.fmean(data), 1/math.sqrt(6), 6, "response_units",
                    provenance={f"pool-test:{seed}:{trial}:{group}"}, robust=False,
                    identity=_target(f"test group {group}", summary="group mean")))
            for name in scores:
                start = time.perf_counter()
                estimates = []
                pooled = statistics.fmean(m.estimate for m in measurements)
                for m in measurements:
                    if name == "partial_pooling":
                        estimate = normal_estimate(model.predict(m))
                    else:
                        estimate = normal_estimate(Quantity(
                            m.estimate if name == "no_pooling" else pooled,
                            m.stderr if name == "no_pooling" else 1/math.sqrt(72),
                            m.units, identity=m.identity))
                    estimates.append(estimate)
                scores[name].add(truths, estimates, time.perf_counter()-start, 12)
                subgroup_scores[name].add(truths[:1], estimates[:1])
        output[case] = {"methods":{name:{**s.report(), "first_subgroup":subgroup_scores[name].report()}
                                  for name,s in scores.items()}}
    return {"training_seed":seed, "test_seed_base":seed+100000, "n_training_groups":200,
            "observations_per_group":6, "test_groups_per_replication":12,
            "frozen_model":{"center":model.center,"between_variance":model.between_variance,
                            "center_variance":model.center_variance},
            "fit_elapsed_seconds":training_elapsed, "cases":output,
            "scope":"Coverage conditional on one independent frozen training fit. Distinct group means are targets; complete pooling intentionally assumes them equal."}


def run_matrix(*, trials=200, seed=9501, particles=2048, grid_points=801):
    if type(trials) is not int or trials < 20 or trials > 2000:
        raise ValueError("trials must be an integer in [20,2000]")
    if type(seed) is not int or type(particles) is not int or particles < 128 or type(grid_points) is not int or grid_points < 101:
        raise ValueError("integer seed, at least 128 particles and at least 101 grid points required")
    start = time.perf_counter()
    report = {"schema":"nl2proof.uncertainty-matrix.v1", "status":"synthetic_known_targets_not_oracle_evidence",
              "writes_beliefs":False, "config":{"trials":trials,"seed":seed,"particles":particles,"grid_points":grid_points},
              "coverage_target":.95,
              "posterior":posterior_matrix(trials,seed,particles,grid_points),
              "nonlinear":nonlinear_matrix(trials,seed+10000000,particles),
              "regime":regime_matrix(trials,seed+20000000),
              "pooling":pooling_matrix(trials,seed+30000000)}
    report["elapsed_seconds"] = time.perf_counter()-start
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--trials",type=int,default=200)
    parser.add_argument("--seed",type=int,default=9501)
    parser.add_argument("--particles",type=int,default=2048)
    parser.add_argument("--grid-points",type=int,default=801)
    parser.add_argument("--out",type=Path)
    args = parser.parse_args()
    result = run_matrix(trials=args.trials,seed=args.seed,particles=args.particles,grid_points=args.grid_points)
    rendered = json.dumps(result,indent=2,allow_nan=False)+"\n"
    if args.out:
        args.out.parent.mkdir(parents=True,exist_ok=True)
        args.out.write_text(rendered,encoding="utf-8")
    else:
        print(rendered,end="")


if __name__ == "__main__":
    main()
