#!/usr/bin/env python3
"""Join cached Pronto input frequencies to a bounded lexical POS snapshot.

Only compact counts are publishable. --recover output and --evidence input
contain local token keys and belong under ignored research/runs/.
"""
import argparse
from collections import Counter
import hashlib
import json
import math
from pathlib import Path
import re
import subprocess

PATTERN = re.compile(r'^(Every|Each) ([A-Za-z][A-Za-z-]*) is (a|an) ([A-Za-z][A-Za-z-]*)\.$')
CONFLICT = {'JJ', 'JJR', 'JJS', 'NNP', 'NNPS'}
NOUN = {'NN', 'NNS'}
STATUSES = ['unknown_pos','contrary_adjective_or_name_pos','noun_pos_supported','known_other_pos_only']

def require(condition, message):
    if not condition:
        raise ValueError(message)

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def recover(cache, inventory_path, output):
    inventory=json.loads(inventory_path.read_text())
    expected=[r for r in inventory['joint_profiles'] if r['family']=='universal_every_each'
              and r['features']==['consequent_article_predication']]
    require(len(expected)==1, 'expected one exact joint profile')
    count=total=eligible=unique=0; keys=set(); pairs={}; previous=None
    before=digest(cache)
    for line in cache.open():
        row=json.loads(line); text=row['text']; n=row['count']
        require(type(n) is int and n>0, 'invalid cached frequency')
        require(previous is None or previous<text, 'cache must be strictly sorted unique inputs')
        previous=text; count+=1; total+=n
        match=PATTERN.fullmatch(text)
        if match:
            eligible+=n; unique+=1; subject=match[2]; predicate=match[4]
            keys.update([subject,predicate]); key=(subject,predicate)
            pair=pairs.setdefault(key,dict(subject=subject,predicate=predicate,occurrences=0,unique=0))
            pair['occurrences']+=n; pair['unique']+=1
    require(before==digest(cache), 'cache changed during recovery')
    require((count,total)==(inventory['unique_sentences'],inventory['sentence_occurrences']), 'whole-cache inventory mismatch')
    require((unique,eligible)==(expected[0]['unique'],expected[0]['occurrences']), 'joint-profile inventory mismatch')
    result=dict(schema=1,cache_sha256=before,inventory_sha256=digest(inventory_path),
                all_unique=count,all_occurrences=total,eligible_unique=unique,eligible_occurrences=eligible,
                interior_lookup='literal case; both nouns are noninitial tokens',keys=sorted(keys),
                pairs=sorted(pairs.values(),key=lambda p:(p['subject'],p['predicate'])))
    output.parent.mkdir(parents=True,exist_ok=True)
    output.write_text(json.dumps(result,indent=2)+'\n')
    output.with_suffix('.keys.txt').write_text(''.join(k+'\n' for k in sorted(keys)))
    return {'all_unique':count,'all_occurrences':total,'opportunity_unique':unique,
            'opportunity_occurrences':eligible,'noun_key_count':len(keys),'pair_count':len(pairs)}

def snapshot(keys_path, extractor_path, output):
    root=Path(__file__).resolve().parents[2]
    subprocess.run(['git','diff','--exit-code','HEAD','--','src'],cwd=root,check=True,capture_output=True)
    names=['src/NL2Proof/Syntax/CCGDeriv.hs','src/NL2Proof/Syntax/CCGBank.hs',
           'src/NL2Proof/Syntax/CCGSupertag.hs','src/NL2Proof/Syntax/CCGSemParse.hs']
    paths=[root/name for name in names]+[extractor_path.resolve(),keys_path.resolve()]
    require(all(path.is_relative_to(root) for path in paths), 'snapshot files must be within worktree')
    sources={str(path.relative_to(root)):digest(path) for path in paths}
    helper_dirty=bool(subprocess.check_output(['git','status','--porcelain','--',str(extractor_path.resolve())],cwd=root,text=True).strip())
    context=dict(scan_source_commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip(),
      tracked_parser_source_clean=True,extractor_was_uncommitted_at_scan=helper_dirty,
      adapted_from_names_extractor_commit='7d85eb1',
      adapted_from_names_extractor_sha256='027eb15d045282433454f4a6e048a1ee34c5e31b2adb2221909da5af6b8cda53')
    output.parent.mkdir(parents=True,exist_ok=True)
    output.write_text(json.dumps(sources,indent=2)+'\n')
    output.with_suffix('.context.json').write_text(json.dumps(context,indent=2)+'\n')
    return {'snapshot_source_count':len(sources),'scan_source_commit':context['scan_source_commit']}

def integer_count(value, positive=False):
    # Haskell JNum renders exact integral counts as e.g. 4.0. Accept only
    # finite integral numeric values, never booleans or fractional weights.
    require(type(value) in (int,float), 'count must be numeric, not boolean')
    require(type(value) is int or (math.isfinite(value) and value.is_integer()), 'nonintegral count')
    require(value>0 if positive else value>=0, 'count outside permitted range')
    return int(value)

def normalized_counts(counts):
    return {key:integer_count(value,positive=True) for key,value in counts.items()}

def status(counts):
    counts=normalized_counts(counts)
    if not counts: return 'unknown_pos'
    if set(counts)&CONFLICT: return 'contrary_adjective_or_name_pos'
    if set(counts)&NOUN: return 'noun_pos_supported'
    return 'known_other_pos_only'

def joined(pairs_path,evidence_path,manifest_path,extractor_path,scan_sources_path,scan_context_path):
    pairdata=json.loads(pairs_path.read_text()); evidence=json.loads(evidence_path.read_text())
    source_snapshot=json.loads(scan_sources_path.read_text()); context=json.loads(scan_context_path.read_text())
    root=Path(__file__).resolve().parents[2]
    for name,value in source_snapshot.items():
        require(digest(root/name)==value, 'scan source changed: '+name)
    require(context['tracked_parser_source_clean'] is True, 'dirty parser source at scan')
    require(evidence['files_unreadable_or_changed']==0, 'unreadable or changed corpus input prevents join')
    for name in ['files_read','files_missing','files_unreadable_or_changed']:
        evidence[name]=integer_count(evidence[name])
    for name in ['accepted_trees','rejected_lines','skipped_lines']:
        evidence['evidence'][name]=integer_count(evidence['evidence'][name])
    rows=evidence['evidence']['keys']
    lexical={r['form']:dict(r,pos=normalized_counts(r['pos']),categories=normalized_counts(r['categories'])) for r in rows}
    require(len(lexical)==len(rows) and set(lexical)==set(pairdata['keys']), 'lexical keyset mismatch')
    require(evidence['evidence']['interior_tokens'] is True, 'wrong lookup context')
    manifest=[json.loads(line) for line in manifest_path.read_text().splitlines()]
    require(len(manifest)==2000, 'unexpected training candidate count')
    require(len({r['path'] for r in manifest})==len(manifest), 'duplicate training input path')
    require(sum(r['status']=='read' for r in manifest)==evidence['files_read'], 'read manifest mismatch')
    require(sum(r['status']=='missing' for r in manifest)==evidence['files_missing'], 'missing manifest mismatch')
    require(evidence['files_read']+evidence['files_missing']==2000, 'incomplete manifest')
    labels={w:status(r['pos']) for w,r in lexical.items()}
    matrix={}; token=Counter(); distinct=Counter(labels.values()); n_attested=Counter()
    total=unique=0
    for row in pairdata['pairs']:
        a,b=labels[row['subject']],labels[row['predicate']]
        require(type(row['occurrences'])is int and type(row['unique'])is int
                and 0<row['unique']<=row['occurrences'], 'invalid joined frequency')
        result=matrix.setdefault((a,b),{'occurrences':0,'unique':0})
        result['occurrences']+=row['occurrences']; result['unique']+=row['unique']
        total+=row['occurrences']; unique+=row['unique']
        for slot in ['subject','predicate']:
            word=row[slot]; token[labels[word]]+=row['occurrences']
            n_attested[slot]+=row['occurrences'] if lexical[word]['categories'].get('N',0)>0 else 0
    require((total,unique)==(pairdata['eligible_occurrences'],pairdata['eligible_unique']), 'joined conservation failure')
    eligible=matrix.get(('noun_pos_supported','noun_pos_supported'),{'occurrences':0,'unique':0})
    return dict(schema='pronto-nominal-v1-pos-policy-join-v1',candidate='8e2a6ad',
        opportunity=dict(occurrences=total,unique=unique,noun_keys=len(lexical),noun_pairs=len(pairdata['pairs'])),
        evidence_source=dict(cache_sha256=pairdata['cache_sha256'],inventory_sha256=pairdata['inventory_sha256'],
          pair_join_sha256=digest(pairs_path),lexical_snapshot_sha256=digest(evidence_path),
          training_manifest_sha256=digest(manifest_path),extractor_sha256=digest(extractor_path),
          scan_source_manifest_sha256=digest(scan_sources_path),scan_context_sha256=digest(scan_context_path),
          scan_source_commit=context['scan_source_commit'],
          extractor_was_uncommitted_at_scan=context['extractor_was_uncommitted_at_scan'],
          adapted_from_names_extractor_commit=context['adapted_from_names_extractor_commit'],
          training_sections='02-21; exact ccgbankTrainFiles candidate list',
          files_read=evidence['files_read'],files_missing=evidence['files_missing'],
          files_unreadable_or_changed=evidence['files_unreadable_or_changed'],
          accepted_trees=evidence['evidence']['accepted_trees'],rejected_lines=evidence['evidence']['rejected_lines'],
          casing='literal interior subject/predicate tokens; no lowercase substitution'),
        distinct_noun_keys_by_pos_status={k:distinct[k] for k in STATUSES},
        noun_token_occurrences_by_pos_status={k:token[k] for k in STATUSES},
        joint_subject_predicate_pos_status=[dict(subject=a,predicate=b,**v) for (a,b),v in sorted(matrix.items())],
        both_nouns_pos_policy_supported=eligible,
        noun_category_attested_occurrences=dict(n_attested),
        actual_nominal_route_eligible=None,
        interpretation='Necessary POS policy only for observed local training snapshot. Raw N attestation is not offered-tag/pruning eligibility. Missing source tags, seen pairs, morphology and chart survival unmeasured. Counts are not parse or fidelity rates.')

def self_check():
    require(status({})=='unknown_pos','unknown control')
    require(status({'NN':2})=='noun_pos_supported','noun control')
    require(status({'NNS':2,'VB':3})=='noun_pos_supported','noun/nonconflicting evidence control')
    for contrary in sorted(CONFLICT):
        require(status({'NN':100,contrary:1})=='contrary_adjective_or_name_pos','rare contrary control')
    require(status({'VB':2})=='known_other_pos_only','known nonnoun control')
    rendered=json.loads('{"pos":{"NN":4.0,"VB":1.0}}')['pos']
    require(normalized_counts(rendered)=={'NN':4,'VB':1}, 'actual JNum integer rendering normalization')
    require(status(rendered)=='noun_pos_supported', 'actual JNum fixture classification')
    for bad in [{'NN':0},{'NN':-1},{'NN':True},{'NN':1.5},{'NN':float('inf')},{'NN':float('nan')}]:
        try: status(bad)
        except ValueError: pass
        else: raise ValueError('bad count admitted')

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    sub=parser.add_subparsers(dest='action',required=True)
    recover_parser=sub.add_parser('recover')
    recover_parser.add_argument('--cache',type=Path,required=True)
    recover_parser.add_argument('--inventory',type=Path,default=Path(__file__).with_name('prontoqa-inventory.json'))
    recover_parser.add_argument('--output',type=Path,required=True)
    join_parser=sub.add_parser('join')
    for arg in ['pairs','evidence','manifest','extractor','scan-sources','scan-context','output']:
        join_parser.add_argument('--'+arg,type=Path,required=True)
    snapshot_parser=sub.add_parser('snapshot')
    for arg in ['keys','extractor','output']:
        snapshot_parser.add_argument('--'+arg,type=Path,required=True)
    sub.add_parser('self-test'); args=parser.parse_args();self_check()
    if args.action=='self-test': print('POS policy synthetic controls passed')
    elif args.action=='recover': print(json.dumps(recover(args.cache,args.inventory,args.output),indent=2))
    elif args.action=='snapshot': print(json.dumps(snapshot(args.keys,args.extractor,args.output),indent=2))
    else:
        result=joined(args.pairs,args.evidence,args.manifest,args.extractor,args.scan_sources,args.scan_context)
        args.output.write_text(json.dumps(result,indent=2)+'\n'); print(json.dumps(result,indent=2))

if __name__=='__main__': main()
