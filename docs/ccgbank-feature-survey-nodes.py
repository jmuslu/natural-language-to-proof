#!/usr/bin/env python3
"""Layer 1 survey, part 2 (read-only): atoms/features on INTERNAL tree nodes.

Leaf categories are the lexicon (part 1). But a full-derivation ingestion pass
(Layer 2's test-case generator) also traverses internal `(<T CAT head n> ...)`
nodes, which introduce categories -- notably the [conj] feature -- that never
appear at a leaf. This pass inventories those so the Cat design covers the
whole tree, not just the lexicon.
"""
import os, re, collections

AUTO = os.path.expanduser("~/ccgbank/ccgbank_1_1/data/AUTO")
NODE = re.compile(r"\(<T\s+(\S+)\s+\d+\s+\d+>")
ATOM = re.compile(r"([A-Za-z]+)(\[[a-z]+\])?")

atom_feats = collections.defaultdict(collections.Counter)
node_cat_counts = collections.Counter()
total_nodes = 0

for sec in sorted(os.listdir(AUTO)):
    secdir = os.path.join(AUTO, sec)
    if not os.path.isdir(secdir):
        continue
    for fn in sorted(os.listdir(secdir)):
        if not fn.endswith(".auto"):
            continue
        with open(os.path.join(secdir, fn), encoding="latin-1") as f:
            for line in f:
                if not line.startswith("("):
                    continue
                for m in NODE.finditer(line):
                    cat = m.group(1)
                    total_nodes += 1
                    node_cat_counts[cat] += 1
                    for am in ATOM.finditer(cat):
                        base, feat = am.group(1), am.group(2)
                        atom_feats[base][feat if feat else "(none)"] += 1

print(f"# total internal nodes : {total_nodes}")
print(f"# distinct node cats    : {len(node_cat_counts)}")
print()
print("=== ATOMS on internal nodes and their feature brackets ===")
atom_totals = {a: sum(c.values()) for a, c in atom_feats.items()}
for atom in sorted(atom_totals, key=lambda a: -atom_totals[a]):
    parts = ", ".join(f"{f}:{c}" for f, c in atom_feats[atom].most_common())
    print(f"  {atom:5s} total={atom_totals[atom]:>8}  feats: {parts}")
print()
print("=== [conj]-bearing node categories (top 15) ===")
for cat, cnt in node_cat_counts.most_common():
    if "[conj]" in cat:
        print(f"  {cnt:>7}  {cat}")
