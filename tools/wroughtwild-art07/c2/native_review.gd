extends Node3D
## Authored resource fixture, using actual current work, pickups, capsule, ray targets and SaveManager.
var player:WroughtwildPlayer
var sim:WroughtwildSim
var manager:=SaveManager.new()
var nodes:Array=[]
var camera:Camera3D
var caption:Label
var output:String
var checks:=0
var failures:=0
var rendered:=false
var contact_report:Array=[]
func check(ok:bool,text:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("C2_NATIVE_FAIL "+text);get_tree().quit(1)
	assert(ok,text)
func _ready()->void:
	rendered=DisplayServer.get_name()!="headless";output="res://c2/evidence/"+(RenderingServer.get_current_rendering_method() if rendered else "headless");DirAccess.make_dir_recursive_absolute(output)
	player=preload("res://scenes/player.tscn").instantiate();add_child(player);player.class_panel.choose("warden");player.set_physics_process(false);player.placement.set_physics_process(false);player.combat.set_physics_process(false);player.hud.hide();player.position=Vector3(0,1.1,5);sim=player.inventory.get_sim()
	var defs:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://../data/tuning/worldgen.json")).nodes
	for id in ["slate_outcrop","shellstone_outcrop"]:
		var n:ResourceNode=preload("res://scenes/resource_node.tscn").instantiate();n.name="c2_"+id;n.resource_id=id
		for key in ["visual","material_family","units_per_harvest","drive_presses"]:n.set(key,defs[id][key])
		n.remaining_units=defs[id].units;n.position=Vector3(-1.65 if id=="slate_outcrop" else 1.65,0,0);add_child(n);nodes.append(n)
		check(n.art.find_children("*","CollisionObject3D",true,false).is_empty(),"candidate adds no collider or resource")
		check(n.get_node("CollisionShape3D").shape.size==Vector3(2,.58,1.15),"original quarry body")
		var fitted:=true;var min_y:=100.0;var max_y:=-100.0;var vertices:=0
		for model in n.stages:
			for mesh in model.find_children("*","MeshInstance3D",true,false):
				for s in mesh.mesh.get_surface_count():
					for vertex in mesh.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]:
						var p:Vector3=n.to_local(mesh.to_global(vertex));min_y=minf(min_y,p.y);max_y=maxf(max_y,p.y);vertices+=1;fitted=fitted and absf(p.x)<=1.001 and absf(p.z)<=.576 and p.y>=-.025 and p.y<=.581
		check(fitted,"all actual imported states fit unchanged native envelope");contact_report.append({"id":id,"sampled_vertices":vertices,"min_y":min_y,"max_y":max_y,"ground_m":0,"body":[2,.58,1.15]})
	var floor:=MeshInstance3D.new();floor.mesh=PlaneMesh.new();floor.mesh.size=Vector2(30,30);add_child(floor);var fm:=StandardMaterial3D.new();fm.albedo_color=Color(.24,.24,.20);floor.material_override=fm
	var body:=StaticBody3D.new();var shape:=CollisionShape3D.new();shape.shape=BoxShape3D.new();shape.shape.size=Vector3(30,.5,30);body.add_child(shape);body.position.y=-.25;add_child(body)
	var world:=WorldEnvironment.new();world.environment=Environment.new();world.environment.background_mode=Environment.BG_COLOR;world.environment.background_color=Color(.23,.29,.35);world.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;world.environment.ambient_light_energy=.8;add_child(world)
	var sun:=DirectionalLight3D.new();sun.light_energy=1.7;sun.rotation_degrees=Vector3(-40,-30,0);sun.shadow_enabled=true;add_child(sun)
	player.hide();camera=Camera3D.new();add_child(camera);camera.position=Vector3(3.8,3.5,5.2);camera.look_at(Vector3(0,.3,0));camera.make_current()
	var canvas:=CanvasLayer.new();add_child(canvas);caption=Label.new();canvas.add_child(caption);caption.position=Vector2(18,18);caption.add_theme_font_size_override("font_size",20)
	for i in 8:await get_tree().physics_frame
	if "--restore-partial" in OS.get_cmdline_user_args():
		check(manager.read("user://c2-partial.json",player),"fresh process partial read")
		await get_tree().process_frame
		for n in nodes:check(n.remaining_units==12 and n.drive_progress==2,"exact partial work and remaining stock");check(n.stages[1].visible,"saved cut face restores")
		check(sim.material_count("raw_slate")==12 and sim.material_count("raw_shellstone")==12,"exact partial inventory")
		if rendered:await shot("restored-partial")
		finish("partial-restart");return
	if "--restore-final" in OS.get_cmdline_user_args():
		check(manager.read("user://c2-final.json",player),"fresh process final read");check(get_tree().get_nodes_in_group("resources").is_empty(),"depleted targets remain absent");check(sim.material_count("raw_slate")==24 and sim.material_count("raw_shellstone")==24,"finite paid-out stock survives restart")
		check(get_tree().get_nodes_in_group("c2_aftermath").is_empty(),"native session-only remnants are absent after restart")
		if rendered:await shot("restored-depleted")
		finish("final-restart");return
	await contacts()
	if rendered:await shot("full")
	for n in nodes:
		for i in 14:player._apply_work(n,n.work(sim))
	for i in 20:await get_tree().physics_frame
	absorb()
	for n in nodes:check(n.remaining_units==12 and n.drive_progress==2 and n.stages[1].visible,"three four-press releases plus two pending presses")
	check(sim.material_count("raw_slate")==12 and sim.material_count("raw_shellstone")==12,"all released materials collected once")
	check(manager.write("user://c2-partial.json",player),"partial checkpoint write")
	var snapshot:=manager.capture(player);check(manager.apply(player,JSON.parse_string(JSON.stringify(snapshot))),"same-process exact checkpoint apply");check(manager.capture(player).resource_nodes==snapshot.resource_nodes,"resource IDs anchors stock work remain exact")
	if rendered:await shot("half-worked")
	for n in nodes:
		for i in 6:player._apply_work(n,n.work(sim))
	for i in 15:await get_tree().physics_frame
	for n in nodes:check(n.remaining_units==4 and n.stages[2].visible,"last four-unit face")
	if rendered:await shot("last-portion")
	for n in nodes:
		for i in 4:player._apply_work(n,n.work(sim))
		check(n.remaining_units==0 and n.harvest()==0,"exhaustion refuses duplicate payout")
	for i in 24:
		await get_tree().physics_frame
		if rendered and i%2==0:await shot("deplete-%03d"%(i/2))
	absorb();check(get_tree().get_nodes_in_group("resources").is_empty(),"native depletion removes work targets")
	check(sim.material_count("raw_slate")==24 and sim.material_count("raw_shellstone")==24,"exact original stock, no grants")
	var remains:=get_tree().get_nodes_in_group("c2_aftermath");check(remains.size()==2,"one inert remnant per spent bed")
	for r in remains:check(r.find_children("*","CollisionObject3D",true,false).is_empty(),"remnant has no work target or collider")
	check(manager.write("user://c2-final.json",player),"final checkpoint write")
	if rendered:await shot("depleted")
	finish("flow")
func absorb()->void:
	for child in get_children():
		if child is Pickup and not child.is_queued_for_deletion():child._absorb(player)
func contacts()->void:
	# Actual current player capsule follows the one-metre gap between the two existing envelopes.
	player.position=Vector3(0,1.1,4)
	for i in 120:
		await get_tree().physics_frame;player.velocity=Vector3(0,-3,-3);player.move_and_slide()
	check(player.position.z< -1.7 and player.is_on_floor(),"current capsule traverses retained working approach")
	for n in nodes:
		var ray:=PhysicsRayQueryParameters3D.create(n.position+Vector3(0,.29,2),n.position+Vector3(0,.29,0));ray.exclude=[player.get_rid()];var hit:=get_world_3d().direct_space_state.intersect_ray(ray)
		check(not hit.is_empty() and hit.collider==n,"actual ray still targets original work body")
		contact_report.append({"id":n.resource_id,"ray_hit":str(hit.position),"distance_from_front_m":2-hit.position.z})
	player.position=Vector3(0,1.1,5)
func shot(name:String)->void:
	caption.text="ART-07C2 | actual native quarry work | "+name+"\nTwo original 24-unit deposits • four work presses / four units • isolated authored fixture"
	await RenderingServer.frame_post_draw;check(get_viewport().get_texture().get_image().save_png(output+"/"+name+".png")==OK,"native rendered evidence")
func finish(mode:String)->void:
	var f:=FileAccess.open(output+"/native-"+mode+".json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"raw_slate":sim.material_count("raw_slate"),"raw_shellstone":sim.material_count("raw_shellstone"),"contacts":contact_report,"fixture":"Authored current-resource flat-ground fixture. Real contextual work, pickups, current capsule/rays and SaveManager; no test material grants. Not a generated-world journey or arbitrary slope fitter."},"\t"));print("C2_NATIVE_RESULT ",checks," checks, ",failures," failures");get_tree().quit(1 if failures else 0)
