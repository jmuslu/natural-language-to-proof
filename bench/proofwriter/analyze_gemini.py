import json, glob, os, math, statistics, sys
BASE = os.path.dirname(os.path.abspath(__file__))
SAMPLE = {x['id']: x for x in map(json.loads, open(os.path.join(BASE, 'sample.jsonl')))}
LABELS = ('True', 'False', 'Unknown')

def wilson(k, n, z=1.96):
    if n == 0: return (float('nan'),) * 2
    p = k / n; d = 1 + z * z / n
    c = (p + z * z / (2 * n)) / d; h = z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n)) / d
    return max(0, c - h), min(1, c + h)

def fmt(k, n):
    if n == 0: return '   -'
    lo, hi = wilson(k, n)
    return f'{k}/{n}={k/n:.0%} [{lo:.0%},{hi:.0%}]'

def load(path):
    rows = {}
    for r in map(json.loads, open(path)):
        if 'error' in r and r['id'] in rows: continue
        rows[r['id']] = r  # last non-error row wins
    return [r for r in rows.values() if 'error' not in r], [r for r in rows.values() if 'error' in r]

def report(path, small):
    rs, errs = load(path)
    name = os.path.basename(path)[len('results_gemini_'):-len('.jsonl')]
    n = len(rs); k = sum(r['correct'] for r in rs)
    inv = sum(r['pred'] is None for r in rs)
    print(f'\n=== {name}  (answered {n}/120; API-error rows {len(errs)})' + ('  PARTIAL' if n < 120 else ''))
    if rs: print('config:', json.dumps(rs[0].get('generation_config')), '| modelVersion:', rs[0].get('model_version'))
    print(f'overall: {fmt(k, n)}   invalid: {inv}')
    print('by depth (n=20 each when complete; Wilson CIs are wide):')
    for d in range(6):
        s = [r for r in rs if r['depth'] == d]
        print(f'  d{d}: {fmt(sum(r["correct"] for r in s), len(s))}')
    print('by label:')
    for L in LABELS:
        s = [r for r in rs if r['label'] == L]
        print(f'  {L:8s}: {fmt(sum(r["correct"] for r in s), len(s))}')
    lat = [r['latency'] for r in rs if r['latency'] is not None]
    if lat: print(f'median latency: {statistics.median(lat):.2f}s')
    tok = lambda f: [(r.get('usage') or {}).get(f) or 0 for r in rs]
    for f in ('promptTokenCount', 'candidatesTokenCount', 'thoughtsTokenCount', 'totalTokenCount'):
        v = tok(f)
        if v: print(f'  {f}: mean {statistics.mean(v):.0f}  median {statistics.median(v):.0f}  sum {sum(v)}')
    if small:
        print('confusion (rows=gold, cols=pred):')
        print('            ' + ''.join(f'{c:>9s}' for c in LABELS + ('invalid',)))
        for g in LABELS:
            row = [sum(r['label'] == g and r['pred'] == p for r in rs) for p in LABELS + (None,)]
            print(f'  {g:9s} ' + ''.join(f'{v:9d}' for v in row))
    return rs

if __name__ == '__main__':
    smalls = ('gemma-4-26b', 'flash-lite')
    files = sorted(glob.glob(os.path.join(BASE, 'results', 'results_gemini_*.jsonl')))
    allr = {}
    for p in files:
        allr[p] = report(p, any(s in p for s in smalls))
    nex = int(sys.argv[1]) if len(sys.argv) > 1 else 5
    for p, rs in allr.items():
        if not any(s in p for s in smalls): continue
        fails = [r for r in rs if r['depth'] >= 3 and not r['correct']][:nex]
        print(f'\n--- example failures depth>=3: {os.path.basename(p)}')
        for r in fails:
            x = SAMPLE[r['id']]
            print(f'[{r["id"]} d{r["depth"]}] gold={r["label"]} pred={r["pred"]} raw={r["raw"][:60]!r}')
            print(f'  Q: {x["question"]}')
            print(f'  T: {x["theory"]}')
