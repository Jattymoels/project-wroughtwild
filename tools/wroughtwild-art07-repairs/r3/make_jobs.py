"""Create fresh guarded engine job specs. Run only through the shared R runner."""
import argparse,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
p=argparse.ArgumentParser();p.add_argument('batch');p.add_argument('--version',default='v01');p.add_argument('--prefix',required=True);a=p.parse_args()
out=ROOT/'build/art07-repairs/r3'/a.version
runtime=out/'runtime'; game=runtime/'game'; engine=runtime/'engine/Godot_v4.5-stable_win64.exe'
jobs=[]
def job(ident,scene=None,renderer='forward_plus',flags=(),state=None,import_only=False):
    ident=a.prefix+'-'+ident
    args=['--headless','--editor','--path',str(game),'--import'] if import_only else ['--rendering-method',renderer,'--path',str(game),'res://'+scene,'--',*flags,'--run-id='+ident]
    jobs.append({'id':ident,'program':str(engine),'arguments':args,'log':str(out/'logs'/(ident+'.log')),'state':str(out/'users'/(state or ident))})
if a.batch=='import':job('import',import_only=True)
if a.batch=='catalogue':
    for r in ['forward_plus','gl_compatibility']:job('catalogue-'+r,'g1/catalogue.tscn',r)
if a.batch=='inspection':
    for r in ['forward_plus','gl_compatibility']:
        for baseline in [True,False]:job(('g1-' if baseline else 'r3-')+r,'r3/inspection.tscn',r,['--r3-baseline'] if baseline else [])
if a.batch=='paid':
    for r in ['forward_plus','gl_compatibility']:
        for baseline in [True,False]:
            tag=('g1-' if baseline else 'r3-')+r;state=a.prefix+'-paid-'+tag
            flags=['--r3-baseline'] if baseline else []
            job('paid-'+tag,'r3/home.tscn',r,flags,state)
            job('restore-'+tag,'r3/home.tscn',r,[*flags,'--r3-restore'],state)
if a.batch=='transactions':
    for r in ['forward_plus','gl_compatibility']:
        state=a.prefix+'-transactions-'+r
        job('transactions-'+r,'tests/placement_transactions.tscn',r,state=state)
        job('transactions-restore-'+r,'tests/placement_transactions.tscn',r,['--placement-restore-only'],state)
if a.batch=='benchmark':
    for r in ['forward_plus','gl_compatibility']:
        for scene in ['inspection','home']:
            for baseline in [True,False]:
                job('benchmark-'+scene+('-g1-' if baseline else '-r3-')+r,'r3/'+scene+'.tscn',r,['--benchmark']+(['--r3-baseline'] if baseline else []))
assert jobs,a.batch
path=out/(a.prefix+'-'+a.batch+'.json')
with path.open('x',encoding='utf-8') as f:json.dump(jobs,f,indent=2)
print(path,len(jobs))
