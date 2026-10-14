"""The benchmark convention is explicit, localized and auditable."""
import copy
import unittest

from domain import normalize_theory
from solver import answer


def ref(name='x'):
    return {'ref': name}


def const(name='Bob'):
    return {'const': name}


def pred(name, arg, cue=None):
    value = {'tag': 'pred', 'name': name, 'args': [arg]}
    if cue is not None:
        value['prov'] = {'leaves': [{'source': 'test', 'span': [0, len(cue)], 'text': cue}]}
    return value


def box(*conditions, universe=()):
    return {'universe': list(universe), 'conditions': list(conditions)}


def neg(condition):
    return {'tag': 'not', 'body': box(condition)}


def rule(guards=None, body=None, head=None, universe=('x',)):
    guards = [pred('person', ref(), 'someone')] if guards is None else guards
    body = [pred('red', ref())] if body is None else body
    head = pred('big', ref()) if head is None else head
    return {'tag': 'imp', 'left': box(*(guards + body), universe=universe), 'right': box(head)}


class DomainTests(unittest.TestCase):
    def test_strict_default_preserves_sortals(self):
        d = box(rule())
        self.assertEqual(normalize_theory(d), (d, []))

    def test_only_named_policy_is_accepted(self):
        with self.assertRaises(ValueError):
            normalize_theory(box(), 'automatic')

    def test_bound_person_guard_and_provenance_are_recorded(self):
        original = box(rule())
        untouched = copy.deepcopy(original)
        normalized, decisions = normalize_theory(original, 'proofwriter')
        self.assertEqual(original, untouched)
        self.assertEqual(normalized['conditions'][0]['left']['conditions'], [pred('red', ref())])
        self.assertEqual(decisions[0]['removed'], untouched['conditions'][0]['left']['conditions'][0])
        self.assertEqual(decisions[0]['path'], ['conditions', 0, 'left', 'conditions', 0])
        self.assertEqual(decisions[0]['policy'], 'proofwriter')

    def test_thing_something_and_plural_domain_cues(self):
        for name, cue in [('thing', 'something'), ('thing', 'things'), ('person', 'people'), ('person', 'Someone')]:
            with self.subTest(cue=cue):
                d = box(rule(guards=[pred(name, ref(), cue)]))
                normalized, decisions = normalize_theory(d, 'proofwriter')
                self.assertEqual(len(decisions), 1)
                self.assertEqual(len(normalized['conditions'][0]['left']['conditions']), 1)

    def test_ground_sortal_assertions_and_query_shapes_are_unchanged(self):
        for d in [box(pred('person', const(), 'someone')), box(pred('thing', const(), 'things'))]:
            self.assertEqual(normalize_theory(d, 'proofwriter'), (d, []))

    def test_sortal_consequence_is_never_dropped(self):
        consequent = pred('thing', ref(), 'things')
        normalized, decisions = normalize_theory(box(rule(head=consequent)), 'proofwriter')
        self.assertEqual(len(decisions), 1)
        self.assertEqual(normalized['conditions'][0]['right'], box(consequent))

    def test_negated_sortal_guard_is_not_erased(self):
        d = box(rule(guards=[neg(pred('person', ref(), 'someone'))]))
        self.assertEqual(normalize_theory(d, 'proofwriter'), (d, []))

    def test_lexical_person_or_thing_property_is_not_domain_cue(self):
        for name in ['person', 'thing']:
            d = box(rule(guards=[pred(name, ref(), name)]))
            self.assertEqual(normalize_theory(d, 'proofwriter'), (d, []))

    def test_missing_or_sentence_wide_provenance_cannot_license_erasure(self):
        guard = pred('person', ref(), 'someone')
        broad = copy.deepcopy(guard)
        broad['prov']['leaves'].append({'source': 'test', 'span': [8, 10], 'text': 'is'})
        for g in [pred('person', ref()), broad]:
            d = box(rule(guards=[g]))
            self.assertEqual(normalize_theory(d, 'proofwriter'), (d, []))

    def test_rule_under_negation_report_or_presupposition_is_unchanged(self):
        for outer in [{'tag': 'not', 'body': box(rule())},
                      {'tag': 'att', 'verb': 'say', 'holders': [const()], 'body': box(rule())},
                      {'tag': 'presup', 'body': box(rule())}]:
            d = box(outer)
            self.assertEqual(normalize_theory(d, 'proofwriter'), (d, []))

    def test_nested_rule_and_disjunctive_body_are_unchanged(self):
        for extra in [rule(), {'tag': 'or', 'left': box(pred('red', ref())), 'right': box(pred('blue', ref()))}]:
            d = box(rule(body=[extra]))
            self.assertEqual(normalize_theory(d, 'proofwriter'), (d, []))

    def test_empty_body_cannot_be_created(self):
        d = box(rule(body=[]))
        self.assertEqual(normalize_theory(d, 'proofwriter'), (d, []))

    def test_head_variable_must_remain_range_restricted(self):
        d = box(rule(body=[pred('red', const('Alice'))]))
        self.assertEqual(normalize_theory(d, 'proofwriter'), (d, []))

    def test_unbound_or_malformed_ref_is_not_rewritten(self):
        d = box(rule(guards=[pred('person', ref('y'), 'someone')]))
        self.assertEqual(normalize_theory(d, 'proofwriter'), (d, []))

    def test_existential_theory_or_rule_head_is_unchanged(self):
        d = box(rule(), universe=['z'])
        self.assertEqual(normalize_theory(d, 'proofwriter'), (d, []))
        r = rule()
        r['right']['universe'] = ['y']
        d = box(r)
        self.assertEqual(normalize_theory(d, 'proofwriter'), (d, []))

    def test_other_top_level_conditions_and_indices_are_preserved(self):
        d = box(pred('red', const()), rule(), neg(pred('blue', const())))
        normalized, decisions = normalize_theory(d, 'proofwriter')
        self.assertEqual(normalized['conditions'][0], d['conditions'][0])
        self.assertEqual(normalized['conditions'][2], d['conditions'][2])
        self.assertEqual(decisions[0]['path'][1], 1)

    def test_signed_proofs_change_only_under_explicit_policy(self):
        for negative in [False, True]:
            head = neg(pred('big', ref())) if negative else pred('big', ref())
            d = box(pred('red', const()), rule(head=head))
            query = box(pred('big', const()))
            normalized, _ = normalize_theory(d, 'proofwriter')
            for backend in ['horn', 'z3']:
                with self.subTest(backend=backend, negative=negative):
                    self.assertEqual(answer(d, query, backend=backend)['answer'], 'Unknown')
                    self.assertEqual(answer(normalized, query, backend=backend)['answer'], 'False' if negative else 'True')


if __name__ == '__main__':
    unittest.main()
