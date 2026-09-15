"""grok.py — the brain GENERALIZES the invariant instead of memorizing the target.

The risk in everything before this file is fitting the Futures-Reversal target ever more
precisely. Intelligence is the opposite: from a handful of grounded/refused signals,
distill the domain-agnostic INVARIANT that makes a signal real — the structural
mechanism-signature — and apply it to signals never seen, in domains never trained on.

We make that measurable. Signals are described by DOMAIN-AGNOSTIC structural features
(does it rest on a weak-predictor residual? is it regime-conditional? out-of-sample
robust? no-lookahead? does it carry an overfit marker?). A hidden invariant decides
reality:  real  iff  CORE ⊆ features  and  overfit_marker ∉ features.  The domain tag
(market / neuromorphic) is a CONFOUND — irrelevant to reality — that a memorizer will lean
on and a grokker must learn to ignore.

  * MEMORIZER : exact feature-set lookup; on a novel signal it can only guess -> stuck at
                base rate on held-out (it learned WHAT, not WHY).
  * GROKKER   : induces (required R, forbidden K) from the examples (necessity by the
                ablation logic: a feature is required iff its absence flips reality) and
                predicts by the invariant -> generalizes, and TRANSFERS across domains.

The grokking curve (held-out accuracy vs #examples) shows the memorization->generalization
transition; the transfer test (train on market, test on neuromorphic) shows it learned the
why. The extracted (R,K) IS a learned method-class for multihop.propose. Dependency-free.
Run: python3 grok.py
"""
from __future__ import annotations

import random

CORE = frozenset({"weak_predictor_residual", "out_of_sample_robust", "no_lookahead"})
KILLER = "overfit_marker"
SEMANTIC = ["regime_conditional", "cross_sectional_specificity"]     # present sometimes, irrelevant
DISTRACTORS = [f"d{i}" for i in range(14)]                            # combinatorial noise
FEATURES = list(CORE) + [KILLER] + SEMANTIC + DISTRACTORS            # ~2^20 configs => novel at test


def is_real(features: frozenset) -> bool:
    """The hidden, domain-agnostic invariant — depends ONLY on CORE and the killer.
    Semantic extras and distractors are irrelevant (the brain must learn to ignore them)."""
    return CORE <= features and KILLER not in features


def sample_signal(rng, domain):
    """A signal's structural features over a large space, so exact configs almost never
    repeat (memorization must fail on held-out). The domain shifts only the distractor
    distribution — a confound — never what makes a signal real."""
    feats = set()
    for f in CORE:
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
    """Induces the invariant. R = features present in ALL positives (necessary). K =
    features common to every R-satisfying negative, minus R (forbidden / killer): a
    negative that already meets the requirements must be failing for a forbidden reason —
    the mechanism-necessity (ablation) test lifted into concept space."""
    def __init__(self):
        self.R = frozenset(FEATURES)     # start maximally strict; shrinks with positives
        self.pos_seen = 0
        self.neg_satisfying = None       # running intersection of (neg.features)

    def learn(self, feats, label):
        if label:
            self.R = self.R & feats if self.pos_seen else frozenset(feats)
            self.pos_seen += 1
        else:
            # only negatives that meet the (current) requirement inform the killer set
            if self.R <= feats:
                self.neg_satisfying = feats if self.neg_satisfying is None else (self.neg_satisfying & feats)

    @property
    def K(self):
        return (self.neg_satisfying - self.R) if self.neg_satisfying is not None else frozenset()

    def predict(self, feats):
        return (self.R <= feats) and not (self.K & feats)


def accuracy(model, test):
    return sum(model.predict(f) == y for f, y, _ in test) / len(test)


def _selftest():
    rng = random.Random(11)
    # fixed held-out sets
    held_market = [sample_signal(rng, "market") for _ in range(400)]
    held_neuro = [sample_signal(rng, "neuromorphic") for _ in range(400)]
    base_rate = max(sum(y for _, y, _ in held_market), len(held_market) - sum(y for _, y, _ in held_market)) / len(held_market)

    # stream of MARKET training examples; measure the grokking curve on held-out MARKET.
    train = [sample_signal(rng, "market") for _ in range(1200)]
    mem, grok = Memorizer(), Grokker()
    curve = []
    checkpoints = [10, 25, 50, 100, 200, 400, 800, 1200]
    for i, (f, y, _) in enumerate(train, 1):
        mem.learn(f, y); grok.learn(f, y)
        if i in checkpoints:
            curve.append((i, accuracy(grok, held_market), accuracy(mem, held_market)))

    print(f"base rate (guess-majority) on held-out: {base_rate:.2f}\n")
    print(f"{'#examples':>9}  {'grokker':>8}  {'memorizer':>9}")
    for n, g, m in curve:
        bar = "█" * int(g * 30)
        print(f"{n:>9}  {g:>8.2f}  {m:>9.2f}  {bar}")

    final_g, final_m = curve[-1][1], curve[-1][2]
    print(f"\nextracted invariant:  R (required) = {set(grok.R)}")
    print(f"                      K (forbidden) = {set(grok.K)}")

    # transfer: the model trained ONLY on market, evaluated on NEUROMORPHIC (never seen).
    tg, tm = accuracy(grok, held_neuro), accuracy(mem, held_neuro)
    print(f"\nTRANSFER to neuromorphic (trained on market only): grokker {tg:.2f}  memorizer {tm:.2f}")

    # CHECKS: the grokker generalizes (held-out high, from ~base-rate start) and TRANSFERS
    # across domain; the memorizer stays near base rate on held-out and does not transfer;
    # and the grokker recovered the EXACT invariant (learned the why, not the target).
    assert curve[0][1] <= final_g and final_g > 0.95, curve
    assert final_g > final_m + 0.2, (final_g, final_m)
    assert tg > 0.95 and tg > tm + 0.2, (tg, tm)
    assert grok.R == CORE and grok.K == frozenset({KILLER}), (grok.R, grok.K)

    print("\ngrok selftest: PASS — the brain distilled the domain-agnostic invariant "
          "(CORE ∧ ¬overfit) from examples, generalized to held-out signals, and TRANSFERRED "
          "it to a domain it never trained on. The extracted (R,K) is a learned method-class "
          "for multihop.propose — generalization, not memorization of the target.")


if __name__ == "__main__":
    _selftest()
