#!/usr/bin/env python3
"""Input-only occurrence frame accounting; no draw, parser, or label evaluation.

Rows are counted separately even when their presented sentence text is identical.
Only compact aggregates are emitted. Original input bytes are hashed opaquely;
only context/question fields are selected for the projected-input/frame digests.
"""
import argparse
from collections import Counter
import hashlib
import importlib.util
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('inventory_other', HERE / 'inventory-other.py')
base = importlib.util.module_from_spec(spec)
spec.loader.exec_module(base)
DIFFICULTIES = ('easy', 'medium', 'hard')
ROLES = ('theory', 'question')


def encoded(value):
    return (json.dumps(value, ensure_ascii=False, sort_keys=True,
                       separators=(',', ':')) + '\n').encode('utf-8')


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def recover(root, reference):
    paths = sorted(root.rglob('*.json'))
    if not paths or any(p.stem not in DIFFICULTIES for p in paths):
        raise ValueError('Expected JSON files named easy, medium, or hard')
    counts = Counter()
    surfaces = { (d, r): set() for d in DIFFICULTIES for r in ROLES }
    outer = { key: Counter() for key in surfaces }
    all_surfaces = set()
    projected = hashlib.sha256()
    frame = hashlib.sha256()
    sources = []
    records = 0
    for path in paths:
        relative = path.relative_to(root).as_posix()
        rows = json.loads(path.read_text(encoding='utf-8'))
        if not isinstance(rows, list):
            raise ValueError('Expected record array')
        file_counts = Counter()
        for index, row in enumerate(rows):
            context, question = row['context'], row['question']
            if not isinstance(context, str) or not isinstance(question, str):
                raise ValueError('Expected textual context and question')
            projected.update(encoded([relative, index, context, question]))
            inputs = [('theory', base.split_sentences(context)),
                      ('question', [base.strip_query(question)])]
            for role, sentences in inputs:
                for sentence_index, text in enumerate(sentences):
                    key = (path.stem, role)
                    counts[key] += 1
                    file_counts[role] += 1
                    surfaces[key].add(text)
                    all_surfaces.add(text)
                    outer[key][base.family(text)] += 1
                    frame.update(encoded([relative, index, role, sentence_index, text]))
        records += len(rows)
        sources.append({'path': relative, 'sha256': digest(path),
                        'records': len(rows), 'occurrences': sum(file_counts.values()),
                        'roles': dict(sorted(file_counts.items()))})
    total_outer = sum(outer.values(), Counter())
    role_counts = {r: sum(counts[d, r] for d in DIFFICULTIES) for r in ROLES}
    result = {
        'schema': 'proverqa-occurrence-strata-v1',
        'scope': 'all JSON inputs under supplied root; duplicates retained; no sampling',
        'role_mapping': {'question': 'existing inventory query; stripped once, never sentence-split'},
        'frame_order': 'sorted relative path, zero-based record index, theory then question, sentence index',
        'digest_encoding': 'UTF-8 canonical JSON arrays, ensure_ascii=False, sorted keys, compact separators, LF',
        'input_projection_fields': ['context', 'question'],
        'sources': sources,
        'splitter_source_sha256': digest(HERE / 'inventory-other.py'),
        'script_sha256': digest(Path(__file__)),
        'projected_inputs_sha256': projected.hexdigest(),
        'occurrence_frame_sha256': frame.hexdigest(),
        'records': records,
        'occurrences': sum(counts.values()),
        'unique_surfaces': len(all_surfaces),
        'duplicate_excess': sum(counts.values()) - len(all_surfaces),
        'roles': role_counts,
        'strata': [{'difficulty': d, 'role': r, 'N_h': counts[d, r],
                    'unique_surfaces': len(surfaces[d, r]),
                    'outer_family_occurrences': dict(sorted(outer[d, r].items()))}
                   for d in DIFFICULTIES for r in ROLES],
    }
    expected = json.loads(reference.read_text())['datasets']['proverqa']
    comparisons = {
        'records': (records, expected['records']),
        'file_count': (len(paths), expected['file_count']),
        'occurrences': (result['occurrences'], expected['sentence_occurrences']),
        'unique_surfaces': (len(all_surfaces), expected['unique_sentences']),
        'roles': ({'theory': role_counts['theory'], 'query': role_counts['question']}, expected['roles']),
        'files': ({'proverqa/' + s['path']: s['occurrences'] for s in sources}, expected['files']),
        'outer_families': (dict(total_outer), {k: v['count'] for k, v in expected['constructions'].items()}),
    }
    mismatches = {k: {'observed': a, 'reference': b}
                  for k, (a, b) in comparisons.items() if a != b}
    result['reconciliation'] = {'reference_sha256': digest(reference),
                                'checked': list(comparisons), 'matches': not mismatches,
                                'mismatches': mismatches}
    return result


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--root', type=Path, required=True)
    ap.add_argument('--reference', type=Path, default=HERE / 'other-counts.json')
    ap.add_argument('--output', type=Path, help='Compact aggregate JSON only; default stdout')
    args = ap.parse_args()
    result = recover(args.root, args.reference)
    output = json.dumps(result, indent=2, ensure_ascii=False) + '\n'
    if args.output:
        args.output.write_text(output, encoding='utf-8')
    else:
        print(output, end='')
    raise SystemExit(0 if result['reconciliation']['matches'] else 2)


if __name__ == '__main__':
    main()
