"""Check source lineage, exported geometry, native-copy scope and final evidence."""
import ast,json,struct,subprocess,sys
from pathlib import Path
from inputs import ROOT,sha,verify
source,review,output=[Path(p).resolve() for p in sys.argv[1:4]]
assert output.is_relative_to(ROOT/'build/art07/e2') and not output.exists()
original=json.loads((ROOT/'build/art07/e2/v01/inputs/provenance.json').read_text())
current=verify()
assert current['dependencies']==original['dependencies']
for name,digest in original['sources'].items():
    p=Path(name) if Path(name).is_absolute() else ROOT/name
    assert sha(p)==digest,name
geometry=json.loads((source/'source/geometry.json').read_text())
reopen=json.loads((source/'reopen/reopen.json').read_text())
assert reopen['packed_images']==9 and len(reopen['imports'])==6
exports={}
for key,row in geometry.items():
    imported=reopen['imports'][key+'.glb']
    assert row['triangles']==imported['triangles'] and row['degenerates']==imported['degenerates']==0
    assert len(row['scar_depths_m'])==4 and all(abs(d-.038)<.00001 for d in row['scar_depths_m'])
    lo,hi=row['bounds_blender']
    assert lo[2]==0 and hi[2]<=2 and all(abs(v)<=.48 for v in lo[:2]+hi[:2])
    blob=(source/'runtime'/(key+'.glb')).read_bytes()
    magic,version,total=struct.unpack_from('<III',blob);size,kind=struct.unpack_from('<II',blob,12)
    assert magic==0x46546c67 and version==2 and total==len(blob) and kind==0x4e4f534a
    gltf=json.loads(blob[20:20+size]);primitives=gltf['meshes'][0]['primitives']
    assert len(primitives)==5 and all(p.get('mode',4)==4 for p in primitives)
    assert sum(gltf['accessors'][p['indices']]['count']//3 for p in primitives)==row['triangles']
    assert sha(source/'runtime'/(key+'.glb'))==sha(review/'game/assets/authored/e2'/(key+'.glb'))
    exports[key]={'triangles':row['triangles'],'surfaces':len(primitives),'bytes':len(blob),'sha256':sha(source/'runtime'/(key+'.glb'))}
for detail in ['near','middle','far']:
    assert geometry['forge_basic_'+detail]['shared_common_geometry_sha256']==geometry['forge_improved_'+detail]['shared_common_geometry_sha256']
for p in Path(__file__).parent.glob('*.py'):ast.parse(p.read_text(),filename=str(p))
base=current['base'];changed=[];unchanged=0
paths=subprocess.check_output(['git','-C',str(ROOT),'ls-tree','-r','--name-only',base,'game','data'],text=True).splitlines()
for name in paths:
    before=subprocess.check_output(['git','-C',str(ROOT),'show',base+':'+name])
    after=(review/name).read_bytes()
    if before.replace(b'\r\n',b'\n')!=after.replace(b'\r\n',b'\n'):changed.append(name)
    else:unchanged+=1
assert sorted(changed)==['game/art/station_look.gd','game/project.godot','game/scripts/station_site.gd'],changed
checks={}
for backend in ['forward_plus','gl_compatibility']:
    for name,count in [('checks',162),('restore',12),('benchmark',137)]:
        row=json.loads((review/'evidence'/backend/(name+'.json')).read_text())
        assert row['failures']==0 and row['checks']==count,(backend,name)
        checks[backend+'/'+name]={'checks':count,'failures':0}
    assert len(list((review/'evidence'/backend).glob('motion-*.png')))==60
data={'base':base,'dependencies':current['dependencies'],'original_sources_unchanged':len(original['sources']),
      'native_copy_changed_files':changed,'native_copy_unchanged_files':unchanged,'runtime':exports,
      'master_sha256':sha(source/'source/e2_forges.blend'),'checks':checks,
      'map_png_bytes':sum(p.stat().st_size for p in (review/'game/e2/textures').glob('*.png'))}
output.write_text(json.dumps(data,indent=2)+'\n')
print('E2_FINAL_AUDIT_OK',json.dumps(data))
