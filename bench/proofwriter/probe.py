import json,sys,os,time
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
import run
x=json.loads(open(os.path.join(run.BASE,'sample.jsonl')).readline())
m,e=sys.argv[1],sys.argv[2]
r=run.call(x,m,e,tries=1)
msg=(r.get('error') or {}).get('errs',[{}])
print(m,e,'pred=',r['pred'],'lat=',r['latency'],'usage=',r['usage'],'tools=',r.get('tool_items'),'err=',json.dumps(msg)[:300] if 'error' in r else None)
