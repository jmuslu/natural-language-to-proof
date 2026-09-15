"""Reproduce a finite synthetic forecast diagnostic; no financial target."""
import hashlib
import json
import math
from pathlib import Path
import random
import argparse

import online_residual
from online_residual import replay_progressive_residual

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--out",type=Path)
args = parser.parse_args()

report = {"scope":"Finite synthetic Gaussian-HMM diagnostic; no model selection or financial target.",
          "configuration":{"mus":[-.75,.75],"sd":1.,"transition":[[.94,.06],[.06,.94]],
                           "model_initial":[.5,.5],"generator_initial_state":0,
                           "forgetting":.97,"ridge":.7,"loss_decay":.8,"lag":1,
                           "total_observations":1100,"scored_from":100,"context":"tanh(current observation)"},
          "replicates":[]}
for seed in (20501,30501):
    rng,state,obs = random.Random(seed),0,[]
    for _ in range(1100):
        if rng.random()>.94:
            state=1-state
        obs.append(rng.gauss((-.75,.75)[state],1.))
    out = replay_progressive_residual(obs,[(math.tanh(x),) for x in obs],mus=(-.75,.75),sd=1.,
              trans=((.94,.06),(.06,.94)),pi=(.5,.5),target_id="synthetic one-lag fixed Gaussian HMM",
              forgetting=.97,ridge=.7,loss_decay=.8)
    rows = out["rows"]
    loss = {k:[] for k in ("blend","AR","context","persistence","zero","past_mean","warmup_mean","past_EWMA")}
    warmup_mean = sum(r["revision_kl"] for r in rows[1:100])/99
    past_sum,ewma = 0.,None
    for t in range(1,len(rows)):
        y = rows[t]["revision_kl"]
        if t>=100:
            m = rows[t]["matured"]
            predictions = {"blend":m["prediction"],"AR":m["branch_predictions"][0],
                           "context":m["branch_predictions"][1],"persistence":rows[t-1]["revision_kl"],
                           "zero":0.,"past_mean":past_sum/(t-1),"warmup_mean":warmup_mean,"past_EWMA":ewma}
            for method,prediction in predictions.items():
                loss[method].append((y-prediction)**2)
        past_sum += y
        ewma = y if ewma is None else .97*ewma+.03*y
    result = {"seed":seed,"scored":1000,"MSE_nats_squared":{k:sum(v)/len(v) for k,v in loss.items()}}
    report["replicates"].append(result)
    print(json.dumps(result))
report["module_sha256"] = hashlib.sha256(Path(online_residual.__file__).read_bytes()).hexdigest()
if args.out:
    args.out.parent.mkdir(parents=True,exist_ok=True)
    args.out.write_text(json.dumps(report,indent=2)+"\n")
