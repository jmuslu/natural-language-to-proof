#!/usr/bin/env python3
"""Send only authored fixtures to Haskell; evaluate against separate expectations."""
import argparse
import json
from pathlib import Path
import subprocess
import time

from score import read


def evaluate(binary, sample, output):
    rows = read(sample)
    request = ''.join(json.dumps({'id': x['id'], 'fixture': x['fixture']})+'\n' for x in rows)
    started = time.monotonic()
    run = subprocess.run([str(binary.resolve())], input=request, text=True,
                         capture_output=True, check=True)
    duration = time.monotonic() - started
    actual = [json.loads(line) for line in run.stdout.splitlines()]
    if len(actual) != len(rows):
        raise ValueError('adapter returned wrong number of rows')
    records = []
    for row, outcome in zip(rows, actual):
        if outcome.pop('id') != row['id']:
            raise ValueError('adapter returned mismatched item ID')
        pred = outcome.get('label')
        records.append(dict(id=row['id'], label=row['label'], stratum=row['stratum'],
                            pred=pred, raw=pred or '', correct=pred == row['label'],
                            exact_support=outcome == row['expected'], outcome=outcome,
                            runner='structured-production-genealogy'))
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(''.join(json.dumps(r, sort_keys=True)+'\n' for r in records))
    summary = dict(n=len(rows), labels_correct=sum(r['correct'] for r in records),
                   exact_support=sum(r['exact_support'] for r in records),
                   elapsed_seconds=duration,
                   by_family={family: dict(n=sum(r['stratum'] == family for r in records),
                       exact=sum(r['stratum'] == family and r['exact_support'] for r in records))
                       for family in sorted({r['stratum'] for r in records})})
    print(json.dumps(summary, indent=2, sort_keys=True))
    return summary


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--binary', type=Path, required=True)
    parser.add_argument('--sample', type=Path, default=Path(__file__).with_name('sample.jsonl'))
    parser.add_argument('--output', type=Path, default=Path(__file__).with_name('results') / 'graph.jsonl')
    args = parser.parse_args()
    evaluate(args.binary, args.sample, args.output)
