#!/usr/bin/env python3
"""Aggregate ProntoQA presented-input templates; never read answer/proof fields.

This is an anchored surface inventory, not a semantic parser or a fidelity test.
No raw strings or examples are emitted. Unknown templates stay explicit.
"""
import argparse
from collections import Counter, defaultdict
from functools import lru_cache
import hashlib
import json
from pathlib import Path
import re
import zipfile

WORD = r"[A-Za-z][A-Za-z-]*"
PRED = re.compile(rf"(?:not )?(?:a |an )?{WORD}")
SPLIT = re.compile(r",\s*(?:(?:and|or) )?|\s+(?:and|or)\s+")

def predicate_features(text, slot):
    parts = SPLIT.split(text)
    if not parts or not all(PRED.fullmatch(x) for x in parts):
        return None
    fs = []
    for op in ('and', 'or'):
        if re.search(rf'\b{op}\b', text): fs.append(slot+'_'+op)
    if 'not ' in text: fs.append(slot+'_negation')
    if any(re.match(r'(?:not )?an? ', x) for x in parts):
        fs.append(slot+'_article_predication')
    if any(not re.match(r'(?:not )?an? ', x) for x in parts):
        fs.append(slot+'_bare_predication')
    if ',' in text: fs.append(slot+'_comma_list')
    return fs

@lru_cache(maxsize=None)
def classify(sentence):
    if not sentence.endswith('.') or any(x in sentence[:-1] for x in '.!?'):
        return 'unmatched', ('punctuation_unmatched',)
    s = sentence[:-1]
    clauses = None
    if (m := re.fullmatch(r'Everything that is (.+) is (.+)', s)):
        family = 'universal_restrictive_relative'
        left, right = m.groups()
        fs = predicate_features(left, 'restriction')
        other = predicate_features(right, 'consequent')
        if fs is None or other is None: return 'unmatched', ('relative_predicate_unmatched',)
        fs += other
    elif (m := re.fullmatch(rf'(Every|Each) ({WORD}) is (.+)', s)):
        family = 'universal_every_each'
        fs = predicate_features(m[3], 'consequent')
    elif (m := re.fullmatch(rf'({WORD}) are (.+)', s)):
        family = 'universal_bare_plural'
        fs = predicate_features(m[2], 'consequent')
    elif (m := re.fullmatch(rf'({WORD}) is (.+)', s)):
        # Repeated copulas reveal sentence-level coordination, unlike a single
        # copula with coordinated predicative NPs/adjectives.
        if re.search(rf'\b{WORD} is\b', m[2]):
            family = 'named_clause_coordination'
            clauses = re.split(rf',\s*(?:(?:and|or) )?(?={WORD} is )|\s+(?:and|or)\s+(?={WORD} is )', s)
            fs = []
            for part in clauses:
                cm = re.fullmatch(rf'({WORD}) is (.+)', part)
                more = predicate_features(cm[2], 'consequent') if cm else None
                if more is None: return 'unmatched', ('coordinated_clause_unmatched',)
                fs.extend(more)
            for op in ('and', 'or'):
                if re.search(rf'\b{op}\s+{WORD} is\b', s): fs.append('clause_'+op)
            if re.search(rf',\s*(?:(?:and|or) )?(?={WORD} is )', s): fs.append('clause_comma_list')
        else:
            family = 'named_single_clause'
            fs = predicate_features(m[2], 'consequent')
    else:
        return 'unmatched', ('outer_unmatched',)
    if fs is None: return 'unmatched', ('predicate_unmatched',)
    if re.search(r'\band\b', s) and re.search(r'\bor\b', s): fs.append('mixed_and_or_surface')
    if ',' in s: fs.append('internal_comma')
    return family, tuple(sorted(set(fs)))

def sentences(text):
    # All supplied fields use full stops, without title abbreviations. Unknown
    # punctuation is retained and rejected by classify rather than repaired.
    return [s.strip() for s in re.split(r'(?<=[.!?])\s+', text.strip()) if s.strip()]

def inputs(path):
    value = json.loads(path.read_text())
    if isinstance(value, list):
        for i, row in enumerate(value):
            for s in sentences(row['context']): yield str(i), 'logiclm_theory', s
            q = row['question']
            prefix = 'Is the following statement true or false? '
            if not q.startswith(prefix): raise ValueError('Unknown LogicLM query wrapper')
            yield str(i), 'logiclm_query', q[len(prefix):]
    elif isinstance(value, dict):
        for key, trial in value.items():
            for name, row in trial.items():
                if not isinstance(row,dict) or not {'question','query'} <= row.keys():
                    raise ValueError('Unknown OOD record schema')
                role = 'test' if name == 'test_example' else 'demonstration'
                if role == 'demonstration' and not name.startswith('in_context_example'):
                    raise ValueError('Unknown OOD role')
                rec = key+'/'+name
                for s in sentences(row['question']): yield rec, role+'_theory', s
                q = row['query']
                if not q.startswith('Prove: '): raise ValueError('Unknown OOD query wrapper')
                yield rec, role+'_query', q[7:]
    else: raise ValueError('Unknown top-level schema')

def self_check():
    family, fs = classify('Everything that is a zor or red is blue and cold.')
    assert family == 'universal_restrictive_relative'
    assert {'restriction_or', 'consequent_and', 'mixed_and_or_surface'} <= set(fs)
    assert 'restriction_and' not in fs
    family, fs = classify('Alex is a zor, a dax, and red and Max is cold.')
    assert family == 'named_clause_coordination'
    assert 'consequent_comma_list' in fs and 'clause_comma_list' not in fs
    assert classify('Alex is red, Max is cold, and Fae is blue.')[1].count('clause_comma_list') == 1
    for s in ['Alex likes Max.', 'Alex is a zor who likes Max.', 'Alex is red. Max is blue.', 'Alex is red']:
        assert classify(s)[0] == 'unmatched'

def main():
    self_check()
    ap=argparse.ArgumentParser();ap.add_argument('--data',type=Path,required=True);ap.add_argument('--output',type=Path,required=True);args=ap.parse_args()
    files=sorted(args.data.glob('*.json'))
    roles=Counter();families=Counter();unique=Counter();profiles=Counter();profile_unique=defaultdict(set);family_unique=defaultdict(set);role_families=defaultdict(Counter);records=set();hashes={};file_counts={};unmatched=Counter();features=Counter();role_records=defaultdict(set);legacy_passive=Counter();legacy_passive_total=0
    for p in files:
        hashes[p.name]=hashlib.sha256(p.read_bytes()).hexdigest()
        count=0
        for rec,role,s in inputs(p):
            count+=1;records.add((p.name,rec));role_records[role].add((p.name,rec));roles[role]+=1;unique[s]+=1
            family,fs=classify(s);families[family]+=1;family_unique[family].add(s);profiles[(family,fs)]+=1;profile_unique[(family,fs)].add(s);role_families[role][family]+=1
            features.update(fs)
            passive_words = re.findall(r'\b(?:is|are|was|were|be|been) (?:\w+ly )?(\w+(?:ed|en))\b', s.lower())
            if passive_words:
                legacy_passive_total += 1
                legacy_passive.update(set(passive_words))
            if family=='unmatched': unmatched[fs]+=1
        file_counts[p.name]=count
    archive={}
    for p in sorted(args.data.glob('*.zip')):
        with zipfile.ZipFile(p) as z:
            members=[i for i in z.infolist() if i.filename.endswith('.json')]
            identical=sum(Path(i.filename).name in hashes and hashlib.sha256(z.read(i)).hexdigest()==hashes[Path(i.filename).name] for i in members)
            archive[p.name]={'json_members':len(members),'byte_identical_extracted_members':identical}
    total=sum(roles.values());assert sum(families.values())==sum(profiles.values())==sum(file_counts.values())==total
    out={'schema':'prontoqa-surface-inventory-v2','file_count':len(files),'record_count':len(records),'sentence_occurrences':total,'unique_sentences':len(unique),'roles':dict(roles),'role_records':{k:len(v) for k,v in role_records.items()},'families':{k:{'occurrences':n,'unique':len(family_unique[k])} for k,n in families.most_common()},'features':dict(features.most_common()),'joint_profiles':[{'family':k[0],'features':k[1],'occurrences':n,'unique':len(profile_unique[k])} for k,n in profiles.most_common()],'role_families':role_families,'unmatched_profiles':{','.join(k):v for k,v in unmatched.items()},'file_occurrences':file_counts,'sha256':hashes,'archives_not_double_counted':archive,'legacy_passive_suffix_audit':{'sentence_occurrences':legacy_passive_total,'matched_words_sentence_counts':dict(legacy_passive)}}
    args.output.parent.mkdir(parents=True,exist_ok=True);args.output.write_text(json.dumps(out,indent=2)+'\n')
    print(json.dumps({k:out[k] for k in ('file_count','record_count','sentence_occurrences','unique_sentences','families','unmatched_profiles','archives_not_double_counted')},indent=2))
if __name__=='__main__': main()
