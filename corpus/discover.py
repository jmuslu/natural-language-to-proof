"""Synthetic template-learning and measurement demonstration.

The feature law is constructed in grok.py. New candidate samples from that law test
generalization within the generator; they do not validate a market mechanism or a
neuromorphic analogy. Measurements below come from explicitly generated responses.
Coherent qualitative checks never manufacture a Sharpe or portfolio estimate.
"""
from __future__ import annotations

import hashlib
import random
import statistics

from grok import Grokker, sample_signal, is_real
from multihop import MethodClass, LegSlot, CandidateApex, belief_chain
from estimand import Leg, colimit


def grok_method(rng, n_train=400) -> tuple:
    """Learn feature requirements from labeled synthetic training examples."""
    learner = Grokker()
    for _ in range(n_train):
        features, label, _ = sample_signal(rng, "market")
        learner.learn(features, label)
    template = tuple(LegSlot(r, "prediction") for r in sorted(learner.R)) + tuple(
        LegSlot(f"no_{k}", "necessity", equivalence_margin=.5) for k in sorted(learner.K))
    return learner, MethodClass("synthetic_feature_law", "same constructed feature law", template)


def measure(candidate_feats: frozenset, R: frozenset, K: frozenset) -> list:
    """Retained-seed Normal response experiments, not a real external oracle.

    Required feature present => mean 3, otherwise 0; forbidden feature present =>
    control mean 3, otherwise 0. Each check gets 128 generated observations with
    sd=1. Sample mean/SE are computed. Control margin .5 is fixed in advance.
    All checks share candidate provenance; feature names do not create replication.
    """
    identifier = hashlib.sha256(repr(sorted(candidate_feats)).encode()).hexdigest()[:16]
    legs = []
    conditions = [(r, "prediction", r in candidate_feats) for r in sorted(R)] + [
        (f"no_{k}", "necessity", k in candidate_feats) for k in sorted(K)]
    for name, kind, condition in conditions:
        seed = int(hashlib.sha256(f"{identifier}:{name}".encode()).hexdigest()[:16], 16)
        rng = random.Random(seed)
        samples = [rng.gauss(3. if condition else 0., 1.) for _ in range(128)]
        legs.append(Leg(name, kind, statistics.mean(samples), statistics.stdev(samples)/(128**.5),
                        frozenset({f"synthetic-candidate:{identifier}"}), n=128,
                        equivalence_margin=.5 if kind == "necessity" else None))
    return legs


def _selftest():
    rng = random.Random(21)
    learner, method = grok_method(rng)
    novel = [(features, label) for features, label, _ in
             (sample_signal(rng, "neuromorphic") for _ in range(300))]
    promising = [(features, label) for features, label in novel if learner.predict(features)]
    correct = sum(label for _, label in promising)
    recall = correct/sum(label for _, label in novel)
    precision = correct/len(promising)
    results = [(features, colimit("candidate", measure(features, learner.R, learner.K)))
               for features, _ in promising]
    coherent = [(features, result) for features, result in results if result.grounded]
    assert recall > .95 and precision > .95
    assert coherent and all(is_real(features) for features, _ in coherent)
    assert all(result.multiplicity == 1 for _, result in coherent)
    _, result = coherent[0]
    candidate = CandidateApex("example", "synthetic law", method.name, method.template,
                              status="coherent-unverified", result=result)
    numerical, note = belief_chain(candidate, None, [])
    assert numerical is None  # no numerical target/estimate was measured by this experiment
    print(f"discover selftest: PASS; {len(novel)} held-out synthetic candidates; "
          f"screen precision={precision:.3f}, recall={recall:.3f}; {len(coherent)} coherent response checks")
    print(note)


if __name__ == "__main__":
    _selftest()
