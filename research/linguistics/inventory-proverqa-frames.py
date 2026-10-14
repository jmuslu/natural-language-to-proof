#!/usr/bin/env python3
"""Refine input-only ProverQA residuals; counts are syntax audits, not parses.

Only text/count fields are inspected. Output contains aggregates and pre-authored
rule labels, never dataset sentences. Narrow audited rules intentionally enumerate
reviewed predicate tails; generalization beyond them is a separate research task.
"""
import argparse
from collections import Counter
import hashlib
import importlib.util
import json
from pathlib import Path
import re

_spec = importlib.util.spec_from_file_location('outer_inventory', Path(__file__).with_name('inventory-other.py'))
base = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(base)

# Every tail here was reviewed as a syntactic construction, without parser/gold
# outputs. Finite tails prevent bare token-shape matches claiming valency success.
AUDITED = {
    'transitive_values_bare_abstract_nominal': (
        'values tradition', 'values stability', 'values sustainability',
        'values simplicity', 'values diversity', 'values creativity',
        'values knowledge', 'values serenity', 'values experience',
        'values heritage', 'values accuracy'),
    'intransitive_works_adverb': (
        'works hard', 'works independently', 'works outdoors',
        'works diligently', 'works tirelessly'),
    'intransitive_listens_adverb': (
        'listens actively', 'listens deeply', 'listens intently', 'listens carefully'),
    'intransitive_thinks_adverb': (
        'thinks critically', 'thinks creatively', 'thinks quickly',
        'thinks ahead', 'thinks logically', 'thinks abstractly'),
    'prepositional_listens_to_nominal': (
        'listens to others', 'listens to opera', 'listens to podcasts'),
    'prepositional_cares_about_nominal': (
        'cares about nature', 'cares about the environment', 'cares about others'),
    'prepositional_cares_for_nominal': (
        'cares for others', 'cares for nature', 'cares for patients',
        'cares for animals', 'cares for plants', 'cares for people', 'cares for the soil'),
    'prepositional_collaborates_with_plural': (
        'collaborates with others', 'collaborates with experts',
        'collaborates with peers', 'collaborates with specialists',
        'collaborates with colleagues'),
    'locative_lives_pp': (
        'lives along the coast', 'lives in a coral reef', 'lives in the forest',
        'lives near the coast', 'lives in an arid land', 'lives in the rainforest'),
    'aspectual_stays_predicative_adjective': (
        'stays calm', 'stays active', 'stays alert', 'stays healthy'),
    'light_verb_takes_bare_nominal': (
        'takes risks', 'takes responsibility', 'takes action',
        'takes naps', 'takes initiative'),
    'idiomatic_thinks_outside_the_box': ('thinks outside the box',),
    'particle_gives_up': ('gives up',),
    'particle_stands_out': ('stands out',),
    'shared_subject_lexical_vp_disjunction': (
        'appreciates nature or learns about marine life',
        'shares recipes or respects tradition'),
    'shared_subject_lexical_copular_disjunction': (
        'values privacy or is introverted',),
}
NAME = r'[A-Z][A-Za-z-]*'
PATTERNS = {key: re.compile(NAME + ' (?:' + '|'.join(map(re.escape, tails)) + r')\.')
            for key, tails in AUDITED.items()}
PATTERNS.update({
    'titled_subject_negated_transitive': re.compile(
        r'Dr\. ' + NAME + r'(?: ' + NAME + r')? does not '
        r'(?:collect plant samples|publish research findings|develop new treatments)\.'),
    'possessive_subject_negated_copular': re.compile(
        NAME + r"'s (?:work is not viral|relationship is not spontaneous)\."),
})
CUES = {
    'title_initial': r'^(?:Dr\.|Mr\.|Mrs\.|Ms\.|Prof\.) ',
    'possessive_subject': r"^[A-Z][\w-]+['’]s\s",
    'any_possessive': r"(?:['’]s\b|s['’](?:\s|$)|\b(?:his|her|their|its|our|your|my)\b)",
    'coordination_token': r'\b(?:and|or)\b',
    'preposition_or_particle_token': r'\b(?:in|on|at|to|for|with|from|of|about|by|under|over|through|along|near|outside|into|out|up|off|back|away)\b',
    'particle_shaped_token': r'\b(?:up|out|off|back|away)\b',
    'complement_ing_candidate': r'^[A-Z][\w-]+ (?:enjoys|avoids|loves|likes|starts|continues) \w+ing\b',
    'linking_verb_candidate': r'^[A-Z][\w-]+ (?:becomes|stays|remains|seems|appears)\b',
    'light_verb_candidate': r'^[A-Z][\w-]+ (?:takes|makes|gives|has|does)\b',
    'attitude_verb_candidate': r'^[A-Z][\w-]+ (?:thinks|believes|knows|says|understands|hopes|wants)\b',
}


def audit(cache):
    counts, unique, cues, cue_unique, heads = (Counter() for _ in range(5))
    total = residual = distinct = distinct_residual = 0
    for line in cache.read_text().splitlines():
        row = json.loads(line)
        sentence, multiplicity = row['text'], row['count']
        if type(multiplicity) is not int or multiplicity < 1 or not isinstance(sentence, str):
            raise ValueError('invalid input cache text/count')
        total += multiplicity
        distinct += 1
        if base.family(sentence) != 'unclassified':
            continue
        residual += multiplicity
        distinct_residual += 1
        matches = [key for key, pattern in PATTERNS.items() if pattern.fullmatch(sentence)]
        if len(matches) > 1:
            raise ValueError('overlapping audited patterns')
        key = matches[0] if matches else 'remaining_unresolved'
        counts[key] += multiplicity
        unique[key] += 1
        for key, pattern in CUES.items():
            if re.search(pattern, sentence):
                cues[key] += multiplicity
                cue_unique[key] += 1
        match = re.match(NAME + r' ([a-z]+)\b', sentence)
        if match:
            heads[match.group(1)] += multiplicity
    assert sum(counts.values()) == residual
    assert sum(unique.values()) == distinct_residual
    return {
        'cache_sha256': hashlib.sha256(cache.read_bytes()).hexdigest(),
        'sentences': total, 'distinct': distinct,
        'residual_occurrences': residual, 'residual_distinct': distinct_residual,
        'audited_narrow_frames_occurrences': counts,
        'audited_narrow_frames_distinct': unique,
        'overlapping_candidate_cues_occurrences': cues,
        'overlapping_candidate_cues_distinct': cue_unique,
        'top_second_tokens_not_pos_tags': heads.most_common(20),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--cache', required=True, type=Path)
    args = parser.parse_args()
    print(json.dumps(audit(args.cache), indent=2))


if __name__ == '__main__':
    main()
