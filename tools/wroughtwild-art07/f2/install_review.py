"""F2 presentation hooks in a frozen COPY only. Main game is never changed."""
import sys,json,shutil
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3];HERE=Path(__file__).resolve().parent
game,devices,source=map(lambda s:Path(s).resolve(),sys.argv[1:])
assert game.is_relative_to(ROOT/'build/art07/f2');assert (game/'project.godot').exists()
dest=game/'f2';dest.mkdir(exist_ok=True);assets=dest/'assets';assets.mkdir(exist_ok=True)
for folder,names in [(devices,['winch.glb','landing.glb','basket.glb','recovered-coil.glb','geometry.json']),(source,['thrumroot-near.glb','thrumroot-middle.glb','thrumroot-far.glb','thrumroot-albedo.png','geometry.json'])]:
    for name in names:shutil.copy2(folder/name,assets/(folder.name+'-'+name if name=='geometry.json' else name))
for name in ['art.gd','review.gd','source.gdshader','energy.gdshader']:shutil.copy2(HERE/name,dest/name)
(dest/'review.tscn').write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://f2/review.gd" id="1"]\n[node name="F2Review" type="Node3D"]\nscript = ExtResource("1")\n')
(dest/'evidence').mkdir(exist_ok=True)
p=game/'scripts/strange_resource_art.gd';text=p.read_text()
if 'F2 presentation hook' not in text:
    text=text.replace('static func fixture_visual(kind: String) -> Node3D:\n','static func fixture_visual(kind: String) -> Node3D:\n\t# F2 presentation hook, isolated copy only.\n\tif kind in ["cargo_winch","winch_landing","cargo_basket"]: return preload("res://f2/art.gd").fixture(kind)\n')
    text=text.replace('\tupdate(node,float(node.drive_progress)/float(maxi(node.drive_presses,1)))','\tif node.visual==&"thrumroot": preload("res://f2/art.gd").attach_source(node)\n\tupdate(node,float(node.drive_progress)/float(maxi(node.drive_presses,1)))',1)
    text=text.replace('static func update(node: ResourceNode, progress: float, depleted: bool = false) -> void:\n','static func update(node: ResourceNode, progress: float, depleted: bool = false) -> void:\n\tif node.visual==&"thrumroot":\n\t\tpreload("res://f2/art.gd").source_state(node,depleted)\n\t\treturn\n')
    p.write_text(text)
p=game/'project.godot';text=p.read_text();import re
text=re.sub(r'run/main_scene=.*','run/main_scene="res://f2/review.tscn"',text)
text=re.sub(r'config/custom_user_dir_name=.*','config/custom_user_dir_name="F2Native"',text)
text=re.sub(r'window/size/viewport_width=.*','window/size/viewport_width=1440',text);text=re.sub(r'window/size/viewport_height=.*','window/size/viewport_height=900',text)
p.write_text(text)
print('F2_REVIEW_INSTALLED',game)
