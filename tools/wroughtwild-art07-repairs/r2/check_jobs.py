"""R2-specific native and rendered replay jobs. Existing assertions are retained."""
import argparse
from measure import BUILD, read, write

def main(version):
    base=BUILD/version;runtime=base/'runtime';game=runtime/'game';engine=runtime/'engine/Godot_v4.5-stable_win64.exe'
    def job(ident,scene,flags=(),renderer=None,state=None,script=False):
        native_id='paid' if scene=='g1/paid.tscn' else scene.split('/')[-1].removesuffix('.tscn')
        native_scene='r2/native_'+native_id+'.tscn'
        native_wrapped=(scene=='g1/paid.tscn' or scene.startswith('tests/living_frontier_')) and (game/native_scene).is_file()
        if native_wrapped:scene=native_scene;renderer=renderer or 'forward_plus'
        replay='r2/replay_'+scene.split('/')[0]+'.tscn'
        if scene.endswith('/review.tscn') or scene.endswith('/native_review.tscn'):
            if (game/replay).is_file():scene=replay
        args=(['--rendering-method',renderer] if renderer else ['--headless','--fixed-fps','60'])+['--path',str(game)]
        if native_wrapped or scene=='r2/reloads.tscn':args[2:2]=['--fixed-fps','60']
        if script:args+=['--script']
        args+=['res://'+scene]
        if flags:args+=['--',*flags]
        return {'id':ident,'program':str(engine),'arguments':args,'log':str(base/'logs'/(ident+'.log')),'state':str(base/'users'/(state or ident))}
    native=[job('unit','tests/run_tests.gd',script=True),job('probe-art','g1/probe.tscn'),job('probe-baseline','g1/probe.tscn',['--baseline'])]
    for ident in ['b1','b3','c1','c2','c3','c4','c5']:
        native.append(job(ident+'-flow',ident+'/native_review.tscn',state=ident))
        source=(game/ident/'native_review.gd').read_text()
        for flag in ['--restore-partial','--restore-final']:
            if flag in source:native.append(job(ident+flag,ident+'/native_review.tscn',[flag],state=ident))
    for ident in ['e1','e2','e3']:
        native += [job(ident+'-flow',ident+'/review.tscn',['--check'] if ident!='e3' else [],state=ident),job(ident+'-restore',ident+'/review.tscn',['--restore'],state=ident)]
    for ident in ['f1','f2','f3']:
        native += [job(ident+'-flow',ident+'/review.tscn',['--check'] if ident=='f2' else [],state=ident),job(ident+'-restart',ident+'/review.tscn',['--restart'],state=ident)]
    native += [job('projection-equivalence','r2/projection_checks.tscn')]
    for renderer in ['forward_plus','gl_compatibility']:
        native += [job('reload-release-'+renderer,'r2/reloads.tscn',renderer=renderer,state='reloads-'+renderer),job('reload-restart-'+renderer,'r2/reloads.tscn',['--r2-restart'],renderer=renderer,state='reloads-'+renderer)]
    native += [job('paid-art','g1/paid.tscn',['--run-id=r2-art'],state='paid-art'),job('paid-art-restart','g1/paid.tscn',['--restart','--run-id=r2-art-restart'],state='paid-art'),job('paid-baseline','g1/paid.tscn',['--baseline','--run-id=r2-baseline'],state='paid-baseline')]
    # These original continuations require the actual preceding paid save, all
    # in one private state tree. Never fabricate their migration checkpoints.
    for ident,flags in [('living_frontier_flow',[]),('living_frontier_flow',['--lf-restore']),('living_frontier_wave2_flow',['--lf2-bootstrap']),('living_frontier_wave2_flow',['--lf2-restore']),('living_frontier_green_flow',[]),('living_frontier_green_flow',['--green-restore']),('living_frontier_heat_flow',[]),('living_frontier_heat_flow',['--heat-restore'])]:
        suffix='-restore' if any('restore' in flag for flag in flags) else '-flow'
        native.append(job(ident+suffix,'tests/'+ident+'.tscn',flags,state='lf-colours'))
    write(base/'native-jobs.json',native)
    rendered=[]
    for renderer in ['forward_plus','gl_compatibility']:
        rendered += [job('catalogue-'+renderer,'g1/catalogue.tscn',renderer=renderer),job('f4-'+renderer,'f4/review.tscn',['--capture'],renderer,state='f4-'+renderer),job('f4-restore-'+renderer,'f4/review.tscn',['--capture','--restore'],renderer,state='f4-'+renderer),job('f4-exhausted-'+renderer,'f4/review.tscn',['--capture','--restore-exhausted'],renderer,state='f4-'+renderer)]
    rendered.append(job('walk-motion','g1/walk_review.tscn',['--capture','--run-id=r2-walk'],'forward_plus'))
    write(base/'render-jobs.json',rendered)
    # The three candidate art-on processes pair against the common art-off and G1
    # groups; this candidate never changes the original baseline controls.
    benchmarks=[]
    for n in range(1,4):
        for renderer in ['forward_plus','gl_compatibility']:
            ident=f'benchmark-art-{renderer}-{n:02d}'
            benchmarks.append(job(ident,'r2/benchmark.tscn',['--benchmark','--run-id='+ident],renderer))
    write(base/'benchmark-jobs.json',benchmarks)
    print('R2_CHECK_JOBS',len(native),len(rendered),len(benchmarks))

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--version',required=True);a=p.parse_args();main(a.version)
