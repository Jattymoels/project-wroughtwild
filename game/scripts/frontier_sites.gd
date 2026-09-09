class_name FrontierSites
extends Node3D
## Visible LF-3 exteriors and local habitat cues. Native geography owns positions;
## these pieces own no stock, rewards, trial progress or transformation state.
var terrain: Terrain
var dressing: Array[MeshInstance3D] = []
var shells: Array[MeshInstance3D] = []
var trail_marks: Array[MeshInstance3D] = []
var trail_pieces: Array[MeshInstance3D] = []
const STONE := Color("555e5b")
const METAL := Color("727a77")

static func build(root: Node3D, ground: Terrain) -> FrontierSites:
	if ground.world_profile() != "living_frontier_wave3": return null
	var result := FrontierSites.new()
	result.name = "FrontierSites"
	result.terrain = ground
	root.add_child(result)
	result._compose()
	return result

func _box(at: Vector3, size: Vector3, colour: Color, solid := false, glow := false) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.roughness = .9
	mat.emission_enabled = glow
	mat.emission = colour
	mat.emission_energy_multiplier = .45 if glow else 0.0
	mesh.material = mat
	part.mesh = mesh
	part.position = at
	part.visibility_range_end = 180
	add_child(part)
	if solid:
		var body := StaticBody3D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		body.name = "ExteriorBody"
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		shape.shape = box
		body.add_child(shape)
		part.add_child(body)
		shells.append(part)
	else:
		dressing.append(part)
	return part

func _compose() -> void:
	for habitat: Dictionary in terrain.map.frontier_hosts:
		var path: PackedVector3Array = habitat.source_route
		var spacing := int(terrain.map.frontier_rules.habitat_cue_spacing_m)
		for i in range(0,path.size(),spacing): _scar(path[i],String(habitat.influence))
		for at: Vector3 in habitat.habits: _scar(at,String(habitat.influence),true)
	for lab: Dictionary in terrain.map.laboratories: _laboratory(lab)
	_artificial_trail()
	refresh_buildings()

func _artificial_trail() -> void:
	var first_piece:=dressing.size()
	var path: PackedVector3Array=terrain.map.laboratory_trail
	var spacing:=int(terrain.map.frontier_rules.trail_spacing_m)
	var indices: Array[int]=[]
	for i in range(0,path.size(),spacing): indices.append(i)
	if indices.is_empty(): return
	if indices.back()!=path.size()-1: indices.append(path.size()-1)
	for slot in indices.size():
		var index:=indices[slot]
		var at:=path[index]
		var next:=path[mini(index+spacing,path.size()-1)]
		var direction: Vector3=(next-at)*Vector3(1,0,1)
		if direction.length_squared()<.1: direction=(at-path[maxi(0,index-1)])*Vector3(1,0,1)
		direction=direction.normalized()
		var side:=direction.cross(Vector3.UP)
		# The walking lane clears the final shell; offset clamps should sit on
		# its outward side as well, rather than disappearing into a wall.
		for lab: Dictionary in terrain.map.laboratories:
			var away: Vector3=(at-lab.position)*Vector3(1,0,1)
			if away.length()<12 and side.dot(away)<0: side=-side
		var post_at:=at+side*.7
		# Later metal clamps have consistent tooling, right angles and a stamped
		# triple cut. Natural influence cues retain their local branching/layers.
		var post:=_box(post_at+Vector3.UP*.65,Vector3(.18,1.3,.18),METAL)
		post.name="CollectionMark%d" % slot
		post.set_meta("walk_position",at)
		post.set_meta("route_index",index)
		trail_marks.append(post)
		var clamp:=_box(post_at+Vector3.UP*.92,Vector3(.75,.12,.34),METAL)
		clamp.rotation.y=atan2(-direction.x,-direction.z)
		for cut in 3:
			var stamp:=_box(post_at+Vector3.UP*1.13+side*(cut-1)*.19,Vector3(.07,.3,.25),Color("cec6a4"))
			stamp.rotation.y=clamp.rotation.y
		if index+2<path.size():
			# Short straight feeds leave the walking lane open, visibly fastened
			# onto the scar rather than pretending to be a natural lightning fork.
			var end:=path[index+2]+side*.7+Vector3.UP*.45
			var start:=post_at+Vector3.UP*.45
			var feed:=_box((start+end)*.5,Vector3(.11,.11,start.distance_to(end)),Color("465453"))
			feed.look_at(end)
			var pointer:=_box(at+Vector3.UP*.09+direction*.6,Vector3(.1,.06,1.2),Color("cec6a4"))
			pointer.rotation.y=clamp.rotation.y
			for turn in [-1,1]:
				var tip:=_box(at+Vector3.UP*.09+direction*1.02+side*turn*.18,Vector3(.07,.06,.55),Color("cec6a4"))
				tip.rotation.y=clamp.rotation.y+turn*.7
		if slot==0 or slot==indices.size()-1:
			var label:=Label3D.new()
			label.text="Collection feed →" if slot==0 else "Collection Annex · feed terminus"
			label.position=post_at+Vector3.UP*1.65
			label.font_size=28
			label.pixel_size=.005
			label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
			label.visibility_range_end=14
			add_child(label)
	trail_pieces=dressing.slice(first_piece)

func _scar(at: Vector3, influence: String, growth := false) -> void:
	var colour: Color = FrontierHostLook.PALETTE[influence]
	# Coloured detail stays a small local part of ordinary ground/wood.
	_box(at + Vector3(0,.09,0),Vector3(.8,.18,.6),Color("615d4b"))
	match influence:
		"red":
			for i in 3: _box(at+Vector3(-.22+i*.2,.19,.06*(i%2)),Vector3(.06,.04,.42),colour,false,true)
		"blue":
			for i in 3: _box(at+Vector3(0,.19+i*.08,0),Vector3(.62-i*.1,.03,.25),colour,false,true)
		"white":
			for i in 3: _box(at+Vector3(-.22+i*.22,.28,0),Vector3(.045,.22,.32),colour,false,true)
		"green":
			for i in 2:
				var branch := _box(at+Vector3(0,.22,i*.16),Vector3(.75,.04,.05),colour,false,true)
				branch.rotation.y = -.4 if i==0 else .4
			if growth: _box(at+Vector3(0,.45,0),Vector3(.07,.6,.07),Color("66724b"))

func _laboratory(data: Dictionary) -> void:
	var at: Vector3 = data.position
	var size: Vector3 = data.size
	var h := size.y
	var floor := _box(at+Vector3(0,-.2,0),Vector3(size.x+.8,.4,size.z+.8),STONE,true)
	floor.set_meta("laboratory_id",data.id)
	# A visible sealed shell, with a framed door and actual physical space.
	for side in [-1,1]:
		_box(at+Vector3(side*size.x*.5,h*.5,0),Vector3(.35,h,size.z),STONE,true)
	_box(at+Vector3(0,h*.5,-size.z*.5),Vector3(size.x,h,.35),STONE,true)
	_box(at+Vector3(0,h*.5,size.z*.5),Vector3(size.x,h,.25),METAL,true)
	_box(at+Vector3(0,h+.08,0),Vector3(size.x+.5,.3,size.z+.5),STONE,true)
	for side in [-1,1]:
		_box(at+Vector3(side*1.1,1.25,size.z*.5+.18),Vector3(.18,2.5,.35),Color("989a87"),true)
	_box(at+Vector3(0,2.5,size.z*.5+.18),Vector3(2.4,.18,.35),Color("989a87"),true)
	_box(at+Vector3(0,1.2,size.z*.5+.16),Vector3(1.7,2.25,.04),Color("343d3c"))
	# Distinct ambition silhouettes; the triple cut mark is repeated on each.
	var count := 1 if String(data.id).contains("annex") else (2 if String(data.id).contains("pairing") else 3)
	for i in count: _box(at+Vector3(-size.x*.3+i*.9,h+.8,-.6),Vector3(.4,1.4,.5),METAL,true)
	for i in 3: _box(at+Vector3(-.32+i*.32,3.1,size.z*.5+.2),Vector3(.1,.4,.07),Color("cec6a4"))
	var label := Label3D.new()
	label.text = "%s\nSealed collection bays" % String(data.label)
	label.position = at+Vector3(0,h+.7,size.z*.5)
	label.font_size = 34
	label.pixel_size = .006
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.visibility_range_end = 28
	add_child(label)

func refresh_buildings(changed: Array[AABB] = [], buildings: Dictionary = {}) -> void:
	var index := StrangeSites._building_index(terrain) if buildings.is_empty() else buildings
	for part in dressing + shells:
		var bounds := part.transform * part.mesh.get_aabb()
		if not StrangeSites.touches_changes(bounds,changed): continue
		# Paid occupied space always wins, including an explicitly loaded fixture.
		part.visible = not StrangeSites._building_overlap(index,bounds)
		var body := part.get_node_or_null("ExteriorBody")
		if body != null:
			for collision: CollisionShape3D in body.get_children(): collision.set_deferred("disabled",not part.visible)
