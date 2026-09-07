extends Node3D
## Real normal-spawn actors: imported anatomy, UVs, weighted binds, status and
## clocks. Also renders a repeatable review and measures a 60-actor mixed group.
const IDS = ["ash_hound","ember_whelp","valley_elk","marsh_wisp","cinder_wisp"]
const ANIMALS = ["wolf","boar","stag","moth","moth"]
var checks:=0
var failures:=0
var output: String
var actors: Array[Enemy]=[]
var camera: Camera3D
var caption: Label

func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL AUGMENTED BEASTS: ",label)

func poses(motion: CreatureMotion) -> Array:
	var values:=[]
	for i in motion.rig.get_bone_count(): values.append(motion.rig.get_bone_pose(i))
	return values

func _ready() -> void:
	output=ProjectSettings.globalize_path("res://../build/augmented-beasts/godot")
	DirAccess.make_dir_recursive_absolute(output)
	_setup()
	var sim:=load("res://scripts/sim.gd").shared() as WroughtwildSim
	var sim_before:=sim.export_json()
	for n in IDS.size():
		var id: String=IDS[n]
		var d: Dictionary=RecoveredActorArt.definitions()[id]
		var actor:=Enemy.spawn(self,StringName(id),Vector3((n-2)*3.4,0,0))
		actors.append(actor); actor.set_physics_process(false)
		var mesh:=actor._mesh
		var motion:=mesh.get_node("Motion") as CreatureMotion
		motion.set_physics_process(false)
		check(d.animal==ANIMALS[n] and int(d.rig_version)==2,"owner family mapping "+id)
		check(String(sim.enemy(id).get("currency_kind","marrow"))==String(d.kind),"existing Kind association "+id)
		check(mesh.material_override==actor._material and mesh.mesh.get_surface_count()==1,"one status surface "+id)
		check(actor._material.albedo_texture!=null and actor._material.roughness_texture!=null,"embedded material atlases "+id)
		check(actor._material.emission_enabled and actor._material.emission_texture!=null,"localised baseline energy "+id)
		check(actor._material.emission_operator==BaseMaterial3D.EMISSION_OP_MULTIPLY,"baseline energy multiplies the black mask instead of whitening the skin "+id)
		var bounds: Array=d.visual_bounds
		var expected:=AABB(Vector3(bounds[0][0],bounds[0][1],bounds[0][2]),Vector3(bounds[1][0],bounds[1][1],bounds[1][2])-Vector3(bounds[0][0],bounds[0][1],bounds[0][2]))
		var actual:=AABB(mesh.mesh.get_aabb().position*mesh.scale,mesh.mesh.get_aabb().size*mesh.scale)
		check(actual.position.distance_to(expected.position)<.002 and actual.size.distance_to(expected.size)<.002,"world metres applied once "+id)
		check(motion.rig.get_bone_count()==d.rig.size(),"complete anatomy skeleton "+id)
		var correct_parents:=true
		for i in d.rig.size():
			var parent:=String(d.rig[i].parent)
			correct_parents=correct_parents and motion.rig.get_bone_name(i)==String(d.rig[i].name)
			correct_parents=correct_parents and motion.rig.get_bone_parent(i)==(-1 if parent.is_empty() else motion.rig.find_bone(parent))
		check(correct_parents,"joint names and hierarchy "+id)
		var a:=mesh.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array=a[Mesh.ARRAY_VERTEX]
		var bones: PackedInt32Array=a[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array=a[Mesh.ARRAY_WEIGHTS]
		var uvs: PackedVector2Array=a[Mesh.ARRAY_TEX_UV]
		var valid:=uvs.size()==vertices.size()
		var weighted_vertices:=0
		for i in vertices.size():
			var total:=0.0
			var restored:=Vector3.ZERO
			var active:=0
			for j in 4:
				var w:=weights[i*4+j]
				var b:=bones[i*4+j]
				valid=valid and is_finite(w) and w>=0 and b>=0 and b<motion.rig.get_bone_count()
				total+=w
				if w>0.001:active+=1
				restored+=(motion.rig.get_bone_global_pose(b)*mesh.skin.get_bind_pose(b)*vertices[i])*w
			if active>1:weighted_vertices+=1
			valid=valid and is_equal_approx(total,1.0) and restored.is_equal_approx(vertices[i])
			valid=valid and uvs[i].x>0 and uvs[i].x<1 and uvs[i].y>0 and uvs[i].y<1
		check(valid,"normalised weights, exact bind reconstruction and bounded atlas UVs "+id)
		check(d.animal=="moth" or weighted_vertices>100,"blended anatomical skin "+id)
		var body:=actor.transform
		var capsule:=actor.get_node("CollisionShape3D") as CollisionShape3D
		var shape:=capsule.shape as CapsuleShape3D
		check(is_equal_approx(shape.radius,.35) and is_equal_approx(shape.height,1.3) and capsule.position==Vector3(0,.65,0),"retained movement/hurt body "+id)
		var stats: Array=[actor.life,actor.damage,actor.damage_type,actor.attack_range,actor._attack_cooldown,actor.projectile_rules.duplicate(true)]
		motion.sample(.13,.30)
		var walking:=poses(motion)
		if d.animal=="moth":
			var left:=motion.rig.find_bone("forewing_l")
			var right:=motion.rig.find_bone("forewing_r")
			check(motion.rig.get_bone_pose_rotation(left)!=motion.rig.get_bone_pose_rotation(right),"paired wings flap in opposite directions "+id)
			var leg_roots:=0
			var wing_roots:=0
			for joint: Dictionary in d.rig:
				if joint.motion=="insect_leg":leg_roots+=1
				if joint.motion in ["forewing","hindwing"]:wing_roots+=1
			check(leg_roots==6 and wing_roots==4,"six thoracic legs and four wing roots "+id)
		else:
			check(motion.rig.get_bone_pose_rotation(motion.rig.find_bone("front_l_lower"))!=Quaternion.IDENTITY
				or motion.rig.get_bone_pose_rotation(motion.rig.find_bone("front_r_lower"))!=Quaternion.IDENTITY,"articulated knee bends "+id)
			var lowest:=INF
			var target:=INF
			for i in d.rig.size():
				if not d.rig[i].has("sole"):continue
				var p: Array=d.rig[i].sole
				var sole:=Vector3(p[0],p[1],p[2])/mesh.scale
				lowest=minf(lowest,(motion.rig.get_bone_global_pose(i)*(sole-motion._points[i])).y)
				target=minf(target,sole.y)
			check(is_finite(lowest) and absf(lowest-target)<.0001,"a supporting foot remains on its authored ground plane "+id)
		motion.sample(.5,1,.7,0,true)
		check(poses(motion)==walking,"freeze holds every joint "+id)
		actor.attack_released.emit("strike")
		check(motion.release_left>0,"existing release drives presentation "+id)
		motion.sample(.03,0)
		motion.sample(.03,0,1,0,false,true)
		check(motion.release_left==0,"stagger cancels release "+id)
		check(actor.transform==body and capsule.shape==shape and stats==[actor.life,actor.damage,actor.damage_type,actor.attack_range,actor._attack_cooldown,actor.projectile_rules],"animation cannot mutate body/combat "+id)
		for status in ["freeze","hit","burn","bleed","normal"]:
			actor.frozen_left=1 if status=="freeze" else 0
			actor._flash_left=1 if status=="hit" else 0
			actor.burning_left=1 if status=="burn" else 0
			actor.bleeding_left=1 if status=="bleed" else 0
			actor._refresh_look()
			check((actor._material.emission_texture!=null)==(status=="normal"),"status controls the emission mask "+id+" "+status)
			check(actor._material.emission_operator==(BaseMaterial3D.EMISSION_OP_MULTIPLY if status=="normal" else BaseMaterial3D.EMISSION_OP_ADD),"status preserves unmasked whole-body feedback "+id+" "+status)
		var scale_before:=mesh.scale
		actor.make_elite({"id":"review","display_name":"Review"})
		check(mesh.scale.is_equal_approx(scale_before*1.3) and capsule.shape==shape,"elite only scales visual "+id)
		actor.configure(sim); actor.elite_id=""; actor._label.modulate=Color.WHITE
		motion=mesh.get_node("Motion") as CreatureMotion; motion.set_physics_process(false)
		check(mesh.scale.is_equal_approx(scale_before) and mesh.get_child_count()==1 and actor.attack_released.get_connections().size()==1,"reconfiguration has one rig, one clock, one scale "+id)
		check(actor.flees==(id=="valley_elk"),"only stag is passive "+id)
		_check_import(id,d)
	check(sim.export_json()==sim_before,"art work leaves native save and economy unchanged")
	var timings:=await _crowd_review()
	if DisplayServer.get_name()!="headless":await _render_review()
	var result: Dictionary={"checks":checks,"failures":failures,"crowd":timings,"scope":"actual normal-spawn actors on an isolated review floor; rendering timings are not normal-world benchmarks"}
	var file:=FileAccess.open(output.path_join("checks.json" if DisplayServer.get_name()=="headless" else "render-checks.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t"))
	print("AUGMENTED_BEASTS %d checks, %d failures"%[checks,failures])
	get_tree().quit(0 if failures==0 else 1)

func _check_import(id: String,d: Dictionary) -> void:
	var source: Node=(load("res://assets/authored/mobs/"+id+".glb") as PackedScene).instantiate()
	var animations: Array[Node]=source.find_children("*","AnimationPlayer",true,false)
	check(animations.size()==1,"one source animation player "+id)
	if not animations.is_empty():
		var player:=animations[0] as AnimationPlayer
		var count:=0
		var safe:=true
		for name in player.get_animation_list():
			if name=="RESET":continue
			count+=1
			var animation:=player.get_animation(name)
			for i in animation.get_track_count():safe=safe and animation.track_get_type(i) in [Animation.TYPE_POSITION_3D,Animation.TYPE_ROTATION_3D,Animation.TYPE_SCALE_3D]
		check(count==d.clips.size() and safe,"source preview clips contain only transforms "+id)
	source.free()

func _crowd_review() -> Dictionary:
	var group: Array[Enemy]=[]
	for i in 60:
		var actor:=Enemy.spawn(self,StringName(IDS[i%5]),Vector3((i%10-5)*2.4,0,8+int(i/10)*2.5))
		actor.set_physics_process(false)
		(actor._mesh.get_node("Motion") as CreatureMotion).set_physics_process(false)
		group.append(actor)
	var samples:=[]
	var frames_ms:=[]
	var previous_frame:=Time.get_ticks_usec()
	var old_camera:=camera.transform
	camera.position=Vector3(0,18,-15);camera.look_at(Vector3(0,1,14))
	for frame in 90:
		var before:=Time.get_ticks_usec()
		for actor in group:(actor._mesh.get_node("Motion") as CreatureMotion).sample(1.0/60,.035)
		if frame>=30:samples.append((Time.get_ticks_usec()-before)/1000.0)
		if DisplayServer.get_name()!="headless":
			await get_tree().process_frame
			var now:=Time.get_ticks_usec()
			if frame>=30:frames_ms.append((now-previous_frame)/1000.0)
			previous_frame=now
	samples.sort()
	frames_ms.sort()
	check(group.size()==60 and not samples.is_empty(),"mixed 60-actor pose sample completes")
	for actor in group:actor.free()
	camera.transform=old_camera
	return {"actors":60,"pose_median_ms":samples[samples.size()/2],"pose_p95_ms":samples[int(samples.size()*.95)],"frame_median_ms":0 if frames_ms.is_empty() else frames_ms[frames_ms.size()/2],"frame_p95_ms":0 if frames_ms.is_empty() else frames_ms[int(frames_ms.size()*.95)],"renderer":DisplayServer.get_name()}

func _setup() -> void:
	var environment:=WorldEnvironment.new(); environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR
	environment.environment.background_color=Color("77898a")
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color=Color("c9d4cc"); environment.environment.ambient_light_energy=.65
	add_child(environment)
	var light:=DirectionalLight3D.new(); light.rotation=Vector3(-.7,-.6,0); light.light_energy=1.4; light.shadow_enabled=true; add_child(light)
	var ground:=MeshInstance3D.new(); var box:=BoxMesh.new(); box.size=Vector3(50,.1,40); ground.mesh=box; ground.position.y=-.1
	var material:=StandardMaterial3D.new(); material.albedo_color=Color("495044"); material.roughness=1; ground.material_override=material; add_child(ground)
	camera=Camera3D.new(); camera.position=Vector3(0,5,-19); add_child(camera); camera.look_at(Vector3(0,1,1)); camera.make_current()
	var layer:=CanvasLayer.new(); add_child(layer); caption=Label.new(); caption.position=Vector2(24,18); caption.add_theme_font_size_override("font_size",24); layer.add_child(caption)

func _capture(name: String) -> void:
	for i in 3:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	check(get_viewport().get_texture().get_image().save_png(output.path_join(name+".png"))==OK,"render capture "+name)

func _render_review() -> void:
	caption.text="AUGMENTED BEASTS · REAL GODOT ACTORS · EXISTING COMBAT CONTRACTS"
	await _capture("roster")
	camera.fov=50
	for actor in actors:
		for other in actors:other.visible=other==actor
		var bounds:=actor._mesh.mesh.get_aabb(); var height:=bounds.end.y*actor._mesh.scale.y
		var moth_family:=String(actor.enemy_id).ends_with("wisp")
		camera.position=actor.position+(Vector3(1.0,1.5,-1.7) if moth_family else Vector3(1.8,1.2,-2.7) if height<1.5 else Vector3(2.4,maxf(1.5,height*.75),-3.8))
		if height>2.0:camera.position=actor.position+(camera.position-actor.position)*1.2
		camera.look_at(actor.position+Vector3(0,.85 if moth_family else height*.52,0))
		caption.text=actor.display_name+" · "+String(RecoveredActorArt.definitions()[String(actor.enemy_id)].animal)
		await _capture(String(actor.enemy_id))
		if not moth_family:
			var sampler:=actor._mesh.get_node("Motion") as CreatureMotion
			for frame in 6:
				sampler.sample(.08,.08)
				await _capture(String(actor.enemy_id)+"-walk-%02d"%frame)
			if not actor.flees:
				sampler.sample(.05,0,1)
				await _capture(String(actor.enemy_id)+"-windup")
				actor.attack_released.emit("strike");sampler.sample(.03,0)
				await _capture(String(actor.enemy_id)+"-release")
	var moth:=actors[4]
	for other in actors:other.visible=other==moth
	var motion:=moth._mesh.get_node("Motion") as CreatureMotion
	camera.position=moth.position+Vector3(1.2,1.6,-2.1);camera.look_at(moth.position+Vector3(0,.8,0))
	for i in 8:
		motion.sample(.04,0);await _capture("moth-wing-%02d"%i)
	moth.frozen_left=1;moth._refresh_look();caption.text="CINDER MOTH · EXISTING FREEZE OVERRIDE";await _capture("moth-frozen")
