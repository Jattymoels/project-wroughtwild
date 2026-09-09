extends "res://tests/living_frontier_flow.gd"
## F5 isolated transaction test. Two labelled test kits per colour; no economy/pacing claim.
## Uses ordinary collision/placement/input/E and native saves; retained art is test-only.
const KINDS := ["white_connection","blue_delay","green_junction","red_heat_buffer"]
const COLOURS := ["white","blue","green","red"]
const SAVE := "user://art07-f5-placement.json"
func select_at(kind: String, cell: Vector3i) -> void:
	var b:=player.placement
	player.work_panel.close_panel();b.set_build_mode_enabled(true)
	b._select_kit(StringName(kind+"_kit"));b.preview_rotation_step=0
	b.preview_element={"kind":"volume","axis":0,"cell":cell};b.preview_visible=true
func attach_retained(site: ContraptionSite,colour: String) -> void:
	var role:="buffer" if colour=="red" else "post"
	var art:Node3D=load("res://art07f5/assets/"+colour+"/"+colour+"-"+role+"-near.glb").instantiate()
	site.add_child(art)
	check(art.transform==Transform3D.IDENTITY,"retained art uses unchanged native ground origin and metres")
	check(art.find_children("*","MeshInstance3D",true,false).size()>0,"retained actual model imports under usable object")
	if site._visual!=null:site._visual.hide()
func _run_lf() -> void:
	var manager:=SaveManager.new()
	var restore:="--f5-restore" in OS.get_cmdline_user_args()
	var path:=SAVE if restore else "res://art07f5/paid-checkpoint.json"
	if not check(manager.read(path,player),"isolated complete world loads: "+manager.last_error):return _finish_lf()
	freeze_fixtures();refresh_stations()
	# Freshly restored collision bodies enter the physics space on its next step.
	for frame in 2: await get_tree().physics_frame
	if restore:
		var saved:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(SAVE))
		check(JSON.parse_string(_sim().export_json())==JSON.parse_string(saved.sim),"fresh exact inventory/work ownership")
		check(_sim().leyline_save()==saved.leylines,"fresh exact finite source ledger")
		check(JSON.parse_string(_sim().contraption_save())==JSON.parse_string(saved.contraptions),"fresh exact machine ownership")
		var expected:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://art07-f5-placement-expected.json"))
		check(get_tree().get_nodes_in_group("contraptions").size()==int(expected.count),"fresh one usable scene per saved native machine")
		for colour:String in expected.keys_by_colour:
			var site:=ContraptionSite.find_site(get_tree(),expected.keys_by_colour[colour])
			check(site!=null,"fresh placed "+colour+" exists once")
			if site!=null:
				attach_retained(site,colour);await aim_at(site);player.interact()
				check(player.work_panel.is_open(),"fresh "+colour+" E controls usable");player.work_panel.close_panel()
		return _finish_lf()
	var source_before:=_sim().leyline_save()
	var keys_by_colour:Dictionary={}
	for i in KINDS.size():
		var kind:String=KINDS[i];var kit:=kind+"_kit"
		_sim().add_material(kit,2) # Explicit transaction test stock; never added to the handoff's paid checkpoint.
		var existing:=fixture(kind)
		if not check(existing!=null,"paid original "+kind+" present"):return _finish_lf()
		select_at(kind,Vector3i((existing.global_position-Vector3(.5,0,.5))*2.0))
		var owned:=_sim().material_count(kit);var machines:=_sim().contraption_save()
		check(not player.placement.element_accepts(player.placement.preview_element),"actual occupied footprint refuses "+kind)
		check(not player.placement.try_place_block() and _sim().material_count(kit)==owned and _sim().contraption_save()==machines,"failed placement retains kit and exact ledger "+kind)
		var before:=_sim().contraption_ids()
		if not await place_paid_kit(kit,player.spawn_position+Vector3(12+i*4,0,-10)):return _finish_lf()
		var added:Array=[]
		for key in _sim().contraption_ids():
			if key not in before:added.append(key)
		check(added.size()==1 and _sim().material_count(kit)==owned-1,"success creates exactly one paid owner "+kind)
		if added.size()!=1:return _finish_lf()
		var site:=ContraptionSite.find_site(get_tree(),added[0]);check(site!=null,"one physical "+kind+" scene")
		site.set_physics_process(false);attach_retained(site,COLOURS[i])
		keys_by_colour[COLOURS[i]]=added[0]
		select_at(kind,Vector3i((site.global_position-Vector3(.5,0,.5))*2.0));machines=_sim().contraption_save()
		check(not player.placement.try_place_block() and _sim().material_count(kit)==owned-1 and _sim().contraption_save()==machines,"repeat placement retains spare kit "+kind)
		player.placement.set_build_mode_enabled(false)
		await aim_at(site);player.interact()
		check(player.work_panel.is_open(),"actual E opens "+kind+" native controls");player.work_panel.close_panel()
	check(_sim().leyline_save()==source_before,"all placement outcomes retain original finite source hashes")
	check(manager.write(SAVE,player),"complete F5 placement world checkpoint writes")
	FileAccess.open("user://art07-f5-placement-expected.json",FileAccess.WRITE).store_string(JSON.stringify({"count":_sim().contraption_ids().size(),"keys_by_colour":keys_by_colour}))
	_finish_lf()
