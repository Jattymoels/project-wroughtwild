extends Node3D
## Small authored pocket and shared mechanism study before large-world review.
## Terrain is deliberately flat here; this does not certify generated geography.
class ReviewTerrain extends Terrain:
	func height_at(_x: int, _z: int) -> int: return 0
	func rendered_height(_x: float, _z: float, _reference_y: float, _reach := 0.8) -> float: return 0.0

var checks:=0
var failures:=0
var view: SubViewport
var stage: Node3D
var camera: Camera3D
var sun: DirectionalLight3D
var caption: Label
var terrain: Terrain
var specimens: Dictionary={}
var fixtures: Dictionary={}
var output: String

func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL STRANGE ART: ",label)

func _ready() -> void:
	output=ProjectSettings.globalize_path("res://../build/strange-frontier/art")
	DirAccess.make_dir_recursive_absolute(output)
	_setup()
	_build()
	for i in 3: await get_tree().physics_frame
	_checks()
	if DisplayServer.get_name()!="headless":
		await _capture("lantern-pocket-day",Vector3(0,1.65,7),Vector3(0,.8,0),"LANTERN FEN POCKET · SHADED DAYLIGHT · AUTHORING STUDY")
		sun.light_energy=.42
		sun.light_color=Color("d8c39e")
		await _capture("lantern-pocket-dusk",Vector3(0,1.65,7),Vector3(0,.8,0),"MATCHED DUSK · LIGHT HELD INSIDE PAPERY GROWTH")
		sun.light_energy=1.3
		sun.light_color=Color("fff1d9")
		for id in specimens:
			var node: ResourceNode=specimens[id]
			var at:=node.global_position
			await _capture("specimen-"+id,at+Vector3(2.1,1.65,3.4),at+Vector3.UP*.45,"FINITE FIND · "+String(id).to_upper())
			StrangeResourceArt.update(node,.75)
			await _capture("work-"+id,at+Vector3(2.1,1.65,3.4),at+Vector3.UP*.45,"CONTEXTUAL WORK · "+String(id).to_upper())
			StrangeResourceArt.update(node,1,true)
			await _capture("aftermath-"+id,at+Vector3(2.1,1.65,3.4),at+Vector3.UP*.45,"EMPTY HOUSING · INTACT COMPONENT REMOVED")
			StrangeResourceArt.update(node,0)
		await _capture("contraption-kit",Vector3(1,4.5,24),Vector3(0,.8,15),"REUSABLE FINDS · LAMP, WINCH, SIGNAL, SORTER AND BELLOWS")
		await _capture("rootvault-arch",Vector3(-24,1.65,11),Vector3(-26,5,-4),"ROOTVAULT · AN OPEN CHAMBER BELOW THE ROOTS")
		await _capture("glasswind-ribs",Vector3(29,1.65,13),Vector3(28,3,-7),"GLASSWIND · PALE RIBS AND OLD LIGHTNING SCARS")
	var authored: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/authored/strange_nature_manifest.json"))
	var report:={"checks":checks,"failures":failures,"scope":"Authored pocket and fixture kit. Generated regional review is separate.","asset_count":authored.get("assets",{}).size()}
	var file:=FileAccess.open(output.path_join("manifest.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print("STRANGE_ART_REVIEW %d checks, %d failures"%[checks,failures])
	get_tree().quit(0 if failures==0 else 1)

func _setup() -> void:
	view=SubViewport.new()
	view.size=Vector2i(1440,900)
	view.own_world_3d=true
	view.world_3d=World3D.new()
	view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	view.msaa_3d=Viewport.MSAA_4X
	add_child(view)
	stage=Node3D.new()
	view.add_child(stage)
	var ground:=StaticBody3D.new()
	stage.add_child(ground)
	var mesh:=MeshInstance3D.new()
	var box:=BoxMesh.new()
	box.size=Vector3(130,.2,100)
	mesh.mesh=box
	mesh.position.y=-.1
	var material:=StandardMaterial3D.new()
	material.albedo_color=Color("48543b")
	material.roughness=1
	mesh.material_override=material
	ground.add_child(mesh)
	var collision:=CollisionShape3D.new()
	var shape:=BoxShape3D.new()
	shape.size=box.size
	collision.shape=shape
	collision.position=mesh.position
	ground.add_child(collision)
	var environment:=WorldEnvironment.new()
	environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR
	environment.environment.background_color=Color("7c8989")
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color=Color("b3b8b0")
	environment.environment.ambient_light_energy=.6
	environment.environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	stage.add_child(environment)
	sun=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-44,-32,0)
	sun.light_energy=1.3
	sun.light_color=Color("fff1d9")
	sun.shadow_enabled=true
	stage.add_child(sun)
	camera=Camera3D.new()
	camera.fov=68
	stage.add_child(camera)
	camera.make_current()
	var canvas:=CanvasLayer.new()
	view.add_child(canvas)
	caption=Label.new()
	caption.position=Vector2(26,23)
	caption.add_theme_font_size_override("font_size",20)
	caption.add_theme_color_override("font_color",Color("ece5d2"))
	canvas.add_child(caption)

func _build() -> void:
	terrain=ReviewTerrain.new()
	terrain.name="Terrain"
	terrain.map={"cell_size":1.0,"seed":1,"regions":[],"nodes":[],"rare_sites":[]}
	stage.add_child(terrain)
	var index:=0
	for id in StrangeResourceArt.IDS:
		var at:=Vector3(index*5.5,0,0)
		var node:=load("res://scenes/resource_node.tscn").instantiate() as ResourceNode
		node.visual=StringName(id)
		node.material_family=StringName(id)
		node.resource_id="art_"+id
		node.remaining_units=8
		node.drive_presses=4
		node.position=at
		stage.add_child(node)
		specimens[id]=node
		terrain.map.rare_sites.append({"id":"art_"+id,"resource_type":id,"x":at.x-.5,"z":at.z-.5,"approach":PackedVector3Array([at+Vector3(0,0,5),at+Vector3(0,0,3),at]),"clue_points":PackedVector3Array([at+Vector3(1.2,0,2),at+Vector3(-1.1,0,3.5)])})
		index+=1
	StrangeSites.build(stage,terrain)
	for offset in [Vector3(-4,0,-1.5),Vector3(3.5,0,-3),Vector3(-2.8,0,3)]:
		StrangeResourceArt.part(stage,"hollow_trunk","FenTrunk",offset)
	for i in 4:
		var tree:=MeshInstance3D.new()
		tree.mesh=AuthoredAssets.mesh_for("broadleaf_tree")
		tree.material_override=StrangeResourceArt.material(0,.018)
		tree.position=Vector3(-6+i*4.8,0,-4.5)
		tree.scale=Vector3.ONE*1.9
		stage.add_child(tree)
	index=0
	for id in ["lantern_lamp","cargo_winch","winch_landing","stormglass_lever","magnetic_sorter","ventlung_bellows"]:
		var fixture:=StrangeResourceArt.fixture_visual(id)
		stage.add_child(fixture)
		fixture.position=Vector3(-7.5+index*3,0,15)
		fixtures[id]=fixture
		index+=1
	StrangeResourceArt.part(stage,"root_arch","RootvaultArch",Vector3(-26,0,-4))
	for i in 3:
		var rib:=StrangeResourceArt.part(stage,"stone_rib","GlasswindRib",Vector3(26+i*4,0,-9-i*3))
		rib.rotation.y=i*.55
	StrangeResourceArt.part(stage,"lightning_scar","OldLightning",Vector3(29,0,-1))

func _checks() -> void:
	var sounds: Dictionary={}
	for kind in ["lanternheart","thrumroot","stormglass","pullstone","ventlung","pulse","tick"]:
		var clip: AudioStreamWAV=preload("res://art/strange_sound.gd")._clip(kind)
		check(clip.mix_rate==22050 and clip.format==AudioStreamWAV.FORMAT_16_BITS and not clip.stereo,"local clue uses a compact mono PCM stream")
		check(clip.data.size()>22050 and not sounds.has(hash(clip.data)),"each clue has a distinct nonempty synthesized voice")
		sounds[hash(clip.data)]=kind
	for id in StrangeResourceArt.IDS:
		var node: ResourceNode=specimens[id]
		check(node.has_node("StrangeCore/Core"),"finite source uses authored core")
		check(not (node.get_node("MeshInstance3D") as MeshInstance3D).visible,"default placeholder is hidden")
		check(node.is_in_group("resources"),"bellows can find ordinary resource body")
		var bounds:=StrangeResourceArt.mesh_for(StringName(id)).get_aabb()
		var envelope:=StrangeResourceArt.bounds_for(StringName(id))
		check(bounds.position.x>=-envelope.x*.5-.01 and bounds.end.x<=envelope.x*.5+.01 and bounds.position.z>=-envelope.z*.5-.01 and bounds.end.z<=envelope.z*.5+.01 and bounds.end.y<=envelope.y+.01,"visible intact specimen fits its ordinary resource body above ground")
		var hit:=stage.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(node.position+Vector3(0,.45,3),node.position+Vector3(0,.45,-3)))
		check(hit.get("collider")==node,"ordinary contextual ray finds the intact core")
		var housing:=stage.get_node("StrangeSites/art_"+id)
		StrangeResourceArt.update(node,1,true)
		check(housing.get_child_count()>0 and housing.visible,"empty site housing survives depletion presentation")
		StrangeResourceArt.update(node,0)
	for id in fixtures:
		var mesh:=StrangeResourceArt.fixture_mesh(id)
		check(mesh!=null and mesh.get_surface_count()>0,"catalogue and placed fixture share authored geometry")
		var body_count:=0
		for child in (fixtures[id] as Node).find_children("*","CollisionObject3D",true,false): body_count+=1
		check(body_count==0,"authored fixture does not duplicate gameplay collision")
	check((fixtures.lantern_lamp as Node).has_node("Heart") and (fixtures.lantern_lamp as Node).has_node("WarmInterior"),"lamp exposes visual receiver and local light")
	check((fixtures.cargo_winch as Node).has_node("Drum"),"winch exposes winding animation pivot")
	check((fixtures.stormglass_lever as Node).has_node("Lever"),"signal exposes committed lever pivot")
	check((fixtures.ventlung_bellows as Node).has_node("Bellows"),"bellows exposes pressure membrane")

func _capture(id: String, from: Vector3, toward: Vector3, label: String) -> void:
	caption.text=label
	camera.global_position=from
	camera.look_at(toward)
	for i in 4: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	check(view.get_texture().get_image().save_png(output.path_join(id+".png"))==OK,"capture "+id)
