"""Apply only scoped F3 presentation hooks to a fresh frozen game copy."""
import json,shutil,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3];tool=Path(__file__).resolve().parent
game=Path(sys.argv[1]).resolve();assets=Path(sys.argv[2]).resolve()
assert game.is_relative_to(ROOT/'build/art07/f3')
dest=game/'f3';dest.mkdir(exist_ok=True);(dest/'assets').mkdir(exist_ok=False)
for p in assets.glob('*.glb'):shutil.copy2(p,dest/'assets'/p.name)
for name in ['visuals.gd','scar.gdshader','review.gd','settings.json']:shutil.copy2(tool/name,dest/name)
def patch(rel,old,new):
 p=game/rel;t=p.read_text();assert t.count(old)==1,(rel,old);p.write_text(t.replace(old,new))
patch('scripts/strange_resource_art.gd','static func fixture_visual(kind: String) -> Node3D:\n','static func fixture_visual(kind: String) -> Node3D:\n\tif kind in ["magnetic_sorter","ventlung_bellows"]: return load("res://f3/visuals.gd").fitted(kind)\n')
patch('scripts/strange_resource_art.gd','static func attach(node: ResourceNode) -> void:\n','static func attach(node: ResourceNode) -> void:\n\tif node.visual in [&"pullstone",&"ventlung"]:\n\t\tload("res://f3/visuals.gd").attach_source(node)\n\t\treturn\n')
patch('scripts/strange_resource_art.gd','static func update(node: ResourceNode, progress: float, depleted: bool = false) -> void:\n','static func update(node: ResourceNode, progress: float, depleted: bool = false) -> void:\n\tif node.visual in [&"pullstone",&"ventlung"]:\n\t\tvar f3root := node.get_node_or_null("StrangeCore")\n\t\tif f3root != null: f3root.source_state(node,progress,depleted)\n\t\treturn\n')
# refresh_from_sim also runs immediately after actual actions and restore.
patch('scripts/contraption_site.gd','\tif kind == "lantern_lamp":\n\t\tvar on: bool = record.get("lamp_on", true)\n','\tif kind in ["magnetic_sorter","ventlung_bellows"] and _visual.has_method("apply_state"): _visual.apply_state(record)\n\tif kind == "lantern_lamp":\n\t\tvar on: bool = record.get("lamp_on", true)\n')
patch('scripts/player.gd','\t# Accepted action results own the sound, not animation/stock refreshes.\n','\tif node.visual in [&"pullstone",&"ventlung"]:\n\t\tvar f3source := node.get_node_or_null("StrangeCore")\n\t\tif f3source != null: f3source.accepted_source_work()\n\t# Accepted action results own the sound, not animation/stock refreshes.\n')
(dest/'review.tscn').write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://f3/review.gd" id="1"]\n[node name="F3Review" type="Node3D"]\nscript = ExtResource("1")\n')
patch('project.godot','run/main_scene="res://scenes/sandpit.tscn"','run/main_scene="res://f3/review.tscn"')
print('F3_PRESENTATION_INSTALLED',game)
