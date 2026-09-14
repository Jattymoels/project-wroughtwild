"""R8 deterministic composition of declared, verified R1-R7 deltas only.

Three text overlaps are applied as checked baseline-relative edits. R2 image
reference changes are recomputed on the final R5/R1 geometry by aliases.py.
"""
import argparse, collections, difflib, json, shutil, subprocess
from pathlib import Path
from inspect_inputs import ROOT,DOCS,read,sha,inputs,payload

def write(path,value):
    path.parent.mkdir(parents=True,exist_ok=True)
    with path.open('x',encoding='utf-8',newline='\n') as f:f.write(value if isinstance(value,str) else json.dumps(value,indent=2))
def delta(current,baseline,candidate,name):
    a=baseline.splitlines(True); b=candidate.splitlines(True)
    for tag,i,j,k,l in reversed(difflib.SequenceMatcher(None,a,b,autojunk=False).get_opcodes()):
        if tag=='equal':continue
        old=''.join(a[i:j]);new=''.join(b[k:l])
        if not old:
            old=''.join(a[max(0,i-2):i]);new=old+new
        assert old and current.count(old)==1,(name,tag,old[:160],current.count(old))
        current=current.replace(old,new,1)
    return current

def main(version):
    assert subprocess.check_output(['git','branch','--show-current'],cwd=ROOT,text=True).strip()=='codex/art07-r8'
    out=ROOT/'build/art07-repairs/r8'/version;runtime=out/'runtime'; prepared=read(out/'prepared.json')
    assert not (out/'composition.json').exists(),'Use a fresh candidate.'
    pins,deliveries=inputs(); baseline=Path(pins['runtime_source']['path'])
    assert prepared['runtime_base']==pins['runtime_base']
    for name,row in prepared['original_files'].items():assert sha(runtime/name)==row['sha256'],name
    print('R8_PREPARED_ALL_HASHES_VERIFIED',len(prepared['original_files']),flush=True)
    owners=collections.defaultdict(list); pending=[]; records={}; before_data={}
    # Preflight every selected delta before touching this runtime.
    for ident in sorted(deliveries):
        package=Path(deliveries[ident]['package']['path']);assert sha(package/'manifest.json')==deliveries[ident]['package']['manifest_sha256']
        receipt=read(ROOT/deliveries[ident]['receipt']);assert receipt['status']=='ready_for_integration'
        for commit in [deliveries[ident]['source_commit'],deliveries[ident]['receipt_commit']]:
            subprocess.run(['git','merge-base','--is-ancestor',commit,'HEAD'],cwd=ROOT,check=True)
        changes=read(package/'changes.json'); records[ident]={'delivery':deliveries[ident],'changes':changes}
        for row in changes['files']+changes.get('fixture_only_files',[]):
            name=row['path'];src=payload(ident,package)/name
            assert name.startswith('game/') and (runtime/name).resolve().is_relative_to(runtime.resolve()),name
            assert src.is_file() and sha(src)==row['after_sha256'],(ident,name)
            prior=row.get('before_sha256')
            if prior:
                assert (baseline/name).is_file() and sha(baseline/name)==prior,(ident,name,'non-common baseline')
            else:assert not (baseline/name).exists(),(ident,name,'unexpected addition')
            owners[name].append(ident)
            if ident=='r2' and (name.endswith(('.glb','.gltf')) or name=='game/r2/texture-aliases.json'):
                pending.append({'owner':ident,'path':name,'resolution':'Recompute image aliases after final geometry and full import settings are composed.'});continue
            target=runtime/name
            old=before_data.get(name,target.read_bytes() if target.exists() else None)
            candidate=src.read_bytes()
            if name in before_data:
                assert name in ['game/g1/art.gd','game/g1/materials.gd'],name
                candidate=delta(old.decode('utf-8-sig').replace('\r\n','\n'),(baseline/name).read_text(encoding='utf-8-sig'),candidate.decode('utf-8-sig').replace('\r\n','\n'),name).encode()
            before_data[name]=candidate
    for name,data in before_data.items():
        target=runtime/name;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(data)
    # R1's final geometry is already fitted, so its production path has no old
    # radius scan to memoize. R2's exact old B1 cache remains for --r1-before.
    extra=[]
    for name in ['game/r3/materials.gd','game/r6/surface.gd','game/r7/cover.gd']:
        target=runtime/name;s=target.read_text(encoding='utf-8-sig')
        if 'load(' not in s:continue
        import re
        s,n=re.subn(r'(?<![A-Za-z_])load\(', 'R2Resources.resource(',s)
        assert n>0 and 'const R2Resources=' not in s
        s+='\nconst R2Resources=preload("res://r2/resources.gd")\n';target.write_text(s,encoding='utf-8',newline='\n')
        extra.append({'path':name,'owners':['r2',name.split('/')[1]],'resolution':'Use exact immutable texture aliases in final repaired material loaders; all shader inputs and mutable work materials retained.'})
    # Test-only capture opt-out, checked before any rendered jobs. Normal launch
    # follows its original capture branch. No mouse movement automation is used.
    target=runtime/'game/scripts/player.gd';s=target.read_bytes()
    old=b'\t\tInput.mouse_mode = Input.MOUSE_MODE_CAPTURED'
    assert s.count(old)==1
    new=b'\t\tInput.mouse_mode = Input.MOUSE_MODE_VISIBLE if "--r8-no-mouse-capture" in OS.get_cmdline_user_args() else Input.MOUSE_MODE_CAPTURED'
    target.write_bytes(s.replace(old,new))
    extra.append({'path':'game/scripts/player.gd','owners':['r8'],'resolution':'Test-only --r8-no-mouse-capture opt-out; absent flag keeps original play controls.'})
    # Original G1 checkpoint is the common comparison input. Replayed saves stay
    # private evidence; no predecessor mutated review/save tree is copied.
    assert sha(runtime/'game/g1/paid-home.json')==prepared['original_files']['game/g1/paid-home.json']['sha256']
    write(out/'composition.json',{'id':'r8','runtime_base':pins['runtime_base'],'parent_candidates':records,'overlaps':[{'path':n,'owners':v,'resolution':'Combine exact baseline-relative text edits' if n.endswith('.gd') else 'Apply R5 geometry then regenerate R2 image references without modifying non-image JSON or BIN.'} for n,v in owners.items() if len(v)>1],'deferred_image_references':pending,'integration_resolutions':extra,'r1_r7_ancestry':'105-file R1 delta applied once; R7 own 32-file delta only.','r1_r2_fit':'R1 uses already fitted geometry with unit scale and no expensive radius scan; R2 original-path numeric cache retained for inspection mode.'})
    write(out/'input-lineage.json',{'pins':pins,'deliveries':deliveries,'checkout':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),'prepared':{k:v for k,v in prepared.items() if k!='original_files'}})
    print('R8_COMPOSED',len(before_data),'declared files;',len(pending),'image-reference deltas deferred',flush=True)
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--version',default='v01');main(p.parse_args().version)
