#!/usr/bin/env python3
"""Independent protocol controls. Initially red on pre-protocol verifier.

Synthetic files only: no binary executes, no model or corpus loads. These test
metadata consistency after digests are deliberately refreshed, so a passing
hash check alone cannot substitute for the proposed execution contract.
"""
import copy
import json
import unittest
from unittest.mock import patch
from types import SimpleNamespace
import contextlib
import io
import os
from pathlib import Path
import subprocess
import sys
import fidelity
import replay_integrity
import test_replay_integrity as replaytests

KNOWN = {'schema': 'nominal-policy-v1', 'parser': 'default', 'nominal_nouns': 'known-only'}
UNKNOWN = dict(KNOWN, nominal_nouns='context-unknown')

class NominalPolicyProtocol(unittest.TestCase):
    setUp = replaytests.ReplaySealIntegrity.setUp
    sha = staticmethod(replaytests.ReplaySealIntegrity.sha)
    write_rows = staticmethod(replaytests.ReplaySealIntegrity.write_rows)
    replay = replaytests.ReplaySealIntegrity.replay

    def write_protocol(self, report_mode=KNOWN, response_modes=None):
        self.report['execution'] = copy.deepcopy(report_mode)
        if response_modes is None:
            response_modes = [report_mode] * len(self.observations)
        for row, mode in zip(self.observations, response_modes):
            if mode is not None:
                row['response']['execution'] = copy.deepcopy(mode)
        self.write_rows(self.obs_path, self.observations)
        self.report['observations_sha256'] = self.sha(self.obs_path)
        self.report_path.write_text(json.dumps(self.report))

    def reject(self):
        for optimized in (False, True):
            with self.subTest(optimized=optimized):
                result = self.replay(optimized)
                self.assertNotEqual(result.returncode, 0,
                    'Mode mismatch accepted after refreshing artifact digests')

    def test_consistent_known_mode_accepts(self):
        self.write_protocol()
        result = self.replay()
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_enabled_mode_is_bound_into_replay_manifest(self):
        self.write_protocol(UNKNOWN)
        result = self.replay()
        self.assertEqual(result.returncode, 0, result.stderr)
        manifest = json.loads((self.root / 'verified.json').read_text())
        self.assertEqual(manifest.get('execution'), UNKNOWN)

    def test_enabled_report_cannot_relabel_known_responses(self):
        self.write_protocol(UNKNOWN, [KNOWN, KNOWN])
        self.reject()

    def test_mixed_response_modes_rejected(self):
        self.write_protocol(KNOWN, [KNOWN, UNKNOWN])
        self.reject()

    def test_missing_response_echo_rejected_for_versioned_report(self):
        self.write_protocol(KNOWN, [KNOWN, None])
        self.reject()

    def test_unknown_policy_value_rejected(self):
        self.write_protocol(dict(KNOWN, nominal_nouns='automatic'))
        self.reject()

    def test_boolean_protocol_schema_rejected(self):
        for schema in [True,1,1.0,None,'nominal-policy-v2']:
            with self.subTest(schema=schema):
                self.write_protocol(dict(KNOWN, schema=schema))
                self.reject()

    def test_report_frontend_mismatch_rejected(self):
        self.write_protocol(dict(KNOWN, parser='pos'))
        self.reject()

    def test_hand_frontend_cannot_claim_unknown_nominal_policy(self):
        self.report['parser'] = 'hand'
        self.write_protocol(dict(UNKNOWN, parser='hand'))
        self.reject()

    def direct_replay(self, expected=None):
        return replay_integrity.verify_replay(self.root,self.report_path,
            {'fixture':self.gold_path},required_sources=['src/Fixture.hs'],
            expected_execution=expected)

    def test_requested_mode_must_match_sealed_mode(self):
        self.write_protocol(KNOWN)
        with self.assertRaises(ValueError):self.direct_replay(UNKNOWN)
        self.assertEqual(self.direct_replay(KNOWN)['manifest']['execution'],KNOWN)

    def test_legacy_missing_mode_stays_unrecorded(self):
        manifest=self.direct_replay()['manifest']
        self.assertIsNone(manifest['execution'])
        self.assertEqual(manifest['execution_binding'],'legacy-unrecorded')
        with self.assertRaises(ValueError):self.direct_replay(KNOWN)
        with self.assertRaises(ValueError):self.direct_replay(UNKNOWN)

    def test_partial_legacy_declaration_rejected(self):
        self.write_protocol(KNOWN)
        del self.report['execution']
        self.report_path.write_text(json.dumps(self.report))
        with self.assertRaises(ValueError):self.direct_replay()

    def test_subset_still_checks_unselected_response_mode(self):
        self.write_protocol(KNOWN,[KNOWN,UNKNOWN])
        self.write_rows(self.gold_path,self.rows[:1])
        with self.assertRaises(ValueError):self.direct_replay(KNOWN)

    def test_null_and_extra_key_execution_rejected(self):
        for execution in [None,dict(KNOWN,extra=True)]:
            with self.subTest(execution=execution):
                self.write_protocol(execution)
                with self.assertRaises(ValueError):self.direct_replay()

    def scorer(self, requested=None, echoed=KNOWN, parser='default', error=False):
        output=self.root/'output.json'
        argv=['run.py','--cases',str(self.gold_path),'--binary',str(self.binary),
              '--parser',parser,'--output',str(output)]
        if requested is not None:argv+=['--nominal-nouns',requested]
        responses=[copy.deepcopy(o['response']) for o in self.observations]
        for response in responses:
            if echoed is not None:response['execution']=echoed
            if error:response['error']='synthetic parser error'
        result=SimpleNamespace(stdout=''.join(json.dumps(r)+'\n' for r in responses),stderr='')
        with patch.object(sys,'argv',argv),patch.object(fidelity,'ROOT',self.root), \
             patch.object(fidelity.subprocess,'run',return_value=result) as invocation, \
             contextlib.redirect_stdout(io.StringIO()):
            # Hash plumbing needs only synthetic paths; never execute binary.
            for name in ['Export.hs','run.py']:(self.gold_dir/name).write_text('-- fixture')
            code=fidelity.main()
        return code,invocation.call_args,json.loads(output.read_text())

    def test_scorer_explicit_known_and_enabled_invocations(self):
        for parser in ['default','pos']:
            for requested,mode in [(None,KNOWN),('context-unknown',UNKNOWN)]:
                echo=dict(mode,parser=parser)
                code,call,report=self.scorer(requested,echo,parser)
                self.assertEqual(code,0)
                self.assertIn('--nominal-nouns='+echo['nominal_nouns'],call.args[0])
                self.assertEqual('--pos-backoff' in call.args[0],parser=='pos')
                self.assertEqual(report['execution'],echo)
                requests=[json.loads(r) for r in call.kwargs['input'].splitlines()]
                self.assertTrue(all(set(r)=={'id','text'} for r in requests))

    def test_scorer_mismatch_and_missing_echo_abort_before_scoring(self):
        for echo in [UNKNOWN,None]:
            with self.subTest(echo=echo),patch.object(fidelity,'evaluate_case') as score:
                with self.assertRaises(ValueError):self.scorer(echoed=echo)
                score.assert_not_called()
                self.assertFalse((self.root/'output.json').exists())

    def test_error_response_still_requires_matching_echo(self):
        with patch.object(fidelity,'evaluate_case') as score:
            with self.assertRaises(ValueError):self.scorer(echoed=UNKNOWN,error=True)
            score.assert_not_called()

    def test_hand_invocation_and_invalid_explicit_policy(self):
        hand=dict(KNOWN,parser='hand',nominal_nouns='not-applicable')
        _,call,report=self.scorer(echoed=hand,parser='hand')
        self.assertIn('--hand',call.args[0]);self.assertEqual(report['execution'],hand)
        with contextlib.redirect_stderr(io.StringIO()),patch.object(fidelity.subprocess,'run') as run:
            with self.assertRaises(SystemExit):self.scorer('known-only',hand,'hand')
            run.assert_not_called()


@unittest.skipUnless(os.environ.get('NOMINAL_PROTOCOL_EXPORTER'),
                     'Set NOMINAL_PROTOCOL_EXPORTER to built candidate (no CCG loads)')
class ExporterExecutionProtocol(unittest.TestCase):
    def invoke(self,args,text=''):
        return subprocess.run([os.environ['NOMINAL_PROTOCOL_EXPORTER']]+args,
            input=text,text=True,capture_output=True,timeout=20)

    def test_hand_success_and_error_echo_actual_mode(self):
        requests=[{'id':'ok','text':'Alice sleeps.'}, {'id':'bad','text':'Alice sleeps.','gold':True}]
        result=self.invoke(['--hand'],''.join(json.dumps(r)+'\n' for r in requests))
        self.assertEqual(result.returncode,0,result.stderr)
        responses=[json.loads(r) for r in result.stdout.splitlines()]
        self.assertEqual(len(responses),2)
        for response in responses:
            fidelity.validate_execution(response['execution'])
            self.assertEqual(response['execution'],
                {'schema':'nominal-policy-v1','parser':'hand','nominal_nouns':'not-applicable'})
        self.assertNotIn('error',responses[0]);self.assertIn('error',responses[1])

    def test_invalid_flags_fail_before_model_loading(self):
        for args in [['--nominal-nouns=automatic'],
                     ['--nominal-nouns=known-only','--nominal-nouns=context-unknown'],
                     ['--nominal-nouns=known-only','--nominal-nouns=known-only'],
                     ['--hand','--nominal-nouns=known-only'],['--hand','--pos-backoff']]:
            with self.subTest(args=args):
                result=self.invoke(args)
                self.assertNotEqual(result.returncode,0)
                self.assertNotIn('loading CCGbank',result.stderr)

if __name__ == '__main__':
    unittest.main()
