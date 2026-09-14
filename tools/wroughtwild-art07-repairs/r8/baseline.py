"""Identical R2 measurement harness on a fresh pinned G1 comparison runtime."""
import json,shutil
from pathlib import Path
from inspect_inputs import ROOT,read,sha
from compose import write
out=ROOT/'build/art07-repairs/r8/v02';candidate=ROOT/'build/art07-repairs/r8/v01/runtime/game';game=out/'runtime/game'
original=read(out/'prepared.json')['original_files']
for n,r in original.items():assert sha(out/'runtime'/n)==r['sha256'],n
for n in ['r2/benchmark.gd','r2/benchmark.tscn','r2/profile.gd','r8/comfort.gd']:
    p=game/n;p.parent.mkdir(parents=True,exist_ok=True);assert not p.exists();shutil.copy2(candidate/n,p)
# The same explicit test flag and startup override are used in both measured copies.
p=game/'scripts/player.gd';s=p.read_bytes();old=b'\t\tInput.mouse_mode = Input.MOUSE_MODE_CAPTURED';assert s.count(old)==1
p.write_bytes(s.replace(old,b'\t\tInput.mouse_mode = Input.MOUSE_MODE_VISIBLE if "--r8-no-mouse-capture" in OS.get_cmdline_user_args() else Input.MOUSE_MODE_CAPTURED'))
shutil.copy2(candidate/'override.cfg',game/'override.cfg')
jobs=read(out/'import-smoke.json')
for j in jobs:
    if '--' not in j['arguments']:j['arguments']+=['--']
    j['arguments']+=['--r8-no-mouse-capture']
write(out/'jobs-import-01.json',jobs)
bench=[];views=[]
for backend in ['forward_plus','gl_compatibility']:
    for n in range(1,4):
        for mode in ['art','baseline']:
            ident=f'original-benchmark-{mode}-{backend}-{n:02d}'
            args=['--rendering-method',backend,'--path',str(game),'res://r2/benchmark.tscn','--','--benchmark','--run-id='+ident,'--r8-no-mouse-capture']+(['--baseline'] if mode=='baseline' else [])
            bench.append({'id':ident,'program':str(out/'runtime/engine/Godot_v4.5-stable_win64.exe'),'arguments':args,'log':str(out/'logs'/(ident+'.log')),'state':str(out/'users'/ident)})
    ident='original-full-kit-'+backend
    views.append({'id':ident,'program':str(out/'runtime/engine/Godot_v4.5-stable_win64.exe'),'arguments':['--rendering-method',backend,'--path',str(game),'res://r2/benchmark.tscn','--','--run-id='+ident,'--r8-no-mouse-capture'],'log':str(out/'logs'/(ident+'.log')),'state':str(out/'users'/ident)})
write(out/'jobs-benchmark-01.json',bench);write(out/'jobs-visual-01.json',views)
write(out/'comparison-source-proof.json',{'original_files_verified':len(original),'production_changes':['game/scripts/player.gd: explicit test-only capture opt-out'],'added_inspection':['game/'+n for n in ['r2/benchmark.gd','r2/benchmark.tscn','r2/profile.gd','r8/comfort.gd','override.cfg']],'runtime_base':read(out/'prepared.json')['runtime_base'],'measurement_harness_matches_candidate':sha(game/'r2/benchmark.gd')==sha(candidate/'r2/benchmark.gd')})
print('R8_ORIGINAL_COMPARISON_PREPARED',len(bench),len(views))
