extends "res://tests/home_workshop_review.gd"
## Fixed inspection stock; actual paid placement and unchanged physical bodies.
const D3=preload("res://art07_d3/adapter.gd")
const SAVE:="user://d3-fine-coverings.json"
var rows:Array=[]

func _run() -> void:
	player.hud.hide(); player.position=Vector3(-15,2,-10)
	if OS.get_cmdline_user_args().has("--d3-restore"):
		var manager:=SaveManager.new()
		check(manager.read(SAVE,player),"fresh process reads D3 checkpoint: "+manager.last_error)
		var expected:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://art07_d3/expected.json"))
		check(sim.export_json()==expected.native,"fresh native ownership and progress exact")
		check(JSON.stringify(manager.capture(player).blocks)==expected.blocks,"every fine address/family restored exactly")
		check(sim.structure_piece_count()==int(expected.count),"one restored owner per paid piece")
		for child in get_children():
			if child is PlacedBlock and String(child.shape_id) in D3.IDS: await _bounds(child)
		await _blocking_and_shelter()
		_finish_d3("restart"); return
	var catalogue:Array=JSON.parse_string(FileAccess.get_file_as_string("res://art07_d3/assigned.json"))
	var build:=player.placement
	for family in sim.build_material_ids():
		sim.add_material(String(sim.build_material(family).source),4000)
	await get_tree().physics_frame
	var index:=0
	for entry:Dictionary in catalogue:
		var id:String=entry.id; var info:Dictionary=sim.shape(id)
		check(info.size==Vector3(entry.size_m[0],entry.size_m[1],entry.size_m[2]),id+" exact published dimensions")
		check(sim.shape_material_cost(id)==int(entry.material_cost),id+" unchanged cost")
		for family in sim.build_material_ids():
			var legal:bool=entry.allowed_materials.has(family)
			check(sim.shape_allows_family(id,family)==legal,id+" exact family gate "+family)
			if not legal:
				var before:=sim.export_json()
				check(not sim.pay_placement(id,family),id+" illegal payment refuses "+family)
				check(sim.export_json()==before,"illegal family retains all possessions")
		for family:String in entry.allowed_materials:
			for turn in 2:
				var kind:String="volume" if entry.element=="block" else "face" if entry.element in ["wall","floor"] else "edge"
				var axis:int=0 if kind=="volume" else 1 if entry.element in ["floor","post"] else turn*2
				# Odd addresses deliberately exercise the 0.5 m registry.
				var elem:Dictionary={"kind":kind,"axis":axis,"cell":Vector3i(1+(index%12)*4,3,1+(index/12 as int)*4)}
				build.set_build_mode_enabled(true); build.fine_mode=id.begins_with("half_"); build.selected_material_family=StringName(family); build.select_shape(StringName(entry.fine_of if id.begins_with("half_") else id))
				build.preview_element=elem; build.preview_visible=true; build.preview_rotation_step=0
				var source:String=sim.build_material(family).source
				var before:int=sim.material_count(source); var count:=sim.structure_piece_count()
				check(build.try_place_block(),id+" paid half-grid placement "+family+": "+build.preview_reason)
				check(sim.material_count(source)==before-int(entry.material_cost),id+" exact source payment "+source)
				check(sim.structure_piece_count()==count+1,id+" exactly one owner")
				var block:=_piece(elem)
				check(block!=null,id+" real usable scene object")
				if block!=null: await _bounds(block)
				check(not build.try_place_block(),id+" occupied footprint refused")
				check(sim.material_count(source)==before-int(entry.material_cost) and sim.structure_piece_count()==count+1,"failed placement retains stock/count")
				index+=1
	await _joins()
	await _blocking_and_shelter()
	var manager:=SaveManager.new()
	check(manager.write(SAVE,player),"atomic isolated save")
	var expected:Dictionary={"native":sim.export_json(),"blocks":JSON.stringify(manager.capture(player).blocks),"count":sim.structure_piece_count()}
	FileAccess.open("res://art07_d3/expected.json",FileAccess.WRITE).store_string(JSON.stringify(expected))
	check(manager.read(SAVE,player),"same-process restore")
	check(sim.export_json()==expected.native and JSON.stringify(manager.capture(player).blocks)==expected.blocks,"same-process exact possessions and records")
	_finish_d3("placement")

func _bounds(block:PlacedBlock) -> void:
	var id:=String(block.shape_id); var mesh:Mesh=block._mesh.mesh
	var visual:=mesh.get_aabb(); var native:Dictionary=PieceMesh.collision_for(block.form,block.size)[0]
	var body:AABB=native.transform*native.shape.get_debug_mesh().get_aabb()
	check(visual.position.is_equal_approx(body.position) and visual.size.is_equal_approx(body.size),id+" imported bounds match native collision")
	check(mesh==D3.mesh_for(id,String(block.material_family)),id+" actual imported candidate used")
	check(mesh.get_surface_count()==(2 if id in ["light_panel","glazed_window"] else 1),id+" complete material roles")
	var pose:Dictionary=player.placement.piece_pose(id,block.element,block.rotation_step)
	check(block.global_transform.is_equal_approx(Transform3D(Basis(Vector3.UP,pose.yaw),pose.centre)),id+" native registry pivot/yaw")
	var proxy:=StaticBody3D.new(); var shape:=CollisionShape3D.new(); shape.shape=mesh.create_trimesh_shape(); proxy.add_child(shape); add_child(proxy)
	proxy.global_transform=block.global_transform; proxy.collision_layer=1<<19
	var old_layer:=block.collision_layer; block.collision_layer=1<<20
	await get_tree().physics_frame
	var maximum_gap:=0.0
	var triangle_edge_retries:=0
	for u in [-.49,-.46,-.3,0.0,.3,.46,.49]:
		for v in [-.49,-.46,-.3,0.0,.3,.46,.49]:
			for signum in [-1,1]:
				var p:=Vector3(u*body.size.x,v*body.size.y,0)
				var from:Vector3=block.to_global(p+Vector3(0,0,signum*2)); var to:Vector3=block.to_global(p-Vector3(0,0,signum*2))
				var q:=PhysicsRayQueryParameters3D.create(from,to,1<<19)
				var visible:=get_world_3d().direct_space_state.intersect_ray(q); q.collision_mask=1<<20
				var solid:=get_world_3d().direct_space_state.intersect_ray(q)
				# Rotated negative-coordinate samples can land exactly on an exported
				# triangle edge. Require ALL four 10-micrometre neighbours to hit;
				# a real slit (including the rejected 4 mm shelf joint) still fails.
				if visible.is_empty() and not solid.is_empty():
					var neighbours:=true
					var recovered:Dictionary={}
					for jitter in [Vector3(.00001,0,0),Vector3(-.00001,0,0),Vector3(0,.00001,0),Vector3(0,-.00001,0)]:
						var world_jitter:Vector3=block.global_basis*jitter
						var retry:=PhysicsRayQueryParameters3D.create(from+world_jitter,to+world_jitter,1<<19)
						recovered=get_world_3d().direct_space_state.intersect_ray(retry)
						neighbours=neighbours and not recovered.is_empty()
					if neighbours: visible=recovered; triangle_edge_retries+=1
				check(not visible.is_empty() and not solid.is_empty(),id+" front/back complete infill and four frame corners")
				if not visible.is_empty() and not solid.is_empty():
					var gap:float=visible.position.distance_to(solid.position); maximum_gap=maxf(maximum_gap,gap)
					# Existing infill is 24% of the 160 mm body; keep that 60.8 mm
					# physical inset, never shrink collision to the thin glass surface.
					check(gap<(.062 if id in ["light_panel","glazed_window"] else .006),id+" existing infill/body or fine detail allowance")
	block.collision_layer=old_layer; proxy.free()
	rows.append({"shape":id,"family":String(block.material_family),"visual":str(visual),"pose":str(block.global_transform),"max_inset_m":maximum_gap,"triangle_edge_retries":triangle_edge_retries})

func _joins() -> void:
	var build:=player.placement
	# Full-height post with two half posts stacked on its top, joined to a half
	# rail and shelf. Contact is checked on actual imported vertices/AABBs.
	var e:Dictionary={"kind":"edge","axis":1,"cell":Vector3i(-10,0,8)}
	build.place_piece(e,&"pillar",&"wood")
	var base:=_piece(e); var last_top:float=base.global_position.y+base._mesh.mesh.get_aabb().end.y
	for y in [2,3]:
		e={"kind":"edge","axis":1,"cell":Vector3i(-10,y,8)}
		build.place_piece(e,&"half_pillar",&"wood"); var post:=_piece(e)
		check(is_equal_approx(post.global_position.y+post._mesh.mesh.get_aabb().position.y,last_top),"exact coarse/fine stacked post contact")
		last_top=post.global_position.y+post._mesh.mesh.get_aabb().end.y
	e={"kind":"edge","axis":0,"cell":Vector3i(-10,4,8)}; build.place_piece(e,&"half_beam",&"wood")
	var rail:=_piece(e)
	check(is_equal_approx(rail.global_position.y,last_top),"half rail centre follows post endpoint on fine registry")
	e={"kind":"face","axis":1,"cell":Vector3i(-10,4,8)}; build.place_piece(e,&"half_slab",&"wood")
	var shelf:=_piece(e)
	check(is_equal_approx(shelf.global_position.y,rail.global_position.y),"shelf and rail share native plane")
	check(rail.size.y>shelf.size.y,"rail exposes both edges beyond shelf; no coplanar skins")
	for pair in [["cube","half_cube","volume",0],["wall_panel","half_wall","face",2],["floor_slab","half_slab","face",1],["beam","half_beam","edge",0]]:
		var cell:=Vector3i(-8,4,10)
		# Separate each element kind so intended face/volume overlap remains legal.
		e={"kind":pair[2],"axis":pair[3],"cell":cell}
		build.place_piece(e,StringName(pair[0]),&"wood")
		check(not sim.structure_free_for(pair[1],e),"coarse footprint blocks its fine twin "+pair[1])
		var next:=e.duplicate(); next.cell=cell+Vector3i(2,0,0)
		check(sim.structure_free_for(pair[1],next),"fine twin fits immediately beside coarse boundary "+pair[1])
		build.place_piece(next,StringName(pair[1]),&"wood")
		var coarse:=_piece(e); var small:=_piece(next)
		var a:AABB=coarse.global_transform*coarse._mesh.mesh.get_aabb(); var b:AABB=small.global_transform*small._mesh.mesh.get_aabb()
		check(is_equal_approx(a.end.x,b.position.x),"exact imported coarse/fine seam "+pair[1])

func _blocking_and_shelter() -> void:
	var build:=player.placement
	# A disposable native enclosure. Rebuild only in this fixture, not saved homes.
	if _piece({"kind":"face","axis":1,"cell":Vector3i(-26,0,0)})==null:
		for x in 2:
			for z in 2:
				for y in [0,3]: build.place_piece({"kind":"face","axis":1,"cell":Vector3i(-26+x*2,y*2,z*2)},&"floor_slab",&"wood")
		for i in 2:
			for y in 3:
				for x in [-26,-22]: build.place_piece({"kind":"face","axis":0,"cell":Vector3i(x,y*2,i*2)},&"light_panel",&"woven_reed")
				for z in [0,4]: build.place_piece({"kind":"face","axis":2,"cell":Vector3i(-26+i*2,y*2,z)},&"glazed_window",&"cinderglass")
	check(build.enclosure_at(Vector3(-12,1.5,1)).enclosed,"light coverings and fixed panes seal native shelter")
	await get_tree().physics_frame
	for spec in [["light_panel",Vector3i(-26,2,0),0],["glazed_window",Vector3i(-26,2,0),2]]:
		var elem:Dictionary={"kind":"face","axis":spec[2],"cell":spec[1]}; var block:=_piece(elem)
		check(block!=null,"blocking fixture exists "+spec[0]); if block==null: continue
		var layer:=block.collision_layer; block.collision_layer=1<<20
		await get_tree().physics_frame
		for signum in [-1,1]:
			var start:Vector3=block.to_global(Vector3(0,0,signum*.8)); var end:Vector3=block.to_global(Vector3(0,0,-signum*.8))
			check(not get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(start,end,1<<20)).is_empty(),spec[0]+" blocks projectile path from both sides")
			var mover:=CharacterBody3D.new(); var capsule:=CapsuleShape3D.new(); capsule.radius=.29; capsule.height=1.92
			var cs:=CollisionShape3D.new(); cs.shape=capsule; mover.add_child(cs); add_child(mover); mover.global_position=start; mover.collision_mask=1<<20
			await get_tree().physics_frame
			check(mover.move_and_collide(end-start)!=null,spec[0]+" actual swept player-size capsule blocked")
			mover.free()
		block.collision_layer=layer
		for signum in [-1,1]:
			var start:Vector3=block.to_global(Vector3(0,0,signum*.8))
			var toward:Vector3=block.global_basis*Vector3(0,0,-signum)
			var arrow:=SkillProjectile.launch(&"prototype_bow_shot",player.combat,self,start,toward,0,[])
			arrow.set_physics_process(false)
			arrow.advance(.1)
			check(arrow.spent,spec[0]+" actual ordinary arrow stops at the covering from either side")
			check(arrow.sweep.is_colliding() and arrow.sweep.get_collider(0)==block,spec[0]+" arrow hits this exact native owner")
			await get_tree().process_frame
		check(sim.structure_remove(elem),"temporarily remove native face for shelter control")
		check(not build.enclosure_at(Vector3(-12,1.5,1)).enclosed,"missing "+spec[0]+" opens shelter")
		check(sim.structure_place(elem,String(block.shape_id),String(block.material_family),0),"restore same native face without new ownership")
		check(build.enclosure_at(Vector3(-12,1.5,1)).enclosed,"restored face seals again")

func _finish_d3(stage:String) -> void:
	FileAccess.open("res://art07_d3/check-"+stage+".json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows},"\t"))
	print("D3_",stage.to_upper()," ",checks," checks, ",failures," failures")
	# Let deferred preview/trim and restored-node deletion settle before renderer
	# teardown; this fixture changes many multi-surface owners in one process.
	player.placement.set_build_mode_enabled(false)
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit(1 if failures else 0)
