"""120 FOLIO validation items (v0.0, github.com/Yale-LILY/FOLIO data/v0.0/folio-validation.jsonl), 40 per label,
stratified by number of premises (FOLIO has no hop annotation): 10 / 14 / 16 per label for 2-4 / 5 / 6-9 premises.
Source: ~/data/folio/folio-validation.jsonl."""
import json, os, sys, collections
BASE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(BASE, '..', 'common'))
from sampling import draw, write
def bucket(n): return '2-4' if n <= 4 else ('5' if n == 5 else '6-9')
pool = collections.defaultdict(list); stories = {}
for i, l in enumerate(open(os.path.expanduser('~/data/folio/folio-validation.jsonl'))):
    d = json.loads(l)
    sid = stories.setdefault(tuple(d['premises']), len(stories))
    s = bucket(len(d['premises']))
    pool[(s, d['label'])].append(dict(id=f'folio-val-{i}', story=sid, context='\n'.join(p.strip() for p in d['premises']),
                                      statement=d['conclusion'].strip(), label=d['label'], stratum=s,
                                      premises_fol=d['premises-FOL'], conclusion_fol=d['conclusion-FOL']))
half = {}
for lab in ('True', 'False', 'Uncertain'):
    half.update({('2-4', lab): 5, ('5', lab): 7, ('6-9', lab): 8})
out = draw(pool, half)
write(out, os.path.join(BASE, 'sample.jsonl'))
print(len(out), sorted(collections.Counter((x['stratum'], x['label']) for x in out).items()),
      collections.Counter(x['label'] for x in out[:60]), 'stories', len({x['story'] for x in out}))
