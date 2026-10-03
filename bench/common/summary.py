"""Cross-benchmark table for bench/README.md: strict accuracy (lenient in parentheses), n in brackets when partial.
usage: python3 summary.py [--write]"""
import os, sys, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import spec as SP, analyze as A
BENCHES = ['prontoqa', 'folio', 'proverqa']
rows = []
hdr = ['model / config'] + BENCHES
data = {b: A.score(SP.load(b), b) for b in BENCHES}
for tag in A.ORDER:
    cells = [tag.replace('__', ' / ')]
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
