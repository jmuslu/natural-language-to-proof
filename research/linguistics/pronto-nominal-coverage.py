#!/usr/bin/env python3
"""Reproduce nominal-v1 surface opportunity from committed joint profiles only.

No raw text, lexical corpus, model, answer fields or parser are read or launched.
This measures surface structure, never parse or semantic coverage.
"""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path

DIRECT = frozenset({'consequent_article_predication'})
FAMILIES = {'universal_every_each', 'universal_bare_plural',
            'universal_restrictive_relative', 'named_single_clause',
            'named_clause_coordination'}

def require(condition, message):
    if not condition:
        raise ValueError(message)

def bucket(row):
    if row['family'] != 'universal_every_each':
        return 'excluded_outer_' + row['family']
    features = frozenset(row['features'])
    if features == DIRECT:
        return 'surface_opportunity_direct_positive_article'
    if 'consequent_negation' in features:
        return 'excluded_universal_negative_consequent'
    if features & {'consequent_and', 'consequent_or', 'consequent_comma_list'}:
        return ('excluded_universal_mixed_coordinated_consequent'
                if 'consequent_bare_predication' in features
                else 'excluded_universal_nominal_coordinated_consequent')
    if features == {'consequent_bare_predication'}:
        return 'excluded_universal_single_bare_consequent'
    raise ValueError('unreviewed universal joint profile')

def aggregate(inventory):
    require(inventory['schema'] == 'prontoqa-surface-inventory-v2', 'unexpected inventory schema')
    require(not inventory['unmatched_profiles'], 'unmatched input templates need review')
    require(set(inventory['families']) == FAMILIES, 'unreviewed outer family')
    totals = Counter(); unique = Counter(); families = Counter(); family_unique = Counter()
    simple = Counter(); simple_unique = Counter()
    seen = set()
    for row in inventory['joint_profiles']:
        identity = (row['family'], tuple(row['features']))
        require(identity not in seen, 'duplicate joint profile'); seen.add(identity)
        require(list(row['features']) == sorted(set(row['features'])), 'features must be sorted and unique')
        require(type(row['occurrences']) is int and type(row['unique']) is int
                and 0 < row['unique'] <= row['occurrences'], 'invalid count')
        label = bucket(row)
        totals[label] += row['occurrences']; unique[label] += row['unique']
        families[row['family']] += row['occurrences']; family_unique[row['family']] += row['unique']
        # A single positive nominal consequent can coexist with a complex
        # relative restriction, but repeated-clause conjunction is not a single
        # complement. Keep the outer-family distinction explicit.
        consequent = {f for f in row['features'] if f.startswith('consequent_')}
        if consequent == DIRECT and row['family'] != 'named_clause_coordination':
            simple[row['family']] += row['occurrences']; simple_unique[row['family']] += row['unique']
    require(sum(totals.values()) == inventory['sentence_occurrences'], 'occurrence conservation')
    require(sum(unique.values()) == inventory['unique_sentences'], 'unique conservation')
    require(dict(families) == {k:v['occurrences'] for k,v in inventory['families'].items()}, 'family conservation')
    require(dict(family_unique) == {k:v['unique'] for k,v in inventory['families'].items()}, 'unique family conservation')
    eligible = 'surface_opportunity_direct_positive_article'
    return {
        'schema': 'pronto-nominal-v1-structural-opportunity-v1',
        'nominal_candidate': '8e2a6ad1780d9e2cf837e02c8c6f9351f0dcd371',
        'scope': '80 extracted files, all presented theory/query roles including demonstrations; archives not double counted',
        'denominator': {'occurrences': inventory['sentence_occurrences'], 'unique': inventory['unique_sentences']},
        'structural_partition': {k:{'occurrences':totals[k], 'unique':unique[k]} for k in sorted(totals)},
        'single_positive_article_consequent_by_outer_family':
            {k:{'occurrences':simple[k], 'unique':simple_unique[k]} for k in sorted(simple)},
        'lexical_eligibility': {
            'status': 'not_identifiable_from_aggregate',
            'structural_opportunity_occurrences_unassessed':totals[eligible],
            'structural_opportunity_unique_unassessed':unique[eligible],
            'dictionary_unknown_count': None, 'conflicting_pos_count': None,
            'fully_licensed_count': None,
            'reason': 'No token/profile join, POS-count evidence, offered-source-category or seen-pair evidence in aggregate; no unknown/eligible counts inferred.'},
        'interpretation': 'Necessary surface form only, not parser coverage or fidelity. Word slots do not prove lexical N, lemma, POS or source category. Occurrence weighting includes demonstrations.',
        'inventory_joint_profile_count': len(seen),
    }

def self_check():
    def row(fs, family='universal_every_each'):
        return {'family':family, 'features':fs}
    require(bucket(row(['consequent_article_predication'])) == 'surface_opportunity_direct_positive_article', 'positive control')
    for fs in [['consequent_article_predication','consequent_negation'],
               ['consequent_and','consequent_article_predication'],
               ['consequent_bare_predication']]:
        require(bucket(row(fs)).startswith('excluded_'), 'joint exclusion control')
    require(bucket(row(['consequent_article_predication'], 'named_single_clause')).startswith('excluded_outer_'), 'subject control')
    try:
        bucket(row(['new_feature']))
    except ValueError:
        pass
    else:
        raise ValueError('unreviewed feature must fail closed')

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--inventory',type=Path,default=Path(__file__).with_name('prontoqa-inventory.json'))
    parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args(); self_check()
    raw=args.inventory.read_bytes(); result=aggregate(json.loads(raw))
    result['inventory_sha256']=hashlib.sha256(raw).hexdigest()
    args.output.write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps({k:result[k] for k in ['denominator','structural_partition','single_positive_article_consequent_by_outer_family','lexical_eligibility']},indent=2))

if __name__=='__main__':
    main()
