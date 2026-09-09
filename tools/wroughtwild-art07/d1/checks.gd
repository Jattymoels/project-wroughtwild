extends "res://tests/home_workshop_review.gd"
## Fixed inspection stock; actual native placement, bodies, ownership and restart.
const D1 = preload("res://art07_d1/adapter.gd")
const SAVE := "user://d1-core.json"
var rows: Array=[]

func _run() -> void:
	player.hud.hide()
	if OS.get_cmdline_user_args().has("--d1-restore"):
		var manager:=SaveManager.new()
		check(manager.read(SAVE,player),"fresh process restores exact D1 checkpoint: "+manager.last_error)
		var expected:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://art07_d1/expected.json"))
		check(sim.export_json()==expected.native,"native possessions/effects unchanged across process")
		check(JSON.stringify(manager.capture(player).blocks)==expected.blocks,"all saved lattice records restored exactly")
		check(sim.structure_piece_count()==int(expected.count),"restart creates one piece per saved record")
		for block in get_children():
			if block is PlacedBlock: await _bounds(block)
		_finish_d1("restart")
		return
	var catalogue:Array=JSON.parse_string(FileAccess.get_file_as_string("res://art07_d1/assigned.json"))
	var build:=player.placement
	sim.add_material("wood",2000); sim.add_material("fieldstone",200)
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
		for turn in 4:
			var kind:String="volume" if entry.element=="block" else "face" if entry.element in ["wall","floor"] else "edge"
			var axis:int=0 if kind=="volume" else 1 if entry.element in ["floor","post"] else (turn%2)*2
			var elem:Dictionary={"kind":kind,"axis":axis,"cell":Vector3i(index*4,2,turn*4)}
			var family:String="fieldstone" if id in ["foundation","dry_wall"] else "wood"
			build.set_build_mode_enabled(true); build.fine_mode=false; build.select_shape(StringName(id)); build.selected_material_family=StringName(family)
			build.preview_element=elem; build.preview_visible=true; build.preview_rotation_step=turn if entry.oriented else 0
			var before:int=sim.material_count(family); var count:int=sim.structure_piece_count()
			check(build.try_place_block(),id+" real coarse placement rotation "+str(turn)+": "+build.preview_reason)
			check(sim.material_count(family)==before-int(entry.material_cost),id+" spends exact material once")
			check(sim.structure_piece_count()==count+1,id+" creates exactly one registered usable object")
			var block:PlacedBlock
			for child in get_children():
				if child is PlacedBlock and child.element==elem: block=child
			check(block!=null,id+" registered record has a real scene object")
			if block!=null:
				await _bounds(block)
				check(block.global_transform.is_equal_approx(Transform3D(Basis(Vector3.UP,build.piece_pose(id,elem,build.preview_rotation_step).yaw),build.piece_pose(id,elem,build.preview_rotation_step).centre)),id+" native face/edge pivot and yaw")
			check(not build.try_place_block(),id+" duplicate footprint refuses")
			check(sim.material_count(family)==before-int(entry.material_cost) and sim.structure_piece_count()==count+1,id+" failed placement retains materials and object count")
	# The low shapes reserve full elements; their empty upper halves grant no extra occupancy.
	var low:Dictionary={"kind":"volume","axis":0,"cell":Vector3i(32,2,0)}
	check(not sim.structure_free_for("cube",low),"footing still reserves its full cell")
	var gate_before:String=sim.export_json()
	check(not sim.pay_placement("cube","fieldstone"),"fieldstone cannot pay for a full house cube")
	check(not sim.pay_placement("foundation","wood"),"timber cannot pay for rough-only footing")
	check(sim.export_json()==gate_before,"refused family gates change no inventory or progress")
	var manager:=SaveManager.new()
	check(manager.write(SAVE,player),"atomic isolated D1 checkpoint saved")
	var expected:Dictionary={"native":sim.export_json(),"blocks":JSON.stringify(manager.capture(player).blocks),"count":sim.structure_piece_count()}
	FileAccess.open("res://art07_d1/expected.json",FileAccess.WRITE).store_string(JSON.stringify(expected))
	check(manager.read(SAVE,player),"same-process read restores D1 models")
	check(sim.export_json()==expected.native and JSON.stringify(manager.capture(player).blocks)==expected.blocks,"same-process ownership and saved addresses exact")
	_finish_d1("placement")

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
	var expected:Mesh=D1.mesh_for(String(block.shape_id))
	check(mesh==expected,String(block.shape_id)+" placed object uses actual imported D1 candidate")
	# Physical ray silhouette is paired with the actual visual triangle mesh, not only AABB.
	var body:=StaticBody3D.new(); var shape:=CollisionShape3D.new(); shape.shape=mesh.create_trimesh_shape(); body.add_child(shape); add_child(body)
	body.global_transform=block.global_transform; body.collision_layer=1<<19
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
					var from:Vector3=block.to_global(mid+offset); var to:Vector3=block.to_global(mid-offset)
					var q:=PhysicsRayQueryParameters3D.create(from,to,1<<19)
					var visible:Dictionary=get_world_3d().direct_space_state.intersect_ray(q)
					q.collision_mask=1<<20
					var solid:Dictionary=get_world_3d().direct_space_state.intersect_ray(q)
					check(solid.is_empty()==visible.is_empty(),String(block.shape_id)+" real body/visual silhouette agrees, including empty clipped half")
					if not solid.is_empty() and not visible.is_empty():
						var allowance:float=.065 if block.form=="low" else .01
						check(visible.position.distance_to(solid.position)<allowance,String(block.shape_id)+" surface stays inside documented detail allowance "+str(allowance))
	block.collision_layer=old_layer
	body.free()
	rows.append({"shape":String(block.shape_id),"visual":str(visual),"body":str(collision),"pose":str(block.global_transform)})

func _finish_d1(stage: String) -> void:
	FileAccess.open("res://art07_d1/check-"+stage+".json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows},"\t"))
	print("D1_",stage.to_upper()," ",checks," checks, ",failures," failures")
	get_tree().quit(1 if failures else 0)
