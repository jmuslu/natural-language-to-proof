"""Stratified, label-balanced sampling with a fixed seed, ordered so the first half (e.g. items 1-60) is itself
balanced by stratum x label: runs that stop at n=60 under quota still see a stratified sample."""
import random, json, os

SEED = 20261003

def draw(pool, half_alloc, seed=SEED):
    """pool: {(stratum,label): [items]}; half_alloc: {(stratum,label): count per half}. Returns ordered list."""
    rng = random.Random(seed)
    halves = [[], []]
    for cell in sorted(half_alloc):
        c = pool[cell][:]; rng.shuffle(c)
        k = half_alloc[cell]
        assert len(c) >= 2 * k, (cell, len(c), 2 * k)
        halves[0] += c[:k]; halves[1] += c[k:2 * k]
    for h in halves: rng.shuffle(h)
    return halves[0] + halves[1]

def write(out, path):
    with open(path, 'w') as f:
        for x in out: f.write(json.dumps(x) + '\n')
