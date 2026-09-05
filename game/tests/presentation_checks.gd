extends Node3D
## Rendering-independent contracts for meshes, status feedback, labels and the
## cached surface sampler. Actual image quality is reviewed in the gallery.
var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ",label)

func _ready() -> void:
	var look := preload("res://art/character_look.tres")
	for role in ["player","peddler","melee","fast","swarm","guard","boss","grazer","skirmisher"]:
		var mesh: ArrayMesh = look.build(role)
		var arrays := mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var valid := true
		for i in range(0,vertices.size(),3):
			var n := (vertices[i+2]-vertices[i]).cross(vertices[i+1]-vertices[i])
			if n.length_squared()>0.00000001:
				valid = valid and n.dot(normals[i]+normals[i+1]+normals[i+2])>0.0
		check(valid and vertices.size()>100,"outward character triangles: "+role)
		check(mesh.get_surface_count()==1 and vertices.size()<12000,"single-surface bounded actor: "+role)
	var enemy := Enemy.spawn(self,&"gloom_crawler",Vector3.ZERO)
	enemy.set_physics_process(false)
	var collider: CollisionShape3D = enemy.get_node("CollisionShape3D")
	check(is_equal_approx(collider.shape.radius,0.35) and is_equal_approx(collider.shape.height,1.3),"silhouette preserves enemy collision")
	var life := enemy.life
	enemy.take_damage(1.0)
	check(enemy.life==life-1.0 and enemy._material.emission_enabled,"new mesh retains damage flash and life")
	enemy._flash_left = 0.0
	enemy.frozen_left = 1.0
	enemy._refresh_look()
	check(enemy._material.albedo_color.b>0.9 and enemy._material.vertex_color_use_as_albedo,"freeze still colours the whole mesh")
	var camera := Camera3D.new()
	add_child(camera)
	camera.make_current()
	var label := enemy.get_node("Label3D") as Label3D
	label.position = Vector3(0,0,-2)
	label._process(0.0)
	var close_scale := label.scale.x
	label.position.z = -4.0
	label._process(0.0)
	check(is_equal_approx(label.scale.x/4.0,close_scale/2.0),"near labels have constant projected size")
	label.position = Vector3(0,0,-30)
	label._process(0.0)
	check(not label.visible,"distant label hidden")
	label.position = Vector3(0,0,4)
	label._process(0.0)
	check(not label.visible and not label.no_depth_test,"behind-camera labels hidden; walls can occlude names")
	label.position = Vector3(0,0,-3)
	label._process(0.0)
	check(label.visible,"focused label returns after turning back")
	var peddler := Peddler.new()
	add_child(peddler)
	check(peddler._mesh.mesh is ArrayMesh and peddler.interact_label().contains("trade"),"peddler silhouette keeps interaction")
	var boss := Boss.spawn_boss(self,Vector3(5,0,0))
	boss.set_physics_process(false)
	check(boss._mesh.mesh is ArrayMesh and boss._telegraph_material.emission_enabled,"boss keeps luminous breath telegraph")
	enemy.enemy_id = &"stone_husk"
	enemy.configure(load("res://scripts/sim.gd").shared())
	var configured_scale := enemy._mesh.scale
	enemy.configure(load("res://scripts/sim.gd").shared())
	check(enemy._mesh.scale.is_equal_approx(configured_scale),"reconfiguration does not repeatedly shrink a humanoid")
	# Sloping triangle at the far map corner, including exact edges/vertices.
	var a := Vector3(300,8,300)
	var b := Vector3(301,8.4,300)
	var c := Vector3(300,8.7,301)
	var sampler := SurfaceSampler.new(PackedVector3Array([a,b,c]))
	var stable := true
	for i in 21:
		for j in range(21-i):
			var point := a+(b-a)*(float(i)/20.0)+(c-a)*(float(j)/20.0)
			var actual := sampler.height_at(point.x,point.z,point.y)
			stable = stable and is_finite(actual) and absf(actual-point.y)<0.00005
	check(stable,"231 far-coordinate slope/edge samples retain precision")
	print("CODEX_PRESENTATION %d checks, %d failures" % [checks,failures])
	get_tree().quit(0 if failures==0 else 1)
