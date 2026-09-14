"""Verify protected runtime bytes and exact R3/G1 comparison evidence."""
import argparse,hashlib,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):
    with p.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def runtime(out):
    original=read(out/'prepared.json')['original_files'];changes=read(out/'changes.json')['files']
    declared={r['path']:r for r in changes};root=out/'runtime';changed=[]
    for name,row in original.items():
        current=sha(root/name)
        if current!=row['sha256']:
            assert name in declared,('undeclared runtime change',name)
            assert current==declared[name]['after_sha256'],('stale delta',name)
            changed.append(name)
    assert set(changed)=={'game/g1/art.gd','game/g1/materials.gd','game/scripts/piece_look.gd'},changed
    for name,row in declared.items():assert sha(root/name)==row['after_sha256'],name
    assert sha(root/'game/bin/libwroughtwild_sim.windows.x86_64.dll')=='0e7c4956b6c870f5879e78f54c5830509b7ae37913055543cc3a6d451298e0e1'
    config=read(root/'data/tuning/construction.json')
    assert len(config['shapes'])==26 and len(config['materials'])==19
    proof={'original_entries':len(original),'changed_original_entries':changed,'new_runtime_files':len(declared)-len(changed),'unchanged_native_dll':True,'unchanged_authored_PNG_GLB_and_checkpoint':True,'shapes':26,'families':19}
    (out/'runtime-preservation.json').write_text(json.dumps(proof,indent=2)+'\n')
    print('R3_RUNTIME_PRESERVED',len(original),len(changed))
def compare(paths):
    baseline,candidate=map(read,paths)
    for r in [baseline,candidate]:assert r['failures']==0
    assert baseline['renderer']==candidate['renderer'] and baseline['gpu']==candidate['gpu']
    assert baseline['views']==candidate['views']
    if 'geometry' in baseline:assert baseline['geometry']==candidate['geometry'],'changed geometry/native placement'
    if 'geography_sha256' in baseline:assert baseline['geography_sha256']==candidate['geography_sha256'],'geography'
    results={'baseline':str(paths[0].resolve()),'candidate':str(paths[1].resolve()),'renderer':baseline['renderer'],'gpu':baseline['gpu'],'matching_cameras':True,'matching_geometry':('geometry' in baseline),'matching_geography':('geography_sha256' in baseline),'cost_before':baseline['cost'],'cost_after':candidate['cost']}
    if baseline['samples']:
        assert len(baseline['samples'])==len(candidate['samples'])
        rows=[]
        for b,c in zip(baseline['samples'],candidate['samples']):
            for key in ['view','light','samples']:assert b[key]==c[key]
            assert b['samples']==300
            rows.append({'view':b['view'],'light':b['light'],'baseline_median_ms':b['median_ms'],'candidate_median_ms':c['median_ms'],'baseline_p95_ms':b['p95_ms'],'candidate_p95_ms':c['p95_ms'],'before_cost':b['cost'],'after_cost':c['cost']})
        results['timing_comparison']=rows
    return results
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--version',default='v01');p.add_argument('--compare',nargs=2,type=Path);p.add_argument('--output',type=Path);a=p.parse_args()
    if a.compare:
        result=compare(a.compare);assert a.output and not a.output.exists()
        a.output.write_text(json.dumps(result,indent=2)+'\n');print('R3_MATCHED_EVIDENCE',result['renderer'])
    else:runtime(ROOT/'build/art07-repairs/r3'/a.version)
