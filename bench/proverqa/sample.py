"""120 ProverQA HARD dev items (huggingface.co/datasets/opendatalab/ProverQA dev/hard.json), 40 per label,
stratified by the number of reasoning steps in the gold proof ('conclusion:' count in the 'reasoning' field):
per half, 7/7/6 per label over 3-6 / 7 / 8-9 steps, rotated across labels, so each bucket has 40. Source: ~/data/proverqa/dev/hard.json."""
import json, os, sys, collections
BASE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(BASE, '..', 'common'))
from sampling import draw, write
PFX = 'Based on the above information, is the following statement true, false, or uncertain? '
def bucket(n): return '3-6' if n <= 6 else ('7' if n == 7 else '8-9')
pool = collections.defaultdict(list)
for d in json.load(open(os.path.expanduser('~/data/proverqa/dev/hard.json'))):
    assert d['question'].startswith(PFX)
    steps = d['reasoning'].count('conclusion:'); s = bucket(steps)
    lab = {'A': 'True', 'B': 'False', 'C': 'Uncertain'}[d['answer']]
    pool[(s, lab)].append(dict(id=f"proverqa-hard-{d['id']}", context=d['context'], statement=d['question'][len(PFX):],
                               label=lab, stratum=s, steps=steps, conclusion_fol=d['conclusion_fol']))
rot = [(7, 7, 6), (7, 6, 7), (6, 7, 7)]
half = {}
for i, lab in enumerate(('True', 'False', 'Uncertain')):
    for s, k in zip(('3-6', '7', '8-9'), rot[i]): half[(s, lab)] = k
out = draw(pool, half)
write(out, os.path.join(BASE, 'sample.jsonl'))
print(len(out), sorted(collections.Counter((x['stratum'], x['label']) for x in out).items()), collections.Counter(x['label'] for x in out[:60]))
