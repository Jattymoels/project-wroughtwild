extends Node3D
## Real catalogue geometry, physics and three normal construction palettes.
## Run headless for checks; run rendered for fixed 1440x900 review captures.
var checks := 0
var failures := 0
var sim: WroughtwildSim
var stage: Node3D
var view: SubViewport
var camera: Camera3D
var sun: DirectionalLight3D
var caption: Label
const FAMILIES := ["slate","shellstone","rustclay_brick","woven_reed","resinheart","corkbark","vitrified_basalt","cinderglass"]

func check(ok: bool, text: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ",text)

func _ready() -> void:
	sim = load("res://scripts/sim.gd").shared()
	if not sim.last_error().is_empty():
		printerr("MATERIAL_INTENSIVE: rebuild the native extension first: ",sim.last_error())
		get_tree().quit(1)
		return
	_setup()
	_check_economy()
	_check_art()
	_catalogue()
	_house(Vector3i(-13,0,12),"shellstone","slate","slate","QUARRY LODGE")
	_house(Vector3i(-3,0,12),"rustclay_brick","woven_reed","woven_reed","FEN WORKHOUSE")
	_house(Vector3i(7,0,12),"resinheart","corkbark","corkbark","OLDGROWTH CABIN")
	for i in 3: await get_tree().physics_frame
	_check_physics()
	if DisplayServer.get_name()!="headless":
		await _capture("materials-catalogue",Vector3(0,5.2,-11.8),Vector3(0,1.1,0),"EIGHT MATERIAL FAMILIES · NORMAL BUILDING CATALOGUE")
		await _capture("three-buildings-day",Vector3(1,7,-9),Vector3(0,0,5),"QUARRY · FEN · OLDGROWTH / THREE MATERIAL AMBITIONS")
		sun.light_energy = 0.50
		sun.light_color = Color("ebbd8f")
		await _capture("three-buildings-dusk",Vector3(1,7,-9),Vector3(0,0,5),"MATCHED DUSK · RESTRAINED MATERIAL COLOUR")
		sun.light_energy = 1.25
		sun.light_color = Color("fff2d8")
		await _capture("quarry-lodge",Vector3(-18,3.8,6),Vector3(-10,2.2,15),"SHELLSTONE LODGE · SLATE · BASALT CHIMNEY")
		await _capture("fen-workhouse",Vector3(-8,2.9,6),Vector3(0,1.7,15),"RUSTCLAY WORKHOUSE · WOVEN REED PANELS AND THATCH")
		await _capture("oldgrowth-cabin",Vector3(2,2.9,5),Vector3(10,1.7,14),"RESINHEART CABIN · CORK-ROOF PORCH · CINDERGLASS")
		await _capture("grove-interior",Vector3(10.5,1.7,15.3),Vector3(8.5,1.3,12.0),"RESINHEART INTERIOR · FRAMED CINDERGLASS · CORK ROOF")
	print("MATERIAL_INTENSIVE %d checks, %d failures" % [checks,failures])
	get_tree().quit(0 if failures==0 else 1)

func _setup() -> void:
	view = SubViewport.new()
	view.size = Vector2i(1440,900)
	view.own_world_3d = true
	view.world_3d = World3D.new()
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	view.msaa_3d = Viewport.MSAA_4X
	add_child(view)
	stage = Node3D.new()
	view.add_child(stage)
	var ground := StaticBody3D.new()
	stage.add_child(ground)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(70,0.1,65)
	mesh.mesh = box
	mesh.position.y = -0.1
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("404d36")
	material.roughness = 1.0
	mesh.material_override = material
	ground.add_child(mesh)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box.size
	collider.shape = shape
	collider.position = mesh.position
	ground.add_child(collider)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("788486")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("b0b9b3")
	environment.environment.ambient_light_energy = 0.48
	environment.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	stage.add_child(environment)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-47,-32,0)
	sun.light_energy = 1.25
	sun.light_color = Color("fff2d8")
	sun.shadow_enabled = true
	stage.add_child(sun)
	camera = Camera3D.new()
	camera.fov = 58
	stage.add_child(camera)
	camera.make_current()
	var canvas := CanvasLayer.new()
	view.add_child(canvas)
	caption = Label.new()
	caption.position = Vector2(34,27)
	caption.add_theme_font_size_override("font_size",23)
	caption.add_theme_color_override("font_color",Color("f0ead8"))
	canvas.add_child(caption)

func _check_economy() -> void:
	check(sim.build_material_ids().size()==19,"exact bounded catalogue: eleven existing plus eight new families")
	for family in FAMILIES:
		var info: Dictionary = sim.build_material(family)
		var recipe: Dictionary = sim.recipe("refine_"+family)
		check(info.source==family and not recipe.is_empty(),family+" has one finished source and one refinement recipe")
		check(recipe.inputs.size()==1 and recipe.outputs.get(family,0)==4,family+" uses a four-unit one-step batch")
		for raw in recipe.inputs:
			check(not sim.build_material_ids().has(raw),raw+" is a source ingredient, never a build family")
	for family in ["woven_reed","corkbark"]:
		for shape in ["cube","door","chest","wall_panel"]:
			check(not sim.shape_allows_family(shape,family),family+" cannot become "+shape)
		for shape in ["light_panel","codex_roof_slope","codex_roof_hip","codex_roof_valley"]:
			check(sim.shape_allows_family(shape,family),family+" forms "+shape)
	check(sim.shape_allows_family("glazed_window","cinderglass") and not sim.shape_allows_family("cube","cinderglass"),"glass stays in its included fixed frame")
	for family in ["wood","pine","bog_oak","ash_wood","iron","bronze","steel"]:
		check(sim.shape_allows_family("codex_roof_slope",family),family+" retains its original roof eligibility")
	check(not sim.shape_unlocked("codex_roof_slope"),"new material does not skip stonecut roof unlock")
	sim.record_world_effect("stonecut_blocks")
	check(sim.shape_unlocked("codex_roof_slope"),"existing reward unlocks new pitched coverings")

func _check_art() -> void:
	var bed:=ArtGeometry.begin()
	var rng:=RandomNumberGenerator.new()
	rng.seed=771
	HabitatResourceArt._stratum(bed,rng,Vector3.ZERO,Vector3(2,.2,1),Color.WHITE)
	var bed_mesh:=bed.commit()
	var bed_faces:=bed_mesh.get_faces()
	for i in range(0,bed_faces.size(),3):
		var midpoint:Vector3=(bed_faces[i]+bed_faces[i+1]+bed_faces[i+2])/3.0
		var outward:Vector3=(bed_faces[i+2]-bed_faces[i]).cross(bed_faces[i+1]-bed_faces[i]).normalized()
		check(outward.dot(midpoint-Vector3(0,.10,0))>0.0,"quarry/clay strata have outward top, sides and capped base")
	for family in FAMILIES:
		var material := PieceLook.material_for(sim,StringName(family))
		check(material!=null and material==PieceLook.material_for(sim,StringName(family)),family+" reuses its shared material")
	for family in ["pine","bog_oak","ash_wood","resinheart"]:
		var material := PieceLook.material_for(sim,StringName(family)) as ShaderMaterial
		check(material.get_shader_parameter("grain")!=(PieceLook.material_for(sim,&"wood") as ShaderMaterial).get_shader_parameter("grain"),family+" has distinct grain beyond a tint")
	for id in ["wall_panel","pillar","beam","broadleaf_tree","field_boulder","shrub","fern_bed","deadfall","stump","workbench","mason_yard","forge_basic","forge_improved","chest","campfire"]:
		var mesh := AuthoredAssets.mesh_for(id)
		check(mesh!=null and mesh.get_surface_count()>0 and mesh.get_aabb().size.is_finite(),id+" authored visual imports with finite bounds")
		check(mesh==AuthoredAssets.mesh_for(id),id+" mesh is cached")
	for form in ["light_panel","glazed_window"]:
		var size: Vector3 = sim.shape(form).size
		var shapes := PieceMesh.collision_for(form,size)
		check(shapes.size()==1 and shapes[0].shape is BoxShape3D and shapes[0].shape.size==size,form+" has exactly one full-face body")
		check(PieceMesh.mesh_for(form,size).get_surface_count()==2,form+" has separate infill and frame surfaces")
	for key in HabitatResourceArt.LABELS:
		var node: ResourceNode = preload("res://scenes/resource_node.tscn").instantiate()
		node.visual = StringName(key)
		node.remaining_units = 12
		node.units_per_harvest = 4
		node.drive_presses = 4
		node.position = Vector3(100,0,100)
		stage.add_child(node)
		check(node.presentation_label==HabitatResourceArt.LABELS[key] and node.workable(),key+" has a useful label and works by hand")
		for i in 3: node.work(sim)
		check(node.remaining_units==12 and node.drive_progress==3,key+" partial work gives no early payout")
		check(node.work(sim).get("granted",0)==4 and node.remaining_units==8,key+" baseline yields once and remains finite")
		node.free()

func _catalogue() -> void:
	for i in FAMILIES.size():
		var family: String = FAMILIES[i]
		var x := (float(i)-3.5)*1.8
		var shape := "glazed_window" if family=="cinderglass" else "light_panel" if family in ["woven_reed","corkbark"] else "wall_panel"
		_piece(shape,family,Vector3(x,0.65,0))
		if family!="cinderglass": _piece("codex_roof_slope",family,Vector3(x,1.6,0.15))
		_label(Hud.pretty(family),Vector3(x,0.1,-0.8),20)

func _piece(shape_id: String, family: String, at: Vector3, yaw: float=0.0) -> PlacedBlock:
	var info: Dictionary = sim.shape(shape_id)
	var block := PlacedBlock.new()
	stage.add_child(block)
	block.init_piece(StringName(shape_id),StringName(family),{},0,info.get("form","box"),info.size,at,yaw,
		PieceLook.material_for(sim,StringName(family),"roof" if shape_id.begins_with("codex_roof") else "frame" if shape_id in ["beam","pillar"] else "surface"))
	return block

func _house(origin: Vector3i, walls: String, panels: String, roof: String, title: String) -> void:
	var at := Vector3(origin)
	if walls=="shellstone":
		for x in 6:
			for z in 6: _piece("foundation","fieldstone",at+Vector3(x+.5,.5,z+.5))
		at.y+=.5
	for x in 6:
		for z in 6:
			_piece("floor_slab","slate" if walls=="shellstone" else "resinheart",at+Vector3(x+0.5,0,z+0.5))
			_piece("floor_slab","resinheart",at+Vector3(x+0.5,3,z+0.5))
			# Closed hip roof: every ring uses the ordinary slope and corner
			# transitions. A six-cell span avoids an unmatched central half-pitch.
			var dx := mini(x,5-x)
			var dz := mini(z,5-z)
			var form := "codex_roof_hip" if dx==dz else "codex_roof_slope"
			var turn := 0.0
			if dx==dz:
				turn = (0.0 if z<3 else PI*0.5) if x<3 else (-PI*0.5 if z<3 else PI)
			else:
				turn = (PI*0.5 if x<3 else -PI*0.5) if dx<dz else (0.0 if z<3 else PI)
			_piece(form,roof,at+Vector3(x+0.5,3.25+mini(dx,dz)*0.5,z+0.5),turn)
	for y in 3:
		for i in 6:
			if i!=2 or y==2:
				var window:=y==1 and i in ([1,4] if walls=="rustclay_brick" else [1,3])
				var woven:=walls=="rustclay_brick" and y>0 and not window
				_piece("glazed_window" if window else "light_panel" if woven else "wall_panel","cinderglass" if window else panels if woven else walls,at+Vector3(i+0.5,y+0.5,0))
			_piece("light_panel",panels,at+Vector3(i+0.5,y+0.5,6))
			_piece("wall_panel",walls,at+Vector3(0,y+0.5,i+0.5),PI*0.5)
			_piece("wall_panel",walls,at+Vector3(6,y+0.5,i+0.5),PI*0.5)
	_piece("door","resinheart",at+Vector3(2.5,1,0))
	if walls=="shellstone":
		for y in 6: _piece("cube","vitrified_basalt",at+Vector3(4.5,y+.5,4.5))
		for z in [-2,-1]:
			for x in [2,3]: _piece("foundation","fieldstone",Vector3(origin)+Vector3(x+.5,.5,z+.5))
	if walls=="resinheart":
		# A useful two-cell covered porch built only from the normal palette.
		for x in range(1,5):
			for z in [-2,-1]:
				_piece("floor_slab","slate",at+Vector3(x+.5,.02,z+.5))
				_piece("codex_roof_slope","corkbark",at+Vector3(x+.5,2.75+(z+2)*.5,z+.5))
		for x in [1,5]:
			for y in 2: _piece("pillar","resinheart",at+Vector3(x,y+.5,-2))
			_piece("half_pillar","resinheart",at+Vector3(x,2.25,-2))
		for x in range(1,5): _piece("beam","resinheart",at+Vector3(x+.5,2.5,-2))
	for x in [0,6]:
		for z in [0,6]:
			for y in 3: _piece("pillar","resinheart",at+Vector3(x,y+0.5,z))
	var furnishing := MeshInstance3D.new()
	furnishing.mesh = AuthoredAssets.mesh_for("workbench" if walls=="resinheart" else "mason_yard" if walls=="shellstone" else "forge_basic")
	furnishing.position = at+Vector3(1,0.10-furnishing.mesh.get_aabb().position.y,3.5)
	stage.add_child(furnishing)
	for i in 3:
		var detail:=MeshInstance3D.new()
		detail.mesh=AuthoredAssets.mesh_for("field_boulder" if walls=="shellstone" else "fern_bed")
		detail.position=Vector3(at.x+7.0+i*.9,-detail.mesh.get_aabb().position.y-.03,at.z+4.0-i*1.8)
		stage.add_child(detail)
	var light := OmniLight3D.new()
	light.position = at+Vector3(2.5,2.4,2.5)
	light.light_color = Color("d6bf96")
	light.light_energy = 0.55
	light.omni_range = 5
	stage.add_child(light)
	_label(title,at+Vector3(2.5,0.25,-1.4),25)

func _label(text: String, at: Vector3, font_size: int) -> void:
	var label := Label3D.new()
	label.text = text
	label.position = at
	label.font_size = font_size
	label.pixel_size = 0.005
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("e1d5bb")
	stage.add_child(label)

func _check_physics() -> void:
	var space := stage.get_world_3d().direct_space_state
	for x in [4.5,6.3]:
		var query := PhysicsRayQueryParameters3D.create(Vector3(x,0.65,-2),Vector3(x,0.65,2))
		check(not space.intersect_ray(query).is_empty(),"normal material infill blocks a centre projectile ray")
	var query := PhysicsRayQueryParameters3D.create(Vector3(8,0.65,-2),Vector3(8,0.65,2))
	check(space.intersect_ray(query).is_empty(),"space beside the glazing stays clear")

func _capture(id: String, from: Vector3, to: Vector3, text: String) -> void:
	camera.position = from
	camera.look_at(to)
	caption.text = text
	for i in 6: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var folder := ProjectSettings.globalize_path("res://../build/intensives/materials")
	DirAccess.make_dir_recursive_absolute(folder)
	check(view.get_texture().get_image().save_png(folder.path_join(id+".png"))==OK,"render "+id)
