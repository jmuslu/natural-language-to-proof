#!/usr/bin/env python3
"""Confound-ablation for the adversarial epistemic corpus.

The corpus handoff's central risk for a small hand-picked set: a discrimination
signal can learn to key off an *incidental correlate* of the label (format,
sheer length, writing style) rather than the epistemic property the label is
meant to represent. This tool measures that risk directly, and — deliberately —
does it the way the Layer 3 statistical suite works: a permutation null, so
"format predicts the label" is only reported when the separation exceeds what
random label assignment over the same records would give.

Two things it answers, per confound feature (currently `format` and
`length`):

  1. *Readiness* — are there enough labeled records, balanced across the two
     adversarial buckets, to draw any discrimination conclusion at all?
  2. *Confound separability* — does a trivial classifier using only the confound
     feature separate the buckets better than chance (permutation p-value)? If it
     does, a content-based discrimination result on this corpus is untrustworthy,
     because the confound alone would reproduce it.

It decides no claim's truth and needs no verdicts — it operates on the owner's
labels and the structural confound fields only. Pure standard library.

Usage:
  python3 corpus/confound_check.py                 # over corpus/records
  python3 corpus/confound_check.py --selftest      # synthetic ground-truth checks
"""
import glob
import itertools
import json
import os
import random
import sys

# Map owner label class -> adversarial bucket. 'unlabeled' is held out; 'ambiguous'
# is not a clean bucket assignment and is excluded from the binary confound test
# (kept visible in the readiness report).
BUCKET = {
    "inconsistent": "neg",
    "consistent": "pos",
    "ambiguous": None,      # excluded from binary test, reported separately
    "unlabeled": None,      # held out
}


def load_records(records_dir):
    recs = []
    for f in sorted(glob.glob(os.path.join(records_dir, "*.json"))):
        d = json.load(open(f))
        recs.append({
            "id": d["record_id"],
            "cls": d["owner_label"]["class"],
            "bucket": BUCKET.get(d["owner_label"]["class"]),
            "format": d["format"],
            "length": d["length"]["raw_word_count"],
        })
    return recs


# ---------------------------------------------------------------------------
# Confound separability: can feature f alone separate the buckets?
# ---------------------------------------------------------------------------

def _best_separation(values, labels):
    """Best balanced-accuracy a single feature achieves separating two labels.

    For a categorical feature: the best label-per-category assignment. For a
    numeric feature: the best threshold. Balanced accuracy (mean of per-class
    recall) so class imbalance can't inflate it. Returns a value in [0.5, 1.0].
    """
    pos = [v for v, l in zip(values, labels) if l == "pos"]
    neg = [v for v, l in zip(values, labels) if l == "neg"]
    if not pos or not neg:
        return 0.5
    numeric = all(isinstance(v, (int, float)) for v in values)
    if numeric:
        cuts = sorted(set(values))
        cuts = [(-float("inf"),)] + [((a + b) / 2,) for a, b in zip(cuts, cuts[1:])] + [(float("inf"),)]
        best = 0.5
        for (t,) in cuts:
            for direction in (+1, -1):
                tp = sum(1 for v in pos if (v > t) == (direction == 1))
                tn = sum(1 for v in neg if (v > t) == (direction == -1))
                bal = 0.5 * (tp / len(pos) + tn / len(neg))
                best = max(best, bal)
        return best
    else:
        # categorical: assign each category to whichever bucket it's more common in
        cats = set(values)
        tp = tn = 0
        for c in cats:
            p = sum(1 for v, l in zip(values, labels) if v == c and l == "pos")
            n = sum(1 for v, l in zip(values, labels) if v == c and l == "neg")
            # assign category c to majority bucket
            if p >= n:
                tp += p
            else:
                tn += n
        return 0.5 * (tp / len(pos) + tn / len(neg))


def confound_pvalue(values, labels, n_perm=5000, seed=0):
    """Permutation p-value: how often does a random relabelling separate as well
    as the observed labelling? Low p => the confound really does track the label."""
    observed = _best_separation(values, labels)
    lab = list(labels)
    n = len(lab)
    npos = lab.count("pos")
    if npos == 0 or npos == n:
        return 1.0, observed
    # exact enumeration when small, else sample
    idx = list(range(n))
    rng = random.Random(seed)
    count = 0
    total = 0
    combos = list(itertools.combinations(idx, npos))
    if len(combos) <= n_perm:
        space = combos
    else:
        space = [tuple(rng.sample(idx, npos)) for _ in range(n_perm)]
    for posset in space:
        perm = ["pos" if i in set(posset) else "neg" for i in idx]
        if _best_separation(values, perm) >= observed - 1e-12:
            count += 1
        total += 1
    return count / total, observed


# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------

def analyze(recs, n_perm=5000, seed=0):
    labeled = [r for r in recs if r["bucket"] in ("pos", "neg")]
    out = {
        "n_total": len(recs),
        "n_labeled_binary": len(labeled),
        "n_pos": sum(1 for r in labeled if r["bucket"] == "pos"),
        "n_neg": sum(1 for r in labeled if r["bucket"] == "neg"),
        "n_ambiguous": sum(1 for r in recs if r["cls"] == "ambiguous"),
        "n_unlabeled": sum(1 for r in recs if r["cls"] == "unlabeled"),
        "confounds": {},
        "ready": False,
        "verdict": "",
    }
    labels = [r["bucket"] for r in labeled]
    ready = out["n_pos"] >= 3 and out["n_neg"] >= 3
    out["ready"] = ready
    for feat in ("format", "length"):
        vals = [r[feat] for r in labeled]
        if len(labeled) < 2 or out["n_pos"] == 0 or out["n_neg"] == 0:
            out["confounds"][feat] = {"separation": None, "pvalue": None,
                                      "note": "too few labeled records to test"}
            continue
        p, sep = confound_pvalue(vals, labels, n_perm=n_perm, seed=seed)
        out["confounds"][feat] = {
            "separation_balanced_acc": round(sep, 3),
            "pvalue": round(p, 4),
            "confounded": bool(sep >= 0.99),   # perfectly separable by this feature alone
            "note": ("this feature ALONE separates the buckets" if sep >= 0.99
                     else "partial/none"),
        }
    if not ready:
        out["verdict"] = ("NOT READY: too few labeled records per bucket "
                          f"(pos={out['n_pos']}, neg={out['n_neg']}; need >=3 each) "
                          "for any discrimination result to be more than anecdotal.")
    elif any(c.get("confounded") for c in out["confounds"].values()):
        bad = [f for f, c in out["confounds"].items() if c.get("confounded")]
        out["verdict"] = (f"CONFOUNDED: {bad} alone separate the buckets; a content-based "
                          "discrimination result here is untrustworthy until these are balanced.")
    else:
        out["verdict"] = ("balanced enough on the tested confounds to attempt a "
                          "discrimination result (still validate WHY it discriminates).")
    return out


def selftest():
    """Validate the checker on synthetic ground truth (it must not certify itself)."""
    def rec(i, cls, fmt, length):
        return {"id": str(i), "cls": cls, "bucket": BUCKET.get(cls), "format": fmt, "length": length}

    # A) format perfectly predicts label -> must be flagged confounded (when ready)
    conf = ([rec(i, "consistent", "article", 400 + i) for i in range(4)]
            + [rec(i, "inconsistent", "video_transcript", 400 + i) for i in range(4, 8)])
    a = analyze(conf, n_perm=5000)
    assert a["ready"], a
    assert a["confounds"]["format"]["confounded"], a
    assert a["confounds"]["format"]["pvalue"] <= 0.05, a

    # B) format balanced across labels -> must NOT be flagged confounded
    bal = ([rec(i, "consistent", "article", 400) for i in range(2)]
           + [rec(i, "consistent", "video_transcript", 400) for i in range(2, 4)]
           + [rec(i, "inconsistent", "article", 400) for i in range(4, 6)]
           + [rec(i, "inconsistent", "video_transcript", 400) for i in range(6, 8)])
    b = analyze(bal, n_perm=5000)
    assert b["ready"], b
    assert not b["confounds"]["format"]["confounded"], b

    # C) too few per bucket -> NOT READY
    c = analyze([rec(0, "consistent", "article", 400), rec(1, "inconsistent", "video_transcript", 400)])
    assert not c["ready"], c

    print("confound_check selftest: PASS (flags a real confound, clears a balanced one, "
          "reports NOT READY at tiny n)")


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    if "--selftest" in sys.argv:
        selftest()
        return
    recs = load_records(os.path.join(here, "records"))
    result = analyze(recs)
    print("== Corpus confound-ablation ==")
    print(f"records: {result['n_total']}  (labeled-binary: {result['n_labeled_binary']} "
          f"= pos {result['n_pos']} / neg {result['n_neg']}; "
          f"ambiguous {result['n_ambiguous']}; unlabeled {result['n_unlabeled']})")
    for feat, c in result["confounds"].items():
        print(f"  {feat:8}: {c}")
    print()
    print("VERDICT:", result["verdict"])


if __name__ == "__main__":
    main()
