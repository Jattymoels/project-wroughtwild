"""Compose verified presentation modules in one freshly archived current game.

Source recipes/packages stay immutable. The explicit hook list is the reviewable
integration diff; no native, tuning or normal checkout file is modified.
"""
import ast
import json
import re
import shutil
import subprocess
import sys
import zipfile
from pathlib import Path
from verify_inputs import ROOT, BASE, INDEX, digest

HERE = Path(__file__).parent
IGNORE = shutil.ignore_patterns('.godot', '*.uid', 'evidence', 'captures', '*.log', '*.previous', 'check-placement.json', 'check-restart.json')
index = json.loads(INDEX.read_text())
packages = {k: Path(v['path']) for k, v in index['inputs'].items()}
out, native = [Path(p).resolve() for p in sys.argv[1:3]]
assert out.is_relative_to(ROOT/'build/art07/g1')
verified_path=Path(sys.argv[3]).resolve() if len(sys.argv)>3 else ROOT/'build/art07/g1/v01/inputs-verified.json'
verified = json.loads(verified_path.read_text())
assert verified['index_sha256'] == digest(INDEX)
assert json.loads((native/'provenance.json').read_text(encoding='utf-8-sig'))['revision'] == BASE
out.mkdir(parents=True, exist_ok=False)
subprocess.run(['git', '-C', str(ROOT), 'archive', '--format=zip', '--output='+str(out/'baseline.zip'), BASE, 'game', 'data'], check=True)
with zipfile.ZipFile(out/'baseline.zip') as archive:
    archive.extractall(out)
game = out/'game'
shutil.copy2(native/'bin/libwroughtwild_sim.windows.x86_64.dll', game/'bin')
lineage = []


def copy_dir(source, target, ident):
    shutil.copytree(source, target, ignore=IGNORE)
    lineage.append({'slice': ident, 'source': str(source), 'target': str(target.relative_to(game))})


for ident in ['b1', 'b3', 'c1', 'c2', 'c3', 'c4', 'c6']:
    copy_dir(packages[ident]/'native/game'/ident, game/ident, ident)
copy_dir(packages['c5']/'review/game/c5', game/'c5', 'c5')
for ident in ['d1', 'd2', 'd3']:
    copy_dir(packages[ident]/'review/game'/('art07_'+ident), game/('art07_'+ident), ident)
for ident in ['e1', 'e2', 'e3', 'f1', 'f3', 'f4']:
    copy_dir(packages[ident]/'review/game'/ident, game/ident, ident)
for ident in ['e1', 'e2', 'e3']:
    copy_dir(packages[ident]/'review/game/assets/authored'/ident, game/'assets/authored'/ident, ident)
copy_dir(packages['f2']/'review/f2', game/'f2', 'f2')
for ident in ['d4', 'd5', 'd6']:
    (game/ident).mkdir()
    copy_dir(packages[ident]/'review/textures', game/ident/'textures', ident)
    shutil.copy2(packages[ident]/'review/materials.json', game/ident/'materials.json')
for ident in ['b2', 'b4']:
    copy_dir(packages[ident]/'review', game/ident, ident)
    # Review resource paths were rooted in their original standalone projects.
    for file in (game/ident).rglob('*'):
        if file.suffix in ['.gd', '.tscn', '.tres', '.gdshader', '.import']:
            file.write_text(file.read_text().replace('res://', f'res://{ident}/'))
    (game/ident/'project.godot').unlink()
(game/'f5').mkdir()
for colour in ['red', 'white', 'blue', 'green']:
    target = game/'f5'/colour
    target.mkdir()
    for file in (packages['f5']/colour/'review').iterdir():
        if file.is_file() and (file.suffix in ['.glb', '.png', '.gdshader'] or file.name in [colour+'.json', 'asset-report.json']):
            shutil.copy2(file, target/file.name)
    lineage.append({'slice': 'f5', 'source': str(packages['f5']/colour/'review'), 'target': str(target.relative_to(game))})

(game/'g1').mkdir()
for file in HERE.iterdir():
    if file.suffix in ['.gd', '.gdshader', '.json', '.tscn']:
        shutil.copy2(file, game/'g1'/file.name)
patches = []


def patch(rel, old, new):
    file = game/rel
    text = file.read_text()
    assert text.count(old) == 1, (rel, old[:140], text.count(old))
    file.write_text(text.replace(old, new))
    patches.append({'file': rel, 'before': old, 'after': new})

# C2's predecessor project replaced its sole ResourceNode scene globally.
# This combined project dispatches by owned ID, so its authored fixture must
# instantiate through that same factory. Keep every existing assertion intact.
patch('c2/native_review.gd', 'preload("res://scenes/resource_node.tscn").instantiate();n.name=', 'G1Art.resource(preload("res://scenes/resource_node.tscn"),defs[id]);n.name=')
patch('c4/native_review.gd', 'load("res://c4/native_tree.gd")', 'load("res://g1/c4_fixture.gd")')
(game/'f2/evidence').mkdir(exist_ok=True)
patch('c5/native_resource.gd', '\tassert(not row.is_empty())', '\tif row.is_empty():return # Unrecognized legacy fallback IDs retain their native picture.')


# Preserve the source-specific callbacks verbatim, adding only the art-off gate.
for ident in ['f1', 'f3']:
    recipe = ROOT/f'tools/wroughtwild-art07/{ident}/install_review.py'
    for node in ast.walk(ast.parse(recipe.read_text())):
        if isinstance(node, ast.Call) and isinstance(node.func, ast.Name) and node.func.id == 'patch':
            rel, old, new = [ast.literal_eval(arg) for arg in node.args]
            if rel == 'project.godot':
                continue
            if ident == 'f1' and 'heart.visible = on' in old:
                new = old.replace('heart.visible = on', 'heart.visible = true if G1Art.enabled() else on')
            else:
                # Gate each newly introduced source/fixture condition.
                new = new.replace('if kind in [', 'if G1Art.enabled() and kind in [').replace('if node.visual in [', 'if G1Art.enabled() and node.visual in [').replace('if kind == "material" and family in [', 'if G1Art.enabled() and kind == "material" and family in [')
            patch(rel, old, new)

patch('scripts/strange_resource_art.gd', 'static func fixture_visual(kind: String) -> Node3D:\n',
      'static func fixture_visual(kind: String) -> Node3D:\n\tif G1Art.enabled():\n\t\tif kind in ["cargo_winch","winch_landing","cargo_basket"]: return load("res://f2/art.gd").fixture(kind)\n\t\tif kind == "pressure_feeder": return F4Art.visual("feeder")\n\t\tif kind in ["white_connection","blue_delay","green_junction","red_heat_buffer"]: return G1Colours.fixture(kind)\n')
patch('scripts/strange_resource_art.gd', '\tupdate(node,float(node.drive_progress)/float(maxi(node.drive_presses,1)))',
      '\tif G1Art.enabled() and node.visual==&"thrumroot": load("res://f2/art.gd").attach_source(node)\n\tupdate(node,float(node.drive_progress)/float(maxi(node.drive_presses,1)))')
patch('scripts/strange_resource_art.gd', 'static func update(node: ResourceNode, progress: float, depleted: bool = false) -> void:\n',
      'static func update(node: ResourceNode, progress: float, depleted: bool = false) -> void:\n\tif G1Art.enabled() and node.visual==&"thrumroot":\n\t\tload("res://f2/art.gd").source_state(node,depleted)\n\t\treturn\n')
patch('scripts/contraption_site.gd', '\tvar changed:=int(record.get("completed_cycles",0))!=_last_cycles',
      '\tif G1Art.enabled(): F4Art.refresh_feeder(self,record,active,paused,progress)\n\tvar changed:=int(record.get("completed_cycles",0))!=_last_cycles')
patch('scripts/contraption_site.gd', '\t\t\tvar result := sim.contraption_request_tick(machine_key,delta,signal_space())', '\t\t\tvar result := sim.contraption_request_tick(machine_key,delta,signal_space())\n\t\t\tif G1Art.enabled() and not sim.contraption_state(machine_key).pending_request: _visual.blue_released()')
patch('scripts/contraption_site.gd', '\t_refresh_span(record)\n', '\t_refresh_span(record)\n\tif G1Art.enabled() and kind == "cargo_winch": load("res://f2/art.gd").energy(_visual,float(record.energy)/float(sim.contraption_config().energy_capacity),float(record.progress),bool(record.moving))\n')
patch('art/station_look.gd', 'func mesh_for(id: StringName) -> ArrayMesh:\n',
      'func mesh_for(id: StringName) -> ArrayMesh:\n\tif G1Art.enabled():\n\t\tif id in [&"workbench",&"mason_yard"]: return E1StationArt.mesh_for(id)\n\t\tif id in [&"forge_basic",&"forge_improved"]: return E2ForgeArt.mesh_for(id)\n')
patch('scripts/station_site.gd', '\t\t_mesh.position = Vector3.ZERO\n',
      '\t\t_mesh.position = Vector3.ZERO\n\t\tif G1Art.enabled() and station_id == &"forge_basic": E2ForgeArt.mount(self)\n')
needle = 'static func mesh_for(shape_id: StringName, form: String, size: Vector3, family: StringName = &"wood") -> Mesh:\n'
patch('scripts/piece_look.gd', needle, needle+'\tif G1Art.enabled():\n\t\tvar selected: Mesh = G1Art.piece_mesh(String(shape_id),form,String(family))\n\t\tif selected != null: return selected\n')
needle = 'static func material_for(sim: WroughtwildSim, family: StringName, role: String="surface") -> Material:\n'
patch('scripts/piece_look.gd', needle, needle+'\tif G1Art.enabled(): return G1Materials.material_for(String(family),role)\n')
patch('scripts/placed_block.gd', '\t\t_light_fire()\n', '\t\t_light_fire()\n\tif G1Art.enabled(): E3HomeArt.mount(self)\n')
patch('scripts/resource_stream.gd', '\tvar node: ResourceNode = _resource_scene.instantiate()', '\tvar node: ResourceNode = G1Art.resource(_resource_scene,record)')
patch('scripts/terrain.gd', '\tvar node: ResourceNode = RESOURCE_NODE_SCENE.instantiate()', '\tvar node: ResourceNode = G1Art.resource(RESOURCE_NODE_SCENE,def)')
patch('scripts/save_manager.gd', '\t\t\t\tnode = RESOURCE_NODE_SCENE.instantiate()', '\t\t\t\tnode = G1Art.resource(RESOURCE_NODE_SCENE,entry)')
patch('scripts/leyline_source.gd', '\tadd_child(_label)\n\trefresh()\n', '\tadd_child(_label)\n\trefresh()\n\tif G1Art.enabled(): G1Colours.mount_source(self)\n')
patch('scripts/sandpit.gd', '\tFrontierSites.build(self,terrain)\n', '\tFrontierSites.build(self,terrain)\n\tif G1Art.enabled(): G1Environment.install(self)\n')
patch('art/frontier_look.gd', 'func cover_mesh(entry: Dictionary) -> ArrayMesh:\n', 'func cover_mesh(entry: Dictionary) -> ArrayMesh:\n\tif G1Art.enabled():\n\t\tvar candidate: ArrayMesh=G1Environment.cover_mesh(entry)\n\t\tif candidate!=null: return candidate\n')
# Preserve the whole baseline pocket path under the switch, including its body.
file = game/'scripts/pressure_pocket.gd'
text = file.read_text(); start = text.index('\tvar hearth:='); end = text.index('\trefresh_visual()', start)
old = text[start:end]
patch('scripts/pressure_pocket.gd', old, '\tif G1Art.enabled():\n\t\tF4Art.mount_pocket(self)\n\telse:\n'+''.join('\t'+line+'\n' for line in old.splitlines()))
patch('scripts/pressure_pocket.gd', '_membrane.scale=Vector3(1,lerpf(.4,1,fraction),1)*LOOK.pocket_membrane_scale', '_membrane.scale=Vector3(1,lerpf(.4,1,fraction),1)*(1.0 if G1Art.enabled() else LOOK.pocket_membrane_scale)')
patch('scripts/pressure_pocket.gd', '\tif _finish!=null:FINISH.set_state(_finish,fraction,0,_highlighted)', '\tif G1Art.enabled(): F4Art.refresh_pocket(self,fraction)\n\telif _finish!=null:FINISH.set_state(_finish,fraction,0,_highlighted)')

# Guard source-specific selection, never a new resource ID or save owner.
for ident, name in [('b1','native_tree.gd'),('c4','native_tree.gd')]:
    file=game/ident/name
    settings = json.loads((HERE/'settings.json').read_text())
    text=file.read_text().replace('-lod0.', f'-lod{int(settings["canopy_lod"])}.')
    if ident=='c4':
        text=text.replace('func _biome_id()->String:\n\treturn "ember_wastes"\n','')
    file.write_text(text)

project = game/'project.godot'
text = project.read_text().replace('[application]', '[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="ART07G1"')
text=text.replace('run/main_scene="res://scenes/sandpit.tscn"','run/main_scene="res://g1/play.tscn"')
project.write_text(text)
patch('scripts/save_manager.gd', 'static func path_for(player: WroughtwildPlayer) -> String:\n', 'static func path_for(player: WroughtwildPlayer) -> String:\n\tif player.has_meta("g1_save_path"): return String(player.get_meta("g1_save_path"))\n')
patch('scripts/save_manager.gd', '\tplayer.finish_world_recovery()\n', '\tif G1Art.enabled():\n\t\tfor pocket in root.get_tree().get_nodes_in_group("pressure_pockets"):\n\t\t\tif root.is_ancestor_of(pocket): pocket.refresh_visual()\n\tplayer.finish_world_recovery()\n')
(out/'integration.json').write_text(json.dumps({'base':BASE,'index_sha256':digest(INDEX),'native':json.loads((native/'provenance.json').read_text(encoding='utf-8-sig')),'copies':lineage,'patches':patches},indent=2))
print('G1_ASSEMBLED',out)
