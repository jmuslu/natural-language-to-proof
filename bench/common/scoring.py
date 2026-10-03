"""Answer parsing shared by the prontoqa / folio / proverqa baselines.

strict_parse: the reply, after trimming .*`"' and whitespace, must be exactly one label word (case-sensitive),
  same rule as bench/proofwriter/run.py.
lenient_parse: same rule as the ProofWriter lenient parser: case-insensitive; strip markdown/punctuation;
  an explicit "Answer:"-style marker wins (last marker that is followed by a label); else the LAST label word
  in the reply. Unknown synonyms (unknown, uncertain, cannot be determined, not enough information,
  undetermined, neither) all map to the benchmark's third label ("Uncertain" here, "Unknown" in ProofWriter).
  Ambiguous (the sentence holding the last label names two different labels, e.g. "True/False") or no label = invalid (None).
  For a two-label benchmark (ProntoQA) an Unknown-synonym answer parses to "Uncertain", which is off-label and
  therefore wrong but not invalid.
"""
import re

UNK = 'Uncertain'
_UNK_SYN = [r"uncertain", r"unknown", r"cannot\s+be\s+determined", r"can\s*not\s+be\s+determined",
            r"can'?t\s+be\s+determined", r"not\s+enough\s+information", r"undetermined", r"neither"]
_LAB = r"(?P<lab>true|false|" + "|".join(_UNK_SYN) + r")"
_LAB_RE = re.compile(r"\b" + _LAB + r"\b")
_MARK_RE = re.compile(r"\b(?:final\s+answer|answer|verdict|conclusion)\s*(?:is|would\s+be|:|-|=)\s*(?:that\s+)?(?:the\s+statement\s+is\s+)?" + _LAB + r"\b")

def _norm(lab):
    if lab == 'true': return 'True'
    if lab == 'false': return 'False'
    return UNK

def strict_parse(s, labels):
    t = (s or '').strip().strip('.*`"\' \n').strip()
    return t if t in labels else None

def _clean(s):
    t = (s or '').lower()
    t = re.sub(r"[*_`#>|\[\]{}()\"]", " ", t)       # markdown
    t = t.replace('’', "'")
    t = re.sub(r"[ \t]+", " ", t)
    return t

def lenient_parse(s, labels=None):
    t = _clean(s)
    m = list(_MARK_RE.finditer(t))
    if m:
        return _norm(m[-1].group('lab'))
    hits = list(_LAB_RE.finditer(t))
    if not hits:
        return None
    last = hits[-1]
    # deciding segment = the sentence/line holding the last label mention; ambiguous if it names two labels
    seps = [m.end() for m in re.finditer(r"[.!?;\n]", t[:last.start()])]
    seg_start = seps[-1] if seps else 0
    on_line = {_norm(h.group('lab')) for h in hits if seg_start <= h.start()}
    if len(on_line) > 1:
        return None
    return _norm(last.group('lab'))

if __name__ == '__main__':
    L = ('True', 'False', 'Uncertain')
    for s, want in [("True", 'True'), ("**False**.", 'False'), ("false", 'False'), ("Unknown", 'Uncertain'),
                    ("It cannot be determined.", 'Uncertain'), ("True/False", None), ("", None), ("Maybe", None),
                    ("Answer: True\nbecause it is not false", 'True'), ("We get false... so the final answer is True", 'True'),
                    ("Step 1 true. Step 2 shows it is False.", 'False'), ("Not enough information", 'Uncertain')]:
        got = lenient_parse(s, L)
        assert got == want, (s, got, want)
    assert strict_parse("True.", L) == 'True' and strict_parse("true", L) is None and strict_parse("Unknown", L) is None
    print('scoring self-test ok')
