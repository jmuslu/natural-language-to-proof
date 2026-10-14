"""Independent either wire/replay controls and opt-in actual exporter probes.
Actual probes use miniature lexical models only; no corpus is loaded.
"""
import copy
import contextlib
import io
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch
import fidelity
import replay_integrity
import test_replay_integrity as fixtures

V1={'schema':'nominal-policy-v1','parser':'default','nominal_nouns':'known-only'}
DISABLED=dict(V1,schema='parser-policy-v2',either_policy='legacy-disabled')
ENABLED=dict(DISABLED,either_policy='surface-inclusive-v1')

class EitherProtocolProposal(unittest.TestCase):
    setUp=fixtures.ReplaySealIntegrity.setUp
    sha=staticmethod(fixtures.ReplaySealIntegrity.sha)
    write_rows=staticmethod(fixtures.ReplaySealIntegrity.write_rows)

    def protocol(self, mode, echoes=None):
        self.report['execution']=copy.deepcopy(mode)
        for observation,echo in zip(self.observations,echoes or [mode]*2):
            observation['response']['execution']=copy.deepcopy(echo)
        self.write_rows(self.obs_path,self.observations)
        self.report['observations_sha256']=self.sha(self.obs_path)
        self.report_path.write_text(json.dumps(self.report))

    def replay(self, expected=None):
        return replay_integrity.verify_replay(self.root,self.report_path,
            {'synthetic':self.gold_path},required_sources=['src/Fixture.hs'],
            expected_execution=expected)

    def test_v1_is_accepted_without_rewriting(self):
        self.assertEqual(fidelity.validate_execution(V1),V1)
        self.protocol(V1)
        self.assertEqual(self.replay(V1)['manifest']['execution'],V1)

    def test_v1_cannot_smuggle_enabled_field(self):
        with self.assertRaises(ValueError):fidelity.validate_execution(dict(V1,either_policy='surface-inclusive-v1'))

    def test_explicit_v2_disabled_and_enabled_are_supported(self):
        for mode in (DISABLED,ENABLED):
            with self.subTest(mode=mode):self.assertEqual(fidelity.validate_execution(mode),mode)

    def test_v2_replay_binds_exact_mode(self):
        for mode in (DISABLED,ENABLED):
            with self.subTest(mode=mode):
                self.protocol(mode)
                self.assertEqual(self.replay(mode)['manifest']['execution'],mode)

    def test_v2_invalid_schema_enums_and_hand_rejected(self):
        for mode in [dict(ENABLED,parser='hand',nominal_nouns='not-applicable'),
                     dict(ENABLED,either_policy='xor'),dict(ENABLED,schema=2),
                     dict(ENABLED,either_policy=True),dict(ENABLED,extra=True)]:
            with self.subTest(mode=mode),self.assertRaises(ValueError):fidelity.validate_execution(mode)

    def test_v1_does_not_establish_explicit_disabled_policy(self):
        self.protocol(V1)
        with self.assertRaises(ValueError):self.replay(DISABLED)

    def test_missing_legacy_mode_cannot_establish_enabled_policy(self):
        with self.assertRaises(ValueError):self.replay(ENABLED)

    def test_mixed_v2_response_rejected_even_in_current_subset(self):
        self.protocol(ENABLED,[ENABLED,DISABLED])
        self.write_rows(self.gold_path,self.rows[:1])
        with self.assertRaises(ValueError):self.replay(ENABLED)

    def invoke_scorer(self, policy, echo, error=False):
        output=self.root/'producer.json'
        argv=['run.py','--cases',str(self.gold_path),'--binary',str(self.binary),
              '--parser','default','--output',str(output)]
        if policy is not None:argv+=['--either-policy',policy]
        responses=[copy.deepcopy(o['response']) for o in self.observations]
        for response in responses:
            response['execution']=echo
            if error:response['error']='synthetic exporter error'
        for name in ['Export.hs','run.py']:(self.gold_dir/name).write_text('synthetic')
        result=SimpleNamespace(stdout=''.join(json.dumps(r)+'\n' for r in responses),stderr='')
        with patch.object(sys,'argv',argv),patch.object(fidelity,'ROOT',self.root), \
             patch.object(fidelity.subprocess,'run',return_value=result) as run, \
             contextlib.redirect_stdout(io.StringIO()),contextlib.redirect_stderr(io.StringIO()):
            code=fidelity.main()
        return code,run.call_args,json.loads(output.read_text())

    def test_mock_enabled_invocation_echo_and_report(self):
        code,call,report=self.invoke_scorer('surface-inclusive-v1',ENABLED)
        self.assertEqual(code,0)
        self.assertIn('--either-policy=surface-inclusive-v1',call.args[0])
        self.assertEqual(report['execution'],ENABLED)
        self.assertTrue(all(set(json.loads(line))=={'id','text'}
                            for line in call.kwargs['input'].splitlines()))

    def test_old_invocation_stays_v1_without_either_flag(self):
        _,call,report=self.invoke_scorer(None,V1)
        self.assertFalse(any(a.startswith('--either-policy') for a in call.args[0]))
        self.assertEqual(report['execution'],V1)

    def test_error_echo_mismatch_rejected_before_scoring(self):
        with patch.object(fidelity,'evaluate_case') as score:
            with self.assertRaises(ValueError):self.invoke_scorer(None,ENABLED,error=True)
            score.assert_not_called()

    def test_declared_enabled_mismatch_cannot_reuse_disabled_cache(self):
        self.protocol(DISABLED)
        with self.assertRaises(ValueError):self.replay(ENABLED)

    def test_missing_enabled_echo_rejected_even_after_refreshing_digest(self):
        self.protocol(ENABLED)
        del self.observations[0]['response']['execution']
        self.write_rows(self.obs_path,self.observations)
        self.report['observations_sha256']=self.sha(self.obs_path)
        self.report_path.write_text(json.dumps(self.report))
        with self.assertRaises(ValueError):self.replay(ENABLED)

    def test_mock_explicit_disabled_invocation(self):
        _,call,report=self.invoke_scorer('legacy-disabled',DISABLED)
        self.assertIn('--either-policy=legacy-disabled',call.args[0])
        self.assertEqual(report['execution'],DISABLED)

    def test_driver_duplicate_or_conflicting_policy_rejected_before_launch(self):
        spellings=[['--either-policy','legacy-disabled','--either-policy','legacy-disabled'],
                   ['--either-policy=legacy-disabled','--either-policy=legacy-disabled'],
                   ['--either-policy=legacy-disabled','--either-policy','surface-inclusive-v1'],
                   ['--either-p','legacy-disabled','--either-policy=surface-inclusive-v1']]
        for flags in spellings:
            with self.subTest(flags=flags):
                argv=['run.py','--cases',str(self.gold_path),'--binary',str(self.binary),
                      '--parser','default','--output',str(self.root/'duplicate.json')]+flags
                with patch.object(sys,'argv',argv),patch.object(fidelity.subprocess,'run') as run, \
                     contextlib.redirect_stderr(io.StringIO()),self.assertRaises(SystemExit) as error:
                    fidelity.main()
                self.assertEqual(error.exception.code,2)
                run.assert_not_called()
                self.assertFalse((self.root/'duplicate.json').exists())

    def test_typed_reading_without_drs_remains_failure_not_no_parse(self):
        response=copy.deepcopy(self.observations[0]['response'])
        response.update(drs_sentences=0,selected=None,readings=[
            {'sentence_id':0,'index':0,'typed':True,'meaning':None}])
        evaluated=fidelity.evaluate_case(self.rows[0],response)
        self.assertEqual(evaluated['status'],'type_failure')
        self.assertFalse(evaluated['any_reading_exact'])
        self.assertEqual(response['readings'][0]['index'],0)


@unittest.skipUnless(os.environ.get('EITHER_PROTOCOL_EXPORTER'),
                     'Set EITHER_PROTOCOL_EXPORTER to built candidate')
class ActualExporterEitherProtocol(unittest.TestCase):
    def invoke(self,args,text=''):
        return subprocess.run([os.environ['EITHER_PROTOCOL_EXPORTER']]+args,
                              input=text,text=True,capture_output=True,timeout=20)

    def test_existing_hand_success_and_error_are_exact_v1(self):
        inputs=[{'id':'ok','text':'Alice sleeps.'},{'id':'bad','text':'Alice sleeps.','gold':{}}]
        result=self.invoke(['--hand'],''.join(json.dumps(x)+'\n' for x in inputs))
        self.assertEqual(result.returncode,0,result.stderr)
        outputs=[json.loads(x) for x in result.stdout.splitlines()]
        self.assertEqual(len(outputs),2)
        for output in outputs:self.assertEqual(fidelity.validate_execution(output['execution']),
            dict(V1,parser='hand',nominal_nouns='not-applicable'))
        self.assertNotIn('error',outputs[0]);self.assertIn('error',outputs[1])

    def test_invalid_options_fail_before_load(self):
        for args in [['--hand','--either-policy=legacy-disabled'],
                     ['--hand','--either-policy=surface-inclusive-v1'],
                     ['--either-policy=xor'],
                     ['--either-policy=legacy-disabled','--either-policy=surface-inclusive-v1'],
                     ['--either-policy=legacy-disabled','--either-policy=legacy-disabled']]:
            with self.subTest(args=args):
                result=self.invoke(args)
                self.assertNotEqual(result.returncode,0)
                self.assertNotIn('loading CCGbank',result.stderr)

    def test_actual_v2_renderer_and_error_echo_without_model_load(self):
        # Partial records expose only configuration fields. No sentence parse is
        # attempted; malformed request rejection must precede model access.
        default='(CCGBankParser (SemModel {smPOSBackoff=False,smNominalPolicy=KnownNounsOnly,smEitherPolicy=EitherLegacyDisabled}))'
        pos='(CCGBankParser (SemModel {smPOSBackoff=True,smNominalPolicy=ContextUnknownNouns,smEitherPolicy=EitherLegacyDisabled}))'
        expression='do { mapM_ (putStrLn . renderJSON) [executionJSON ExplicitPolicy '+default+', executionJSON ExplicitPolicy '+pos+']; loop ExplicitPolicy '+default+' }'
        root=Path(__file__).resolve().parents[2]
        result=subprocess.run(['ghc','-package-env','-','-isrc',
            'test/fidelity/Export.hs','-e',expression],cwd=root,
            input=json.dumps({'id':'bad','text':'Alice sleeps.','gold':True})+'\n',
            text=True,capture_output=True,timeout=120)
        self.assertEqual(result.returncode,0,result.stderr)
        outputs=[json.loads(line) for line in result.stdout.splitlines()]
        self.assertEqual(len(outputs),3)
        self.assertEqual(fidelity.validate_execution(outputs[0]),DISABLED)
        self.assertEqual(fidelity.validate_execution(outputs[1]),
                         dict(DISABLED,parser='pos',nominal_nouns='context-unknown'))
        self.assertIn('error',outputs[2])
        self.assertEqual(fidelity.validate_execution(outputs[2]['execution']),DISABLED)

    def test_actual_enabled_success_error_and_origin_failure(self):
        # A renamed test module exposes its real miniature chart fixture only.
        # The failed ReadingResult is created by Pipeline's private backend,
        # never manufactured by setting rrOriginFailure in a record.
        root=Path(__file__).resolve().parents[2]
        fixture=(root/'test/EitherCarrierSpec.hs').read_text().replace(
            'module Main(main) where','module EitherFixture where',1)
        with tempfile.TemporaryDirectory() as directory:
            path=Path(directory)/'EitherFixture.hs';path.write_text(fixture)
            script='\n'.join([
                ':set prompt ""', ':set prompt-cont ""',
                ':load test/fidelity/Export.hs '+str(path),
                ':module *Main *NL2Proof.Pipeline *EitherFixture',
                'let emit value = putStrLn ("PROBE:" ++ renderJSON value)',
                'let choice = CCGBankParser fixtureModel',
                'emit (either (error . show) id (observe ExplicitPolicy choice (JObj [("id",JStr "ok"),("text",JStr fixtureText)])))',
                'let rootSign = head fixtureRoots',
                'let sentence = Sentence (Span 0 (length fixtureText)) fixtureText',
                'let backend = BackEnd "test-order" (const M.empty) (\\_ d -> (d,mempty)) (const mempty) (const (Just (-999)))',
                'let mk r = ccgCandidateFor fixtureModel r (Sign S (ssSem r) (ssProv r))',
                'let stale = rootSign {ssSem=TAnd (ssSem rootSign) (App (pred1 "calm") (entity "Bob")),ssScore=7}',
                'let (_,_,_,readings,_) = backEnd backend fixtureSource sentence True [mk stale,mk rootSign]',
                'mapM_ (emit . uncurry (readingJSON 0)) (zip [0..] readings)',
                'loop ExplicitPolicy choice',
                '{"id":"bad","text":"Bob is red.","gold":true}',
            ])+'\n'
            result=subprocess.run(['ghci','-package-env','-','-v0','-isrc','-itest'],
                cwd=root,input=script,text=True,capture_output=True,timeout=120)
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertNotIn('error:',result.stderr)
        outputs=[json.loads(line[6:]) for line in result.stdout.splitlines() if line.startswith('PROBE:')]
        self.assertEqual(len(outputs),3,result.stdout+result.stderr)
        success,failed,later=outputs
        self.assertEqual(fidelity.validate_execution(success['execution']),ENABLED)
        self.assertIsNotNone(success['selected'])
        self.assertEqual(success['selected']['disjunctions'][0]['either'],True)
        self.assertTrue(failed['typed']);self.assertIsNotNone(failed['form'])
        self.assertIsNone(failed['meaning']);self.assertEqual(failed['index'],0)
        self.assertEqual(failed['origin_failure']['kind'],'origin-lowering-failure')
        self.assertIn('OrSnapshotMismatch',failed['origin_failure']['detail'])
        self.assertIn('OriginLoweringFailure',json.dumps(failed['trace']))
        self.assertNotIn('TypeCheckFailure',json.dumps(failed['trace']))
        self.assertEqual(later['index'],1);self.assertIsNotNone(later['meaning'])
        self.assertNotIn('origin_failure',later)
        errors=[json.loads(line) for line in result.stdout.splitlines() if line.startswith('{')]
        self.assertEqual(len(errors),1,result.stdout)
        self.assertIn('error',errors[0])
        self.assertEqual(fidelity.validate_execution(errors[0]['execution']),ENABLED)

if __name__=='__main__':unittest.main()
