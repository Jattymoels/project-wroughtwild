extends Node3D
## INT-03B: paid station placement against actual player-built geometry.
## Fixed stock isolates fit; no user save, terrain or economy-pacing claim.
var player: WroughtwildPlayer
var build: GridPlacement
var sim: WroughtwildSim
var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL HOME_STATION_CLEARANCE: ",label)

func address(kind: String, axis: int, cell: Vector3i) -> Dictionary:
	return {"kind":kind,"axis":axis,"cell":cell}

func _ready() -> void:
	player=preload("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.class_panel.choose("warden")
	player.position=Vector3(-10,2,-10)
	player.set_physics_process(false)
	player.combat.set_physics_process(false)
	build=player.placement
	build.set_physics_process(false)
	build.set_build_mode_enabled(true)
	sim=player.inventory.get_sim()
	sim.add_material("wood",200)
	for id in ["workbench_kit","mason_yard_kit","forge_kit"]:sim.add_material(id,12)
	_run.call_deferred()

func piece(shape: StringName, at: Dictionary) -> void:
	build.fine_mode=false
	build.selected_material_family=&"wood"
	build.select_shape(shape)
	build.preview_element=at
	build.preview_visible=true
	var before:=sim.material_count("wood")
	check(build.try_place_block(),"ordinary paid construction places "+String(shape))
	check(sim.material_count("wood")==before-sim.shape_material_cost(shape),"construction pays its native cost")
	await get_tree().physics_frame

func station(id: StringName, cell: Vector3i, allowed: bool, label: String, turn:=0) -> void:
	build._select_kit(id)
	build.preview_rotation_step=turn
	build.preview_element=address("volume",0,cell)
	build.preview_visible=true
	var before:=sim.material_count(id)
	var reason:=build.element_refusal(build.preview_element)
	check(reason.is_empty()==allowed,label+": preview verdict ["+reason+"]")
	check(build.try_place_block()==allowed,label+": final placement uses the same verdict")
	check(sim.material_count(id)==before-(1 if allowed else 0),label+": exact kit ownership")
	await get_tree().physics_frame

func _run() -> void:
	for i in 3:
		var id: StringName=[&"workbench_kit",&"mason_yard_kit",&"forge_kit"][i]
		# Horizontal slab skins straddle the build plane by design. They must
		# remain usable supporting surfaces, including half-grid addresses.
		var floor_at:=Vector3i(i*16,0,0)
		await piece(&"floor_slab",address("face",1,floor_at))
		await station(id,floor_at,true,"station on its ordinary floor slab",i)
		var raised:=Vector3i(i*16+1,1,10)
		await piece(&"floor_slab",address("face",1,raised))
		await station(id,raised,true,"station on an off-grid raised slab",3-i)
	# This ceiling occupies a different native element from the kit's cube
	# stand-in, but its underside lies inside the existing two-metre body.
	for turn in 4:
		var at:=Vector3i(64+turn*12,0,0)
		await piece(&"floor_slab",address("face",1,at+Vector3i(0,4,0)))
		await station(&"workbench_kit",at,false,"low ceiling blocks the actual body",turn)
	var clear:=Vector3i(64,0,14)
	await piece(&"floor_slab",address("face",1,clear+Vector3i(0,6,0)))
	await station(&"forge_kit",clear,true,"sufficient built headroom stays valid")
	var beam:=Vector3i(78,0,14)
	await piece(&"beam",address("edge",0,beam+Vector3i(0,3,1)))
	await station(&"mason_yard_kit",beam,false,"overhead beam blocks the body")
	var wall:=Vector3i(92,0,14)
	# INT-03C can seat beside a neighbouring wall skin without intersection.
	# Keep the genuine-obstruction control through the centre of the body:
	# this cannot be cleared by the bounded seating adjustment.
	await piece(&"wall_panel",address("face",0,wall+Vector3i(1,0,0)))
	await station(&"forge_kit",wall,false,"wall intrusion blocks the body")
	await station(&"forge_kit",wall-Vector3i(1,0,0),true,"moving half a cell clears the wall")
	# A late blocker must be rechecked at the actual payment boundary.
	var late:=Vector3i(110,0,14)
	build._select_kit(&"workbench_kit")
	check(build.element_refusal(address("volume",0,late)).is_empty(),"empty candidate starts valid")
	await piece(&"floor_slab",address("face",1,late+Vector3i(0,4,0)))
	await station(&"workbench_kit",late,false,"new overhead block cannot spend a stale preview's kit")
	# D-017's intentional piece-to-piece skin overlap still belongs to the
	# native registry. This fix only changes station-kit physical refusal.
	var joined:=Vector3i(126,0,14)
	await piece(&"cube",address("volume",0,joined))
	await piece(&"wall_panel",address("face",0,joined))
	# Existing saves can contain the formerly permitted overlap. Build the
	# old geometry directly for this compatibility check; no payment claim.
	var legacy_at:=Vector3i(140,0,14)
	await station(&"workbench_kit",legacy_at,true,"legacy save setup starts with a paid station")
	var legacy_roof:=build.place_piece(address("face",1,legacy_at+Vector3i(0,4,0)),&"floor_slab",&"wood")
	check(legacy_roof!=null,"legacy overlap is represented without changing new-placement rules")
	var manager:=SaveManager.new()
	var saved:=manager.capture(player)
	var held:=sim.inventory().duplicate(true)
	check(manager.apply(player,JSON.parse_string(JSON.stringify(saved))),"existing overlapped buildings still load")
	check(manager.capture(player).blocks==saved.blocks and sim.inventory()==held,"restoring legacy geometry neither drops pieces nor pays/refunds stock")
	print("HOME_STATION_CLEARANCE %d checks, %d failures"%[checks,failures])
	get_tree().quit(1 if failures else 0)
