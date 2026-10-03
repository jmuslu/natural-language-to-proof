"""Raw-text baseline via Gemini API generateContent (plain chat, no tools); logic copied from
bench/proofwriter/run_gemini.py. Prompt = Codex prompt minus the "Do NOT use any tools" preamble.
usage: python3 run_gemini.py <bench> <model> <config> [pace_seconds] [n]
config: none | minimal | low | medium | high (thinkingLevel) | budget<N> (thinkingBudget=N)
Resumable: rows without 'error' are skipped. API key read from env / ~/.config/nl2proof/gemini.env, never logged."""
import json, os, re, sys, time, urllib.request, urllib.error
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import spec as SP
from scoring import strict_parse, lenient_parse
URL = "https://generativelanguage.googleapis.com/v1beta/models/{}:generateContent"

def _key():
    k = os.environ.get('GEMINI_API_KEY')
    if k: return k
    for l in open(os.path.expanduser('~/.config/nl2proof/gemini.env')):
        l = l.strip()
        if l.startswith('export '): l = l[7:]
        if l.startswith('GEMINI_API_KEY='): return l.split('=', 1)[1].strip().strip('"\'')
    raise SystemExit('no GEMINI_API_KEY')
KEY = _key()

def gen_config(config):
    gc = {"temperature": 0}
    if config.startswith('budget'): gc["thinkingConfig"] = {"thinkingBudget": int(config[6:])}
    elif config in ('minimal', 'low', 'medium', 'high'): gc["thinkingConfig"] = {"thinkingLevel": config}
    return gc

class DailyQuota(Exception): pass

def post(model, body):
    req = urllib.request.Request(URL.format(model), data=json.dumps(body).encode(),
                                 headers={"Content-Type": "application/json", "x-goog-api-key": KEY})
    return json.load(urllib.request.urlopen(req, timeout=600))

def call(S, x, model, gc, tries=6):
    body = {"contents": [{"role": "user", "parts": [{"text": SP.prompt(S, x, False)}]}], "generationConfig": gc}
    err = None
    for a in range(tries):
        t0 = time.time()
        try:
            r = post(model, body)
        except urllib.error.HTTPError as e:
            txt = e.read().decode(errors='replace')
            try: j = json.loads(txt)['error']
            except Exception: j = {'message': txt[:500]}
            err = dict(http=e.code, message=j.get('message', '')[:400])
            if e.code == 429:
                det = j.get('details', [])
                qids = [v.get('quotaId', '') for d in det for v in d.get('violations', [])]
                delay = None
                for d in det:
                    if 'retryDelay' in d:
                        m = re.match(r'([\d.]+)s', d['retryDelay']); delay = float(m.group(1)) if m else None
                if any('PerDay' in q for q in qids) and not any('PerMinute' in q for q in qids):
                    raise DailyQuota(f"{qids}")
                if 'limit: 0' in err['message']: raise DailyQuota('limit 0 on free tier')
                wait = (delay or 10 * 2 ** a) + 1
                print(f'  429 {x["id"]} wait {wait:.0f}s {qids}', flush=True); time.sleep(wait); continue
            if 500 <= e.code < 600:
                wait = 5 * 2 ** a
                print(f'  {e.code} {x["id"]} wait {wait}s', flush=True); time.sleep(wait); continue
            break
        except Exception as e:
            err = dict(exc=repr(e)[:300]); time.sleep(5 * 2 ** a); continue
        dt = time.time() - t0
        c = (r.get('candidates') or [{}])[0]
        parts = (c.get('content') or {}).get('parts', [])
        raw = ''.join(p.get('text', '') for p in parts if not p.get('thought'))
        return dict(raw=raw, latency=round(dt, 2), usage=r.get('usageMetadata'), finish=c.get('finishReason'),
                    model_version=r.get('modelVersion'), attempts=a + 1)
    return dict(raw='', latency=None, usage=None, error=err, attempts=a + 1)

if __name__ == '__main__':
    bench, model, config = sys.argv[1], sys.argv[2], sys.argv[3]
    pace = float(sys.argv[4]) if len(sys.argv) > 4 else 5.0
    n = int(sys.argv[5]) if len(sys.argv) > 5 else 10 ** 9
    S = SP.load(bench); gc = gen_config(config)
    outp = os.path.join(S.DIR, 'results', f'results_gemini_{model}__{config}.jsonl'); os.makedirs(os.path.dirname(outp), exist_ok=True)
    done = set()
    if os.path.exists(outp): done = {r['id'] for r in map(json.loads, open(outp)) if 'error' not in r}
    xs = [json.loads(l) for l in open(os.path.join(S.DIR, 'sample.jsonl'))][:n]
    xs = [x for x in xs if x['id'] not in done]
    print(f'{bench} {model} {config} gc={gc} todo={len(xs)} pace={pace}s', flush=True)
    last = 0.0
    for x in xs:
        time.sleep(max(0, last + pace - time.time())); last = time.time()
        try: r = call(S, x, model, gc)
        except DailyQuota as e:
            print(f'DAILY QUOTA EXHAUSTED for {model}: {e}; stopping (partial).', flush=True); sys.exit(3)
        pred, lpred = strict_parse(r['raw'], S.LABELS), lenient_parse(r['raw'], S.LABELS)
        rec = dict(id=x['id'], stratum=x['stratum'], label=x['label'], model=model, effort=config, runner='gemini',
                   generation_config=gc, **r, pred=pred, lenient_pred=lpred,
                   correct=(pred == x['label']), lenient_correct=(lpred == x['label']))
        with open(outp, 'a') as f: f.write(json.dumps(rec) + '\n')
        u = r.get('usage') or {}
        print(x['id'], x['label'], pred, lpred, r['latency'], u.get('promptTokenCount'), u.get('candidatesTokenCount'),
              u.get('thoughtsTokenCount'), r.get('error', ''), flush=True)
