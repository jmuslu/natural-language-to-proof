#!/usr/bin/env python3
"""Seal one benchmark's complete parser records atomically from a growing cache.

The small sample supplies input IDs/hashes only. No output is considered ready
until every requested ID matches and the temporary file has been renamed.
"""
import argparse
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'bench' / 'reasoning'))
from run import digest, inference_request, read_jsonl


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('source', type=Path)
    ap.add_argument('bench', choices=['proverqa', 'folio', 'proofwriter', 'prontoqa'])
    ap.add_argument('output', type=Path)
    ap.add_argument('--limit', type=int, default=120)
    args = ap.parse_args()
    samples = read_jsonl(ROOT / 'bench' / args.bench / 'sample.jsonl')[:args.limit]
    expected = {s['id']: digest(inference_request(s)) for s in samples}
    found = set()
    temporary = args.output.with_suffix(args.output.suffix + '.tmp')
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.source.open() as source, temporary.open('w') as output:
        for line in source:
            if not line.endswith('\n'):
                break
            record = json.loads(line)
            ident = record['id']
            if ident not in expected:
                continue
            if ident in found or record.get('request_hash') != expected[ident]:
                raise ValueError('duplicate or mismatched parser request')
            found.add(ident)
            output.write(line)
            if found == expected.keys():
                break
    if found != expected.keys():
        raise ValueError(f'incomplete cache: {len(found)}/{len(expected)}; final output not created')
    temporary.replace(args.output)
    print(args.bench, len(found), str(args.output), flush=True)


if __name__ == '__main__':
    main()
