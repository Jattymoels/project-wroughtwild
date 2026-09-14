"""Seal exact R6 runtime/evidence and baseline-relative changes, or verify a seal."""
import argparse
import hashlib
import json
import shutil
from pathlib import Path
from stage import ROOT, TOOLS, OUT, GAME, sha, write

def read(path): return json.loads(path.read_text(encoding='utf-8-sig'))

def verify(package):
    rows=read(package/'manifest.json')['files']
    actual={p.relative_to(package).as_posix() for p in package.rglob('*') if p.is_file() and p!=package/'manifest.json'}
    assert actual==set(rows), {'missing':sorted(set(rows)-actual),'extra':sorted(actual-set(rows))}
    for name,row in rows.items():
        path=(package/name).resolve()
        assert path.is_relative_to(package.resolve())
        assert path.stat().st_size==row['bytes'] and sha(path)==row['sha256'],name
    summary={'path':str(package),'manifest_sha256':sha(package/'manifest.json'),'files':len(rows),'bytes':sum(r['bytes'] for r in rows.values())}
    print(json.dumps(summary,indent=2))
    return summary

def seal(package, runs):
    assert not package.exists(), 'Use a fresh seal'
    selected_master=read(OUT/'sources/selected-master.json')
    master=Path(selected_master['path'])
    assert master.parent==OUT/'sources' and sha(master)==selected_master['sha256']
    prepared=read(OUT/'prepared.json')['original_files']
    allowed={'game/c5/native_resource.gd','game/g1/art.gd'}
    changes=[]
    for name,row in prepared.items():
        source=OUT/'runtime'/name
        after=sha(source)
        if after!=row['sha256']:
            assert name in allowed,'Unexpected baseline mutation: '+name
            changes.append({'path':name,'before_sha256':row['sha256'],'after_sha256':after,
                'functions': ['_apply_visual','refresh_surface','sync_state'] if '/c5/' in name else ['resource'],
                'purpose':'Material-only faceted ore presentation, exact native geometry/body and stock; retain fallback' if '/c5/' in name else 'Dispatch the existing native ember_vein visual key to C5',
                'overlaps':['R2 may alter C5 resource/material loading; merge the bounded surface branch and synchronisation, retain R2 resource reuse.'] if '/c5/' in name else ['R1/R7 may touch other resource dispatch entries; preserve their independent mappings.'],
                'text_note':'Copied baseline CRLF normalised to LF; changes are also described by function.'})
        target=package/name
        target.parent.mkdir(parents=True,exist_ok=True)
        shutil.copy2(source,target)
    for source in sorted((GAME/'r6').iterdir()):
        if source.suffix not in ['.gd','.gdshader','.json','.tscn','.png']: continue
        name='game/r6/'+source.name
        target=package/name
        target.parent.mkdir(parents=True,exist_ok=True)
        shutil.copy2(source,target)
        production = source.name in ['surface.gd','surface.gdshader','surface.json','c5-surface-fields.png']
        changes.append({'path':name,'before_sha256':None,'after_sha256':sha(source),'purpose':'R6 source-derived surface material/map/tuning on the unchanged native ribbon' if production else 'R6 isolated verification fixture or source provenance; no ordinary-world entry', 'overlaps':[]})
    for folder in ['verification','logs','sources','projection-v01']:
        if (OUT/folder).exists():shutil.copytree(OUT/folder,package/'evidence'/folder)
    # Keep successful and failed runs and job receipts, but never import caches or device state.
    for run_name in runs:
        run=OUT/'runs'/run_name
        assert run.is_dir()
        for source in run.rglob('*'):
            if not source.is_file() or 'users' in source.relative_to(run).parts: continue
            target=package/'evidence/runs'/run_name/source.relative_to(run)
            target.parent.mkdir(parents=True,exist_ok=True)
            shutil.copy2(source,target)
    for source in TOOLS.iterdir():
        if source.suffix in ['.py','.gd','.gdshader','.json','.tscn','.md','.ps1']:
            target=package/'tools/r6'/source.name
            target.parent.mkdir(parents=True,exist_ok=True)
            shutil.copy2(source,target)
    shutil.copytree(ROOT/'docs/art/leyline-studies/2026-09-14/art07-repairs/r6',package/'evidence/review')
    write(package/'changes.json',json.dumps({'id':'r6','runtime_base':'6bb2e044dcd0bf1788896aa2c19cdf56fee93522','delta_base_manifest':'fd5c592ef52185cc7d0737840e41af09dbb5bcea36b719539931e156f42865cd','parent_candidates':[],'settings':read(TOOLS/'surface.json'),'changed_source_masters':[{'path':'evidence/sources/'+master.name,'sha256':sha(master),'changes':'Original C5 mesh geometry preserved; packed projected vertex-field atlas and editable R6 controls added.'}],'files':changes,'no_changes':'Native DLL, normal scripts, original source assets, terrain, resource definitions, targeting and saves remain exact. R6 shades the existing ribbon; it adds no raised slab.'},indent=2))
    write(package/'README.md', '# ART-07R6 sealed candidate\n\n'
        'Owner visual acceptance is pending. Ordinary-world rollout is outside scope.\n\n'
        '- [Actual review, motion and cost tables](evidence/review/README.md)\n'
        '- [Recipe and every presentation control](tools/r6/README.md)\n'
        '- [Baseline-relative integration changes](changes.json)\n'
        '- [Final native preservation audit](evidence/verification/preservation.json)\n\n'
        'The review copy preserves its Git-relative tools link; use the recipe link above inside this seal. '
        'Run the tracked tools from D:/project-wroughtwild-art07-r6. package.py verify checks this exact seal; '
        'apply.py reconstructs a fresh private runtime from the verified G1 baseline and this delta. '
        'Never import or launch the sealed game in place.\n\n'
        'Selected packed master: evidence/sources/'+master.name+'. Original and failed earlier master copies are retained as evidence only. '
        'The separate Git receipt names the implementation commit and manifest identity; it is intentionally outside its own hashed package.\n')
    rows={p.relative_to(package).as_posix():{'bytes':p.stat().st_size,'sha256':sha(p)} for p in sorted(package.rglob('*')) if p.is_file()}
    write(package/'manifest.json',json.dumps({'files':rows},indent=2))
    verify(package)

def compare_probes(run):
    rows=[]
    for renderer in ['forward_plus','gl_compatibility']:
        baseline=read(run/('baseline-'+renderer)/'probe.json')
        art=read(run/('art-'+renderer)/'probe.json')
        assert baseline['geography_sha256']==art['geography_sha256']
        assert baseline['snapshot']==art['snapshot'],renderer+' full native snapshot differs'
        rows.append({'renderer':renderer,'geography_sha256':art['geography_sha256'],'snapshot_keys':sorted(art['snapshot']),'entire_snapshot_equal':True,'resources':len(art['snapshot']['resource_nodes'])})
    write(run/'comparison.json',json.dumps(rows,indent=2))
    print(json.dumps(rows,indent=2))

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('mode',choices=['seal','verify','compare-probes'])
    parser.add_argument('path',type=Path)
    parser.add_argument('--runs',nargs='*',default=[])
    args=parser.parse_args()
    if args.mode=='verify':verify(args.path)
    elif args.mode=='compare-probes':compare_probes(args.path)
    else:seal(args.path,args.runs)

if __name__=='__main__':main()
