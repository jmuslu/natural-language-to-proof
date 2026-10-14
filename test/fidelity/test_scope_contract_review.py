"""Independent scope/status counterexamples, authored without parser observations."""
import copy
import unittest

from fidelity import evaluate_case, validate_case


def pred(name, *args):
    return {'tag': 'pred', 'name': name, 'args': list(args)}


def box(conditions, universe=()):
    return {'universe': list(universe), 'conditions': conditions}


def fixture(drs, asserted, embedded=(), reported=(), presupposed=()):
    return {'id': 'scope-review', 'construction': 'authored-scope-review',
            'text': 'Authored scope control.', 'origin': {'kind': 'authored-control'},
            'gold': [{'drs': drs, 'claims': {'universe': list(drs['universe']),
                'asserted': list(asserted), 'embedded': list(embedded),
                'reported': list(reported), 'presupposed': list(presupposed)}}]}


def observed(value):
    return {'id': 'scope-review', 'sentence_count': 1, 'parsed_sentences': 1,
            'typed_sentences': 1, 'drs_sentences': 1,
            'selected': value, 'readings': []}


def nested():
    # Every cat sees some dog: forall x(cat(x) -> exists y(dog(y) & see(x,y))).
    cat = pred('cat', {'ref': 'r0'})
    dog = pred('dog', {'ref': 'r1'})
    see = pred('see', {'ref': 'r0'}, {'ref': 'r1'})
    implication = {'tag': 'imp', 'left': box([cat], ['r0']),
                   'right': box([dog, see], ['r1'])}
    return fixture(box([implication]), [implication], [cat, dog, see])


class FidelityScopeReview(unittest.TestCase):
    def status(self, row, value):
        validate_case(row)
        return evaluate_case(row, observed(value))['status']

    def test_nested_shared_subject_and_fresh_object_exact_control(self):
        row = nested()
        self.assertEqual(self.status(row, copy.deepcopy(row['gold'][0])), 'exact')

    def test_reflexive_diagonal_cannot_equal_two_independent_witnesses(self):
        p = pred('see', {'ref': 'r0'}, {'ref': 'r0'})
        row = fixture(box([p], ['r0']), [p])
        q = pred('see', {'ref': 'r0'}, {'ref': 'r1'})
        wrong = fixture(box([q], ['r0', 'r1']), [q])['gold'][0]
        self.assertEqual(self.status(row, wrong), 'wrong_but_typed')

    def test_quantifier_scope_inversion_does_not_match_same_atoms(self):
        row = nested()
        cat = pred('cat', {'ref': 'r1'})
        dog = pred('dog', {'ref': 'r0'})
        see = pred('see', {'ref': 'r1'}, {'ref': 'r0'})
        implication = {'tag': 'imp', 'left': box([cat], ['r1']),
                       'right': box([see])}
        wrong = fixture(box([dog, implication], ['r0']), [dog, implication],
                        [cat, see])['gold'][0]
        self.assertEqual(self.status(row, wrong), 'wrong_but_typed')

    def test_free_reference_in_nested_consequent_gold_is_rejected(self):
        row = nested()
        row['gold'][0]['drs']['conditions'][0]['right']['conditions'][1]['args'][1] = {'ref': 'r7'}
        with self.assertRaises(ValueError):
            validate_case(row)

    def test_negation_witness_cannot_escape_to_sibling_gold(self):
        p = pred('dog', {'ref': 'r0'})
        neg = {'tag': 'not', 'body': box([p], ['r0'])}
        escaped = pred('sleep', {'ref': 'r0'})
        row = fixture(box([neg, escaped]), [neg, escaped], [p])
        with self.assertRaises(ValueError):
            validate_case(row)

    def test_nested_antecedent_negation_does_not_export_its_witness(self):
        p = pred('dog', {'ref': 'r0'})
        neg = {'tag': 'not', 'body': box([p], ['r0'])}
        imp = {'tag': 'imp', 'left': box([neg]), 'right': box([p])}
        row = fixture(box([imp]), [imp], [neg, p, p])
        with self.assertRaises(ValueError):
            validate_case(row)

    def test_repeated_reference_as_argument_is_not_duplicate_binder(self):
        p = pred('see', {'ref': 'r0'}, {'ref': 'r0'})
        row = fixture(box([p], ['r0']), [p])
        self.assertEqual(self.status(row, copy.deepcopy(row['gold'][0])), 'exact')

    def test_negated_embedded_atom_promoted_to_asserted_is_not_exact(self):
        p = pred('red', {'const': 'Ada'})
        neg = {'tag': 'not', 'body': box([p])}
        row = fixture(box([neg]), [neg], [p])
        wrong = copy.deepcopy(row['gold'][0])
        wrong['claims']['asserted'].append(p)
        wrong['claims']['embedded'] = []
        self.assertEqual(self.status(row, wrong), 'wrong_but_typed')

    def test_presupposed_atom_promoted_to_asserted_is_not_exact(self):
        p = pred('red', {'const': 'Ada'})
        pres = {'tag': 'presup', 'body': box([p])}
        row = fixture(box([pres]), [], presupposed=[p])
        wrong = copy.deepcopy(row['gold'][0])
        wrong['claims']['presupposed'] = []
        wrong['claims']['asserted'] = [p]
        self.assertEqual(self.status(row, wrong), 'wrong_but_typed')

    def test_report_holder_swap_is_not_exact_even_if_body_identical(self):
        p = pred('red', {'const': 'Ada'})
        att = {'tag': 'att', 'verb': 'say', 'holders': [{'const': 'Bob'}], 'body': box([p])}
        report = {'condition': p, 'chain': [{'verb': 'say', 'holders': [{'const': 'Bob'}], 'factive': False}]}
        row = fixture(box([att]), [att], reported=[report])
        wrong = copy.deepcopy(row['gold'][0])
        wrong['claims']['reported'][0]['chain'][0]['holders'][0] = {'const': 'Anne'}
        self.assertEqual(self.status(row, wrong), 'wrong_but_typed')

    def test_noncanonical_wire_alpha_rename_is_not_silently_normalized(self):
        # Scorer consumes already canonical structures; raw alpha-conversion is
        # the exporter's obligation. Renaming only the wire isn't a valid export.
        p = pred('dog', {'ref': 'r0'})
        row = fixture(box([p], ['r0']), [p])
        q = pred('dog', {'ref': 'r9'})
        wrong = fixture(box([q], ['r9']), [q])['gold'][0]
        self.assertEqual(self.status(row, wrong), 'wrong_but_typed')

    def test_gold_requires_canonical_first_occurrence_numbering(self):
        # Canonicalize always starts at r0; r9 cannot be the first canonical ref.
        p = pred('dog', {'ref': 'r9'})
        row = fixture(box([p], ['r9']), [p])
        with self.assertRaises(ValueError):
            validate_case(row)

    def test_gold_cannot_redeclare_enclosing_canonical_binder(self):
        # Canonical reference identity is global, not a lexical variable name
        # whose nested redeclaration may harmlessly shadow the outer binding.
        # This requests stricter gold policy: canonicalize itself preserves
        # duplicate declarations and can export this structure.
        p = pred('cat', {'ref': 'r0'})
        q = pred('dog', {'ref': 'r0'})
        neg = {'tag': 'not', 'body': box([q], ['r0'])}
        row = fixture(box([p, neg], ['r0']), [p, neg], [q])
        with self.assertRaises(ValueError):
            validate_case(row)


if __name__ == '__main__':
    unittest.main()
