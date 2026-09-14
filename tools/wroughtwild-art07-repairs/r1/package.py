"""Seal/verify R1's checked candidate without importing or changing the seal."""
import argparse,hashlib,json,re,shutil
from pathlib import Path
from measure import ROOT,OUT,GAME,INPUTS,sha,write

def verify(root):
    root=Path(root).resolve();manifest=json.loads((root/'manifest.json').read_text());rows=manifest['files']
    actual={p.relative_to(root).as_posix() for p in root.rglob('*') if p.is_file()}-{'manifest.json'}
    assert actual==set(rows),{'missing':list(set(rows)-actual),'extra':list(actual-set(rows))}
    for n,r in rows.items():
        p=(root/n).resolve();assert p.is_relative_to(root)
        assert p.stat().st_size==r['bytes'] and sha(p)==r['sha256'],n
    result={'path':str(root),'manifest_sha256':sha(root/'manifest.json'),'files':len(rows),'bytes':sum(r['bytes'] for r in rows.values())}
    print(json.dumps(result,indent=2));return result

def seal():
    out=OUT/'handoff';assert not out.exists()
    checks=json.loads((OUT/'evidence/final-checks.json').read_text());assert checks['passed'] is True
    original=json.loads((OUT/'prepared.json').read_text())['original_files']
    changes=[]
    for name,row in original.items():
        p=OUT/'runtime'/name;assert p.is_file(),name
        if sha(p)!=row['sha256']:
            assert name=='game/g1/art.gd',('Unexpected original runtime edit',name)
            changes.append({'path':name,'before_sha256':row['sha256'],'after_sha256':sha(p),'functions':['G1Art.resource'],'purpose':'Select R1 fitted B1 tree presentation; preserve family choice and source-owner metadata. --r1-before selects unchanged G1 B1 visuals.','overlaps':['R2 may change resource loading/dispatch; R8 must merge this one selection hook by function.']})
    assert len(changes)==1
    # Keep all pinned runtime inputs, including their original UID files.
    for name in original:
        src=OUT/'runtime'/name;dst=out/name;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dst)
    for src in sorted((GAME/'r1').rglob('*')):
        if not src.is_file() or src.name.endswith('.import') or src.name=='replayed-paid-home.json':continue
        name=src.relative_to(OUT/'runtime').as_posix();dst=out/name;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dst)
        role='selected presentation' if src.name in ['native_tree.gd','settings.json'] or src.parent.name=='assets' else 'inspection/test addition; not used by ordinary pilot play'
        changes.append({'path':name,'before_sha256':None,'after_sha256':sha(src),'functions':re.findall(r'(?m)^func\s+(\w+)\s*\(',src.read_text(encoding='utf-8')) if src.suffix=='.gd' else [],'purpose':role,'overlaps':['R2 may optimize R1 resource reuse; geometry/fit contract belongs to R1.'] if src.name=='native_tree.gd' else []})
    models=OUT/('models-packed-v2' if (OUT/'models-packed-v2').exists() else 'models')
    shutil.copytree(models,out/'models')
    for folder in ['sources','evidence','logs']:
        shutil.copytree(OUT/folder,out/folder)
    shutil.copytree(ROOT/'tools/wroughtwild-art07-repairs/r1',out/'recipes/r1',ignore=shutil.ignore_patterns('__pycache__','*.pyc'))
    # Include the actual encoded review media as well as every source frame.
    review_root=ROOT/'docs/art/leyline-studies/2026-09-14/art07-repairs/r1'
    media=json.loads((OUT/'evidence/image-provenance.json').read_text())
    for row in media:
        src=Path(row['path']).resolve();assert src.is_relative_to(review_root.resolve())
        assert sha(src)==row['sha256'],src
        dst=out/'review'/src.name;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dst)
    write(out/'review/index.json',{'artifacts':[{'path':r['path'].replace('\\','/').split('/')[-1],'sha256':r['sha256']} for r in media],'provenance':'../evidence/image-provenance.json','scope':'Actual captured model/world/native frames, tiled or paced as recorded. Owner visual acceptance remains pending.'})
    # Actual R1 engine evidence was redirected outside original sealed resources.
    evidence=OUT/'runtime/evidence'
    for src in evidence.iterdir():
        if not (src.name.startswith('r1-') or 'r1-' in src.name):continue
        dst=out/'engine-evidence'/src.name
        if src.is_dir():shutil.copytree(src,dst)
        else:dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dst)
    for src in OUT.glob('*jobs.json'):shutil.copy2(src,out/'evidence'/src.name)
    shutil.copy2(OUT/'import-smoke.json',out/'evidence/import-smoke.json')
    source_masters=[{'path':'models/'+kind+'/'+kind+'-master.blend','original_source_sha256':sha(OUT/'sources/b1/models'/kind/(kind+'-master.blend')),'changed_sha256':sha(models/kind/(kind+'-master.blend')),'purpose':'Editable lower-trunk/crown refit retaining exact original source objects, UVs and packed image bytes.'} for kind in ['broadleaf','pine']]
    for change in changes:
        if change['path']=='game/r1/native_tree.gd':
            change['functions']=['_apply_visual','_leave_stump']
            change['purpose']='Offline lower-trunk fit replaces the B1 per-instance whole-tree squeeze; selected model/stump instantiate at unit scale. Original material handling, native parent rules and owner metadata remain.'
        if change['path']=='game/r1/settings.json':
            change['settings']=json.loads((GAME/'r1/settings.json').read_text())
        if change['path'].startswith('game/r1/assets/'):
            asset=Path(change['path']).name
            change['replaces_presentation_asset']='game/b1/assets/'+asset
            change['source_refit']='models/'+('pine' if asset.startswith('pine') else 'broadleaf')+'/'+asset
    write(out/'changes.json',{'id':'r1','changed_source_masters':source_masters,'runtime_base':INPUTS['runtime_base'],'baseline_manifest_sha256':INPUTS['runtime_source']['manifest_sha256'],'parent_candidates':[],'delta_base':'unchanged sealed G1 runtime','files':changes,'geometry':'B1 broadleaf/pine source-preserving lower-trunk fit and reattached crowns; source Y normalization, root burial and native bodies retained.','unchanged_context':['C4 geometry/fit','G1 settings and visibility distances','all game/sim/data/native authority','ground-cover composition','loading/cache policy'],'line_endings':'g1/art.gd retains the original mixed line endings (28 CRLF lines); the selection hook adds LF lines. New UTF-8 R1 source/evidence files retain their recorded LF/CRLF bytes, all covered by per-file hashes.'})
    rows={p.relative_to(out).as_posix():{'bytes':p.stat().st_size,'sha256':sha(p)} for p in sorted(out.rglob('*')) if p.is_file()}
    write(out/'manifest.json',{'id':'r1','runtime_base':INPUTS['runtime_base'],'files':rows})
    result=verify(out);write(OUT/'sealed-package.json',result)
if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('command',choices=['seal','verify']);parser.add_argument('path',nargs='?');args=parser.parse_args()
    if args.command=='seal':seal()
    else:verify(args.path)
