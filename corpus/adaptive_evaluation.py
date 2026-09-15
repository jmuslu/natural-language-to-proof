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
from grok import CORE, KILLER, Grokker, Memorizer, accuracy, is_real, sample_signal
from metalearn import ResidualLearner, fixed_policy, incurred


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


def run():
    return {"schema": "adaptive-outcomes-v1", "concept": concept_experiment(),
            "abstention": abstention_experiment(), "selector": selector_experiment()}


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
