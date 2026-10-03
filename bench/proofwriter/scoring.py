"""Strict and lenient answer parsing for the ProofWriter baseline (re-scores saved `raw` replies).

python3 scoring.py          # print every strict-invalid reply (200 chars) next to its lenient parse
python3 scoring.py table    # print the README results rows (strict + "with leniency")
"""
import json, glob, os, re, math, sys
BASE = os.path.dirname(os.path.abspath(__file__))
LABELS = ('True', 'False', 'Unknown')

def strict_parse(raw):
    """Exactly True/False/Unknown after trimming .*`"' and whitespace (what run*.py stored as `pred`)."""
    s = (raw or '').strip().strip('.*`"\'').strip()
    return s if s in LABELS else None

# Unknown synonyms; "neither true nor false" is consumed as one unit so its true/false don't count.
_UNK = r"neither\s+true\s+nor\s+false|cannot\s+be\s+determined|can'?t\s+be\s+determined|not\s+enough\s+information|undetermined|uncertain|neither"
_LABEL = re.compile(r"\b(?:(true|false|unknown)|(" + _UNK + r"))\b")
_MARKER = re.compile(r"(?:final\s+answer|answer)\s*:|the\s+answer\s+is")
_SENT_END = re.compile(r"[.!?](?=\s)|\n")

def _norm(raw):
    s = (raw or '').lower().replace('’', "'")
    s = re.sub(r"\*\*|`|#|[\"“”‘]", ' ', s)          # markdown and double/curly quotes
    s = re.sub(r"(?<![a-z])'|'(?![a-z])", ' ', s)                    # single quotes, keeping can't
    return s

def _labels(s):
    return [(m.start(), m.end(), m.group(1).capitalize() if m.group(1) else 'Unknown') for m in _LABEL.finditer(s)]

def lenient_parse(raw):
    """1 lowercase, strip markdown/quotes; 2 if an answer marker exists, the first label in the rest of the
    marker's sentence; 3 else the last label word; 4 Unknown synonyms count as Unknown (yes/no never do);
    5 None (invalid) if there is no label or the sentence holding the chosen label has two different labels."""
    s = _norm(raw)
    def sentence(i):
        a = max([m.end() for m in _SENT_END.finditer(s, 0, i)] or [0])
        e = _SENT_END.search(s, i)
        return s[a:e.start() if e else len(s)]
    marks = list(_MARKER.finditer(s))
    if marks:
        rest = s[marks[-1].end():].lstrip()
        e = _SENT_END.search(rest)
        labs = _labels(rest[:e.start() if e else len(rest)])
        if labs:
            return labs[0][2] if len({l for *_, l in labs}) == 1 else None
    labs = _labels(s)
    if not labs: return None
    seg = sentence(labs[-1][0])
    return labs[-1][2] if len({l for *_, l in _labels(seg)}) == 1 else None

# ---------------------------------------------------------------- re-scoring helpers
def load(path):
    rows = {}
    for r in map(json.loads, open(path)):
        if 'error' in r and r['id'] in rows: continue
        rows[r['id']] = r  # last non-error row wins
    return [r for r in rows.values() if 'error' not in r]

def rescore(rs):
    """Copy of rs with lenient pred/correct, plus (invalid->correct, invalid->wrong) counts."""
    out, fixed, wrong = [], 0, 0
    for r in rs:
        p = r['pred'] if r['pred'] is not None else lenient_parse(r['raw'])
        if r['pred'] is None and p is not None:
            if p == r['label']: fixed += 1
            else: wrong += 1
        out.append(dict(r, pred=p, correct=(p == r['label'])))
    return out, fixed, wrong

def wilson(k, n, z=1.96):
    p = k / n; d = 1 + z * z / n
    c = (p + z * z / (2 * n)) / d; h = z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n)) / d
    return max(0, c - h), min(1, c + h)

def row(name, rs, status, note):
    k, n = sum(r['correct'] for r in rs), len(rs)
    lo, hi = wilson(k, n)
    cell = lambda g: f"{sum(r['correct'] for r in g)}/{len(g)}" if g else '–'
    c = [cell([r for r in rs if r['depth'] == d]) for d in range(6)] + [cell([r for r in rs if r['label'] == L]) for L in LABELS]
    inv = sum(r['pred'] is None for r in rs)
    return f"| {name} | {status} | {k}/{n} = {100*k/n:.1f}% [{100*lo:.1f}, {100*hi:.1f}] | " + ' | '.join(c) + f" | {inv} | {note} |"

ORDER = ['gpt-5.5__low', 'gpt-5.5__high', 'gemini-3.1-flash-lite__budget0', 'gemma-4-26b-a4b-it__minimal', 'gemma-4-31b-it__minimal',
         'gemini-3-flash-preview__high', 'gemini-3.5-flash__high', 'gemini-3.6-flash__high', 'gemini-3.7-flash__high', 'gemini-3.8-flash__high']

def table():
    for key in ORDER:
        f = glob.glob(os.path.join(BASE, 'results', f'results_*{key}.jsonl'))
        if not f: continue
        gem = 'gemini_' in f[0]
        rs = load(f[0]); lr, fx, wr = rescore(rs)
        name = key.replace('__', ' / ') + (' (Gemini API)' if gem else ' (Codex)')
        status = 'complete' if len(rs) == 120 else f'partial {len(rs)}/120'
        print(row(name, rs, status, ''))
        print(row(key.replace('__', ' / ') + ' (with leniency)', lr, status, f'{fx} / {wr}'))

if __name__ == '__main__':
    if sys.argv[1:] == ['table']: table(); sys.exit()
    for f in sorted(glob.glob(os.path.join(BASE, 'results', 'results_*.jsonl'))):
        rs = load(f)
        bad = [r['id'] for r in rs if r['pred'] is not None and lenient_parse(r['raw']) != r['pred']]
        if bad: print('!! lenient disagrees with a strict-valid reply in', f, bad)
        for r in rs:
            if r['pred'] is None:
                p = lenient_parse(r['raw'])
                print(f"{os.path.basename(f)[8:-6]:34s} gold={r['label']:7s} lenient={p!s:7s} {'correct' if p == r['label'] else 'wrong  '}"
                      f"\n   head: {r['raw'][:200]!r}\n   tail: {r['raw'][-120:]!r}")
