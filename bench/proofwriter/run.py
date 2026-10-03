import json, subprocess, tempfile, time, re, sys, os, concurrent.futures as cf, threading
BASE=os.path.dirname(os.path.abspath(__file__))
def prompt(x):
    return ("Do NOT use any tools, do NOT run commands, and do NOT read any files. "
            "This is a pure reading-comprehension logic question; answer from the text below only.\n\n"
            f"Facts and rules:\n{x['theory']}\n\nQuestion: Based only on the facts and rules above, is the following statement true?\n"
            f"Statement: {x['question']}\n\n"
            "Answer with exactly one word: True, False, or Unknown. Unknown means it cannot be proven true or false "
            "from the given facts and rules (open-world).")
def parse(s):
    t=s.strip().strip('.*`"\' \n').strip()
    return t if t in ('True','False','Unknown') else None
def call(x, model, effort, tries=3):
    for a in range(tries):
        with tempfile.TemporaryDirectory(dir=os.path.join(BASE,'tmp')) as td:
            wd=os.path.join(td,'w'); os.mkdir(wd); of=os.path.join(td,'out.txt')
            cmd=['codex','exec','--skip-git-repo-check','--ephemeral','--sandbox','read-only',
                 '-m',model,'-c',f'model_reasoning_effort="{effort}"','-C',wd,'--json','-o',of,'-']
            t0=time.time()
            try:
                p=subprocess.run(cmd,input=prompt(x),capture_output=True,text=True,timeout=600,cwd=wd)
            except subprocess.TimeoutExpired:
                err='timeout'; continue
            dt=time.time()-t0
            out=open(of).read() if os.path.exists(of) else ''
            usage=None; tools=0; errs=[]
            for line in p.stdout.splitlines():
                try: e=json.loads(line)
                except: continue
                if e.get('type')=='turn.completed': usage=e.get('usage')
                if e.get('type','').startswith('item.') and e.get('item',{}).get('type') not in (None,'agent_message','reasoning'): tools+=1
                if e.get('type') in ('error','turn.failed'): errs.append(e)
            if p.returncode==0 and out.strip():
                return dict(raw=out, pred=parse(out), latency=round(dt,2), usage=usage, tool_items=tools, attempts=a+1)
            err=dict(rc=p.returncode, errs=errs[:2], stderr=p.stderr[-500:])
    return dict(raw='', pred=None, latency=None, usage=None, error=err, attempts=tries)
if __name__=='__main__':
    model, effort, n, workers = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4])
    tag=f'{model}__{effort}'; outp=os.path.join(BASE,'results',f'results_{tag}.jsonl')
    os.makedirs(os.path.join(BASE,'tmp'),exist_ok=True); os.makedirs(os.path.join(BASE,'results'),exist_ok=True)
    done=set()
    if os.path.exists(outp):
        done={r['id'] for r in map(json.loads,open(outp)) if 'error' not in r}  # API-error rows are retried
    xs=[json.loads(l) for l in open(os.path.join(BASE,'sample.jsonl'))][:n]
    xs=[x for x in xs if x['id'] not in done]
    lock=threading.Lock()
    def job(x):
        r=call(x,model,effort)
        rec=dict(id=x['id'],depth=x['depth'],label=x['label'],model=model,effort=effort,**r,correct=(r['pred']==x['label']))
        with lock:
            with open(outp,'a') as f: f.write(json.dumps(rec)+'\n')
        print(x['id'],x['label'],r['pred'],r['latency'],r.get('usage'),flush=True)
    with cf.ThreadPoolExecutor(workers) as ex: list(ex.map(job,xs))
