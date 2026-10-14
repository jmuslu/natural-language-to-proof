#!/usr/bin/env python3
"""Independent seal acceptance tests: synthetic fixtures, no parser/corpus run.

The initial nine tests exposed six failures in the original root helper (commit
5894cd0). They now target the portable verifier with the same evidence mutations.
Execute: python3 test/fidelity/test_replay_integrity.py -v
"""
import copy
import contextlib
import io
from types import SimpleNamespace
from unittest.mock import patch
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

VERIFIER = Path(__file__).with_name('replay_integrity.py')
SCORER = Path(__file__).with_name('fidelity.py')

class ReplaySealIntegrity(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.current = self.root / 'research/runs/coordination-integration'
        self.current.mkdir(parents=True)
        (self.root / 'research/runs/integration-fidelity').mkdir()
        self.gold_dir = self.root / 'test/fidelity'
        self.gold_dir.mkdir(parents=True)
        shutil.copyfile(SCORER, self.gold_dir / 'fidelity.py')
        source = self.root / 'src/Fixture.hs'
        source.parent.mkdir()
        source.write_text('-- synthetic source, never compiled\n')
        self.binary = self.current / 'synthetic-binary'
        self.binary.write_bytes(b'never executable; seal fixture only')
        self.rows = []
        self.observations = []
        for name in ('Alice', 'Bob'):
            atom = {'tag':'pred','name':'quiet','args':[{'const':name}]}
            meaning = {'drs':{'universe':[],'conditions':[atom]},
                       'claims':{'universe':[],'asserted':[atom], 'reported':[],
                                 'presupposed':[],'embedded':[]}, 'disjunctions':[]}
            row = {'id':name,'construction':'synthetic','text':name+' is quiet.',
                   'origin':{'kind':'authored-control'},'gold':[meaning]}
            response = {'schema':1,'id':name,'sentence_count':1,'parsed_sentences':1,
                        'typed_sentences':1,'drs_sentences':1,'selected':meaning,'readings':[]}
            self.rows.append(row)
            self.observations.append({'request':{'id':name,'text':row['text']},'response':response})
        self.gold_path = self.gold_dir / 'prontoqa.jsonl'
        self.frozen = self.current / 'cases.jsonl'
        self.obs_path = self.current / 'fresh.observations.jsonl'
        self.write_rows(self.gold_path, self.rows)
        self.write_rows(self.frozen, self.rows)
        self.write_rows(self.obs_path, self.observations)
        self.report = {'schema':1,'parser':'default','binary':str(self.binary),
                       'binary_sha256':self.sha(self.binary),'cases':str(self.frozen),
                       'cases_sha256':self.sha(self.frozen),
                       'source_sha256':{'src/Fixture.hs':self.sha(source)},
                       'observations':str(self.obs_path),
                       'observations_sha256':self.sha(self.obs_path)}
        self.report_path = self.current / 'fresh.json'
        self.report_path.write_text(json.dumps(self.report))
        self.driver = self.root / 'driver.py'
        self.driver.write_text(
            'import json,sys\n'
            'from pathlib import Path\n'
            'sys.path.insert(0,'+repr(str(VERIFIER.parent.resolve()))+')\n'
            'from replay_integrity import verify_replay\n'
            'seal=Path("audit-seal.json")\n'
            'result=verify_replay(Path.cwd(),"research/runs/coordination-integration/fresh.json",'
            '{"synthetic":"test/fidelity/prontoqa.jsonl"},required_sources=["src/Fixture.hs"],'
            'retrospective_seal=seal if seal.exists() else None,helper_paths=[__file__])\n'
            'Path("verified.json").write_text(json.dumps(result["manifest"]))\n')

    @staticmethod
    def sha(path):
        return hashlib.sha256(path.read_bytes()).hexdigest()

    @staticmethod
    def write_rows(path, rows):
        path.write_text(''.join(json.dumps(x)+'\n' for x in rows))

    def replay(self, optimized=False):
        command = [sys.executable] + (['-O'] if optimized else []) + [str(self.driver)]
        return subprocess.run(command,cwd=self.root,text=True,capture_output=True)

    def rejected(self, optimized=False):
        result = self.replay(optimized)
        self.assertNotEqual(result.returncode,0,'Tampered or incomplete cache was accepted as sealed replay')

    def test_intact_fixture_is_accepted(self):
        result = self.replay()
        self.assertEqual(result.returncode,0,result.stderr)

    def test_changed_response_bytes_are_rejected(self):
        changed = copy.deepcopy(self.observations)
        changed[0]['response'].update(parsed_sentences=0,typed_sentences=0,drs_sentences=0,selected=None)
        self.write_rows(self.obs_path,changed)
        self.rejected()

    def test_duplicate_observation_id_is_rejected(self):
        self.write_rows(self.obs_path,self.observations+[self.observations[0]])
        self.refresh_observation_digest()
        self.rejected()

    def test_frozen_case_bytes_are_verified(self):
        self.frozen.write_text('[]\n')
        self.rejected()

    def test_missing_frozen_observation_rejected_even_if_current_subset_hides_it(self):
        self.write_rows(self.gold_path,self.rows[:1])
        self.write_rows(self.obs_path,self.observations[:1])
        self.refresh_observation_digest()
        self.rejected()

    def test_duplicate_current_case_is_not_double_counted(self):
        self.write_rows(self.gold_path,self.rows+[self.rows[0]])
        self.rejected()

    def test_needed_observation_missing_is_rejected(self):
        self.write_rows(self.obs_path,self.observations[:1])
        self.rejected()

    def test_changed_request_text_is_rejected(self):
        changed=copy.deepcopy(self.observations)
        changed[0]['request']['text']='Alice is noisy.'
        self.write_rows(self.obs_path,changed)
        self.rejected()

    def test_binary_binding_survives_python_optimization(self):
        self.binary.write_bytes(b'changed binary')
        self.rejected(optimized=True)

    def refresh_observation_digest(self):
        self.report['observations_sha256'] = self.sha(self.obs_path)
        self.report_path.write_text(json.dumps(self.report))

    def test_intact_fixture_under_optimization(self):
        result = self.replay(optimized=True)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_changed_response_rejected_under_optimization(self):
        self.obs_path.write_text(self.obs_path.read_text() + ' \n')
        self.rejected(optimized=True)

    def test_response_id_mismatch_even_with_matching_observation_digest(self):
        changed = copy.deepcopy(self.observations)
        changed[0]['response']['id'] = 'Impostor'
        self.write_rows(self.obs_path, changed)
        self.refresh_observation_digest()
        self.rejected()

    def test_added_source_invalidates_complete_manifest(self):
        self.report['source_sha256']['src/Extra.hs'] = '0'*64
        self.report_path.write_text(json.dumps(self.report))
        self.rejected()

    def test_changed_source_rejected_under_optimization(self):
        (self.root/'src/Fixture.hs').write_text('changed source')
        self.rejected(optimized=True)

    def test_missing_explicit_dataset_rejected(self):
        self.gold_path.unlink()
        self.rejected()

    def test_duplicate_frozen_id_even_with_updated_digest(self):
        self.write_rows(self.frozen, self.rows + [self.rows[0]])
        self.report['cases_sha256'] = self.sha(self.frozen)
        self.report_path.write_text(json.dumps(self.report))
        self.rejected()

    def test_legacy_without_audit_seal_rejected(self):
        del self.report['observations_sha256']
        self.report_path.write_text(json.dumps(self.report))
        self.rejected()

    def make_legacy_seal(self):
        from replay_integrity import audit_legacy_seal
        del self.report['observations_sha256']
        self.report_path.write_text(json.dumps(self.report))
        seal = audit_legacy_seal(self.root,self.report_path,'Independent synthetic fixture audit only')
        (self.root/'audit-seal.json').write_text(json.dumps(seal))

    def test_explicit_retrospective_seal_remains_labeled(self):
        self.make_legacy_seal()
        result = self.replay()
        self.assertEqual(result.returncode,0,result.stderr)
        manifest=json.loads((self.root/'verified.json').read_text())
        self.assertEqual(manifest['seal']['kind'],'retrospective-audited-snapshot')
        self.assertIs(manifest['seal']['producer_binding'],False)
        self.assertTrue(manifest['source_manifest_override'])
        self.assertIn(str(self.driver),manifest['replay_tool_sha256'])

    def test_retrospective_seal_rejects_later_changed_report(self):
        self.make_legacy_seal()
        self.report['parser']='changed-mode'
        self.report_path.write_text(json.dumps(self.report))
        self.rejected()

    def test_current_gold_only_rescore_records_new_digest(self):
        changed=copy.deepcopy(self.rows)
        changed[0]['notes']='Explicit gold revision; request and observations unchanged'
        self.write_rows(self.gold_path,changed)
        result=self.replay()
        self.assertEqual(result.returncode,0,result.stderr)
        manifest=json.loads((self.root/'verified.json').read_text())
        self.assertEqual(manifest['datasets']['synthetic']['sha256'],self.sha(self.gold_path))
        self.assertEqual(manifest['frozen_cases_sha256'],self.report['cases_sha256'])
        self.assertNotEqual(manifest['datasets']['synthetic']['sha256'],manifest['frozen_cases_sha256'])

    def test_explicit_current_subset_keeps_full_original_observations(self):
        self.write_rows(self.gold_path,self.rows[:1])
        result=self.replay()
        self.assertEqual(result.returncode,0,result.stderr)
        manifest=json.loads((self.root/'verified.json').read_text())
        self.assertEqual(manifest['selected_ids'],['Alice'])
        self.assertEqual(manifest['frozen_ids'],['Alice','Bob'])

    def test_producer_records_exact_observation_digest_without_parser_launch(self):
        import fidelity
        (self.gold_dir/'Export.hs').write_text('-- synthetic export fixture')
        (self.gold_dir/'run.py').write_text('# synthetic launcher fixture')
        result=SimpleNamespace(stdout=''.join(json.dumps(x['response'])+'\n' for x in self.observations),stderr='')
        output=self.current/'produced.json'
        argv=['fidelity','--cases',str(self.gold_path),'--binary',str(self.binary),
              '--parser','hand','--output',str(output)]
        with patch.object(fidelity,'ROOT',self.root), patch.object(sys,'argv',argv), \
             patch.object(fidelity.subprocess,'run',return_value=result) as mocked, \
             contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(fidelity.main(),0)
        mocked.assert_called_once()
        report=json.loads(output.read_text())
        self.assertEqual(report['observations_sha256'],self.sha(Path(report['observations'])))

    def test_cross_dataset_duplicate_current_id_rejected(self):
        from replay_integrity import verify_replay,IntegrityError
        other=self.gold_dir/'duplicate.jsonl'
        self.write_rows(other,self.rows[:1])
        with self.assertRaises(IntegrityError):
            verify_replay(self.root,self.report_path,{'one':self.gold_path,'two':other},
                          required_sources=['src/Fixture.hs'])

    def test_retrospective_seal_requires_explicit_audit_note(self):
        from replay_integrity import audit_legacy_seal,IntegrityError
        del self.report['observations_sha256']
        self.report_path.write_text(json.dumps(self.report))
        with self.assertRaises(IntegrityError):
            audit_legacy_seal(self.root,self.report_path,'   ')

    def test_malformed_recorded_scorer_digest_rejected(self):
        self.report['source_sha256']['test/fidelity/fidelity.py']='not-a-sha256'
        self.report_path.write_text(json.dumps(self.report))
        self.rejected()

    def test_legacy_factory_resolves_report_from_root_not_working_directory(self):
        from replay_integrity import audit_legacy_seal
        del self.report['observations_sha256']
        self.report_path.write_text(json.dumps(self.report))
        relative=self.report_path.relative_to(self.root)
        seal=audit_legacy_seal(self.root,relative,'Independent relative-path fixture audit')
        self.assertEqual(seal['report_sha256'],self.sha(self.report_path))

    def test_boolean_retrospective_schema_rejected(self):
        self.make_legacy_seal()
        path=self.root/'audit-seal.json'
        seal=json.loads(path.read_text())
        seal['schema']=True
        path.write_text(json.dumps(seal))
        self.rejected()

    def test_hashes_actual_scorer_when_verifier_is_staged_elsewhere(self):
        staged=self.root/'staged-verifier'
        staged.mkdir()
        shutil.copyfile(VERIFIER,staged/'replay_integrity.py')
        self.driver.write_text(
            'import json,sys\n'
            'from pathlib import Path\n'
            'sys.path[:0]='+repr([str(staged),str(self.gold_dir)])+'\n'
            'from replay_integrity import verify_replay\n'
            'result=verify_replay(Path.cwd(),"research/runs/coordination-integration/fresh.json",'
            '{"synthetic":"test/fidelity/prontoqa.jsonl"},required_sources=["src/Fixture.hs"],'
            'helper_paths=[__file__])\n'
            'Path("verified.json").write_text(json.dumps(result["manifest"]))\n')
        result=self.replay()
        self.assertEqual(result.returncode,0,result.stderr)
        manifest=json.loads((self.root/'verified.json').read_text())
        actual_scorer=str((self.gold_dir/'fidelity.py').resolve())
        self.assertEqual(manifest['replay_tool_sha256'][actual_scorer],self.sha(Path(actual_scorer)))
        self.assertIn(str(staged/'replay_integrity.py'),manifest['replay_tool_sha256'])
        self.assertNotIn(str(staged/'fidelity.py'),manifest['replay_tool_sha256'])

if __name__ == '__main__':
    unittest.main()
