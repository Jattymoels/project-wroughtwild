"""Freeze current game/data and native commit; patch E3 only in a fresh copy."""
import json,shutil,subprocess,sys,zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3];BASE='bbcb3a7dfd235e8f803141ccb57c38e03d6c1708'
out,models,native,inputs=[Path(p).resolve() for p in sys.argv[1:5]]
assert out.is_relative_to(ROOT/'build/art07/e3');out.mkdir(parents=True,exist_ok=False)
assert json.loads((native/'provenance.json').read_text())['revision']==BASE
subprocess.run(['git','-C',str(ROOT),'archive','--format=zip','--output='+str(out/'frozen.zip'),BASE,'game','data'],check=True)
with zipfile.ZipFile(out/'frozen.zip') as z:z.extractall(out)
game=out/'game';local=game/'e3';local.mkdir();asset=game/'assets/authored/e3';asset.mkdir()
shutil.copytree(inputs/'textures',local/'textures')
for p in (models/'runtime').glob('*.glb'):shutil.copy2(p,asset/p.name)
for p in Path(__file__).parent.iterdir():
 if p.suffix in ['.gd','.gdshader'] or p.name=='appearance.json':shutil.copy2(p,local/p.name)
shutil.copy2(models/'source/geometry.json',local/'geometry.json')
shutil.copy2(native/'bin/libwroughtwild_sim.windows.x86_64.dll',game/'bin/libwroughtwild_sim.windows.x86_64.dll')
p=game/'project.godot';s=p.read_text();s=s.replace('[application]','[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="E3Native"');p.write_text(s)
p=game/'scripts/piece_look.gd';s=p.read_text();needle='static func mesh_for(shape_id: StringName, form: String, size: Vector3, family: StringName = &"wood") -> Mesh:\n';assert s.count(needle)==1
s=s.replace(needle,needle+'\tif form in ["chest","fire"]: return E3HomeArt.closed(form,family)\n');p.write_text(s)
p=game/'scripts/placed_block.gd';s=p.read_text();needle='\t\t_light_fire()\n';assert s.count(needle)==1;s=s.replace(needle,needle+'\tE3HomeArt.mount(self)\n');p.write_text(s)
(local/'review.tscn').write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://e3/review.gd" id="1"]\n[node name="E3Review" type="Node3D"]\nscript = ExtResource("1")\n')
(out/'provenance.json').write_text(json.dumps({'base':BASE,'native':json.loads((native/'provenance.json').read_text()),'patches':['scripts/piece_look.gd E3 mesh dispatch','scripts/placed_block.gd E3 read-only view mount'],'scope':'isolated game only'},indent=2))
print('E3_GAME_PREPARED',out)
