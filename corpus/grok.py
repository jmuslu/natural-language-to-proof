"""Order-invariant induction of a restricted Boolean concept from labeled examples.

Required/forbidden feature sets describe a hypothesis, not causal necessity or
external truth. The example worlds share a stipulated conjunction target; changing
distractor frequency measures only that covariate shift. Contradictory labels or
targets outside this hypothesis class can leave the fitted concept inconsistent.
"""
from __future__ import annotations

import random

CORE = frozenset({"weak_predictor_residual", "out_of_sample_robust", "no_lookahead"})
KILLER = "overfit_marker"
SEMANTIC = ["regime_conditional", "cross_sectional_specificity"]     # present sometimes, irrelevant
DISTRACTORS = [f"d{i}" for i in range(14)]                            # combinatorial noise
FEATURES = sorted(CORE) + [KILLER] + SEMANTIC + DISTRACTORS


def is_real(features: frozenset) -> bool:
    """The hidden, domain-agnostic invariant — depends ONLY on CORE and the killer.
    Semantic extras and distractors are irrelevant (the brain must learn to ignore them)."""
    return CORE <= features and KILLER not in features


def sample_signal(rng, domain):
    """A signal's structural features over a large space, so exact configs almost never
    repeat (memorization must fail on held-out). The domain shifts only the distractor
    distribution — a confound — never what makes a signal real."""
    feats = set()
    for f in sorted(CORE):
        if rng.random() < 0.7:
            feats.add(f)
    if rng.random() < 0.15:
        feats.add(KILLER)
    for f in SEMANTIC:
        if rng.random() < 0.4:
            feats.add(f)
    pd = 0.4 if domain == "market" else 0.6     # domain shifts the confound only
    for f in DISTRACTORS:
        if rng.random() < pd:
            feats.add(f)
    ff = frozenset(feats)
    return ff, is_real(ff), domain


class Memorizer:
    def __init__(self): self.table = {}
    def learn(self, feats, label): self.table[feats] = label
    def predict(self, feats):
        return self.table.get(feats, False)      # novel -> can only guess (majority=not-real)


class Grokker:
    """Fit required features and a conservative common forbidden-feature set.

    All negatives are retained: a negative rejected by an early, stricter R may
    become relevant after another positive shrinks R. K also excludes any feature
    observed in a positive. This is a limited hypothesis class, not a general
    Boolean learner; inspect consistent before interpreting a noisy fit.
    """
    def __init__(self):
        self.R = frozenset(FEATURES)     # start maximally strict; shrinks with positives
        self.pos_seen = 0
        self.positives = set()
        self.negatives = set()

    def learn(self, feats, label):
        feats = frozenset(feats)
        if type(label) is not bool or any(not isinstance(f, str) for f in feats):
            raise ValueError("string features and an externally supplied Boolean label required")
        if label:
            self.R = self.R & feats if self.pos_seen else frozenset(feats)
            self.pos_seen += 1
            self.positives.add(feats)
        else:
            self.negatives.add(feats)

    @property
    def neg_satisfying(self):
        eligible = [f for f in self.negatives if self.R <= f]
        return frozenset.intersection(*eligible) if eligible else None

    @property
    def K(self):
        common = self.neg_satisfying
        positive_features = frozenset().union(*self.positives)
        return common - self.R - positive_features if common is not None else frozenset()

    def predict(self, feats):
        return bool(self.pos_seen and (self.R <= feats) and not (self.K & feats))

    @property
    def consistent(self):
        return all(self.predict(f) for f in self.positives) and not any(self.predict(f) for f in self.negatives)


def accuracy(model, test):
    return sum(model.predict(f) == y for f, y, _ in test) / len(test)


def _selftest():
    import json
    from adaptive_evaluation import concept_experiment
    print(json.dumps(concept_experiment(), indent=2))


if __name__ == "__main__":
    _selftest()
