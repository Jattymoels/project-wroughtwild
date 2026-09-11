"""Freeze one current game/native revision and install E2 only in that copy."""
import json, re, shutil, subprocess, sys, zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3];BASE='0f35e87c6a23e3197bec968fa4443c8e134317b3'
out,source,native,inputs=[Path(p).resolve() for p in sys.argv[1:5]]
assert out.is_relative_to(ROOT/'build/art07/e2');out.mkdir(parents=True,exist_ok=False)
subprocess.run(['git','-C',str(ROOT),'archive','--format=zip','--output='+str(out/'frozen.zip'),BASE,'game','data'],check=True)
with zipfile.ZipFile(out/'frozen.zip') as z:z.extractall(out)
game=out/'game';local=game/'e2';local.mkdir();asset=game/'assets/authored/e2';asset.mkdir()
shutil.copytree(inputs/'textures',local/'textures')
for p in (source/'runtime').glob('*.glb'):shutil.copy2(p,asset/p.name)
for p in Path(__file__).parent.iterdir():
    if p.suffix in ['.gd','.gdshader'] or p.name=='appearance.json':shutil.copy2(p,local/p.name)
shutil.copy2(source/'source/geometry.json',local/'geometry.json')
shutil.copy2(native/'bin/libwroughtwild_sim.windows.x86_64.dll',game/'bin/libwroughtwild_sim.windows.x86_64.dll')
p=game/'project.godot';s=p.read_text();s=s.replace('[application]','[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="E2Native"');p.write_text(s)
p=game/'art/station_look.gd';s=p.read_text();s=s.replace('func mesh_for(id: StringName) -> ArrayMesh:\n','func mesh_for(id: StringName) -> ArrayMesh:\n\tif id in [&"forge_basic", &"forge_improved"]: return E2ForgeArt.mesh_for(id)\n');p.write_text(s)
p=game/'scripts/station_site.gd';s=p.read_text();needle='\t\t_mesh.position = Vector3.ZERO\n';assert s.count(needle)==1
s=s.replace(needle,needle+'\t\tif station_id == &"forge_basic": E2ForgeArt.mount(self)\n');p.write_text(s)
(game/'e2/review.tscn').write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://e2/review.gd" id="1"]\n[node name="E2Review" type="Node3D"]\nscript = ExtResource("1")\n')
(out/'provenance.json').write_text(json.dumps({'base':BASE,'native':json.loads((native/'provenance.json').read_text()),'patches':['art/station_look.gd: E2 mesh dispatch only','scripts/station_site.gd: attach read-only state view'],'scope':'isolated copy only; original game/data/sim unchanged'},indent=2))
print('E2_REVIEW_PREPARED',out)
