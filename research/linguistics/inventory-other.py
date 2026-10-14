#!/usr/bin/env python3
"""Count presented English constructions, keeping raw text in ignored local files.

This is an inventory, not a semantic parser. A sentence has one outer family and
zero or more overlapping construction features. Gold labels/formulas/proofs are
never read. Counts distinguish physical occurrences from global surface types.
"""
import argparse
import collections
import hashlib
import json
import pathlib
import re

QUERY_PREFIXES = (
    'Based on the above information, is the following statement true, false, or uncertain? ',
    'Is the following statement true or false? ', 'Prove: ',
)

def strip_query(s):
    for p in QUERY_PREFIXES:
        if s.startswith(p):
            return s[len(p):]
    return s


def split_sentences(s):
    # Generated corpora do not have abbreviation-aware premise arrays. Preserve
    # punctuation; audit the resulting local unique-sentence file before claiming
    # this split recovers all constructions. FOLIO has explicit newline premises.
    return [x.strip() for x in re.split(r'(?<!\bDr\.)(?<!\bMr\.)(?<!\bMs\.)(?<!\bMrs\.)(?<!\bProf\.)(?<=[.!?])\s+', s.strip()) if x.strip()]


def features(s):
    t = s.lower()
    patterns = {
        'negation': r'\b(?:not|never|no|neither|nor|cannot)\b|n.t\b',
        'never': r'\bnever\b',
        'coord_and': r'\band\b', 'coord_or': r'\bor\b',
        'exclusive': r'\b(?:not both|mutually exclusive|but not simultaneously|exactly one)\b',
        'either': r'\beither\b', 'relative': r'\b(?:who|which|that)\b',
        'reflexive': r'\b(?:himself|herself|itself|themselves|oneself)\b',
        'possessive': r"\b(?:his|her|its|their)\b|\w['’]s\b",
        'modal': r'\b(?:can|could|may|might|must|should|would|will|cannot)\b',
        'only': r'\bonly\b', 'unless': r'\bunless\b',
        'conditional': r'\bif\b', 'biconditional': r'\bif and only if\b',
        'passive_candidate': r'\b(?:is|are|was|were|be|been) (?:\w+ly )?\w+(?:ed|en)\b',
        # Indefinite pronouns are not S[ng] evidence merely because they end in ing.
        'gerund_candidate': r'\b(?!(?:anything|everything|nothing|something|thing|king|spring)\b)\w+ing\b',
        'particle_or_pp': r'\b(?:up|down|out|off|on|over|in|into|from|to|with|for|at|of|about|through)\b',
        'punctuation_internal': r'[,;:()]',
        'existential_there': r'\bthere (?:is|are|exists)\b',
        'numeral': r'\b(?:\d+|one|two|three|four|five|six|seven|eight|nine|ten|least|most|exactly)\b',
        'report_or_attitude': r'\b(?:say|says|said|believes?|knows?|knew|realizes?|realized|claims?|claimed|thinks?|thought)\b',
    }
    return [k for k,p in patterns.items() if re.search(p,t)]


def family(s):
    t = s.strip().rstrip('.!?').lower()
    if t.startswith('if '): return 'conditional_initial'
    if ' if and only if ' in t: return 'biconditional'
    if ' only if ' in t: return 'only_if'
    if re.search(r'\bunless\b',t): return 'unless'
    if t.startswith('either '): return 'sentence_either_or'
    if t.startswith('neither '): return 'sentence_neither_nor'
    if t.startswith('for '): return 'for_topic'
    if re.match(r'(?:everyone|everybody|anyone|anybody|whoever|anything|everything|those|people)\b',t): return 'quantified_pronoun_or_relative'
    if re.match(r'(?:all|every|each|any)\b',t): return 'universal_nominal'
    if re.match(r'(?:no|none|nobody|nothing|no one)\b',t): return 'negative_quantifier'
    if re.match(r'(?:some|someone|somebody|something|a|an)\b',t): return 'existential_nominal'
    if re.match(r'there (?:is|are|exists)\b',t): return 'existential_there'
    if ' if ' in t: return 'conditional_final'
    if re.search(r'\beither\b',t): return 'vp_either_or'
    if re.search(r'\bneither\b',t): return 'vp_neither_nor'
    if re.match(r'[\w-]+(?: and [\w-]+)* are\b',t): return 'bare_plural_generic'
    if re.match(r'(?:[\w-]+|the [\w-]+) (?:is|was|isn.t|wasn.t)\b',t): return 'subject_copula'
    if re.match(r'(?:[\w-]+|the [\w-]+) (?:does|did|doesn.t|didn.t)\b',t): return 'subject_do'
    if re.match(r'(?:[\w-]+|the [\w-]+) (?:has|have|had|hasn.t|haven.t)\b',t): return 'subject_have'
    if re.match(r'(?:[\w-]+|the [\w-]+) (?:can|could|may|might|must|should|would|will|cannot)\b',t): return 'subject_modal'
    # This is intentionally marked for manual subcategorization, not a claim
    # that arbitrary English is understood by a lexical-verb catch-all.
    return 'unclassified'


def inputs(data, repo):
    for p in sorted((data/'proverqa').rglob('*.json')):
        rel=p.relative_to(data).as_posix()
        rows=json.loads(p.read_text())
        for i,r in enumerate(rows):
            src=f'{rel}/{r.get("id",i)}'
            for j,s in enumerate(split_sentences(r['context'])):
                yield 'proverqa',rel,src,'theory',j,s
            yield 'proverqa',rel,src,'query',0,strip_query(r['question'])
    for p in sorted((data/'prontoqa').rglob('*.json')):
        rel=p.relative_to(data).as_posix()
        rows=json.loads(p.read_text())
        if isinstance(rows,list):
            for i,r in enumerate(rows):
                src=f'{rel}/{r.get("id",i)}'
                for j,s in enumerate(split_sentences(r['context'])):
                    yield 'prontoqa',rel,src,'theory',j,s
                yield 'prontoqa',rel,src,'query',0,strip_query(r['question'])
        else:
            for key,r in rows.items():
                for ex,e in r.items():
                    if not isinstance(e,dict) or 'question' not in e or 'query' not in e:
                        raise ValueError(f'Unknown input schema: {p.name}/{key}/{ex}')
                    src=f'{rel}/{key}/{ex}'
                    role='test' if ex=='test_example' else 'demonstration'
                    for j,s in enumerate(split_sentences(e['question'])):
                        yield 'prontoqa',rel,src,role+'_theory',j,s
                    yield 'prontoqa',rel,src,role+'_query',0,strip_query(e['query'])
    for line in (repo/'bench/folio/sample.jsonl').read_text().splitlines():
        r=json.loads(line); src=r['id']
        for j,s in enumerate(r['context'].splitlines()):
            yield 'folio_sample','bench/folio/sample.jsonl',src,'premise',j,s.strip()
        yield 'folio_sample','bench/folio/sample.jsonl',src,'query',0,r['statement']


def main():
    ap=argparse.ArgumentParser();ap.add_argument('--data',type=pathlib.Path,required=True);ap.add_argument('--work',type=pathlib.Path,required=True);ap.add_argument('--output',type=pathlib.Path,required=True);a=ap.parse_args()
    a.work.mkdir(parents=True,exist_ok=True)
    corpora={}
    for ds,file,source,role,index,s in inputs(a.data,pathlib.Path(__file__).resolve().parents[2]):
        d=corpora.setdefault(ds,{'sentences':{},'files':collections.Counter(),'roles':collections.Counter(),'records':set()})
        d['files'][file]+=1;d['roles'][role]+=1;d['records'].add(source)
        row=d['sentences'].setdefault(s,{'count':0,'source':source,'role':role,'index':index})
        row['count']+=1
    result={'schema':'input-constructions-v1','classification':'outer family plus overlapping features; unclassified is explicit','datasets':{}}
    for ds,d in corpora.items():
        families={};feats={};profiles=collections.Counter()
        with (a.work/(ds+'-unique.jsonl')).open('w') as f:
            for s,row in sorted(d['sentences'].items()):
                fam=family(s); fs=features(s)
                profiles[(fam, tuple(sorted(fs)))]+=row['count']
                f.write(json.dumps({'text':s,'family':fam,'features':fs,**row},ensure_ascii=False)+'\n')
                x=families.setdefault(fam,{'count':0,'unique_count':0,'examples':[]});x['count']+=row['count'];x['unique_count']+=1
                if len(x['examples'])<3:x['examples'].append({'text':s,'source':row['source'],'role':row['role']})
                for ft in fs:
                    y=feats.setdefault(ft,{'count':0,'unique_count':0});y['count']+=row['count'];y['unique_count']+=1
        total=sum(d['roles'].values())
        result['datasets'][ds]={'file_count':len(d['files']),'records':len(d['records']),'sentence_occurrences':total,'unique_sentences':len(d['sentences']),'roles':dict(d['roles']),'files':dict(d['files']),'constructions':dict(sorted(families.items(),key=lambda x:-x[1]['count'])),'features':dict(sorted(feats.items(),key=lambda x:-x[1]['count']))}
        result['datasets'][ds]['feature_profiles']=[{'family':fam,'features':list(fs),'count':n} for (fam,fs),n in sorted(profiles.items(),key=lambda x:(-x[1],x[0]))]
        result['datasets'][ds]['sha256']={file:hashlib.sha256(((pathlib.Path(__file__).resolve().parents[2] if ds=='folio_sample' else a.data)/file).read_bytes()).hexdigest() for file in d['files']}
        assert sum(v['count'] for v in families.values())==total
        assert sum(profiles.values())==total
        print(ds,total,len(d['sentences']),{k:v['count'] for k,v in result['datasets'][ds]['constructions'].items()})
    a.output.write_text(json.dumps(result,indent=2,ensure_ascii=False)+'\n')

if __name__=='__main__':main()
