#!/usr/bin/env python3
"""Audit committed FOLIO English only; print aggregate counts, never labels/FOL.

Outer-family and cue functions deliberately reproduce inventory-other.py. They
are surface diagnostics, not semantic annotation. Audited exemplars below count
exact strings; they do not estimate total construction frequency.
"""
import collections
import hashlib
import importlib.util
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('surface_inventory', Path(__file__).with_name('inventory-other.py'))
surface = importlib.util.module_from_spec(spec)
spec.loader.exec_module(surface)
AUDITED = {
    'graded quantity': 'Many of Beijing\'s 91 universities consistently rank among the best in the Asia-Pacific and the world.',
    'currency comparison': '2000$ is more than $1500.',
    'temporal adjunct + passive particle': 'On some Mondays at 8 pm, roses are given out on TV.',
    'reduced relative + passive': 'The Harding Pegmatite Mine, located in the Picuris Mountains, was donated.',
    'restrictive relative + negation': 'Plates that do not begin with the number 34 are not from Istanbul.',
    'infinitival attitude': 'James wants to have a long vacation.',
    'infinitival preference': 'Koalas love to sleep.',
    'impersonal cost + infinitive': 'It costs US $205 to take the GRE test.',
    'possession + cross-sentence anaphora': 'His dad has been out of work for more than a year.',
    'explicit relational from adjunct': 'John flies from LGA airport.',
    'explicit relational to adjunct': 'John flies to LGA airport.',
    'mixed VP coordination': 'KiKi barks and is a dog.',
    'passive particle + goal': 'Ailton Silva was loaned out to a football club.',
    'passive by-agent': 'Family History is written by Dani Shapiro.',
    'reduced passive modifier': 'Family History is a novel written in 2003.',
    'proper name + negative predication': 'Breaking Bad is not a reality TV show.',
    'quotation-delimited proper name': '"Black Mirror" is a Netflix show.',
    'superlative quantified comparison': 'Yale University has the largest university endowment of any educational institution.',
    'negative existential + nested relatives': 'There are no mountain ranges in texas that have mines which have been donated.',
    'fronted biconditional + pronoun': 'If and only if Karen binge-watches a Netflix show, she will download it.',
    'fragment enumeration': 'turkey, Rio Grande wild turkey, and Ocellated wild turkey.',
    'input typo': 'Ailton Silva foes not play for a football club.',
}

def main():
    path = ROOT / 'bench/folio/sample.jsonl'
    units = []
    ids = set()
    for line in path.read_text().splitlines():
        record = json.loads(line)
        # Access no label, story metadata, or supplied logical formula fields.
        ids.add(record['id'])
        for role, texts in [('premise', record['context'].splitlines()), ('query', [record['statement']])]:
            for index, text in enumerate(texts):
                text = text.strip()
                if not text:
                    raise ValueError('Unexpected empty input unit')
                units.append((text, record['id'], role, index))
    families = collections.defaultdict(lambda: [0, set()])
    cues = collections.defaultdict(lambda: [0, set()])
    for text, *_ in units:
        f = families[surface.family(text)]; f[0] += 1; f[1].add(text)
        for cue in surface.features(text):
            f = cues[cue]; f[0] += 1; f[1].add(text)
    assert sum(n for n, _ in families.values()) == len(units)
    def table(title, values):
        print('\n' + title + '\n\n| Diagnostic | Occurrences | Unique strings |\n|---|---:|---:|')
        for key, (n, strings) in sorted(values.items(), key=lambda p: (-p[1][0], p[0])):
            print(f'| `{key}` | {n} | {len(strings)} |')
    print(f'Sample: {len(ids)} items; {len(units)} units; {len(set(x[0] for x in units))} unique strings.')
    print('Roles:', dict(collections.Counter(x[2] for x in units)))
    print('SHA256:', hashlib.sha256(path.read_bytes()).hexdigest())
    table('Outer surface buckets (mutually exclusive by precedence)', families)
    table('Overlapping lexical cues (not constructions)', cues)
    print('\nHand-audited exact exemplars\n\n| Construction or exception | Occurrences | First input reference (zero-based index) |\n|---|---:|---|')
    for key, text in AUDITED.items():
        matched = [x for x in units if x[0] == text]
        if not matched:
            raise ValueError('Missing audited input: ' + key)
        _, item, role, index = matched[0]
        print(f'| {key} | {len(matched)} | `{item}:{role}:{index}` |')

if __name__ == '__main__':
    main()
