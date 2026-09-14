"""Prepare and audit the fresh v03 reconstruction of the immutable R8 package."""
import argparse
from pathlib import Path
from inspect_inputs import ROOT,read,sha
from compose import write
p=argparse.ArgumentParser();p.add_argument('action',choices=['jobs','audit']);a=p.parse_args()
build=ROOT/'build/art07-repairs/r8';out=build/'v03';source=build/'v01';package=read(source/'sealed-package.json');seal=Path(package['path'])
if a.action=='jobs':
    assert read(out/'r8-applied.json')['all_bytes_match']
    selected=read(source/'jobs-import-comfort-01.json')
    selected += [j for j in read(source/'jobs-native-01.json') if j['id'].startswith('f4-')]
    selected += [j for j in read(source/'jobs-core-01.json') if j['id'].startswith('probe-art-')]
    jobs=[]
    def remap(s):return s.replace(str(source),str(out)).replace(source.as_posix(),out.as_posix())
    for j in selected:
        row={'id':'sealed-'+j['id'],'program':remap(j['program']),'arguments':[remap(s) for s in j['arguments']],'log':str(out/'logs'/('sealed-'+j['id']+'.log')),'state':remap(j['state'])}
        assert not Path(row['log']).exists()
        for arg in row['arguments']:
            if arg.startswith(('--output=','--out=','--checkpoint-dir=')):
                dest=Path(arg.split('=',1)[1]).resolve();assert dest.is_relative_to(out.resolve());dest.mkdir(parents=True,exist_ok=True)
        jobs.append(row)
    write(out/'jobs-sealed.json',jobs);print('R8_POSTSEAL_JOBS',len(jobs))
else:
    checks=[]
    for j in read(out/'jobs-sealed.json'):
        r=read(Path(j['log']+'.json'));assert r['exit_code']==0 and not r['failure'] and not r['processes_before'] and not r['benchmark_competitors'],j['id'];assert sha(Path(j['log']))==r['log_sha256']
        checks.append({**r,'log':j['log']})
    final=read(seal/'runtime-files.json')
    for n,r in final.items():assert sha(out/'runtime'/n)==r['sha256'],n
    extra=[p.relative_to(out/'runtime').as_posix() for p in (out/'runtime').rglob('*') if p.is_file() and p.relative_to(out/'runtime').as_posix() not in final and '.godot' not in p.parts and 'evidence' not in p.parts]
    assert extra==['game/override.cfg'],extra
    for renderer in ['forward_plus','gl_compatibility']:
        probe=read(out/'evidence'/('probe-art-'+renderer)/'probe.json');assert probe['checks']==10 and probe['failures']==0
        assert probe['geography_sha256']==read(source/'evidence'/('probes-'+renderer+'.json'))['geography_sha256']
    proof={'package':package,'application':read(out/'r8-applied.json'),'all_runtime_bytes_match':True,'runtime_entries_verified':len(final),'all_jobs_passed':True,'checks':checks,'generated_additions_outside_runtime_map':extra,'scope':'Fresh baseline prepared and every original hash checked; sealed composite applied with every final hash checked; guarded fresh import, both paid-home launches, both native F4 work/pause/block/fractional/exhausted flows and both final-hook probes passed. Source hashes remain equal after import and testing; generated cache/evidence stays only in this test copy.'}
    write(out/'post-seal.json',proof);print('R8_POSTSEAL_VERIFIED',len(checks),len(final))
