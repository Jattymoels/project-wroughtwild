extends Node3D
## Actual Enemy/Boss/StationSite/ResourceNode paths, including skinning and status
## reset. The flat review floor isolates presentation; world journeys are separate.
class FlatTerrain extends Terrain:
	func height_at(_x: int,_z: int) -> int: return 0
	func rendered_height(_x: float,_z: float,_reference: float,_reach:=.8) -> float: return 0.0

var checks:=0
var failures:=0
var actors: Dictionary={}
var sites: Dictionary={}
var camera: Camera3D
var caption: Label
var output: String

func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL CATACLYSM ACTOR CRAFT: ",label)

func _ready() -> void:
	output=ProjectSettings.globalize_path("res://../build/cataclysm/actor-craft")
	DirAccess.make_dir_recursive_absolute(output)
	_setup()
	_check_actors()
	_check_stations()
	_check_resources()
	if DisplayServer.get_name()!="headless": await _review()
	var file:=FileAccess.open(output.path_join("checks.json" if DisplayServer.get_name()=="headless" else "manifest.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"scope":"Real actor/station/resource scene paths on a fixed review floor. Existing combat clocks/capsules and economy retained; no claim of normal-world performance from this isolated scene."},"\t"))
	print("CATACLYSM_ACTOR_CRAFT %d checks, %d failures"%[checks,failures])
	get_tree().quit(0 if failures==0 else 1)

func _setup() -> void:
	var env:=WorldEnvironment.new()
	env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR
	env.environment.background_color=Color("768b91")
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color=Color("b8c4bb")
	env.environment.ambient_light_energy=.48
	add_child(env)
	var sun:=DirectionalLight3D.new()
	sun.rotation=Vector3(-.85,-.6,0)
	sun.light_color=Color("fff0d4")
	sun.light_energy=1.25
	sun.shadow_enabled=true
	add_child(sun)
	var ground:=MeshInstance3D.new()
	var box:=BoxMesh.new()
	box.size=Vector3(45,.2,32)
	ground.mesh=box
	ground.position.y=-.1
	var mat:=StandardMaterial3D.new()
	mat.albedo_color=Color("454a3e")
	mat.roughness=1
	ground.material_override=mat
	add_child(ground)
	camera=Camera3D.new()
	camera.fov=62
	add_child(camera)
	camera.make_current()
	var layer:=CanvasLayer.new()
	add_child(layer)
	caption=Label.new()
	caption.position=Vector2(24,20)
	caption.add_theme_font_size_override("font_size",23)
	layer.add_child(caption)

func _check_actors() -> void:
	var index:=0
	for id: String in RecoveredActorArt.definitions():
		var definition: Dictionary=RecoveredActorArt.definitions()[id]
		var at:=Vector3(float(index%6)*3.0-7.5,0,float(index/6)*4)
		var actor: Enemy=Boss.spawn_boss(self,at) if id=="forge_tyrant" else Enemy.spawn(self,StringName(id),at)
		actors[id]=actor
		index+=1
		actor.set_physics_process(false)
		var mesh:=actor._mesh
		var motion:=mesh.get_node("Motion") as CreatureMotion
		motion.set_physics_process(false)
		check(mesh.get_meta("authored_actor_id","")==id,"normal configure installs reviewed mesh: "+id)
		check(mesh.mesh.get_surface_count()==1 and mesh.material_override==actor._material,"one live status surface: "+id)
		check(mesh.get_child_count()==1 and actor.attack_released.get_connections().size()==1,"one sampler and release listener, no imported animation player: "+id)
		var capsule:=actor.get_node("CollisionShape3D") as CollisionShape3D
		check(capsule.shape is CapsuleShape3D and is_equal_approx(capsule.shape.radius,float(definition.collision.radius))
			and is_equal_approx(capsule.shape.height,float(definition.collision.height)),"existing capsule dimensions: "+id)
		var arrays:=mesh.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var bones: PackedInt32Array=arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array=arrays[Mesh.ARRAY_WEIGHTS]
		var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
		var source_bounds:=AABB(vertices[indices[0]]*mesh.scale,Vector3.ZERO)
		for vertex_index in int(definition.triangles)*3:
			source_bounds=source_bounds.expand(vertices[indices[vertex_index]]*mesh.scale)
		var expected_min: Array=definition.visual_bounds[0]
		var expected_max: Array=definition.visual_bounds[1]
		check(source_bounds.position.distance_to(Vector3(expected_min[0],expected_min[1],expected_min[2]))<.001
			and source_bounds.end.distance_to(Vector3(expected_max[0],expected_max[1],expected_max[2]))<.001,"runtime source silhouette matches reviewed world-metre envelope: "+id)
		var valid:=true
		var largest_bind_error:=0.0
		var largest_weight_error:=0.0
		for i in vertices.size():
			var restored:=Vector3.ZERO
			var total:=0.0
			for slot in 4:
				var bone:=bones[i*4+slot]
				var weight:=weights[i*4+slot]
				valid=valid and bone>=0 and bone<motion.rig.get_bone_count() and weight>=0.0 and is_finite(weight)
				total+=weight
				restored+=(motion.rig.get_bone_global_pose(bone)*mesh.skin.get_bind_pose(bone)*vertices[i])*weight
			valid=valid and is_equal_approx(total,1.0)
			valid=valid and restored.is_equal_approx(vertices[i])
			largest_bind_error=maxf(largest_bind_error,restored.distance_to(vertices[i]))
			largest_weight_error=maxf(largest_weight_error,absf(total-1.0))
		if not valid:print("Bind diagnostics ",id," position error ",largest_bind_error," weight error ",largest_weight_error)
		check(valid,"all imported/detail vertices retain exact bind pose: "+id)
		var shape_before:=capsule.shape
		var body_before:=actor.transform
		var life_before:=actor.life
		var clock_before:=actor._attack_cooldown
		motion.sample(.1,.15,.75)
		actor.attack_released.emit("strike")
		motion.sample(.05,0)
		var held:=motion.rig.get_bone_pose(0)
		motion.sample(.5,2,0,0,true)
		check(motion.rig.get_bone_pose(0)==held,"freeze holds the authored body: "+id)
		motion.sample(.1,0,0,0,false,true)
		check(motion.release_left==0 and actor.transform==body_before and actor.life==life_before
			and actor._attack_cooldown==clock_before and capsule.shape==shape_before,"pose sampling preserves body/rules and stagger cancels follow-through: "+id)
		actor.frozen_left=0
		actor._flash_left=.1
		actor._refresh_look()
		check(actor._material.emission_enabled and actor._material.albedo_color==Color.WHITE,"white normal tint preserves hit flash: "+id)
		actor._flash_left=0
		actor.frozen_left=1
		actor._refresh_look()
		check(actor._material.emission_enabled and actor._material.albedo_color.b>.9,"freeze still overrides body and embedded detail: "+id)
		actor.frozen_left=0
		actor.burning_left=1
		actor._refresh_look()
		check(actor._material.emission_enabled and actor._material.emission.r>.9,"burn still uses current danger colour: "+id)
		actor.burning_left=0
		actor._refresh_look()
		var grown_light:=int(definition.get("rig_version",1))==2
		check(actor._material.albedo_color==Color.WHITE and actor._material.emission_enabled==grown_light
			and (not grown_light or actor._material.emission_texture!=null),"status expiry restores normal tint and the correct local-light policy: "+id)
		var original_scale:=mesh.scale
		actor.configure(load("res://scripts/sim.gd").shared())
		check(mesh.scale.is_equal_approx(original_scale) and mesh.get_child_count()==1
			and actor.attack_released.get_connections().size()==1,"reconfigure restores one rig and applies family size once: "+id)
		(mesh.get_node("Motion") as CreatureMotion).set_physics_process(false)
		if actor is Boss:
			check(actor._telegraph_material.emission_enabled and actor._telegraph_material.emission_energy_multiplier==3.0,"boss inhale retains its dedicated strong tell")
			mesh.material_override=actor._telegraph_material
			check(mesh.material_override==actor._telegraph_material,"boss tell covers the entire imported single surface")
			mesh.material_override=actor._base_material
		else:
			actor.make_elite({"id":"fixture","display_name":"Elite"})
			check(mesh.scale.is_equal_approx(original_scale*1.3) and capsule.shape==shape_before,"elite visual growth leaves original collision: "+id)
			actor.configure(load("res://scripts/sim.gd").shared())
			# The review returns the disposable actor to an ordinary label after
			# checking elite growth; runtime respawns make a new actor instead.
			actor.elite_id=""
			actor._label.modulate=Color.WHITE
			(mesh.get_node("Motion") as CreatureMotion).set_physics_process(false)

func _check_stations() -> void:
	var sim:=WroughtwildSim.new()
	check(sim.load_tuning(load("res://scripts/sim.gd").get_tuning_directory()),"load isolated station rules")
	for item in ["wood","iron_ore","fieldstone","iron_fittings","bog_iron"]: sim.add_material(item,100)
	sim.add_material("vanguard",10)
	for id in ["workbench","mason_yard","forge_basic","forge_improved"]:
		check(sim.build_station(id),"existing station build/upgrade transaction: "+id)
		var site: StationSite=preload("res://scenes/station_site.tscn").instantiate()
		site.station_id=StringName(id)
		site.upgrade_station_id=&""
		add_child(site)
		site.position=Vector3(float(sites.size())*2.3-3.4,0,9)
		var before:=sim.export_json()
		site.refresh_visual(sim)
		sites[id]=site
		check(site._mesh.mesh.get_meta("contained_augmentation",false),"ordinary station mesh contains shared recovered inlay: "+id)
		check(site._mesh.material_override==null and site._mesh.mesh.get_surface_count()>AuthoredAssets.mesh_for(id).get_surface_count(),"station retains authored grain/materials: "+id)
		var collision:=site.get_node("CollisionShape3D") as CollisionShape3D
		check(collision.shape.size==Vector3(.96,2,.96) and collision.position==Vector3(0,1,0),"station body retains approved existing dimensions: "+id)
		check(before==sim.export_json(),"visual refresh does not spend inventory, fuel or quality: "+id)
		if id.begins_with("forge_"):
			check(site.get_node_or_null("HearthLight")!=null,"existing forge hearth remains visible: "+id)

func _check_resources() -> void:
	var terrain:=FlatTerrain.new()
	terrain.weathered=true
	terrain.frontier_look=preload("res://art/wildland_look.tres")
	terrain._world_profile="frontier_v4"
	var field:=PackedFloat32Array([0.0,.8,0.0,.8])
	terrain.map={"width":2,"height":2,"cell_size":1.0,"augmentation_field":field,"biomes":PackedInt32Array([0,0,0,0]),"biome_defs":[{"id":"meadow"}],"landmarks":[],"habitats":[]}
	add_child(terrain)
	terrain.set_process(false)
	var nodes:=Node3D.new()
	terrain.add_child(nodes)
	for visual in [&"tree",&"boulder"]:
		var node: ResourceNode=preload("res://scenes/resource_node.tscn").instantiate()
		node.visual=visual
		node.position=Vector3(1.5,0,.5)
		nodes.add_child(node)
		var mesh:=node.get_node("MeshInstance3D") as MeshInstance3D
		var collider:=node.get_node("CollisionShape3D") as CollisionShape3D
		var id: String="broadleaf_tree" if visual==&"tree" else "field_boulder"
		check(mesh.get_node_or_null("EmbeddedAugmentation")!=null,"native high-influence common resource exposes fragment: "+id)
		var shape:=collider.shape
		var stock:=node.remaining_units
		node._lean_from_player()
		check(mesh.get_node("EmbeddedAugmentation").get_parent()==mesh and collider.shape==shape and node.remaining_units==stock,"detail follows existing harvest visual without extra stock/body: "+id)
		node.position.x=.5
		node._use_authored(mesh,id)
		check(mesh.get_node_or_null("EmbeddedAugmentation")==null,"protected low-influence resource remains plain: "+id)
		node.position.x=1.5
		terrain._world_profile="frontier_v3"
		node._use_authored(mesh,id)
		check(mesh.get_node_or_null("EmbeddedAugmentation")==null,"older profile never infers augmentation: "+id)
		terrain._world_profile="frontier_v4"
		node.free()
	terrain.free()

func _capture(id: String, at: Vector3, target: Vector3, text: String) -> void:
	camera.global_position=at
	camera.look_at(target)
	caption.text=text
	for i in 3: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	check(get_viewport().get_texture().get_image().save_png(output.path_join(id+".png"))==OK,"capture "+id)

func _review() -> void:
	await _capture("actors",Vector3(0,4.8,-12),Vector3(0,1,2),"EXISTING CREATURES · REVIEWED BLENDER SKINS · LIVE GAME ACTORS")
	await _capture("workstations",Vector3(0,2,14.5),Vector3(0,.9,9),"CURRENT WORKSTATIONS · CONTAINED RECOVERED COMPONENTS")
	for id in ["ember_whelp","cinder_archer","gloom_crawler","forge_tyrant"]:
		var actor: Enemy=actors[id]
		var at:=actor.global_position
		var height: float=RecoveredActorArt.definitions()[id].visual_bounds[1][1]
		var distance:=maxf(3.7,height*1.5)
		await _capture("actor-"+id,at+Vector3(distance*.48,maxf(1.65,height*.7),-distance),at+Vector3.UP*height*.5,String(id).replace("_"," ").to_upper()+" · EXISTING BODY AND COMBAT CLOCK")
	var boss: Boss=actors.forge_tyrant
	boss._mesh.material_override=boss._telegraph_material
	await _capture("boss-tell",boss.global_position+Vector3(2.8,1.65,-5),boss.global_position+Vector3.UP*1.6,"FORGE TYRANT · EXISTING INHALE TELL REMAINS DOMINANT")
	boss._mesh.material_override=boss._base_material
