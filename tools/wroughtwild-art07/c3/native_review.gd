extends Node3D
## Posed current native work/collection and separate-process SaveManager fixture.
var player:WroughtwildPlayer
var sim:WroughtwildSim
var manager:=SaveManager.new()
var camera:Camera3D
var nodes:Array=[]
var checks:=0
var failures:=0
var output:String
var rendered:=false
var label:Label
func check(value:bool,description:String)->void:
	checks+=1
	if not value:failures+=1;push_error("C3_NATIVE_FAIL "+description);get_tree().quit(1)
	assert(value,description)
func _ready()->void:
	rendered=DisplayServer.get_name()!="headless"
	output="res://c3/evidence/"+(RenderingServer.get_current_rendering_method() if rendered else "headless")
	DirAccess.make_dir_recursive_absolute(output)
	player=preload("res://scenes/player.tscn").instantiate();add_child(player);player.class_panel.choose("warden")
	player.set_physics_process(false);player.placement.set_physics_process(false);player.combat.set_physics_process(false);player.hud.hide();player.position=Vector3(0,1.1,4)
	sim=player.inventory.get_sim()
	var defs:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://../data/tuning/worldgen.json")).nodes
	for id in ["resinheart_tree","corkbark_deadfall"]:
		var node:ResourceNode=preload("res://scenes/resource_node.tscn").instantiate();node.set_script(load("res://c3/native_resource.gd"))
		node.name="c3_"+id;node.resource_id="c3_fixture_"+id;node.habitat_id="oldgrowth_grove";node.visual=defs[id].visual;node.material_family=defs[id].material_family;node.remaining_units=defs[id].units;node.units_per_harvest=defs[id].units_per_harvest;node.drive_presses=defs[id].drive_presses
		node.position=Vector3(2 if id=="resinheart_tree" else -2,0,0);node.altered=id=="resinheart_tree";add_child(node);nodes.append(node)
		check(node.get_node("CollisionShape3D").shape.size.is_equal_approx(HabitatResourceArt.bounds_for(node.visual)),"native body retained")
	var floor:=MeshInstance3D.new();floor.mesh=PlaneMesh.new();floor.mesh.size=Vector2(35,35);add_child(floor);floor.create_trimesh_collision()
	var fm:=StandardMaterial3D.new();fm.albedo_color=Color(.16,.19,.10);floor.material_override=fm
	var world:=WorldEnvironment.new();world.environment=Environment.new();world.environment.background_mode=Environment.BG_COLOR;world.environment.background_color=Color(.30,.37,.4);world.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;world.environment.ambient_light_energy=.8;add_child(world)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-40,-30,0);sun.light_energy=1.8;sun.shadow_enabled=true;add_child(sun)
	camera=Camera3D.new();add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=13;camera.position=Vector3(12,6,15);camera.look_at(Vector3(0,4.5,0));camera.make_current()
	var canvas:=CanvasLayer.new();add_child(canvas);label=Label.new();canvas.add_child(label);label.position=Vector2(18,18);label.add_theme_font_size_override("font_size",18)
	for i in 8:await get_tree().physics_frame
	# Work picking is native axis-aligned body; check both actual rays before posing work.
	for n in nodes:
		var target:Vector3=n.position+Vector3.UP*(1.4 if n._is_tree() else .3)
		var hit:=get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(target+Vector3(0,0,2),target))
		check(not hit.is_empty() and hit.collider==n,"native work ray selects its own resource")
	var args:=OS.get_cmdline_user_args()
	if "--restore-partial" in args:
		check(manager.read("user://c3-partial.json",player),"separate process partial load")
		check(nodes[0].remaining_units==24 and nodes[0].drive_progress==3,"tree partial work independent")
		check(nodes[1].remaining_units==12 and nodes[1].drive_progress==1,"bark partial work and stock exact")
		check(sim.material_count("resinheart_log")==0 and sim.material_count("raw_corkbark")==6,"exact intermediate inventory")
		await get_tree().process_frame;check(nodes[1].c3_state==12,"bark layer follows restored native stock")
		finish("partial-restart");return
	if "--restore-final" in args:
		check(manager.read("user://c3-final.json",player),"separate process final load")
		check(get_tree().get_nodes_in_group("resources").is_empty(),"both depleted identities absent")
		check(get_tree().get_nodes_in_group("c3_session_stumps").is_empty(),"native session stump absent after fresh load")
		check(get_tree().get_nodes_in_group("c3_session_bark_remnants").is_empty(),"native bark aftermath absent after fresh load")
		check(sim.material_count("resinheart_log")==24 and sim.material_count("raw_corkbark")==18,"exact final separate-family inventory")
		finish("final-restart");return
	if rendered:await shot("full")
	for i in 3:player._apply_work(nodes[0],nodes[0].work(sim))
	check(nodes[0].drive_progress==3 and nodes[0].remaining_units==24,"three tree chops give no premature output")
	for i in 3:player._apply_work(nodes[1],nodes[1].work(sim))
	absorb();player._apply_work(nodes[1],nodes[1].work(sim))
	check(nodes[1].remaining_units==12 and nodes[1].drive_progress==1,"one bark harvest plus next partial press")
	check(nodes[0].remaining_units==24 and nodes[0].drive_progress==3,"bark work cannot alter tree")
	check(manager.write("user://c3-partial.json",player),"save partial identities/work/inventory")
	var saved:=manager.capture(player);check(manager.apply(player,JSON.parse_string(JSON.stringify(saved))),"in-place restore")
	check(manager.capture(player).resource_nodes==saved.resource_nodes,"exact restored positions and work state")
	if rendered:await shot("partial")
	for i in 2:player._apply_work(nodes[1],nodes[1].work(sim))
	absorb();check(nodes[1].remaining_units==6,"second independent bark yield")
	if rendered:
		camera.size=2.5;camera.position=Vector3(.2,1.3,2.4);camera.look_at(Vector3(-2,.3,0));await shot("bark-six-remain")
	# Let the preceding harvest's native .18 s punch settle before measuring
	# the separate depletion tween. Posed same-frame presses otherwise overlap.
	for i in 16:await get_tree().process_frame
	for i in 3:
		player._apply_work(nodes[1],nodes[1].work(sim))
		if i<2:
			for settle in 16:await get_tree().process_frame
	check(nodes[1].remaining_units==0 and nodes[1].harvest()==0,"exact cork depletion and no repeat payout")
	check(nodes[0].remaining_units==24,"depleted cork leaves live tree")
	var bark_model:Node3D=nodes[1].c3_model
	var bark_scale:Vector3=nodes[1].scale
	for i in 4:await get_tree().process_frame
	check(is_instance_valid(bark_model) and not bark_model.is_queued_for_deletion(),"last bark model retained during native shrink")
	check(nodes[1].scale.length()<bark_scale.length(),"native bark shrink progresses: %s to %s"%[bark_scale,nodes[1].scale])
	if rendered:await shot("cork-depleting")
	for i in 3:player._apply_work(nodes[0],nodes[0].work(sim))
	check(nodes[0].remaining_units==0 and nodes[0].harvest()==0,"tree final chop yields once")
	camera.size=13;camera.position=Vector3(12,6,15);camera.look_at(Vector3(0,4.5,0))
	for i in 84:
		await get_tree().physics_frame
		if rendered and i%2==0:await shot("fall-%03d"%(i/2))
	absorb()
	check(get_tree().get_nodes_in_group("resources").is_empty(),"both spent resource scenes removed")
	check(get_tree().get_nodes_in_group("c3_session_stumps").size()==1,"one inert stump only from tree")
	check(get_tree().get_nodes_in_group("c3_session_bark_remnants").size()==1,"one matching inert native bark aftermath")
	check(sim.material_count("resinheart_log")==24 and sim.material_count("raw_corkbark")==18,"exact yields via native pickup absorption")
	check(manager.write("user://c3-final.json",player),"save settled exact ownership")
	if rendered:
		camera.size=2;camera.position=Vector3(3.2,1.8,1.8);camera.look_at(Vector3(2,.3,0));await shot("amber-stump")
	finish("flow")
func absorb()->void:
	for child in get_children():
		if child is Pickup and not child.is_queued_for_deletion():child._absorb(player)
func shot(name:String)->void:
	label.text="ART-07C3 native finite work | "+name+"\nSeparate tree / bark identities; posed native interaction fixture"
	await RenderingServer.frame_post_draw
	check(get_viewport().get_texture().get_image().save_png(output+"/"+name+".png")==OK,"actual native frame")
func finish(name:String)->void:
	if failures>0:get_tree().quit(1);return
	var file:=FileAccess.open(output+"/"+name+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"resinheart_log":sim.material_count("resinheart_log"),"raw_corkbark":sim.material_count("raw_corkbark"),"state":name,"fixture":"Current native ResourceNode work/fall/pickup and SaveManager; posed actions, no generated route or paid first-hour claim."},"\t"))
	print("C3_NATIVE_OK ",checks);get_tree().quit()
