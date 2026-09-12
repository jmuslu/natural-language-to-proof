#!/usr/bin/env python3
"""Layer 1 survey (read-only): what feature-annotated categories does CCGbank
actually attest, and at what frequency?

Parses every leaf `(<L CAT modPOS POS word predArgCat>)` across all AUTO
sections. We look at the CAT field (the surface category, not the predarg one).

Emits:
  * total leaves, distinct leaf categories
  * every atomic category token that appears anywhere in the derivations,
    with the set of feature brackets seen on each atom and their counts
  * frequency of bare PP as an atom (the handoff's specific example)
  * top-N distinct leaf categories by frequency
This does NOT change any code. It is the evidence base for deciding what
Cat/Ty must distinguish.
"""
import os, re, sys, collections

AUTO = os.path.expanduser("~/ccgbank/ccgbank_1_1/data/AUTO")

# Leaf token: (<L cat modpos pos word predarg>)
LEAF = re.compile(r"\(<L\s+(\S+)\s+\S+\s+\S+\s+\S+\s+(\S+)>\)")
# An atom is an uppercase category letter run optionally followed by [feat].
# We enumerate atoms inside a (possibly complex) category string by splitting
# on slashes and parens.
ATOM = re.compile(r"([A-Z]+)(\[[a-z]+\])?")

leaf_cat_counts = collections.Counter()   # full surface category -> count
atom_feats = collections.defaultdict(collections.Counter)  # atom -> {feat->count}
total_leaves = 0
files = 0

def atoms_of(catstr):
    # strip slashes/backslashes/parens, then find atom+feat tokens
    for m in ATOM.finditer(catstr):
        base, feat = m.group(1), m.group(2)
        yield base, (feat if feat else "(none)")

for sec in sorted(os.listdir(AUTO)):
    secdir = os.path.join(AUTO, sec)
    if not os.path.isdir(secdir):
        continue
    for fn in sorted(os.listdir(secdir)):
        if not fn.endswith(".auto"):
            continue
        files += 1
        with open(os.path.join(secdir, fn), encoding="latin-1") as f:
            for line in f:
                if not line.startswith("("):
                    continue  # skip ID= header lines
                for m in LEAF.finditer(line):
                    cat = m.group(1)
                    total_leaves += 1
                    leaf_cat_counts[cat] += 1
                    for base, feat in atoms_of(cat):
                        atom_feats[base][feat] += 1

print(f"# files parsed        : {files}")
print(f"# total leaf tokens   : {total_leaves}")
print(f"# distinct leaf cats   : {len(leaf_cat_counts)}")
print()
print("=== ATOMS and their feature brackets (by leaf-occurrence count) ===")
# order atoms by total occurrences
atom_totals = {a: sum(c.values()) for a, c in atom_feats.items()}
for atom in sorted(atom_totals, key=lambda a: -atom_totals[a]):
    feats = atom_feats[atom]
    total = atom_totals[atom]
    parts = ", ".join(f"{feat}:{cnt}" for feat, cnt in feats.most_common())
    print(f"  {atom:4s} total={total:>8}  feats: {parts}")
print()
print("=== TOP 40 distinct leaf categories ===")
for cat, cnt in leaf_cat_counts.most_common(40):
    print(f"  {cnt:>8}  {cat}")
print()
# specific handoff examples
print("=== handoff-named examples: exact-match leaf-category counts ===")
for probe in ["PP", "S[dcl]", "S[adj]", "S[b]", "NP[nb]", "NP[conj]", "N[num]"]:
    print(f"  {probe:10s} exact-leaf-cat count = {leaf_cat_counts.get(probe,0)}")
