"""Install D1 only into a frozen disposable game; refuse normal checkout paths."""
import argparse, json, shutil
from pathlib import Path

ap=argparse.ArgumentParser(); ap.add_argument('--snapshot',type=Path,required=True); ap.add_argument('--models',type=Path,required=True); ap.add_argument('--native',type=Path,required=True)
a=ap.parse_args(); script=Path(__file__).resolve().parent; root=script.parents[2]
snap=a.snapshot.resolve(); assert snap.is_relative_to(root/'build/art07/d1')
target=snap/'game/art07_d1'; assert not target.exists(); target.mkdir()
shutil.copytree(a.models/'assets',target/'assets')
for name in ['adapter.gd','checks.gd','gallery.gd']: shutil.copyfile(script/name,target/name)
for name in ['checks','gallery']:
    (target/(name+'.tscn')).write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://art07_d1/'+name+'.gd" id="1"]\n[node name="D1" type="Node3D"]\nscript = ExtResource("1")\n')
shutil.copyfile(a.models/'geometry.json',target/'geometry.json')
shutil.copyfile(snap.parent/'assigned.json',target/'assigned.json')
shutil.copyfile(a.native/'bin/libwroughtwild_sim.windows.x86_64.dll',snap/'game/bin/libwroughtwild_sim.windows.x86_64.dll')
look=snap/'game/scripts/piece_look.gd'; text=look.read_text()
needle='static func mesh_for(shape_id: StringName, form: String, size: Vector3, family: StringName = &"wood") -> Mesh:\n'
assert needle in text
text=text.replace(needle,needle+'\tif String(shape_id) in preload("res://art07_d1/adapter.gd").IDS:\n\t\treturn preload("res://art07_d1/adapter.gd").mesh_for(String(shape_id))\n',1)
look.write_text(text)
for folder in ['cataclysm','codex-aesthetic','strange-frontier','intensives']: (snap/'build'/folder).mkdir(parents=True,exist_ok=True)
print('D1_ISOLATED_ADAPTER_INSTALLED',snap)
