"""Audit exact R8 source preservation, overlaps, image bindings and native pin."""
import argparse,collections,hashlib,json,struct
from pathlib import Path
from inspect_inputs import ROOT,inputs,read,sha,payload
from aliases import chunks,params,digest
from compose import write

def main(version,tag):
    out=ROOT/'build/art07-repairs/r8'/version;runtime=out/'runtime';original=read(out/'prepared.json')['original_files'];pins,ds=inputs();base=Path(pins['runtime_source']['path'])
    comp=read(out/'composition.json');declared={r['path'] for c in comp['parent_candidates'].values() for r in c['changes']['files']}
    allowed=declared|{'game/scripts/player.gd'}
    for p in out.glob('aliases-*.json'):allowed.update(r['path'] for r in read(p)['image_references'])
    modified=[];unchanged=0
    for name,row in original.items():
        p=runtime/name;assert p.is_file(),name
        if sha(p)==row['sha256']:unchanged+=1;continue
        assert name in allowed,(name,'unexpected original source change')
        modified.append({'path':name,'before_sha256':row['sha256'],'after_sha256':sha(p),'bytes':p.stat().st_size})
    assert sha(runtime/'game/bin/libwroughtwild_sim.windows.x86_64.dll')==pins['native']['dll_sha256']
    player=(base/'game/scripts/player.gd').read_bytes()
    old=b'\t\tInput.mouse_mode = Input.MOUSE_MODE_CAPTURED'
    new=b'\t\tInput.mouse_mode = Input.MOUSE_MODE_VISIBLE if "--r8-no-mouse-capture" in OS.get_cmdline_user_args() else Input.MOUSE_MODE_CAPTURED'
    assert player.count(old)==1 and (runtime/'game/scripts/player.gd').read_bytes()==player.replace(old,new),'Unexpected player change'
    aliases=read(runtime/'game/r2/texture-aliases.json')
    for old,new in aliases.items():
        a=runtime/'game'/old[6:];b=runtime/'game'/new[6:]
        assert sha(a)==sha(b) and params(Path(str(a)+'.import'))==params(Path(str(b)+'.import')),(old,new)
    # Compare final interchange to its geometry owner, never to R2's old body.
    models=[]
    candidates={name:base/name for name in original if name.endswith(('.glb','.gltf'))}
    for ident in sorted(ds):
        if ident=='r2':continue
        pkg=Path(ds[ident]['package']['path'])
        for row in read(pkg/'changes.json')['files']:
            if row['path'].endswith(('.glb','.gltf')):candidates[row['path']]=payload(ident,pkg)/row['path']
    for name,expected in candidates.items():
        p=runtime/name;a=expected.read_bytes();b=p.read_bytes()
        if a==b:continue
        ac=chunks(a) if name.endswith('.glb') else None;bc=chunks(b) if ac else None
        x=json.loads(ac[0][1] if ac else a);y=json.loads(bc[0][1] if bc else b)
        assert {k:v for k,v in x.items() if k!='images'}=={k:v for k,v in y.items() if k!='images'},name
        if ac:assert ac[1:]==bc[1:],name
        models.append({'path':name,'geometry_owner':str(expected),'owner_sha256':digest(a),'final_sha256':digest(b),'non_image_json_equal':True,'non_json_chunks_equal':True})
    for name in original:
        if name.startswith(('data/','engine/','game/bin/')):assert sha(runtime/name)==original[name]['sha256'],name
    s=(runtime/'game/scripts/save_manager.gd').read_text(encoding='utf-8-sig');assert sha(runtime/'game/scripts/save_manager.gd')==original['game/scripts/save_manager.gd']['sha256']
    assert s.index('pocket.refresh_visual()')<s.index('player.finish_world_recovery()')
    for marker in ['script="r1/native_tree"','mesh.set_meta("r3_shape",id)','"ember_vein"']:assert marker in (runtime/'game/g1/art.gd').read_text(encoding='utf-8-sig'),marker
    for ident in ['r3','r6','r7']:assert 'R2Resources.resource(' in (runtime/'game'/ident/('materials.gd' if ident=='r3' else 'surface.gd' if ident=='r6' else 'cover.gd')).read_text(encoding='utf-8-sig')
    write(out/('source-audit-'+tag+'.json'),{'runtime_base':pins['runtime_base'],'dll_sha256':pins['native']['dll_sha256'],'unchanged_original_files':unchanged,'changed_original_files':modified,'final_aliases_verified':len(aliases),'image_only_derivatives':models,'f4_synchronous_restore_unchanged':True,'all_data_engine_native_bytes_unchanged':True,'overlap_ledger':comp['overlaps'],'scope':'Source audit; this is not an engine run or runtime acceptance.'})
    print('R8_SOURCE_AUDIT',unchanged,'originals unchanged;',len(modified),'declared changes;',len(aliases),'exact aliases;',len(models),'image-only interchange derivatives')
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--version',default='v01');p.add_argument('--tag',required=True);a=p.parse_args();main(a.version,a.tag)
