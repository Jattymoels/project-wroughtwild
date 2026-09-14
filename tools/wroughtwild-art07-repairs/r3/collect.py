"""Index actual runner results, required native gates and matched benchmark costs."""
import argparse,hashlib,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):
    with p.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
p=argparse.ArgumentParser();p.add_argument('--version',default='v01');a=p.parse_args();out=ROOT/'build/art07-repairs/r3'/a.version
logs={}
for path in sorted((out/'logs').glob('*.log.json')):
    row=read(path);log=Path(str(path)[:-5]);assert sha(log)==row['log_sha256'],log
    row['receipt']=str(path.resolve());logs[row['id']]=row
required=['import','smoke-forward_plus','smoke-gl_compatibility','pass04-import','packed-source-reopen-01']
for renderer in ['forward_plus','gl_compatibility']:
    required += [f'pass02-{tag}-{renderer}' for tag in ['g1','r3']]
    required += [f'pass01-catalogue-{renderer}',f'pass01-transactions-{renderer}',f'pass01-transactions-restore-{renderer}']
    for tag in ['g1','r3']:
        required += [f'pass02-paid-{tag}-{renderer}']
        required += ['pass03-restore-g1-forward_plus' if tag=='g1' and renderer=='forward_plus' else f'pass02-restore-{tag}-{renderer}']
        for scene in ['inspection','home']:required += [f'bench01-benchmark-{scene}-{tag}-{renderer}']
for key in required:
    assert key in logs,('missing real run',key)
    row=logs[key];assert row['exit_code']==0 and not row['failure'],(key,row['failure'])
    assert not row.get('processes_before') and not row.get('benchmark_competitors'),key
raw=out/'runtime/evidence';catalogues=[]
for renderer in ['forward_plus','gl_compatibility']:
    path=raw/f'catalogue-{renderer}/checks.json';d=read(path)
    assert d['failures']==0 and d['checks']==1861 and len(d['pairs'])==273
    catalogues.append({'renderer':renderer,'checks':d['checks'],'pairs':len(d['pairs']),'sha256':sha(path),'source':str(path.resolve())})
benchmarks=[]
for renderer in ['forward_plus','gl_compatibility']:
    for scene in ['inspection','home']:
        reports=[]
        for tag,kind in [('g1','g1'),('r3','candidate')]:
            lead='r3-home-' if scene=='home' else 'r3-'
            path=raw/(lead+f'bench01-benchmark-{scene}-{tag}-{renderer}-{kind}-{renderer}')/'report.json'
            data=read(path);assert data['failures']==0
            expected=6 if scene=='home' else 33
            assert len(data['samples'])==expected and all(r['samples']==300 for r in data['samples'])
            reports.append((path,data))
        before,after=[d for _,d in reports]
        assert before['views']==after['views'] and before['gpu']==after['gpu']
        if scene=='inspection':assert before['geometry']==after['geometry']
        else:assert before['geography_sha256']==after['geography_sha256']
        rows=[]
        for b,c in zip(before['samples'],after['samples']):
            assert (b['view'],b['light'])==(c['view'],c['light'])
            rows.append({'view':b['view'],'light':b['light'],'samples_each':300,'baseline':b,'candidate':c})
        image_before=before['material_bindings']['images'];image_after=after['material_bindings']['images']
        benchmarks.append({'scene':scene,'renderer':renderer,'gpu':before['gpu'],'baseline_report':str(reports[0][0].resolve()),'candidate_report':str(reports[1][0].resolve()),'newly_bound_original_images':sorted(set(image_after)-set(image_before)),'no_longer_bound_original_images':sorted(set(image_before)-set(image_after)),'before_material_bindings':before['material_bindings'],'after_material_bindings':after['material_bindings'],'samples':rows,'scope':'Paired warmed views. Source geometry is unchanged; rendered primitive and draw counters include backend pass/culling behavior. Zero GPU timing values indicate unavailable backend telemetry, not zero cost.'})
result={'required_passed_runs':required,'catalogues':catalogues,'all_recorded_runner_results':logs,'benchmark_comparisons':benchmarks,'authored_textures_added':0,'authored_textures_removed':0,'authored_geometry_replaced':0,'hardware':read(out/'hardware.json'),'owner_visual_acceptance':'pending','ordinary_world_rollout':'outside scope'}
with (out/'checks-and-costs.json').open('x') as f:json.dump(result,f,indent=2)
print('R3_RUN_INDEX',len(required),'required passes;',len(logs),'total retained runs;',len(benchmarks),'paired benchmark groups')
