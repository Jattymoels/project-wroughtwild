extends Node3D
const IDS=["iron_vein","copper_vein","tin_vein","ember_iron_vein","silver_vein"]
var player:WroughtwildPlayer
var sim:WroughtwildSim
var manager:=SaveManager.new()
var nodes:Array=[]
var checks:=0
var rendered:=false
var output:String
var caption:Label
var camera:Camera3D
var defs:Dictionary
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok:push_error("C5_NATIVE_FAIL "+message);get_tree().quit(1)
	assert(ok,message)
func _ready()->void:
	rendered=DisplayServer.get_name()!="headless";output="res://c5/evidence/native-"+(RenderingServer.get_current_rendering_method() if rendered else "headless");DirAccess.make_dir_recursive_absolute(output)
	player=preload("res://scenes/player.tscn").instantiate();add_child(player);player.class_panel.choose("warden");player.set_physics_process(false);player.placement.set_physics_process(false);player.combat.set_physics_process(false);player.hud.hide();player.hide();player.position=Vector3(0,1,5);sim=player.inventory.get_sim()
	defs=JSON.parse_string(FileAccess.get_file_as_string("res://../data/tuning/worldgen.json")).nodes
	for i in IDS.size():
		var id:String=IDS[i];var n:ResourceNode=preload("res://scenes/resource_node.tscn").instantiate();n.set_script(load("res://c5/native_resource.gd"));n.name="c5_"+id;n.resource_id=id;n.presentation_label=defs[id].display_name
		for key in ["visual","material_family","units_per_harvest"]:n.set(key,defs[id][key])
		n.remaining_units=defs[id].units;n.heat_to_work=defs[id].get("heat_to_work",0);n.position=Vector3((i-2)*3.1,0,0);add_child(n);nodes.append(n)
		check(n.drive_presses==1 and n.tool_item==&"","unchanged no-tool one-press ore work")
		check(n.art.find_children("*","CollisionObject3D",true,false).is_empty(),"no source-created collider")
		var body:CollisionShape3D=n.get_node("CollisionShape3D");var half:Vector3=body.shape.size*.5
		for model in n.models.values():
			var fits:=true
			for mesh in model.find_children("*","MeshInstance3D",true,false):
				for s in mesh.mesh.get_surface_count():
					for v in mesh.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]:
						var p:Vector3=n.to_local(mesh.to_global(v))-body.position;fits=fits and absf(p.x)<=half.x+.001 and absf(p.y)<=half.y+.001 and absf(p.z)<=half.z+.001
			check(fits,"every solid stock/crack model fits the measured fallback body "+id)
		check(sim.material_count(defs[id].material_family)==0,"starts with no test ore grant")
	setup_review()
	for i in 8:await get_tree().physics_frame
	var args:=OS.get_cmdline_user_args()
	if "--restore-partial" in args:
		check(manager.read("user://c5-partial.json",player),"fresh partial load")
		for n in nodes:
			check(n.remaining_units==int(defs[n.resource_id].units)-2 and n.hot_level==0,"saved stock and transient heat")
			check(n.cracked==(n.resource_id!="iron_vein") and n.drive_progress==0,"exact cracks and no invented work progress")
			check(sim.material_count(defs[n.resource_id].material_family)==2,"saved collected ore exact")
			check(n.displayed_state=="u%d-%s"%[n.remaining_units,"cold" if n.resource_id=="iron_vein" else "cracked"],"saved state chooses matched source")
		finish("partial");return
	if "--restore-final" in args:
		check(manager.read("user://c5-final.json",player),"fresh depleted load")
		check(get_tree().get_nodes_in_group("resources").is_empty(),"depleted resources stay absent")
		for id in IDS:check(sim.material_count(defs[id].material_family)==int(defs[id].units),"exact finite final haul "+id)
		finish("final");return
	await approaches();surface_contract()
	if rendered:await shot("full")
	for i in nodes.size():
		var n:ResourceNode=nodes[i];var before:=n.remaining_units
		if i==0:
			n.soak(2,60);check(n.hot_level==0 and n.workable() and not n.quench(),"iron is hands work; heat ignored")
		else:
			check(n.work(sim).has("refusal") and n.remaining_units==before,"cold gate refuses without spending or yielding")
			check(n.strike().is_empty() and not n.cracked,"cold strike does not bypass heat")
			n.soak(1,60);check(not n.workable() and not n.quench() and not n.cracked,"wood heat insufficient")
			n.soak(2,60);check(n.workable() and not n.cracked,"charcoal heat allows immediate work before crack")
	if rendered:await shot("heated")
	for n in nodes:player._apply_work(n,n.work(sim))
	for i in 18:await get_tree().physics_frame
	absorb()
	for n in nodes:check(n.remaining_units==int(defs[n.resource_id].units)-2 and not n.cracked and sim.material_count(n.material_family)==2,"one ordinary E pays two and reveals one matched face")
	if rendered:await shot("part-worked-hot")
	for i in range(1,nodes.size()):
		var n:ResourceNode=nodes[i]
		if i%2:check(n.quench(),"native cold cracks heated ore")
		else:check(n.strike().get("struck",false),"native heavy impact cracks heated ore")
		check(n.cracked and n.hot_level==0 and n.workable(),"cracked is permanent and cool")
	if rendered:await shot("part-worked-cracked")
	check(manager.write("user://c5-partial.json",player),"write exact partial ownership")
	var snapshot:=manager.capture(player)
	check(manager.apply(player,JSON.parse_string(JSON.stringify(snapshot))),"roundtrip current save")
	check(manager.capture(player).resource_nodes==snapshot.resource_nodes,"same saved IDs positions stock and cracks")
	for n in nodes:
		while n.remaining_units>2:player._apply_work(n,n.work(sim))
	for i in 18:await get_tree().physics_frame
	if rendered:await shot("last-portions")
	for n in nodes:
		player._apply_work(n,n.work(sim));check(n.remaining_units==0 and n.harvest()==0,"finite exhaustion rejects duplicate harvest")
	for i in 42:
		await get_tree().physics_frame
		if rendered and i%2==0:await shot("depletion-%03d"%(i/2))
	absorb();check(get_tree().get_nodes_in_group("resources").is_empty(),"native depletion removes every target")
	for id in IDS:check(sim.material_count(defs[id].material_family)==int(defs[id].units),"one finite haul "+id)
	check(manager.write("user://c5-final.json",player),"save depleted ownership")
	if rendered:await shot("depleted")
	finish("flow")
func setup_review()->void:
	var body:=StaticBody3D.new();var c:=CollisionShape3D.new();c.shape=BoxShape3D.new();c.shape.size=Vector3(30,.5,20);c.position.y=-.25;body.add_child(c);add_child(body)
	var floor:=MeshInstance3D.new();floor.mesh=PlaneMesh.new();floor.mesh.size=Vector2(30,20);var m:=StandardMaterial3D.new();m.albedo_color=Color(.22,.23,.21);m.roughness=1;floor.material_override=m;add_child(floor)
	var w:=WorldEnvironment.new();w.environment=Environment.new();w.environment.background_mode=Environment.BG_COLOR;w.environment.background_color=Color(.24,.29,.33);w.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;w.environment.ambient_light_energy=.75;add_child(w)
	var sun:=DirectionalLight3D.new();sun.light_energy=1.7;sun.rotation_degrees=Vector3(-45,-25,0);sun.shadow_enabled=true;add_child(sun)
	camera=Camera3D.new();add_child(camera);camera.position=Vector3(3,8,12);camera.look_at(Vector3(0,.15,0));camera.make_current();get_viewport().msaa_3d=Viewport.MSAA_4X
	var canvas:=CanvasLayer.new();add_child(canvas);caption=Label.new();caption.position=Vector2(18,18);caption.add_theme_font_size_override("font_size",20);canvas.add_child(caption)
func absorb()->void:
	for child in get_children():
		if child is Pickup and not child.is_queued_for_deletion():child._absorb(player)
func approaches()->void:
	# Ordinary capsule movement along the working side, with no model collision enlargement.
	player.position=Vector3(-8,1.0,2.0)
	for i in 260:
		await get_tree().physics_frame;player.velocity=Vector3(4,-3,0);player.move_and_slide()
	check(player.position.x>8 and player.is_on_floor(),"real capsule crosses all five unchanged work approaches")
	for n in nodes:
		var ray:=PhysicsRayQueryParameters3D.create(n.position+Vector3(0,2,0),n.position+Vector3(0,-.1,0));var hit:=get_world_3d().direct_space_state.intersect_ray(ray)
		check(not hit.is_empty() and hit.collider==n,"original ore body still picks at work point")
	player.position=Vector3(0,1,5)
func surface_faces(gap:bool)->PackedVector3Array:
	var faces:=PackedVector3Array()
	for x in range(60,100):
		if gap and x in range(76,84):continue
		var a:=Vector3(x*.1,(x*.1-8)*.08,6);var b:=a+Vector3(.1,.008,0);var c:=b+Vector3(0,0,4);var d:=a+Vector3(0,0,4);faces.append_array(PackedVector3Array([a,b,c,a,c,d]))
	return faces
func surface_contract()->void:
	var t:=Terrain.new();t.faceted_surface=true;t.weathered=true;t.frontier_look=load("res://art/weathered_look.tres");t.map={"cell_size":1.0};add_child(t);t.set_process(false)
	var chunk:=Node3D.new();t.add_child(chunk);t.chunks["0_0"]=chunk;chunk.set_meta("surface_sampler",SurfaceSampler.new(surface_faces(false),1.0));t.nodes_root=Node3D.new();t.add_child(t.nodes_root)
	for id in IDS:
		var n:ResourceNode=load("res://scenes/resource_node.tscn").instantiate();n.set_script(load("res://c5/native_resource.gd"));n.visual=defs[id].visual;n.resource_id=id;n.position=Vector3(8,0,8);n.remaining_units=defs[id].units;t.nodes_root.add_child(n)
		check(n.art==null,"solid candidate does not replace zero-thickness ordinary ribbon")
		var mesh:Mesh=n.get_node("MeshInstance3D").mesh;var before:PackedVector3Array=mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX];var body_before:PackedVector3Array=n.get_node("CollisionShape3D").shape.get_faces()
		chunk.set_meta("surface_sampler",SurfaceSampler.new(surface_faces(true),1.0));n.refresh_surface()
		var after:Mesh=n.get_node("MeshInstance3D").mesh
		check(after==null or after.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()<before.size(),"excavated unsupported ribbon disappears")
		chunk.set_meta("surface_sampler",SurfaceSampler.new(surface_faces(false),1.0));n.refresh_surface()
		check(n.get_node("MeshInstance3D").mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]==before,"exact ribbon geometry restored")
		check(n.get_node("CollisionShape3D").shape.get_faces()==body_before,"exact ribbon collision restored")
		check(n.position==Vector3(8,0,8) and n.remaining_units==int(defs[id].units),"saved anchor and finite state unchanged by ground refresh")
		n.free()
	t.free()
func shot(name:String)->void:
	caption.text="ART-07C5 | actual native work | "+name+"\nIron / Copper / Tin / Ember-Iron / Silver • fixture sites; no ore inventory grants"
	await RenderingServer.frame_post_draw;check(get_viewport().get_texture().get_image().save_png(output+"/"+name+".png")==OK,"native screenshot")
func finish(mode:String)->void:
	var f:=FileAccess.open(output+"/native-"+mode+".json",FileAccess.WRITE);var inventory:Dictionary={}
	for id in IDS:inventory[id]=sim.material_count(defs[id].material_family)
	f.store_string(JSON.stringify({"checks":checks,"failures":0,"mode":mode,"inventory":inventory,"scope":"Authored fixture using current ResourceNode, native inventory, player work/pickup and SaveManager. No normal campaign or ordinary-world art adoption."},"\t"));print("C5_NATIVE_OK ",checks);get_tree().quit()
