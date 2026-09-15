"""Finite signed-conjunction induction with empirical error and held-out selection.

This learner sees only caller-supplied features and labels. It has no synthetic
target or corruption flag. Bitsets make a declared finite hypothesis class cheap
to score; resource caps are checked before enumeration. The class is restricted,
so low training error is not a universal representation or truth guarantee.
"""
from __future__ import annotations

from dataclasses import dataclass
import itertools
import math


@dataclass(frozen=True)
class Conjunction:
    required: tuple = ()
    forbidden: tuple = ()
    constant_false: bool = False

    @property
    def complexity(self):
        return len(self.required)+len(self.forbidden)

    def predict(self, features):
        features = frozenset(features)
        return not self.constant_false and all(f in features for f in self.required) and not any(f in features for f in self.forbidden)

    def to_dict(self):
        return {"required": list(self.required), "forbidden": list(self.forbidden),
                "constant_false": self.constant_false, "complexity": self.complexity}

    def order_key(self):
        # Explicit conservative tie-break when constant true and false tie.
        return self.complexity, not self.constant_false, self.required, self.forbidden


def examples(rows, *, max_examples=10000):
    if type(max_examples) is not int or max_examples < 1:
        raise ValueError("positive integer sample cap required")
    rows = list(itertools.islice(rows, max_examples+1))
    if not rows or len(rows) > max_examples:
        raise ValueError("nonempty examples within the declared sample cap required")
    checked = []
    for features, label in rows:
        if isinstance(features, str) or type(label) is not bool:
            raise ValueError("feature collections and Boolean labels required")
        features = frozenset(features)
        if any(not isinstance(f, str) or not f for f in features):
            raise ValueError("nonempty feature names required")
        checked.append((features, label))
    return checked


def train_candidates(rows, feature_names, *, max_required=3, max_forbidden=1,
                     max_features=24, max_hypotheses=50000, max_examples=10000):
    """Keep one minimum-training-error candidate for each literal complexity.

    The family contains conjunctions with up to max_required positive literals
    and zero or one negative literal, plus constant false. No test labels are
    accepted by this API. All later model selection must use a separate split.
    """
    rows = examples(rows, max_examples=max_examples)
    if isinstance(feature_names, str):
        raise ValueError("feature universe must be a collection of names")
    names = tuple(feature_names)
    if (not names or any(not isinstance(f, str) or not f for f in names)
            or type(max_features) is not int or max_features < 1
            or type(max_hypotheses) is not int or max_hypotheses < 1
            or type(max_required) is not int or type(max_forbidden) is not int):
        raise ValueError("invalid feature universe or signed-conjunction limits")
    names = tuple(sorted(set(names)))
    if (len(names) > max_features or not 0 <= max_required <= len(names)
            or max_forbidden not in (0, 1)):
        raise ValueError("invalid feature universe or signed-conjunction limits")
    if any(not features <= set(names) for features, _ in rows):
        raise ValueError("training features exceed the declared universe")
    count = 1 + sum(math.comb(len(names), p) for p in range(max_required+1))
    if max_forbidden:
        count += len(names)*sum(math.comb(len(names)-1, p) for p in range(min(max_required, len(names)-1)+1))
    if count > max_hypotheses:
        raise ValueError(f"hypothesis cap exceeded: {count} > {max_hypotheses}")
    full = (1 << len(rows))-1
    labels = sum(1 << i for i, (_, label) in enumerate(rows) if label)
    cover = {name: sum(1 << i for i, (features, _) in enumerate(rows) if name in features) for name in names}
    best = {}

    def consider(model, predicted):
        errors = (predicted ^ labels).bit_count()
        rank = errors, model.order_key()
        prior = best.get(model.complexity)
        if prior is None or rank < prior[0]:
            best[model.complexity] = rank, model

    consider(Conjunction(constant_false=True), 0)
    enumerated = 1
    for size in range(max_required+1):
        for required in itertools.combinations(names, size):
            mask = full
            for feature in required:
                mask &= cover[feature]
            consider(Conjunction(required), mask)
            enumerated += 1
            if max_forbidden:
                for forbidden in names:
                    if forbidden not in required:
                        consider(Conjunction(required, (forbidden,)), mask & (full ^ cover[forbidden]))
                        enumerated += 1
    if enumerated != count:
        raise AssertionError("hypothesis enumeration differs from declared resource count")
    candidates = [{"model": model, "training_errors": rank[0], "training_examples": len(rows)}
                  for _, (rank, model) in sorted(best.items())]
    return candidates, {"features": len(names), "max_required": max_required,
                        "max_forbidden": max_forbidden, "hypotheses_evaluated": count,
                        "max_hypotheses": max_hypotheses, "selection_candidates": len(candidates)}


def select_candidate(candidates, calibration):
    """Choose on independent calibration errors, then lower complexity on ties."""
    calibration = examples(calibration)
    if not candidates:
        raise ValueError("trained candidates required")
    scores = []
    for candidate in candidates:
        model = candidate["model"]
        errors = sum(model.predict(features) != label for features, label in calibration)
        scores.append((errors, model.order_key(), model, candidate))
    winner = min(scores, key=lambda row: row[:2])
    report = [{**candidate["model"].to_dict(), "training_errors": candidate["training_errors"],
               "calibration_errors": errors, "calibration_examples": len(calibration)}
              for errors, _, _, candidate in scores]
    return winner[2], report


def prediction_confidence(model, calibration):
    """Empirical correctness by predicted class, learned before risk calibration.

    This is a fallible score, not a certificate. A fresh split must validate any
    threshold chosen using it. Unseen prediction classes receive confidence zero.
    """
    rows = examples(calibration)
    groups = {False: [0, 0], True: [0, 0]}
    for features, label in rows:
        predicted = model.predict(features)
        groups[predicted][0] += predicted == label
        groups[predicted][1] += 1
    return {predicted: correct/count if count else 0. for predicted, (correct, count) in groups.items()}
