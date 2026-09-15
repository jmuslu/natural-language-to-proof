"""abstain.py — the discrete structure stays faithful by REFUSING to ingest noise.

The caveat that reframes "grok under noisy labels": a discrete invariant is a PROJECTION,
and its value is its faithfulness. Softening it to absorb every noisy/soft label loses
exactly what makes it worth having. So the right move under label noise is not to soften —
it is to ABSTAIN: ingest a label into the discrete invariant only when it is externally
well-checked; leave the rest to the soft layer. Selectivity keeps the projection faithful.

This is the calibration-NULL discipline (don't impute from what isn't checked) and the
belief-gate, applied to concept induction. Demonstrated: with flipped low-confidence
labels, the naive grokker (ingests all) has its invariant CORRUPTED and its generalization
collapses; the abstaining grokker (ingests only high-confidence) keeps the exact invariant
and generalizes — on FEWER labels. Faithfulness > quantity. Dependency-free.
"""
from __future__ import annotations

import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from grok import Grokker, sample_signal, is_real, CORE, KILLER


def labeled_stream(rng, n, p_noise=0.25):
    """Each example carries a CONFIDENCE reflecting external-check quality. A noisy label
    is FLIPPED and comes with low confidence (the oracle was unsure); clean labels are
    high-confidence. (In the real system the confidence is the certificate's, not a tag we
    peek at — here it stands in for how well-checked the outcome is.)"""
    out = []
    for _ in range(n):
        f, y, _ = sample_signal(rng, "market")
        if rng.random() < p_noise:
            out.append((f, not y, 0.30))       # flipped + low confidence
        else:
            out.append((f, y, 0.95))           # clean + high confidence
    return out


def _selftest():
    rng = random.Random(4)
    train = labeled_stream(rng, 1500, p_noise=0.25)
    held = [sample_signal(rng, "market") for _ in range(500)]     # clean held-out
    base = max(sum(y for _, y, _ in held), 500 - sum(y for _, y, _ in held)) / 500

    naive, faithful = Grokker(), Grokker()
    ingested_naive = ingested_faithful = 0
    for f, label, conf in train:
        naive.learn(f, label); ingested_naive += 1
        if conf >= 0.5:                         # ABSTAIN on low-confidence labels
            faithful.learn(f, label); ingested_faithful += 1

    acc_naive = sum(naive.predict(f) == y for f, y, _ in held) / len(held)
    acc_faith = sum(faithful.predict(f) == y for f, y, _ in held) / len(held)

    print(f"base rate {base:.2f}; 25% of labels flipped+low-confidence\n")
    print(f"  naive (ingest all)      : held-out {acc_naive:.2f}   "
          f"invariant R={set(naive.R)} K={set(naive.K)}   [{ingested_naive} ingested]")
    print(f"  faithful (abstain <0.5) : held-out {acc_faith:.2f}   "
          f"invariant R={set(faithful.R)} K={set(faithful.K)}   [{ingested_faithful} ingested]")

    # the abstaining grokker keeps the EXACT invariant and generalizes; the naive one is
    # corrupted by noise and worse — even though it ingested MORE. Faithfulness > quantity.
    assert faithful.R == CORE and faithful.K == frozenset({KILLER}), (faithful.R, faithful.K)
    assert acc_faith > acc_naive + 0.1, (acc_faith, acc_naive)
    assert ingested_faithful < ingested_naive         # it deliberately saw fewer
    corrupted = (naive.R != CORE) or (naive.K != frozenset({KILLER}))
    print(f"\n  naive invariant corrupted by noise? {corrupted}")
    assert corrupted

    print("\nabstain selftest: PASS — refusing to ingest low-confidence labels kept the "
          "discrete invariant faithful and generalizing on FEWER labels, while ingesting "
          "everything corrupted it. The discreteness + selectivity is the value; not "
          "everything should be ingested, by design.")


if __name__ == "__main__":
    _selftest()
