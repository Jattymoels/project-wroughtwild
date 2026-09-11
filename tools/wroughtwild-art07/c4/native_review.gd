extends Node3D
## C4 derivative of B1's real native felling and SaveManager fixture.
var player:WroughtwildPlayer
var sim:WroughtwildSim
var manager:=SaveManager.new()
var camera:Camera3D
var nodes:Array=[]
var output:="res://c4/evidence/"
var rendered:=false
var caption:Label
var checks:=0
var envelopes:Array=[]
func check(value:bool,label:String)->void:
	checks+=1
	if not value:push_error("C4_NATIVE_FAIL "+label);get_tree().quit(1)
	assert(value,label)
func _ready()->void:
	rendered=DisplayServer.get_name()!="headless"
	output+=RenderingServer.get_current_rendering_method() if rendered else "headless"
	DirAccess.make_dir_recursive_absolute(output)
	player=preload("res://scenes/player.tscn").instantiate();add_child(player);player.class_panel.choose("warden")
	player.set_physics_process(false);player.placement.set_physics_process(false);player.combat.set_physics_process(false);player.hud.hide();player.position=Vector3(0,1.1,3)
	sim=player.inventory.get_sim()
	var defs:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://../data/tuning/worldgen.json")).nodes
	for i in 2:
		var def:Dictionary=defs.ash_snag
		var node:ResourceNode=preload("res://scenes/resource_node.tscn").instantiate();node.set_script(load("res://c4/native_tree.gd"));node.source_kind="ash-a" if i==0 else "ash-b"
		node.name="c4_ash_"+str(i);node.resource_id=String(node.name);node.visual=def.visual;node.material_family=def.material_family;node.remaining_units=def.units;node.units_per_harvest=def.units_per_harvest;node.drive_presses=def.drive_presses
		node.position=Vector3(-1.7 if i==0 else 1.7,0,0);add_child(node);nodes.append(node)
		var cs:CollisionShape3D=node.get_node("CollisionShape3D")
		check(cs.shape.size==Vector3(.6,2.6,.6) and cs.position==Vector3(0,1.3,0),"native wastes body unchanged")
		envelopes.append({"id":node.resource_id,"body_size":cs.shape.size,"body_position":cs.position,"visual_scale":node.get_node("MeshInstance3D").scale,"drive_presses":node.drive_presses,"units":node.remaining_units,"item":node.material_family})
	var floor:=MeshInstance3D.new();floor.mesh=PlaneMesh.new();floor.mesh.size=Vector2(30,30);add_child(floor)
	var floor_mat:=StandardMaterial3D.new();floor_mat.albedo_color=Color(.25,.23,.19);floor.material_override=floor_mat
	var env:=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color(.35,.38,.40);env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_energy=.8;env.environment.ambient_light_color=Color(.8,.85,1);add_child(env)
	var sun:=DirectionalLight3D.new();sun.light_energy=2;sun.rotation_degrees=Vector3(-42,-30,0);sun.shadow_enabled=true;add_child(sun)
	camera=Camera3D.new();add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=7.8;camera.position=Vector3(7,4,10);camera.look_at(Vector3(0,1.9,0));camera.make_current()
	var canvas:=CanvasLayer.new();add_child(canvas);caption=Label.new();canvas.add_child(caption);caption.position=Vector2(18,18);caption.add_theme_font_size_override("font_size",18)
	for i in 8:await get_tree().physics_frame
	# Native picking/body, not a visual bounds proxy.
	for n:ResourceNode in nodes:
		for h in [.3,.9,1.62,2.5]:
			var q:=PhysicsRayQueryParameters3D.create(n.position+Vector3(0,h,2),n.position+Vector3(0,h,-2));q.exclude=[player.get_rid()]
			var hit:=get_world_3d().direct_space_state.intersect_ray(q)
			check(not hit.is_empty() and hit.collider==n,"native work target remains hittable")
			check(absf(hit.position.z-.3)<.001,"actual front body surface")
	if "--restore-partial" in OS.get_cmdline_user_args():
		check(manager.read("user://c4-partial.json",player),"fresh process loads partial checkpoint")
		for n in nodes:check(n.drive_progress==3 and n.remaining_units==14,"partial work and stock exact")
		check(sim.material_count("ash_wood")==0,"no premature stock on restart")
		finish();return
	if "--restore-final" in OS.get_cmdline_user_args():
		check(manager.read("user://c4-final.json",player),"fresh process loads depleted checkpoint")
		check(get_tree().get_nodes_in_group("resources").is_empty(),"depleted identities absent")
		check(get_tree().get_nodes_in_group("c4_session_stumps").is_empty(),"session-only aftermath absent on fresh load")
		check(sim.material_count("ash_wood")==28,"exact ash inventory survives reload")
		finish();return
	if rendered:await shot("standing")
	for node in nodes:
		for i in 3:player._apply_work(node,node.work(sim))
		check(node.drive_progress==3 and node.remaining_units==14,"native partial state retains stock")
		check(node.get_node("MeshInstance3D").scale.is_equal_approx(Vector3.ONE),"native lean has no runtime fit scaling")
		check(node.get_node("MeshInstance3D").get_child(0).scale==Vector3.ONE,"exported model is used at exact scale")
	check(manager.write("user://c4-partial.json",player),"write partial native checkpoint")
	var saved:=manager.capture(player)
	check(manager.apply(player,JSON.parse_string(JSON.stringify(saved))),"restore partial in place")
	check(manager.capture(player).resource_nodes==saved.resource_nodes,"exact IDs positions stock and partial work")
	if rendered:await shot("partial")
	for node in nodes:
		for i in 3:player._apply_work(node,node.work(sim))
		check(node.remaining_units==0,"native felling spends finite stock")
		check(node.harvest()==0,"repeat depletion cannot yield")
	for frame in 84:
		await get_tree().physics_frame
		if rendered and frame%2==0:await shot("fall-%03d"%(frame/2))
	check(get_tree().get_nodes_in_group("resources").is_empty(),"native fall frees both resources")
	check(get_tree().get_nodes_in_group("c4_session_stumps").size()==2,"one inert matching stump per resource")
	for child in get_children():
		if child is Pickup and not child.is_queued_for_deletion():child._absorb(player)
	check(sim.material_count("ash_wood")==28,"one fourteen-unit payout per resource")
	check(manager.write("user://c4-final.json",player),"save exact final ownership")
	if rendered:await shot("stumps")
	finish()
func shot(name:String)->void:
	caption.text="ART-07C4 | actual native ash work and felling | "+name+"\n0.6 × 2.6 × 0.6 m native body • six presses • fourteen ash wood"
	await RenderingServer.frame_post_draw
	check(get_viewport().get_texture().get_image().save_png(output+"/"+name+".png")==OK,"native capture")
func finish()->void:
	var name:="partial-restart" if "--restore-partial" in OS.get_cmdline_user_args() else ("final-restart" if "--restore-final" in OS.get_cmdline_user_args() else "flow")
	var file:=FileAccess.open(output+"/native-"+name+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":0,"envelopes":envelopes,"ash_wood":sim.material_count("ash_wood"),"fixture":"Authored wastes-biome presentation adapter. Actual native _apply_work, fall tween, pickup and SaveManager. Posed collection; not paid campaign play."},"\t"))
	print("C4_NATIVE_OK ",checks);get_tree().quit()
