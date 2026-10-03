"""120 ProntoQA items (5-hop, fictional ontology; Logic-LM release of the ProntoQA dev set), 60 True / 60 False.
Source: ~/data/prontoqa/logiclm_dev.json (github.com/teacherpeterpan/Logic-LLM data/ProntoQA/dev.json)."""
import json, os, sys, collections
BASE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(BASE, '..', 'common'))
from sampling import draw, write
PFX = 'Is the following statement true or false? '
pool = collections.defaultdict(list)
for d in json.load(open(os.path.expanduser('~/data/prontoqa/logiclm_dev.json'))):
    assert d['question'].startswith(PFX)
    hops = (len(d['explanation']) - 1) // 2
    lab = {'A': 'True', 'B': 'False'}[d['answer']]
    pool[(str(hops), lab)].append(dict(id=d['id'], context=d['context'], statement=d['question'][len(PFX):],
                                       label=lab, stratum=str(hops), explanation=d['explanation']))
out = draw(pool, {('5', 'True'): 30, ('5', 'False'): 30})
write(out, os.path.join(BASE, 'sample.jsonl'))
print(len(out), collections.Counter((x['stratum'], x['label']) for x in out), collections.Counter(x['label'] for x in out[:60]))
