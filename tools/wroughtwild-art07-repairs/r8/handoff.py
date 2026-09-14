"""Exact full-runtime R8 handoff, audit, and guarded baseline-relative application."""
import argparse,datetime,hashlib,json,shutil,subprocess,re
from pathlib import Path
from inspect_inputs import ROOT,read,sha,inputs
from compose import write

def safe(root,name):
    p=(root/name).resolve();assert p.is_relative_to(root.resolve()),name;return p

def rows(root):
    return {p.relative_to(root).as_posix():{'bytes':p.stat().st_size,'sha256':sha(p)} for p in sorted(root.rglob('*')) if p.is_file() and p!=root/'manifest.json'}

def verify(package,expected):
    assert sha(package/'manifest.json')==expected,'Manifest identity'
    m=read(package/'manifest.json');expected_rows=m['files'];actual={p.relative_to(package).as_posix() for p in package.rglob('*') if p.is_file() and p!=package/'manifest.json'}
    assert actual==set(expected_rows),{'extra':sorted(actual-set(expected_rows)),'missing':sorted(set(expected_rows)-actual)}
    for name,row in expected_rows.items():
        p=safe(package,name);assert p.stat().st_size==row['bytes'] and sha(p)==row['sha256'],name
    assert len(actual)==m['file_count'] and sum(r['bytes'] for r in expected_rows.values())==m['bytes']
    print('R8_PACKAGE_VERIFIED',len(actual),m['bytes'],expected,flush=True);return m

def copy(src,dst):
    assert not dst.exists(),str(dst);dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dst)

def seal(version):
    out=ROOT/'build/art07-repairs/r8'/version;dest=out/'handoff';assert not dest.exists();dest.mkdir()
    original=read(out/'prepared.json')['original_files'];comp=read(out/'composition.json')
    declared={r['path'] for c in comp['parent_candidates'].values() for r in c['changes']['files']+c['changes'].get('fixture_only_files',[])}
    assert read(out/'acceptance.json')['required_checks_complete']
    runtime=out/'runtime';names=set(original)|declared
    # Include additive fixtures and final importer parameters, never generated caches/evidence.
    for p in (runtime/'game').rglob('*'):
        if not p.is_file():continue
        n=p.relative_to(runtime).as_posix()
        if '.godot' in p.parts or 'evidence' in p.parts or p.name=='override.cfg':continue
        if p.suffix in ['.gd','.gdshader','.tscn','.json','.png','.glb','.gltf','.import','.uid']:names.add(n)
    names.discard('game/override.cfg')
    changes=[]
    for n in sorted(names):
        p=runtime/n;assert p.exists(),n;copy(p,dest/'runtime'/n)
        before=original.get(n);after=sha(p)
        if before and before['sha256']==after:continue
        owners=[];details=[]
        for ident,c in comp['parent_candidates'].items():
            for r in c['changes']['files']+c['changes'].get('fixture_only_files',[]):
                if r['path']==n:owners.append(ident);details.append(r)
        purpose='Final image binding aliases; geometry owner data/BIN unchanged' if n.endswith(('.glb','.gltf')) else 'R8 composition/evidence; see exact parent delta and integration resolution'
        changes.append({'path':n,'before_sha256':before['sha256'] if before else None,'after_sha256':after,'bytes':p.stat().st_size,'parent_owners':owners,'parent_changes':details,'functions_or_settings':([m.group(1) for m in re.finditer(r'^(?:static )?func ([A-Za-z_][A-Za-z_0-9]*)',p.read_text(encoding='utf-8-sig'),re.M)] if n.startswith('game/r8/') and n.endswith('.gd') else ['_capture_mouse: explicit test-only flag'] if n=='game/scripts/player.gd' else [f for d in details for f in d.get('functions',d.get('functions_or_settings',[]))]),'purpose':purpose,'r8_owns':'composition and validation only; inherited repairs credited to parent owners','scope':'R8 evidence fixture' if n.startswith('game/r8/') else 'Test-only input hook; normal branch preserved' if n=='game/scripts/player.gd' else 'Parent repair/inspection source; exact owner purpose retained above'})
        if before:copy(Path(read(out/'input-lineage.json')['pins']['runtime_source']['path'])/n,dest/'baseline_sources'/n)
    for dirname in ['sources','evidence','logs']:
        for p in (out/dirname).rglob('*'):
            if p.is_file() and p.suffix!='.pyc':copy(p,dest/dirname/p.relative_to(out/dirname))
    for p in (runtime/'evidence').rglob('*'):
        if p.is_file():copy(p,dest/'engine-evidence'/p.relative_to(runtime/'evidence'))
    # Some original fixtures route output under game/<source>/evidence.
    for p in (runtime/'game').rglob('*'):
        if p.is_file() and 'evidence' in p.relative_to(runtime/'game').parts and '.godot' not in p.parts:copy(p,dest/'fixture-evidence'/p.relative_to(runtime/'game'))
    for p in (out/'users').rglob('*'):
        if p.is_file() and p.suffix=='.json' and 'ART07G1' in p.parts:copy(p,dest/'private-state'/p.relative_to(out/'users'))
    for p in out.iterdir():
        if p.is_file() and p.suffix in ['.json','.txt','.py']:copy(p,dest/'records'/p.name)
    comparison=out.parent/'v02'
    for dirname,target in [('logs','comparison/logs'),('runtime/evidence','comparison/engine-evidence')]:
        for p in (comparison/dirname).rglob('*'):
            if p.is_file():copy(p,dest/target/p.relative_to(comparison/dirname))
    for p in comparison.glob('*.json'):copy(p,dest/'comparison/records'/p.name)
    for owner,where in [('tools',ROOT/'tools/wroughtwild-art07-repairs/r8'),('documentation',ROOT/'docs/art/leyline-studies/2026-09-14/art07-repairs/r8')]:
        for p in where.rglob('*'):
            if p.is_file() and '__pycache__' not in p.parts:copy(p,dest/owner/p.relative_to(where))
    pins,ds=inputs()
    for ident,d in ds.items():
        receipt=ROOT/d['receipt'];copy(receipt,dest/'parents'/(ident+'.json'))
        copy(Path(d['package']['path'])/'changes.json',dest/'parents'/(ident+'-changes.json'))
    # Preserve exact tracked predecessor recipes and the unchanged common runner.
    support=[]
    patterns=['tools/wroughtwild-art07-repairs/r'+str(i) for i in range(1,8)]+['tools/wroughtwild-art07/g1','tools/wroughtwild-art07/g2','tools/wroughtwild-art07-repairs/run.ps1','tools/wroughtwild-art07-repairs/workspace.py','docs/prototype/art07-repairs/2026-09-14/inputs.json']
    for name in subprocess.check_output(['git','ls-files','--',*patterns],cwd=ROOT,text=True).splitlines():
        p=ROOT/name;assert subprocess.check_output(['git','hash-object',str(p)],cwd=ROOT,text=True).strip()==subprocess.check_output(['git','rev-parse','HEAD:'+name],cwd=ROOT,text=True).strip(),name;copy(p,dest/'support'/name);support.append({'path':name,'sha256':sha(p),'git_blob':subprocess.check_output(['git','rev-parse','HEAD:'+name],cwd=ROOT,text=True).strip()})
    write(dest/'support-files.json',support)
    copy(runtime/'game/override.cfg',dest/'test-support/override.cfg')
    write(dest/'changes.json',{'id':'r8','runtime_base':pins['runtime_base'],'delta_base':pins['runtime_source'],'parent_candidates':ds,'files':changes,'overlaps':comp['overlaps'],'integration_resolutions':comp['integration_resolutions'],'file_accounting':'Complete baseline-relative composite; parent-owned changes are credited once, not claimed as newly authored R8 repairs.','normal_play':'test-support/override.cfg is excluded from normal runtime; test flag absent keeps original mouse capture.'})
    write(dest/'runtime-files.json',{n:{'bytes':(dest/'runtime'/n).stat().st_size,'sha256':sha(dest/'runtime'/n)} for n in sorted(names)})
    write(dest/'baseline-files.json',original)
    copy(ROOT/'tools/wroughtwild-art07-repairs/r8/play.ps1',dest/'play.ps1')
    write(dest/'README.md','ART-07R8 isolated retained-world package. See documentation/README.md, changes.json and records/acceptance.json. Original paid checkpoint remains game/g1/paid-home.json; private-state contains fresh no-grants replay checkpoints. Run play.ps1 with a fresh private target through its guarded copy workflow. Test-only override stays outside normal runtime. Never import/run this immutable seal in place.\n')
    runtime_rows=read(dest/'runtime-files.json')
    write(dest/'disk-costs.json',{'original_runtime_files':len(original),'original_runtime_bytes':sum(r['bytes'] for r in original.values()),'combined_runtime_files':len(runtime_rows),'combined_runtime_bytes':sum(r['bytes'] for r in runtime_rows.values()),'scope':'Full retained source runtime including its inherited fixture/evidence files, plus additive R8 inspection sources. Imported caches excluded. Disk bytes are independent of measured renderer allocations.'})
    entries=rows(dest);m={'id':'r8','runtime_base':pins['runtime_base'],'file_count':len(entries),'bytes':sum(r['bytes'] for r in entries.values()),'files':entries}
    write(dest/'manifest.json',m);digest=sha(dest/'manifest.json');verify(dest,digest)
    write(out/'sealed-package.json',{'path':str(dest),'manifest_sha256':digest,'files':len(entries),'bytes':m['bytes']})

def apply(package,digest,target,tests):
    m=verify(package,digest);original=read(package/'baseline-files.json');final=read(package/'runtime-files.json')
    target=target.resolve();allowed=(ROOT/'build/art07-repairs/r8').resolve()
    assert target.is_relative_to(allowed) and target.name=='runtime' and target!=package/'runtime'
    actual={p.relative_to(target).as_posix() for p in target.rglob('*') if p.is_file()}
    assert actual==set(original),'Apply only to a freshly prepared exact baseline file set'
    for n,r in original.items():
        p=safe(target,n);assert p.exists() and sha(p)==r['sha256'],(n,'requires freshly prepared original runtime')
    for n,r in final.items():
        p=safe(target,n)
        if n not in original:assert not p.exists(),n
    for n,r in final.items():
        p=safe(target,n);p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(package/'runtime'/n,p)
    for n,r in final.items():assert sha(target/n)==r['sha256'],n
    if tests:copy(package/'test-support/override.cfg',target/'game/override.cfg')
    write(target.parent/'r8-applied.json',{'package':str(package),'manifest_sha256':digest,'runtime_files':len(final),'all_bytes_match':True,'test_override':tests})
    print('R8_APPLIED',len(final),str(target),flush=True)

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('action',choices=['seal','verify','apply','clone']);p.add_argument('--version',default='v01');p.add_argument('--package',type=Path);p.add_argument('--manifest-sha256');p.add_argument('--target',type=Path);p.add_argument('--tests',action='store_true');a=p.parse_args()
    if a.action=='seal':seal(a.version)
    elif a.action=='verify':verify(a.package,a.manifest_sha256)
    elif a.action=='apply':apply(a.package,a.manifest_sha256,a.target,a.tests)
    else:
        verify(a.package,a.manifest_sha256)
        target=a.target.resolve();assert target.is_relative_to((ROOT/'build/art07-repairs/r8').resolve()) and target.name=='runtime' and not target.exists()
        for n,r in read(a.package/'runtime-files.json').items():copy(a.package/'runtime'/n,safe(target,n))
        for n,r in read(a.package/'runtime-files.json').items():assert sha(target/n)==r['sha256'],n
        if a.tests:copy(a.package/'test-support/override.cfg',target/'game/override.cfg')
        print('R8_CLONED',str(target))
