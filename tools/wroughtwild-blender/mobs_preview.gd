extends SceneTree
## Render actual imported skins, capsule overlays and a short presentation reel.
var animations: Dictionary = {}
var wires: Array[Node3D] = []

func _initialize() -> void:
	call_deferred("run")

func capsule_wire(contract: Dictionary) -> MeshInstance3D:
	var radius: float = contract.radius
	var height: float = contract.height
	var centre := Vector3(contract.centre[0],contract.centre[1],contract.centre[2])
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color("81dbb4")
	material.no_depth_test = true
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES,material)
	for axis in 2:
		for half in 2:
			for i in 32:
				for j in [i,i+1]:
					var angle: float = half*PI+j*PI/32
					var p := Vector3.ZERO
					p[axis*2] = cos(angle)*radius
					p.y = sin(angle)*radius + (1 if half==0 else -1)*(height/2-radius)
					mesh.surface_add_vertex(p+centre)
		for side in [-1,1]:
			for end in [-1,1]:
				var p := Vector3(0,end*(height/2-radius),0)
				p[axis*2] = side*radius
				mesh.surface_add_vertex(p+centre)
	for level in [-1,1]:
		for i in 48:
			for j in [i,i+1]:
				var angle: float = j*TAU/48
				mesh.surface_add_vertex(centre+Vector3(cos(angle)*radius,level*(height/2-radius),sin(angle)*radius))
	mesh.surface_end()
	var result := MeshInstance3D.new()
	result.mesh = mesh
	return result

func find_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var result := find_player(child)
		if result != null:
			return result
	return null

func run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(2200,1400)
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var stage := Node3D.new()
	viewport.add_child(stage)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color("222b27")
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("c2c9bf")
	world.environment.ambient_light_energy = .75
	stage.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42,135,0)
	sun.light_energy = 1.6
	sun.shadow_enabled = true
	stage.add_child(sun)
	var floor_mesh := MeshInstance3D.new()
	var floor_box := BoxMesh.new()
	floor_box.size = Vector3(9.7,.04,9.5)
	floor_mesh.mesh = floor_box
	floor_mesh.position.y = -.028
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color("414a42")
	floor_material.roughness = 1
	floor_mesh.material_override = floor_material
	stage.add_child(floor_mesh)
	var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://report.json"))
	var placements := {
		"ember_whelp":Vector3(-3.3,0,-3),"ash_hound":Vector3(-1.1,0,-3),"gloom_crawler":Vector3(1.1,0,-3),"bog_lurker":Vector3(3.3,0,-3),
		"cinder_archer":Vector3(-3.3,0,0),"stone_husk":Vector3(-1.1,0,0),"shrieker":Vector3(1.1,0,0),"hollow_knight":Vector3(3.3,0,0),
		"valley_elk":Vector3(-3.3,0,3),"marsh_wisp":Vector3(-1.1,0,3),"cinder_wisp":Vector3(1.1,0,3),"forge_tyrant":Vector3(3.3,0,3)}
	for id in placements:
		var visual: Node3D = load("res://"+id+".glb").instantiate()
		stage.add_child(visual)
		visual.position = placements[id]
		var player := find_player(visual)
		player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		animations[id] = player
		var wire := capsule_wire(report.assets[id].collision)
		stage.add_child(wire)
		wire.position = placements[id]
		wires.append(wire)
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.position = Vector3(-4.6,9,-14)
	camera.look_at(Vector3(0,1.0,0))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 12.3
	camera.current = true
	var ui := CanvasLayer.new()
	stage.add_child(ui)
	var title := Label.new()
	title.position = Vector2(40,26)
	title.text = "WROUGHTWILD / MOB ROSTER\nActual Godot imports - world metres - simple part rigs"
	title.add_theme_font_size_override("font_size",27)
	ui.add_child(title)
	var note := Label.new()
	note.position = Vector2(40,1290)
	note.add_theme_font_size_override("font_size",24)
	note.text = "GREEN: existing actor capsules. Mob size and elite enlargement currently do not resize these bodies.\nWisps have substantial empty collision space; crawler legs and larger silhouettes extend beyond their capsule."
	ui.add_child(note)
	for frame in 8:
		await process_frame
	for id in placements:
		var label := Label.new()
		label.text = report.assets[id].display_name + (" (passive)" if report.assets[id].passive else "")
		label.size.x = 280
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.position = camera.unproject_position(placements[id]+Vector3(0,0,-.22))-Vector2(140,0)
		label.add_theme_font_size_override("font_size",21)
		ui.add_child(label)
	await process_frame
	await RenderingServer.frame_post_draw
	var error := viewport.get_texture().get_image().save_png("res://mobs-collision.png")
	for wire in wires:
		wire.hide()
	note.text = "Ten hostile families + Forge Tyrant + passive Valley Elk\nPresentation study: imported skins and clips; AI, damage, event timing and normal game art are unchanged."
	await process_frame
	await RenderingServer.frame_post_draw
	error = maxi(error,viewport.get_texture().get_image().save_png("res://mobs-roster.png"))
	DirAccess.make_dir_recursive_absolute("res://motion")
	for frame in 24:
		var t := frame/12.0
		for id in animations:
			var player: AnimationPlayer = animations[id]
			var data: Dictionary = report.assets[id]
			var clip := "walk"
			var seek := fmod(t,1.0)
			if t>=1.0 and not data.passive:
				var windup: float = data.clips.windup
				clip = "windup" if t-1.0<=windup else "release"
				seek = minf(t-1.0,windup) if clip=="windup" else minf(t-1.0-windup,float(data.clips.release))
			player.play(clip)
			player.seek(seek,true)
			player.advance(0)
		note.text = ("IN-PLACE WALK" if t<1 else "EXISTING WIND-UP LENGTHS / RELEASE POSES") + "  |  Preview time %.2f s\nPresentation clips only. Elk continues walking; no attack clips or damage events." % t
		await process_frame
		await RenderingServer.frame_post_draw
		error = maxi(error,viewport.get_texture().get_image().save_png("res://motion/frame-%02d.png" % frame))
	var html := """<!doctype html><meta charset="utf-8"><title>Wroughtwild mob motion study</title>
<style>body{margin:0;background:#17201b;color:#e6ebe4;font:18px system-ui}main{max-width:1400px;margin:auto;padding:20px}img{width:100%;display:block}button,input{font:inherit}button{padding:8px 20px}input{width:60%;vertical-align:middle}</style>
<main><h1>Wroughtwild / mob motion study</h1><p>Actual Godot skinning: one in-place stride, then the existing wind-up lengths and release poses. Passive elk keeps walking. These clips contain no hit events.</p><button id="play">Pause</button> <input id="scrub" type="range" min="0" max="23" value="0"><span id="counter"></span><img id="view" alt="Animated mob roster" src="motion/frame-00.png"><p><a href="mobs-collision.png">Current capsule comparison</a></p></main>
<script>let frame=0,playing=true;const view=document.querySelector('#view'),scrub=document.querySelector('#scrub'),button=document.querySelector('#play');function show(){view.src='motion/frame-'+String(frame).padStart(2,'0')+'.png';scrub.value=frame;document.querySelector('#counter').textContent=' '+(frame/12).toFixed(2)+' s'}button.onclick=()=>{playing=!playing;button.textContent=playing?'Pause':'Play'};scrub.oninput=()=>{frame=Number(scrub.value);show()};setInterval(()=>{if(playing){frame=(frame+1)%24;show()}},1000/12);</script>"""
	var file := FileAccess.open("res://mobs-motion.html",FileAccess.WRITE)
	file.store_string(html)
	file.close()
	print("BLENDER_MOBS_PREVIEW ",error)
	quit(error)
