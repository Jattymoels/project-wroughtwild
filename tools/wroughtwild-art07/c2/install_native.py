"""Install C2 visual adapter only in a fresh archived current game copy."""
import sys,shutil
from pathlib import Path
current,review,out=[Path(p).resolve() for p in sys.argv[1:]];assert not out.exists()
shutil.copytree(current,out,ignore=shutil.ignore_patterns('.godot','*.json.previous','*.pending','current.zip','probe.gd','probe.json'))
game=out/'game';target=game/'c2';target.mkdir();recipe=Path(__file__).parent
for n in ['assets','textures']:shutil.copytree(review/n,target/n,ignore=shutil.ignore_patterns('*.import'))
for n in ['native_resource.gd','native_review.gd']:shutil.copy2(recipe/n,target/n)
(target/'native_review.tscn').write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://c2/native_review.gd" id="1"]\n[node name="C2Native" type="Node3D"]\nscript=ExtResource("1")\n')
scene=game/'scenes/resource_node.tscn';text=scene.read_text();assert 'res://scripts/resource_node.gd' in text;scene.write_text(text.replace('res://scripts/resource_node.gd','res://c2/native_resource.gd'))
print('C2_NATIVE_VISUAL_COPY_OK',out)
