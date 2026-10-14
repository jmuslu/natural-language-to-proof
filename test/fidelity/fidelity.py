"""Exact meaning-fidelity evaluation with manual gold outside the parser process.

The gold format is documented in README.md. Canonical condition order, multiplicity,
and scope are significant; this is structural fidelity, not logical equivalence.
"""
import argparse
from collections import Counter
import hashlib
import json
import math
from pathlib import Path
import re
import subprocess
import sys
import time

ROOT=Path(__file__).resolve().parents[2]
STATUSES=('exact','wrong_but_typed','no_parse','type_failure','incomplete','error')


def object_keys(value,keys):
    if not isinstance(value,dict) or set(value)!=set(keys):
        raise ValueError('expected object keys '+str(sorted(keys)))


def string(value):
    if not isinstance(value,str) or not value:
        raise ValueError('expected nonempty string')


def refs(value):
    if not isinstance(value,list):
        raise ValueError('universe must contain unique canonical references')
    for ref in value:
        if not isinstance(ref,str) or not re.fullmatch(r'r\d+',ref):
            raise ValueError('canonical references must have form r0, r1, ...')
    if len(set(value))!=len(value):
        raise ValueError('universe must contain unique canonical references')


def term(value,bound):
    if not isinstance(value,dict) or set(value) not in ({'ref'},{'const'}):
        raise ValueError('term must be exactly ref or const')
    name=next(iter(value.values()));string(name)
    if 'ref' in value:
        if not re.fullmatch(r'r\d+',name) or bound is not None and name not in bound:
            raise ValueError('free or noncanonical reference in gold DRS: '+name)


def box(value,bound=()):
    object_keys(value,('universe','conditions'));refs(value['universe'])
    if not isinstance(value['conditions'],list):raise ValueError('conditions must be a list')
    inner=None if bound is None else set(bound)|set(value['universe'])
    for condition in value['conditions']:cond(condition,inner)


def cond(value,bound=None):
    if not isinstance(value,dict):raise ValueError('condition must be an object')
    tag=value.get('tag')
    if tag=='pred':
        object_keys(value,('tag','name','args'));string(value['name'])
        if not isinstance(value['args'],list):raise ValueError('predicate args must be a list')
        for argument in value['args']:term(argument,bound)
    elif tag=='eq':
        object_keys(value,('tag','left','right'));term(value['left'],bound);term(value['right'],bound)
    elif tag in ('not','presup'):
        object_keys(value,('tag','body'));box(value['body'],bound)
    elif tag in ('imp','or'):
        object_keys(value,('tag','left','right'));box(value['left'],bound)
        right_bound=(None if bound is None else set(bound)|set(value['left']['universe'])) if tag=='imp' else bound
        box(value['right'],right_bound)
    elif tag=='att':
        object_keys(value,('tag','verb','holders','body'));string(value['verb'])
        if not isinstance(value['holders'],list):raise ValueError('holders must be a list')
        for holder in value['holders']:term(holder,bound)
        box(value['body'],bound)
    else:raise ValueError('unknown canonical condition tag: '+str(tag))


def referenced_names(value):
    """Inspect references without computing expected claim classifications."""
    if isinstance(value,dict):
        names={value['ref']} if set(value)=={'ref'} else set()
        names.update(value.get('universe',[]))
        for child in value.values():names.update(referenced_names(child))
        return names
    if isinstance(value,list):
        return set().union(*(referenced_names(child) for child in value))
    return set()


def disjunction_paths(value,path=()):
    paths=[]
    for index,condition in enumerate(value['conditions']):
        here=path+('conditions',index)
        if condition['tag']=='or':paths.append(here)
        child_keys={'not':('body',),'presup':('body',),'att':('body',),
                    'imp':('left','right'),'or':('left','right')}.get(condition['tag'],())
        for key in child_keys:
            paths.extend(disjunction_paths(condition[key],here+(key,)))
    return paths


def validate_meaning(value):
    if not isinstance(value,dict) or set(value)-{'drs','claims','disjunctions'} or not {'drs','claims'}<=set(value):
        raise ValueError('gold meaning requires drs and independently authored claims')
    box(value['drs'])
    claims=value['claims']
    object_keys(claims,('universe','asserted','reported','presupposed','embedded'))
    if claims['universe']!=value['drs']['universe']:
        raise ValueError('claim table must retain the root DRS universe')
    for name in ('asserted','presupposed','embedded'):
        if not isinstance(claims[name],list):raise ValueError('claim group must be a list')
        for condition in claims[name]:cond(condition)
    if not isinstance(claims['reported'],list):raise ValueError('reported claims must be a list')
    for report in claims['reported']:
        object_keys(report,('condition','chain'));cond(report['condition'])
        if not isinstance(report['chain'],list) or not report['chain']:
            raise ValueError('reported claims require a nonempty attribution chain')
        for attribution in report['chain']:
            object_keys(attribution,('verb','holders','factive'));string(attribution['verb'])
            if type(attribution['factive']) is not bool or not isinstance(attribution['holders'],list):
                raise ValueError('invalid attribution')
            for holder in attribution['holders']:term(holder,None)
    if not referenced_names(claims)<=referenced_names(value['drs']):
        raise ValueError('claim reference absent from gold DRS')
    required_paths=disjunction_paths(value['drs'])
    if required_paths and 'disjunctions' not in value:
        raise ValueError('every disjunction requires explicit annotations')
    if 'disjunctions' in value:
        if not isinstance(value['disjunctions'],list):raise ValueError('disjunction annotations must be a list')
        seen=set()
        for annotation in value['disjunctions']:
            object_keys(annotation,('path','either','scope_ambiguous'))
            if (not isinstance(annotation['path'],list) or
                any(type(v) not in (str,int) for v in annotation['path']) or
                type(annotation['either']) is not bool or type(annotation['scope_ambiguous']) is not bool):
                raise ValueError('invalid disjunction annotation')
            path=tuple(annotation['path'])
            if path in seen:raise ValueError('duplicate disjunction annotation path')
            seen.add(path)
            target=value['drs']
            try:
                for step in path:
                    if isinstance(target,list) and type(step) is int and 0<=step<len(target):
                        target=target[step]
                    elif isinstance(target,dict) and isinstance(step,str):target=target[step]
                    else:raise ValueError('invalid disjunction path')
            except KeyError as exc:raise ValueError('invalid disjunction path') from exc
            if not isinstance(target,dict) or target.get('tag')!='or':
                raise ValueError('disjunction annotation must target an or condition')
        if [tuple(a['path']) for a in value['disjunctions']]!=required_paths:
            raise ValueError('disjunction annotations must cover every or in traversal order')


def semantics_contract_id(row):
    """Evaluation metadata only; absent legacy policies are not inferred from text."""
    if 'semantics_contract' not in row:return None
    metadata=row['semantics_contract']
    identifier=metadata.get('id') if isinstance(metadata,dict) else metadata
    if not isinstance(identifier,str) or not identifier.strip():
        raise ValueError('semantics_contract requires a nonempty string or object id')
    return identifier


def validate_case(row):
    if not isinstance(row,dict) or not {'id','construction','text','origin','gold'}<=set(row):
        raise ValueError('case requires id, construction, text, origin, gold')
    for key in ('id','construction','text'):string(row[key])
    if not isinstance(row['origin'],dict) or row['origin'].get('kind') not in ('authored-control','benchmark-adapted'):
        raise ValueError('origin must declare authored-control or benchmark-adapted')
    if not isinstance(row['gold'],list) or not row['gold']:raise ValueError('gold must list manual allowed readings')
    for value in row['gold']:validate_meaning(value)
    semantics_contract_id(row)
    return row


def project_request(row):
    return {key:row[key] for key in ('id','text')}


def json_equal(expected,observed):
    # JSON booleans are not numeric indices, despite Python True == 1.
    if type(expected) is bool or type(observed) is bool:
        return type(expected) is type(observed) and expected == observed
    if isinstance(expected,dict) and isinstance(observed,dict):
        return expected.keys() == observed.keys() and all(
            json_equal(value,observed[key]) for key,value in expected.items())
    if isinstance(expected,list) and isinstance(observed,list):
        return len(expected) == len(observed) and all(
            json_equal(a,b) for a,b in zip(expected,observed))
    return expected == observed


def matches(expected,observed):
    # Exporter metadata is allowed only outside the specified meaning components.
    return isinstance(observed,dict) and all(
        key in observed and json_equal(value,observed[key]) for key,value in expected.items())


def first_difference(expected,observed,path=()):
    if isinstance(expected,dict) and isinstance(observed,dict):
        if path and observed.keys() - expected.keys():
            key=sorted(observed.keys() - expected.keys())[0]
            return dict(path=list(path)+[key],expected='<absent>',observed=observed[key])
        for key,value in expected.items():
            if key not in observed:return dict(path=list(path)+( [key]),expected=value,observed='<missing>')
            diff=first_difference(value,observed[key],path+(key,))
            if diff:return diff
        return None
    if isinstance(expected,list) and isinstance(observed,list):
        if len(expected)!=len(observed):return dict(path=list(path),expected_length=len(expected),observed_length=len(observed))
        for index,(a,b) in enumerate(zip(expected,observed)):
            diff=first_difference(a,b,path+(index,))
            if diff:return diff
        return None
    return None if json_equal(expected,observed) else dict(path=list(path),expected=expected,observed=observed)


def integral_number(value):
    # The production JNum wire format renders integral counts as 1.0.
    return type(value) is int or (type(value) is float and math.isfinite(value) and value == int(value))


def observation_error(response):
    if 'error' in response:return str(response['error'])
    counts=[response.get(k) for k in ('sentence_count','parsed_sentences','typed_sentences','drs_sentences')]
    if any(not integral_number(v) or v<0 for v in counts):
        return 'observation requires nonnegative integer sentence counts'
    n,parsed,typed,drs=counts
    if not 0<=drs<=typed<=parsed<=n:return 'inconsistent observation sentence counts'
    if 'selected' not in response:return 'observation missing selected meaning'
    selected=response['selected']
    if (drs==0 and selected is not None) or (drs>0 and
            (not isinstance(selected,dict) or
             not all(isinstance(selected.get(k),dict) for k in ('drs','claims')))):
        return 'selected meaning disagrees with DRS count or has invalid shape'
    readings=response.get('readings')
    if not isinstance(readings,list):return 'observation readings must be an array'
    seen=set()
    for reading in readings:
        if not isinstance(reading,dict):return 'invalid reading object'
        sentence=reading.get('sentence_id');index=reading.get('index')
        if (not integral_number(sentence) or not 0<=sentence<n or
                not integral_number(index) or index<0 or type(reading.get('typed')) is not bool or
                'meaning' not in reading):return 'invalid reading fields'
        key=(sentence,index)
        if key in seen:return 'duplicate reading index'
        seen.add(key)
    return None


def evaluate_case(row,response):
    if not isinstance(response,dict) or response.get('id')!=row['id']:
        raise ValueError('observation/request ID mismatch')
    error=observation_error(response)
    n=response.get('sentence_count',0)
    parsed=response.get('parsed_sentences',0);typed=response.get('typed_sentences',0)
    drs=response.get('drs_sentences',0);selected=response.get('selected')
    if error is not None:status='error'
    elif n==0 or parsed==0:status='no_parse'
    elif parsed<n:status='incomplete'
    elif typed<n or drs<n or selected is None:status='type_failure'
    elif any(matches(g,selected) for g in row['gold']):status='exact'
    else:status='wrong_but_typed'
    matching=[r['index'] for r in response.get('readings',[]) if r.get('typed') and
              any(matches(g,r.get('meaning')) for g in row['gold'])] if n==1 and error is None else []
    return dict(id=row['id'],construction=row['construction'],status=status,
                semantics_contract_id=semantics_contract_id(row),
                any_reading_exact=bool(matching) if n==1 and error is None else None,
                matching_reading_indices=matching,
                selected_exact_gold_indices=[i for i,g in enumerate(row['gold']) if matches(g,selected)],
                first_gold_difference=first_difference(row['gold'][0],selected) if status=='wrong_but_typed' else None,
                observed_selected=selected,error=error)


def summarize(rows):
    result=summary_counts(rows)
    identifiers=sorted({r.get('semantics_contract_id') for r in rows},
                       key=lambda value:(value is not None,value or ''))
    result['by_semantics_contract']=[dict(semantics_contract_id=identifier,
        **summary_counts([r for r in rows if r.get('semantics_contract_id')==identifier]))
        for identifier in identifiers]
    result['aggregation_scope']=('empty' if not identifiers else
        'mixed_contracts' if len(identifiers)>1 else
        'legacy_unversioned' if identifiers[0] is None else 'single_declared_contract')
    # IDs partition evidence; they do not prove consistent meanings, membership,
    # independence, representativeness or satisfaction of the owner's launch gate.
    result['certifies_acceptance_panel']=False
    result['contract_interpretation']=(
        'Aggregate counts are diagnostic only, not coherent acceptance-panel certification. '
        'Null contract IDs are legacy unversioned meanings, potentially with mixed policies. '
        'Do not pool incompatible contracts for acceptance; declared IDs alone do not '
        'validate their semantic policy or establish a representative fidelity gate.')
    return result


def summary_counts(rows):
    counts=Counter(row['status'] for row in rows)
    evaluable=[row['any_reading_exact'] for row in rows if row['any_reading_exact'] is not None]
    result=dict(n=len(rows),counts={status:counts[status] for status in STATUSES},
                exact_rate=counts['exact']/len(rows) if rows else None,
                any_reading_exact=dict(n_evaluable=len(evaluable),n_exact=sum(evaluable)))
    result['by_construction']={name:summary_group([r for r in rows if r['construction']==name])
                               for name in sorted({r['construction'] for r in rows})}
    return result


def summary_group(rows):
    counts=Counter(row['status'] for row in rows)
    return dict(n=len(rows),counts={status:counts[status] for status in STATUSES},
                any_reading_exact=sum(r['any_reading_exact'] is True for r in rows))


def unique_object(pairs):
    if len({key for key,_ in pairs})!=len(pairs):raise ValueError('duplicate JSON key')
    return dict(pairs)


def read_jsonl(path):
    return [json.loads(line,object_pairs_hook=unique_object) for line in Path(path).read_text().splitlines() if line.strip()]


def file_hash(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def validate_execution(value):
    """Validate protocol metadata only; never interpret a sentence or gold."""
    if not isinstance(value, dict) or set(value) != {'schema', 'parser', 'nominal_nouns'}:
        raise ValueError('execution requires exact schema/parser/nominal_nouns keys')
    if value['schema'] != 'nominal-policy-v1':
        raise ValueError('invalid execution schema')
    parser, policy = value['parser'], value['nominal_nouns']
    allowed = {'hand': {'not-applicable'},
               'default': {'known-only', 'context-unknown'},
               'pos': {'known-only', 'context-unknown'}}
    if not isinstance(parser, str) or parser not in allowed or not isinstance(policy, str) or policy not in allowed[parser]:
        raise ValueError('invalid execution parser/nominal policy combination')
    return value


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--cases',type=Path,required=True)
    parser.add_argument('--binary',type=Path,required=True)
    parser.add_argument('--parser',choices=['hand','default','pos'],required=True)
    parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--nominal-nouns',choices=['known-only','context-unknown'])
    parser.add_argument('--timeout-seconds',type=float,default=600)
    parser.add_argument('--require-exact',action='store_true')
    args=parser.parse_args()
    if args.parser == 'hand' and args.nominal_nouns is not None:
        parser.error('hand parser does not accept nominal policy')
    execution=validate_execution(dict(schema='nominal-policy-v1',parser=args.parser,nominal_nouns=
        'not-applicable' if args.parser == 'hand' else (args.nominal_nouns or 'known-only')))
    cases=[validate_case(row) for row in read_jsonl(args.cases)]
    if len({row['id'] for row in cases})!=len(cases):raise ValueError('duplicate case IDs')
    binary=args.binary.resolve();binary_hash=file_hash(binary)
    flags={'hand':['--hand'],'default':[],'pos':['--pos-backoff']}[args.parser]
    if args.parser != 'hand':flags.append('--nominal-nouns='+execution['nominal_nouns'])
    requests=[project_request(row) for row in cases]
    started=time.monotonic()
    process=subprocess.run([str(binary)]+flags,input=''.join(json.dumps(row,ensure_ascii=False)+'\n' for row in requests),
                           capture_output=True,text=True,timeout=args.timeout_seconds,check=True)
    elapsed=time.monotonic()-started
    observations=[json.loads(line,object_pairs_hook=unique_object) for line in process.stdout.splitlines() if line.strip()]
    if len(observations)!=len(cases):raise ValueError('one response per case required')
    for response in observations:
        if not isinstance(response,dict) or validate_execution(response.get('execution')) != execution:
            raise ValueError('exporter execution does not match requested configuration')
    evaluated=[evaluate_case(row,response) for row,response in zip(cases,observations)]
    args.output.parent.mkdir(parents=True,exist_ok=True)
    observations_path=args.output.with_suffix('.observations.jsonl')
    observations_path.write_text(''.join(json.dumps(dict(request=request,response=response),ensure_ascii=False)+'\n'
                                        for request,response in zip(requests,observations)))
    stderr_path=args.output.with_suffix('.stderr.log');stderr_path.write_text(process.stderr)
    source_paths=['test/fidelity/Export.hs','test/fidelity/fidelity.py','test/fidelity/run.py']+[
        str(path.relative_to(ROOT)) for path in sorted((ROOT/'src').rglob('*.hs'))]
    report=dict(schema=1,parser=args.parser,execution=execution,cases=str(args.cases.resolve()),cases_sha256=file_hash(args.cases),
                binary=str(binary),binary_sha256=binary_hash,wall_seconds=elapsed,
                source_sha256={path:file_hash(ROOT/path) for path in source_paths},
                source_hash_interpretation='Observed at evaluation; these hashes may differ from the compiled source snapshot. The executable SHA256 identifies the parser actually run.',
                observations=str(observations_path),observations_sha256=file_hash(observations_path),
                summary=summarize(evaluated),cases_results=evaluated,
                interpretation='Manual structural meaning gold, never solver-answer gold. Selected exactness is primary; any-reading exactness is a sentence-only diagnostic within returned candidates. Scope, order, duplicates and claim commitment are preserved.')
    args.output.write_text(json.dumps(report,indent=2,ensure_ascii=False)+'\n')
    print(json.dumps(report['summary'],indent=2))
    if args.require_exact and report['summary']['counts']['exact']!=len(cases):return 1
    return 0


if __name__=='__main__':sys.exit(main())
