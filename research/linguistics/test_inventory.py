import importlib.util
import sqlite3
import unittest

spec = importlib.util.spec_from_file_location('inventory', 'research/linguistics/inventory-proofwriter.py')
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)


class InventoryIntegrity(unittest.TestCase):
    def test_presented_natlang_not_synthetic(self):
        record = {'triples': {'triple1': {'text': 'Bob is blue.'}, 'triple2': {'text': 'Bob is kind.'}}, 'rules': {}, 'mappings': {'triple1': 's1', 'triple2': 's1'}, 'sentences': {'s1': 'Bob is blue but kind.'}}
        self.assertEqual(list(m.inputs(record)), [('Bob is blue but kind.', 'premise_fact', 'paraphrase', 'sentences.s1')])

    def test_gold_independence_and_stage_addition(self):
        record = {'triples': {'triple1': {'text': 'Bob is blue.', 'representation': 'DO NOT USE'}, 'triple2': {'text': 'Bob is nice.'}}, 'mappings': {'triple1': 's1'}, 'sentences': {'s1': 'Bob seems blue.'}, 'questions': {'q1': {'question': 'Bob is green.', 'answer': True, 'proofs': 'DO NOT USE'}}, 'abductions': {'q2': {'question': 'Bob is cold.', 'answers': [{'text': 'SECRET GOLD'}]}}, 'allInferences': [{'text': 'SECRET GOLD'}]}
        before = list(m.inputs(record))
        record['questions']['q1']['answer'] = False
        record['questions']['q1']['proofs'] = 'OTHER GOLD'
        record['triples']['triple1']['representation'] = 'OTHER GOLD'
        self.assertEqual(before, list(m.inputs(record)))
        self.assertEqual([x[0] for x in before], ['Bob seems blue.', 'Bob is nice.', 'Bob is green.', 'Bob is cold.'])

    def test_theory_punctuation_is_authoritative(self):
        record = {'id': 'test', 'theory': 'Bob is blue. He is cold; however, nice.', 'triples': {'triple1': {'text': 'Bob is blue.'}}, 'mappings': {'triple1': 's1'}, 'sentences': {'s1': 'Bob is blue; He is cold; however, nice.'}}
        self.assertEqual(list(m.inputs(record))[0][0], record['theory'])
        record['theory'] = 'Bob is blue. He is green; however, nice.'
        with self.assertRaises(ValueError):
            list(m.inputs(record))

    def test_sentence_split_counts_and_idempotence(self):
        db = sqlite3.connect(':memory:')
        db.execute('CREATE TABLE occurrences(text,file,role,layer,n,source,PRIMARY KEY(text,file,role,layer))')
        db.executemany('INSERT INTO occurrences VALUES (?,?,?,?,?,?)', [('Bob is blue. Bob is nice.', 'f', 'premise_fact', 'paraphrase', 3, 'x'), ('Bob is blue.', 'f', 'premise_fact', 'paraphrase', 7, 'y')])
        first = m.split_source_units(db)
        self.assertEqual(dict(db.execute('SELECT text,n FROM occurrences')), {'Bob is blue.': 10, 'Bob is nice.': 3})
        self.assertEqual(first['additional_sentence_occurrences'], 3)
        self.assertEqual(first, m.split_source_units(db))
        self.assertEqual(db.execute('SELECT SUM(n) FROM occurrences').fetchone()[0], 13)

    def test_surface_template_distinctions(self):
        pairs = [('If someone is big and not blue then they are cold.', 'PW.COND.GENERIC.COORD'), ('If the cow is blue then the dog is kind.', 'PW.COND.GROUND'), ('The bear does not see the dog.', 'PW.ATOM.TRANSITIVE.NEG'), ('All big, blue people are green.', 'PW.UNIVERSAL.EXPLICIT'), ('Big, blue things are green.', 'PW.UNIVERSAL.BARE'), ('Arthur cannot fly.', 'PW.ATOM.MODAL.NEG'), ('Fred is also said to be very kind.', 'PW.NL.ATTRIBUTION'), ('A big blue someone could also be green.', 'PW.NL.MODAL.HABITUAL')]
        for text, wanted in pairs:
            self.assertEqual(m.classify(text)[0], wanted, text)
        self.assertIn('they', m.classify(pairs[0][0])[1])
        self.assertIn('not', m.classify(pairs[0][0])[1])


unittest.main(verbosity=2)
