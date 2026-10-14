"""Independent gold-only admission prototype; not wired into fidelity.py.

No observation is normalized or rejected by this helper. Existing expected
failures remain unchanged until production policy receives independent review.
"""
import copy
import unittest

from fidelity import validate_case, evaluate_case
from test_scope_contract_review import box, pred, fixture, nested, observed


def proposed_gold_admission(row):
    """Keep existing schema/scope checks; additionally audit each gold DRS only."""
    validate_case(row)
    for reading_index, meaning in enumerate(row['gold']):
        encountered = set()
        declarations = set()

        def reference(name, path, declaration=False):
            if declaration:
                if name in declarations:
                    raise ValueError(f'gold[{reading_index}] duplicate declaration {name} at {path}')
                declarations.add(name)
            if name not in encountered:
                expected = f'r{len(encountered)}'
                if name != expected:
                    raise ValueError(f'gold[{reading_index}] first occurrence {name}, expected {expected} at {path}')
                encountered.add(name)

        def term(value, path):
            if 'ref' in value:
                reference(value['ref'], path)

        def drs(value, path):
            for index, name in enumerate(value['universe']):
                reference(name, path + ('universe', index), declaration=True)
            for index, condition in enumerate(value['conditions']):
                cond(condition, path + ('conditions', index))

        def cond(value, path):
            tag = value['tag']
            if tag == 'pred':
                for index, argument in enumerate(value['args']):
                    term(argument, path + ('args', index))
            elif tag == 'eq':
                term(value['left'], path + ('left',))
                term(value['right'], path + ('right',))
            elif tag in ('not', 'presup'):
                drs(value['body'], path + ('body',))
            elif tag in ('imp', 'or'):
                drs(value['left'], path + ('left',))
                drs(value['right'], path + ('right',))
            elif tag == 'att':
                for index, holder in enumerate(value['holders']):
                    term(holder, path + ('holders', index))
                drs(value['body'], path + ('body',))
            else:
                raise ValueError('unexpected condition after schema validation')

        drs(meaning['drs'], ('drs',))
    return row


class GoldCanonicalAdmissionProposal(unittest.TestCase):
    def test_first_occurrence_cases_are_rejected_without_mutating_input(self):
        for refs in (['r9'], ['r01'], ['r1', 'r0'], ['r0', 'r2']):
            with self.subTest(refs=refs):
                p = pred('related', *({'ref': ref} for ref in refs))
                row = fixture(box([p], refs), [p]); original = copy.deepcopy(row)
                with self.assertRaisesRegex(ValueError, 'first occurrence'):
                    proposed_gold_admission(row)
                self.assertEqual(row, original)

    def test_nested_redeclaration_rejected_as_policy_not_export_impossibility(self):
        p = pred('cat', {'ref': 'r0'}); q = pred('dog', {'ref': 'r0'})
        neg = {'tag': 'not', 'body': box([q], ['r0'])}
        row = fixture(box([p, neg], ['r0']), [p, neg], [q])
        validate_case(row)  # Current validator accepts; canonicalizer can export it.
        with self.assertRaisesRegex(ValueError, 'duplicate declaration'):
            proposed_gold_admission(row)

    def test_disjoint_sibling_redeclaration_also_rejected(self):
        p = pred('sleep', {'ref': 'r0'})
        neg = {'tag': 'not', 'body': box([p], ['r0'])}
        row = fixture(box([neg, neg]), [neg, neg], [p, p])
        with self.assertRaisesRegex(ValueError, 'duplicate declaration'):
            proposed_gold_admission(row)

    def test_claim_copies_are_not_counted_as_new_declarations(self):
        row = nested(); original = copy.deepcopy(row)
        self.assertIs(proposed_gold_admission(row), row)
        self.assertEqual(row, original)

    def test_repeated_terms_and_equality_are_not_new_binders(self):
        p = pred('see', {'ref': 'r0'}, {'ref': 'r0'})
        eq = {'tag': 'eq', 'left': {'ref': 'r0'}, 'right': {'const': 'Ada'}}
        proposed_gold_admission(fixture(box([p, eq], ['r0']), [p, eq]))

    def test_first_encounter_visits_all_root_universe_before_conditions(self):
        # r1 is first USED; r0 was first DECLARED. Do not reorder by term use.
        p = pred('see', {'ref': 'r1'}, {'ref': 'r0'})
        proposed_gold_admission(fixture(box([p], ['r0', 'r1']), [p]))

    def test_attribution_holder_reuses_outer_ref_and_body_introduces_next(self):
        p = pred('sleep', {'ref': 'r1'})
        att = {'tag': 'att', 'verb': 'say', 'holders': [{'ref': 'r0'}],
               'body': box([p], ['r1'])}
        report = {'condition': p, 'chain': [{'verb': 'say', 'holders': [{'ref': 'r0'}], 'factive': False}]}
        proposed_gold_admission(fixture(box([att], ['r0']), [att], reported=[report]))

    def test_presupposition_and_negation_use_shared_numbering_not_fresh_r0(self):
        p = pred('red', {'ref': 'r0'}); q = pred('blue', {'ref': 'r1'})
        pres = {'tag': 'presup', 'body': box([p], ['r0'])}
        neg = {'tag': 'not', 'body': box([q], ['r1'])}
        proposed_gold_admission(fixture(box([pres, neg]), [neg], [q], presupposed=[p]))

    def test_disjunction_branches_share_numbering_but_not_scope(self):
        p = pred('red', {'ref': 'r0'}); q = pred('blue', {'ref': 'r1'})
        disj = {'tag': 'or', 'left': box([p], ['r0']), 'right': box([q], ['r1'])}
        row = fixture(box([disj]), [disj], [p, q])
        row['gold'][0]['disjunctions'] = [{'path': ['conditions', 0],
            'either': False, 'scope_ambiguous': False}]
        proposed_gold_admission(row)

    def test_duplicate_declaration_observation_is_still_wrong_not_error(self):
        row = nested(); proposed_gold_admission(row)
        p = pred('cat', {'ref': 'r0'}); q = pred('dog', {'ref': 'r0'})
        neg = {'tag': 'not', 'body': box([q], ['r0'])}
        candidate = fixture(box([p, neg], ['r0']), [p, neg], [q])['gold'][0]
        self.assertEqual(evaluate_case(row, observed(candidate))['status'], 'wrong_but_typed')

    def test_alternative_gold_readings_have_separate_numbering(self):
        row = nested(); row['gold'].append(copy.deepcopy(row['gold'][0]))
        proposed_gold_admission(row)

    def test_no_binder_gold_remains_valid(self):
        p = pred('red', {'const': 'Ada'})
        proposed_gold_admission(fixture(box([p]), [p]))

    def test_observed_noncanonical_wire_stays_wrong_not_protocol_error(self):
        p = pred('sleep', {'ref': 'r0'}); row = fixture(box([p], ['r0']), [p])
        proposed_gold_admission(row)
        q = pred('sleep', {'ref': 'r9'})
        candidate = fixture(box([q], ['r9']), [q])['gold'][0]
        self.assertEqual(evaluate_case(row, observed(candidate))['status'], 'wrong_but_typed')

    def test_existing_scope_rejection_is_not_weakened(self):
        row = nested()
        row['gold'][0]['drs']['conditions'][0]['right']['conditions'][1]['args'][0] = {'ref': 'r7'}
        with self.assertRaisesRegex(ValueError, 'free or noncanonical'):
            proposed_gold_admission(row)


if __name__ == '__main__':
    unittest.main()
