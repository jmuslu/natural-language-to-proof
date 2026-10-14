"""Protect evaluation isolation and paired statistics, not incidental formatting."""
import unittest
from run import inference_request, summarize, paired, top_mass


class RunnerTests(unittest.TestCase):
    def test_no_gold_reaches_inference(self):
        x = dict(id='x', context='text', statement='query', label='SECRET', conclusion_fol='SECRET', explanation='SECRET')
        self.assertEqual(inference_request(x), dict(id='x', context='text', statement='query'))

    def test_proofwriter_adapter(self):
        self.assertEqual(inference_request(dict(id='x', theory='t', question='q', label='True')),
                         dict(id='x', context='t', statement='q'))

    def test_abstentions_stay_in_accuracy_denominator(self):
        s = summarize([{'pred': 'True', 'label': 'True'}, {'pred': None, 'label': 'False'}])
        self.assertEqual((s['n'], s['answered'], s['correct'], s['coverage'], s['precision'], s['accuracy']),
                         (2, 1, 1, 0.5, 1.0, 0.5))

    def test_no_answer_precision_is_undefined(self):
        self.assertIsNone(summarize([{'pred': None, 'label': 'True'}])['precision'])

    def test_pair_ids_must_match(self):
        with self.assertRaises(ValueError):
            paired([{'id': 'a', 'pred': 'True', 'label': 'True'}],
                   [{'id': 'b', 'pred': 'True', 'label': 'True'}])

    def test_paired_discordance(self):
        a = [{'id': str(i), 'label': 'True', 'pred': 'True'} for i in range(6)]
        b = [dict(x, pred='False') for x in a]
        p = paired(a, b)
        self.assertEqual((p['a_only'], p['b_only'], p['mcnemar_exact_p']), (6, 0, 0.03125))

    def test_rank_mass_is_not_truth_confidence(self):
        doc = {'sentences': [{'readings': [{'score': -10000}, {'score': -10000}]}]}
        self.assertAlmostEqual(top_mass(doc), 0.5)


if __name__ == '__main__':
    unittest.main()
