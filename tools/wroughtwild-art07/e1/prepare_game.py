"""Current game/data/native plus E1 presentation only, in a disposable copy."""
import json, shutil, subprocess, sys, zipfile
from pathlib import Path
from inputs import BASE, ROOT, PACKAGES
out,models,native,inputs=[Path(p).resolve() for p in sys.argv[1:5]]
assert out.is_relative_to(ROOT/'build/art07/e1');out.mkdir(parents=True,exist_ok=False)
subprocess.run(['git','-C',str(ROOT),'archive','--format=zip','--output='+str(out/'frozen.zip'),BASE,'game','data'],check=True)
with zipfile.ZipFile(out/'frozen.zip') as z:z.extractall(out)
game=out/'game';local=game/'e1';local.mkdir();asset=game/'assets/authored/e1';asset.mkdir()
shutil.copytree(inputs/'textures',local/'textures')
for p in (models/'runtime').glob('*.glb'):shutil.copy2(p,asset/p.name)
for p in Path(__file__).parent.glob('*.gd'):shutil.copy2(p,local/p.name)
shutil.copy2(models/'source/geometry.json',local/'geometry.json')
shutil.copy2(Path(__file__).with_name('stations.json'),local/'stations.json')
shutil.copy2(native/'bin/libwroughtwild_sim.windows.x86_64.dll',game/'bin/libwroughtwild_sim.windows.x86_64.dll')
p=game/'project.godot';s=p.read_text().replace('[application]','[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="E1Native"');p.write_text(s)
p=game/'art/station_look.gd';s=p.read_text();needle='func mesh_for(id: StringName) -> ArrayMesh:\n';assert needle in s
p.write_text(s.replace(needle,needle+'\tif id in [&"workbench", &"mason_yard"]: return E1StationArt.mesh_for(id)\n'))
# D1's checked shape geometry is exercised by the actual corners. Materials and
# collision remain the native pieces. E1 does not republish D1 source geometry.
d1=game/'art07_d1';(d1/'assets').mkdir(parents=True)
shutil.copy2(ROOT/'tools/wroughtwild-art07/d1/adapter.gd',d1/'adapter.gd')
p=d1/'adapter.gd';s=p.read_text();start=s.index('const IDS :=');end=s.index('\n',start)
p.write_text(s[:start]+'const IDS := ["wall_panel","floor_slab"]'+s[end:])
for id in ['wall_panel','floor_slab']:
 shutil.copy2(PACKAGES['d1'][0]/f'review/game/art07_d1/assets/{id}.glb',d1/'assets'/f'{id}.glb')
p=game/'scripts/piece_look.gd';s=p.read_text();needle='static func mesh_for(shape_id: StringName, form: String, size: Vector3, family: StringName = &"wood") -> Mesh:\n';assert needle in s
p.write_text(s.replace(needle,needle+'\tif String(shape_id) in preload("res://art07_d1/adapter.gd").IDS: return preload("res://art07_d1/adapter.gd").mesh_for(String(shape_id))\n',1))
(local/'review.tscn').write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://e1/review.gd" id="1"]\n[node name="E1Review" type="Node3D"]\nscript = ExtResource("1")\n')
for folder in ['cataclysm','codex-aesthetic','strange-frontier','intensives']:(out/'build'/folder).mkdir(parents=True,exist_ok=True)
(out/'provenance.json').write_text(json.dumps({'base':BASE,'native':json.loads((native/'provenance.json').read_text()),'patches':['E1 station mesh dispatch','D1 wall/slab mesh dispatch'],'scope':'isolated presentation; no gameplay changes'},indent=2))
print('E1_REVIEW_PREPARED',out)
