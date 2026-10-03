"""Raw-text ProofWriter baseline via Gemini API generateContent (plain chat, no tools).
usage: python3 run_gemini.py <model> <config> [pace_seconds] [n]
config: none | minimal | low | medium | high (thinkingLevel) | budget<N> (thinkingBudget=N)
Resumable: rows without 'error' are skipped. API key is read from gemini.env and never logged.
"""
import json, os, re, sys, time, urllib.request, urllib.error
BASE = os.path.dirname(os.path.abspath(__file__))
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

# Identical to run.py's prompt() minus the "Do NOT use any tools ..." preamble (no tools in a plain chat call).
def prompt(x):
    return (f"Facts and rules:\n{x['theory']}\n\nQuestion: Based only on the facts and rules above, is the following statement true?\n"
            f"Statement: {x['question']}\n\n"
            "Answer with exactly one word: True, False, or Unknown. Unknown means it cannot be proven true or false "
            "from the given facts and rules (open-world).")

def parse(s):  # identical to run.py (strict)
    t = s.strip().strip('.*`"\' \n').strip()
    return t if t in ('True', 'False', 'Unknown') else None

def gen_config(config):
    gc = {"temperature": 0}
    if config.startswith('budget'):
        gc["thinkingConfig"] = {"thinkingBudget": int(config[6:])}
    elif config in ('minimal', 'low', 'medium', 'high'):
        gc["thinkingConfig"] = {"thinkingLevel": config}
    return gc

class DailyQuota(Exception): pass

def post(model, body):
    req = urllib.request.Request(URL.format(model), data=json.dumps(body).encode(),
                                 headers={"Content-Type": "application/json", "x-goog-api-key": KEY})
    return json.load(urllib.request.urlopen(req, timeout=600))

def call(x, model, gc, tries=6):
    body = {"contents": [{"role": "user", "parts": [{"text": prompt(x)}]}], "generationConfig": gc}
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
                if 'limit: 0' in err['message']:
                    raise DailyQuota('limit 0 on free tier')
                wait = (delay or 10 * 2 ** a) + 1
                print(f'  429 {x["id"]} wait {wait:.0f}s {qids}', flush=True); time.sleep(wait); continue
            if 500 <= e.code < 600:
                wait = 5 * 2 ** a
                print(f'  {e.code} {x["id"]} wait {wait}s', flush=True); time.sleep(wait); continue
            break  # other 4xx: don't burn quota
        except Exception as e:  # network/timeouts
            err = dict(exc=repr(e)[:300]); time.sleep(5 * 2 ** a); continue
        dt = time.time() - t0
        cands = r.get('candidates') or [{}]
        c = cands[0]
        parts = (c.get('content') or {}).get('parts', [])
        raw = ''.join(p.get('text', '') for p in parts if not p.get('thought'))
        thought_text_chars = sum(len(p.get('text', '')) for p in parts if p.get('thought'))
        return dict(raw=raw, pred=parse(raw), latency=round(dt, 2), usage=r.get('usageMetadata'),
                    finish=c.get('finishReason'), model_version=r.get('modelVersion'),
                    thought_text_chars=thought_text_chars, attempts=a + 1)
    return dict(raw='', pred=None, latency=None, usage=None, error=err, attempts=a + 1)

if __name__ == '__main__':
    model, config = sys.argv[1], sys.argv[2]
    pace = float(sys.argv[3]) if len(sys.argv) > 3 else 5.0
    n = int(sys.argv[4]) if len(sys.argv) > 4 else 10 ** 9
    gc = gen_config(config)
    outp = os.path.join(BASE, 'results', f'results_gemini_{model}__{config}.jsonl')
    os.makedirs(os.path.dirname(outp), exist_ok=True)
    done = set()
    if os.path.exists(outp):
        done = {r['id'] for r in map(json.loads, open(outp)) if 'error' not in r}
    xs = [json.loads(l) for l in open(os.path.join(BASE, 'sample.jsonl'))][:n]
    xs = [x for x in xs if x['id'] not in done]
    print(f'{model} {config} gc={gc} todo={len(xs)} pace={pace}s', flush=True)
    last = 0.0
    for x in xs:
        time.sleep(max(0, last + pace - time.time())); last = time.time()
        try:
            r = call(x, model, gc)
        except DailyQuota as e:
            print(f'DAILY QUOTA EXHAUSTED for {model}: {e}; stopping (partial).', flush=True); break
        rec = dict(id=x['id'], depth=x['depth'], label=x['label'], model=model, effort=config,
                   generation_config=gc, **r, correct=(r['pred'] == x['label']))
        with open(outp, 'a') as f: f.write(json.dumps(rec) + '\n')
        u = r.get('usage') or {}
        print(x['id'], x['label'], r['pred'], r['latency'], u.get('promptTokenCount'),
              u.get('candidatesTokenCount'), u.get('thoughtsTokenCount'), r.get('error', ''), flush=True)
