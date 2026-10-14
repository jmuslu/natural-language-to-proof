#!/usr/bin/env python3
"""Four-label parsing and descriptive scores for this designed, non-random suite."""
import argparse
from collections import Counter
import json
from pathlib import Path
import re

from spec import LABELS

CANON = {label.lower(): label for label in LABELS}
WORD = r'\b(' + '|'.join(CANON) + r')\b'
MARKER = re.compile(r'\b(?:final\s+)?(?:answer|label|verdict|conclusion)\s*(?:is|:|=|-)\s*' + WORD)


def strict_parse(text):
    value = (text or '').strip().strip('.*`"\' \n').strip()
    return value if value in LABELS else None


def lenient_parse(text):
    clean = re.sub(r'[*_`#>|\[\]{}()"]', ' ', (text or '').lower())
    markers = list(MARKER.finditer(clean))
    if markers:
        segment = re.split(r'[.!?;\n]', clean[markers[-1].start(1):], maxsplit=1)[0]
        labels = {CANON[match.group(1)] for match in re.finditer(WORD, segment)}
        return labels.pop() if len(labels) == 1 else None
    hits = list(re.finditer(WORD, clean))
    if not hits:
        return None
    start = max([m.end() for m in re.finditer(r'[.!?;\n]', clean[:hits[-1].start()])] or [0])
    labels = {CANON[hit.group(1)] for hit in hits if hit.start() >= start}
    return labels.pop() if len(labels) == 1 else None


def read(path):
    return [json.loads(line) for line in Path(path).read_text().splitlines() if line.strip()]


def summarize(samples, results, parser):
    by_id = {row['id']: row for row in results}
    if len(by_id) != len(results):
        raise ValueError('duplicate result IDs; deduplicate retries explicitly')
    unknown = set(by_id) - {row['id'] for row in samples}
    if unknown:
        raise ValueError('result IDs outside the sample')
    rows = [(sample, parser(by_id.get(sample['id'], {}).get('raw', ''))) for sample in samples]
    correct = sum(pred == sample['label'] for sample, pred in rows)
    answered = sum(pred is not None for _, pred in rows)
    return dict(n=len(samples), completed=len(results), correct=correct, answered=answered,
                accuracy=correct / len(samples), coverage=answered / len(samples),
                precision=correct / answered if answered else None,
                by_family={family: dict(n=sum(x['stratum'] == family for x, _ in rows),
                    correct=sum(x['stratum'] == family and p == x['label'] for x, p in rows))
                    for family in sorted({x['stratum'] for x in samples})},
                confusion=dict(Counter(str(x['label']) + '->' + str(p) for x, p in rows)))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('results', type=Path)
    parser.add_argument('--sample', type=Path, default=Path(__file__).with_name('sample.jsonl'))
    args = parser.parse_args()
    samples, results = read(args.sample), read(args.results)
    usage = Counter()
    for result in results:
        for key, value in (result.get('usage') or {}).items():
            if isinstance(value, (int, float)):
                usage[key] += value
    print(json.dumps(dict(strict=summarize(samples, results, strict_parse),
                          lenient=summarize(samples, results, lenient_parse),
                          usage_totals=dict(usage)), indent=2, sort_keys=True))


if __name__ == '__main__':
    main()
