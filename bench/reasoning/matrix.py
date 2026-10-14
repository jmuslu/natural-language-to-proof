"""Evaluate all reading policies while solving each returned variant only once.

This is an experiment driver, not a second reasoner. All inference goes through
solver.py. It writes local per-item results and a small aggregate summary; the
same item IDs and sample labels are joined only after inference.
"""
import argparse
from collections import Counter
import json
from pathlib import Path
import time

from run import ROOT, read_jsonl, digest, file_hash, inference_request, evaluate_record, normalized_label, summarize
from solver import aggregate


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--parses', required=True)
    ap.add_argument('--out-dir', required=True)
    ap.add_argument('--benches', nargs='+', default=['proverqa', 'folio', 'proofwriter', 'prontoqa'])
    ap.add_argument('--limit', type=int, default=120)
    ap.add_argument('--timeout-ms', type=int, default=2000)
    args = ap.parse_args()
    parsed = {x['id']: x for x in read_jsonl(args.parses)}
    out = Path(args.out_dir)
    out.mkdir(parents=True, exist_ok=True)
    identity = {'parses_sha256': file_hash(args.parses), 'solver_sha256': file_hash(Path(__file__).with_name('solver.py')),
                'runner_sha256': file_hash(Path(__file__).with_name('run.py')), 'matrix_sha256': file_hash(__file__)}
    summaries = {}
    for bench in args.benches:
        samples = read_jsonl(ROOT / 'bench' / bench / 'sample.jsonl')[:args.limit]
        if any(x['id'] not in parsed for x in samples):
            raise ValueError('incomplete parser cache for ' + bench)
        for backend in ['horn', 'z3']:
            for or_policy in (['inclusive', 'proverqa'] if bench == 'proverqa' and backend == 'z3' else ['inclusive']):
                configs = [(reading, mass) for reading in ['top', 'skeptical', 'credulous']
                           for mass in ([0, .5, .8, .95] if reading == 'top' else [0])]
                outputs = {}
                rows = {key: [] for key in configs}
                try:
                    for reading, mass in configs:
                        name = f'{bench}-{backend}-{reading}-{or_policy}' + (f'-mass{mass:g}' if mass else '')
                        outputs[(reading, mass)] = ((out / (name + '.jsonl')).open('w'), name)
                    for sample in samples:
                        record = parsed[sample['id']]
                        if record.get('request_hash') != digest(inference_request(sample)):
                            raise ValueError('sample/parser request mismatch')
                        config = dict(backend=backend, timeout_ms=args.timeout_ms, or_semantics=or_policy,
                                      readings='skeptical', min_top_mass=0, **identity)
                        t0 = time.monotonic()
                        solved = evaluate_record(record, config)
                        elapsed = time.monotonic() - t0
                        variants = solved['variants']
                        for reading, mass in configs:
                            final = aggregate(variants, reading, truncated=record.get('truncated', False))
                            if reading == 'top' and solved['top_mass'] < mass:
                                final = dict(answer=None, reason='ranking-mass-threshold')
                            cfg = dict(config, readings=reading, min_top_mass=mass)
                            pred = normalized_label(final['answer'], bench)
                            # Keep rich first proof for graph-context generation. Other
                            # variants need only compact proof outcomes in these reports.
                            compact = variants[:1] if reading == 'top' else [
                                {k: v for k, v in r.items() if k != 'facts'} for r in variants]
                            row = dict(id=sample['id'], label=sample['label'], pred=pred, lenient_pred=pred,
                                       correct=pred == sample['label'], config=cfg, config_hash=digest(cfg),
                                       inference=dict(final, variants=compact, top_mass=solved['top_mass'],
                                                      enumerated_variants=len(variants)),
                                       latency=elapsed, latency_scope='all variants shared across policies', usage=None)
                            rows[(reading, mass)].append(row)
                            handle, _ = outputs[(reading, mass)]
                            handle.write(json.dumps(row, ensure_ascii=False) + '\n')
                            handle.flush()
                        print(bench, backend, or_policy, sample['id'], len(variants), round(elapsed, 3), flush=True)
                    for key, records in rows.items():
                        _, name = outputs[key]
                        summaries[name] = dict(summarize(records), reasons=dict(Counter(x['inference']['reason'] for x in records)),
                                               config_hash=records[0]['config_hash'] if records else None)
                    (out / 'summary.json').write_text(json.dumps(summaries, indent=2) + '\n')
                finally:
                    for handle, _ in outputs.values():
                        handle.close()
    print(json.dumps(summaries, indent=2))


if __name__ == '__main__':
    main()
