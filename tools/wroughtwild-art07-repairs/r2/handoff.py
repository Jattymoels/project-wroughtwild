"""Seal, verify and apply the R2 delta against a verified common G1 baseline."""
import argparse
import copy
import hashlib
import json
import re
import shutil
from pathlib import Path
from measure import BUILD, ROOT, TOOLS, read, write
from source import sha

PIN='6bb2e044dcd0bf1788896aa2c19cdf56fee93522'


def safe_file(root,name):
    path=(root/name).resolve()
    assert path.is_relative_to(root.resolve()) and path!=root.resolve(),name
    assert not (root/name).is_symlink(),name
    return path


def copy_file(source,target,expected=None):
    assert source.is_file() and not target.exists(),str(target)
    if expected is not None:assert sha(source)==expected,str(source)
    target.parent.mkdir(parents=True,exist_ok=True)
    shutil.copyfile(source,target)
    if expected is not None:assert sha(target)==expected,str(target)


def verify(package,expected):
    package=package.resolve();manifest=package/'manifest.json'
    assert sha(manifest)==expected,'Manifest identity mismatch'
    info=read(manifest);rows=info['files']
    actual={p.relative_to(package).as_posix() for p in package.rglob('*') if p.is_file() and p!=manifest}
    assert actual==set(rows),{'missing':sorted(set(rows)-actual),'extra':sorted(actual-set(rows))}
    for name,row in rows.items():
        path=safe_file(package,name)
        assert path.stat().st_size==row['bytes'] and sha(path)==row['sha256'],name
    total=sum(r['bytes'] for r in rows.values())
    assert len(rows)==info['file_count'] and total==info['bytes']
    print('R2_FULL_PACKAGE_VERIFIED',len(rows),total,expected)
    return info


def functions(text):
    # Ignore top-level dependency declarations appended after the last method.
    lines=text.splitlines();result={}
    for i,line in enumerate(lines):
        match=re.match(r'^(?:static )?func ([A-Za-z_][A-Za-z_0-9]*)\(',line)
        if not match:continue
        end=i+1
        while end<len(lines) and (not lines[end].strip() or lines[end][0].isspace()):end+=1
        result[match.group(1)]='\n'.join(lines[i:end]).strip()
    return result


def seal(version):
    base=BUILD/version;runtime=base/'runtime';package=base/'handoff'
    assert not package.exists(),'Seal into a fresh absent handoff only'
    prepared=read(base/'prepared.json');assert prepared['runtime_base']==PIN
    record=copy.deepcopy(read(base/'changes.json'));changes={r['path']:r for r in record['files']}
    source=Path(prepared['source']['path']);assert sha(source/'manifest.json')==prepared['source']['manifest_sha256']
    source_rows=read(source/'manifest.json')['files']
    # Preflight every source before any seal copy. No imported-cache files become
    # runtime source. Original sidecar import settings are pinned source entries.
    for name,row in prepared['original_files'].items():
        expected=changes[name]['after_sha256'] if name in changes else row['sha256']
        assert sha(runtime/name)==expected,(name,'Unexpected source change')
    for row in record['files']:
        assert sha(runtime/row['path'])==row['after_sha256'],row['path']
        row['category']='production'
        if row['path'].endswith('.gd'):
            before=functions((source/row['path']).read_text(encoding='utf-8-sig')) if row['before_sha256'] else {}
            after=functions((runtime/row['path']).read_text(encoding='utf-8-sig'))
            row['functions_or_settings']=[n for n in sorted(set(before)|set(after)) if before.get(n)!=after.get(n)]
            if 'native_tree.gd' in row['path']:row['functions_or_settings'].append('static r2_fit_radii')
            if 'R2Resources' in (runtime/row['path']).read_text():row['functions_or_settings'].append('top-level R2Resources dependency')
        elif row['path'].endswith(('.glb','.gltf')):
            row['functions_or_settings']=['glTF images[].uri and equivalent bufferView/mimeType representation only']
            row['replacement_asset']=row['path']
        if row['path'].startswith('game/b3/'):
            row['overlaps'].append('r6: B3 retained-surface presentation; preserve final supported geometry and apply the call-local memo to its final projection.')
        if row['path'].startswith('game/assets/authored/e3/chest_') or row['path']=='game/e3/home_art.gd':
            row['overlaps'].append('r5: chest visual fit and source packaging; apply only equivalent image references to the final R5 meshes/materials.')
    for path in sorted((runtime/'game/r2').iterdir()):
        if path.suffix not in ['.gd','.tscn','.json']:continue
        name=path.relative_to(runtime).as_posix()
        if name in changes:continue
        record['files'].append({'path':name,'before_sha256':None,'after_sha256':sha(path),'functions_or_settings':(sorted(functions(path.read_text(encoding='utf-8-sig'))) if path.suffix=='.gd' else ['R2 scene script reference' if path.suffix=='.tscn' else 'R2 evidence data']),'purpose':'Reproduce timings, paired views, exact geometry, native projection or reload evidence; no ordinary-world adoption.','overlaps':[],'replacement_asset':None,'category':'evidence_harness'})
    package.mkdir()
    for name,row in prepared['original_files'].items():
        expected=changes[name]['after_sha256'] if name in changes else row['sha256']
        copy_file(runtime/name,package/name,expected)
    for row in record['files']:
        if row['before_sha256'] is None:copy_file(runtime/row['path'],package/row['path'],row['after_sha256'])
        else:copy_file(source/row['path'],package/'baseline_sources'/row['path'],row['before_sha256'])
    # Retain the fully verified packed masters and source lineage unmodified.
    lineage=[]
    for name,row in source_rows.items():
        if name.startswith(('masters/','lineage/','recipes/')):
            copy_file(source/name,package/'g1_originals'/name,row['sha256']);lineage.append({'path':'g1_originals/'+name,**row})
    write(package/'source-lineage.json',{'runtime_base':PIN,'source':prepared['source'],'retained_originals':lineage,'changed_blender_masters':[],'changed_png_maps':[],'geometry_regeneration':False,'source_derivatives':'Only lossless glTF image references and presentation scripts changed; PNG bytes, every non-image glTF JSON field, GLB non-JSON chunks, transforms, rigs and geometry remain original. Packed Blender masters are unchanged provenance, not claimed as freshly edited or reopened models.'})
    copy_file(source/'manifest.json',package/'source-manifests/g1.json',prepared['source']['manifest_sha256'])
    inputs_path=ROOT/'docs/prototype/art07-repairs/2026-09-14/inputs.json';inputs=read(inputs_path)
    copy_file(inputs_path,package/'source-manifests/inputs.json')
    copy_file(Path(inputs['g2_review']['path'])/'manifest.json',package/'source-manifests/g2.json',inputs['g2_review']['manifest_sha256'])
    copy_file(Path(inputs['source_index']['path']),package/'source-manifests/source-index.json',inputs['source_index']['sha256'])
    write(package/'baseline-runtime.json',prepared)
    write(package/'changes.json',record)
    for v in ['v01','v02',version]:
        vb=BUILD/v
        for directory in ['logs','analysis','runtime/evidence','runtime/captures']:
            for path in sorted((vb/directory).rglob('*')):
                if path.is_file():copy_file(path,package/'evidence'/v/path.relative_to(vb))
        for path in sorted(vb.iterdir()):
            if path.is_file() and path.suffix in ['.json','.log','.md']:
                copy_file(path,package/'evidence'/v/path.name)
        for path in sorted((vb/'runtime/game/r2').glob('*')):
            if path.suffix in ['.gd','.tscn','.json']:copy_file(path,package/'evidence'/v/'harness'/path.name)
        for path in sorted((vb/'users').rglob('*')):
            if path.is_file() and path.suffix in ['.json','.previous','.expected'] and 'ART07G1' in path.parts:
                copy_file(path,package/'evidence'/v/path.relative_to(vb))
    for path in sorted(TOOLS.iterdir()):
        if path.is_file() and path.suffix in ['.py','.ps1','.gd','.txt']:copy_file(path,package/'r2-tools'/path.name)
    docs=ROOT/'docs/art/leyline-studies/2026-09-14/art07-repairs/r2'
    for path in sorted(docs.rglob('*')):
        if path.is_file():copy_file(path,package/'documentation'/path.relative_to(docs))
    # Record both comparable runtime payloads and the evidence/master overhead.
    runtime_names=set(prepared['original_files'])|{r['path'] for r in record['files']}
    production_names=set(prepared['original_files'])|{r['path'] for r in record['files'] if r['category']=='production'}
    write(package/'disk-costs.json',{'baseline_runtime_files':prepared['files'],'baseline_runtime_bytes':prepared['bytes'],'candidate_production_runtime_files':len(production_names),'candidate_production_runtime_bytes':sum((package/n).stat().st_size for n in production_names),'candidate_runtime_with_harness_files':len(runtime_names),'candidate_runtime_with_harness_bytes':sum((package/n).stat().st_size for n in runtime_names),'original_g1_full_package_bytes':prepared['source']['bytes'],'disk_png_duplicates_removed':0,'scope':'Comparable game/data/engine runtime payload separately from masters and evidence overhead. All original redundant PNGs remain; GPU savings are measured allocations, not disk-byte estimates.'})
    rows={p.relative_to(package).as_posix():{'bytes':p.stat().st_size,'sha256':sha(p)} for p in sorted(package.rglob('*')) if p.is_file()}
    info={'id':'r2','runtime_base':PIN,'file_count':len(rows),'bytes':sum(r['bytes'] for r in rows.values()),'files':rows}
    write(package/'manifest.json',info)
    digest=sha(package/'manifest.json');verify(package,digest)
    write(base/'sealed-package.json',{'path':str(package.resolve()),'manifest_sha256':digest,'files':info['file_count'],'bytes':info['bytes']})
    print('R2_SEALED',str(package.resolve()),digest)


def apply(package,expected,target,with_harness):
    verify(package,expected)
    target=target.resolve()
    assert target.name=='runtime' and re.fullmatch('v[0-9]+',target.parent.name),str(target)
    assert target.parent.parent.parent.name=='art07-repairs',str(target)
    assert re.fullmatch('r[1-9]',target.parent.parent.name),str(target)
    prepared=read(target.parent/'prepared.json');baseline=read(package/'baseline-runtime.json')
    assert prepared['runtime_base']==baseline['runtime_base']==PIN
    assert prepared['source']==baseline['source'] and prepared['original_files']==baseline['original_files'],'Requires the exact common G1 state, not an unfinished peer candidate'
    present={p.relative_to(target).as_posix() for folder in ['game','data','engine'] for p in (target/folder).rglob('*') if p.is_file() and '.godot' not in p.relative_to(target).parts}
    assert present==set(prepared['original_files']),{'unexpected_source_files':sorted(present-set(prepared['original_files'])),'missing_source_files':sorted(set(prepared['original_files'])-present)}
    for name,row in prepared['original_files'].items():assert sha(safe_file(target,name))==row['sha256'],(name,'Conflicting source; compose functions manually, never overwrite')
    selected=[r for r in read(package/'changes.json')['files'] if with_harness or r['category']=='production']
    for row in selected:
        path=safe_file(target,row['path'])
        assert (not path.exists()) if row['before_sha256'] is None else sha(path)==row['before_sha256'],row['path']
    for row in selected:
        path=safe_file(target,row['path']);path.parent.mkdir(parents=True,exist_ok=True)
        shutil.copyfile(package/row['path'],path)
        assert sha(path)==row['after_sha256'],row['path']
    write(target.parent/'r2-applied.json',{'package':str(package.resolve()),'manifest_sha256':expected,'files':selected,'runtime_base':PIN,'scope':'Applied to a fully rehashed fresh common baseline. Combined R8 peer changes require explicit function/image-reference composition.'})
    print('R2_EXACT_COMMON_BASE_APPLICATION_VERIFIED',len(selected),str(target))

if __name__=='__main__':
    p=argparse.ArgumentParser();s=p.add_subparsers(dest='command',required=True)
    x=s.add_parser('seal');x.add_argument('--version',required=True)
    for name in ['verify','apply']:
        x=s.add_parser(name);x.add_argument('--package',type=Path,required=True);x.add_argument('--manifest-sha256',required=True)
        if name=='apply':x.add_argument('--target',type=Path,required=True);x.add_argument('--with-evidence-harness',action='store_true')
    a=p.parse_args()
    if a.command=='seal':seal(a.version)
    elif a.command=='verify':verify(a.package,a.manifest_sha256)
    else:apply(a.package,a.manifest_sha256,a.target,a.with_evidence_harness)
