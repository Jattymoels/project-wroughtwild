class_name ForgeDungeon
extends Node3D
## Eight authored module treatments arranged by the sim's floor topology.
## One floor exists at a time. Floor polygons are authored from the same walk
## rectangles and cover footprints as collision, using Godot navigation.
const LOOK = preload("res://art/forge_look.tres")
const FIXTURE = preload("res://scripts/trial_fixture.gd")
var rooms: Dictionary = {}
var fixtures: Array = []
var spine_gates: Dictionary = {}
var floor_rects: Array[Rect2] = []
var obstacles: Array[Rect2] = []
var region: NavigationRegion3D
var navigation_map := RID()
var entry := Vector3(0, 0.5, 8)
var boundary: TrialFixture
var secret: TrialFixture
var reward: TrialFixture
var floor_index := 0
var _materials: Dictionary = {}
var _box_meshes: Dictionary = {}
var _walk_cells: Dictionary = {}
var module_ids: Array[String] = []
var navigation_build_count := 0
var navigation_last_build_usec := 0
var navigation_peak_build_usec := 0
var _authored_obstacles: Array[Rect2] = []
var _authored_walk_cells: Dictionary = {}
var _authored_cells_ready := false
var _fixture_obstacles: Array[Rect2] = []
var _navigation_fixture_ids: Dictionary = {}
var _navigation_refresh_queued := false
var _navigation_closing := false

func _exit_tree() -> void:
	_navigation_closing = true
	_navigation_refresh_queued = false
	if navigation_map.is_valid():
		NavigationServer3D.free_rid(navigation_map)
		navigation_map = RID()

func build(layout: Dictionary, which_floor: int) -> void:
	floor_index = which_floor
	var stages: Array = []
	for stage in layout.get("stages", []):
		if int(stage.get("floor_index", 0)) == which_floor:
			stages.append(stage)
	var depth := maxf(32.0, float(stages.size()) * LOOK.row_spacing + 22.0)
	_floor(Rect2(-LOOK.gallery_width * 0.5, -depth + 10.0, LOOK.gallery_width, depth + 20.0))
	_box(Vector3(0, LOOK.wall_height, -depth * 0.5 + 20), Vector3(LOOK.gallery_width + 1, .6, depth + 20), LOOK.stone, true)
	for i in stages.size():
		var stage: Dictionary = stages[i]
		var index := int(stage.get("index", i))
		var z := -12.0 - float(i) * LOOK.row_spacing
		var choices: Array = stage.get("choices", [])
		for c in choices.size():
			var choice: Dictionary = choices[c]
			var side := -1.0 if c % 2 == 0 else 1.0
			var centre := Vector3(side * LOOK.wing_offset, 0, z)
			var module := String(choice.get("module", "loading_yard"))
			_module(centre, module, i + which_floor, side)
			var key := "%d:%d" % [index, c]
			var inward := centre.x - side * LOOK.room_width * .5
			var plaque_at := Vector3(side * (LOOK.gallery_width * .5 - LOOK.route_gallery_edge_inset_m), 0,
				z + LOOK.route_approach_offset_m)
			var plate := _fixture("route", plaque_at, String(choice.get("display_name", module)), "enter")
			plate.stage_index = index
			plate.choice_index = c
			plate.entry_point = centre + Vector3(-side * 6, .5, 3)
			plate.payload = choice
			plate.rotation.y = side * PI * .5
			var seal := _box(Vector3(inward, 2.2, z + 3), Vector3(.45, 4.4, LOOK.doorway_width), LOOK.iron, true, false)
			rooms[key] = {"centre": centre, "rect": Rect2(centre.x-10, z-12, 20, 24), "door": plate, "seal": seal, "module": module,
				"reward_at": centre + Vector3(side * 4, .0, -8), "spawn_at": centre + Vector3(side * 2, .5, -3)}
			module_ids.append(module)
		var gate_z := z - LOOK.room_depth * .5 - 3.0
		spine_gates[index] = _box(Vector3(0, 2.6, gate_z), Vector3(LOOK.gallery_width, 5.2, .5), LOOK.iron, true, false)
		_arch(Vector3(0, 0, gate_z), LOOK.gallery_width)
		_light(Vector3(0, 4.8, z + 10), Color("d6b286"), 12, .9)
		# Solid gallery rails between branch entrances, so the kit is a place,
		# not a set of disconnected platforms over a void.
		for side in [-1.0, 1.0]:
			# Only the actual corridor floor (z+.5 through z+5.5) is open.
			# Wider decorative gaps let strafing players step into the void.
			for span in [Vector2(z-8.25, 17.5), Vector2(z+11.25, 11.5)]:
				_box(Vector3(side * 5.0, 3.5, span.x), Vector3(.6, 7, span.y), LOOK.stone, true)
			if (side>0 and choices.size()<2) or choices.is_empty():
				_box(Vector3(side*5,3.5,z+3),Vector3(.6,7,LOOK.doorway_width),LOOK.stone,true)
	var end_z := -12.0 - float(maxi(stages.size()-1, 0)) * LOOK.row_spacing - 23.0
	boundary = _fixture("boundary", Vector3(0, 0, end_z), "The descent lift", "choose the next floor")
	if which_floor + 1 >= int(layout.get("floor_count", 2)):
		boundary.title = "End of gallery"
		boundary.payload["terminal"] = true
		boundary.refresh()
	# Secret is on the first floor only; both variants occupy real side space.
	if which_floor == 0:
		var s := -1.0 if int(layout.get("seed", 0)) % 2 == 0 else 1.0
		var secret_centre := Vector3(s * 18, 0, 22)
		_floor(Rect2(secret_centre.x-10, 12, 20, 20))
		_floor(Rect2(minf(0, secret_centre.x), 14, absf(secret_centre.x), 8))
		for z in [12.0,32.0]:
			_box(Vector3(secret_centre.x,3.5,z),Vector3(20,7,.8),LOOK.stone,true)
		_box(Vector3(s*28,3.5,22),Vector3(.8,7,20),LOOK.stone,true)
		for span in [Vector2(12,14),Vector2(22,32)]:
			_box(Vector3(s*8,3.5,(span.x+span.y)*.5),Vector3(.6,7,span.y-span.x),LOOK.stone,true)
		_box(secret_centre+Vector3(0,7.3,0),Vector3(20,.6,20),LOOK.stone,true)
		_module_dress(secret_centre, "secret_crucible", int(layout.get("seed", 0)) % 2)
		secret = _fixture("secret", Vector3(s * 27, 0, 23), "Loose furnace catch" if s < 0 else "Hollow cistern stone", "search the hidden store")
		secret.available = true
		secret.refresh()
	# Close the gallery's entry and lift aprons. The chosen secret corridor
	# retains its full eight-metre opening and solid side rails.
	var secret_side := -1.0 if int(layout.get("seed",0))%2==0 else 1.0
	for side in [-1.0,1.0]:
		var spans:Array=[Vector2(5,30)]
		if which_floor==0 and side==secret_side: spans=[Vector2(5,14),Vector2(22,30)]
		for span in spans:
			_box(Vector3(side*5,3.5,(span.x+span.y)*.5),Vector3(.6,7,span.y-span.x),LOOK.stone,true)
		_box(Vector3(side*5,3.5,-depth+18.5),Vector3(.6,7,17),LOOK.stone,true)
	for z in [-depth+10,30.0]:
		_box(Vector3(0,3.5,z),Vector3(10,7,.6),LOOK.stone,true)
	if which_floor==0:
		for z in [14.0,22.0]:
			_box(Vector3(secret_side*6.5,3.5,z),Vector3(3,7,.6),LOOK.stone,true)
	# Read actual collider poses after route plaque yaw is applied. Pedestals
	# share the cover clearance map, including offerings and later conduits.
	_authored_obstacles.assign(obstacles)
	_refresh_fixture_obstacles()
	_build_navigation()

func _refresh_fixture_obstacles() -> void:
	obstacles.assign(_authored_obstacles)
	_fixture_obstacles.clear()
	_navigation_fixture_ids.clear()
	var live: Array = []
	for candidate in fixtures:
		if not is_instance_valid(candidate) or candidate.is_queued_for_deletion() or not candidate.is_inside_tree(): continue
		var fixture: TrialFixture = candidate
		live.append(fixture)
		for child in fixture.get_children():
			if not (child is CollisionShape3D) or child.disabled or not (child.shape is BoxShape3D): continue
			var shape: BoxShape3D = child.shape
			var pose: Transform3D = fixture.transform * child.transform
			var half := shape.size * .5
			var extent := pose.basis.x.abs() * half.x + pose.basis.y.abs() * half.y + pose.basis.z.abs() * half.z
			var footprint := Rect2(pose.origin.x - extent.x, pose.origin.z - extent.z, extent.x * 2, extent.z * 2)
			_fixture_obstacles.append(footprint)
			obstacles.append(footprint)
			_navigation_fixture_ids[fixture.get_instance_id()] = true
	fixtures = live

func _fixture_exiting(instance_id: int) -> void:
	# A replaced offering can already have been excluded in the pending add
	# refresh before queue_free emits this signal. Do not build twice for it.
	if _navigation_fixture_ids.has(instance_id): _queue_navigation_refresh()

func _queue_navigation_refresh() -> void:
	if _navigation_refresh_queued or _navigation_closing or is_queued_for_deletion() or not is_inside_tree() or not is_instance_valid(region): return
	_navigation_refresh_queued = true
	_refresh_navigation.call_deferred()

func _refresh_navigation() -> void:
	_navigation_refresh_queued = false
	if _navigation_closing or is_queued_for_deletion() or not is_inside_tree() or not navigation_map.is_valid(): return
	_refresh_fixture_obstacles()
	_build_navigation()

func _material(colour: Color, metallic := false) -> Material:
	var key := str(colour) + str(metallic)
	if _materials.has(key): return _materials[key]
	# Architecture previews the exact products the player can take home. Keep
	# effect colours out of this lookup so danger tells remain unambiguous.
	var family := ""
	if colour==LOOK.stone: family="vitrified_basalt"
	elif colour==LOOK.stone_light: family="shellstone"
	elif colour==LOOK.clay: family="rustclay_brick"
	elif colour==LOOK.glass: family="cinderglass"
	if family!="":
		var surface := PieceLook.material_for(load("res://scripts/sim.gd").shared(),StringName(family))
		_materials[key]=surface
		return surface
	var m := StandardMaterial3D.new()
	m.albedo_color = colour
	m.roughness = .86 if not metallic else .55
	m.metallic = .45 if metallic else 0.0
	_materials[key] = m
	return m

func _box(at: Vector3, size: Vector3, colour: Color, solid := false, nav_obstacle := true) -> Node3D:
	var node: Node3D = StaticBody3D.new() if solid else Node3D.new()
	node.position = at
	add_child(node)
	var mesh := MeshInstance3D.new()
	var box:BoxMesh=_box_meshes.get(size)
	if box==null:
		box=BoxMesh.new()
		box.size=size
		_box_meshes[size]=box
	mesh.mesh = box
	mesh.material_override = _material(colour, colour == LOOK.iron)
	node.add_child(mesh)
	if solid:
		if nav_obstacle and at.y-size.y*.5<2.5 and at.y+size.y*.5>.1:
			obstacles.append(Rect2(at.x-size.x*.5,at.z-size.z*.5,size.x,size.z))
		var collider := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collider.shape = shape
		node.add_child(collider)
	return node

func _floor(rect: Rect2) -> void:
	floor_rects.append(rect)
	_box(Vector3(rect.get_center().x, -.4, rect.get_center().y), Vector3(rect.size.x, .8, rect.size.y), LOOK.stone, true)
	# Inset courses break the floor into architecture at consistent metre scale.
	for z in range(int(rect.position.y), int(rect.end.y), 4):
		_box(Vector3(rect.get_center().x, .015, z), Vector3(rect.size.x, .02, .035), LOOK.iron)
	# A thin border is flush decoration, keeping movement and navigation on
	# the existing continuous floor while rooms read as authored chambers.
	for side in [-1.0,1.0]:
		_box(Vector3(rect.get_center().x+side*(rect.size.x*.5-.65),.018,rect.get_center().y),Vector3(.10,.025,rect.size.y),LOOK.stone_light)

func _module(centre: Vector3, module: String, variant: int, side: float) -> void:
	var w: float = LOOK.room_width
	var d: float = LOOK.room_depth
	_floor(Rect2(centre.x-w*.5, centre.z-d*.5, w, d))
	_floor(Rect2(minf(centre.x-side*w*.5, side*5.0), centre.z+.5, 3, LOOK.doorway_width))
	# The short branch connector needs its own side walls; gallery rails only
	# protect the spine, and otherwise a strafe can leave this floor sideways.
	for z in [.5,.5+LOOK.doorway_width]:
		_box(Vector3(side*6.5,3.5,centre.z+z),Vector3(3,7,.6),LOOK.stone,true)
	_box(centre+Vector3(side*w*.5, 3.5, 0), Vector3(.8, 7, d+.8), LOOK.stone, true)
	for z in [-d*.5, d*.5]:
		_box(centre+Vector3(0, 3.5, z), Vector3(w+.8, 7, .8), LOOK.stone, true)
	# Interior wall with a five-metre doorway at local z=3.
	var inner_x := centre.x-side*w*.5
	_box(Vector3(inner_x, 3.5, centre.z-5.75), Vector3(.8, 7, 12.5), LOOK.stone, true)
	_box(Vector3(inner_x, 3.5, centre.z+8.75), Vector3(.8, 7, 6.5), LOOK.stone, true)
	_box(Vector3(inner_x, 5.8, centre.z+3), Vector3(.8, 2.4, 5), LOOK.stone_light, true)
	_box(centre+Vector3(0, 7.3, 0), Vector3(w+.8,.6,d+.8), LOOK.stone, true)
	for z in [-8.0, 0.0, 8.0]:
		_box(centre+Vector3(0, 6.5, z), Vector3(w, .45, .5), LOOK.iron)
	_module_dress(centre, module, variant)
	_light(centre+Vector3(side*7, 4.8, -6), Color("f0b578"), 16, 1.3)
	_light(centre+Vector3(-side*4, 5.5, 6), Color("a0b8af"), 13, .65)

func _cover(at: Vector3, size: Vector3, colour: Color) -> void:
	_box(at+Vector3.UP*size.y*.5, size, colour, true)

func _module_dress(c: Vector3, module: String, variant: int) -> void:
	CataclysmSites.dress_forge(self, c, LOOK.room_width)
	var furnish := func(id:String,at:Vector3,scale_value:Vector3,yaw:=0.0)->void:
		var mesh:=AuthoredAssets.mesh_for(id)
		if mesh==null: return
		var instance:=MeshInstance3D.new()
		instance.mesh=mesh
		instance.position=at-Vector3.UP*mesh.get_aabb().position.y*scale_value.y
		instance.scale=scale_value
		instance.rotation.y=yaw
		instance.visibility_range_end=LOOK.decor_detail_distance
		add_child(instance)
	# Banded upper piers and an ash-marked plinth give the room a consistent
	# workshop scale. They stay against the existing solid perimeter.
	for x in [-9.55,9.55]:
		for z in [-9.5,-5.5,7.8]:
			_box(c+Vector3(x,3.2,z),Vector3(.18,5.9,.7),LOOK.stone_light)
			for y in [1.0,5.2]: _box(c+Vector3(x,y,z),Vector3(.24,.14,.84),LOOK.iron)
	for z in [-11.55,11.55]:
		_box(c+Vector3(0,.38,z),Vector3(19.2,.7,.14),LOOK.clay)
		_box(c+Vector3(0,5.9,z),Vector3(19.2,.18,.18),LOOK.stone_light)
	match module:
		"threshold_gallery":
			for x in [-5.0, 5.0]:
				for z in [-5.0, 5.0]:
					_cover(c+Vector3(x,0,z),Vector3(1.2,6.5,1.2),LOOK.stone_light)
					for y in [.3,3.9,6.2]: _box(c+Vector3(x,y,z),Vector3(1.35,.18,1.35),LOOK.iron)
		"loading_yard":
			for x in [-4.0, 4.0]: _cover(c+Vector3(x,0,-2),Vector3(3,1.8,4),LOOK.clay)
			for x in [-4.7,-3.3,3.3,4.7]:
				for z in [-3.2,-1.7,-.2]: furnish.call("chest",c+Vector3(x,1.80,z),Vector3.ONE,0)
			for z in [-7.0,0.0,7.0]: _box(c+Vector3(0,.04,z),Vector3(12,.04,.13),LOOK.iron)
		"fuel_chamber":
			for x in [-5.5, 5.5]:
				_cover(c+Vector3(x,0,-3),Vector3(3,3.4,7),LOOK.iron)
				for z in [-5.0,-2.0,1.0]: _box(c+Vector3(x,3.42,z),Vector3(2,.06,.4),LOOK.clay)
				for z in [-5.0,-2.0,1.0]: furnish.call("campfire",c+Vector3(x,3.45,z),Vector3.ONE,0)
				for z in [-5.5,-3.5,-1.5,.5]: _box(c+Vector3(x-signf(x)*1.51,1.8,z),Vector3(.05,2.8,.10),LOOK.stone_light)
		"kiln_hall":
			_cover(c+Vector3(0,0,-3),Vector3(4,3.4,5),LOOK.clay)
			furnish.call("forge_improved",c+Vector3(0,3.4,-3),Vector3.ONE*1.25,0)
			for x in [-7.0,7.0]: _box(c+Vector3(x,2,-6),Vector3(1,4,5),LOOK.clay)
			for x in [-7.0,7.0]:
				for z in [-8.0,-6.0,-4.0]: _box(c+Vector3(x,4.2,z),Vector3(.8,.3,.8),LOOK.iron)
		"ward_gallery":
			for x in [-4.0,4.0]:
				for z in [-5.0,3.0]: _cover(c+Vector3(x,0,z),Vector3(1.6,5.5,1.6),LOOK.stone_light)
			_box(c+Vector3(0,5.8,-7),Vector3(12,.3,.3),LOOK.glass)
			for x in [-6.5,0.0,6.5]:
				var window:=MeshInstance3D.new()
				window.mesh=PieceMesh.mesh_for("glazed_window",Vector3(2.5,3.0,.20))
				PieceLook.apply_to(window,"glazed_window",&"cinderglass",_material(LOOK.glass))
				window.position=c+Vector3(x,3.6,-11.44)
				add_child(window)
		"cistern":
			for x in [-6.0,6.0]:
				# The trough ends before the doorway apron, including boss clearance.
				_cover(c+Vector3(x,0,-3),Vector3(2,1.2,8),LOOK.stone_light)
				_box(c+Vector3(x,1.21,-3),Vector3(1.7,.02,7.7),LOOK.glass)
				for z in [-6.0,-3.0,0.0]: _box(c+Vector3(x,1.35,z),Vector3(2.12,.1,.1),LOOK.iron)
		"secret_crucible":
			_cover(c+Vector3(0,0,0),Vector3(3,1,3),LOOK.clay if variant==0 else LOOK.glass)
			for x in [-7.0,7.0]: _cover(c+Vector3(x,0,-5),Vector3(1.4,4,1.4),LOOK.stone_light)
			_light(c+Vector3(0,3,0),Color("b2c2a3"),13,.8)
			furnish.call("mason_yard" if variant==0 else "workbench",c+Vector3(0,1.0,0),Vector3.ONE,0)
		"heart_forge":
			for x in [-7.0,7.0]: _cover(c+Vector3(x,0,-6),Vector3(2,5,2),LOOK.iron)
			for x in [-5.0,0.0,5.0]: _box(c+Vector3(x,.025,-1),Vector3(.32,.025,16),LOOK.clay)
			_box(c+Vector3(0,4.5,-10),Vector3(9,2,1),LOOK.clay)
			for x in [-7.0,7.0]:
				for y in [.5,3.0,4.7]: _box(c+Vector3(x,y,-6),Vector3(2.2,.2,2.2),LOOK.stone_light)
			for x in [-7.0,7.0]: furnish.call("forge_basic",c+Vector3(x,5.0,-6),Vector3.ONE,0)
		_:
			_cover(c+Vector3(-4,0,-3),Vector3(2,2,3),LOOK.stone_light)

func _arch(at: Vector3, width: float) -> void:
	for x in [-width*.5,width*.5]: _box(at+Vector3(x,3.5,0),Vector3(.8,7,1.2),LOOK.stone_light)
	_box(at+Vector3(0,6.5,0),Vector3(width,1,1.2),LOOK.stone_light)

func _light(at: Vector3, colour: Color, radius: float, energy: float) -> void:
	var lamp := OmniLight3D.new()
	lamp.position = at
	lamp.light_color = colour
	lamp.omni_range = radius
	lamp.light_energy = energy*LOOK.lamp_gain
	lamp.shadow_enabled = false
	lamp.distance_fade_enabled=true
	lamp.distance_fade_begin=LOOK.lamp_distance
	lamp.distance_fade_length=10.0
	add_child(lamp)
	var housing:=_box(at,Vector3(.18,.5,.18),colour)
	var glow:=StandardMaterial3D.new()
	glow.albedo_color=colour
	glow.emission_enabled=true
	glow.emission=colour
	glow.emission_energy_multiplier=LOOK.lamp_glow
	(housing.get_child(0) as MeshInstance3D).material_override=glow
	for y in [-.32,.32]: _box(at+Vector3.UP*y,Vector3(.36,.08,.36),LOOK.iron)

func _fixture(kind: String, at: Vector3, title: String, detail: String) -> TrialFixture:
	var f := TrialFixture.new()
	f.fixture_kind = kind
	f.position = at
	if kind in ["reward", "boundary", "conduit"]: f.rotation.y = PI
	f.title = title
	f.detail = detail
	add_child(f)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.2,2.1,.7)
	collider.shape = shape
	collider.position.y=1.05
	f.add_child(collider)
	TrialFixtureArt.build(f, _material(LOOK.stone_light), _material(LOOK.iron))
	fixtures.append(f)
	f.refresh()
	f.tree_exiting.connect(_fixture_exiting.bind(f.get_instance_id()))
	_queue_navigation_refresh()
	return f

func select_stage(index: int, choices: Array) -> void:
	for f in fixtures:
		if f.fixture_kind != "route": continue
		f.available=f.stage_index==index and not f.claimed
		if f.available and f.choice_index<choices.size():
			var choice: Dictionary=choices[f.choice_index]
			f.payload = choice.duplicate(true)
			var counts := {}
			var sim = load("res://scripts/sim.gd").shared()
			for id in choice.get("encounter",[]):
				var display: String = sim.boss()["display_name"] if id == sim.boss()["id"] else sim.enemy(id).get("display_name", id)
				counts[display]=int(counts.get(display,0))+1
			var danger := PackedStringArray()
			for display in counts: danger.append("%d× %s" % [counts[display], display])
			f.payload["danger_summary"] = ", ".join(danger)
			f.detail = f.reward_label() + " · " + f.danger_label()
		f.refresh()

func open_room(index: int, choice: int) -> Dictionary:
	var room: Dictionary=rooms.get("%d:%d" % [index,choice],{})
	if room.is_empty(): return {}
	_set_seal(room["seal"],false)
	for f in fixtures:
		if f.fixture_kind=="route" and f.stage_index==index:
			f.available=false
			f.claimed=f.choice_index==choice
			f.refresh()
	return room

func complete_stage(index: int) -> void:
	if spine_gates.has(index): _set_seal(spine_gates[index],false)

func place_reward(room: Dictionary, text: String) -> TrialFixture:
	if is_instance_valid(reward):
		fixtures.erase(reward)
		reward.queue_free()
	reward=_fixture("reward",room.get("reward_at",Vector3.ZERO),"Recovered offering",text)
	reward.available=true
	reward.refresh()
	return reward

func _set_seal(seal: Node3D, closed: bool) -> void:
	seal.visible=closed
	for child in seal.get_children():
		if child is CollisionShape3D: child.set_deferred("disabled",not closed)

func contains_world(p: Vector3) -> bool:
	var v:=to_local(p)
	if v.y < -3.0 or v.y>15.0: return false
	for rect in floor_rects:
		if rect.grow(.8).has_point(Vector2(v.x,v.z)): return true
	return false

func nearest_floor(p: Vector3) -> Vector3:
	var v:=to_local(p)
	var best:=entry
	var distance:=INF
	# Recovery uses the same clear cells as navigation, so a knockback cannot
	# put a capsule inside cover or send the player back to the floor entrance.
	for cell in _walk_cells:
		var candidate:=Vector3(cell.x+.5,.5,cell.y+.5)
		var d:=candidate.distance_squared_to(v)
		if d<distance: best=candidate; distance=d
	if not _walk_cells.is_empty(): return to_global(best)
	for rect in floor_rects:
		var safe: Rect2=rect.grow(-1.1)
		var candidate:=Vector3(clampf(v.x,safe.position.x,safe.end.x),.5,clampf(v.z,safe.position.y,safe.end.y))
		var d:=candidate.distance_squared_to(v)
		if d<distance: best=candidate; distance=d
	return to_global(best)

func spawn_points(room: Dictionary,count: int, player_at := Vector3.INF, occupied: Array = [], rules: Dictionary = {}, wave := 0) -> Array:
	var points: Array=[]
	var centre: Vector3=room.get("spawn_at",Vector3.ZERO)
	var room_centre: Vector3=room.get("centre",centre)
	# Alternate a close entry-side group and a rear group around existing cover.
	# All points stay in the same compact occupied area; room/exit geometry is unchanged.
	if not rules.is_empty():
		centre = room_centre + Vector3(-signf(room_centre.x) * float(rules["spawn_group_side_m"]) * (1 if wave % 2 == 0 else -1), .6, float(rules["spawn_front_m"] if wave % 2 == 0 else rules["spawn_rear_m"]))
	var candidates: Array[Vector3]=[]
	var bounds: Rect2=room.get("rect",Rect2())
	if not rules.is_empty():
		var size := Vector2(float(rules["spawn_area_width_m"]),float(rules["spawn_area_depth_m"]))
		bounds = bounds.intersection(Rect2(Vector2(room_centre.x,room_centre.z) - size*.5,size))
	var spacing := float(rules.get("spawn_spacing_m",1.7))
	var player_clearance := float(rules.get("spawn_player_clearance_m",5.0))
	for cell in _walk_cells:
		var candidate:=Vector3(cell.x+.5,.6,cell.y+.5)
		if not bounds.grow(-1).has_point(Vector2(candidate.x,candidate.z)): continue
		var world_candidate := to_global(candidate)
		if Vector2(world_candidate.x-player_at.x,world_candidate.z-player_at.z).length() < player_clearance: continue
		var clear := true
		for used in occupied:
			if Vector2(world_candidate.x-used.x,world_candidate.z-used.z).length() < spacing: clear=false; break
		if clear: candidates.append(candidate)
	candidates.sort_custom(func(a:Vector3,b:Vector3)->bool:return a.distance_squared_to(centre)<b.distance_squared_to(centre))
	for i in count:
		var found := false
		for candidate in candidates:
			var clear:=true
			for used in points:
				if to_local(used).distance_to(candidate)<spacing: clear=false; break
			if clear:
				points.append(to_global(candidate))
				found = true
				break
		# No fallback into a wall/body: the controller retains unplaced reserves.
		if not found: break
	return points

func _on_floor(point: Vector2) -> bool:
	for rect in floor_rects:
		if rect.has_point(point): return true
	return false

func _cache_authored_walk_cells() -> void:
	# This floor's walls, cover and connected walk rectangles never change.
	# Cache exactly their original eligibility, then consider only the current
	# small fixture list when a reward or conduit is added or removed.
	for rect in floor_rects:
		for x in range(ceili(rect.position.x),floori(rect.end.x)):
			for z in range(ceili(rect.position.y),floori(rect.end.y)):
				var cell:=Vector2i(x,z)
				if _authored_walk_cells.has(cell): continue
				var blocked:=false
				# Erode the UNION of connected floors, not each rectangle: a
				# doorway shared by room/corridor must retain connected polygons.
				var margin: float=LOOK.navigation_clearance
				for offset in [Vector2(-margin,-margin),Vector2(margin,-margin),Vector2(-margin,margin),Vector2(margin,margin)]:
					if not _on_floor(Vector2(x+.5,z+.5)+offset): blocked=true; break
				for obstacle in _authored_obstacles:
					if obstacle.grow(LOOK.navigation_clearance).intersects(Rect2(x,z,1,1)):
						blocked=true; break
				if blocked: continue
				_authored_walk_cells[cell]=true
	_authored_cells_ready = true

func _build_navigation() -> void:
	var started := Time.get_ticks_usec()
	if not _authored_cells_ready: _cache_authored_walk_cells()
	_walk_cells.clear()
	var vertices:=PackedVector3Array()
	var polygons: Array[PackedInt32Array]=[]
	var corners: Dictionary={}
	var occupied: Array[Rect2] = []
	for obstacle in _fixture_obstacles: occupied.append(obstacle.grow(LOOK.navigation_clearance))
	for cell: Vector2i in _authored_walk_cells:
		var blocked := false
		for obstacle in occupied:
			if obstacle.intersects(Rect2(cell.x, cell.y, 1, 1)): blocked = true; break
		if blocked: continue
		_walk_cells[cell]=true
		var poly:=PackedInt32Array()
		for corner in [cell,cell+Vector2i(0,1),cell+Vector2i(1,1),cell+Vector2i(1,0)]:
			if not corners.has(corner):
				corners[corner]=vertices.size()
				vertices.append(Vector3(corner.x,.05,corner.y))
			poly.append(corners[corner])
		polygons.append(poly)
	var mesh:=NavigationMesh.new()
	mesh.set_vertices(vertices)
	for poly in polygons: mesh.add_polygon(poly)
	if not navigation_map.is_valid():
		navigation_map=NavigationServer3D.map_create()
		NavigationServer3D.map_set_active(navigation_map,true)
		NavigationServer3D.map_set_cell_size(navigation_map,.25)
		NavigationServer3D.map_set_edge_connection_margin(navigation_map,.1)
	if not is_instance_valid(region):
		region=NavigationRegion3D.new()
		region.set_navigation_map(navigation_map)
		add_child(region)
	region.navigation_mesh=mesh
	navigation_build_count += 1
	navigation_last_build_usec = Time.get_ticks_usec() - started
	navigation_peak_build_usec = maxi(navigation_peak_build_usec, navigation_last_build_usec)

func path(from: Vector3,to: Vector3) -> PackedVector3Array:
	if not navigation_map.is_valid() or not is_instance_valid(region) or NavigationServer3D.region_get_iteration_id(region.get_rid())==0 or NavigationServer3D.map_get_iteration_id(navigation_map)<2:
		return PackedVector3Array()
	return NavigationServer3D.map_get_path(navigation_map,from,to,true)
