"""Seal exact R7 candidate with own delta separated from consumed R1."""
import argparse,re,shutil
from common import *
def verify(root):
    root=Path(root).resolve();rows=read(root/'manifest.json')['files']
    actual={p.relative_to(root).as_posix() for p in root.rglob('*') if p.is_file()}-{'manifest.json'}
    assert actual==set(rows),{'missing':sorted(set(rows)-actual),'extra':sorted(actual-set(rows))}
    for n,r in rows.items():
        p=(root/n).resolve();assert p.is_relative_to(root)
        assert p.stat().st_size==r['bytes'] and sha(p)==r['sha256'],n
    result={'path':root.as_posix(),'manifest_sha256':sha(root/'manifest.json'),'files':len(rows),'bytes':sum(r['bytes'] for r in rows.values())}
    print(json.dumps(result,indent=2));return result
def seal(name="handoff"):
    assert Path(name).name==name and name not in [".",".."],"Use a fresh child directory name"
    guard();checks=read(OUT/'evidence/final-checks.json');assert checks['passed']
    target=OUT/name;assert not target.exists()
    parent=read(OUT/'evidence/r1-consumption.json');base=read(OUT/'evidence/parent-runtime-hashes.json')
    hooks=read(OUT/'evidence/r7-overlay-application.json');owned={r['path']:r for r in hooks}
    changes=[]
    for name,before in base.items():
        source=OUT/'runtime'/name;after=sha(source)
        if before!=after:
            assert name in owned,('Undeclared parent edit',name)
            row=owned[name];assert row['before_sha256']==before
            row['after_sha256']=after;row['overlaps']=[]  # No direct file overlap in checked published R1-R4 deltas.
            changes.append(row)
        dest=target/name;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source,dest)
    for source in sorted((GAME/'r7').rglob('*')):
        if not source.is_file() or source.name.endswith('.import') or source.name=='replayed-paid-home.json':continue
        name=source.relative_to(OUT/'runtime').as_posix();dest=target/name;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source,dest)
        changes.append({'path':name,'before_sha256':None,'after_sha256':sha(source),'functions':re.findall(r'(?m)^(?:static )?func\s+(\w+)',source.read_text()) if source.suffix=='.gd' else [],'purpose':'Retained-anchor presentation' if source.name in ['cover.gd','settings.json','surface.gdshader'] else 'Owned inspection/test fixture; does not run in ordinary pilot play','overlaps':['R2 changes image packaging in the consumed game/b2/assets/sapling-shrub-lod2.glb and its texture aliases. R8 must apply that delta once, retain non-image geometry, and validate R7 material bindings against the final imported albedo/ORM. R7 does not overwrite this asset in its own delta.'] if source.name=='cover.gd' else []})
    write(target/'changes.json',{'id':'r7','runtime_base':'6bb2e044dcd0bf1788896aa2c19cdf56fee93522','parent_candidates':[{'id':'r1',**parent['parent']}],'delta_base':'Common G1 runtime plus exact published R1 delta. Before hashes name that state; R1 entries are not newly owned R7 changes.','files':changes,'changed_source_masters':[],'source_geometry':'Unchanged B2 far GLB geometry composed by uniform scale and local yaw at retained root origins; original packed masters preserved. No authored geometry or texture pixels edited.','tuning':read(TOOLS/'settings.json'),'line_endings':'Inherited source line endings retained for baseline-relative files; exact before/after bytes and full file set hashed.'})
    for folder in ['evidence','sources','logs']:shutil.copytree(OUT/folder,target/folder)
    for source in (OUT/'runtime/evidence').iterdir():
        dest=target/'engine-evidence'/source.name;dest.parent.mkdir(parents=True,exist_ok=True)
        if source.is_dir():shutil.copytree(source,dest)
        else:shutil.copy2(source,dest)
    for spec in OUT.glob('*.json'):
        if spec.name=='prepared.json':continue
        dest=target/'job-specs'/spec.name;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(spec,dest)
    shutil.copy2(OUT/'input-verification-r7-01.txt',target/'evidence/input-verification-r7-01.txt')
    shutil.copytree(TOOLS,target/'recipes/r7',ignore=shutil.ignore_patterns('__pycache__','*.pyc'))
    shutil.copytree(ROOT/'docs/art/leyline-studies/2026-09-14/art07-repairs/r7',target/'review')
    rows={p.relative_to(target).as_posix():{'bytes':p.stat().st_size,'sha256':sha(p)} for p in sorted(target.rglob('*')) if p.is_file()}
    write(target/'manifest.json',{'id':'r7','files':rows});write(OUT/'sealed-package.json',verify(target))
if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('command',choices=['seal','verify']);parser.add_argument('path',nargs='?');args=parser.parse_args()
    if args.command=='seal':seal(args.path or 'handoff')
    else:verify(args.path)
