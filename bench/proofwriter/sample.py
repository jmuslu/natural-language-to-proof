import json, random, collections, os
BASE=os.path.dirname(os.path.abspath(__file__))
P=os.path.expanduser('~/data/proofwriter/proofwriter-dataset-V2020.12.3/OWA/depth-5/meta-test.jsonl')
rng=random.Random(20261003)
pool=collections.defaultdict(list)
for l in open(P):
    d=json.loads(l)
    for qk,q in d['questions'].items():
        lab={True:'True',False:'False'}.get(q['answer'],q['answer'])
        pool[(q['QDep'],lab)].append(dict(id=d['id']+'-'+qk,theory_id=d['id'],theory=d['theory'],question=q['question'],label=lab,depth=q['QDep']))
alloc=[(7,7,6),(7,6,7),(6,7,7)]
out=[];used=set()
for i,dep in enumerate(range(6)):
    for lab,n in zip(('True','False','Unknown'),alloc[i%3]):
        c=pool[(dep,lab)][:]; rng.shuffle(c)
        k=0
        for x in c:
            if x['theory_id'] in used: continue
            used.add(x['theory_id']); out.append(x); k+=1
            if k==n: break
        assert k==n,(dep,lab)
rng.shuffle(out)
with open(os.path.join(BASE,'sample.jsonl'),'w') as f:
    for x in out: f.write(json.dumps(x)+'\n')
print(len(out), collections.Counter((x['depth'],x['label']) for x in out))
