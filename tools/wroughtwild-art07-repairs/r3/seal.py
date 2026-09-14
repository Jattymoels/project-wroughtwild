"""Seal a fresh R3 candidate and verify its exact file set without cache artefacts."""
import argparse,hashlib,json,shutil,subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
TOOLS=Path(__file__).resolve().parent

def read(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):
    with p.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def verify(package):
    manifest=read(package/'manifest.json')
    actual={p.relative_to(package).as_posix() for p in package.rglob('*') if p.is_file() and p!=package/'manifest.json'}
    assert actual==set(manifest['files']),('file set mismatch',sorted(actual-set(manifest['files'])),sorted(set(manifest['files'])-actual))
    total=0
    for name,row in manifest['files'].items():
        p=(package/name).resolve();assert p.is_relative_to(package.resolve()),name
        assert p.stat().st_size==row['bytes'] and sha(p)==row['sha256'],name
        total+=p.stat().st_size
    assert manifest['file_count']==len(actual) and manifest['total_bytes']==total
    result={'path':str(package.resolve()),'manifest_sha256':sha(package/'manifest.json'),'files':len(actual),'bytes':total}
    print('R3_EXACT_SEAL',json.dumps(result));return result

def seal(out,name,commit):
    assert subprocess.check_output(['git','branch','--show-current'],cwd=ROOT,text=True).strip()=='codex/art07-r3'
    assert len(commit)==40 and subprocess.check_output(['git','rev-parse',commit],cwd=ROOT,text=True).strip()==commit
    assert not subprocess.check_output(['git','status','--porcelain','--','tools/wroughtwild-art07-repairs/r3','docs/art/leyline-studies/2026-09-14/art07-repairs/r3'],cwd=ROOT,text=True).strip(),'Commit checked tools and visual evidence before sealing.'
    readiness=read(out/'ready-to-seal.json')
    assert readiness['all_required_checks_passed'] is True and readiness['owner_visual_acceptance']=='pending'
    package=(out/name).resolve();assert package.parent==out.resolve() and not package.exists()
    package.mkdir()
    def copy(source,target):
        target=package/target;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source,target)
    prepared=read(out/'prepared.json');changes=read(out/'changes.json')
    runtime_names=set(prepared['original_files'])|{r['path'] for r in changes['files']}
    for rel in sorted(runtime_names):copy(out/'runtime'/rel,'runtime/'+rel)
    for folder in ['inputs','masters','logs','packed-reopen-01']:
        for p in sorted((out/folder).rglob('*')):
            if p.is_file():copy(p,p.relative_to(out))
    for p in sorted(out.glob('*')):
        if p.is_file() and p.suffix in ['.json','.txt']:copy(p,p.name)
    for p in sorted((out/'runtime/evidence').rglob('*')):
        if p.is_file():copy(p,Path('evidence')/p.relative_to(out/'runtime/evidence'))
    for p in sorted((out/'runtime/captures').rglob('*')):
        if p.is_file():copy(p,Path('native-captures')/p.relative_to(out/'runtime/captures'))
    for p in sorted((out/'users').rglob('*.json')):
        if p.name in ['r3-paid-home.json','int03c-fixtures.json']:
            copy(p,Path('private-checkpoints')/p.relative_to(out/'users'))
    for p in sorted(TOOLS.iterdir()):
        if p.is_file():copy(p,Path('reconstruction')/p.name)
    visual=ROOT/'docs/art/leyline-studies/2026-09-14/art07-repairs/r3'
    for p in sorted(visual.rglob('*')):
        if p.is_file():copy(p,Path('curated')/p.relative_to(visual))
    provenance={'id':'r3','source_commits':[commit],'runtime_base':prepared['runtime_base'],'source':prepared['source'],'parent_candidates':[],'map_or_geometry_replacement':False,'owner_visual_acceptance':'pending','ordinary_world_rollout':'outside scope','shared_runner_sha256':sha(ROOT/'tools/wroughtwild-art07-repairs/run.ps1'),'workspace_helper_sha256':sha(ROOT/'tools/wroughtwild-art07-repairs/workspace.py')}
    (package/'provenance.json').write_text(json.dumps(provenance,indent=2)+'\n')
    entries={}
    for p in sorted(package.rglob('*')):
        if p.is_file():entries[p.relative_to(package).as_posix()]={'bytes':p.stat().st_size,'sha256':sha(p)}
    manifest={'schema':1,'id':'r3','files':entries,'file_count':len(entries),'total_bytes':sum(r['bytes'] for r in entries.values()),'source_commits':[commit]}
    (package/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    result=verify(package)
    with (out/(name+'-seal-result.json')).open('x') as f:json.dump(result,f,indent=2)

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--version',default='v01');p.add_argument('--verify',type=Path);p.add_argument('--name',default='handoff');p.add_argument('--commit');a=p.parse_args()
    if a.verify:verify(a.verify)
    else:
        assert a.commit,'Supply the checked source commit.'
        seal(ROOT/'build/art07-repairs/r3'/a.version,a.name,a.commit)
