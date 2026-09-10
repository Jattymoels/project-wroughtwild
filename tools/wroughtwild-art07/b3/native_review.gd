extends Node3D
## Explicit authored fixture at pinned current rules; no generated geography or owner saves.
var player:WroughtwildPlayer
var sim:WroughtwildSim
var manager:=SaveManager.new()
var nodes:Array=[]
var camera:Camera3D
var caption:Label
var output:String
var checks:=0
var rendered:=false
func check(ok:bool,text:String)->void:
	checks+=1
	if not ok:push_error("B3_NATIVE_FAIL "+text);get_tree().quit(1)
	assert(ok,text)
func _ready()->void:
	rendered=DisplayServer.get_name()!="headless";output="res://b3/evidence/"+(RenderingServer.get_current_rendering_method() if rendered else "headless");DirAccess.make_dir_recursive_absolute(output)
	player=preload("res://scenes/player.tscn").instantiate();add_child(player);player.class_panel.choose("warden");player.set_physics_process(false);player.placement.set_physics_process(false);player.combat.set_physics_process(false);player.hud.hide();player.position=Vector3(0,1.1,5);sim=player.inventory.get_sim()
	var defs:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://../data/tuning/worldgen.json")).nodes
	for id in ["boulder","stone_seam"]:
		var n:ResourceNode=preload("res://scenes/resource_node.tscn").instantiate();n.set_script(load("res://b3/native_resource.gd"));n.name="b3_"+id;n.resource_id=id
		for key in ["visual","material_family","units_per_harvest","drive_presses"]:n.set(key,defs[id][key])
		n.remaining_units=defs[id].units;n.tool_item=defs[id].get("tool_item","");n.position=Vector3(-1.6 if id=="boulder" else 1.6,0,0);add_child(n);nodes.append(n)
		check(n.art.find_children("*","CollisionObject3D",true,false).is_empty(),"candidate adds no collider or resource authority")
	check(nodes[0].get_node("CollisionShape3D").shape.size==Vector3(1.4,1,1.2),"original boulder body")
	var fitted:=true
	for model in nodes[0].stages:
		for mesh in model.find_children("*","MeshInstance3D",true,false):
			for s in mesh.mesh.get_surface_count():
				for vertex in mesh.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]:
					var p:Vector3=nodes[0].to_local(mesh.to_global(vertex))
					fitted=fitted and absf(p.x)<=.701 and absf(p.z)<=.601 and p.y>=-.025 and p.y<=1.001
	check(fitted,"actual imported boulder vertices fit unchanged native body")
	var seam_size:Vector3=nodes[1].get_node("CollisionShape3D").shape.size;check(seam_size==Vector3(2.6,.6,.9) or seam_size==Vector3(.9,.6,2.6),"original seam body")
	var floor:=MeshInstance3D.new();floor.mesh=PlaneMesh.new();floor.mesh.size=Vector2(30,30);add_child(floor);var fm:=StandardMaterial3D.new();fm.albedo_color=Color(.22,.23,.18);floor.material_override=fm
	var world:=WorldEnvironment.new();world.environment=Environment.new();world.environment.background_mode=Environment.BG_COLOR;world.environment.background_color=Color(.23,.29,.35);world.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;world.environment.ambient_light_energy=.8;add_child(world)
	var sun:=DirectionalLight3D.new();sun.light_energy=1.7;sun.rotation_degrees=Vector3(-40,-30,0);sun.shadow_enabled=true;add_child(sun)
	player.hide() # Fixture camera is external; keep the native capsule active without detached first-person hands.
	camera=Camera3D.new();add_child(camera);camera.position=Vector3(3.8,2.9,5.2);camera.look_at(Vector3(0,.3,0));camera.make_current()
	var canvas:=CanvasLayer.new();add_child(canvas);caption=Label.new();canvas.add_child(caption);caption.position=Vector2(18,18);caption.add_theme_font_size_override("font_size",20)
	for i in 8:await get_tree().physics_frame
	if "--restore-partial" in OS.get_cmdline_user_args():
		check(manager.read("user://b3-partial.json",player),"fresh process partial save read")
		await get_tree().process_frame
		check(nodes[0].remaining_units==6 and nodes[0].drive_progress==1,"boulder exact partial stock and work")
		check(nodes[1].remaining_units==12 and nodes[1].wedge_set and nodes[1].drive_progress==2,"seam exact wedge and work")
		check(sim.material_count("fieldstone")==3 and sim.material_count("timber_wedge")==5,"partial inventory exact")
		check(nodes[0].stages[1].visible,"restored boulder cut state follows saved stock")
		finish("partial-restart");return
	if "--restore-final" in OS.get_cmdline_user_args():
		check(manager.read("user://b3-final.json",player),"fresh process final save read")
		check(get_tree().get_nodes_in_group("resources").is_empty(),"depleted native resources stay absent")
		check(sim.material_count("fieldstone")==9 and sim.material_count("split_stone")==12 and sim.material_count("timber_wedge")==0,"one finite payout and six paid wedges persist")
		finish("final-restart");return
	await passage()
	surface_contacts()
	if rendered:await shot("intact")
	var cold:=manager.capture(player)
	nodes[1].soak(1,10.0);check(nodes[1].hot_level==1,"native seam heat presentation")
	if rendered:await shot("heated")
	check(nodes[1].quench() and nodes[1].cracked,"native quench presentation")
	if rendered:await shot("cracked")
	check(manager.apply(player,cold),"restore cold fixture before ordinary paid wedge sequence")
	var denied:Dictionary=nodes[1].work(sim);check(denied.has("refusal") and not nodes[1].wedge_set,"missing wedge refuses without work")
	sim.add_material("timber_wedge",6) # Explicit fixture input; every native split still consumes one.
	for i in 4:player._apply_work(nodes[0],nodes[0].work(sim))
	for i in 3:player._apply_work(nodes[1],nodes[1].work(sim))
	for i in 15:await get_tree().physics_frame
	absorb()
	check(nodes[0].remaining_units==6 and nodes[0].drive_progress==1,"boulder native third-press chunk")
	check(nodes[1].wedge_set and nodes[1].drive_progress==2 and nodes[1].remaining_units==12,"native wedge depth midpoint")
	check(manager.write("user://b3-partial.json",player),"partial checkpoint write")
	var saved:=manager.capture(player);check(manager.apply(player,JSON.parse_string(JSON.stringify(saved))),"partial checkpoint apply")
	check(manager.capture(player).resource_nodes==saved.resource_nodes,"exact IDs positions and work roundtrip")
	if rendered:await shot("worked-wedge-half")
	for i in 2:player._apply_work(nodes[0],nodes[0].work(sim))
	for i in 2:player._apply_work(nodes[1],nodes[1].work(sim))
	for i in 15:await get_tree().physics_frame
	check(nodes[0].remaining_units==3 and nodes[0].stages[2].visible,"one last capped boulder chunk")
	check(nodes[1].remaining_units==10 and not nodes[1].wedge_set,"first seam split pays two")
	if rendered:await shot("remnant-first-split")
	for i in 3:player._apply_work(nodes[0],nodes[0].work(sim))
	for i in 25:player._apply_work(nodes[1],nodes[1].work(sim))
	check(nodes[0].remaining_units==0 and nodes[1].remaining_units==0,"exact finite exhaustion")
	check(nodes[0].harvest()==0 and nodes[1].harvest()==0,"repeat harvest cannot duplicate")
	for i in 36:
		await get_tree().physics_frame
		if rendered and i%2==0:await shot("deplete-%03d"%(i/2))
	absorb();check(get_tree().get_nodes_in_group("resources").is_empty(),"native roll and shrink remove work targets")
	check(sim.material_count("fieldstone")==9 and sim.material_count("split_stone")==12 and sim.material_count("timber_wedge")==0,"exact final materials and wedge spending")
	check(manager.write("user://b3-final.json",player),"final checkpoint write")
	if rendered:await shot("depleted")
	finish("flow")
func absorb()->void:
	for child in get_children():
		if child is Pickup and not child.is_queued_for_deletion():child._absorb(player)
func surface_contacts()->void:
	var terrain:=Terrain.new();terrain.faceted_surface=true;terrain.weathered=true;terrain.frontier_look=load("res://art/weathered_look.tres");terrain.map={"cell_size":1.0};add_child(terrain);terrain.set_process(false)
	var chunk:=Node3D.new();terrain.add_child(chunk);terrain.chunks["0_0"]=chunk
	terrain.nodes_root=Node3D.new();terrain.add_child(terrain.nodes_root)
	var full:=surface_faces(false);chunk.set_meta("surface_sampler",SurfaceSampler.new(full,1.0))
	var n:ResourceNode=preload("res://scenes/resource_node.tscn").instantiate();n.set_script(load("res://b3/native_resource.gd"));n.visual=&"seam";n.remaining_units=12;n.units_per_harvest=2;n.tool_item=&"timber_wedge";n.drive_presses=4;n.position=Vector3(8,0,8);terrain.nodes_root.add_child(n)
	var before:=surface_vertices(n);check(before.size()>100,"candidate conforms to actual terrain triangle sampler")
	var original:Mesh=GroundedSeam.build(n,terrain,n._visual_seed()%2==0,Color("2e3036"));check(n.get_node("MeshInstance3D").mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]==original.surface_get_arrays(0)[Mesh.ARRAY_VERTEX],"original grounded work face and picking geometry retained")
	chunk.set_meta("surface_sampler",SurfaceSampler.new(surface_faces(true),1.0));n.refresh_surface();var removed:=surface_vertices(n);check(removed.size()<before.size(),"missing support removes dressing triangles")
	for v in removed:
		check(is_finite(terrain.rendered_height(8+v.x,8+v.z,0,1.25)),"no unsupported exported dressing vertex")
	chunk.set_meta("surface_sampler",SurfaceSampler.new(full,1.0));n.refresh_surface();check(surface_vertices(n)==before,"repeat support restoration reconstructs exact candidate vertices")
	check(n.position==Vector3(8,0,8) and n.remaining_units==12 and n.drive_progress==0,"ground refresh cannot move or refill native resource")
	terrain.free()
func surface_vertices(n:ResourceNode)->PackedVector3Array:
	var result:=PackedVector3Array()
	for m in n.art.find_children("*","MeshInstance3D",true,false):
		for s in m.mesh.get_surface_count():result.append_array(m.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX])
	return result
func surface_faces(gap:bool)->PackedVector3Array:
	var faces:=PackedVector3Array()
	for x in range(60,100):
		if gap and x in range(76,84):continue
		var a:=Vector3(x*.1,(x*.1-8)*.08,6);var b:=a+Vector3(.1,.008,0);var c:=b+Vector3(0,0,4);var d:=a+Vector3(0,0,4)
		faces.append_array(PackedVector3Array([a,b,c,a,c,d]))
	return faces
func support(size:Vector3,at:Vector3)->void:
	var body:=StaticBody3D.new();var c:=CollisionShape3D.new();c.shape=BoxShape3D.new();c.shape.size=size;body.add_child(c);add_child(body);body.position=at
func passage()->void:
	# Physical support fixture representing retained cave walls/floor, not decorative triangle collision.
	var cave:Node3D=load("res://b3/assets/cave-threshold-lod0.glb").instantiate();add_child(cave);cave.position=Vector3(8,0,0)
	check(cave.find_children("*","CollisionObject3D",true,false).is_empty(),"cave dressing has no collider")
	support(Vector3(30,.5,30),Vector3(0,-.25,0));support(Vector3(1,3,1.6),Vector3(6.25,1.5,0));support(Vector3(1,3,1.6),Vector3(9.75,1.5,0));support(Vector3(4.5,.5,1.6),Vector3(8,2.85,0))
	player.position=Vector3(8,1.05,2.5)
	for i in 140:
		await get_tree().physics_frame;player.velocity=Vector3(0,-3,-2);player.move_and_slide()
	check(player.position.z< -1.5 and player.is_on_floor(),"actual player capsule walks the supported clear cave opening")
	player.position=Vector3(0,1.1,5)
func shot(name:String)->void:
	caption.text="ART-07B3 | actual native work | "+name+"\nFixture: 9 fieldstone / 12 split stone • six supplied wedges, each spent normally"
	await RenderingServer.frame_post_draw;check(get_viewport().get_texture().get_image().save_png(output+"/"+name+".png")==OK,"native rendered evidence")
func finish(mode:String)->void:
	var f:=FileAccess.open(output+"/native-"+mode+".json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":0,"fieldstone":sim.material_count("fieldstone"),"split_stone":sim.material_count("split_stone"),"fixture":"Authored current-resource and cave-support fixture; six supplied wedges. Actual work, pickups, bodies and SaveManager. Not a normal campaign or all cave shapes."},"\t"));print("B3_NATIVE_OK ",checks);get_tree().quit()
