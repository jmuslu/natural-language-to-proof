import json, glob, os, math, statistics, collections, sys
BASE = os.path.dirname(os.path.abspath(__file__))
S = {x['id']: x for x in map(json.loads, open(os.path.join(BASE, 'sample.jsonl')))}

def wilson(k, n, z=1.96):
    if n == 0: return (float('nan'),) * 2
    p = k / n; d = 1 + z * z / n
    c = (p + z * z / (2 * n)) / d; h = z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n)) / d
    return max(0, c - h), min(1, c + h)

def fmt(k, n):
    lo, hi = wilson(k, n)
    return f"{k}/{n} = {100*k/n:5.1f}% [{100*lo:4.1f}, {100*hi:4.1f}]" if n else "-"

def load(f):
    recs = {}
    for r in map(json.loads, open(f)):
        if r['id'] in recs and 'error' not in recs[r['id']] and 'error' in r: continue
        recs[r['id']] = r
    return recs

for f in sorted(glob.glob(os.path.join(BASE, 'results', 'results_*.jsonl'))):
    R = load(f); rs = list(R.values())
    ok = [r for r in rs if 'error' not in r]
    print(f"\n=== {os.path.basename(f)}  (records {len(rs)}, api-errors {len(rs)-len(ok)}) ===")
    print("overall      ", fmt(sum(r['correct'] for r in ok), len(ok)))
    for d in range(6):
        g = [r for r in ok if r['depth'] == d]; print(f"depth {d}      ", fmt(sum(r['correct'] for r in g), len(g)))
    g = [r for r in ok if r['depth'] >= 3]; print("depth>=3     ", fmt(sum(r['correct'] for r in g), len(g)))
    for lab in ('True', 'False', 'Unknown'):
        g = [r for r in ok if r['label'] == lab]; print(f"label {lab:8s}", fmt(sum(r['correct'] for r in g), len(g)))
    cm = collections.Counter((r['label'], r['pred']) for r in ok)
    print("confusion (gold->pred):", {f"{a}->{b}": c for (a, b), c in sorted(cm.items(), key=str)})
    print("invalid answers:", sum(r['pred'] is None for r in ok), [r['raw'][:60] for r in ok if r['pred'] is None][:5])
    print("tool items total:", sum(r.get('tool_items', 0) for r in ok), " records w/ tools:", sum(1 for r in ok if r.get('tool_items')))
    print("retries (attempts>1):", sum(1 for r in ok if r['attempts'] > 1))
    lat = [r['latency'] for r in ok if r['latency']]
    if lat: print(f"latency s: median {statistics.median(lat):.1f}  p90 {sorted(lat)[int(.9*len(lat))-1]:.1f}  max {max(lat):.1f}")
    U = [r['usage'] for r in ok if r['usage']]
    if U:
        for k in ('input_tokens', 'cached_input_tokens', 'output_tokens', 'reasoning_output_tokens'):
            v = [u.get(k, 0) for u in U]
            print(f"  {k:24s} median {statistics.median(v):8.0f}  mean {statistics.mean(v):8.0f}  total {sum(v)}")
        for d in range(6):
            v = [r['usage'].get('reasoning_output_tokens', 0) for r in ok if r['usage'] and r['depth'] == d]
            if v: print(f"  reasoning tok depth {d}: median {statistics.median(v):.0f}")
    if '-v' in sys.argv:
        fails = [r for r in ok if not r['correct'] and r['depth'] >= 3]
        for r in fails:
            x = S[r['id']]
            print(f"\n  FAIL {r['id']} depth={x['depth']} gold={x['label']} pred={r['pred']}\n   Q: {x['question']}\n   T: {x['theory']}")
