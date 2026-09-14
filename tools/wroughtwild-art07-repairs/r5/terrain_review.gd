extends "res://g1/review.gd"
## Retained LF3 seed 77 and unchanged paid checkpoint. Added terrain chests use
## explicitly supplied stock with ordinary paid placement, never changed terrain.
var r5terrain:Dictionary={"cases":[],"scope":"Original paid home restored; three additional terrain probes use supplied wood and native paid placement. No terrain or resource mutation."}
func execute():
	get_window().size=Vector2i(1440,900);DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED);get_viewport().msaa_3d=Viewport.MSAA_4X
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):output=arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(output)
	var manager:=SaveManager.new()
	check(manager.read("res://g1/paid-home.json",player),"unchanged original paid retained checkpoint loads")
	freeze_fixtures();refresh_stations();player.hide();player.hud.hide();player.camera.current=false;mood.set_process(false)
	camera=Camera3D.new();camera.fov=45;add_child(camera);camera.current=true
	var layer:=CanvasLayer.new();add_child(layer);caption=Label.new();layer.add_child(caption);caption.position=Vector2(22,20);caption.add_theme_font_size_override("font_size",20)
	var geography:=terrain._blocks.hex_encode().sha256_text()
	var sources:String=_sim().leyline_save()
	var machines:String=_sim().contraption_save()
	var retained:Array=[]
	for child in get_children():
		if child is PlacedBlock and child.is_chest():retained.append(child)
	for c in retained:await inspect_chest(c,"original-paid-home")
	_sim().add_material("wood",18)
	var home_site:Dictionary=terrain.map.home_sites[0]
	var found:=0
	# Deterministic search through original cells near the home; no reseed/excavation.
	for dx in range(-9,10,3):
		for dz in range(-9,10,3):
			if found>=3:break
			var x:=int(home_site.x)+dx;var z:=int(home_site.z)+dz;var y:=terrain.height_at(x,z)
			var cell:=Vector3i(x,y,z)
			terrain.ensure_area(Vector3(cell),8);terrain.set_process(false)
			player.placement.select_shape(&"chest");player.build_palette.select_material(&"wood");selected=""
			var element:Dictionary={"kind":"volume","axis":0,"cell":cell*2}
			if not player.placement.element_refusal(element).is_empty():continue
			var c:=_place(&"chest",&"wood",cell) as PlacedBlock
			if c==null:continue
			found+=1;await inspect_chest(c,"retained-terrain-"+str(found))
		if found>=3:break
	check(found==3,"three original terrain placement probes")
	check(terrain._blocks.hex_encode().sha256_text()==geography,"complete retained terrain bytes unchanged")
	check(_sim().leyline_save()==sources and _sim().contraption_save()==machines,"all existing source/work/machine ledgers unchanged")
	r5terrain.terrain_sha256=geography;r5terrain.gpu=RenderingServer.get_video_adapter_name();r5terrain.backend=RenderingServer.get_current_rendering_method();r5terrain.failures=failures;r5terrain.checks=report.checks
	FileAccess.open(output+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(r5terrain,"  "))
	print("R5_TERRAIN ",report.checks.size()," checks, ",failures," failures")
	get_tree().quit(1 if failures else 0)
func mesh_bounds(node:Node3D)->AABB:
	var bounds:=AABB();var first:=true
	for c in node.find_children("*","MeshInstance3D",true,false):
		if not c.is_visible_in_tree():continue
		var a:AABB=c.global_transform*c.mesh.get_aabb();bounds=a if first else bounds.merge(a);first=false
	return bounds
func inspect_chest(c:PlacedBlock,label:String)->void:
	player.placement.set_build_mode_enabled(false)
	for frame in 5:await get_tree().physics_frame
	var body:Node3D=c.get_node("E3View")
	var before:=c.transform;var collider_before:Transform3D=c._collision_shapes[0].transform
	var bounds:=mesh_bounds(body)
	var cabinet_bottom:=bounds.position.y
	var geometry:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://e3/geometry.json"))["chest_"+String(c.material_family)+"_body"]
	if geometry.has("seating"):cabinet_bottom=c.global_position.y+float(geometry.seating.cabinet_bounds_blender[0][2])
	var samples:Array=[]
	for dx in [-.45,0.0,.45]:
		for dz in [-.35,0.0,.35]:
			var origin:=c.global_position+Vector3(dx,.5,dz)
			var query:=PhysicsRayQueryParameters3D.create(origin,origin-Vector3.UP*3)
			query.exclude=[c,player]
			var hit:=get_world_3d().direct_space_state.intersect_ray(query)
			if not hit.is_empty():samples.append({"point":str(hit.position),"support_y":hit.position.y,"gap_m":bounds.position.y-hit.position.y,"cabinet_gap_m":cabinet_bottom-hit.position.y,"normal":str(hit.normal),"collider":String(hit.collider.get_class())})
	var info:Dictionary={"id":label,"pose":str(c.transform),"element":str(c.element),"body_transform":str(collider_before),"body_size":str(c._collision_shapes[0].shape.size),"closed_bounds":str(bounds),"bottom_world":bounds.position.y,"cabinet_bottom_world":cabinet_bottom,"support_samples":samples}
	if geometry.has("seating"):
		check(not samples.is_empty(),label+" actual supporting surface measured")
		for sample in samples:check(float(sample.cabinet_gap_m)>=-.0001,label+" cabinet clears retained surface")
	camera.position=c.global_position+(Vector3(-1.3,.8,-1.9) if label=="original-paid-home" else Vector3(1.3,.8,1.9));camera.look_at(c.global_position+Vector3(0,-.1,0));caption.text="R5 / "+label+" / retained geometry and paid chest"
	await RenderingServer.frame_post_draw;get_viewport().get_texture().get_image().save_png(output+"/"+label+"-closed.png")
	check(_aim(c,c.global_position+(Vector3(-1,.8,-1.6) if label=="original-paid-home" else Vector3(0,.8,2)),c.global_position+Vector3(0,-.1,0)),label+" actual interaction ray")
	player.interact();check(player.chest_panel.is_open() and player.chest_panel.chest==c,label+" native panel identity")
	player.chest_panel.hide()
	for frame in 40:await get_tree().physics_frame
	camera.position=c.global_position+(Vector3(-1.6,1.15,-2.5) if label=="original-paid-home" else Vector3(1.6,1.15,2.5));camera.look_at(c.global_position+Vector3(0,.2,0))
	info.open_bounds=str(mesh_bounds(body));caption.text="R5 / "+label+" / actual open storage panel, canvas hidden"
	await RenderingServer.frame_post_draw;get_viewport().get_texture().get_image().save_png(output+"/"+label+"-open.png")
	player.chest_panel.close_panel();player.chest_panel.show()
	check(c.transform==before and c._collision_shapes[0].transform==collider_before,label+" native transform/body remain exact")
	r5terrain.cases.append(info)
