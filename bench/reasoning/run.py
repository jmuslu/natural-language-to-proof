"""Gold-isolated parser/solver measurements and paired abstention-aware statistics.

The process boundary accepts only id/context/statement. Labels enter after inference
for scoring. Raw caches live at caller-chosen ignored paths and resume only when
request, binary/configuration and implementation hashes match.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'bench' / 'common'))
from analyze import wilson
from solver import answer, aggregate
from domain import normalize_theory


def read_jsonl(path):
    return [json.loads(line) for line in Path(path).read_text().splitlines() if line.strip()]


def digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, ensure_ascii=False).encode()).hexdigest()


def file_hash(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b''):
            h.update(chunk)
    return h.hexdigest()


def inference_request(x):
    return {'id': x['id'], 'context': x['context'] if 'context' in x else x['theory'],
            'statement': x['statement'] if 'statement' in x else x['question']}


def summarize(rows):
    n = len(rows)
    answered = sum(x.get('pred') is not None for x in rows)
    correct = sum(x.get('pred') == x['label'] for x in rows)
    return dict(n=n, answered=answered, correct=correct, coverage=answered / n if n else None,
                precision=correct / answered if answered else None, accuracy=correct / n if n else None,
                accuracy_wilson=wilson(correct, n) if n else None,
                precision_wilson=wilson(correct, answered) if answered else None)


def paired(rows_a, rows_b):
    a, b = {x['id']: x for x in rows_a}, {x['id']: x for x in rows_b}
    if len(a) != len(rows_a) or len(b) != len(rows_b) or a.keys() != b.keys():
        raise ValueError('paired comparisons require unique, identical item IDs')
    if any(a[k]['label'] != b[k]['label'] for k in a):
        raise ValueError('paired labels differ')
    both = neither = only_a = only_b = 0
    for k in a:
        ca, cb = a[k].get('pred') == a[k]['label'], b[k].get('pred') == b[k]['label']
        both += ca and cb
        neither += not ca and not cb
        only_a += ca and not cb
        only_b += cb and not ca
    discordant = only_a + only_b
    p = min(1.0, 2 * sum(math.comb(discordant, i) for i in range(min(only_a, only_b) + 1)) / 2 ** discordant)
    return dict(n=len(a), both_correct=both, neither_correct=neither, a_only=only_a, b_only=only_b,
                mcnemar_exact_p=p, delta_accuracy=(only_b - only_a) / len(a) if a else None)


def top_mass(document):
    """Product of per-sentence top masses within returned readings, uncalibrated."""
    probability = 1.0
    for sentence in document.get('sentences', []):
        readings = sentence.get('readings', [])
        if not readings:
            return 0.0
        scores = [r.get('score') for r in readings]
        if any(x is None or not math.isfinite(x) for x in scores):
            return 1.0 if all(len(s.get('readings', [])) == 1 for s in document.get('sentences', [])) else 0.0
        maximum = max(scores)
        probability *= math.exp(scores[0] - maximum) / sum(math.exp(x - maximum) for x in scores)
    return probability


def normalized_label(value, bench):
    if value == 'Unknown' and bench == 'prontoqa':
        return None
    return 'Uncertain' if value == 'Unknown' and bench != 'proofwriter' else value


def evaluate_record(record, config):
    """No label is accepted here. Every result is conditional on parser meanings."""
    results = []
    domain_policy = config.get('domain_policy', 'strict')
    if domain_policy != 'strict' and config.get('bench') != 'proofwriter':
        raise ValueError('ProofWriter domain policy requires the ProofWriter benchmark')
    mass = top_mass(record.get('context', {})) * top_mass(record.get('statement', {}))
    for theory in record.get('theories', []):
        drs, decisions = normalize_theory(theory['drs'], domain_policy)
        for query in theory.get('queries', []):
            if not query.get('complete', False) or query.get('drs') is None:
                r = dict(answer=None, reason='incomplete-query', residuals=query.get('residuals', []))
            else:
                r = answer(drs, query['drs'], backend=config['backend'],
                           complete=theory['complete'], timeout_ms=config['timeout_ms'],
                           or_semantics=config['or_semantics'])
            r['domain_decisions'] = decisions
            results.append(r)
            if config['readings'] == 'top':
                break
        if config['readings'] == 'top':
            break
    combined = aggregate(results, config['readings'], truncated=record.get('truncated', False))
    if config['readings'] == 'top' and mass < config.get('min_top_mass', 0):
        combined = dict(answer=None, reason='ranking-mass-threshold')
    return dict(combined, variants=results, top_mass=mass, parser_error=record.get('error'))


def parse_samples(args):
    binary = Path(args.binary).resolve()
    benches = ['proverqa', 'folio', 'proofwriter', 'prontoqa'] if args.bench == 'all' else [args.bench]
    samples = [x for bench in benches for x in read_jsonl(ROOT / 'bench' / bench / 'sample.jsonl')[:args.limit]]
    if len({x['id'] for x in samples}) != len(samples):
        raise ValueError('cache requires globally unique item IDs')
    config = dict(binary_sha256=file_hash(binary), pos_backoff=args.pos_backoff,
                  max_combinations=args.max_combinations, schema=1)
    config_hash = digest(config)
    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    existing = {x['id']: x for x in read_jsonl(output)} if output.exists() else {}
    command = [str(binary), '--max-combinations', str(args.max_combinations)]
    if args.pos_backoff:
        command.append('--pos-backoff')
    with open(str(output) + '.stderr', 'a') as err:
        process = subprocess.Popen(command, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                   stderr=err, text=True, bufsize=1)
        try:
            with output.open('a') as out:
                for row in samples:
                    request = inference_request(row)
                    request_hash = digest(request)
                    old = existing.get(row['id'])
                    if old is not None:
                        if old.get('config_hash') != config_hash or old.get('request_hash') != request_hash:
                            raise ValueError('cache mismatch: choose a new output path')
                        if 'error' not in old:
                            continue
                    t0 = time.monotonic()
                    process.stdin.write(json.dumps(request, ensure_ascii=False) + '\n')
                    process.stdin.flush()
                    line = process.stdout.readline()
                    if not line:
                        raise RuntimeError('parser terminated; inspect stderr log')
                    response = json.loads(line)
                    if response.get('id', row['id']) != row['id']:
                        raise ValueError('parser response ID mismatch')
                    response.update(id=row['id'], request_hash=request_hash, config_hash=config_hash,
                                    parse_config=config, latency=time.monotonic() - t0)
                    out.write(json.dumps(response, ensure_ascii=False) + '\n')
                    out.flush()
                    print(row['id'], response.get('error', 'parsed'), round(response['latency'], 2), flush=True)
        finally:
            process.stdin.close()
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.terminate()
                process.wait(timeout=5)


def evaluate_samples(args):
    samples = {x['id']: x for x in read_jsonl(ROOT / 'bench' / args.bench / 'sample.jsonl')[:args.limit]}
    parsed = {x['id']: x for x in read_jsonl(args.parses)}
    if not samples.keys() <= parsed.keys():
        raise ValueError('parser cache missing sample IDs')
    config = dict(backend=args.backend, readings=args.readings, timeout_ms=args.timeout_ms,
                  bench=args.bench, domain_policy=args.domain_policy,
                  or_semantics=args.or_semantics, min_top_mass=args.min_top_mass,
                  solver_sha256=file_hash(Path(__file__).with_name('solver.py')), runner_sha256=file_hash(__file__),
                  domain_sha256=file_hash(Path(__file__).with_name('domain.py')),
                  parses_sha256=file_hash(args.parses))
    config_hash = digest(config)
    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    rows = []
    with output.open('w') as out:
        for ident, sample in samples.items():
            p = parsed[ident]
            if p.get('request_hash') != digest(inference_request(sample)):
                raise ValueError('sample/parser request mismatch')
            t0 = time.monotonic()
            inference = evaluate_record(p, config)
            pred = normalized_label(inference['answer'], args.bench)
            row = dict(id=ident, label=sample['label'], pred=pred, lenient_pred=pred, inference=inference,
                       request_hash=p['request_hash'],
                       correct=pred == sample['label'], config=config, config_hash=config_hash,
                       latency=time.monotonic() - t0, parser_latency=p.get('latency'), usage=None)
            rows.append(row)
            out.write(json.dumps(row, ensure_ascii=False) + '\n')
            out.flush()
    print(json.dumps(summarize(rows), indent=2))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    subs = parser.add_subparsers(dest='command', required=True)
    p = subs.add_parser('parse')
    p.add_argument('--binary', required=True)
    p.add_argument('--pos-backoff', action='store_true')
    p.add_argument('--max-combinations', type=int, default=64)
    e = subs.add_parser('evaluate')
    e.add_argument('--parses', required=True)
    e.add_argument('--backend', choices=['horn', 'z3'], required=True)
    e.add_argument('--readings', choices=['top', 'skeptical', 'credulous'], default='top')
    e.add_argument('--or-semantics', choices=['inclusive', 'proverqa'], default='inclusive')
    e.add_argument('--timeout-ms', type=int, default=2000)
    e.add_argument('--min-top-mass', type=float, default=0)
    e.add_argument('--domain-policy', choices=['strict', 'proofwriter'], default='strict')
    for sub in (p, e):
        sub.add_argument('--bench', choices=['proofwriter', 'prontoqa', 'folio', 'proverqa', 'all'] if sub is p else ['proofwriter', 'prontoqa', 'folio', 'proverqa'], required=True)
        sub.add_argument('--limit', type=int, default=120)
        sub.add_argument('--output', required=True)
    s = subs.add_parser('stats')
    s.add_argument('paths', nargs='+')
    args = parser.parse_args()
    if args.command == 'parse':
        parse_samples(args)
    elif args.command == 'evaluate':
        evaluate_samples(args)
    else:
        rows = [read_jsonl(p) for p in args.paths]
        print(json.dumps({'summaries': dict(zip(args.paths, map(summarize, rows))),
                          'paired': paired(rows[0], rows[1]) if len(rows) == 2 else None}, indent=2))


if __name__ == '__main__':
    main()
