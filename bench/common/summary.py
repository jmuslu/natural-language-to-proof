"""Cross-benchmark table for bench/README.md: strict accuracy (lenient in parentheses), n in brackets when partial.
usage: python3 summary.py [--write]"""
import os, sys, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import spec as SP, analyze as A
import importlib.util, glob
BENCHES = ['prontoqa', 'folio', 'proverqa']
# ProofWriter predates common/ and keeps its own scorer; load it by path (bench/proofwriter/scoring.py).
_spec = importlib.util.spec_from_file_location('pw_scoring', os.path.join(SP.ROOT, 'proofwriter', 'scoring.py'))
PW = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(PW)

def proofwriter_cell(tag):
    f = glob.glob(os.path.join(SP.ROOT, 'proofwriter', 'results', f'results_{tag}.jsonl')) + \
        glob.glob(os.path.join(SP.ROOT, 'proofwriter', 'results', f'results_gemini_{tag}.jsonl'))
    if not f: return '–'
    rs = PW.load(f[0]); lr, _, _ = PW.rescore(rs); n = len(rs)
    if not n: return '–'
    return f"{100*sum(r['correct'] for r in rs)/n:.1f}% ({100*sum(r['correct'] for r in lr)/n:.1f}%) n={n}"

rows = []
hdr = ['model / config', 'proofwriter'] + BENCHES
data = {b: A.score(SP.load(b), b) for b in BENCHES}
for tag in A.ORDER:
    cells = [tag.replace('__', ' / '), proofwriter_cell(tag)]
    for b in BENCHES:
        S = SP.load(b); rs = data[b].get(tag, [])
        if not rs: cells.append('–'); continue
        st, le = A.summary(S, rs, 'p_strict'), A.summary(S, rs, 'p_len')
        cells.append(f"{100*st['k']/st['n']:.1f}% ({100*le['k']/le['n']:.1f}%) n={st['n']}")
    rows.append('| ' + ' | '.join(cells) + ' |')
tbl = '\n'.join(['| ' + ' | '.join(hdr) + ' |', '|' + '---|' * len(hdr)] + rows)
if '--write' in sys.argv:
    rp = os.path.join(SP.ROOT, 'README.md'); txt = open(rp).read()
    a, b = txt.index('<!-- table -->') + len('<!-- table -->'), txt.index('<!-- /table -->')
    open(rp, 'w').write(txt[:a] + '\n' + tbl + '\n' + txt[b:])
print(tbl)
