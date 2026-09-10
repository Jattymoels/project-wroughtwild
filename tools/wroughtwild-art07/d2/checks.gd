extends "res://tests/home_workshop_review.gd"
## Fixed inspection stock; actual native placement, bodies, ownership and restart.
const D2 = preload("res://art07_d2/adapter.gd")
const SAVE := "user://d2-roofs.json"
var rows: Array=[]

func _run() -> void:
	player.hud.hide()
	if OS.get_cmdline_user_args().has("--d2-restore"):
		var manager:=SaveManager.new()
		check(manager.read(SAVE,player),"fresh process restores exact D2 checkpoint: "+manager.last_error)
		var expected:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://art07_d2/expected.json"))
		check(sim.export_json()==expected.native,"native possessions/effects unchanged across process")
		check(JSON.stringify(manager.capture(player).blocks)==expected.blocks,"all saved lattice records restored exactly")
		check(sim.structure_piece_count()==int(expected.count),"restart creates one piece per saved record")
		for block in get_children():
			if block is PlacedBlock: await _bounds(block)
		_finish_d2("restart")
		return
	var catalogue:Array=JSON.parse_string(FileAccess.get_file_as_string("res://art07_d2/assigned.json"))
	var build:=player.placement
	for family in ["wood","stone","iron_ingot","bronze_ingot"]: sim.add_material(family,500)
	for id in ["codex_roof_slope","codex_roof_hip","codex_roof_valley","roof_wedge"]:
		check(not sim.shape_unlocked(id),id+" retains existing world unlock before inspection grant")
	sim.record_world_effect("stonecut_blocks")
	player.position=Vector3(-15,2,-10)
	await get_tree().physics_frame
	for index in catalogue.size():
		var entry:Dictionary=catalogue[index]
		var id:String=entry.id
		var info:Dictionary=sim.shape(id)
		check(info.size==Vector3(entry.size_m[0],entry.size_m[1],entry.size_m[2]),id+" current native dimensions")
		check(sim.shape_material_cost(id)==int(entry.material_cost),id+" unchanged cost")
		for family in sim.build_material_ids():
			check(sim.shape_allows_family(id,family)==entry.allowed_materials.has(family),id+" exact material gate "+family)
		for turn in (8 if id=="door" else 4):
			var kind:String="volume" if entry.element=="block" else "face" if entry.element in ["wall","floor"] else "edge"
			var axis:int=0 if kind=="volume" else (0 if turn<4 else 2) if id=="door" else (turn%2)*2
			var elem:Dictionary={"kind":kind,"axis":axis,"cell":Vector3i(index*4,2,turn*4)}
			var family:String="stone" if id=="roof_wedge" else "iron" if id=="girder" else "bronze" if id=="arch" else "wood"
			var item:String=sim.build_material(family).get("source",family)
			build.set_build_mode_enabled(true); build.fine_mode=false; build.select_shape(StringName(id)); build.selected_material_family=StringName(family)
			build.preview_element=elem; build.preview_visible=true; build.preview_rotation_step=(turn/2 as int)%2 if id=="door" else turn if entry.oriented else 0
			var before:int=sim.material_count(item); var count:int=sim.structure_piece_count()
			check(build.try_place_block(),id+" real coarse placement rotation "+str(turn)+": "+build.preview_reason)
			check(sim.material_count(item)==before-int(entry.material_cost),id+" spends exact material once")
			check(sim.structure_piece_count()==count+1,id+" creates exactly one registered usable object")
			var block:PlacedBlock
			for child in get_children():
				if child is PlacedBlock and child.element==elem: block=child
			check(block!=null,id+" registered record has a real scene object")
			if block!=null:
				if id=="door" and turn%2==1:
					var aim:=Camera3D.new(); add_child(aim)
					aim.global_position=block.leaf_point()+block.global_basis.z*1.5
					aim.look_at(block.leaf_point()); player.camera=aim
					await get_tree().physics_frame
					player.interact()
					check(block.open,"actual E opens native door before checkpoint")
				await _bounds(block)
				check(block.global_transform.is_equal_approx(Transform3D(Basis(Vector3.UP,build.piece_pose(id,elem,build.preview_rotation_step).yaw),build.piece_pose(id,elem,build.preview_rotation_step).centre)),id+" native face/edge pivot and yaw")
			check(not build.try_place_block(),id+" duplicate footprint refuses")
			check(sim.material_count(item)==before-int(entry.material_cost) and sim.structure_piece_count()==count+1,id+" failed placement retains materials and object count")
			if entry.element=="block": check(not sim.structure_free_for("cube",elem),"roof reserves whole native cell despite half-height art")
	var gate_before:String=sim.export_json()
	check(not sim.pay_placement("arch","stone"),"stone arch remains ineligible")
	check(not sim.pay_placement("door","stone"),"stone door remains ineligible")
	check(not sim.pay_placement("girder","wood"),"wood cannot pay for metal span")
	check(not sim.pay_placement("roof_wedge","wood"),"timber cannot pay for full masonry wedge")
	check(sim.export_json()==gate_before,"refused family gates change no inventory or progress")
	var manager:=SaveManager.new()
	check(manager.write(SAVE,player),"atomic isolated D2 checkpoint saved")
	var expected:Dictionary={"native":sim.export_json(),"blocks":JSON.stringify(manager.capture(player).blocks),"count":sim.structure_piece_count()}
	FileAccess.open("res://art07_d2/expected.json",FileAccess.WRITE).store_string(JSON.stringify(expected))
	check(manager.read(SAVE,player),"same-process read restores D2 models")
	check(sim.export_json()==expected.native and JSON.stringify(manager.capture(player).blocks)==expected.blocks,"same-process ownership and saved addresses exact")
	_finish_d2("placement")

func _bounds(block: PlacedBlock) -> void:
	var mesh:Mesh=block._mesh.mesh
	var visual:AABB=mesh.get_aabb()
	var collision:AABB
	var first:=true
	for part in PieceMesh.collision_for(block.form,block.size):
		var box:AABB=part.transform*part.shape.get_debug_mesh().get_aabb()
		collision=box if first else collision.merge(box); first=false
	check(visual.position.is_equal_approx(collision.position) and visual.size.is_equal_approx(collision.size),String(block.shape_id)+" imported visual and unchanged body bounds match")
	check(mesh.get_surface_count()==1,String(block.shape_id)+" one material surface")
	var expected:Mesh=D2.mesh_for(String(block.shape_id))
	check(mesh==expected,String(block.shape_id)+" placed object uses actual imported D2 candidate")
	var native_parts:Array=PieceMesh.collision_for(block.form,block.size)
	check(block._collision_shapes.size()==native_parts.size(),"unchanged native collider count")
	for i in native_parts.size():
		var actual:CollisionShape3D=block._collision_shapes[i]
		var expected_shape:Shape3D=native_parts[i].shape
		check(actual.shape.get_class()==expected_shape.get_class(),"native collider class retained")
		if expected_shape is BoxShape3D: check(actual.shape.size==expected_shape.size,"native box dimensions exact")
		if expected_shape is ConvexPolygonShape3D: check(actual.shape.points==expected_shape.points,"native convex vertices exact")
		if block.is_door(): check(actual.global_transform.is_equal_approx(block._mesh.global_transform),"door visible leaf and collision share exact current pivot")
		else: check(actual.transform.is_equal_approx(native_parts[i].transform),"static collision transform exact")
	# Physical ray silhouette is paired with the actual visual triangle mesh, not only AABB.
	var body:=StaticBody3D.new(); var shape:=CollisionShape3D.new(); shape.shape=mesh.create_trimesh_shape(); body.add_child(shape); add_child(body)
	body.global_transform=block._mesh.global_transform; body.collision_layer=1<<19
	# The established arch has a twelve-strip visual but three simple colliders.
	# Compare its candidate silhouette to the unchanged native VISUAL, while the
	# preceding assertions retain every actual collider. Do not smooth either one.
	var arch_reference:StaticBody3D
	if block.form=="arch":
		arch_reference=StaticBody3D.new(); var c:=CollisionShape3D.new()
		c.shape=PieceMesh.mesh_for("arch",block.size).create_trimesh_shape(); arch_reference.add_child(c); add_child(arch_reference)
		arch_reference.global_transform=block.global_transform; arch_reference.collision_layer=1<<21
	var old_layer:int=block.collision_layer
	block.collision_layer=1<<20
	await get_tree().physics_frame
	for axis in 3:
		for u in [-.31,-.11,.11,.31]:
			# Offset sample axes avoid ambiguous zero-area hits on the diagonal edge.
			for v in [-.29,-.09,.13,.33]:
				var mid:=collision.get_center(); var others:Array=[0,1,2]; others.erase(axis)
				mid[others[0]]+=u*collision.size[others[0]]; mid[others[1]]+=v*collision.size[others[1]]
				for signum in [-1,1]:
					var offset:=Vector3.ZERO; offset[axis]=2*signum
					var from:Vector3=block._mesh.to_global(mid+offset); var to:Vector3=block._mesh.to_global(mid-offset)
					var q:=PhysicsRayQueryParameters3D.create(from,to,1<<19)
					var visible:Dictionary=get_world_3d().direct_space_state.intersect_ray(q)
					q.collision_mask=1<<21 if block.form=="arch" else 1<<20
					var solid:Dictionary=get_world_3d().direct_space_state.intersect_ray(q)
					check(solid.is_empty()==visible.is_empty(),String(block.shape_id)+" candidate silhouette agrees with native reference")
					if not solid.is_empty() and not visible.is_empty():
						# Six mm vertical relief projects to twelve mm along the
						# half-height roof's horizontal ray (rise/run = 0.5).
						var allowance:float=.014 if block.form.begins_with("roof_") else .01
						check(visible.position.distance_to(solid.position)<allowance,String(block.shape_id)+" surface stays inside documented detail allowance "+str(allowance))
	block.collision_layer=old_layer
	if arch_reference!=null: arch_reference.free()
	body.free()
	rows.append({"shape":String(block.shape_id),"visual":str(visual),"body":str(collision),"pose":str(block.global_transform)})

func _finish_d2(stage: String) -> void:
	FileAccess.open("res://art07_d2/check-"+stage+".json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows},"\t"))
	print("D2_",stage.to_upper()," ",checks," checks, ",failures," failures")
	get_tree().quit(1 if failures else 0)
