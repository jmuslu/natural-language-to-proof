"""Gold-free paired domain-policy probe over completed ProofWriter cache rows.

Run with the research Python environment and a parser JSONL cache. This reads no
sample/label files, compares top returned meanings only, and reports transitions
rather than accuracy. A growing cache's unfinished final line is ignored.
"""
import argparse
from collections import Counter
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'bench' / 'reasoning'))
from domain import normalize_theory
from run import evaluate_record


def rows(path, limit):
    selected = []
    with path.open() as stream:
        for line in stream:
            if not line.endswith('\n'):
                break
            row = json.loads(line)
            # ProofWriter preserves source theory IDs, unlike the other
            # benchmark adapters' proverqa-/folio-/prontoqa- namespaces.
            if '-OWA-D5-' in row.get('id', ''):
                selected.append(row)
                if len(selected) == limit:
                    break
    return selected


def bound_sortals(drs):
    guards = []
    for condition in drs.get('conditions', []):
        if condition.get('tag') != 'imp':
            continue
        left = condition['left']
        bound = set(left['universe'])
        for guard in left['conditions']:
            args = guard.get('args', [])
            if (guard.get('tag') == 'pred' and guard.get('name') in ('person', 'thing')
                    and len(args) == 1 and args[0].get('ref') in bound):
                guards.append(guard)
    return guards


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('cache', type=Path)
    parser.add_argument('--limit', type=int, default=5)
    args = parser.parse_args()
    if args.limit < 1:
        parser.error('limit must be positive')
    selected = rows(args.cache, args.limit)
    totals = Counter()
    transitions = {backend: Counter() for backend in ('horn', 'z3')}
    for record in selected:
        theory = next(iter(record.get('theories', [])), None)
        guards = bound_sortals(theory['drs']) if theory else []
        _, decisions = normalize_theory(theory['drs'], 'proofwriter') if theory else ({}, [])
        totals['direct_bound_sortals'] += len(guards)
        totals['removed_guards'] += len(decisions)
        totals['changed_top_theories'] += bool(decisions)
        result = dict(id=record['id'], complete=theory and theory['complete'],
                      direct_bound_sortals=len(guards), removed_guards=len(decisions),
                      guard_cues=[[leaf.get('text') for leaf in g.get('prov', {}).get('leaves', [])]
                                  for g in guards], backends={})
        for backend in ('horn', 'z3'):
            pair = {}
            for policy in ('strict', 'proofwriter'):
                config = dict(bench='proofwriter', backend=backend, readings='top',
                              timeout_ms=2000, domain_policy=policy, or_semantics='inclusive')
                answer = evaluate_record(record, config)
                pair[policy] = {key: answer.get(key) for key in ('answer', 'reason')}
            result['backends'][backend] = pair
            transitions[backend][str(pair['strict']['answer']) + ' -> '
                                 + str(pair['proofwriter']['answer'])] += 1
        print(json.dumps(result, ensure_ascii=False), flush=True)
    print(json.dumps(dict(kind='summary', cache=str(args.cache), selected=len(selected),
                          requested=args.limit, **totals,
                          transitions={k: dict(v) for k, v in transitions.items()},
                          limitation='top returned meanings; no gold/accuracy measurement')))


if __name__ == '__main__':
    main()
