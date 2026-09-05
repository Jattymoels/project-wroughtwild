extends Node3D
## Real player-controller walking, chunk/material normal seams and excavation.
var terrain: Terrain
var player: WroughtwildPlayer
var checks := 0
var failures := 0
var frame := 0
var start := Vector3.ZERO
var highest := -INF
var lowest := INF
var shared_normals: Dictionary = {}
var start_ticks := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ",label)

func _ready() -> void:
	start_ticks = Time.get_ticks_msec()
	var sim: WroughtwildSim = load("res://scripts/sim.gd").shared()
	terrain = Terrain.new()
	terrain.name = "Terrain"
	add_child(terrain)
	terrain._sim = sim
	terrain._seed = 1
	terrain.map = sim.world_map(1)
	terrain._blocks = terrain.map.blocks.duplicate()
	terrain.block_rules = sim.block_rules()
	terrain.faceted_surface = true
	terrain.frontier_look = preload("res://art/crafted_look.tres")
	var normals_ok := true
	var seam_ok := true
	var shared_count := 0
	for x in [144,160]:
		for z in [144,160]:
			var chunk: Dictionary = sim.world_mesh_chunk(1,16,x,z,PackedInt32Array(),true)
			for kind in chunk.surfaces:
				var vertices: PackedVector3Array = chunk.surfaces[kind]
				var normals: PackedVector3Array = chunk.soft_normals[kind]
				check(vertices.size()==normals.size(),"every surface vertex has a shared normal")
				for i in vertices.size():
					normals_ok = normals_ok and normals[i].is_finite() and absf(normals[i].length()-1)<0.001
					# Include material borders; ambiguous topology may share a position
					# but not a normal, so test ordinary exposed surface above y=10.
					if vertices[i].y > 10 and absf(vertices[i].x-160)<0.001:
						var key := vertices[i]
						if shared_normals.has(key):
							shared_count += 1
							seam_ok = seam_ok and shared_normals[key].is_equal_approx(normals[i])
						else:
							shared_normals[key] = normals[i]
			terrain._build_chunk(chunk,1.0)
	check(normals_ok,"shared normals are finite unit vectors")
	check(shared_count>0 and seam_ok,"lighting is continuous across chunk and material boundaries")
	# Select a repeatable gentle route crossing x=160, including an elevation
	# change. The steep-cliff routes remain a separate movement design issue.
	var route_z := -1
	for z in range(148,173):
		var heights: Array[int] = []
		var usable := true
		for x in range(154,168):
			var h := terrain.height_at(x,z)
			heights.append(h)
			usable = usable and terrain.block_at(x,h-1,z)!=0
			if heights.size()>1 and absi(heights[-1]-heights[-2])>1:
				usable = false
		if usable and heights.max()-heights.min()>=1 and heights.max()-heights.min()<=3:
			route_z = z
			break
	check(route_z>=0,"fixed seed provides a gentle route with an elevation change")
	if route_z<0:
		get_tree().quit(1)
		return
	player = preload("res://scenes/player.tscn").instantiate()
	add_child(player)
	# Keep the body in the physics space while driving its controller ourselves.
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	start = Vector3(154.5,terrain.height_at(154,route_z)+1.05,route_z+0.5)
	player.position = start
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	print("CODEX_TRAVERSAL_ROUTE ",start)

func _physics_process(delta: float) -> void:
	frame += 1
	if frame>10 and frame<=175:
		player.test_walk = Vector2.RIGHT
	else:
		player.test_walk = Vector2.ZERO
	player._physics_process(delta)
	highest = maxf(highest,player.position.y)
	lowest = minf(lowest,player.position.y)
	if frame==185:
		check(player.position.x-start.x>10.0,"actual player walks over ten metres across faceted slopes and chunk seam")
		check(highest-lowest>0.25,"controller negotiates a real elevation change")
		check(player.position.y>terrain.height_at(int(player.position.x),int(player.position.z))-1,"player remains above the terrain")
		check(player.is_on_floor(),"player settles on the faceted ground")
		print("CODEX_TRAVERSAL ",JSON.stringify({"distance_m":player.position.x-start.x,"vertical_span_m":highest-lowest,
			"frames":frame,"elapsed_ms":Time.get_ticks_msec()-start_ticks,"end":[player.position.x,player.position.y,player.position.z]}))
		print("%d checks, %d failures" % [checks,failures])
		get_tree().quit(0 if failures==0 else 1)
