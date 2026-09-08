extends "res://tests/exploration_review.gd"
## The same full-world cameras and route/collision checks on both revisions.
func _select_views() -> void:
	super._select_views()
	if smithy.is_empty(): return
	var centre:=terrain.surface_position(smithy.x,smithy.z)
	var path: PackedVector3Array=smithy.approach
	var departure: PackedVector3Array=smithy.discovery_route
	# Keep the parent's eight contract views, adding foreground/middle/horizon
	# views of the actual surroundings rather than a separately dressed gallery.
	review_views.append({"id":"smithy_woodland","at":path[maxi(0,path.size()-40)],"target":centre,"target_height":2.5,"native_id":smithy.id,"timed":true})
	var linked: Dictionary={}
	for site: Dictionary in terrain.map.rare_sites:
		if site.id==smithy.linked_site_id: linked=site
	if not linked.is_empty():
		var at: Vector3=departure[maxi(0,departure.size()-9)]
		review_views.append({"id":"ventlung_host","at":at,"target":Vector3(linked.x+.5,linked.y,linked.z+.5),"target_height":1.1,"native_id":linked.id,"timed":false})
	# Parent checks the original eight; retain that contract while our additional
	# views are captured after its own complete review (see _route_check below).
	set_meta("extra_views",review_views.slice(8))
	review_views=review_views.slice(0,8)

func _route_check() -> void:
	var canopies: Variant = terrain.resource_stream.get("canopies")
	report.canopies = {"authored_near_limit_m":preload("res://art/material_library.tres").authored_tree_distance,"distant_batches":canopies.root.get_child_count() if canopies!=null else 0,"surviving_tree_slots":canopies.slots.size() if canopies!=null else 0,"resource_stream_radius_m":terrain.resource_stream.radius_m}
	for view: Dictionary in get_meta("extra_views",[]): await _review_view(view)
	await super._route_check()
	if smithy.is_empty(): return
	report.walks = []
	await _target_walk("day")
	var energy: float = $Sun.light_energy
	var colour: Color = $Sun.light_color
	$Sun.light_energy = energy*.48
	$Sun.light_color = Color("d9bd91")
	await _target_walk("dusk")
	$Sun.light_energy = energy
	$Sun.light_color = colour

func _target_walk(light: String) -> void:
	var path: PackedVector3Array = smithy.approach
	path = path.slice(maxi(0,path.size()-40))
	path.append_array(smithy.discovery_route)
	await _settle(path[0],64)
	terrain.set_process(false)
	var times: Array[float] = []
	var streaming: Array[float] = []
	var length := 0.0
	var valid_ground := true
	var last := Time.get_ticks_usec()
	for segment in path.size()-1:
		var a := path[segment]; var b := path[segment+1]
		var distance := Vector2(a.x,a.z).distance_to(Vector2(b.x,b.z))
		length += distance
		var steps := maxi(1,ceili(distance/(5.0/60.0)))
		for step in steps:
			var at := a.lerp(b,float(step)/steps)
			var began := Time.get_ticks_usec()
			terrain._tick_streaming(1.0/60.0,at)
			streaming.append((Time.get_ticks_usec()-began)/1000.0)
			var ground := _ground(at)
			valid_ground = valid_ground and ground.is_finite()
			if not ground.is_finite(): continue
			player.position = ground+Vector3.UP*1.2
			review_camera.position = ground+Vector3.UP*1.65
			var ahead := Vector3(b.x-a.x,0,b.z-a.z)
			if ahead.length_squared()>.001: review_camera.look_at(review_camera.position+ahead)
			await get_tree().process_frame
			var now := Time.get_ticks_usec()
			times.append((now-last)/1000.0)
			last=now
		if segment%20==0 and DisplayServer.get_name()!="headless":
			caption.text="SMITHY TO VENTLUNG · %s · WALK %d" % [light.to_upper(),segment]
			await _capture("walk-%s-%03d" % [light,segment])
			last=Time.get_ticks_usec() # screenshots are excluded from timings
	check(valid_ground,"continuous route camera retains ground throughout "+light)
	times.sort(); streaming.sort()
	report.walks.append({"light":light,"metres":length,"frames":times.size(),"median_ms":times[times.size()/2],"p95_ms":times[floori(times.size()*.95)],"max_ms":times.back(),"stream_p95_ms":streaming[floori(streaming.size()*.95)],"stream_max_ms":streaming.back(),"scope":"Fixed-step 5 m/s, 60 simulation ticks/s camera traverse through production streaming; rendered wall-frame costs exclude captures. No player-input or combat claim."})
	terrain.set_process(true)
