#!/usr/bin/env python3
"""Independent seal acceptance tests for the coordinator replay helper.

No parser/corpus run: only small invented fixtures in temporary directories.
These tests are intentionally red against the unsealed helper reviewed here.
Set FIDELITY_REPLAY_HELPER to review a replacement; no production helper copied
into the repository. Execute: python3 test/fidelity/test_replay_integrity.py -v
"""
import copy
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

HELPER = Path(os.environ.get('FIDELITY_REPLAY_HELPER',
    '/home/gram/nl2proof-astra/research/runs/integration-fidelity/replay.py'))
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

    @staticmethod
    def sha(path):
        return hashlib.sha256(path.read_bytes()).hexdigest()

    @staticmethod
    def write_rows(path, rows):
        path.write_text(''.join(json.dumps(x)+'\n' for x in rows))

    def replay(self, optimized=False):
        command = [sys.executable] + (['-O'] if optimized else []) + [str(HELPER),'audit']
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
        self.rejected()

    def test_frozen_case_bytes_are_verified(self):
        self.frozen.write_text('[]\n')
        self.rejected()

    def test_missing_frozen_observation_rejected_even_if_current_subset_hides_it(self):
        self.write_rows(self.gold_path,self.rows[:1])
        self.write_rows(self.obs_path,self.observations[:1])
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

if __name__ == '__main__':
    unittest.main()
