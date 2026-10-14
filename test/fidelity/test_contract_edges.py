"""Independent wire-edge regressions; no parser or benchmark process is launched."""
import copy
import json
import unittest

from fidelity import evaluate_case, integral_number, summarize


def fixture():
    p = {'tag': 'pred', 'name': 'red', 'args': [{'const': 'Ada'}]}
    q = {'tag': 'pred', 'name': 'blue', 'args': [{'const': 'Ada'}]}
    either = {'tag': 'or', 'left': {'universe': [], 'conditions': [p]},
              'right': {'universe': [], 'conditions': [q]}}
    value = {'drs': {'universe': [], 'conditions': [either]},
             'claims': {'universe': [], 'asserted': [either], 'reported': [],
                        'presupposed': [], 'embedded': [p, q]},
             'disjunctions': [{'path': ['conditions', 0], 'either': True,
                               'scope_ambiguous': False}]}
    row = {'id': 'edge', 'construction': 'disjunction', 'text': 'Ada is either red or blue.',
           'origin': {'kind': 'authored-control'}, 'gold': [value]}
    observed = {'id': 'edge', 'sentence_count': 1, 'parsed_sentences': 1,
                'typed_sentences': 1, 'drs_sentences': 1,
                'selected': copy.deepcopy(value), 'readings': []}
    return row, observed


class FidelityWireEdges(unittest.TestCase):
    def test_arbitrary_json_integer_does_not_overflow_finiteness_check(self):
        # JSON permits this integer; Python integers are finite without float conversion.
        value = json.loads('1' + '0' * 400)
        self.assertTrue(integral_number(value))
        row, observed = fixture()
        observed['readings'] = [{'sentence_id': 0, 'index': value,
                                 'typed': True, 'meaning': copy.deepcopy(row['gold'][0])}]
        self.assertEqual(evaluate_case(row, observed)['status'], 'exact')

    def test_enormous_negative_count_is_error_without_aborting_report(self):
        row, observed = fixture()
        observed['sentence_count'] = json.loads('-1' + '0' * 400)
        self.assertEqual(evaluate_case(row, observed)['status'], 'error')

    def test_numeric_disjunction_flags_cannot_equal_boolean_gold(self):
        # Python False == 0 and True == 1; these are different JSON field types.
        for key, value in [('either', 1), ('scope_ambiguous', 0)]:
            with self.subTest(key=key):
                row, observed = fixture()
                observed['selected']['disjunctions'][0][key] = value
                self.assertNotEqual(evaluate_case(row, observed)['status'], 'exact')

    def test_boolean_path_index_cannot_equal_integer_gold(self):
        row, observed = fixture()
        observed['selected']['disjunctions'][0]['path'][1] = False
        self.assertNotEqual(evaluate_case(row, observed)['status'], 'exact')

    def test_integral_float_path_index_remains_valid_exporter_wire_format(self):
        # The same Haskell JNum serializer handles annotation indices and counts.
        row, observed = fixture()
        observed['selected']['disjunctions'][0]['path'][1] = 0.0
        self.assertEqual(evaluate_case(row, observed)['status'], 'exact')

    def test_malformed_selected_payload_is_instrumentation_error(self):
        row, observed = fixture()
        observed['selected'] = {'drs': None, 'claims': None}
        self.assertEqual(evaluate_case(row, observed)['status'], 'error')

    def test_all_six_outcomes_keep_instrumentation_errors_in_denominator(self):
        results = []
        modifications = [
            ({}, 'exact'),
            ({'selected': {'drs': {'universe': [], 'conditions': []},
                           'claims': {'universe': [], 'asserted': [], 'reported': [],
                                      'presupposed': [], 'embedded': []}}}, 'wrong_but_typed'),
            ({'parsed_sentences': 0, 'typed_sentences': 0, 'drs_sentences': 0,
              'selected': None}, 'no_parse'),
            ({'typed_sentences': 0, 'drs_sentences': 0, 'selected': None}, 'type_failure'),
            ({'sentence_count': 2}, 'incomplete'),
            ({'sentence_count': '1'}, 'error'),
        ]
        for updates, status in modifications:
            row, observed = fixture()
            observed.update(updates)
            result = evaluate_case(row, observed)
            self.assertEqual(result['status'], status)
            results.append(result)
        summary = summarize(results)
        self.assertEqual(summary['n'], 6)
        self.assertEqual(summary['exact_rate'], 1 / 6)
        self.assertEqual(summary['counts'], {status: 1 for _, status in modifications})
        self.assertEqual(summary['by_construction']['disjunction']['n'], 6)
        self.assertEqual(summary['by_construction']['disjunction']['counts']['error'], 1)


if __name__ == '__main__':
    unittest.main()
