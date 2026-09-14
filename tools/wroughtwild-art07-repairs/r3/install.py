"""Apply only R3 presentation hooks to the byte-verified prepared G1 runtime."""
import argparse, hashlib, json, re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
TOOLS=Path(__file__).resolve().parent

def read(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):
    with p.open('rb') as f: return hashlib.file_digest(f,'sha256').hexdigest()
def write(p,data):
    p.parent.mkdir(parents=True,exist_ok=True)
    p.write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')

def apply(version, check_only=False):
    out=(ROOT/'build/art07-repairs/r3'/version).resolve()
    assert out.is_relative_to((ROOT/'build/art07-repairs/r3').resolve())
    prepared=read(out/'prepared.json'); runtime=out/'runtime'
    assert prepared['runtime_base']=='6bb2e044dcd0bf1788896aa2c19cdf56fee93522'
    assert prepared['source']['manifest_sha256']=='fd5c592ef52185cc7d0737840e41af09dbb5bcea36b719539931e156f42865cd'
    if check_only:
        for name,row in prepared['original_files'].items():
            p=runtime/name
            assert p.stat().st_size==row['bytes'] and sha(p)==row['sha256'],name
        report={k:prepared[k] for k in ['runtime_base','files','bytes','source']}
        report['result']='Every prepared runtime entry matches the pinned source; no cache or peer payload consumed.'
        write(out/'runtime-input-verification.json',report)
        print('R3_PREPARED_RUNTIME_VERIFIED',prepared['files'],prepared['bytes']); return
    assert (out/'runtime-input-verification.json').is_file()
    patches={
        'game/g1/materials.gd':[(
            'static func material_for(family: String, role: String) -> Material:\n',
            'static func material_for(family: String, role: String) -> Material:\n\tif R3Materials.enabled(): return R3Materials.material_for(family,role)\n')],
        'game/g1/art.gd':[(
            '\tif mesh!=null:\n\t\t# Keep a valid base material',
            '\tif mesh!=null:\n\t\tmesh.set_meta("r3_shape",id)\n\t\t# Keep a valid base material')],
        'game/scripts/piece_look.gd':[(
            'static func apply_to(mesh: MeshInstance3D, form: String, family: StringName, material: Material) -> void:\n',
            'static func apply_to(mesh: MeshInstance3D, form: String, family: StringName, material: Material) -> void:\n\tif G1Art.enabled() and R3Materials.enabled() and not form in ["chest","fire"]:\n\t\tR3Materials.apply_to(mesh,family,material)\n\t\treturn\n')]
    }
    source=Path(prepared['source']['path'])
    for name,edits in patches.items():
        before=(source/name).read_bytes()
        assert hashlib.sha256(before).hexdigest()==prepared['original_files'][name]['sha256']
        text=before.decode('utf-8').replace('\r\n','\n')
        for old,new in edits:
            assert text.count(old)==1,(name,old)
            text=text.replace(old,new)
        if b'\r\n' in before: text=text.replace('\n','\r\n')
        (runtime/name).write_bytes(text.encode('utf-8'))
    for p in TOOLS.iterdir():
        if p.suffix in ['.gd','.gdshader','.gdshaderinc','.json','.tscn']:
            dest=runtime/'game/r3'/p.name; dest.parent.mkdir(exist_ok=True)
            dest.write_text(p.read_text(encoding='utf-8-sig'),encoding='utf-8',newline='\n')
    changes=[]
    functions={'game/g1/materials.gd':['G1Materials.material_for'], 'game/g1/art.gd':['G1Art.piece_mesh'], 'game/scripts/piece_look.gd':['PieceLook.apply_to']}
    for name in patches:
        changes.append({'path':name,'before_sha256':prepared['original_files'][name]['sha256'],'after_sha256':sha(runtime/name),'functions':functions[name],'purpose':'Route retained construction to R3 material mapping; --r3-baseline restores the sealed G1 appearance.','overlaps':['R2: reconcile shared G1 material/cache and mesh dispatch changes against the common baseline.'],'replacement_asset':None})
    for p in sorted((runtime/'game/r3').iterdir()):
        if p.suffix=='.uid': continue
        source_text=p.read_text(encoding='utf-8')
        affected=re.findall(r'^(?:static )?func (\w+)|^void (\w+)\(',source_text,re.M)
        affected=[left or right for left,right in affected]
        settings=list(read(p)['controls']) if p.name=='settings.json' else re.findall(r'^uniform \w+ (\w+)',source_text,re.M)
        changes.append({'path':p.relative_to(runtime).as_posix(),'before_sha256':None,'after_sha256':sha(p),'functions':affected,'settings':settings,'purpose':'R3 retained-map material implementation' if p.name in ['materials.gd','opaque.gdshader','glass.gdshader','surface.gdshaderinc','settings.json'] else 'Labelled native inspection or real paid-home evidence harness; never an ordinary-world entry point.','overlaps':[],'replacement_asset':None})
    write(out/'changes.json',{'id':'r3','delta_base':prepared['source'],'runtime_base':prepared['runtime_base'],'files':changes,'authored_maps_added':0,'authored_maps_removed':0,'authored_geometry_replaced':0,'note':'Only shading and dispatch. PNG/GLB bytes, triangle/vertex/index arrays, collisions, game rules and paid checkpoint remain untouched.'})
    print('R3_APPLIED',len(changes))

if __name__=='__main__':
    parser=argparse.ArgumentParser(); parser.add_argument('--version',default='v01'); parser.add_argument('--check-base',action='store_true')
    args=parser.parse_args(); apply(args.version,args.check_base)
