extends "res://scripts/sandpit.gd"
## All fixture kits through catalogue, actual camera ghost, click and E on V6.
var checks:=0
var failures:=0
const SAVE:="user://int03c-generated-fixtures.json"

func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL GENERATED_FIXTURES: ",label)

func _ready() -> void:
	world_seed=77
	_build_world(world_seed)
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.combat.set_physics_process(false)
	player.placement.set_physics_process(false)
	player.spring_arm.set_physics_process(false)
	mob_packs.set_physics_process(false)
	mob_packs.set_process(false)
	set_physics_process(false)
	var manager:=SaveManager.new()
	if OS.get_cmdline_user_args().has("--placement-restore-only"):
		var saved: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(SAVE))
		check(manager.read(SAVE,player),"fresh V6 checkpoint loads: "+manager.last_error)
		check(JSON.parse_string(_sim().contraption_save())==JSON.parse_string(saved.contraptions),"fresh V6 exact fixture/source ledger")
		check(JSON.parse_string(_sim().export_json())==JSON.parse_string(saved.sim),"fresh V6 exact possessions and progression")
	else:
		var home: Dictionary=terrain.map.home_sites[0]
		for i in _sim().contraption_kinds().size():
			var kind: String=_sim().contraption_kinds()[i]
			var kit:=kind+"_kit"
			_sim().add_material(kit,1)
			player.placement.set_build_mode_enabled(true)
			player.build_palette.open_panel()
			player.build_palette.select_entry(StringName(kit),"kit")
			player.build_palette.close_panel()
			var found:=false
			for attempt in 25:
				var x:=int(home.x)-10+(i%3)*7+(attempt%5)
				var z:=int(home.z)-10+(i/3)*7+(attempt/5)
				var at:=terrain.surface_position(x,z)
				terrain.ensure_area(at,16)
				at.y=terrain.rendered_height(at.x,at.z,at.y)
				player.position=at+Vector3(0,2.5,3)
				player.camera.global_position=player.position
				player.camera.look_at(at)
				for frame in 2: await get_tree().physics_frame
				player.placement._update_preview()
				if player.placement.preview_valid:
					found=true
					break
				check(not player.placement.try_place_block() and _sim().material_count(kit)==1,kind+": rejected terrain/prop position retains kit")
			check(found,kind+": actual camera finds a legal home-ground footprint")
			if not found: continue
			var ghost:=player.placement._preview_mesh.global_transform
			var cell: Vector3i=player.placement.preview_element.cell
			var key:="fixture_%d_%d_%d" % [cell.x,cell.y,cell.z]
			var click:=InputEventAction.new()
			click.action="primary_action"
			click.pressed=true
			player._unhandled_input(click)
			var site:=ContraptionSite.find_site(get_tree(),key)
			check(site!=null and _sim().material_count(kit)==0,kind+": click converts one kit into one scene")
			if site!=null: check(site.global_transform.is_equal_approx(ghost),kind+": world body exactly matches preview pivot/yaw")
			await get_tree().physics_frame
		check(manager.write(SAVE,player),"V6 complete fixture checkpoint writes")
	await get_tree().physics_frame
	check(_sim().contraption_ids().size()==7 and get_tree().get_nodes_in_group("contraptions").size()==7,"all seven fixture kinds have exactly one native and visible owner")
	for key in _sim().contraption_ids():
		var site:=ContraptionSite.find_site(get_tree(),key)
		check(site!=null and site._visual.is_visible_in_tree(),"generated fixture scene stays visible")
		if site==null: continue
		var target:=site.position+Vector3.UP*ContraptionSite.bounds_for(site.kind).y*.5
		terrain.ensure_area(target,16)
		player.position=target+Vector3(0,.3,2.5)
		player.camera.global_position=player.position
		player.camera.look_at(target)
		player.placement.set_build_mode_enabled(false)
		for frame in 2: await get_tree().physics_frame
		# SpringArm's native internal update resets its child translation even
		# with scripted physics disabled. Aim from its actual settled eye pose.
		player.camera.position=Vector3.ZERO
		player.camera.look_at(target)
		var hit:=player.placement._get_view_trace()
		check(hit.get("collider")==site,site.kind+": generated fixture exposed to ray; hit="+str(hit.get("collider"))+" site="+str(site.position)+" camera="+str(player.camera.global_position))
		player.interact()
		check(player.work_panel.is_open(),site.kind+": generated fixture E opens controls")
		player.work_panel.close_panel()
		if DisplayServer.get_name()!="headless":
			player.hud.hide()
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../captures/placement"))
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://../captures/placement/generated-"+site.kind+".png")
	print("GENERATED_FIXTURES %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)
