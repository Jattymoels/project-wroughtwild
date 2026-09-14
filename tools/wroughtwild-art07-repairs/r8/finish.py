"""Preserve inherited test checkpoints and seal post-reconstruction evidence without changing runtime bytes."""
import argparse,shutil
from pathlib import Path
from inspect_inputs import ROOT,read,sha
from compose import write
from handoff import verify,copy,rows
build=ROOT/'build/art07-repairs/r8';out=build/'v01';tested=build/'v03';doc=ROOT/'docs/art/leyline-studies/2026-09-14/art07-repairs/r8'
p=argparse.ArgumentParser();p.add_argument('action',choices=['capture','seal']);a=p.parse_args()
if a.action=='capture':
    records=[]
    for name in ['midcycle.json','midcycle.json.previous']:
        src=(tested/'runtime/build/pressure-workshop'/name).resolve();prior=out/'runtime/build/pressure-workshop'/name;dest=(tested/'evidence/native-checkpoints'/name).resolve()
        assert src.is_relative_to((tested/'runtime').resolve()) and dest.is_relative_to((tested/'evidence').resolve()) and not dest.exists()
        assert sha(src)==sha(prior)=='04b057919f34b38089816ece5c7942bddae8e29229367e9c2bb039efba3b0411'
        state=read(src);assert 'sim' in state and 'contraptions' in state and 'resource_nodes' in state
        dest.parent.mkdir(parents=True,exist_ok=True);shutil.move(str(src),str(dest));assert sha(dest)==sha(prior)
        records.append({'original_path':str(src),'evidence_path':str(dest),'prior_run_path':str(prior),'sha256':sha(dest),'bytes':dest.stat().st_size})
    write(tested/'checkpoint-routing.json',{'files':records,'source':'game/tests/pressure_workshop.gd: inherited whole-world atomic checkpoint write/read; source remains unchanged','scope':'After all engine jobs, preserve the two exact generated checkpoints under evidence. No source file, assertion, save content or normal-user path changes.'})
    write(tested/'postseal-audit-initial-failure.json',{'engine_jobs_passed':11,'sealed_runtime_entries_matched':5673,'failed_gate':'Unexpected additions outside runtime map','extra':['game/override.cfg','build/pressure-workshop/midcycle.json','build/pressure-workshop/midcycle.json.previous'],'resolution':'Preserve both named native fixture checkpoint files byte-for-byte under evidence, then rerun the unchanged strict source audit.'})
    print('R8_NATIVE_CHECKPOINTS_PRESERVED',len(records))
else:
    original=read(out/'sealed-package.json');base=Path(original['path']);m=verify(base,original['manifest_sha256']);dest=out/'handoff-final';assert not dest.exists();dest.mkdir()
    post=read(tested/'post-seal.json');assert post['all_runtime_bytes_match'] and post['all_jobs_passed']
    for n in m['files']:copy(base/n,dest/n)
    # Refresh only repository tools/documentation in this new, unpublished destination.
    for target,source in [('tools',ROOT/'tools/wroughtwild-art07-repairs/r8'),('documentation',doc)]:
        for file in source.rglob('*'):
            if file.is_file() and '__pycache__' not in file.parts:
                dst=dest/target/file.relative_to(source);dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(file,dst)
    for dirname,target in [('logs','logs'),('evidence','evidence'),('runtime/evidence','engine-evidence')]:
        for file in (tested/dirname).rglob('*'):
            if file.is_file():copy(file,dest/'post-seal'/target/file.relative_to(tested/dirname))
    for file in (tested/'users').rglob('*'):
        if file.is_file() and file.suffix=='.json' and 'ART07G1' in file.parts:copy(file,dest/'post-seal/private-state'/file.relative_to(tested/'users'))
    for file in tested.glob('*.json'):copy(file,dest/'post-seal/records'/file.name)
    for name in ['git-packaging-adjustments.json','staged-source-proof.json']:copy(out/name,dest/'records'/name)
    runtime_map=read(base/'runtime-files.json');assert (base/'runtime-files.json').read_bytes()==(dest/'runtime-files.json').read_bytes()
    for name,row in runtime_map.items():assert sha(dest/'runtime'/name)==sha(tested/'runtime'/name)==row['sha256'],name
    write(dest/'post-seal/runtime-equivalence.json',{'initial_seal':original,'tested_runtime':str(tested/'runtime'),'runtime_map_sha256':sha(dest/'runtime-files.json'),'runtime_entries':len(runtime_map),'every_runtime_file_equal_to_tested_copy':True,'scope':'Final handoff adds post-seal logs, images, checkpoints and repository formatting metadata. Every final runtime byte is exactly the runtime that passed all 11 reconstructed-copy engine checks; no new runtime behavior or assets.'})
    entries=rows(dest);manifest={'id':'r8','runtime_base':m['runtime_base'],'parent_seal':original,'file_count':len(entries),'bytes':sum(v['bytes'] for v in entries.values()),'files':entries};write(dest/'manifest.json',manifest);digest=sha(dest/'manifest.json');verify(dest,digest)
    write(out/'final-package.json',{'path':str(dest),'manifest_sha256':digest,'files':len(entries),'bytes':manifest['bytes']});print('R8_FINAL_HANDOFF_SEALED',digest)
