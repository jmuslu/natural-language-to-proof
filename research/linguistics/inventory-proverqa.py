#!/usr/bin/env python3
"""Audit ProverQA input English only; print aggregates, never labels or raw text.

Outer classes and cues are surface diagnostics, not semantic parses. The residual
partition deliberately leaves lexical frames for manual review rather than
pretending that a catch-all verb pattern establishes construction coverage.
"""
import argparse
import collections
import importlib.util
import json
from pathlib import Path
import re

spec = importlib.util.spec_from_file_location('inventory_other', Path(__file__).with_name('inventory-other.py'))
base = importlib.util.module_from_spec(spec)
spec.loader.exec_module(base)

CUES = {
    'if_someone_or_anyone': r'\bif (?:someone|anyone|somebody|anybody)\b',
    'anyone_who': r'\b(?:anyone|everyone|someone|those|people) who\b',
    'relative_who': r'\bwho\b',
    'relative_that_candidate': r'\bthat\b',
    'explicit_not_both': r'\bnot both\b',
    'not_necessarily_both': r'\bnot necessarily both\b',
    'not_necessary': r'\bnot necessary\b',
    'mutually_exclusive': r'\bmutually exclusive\b',
    'or_both': r'\bor both\b',
    'either_without_explicit_exclusion': None,
    'reflexive': r'\b(?:himself|herself|itself|themselves|oneself)\b',
    'phrasal_look_up_candidate': r'\blook(?:s|ed|ing)? up\b',
    'phrasal_carry_out_candidate': r'\bcarr(?:y|ies|ied|ying) out\b',
    'phrasal_give_up_candidate': r'\bgiv(?:e|es|ing) up\b|\bgave up\b',
    'copular_indefinite_predicate': r'\b(?:is|are|was|were) (?:a|an)\b',
    'negated_do': r'\b(?:does|do|did) not\b',
    'negated_copula': r'\b(?:is|are|was|were) not\b',
    'pronoun_he_she_they': r'\b(?:he|she|they)\b',
}

def residual(s):
    # These are token-shape partitions, explicitly NOT recovered CCG templates.
    if re.match(r'^[A-Z][\w-]+ [a-z][\w-]*s\b', s):
        return 'one_capitalized_token_plus_s_ending_token'
    if re.match(r'^[A-Z][\w-]+ [a-z]', s):
        return 'one_capitalized_token_plus_other_lowercase_token'
    return 'other_residual'

def main():
    ap = argparse.ArgumentParser()
    group = ap.add_mutually_exclusive_group(required=True)
    group.add_argument('--root', type=Path)
    group.add_argument('--cache', type=Path, help='Read unique JSONL with text/count; roles are unrecoverable from deduplicated cache')
    a = ap.parse_args()
    texts = collections.Counter()
    files = {}
    roles = collections.Counter()
    if a.root:
        for path in sorted(a.root.rglob('*.json')):
            rows = json.loads(path.read_text())
            if not isinstance(rows, list):
                raise ValueError('Unexpected ProverQA schema')
            count = 0
            for row in rows:
                # Do not inspect answers, reasoning, nl2fol, or conclusion_fol.
                theory = base.split_sentences(row['context'])
                query = base.strip_query(row['question'])
                texts.update(theory + [query])
                roles['theory'] += len(theory)
                roles['query'] += 1
                count += len(theory) + 1
            files[str(path.relative_to(a.root))] = {'records': len(rows), 'sentences': count}
        sentences = texts.items()
    else:
        def cached():
            with a.cache.open() as stream:
                for line in stream:
                    row = json.loads(line)
                    if not isinstance(row['count'], int) or row['count'] < 1:
                        raise ValueError('Invalid cache multiplicity')
                    yield row['text'], row['count']
        sentences = cached()
    total = unique = 0
    outer = collections.Counter()
    unmatched = collections.Counter()
    cues = collections.Counter()
    nested = collections.Counter()
    for sentence, n in sentences:
        total += n
        unique += 1
        fam = base.family(sentence)
        outer[fam] += n
        if fam == 'unclassified':
            unmatched[residual(sentence)] += n
        for name, pattern in CUES.items():
            if pattern is not None and re.search(pattern, sentence, re.I):
                cues[name] += n
                if fam == 'conditional_initial':
                    nested[name] += n
        if re.search(r'\beither\b', sentence, re.I) and not re.search(r'\b(?:not both|mutually exclusive|but not simultaneously|exactly one)\b', sentence, re.I):
            cues['either_without_explicit_exclusion'] += n
    assert sum(outer.values()) == total
    if a.root:
        assert total == sum(roles.values())
    assert sum(unmatched.values()) == outer['unclassified']
    print(json.dumps({'files': files, 'roles': roles, 'sentences': total, 'unique': unique, 'outer': outer, 'unmatched_audit': unmatched, 'overlapping_cues': cues, 'conditional_initial_nested_cues': nested}, indent=2))

if __name__ == '__main__':
    main()
