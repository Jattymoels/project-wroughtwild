extends Node3D
## Native authored two-tree fixture, not generated geography or paid campaign play.
var player:WroughtwildPlayer
var sim:WroughtwildSim
var manager:=SaveManager.new()
var camera:Camera3D
var nodes:Array=[]
var fits:Array=[]
var output:="res://b1/evidence/"
var rendered:=false
var caption:Label
var checks:=0
func check(value:bool,label:String)->void:
	checks+=1
	if not value:push_error("B1_NATIVE_FAIL "+label);get_tree().quit(1)
	assert(value,label)

func _ready()->void:
	rendered=DisplayServer.get_name()!="headless"
	output+=RenderingServer.get_current_rendering_method() if rendered else "headless"
	DirAccess.make_dir_recursive_absolute(output)
	player=preload("res://scenes/player.tscn").instantiate();add_child(player);player.class_panel.choose("warden")
	player.set_physics_process(false);player.placement.set_physics_process(false);player.combat.set_physics_process(false);player.hud.hide();player.position=Vector3(0,1.1,3)
	sim=player.inventory.get_sim()
	var defs:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://../data/tuning/worldgen.json")).nodes
	for id in ["tree","pine"]:
		var node:ResourceNode=preload("res://scenes/resource_node.tscn").instantiate();node.set_script(load("res://b1/native_tree.gd"));node.source_kind="broadleaf" if id=="tree" else "pine"
		node.name="b1_"+id;node.resource_id=id;node.visual=defs[id].visual;node.material_family=defs[id].material_family;node.remaining_units=defs[id].units;node.units_per_harvest=defs[id].units_per_harvest;node.drive_presses=defs[id].drive_presses
		node.position=Vector3(-3 if id=="tree" else 3,0,0);add_child(node);nodes.append(node);fits.append(node.get_meta("b1_fit"))
		check(node.get_node("CollisionShape3D").shape.size==Vector3(.7,3,.7),"native authored-fixture body unchanged")
	var floor:=MeshInstance3D.new();floor.mesh=PlaneMesh.new();floor.mesh.size=Vector2(50,50);add_child(floor);var floor_mat:=StandardMaterial3D.new();floor_mat.albedo_color=Color(.20,.24,.14);floor.material_override=floor_mat
	var env:=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color(.28,.36,.43);env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_energy=.75;env.environment.ambient_light_color=Color(.8,.85,1);add_child(env)
	var sun:=DirectionalLight3D.new();sun.light_energy=1.8;sun.rotation_degrees=Vector3(-42,-30,0);sun.shadow_enabled=true;add_child(sun)
	camera=Camera3D.new();add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=11.5;camera.position=Vector3(11,6,15);camera.look_at(Vector3(0,4,0));camera.make_current()
	var canvas:=CanvasLayer.new();add_child(canvas);caption=Label.new();canvas.add_child(caption);caption.position=Vector2(18,18);caption.add_theme_font_size_override("font_size",18)
	for i in 8:await get_tree().physics_frame
	if "--restore-partial" in OS.get_cmdline_user_args():
		check(manager.read("user://b1-partial.json",player),"fresh process loads partial checkpoint")
		for n in nodes:check(n.drive_progress==3 and n.remaining_units==14,"partial work and finite stock exact")
		check(sim.material_count("wood")==0 and sim.material_count("pine")==0,"no premature inventory on restart")
		finish();return
	if "--restore-final" in OS.get_cmdline_user_args():
		check(manager.read("user://b1-final.json",player),"fresh process loads depleted checkpoint")
		check(get_tree().get_nodes_in_group("resources").is_empty(),"depleted native identities absent")
		check(get_tree().get_nodes_in_group("b1_session_stumps").is_empty(),"session-only stumps absent on fresh load")
		check(sim.material_count("wood")==14 and sim.material_count("pine")==14,"exact two families survive reload")
		finish();return
	for node in nodes:
		for i in 3:player._apply_work(node,node.work(sim))
		check(node.drive_progress==3 and node.remaining_units==14,"partial work on new visual keeps full stock")
	check(manager.write("user://b1-partial.json",player),"write partial native checkpoint")
	var saved:=manager.capture(player)
	check(manager.apply(player,JSON.parse_string(JSON.stringify(saved))),"restore partial checkpoint in place")
	check(manager.capture(player).resource_nodes==saved.resource_nodes,"exact native IDs, positions and partial work")
	if rendered:await shot("full-partial")
	for node in nodes:
		for i in 3:player._apply_work(node,node.work(sim))
		check(node.remaining_units==0,"native felling spends finite stock")
		check(node.harvest()==0,"repeat depletion cannot yield")
	for frame in 84:
		await get_tree().physics_frame
		if rendered and frame%2==0:await shot("fall-%03d"%(frame/2))
	check(get_tree().get_nodes_in_group("resources").is_empty(),"native felling frees both resources")
	check(get_tree().get_nodes_in_group("b1_session_stumps").size()==2,"one matching inert stump per tree")
	# Normal absorption entry point, posed close collection to isolate ownership from travel.
	for pickup in get_tree().get_nodes_in_group("pickups"):
		if pickup is Pickup:pickup._absorb(player)
	# Pickup scenes are not required to use that group; traverse the actual owned scene set.
	for child in get_children():
		if child is Pickup and not child.is_queued_for_deletion():child._absorb(player)
	check(sim.material_count("wood")==14 and sim.material_count("pine")==14,"one exact fourteen-unit payout per family")
	check(manager.write("user://b1-final.json",player),"save exact final native ownership")
	if rendered:await shot("stumps")
	finish()

func shot(name:String)->void:
	caption.text="ART-07B1 native finite-tree fixture | "+name+"\nCompact body fit; full-width source review is separate"

	await RenderingServer.frame_post_draw
	check(get_viewport().get_texture().get_image().save_png(output+"/"+name+".png")==OK,"actual native capture")

func finish()->void:
	var file:=FileAccess.open(output+"/native-"+("partial-restart" if "--restore-partial" in OS.get_cmdline_user_args() else ("final-restart" if "--restore-final" in OS.get_cmdline_user_args() else "flow"))+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":0,"fit":fits,"wood":sim.material_count("wood"),"pine":sim.material_count("pine"),"fixture":"Authored current native rules; normal _apply_work, fall tween and _absorb. Compact body-fit presentation only; no normal-world adoption."},"\t"))
	print("B1_NATIVE_OK ",checks);get_tree().quit()
