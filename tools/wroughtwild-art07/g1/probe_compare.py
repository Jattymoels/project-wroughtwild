"""Compare fresh final-hook snapshots and deterministic generated geography."""
import copy
import hashlib
import json
import sys
from pathlib import Path


def canonical(s):
    s=copy.deepcopy(s)
    for key in ['sim','contraptions','leylines']:s[key]=json.loads(s[key])
    s['resource_nodes'].sort(key=lambda r:r['resource_id'])
    for row in s['stations']:row.pop('name')
    s['stations'].sort(key=lambda r:r['station_key'])
    return s


a,b,dest=map(Path,sys.argv[1:])
x,y=[json.loads(p.read_text()) for p in [a,b]]
assert x['failures']==y['failures']==0
assert x['geography_sha256']==y['geography_sha256']
xx,yy=canonical(x['snapshot']),canonical(y['snapshot'])
assert xx==yy,[key for key in xx if xx[key]!=yy[key]]
row={'geography_sha256':x['geography_sha256'],'snapshot_sha256':hashlib.sha256(json.dumps(xx,sort_keys=True,separators=(',',':')).encode()).hexdigest(),'art_checks':x['checks'],'baseline_checks':y['checks'],'scope':'Fresh final integration hooks; exact generated map and complete save snapshot. Only ephemeral auto-generated station scene names excluded, never station_key.'}
with dest.open('x') as f:json.dump(row,f,indent=2)
print('G1_FINAL_PROBES_MATCH',row['snapshot_sha256'])
