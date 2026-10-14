"""Semantic tests for the two deliberately different inference policies."""
import unittest
from solver import answer, aggregate


def term(x):
    return {'ref': x[1:]} if x.startswith('?') else {'const': x}


def pred(name, *args):
    return {'tag': 'pred', 'name': name, 'args': [term(a) for a in args]}


def box(*conditions, refs=()):
    return {'universe': list(refs), 'conditions': list(conditions)}


def neg(p):
    return {'tag': 'not', 'body': box(p)}


def rule(a, b, refs=('x',)):
    return {'tag': 'imp', 'left': box(*a, refs=refs), 'right': box(*b)}


class SolverTests(unittest.TestCase):
    def check_both(self, theory, query, expected, **kwargs):
        for backend in ('horn', 'z3'):
            with self.subTest(backend=backend):
                self.assertEqual(answer(theory, query, backend=backend, **kwargs)['answer'], expected)

    def test_fact(self):
        self.check_both(box(pred('red', 'cat')), box(pred('red', 'cat')), 'True')

    def test_explicit_negative(self):
        self.check_both(box(neg(pred('red', 'cat'))), box(pred('red', 'cat')), 'False')

    def test_negative_query(self):
        self.check_both(box(pred('red', 'cat')), box(neg(pred('red', 'cat'))), 'False')

    def test_open_world(self):
        self.check_both(box(pred('red', 'cat')), box(pred('big', 'cat')), 'Unknown')

    def test_partial_unknown_abstains(self):
        self.check_both(box(pred('red', 'cat')), box(pred('big', 'cat')), None, complete=False)

    def test_partial_proof_survives(self):
        self.check_both(box(pred('red', 'cat')), box(pred('red', 'cat')), 'True', complete=False)

    def test_rule(self):
        self.check_both(box(pred('red', 'cat'), rule([pred('red', '?x')], [pred('big', '?x')])),
                        box(pred('big', 'cat')), 'True')

    def test_conjunction_rule(self):
        self.check_both(box(pred('red', 'cat'), pred('kind', 'cat'),
                            rule([pred('red', '?x'), pred('kind', '?x')], [neg(pred('big', '?x'))])),
                        box(pred('big', 'cat')), 'False')

    def test_no_cross_individual_join(self):
        self.check_both(box(pred('red', 'cat'), pred('kind', 'dog'),
                            rule([pred('red', '?x'), pred('kind', '?x')], [pred('big', '?x')])),
                        box(pred('big', 'cat')), 'Unknown')

    def test_no_grounding_from_cycle(self):
        self.check_both(box(rule([pred('red', '?x')], [pred('big', '?x')]),
                            rule([pred('big', '?x')], [pred('red', '?x')])),
                        box(pred('red', 'cat')), 'Unknown')

    def test_seeded_cycle_and_retraction(self):
        rs = [rule([pred('red', '?x')], [pred('big', '?x')]),
              rule([pred('big', '?x')], [pred('red', '?x')])]
        self.check_both(box(pred('red', 'cat'), *rs), box(pred('big', 'cat')), 'True')
        self.check_both(box(*rs), box(pred('big', 'cat')), 'Unknown')

    def test_contradiction_abstains(self):
        self.check_both(box(pred('red', 'cat'), neg(pred('red', 'cat'))), box(pred('big', 'cat')), None)

    def test_report_not_fact(self):
        report = {'tag': 'att', 'verb': 'say', 'holders': [term('Bob')], 'body': box(pred('red', 'cat'))}
        self.check_both(box(report), box(pred('red', 'cat')), None)

    def test_presupposition_not_fact(self):
        self.check_both(box({'tag': 'presup', 'body': box(pred('red', 'cat'))}), box(pred('red', 'cat')), None)

    def test_unsupported_not_a_predicate(self):
        self.check_both(box(pred('UNSUPPORTED', 'cat')), box(pred('red', 'cat')), None)

    def test_unresolved_anaphor_not_entity(self):
        self.check_both(box(pred('red', 'cat')), box({'tag': 'pred', 'name': 'red', 'args': [{'const': '?it_0'}]}), None)

    def test_free_reference_not_constant(self):
        self.check_both(box(pred('red', '?x')), box(pred('red', 'cat')), None)

    def test_unsafe_rule_is_residual(self):
        self.check_both(box(rule([pred('red', '?x')], [pred('big', '?y')])), box(pred('big', 'cat')), None)

    def test_horn_is_not_classical_contraposition(self):
        t = box(neg(pred('big', 'cat')), rule([pred('red', '?x')], [pred('big', '?x')]))
        q = box(pred('red', 'cat'))
        self.assertEqual(answer(t, q, backend='horn')['answer'], 'Unknown')
        self.assertEqual(answer(t, q, backend='z3')['answer'], 'False')

    def test_disjunction_fol(self):
        t = box({'tag': 'or', 'left': box(pred('red', 'cat')), 'right': box(pred('big', 'cat'))}, neg(pred('red', 'cat')))
        self.assertEqual(answer(t, box(pred('big', 'cat')), backend='z3')['answer'], 'True')
        self.assertIsNone(answer(t, box(pred('big', 'cat')), backend='horn')['answer'])

    def test_inclusive_and_local_exclusive_either(self):
        disj = {'tag': 'or', 'left': box(pred('red', 'cat')), 'right': box(pred('big', 'cat')), 'either': True}
        t = box(disj, pred('red', 'cat'))
        q = box(pred('big', 'cat'))
        self.assertEqual(answer(t, q, backend='z3')['answer'], 'Unknown')
        self.assertEqual(answer(t, q, backend='z3', or_semantics='proverqa')['answer'], 'False')
        disj['either'] = False
        self.assertEqual(answer(t, q, backend='z3', or_semantics='proverqa')['answer'], 'Unknown')

    def test_existential_shared_witness(self):
        t = box(pred('red', '?x'), pred('big', '?x'), refs=('x',))
        q = box(pred('red', '?y'), pred('big', '?y'), refs=('y',))
        self.assertEqual(answer(t, q, backend='z3')['answer'], 'True')
        self.assertIsNone(answer(t, q, backend='horn')['answer'])

    def test_separate_existentials_do_not_share(self):
        # Distinct quantified consequents must not identify their witnesses.
        t = box({'tag': 'imp', 'left': box(), 'right': box(pred('red', '?x'), refs=('x',))},
                {'tag': 'imp', 'left': box(), 'right': box(pred('big', '?x'), refs=('x',))})
        q = box(pred('red', '?y'), pred('big', '?y'), refs=('y',))
        self.assertEqual(answer(t, q, backend='z3')['answer'], 'Unknown')

    def test_existential_rule_consequent(self):
        t = box(pred('red', 'cat'), {'tag': 'imp', 'left': box(pred('red', '?x'), refs=('x',)),
                                    'right': box(pred('likes', '?x', '?y'), refs=('y',))})
        q = box(pred('likes', 'cat', '?z'), refs=('z',))
        self.assertEqual(answer(t, q, backend='z3')['answer'], 'True')
        self.assertIsNone(answer(t, q, backend='horn')['answer'])

    def test_no_unique_names_axiom(self):
        q = box({'tag': 'eq', 'left': term('cat'), 'right': term('dog')})
        self.assertEqual(answer(box(), q, backend='z3')['answer'], 'Unknown')

    def test_horn_proof_includes_rule(self):
        r = answer(box(pred('red', 'cat'), rule([pred('red', '?x')], [pred('big', '?x')])),
                   box(pred('big', 'cat')), backend='horn')
        self.assertEqual(r['support'], [['p0', 'p1']])

    def test_horn_retains_alternative_support(self):
        t = box(pred('red', 'cat'), pred('big', 'cat'), rule([pred('red', '?x')], [pred('big', '?x')]))
        r = answer(t, box(pred('big', 'cat')), backend='horn')
        self.assertEqual({frozenset(x) for x in r['support']}, {frozenset(['p1']), frozenset(['p0', 'p2'])})

    def test_skeptical_unanimity(self):
        self.assertEqual(aggregate([{'answer': 'True'}, {'answer': 'True'}], 'skeptical')['answer'], 'True')
        self.assertIsNone(aggregate([{'answer': 'True'}, {'answer': 'Unknown'}], 'skeptical')['answer'])

    def test_credulous_proof_and_conflict(self):
        self.assertEqual(aggregate([{'answer': 'True'}, {'answer': 'Unknown'}], 'credulous')['answer'], 'True')
        self.assertIsNone(aggregate([{'answer': 'True'}, {'answer': 'False'}], 'credulous')['answer'])
        self.assertIsNone(aggregate([{'answer': 'Unknown'}], 'credulous')['answer'])

    def test_cap_is_not_skeptical_proof(self):
        self.assertIsNone(aggregate([{'answer': 'True'}], 'skeptical', truncated=True)['answer'])
        self.assertIsNone(aggregate([{'answer': 'True'}], 'credulous', truncated=True)['answer'])
        self.assertEqual(aggregate([{'answer': 'True'}], 'top', truncated=True)['answer'], 'True')

    def test_missing_reading_abstains(self):
        self.assertIsNone(aggregate([], 'top')['answer'])


if __name__ == '__main__':
    unittest.main()
