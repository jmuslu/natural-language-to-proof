#!/usr/bin/env python3
"""Reproducible Phase E scoring over saved outputs; never invokes inference.

Usage: python bench/reasoning/report.py --manifest manifest.json --output report.json
Manifest: {"bench":"proverqa", "limit":12, "runs":[
 {"name":"A-low", "condition":"A", "timing":"fresh", "path":"...jsonl"},
 {"name":"C", "condition":"C", "timing":"fresh", "path":"...jsonl"}]}
Paths are relative to the repository root. Omit limit for the complete sample;
optional sample overrides bench/<bench>/sample.jsonl. Optional pairs:[[name,name]]
adds comparisons; otherwise every A is compared with every C/D automatically.
Metadata fields (timing, model, effort, notes) are copied verbatim, not inferred
from filenames. Historical rows without request hashes have weaker identity checks.

Missing rows remain visible in full-sample summaries as pending, and suppress
paired tests. Use an explicit common limit for operational pilots. Duplicate IDs
are rejected: select retries explicitly while separately accounting for their cost.
Errors, tool-using model rows and off-label responses count as unanswered. Raw
answers use their benchmark's existing strict/lenient parser; solver/translation
rows use stored predictions. Cached/reasoning tokens are subsets, never added a
second time. Retry usage without complete accounting is a lower bound. Row latency
sums are not concurrent-job wall time, and no end-to-end latency is invented.

Observed top-mass curves are descriptive on this fixed sample. They threshold
saved predictions only, at each distinct observed mass (keeping ties). Mass is
uncalibrated within returned readings, not a probability of English correctness.
The script never selects a threshold or changes admission; capped or already
abstained predictions remain unanswered. Missing masses remain in the denominator.
"""
import argparse
from collections import Counter
import importlib.util
import json
import math
from pathlib import Path

from run import ROOT, digest, file_hash, inference_request, read_jsonl, summarize, paired, wilson

LABELS = {'proofwriter': ('True', 'False', 'Unknown'), 'prontoqa': ('True', 'False'),
          'folio': ('True', 'False', 'Uncertain'), 'proverqa': ('True', 'False', 'Uncertain')}
TOKEN_KEYS = ('input_tokens', 'cached_input_tokens', 'cache_write_input_tokens',
              'output_tokens', 'reasoning_output_tokens', 'total_tokens')


def load_parser(path, name):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


COMMON = load_parser(ROOT / 'bench/common/scoring.py', 'report_common_scoring')
PW = load_parser(ROOT / 'bench/proofwriter/scoring.py', 'report_pw_scoring')


def canonical(value, bench):
    if type(value) is bool:
        value = 'True' if value else 'False'
    if value == 'Unknown' and bench != 'proofwriter':
        value = 'Uncertain'
    if value == 'Uncertain' and bench == 'proofwriter':
        value = 'Unknown'
    return value if value in LABELS[bench] else None


def prediction(row, bench, condition, mode):
    if 'error' in row or row.get('tool_items', 0) or row.get('tool_calls', 0):
        return None
    stored = (condition == 'B' or row.get('route') in ('B', 'abstain', 'translate')
              or row.get('inference', {}).get('strength') == 'LLMTranslated' or 'raw' not in row)
    if stored:
        return canonical(row.get('lenient_pred', row.get('pred')) if mode == 'lenient' else row.get('pred'), bench)
    parser = PW if bench == 'proofwriter' else COMMON
    function = parser.lenient_parse if mode == 'lenient' else parser.strict_parse
    raw = row.get('raw') or ''
    parsed = function(raw) if bench == 'proofwriter' else function(raw, LABELS[bench])
    return canonical(parsed, bench)


def normalize_rows(samples, records, bench, condition):
    if bench not in LABELS:
        raise ValueError('unsupported benchmark')
    ids = [x['id'] for x in samples]
    by_id = {x['id']: x for x in records}
    if len(set(ids)) != len(ids) or len(by_id) != len(records):
        raise ValueError('duplicate item IDs; resolve retries explicitly')
    if set(by_id) - set(ids):
        raise ValueError('result IDs outside selected sample')
    output = dict(strict=[], lenient=[], pending=[], request_hash_rows=0)
    for sample in samples:
        gold = canonical(sample['label'], bench)
        if gold is None:
            raise ValueError('invalid sample label')
        row = by_id.get(sample['id'])
        if row is None:
            output['pending'].append(sample['id'])
            row = {}
        if 'label' in row and canonical(row['label'], bench) != gold:
            raise ValueError('result/sample gold mismatch')
        if row.get('request_hash'):
            if row['request_hash'] != digest(inference_request(sample)):
                raise ValueError('result/sample request mismatch')
            output['request_hash_rows'] += 1
        for mode in ('strict', 'lenient'):
            output[mode].append(dict(id=sample['id'], label=gold,
                                     pred=prediction(row, bench, condition, mode)))
    return output


def compare_runs(a, b):
    if a['pending'] or b['pending']:
        return dict(status='incomplete', pending_a=len(a['pending']), pending_b=len(b['pending']))
    return dict(status='paired', **{mode: paired(a[mode], b[mode]) for mode in ('strict', 'lenient')})


def score_summary(rows):
    result = summarize(rows)
    result['coverage_wilson'] = wilson(result['answered'],result['n']) if result['n'] else None
    return result


def number(value):
    return value if type(value) in (int, float) and math.isfinite(value) and value >= 0 else None


def risk_coverage(records, normalized):
    observed = any('top_mass' in row.get('inference', {}) for row in records)
    if not observed:
        return None
    masses = {}
    for row in records:
        mass = number(row.get('inference', {}).get('top_mass'))
        if mass is not None and mass <= 1:
            masses[row['id']] = mass
    result = dict(mass_rows=len(masses),
                  missing_or_invalid_mass_rows=len(normalized['strict'])-len(masses),
                  interpretation='Fixed-sample descriptive curve over saved predictions; uncalibrated mass within returned readings. No threshold chosen or admission changed.')
    for mode in ('strict', 'lenient'):
        points = []
        for threshold in sorted(set(masses.values())):
            eligible = {ident for ident, mass in masses.items() if mass >= threshold}
            rows = [dict(row, pred=row['pred'] if row['id'] in eligible else None)
                    for row in normalized[mode]]
            point = score_summary(rows)
            precision = point['precision']
            point.update(threshold=threshold, mass_eligible=len(eligible),
                         risk=1-precision if precision is not None else None,
                         risk_wilson=[1-v for v in reversed(point['precision_wilson'])]
                         if point['precision_wilson'] is not None else None)
            points.append(point)
        result[mode] = points
    return result


def usage_values(row, no_call):
    if no_call:
        return {key: 0 for key in TOKEN_KEYS}
    usage = row.get('usage') if isinstance(row.get('usage'), dict) else {}
    aliases = dict(input_tokens='promptTokenCount', cached_input_tokens='cachedContentTokenCount',
                   reasoning_output_tokens='thoughtsTokenCount')
    values = {key: number(usage.get(key, usage.get(aliases.get(key)))) for key in TOKEN_KEYS[:-1]}
    if values['output_tokens'] is None and number(usage.get('candidatesTokenCount')) is not None:
        # Gemini separates visible candidate and thought output, unlike Codex.
        values['output_tokens'] = usage['candidatesTokenCount'] + (number(usage.get('thoughtsTokenCount')) or 0)
    values['total_tokens'] = (values['input_tokens'] + values['output_tokens']
                              if values['input_tokens'] is not None and values['output_tokens'] is not None else None)
    return values


def metric(values, n):
    present = [x for x in values if x is not None]
    total = sum(present) if present else None
    return dict(sum=total, n_reported=len(present), per_selected_item=total/n if n and present else None,
                per_reported_item=total/len(present) if present else None)


def cost_summary(records, condition, n):
    tokens = {key: [] for key in TOKEN_KEYS}
    latency = {key: [] for key in ('call_wall_seconds', 'final_attempt_seconds',
                                  'parser_seconds', 'preparation_seconds', 'solver_seconds')}
    unknown = retries = missing_attempts = no_calls = 0
    for row in records:
        no_call = row.get('route') in ('B', 'abstain') or (condition == 'B' and row.get('usage') is None)
        no_calls += no_call
        values = usage_values(row, no_call)
        for key, value in values.items():
            tokens[key].append(value)
        attempts = 0 if no_call else number(row.get('attempts'))
        missing_attempts += attempts is None
        retries += max(0, attempts-1) if attempts is not None else 0
        known = no_call or (values['total_tokens'] is not None and
                           row.get('total_attempt_usage_known', attempts == 1))
        unknown += not known
        wall = (0 if no_call else number(row.get('llm_latency', row.get('wall_latency'))))
        if wall is None and attempts == 1:
            wall = number(row.get('latency'))
        latency['call_wall_seconds'].append(wall)
        latency['final_attempt_seconds'].append(0 if no_call else number(row.get('latency')))
        latency['parser_seconds'].append(number(row.get('parser_latency')))
        latency['preparation_seconds'].append(number(row.get('preparation_latency')))
        latency['solver_seconds'].append(number(row.get('latency')) if no_call else None)
    return dict(reported_tokens={key: metric(v,n) for key,v in tokens.items()},
                latencies={key: metric(v,n) for key,v in latency.items()},
                unknown_total_token_rows=unknown, pending_cost_rows=n-len(records),
                known_retry_count=retries, missing_attempt_count_rows=missing_attempts,
                no_model_call_rows=no_calls,
                fully_known_total_usage=unknown == 0 and len(records) == n,
                errors=sum('error' in r for r in records),
                tool_using_rows=sum(bool(r.get('tool_items',0) or r.get('tool_calls',0)) for r in records),
                interpretation='Reported token sums may omit retries; cached/reasoning are subsets. Latencies are separate row measurements.')


def analyze(manifest):
    bench = manifest['bench']
    sample_path = ROOT / manifest.get('sample', f'bench/{bench}/sample.jsonl')
    complete_sample = read_jsonl(sample_path)
    selected = complete_sample[:manifest.get('limit')]
    all_ids, selected_ids = {x['id'] for x in complete_sample}, {x['id'] for x in selected}
    summaries, normalized = {}, {}
    descriptors = manifest['runs']
    if len({x['name'] for x in descriptors}) != len(descriptors):
        raise ValueError('duplicate run names')
    for descriptor in descriptors:
        path = ROOT / descriptor['path']
        records = read_jsonl(path)
        if len({r['id'] for r in records}) != len(records):
            raise ValueError('duplicate result IDs; resolve retries explicitly')
        if any(r['id'] not in all_ids for r in records):
            raise ValueError('result from a different sample')
        rows = [row for row in records if row['id'] in selected_ids]
        norm = normalize_rows(selected, rows, bench, descriptor['condition'])
        normalized[descriptor['name']] = norm
        summaries[descriptor['name']] = dict(
            metadata={key:value for key,value in descriptor.items() if key != 'path'},
            timing=descriptor.get('timing','unspecified'), path=str(path), sha256=file_hash(path),
            selected_n=len(selected), records=len(rows), ignored_outside_selection=len(records)-len(rows),
            pending=norm['pending'], request_hash_rows=norm['request_hash_rows'],
            legacy_identity_rows=len(rows)-norm['request_hash_rows'],
            config_hashes=sorted({r['config_hash'] for r in rows if r.get('config_hash')}),
            latency_scopes=sorted({r['latency_scope'] for r in rows if r.get('latency_scope')}),
            routes=dict(Counter(r['route'] for r in rows if r.get('route'))),
            inference_reasons=dict(Counter(r.get('inference',{}).get('reason') for r in rows
                                           if r.get('inference',{}).get('reason'))),
            inference_strengths=dict(Counter(r.get('inference',{}).get('strength') for r in rows
                                             if r.get('inference',{}).get('strength'))),
            strict=score_summary(norm['strict']), lenient=score_summary(norm['lenient']),
            risk_coverage=risk_coverage(rows,norm),
            cost=cost_summary(rows,descriptor['condition'],len(selected)))
    comparisons = manifest.get('pairs')
    if comparisons is None:
        comparisons = [(a['name'],b['name']) for a in descriptors if a['condition']=='A'
                       for b in descriptors if b['condition'] in ('C','D')]
    paired_results = {a+' -> '+b: compare_runs(normalized[a],normalized[b]) for a,b in comparisons}
    return dict(bench=bench, sample_sha256=file_hash(sample_path), sample_size=len(selected),
                manifest=manifest, manifest_sha256=digest(manifest), script_sha256=file_hash(__file__),
                dependency_sha256={str(p.relative_to(ROOT)):file_hash(p) for p in
                    [ROOT/'bench/reasoning/run.py', ROOT/'bench/common/analyze.py',
                     ROOT/'bench/common/scoring.py', ROOT/'bench/proofwriter/scoring.py']},
                runs=summaries, paired=paired_results,
                caution='Intervals describe this selected sample. P values are unadjusted exploratory paired comparisons; historical prompt/CLI costs may differ.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--manifest', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    report = analyze(json.loads(args.manifest.read_text()))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report,indent=2,sort_keys=True)+'\n')
    print(json.dumps(dict(bench=report['bench'], n=report['sample_size'],
                         scores={name:dict(strict=r['strict']['correct'],lenient=r['lenient']['correct'],
                                           answered=r['strict']['answered'],pending=len(r['pending']))
                                 for name,r in report['runs'].items()}, paired=report['paired']),indent=2))


if __name__ == '__main__':
    main()
