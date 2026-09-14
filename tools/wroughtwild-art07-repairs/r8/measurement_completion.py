"""Complete the exact R2 visual-inventory and uncaptured-traversal protocol."""
import shutil
from pathlib import Path
from inspect_inputs import ROOT,read,sha
from compose import write
build=ROOT/'build/art07-repairs/r8';candidate=build/'v01/runtime/game';original=build/'v02/runtime/game'
for name in ['views.gd','views.tscn','traversal.gd','traversal.tscn']:
    dst=original/'r2'/name;assert not dst.exists();shutil.copy2(candidate/'r2'/name,dst);assert sha(dst)==sha(candidate/'r2'/name)
proof=read(build/'v02/comparison-source-proof.json');proof['added_inspection'] += ['game/r2/'+n for n in ['views.gd','views.tscn','traversal.gd','traversal.tscn']]
write(build/'v02/comparison-source-proof-complete.json',proof)
for version in ['v01','v02']:
    out=build/version;source='jobs-visual-02.json' if version=='v01' else 'jobs-visual-01.json';jobs=read(out/source)
    for j in jobs:
        if 'full-kit' not in j['id']:continue
        j['arguments']=[a.replace('r2/benchmark.tscn','r2/views.tscn') for a in j['arguments']]
        if '--fixed-fps' not in j['arguments']:j['arguments']=['--fixed-fps','60',*j['arguments']]
    write(out/'jobs-visual-complete.json',jobs)
    traversal=[]
    for renderer in ['forward_plus','gl_compatibility']:
        for mode in (['art','baseline'] if version=='v02' else ['art']):
            ident=('original-' if version=='v02' else '')+'traversal-'+mode+'-'+renderer
            args=['--rendering-method',renderer,'--path',str(out/'runtime/game'),'res://r2/traversal.tscn','--','--benchmark','--run-id=r8-'+ident,'--r8-no-mouse-capture']+(['--baseline'] if mode=='baseline' else [])
            traversal.append({'id':ident,'program':str(out/'runtime/engine/Godot_v4.5-stable_win64.exe'),'arguments':args,'log':str(out/'logs'/(ident+'.log')),'state':str(out/'users'/ident)})
    write(out/'jobs-traversal-01.json',traversal)
print('R8_FULL_R2_PROTOCOL_PREPARED')
