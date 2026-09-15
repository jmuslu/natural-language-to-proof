"""Seeded, finite experiments for concept induction, abstention and escalation.

No model, market, or live-data calls. World outcomes are generated independently
of policy choices; only train/calibration labels can influence fitted decisions.
Shifted tests intentionally violate training assumptions and retain failures.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import random
import statistics

from abstain import fit_threshold, labeled_stream, risk_coverage
from grok import CORE, KILLER, FEATURES, Grokker, Memorizer, accuracy, is_real, sample_signal
from metalearn import ResidualLearner, fixed_policy, incurred
from robust_concept import Conjunction, train_candidates, select_candidate, prediction_confidence


def concept_experiment(seed=9201, n_train=1200, n_test=600):
    train_rng = random.Random(seed)
    train = [sample_signal(train_rng, "market") for _ in range(n_train)]
    model, memorizer = Grokker(), Memorizer()
    for f, y, _ in train:
        model.learn(f, y); memorizer.learn(f, y)
    majority = sum(y for _, y, _ in train) > len(train)/2
    tests = {}
    for offset, domain in ((1, "market"), (2, "neuromorphic")):
        rng = random.Random(seed+offset)
        data = [sample_signal(rng, domain) for _ in range(n_test)]
        tests[domain] = {"grokker_accuracy": accuracy(model, data),
                         "memorizer_accuracy": accuracy(memorizer, data),
                         "train_majority_accuracy": sum(y == majority for _, y, _ in data)/n_test}
    rng = random.Random(seed+3)
    shifted = [sample_signal(rng, "market") for _ in range(n_test)]
    shifted = [(f, ("weak_predictor_residual" in f) != ("regime_conditional" in f), d) for f, _, d in shifted]
    return {"seed": seed, "train_seed": seed, "test_seeds": [seed+1, seed+2, seed+3],
            "n_train": n_train, "n_test_each": n_test, "required": sorted(model.R), "forbidden": sorted(model.K),
            "training_consistent": model.consistent, "same_target_tests": tests,
            "changed_target_accuracy": accuracy(model, shifted),
            "scope": "Restricted conjunction recovery and distractor shift; changed-target test is a failure control, not broad domain transfer."}


def abstention_experiment(seed=9301, n_train=1500, n_calibration=4000, n_test=4000):
    train = labeled_stream(random.Random(seed), n_train)
    calibration = labeled_stream(random.Random(seed+1), n_calibration)
    checked = lambda rows: [(score, label, is_real(f)) for f, label, score in rows]
    threshold = fit_threshold(checked(calibration), max_risk=.1)
    naive, selective = Grokker(), Grokker()
    accepted_train = 0
    for f, label, score in train:
        naive.learn(f, label)
        if threshold.accepts(score):
            selective.learn(f, label)
            accepted_train += 1
    reports = {}
    for offset, shift in ((2, False), (3, True)):
        rows = labeled_stream(random.Random(seed+offset), n_test, shifted=shift)
        reports["shifted_quality" if shift else "same_distribution"] = {
            "all_labels": risk_coverage(checked(rows)),
            "calibrated_selection": risk_coverage(checked(rows), threshold),
            "naive_concept_accuracy": sum(naive.predict(f) == is_real(f) for f, _, _ in rows)/n_test,
            "selective_concept_accuracy": sum(selective.predict(f) == is_real(f) for f, _, _ in rows)/n_test}
    return {"seed": seed, "split_seeds": {"train": seed, "calibration": seed+1, "test": seed+2, "shifted_test": seed+3},
            "n_train": n_train, "n_calibration": n_calibration, "n_test_each": n_test,
            "policy": threshold.to_dict(), "training_labels_accepted": accepted_train,
            "concept_training_consistent": {"all": naive.consistent, "selected": selective.consistent},
            "tests": reports,
            "scope": "Calibration controls a simulated label channel under its sampling assumptions; even selected labels contain errors and can corrupt a brittle discrete learner."}


def simulated_outcomes(seed, n, *, shifted=False):
    """Finite measurement-channel world, with truth drawn before noisy responses.

    The policy sees n,z and the cheap response, not hidden channel probabilities,
    corruption events or truth. Heavy responses are never assumed correct.
    Both hypothetical responses are retained offline for paired scoring.
    """
    rng, rows = random.Random(seed), []
    for _ in range(n):
        samples, discrepancy = rng.choice((5, 20, 60, 200, 500)), rng.uniform(0, 8)
        truth = bool(rng.getrandbits(1))
        if (samples < 30 and discrepancy > 4) or (samples >= 200 and 1 <= discrepancy < 2):
            regime, cheap_error, heavy_error, shared_error = "heavy_helpful", .45, .08, .03
        elif discrepancy < 1:
            regime, cheap_error, heavy_error, shared_error = "heavy_harmful", .03, .45, .03
        elif 2 <= discrepancy < 4:
            regime, cheap_error, heavy_error, shared_error = "shared_bias", .02, .02, .35
        else:
            regime, cheap_error, heavy_error, shared_error = "similar", .05, .05, .03
        if shifted:
            cheap_error, heavy_error = heavy_error, cheap_error
            if regime == "shared_bias":
                shared_error = .65
        shared = rng.random() < shared_error
        cheap = truth ^ shared ^ (rng.random() < cheap_error)
        heavy = truth ^ shared ^ (rng.random() < heavy_error)
        rows.append({"n": samples, "z": discrepancy, "truth": truth, "cheap": cheap,
                     "heavy": heavy, "regime": regime})
    return rows


def score_policy(rows, policy, cost=1., stakes=10.):
    total_loss = total_error = escalations = lower_bound = 0
    per_regime = {}
    for row in rows:
        # Decide before the scoring branch is allowed to read truth.
        escalate = bool(policy(row["n"], row["z"]))
        cheap_loss, heavy_loss = int(row["cheap"] != row["truth"]), int(row["heavy"] != row["truth"])
        loss = incurred(escalate, cheap_loss, heavy_loss, cost, stakes)
        total_loss += loss
        total_error += heavy_loss if escalate else cheap_loss
        escalations += escalate
        lower_bound += min(stakes*cheap_loss, cost+stakes*heavy_loss)
        group = per_regime.setdefault(row["regime"], {"n": 0, "loss": 0., "errors": 0})
        group["n"] += 1; group["loss"] += loss
        group["errors"] += heavy_loss if escalate else cheap_loss
    return {"examples": len(rows), "errors": total_error, "error_rate": total_error/len(rows),
            "escalations": escalations, "escalation_rate": escalations/len(rows),
            "mean_loss": total_loss/len(rows), "hindsight_regret": (total_loss-lower_bound)/len(rows),
            "per_regime": per_regime}


def selector_experiment(seed=9401, n_train=6000, n_calibration=2000, n_test=4000):
    cost, stakes = 1., 10.
    train = simulated_outcomes(seed, n_train)
    calibration = simulated_outcomes(seed+1, n_calibration)
    candidates, training = [], []
    for beta in (.15, .3, .6):
        learner = ResidualLearner(cost, stakes, beta)
        probes = 0
        for row in train:
            if learner.decide(row["n"], row["z"]):
                probes += 1
                learner.observe(row["n"], row["z"], cheap_loss=int(row["cheap"] != row["truth"]),
                                heavy_loss=int(row["heavy"] != row["truth"]))
        calibration_loss = score_policy(calibration, learner.escalates, cost, stakes)["mean_loss"]
        candidates.append((calibration_loss, beta, learner))
        training.append({"beta": beta, "paired_training_checks": probes, "training_escalation_cost": probes*cost,
                         "calibration_loss": calibration_loss})
    _, chosen_beta, chosen = min(candidates, key=lambda candidate: candidate[:2])
    policies = {"never": lambda n,z: False, "always": lambda n,z: True,
                "fixed": fixed_policy, "learned": chosen.escalates}
    tests = {}
    for offset, shifted in ((2, False), (3, True)):
        rows = simulated_outcomes(seed+offset, n_test, shifted=shifted)
        scores = {name: score_policy(rows, policy, cost, stakes) for name, policy in policies.items()}
        best_fixed = min(scores[name]["mean_loss"] for name in ("never", "always", "fixed"))
        for values in scores.values():
            values["loss_minus_best_fixed"] = values["mean_loss"]-best_fixed
        tests["context_shift" if shifted else "same_distribution"] = scores
    return {"seed": seed, "split_seeds": {"train": seed, "calibration": seed+1, "test": seed+2, "shifted_test": seed+3},
            "n_train": n_train, "n_calibration": n_calibration, "n_test_each": n_test,
            "cost_per_escalation": cost, "error_stakes": stakes, "training": training,
            "selected_beta": chosen_beta, "tests": tests,
            "scope": "Simulated fallible channels; costs are stipulated units. Hindsight regret compares with a nondeployable per-example lower bound. Test labels never update the policy; training probes are additional reported cost."}


def induction_rows(seed, n, scenario, *, changed_target=False):
    """Synthetic world outcomes and fallible labels, generated before model fitting."""
    if scenario not in ("clean", "symmetric_noise", "confident_asymmetric_errors", "irreducible_outcome_noise"):
        raise ValueError("unknown induction scenario")
    rng, rows = random.Random(seed), []
    for _ in range(n):
        features, latent, _ = sample_signal(rng, "market")
        if changed_target:
            latent = ("weak_predictor_residual" in features) != ("regime_conditional" in features)
        # Irreducible outcome variation is different from a bad observed label.
        truth = latent ^ (scenario == "irreducible_outcome_noise" and rng.random() < .25)
        if scenario == "symmetric_noise":
            score, flip_probability = rng.choice((.55, .75, .95)), None
            flip_probability = 1-score
        elif scenario == "confident_asymmetric_errors":
            score, flip_probability = .95, .4 if truth else .05
        else:
            score, flip_probability = .99, 0.
        observed = truth ^ (rng.random() < flip_probability)
        rows.append({"features": features, "observed": observed, "truth": truth,
                     "score": score, "latent": latent})
    return rows


def robust_induction_experiment(seed=9501, n_train=1500, n_selection=4000,
                                n_risk_calibration=2000, n_test=4000, *, evaluation_role="development"):
    """Same noisy training labels for three discrete induction methods.

    Model/complexity and source-label threshold use selection calibration only.
    Prediction-risk calibration is separate again; test data select nothing.
    """
    if evaluation_role not in ("development", "fixed_replication"):
        raise ValueError("evaluation role must distinguish development from a fixed replication")
    scenarios = ("clean", "symmetric_noise", "confident_asymmetric_errors", "irreducible_outcome_noise")
    result = {}
    for index, scenario in enumerate(scenarios):
        start = seed+100*index
        train = induction_rows(start, n_train, scenario)
        selection = induction_rows(start+1, n_selection, scenario)
        risk_calibration = induction_rows(start+2, n_risk_calibration, scenario)
        test = induction_rows(start+3, n_test, scenario)
        pairs = lambda rows, label: [(row["features"], row[label]) for row in rows]
        checked_selection = pairs(selection, "truth")
        source_threshold = fit_threshold([(row["score"], row["observed"], row["truth"]) for row in selection])
        exact, selection_only = Grokker(), Grokker()
        selected_count = 0
        for row in train:
            exact.learn(row["features"], row["observed"])
            if source_threshold.accepts(row["score"]):
                selection_only.learn(row["features"], row["observed"])
                selected_count += 1
        candidates, resources = train_candidates(pairs(train, "observed"), FEATURES)
        robust, candidate_scores = select_candidate(candidates, checked_selection)
        # Freeze the same R/K patterns once; evaluating must not relearn them or
        # repeatedly scan every historical negative at every test prediction.
        freeze = lambda model: Conjunction(tuple(sorted(model.R)), tuple(sorted(model.K)), not model.pos_seen)
        models = {"exact_intersection": freeze(exact), "selection_only": freeze(selection_only),
                  "empirical_signed_conjunction": robust}
        tests = {"same_distribution": test}
        if scenario == "symmetric_noise":
            tests["changed_target"] = induction_rows(start+4, n_test, scenario, changed_target=True)
        reports = {}
        for name, model in models.items():
            confidence = prediction_confidence(model, checked_selection)
            scored = lambda rows: [(confidence[model.predict(row["features"])],
                                   model.predict(row["features"]), row["truth"]) for row in rows]
            threshold = fit_threshold(scored(risk_calibration))
            reports[name] = {"prediction_confidence": {"false": confidence[False], "true": confidence[True]},
                             "risk_threshold": threshold.to_dict(),
                             "tests": {test_name: {"all_predictions": risk_coverage(scored(rows)),
                                                   "with_abstention": risk_coverage(scored(rows), threshold)}
                                       for test_name, rows in tests.items()}}
        result[scenario] = {
            "split_seeds": {"train": start, "selection": start+1, "risk_calibration": start+2,
                            "test": start+3, "changed_target_test": start+4 if "changed_target" in tests else None},
            "training_label_error_rate": sum(row["observed"] != row["truth"] for row in train)/n_train,
            "training_outcome_variation_rate": sum(row["truth"] != row["latent"] for row in train)/n_train,
            "source_label_threshold": source_threshold.value, "training_labels_selected": selected_count,
            "exact_training_consistent": exact.consistent, "selection_training_consistent": selection_only.consistent,
            "hypothesis_class": resources, "selected_model": robust.to_dict(),
            "candidate_scores": candidate_scores, "methods": reports}
    return {"seed": seed, "evaluation_role": evaluation_role, "n_train": n_train, "n_selection": n_selection,
            "n_risk_calibration": n_risk_calibration, "n_test_each": n_test, "scenarios": result,
            "scope": "Finite signed-conjunction class with supplied feature universe. Same noisy labels train all methods; separate checked calibration outcomes select complexity and then validate abstention. No hidden corruption flag or test outcome enters a learner. Risk bounds require unchanged sampling; irreducible variation and target shift remain failure controls."}


def run():
    return {"schema": "adaptive-outcomes-v2", "concept": concept_experiment(),
            "abstention": abstention_experiment(), "selector": selector_experiment(),
            "robust_induction": robust_induction_experiment()}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", type=Path)
    args = parser.parse_args()
    report = run()
    text = json.dumps(report, indent=2)
    if args.out:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(text+"\n")
    else:
        print(text)


if __name__ == "__main__":
    main()
