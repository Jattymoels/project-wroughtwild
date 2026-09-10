"""Fresh isolated review and exact-revision native game; never imports canonical handoffs."""
import sys,json,shutil,subprocess,zipfile
from pathlib import Path
root,kit,out=[Path(p).resolve() for p in sys.argv[1:]];assert not out.exists();out.mkdir(parents=True)
recipe=Path(__file__).parent;review=out/'review';(review/'assets').mkdir(parents=True)
for p in kit.glob('*.glb'):shutil.copy2(p,review/'assets'/p.name)
for name in ['kit.json','scar.gdshader','review.gd','verify_pause.gd']:shutil.copy2(recipe/name,review/name)
grove=Path('C:/Users/Matty/Dev/project-wroughtwild/build/grove-art02/emberroot-handoff/review')
shutil.copy2(grove/'forest-floor.png',review/'forest-floor.png')
(review/'project.godot').write_text('''config_version=5
[application]
config/name="ART-07B3 contact kit review"
run/main_scene="res://review.tscn"
[display]
window/size/viewport_width=1440
window/size/viewport_height=900
window/vsync/vsync_mode=0
[rendering]
renderer/rendering_method="forward_plus"
''')
(review/'review.tscn').write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://review.gd" id="1"]\n[node name="B3Review" type="Node3D"]\nscript=ExtResource("1")\n')
revision='f00d4b76274ef2a73c3b6f4a275d2bd3ca0f958d'
archive=out/'current-game.zip';subprocess.run(['git','archive','--format=zip','--output='+str(archive),revision,'game','data'],check=True)
with zipfile.ZipFile(archive) as z:z.extractall(out/'native')
game=out/'native/game';shutil.copy2(root/'native-v02/bin/libwroughtwild_sim.windows.x86_64.dll',game/'bin/libwroughtwild_sim.windows.x86_64.dll')
shutil.copytree(review/'assets',game/'b3/assets')
for name in ['kit.json','native_resource.gd','native_review.gd']:shutil.copy2(recipe/name,game/'b3'/name)
(game/'b3/native_review.tscn').write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://b3/native_review.gd" id="1"]\n[node name="B3Native" type="Node3D"]\nscript=ExtResource("1")\n')
shutil.copy2(root/'native-v02/provenance.json',out/'native/provenance.json')
print('B3_PREPARED',out)
