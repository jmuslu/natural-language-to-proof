"""Verify evidence bindings before replay; never parse English or change scoring.

A digest detects change relative to a trusted record, not producer authenticity.
Legacy audits are explicitly retrospective and cannot establish producer binding.
"""
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path

import fidelity
from fidelity import unique_object, validate_case


class IntegrityError(ValueError):
    """Evidence cannot support the requested unchanged-parser replay."""


def require(condition, message):
    if not condition:
        raise IntegrityError(message)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def valid_digest(value):
    return isinstance(value, str) and len(value) == 64 and all(c in '0123456789abcdef' for c in value)


def resolve(root, value):
    path = Path(value)
    return path if path.is_absolute() else root / path


def document(path):
    data = Path(path).read_bytes()
    return json.loads(data, object_pairs_hook=unique_object), digest(data)


def rows(data):
    return [json.loads(line, object_pairs_hook=unique_object)
            for line in data.decode('utf-8').splitlines() if line.strip()]


def unique_index(items, identity, label):
    result = {}
    for row in items:
        key = identity(row)
        require(isinstance(key, str) and key, label + ': invalid ID')
        require(key not in result, label + ': duplicate ID ' + key)
        result[key] = row
    return result


def snapshot(root, report_path):
    report, report_hash = document(report_path)
    require(isinstance(report, dict), 'report must be an object')
    for key in ('cases_sha256', 'binary_sha256'):
        require(valid_digest(report.get(key)), 'invalid digest field: ' + key)
    if 'observations_sha256' in report:
        require(valid_digest(report['observations_sha256']), 'invalid observation digest')
    frozen_data = resolve(root, report['cases']).read_bytes()
    observation_data = resolve(root, report['observations']).read_bytes()
    require(digest(frozen_data) == report['cases_sha256'], 'frozen cases digest mismatch')
    return report, report_hash, frozen_data, observation_data


def audit_legacy_seal(root, report_path, audit_note):
    """Return (do not write) an explicitly retrospective audit record.

    Caller must independently audit the original artifacts and retain the note.
    This records bytes now; it does not assert they were sealed at production.
    """
    root = Path(root)
    report, report_hash, frozen, observations = snapshot(root, resolve(root, report_path))
    require('observations_sha256' not in report, 'producer digest exists; use producer seal')
    require(isinstance(audit_note, str) and audit_note.strip(), 'audit note required')
    return {'schema': 1, 'kind': 'retrospective-audited-snapshot',
            'producer_binding': False,
            'audited_at_utc': datetime.now(timezone.utc).isoformat(),
            'audit_note': audit_note,
            'report_sha256': report_hash, 'cases_sha256': digest(frozen),
            'observations_sha256': digest(observations)}


def verify_replay(root, report_path, datasets, *, required_sources=None,
                  retrospective_seal=None, helper_paths=()):
    """Return verified snapshot rows and a replay provenance manifest.

    datasets explicitly declares current membership (subset/revised gold allowed).
    All original frozen observations must remain present even for a subset replay.
    required_sources defaults to every current Haskell source plus Export.hs;
    overrides are an explicit caller trust decision, recorded in the manifest.
    helper_paths must identify any wrapper/driver responsible for this replay.
    """
    root = Path(root).resolve()
    report_path = resolve(root, report_path)
    report, report_hash, frozen_data, observation_data = snapshot(root, report_path)
    require(isinstance(datasets, dict) and datasets, 'explicit nonempty datasets required')
    if 'observations_sha256' in report:
        require(digest(observation_data) == report['observations_sha256'],
                'producer observation digest mismatch')
        require(retrospective_seal is None, 'do not override producer observation seal')
        seal_info = {'kind': 'producer-recorded-digest', 'producer_binding': 'digest recorded; authenticity not established'}
    else:
        require(retrospective_seal is not None, 'legacy observations lack producer digest; audited retrospective seal required')
        seal, seal_hash = document(resolve(root, retrospective_seal))
        require(type(seal.get('schema')) is int and seal['schema'] == 1 and seal.get('kind') == 'retrospective-audited-snapshot'
                and seal.get('producer_binding') is False, 'invalid retrospective seal kind')
        require(isinstance(seal.get('audit_note'), str) and bool(seal['audit_note'].strip())
                and isinstance(seal.get('audited_at_utc'), str) and bool(seal['audited_at_utc']),
                'retrospective audit note and time required')
        for key, wanted in [('report_sha256', report_hash), ('cases_sha256', digest(frozen_data)),
                            ('observations_sha256', digest(observation_data))]:
            require(seal.get(key) == wanted, 'retrospective seal mismatch: ' + key)
        seal_info = dict(seal, seal_sha256=seal_hash)
    binary_path = resolve(root, report['binary'])
    binary_hash = digest(binary_path.read_bytes())
    require(binary_hash == report['binary_sha256'], 'binary digest mismatch')
    defaults = sorted(str(p.relative_to(root)) for p in (root / 'src').rglob('*.hs')) + ['test/fidelity/Export.hs']
    source_names = defaults if required_sources is None else list(required_sources)
    require(source_names and len(source_names) == len(set(source_names)), 'nonempty unique source manifest required')
    producer_sources = report.get('source_sha256')
    require(isinstance(producer_sources, dict), 'producer source manifest required')
    require(all(isinstance(name, str) and valid_digest(value)
                for name, value in producer_sources.items()), 'invalid producer source digest manifest')
    # Also retain any old parser source path; deleting one cannot evade checking.
    parser_recorded = {name for name in producer_sources
                       if name.startswith('src/') or name == 'test/fidelity/Export.hs'}
    require(parser_recorded == set(source_names), 'parser source manifest membership differs')
    current_sources = {}
    for name in source_names:
        path = Path(name)
        require(not path.is_absolute() and '..' not in path.parts, 'source path must be root relative')
        actual = digest((root / path).read_bytes())
        require(producer_sources.get(name) == actual, 'parser source digest mismatch: ' + name)
        current_sources[name] = actual
    frozen = [validate_case(row) for row in rows(frozen_data)]
    frozen_index = unique_index(frozen, lambda r: r['id'], 'frozen cases')
    observations = unique_index(rows(observation_data), lambda r: r['request']['id'], 'observations')
    require(set(observations) == set(frozen_index), 'frozen observation coverage mismatch')
    for ident, case in frozen_index.items():
        observation = observations[ident]
        require(observation['request'] == {'id': ident, 'text': case['text']}, 'frozen request mismatch: ' + ident)
        require(isinstance(observation.get('response'), dict) and observation['response'].get('id') == ident,
                'response ID mismatch: ' + ident)
    current = {}
    dataset_manifest = {}
    seen_ids = set()
    seen_paths = set()
    for label, value in datasets.items():
        require(isinstance(label, str) and label, 'invalid dataset label')
        path = resolve(root, value).resolve()
        require(path not in seen_paths, 'duplicate dataset path')
        seen_paths.add(path)
        data = path.read_bytes()  # Missing explicitly selected files fail, never skip.
        cases = [validate_case(row) for row in rows(data)]
        index = unique_index(cases, lambda r: r['id'], 'current dataset ' + label)
        require(not (seen_ids & set(index)), 'duplicate current ID across datasets')
        seen_ids.update(index)
        for ident, case in index.items():
            require(ident in observations and observations[ident]['request'] == {'id': ident, 'text': case['text']},
                    'current request not bound to frozen evidence: ' + ident)
        current[label] = cases
        dataset_manifest[label] = {'path': str(path), 'sha256': digest(data),
                                   'ids': list(index),
                                   'semantics_contracts': {r['id']: r.get('semantics_contract') for r in cases}}
    tools = [Path(__file__).resolve(), Path(fidelity.__file__).resolve()]
    tools += [resolve(root, p).resolve() for p in helper_paths]
    tool_hashes = {str(p): digest(p.read_bytes()) for p in tools}
    manifest = {'schema': 1, 'seal': seal_info, 'producer_report_sha256': report_hash,
                'producer_report_path': str(report_path), 'frozen_cases_sha256': digest(frozen_data),
                'observations_sha256': digest(observation_data), 'binary_sha256': binary_hash,
                'producer_source_sha256': producer_sources, 'verified_parser_source_sha256': current_sources,
                'source_manifest_override': required_sources is not None,
                'replay_tool_sha256': tool_hashes, 'datasets': dataset_manifest,
                'frozen_ids': list(frozen_index), 'selected_ids': sorted(seen_ids),
                'interpretation': 'Integrity relative to recorded digests, not authenticated execution proof. '
                'Compiled source, external data/environment and semantic contract coherence remain separate obligations. '
                'Changed gold is rescoring; historical scores are not rewritten.'}
    return {'observations': observations, 'cases': current, 'manifest': manifest}
