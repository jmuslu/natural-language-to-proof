#!/usr/bin/env python3
"""Independent future protocol controls. Expected red on pre-protocol verifier.

Synthetic files only: no binary executes, no model or corpus loads. These test
metadata consistency after digests are deliberately refreshed, so a passing
hash check alone cannot substitute for the proposed execution contract.
"""
import copy
import json
import unittest
import test_replay_integrity as replaytests

KNOWN = {'schema': 1, 'parser': 'default', 'nominal_nouns': 'known-only'}
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
        self.write_protocol(dict(KNOWN, schema=True))
        self.reject()

    def test_report_frontend_mismatch_rejected(self):
        self.write_protocol(dict(KNOWN, parser='pos'))
        self.reject()

    def test_hand_frontend_cannot_claim_unknown_nominal_policy(self):
        self.report['parser'] = 'hand'
        self.write_protocol(dict(UNKNOWN, parser='hand'))
        self.reject()

if __name__ == '__main__':
    unittest.main()
