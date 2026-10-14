"""Protect evaluation isolation and paired statistics, not incidental formatting."""
import unittest
from run import inference_request, summarize, paired, top_mass, normalized_label, evaluate_record
from test_domain import box, pred, const, rule


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

    def test_unknown_abstains_on_binary_benchmark(self):
        self.assertIsNone(normalized_label('Unknown', 'prontoqa'))
        self.assertEqual(normalized_label('Unknown', 'proofwriter'), 'Unknown')
        self.assertEqual(normalized_label('Unknown', 'folio'), 'Uncertain')

    def test_domain_policy_requires_named_benchmark_and_records_decisions(self):
        theory = box(pred('red', const()), rule())
        record = {'theories': [{'drs': theory, 'complete': True, 'queries': [
            {'drs': box(pred('big', const())), 'complete': True}]}]}
        cfg = dict(backend='horn', readings='top', timeout_ms=2000, or_semantics='inclusive')
        self.assertEqual(evaluate_record(record, cfg)['answer'], 'Unknown')
        with self.assertRaises(ValueError):
            evaluate_record(record, dict(cfg, domain_policy='proofwriter', bench='folio'))
        adapted = evaluate_record(record, dict(cfg, domain_policy='proofwriter', bench='proofwriter'))
        self.assertEqual(adapted['answer'], 'True')
        self.assertEqual(len(adapted['domain_decisions']), 1)


if __name__ == '__main__':
    unittest.main()
