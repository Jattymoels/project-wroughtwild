"""Assert the concrete R8 acceptance matrix and summarize fresh receipts."""
import argparse,json,re
from pathlib import Path
from inspect_inputs import ROOT,read,sha
from compose import write
from job_index import collect

def main():
    build=ROOT/'build/art07-repairs/r8';out=build/'v01';all_jobs=collect();required=[]
    specs=['jobs-import-comfort-01.json','jobs-import-final-01.json','jobs-paid-traced-02.json','jobs-encoding-import.json','jobs-core-final.json','jobs-core-02.json','jobs-projection-clean-01.json','jobs-cleanup-01.json','jobs-native-01.json','jobs-extra-01.json','jobs-reopen-02.json','jobs-comfort-live-01.json','jobs-visual-complete.json','jobs-benchmark-01.json','jobs-traversal-01.json']
    # Retain the two unchanged initial headless gates, not the old diagnostic projection exit.
    required.extend(read(out/'jobs-core-01.json')[:2])
    for name in specs:required.extend(read(out/name))
    for name in ['jobs-import-01.json','jobs-visual-complete.json','jobs-benchmark-01.json','jobs-traversal-01.json']:required.extend(read(build/'v02'/name))
    replacements=read(out/'accepted-retries.json') if (out/'accepted-retries.json').exists() else {}
    for j in required:
        if j['id'] in replacements:j.update(replacements[j['id']])
        r=read(Path(j['log']+'.json'));assert not r['failure'] and r['exit_code']==0,(j['id'],r['failure']);assert sha(Path(j['log']))==r['log_sha256']
        assert not r['processes_before'] and not r['benchmark_competitors'],j['id']
        if j['id'].startswith('cleanup-'):
            s=Path(j['log']).read_text(encoding='utf-8-sig');assert 'R4_CLEANUP ' in s and not re.search(r'ObjectDB.*leak|Orphan.*leak',s)
            for line in s.splitlines():
                if line.startswith('R4_CLEANUP '):
                    d=json.loads(line[len('R4_CLEANUP '):]);assert d['children_after']==d['playbacks_after']==0
    for renderer in ['forward_plus','gl_compatibility']:
        for ident,marker in [('catalogue','1861 checks, 0 failures; 273 legal pairs'),('actors','50 checks, 0 failures'),('comfort-live','verified 120 rendered player frames')]:
            assert marker in (out/'logs'/(ident+'-'+renderer+'.log')).read_text(encoding='utf-8-sig'),(ident,renderer)
        assert read(out/'evidence'/('fingerprints-'+renderer+'.json'))['walk_metres']>100
    assert read(out/'evidence/fingerprints-forward_plus.json')['stages']==read(out/'evidence/fingerprints-gl_compatibility.json')['stages']
    a=read(out/'evidence/probes-forward_plus.json');b=read(out/'evidence/probes-gl_compatibility.json');assert a==b
    audit=read(out/'source-audit-final.json');assert audit['all_data_engine_native_bytes_unchanged'] and audit['f4_synchronous_restore_unchanged']
    assert len(read(out/'evidence/matched-visuals.json')['pairs'])==60
    assert len(read(ROOT/'docs/art/leyline-studies/2026-09-14/art07-repairs/r8/traversal-costs.json')['runs'])==6
    assert read(build/'v02/comparison-source-audit-final.json')['identical_measurement_harness']
    final_player=read(out/'evidence/final-player-checks.json');assert final_player['all_stages_and_geography_match_prior']
    costs=read(ROOT/'docs/art/leyline-studies/2026-09-14/art07-repairs/r8/costs.json')
    parent_lines=(out/'input-verification-after.txt').read_text(encoding='utf-8-sig')
    for ident in ['runtime_source','g2_review','r1','r2','r3','r4','r5','r6','r7']:assert 'REPAIR_FULL_INPUT_VERIFIED '+ident+' ' in parent_lines
    selected=read(out/'selected-source-hashes.json')
    for row in selected:assert sha(out/row['path'])==row['sha256'],row['path']
    required_ids={(str(Path(j['log']).resolve())) for j in required}
    final={'id':'r8','required_checks_complete':True,'required_fresh_jobs':len(required),'all_recorded_jobs':len(all_jobs),'required_receipts':[r for r in all_jobs if str(Path(r['log']).resolve()) in required_ids],'retained_other_attempts':[r for r in all_jobs if str(Path(r['log']).resolve()) not in required_ids],'geography':a,'input_hashes_before':'input-verification-full.txt','input_hashes_after':'input-verification-after.txt','source_audit':'source-audit-final.json','costs':'documentation/costs.json','owner_visual_acceptance':'pending','minimum_hardware':'unverified','ordinary_world_rollout':'outside scope','finding_closure':'Integration runtime gates only; raised ore/physical recess and continuous understorey remain explicitly unmet.'}
    write(out/'acceptance.json',final);print('R8_ACCEPTANCE',len(required),'required jobs pass')
if __name__=='__main__':main()
