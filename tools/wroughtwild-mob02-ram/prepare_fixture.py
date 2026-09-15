"""Prepare a tiny disposable Godot project from the selected runtime export."""
import json,shutil,sys
from pathlib import Path
repo=Path(__file__).resolve().parents[2]
dest=Path(sys.argv[1]).resolve()
dest.mkdir(parents=True,exist_ok=True)
(dest/'ram').mkdir(exist_ok=True)
for name in ['model.glb','base.png','orm.png','scar-mask.png']:
    shutil.copyfile(repo/'game/assets/authored/roster/stone_husk'/name,dest/'ram'/name)
shutil.copyfile(repo/'game/tests/mob02/fixture.gd',dest/'fixture.gd')
shutil.copyfile(repo/'tools/wroughtwild-roster/surface_scar.gdshader',dest/'surface_scar.gdshader')
(dest/'project.godot').write_text('''config_version=5
[application]
config/name="MOB02RamSourceFixture"
run/main_scene="res://fixture.tscn"
config/use_custom_user_dir=true
config/custom_user_dir_name="MOB02RamSourceFixture"
[display]
window/size/viewport_width=1080
window/size/viewport_height=648
window/size/window_width_override=1080
window/size/window_height_override=648
window/size/no_focus=true
window/vsync/vsync_mode=0
[rendering]
renderer/rendering_method="forward_plus"
textures/default_filters/use_nearest_mipmap_filter=false
''')
(dest/'fixture.tscn').write_text('''[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://fixture.gd" id="1"]
[node name="RamFixture" type="Node3D"]
script = ExtResource("1")
''')
print(str(dest))
