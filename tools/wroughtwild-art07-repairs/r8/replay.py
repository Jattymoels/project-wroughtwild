"""Rebase a recorded R8 job group onto a fresh verified R8 test copy."""
import argparse,json
from pathlib import Path
from inspect_inputs import ROOT,read
from compose import write
p=argparse.ArgumentParser();p.add_argument('--package',type=Path,required=True);p.add_argument('--target',type=Path,required=True);p.add_argument('--spec',required=True);p.add_argument('--tag',required=True);a=p.parse_args()
target=a.target.resolve();assert target.is_relative_to((ROOT/'build/art07-repairs/r8').resolve()) and target.name!='runtime'
assert (target/'runtime/game/override.cfg').is_file(),'Use handoff apply/clone --tests first'
source=read(a.package/'records'/a.spec);old=(ROOT/'build/art07-repairs/r8/v01').resolve();mapped=[]
def remap(value):
    return value.replace(str(old),str(target)).replace(old.as_posix(),target.as_posix())
for j in source:
    row={'id':j['id']+'-'+a.tag,'program':remap(j['program']),'arguments':[remap(v) for v in j['arguments']],'log':str(target/'logs'/(j['id']+'-'+a.tag+'.log')),'state':remap(j['state'])}
    assert not Path(row['log']).exists()
    for arg in row['arguments']:
        if arg.startswith(('--output=','--out=','--checkpoint-dir=')):
            directory=Path(arg.split('=',1)[1]).resolve();assert directory.is_relative_to(target);directory.mkdir(parents=True,exist_ok=True)
    mapped.append(row)
for renderer in ['forward_plus','gl_compatibility']:
    for ident in ['b3','c1','c2','c3','c4','e1','f2','f3']:(target/'runtime/evidence/r8-replays'/renderer/ident).mkdir(parents=True,exist_ok=True)
write(target/('replay-'+a.tag+'.json'),mapped)
print('R8_REPLAY_SPEC',str(target/('replay-'+a.tag+'.json')),len(mapped))
