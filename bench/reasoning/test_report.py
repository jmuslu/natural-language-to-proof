"""Guard heterogeneous result normalization and honest paired/cost denominators."""
import unittest

from report import normalize_rows, cost_summary, compare_runs, risk_coverage, score_summary
from run import summarize


def sample(i='x', label='True'):
    return dict(id=i, label=label, context='Ada is blue.', statement='Ada is blue.')


class ReportTests(unittest.TestCase):
    def test_coverage_interval_uses_answers_over_all_selected_items(self):
        rows=[dict(id=str(i),label='True',pred=pred)
              for i,pred in enumerate(['True','False',None,None])]
        summary=score_summary(rows)
        self.assertEqual((summary['coverage'],summary['precision'],summary['accuracy']),(.5,.5,.25))
        self.assertAlmostEqual(summary['coverage_wilson'][0],.150036,places=5)
        self.assertAlmostEqual(summary['coverage_wilson'][1],.849964,places=5)

    def test_proofwriter_boolean_gold_and_unknown_spelling(self):
        samples = [sample('a', True), sample('b', 'Unknown')]
        result = normalize_rows(samples, [dict(id='a', label=True, raw='True'),
                                         dict(id='b', label='Unknown', raw='It is uncertain.')], 'proofwriter', 'A')
        self.assertEqual([x['label'] for x in result['strict']], ['True', 'Unknown'])
        self.assertEqual([x['pred'] for x in result['strict']], ['True', None])
        self.assertEqual([x['pred'] for x in result['lenient']], ['True', 'Unknown'])

    def test_errors_and_tool_use_are_not_answers(self):
        samples = [sample('a'), sample('b')]
        rows = [dict(id='a', raw='True', error='quota'),dict(id='b', raw='True', tool_items=1)]
        result = normalize_rows(samples, rows, 'proverqa', 'C')
        self.assertEqual(summarize(result['lenient'])['answered'], 0)

    def test_translation_json_uses_solver_prediction_not_incidental_words(self):
        row = dict(id='x', raw='{"note":"False"}', pred='True', lenient_pred='True',
                   inference={'strength':'LLMTranslated'})
        result = normalize_rows([sample()], [row], 'proverqa', 'D')
        self.assertEqual(result['strict'][0]['pred'], 'True')
        self.assertEqual(result['lenient'][0]['pred'], 'True')

    def test_prontoqa_off_label_uncertainty_is_abstention(self):
        result = normalize_rows([sample()], [dict(id='x',raw='Unknown')], 'prontoqa', 'A')
        self.assertIsNone(result['lenient'][0]['pred'])

    def test_mismatched_gold_and_request_fail(self):
        with self.assertRaises(ValueError):
            normalize_rows([sample()], [dict(id='x',label='False',raw='True')], 'proverqa', 'A')
        with self.assertRaises(ValueError):
            normalize_rows([sample()], [dict(id='x',request_hash='wrong',raw='True')], 'proverqa', 'A')

    def test_duplicate_ids_require_explicit_clean_input(self):
        with self.assertRaises(ValueError):
            normalize_rows([sample()], [dict(id='x',raw='True')]*2, 'proverqa', 'A')

    def test_pending_rows_stay_in_summary_but_prevent_paired_claims(self):
        samples=[sample('a'),sample('b')]
        a=normalize_rows(samples,[dict(id='a',raw='True'),dict(id='b',raw='True')],'proverqa','A')
        c=normalize_rows(samples,[dict(id='a',raw='True')],'proverqa','C')
        self.assertEqual(summarize(c['strict'])['accuracy'], .5)
        self.assertEqual(c['pending'], ['b'])
        self.assertEqual(compare_runs(a,c)['status'], 'incomplete')

    def test_paired_discordance_uses_same_items_in_both_parsers(self):
        samples=[sample(str(i)) for i in range(6)]
        a=normalize_rows(samples,[dict(id=str(i),raw='True') for i in range(6)],'proverqa','A')
        c=normalize_rows(samples,[dict(id=str(i),raw='false') for i in range(6)],'proverqa','C')
        comparison=compare_runs(a,c)
        self.assertEqual(comparison['strict']['mcnemar_exact_p'], .03125)
        self.assertEqual(comparison['lenient']['a_only'],6)

    def test_retry_tokens_are_reported_but_not_called_complete_totals(self):
        row=dict(id='x',attempts=2,usage=dict(input_tokens=100,cached_input_tokens=80,
             output_tokens=20,reasoning_output_tokens=15),latency=3)
        cost=cost_summary([row],'A',1)
        self.assertEqual(cost['reported_tokens']['total_tokens']['sum'],120)
        self.assertEqual(cost['unknown_total_token_rows'],1)
        self.assertEqual(cost['known_retry_count'],1)
        self.assertEqual(cost['latencies']['call_wall_seconds']['n_reported'],0)

    def test_cached_and_reasoning_tokens_are_not_double_counted(self):
        row=dict(id='x',attempts=1,usage=dict(input_tokens=100,cached_input_tokens=80,
             output_tokens=20,reasoning_output_tokens=15),wall_latency=4)
        cost=cost_summary([row],'C',1)
        self.assertEqual(cost['reported_tokens']['total_tokens']['sum'],120)
        self.assertEqual(cost['reported_tokens']['cached_input_tokens']['sum'],80)
        self.assertEqual(cost['unknown_total_token_rows'],0)

    def test_hybrid_b_route_has_zero_model_cost(self):
        row=dict(id='x',route='B',usage=None,llm_latency=0,latency=.1)
        cost=cost_summary([row],'D',1)
        self.assertEqual(cost['reported_tokens']['total_tokens']['sum'],0)
        self.assertEqual(cost['unknown_total_token_rows'],0)

    def test_missing_usage_is_unknown_even_on_one_attempt(self):
        cost=cost_summary([dict(id='x',attempts=1,usage=None)],'A',1)
        self.assertEqual(cost['unknown_total_token_rows'],1)
        self.assertIsNone(cost['reported_tokens']['total_tokens']['sum'])
        self.assertIsNone(cost['reported_tokens']['total_tokens']['per_selected_item'])

    def test_malformed_usage_is_unknown(self):
        cost=cost_summary([dict(id='x',attempts=1,usage='not an object')],'A',1)
        self.assertEqual(cost['unknown_total_token_rows'],1)

    def test_mass_curve_keeps_ties_and_counts_abstentions_in_denominator(self):
        samples=[sample(str(i)) for i in range(4)]
        rows=[dict(id='0',pred='False',inference=dict(top_mass=.2)),
              dict(id='1',pred='True',inference=dict(top_mass=.8)),
              dict(id='2',pred=None,inference=dict(top_mass=.8)),
              dict(id='3',pred=None,inference=dict(top_mass=1.0))]
        norm=normalize_rows(samples,rows,'proverqa','B')
        curve=risk_coverage(rows,norm)
        points=curve['strict']
        self.assertEqual([p['threshold'] for p in points],[.2,.8,1.0])
        self.assertEqual([p['mass_eligible'] for p in points],[4,3,1])
        self.assertEqual([p['answered'] for p in points],[2,1,0])
        self.assertEqual([p['coverage'] for p in points],[.5,.25,0.0])
        self.assertEqual([p['risk'] for p in points],[.5,0.0,None])
        self.assertEqual([p['n'] for p in points],[4,4,4])

    def test_mass_curve_excludes_missing_and_invalid_mass_without_shrinking_sample(self):
        samples=[sample(str(i)) for i in range(5)]
        rows=[dict(id=str(i),pred='True',inference=dict(top_mass=m))
              for i,m in enumerate([.5,None,True,float('nan'),1.1])]
        norm=normalize_rows(samples,rows,'proverqa','B')
        curve=risk_coverage(rows,norm)
        self.assertEqual(curve['mass_rows'],1)
        self.assertEqual(curve['missing_or_invalid_mass_rows'],4)
        self.assertEqual(curve['strict'][0]['coverage'],.2)

    def test_mass_curve_absent_without_observed_mass(self):
        rows=[dict(id='x',raw='True')]
        norm=normalize_rows([sample()],rows,'proverqa','A')
        self.assertIsNone(risk_coverage(rows,norm))


if __name__ == '__main__':
    unittest.main()
