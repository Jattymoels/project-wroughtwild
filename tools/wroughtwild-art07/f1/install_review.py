"""Install F1-only presentation into a frozen, disposable game copy."""
import shutil,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3];TOOL=Path(__file__).resolve().parent
game=Path(sys.argv[1]).resolve();assets=Path(sys.argv[2]).resolve()
assert game.is_relative_to(ROOT/'build/art07/f1')
dest=game/'f1';dest.mkdir(exist_ok=False);(dest/'assets').mkdir()
for p in assets.glob('*.glb'):shutil.copy2(p,dest/'assets'/p.name)
for name in ['visuals.gd','scar.gdshader','review.gd','settings.json']:shutil.copy2(TOOL/name,dest/name)
def patch(rel,old,new):
    p=game/rel;t=p.read_text();assert t.count(old)==1,(rel,old);p.write_text(t.replace(old,new))
patch('scripts/strange_resource_art.gd','static func fixture_visual(kind: String) -> Node3D:\n','static func fixture_visual(kind: String) -> Node3D:\n\tif kind in ["lantern_lamp","stormglass_lever"]: return load("res://f1/visuals.gd").fitted(kind)\n')
patch('scripts/strange_resource_art.gd','static func attach(node: ResourceNode) -> void:\n','static func attach(node: ResourceNode) -> void:\n\tif node.visual in [&"lanternheart",&"stormglass"]:\n\t\tload("res://f1/visuals.gd").attach_source(node)\n\t\treturn\n')
patch('scripts/strange_resource_art.gd','static func update(node: ResourceNode, progress: float, depleted: bool = false) -> void:\n','static func update(node: ResourceNode, progress: float, depleted: bool = false) -> void:\n\tif node.visual in [&"lanternheart",&"stormglass"]:\n\t\tvar f1root := node.get_node_or_null("StrangeCore")\n\t\tif f1root != null: f1root.source_state(node,progress,depleted)\n\t\treturn\n')
patch('scripts/contraption_site.gd','\tif kind == "lantern_lamp":\n\t\tvar on: bool = record.get("lamp_on", true)\n','\tif kind in ["lantern_lamp","stormglass_lever"] and _visual.has_method("apply_state"): _visual.apply_state(record)\n\tif kind == "lantern_lamp":\n\t\tvar on: bool = record.get("lamp_on", true)\n')
patch('scripts/contraption_site.gd','\t\tif heart != null: heart.visible = on','\t\tif heart != null: heart.visible = true # Recovered solid remains present when shuttered.')
patch('scripts/player.gd','\t# Accepted action results own the sound, not animation/stock refreshes.\n','\tif node.visual in [&"lanternheart",&"stormglass"]:\n\t\tvar f1source := node.get_node_or_null("StrangeCore")\n\t\tif f1source != null: f1source.accepted_source_work()\n\t# Accepted action results own the sound, not animation/stock refreshes.\n')
patch('scripts/pickup.gd','\t_bob_phase = randf() * TAU\n','\t_bob_phase = randf() * TAU\n\tif kind == "material" and family in ["lanternheart","stormglass"]: load("res://f1/visuals.gd").recovered(self)\n')
(dest/'review.tscn').write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://f1/review.gd" id="1"]\n[node name="F1Review" type="Node3D"]\nscript = ExtResource("1")\n')
patch('project.godot','run/main_scene="res://scenes/sandpit.tscn"','run/main_scene="res://f1/review.tscn"')
print('F1_REVIEW_INSTALLED',game)
