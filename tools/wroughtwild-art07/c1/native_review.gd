extends Node3D
## Posed current-native three-resource fixture. No stock grants or saved-world changes.
var player:WroughtwildPlayer
var sim:WroughtwildSim
var manager:=SaveManager.new()
var nodes:Array=[]
var camera:Camera3D
var label:Label
var output:String
var rendered:bool
var checks:=0
var frames:=0
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok:push_error("C1_NATIVE_FAIL "+message);get_tree().quit(1)
	assert(ok,message)
func _ready()->void:
	rendered=DisplayServer.get_name()!="headless";output="res://c1/evidence/"+(RenderingServer.get_current_rendering_method() if rendered else "headless");DirAccess.make_dir_recursive_absolute(output)
	player=preload("res://scenes/player.tscn").instantiate();add_child(player);player.class_panel.choose("warden");player.set_physics_process(false);player.placement.set_physics_process(false);player.combat.set_physics_process(false);player.hud.hide();player.position=Vector3(0,1.1,4)
	sim=player.inventory.get_sim()
	var defs:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://../data/tuning/worldgen.json")).nodes
	for id:String in ["bog_oak","clay_bank","reed_bed"]:
		var n:ResourceNode=preload("res://scenes/resource_node.tscn").instantiate();n.set_script(load("res://c1/native_resource.gd"));n.name="c1_"+id;n.resource_id=id
		for p:String in ["visual","material_family","units_per_harvest","drive_presses"]:n.set(p,defs[id][p])
		n.remaining_units=defs[id].units;n.position=Vector3((nodes.size()-1)*2.4,0,0);add_child(n);nodes.append(n)
		var expected:=Vector3(.7,3,.7) if id=="bog_oak" else (Vector3(1.8,.38,1.25) if id=="clay_bank" else Vector3(1,1.3,1))
		check(n.get_node("CollisionShape3D").shape.size==expected,"actual original body "+id)
	var floor:=MeshInstance3D.new();floor.mesh=PlaneMesh.new();floor.mesh.size=Vector2(40,40);add_child(floor);var fm:=StandardMaterial3D.new();fm.albedo_color=Color(.13,.12,.075);fm.roughness=.94;floor.material_override=fm
	var world:=WorldEnvironment.new();world.environment=Environment.new();world.environment.background_mode=Environment.BG_COLOR;world.environment.background_color=Color(.34,.41,.44);world.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;world.environment.ambient_light_color=Color(.78,.84,.9);world.environment.ambient_light_energy=.8;add_child(world)
	var sun:=DirectionalLight3D.new();add_child(sun);sun.light_energy=1.8;sun.rotation_degrees=Vector3(-40,-35,0);sun.shadow_enabled=true
	camera=Camera3D.new();add_child(camera);camera.position=Vector3(8,5,12);camera.look_at(Vector3(0,2.8,0));camera.make_current();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=12
	var canvas:=CanvasLayer.new();add_child(canvas);label=Label.new();canvas.add_child(label);label.position=Vector2(18,18);label.add_theme_font_size_override("font_size",18)
	for i in 8:await get_tree().physics_frame
	var args:=OS.get_cmdline_user_args()
	if "--restore-partial" in args:
		check(manager.read("user://c1-partial.json",player),"separate process restores partial work")
		check(nodes[0].drive_progress==3 and nodes[0].remaining_units==14,"oak chop stock exact")
		check(nodes[1].drive_progress==1 and nodes[1].remaining_units==16,"clay partial second cycle exact")
		check(nodes[2].drive_progress==2 and nodes[2].remaining_units==18,"reed partial second cycle exact")
		await settle(16)
		check(nodes[0].current_art=="bog-oak-worked" and nodes[1].current_art=="clay-16" and nodes[2].current_art=="reed-18","restored stock selects actual matching art")
		check(sim.material_count("bog_oak")==0 and sim.material_count("raw_clay")==8 and sim.material_count("raw_reed")==6,"partial inventory exact")
		finish("partial-restart");return
	if "--restore-final" in args:
		check(manager.read("user://c1-final.json",player),"separate process restores depleted state")
		await settle(6);check(get_tree().get_nodes_in_group("resources").is_empty(),"depleted finite identities remain absent")
		check(get_tree().get_nodes_in_group("c1_session_aftermath").is_empty(),"session-only remnants do not reappear after reload")
		check(sim.material_count("bog_oak")==14 and sim.material_count("raw_clay")==24 and sim.material_count("raw_reed")==24,"final inventory exact")
		finish("final-restart");return
	if rendered:await shot("intact")
	for i in 3:await press(nodes[0])
	for i in 7:await press(nodes[1])
	for i in 5:await press(nodes[2])
	absorb();await settle(16)
	check(nodes[0].drive_progress==3 and nodes[0].remaining_units==14,"three chops no premature payout")
	check(nodes[1].drive_progress==1 and nodes[1].remaining_units==16,"two clay releases and next partial press")
	check(nodes[2].drive_progress==2 and nodes[2].remaining_units==18,"one reed release and partial work")
	check(manager.write("user://c1-partial.json",player),"native partial snapshot written")
	var saved:=manager.capture(player);check(manager.apply(player,JSON.parse_string(JSON.stringify(saved))),"in-place partial restore")
	check(manager.capture(player).resource_nodes==saved.resource_nodes,"exact original IDs, coordinates, stock and work after snapshot")
	if rendered:await shot("partial-work")
	# Actual native pause freezes the tree's process/material clock.
	var prior:float=nodes[0].presenter.clock_seconds;get_tree().paused=true
	for i in 4:await get_tree().process_frame
	check(nodes[0].presenter.clock_seconds==prior,"paused native scene stops wind");get_tree().paused=false
	for index in [1,2]:
		while nodes[index].remaining_units>0:await press(nodes[index])
		check(nodes[index].work(sim).has("refusal") and nodes[index].harvest()==0,"depleted source cannot yield again")
	for i in 3:await press(nodes[0])
	check(nodes[0].harvest()==0,"tree payout cannot repeat")
	for i in 72:
		await get_tree().physics_frame
		if rendered and i%3==0:await shot("fall-%03d"%(i/3))
	absorb();await settle(12)
	check(get_tree().get_nodes_in_group("resources").is_empty(),"all three native resource nodes depleted")
	check(get_tree().get_nodes_in_group("c1_session_aftermath").size()==3,"exactly one inert aftermath per source")
	for obj:Node in get_tree().get_nodes_in_group("c1_session_aftermath"):
		check(obj.find_children("*","CollisionObject3D",true,false).is_empty() and not obj.is_in_group("resources"),"aftermath owns no body or harvest identity")
	check(sim.material_count("bog_oak")==14 and sim.material_count("raw_clay")==24 and sim.material_count("raw_reed")==24,"exact finite payouts collected")
	check(manager.write("user://c1-final.json",player),"native depleted checkpoint written")
	if rendered:
		camera.size=8;camera.position=Vector3(5,3,7);camera.look_at(Vector3(0,.3,0));await shot("aftermath")
	finish("flow")
func press(n:ResourceNode)->void:
	player._apply_work(n,n.work(sim));await settle(13)
	if rendered:
		camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=3.6 if n.visual!=&"tree" else 10
		camera.position=n.position+Vector3(3,2.1,3.3) if n.visual!=&"tree" else Vector3(8,5,12)
		camera.look_at(n.position+Vector3.UP*(.4 if n.visual!=&"tree" else 3.2));await shot("work-%03d"%frames);frames+=1
func absorb()->void:
	for child:Node in get_children():
		if child is Pickup and not child.is_queued_for_deletion():child._absorb(player)
func settle(count:int)->void:
	for i in count:await get_tree().physics_frame
func shot(name:String)->void:
	label.text="ART-07C1 native finite-work fixture | "+name+"\nActual native dispatcher, fixed bodies, finite stock, pickup ownership and SaveManager"
	await RenderingServer.frame_post_draw;check(get_viewport().get_texture().get_image().save_png(output+"/"+name+".png")==OK,"actual native render saved")
func finish(mode:String)->void:
	var f:=FileAccess.open(output+"/native-"+mode+".json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":0,"bog_oak":sim.material_count("bog_oak"),"raw_clay":sim.material_count("raw_clay"),"raw_reed":sim.material_count("raw_reed"),"fixture":"Posed source work using actual native dispatcher; no paid first-hour or generated-route claim."},"\t"));f.close();print("C1_NATIVE_OK ",mode," ",checks);get_tree().quit()
