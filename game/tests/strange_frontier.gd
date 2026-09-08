extends "res://scripts/sandpit.gd"
## Normal generated-world checks: finite finds, resource activation, recipes,
## exact world restore and the default profile. Native suites cover many seeds.
var checks := 0
var failures := 0
var evidence := {}

func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL STRANGE: ",label)

func _ready() -> void:
	# Preserve this historical v3 regression; cataclysm_intensive checks the new default.
	world_profile = "frontier_v3"
	super._ready()
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.combat.set_physics_process(false)
	player.placement.set_physics_process(false)
	mob_packs.set_physics_process(false)
	mob_packs.set_process(false)
	set_physics_process(false)
	await get_tree().physics_frame
	var sim := _sim()
	check(world_profile=="frontier_v3" and terrain.world_profile()=="frontier_v3","frozen v3 remains selectable")
	check(terrain.map.width==512 and terrain.map.height==512,"bounded larger world")
	check(terrain.map.regions.size()==3,"three broad regional identities")
	check(terrain.map.habitats.size()==3,"existing six building sources remain")
	check(terrain.resource_stream!=null,"resource records are separate from loaded scenes")
	evidence.startup=terrain.build_profile.duplicate(true)
	evidence.total_resource_records=terrain.resource_stream.records.size()
	evidence.active_resource_scenes=terrain.nodes_root.get_child_count()
	check(terrain.nodes_root.get_child_count()<terrain.resource_stream.records.size(),"startup does not instantiate all distant resources")
	var manager := SaveManager.new()
	var original := manager.capture(player)
	check(original.resource_nodes.size()==terrain.resource_stream.records.size(),"save contains unloaded resources")
	var ids := {}
	for row in original.resource_nodes:
		check(not ids.has(row.name),"stable instance ID is unique")
		ids[row.name]=true
	var raw_types := ["lanternheart","thrumroot","stormglass","pullstone","ventlung"]
	var used := {}
	for def in terrain.map.nodes:
		if String(def.type) not in raw_types or used.has(def.type): continue
		used[def.type]=true
		var at:=Vector3(float(def.x)+0.5,float(def.y),float(def.z)+0.5)
		terrain.ensure_area(at,24.0)
		player.global_position=at+Vector3(0,2,3)
		terrain.resource_stream.focus(at,true)
		var node: ResourceNode=terrain.resource_stream.materialise(String(def.resource_id))
		check(node!=null,"rare resource scene can be loaded at its site")
		if node==null: continue
		check(node.tool_item==&"" and node.heat_to_work==0,"every class can use ordinary contextual work")
		check(node.get_node_or_null("StrangeCore")!=null,"rare resource has authored specimen art")
		check(not String(def.get("use_preview","")).is_empty(),"the find communicates a useful payoff")
		var before:=node.remaining_units
		var result: Dictionary={}
		for press in node.drive_presses: result=node.work(sim)
		check(int(result.get("granted",0))>0,"contextual stages grant an intact finite haul")
		check(node.remaining_units<before,"working reduces finite supply")
		if node.remaining_units<=0:
			check(not terrain.resource_stream.has_resource(String(def.resource_id)),"depletion is recorded before scene cleanup")
		await get_tree().process_frame
	check(used.size()==5,"all five discovery loops exist")
	check(manager.apply(player,original),"original world restores after five harvests")
	var partial_id := ""
	for row in original.resource_nodes:
		if String(row.visual)=="thrumroot": partial_id=String(row.name); break
	var partial: ResourceNode=terrain.resource_stream.materialise(partial_id)
	check(partial!=null,"a restored specimen can be revisited")
	if partial!=null:
		partial.drive_progress=2
		var units:=partial.remaining_units
		terrain.resource_stream.focus(Vector3(-1000,0,-1000),true)
		check(not terrain.resource_stream.active.has(partial_id),"distant specimen scene retires")
		var saved:=manager.capture(player)
		check(manager.apply(player,saved),"unloaded partial work restores")
		partial=terrain.resource_stream.materialise(partial_id)
		check(partial.drive_progress==2 and partial.remaining_units==units,"partial harvest survives retirement and save")
	var before_invalid := sim.export_json()
	var corrupt:=manager.capture(player)
	corrupt.contraptions="{\"version\":999}"
	check(not manager.apply(player,corrupt),"malformed machine checkpoint rejected before mutation")
	check(sim.export_json()==before_invalid,"rejected checkpoint retains inventory")
	_check_recipes()
	player.inventory_panel.guide.select_page("Wild finds")
	check(sim.rare_resource_guide().size()==5,"existing guide presents five resource properties")
	var final_snapshot:=manager.capture(player)
	var path:=ProjectSettings.globalize_path("res://../build/strange-frontier/world-checkpoint.json")
	check(DirAccess.make_dir_recursive_absolute(path.get_base_dir()) == OK, "isolated checkpoint directory exists")
	check(manager.write_data(path,final_snapshot),"atomic world and machine save writes")
	check(manager.read(path,player),"atomic world and machine save reads")
	evidence.checks=checks
	evidence.failures=failures
	var file:=FileAccess.open(ProjectSettings.globalize_path("res://../build/strange-frontier/world-checks.json"),FileAccess.WRITE)
	if file!=null: file.store_string(JSON.stringify(evidence,"  ")); file.close()
	print("STRANGE_FRONTIER: ",checks," checks, ",failures," failures; startup ",JSON.stringify(evidence.startup))
	get_tree().quit(0 if failures==0 else 1)

func _check_recipes() -> void:
	var sim:=_sim()
	sim.add_station("workbench")
	for kind in sim.contraption_kinds():
		var recipe: Dictionary=sim.recipe("assemble_"+kind)
		check(not recipe.is_empty(),"fixture has a visible existing-station recipe")
		if recipe.is_empty(): continue
		check(recipe.station=="workbench","fixture needs no new station")
		sim.add_materials(recipe.inputs)
		var before:=sim.material_count(kind+"_kit")
		check(sim.craft("assemble_"+kind).crafted,"ordinary input and rare specimen assemble")
		check(sim.material_count(kind+"_kit")==before+1,"one assembly yields one usable kit")
		check(sim.kit_item_ids().has(kind+"_kit"),"kit is available in B/Tab placement")
		check(StrangeResourceArt.fixture_mesh(kind)!=null,"preview and placed object share authored art")
	for raw in ["lanternheart","thrumroot","stormglass","pullstone","ventlung"]:
		check(not sim.build_material_ids().has(raw),"raw finds do not add wall-material families")
