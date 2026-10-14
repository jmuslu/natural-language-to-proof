"""Semantic policies partition reports; they never alter inference or exactness."""
import copy
import unittest

from fidelity import evaluate_case, project_request, summarize, validate_case
from test_fidelity import case, response


class SemanticsContractTests(unittest.TestCase):
    def test_metadata_validation_accepts_string_or_id_object(self):
        for metadata in ('person-v1', {'id': 'person-v1', 'policy': 'retain person'}):
            row = case(); row['semantics_contract'] = metadata
            validate_case(row)
            self.assertEqual(evaluate_case(row, response())['semantics_contract_id'], 'person-v1')

    def test_invalid_metadata_is_rejected_before_inference(self):
        for metadata in (None, '', '  ', [], 1, True, {}, {'id': ''}, {'id': ' '}, {'id': 2}):
            with self.subTest(metadata=metadata):
                row = case(); row['semantics_contract'] = metadata
                with self.assertRaises(ValueError): validate_case(row)

    def test_request_projection_never_leaks_contract_or_gold(self):
        row = case(); row['semantics_contract'] = {'id': 'private-policy', 'rationale': 'secret'}
        self.assertEqual(project_request(row), {'id': 'fixture', 'text': 'John smiles.'})

    def test_mixed_contracts_partition_identical_english_without_changing_status(self):
        results = []
        for metadata in ('domain-v1', {'id': 'person-v1'}):
            row = case(); row['semantics_contract'] = metadata
            results.append(evaluate_case(row, response()))
        summary = summarize(results)
        self.assertEqual(summary['aggregation_scope'], 'mixed_contracts')
        self.assertEqual(summary['counts']['exact'], 2)
        self.assertFalse(summary['certifies_acceptance_panel'])
        self.assertEqual([(p['semantics_contract_id'], p['n']) for p in summary['by_semantics_contract']],
                         [('domain-v1', 1), ('person-v1', 1)])

    def test_all_statuses_remain_in_each_contract_denominator(self):
        results = []
        mutations = [({}, 'exact'),
                     ({'selected': {'drs': {}, 'claims': {}}}, 'wrong_but_typed'),
                     ({'parsed_sentences': 0, 'typed_sentences': 0, 'drs_sentences': 0,
                       'selected': None, 'readings': []}, 'no_parse'),
                     ({'typed_sentences': 0, 'drs_sentences': 0, 'selected': None}, 'type_failure'),
                     ({'sentence_count': 2}, 'incomplete'),
                     ({'sentence_count': 'bad'}, 'error')]
        for updates, status in mutations:
            row = case(); row['semantics_contract'] = 'person-v1'
            observed = response(); observed.update(copy.deepcopy(updates))
            result = evaluate_case(row, observed)
            self.assertEqual(result['status'], status); results.append(result)
        summary = summarize(results); partition = summary['by_semantics_contract'][0]
        self.assertEqual(partition['n'], 6)
        self.assertEqual(partition['exact_rate'], 1 / 6)
        self.assertEqual(partition['counts'], {status: 1 for _, status in mutations})
        self.assertEqual(partition['by_construction']['intransitive']['n'], 6)
        self.assertEqual(summary['aggregation_scope'], 'single_declared_contract')
        self.assertFalse(summary['certifies_acceptance_panel'])

    def test_legacy_is_null_and_cannot_collide_with_declared_name(self):
        row = case(); legacy = evaluate_case(row, response())
        self.assertIsNone(legacy['semantics_contract_id'])
        summary = summarize([legacy])
        self.assertEqual(summary['aggregation_scope'], 'legacy_unversioned')
        self.assertFalse(summary['certifies_acceptance_panel'])
        row['semantics_contract'] = 'legacy_unversioned'
        mixed = summarize([legacy, evaluate_case(row, response())])
        self.assertEqual([p['semantics_contract_id'] for p in mixed['by_semantics_contract']],
                         [None, 'legacy_unversioned'])
        self.assertEqual(mixed['aggregation_scope'], 'mixed_contracts')

    def test_empty_summary_does_not_certify_acceptance(self):
        summary = summarize([])
        self.assertEqual(summary['by_semantics_contract'], [])
        self.assertEqual(summary['aggregation_scope'], 'empty')
        self.assertFalse(summary['certifies_acceptance_panel'])


if __name__ == '__main__': unittest.main()
