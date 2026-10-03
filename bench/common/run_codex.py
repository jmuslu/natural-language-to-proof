"""Raw-text baseline via Codex CLI (same invocation as bench/proofwriter/run.py: fresh empty dir, read-only, ephemeral).
usage: python3 run_codex.py <bench> <model> <effort> <n> <workers>
Resumable: rows without 'error' are skipped. Writes bench/<bench>/results/results_<model>__<effort>.jsonl"""
import json, subprocess, tempfile, time, sys, os, concurrent.futures as cf, threading
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import spec as SP
from scoring import strict_parse, lenient_parse

def call(S, x, model, effort, tries=3):
    err = None
    tmp = os.path.join(S.DIR, 'tmp'); os.makedirs(tmp, exist_ok=True)
    for a in range(tries):
        with tempfile.TemporaryDirectory(dir=tmp) as td:
            wd = os.path.join(td, 'w'); os.mkdir(wd); of = os.path.join(td, 'out.txt')
            cmd = ['codex', 'exec', '--skip-git-repo-check', '--ephemeral', '--sandbox', 'read-only',
                   '-m', model, '-c', f'model_reasoning_effort="{effort}"', '-C', wd, '--json', '-o', of, '-']
            t0 = time.time()
            try:
                p = subprocess.run(cmd, input=SP.prompt(S, x, True), capture_output=True, text=True, timeout=900, cwd=wd)
            except subprocess.TimeoutExpired:
                err = 'timeout'; continue
            dt = time.time() - t0
            out = open(of).read() if os.path.exists(of) else ''
            usage = None; tools = 0; errs = []
            for line in p.stdout.splitlines():
                try: e = json.loads(line)
                except Exception: continue
                if e.get('type') == 'turn.completed': usage = e.get('usage')
                if e.get('type', '').startswith('item.') and e.get('item', {}).get('type') not in (None, 'agent_message', 'reasoning'): tools += 1
                if e.get('type') in ('error', 'turn.failed'): errs.append(e)
            if p.returncode == 0 and out.strip():
                return dict(raw=out, latency=round(dt, 2), usage=usage, tool_items=tools, attempts=a + 1)
            err = dict(rc=p.returncode, errs=errs[:2], stderr=p.stderr[-500:])
    return dict(raw='', latency=None, usage=None, error=err, attempts=tries)

if __name__ == '__main__':
    bench, model, effort, n, workers = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4]), int(sys.argv[5])
    S = SP.load(bench)
    outp = os.path.join(S.DIR, 'results', f'results_{model}__{effort}.jsonl'); os.makedirs(os.path.dirname(outp), exist_ok=True)
    done = set()
    if os.path.exists(outp): done = {r['id'] for r in map(json.loads, open(outp)) if 'error' not in r}
    xs = [json.loads(l) for l in open(os.path.join(S.DIR, 'sample.jsonl'))][:n]
    xs = [x for x in xs if x['id'] not in done]
    lock = threading.Lock()
    def job(x):
        r = call(S, x, model, effort)
        pred, lpred = strict_parse(r['raw'], S.LABELS), lenient_parse(r['raw'], S.LABELS)
        rec = dict(id=x['id'], stratum=x['stratum'], label=x['label'], model=model, effort=effort, runner='codex', **r,
                   pred=pred, lenient_pred=lpred, correct=(pred == x['label']), lenient_correct=(lpred == x['label']))
        with lock:
            with open(outp, 'a') as f: f.write(json.dumps(rec) + '\n')
        print(x['id'], x['label'], pred, r['latency'], (r.get('usage') or {}).get('reasoning_output_tokens'), flush=True)
    with cf.ThreadPoolExecutor(workers) as ex: list(ex.map(job, xs))
