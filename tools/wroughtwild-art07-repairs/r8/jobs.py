"""Prepare R8-only evidence derivatives and bounded sequential job groups.

Every reused source assertion stays intact. R4 terminal cleanup is inherited
from the composed source; only output routing changes in fixture derivatives.
"""
import argparse,hashlib,json,shutil
from pathlib import Path
from inspect_inputs import ROOT,read,sha
from compose import write

def main(version):
    out=ROOT/'build/art07-repairs/r8'/version;game=out/'runtime/game';engine=out/'runtime/engine/Godot_v4.5-stable_win64.exe'
    proof=[]
    def scene(script,node='Node'):
        return '[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://'+script+'" id="1"]\n[node name="R8Fixture" type="'+node+'"]\nscript=ExtResource("1")\n'
    def derivative(source,target,changes=()):
        original=(game/(source+'.gd')).read_text(encoding='utf-8-sig');s=original;used=[]
        for a,b in changes:
            if a in s:s=s.replace(a,b);used.append((a,b))
        inv=s
        for a,b in reversed(used):inv=inv.replace(b,a)
        assert inv==original,(source,'assertions/logic must be restored exactly by inverse substitutions')
        write(game/(target+'.gd'),s)
        write(game/(target+'.tscn'),(game/(source+'.tscn')).read_text(encoding='utf-8-sig').replace('res://'+source+'.gd','res://'+target+'.gd'))
        proof.append({'source':source+'.gd','source_sha256':sha(game/(source+'.gd')),'target':target+'.gd','substitutions':used,'inverse_exact':True})
        return target+'.tscn'
    def job(ident,sc,flags=(),renderer=None,state=None,fixed=False,script=False):
        args=['--rendering-method',renderer] if renderer else ['--headless']
        if fixed or not renderer:args+=['--fixed-fps','60']
        args+=['--path',str(game)]+(['--script'] if script else [])+['res://'+sc,'--',*flags,'--r8-no-mouse-capture']
        return {'id':ident,'program':str(engine),'arguments':args,'log':str(out/'logs'/(ident+'.log')),'state':str(out/'users'/(state or ident))}
    cleanup=[];native=[];core=[];visual=[];cost=[]
    ids=['b3','c1','c2','c3','c4','e1','f2','f3']
    for backend in ['forward_plus','gl_compatibility']:
        for ident in ids:
            source=ident+('/native_review' if ident in ids[:5] else '/review')
            target='r8/replays/'+backend+'/'+ident
            prefix='res://../evidence/r8-replays/'+backend+'/'+ident+'/'
            sc=derivative(source,target,[('res://../evidence/',prefix),('res://'+ident+'/evidence',prefix.rstrip('/'))])
            cases=[('flow',['--check'] if ident in ['e1','f2'] else [])]
            cases+= [('partial',['--restore-partial']),('final',['--restore-final'])] if ident in ids[:5] else [('restart',['--restore' if ident=='e1' else '--restart'])]
            if ident=='f3':cases.append(('depleted',['--restart-depleted']))
            for label,flags in cases:cleanup.append(job('cleanup-'+ident+'-'+label+'-'+backend,sc,flags,backend,state='cleanup-'+ident+'-'+backend,fixed=True))
        for ident in ['b1','c4']:
            sc=derivative('r1/'+ident+'_native','r8/replays/'+backend+'/r1-'+ident,[('res://../evidence/','res://../evidence/r8-r1/'+backend+'/')])
            for label,flags in [('flow',[]),('partial',['--restore-partial']),('final',['--restore-final'])]:
                native.append(job('canopy-'+ident+'-'+label+'-'+backend,sc,flags,backend,state='canopy-'+ident+'-'+backend,fixed=True))
        for mode in ['art','baseline']:
            flags=[] if mode=='art' else ['--baseline']
            sc='r8/paid.tscn'
            core.append(job('paid-'+mode+'-'+backend,sc,flags+['--run-id=r8-'+mode+'-'+backend],backend,state='paid-'+mode+'-'+backend,fixed=True))
            core.append(job('paid-restart-'+mode+'-'+backend,sc,flags+['--restart','--run-id=r8-'+mode+'-'+backend+'-restart'],backend,state='paid-'+mode+'-'+backend,fixed=True))
            directory=out/'evidence'/('probe-'+mode+'-'+backend);directory.mkdir(parents=True,exist_ok=False)
            core.append(job('probe-'+mode+'-'+backend,'r6/probe.tscn',flags+['--output='+str(directory)],backend,fixed=True))
        core.append(job('catalogue-'+backend,'r1/catalogue.tscn',renderer=backend))
        core.append(job('actors-'+backend,'r8/fauna.tscn',renderer=backend))
        core.append(job('grounding-'+backend,'r7/grounding.tscn',renderer=backend))
        core.append(job('mesh-envelope-'+backend,'r7/mesh_checks.tscn',renderer=backend))
        for phase,flags in [('flow',['--capture']),('fractional',['--capture','--restore']),('exhausted',['--capture','--restore-exhausted'])]:
            sc=derivative('f4/review','r8/replays/'+backend+'/f4-'+phase,[('res://../evidence/','res://../evidence/r8-f4/'+backend+'/'+phase+'/')])
            native.append(job('f4-'+phase+'-'+backend,sc,flags,backend,state='f4-'+backend,fixed=True))
        for phase,flags in [('flow',[]),('restart',['--r2-restart'])]:
            native.append(job('reload-'+phase+'-'+backend,'r2/reloads.tscn',flags,backend,state='reload-'+backend,fixed=True))
        for phase,flags in [('flow',['--capture']),('restore',['--restore'])]:
            directory=out/'evidence'/('chest-'+phase+'-'+backend);directory.mkdir(parents=True,exist_ok=False)
            native.append(job('chest-'+phase+'-'+backend,'r5/review.tscn',flags+['--out='+str(directory)],backend,state='chest-'+backend,fixed=True))
        for phase in ['flow','restart']:
            directory=out/'evidence'/('ore-'+phase+'-'+backend);directory.mkdir(parents=True,exist_ok=False)
            flags=['--output='+str(directory)]
            if phase=='restart':flags+=['--restart-dir='+str(out/'evidence'/('ore-flow-'+backend))]
            native.append(job('ore-'+phase+'-'+backend,'r6/review.tscn',flags,backend,fixed=True))
        for mode,flags in [('combined',[]),('g1',['--r1-before','--r3-baseline','--r7-before','--r6-before'])]:
            visual.append(job('building-'+mode+'-'+backend,'r3/inspection.tscn',flags+['--run-id=r8-'+mode],backend))
        # Original R2 full-kit cameras, fixed IDs/settings and snapshots.
        visual.append(job('full-kit-'+backend,'r2/benchmark.tscn',['--run-id=r8-full-kit'],backend))
        visual.append(job('habitat-'+backend,'r7/views.tscn',renderer=backend))
        visual.append(job('walk-'+backend,'r7/route.tscn',['--capture','--run-id=r8-walk-'+backend],backend))
        for n in range(1,4):
            for mode in ['art','baseline']:
                ident=f'benchmark-{mode}-{backend}-{n:02d}'
                flags=['--benchmark','--run-id=r8-'+ident]+(['--baseline'] if mode=='baseline' else [])
                cost.append(job(ident,'r2/benchmark.tscn',flags,backend))
    derivative('r7/paid','r8/paid',[('res://r7/replayed-paid-home.json','user://r8-replayed-paid-home.json')])
    # The exact G2 16-actor inspector, with only output/entry paths changed.
    s=(ROOT/'tools/wroughtwild-art07/g2/fauna.gd').read_text(encoding='utf-8-sig');s=s.replace('res://g2/fauna.json','res://r8/fauna.json').replace('g2-fauna-','r8-fauna-')
    write(game/'r8/fauna.gd',s);write(game/'r8/fauna.tscn',scene('r8/fauna.gd','Node3D'))
    write(game/'r8/fauna.json',read(ROOT/'docs/art/concepts/environment/2026-09-09-frontier/asset-catalogue.json')['fauna_presentation'])
    core.insert(0,job('unit','tests/run_tests.gd',script=True))
    core.insert(1,job('ecology','r7/ecology.tscn'))
    core.insert(2,job('projection-equivalence','r2/projection_checks.tscn'))
    for name,jobs in [('cleanup',cleanup),('native',native),('core',core),('visual',visual),('benchmark',cost)]:
        write(out/('jobs-'+name+'-01.json'),jobs);print('R8_JOBS',name,len(jobs))
    write(out/'replay-assertion-preservation.json',proof)
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--version',default='v01');main(p.parse_args().version)
