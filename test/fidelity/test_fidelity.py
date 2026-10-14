"""Meaning comparisons must preserve scope, commitment, and selection failures."""
import copy
import unittest

from fidelity import validate_case, project_request, evaluate_case, summarize


def atom(name='smile',term=None):
    return dict(tag='pred',name=name,args=[term or {'const':'john'}])


def box(*conditions,universe=()):
    return dict(universe=list(universe),conditions=list(conditions))


def meaning():
    condition=atom()
    return dict(drs=box(condition),claims=dict(universe=[],asserted=[condition],
                reported=[],presupposed=[],embedded=[]))


def case():
    return dict(id='fixture',construction='intransitive',text='John smiles.',
                origin=dict(kind='authored-control'),gold=[meaning()],notes='Manual expectation.')


def response(value=None):
    value=value or meaning()
    return dict(id='fixture',sentence_count=1,parsed_sentences=1,typed_sentences=1,
                drs_sentences=1,selected=value,readings=[dict(sentence_id=0,index=0,typed=True,meaning=value)])


class FidelityContractTests(unittest.TestCase):
    def test_only_id_and_text_cross_inference_boundary(self):
        row=case();row['notes']='SECRET';row['gold'][0]['claims']['asserted'][0]['name']='SECRET'
        self.assertEqual(project_request(row),dict(id='fixture',text='John smiles.'))

    def test_exact_requires_drs_and_independent_claim_table(self):
        row=case();observed=response()
        self.assertEqual(evaluate_case(row,observed)['status'],'exact')
        observed=copy.deepcopy(observed)
        observed['selected']['claims']['reported']=[dict(condition=atom(),chain=[])]
        observed['selected']['claims']['asserted']=[]
        self.assertEqual(evaluate_case(row,observed)['status'],'wrong_but_typed')

    def test_same_literal_with_missing_existential_scope_is_not_exact(self):
        row=case();m=row['gold'][0];a=atom(term={'ref':'r0'})
        m['drs']=box(a,universe=['r0']);m['claims']['universe']=['r0'];m['claims']['asserted']=[a]
        observed=response(copy.deepcopy(m));observed['selected']['drs']['universe']=[]
        self.assertEqual(evaluate_case(row,observed)['status'],'wrong_but_typed')

    def test_duplicate_claims_are_not_silently_deduplicated(self):
        row=case();row['gold'][0]['drs']['conditions']*=2;row['gold'][0]['claims']['asserted']*=2
        self.assertEqual(evaluate_case(row,response())['status'],'wrong_but_typed')

    def test_correct_alternative_does_not_relabel_wrong_selected_reading(self):
        wrong=meaning();wrong['drs']['conditions'][0]['name']='sleep'
        observed=response(wrong)
        observed['readings'].append(dict(sentence_id=0,index=1,typed=True,meaning=meaning()))
        result=evaluate_case(case(),observed)
        self.assertEqual(result['status'],'wrong_but_typed')
        self.assertTrue(result['any_reading_exact'])
        self.assertEqual(result['matching_reading_indices'],[1])

    def test_failure_categories_do_not_hide_typed_wrong_meaning(self):
        for changes,expected in [
            (dict(parsed_sentences=0,typed_sentences=0,drs_sentences=0,selected=None,readings=[]),'no_parse'),
            (dict(typed_sentences=0,drs_sentences=0,selected=None),'type_failure'),
            (dict(sentence_count=2),'incomplete')]:
            observed=response();observed.update(changes)
            self.assertEqual(evaluate_case(case(),observed)['status'],expected)

    def test_gold_scope_validates_implication_accessibility_without_sibling_escape(self):
        row=case();m=row['gold'][0];a=atom(term={'ref':'r0'})
        rule=dict(tag='imp',left=box(a,universe=['r0']),right=box(a))
        m['drs']=box(rule);m['claims']['asserted']=[rule];m['claims']['embedded']=[a,a]
        validate_case(row)
        rule['tag']='or'
        with self.assertRaises(ValueError):validate_case(row)

    def test_claim_table_cannot_drop_top_universe(self):
        row=case();m=row['gold'][0];a=atom(term={'ref':'r0'})
        m['drs']=box(a,universe=['r0']);m['claims']['asserted']=[a]
        with self.assertRaises(ValueError):validate_case(row)

    def test_either_annotation_is_checked_when_manually_specified(self):
        row=case();m=row['gold'][0]
        disjunction=dict(tag='or',left=box(atom()),right=box(atom('sleep')))
        m['drs']=box(disjunction);m['claims']['asserted']=[disjunction]
        m['claims']['embedded']=[atom(),atom('sleep')]
        m['disjunctions']=[dict(path=['conditions',0],either=True,scope_ambiguous=False)]
        validate_case(row)
        observed=response(copy.deepcopy(m));observed['selected']['disjunctions'][0]['either']=False
        self.assertEqual(evaluate_case(row,observed)['status'],'wrong_but_typed')

    def test_disjunction_annotations_must_target_unique_actual_disjunctions(self):
        row=case();m=row['gold'][0]
        annotation=dict(path=['conditions',0],either=True,scope_ambiguous=False)
        m['disjunctions']=[annotation]
        with self.assertRaises(ValueError):validate_case(row)
        disjunction=dict(tag='or',left=box(atom()),right=box(atom('sleep')))
        m['drs']=box(disjunction);m['claims']['asserted']=[disjunction]
        m['claims']['embedded']=[atom(),atom('sleep')]
        validate_case(row)
        annotation['path']=['conditions',-1]
        with self.assertRaises(ValueError):validate_case(row)
        annotation['path']=['conditions',0]
        m['disjunctions'].append(copy.deepcopy(annotation))
        with self.assertRaises(ValueError):validate_case(row)

    def test_or_gold_requires_complete_explicit_annotations(self):
        row=case();m=row['gold'][0]
        disjunction=dict(tag='or',left=box(atom()),right=box(atom('sleep')))
        m['drs']=box(disjunction);m['claims']['asserted']=[disjunction]
        for annotations in (None,[]):
            if annotations is not None:m['disjunctions']=annotations
            with self.assertRaises(ValueError):validate_case(row)
        m['disjunctions']=[dict(path=['conditions',0],either=False,scope_ambiguous=False)]
        validate_case(row)
        observed=response(copy.deepcopy(m));observed['selected']['disjunctions'][0]['either']=True
        self.assertEqual(evaluate_case(row,observed)['status'],'wrong_but_typed')

    def test_equality_terms_are_not_disjunction_child_boxes(self):
        row=case();m=row['gold'][0]
        equality=dict(tag='eq',left={'const':'John'},right={'const':'Jack'})
        m['drs']=box(equality);m['claims']['asserted']=[equality]
        validate_case(row)

    def test_nested_or_requires_all_annotation_paths_in_order(self):
        row=case();m=row['gold'][0]
        inner=dict(tag='or',left=box(atom()),right=box(atom('sleep')))
        outer=dict(tag='or',left=box(inner),right=box(atom('laugh')))
        m['drs']=box(outer);m['claims']['asserted']=[outer]
        a=dict(path=['conditions',0],either=False,scope_ambiguous=False)
        b=dict(path=['conditions',0,'left','conditions',0],either=False,scope_ambiguous=False)
        for annotations in ([a],[b],[b,a]):
            m['disjunctions']=annotations
            with self.assertRaises(ValueError):validate_case(row)
        m['disjunctions']=[a,b];validate_case(row)

    def test_claim_references_must_occur_in_drs(self):
        for group in ('asserted','presupposed','embedded'):
            row=case();row['gold'][0]['claims'][group]=[atom(term={'ref':'r999'})]
            with self.assertRaises(ValueError):validate_case(row)
        row=case();row['gold'][0]['claims']['reported']=[dict(condition=atom(),chain=[
            dict(verb='say',holders=[{'ref':'r999'}],factive=False)])]
        with self.assertRaises(ValueError):validate_case(row)

    def test_exporter_integral_json_numbers_are_valid_but_fractional_nonfinite_are_not(self):
        observed=response()
        for key in ('sentence_count','parsed_sentences','typed_sentences','drs_sentences'):
            observed[key]=float(observed[key])
        for key in ('sentence_id','index'):
            observed['readings'][0][key]=float(observed['readings'][0][key])
        self.assertEqual(evaluate_case(case(),observed)['status'],'exact')
        for invalid in (True,0.5,float('nan'),float('inf'),-1.0):
            for key in ('sentence_count','parsed_sentences','typed_sentences','drs_sentences'):
                mutated=copy.deepcopy(observed);mutated[key]=invalid
                self.assertEqual(evaluate_case(case(),mutated)['status'],'error')
            for key in ('sentence_id','index'):
                mutated=copy.deepcopy(observed);mutated['readings'][0][key]=invalid
                self.assertEqual(evaluate_case(case(),mutated)['status'],'error')

    def test_malformed_observation_is_error_not_parse_failure_or_exact(self):
        mutations=[dict(sentence_count=None),dict(sentence_count=True),dict(sentence_count=-1),
                   dict(parsed_sentences=2),dict(typed_sentences=2),dict(drs_sentences=2),
                   dict(parsed_sentences=0),dict(typed_sentences=0),dict(readings='bad'),
                   dict(selected=[]),dict(readings=[{}]),dict(readings=[dict(
                       sentence_id=1,index=0,typed=True,meaning=meaning())])]
        for mutation in mutations:
            observed=response();observed.update(mutation)
            self.assertEqual(evaluate_case(case(),observed)['status'],'error',mutation)
        observed=response();del observed['sentence_count']
        self.assertEqual(evaluate_case(case(),observed)['status'],'error')

    def test_malformed_universe_is_a_validation_error(self):
        row=case();row['gold'][0]['drs']['universe']=[{'ref':'r0'}]
        with self.assertRaises(ValueError):validate_case(row)

    def test_summary_keeps_failure_denominators_and_construction_groups(self):
        rows=[dict(id=str(i),construction='quantifier',status=status,any_reading_exact=any_exact)
              for i,(status,any_exact) in enumerate([('exact',True),('wrong_but_typed',True),('no_parse',False),('type_failure',False),('incomplete',None)])]
        result=summarize(rows)
        self.assertEqual(result['n'],5)
        self.assertEqual(result['counts']['wrong_but_typed'],1)
        self.assertEqual(result['by_construction']['quantifier']['counts']['exact'],1)
        self.assertEqual(result['any_reading_exact'],dict(n_evaluable=4,n_exact=2))


if __name__=='__main__':unittest.main()
