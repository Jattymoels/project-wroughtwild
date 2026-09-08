extends "res://scripts/sandpit.gd"
## Actual finite ledger, normal work, stream retirement and schema-2 disk reload.
var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL ENVIRONMENT: ",label)

func _ready() -> void:
	world_profile = "frontier_v6"
	_build_world(77)
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.placement.set_physics_process(false)
	player.combat.set_physics_process(false)
	mob_packs.set_process(false)
	mob_packs.set_physics_process(false)
	terrain.set_process(false)
	set_physics_process(false)
	var stream := terrain.resource_stream
	# Dynamic lookup lets the identical fixture expose the missing baseline layer.
	var canopies: Variant = stream.get("canopies")
	check(canopies != null,"surviving resources have a distant presentation")
	if canopies == null:
		_finish()
		return
	var before := JSON.stringify(stream.capture())
	canopies.rebuild()
	check(JSON.stringify(stream.capture())==before,"rebuilding presentation does not mutate the finite ledger")
	var id := ""
	for candidate: String in canopies.slots:
		if not stream.active.has(candidate): id=candidate; break
	check(not id.is_empty(),"actual world supplies an unloaded broadleaf resource")
	if id.is_empty():
		_finish()
		return
	var record: Dictionary = stream.records[id].duplicate(true)
	check(_shown(canopies,id),"unloaded surviving tree has one distant instance")
	check(_bodies(canopies.root)==0,"distant batches have no collision or harvest bodies")
	var mesh := AuthoredAssets.mesh_for("broadleaf_tree_far")
	var triangles := 0
	for surface in mesh.get_surface_count(): triangles += mesh.surface_get_array_index_len(surface)/3
	check(triangles>0 and triangles<2000,"distant silhouette uses fewer than 2000 triangles")
	check(AuthoredAssets.mesh_for("broadleaf_tree").get_aabb().grow(.001).encloses(mesh.get_aabb()),"distant silhouette stays inside the accepted tree envelope")
	var node := stream.materialise(id)
	check(node!=null and not _shown(canopies,id),"materialisation hides the distant instance immediately")
	check(node.remaining_units==record.remaining_units,"materialisation retains exact stock")
	var shape := node.get_node("CollisionShape3D").shape as BoxShape3D
	check(shape.size==Vector3(.7,3,.7),"the existing broadleaf body remains trunk-sized")
	check(node.get_node("MeshInstance3D").visibility_range_end>=stream.radius_m+stream.retire_margin_m,"near canopy remains visible through the complete retirement range")
	var at := node.position
	stream.focus(at+Vector3.RIGHT*400)
	check(not stream.active.has(id) and _shown(canopies,id),"retirement swaps one near tree for one distant tree")
	node=stream.materialise(id)
	var stock := node.remaining_units
	node.set_meta("immediate_world_mutation",true)
	var gathered := 0
	for press in 100:
		var result := node.work(player.combat.sim)
		gathered += int(result.get("granted",0))
		if node.remaining_units==0: break
	check(gathered==stock,"normal chop work grants exactly the original finite stock")
	await get_tree().process_frame
	check(not stream.has_resource(id) and not _shown(canopies,id),"depletion cannot resurrect a distant canopy")
	canopies.rebuild()
	check(not canopies.slots.has(id),"rebuilding after depletion tolerates stale spatial bucket IDs")
	var manager := SaveManager.new()
	var path := ProjectSettings.globalize_path("res://../build/environment-target/lifecycle-save.json")
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	check(manager.write(path,player),"depleted world writes to the isolated schema-2 save")
	check(manager.read(path,player),"normal disk reload succeeds")
	stream=terrain.resource_stream
	canopies=stream.get("canopies")
	check(not stream.records.has(id) and not canopies.slots.has(id),"reload derives canopies from saved survivors, not generated stock")
	var old_stream: WeakRef = weakref(stream)
	canopies=null
	stream=null
	# Normal terrain rebuild must release the old stream despite the visual layer.
	terrain.build(player.combat.sim,77,"frontier_v6")
	terrain.set_process(false)
	check(old_stream.get_ref()==null,"canopy ownership does not keep retired resource streams alive")
	_finish()

func _shown(canopies: Variant, id: String) -> bool:
	if not canopies.slots.has(id): return false
	var slot: Array = canopies.slots[id]
	var submitted: Transform3D = slot[2]
	# Dummy rendering returns identity from MultiMesh readback. The rendered run
	# additionally verifies the engine's actual pose, including collapsed scale.
	if DisplayServer.get_name()!="headless":
		check((slot[0] as MultiMesh).get_instance_transform(int(slot[1])).is_equal_approx(submitted),"renderer receives the exact ledger visibility pose")
	return absf(submitted.basis.determinant())>.01

func _bodies(node: Node) -> int:
	var count := 1 if node is CollisionObject3D or node is CollisionShape3D else 0
	for child in node.get_children(): count += _bodies(child)
	return count

func _finish() -> void:
	print("ENVIRONMENT_TARGET %d checks, %d failures" % [checks,failures])
	get_tree().quit(0 if failures==0 else 1)
