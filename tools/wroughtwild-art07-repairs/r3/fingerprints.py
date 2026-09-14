"""Compare all persistent paid-home fields, retaining native identity and amounts."""
import argparse,copy,hashlib,json
from pathlib import Path

def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def canonical(snapshot):
    result=copy.deepcopy(snapshot)
    for name in ['sim','contraptions','leylines']:result[name]=json.loads(result[name])
    result['resource_nodes'].sort(key=lambda row:row['resource_id'])
    for row in result['stations']:row.pop('name')
    result['stations'].sort(key=lambda row:row['station_key'])
    return result

def digest(obj):return hashlib.sha256(json.dumps(obj,sort_keys=True,separators=(',',':')).encode()).hexdigest()
def compare(a,b,stage_a,stage_b):
    x,y=canonical(a[stage_a]),canonical(b[stage_b])
    assert x==y,[(key,x[key],y[key]) for key in x if x[key]!=y[key]]
    return {'sha256':digest(x),'fields':{key:digest(x[key]) for key in x}}

p=argparse.ArgumentParser();p.add_argument('baseline',type=Path);p.add_argument('candidate',type=Path);p.add_argument('--restart',action='store_true');p.add_argument('--output',required=True,type=Path);a=p.parse_args()
b,c=read(a.baseline),read(a.candidate)
assert b['failures']==c['failures']==0 and b['geography_sha256']==c['geography_sha256']
result={'baseline':str(a.baseline.resolve()),'candidate':str(a.candidate.resolve()),'geography_sha256':b['geography_sha256'],'canonicalization':'Parse native JSON and sort resource/station records; omit only auto-generated station scene-node name. All persistent identities, addresses, quantities, work, progression and positions remain exact.','stages':{}}
for before,after in [('final','initial')] if a.restart else [('initial','initial'),('final','final')]:
    result['stages'][before+'->'+after]=compare(b,c,before,after)
with a.output.open('x') as f:json.dump(result,f,indent=2)
print('R3_PAID_FINGERPRINTS_MATCH',list(result['stages']))
