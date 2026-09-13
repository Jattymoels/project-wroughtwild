"""Explicit G2 jobs replay sealed scenes unchanged with G2-only output/state."""
import json
from pathlib import Path
ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / 'build/art07/g2/v01'
GAME = OUT / 'review/game'
ENGINE = OUT / 'review/engine/Godot_v4.5-stable_win64.exe'

def job(ident, scene=None, flags=(), renderer=None, state='core', script=False, import_only=False):
    args = ['--path', str(GAME)]
    if import_only:
        args = ['--headless', '--editor', *args, '--import']
    else:
        args = (['--rendering-method', renderer] if renderer else ['--headless', '--fixed-fps', '60']) + args
        if script: args += ['--script']
        args += ['res://' + scene]
        if flags: args += ['--', *flags]
    return {'id': ident, 'program': str(ENGINE), 'arguments': args,
            'log': str(OUT / 'logs' / (ident+'.log')), 'state': str(OUT / 'users' / state)}

def save(name, jobs):
    with (OUT / (name+'.json')).open('x') as stream: json.dump(jobs, stream, indent=2)
    print(name, len(jobs))

core = [job('import', import_only=True),job('unit','tests/run_tests.gd',script=True),
        job('probe-art','g1/probe.tscn'),job('probe-baseline','g1/probe.tscn',['--baseline']),
        job('placement','tests/placement_transactions.tscn'),
        job('placement-restart','tests/placement_transactions.tscn',['--placement-restore-only']),
        job('local-scenery','tests/placement_scenery.tscn'),job('home','tests/home_workshop_review.tscn'),
        job('paid-art','g1/paid.tscn',['--run-id=g2-art']),
        job('paid-art-restart','g1/paid.tscn',['--restart','--run-id=g2-art-restart']),
        job('paid-baseline','g1/paid.tscn',['--baseline','--run-id=g2-baseline']),
        job('save-recovery','tests/save_recovery.tscn')]
save('core-jobs',core)
native=[]
for ident in ['b1','b3','c1','c2','c3','c4','c5']:
    native += [job(ident,ident+'/native_review.tscn')]
    if ident.startswith('c'): native += [job(ident+'-partial',ident+'/native_review.tscn',['--restore-partial'])]
for ident in ['e1','e2','e3']:
    native += [job(ident,ident+'/review.tscn',['--check'] if ident!='e3' else []),
               job(ident+'-restart',ident+'/review.tscn',['--restore'])]
for ident in ['f1','f2','f3']:
    native += [job(ident,ident+'/review.tscn',['--check'] if ident=='f2' else []),
               job(ident+'-restart',ident+'/review.tscn',['--restart'])]
for ident in ['d1','d2']:
    native += [job(ident,'art07_'+ident+'/checks.tscn',renderer='gl_compatibility'), job(ident+'-restart','art07_'+ident+'/checks.tscn',['--'+ident+'-restore'],renderer='gl_compatibility')]
save('native-jobs',native)
render=[]
for renderer in ['forward_plus','gl_compatibility']:
    suffix='-'+renderer
    render += [job('smoke'+suffix,'g1/play.tscn',['--smoke'],renderer,state='render'+suffix),
               job('catalogue'+suffix,'g1/catalogue.tscn',renderer=renderer,state='render'+suffix),
               job('f4'+suffix,'f4/review.tscn',['--capture'],renderer,state='render'+suffix),
               job('f4-restart'+suffix,'f4/review.tscn',['--capture','--restore'],renderer,state='render'+suffix),
               job('f4-exhausted'+suffix,'f4/review.tscn',['--capture','--restore-exhausted'],renderer,state='render'+suffix),
               job('views'+suffix,'g1/review.tscn',renderer=renderer,state='render'+suffix)]
render += [job('d3','art07_d3/checks.tscn',renderer='gl_compatibility'),
           job('d3-restart','art07_d3/checks.tscn',['--d3-restore'],renderer='gl_compatibility'),
           job('walk','g1/walk_review.tscn',['--capture','--run-id=g2-walk'],renderer='forward_plus')]
save('render-jobs',render)
benchmark=[]
for renderer in ['forward_plus','gl_compatibility']:
    for mode in ['art','baseline']:
        benchmark += [job('benchmark-'+mode+'-'+renderer,'g1/review.tscn',['--benchmark']+(['--baseline'] if mode=='baseline' else []),renderer,state='benchmark-'+mode+'-'+renderer)]
save('benchmark-jobs',benchmark)
blender=[{'id':'blender-reopen','program':'C:/Users/Matty/Dev/project-wroughtwild/build/blender-tool/blender-4.5.9-windows-x64/blender.exe',
          'arguments':['--background','--threads','8','--python-exit-code','1','--python',str(OUT/'sealed/recipes/g1/reopen.py'),'--',str(OUT/'sealed/masters'),str(GAME),str(OUT/'blender')],
          'log':str(OUT/'logs/blender-reopen.log'),'state':str(OUT/'users/blender')}]
save('blender-jobs',blender)
