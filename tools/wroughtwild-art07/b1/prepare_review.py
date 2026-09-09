"""Prepare a fresh standalone B1 review. Sources are read-only."""
import sys,shutil,json
from pathlib import Path
broadleaf,pine,out=map(Path,sys.argv[1:]);assert not out.exists();(out/'assets').mkdir(parents=True)
source=Path(__file__).parent;depot=Path('C:/Users/Matty/Dev/project-wroughtwild')
for folder in [broadleaf,pine]:
 for p in folder.glob('*.glb'):shutil.copy2(p,out/'assets'/p.name)
 for name in ['kit-report.json','attachment-sockets.json']:shutil.copy2(folder/name,out/(folder.name+'-'+name))
for name in ['kit.json','review.gd','canopy.gdshader']:shutil.copy2(source/name,out/name)
grove=depot/'build/grove-art02/emberroot-handoff/review'
shutil.copy2(grove/'fractured-rock.glb',out/'assets/fractured-rock.glb');shutil.copy2(grove/'forest-floor.png',out/'forest-floor.png')
(out/'project.godot').write_text('''config_version=5
[application]
config/name="Wroughtwild ART-07B1 isolated review"
run/main_scene="res://review.tscn"
[display]
window/size/viewport_width=1440
window/size/viewport_height=900
window/size/window_width_override=1440
window/size/window_height_override=900
window/vsync/vsync_mode=0
[rendering]
renderer/rendering_method="forward_plus"
textures/default_filters/use_nearest_mipmap_filter=false
''')
(out/'review.tscn').write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://review.gd" id="1"]\n[node name="B1Review" type="Node3D"]\nscript=ExtResource("1")\n')
print('B1_REVIEW_PREPARED',out)
