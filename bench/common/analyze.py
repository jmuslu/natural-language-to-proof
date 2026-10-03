"""Score results for one benchmark (re-parses 'raw' with scoring.py, so parser changes apply retroactively).
usage: python3 analyze.py <bench> [--md] [-v]
--md prints README table rows; -v prints wrong answers."""
import json, glob, os, math, sys, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import spec as SP
from scoring import strict_parse, lenient_parse

ORDER = ['gpt-5.5__high', 'gemini-3.5-flash__high', 'gemma-4-31b-it__minimal', 'gemini-3.1-flash-lite__budget0', 'gemma-4-26b-a4b-it__minimal']

def wilson(k, n, z=1.96):
    if n == 0: return (float('nan'),) * 2
    p = k / n; d = 1 + z * z / n
    c = (p + z * z / (2 * n)) / d; h = z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n)) / d
    return max(0, c - h), min(1, c + h)

def load(f):
    recs = {}
    for r in map(json.loads, open(f)):
        if r['id'] in recs and 'error' not in recs[r['id']] and 'error' in r: continue
        recs[r['id']] = r
    return [r for r in recs.values() if 'error' not in r]

def tag_of(f):
    b = os.path.basename(f)[len('results_'):-len('.jsonl')]
    return b[len('gemini_'):] if b.startswith('gemini_') else b

def score(S, bench):
    out = {}
    for f in glob.glob(os.path.join(S.DIR, 'results', 'results_*.jsonl')):
        rs = load(f)
        for r in rs:
            r['p_strict'] = strict_parse(r['raw'], S.LABELS); r['p_len'] = lenient_parse(r['raw'], S.LABELS)
        out[tag_of(f)] = rs
    return out

def summary(S, rs, key):
    n = len(rs); k = sum(r[key] == r['label'] for r in rs)
    lo, hi = wilson(k, n)
    by_s = {s: (sum(r[key] == r['label'] for r in rs if r['stratum'] == s), sum(r['stratum'] == s for r in rs)) for s in S.STRATA}
    by_l = {l: (sum(r[key] == r['label'] for r in rs if r['label'] == l), sum(r['label'] == l for r in rs)) for l in S.LABELS}
    inv = sum(r[key] is None for r in rs)
    return dict(n=n, k=k, lo=lo, hi=hi, by_s=by_s, by_l=by_l, inv=inv)

def md_rows(S, R, total):
    rows = []
    for tag in ORDER + sorted(set(R) - set(ORDER)):
        if tag not in R: continue
        rs = R[tag]
        for key, name in (('p_strict', tag.replace('__', ' / ')), ('p_len', '(with leniency)')):
            s = summary(S, rs, key)
            if not s['n']: continue
            status = '' if key == 'p_len' else (f" ({s['n']}/{total})" if s['n'] < total else '')
            cells = [f"{name}{status}", str(s['n']),
                     f"{s['k']}/{s['n']} = {100*s['k']/s['n']:.1f}% [{100*s['lo']:.0f}, {100*s['hi']:.0f}]"]
            cells += [f"{a}/{b}" if b else '–' for a, b in s['by_s'].values()]
            cells += [f"{a}/{b}" if b else '–' for a, b in s['by_l'].values()]
            cells.append(str(s['inv']))
            rows.append('| ' + ' | '.join(cells) + ' |')
    hdr = ['model / config', 'n', 'overall [95% CI]'] + [S.STRATUM_NAME + ' ' + s for s in S.STRATA] + list(S.LABELS) + ['invalid']
    return '\n'.join(['| ' + ' | '.join(hdr) + ' |', '|' + '---|' * len(hdr)] + rows)

if __name__ == '__main__':
    bench = sys.argv[1]; S = SP.load(bench)
    total = sum(1 for _ in open(os.path.join(S.DIR, 'sample.jsonl')))
    R = score(S, bench)
    if '--md' in sys.argv or '--write' in sys.argv:
        tbl = md_rows(S, R, total)
        if '--write' in sys.argv:  # replace the table between markers in bench/<bench>/README.md
            rp = os.path.join(S.DIR, 'README.md'); txt = open(rp).read()
            a, b = txt.index('<!-- table -->') + len('<!-- table -->'), txt.index('<!-- /table -->')
            open(rp, 'w').write(txt[:a] + '\n' + tbl + '\n' + txt[b:])
        print(tbl); sys.exit()
    if '--json' in sys.argv:
        print(json.dumps({t: {k: summary(S, rs, k) for k in ('p_strict', 'p_len')} for t, rs in R.items()})); sys.exit()
    for tag, rs in sorted(R.items()):
        print(f'\n=== {bench} {tag} (n={len(rs)}) ===')
        for key in ('p_strict', 'p_len'):
            s = summary(S, rs, key)
            print(f"  {key:8s} {s['k']}/{s['n']} = {100*s['k']/max(1,s['n']):.1f}% [{100*s['lo']:.1f}, {100*s['hi']:.1f}]  "
                  f"strata {s['by_s']}  labels {s['by_l']}  invalid {s['inv']}")
        print('  confusion strict:', dict(collections.Counter(f"{r['label']}->{r['p_strict']}" for r in rs)))
        print('  confusion lenient:', dict(collections.Counter(f"{r['label']}->{r['p_len']}" for r in rs)))
        long_ = [r for r in rs if len(r['raw'].strip()) > 20]
        if long_:
            short = [r for r in rs if len(r['raw'].strip()) <= 20]
            print(f"  verbose replies (>20 chars): {len(long_)}/{len(rs)}; lenient acc verbose "
                  f"{sum(r['p_len']==r['label'] for r in long_)}/{len(long_)}, terse {sum(r['p_len']==r['label'] for r in short)}/{len(short)}")
        bad = [r['raw'][:80].replace('\n', ' ') for r in rs if r['p_strict'] is None][:5]
        if bad: print('  invalid raw:', bad)
        th = [((r.get('usage') or {}).get('thoughtsTokenCount') or (r.get('usage') or {}).get('reasoning_output_tokens') or 0) for r in rs]
        if any(th): print(f'  reasoning tokens: mean {sum(th)/len(th):.0f} max {max(th)}')
        if '-v' in sys.argv:
            for r in rs:
                if r['p_len'] != r['label']: print(f"   WRONG {r['id']} {r['stratum']} gold={r['label']} strict={r['p_strict']} len={r['p_len']} raw={r['raw'][:100]!r}")
